# GitOps Platform Lab

Production-ready Kubernetes platform demonstrating platform engineering and SRE best practices.

## Overview

A complete GitOps-driven platform showcasing:
- **Observability**: Prometheus, Loki, Tempo with full correlation (metrics → logs → traces)
- **Service Mesh**: Istio (Ambient mode)
- **Progressive Delivery**: Argo Rollouts with canary and blue-green strategies
- **Security Baseline**: Falco, Trivy, Pod Security Standards, Network Policies
- **GitOps**: ArgoCD with App-of-Apps pattern

## Tech Stack

- **Kubernetes**: Kind (multi-node local cluster)
- **GitOps**: ArgoCD
- **Observability**: Prometheus, Grafana, Loki, Tempo, OpenTelemetry
- **Service Mesh**: Istio
- **Progressive Delivery**: Argo Rollouts
- **Security**: Falco, Trivy, cert-manager
- **Ingress**: Nginx Ingress Controller

## Quick Start

```bash
# Create Kind cluster and bootstrap platform
make bootstrap

# Deploy platform services (monitoring, service mesh, etc.)
make deploy-platform

# Deploy demo applications
make deploy-apps

# Get ArgoCD admin password
make argocd-password
```

Access services (add to `/etc/hosts` pointing to `127.0.0.1`):
- ArgoCD: https://argocd.local
- Grafana: https://grafana.local

## Architecture

```
infrastructure/     # Bootstrap components (ArgoCD, cert-manager, ingress)
platform/          # Platform services managed by ArgoCD
applications/      # Demo apps with progressive delivery
docs/             # Detailed documentation
scripts/          # Automation helpers
tests/            # Integration and E2E tests
```

## Documentation

- [Detailed Documentation](docs/Readme.md) - Complete architecture and setup guide
- [Quick Start Guide](docs/quick-start.md) - Step-by-step getting started
- [Runbooks](docs/runbooks/) - Operational procedures

## Key Features

- **GitOps Workflow**: All changes via Git commits, ArgoCD handles deployment
- **Full Observability**: Metrics, logs, and traces with correlation and unified dashboards
- **Automated Rollouts**: Canary and blue-green deployments with metric-based analysis
- **Security First**: Runtime monitoring, image scanning, network policies, TLS everywhere
- **Local Development**: Complete platform running locally on Kind

## Common Commands

```bash
make create-cluster     # Create Kind cluster
make delete-cluster     # Delete Kind cluster
make status            # Check ArgoCD application status
make install-argocd    # Install ArgoCD
make install-ingress   # Install Nginx Ingress
```

## Project Purpose

Portfolio project demonstrating:
- Platform engineering mindset
- Production-ready practices
- Cloud-native expertise
- GitOps workflows
- Observability and SRE principles
