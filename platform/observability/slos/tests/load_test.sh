#!/bin/bash
# load_test.sh
# Generates traffic to the demo-app to test SLOs and Error Budget formatting.

# Default endpoints (adjust if port-forwarding differs)
URL="http://localhost:8080"

echo "🚀 Starting Load Test for SLO Verification"
echo "Target: $URL"
echo "Press [CTRL+C] to stop."

while true; do
  # 1. Generate Successful Requests (High volume/Fast)
  # curl -s -o /dev/null -w "%{http_code}\n" "$URL/health"
  # match normal traffic pattern
  for i in {1..20}; do
    curl -s "$URL/health" > /dev/null
  done

  # 2. Generate Errors (Low volume - to burn budget slowly)
  # Uncomment to test error budget alert
  # curl -s "$URL/error" > /dev/null
  
  # 3. Generate Latency (Occasional slow request)
  # Assuming /delay endpoint exists or simulate network delay
  # curl -s "$URL/delay?seconds=1" > /dev/null

  sleep 0.5
  echo -n "."
done
