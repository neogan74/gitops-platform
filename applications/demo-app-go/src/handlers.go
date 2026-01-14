package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"time"
)

// handleData returns sample data
func handleData(w http.ResponseWriter, r *http.Request) {
	data := map[string]interface{}{
		"message":   "Hello from demo-app-go!",
		"timestamp": time.Now().Format(time.RFC3339),
		"random":    rand.Intn(1000),
		"status":    "success",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// handleSlow simulates a slow endpoint for testing latency
func handleSlow(w http.ResponseWriter, r *http.Request) {
	// Simulate slow processing
	time.Sleep(2 * time.Second)

	data := map[string]interface{}{
		"message":   "This was a slow endpoint",
		"timestamp": time.Now().Format(time.RFC3339),
		"delay":     "2s",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// handleError simulates errors for testing failure scenarios
func handleError(w http.ResponseWriter, r *http.Request) {
	// 50% chance of error
	if rand.Intn(2) == 0 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, `{"error":"Internal server error","timestamp":"%s"}`, time.Now().Format(time.RFC3339))
		return
	}

	// Success response
	data := map[string]interface{}{
		"message":   "Success despite error endpoint",
		"timestamp": time.Now().Format(time.RFC3339),
		"lucky":     true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
