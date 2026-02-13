# Loki — Log Aggregation

Loki provides centralized log collection and querying for all Kubernetes workloads, completing the logs pillar of the observability stack.

## Overview

Loki is a horizontally-scalable, highly-available log aggregation system inspired by Prometheus. Unlike traditional log systems, Loki indexes only **labels** (not full text), making it lightweight and cost-effective.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Kubernetes Nodes                      │
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ App Pod │  │ App Pod │  │ System  │                │
│  │ stdout  │  │ stdout  │  │ Pod     │                │
│  └────┬────┘  └────┬────┘  └────┬────┘                │
│       │            │            │                      │
│       └────────────┴────────────┘                      │
│                    │                                    │
│                    ▼                                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Promtail (DaemonSet)                     │  │
│  │  • Reads container logs from /var/log/pods        │  │
│  │  • Adds labels: namespace, pod, container         │  │
│  │  • Drops kube-system logs (noise reduction)       │  │
│  └──────────────────────┬───────────────────────────┘  │
└─────────────────────────┼──────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│                  Loki (Single Binary)                 │
│                                                       │
│  • Chunk storage: filesystem                          │
│  • Replication factor: 1 (demo)                       │
│  • Retention: enabled with compactor                  │
│  • Auth: disabled (internal use)                      │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │    Grafana     │
              │ (Explore/Logs) │
              └────────────────┘
```

## Configuration

### Datasource

Loki is pre-configured as a Grafana datasource:
```yaml
name: Loki
type: loki
url: http://loki-gateway.monitoring.svc.cluster.local
```

### Storage

| Setting | Value |
|---------|-------|
| Storage type | Filesystem |
| Chunks directory | `/var/loki/chunks` |
| Rules directory | `/var/loki/rules` |
| Compaction interval | 10 minutes |
| Retention | Enabled (2h delete delay) |

## Usage

### Query Logs in Grafana

Navigate to **Explore** → Select **Loki** datasource.

#### LogQL Examples

```logql
# All logs from a specific namespace
{namespace="production"}

# Logs from a specific pod
{pod="demo-app-go-abc123"}

# Filter by content
{namespace="default"} |= "error"

# JSON parsing
{namespace="default"} | json | level = "error"

# Rate of log lines
rate({namespace="production"}[5m])

# Top 5 log-producing pods
topk(5, sum by (pod) (rate({namespace="production"}[5m])))
```

### Correlation with Prometheus

In Grafana dashboards, you can link from metrics panels to log queries:
```logql
{namespace="$namespace", pod=~"$pod"}
```

### CLI Querying

```bash
# Port-forward Loki gateway
kubectl port-forward -n monitoring svc/loki-gateway 3100:80

# Query via API
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={namespace="default"}' \
  --data-urlencode 'limit=10' | jq .
```

## Troubleshooting

### No Logs Appearing

```bash
# Check Promtail pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail

# Check Promtail targets
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=20

# Verify Loki is receiving data
kubectl port-forward -n monitoring svc/loki-gateway 3100:80
curl http://localhost:3100/loki/api/v1/labels
```

### Loki Out of Memory

```bash
# Check resource usage
kubectl top pods -n monitoring -l app.kubernetes.io/name=loki

# Reduce ingestion rate or increase limits
# Consider increasing memory limits in application config
```

## References

- [Loki Documentation](https://grafana.com/docs/loki/)
- [LogQL Reference](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)
