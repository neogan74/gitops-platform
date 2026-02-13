# Argo Rollouts — Progressive Delivery

Argo Rollouts provides advanced deployment strategies (canary and blue-green) with automated analysis and rollback capabilities.

## Overview

Argo Rollouts replaces standard Kubernetes Deployments with `Rollout` resources that support progressive delivery — gradually shifting traffic to new versions while monitoring health metrics.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Progressive Delivery                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Rollout Resource                   │   │
│  │                                                      │   │
│  │  Strategy: Canary                                    │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  Step 1: setWeight: 20%                      │   │   │
│  │  │  Step 2: pause (analysis)                    │   │   │
│  │  │  Step 3: setWeight: 40%                      │   │   │
│  │  │  Step 4: pause (analysis)                    │   │   │
│  │  │  Step 5: setWeight: 80%                      │   │   │
│  │  │  Step 6: promote → 100%                      │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Traffic Split:                                             │
│                                                             │
│  ┌───────────────┐         ┌───────────────┐               │
│  │ Stable (v1)   │  80%    │ Canary (v2)   │  20%          │
│  │               │◄────────│               │◄──────        │
│  │ ReplicaSet    │         │ ReplicaSet    │               │
│  └───────────────┘         └───────────────┘               │
│                                                             │
│  Analysis:                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AnalysisTemplate                                    │   │
│  │  • Query Prometheus metrics                          │   │
│  │  • Check success rate > 95%                         │   │
│  │  • Check p95 latency < 500ms                        │   │
│  │  • Auto-rollback if analysis fails                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Strategies

### Canary (Staging)

Gradually shifts traffic percentages while running analysis:

```yaml
strategy:
  canary:
    steps:
    - setWeight: 20
    - pause: {duration: 30s}
    - analysis:
        templates:
        - templateName: success-rate
    - setWeight: 40
    - pause: {duration: 30s}
    - setWeight: 80
    - pause: {duration: 30s}
```

### Blue-Green (Production)

Deploys the new version alongside the old, then switches traffic atomically:

```yaml
strategy:
  blueGreen:
    activeService: prod-active
    previewService: prod-preview
    autoPromotionEnabled: true
    prePromotionAnalysis:
      templates:
      - templateName: success-rate
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `argo/argo-rollouts` |
| Namespace | `argo-rollouts` |

### ArgoCD Integration

ArgoCD has custom resource health checks for Rollouts configured in `argocd-cm.yaml`:
- Recognizes `Progressing`, `Degraded`, and `Healthy` phases
- Displays accurate sync status for Rollout resources

## Usage

### Monitor Rollouts

```bash
# Install kubectl plugin
brew install argoproj/tap/kubectl-argo-rollouts

# Watch rollout progress
kubectl argo rollouts get rollout demo-app-go -n production -w

# List all rollouts
kubectl argo rollouts list rollouts -A

# View rollout dashboard
kubectl argo rollouts dashboard
# Access: http://localhost:3100
```

### Manual Operations

```bash
# Promote a paused rollout
kubectl argo rollouts promote demo-app-go -n staging

# Abort a rollout (rollback)
kubectl argo rollouts abort demo-app-go -n staging

# Retry a failed rollout
kubectl argo rollouts retry rollout demo-app-go -n staging

# Restart (re-deploy current version)
kubectl argo rollouts restart demo-app-go -n staging
```

### Trigger a Deployment

```bash
# Update image (triggers rollout)
kubectl argo rollouts set image demo-app-go demo-app-go=localhost:5001/demo-app-go:v2 -n staging

# Or update via Git (GitOps way)
# Edit applications/demo-app-go/staging/rollout.yaml → commit → push
```

## Grafana Dashboard

A custom Argo Rollouts dashboard is provisioned via `platform/observability/dashboards/rollouts-dashboard-cm.yaml`, showing:
- Active vs canary replica counts
- Rollout phase progression
- Analysis run results

## Troubleshooting

### Rollout Stuck in "Progressing"

```bash
# Check rollout status
kubectl argo rollouts get rollout <name> -n <namespace>

# Check analysis runs
kubectl get analysisruns -n <namespace>
kubectl describe analysisrun <name> -n <namespace>

# Check if Prometheus is returning data for analysis queries
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Query the analysis metric in Prometheus UI
```

### Analysis Always Failing

```bash
# Check the AnalysisTemplate metrics
kubectl get analysistemplate <name> -n <namespace> -o yaml

# Ensure the metric query returns data
# Common issue: no traffic → division by zero → analysis fails
```

## References

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Canary Strategy](https://argoproj.github.io/argo-rollouts/features/canary/)
- [Blue-Green Strategy](https://argoproj.github.io/argo-rollouts/features/bluegreen/)
- [Analysis & Progressive Delivery](https://argoproj.github.io/argo-rollouts/features/analysis/)
