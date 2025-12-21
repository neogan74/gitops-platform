# Quick Start Guide - Week 1 Foundation

## Prerequisites

Ensure you have the following tools installed:
- Docker
- Kind (Kubernetes in Docker)
- kubectl
- helm

## Bootstrap the Platform

### Option 1: Using Makefile (Recommended)

```bash
# See all available commands
make help

# Create cluster and install all bootstrap components
make bootstrap

# Get ArgoCD admin password
make argocd-password
```

### Option 2: Using Bootstrap Script

```bash
./scripts/bootstrap.sh
```

## What Gets Installed

### Bootstrap Layer (installed directly)
- **Kind Cluster**: 3-node cluster (1 control-plane, 2 workers)
- **Local Registry**: localhost:5001 for demo app images
- **ArgoCD**: GitOps deployment controller
- **Cert-Manager**: TLS certificate management
- **Nginx Ingress**: Ingress controller

### Platform Services Layer (managed by ArgoCD)
- **Kube-Prometheus-Stack**: Prometheus, Grafana, Alertmanager
  - Pre-configured dashboards
  - Metrics collection
  - Grafana accessible at grafana.local

### Application Layer
- **Demo App**: Simple nginx application (placeholder)
  - Accessible at demo-app.local
  - Uses Kustomize overlays for environments

## Access Services

### 1. ArgoCD UI

```bash
# Port-forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
make argocd-password

# Access at: https://localhost:8080
# Username: admin
```

### 2. Grafana

```bash
# Add to /etc/hosts
echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts

# Access at: http://grafana.local
# Username: admin
# Password: admin (change in production!)
```

### 3. Demo Application

```bash
# Add to /etc/hosts
echo "127.0.0.1 demo-app.local" | sudo tee -a /etc/hosts

# Access at: http://demo-app.local
```

## Deploy Platform Services

```bash
# Deploy monitoring stack via ArgoCD
make deploy-platform

# Check deployment status
make status

# Or view in ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Deploy Demo Application

```bash
# Deploy demo app via ArgoCD
make deploy-apps

# Check status
kubectl get pods -n default

# Access the app
curl http://demo-app.local
```

## Verify Everything is Working

```bash
# Check cluster health
make check-cluster

# View all ArgoCD applications
make status

# Check specific namespaces
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get pods -n cert-manager
kubectl get pods -n ingress-nginx
kubectl get pods -n default
```

## Troubleshooting

### ArgoCD Applications Not Syncing

```bash
# Check ArgoCD server logs
make logs-argocd

# Manually sync an application
kubectl get applications -n argocd
# Then sync in UI or:
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verify /etc/hosts entries
cat /etc/hosts | grep local
```

### Certificate Issues

```bash
# Check cert-manager
kubectl get pods -n cert-manager
kubectl get certificates -A
kubectl get clusterissuers

# Check certificate details
kubectl describe certificate <cert-name> -n <namespace>
```

## Cleanup

```bash
# Delete everything
make clean

# Or just delete cluster
make delete-cluster
```

## Next Steps

After Week 1 foundation is complete:

1. **Week 2**: Add full observability stack
   - Loki for log aggregation
   - Tempo for distributed tracing
   - OpenTelemetry Collector
   - Replace nginx demo app with Go app

2. **Week 3+**: Add advanced features
   - Istio service mesh
   - Argo Rollouts for progressive delivery
   - Security tools (Falco, Trivy)
   - Network policies

## Important Notes

### GitHub Repository URL

All ArgoCD application manifests reference `GITHUB_USERNAME/gitops-platform-lab.git`.
You need to update this to your actual GitHub repository:

```bash
# Update all files
find . -type f -name "*.yaml" -exec sed -i 's/GITHUB_USERNAME/your-github-username/g' {} +
```

### Production Considerations

Current setup is for **demo/learning purposes only**:
- Self-signed certificates (use Let's Encrypt in production)
- Default Grafana password (change immediately!)
- No persistent storage for some components
- Minimal resource limits
- All services on single cluster

## Useful Commands

```bash
# Watch all pods
watch kubectl get pods -A

# View ArgoCD apps
kubectl get applications -n argocd -w

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -A

# View events
kubectl get events -A --sort-by='.lastTimestamp'
```
