package main

import (
	"log"
	"net/http"
	"time"

	"dashboard-financas-go/internal/cache"
	"dashboard-financas-go/internal/config"
	"dashboard-financas-go/internal/handlers"
	"dashboard-financas-go/internal/service"
)

func main() {
	cfg := config.Load()

	client := &http.Client{
		Timeout: 35 * time.Second,
	}

	appService := service.New(
		client,
		cache.New(),
		cfg.CacheTTL,
		cfg.RustURL,
	)

	handler := handlers.New(
		appService,
		cfg.AllowOrigin,
	)

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           handler.Routes(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      40 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Printf(
		"API Go disponível em http://localhost:%s/api/health",
		cfg.Port,
	)

	log.Printf(
		"Cache local configurado para %s",
		cfg.CacheTTL,
	)

	if err := server.ListenAndServe(); err != nil &&
		err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

