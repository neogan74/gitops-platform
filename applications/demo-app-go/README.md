# Demo App Go - Progressive Delivery Demo

A demonstration Go application showcasing progressive delivery patterns with Argo Rollouts, complete Prometheus instrumentation, and multi-environment deployment strategies.

## Features

### Application
- **HTTP Server**: Lightweight Go web server with graceful shutdown
- **Endpoints**:
  - `GET /` - Homepage with documentation
  - `GET /health` - Liveness probe
  - `GET /ready` - Readiness probe
  - `GET /version` - Application version info
  - `GET /api/data` - Sample API endpoint
  - `GET /api/slow` - Simulates slow requests (2s delay)
  - `GET /api/error` - Simulates errors (50% failure rate)
  - `GET /metrics` - Prometheus metrics

### Observability
- **Prometheus Metrics**:
  - `http_requests_total` - Request counter by method, endpoint, status
  - `http_request_duration_seconds` - Request latency histogram
  - `http_requests_in_flight` - Active request gauge
  - `api_calls_total` - API-specific counters
  - `error_rate_total` - Error counter
- **ServiceMonitor**: Automatic Prometheus scraping configuration
- **Health Checks**: Kubernetes liveness/readiness probes

### Progressive Delivery

#### Development Environment
- **Namespace**: `default`
- **Strategy**: Immediate rollout (no progressive delivery)
- **Replicas**: 1
- **Resources**: Minimal (50m CPU, 32Mi RAM)
- **Use Case**: Rapid iteration and testing

#### Staging Environment
- **Namespace**: `staging`
- **Strategy**: **Canary Deployment**
- **Replicas**: 2
- **Traffic Shift**:
  1. 20% traffic → Pause 1m → Analysis
  2. 40% traffic → Pause 1m → Analysis
  3. 60% traffic → Pause 1m → Analysis
  4. 100% traffic (full promotion)
- **Analysis**:
  - Error rate < 5%
  - Success rate ≥ 99%
  - p95 latency < 500ms
- **Auto-rollback**: Enabled on analysis failure

#### Production Environment
- **Namespace**: `production`
- **Strategy**: **Blue-Green Deployment**
- **Replicas**: 3 (HPA: 3-10)
- **Process**:
  1. Deploy green version alongside blue
  2. Run pre-promotion analysis
  3. **Manual approval required** for promotion
  4. Switch traffic to green
  5. Run post-promotion analysis
  6. Scale down blue after 30s delay
- **HPA**: Auto-scaling based on CPU (70%) and memory (80%)

## Project Structure

```
demo-app-go/
├── src/
│   ├── main.go              # HTTP server entry point
│   ├── handlers.go          # HTTP request handlers
│   ├── metrics.go           # Prometheus metrics
│   ├── go.mod               # Go dependencies
│   └── go.sum               # Dependency checksums
├── k8s/
│   ├── base/
│   │   ├── rollout.yaml           # Argo Rollout base
│   │   ├── service.yaml           # Kubernetes Services
│   │   ├── ingress.yaml           # Ingress configuration
│   │   ├── servicemonitor.yaml    # Prometheus integration
│   │   ├── analysistemplate.yaml  # Metrics-based analysis
│   │   └── kustomization.yaml     # Base Kustomize config
│   └── overlays/
│       ├── dev/                   # Development overlay
│       ├── staging/               # Staging (canary)
│       └── production/            # Production (blue-green)
├── Dockerfile              # Multi-stage Docker build
├── Makefile               # Build automation
└── README.md              # This file
```

## Building and Deploying

### Local Development

```bash
# Run locally
cd src
go run .

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/metrics
```

### Docker Build

```bash
# Build and push to local registry
make build VERSION=v1.0.0
make push VERSION=v1.0.0

# Quick dev build
make dev
```

### Deploy via ArgoCD

```bash
# Deploy development environment
kubectl apply -f ../demo-app-go-dev.yaml

# Deploy staging environment (canary)
kubectl apply -f ../demo-app-go-staging.yaml

# Deploy production environment (blue-green)
kubectl apply -f ../demo-app-go-production.yaml
```

