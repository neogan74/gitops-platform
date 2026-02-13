# Grafana Dashboards

This directory contains custom Grafana dashboards deployed as Kubernetes ConfigMaps, automatically provisioned into Grafana via the sidecar.

## Overview

Custom dashboards complement the community dashboards loaded from Grafana.com. They are stored as ConfigMaps with the label `grafana_dashboard: "1"`, which the Grafana sidecar detects and imports automatically.

## Dashboards

### Argo Rollouts Dashboard

**File:** `rollouts-dashboard-cm.yaml`

Visualizes progressive delivery deployments:
- Active vs preview replica counts
- Rollout phase and status
- Canary weight progression
- Step completion timeline

## How Dashboard Provisioning Works

```
┌──────────────────────────────────────────┐
│  Git Repository                          │
│  platform/observability/dashboards/      │
│  └── rollouts-dashboard-cm.yaml          │
└───────────────┬──────────────────────────┘
                │ ArgoCD sync
                ▼
┌──────────────────────────────────────────┐
│  Kubernetes ConfigMap                    │
│  labels:                                 │
│    grafana_dashboard: "1"               │
└───────────────┬──────────────────────────┘
                │ Sidecar detects label
                ▼
┌──────────────────────────────────────────┐
│  Grafana Sidecar                        │
│  → Imports JSON into Grafana            │
│  → Dashboard available in UI            │
└──────────────────────────────────────────┘
```

## Adding New Dashboards

### 1. Design in Grafana UI

Create your dashboard interactively in Grafana, then export:
- Click **Dashboard Settings** → **JSON Model**
- Copy the JSON

### 2. Create ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-new-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  my-dashboard.json: |
    {
      "title": "My Dashboard",
      "panels": [...]
    }
```

### 3. Add to This Directory

Save the ConfigMap YAML in this directory. ArgoCD will automatically sync it and Grafana will pick it up.

## Available Dashboard Sources

| Source | Type | Dashboards |
|--------|------|------------|
| This directory | Custom ConfigMaps | Argo Rollouts |
| kube-prometheus-stack | Grafana.com imports | Kubernetes Cluster (7249), Node Exporter (1860), Pod Monitoring (6417) |
| kube-prometheus-stack | Built-in | CoreDNS, etcd, API Server, etc. |

## References

- [Grafana Dashboard JSON Model](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/view-dashboard-json-model/)
- [Grafana Sidecar](https://github.com/kiwigrid/k8s-sidecar)
