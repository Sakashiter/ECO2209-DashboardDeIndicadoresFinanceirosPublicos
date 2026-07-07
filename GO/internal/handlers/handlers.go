package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"dashboard-financas-go/internal/service"
)

type Handler struct {
	service *service.Service
	origin  string
}

func New(appService *service.Service, allowOrigin string) *Handler {
	return &Handler{
		service: appService,
		origin:  allowOrigin,
	}
}

func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /api/health", h.health)
	mux.HandleFunc("GET /api/indicadores", h.indicators)
	mux.HandleFunc("GET /api/historico/", h.history)
	mux.HandleFunc("GET /api/relatorios/csv", h.csv)

	return h.withCORS(h.withLogging(mux))
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"service": "dashboard-financas-go",
	})
}

func (h *Handler) indicators(w http.ResponseWriter, r *http.Request) {
	data, err := h.service.GetIndicators(r.Context())

	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{
			"erro": "Não foi possível consultar os provedores externos.",
		})
		return
	}

	writeJSON(w, http.StatusOK, data)
}

func (h *Handler) history(w http.ResponseWriter, r *http.Request) {
	indicator := strings.TrimPrefix(
		r.URL.Path,
		"/api/historico/",
	)

	if indicator != "ipca" &&
		indicator != "selic" &&
		indicator != "dolar" {
		writeJSON(w, http.StatusBadRequest, map[string]string{
			"erro": "Indicador inválido. Use ipca, selic ou dolar.",
		})
		return
	}

	data, err := h.service.GetHistory(
		r.Context(),
		indicator,
	)

	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{
			"erro": "Não foi possível consultar o histórico solicitado.",
		})
		return
	}

	writeJSON(w, http.StatusOK, data)
}

func (h *Handler) csv(w http.ResponseWriter, r *http.Request) {
	data, err := h.service.CSV(r.Context())

	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{
			"erro": "Não foi possível gerar o relatório CSV.",
		})
		return
	}

	fileName := "indicadores_financeiros_" +
		time.Now().Format("20060102_150405") +
		".csv"

	w.Header().Set(
		"Content-Type",
		"text/csv; charset=utf-8",
	)

	w.Header().Set(
		"Content-Disposition",
		"attachment; filename="+fileName,
	)

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(data)
}

func (h *Handler) withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set(
			"Access-Control-Allow-Origin",
			h.origin,
		)

		w.Header().Set(
			"Access-Control-Allow-Methods",
			"GET, OPTIONS",
		)

		w.Header().Set(
			"Access-Control-Allow-Headers",
			"Content-Type",
		)

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func (h *Handler) withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		next.ServeHTTP(w, r)

		log.Printf(
			"%s %s em %s",
			r.Method,
			r.URL.Path,
			time.Since(start).Round(time.Millisecond),
		)
	})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set(
		"Content-Type",
		"application/json; charset=utf-8",
	)

	w.WriteHeader(status)

	_ = json.NewEncoder(w).Encode(value)
}
