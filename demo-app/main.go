package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"
)

type serviceStatus struct {
	Status string `json:"status"`
	Host   string `json:"host,omitempty"`
	Error  string `json:"error,omitempty"`
}

type healthResponse struct {
	Status   string                   `json:"status"`
	Uptime   string                   `json:"uptime"`
	Services map[string]serviceStatus `json:"services,omitempty"`
}

type app struct {
	startTime time.Time
	db        *database
	dragonfly *dragonflyClient
	typesense *typesenseClient
	nats      *natsClient
}

func main() {
	cfg, err := loadConfig()
	if err != nil {
		log.Fatalf("loading config: %v", err)
	}

	a := &app{startTime: time.Now()}

	// PostgreSQL is the primary data store — fatal on connection failure.
	// Data layer services (Dragonfly, Typesense, NATS) are auxiliary — warn and continue.
	if cfg.DB.WriteDSN != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		db, err := newDatabase(ctx, cfg.DB.WriteDSN, cfg.DB.ReadDSN)
		cancel()
		if err != nil {
			log.Fatalf("connecting to database: %v", err)
		}
		a.db = db

		logCtx, logCancel := context.WithTimeout(context.Background(), 3*time.Second)
		log.Printf("write pool connected: %s", poolHost(logCtx, db.WritePool))
		logCancel()

		logCtx, logCancel = context.WithTimeout(context.Background(), 3*time.Second)
		log.Printf("read pool connected: %s", poolHost(logCtx, db.ReadPool))
		logCancel()
	}

	// Dragonfly (optional)
	if cfg.Dragonfly.Addr != "" {
		df, err := newDragonfly(cfg.Dragonfly.Addr)
		if err != nil {
			log.Printf("WARNING: dragonfly not available: %v", err)
		} else {
			a.dragonfly = df
			log.Printf("dragonfly connected: %s", cfg.Dragonfly.Addr)
		}
	}

	// Typesense (optional)
	if cfg.Typesense.Addr != "" {
		ts, err := newTypesense(cfg.Typesense.Addr, cfg.Typesense.APIKey)
		if err != nil {
			log.Printf("WARNING: typesense not available: %v", err)
		} else {
			a.typesense = ts
			log.Printf("typesense connected: %s", cfg.Typesense.Addr)
		}
	}

	// NATS (optional)
	if cfg.NATS.URL != "" {
		nc, err := newNATS(cfg.NATS.URL)
		if err != nil {
			log.Printf("WARNING: nats not available: %v", err)
		} else {
			a.nats = nc
			log.Printf("nats connected: %s", cfg.NATS.URL)
		}
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /", a.handleHealth)
	mux.HandleFunc("GET /healthz", a.handleHealthz)
	mux.HandleFunc("GET /readyz", a.handleReady)

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           mux,
		ReadTimeout:       5 * time.Second,
		ReadHeaderTimeout: 3 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("shutting down...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
	if a.db != nil {
		a.db.Close()
	}
	if a.dragonfly != nil {
		a.dragonfly.Close()
	}
	if a.typesense != nil {
		a.typesense.Close()
	}
	if a.nats != nil {
		a.nats.Close()
	}
	log.Println("stopped")
}

func (a *app) handleHealth(w http.ResponseWriter, r *http.Request) {
	resp := healthResponse{
		Status:   "up",
		Uptime:   time.Since(a.startTime).Round(time.Second).String(),
		Services: make(map[string]serviceStatus),
	}

	if a.db != nil {
		ws := checkPool(r.Context(), a.db.WritePool)
		resp.Services["postgres-write"] = ws
		if ws.Status != "up" {
			resp.Status = "degraded"
		}

		rs := checkPool(r.Context(), a.db.ReadPool)
		resp.Services["postgres-read"] = rs
		if rs.Status != "up" {
			resp.Status = "degraded"
		}
	}

	if a.dragonfly != nil {
		ds := a.dragonfly.Check(r.Context())
		resp.Services["dragonfly"] = ds
		if ds.Status != "up" {
			resp.Status = "degraded"
		}
	}

	if a.typesense != nil {
		ts := a.typesense.Check(r.Context())
		resp.Services["typesense"] = ts
		if ts.Status != "up" {
			resp.Status = "degraded"
		}
	}

	if a.nats != nil {
		ns := a.nats.Check(r.Context())
		resp.Services["nats"] = ns
		if ns.Status != "up" {
			resp.Status = "degraded"
		}
	}

	// If no services configured, omit the map
	if len(resp.Services) == 0 {
		resp.Services = nil
	}

	code := http.StatusOK
	if resp.Status != "up" {
		code = http.StatusServiceUnavailable
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(resp)
}

func (a *app) handleHealthz(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "ok")
}

func (a *app) handleReady(w http.ResponseWriter, r *http.Request) {
	if a.db != nil {
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()

		if err := a.db.WritePool.Ping(ctx); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprintln(w, "write db unreachable")
			return
		}
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "ok")
}
