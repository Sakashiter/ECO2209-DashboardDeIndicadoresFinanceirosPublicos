package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port        string
	CacheTTL    time.Duration
	AllowOrigin string
	RustURL     string
}

func Load() Config {
	port := envOrDefault("PORT", "8080")
	origin := envOrDefault("ALLOW_ORIGIN", "*")
	rustURL := envOrDefault("RUST_URL", "http://localhost:3000")

	cacheMinutes, err := strconv.Atoi(
		envOrDefault("CACHE_MINUTES", "5"),
	)

	if err != nil || cacheMinutes < 1 {
		cacheMinutes = 5
	}

	return Config{
		Port:        port,
		CacheTTL:    time.Duration(cacheMinutes) * time.Minute,
		AllowOrigin: origin,
		RustURL:     rustURL,
	}
}

func envOrDefault(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}

	return fallback
}
