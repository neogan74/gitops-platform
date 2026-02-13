# Istio Service Mesh — Ambient Mode

Istio provides service mesh capabilities using the **Ambient mode** (sidecar-less), adding mTLS encryption, traffic management, and observability to all workloads.

## Overview

Unlike traditional Istio with sidecar proxies, this platform uses **Ambient mode** which operates through:
- **ztunnel** — A per-node proxy (DaemonSet) that handles L4 mTLS encryption
- **Waypoint proxies** — Optional L7 proxies for advanced traffic management (deployed on-demand)

This approach eliminates sidecar injection complexity while still providing transparent mTLS.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                        │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              istio-system namespace                    │  │
│  │                                                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │  │
│  │  │ istio-   │  │  istiod  │  │  ztunnel         │   │  │
│  │  │ base     │  │ (control │  │  (DaemonSet)     │   │  │
│  │  │ (CRDs)   │  │  plane)  │  │  L4 mTLS proxy   │   │  │
│  │  └──────────┘  └──────────┘  └──────────────────┘   │  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────────────────┐    │  │
│  │  │  istio-cni (DaemonSet)                       │    │  │
│  │  │  Network redirection without init containers  │    │  │
│  │  └──────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  Traffic flow (Ambient mode):                               │
│                                                             │
│  Pod A ──── ztunnel (mTLS) ──── ztunnel ──── Pod B         │
│       (plaintext)    (encrypted)    (plaintext)             │
└─────────────────────────────────────────────────────────────┘
```

## Components

This Istio installation is split into 4 ArgoCD Applications:

| Application | Chart | Version | Purpose |
|-------------|-------|---------|---------|
| `istio-base` | `base` | — | CRDs and cluster-wide resources |
| `istiod` | `istiod` | 1.24.1 | Control plane (Pilot) |
| `istio-cni` | `cni` | 1.24.1 | CNI plugin for traffic redirection |
| `ztunnel` | `ztunnel` | 1.24.1 | Per-node L4 proxy for mTLS |

## Configuration

### Istiod (Control Plane)

| Setting | Value | Purpose |
|---------|-------|---------|
| `PILOT_ENABLE_AMBIENT` | `true` | Enable ambient mesh mode |
| Access logging | `/dev/stdout` | Log all mesh traffic |
| Prometheus merge | `true` | Expose Istio metrics to Prometheus |
| Tracing sampling | 100% | Full trace sampling (demo only) |
| Proxy access log | JSON format | Structured logging |

### Resource Allocation

| Component | CPU Request/Limit | Memory Request/Limit |
|-----------|-------------------|----------------------|
| Istiod | 200m / 1000m | 512Mi / 1Gi |
| Proxy (ztunnel) | 100m / 500m | 128Mi / 512Mi |

## Usage

### Enable Ambient Mesh for a Namespace

```bash
# Add the ambient label to enable mesh
kubectl label namespace default istio.io/dataplane-mode=ambient

# Verify mesh enrollment
kubectl get namespace default --show-labels | grep istio
```

### Verify mTLS

```bash
# Check if ztunnel is intercepting traffic
kubectl logs -n istio-system -l app=ztunnel --tail=20

# Test mTLS between pods
kubectl exec <pod-a> -- curl -v http://<pod-b-service>:8080/health
# Look for ztunnel logs showing encrypted tunnel
```

### View Mesh Status

```bash
# Check all Istio components
kubectl get pods -n istio-system

# Check mesh configuration
kubectl get cm istio -n istio-system -o yaml

# View ztunnel workload status
kubectl get daemonset -n istio-system ztunnel
```

## Prometheus Metrics

Istio exports metrics to Prometheus:

```promql
# Request rate through the mesh
sum(rate(istio_requests_total[5m])) by (destination_service_name)

# Request latency (p99)
histogram_quantile(0.99, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (le, destination_service_name))

# mTLS connection count
sum(envoy_cluster_upstream_cx_total) by (cluster_name)
```

## Troubleshooting

### Pods Not Enrolled in Mesh

```bash
# Verify namespace label
kubectl get ns <namespace> -o jsonpath='{.metadata.labels}'

# Check ztunnel logs
kubectl logs -n istio-system -l app=ztunnel | grep <pod-name>
```

### ztunnel CrashLooping

```bash
# Check DaemonSet status
kubectl get ds ztunnel -n istio-system

# Check logs
kubectl logs -n istio-system -l app=ztunnel --previous

# Verify CNI plugin is installed
kubectl get pods -n istio-system -l k8s-app=istio-cni-node
```

### Traffic Not Flowing

```bash
# Check network policies allow Istio traffic
kubectl get networkpolicy -n <namespace> | grep istio

# Verify the allow-istio network policy exists
kubectl describe networkpolicy allow-istio-traffic -n <namespace>
```

## References

- [Istio Ambient Mode](https://istio.io/latest/docs/ambient/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [ztunnel Architecture](https://istio.io/latest/docs/ambient/architecture/)
- [Istio + Kind Setup](https://istio.io/latest/docs/setup/platform-setup/kind/)
