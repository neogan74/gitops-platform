# ArgoCD — GitOps Deployment Controller

ArgoCD is the core GitOps engine that continuously syncs the desired state from this Git repository to the Kubernetes cluster.

## Overview

ArgoCD monitors this repository and automatically reconciles any drift between Git (desired state) and the cluster (actual state). It manages **all platform services and applications** through the App-of-Apps pattern.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Git Repository                           │
│                                                             │
│  platform/app-of-apps.yaml ─────────┐                      │
│  applications/app-of-apps.yaml ─────┤                      │
│                                     │                      │
└─────────────────────────────────────┼──────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    ArgoCD (argocd namespace)                 │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ argocd-server│  │ repo-server  │  │ app-controller   │  │
│  │ (UI + API)   │  │ (Git sync)   │  │ (Reconciliation) │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
│  Projects: platform, applications                           │
│  Reconciliation interval: 180s                              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│               Managed Applications                          │
│                                                             │
│  Platform Layer:                                            │
│  ├── kube-prometheus-stack  ├── falco                       │
│  ├── loki                   ├── trivy-operator              │
│  ├── tempo                  ├── kyverno + policies          │
│  ├── istio (base/istiod/    ├── external-secrets            │
│  │   cni/ztunnel)           ├── chaos-mesh + experiments    │
│  ├── argo-rollouts          ├── opencost                    │
│  ├── velero                 └── minio                       │
│  │                                                          │
│  Application Layer:                                         │
│  └── demo-app-go (dev/staging/production)                   │
└─────────────────────────────────────────────────────────────┘
```

## App-of-Apps Pattern

This platform uses a **two-level App-of-Apps** pattern:

1. **Root Applications** (`platform/app-of-apps.yaml` and `applications/app-of-apps.yaml`) — deployed manually via `make deploy-platform` / `make deploy-apps`
2. **Child Applications** — each root application points to a directory containing individual ArgoCD `Application` resources
3. **Leaf Applications** — install Helm charts or sync Kustomize manifests

```
make deploy-platform
  └── platform/app-of-apps.yaml
        ├── platform-observability → platform/observability/ → kube-prometheus-stack, loki, tempo, ...
        ├── platform-security-falco → platform/security/falco/ → Falco Helm chart
        ├── platform-security-kyverno → platform/security/kyverno/ → Kyverno + policies
        ├── platform-chaos-engineering → platform/chaos-engineering/chaos-mesh/ → Chaos Mesh
        └── ...
```

## Configuration

### Projects

| Project | Scope | Purpose |
|---------|-------|---------|
| `platform` | All platform services | Infrastructure components (monitoring, security, mesh, etc.) |
| `applications` | Demo workloads | User-facing demo applications |

### ArgoCD ConfigMap (`argocd-cm.yaml`)

| Setting | Value | Purpose |
|---------|-------|---------|
| Repository | `neogan74/gitops-platform.git` | Source of truth |
| Resource customizations | Argo Rollouts health check | Custom Lua health for Rollout resources |
| UI banner | "GitOps Platform Lab" | Visual environment indicator |
| Reconciliation timeout | 180s | How often ArgoCD checks for drift |

### Sync Policies

All applications use:
- **Automated sync** — changes in Git are automatically applied
- **Prune** — removed resources in Git are deleted from cluster
- **Self-heal** — manual changes in cluster are reverted to match Git

## Usage

### Installation

```bash
# Install ArgoCD (part of bootstrap)
make install-argocd

# Or full bootstrap (cluster + argocd + cert-manager + ingress)
make bootstrap
```

### Access the UI

```bash
# Get admin password
make argocd-password

# Port-forward to ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: https://localhost:8080
# User: admin
```

### Deploy Platform

```bash
# Deploy all platform services
make deploy-platform

# Deploy demo applications
make deploy-apps

# Check sync status
make status
```

### Common Operations

```bash
# Force sync all applications
make sync-all

# Check application logs
make logs-argocd

# View specific app status
kubectl get application <app-name> -n argocd -o yaml

# Manually sync an app
argocd app sync <app-name>
```

## Troubleshooting

### Application Stuck in "Progressing"

```bash
# Check app events
kubectl describe application <app-name> -n argocd

# Check sync status
kubectl get application <app-name> -n argocd -o jsonpath='{.status.sync.status}'

# Check for resource errors
kubectl get application <app-name> -n argocd -o jsonpath='{.status.conditions[*].message}'
```

### Sync Failed

```bash
# View detailed sync result
kubectl get application <app-name> -n argocd -o jsonpath='{.status.operationState.message}'

# Check repo-server logs (Git fetch issues)
kubectl logs -n argocd deployment/argocd-repo-server --tail=50

# Check app-controller logs (reconciliation issues)
kubectl logs -n argocd deployment/argocd-application-controller --tail=50
```

### Out of Sync — Expected

Some resources have expected drift (e.g., webhooks mutated by admission controllers). These are handled via `ignoreDifferences` in the Application spec.

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Declarative GitOps](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
