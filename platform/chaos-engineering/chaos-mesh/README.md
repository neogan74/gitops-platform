# Chaos Mesh — Chaos Engineering

Chaos Mesh provides fault injection capabilities to test the resilience and recoverability of the platform under failure conditions.

## Overview

Chaos Mesh is a cloud-native chaos engineering platform that orchestrates controlled experiments — introducing faults like pod kills, network delays, and I/O stress — to verify that the system handles failures gracefully.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   chaos-mesh namespace                       │
│                                                             │
│  ┌──────────────────────┐   ┌──────────────────────────┐   │
│  │ chaos-controller-    │   │ chaos-daemon             │   │
│  │ manager              │   │ (DaemonSet)              │   │
│  │                      │   │                          │   │
│  │ • Watches experiment │   │ • Injects faults at      │   │
│  │   CRDs               │   │   node level             │   │
│  │ • Schedules chaos    │   │ • Uses containerd socket │   │
│  │   actions             │   │ • Manages tc/iptables    │   │
│  └──────────┬───────────┘   └──────────────────────────┘   │
│             │                                               │
│             │ creates                                       │
│             ▼                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Chaos Experiments                        │  │
│  │                                                      │  │
│  │  ┌──────────────┐  ┌──────────────────────────────┐  │  │
│  │  │ PodChaos:    │  │ NetworkChaos:                │  │  │
│  │  │ pod-kill     │  │ network-delay                │  │  │
│  │  │              │  │                              │  │  │
│  │  │ • Target:    │  │ • Target: demo-app-go        │  │  │
│  │  │   production │  │   (production)               │  │  │
│  │  │ • Mode: one  │  │ • Latency: 100ms ± 20ms     │  │  │
│  │  │ • Cron: @1m  │  │ • Correlation: 50%           │  │  │
│  │  └──────────────┘  │ • Duration: 30s              │  │  │
│  │                     └──────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `chaos-mesh/chaos-mesh` |
| Version | `2.6.2` |
| Namespace | `chaos-mesh` |
| Container runtime | `containerd` |
| Socket path | `/run/containerd/containerd.sock` |
| Dashboard | Enabled |

## Experiments

### 1. Pod Kill (`experiments/pod-kill.yaml`)

Randomly kills one pod matching the selector to test auto-recovery:

| Setting | Value |
|---------|-------|
| Type | `PodChaos` |
| Action | `pod-kill` |
| Mode | `one` (single pod) |
| Target | `app: demo-app-go` in `production` |
| Schedule | Every 1 minute |
| Duration | 10 seconds |

**What it validates:**
- ReplicaSet recreates killed pods
- Service remains available during pod replacement
- No dropped requests (with multiple replicas)

### 2. Network Delay (`experiments/network-delay.yaml`)

Injects network latency to test timeout handling and circuit breaking:

| Setting | Value |
|---------|-------|
| Type | `NetworkChaos` |
| Action | `delay` |
| Mode | `all` (all matching pods) |
| Target | `app: demo-app-go` in `production` |
| Latency | 100ms ± 20ms jitter |
| Correlation | 50% |
| Duration | 30 seconds |

**What it validates:**
- Application handles increased latency gracefully
- Timeouts are configured appropriately
- SLO burn rate alerts fire correctly

## Usage

### Run an Experiment

```bash
# Apply a pod kill experiment (one-time)
kubectl apply -f platform/chaos-engineering/chaos-mesh/experiments/pod-kill.yaml

# Apply network delay experiment
kubectl apply -f platform/chaos-engineering/chaos-mesh/experiments/network-delay.yaml

# Watch the experiment status
kubectl get podchaos,networkchaos -n chaos-mesh

# Delete experiment (stop chaos)
kubectl delete podchaos pod-kill-demo -n chaos-mesh
```

### Access Chaos Dashboard

```bash
# Port-forward the dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333

# Access: http://localhost:2333
```

### Create Custom Experiments

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: cpu-stress-demo
  namespace: chaos-mesh
spec:
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      app: demo-app-go
  stressors:
    cpu:
      workers: 2
      load: 80
  duration: "60s"
```

## Available Chaos Types

| Type | Description | Use Case |
|------|-------------|----------|
| `PodChaos` | Kill, failure, container kill | Test recovery and resilience |
| `NetworkChaos` | Delay, loss, duplication, corruption | Test timeout and retry handling |
| `StressChaos` | CPU, memory stress | Test HPA scaling and resource limits |
| `IOChaos` | Latency, fault, attribute override | Test storage resilience |
| `DNSChaos` | DNS error, random responses | Test DNS fail-over |
| `HTTPChaos` | Abort, delay HTTP requests | Test application error handling |

## Observing Chaos Impact

During experiments, observe the impact in:

1. **Grafana dashboards** — Watch error rate, latency, and pod restart metrics
2. **SLO burn rate alerts** — Verify alerts fire when SLOs are breached
3. **Argo Rollouts** — Confirm canary analysis catches degradation
4. **kubectl** — Watch pod restarts and events

```bash
# Watch pods during chaos
kubectl get pods -n production -w

# Watch events
kubectl get events -n production --sort-by='.lastTimestamp' --watch
```

## Troubleshooting

### Experiment Not Taking Effect

```bash
# Check chaos-daemon is running on target nodes
kubectl get daemonset -n chaos-mesh

# Check chaos-daemon logs
kubectl logs -n chaos-mesh -l app.kubernetes.io/component=chaos-daemon --tail=20

# Verify selector matches target pods
kubectl get pods -n production -l app=demo-app-go
```

### Dashboard Not Loading

```bash
# Check dashboard pod
kubectl get pods -n chaos-mesh -l app.kubernetes.io/component=chaos-dashboard

# Port-forward directly
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
```

## References

- [Chaos Mesh Documentation](https://chaos-mesh.org/docs/)
- [Chaos Mesh Experiments](https://chaos-mesh.org/docs/simulate-pod-chaos-on-kubernetes/)
- [Principled Chaos Engineering](https://principlesofchaos.org/)
