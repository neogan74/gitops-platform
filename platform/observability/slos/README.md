# SLOs — Service Level Objectives

This directory contains the SLO/SLI implementation for the demo application, using Prometheus recording rules and alerting rules based on the Google SRE error budget burn rate methodology.

## Overview

SLOs define the reliability targets for the demo application:

| SLO | Target | Window | Error Budget |
|-----|--------|--------|--------------|
| **Availability** | 99.9% | 28 days | 0.1% (≈40 min/month downtime) |
| **Latency** | 99% of requests < 500ms | 28 days | 1% |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Demo App (demo-app-go)                  │
│                                                         │
│  Exposes: http_request_duration_seconds (histogram)     │
│  Labels: method, path, status                           │
└────────────────────────┬────────────────────────────────┘
                         │ Prometheus scrape
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Prometheus                            │
│                                                         │
│  Recording Rules (SLIs):                                │
│  ├── job:http_requests_total:rate1m                     │
│  ├── job:http_requests_error:rate1m                     │
│  ├── job:http_requests_success:ratio_rate1m             │
│  ├── job:http_request_duration_seconds_bucket:rate1m_*  │
│  └── job:http_request_latency_success:ratio_rate1m      │
│                                                         │
│  Alert Rules (Error Budget Burn):                       │
│  ├── HighErrorBudgetBurn (critical, 14.4x burn)        │
│  └── HighLatencyBudgetBurn (warning, 14.4x burn)       │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
           ┌───────────────┐
           │   Grafana     │
           │  SLO Dashboard│
           └───────────────┘
```

## SLI Definitions

### Availability SLI

Measures the ratio of successful (non-5xx) requests:

```
Availability = 1 - (error_requests / total_requests)
```

**Recording rules:**
1. `job:http_requests_total:rate1m` — Total request rate
2. `job:http_requests_error:rate1m` — 5xx error request rate
3. `job:http_requests_success:ratio_rate1m` — Success ratio (the SLI)

### Latency SLI

Measures the proportion of requests served within 500ms:

```
Latency SLI = requests_under_500ms / total_requests
```

**Recording rules:**
1. `job:http_request_duration_seconds_bucket:rate1m_le0_5` — Requests ≤ 500ms
2. `job:http_request_duration_seconds_bucket:rate1m_total` — Total requests
3. `job:http_request_latency_success:ratio_rate1m` — Latency success ratio (the SLI)

## Error Budget Burn Rate Alerts

Based on Google SRE's multi-window, multi-burn-rate approach:

### HighErrorBudgetBurn (Critical — Page)

| Metric | Value |
|--------|-------|
| Burn rate | 14.4x |
| Time to exhaust budget | 2 days |
| Threshold | Error rate > 1.44% |
| Wait time | 2 minutes |
| Action | **Page on-call** |

### HighLatencyBudgetBurn (Warning — Ticket)

| Metric | Value |
|--------|-------|
| Burn rate | 14.4x |
| Time to exhaust budget | 2 days |
| Threshold | > 14.4% slow requests |
| Wait time | 2 minutes |
| Action | **Create ticket** |

## Usage

### Check SLI Values

```promql
# Current availability SLI
job:http_requests_success:ratio_rate1m

# Current latency SLI
job:http_request_latency_success:ratio_rate1m

# Error budget remaining (availability)
1 - ((1 - job:http_requests_success:ratio_rate1m) / 0.001)

# Error budget remaining (latency)
1 - ((1 - job:http_request_latency_success:ratio_rate1m) / 0.01)
```

### Verify Rules Are Loaded

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Check rules
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name | contains("slo"))'
```

### Generate Load for Testing

```bash
# Generate normal traffic
kubectl run -it --rm loadtest --image=busybox --restart=Never -- \
  sh -c 'while true; do wget -q -O- http://demo-app-go.default.svc:8080/health; sleep 0.1; done'

# Generate error traffic (to test alerts)
kubectl run -it --rm errortest --image=busybox --restart=Never -- \
  sh -c 'while true; do wget -q -O- http://demo-app-go.default.svc:8080/nonexistent; sleep 0.1; done'
```

## Files

| File | Purpose |
|------|---------|
| `prometheus-rule.yaml` | PrometheusRule with SLI recording rules and burn rate alerts |
| `dashboard-cm.yaml` | Grafana ConfigMap dashboard for SLO visualization |
| `application.yaml` | ArgoCD Application for deploying SLO resources |

## References

- [Google SRE Book — SLOs](https://sre.google/sre-book/service-level-objectives/)
- [Google SRE Workbook — Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- [Prometheus Recording Rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Error Budget Policy](https://sre.google/workbook/error-budget-policy/)
