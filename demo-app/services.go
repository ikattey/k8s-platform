package main

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/redis/go-redis/v9"
)

// --- Valkey (Redis-compatible) ---

type valkeyClient struct {
	client *redis.Client
}

func newValkey(addr string) (*valkeyClient, error) {
	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		client.Close()
		return nil, fmt.Errorf("valkey ping: %w", err)
	}
	return &valkeyClient{client: client}, nil
}

func (v *valkeyClient) Check(ctx context.Context) serviceStatus {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	if err := v.client.Ping(ctx).Err(); err != nil {
		return serviceStatus{Status: "down", Error: err.Error()}
	}
	return serviceStatus{Status: "up", Host: v.client.Options().Addr}
}

func (v *valkeyClient) Close() { v.client.Close() }

// --- Typesense ---

type typesenseClient struct {
	addr   string
	apiKey string
	http   *http.Client
}

func newTypesense(addr, apiKey string) (*typesenseClient, error) {
	tc := &typesenseClient{
		addr:   addr,
		apiKey: apiKey,
		http:   &http.Client{Timeout: 5 * time.Second},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	status := tc.Check(ctx)
	if status.Status != "up" {
		return nil, fmt.Errorf("typesense health: %s", status.Error)
	}
	return tc, nil
}

func (t *typesenseClient) Check(ctx context.Context) serviceStatus {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", fmt.Sprintf("http://%s/health", t.addr), nil)
	if err != nil {
		return serviceStatus{Status: "down", Error: err.Error()}
	}
	if t.apiKey != "" {
		req.Header.Set("X-TYPESENSE-API-KEY", t.apiKey)
	}

	resp, err := t.http.Do(req)
	if err != nil {
		return serviceStatus{Status: "down", Error: err.Error()}
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		return serviceStatus{Status: "up", Host: t.addr}
	}
	return serviceStatus{Status: "down", Error: fmt.Sprintf("status %d", resp.StatusCode)}
}

func (t *typesenseClient) Close() { t.http.CloseIdleConnections() }

// --- NATS ---

type natsClient struct {
	conn *nats.Conn
}

func newNATS(url string) (*natsClient, error) {
	nc, err := nats.Connect(url,
		nats.Timeout(5*time.Second),
		nats.MaxReconnects(-1), // infinite reconnects — K8s pods restart
		nats.ReconnectWait(time.Second),
	)
	if err != nil {
		return nil, fmt.Errorf("nats connect: %w", err)
	}
	return &natsClient{conn: nc}, nil
}

func (n *natsClient) Check(_ context.Context) serviceStatus {
	if n.conn.IsConnected() {
		return serviceStatus{Status: "up", Host: n.conn.ConnectedUrlRedacted()}
	}
	return serviceStatus{Status: "down", Error: "not connected"}
}

func (n *natsClient) Close() { n.conn.Close() }
