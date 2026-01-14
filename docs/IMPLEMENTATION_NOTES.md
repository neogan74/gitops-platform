# Implementation Notes - Technical Reference

## Quick Context Restore

**What we built:** Week 1 Foundation for GitOps Platform Lab
**Status:** All files created (30+), ready to test
**Approach:** Step-by-step with testing checkpoints

---

## Critical Information

### Must Update Before Testing

```bash
# 1. Replace GitHub username in all YAML files
find . -type f -name "*.yaml" -exec sed -i 's/GITHUB_USERNAME/YOUR_ACTUAL_USERNAME/g' {} +

# 2. Initialize git repository
git init
git add .
git commit -m "Week 1: Foundation implementation"
git branch -M main

# 3. Create GitHub repo and push
git remote add origin https://github.com/YOUR_USERNAME/gitops-platform-lab.git
git push -u origin main

# 4. Add /etc/hosts entries
echo "127.0.0.1 grafana.local demo-app.local" | sudo tee -a /etc/hosts
```

### Quick Start

```bash
# Bootstrap (creates cluster + installs base components)
make bootstrap

# Deploy monitoring stack
make deploy-platform

# Deploy demo app
make deploy-apps

# Check status
make status
```

---

## Architecture Decisions

### Why Kind?
- Easy local development
- Multi-node simulation
- Port mapping for ingress
- Fast cluster creation/deletion

### Why App-of-Apps Pattern?
- Single root application manages all children
- Clear separation: platform vs applications
- Easy to add new services
- GitOps best practice

### Why Kustomize?
- Native to kubectl
- Environment overlays (dev/staging/prod)
- No templating complexity
- Good for simple use cases

### Why Self-Signed Certificates?
- Demo environment
- No external dependencies
- cert-manager practice
- Easy to switch to Let's Encrypt later

---

## Design Patterns Used

### 1. GitOps Pattern
- Git as single source of truth
- ArgoCD for continuous sync
- Declarative configuration
- Self-healing enabled

### 2. Infrastructure as Code
- All configuration in YAML
- Version controlled
- Reproducible
- Documented

### 3. Three-Layer Architecture
```
Infrastructure (kubectl/helm) → Platform (ArgoCD) → Apps (ArgoCD)
     Bootstrap                     Monitoring          Demo App
     ArgoCD                        Logging (future)    User Apps
     Cert-Manager                  Tracing (future)
     Ingress                       Service Mesh (future)
```

### 4. Separation of Concerns
- Infrastructure: manually bootstrapped (chicken-and-egg)
- Platform: ArgoCD-managed, platform team owned
- Applications: ArgoCD-managed, app team owned
- Projects: RBAC separation (platform vs applications)

---

## Key Files Explained

### `Makefile`
**Purpose:** Main automation interface
**Key Targets:**
- `bootstrap`: End-to-end cluster setup
- `deploy-platform`: Deploy monitoring
- `deploy-apps`: Deploy applications
- `status`: Check deployment status

**Why Makefile?**
- Standardized interface
- Self-documenting (make help)
- Easy to extend
- IDE integration

### `platform/app-of-apps.yaml`
**Purpose:** Root ArgoCD application for platform services
**Current:** Only deploys kube-prometheus-stack
**Future:** Will include Loki, Tempo, Istio, Argo Rollouts, etc.

**Pattern:**
```yaml
Application → Directory → Individual Applications
   (root)        (platform/observability/)    (kube-prometheus-stack)
```

### `infrastructure/argocd/argocd-cm.yaml`
**Purpose:** ArgoCD configuration
**Key Settings:**
- Repository URL (must update!)
- Rollout health checks (for Argo Rollouts)
- UI customization
- Timeout settings

**Critical:** Update `GITHUB_USERNAME` before deploying!

### `applications/demo-app/`
**Purpose:** Demo application with Kustomize overlays
**Structure:**
- `base/`: Common manifests
- `overlays/dev/`: Dev-specific patches
- `application.yaml`: ArgoCD app definition

**Pattern:** Base + Overlays for environment-specific config

---

## Resource Sizing

All resources sized for **demo/learning**, not production.

### Kind Cluster
- Control-plane: 1 node
- Workers: 2 nodes
- No resource limits on nodes

### Prometheus
```yaml
requests: { cpu: 200m, memory: 512Mi }
limits:   { cpu: 1000m, memory: 2Gi }
retention: 7d
storage: 10Gi
```

### Grafana
```yaml
requests: { cpu: 100m, memory: 128Mi }
limits:   { cpu: 500m, memory: 512Mi }
storage: 5Gi
```

### Demo App (Nginx)
```yaml
dev overlay:
  requests: { cpu: 25m, memory: 32Mi }
  limits:   { cpu: 100m, memory: 64Mi }
  replicas: 1
```

---

## Security Considerations

### Current Implementation
- ✅ RBAC for ArgoCD projects
- ✅ Self-signed CA for TLS
- ✅ Resource limits defined
- ✅ Network policies ready (not yet applied)
- ✅ Security contexts in some components

