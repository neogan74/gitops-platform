# Kube-Prometheus-Stack — Metrics, Alerting & Dashboards

The kube-prometheus-stack is the foundation of the platform's observability, providing Prometheus for metrics collection, Grafana for visualization, and Alertmanager for alerting.

## Overview

This is a **batteries-included** monitoring stack deployed as a single Helm chart that includes:
- **Prometheus** — Time-series metrics collection and storage
- **Grafana** — Dashboards and visualization
- **Alertmanager** — Alert routing and deduplication
- **Node Exporter** — Host-level metrics
- **kube-state-metrics** — Kubernetes object metrics

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                            │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ App Pods │  │ kubelet  │  │ Node     │  │ kube-state   │   │
│  │ /metrics │  │ /metrics │  │ Exporter │  │ -metrics     │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │             │               │           │
│       └──────────────┴─────────────┴───────────────┘           │
│                              │                                  │
│                         Scrape targets                          │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   Prometheus                               │  │
│  │  • Retention: 7 days                                      │  │
│  │  • Storage: 10Gi PVC                                      │  │
│  │  • Custom scrape: demo-app pods                           │  │
│  └───────────────────┬───────────────┬───────────────────────┘  │
│                      │               │                          │
│              query   │               │  fire alerts             │
│                      ▼               ▼                          │
│  ┌───────────────────────┐  ┌────────────────────────────┐     │
│  │      Grafana          │  │     Alertmanager           │     │
│  │  • grafana.local      │  │  • Group by alertname      │     │
│  │  • Pre-loaded         │  │  • 12h repeat interval     │     │
│  │    dashboards         │  │  • Receiver: null (demo)   │     │
│  │  • Datasources:       │  └────────────────────────────┘     │
│  │    Prometheus, Loki,  │                                      │
│  │    Tempo              │                                      │
│  └───────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `prometheus-community/kube-prometheus-stack` |
| Version | `55.5.0` |
| Namespace | `monitoring` |

### Prometheus

| Setting | Value | Purpose |
|---------|-------|---------|
| Retention | 7 days | How long metrics are kept |
| Storage | 10Gi PVC | Persistent volume for TSDB |
| CPU request/limit | 200m / 1000m | Resource allocation |
| Memory request/limit | 512Mi / 2Gi | Resource allocation |
| `demo-app` scrape | kubernetes_sd pod discovery | Custom scrape for demo app metrics |

### Grafana

| Setting | Value |
|---------|-------|
| Admin password | `admin` (change in production!) |
| Persistence | 5Gi PVC |
| Ingress | `grafana.local` via nginx |
| TLS | Self-signed via cert-manager |

### Pre-configured Datasources

| Datasource | URL | Purpose |
|------------|-----|---------|
| Prometheus | (default) | Metrics queries |
| Loki | `http://loki-gateway.monitoring.svc.cluster.local` | Log queries |
| Tempo | `http://tempo.monitoring.svc.cluster.local:3100` | Trace queries |

### Pre-loaded Dashboards

| Dashboard | Grafana.com ID | Description |
|-----------|----------------|-------------|
| Kubernetes Cluster | 7249 | Cluster-wide resource overview |
| Node Exporter | 1860 | Host-level metrics |
| Pod Monitoring | 6417 | Per-pod resource usage |

### Alertmanager

Routes alerts grouped by `alertname`, `cluster`, and `namespace`. Currently uses a `null` receiver (no external notifications in demo mode).

### Disabled Components

These components are disabled because they're not available in Kind clusters:
- `kubeEtcd`
- `kubeScheduler`
- `kubeControllerManager`

## Usage

### Access Grafana

```bash
# Via ingress (add to /etc/hosts first)
# https://grafana.local

# Via port-forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Access: http://localhost:3000 (admin/admin)
```

### Query Prometheus

```bash
# Port-forward Prometheus UI
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090

# Example queries
# CPU usage by pod
sum by (pod) (rate(container_cpu_usage_seconds_total[5m]))

# Memory usage by namespace
sum by (namespace) (container_memory_working_set_bytes)

# Demo app request rate
rate(http_request_duration_seconds_count{job="demo-app-go"}[5m])
```

### Access Alertmanager

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Access: http://localhost:9093
```

## Troubleshooting

### No Metrics for Demo App

```bash
# Check if ServiceMonitor or scrape config matches
kubectl get servicemonitors -n monitoring

# Verify targets in Prometheus UI
# http://localhost:9090/targets

# Check if demo app exposes /metrics
kubectl exec -it <demo-pod> -- curl localhost:8080/metrics
```

### Grafana Dashboard Not Loading

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana --tail=50

# Verify datasource connectivity
kubectl exec -it deployment/kube-prometheus-stack-grafana -n monitoring -- curl prometheus:9090/api/v1/status/config
```

### High Memory Usage

```bash
# Check Prometheus TSDB stats
kubectl exec -it prometheus-kube-prometheus-stack-prometheus-0 -n monitoring -- promtool tsdb analyze /prometheus

# Check cardinality
# In Prometheus UI: topk(10, count by (__name__)({__name__=~".+"}))
```

## References

- [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
