# Kind Cluster — Local Kubernetes

Kind (Kubernetes in Docker) provides the local Kubernetes cluster that runs the entire gitops-platform.

## Overview

The cluster is configured as a **single control-plane node** with ingress support, designed for local development and demonstration of production-grade practices.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Host (macOS)                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Kind Cluster: gitops-platform             │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │          control-plane node                  │  │  │
│  │  │                                             │  │  │
│  │  │  • Kubernetes v1.27.3                       │  │  │
│  │  │  • Ingress-ready label                      │  │  │
│  │  │  • Port 80 → Host 80                        │  │  │
│  │  │  • Port 443 → Host 443                      │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │         kind-registry (localhost:5001)             │  │
│  │         └─ Docker Registry for demo images        │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Configuration

### `cluster-config.yaml`

| Setting | Value | Purpose |
|---------|-------|---------|
| Kubernetes version | v1.27.3 | Pinned for reproducibility |
| Nodes | 1 control-plane | Sufficient for demo purposes |
| Host port 80 | → container 80 | HTTP ingress |
| Host port 443 | → container 443 | HTTPS ingress |
| Node label | `ingress-ready=true` | Required for ingress controller scheduling |
| Container registry | `localhost:5001` → `kind-registry:5000` | Local image building and pushing |

### Local Registry

A local Docker registry runs alongside the cluster, enabling fast image builds without pushing to remote registries:

```bash
# Push images to local registry
docker build -t localhost:5001/my-app:v1 .
docker push localhost:5001/my-app:v1

# Use in Kubernetes manifests
image: localhost:5001/my-app:v1
```

## Usage

```bash
# Create cluster with local registry
make create-cluster

# Verify cluster is running
kubectl cluster-info --context kind-gitops-platform
kubectl get nodes

# Delete cluster and registry
make delete-cluster
```

## Prerequisites

- **Docker Desktop** (or Docker Engine) running
- **Kind** (`brew install kind`)
- **kubectl** (`brew install kubectl`)

## Troubleshooting

### Cluster Won't Start

```bash
# Check Docker is running
docker info

# Check for port conflicts (80, 443)
lsof -i :80
lsof -i :443

# Delete and recreate
make delete-cluster
make create-cluster
```

### Registry Not Accessible

```bash
# Verify registry container is running
docker ps | grep kind-registry

# Test registry connectivity
curl -s http://localhost:5001/v2/_catalog

# Restart registry
docker restart kind-registry
```

### Node Not Ready

```bash
# Check node status
kubectl get nodes -o wide
kubectl describe node gitops-platform-control-plane

# Check system pods
kubectl get pods -n kube-system
```

## References

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kind Ingress Guide](https://kind.sigs.k8s.io/docs/user/ingress/)
- [Kind Local Registry](https://kind.sigs.k8s.io/docs/user/local-registry/)
