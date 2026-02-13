# Tempo — Distributed Tracing

Tempo provides distributed tracing storage and querying, completing the traces pillar of the observability stack.

## Overview

Grafana Tempo is a high-scale distributed tracing backend. It integrates natively with Grafana, enabling seamless correlation between **metrics → traces → logs**.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Application Pods                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  demo-app-go (instrumented with OpenTelemetry)      │   │
│  │  → Exports traces via OTLP (gRPC/HTTP)              │   │
│  └─────────────────────────┬───────────────────────────┘   │
└────────────────────────────┼───────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Tempo (monitoring namespace)              │
│                                                             │
│  • Backend: Filesystem                                      │
│  • Protocol: OTLP (gRPC + HTTP)                            │
│  • Query: Grafana Tempo datasource                         │
└─────────────────────────────┬───────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
           ┌──────────────┐    ┌──────────────┐
           │   Grafana    │    │  Prometheus  │
           │  (Explore)   │    │ (Exemplars)  │
           │              │    │              │
           │ Traces →     │    │ Metrics →    │
           │   Logs       │    │   Traces     │
           └──────────────┘    └──────────────┘
```

## Configuration

### Datasource

Tempo is pre-configured in Grafana with correlation links:

```yaml
name: Tempo
type: tempo
url: http://tempo.monitoring.svc.cluster.local:3100
jsonData:
  tracesToLogs:
    datasourceUid: loki         # Click trace → view logs
    tags: ['pod', 'namespace']
  tracesToMetrics:
    datasourceUid: prometheus   # Click trace → view metrics
```

## The Three Pillars Correlation

This platform achieves full observability correlation:

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│  Prometheus  │ ────▶ │    Tempo     │ ────▶ │    Loki      │
│  (Metrics)   │       │   (Traces)   │       │   (Logs)     │
│              │ ◀──── │              │ ◀──── │              │
│  Exemplars   │       │  Trace ID    │       │  Labels      │
└──────────────┘       └──────────────┘       └──────────────┘

Flow: Metric alert → Find trace exemplar → View full trace → Jump to logs
```

## Usage

### Viewing Traces in Grafana

1. Open **Grafana** → **Explore**
2. Select **Tempo** datasource
3. Search by **Trace ID** or use **Search** tab
4. Click on a trace to see the full flame graph / span waterfall

### Finding Traces from Metrics

In Grafana dashboards with exemplars enabled:
1. Hover over a data point with an exemplar marker
2. Click the exemplar to jump directly to the trace in Tempo

### Finding Traces from Logs

In Loki log results, if a log line contains a `traceID` field:
1. Click the trace ID link
2. This opens the trace in Tempo automatically

### TraceQL Examples

```
# Find traces by service name
{.service.name = "demo-app-go"}

# Find slow traces (>500ms)
{.service.name = "demo-app-go" && duration > 500ms}

# Find error traces
{.service.name = "demo-app-go" && status = error}
```

## Troubleshooting

### No Traces Appearing

```bash
# Check Tempo pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=tempo

# Check Tempo logs for ingestion
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo --tail=20

# Verify app is sending traces
kubectl logs <demo-app-pod> | grep -i "trace\|otel\|telemetry"
```

### Traces Not Linking to Logs

Ensure your application includes `traceID` in log output and both Loki and Tempo datasource UIDs match in the Grafana configuration.

## References

- [Grafana Tempo Documentation](https://grafana.com/docs/tempo/)
- [TraceQL](https://grafana.com/docs/tempo/latest/traceql/)
- [OpenTelemetry](https://opentelemetry.io/)
