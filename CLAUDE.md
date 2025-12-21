# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GitOps Platform Lab - a portfolio project demonstrating platform engineering and SRE expertise through a production-ready Kubernetes platform with complete observability, progressive delivery, and security baseline.

**Tech Stack:** Kubernetes (Kind), ArgoCD, Prometheus/Loki/Tempo, Istio, Argo Rollouts, Cert-Manager, Nginx Ingress

**Purpose:** Showcase platform engineering mindset, production-ready practices, and cloud-native expertise.

## Common Commands

### Cluster Management
```bash
# Create Kind cluster with local registry and ingress
make create-cluster

# Delete Kind cluster
make delete-cluster

# Full cluster bootstrap (create cluster + install core components)
make bootstrap
```

### Component Installation
```bash
# Install ArgoCD
make install-argocd

# Install cert-manager
make install-cert-manager

# Install Nginx Ingress Controller
make install-ingress

# Get ArgoCD admin password
make argocd-password
```

### Deployment
```bash
# Deploy platform services (monitoring, service mesh, etc.)
make deploy-platform

# Deploy demo applications
make deploy-apps

# Check ArgoCD application status
make status
```

### Development Workflow
```bash
# Validate manifests before deployment
./scripts/validate-manifests.sh

# Run integration tests
go test ./tests/integration/...

# Run end-to-end tests
go test ./tests/e2e/...

# Generate load for testing
./scripts/load-test.sh
```

## Architecture

### Three-Layer Structure

1. **Infrastructure Layer** (`infrastructure/`)
   - Bootstrap components installed directly via kubectl/helm
   - ArgoCD, cert-manager, ingress-nginx, Kind cluster config
   - These components enable GitOps workflow

2. **Platform Services Layer** (`platform/`)
   - Managed by ArgoCD using App-of-Apps pattern
   - Observability: kube-prometheus-stack, Loki, Tempo, OpenTelemetry
   - Service Mesh: Istio (Ambient mode)
   - Progressive Delivery: Argo Rollouts
   - Security: Falco, Trivy, Pod Security Standards, Network Policies

3. **Application Layer** (`applications/`)
   - Demo applications managed by ArgoCD
   - Uses Kustomize for environment-specific overlays (dev/staging/production)
   - Progressive delivery with canary and blue-green strategies

### GitOps Workflow

- All platform services and applications are defined declaratively in Git
- ArgoCD continuously syncs cluster state with Git repository
- Changes are made via Git commits, ArgoCD handles deployment
- App-of-Apps pattern: root application manages child applications

### Observability Stack

**Metrics → Logs → Traces correlation:**
- Prometheus scrapes metrics from applications (via ServiceMonitors)
- Loki collects logs from all pods (via Promtail DaemonSet)
- Tempo stores distributed traces (via OpenTelemetry Collector)
- Grafana provides unified dashboards with cross-linking between signals
- OpenTelemetry Collector acts as central collection point for telemetry data

**Demo App instrumentation:**
- Prometheus client for metrics (HTTP request count, duration histograms)
- Structured logging with zap (JSON format with trace IDs)
- OpenTelemetry SDK for distributed tracing (OTLP export)
- All telemetry includes trace_id for correlation

### Progressive Delivery

Argo Rollouts enables:
- **Canary deployments:** Gradual traffic shifting with automated analysis
- **Blue-Green deployments:** Zero-downtime switches with instant rollback
- **Analysis Templates:** Automated promotion based on Prometheus metrics (success rate, latency, error rate)

### Local Registry

A local Docker registry runs at `localhost:5001` for demo app images:
- Connected to Kind cluster network
- Used for rapid iteration without pushing to remote registry
- Configured in Kind cluster via containerd patches

## Key Implementation Patterns

### Helm Values in ArgoCD Applications

Platform services use Helm charts with custom values defined inline in ArgoCD Application manifests. Values are read from separate `values.yaml` files in the platform directory structure.

### Kustomize Overlays for Environments

Applications use base manifests with environment-specific overlays:
- `base/`: Common resources (deployment, service, ingress)
- `overlays/dev/`: Development configuration (low resources, simple deployments)
- `overlays/staging/`: Staging with canary rollouts
- `overlays/production/`: Production with blue-green rollouts and HPA

### Resource Customizations in ArgoCD

Custom health checks for Argo Rollouts defined in `argocd-cm.yaml` to properly detect Rollout status (Degraded, Progressing, Healthy).

### OpenTelemetry Integration

Demo app sends all telemetry to OpenTelemetry Collector, which:
1. Enriches with Kubernetes metadata (pod, namespace, labels)
2. Applies tail sampling (always keep errors and slow requests)
3. Exports to appropriate backends (Tempo for traces, Prometheus for metrics, Loki for logs)

### Security Baseline

- Pod Security Standards enforced at namespace level
- Network Policies with default-deny
- Image scanning via Trivy Operator
- Runtime security monitoring via Falco
- TLS certificates managed by cert-manager

## Important Notes

### ArgoCD Projects

Two ArgoCD projects organize applications:
- `platform`: For infrastructure services (strict policies)
- `applications`: For workload applications (more permissive)

### Ingress Configuration

All ingresses use `nginx` IngressClassName and expect TLS certificates from cert-manager. Hostnames like `argocd.local`, `grafana.local` must be added to `/etc/hosts` pointing to `127.0.0.1`.

### Namespace Organization

- `argocd`: ArgoCD control plane
- `cert-manager`: Certificate management
- `ingress-nginx`: Ingress controller
- `monitoring`: All observability stack components
- `istio-system`: Service mesh components
- `default`: Demo applications (or dedicated app namespaces)

### Kind Cluster Configuration

Multi-node cluster (1 control-plane, 2 workers) with:
- Custom port mappings for HTTP/HTTPS ingress (80, 443)
- Local registry mirror configuration
- Custom pod/service subnets
- Ingress-ready label on control-plane node

## Development Workflow

1. Make changes to manifests in Git
2. Commit and push changes (or test locally by applying to cluster)
3. ArgoCD detects changes and syncs automatically (or manually sync)
4. Verify deployment status: `kubectl get applications -n argocd`
5. Check Grafana dashboards for application health
6. Rollback if needed via Git revert or ArgoCD UI

## Testing Strategy

- **Validation:** Pre-commit validation of YAML manifests
- **Integration tests:** Verify deployments succeed, services are reachable
- **E2E tests:** Full GitOps workflow tests (commit → sync → verify)
- **Load testing:** Verify observability stack captures metrics under load

## Project Structure Philosophy

- `infrastructure/`: Bootstrapped manually (chicken-and-egg problem)
- `platform/`: Self-managed via ArgoCD after bootstrap
- `applications/`: User workloads, completely GitOps-managed
- `docs/`: Architecture, runbooks, guides
- `scripts/`: Automation helpers
- `tests/`: Validation and testing code