### Not Yet Implemented (Week 3+)
- ⏳ Pod Security Standards enforcement
- ⏳ Network Policies (default deny)
- ⏳ Image scanning (Trivy)
- ⏳ Runtime security (Falco)
- ⏳ Secret management (External Secrets Operator)

### Known Security Issues (Demo Only!)
- ❌ Grafana default password: `admin`
- ❌ No HTTPS for ArgoCD (using port-forward)
- ❌ Self-signed certificates (browser warnings)
- ❌ No secret scanning in CI/CD

---

## Troubleshooting Guide

### ArgoCD App Stuck in "Unknown" State
**Cause:** Repository URL incorrect or not accessible
**Fix:**
```bash
# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server

# Verify repository URL in app
kubectl get application <app-name> -n argocd -o yaml | grep repoURL

# Update if needed
kubectl edit application <app-name> -n argocd
```

### Ingress Returns 404
**Cause:** /etc/hosts not configured OR ingress controller not ready
**Fix:**
```bash
# Check /etc/hosts
cat /etc/hosts | grep local

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress resource
kubectl get ingress -A
kubectl describe ingress <name> -n <namespace>
```

### Cert-Manager Not Issuing Certificates
**Cause:** ClusterIssuer not ready OR certificate request failed
**Fix:**
```bash
# Check ClusterIssuers
kubectl get clusterissuers
kubectl describe clusterissuer selfsigned-ca-issuer

# Check certificates
kubectl get certificates -A
kubectl describe certificate <name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### Prometheus Not Scraping Metrics
**Cause:** ServiceMonitor not created OR labels don't match
**Fix:**
```bash
# Check ServiceMonitors
kubectl get servicemonitors -A

# Check Prometheus targets in Grafana
# Or port-forward Prometheus:
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

---

## Testing Strategy

### Unit Testing (Not Implemented)
- YAML validation (kubeval, kubeconform)
- Helm template rendering
- Kustomize build

### Integration Testing (Manual)
1. ✅ Cluster creation
2. ✅ Component installation
3. ✅ Service accessibility
4. ✅ Metrics collection
5. ✅ GitOps sync

### E2E Testing (Future)
- Automated deployment test
- Service mesh test
- Progressive delivery test
- Disaster recovery test

---

## Performance Considerations

### Current Setup
- **Cluster:** Local Kind (Docker resources limited)
- **Storage:** Local volumes (no persistence guarantee)
- **Network:** Docker network (bridge)
- **Registry:** Local registry (fast image pulls)

### Limitations
- Not suitable for production workloads
- No HA for any component
- No distributed storage
- Limited to laptop resources

### Optimizations Applied
- Minimal resource requests
- Disabled kubeEtcd/kubeScheduler monitoring (not available in Kind)
- Local registry to avoid external image pulls
- Prometheus retention limited to 7 days

---

## Extending the Platform

### Adding New Platform Service

1. Create ArgoCD Application:
```yaml
# platform/observability/new-service/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: new-service
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://charts.example.com
    chart: new-service
    targetRevision: 1.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

2. Update app-of-apps to include new directory:
```yaml
# platform/app-of-apps.yaml
spec:
  source:
    path: platform/observability  # Will include new-service/
```

3. Commit and push:
```bash
git add platform/observability/new-service/
git commit -m "Add new-service"
git push
```

4. ArgoCD syncs automatically!

### Adding New Application

1. Create app structure:
```bash
mkdir -p applications/my-app/{base,overlays/dev}
# Add kustomization.yaml, deployment.yaml, etc.
```

2. Create ArgoCD Application:
```yaml
# applications/my-app/application.yaml
```

3. Update applications/app-of-apps.yaml if needed

4. Commit and push

---

## Week 2 Preview

### What's Coming
- **Loki Stack:** Log aggregation with Promtail
- **Tempo:** Distributed tracing backend
- **OpenTelemetry Collector:** Unified telemetry collection
- **Go Demo App:** Replace nginx with instrumented Go application
  - Prometheus metrics (http_requests_total, http_request_duration)
  - Structured logging with zap (JSON format)
  - OpenTelemetry tracing (OTLP export)
  - Trace ID in logs for correlation
- **Unified Grafana Dashboards:** Metrics + Logs + Traces

### Architecture Change
```
Current:  App → Prometheus (metrics only)

Week 2:   App → OpenTelemetry Collector → {
            Prometheus (metrics)
            Loki (logs)
            Tempo (traces)
          } → Grafana (unified view)
```

---

## Useful Links

### Documentation
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Kustomize Docs](https://kustomize.io/)
- [Kind Docs](https://kind.sigs.k8s.io/)
- [Prometheus Operator](https://prometheus-operator.dev/)

### Tools
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Docs](https://helm.sh/docs/)

### Best Practices
- [GitOps Principles](https://opengitops.dev/)
- [12 Factor App](https://12factor.net/)
- [Cloud Native Trail Map](https://github.com/cncf/trailmap)

---

## Lessons Learned (To Document After Testing)

- [ ] What worked well?
- [ ] What was challenging?
- [ ] What would you do differently?
- [ ] Performance observations
- [ ] Time to bootstrap
- [ ] Resource usage

---

**Last Updated:** 2025-12-21
**Next Review:** After Week 1 testing
