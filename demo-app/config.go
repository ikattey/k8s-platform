package main

import "github.com/kelseyhightower/envconfig"

type config struct {
	Port      string        `envconfig:"PORT" default:"8080"`
	DB        dbConfig
	Valkey    valkeyConfig
	Typesense typesenseConfig
	NATS      natsConfig
}

type dbConfig struct {
	WriteDSN string `envconfig:"DATABASE_WRITE_URL"`
	ReadDSN  string `envconfig:"DATABASE_READ_URL"`
}

type valkeyConfig struct {
	Addr string `envconfig:"REDIS_ADDR"` // e.g. valkey.cache:6379
}

type typesenseConfig struct {
	Addr   string `envconfig:"TYPESENSE_ADDR"`    // e.g. typesense.database:8108
	APIKey string `envconfig:"TYPESENSE_API_KEY"`
}

type natsConfig struct {
	URL string `envconfig:"NATS_URL"` // e.g. nats://nats.database:4222
}

func loadConfig() (config, error) {
	var cfg config
	if err := envconfig.Process("", &cfg); err != nil {
		return cfg, err
	}
	if cfg.DB.ReadDSN == "" {
		cfg.DB.ReadDSN = cfg.DB.WriteDSN
	}
	return cfg, nil
}
