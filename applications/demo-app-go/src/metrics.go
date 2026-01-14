package main

import (
	"net/http"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// httpRequestsTotal counts total HTTP requests by method, endpoint, and status
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	// httpRequestDuration tracks HTTP request latency
	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets, // [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
		},
		[]string{"method", "endpoint", "status"},
	)

	// httpRequestsInFlight tracks currently processing requests
	httpRequestsInFlight = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "http_requests_in_flight",
			Help: "Number of HTTP requests currently being processed",
		},
	)

	// Custom business metrics
	apiCallsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "api_calls_total",
			Help: "Total number of API calls",
		},
		[]string{"endpoint", "result"},
	)

	errorRateTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "error_rate_total",
			Help: "Total number of errors",
		},
	)
)

// initMetrics initializes Prometheus metrics
func initMetrics() {
	// Metrics are automatically registered via promauto
	// This function exists for future initialization needs
}

// metricsMiddleware wraps HTTP handlers to collect metrics
func metricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Skip metrics for /metrics endpoint itself
		if r.URL.Path == "/metrics" {
			next.ServeHTTP(w, r)
			return
		}

		start := time.Now()

		// Increment in-flight requests
		httpRequestsInFlight.Inc()
		defer httpRequestsInFlight.Dec()

		// Create response writer wrapper to capture status code
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		// Process request
		next.ServeHTTP(rw, r)

		// Record metrics
		duration := time.Since(start).Seconds()
		status := strconv.Itoa(rw.statusCode)
		endpoint := r.URL.Path
		method := r.Method

		httpRequestsTotal.WithLabelValues(method, endpoint, status).Inc()
		httpRequestDuration.WithLabelValues(method, endpoint, status).Observe(duration)

		// Track API-specific metrics
		if len(endpoint) > 4 && endpoint[:4] == "/api" {
			result := "success"
			if rw.statusCode >= 400 {
				result = "error"
				errorRateTotal.Inc()
			}
			apiCallsTotal.WithLabelValues(endpoint, result).Inc()
		}
	})
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}