## Monitoring Deployments

### Watch Rollout Status

```bash
# Development
kubectl argo rollouts get rollout demo-app-go -n default -w

# Staging (canary)
kubectl argo rollouts get rollout staging-demo-app-go -n staging -w

# Production (blue-green)
kubectl argo rollouts get rollout prod-demo-app-go -n production -w
```

### Promote/Abort Rollouts

```bash
# Promote (skip analysis/pauses)
kubectl argo rollouts promote <rollout-name> -n <namespace>

# Abort (rollback to stable)
kubectl argo rollouts abort <rollout-name> -n <namespace>
```

### Access Application

```bash
# Add to /etc/hosts
echo "127.0.0.1 demo.local staging-demo.local prod-demo.local" | sudo tee -a /etc/hosts

# Access endpoints
curl https://demo.local/
curl https://staging-demo.local/
curl https://prod-demo.local/
```

## Analysis Templates

### success-rate
Comprehensive analysis checking:
- Success rate ≥ 99%
- p95 latency < 500ms
- Error rate < 1%

**Usage**: Production and staging final promotion

### error-rate-only
Quick error rate check:
- Error rate < 5%

**Usage**: Staging early gates

## Environment Variables

- `PORT` - HTTP server port (default: 8080)
- `VERSION` - Application version (default: v1.0.0)
- `ENVIRONMENT` - Environment name (set by overlay)

## Security

- **Non-root user**: Runs as UID 1000
- **Read-only root filesystem**: Enabled
- **Dropped capabilities**: All Linux capabilities dropped
- **Resource limits**: CPU and memory limits enforced
- **Multi-stage build**: Minimal attack surface (Alpine base)

## Testing Progressive Delivery

### Simulate Canary Rollout (Staging)

```bash
# 1. Deploy v1.0.0
kubectl apply -f ../demo-app-go-staging.yaml

# 2. Update image to v1.1.0 in k8s/overlays/staging/kustomization.yaml
# 3. Commit and push (or manually apply)

# 4. Watch canary progression
kubectl argo rollouts get rollout staging-demo-app-go -n staging -w

# 5. Observe analysis results
kubectl get analysisrun -n staging -w
```

### Simulate Blue-Green Rollout (Production)

```bash
# 1. Deploy v1.0.0
kubectl apply -f ../demo-app-go-production.yaml

# 2. Update image to v1.1.0
# 3. Watch blue-green deployment
kubectl argo rollouts get rollout prod-demo-app-go -n production -w

# 4. Manually promote after analysis passes
kubectl argo rollouts promote prod-demo-app-go -n production

# 5. Verify green version is active
kubectl get svc prod-demo-app-go -n production -o yaml | grep selector
```

## Grafana Dashboards

Import the provided dashboard for visualizing:
- Request rates and error rates
- Latency percentiles (p50, p95, p99)
- Rollout status and analysis results
- Resource usage and scaling events

## Troubleshooting

### Rollout Stuck

```bash
# Check rollout status
kubectl argo rollouts status <rollout-name> -n <namespace>

# Check analysis runs
kubectl get analysisrun -n <namespace>

# View analysis logs
kubectl describe analysisrun <name> -n <namespace>
```

### Metrics Not Available

```bash
# Verify ServiceMonitor
kubectl get servicemonitor -n <namespace>

# Check Prometheus targets
# Access Prometheus UI and check targets page

# Test metrics endpoint directly
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
curl http://localhost:8080/metrics
```

### Analysis Failing

```bash
# Check Prometheus connectivity
kubectl exec -it <rollout-pod> -n <namespace> -- wget -O- \
  http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=up

# Verify metrics are being collected
# Check Prometheus for http_requests_total{app="demo-app-go"}
```

## Future Enhancements

- [ ] Distributed tracing with OpenTelemetry
- [ ] Structured logging with correlation IDs
- [ ] Service mesh integration (Istio traffic splitting)
- [ ] Notification webhooks (Slack, PagerDuty)
- [ ] Automated load testing during canary
- [ ] Custom metrics for business KPIs
