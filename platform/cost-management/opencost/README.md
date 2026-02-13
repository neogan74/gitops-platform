# OpenCost — Cost Management & Visibility

OpenCost provides real-time cost monitoring and allocation for Kubernetes workloads, enabling cost-per-namespace, cost-per-label, and efficiency tracking.

## Overview

OpenCost is a CNCF Sandbox project that monitors resource allocation and calculates cost attribution. It uses Prometheus metrics to determine how much each workload costs in terms of CPU, memory, storage, and network.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   opencost namespace                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              OpenCost Exporter                       │   │
│  │                                                      │   │
│  │  • Reads resource allocation from Prometheus         │   │
│  │  • Calculates cost using pricing data                │   │
│  │  • Cluster ID: gitops-platform                       │   │
│  │  • Exports /metrics for Prometheus                   │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│              ┌──────────┴──────────┐                       │
│              ▼                     ▼                        │
│  ┌───────────────────┐  ┌──────────────────┐              │
│  │   Prometheus      │  │    Grafana       │              │
│  │   (scrape costs)  │  │  (dashboards)    │              │
│  └───────────────────┘  └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `opencost/opencost` |
| Version | `1.29.0` |
| Namespace | `opencost` |
| Cluster ID | `gitops-platform` |
| Prometheus URL | `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090` |
| ServiceMonitor | Enabled (label: `release: kube-prometheus-stack`) |

### Pricing

Since this is a local Kind cluster, OpenCost uses **default/estimated pricing** data. In production with cloud providers (AWS, GCP, Azure), OpenCost can pull real pricing from cloud APIs.

## Usage

### Access OpenCost UI

```bash
# Port-forward OpenCost API
kubectl port-forward -n opencost svc/opencost 9003:9003

# Access UI: http://localhost:9003
```

### Query Costs via API

```bash
# Get all namespace costs (last 24h)
curl -s "http://localhost:9003/allocation/compute?window=24h&aggregate=namespace" | jq .

# Get costs by label
curl -s "http://localhost:9003/allocation/compute?window=24h&aggregate=label:app" | jq .

# Get costs by controller
curl -s "http://localhost:9003/allocation/compute?window=7d&aggregate=controller" | jq .
```

### Prometheus Metrics

```promql
# Total cluster cost (monthly estimate)
sum(opencost_cluster_cost_daily) * 30

# Cost per namespace
sum by (namespace) (opencost_allocation_cost)

# Resource efficiency (actual usage / requested)
sum(container_cpu_usage_seconds_total) / sum(kube_pod_container_resource_requests{resource="cpu"})
```

### Grafana Dashboards

Import OpenCost dashboards from Grafana.com:
- **OpenCost Overview** — Cluster-wide cost breakdown
- **Namespace Cost Allocation** — Per-namespace costs
- **Pod Cost Efficiency** — Resource waste identification

## Cost Optimization Tips

| Check | Query / Command | Action |
|-------|----------------|--------|
| Over-provisioned pods | Check `requests` vs actual `usage` | Reduce resource requests |
| Idle namespaces | Zero CPU/memory usage | Delete or scale down |
| Unused PVCs | `kubectl get pvc -A` | Delete unused volumes |
| Right-sizing | OpenCost efficiency metrics | Adjust based on p95 usage |

## Troubleshooting

### No Cost Data

```bash
# Check OpenCost pod
kubectl get pods -n opencost
kubectl logs -n opencost -l app.kubernetes.io/name=opencost --tail=20

# Verify Prometheus connectivity
kubectl exec -n opencost deployment/opencost -- \
  curl -s "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/status/config" | head -5
```

### ServiceMonitor Not Detected

```bash
# Verify label matches Prometheus selector
kubectl get servicemonitor -n opencost -o yaml | grep -A2 labels
# Should have: release: kube-prometheus-stack
```

## References

- [OpenCost Documentation](https://www.opencost.io/docs/)
- [OpenCost API](https://www.opencost.io/docs/integrations/api)
- [CNCF OpenCost](https://www.cncf.io/projects/opencost/)
- [Kubernetes Finops](https://www.finops.org/)
