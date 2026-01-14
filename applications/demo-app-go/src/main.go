package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	defaultPort    = "8080"
	defaultVersion = "v1.0.0"
)

func main() {
	// Get configuration from environment
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	version := os.Getenv("VERSION")
	if version == "" {
		version = defaultVersion
	}

	// Initialize metrics
	initMetrics()

	// Setup HTTP routes
	mux := http.NewServeMux()

	// Application endpoints
	mux.HandleFunc("/", handleHome)
	mux.HandleFunc("/health", handleHealth)
	mux.HandleFunc("/ready", handleReady)
	mux.HandleFunc("/version", handleVersion(version))
	mux.HandleFunc("/api/data", handleData)
	mux.HandleFunc("/api/slow", handleSlow)
	mux.HandleFunc("/api/error", handleError)

	// Metrics endpoint
	mux.Handle("/metrics", promhttp.Handler())

	// Wrap with metrics middleware
	handler := metricsMiddleware(mux)

	// Create HTTP server
	server := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Starting server on port %s (version: %s)", port, version)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped")
}

func handleHome(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	w.Header().Set("Content-Type", "text/html")
	fmt.Fprintf(w, `<!DOCTYPE html>
<html>
<head>
	<title>Demo App Go</title>
	<style>
		body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
		h1 { color: #326ce5; }
		.endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-left: 3px solid #326ce5; }
		code { background: #e0e0e0; padding: 2px 6px; border-radius: 3px; }
	</style>
</head>
<body>
	<h1>🚀 Demo App Go - GitOps Platform</h1>
	<p>Progressive Delivery Demo Application with Prometheus Metrics</p>

	<h2>Available Endpoints:</h2>
	<div class="endpoint"><code>GET /</code> - This page</div>
	<div class="endpoint"><code>GET /health</code> - Health check</div>
	<div class="endpoint"><code>GET /ready</code> - Readiness probe</div>
	<div class="endpoint"><code>GET /version</code> - Application version</div>
	<div class="endpoint"><code>GET /api/data</code> - Sample API endpoint</div>
	<div class="endpoint"><code>GET /api/slow</code> - Slow endpoint (2s delay)</div>
	<div class="endpoint"><code>GET /api/error</code> - Error endpoint (50%% failure rate)</div>
	<div class="endpoint"><code>GET /metrics</code> - Prometheus metrics</div>

	<h2>Observability:</h2>
	<ul>
		<li>Prometheus metrics exported on /metrics</li>
		<li>Request count, duration, and in-flight requests tracked</li>
		<li>Instrumented for Argo Rollouts analysis</li>
	</ul>
</body>
</html>`)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"healthy","timestamp":"%s"}`, time.Now().Format(time.RFC3339))
}

func handleReady(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"ready","timestamp":"%s"}`, time.Now().Format(time.RFC3339))
}

func handleVersion(version string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"version":"%s","buildTime":"%s"}`, version, time.Now().Format(time.RFC3339))
	}
}
