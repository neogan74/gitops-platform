# Nginx Ingress Controller

The Nginx Ingress Controller handles all external HTTP/HTTPS traffic routing into the Kubernetes cluster.

## Overview

Acting as the single entry point into the cluster, the ingress controller routes traffic based on hostname and path rules to the appropriate backend services.

## Architecture

```
┌──────────────────┐
│   Browser/curl   │
│                  │
│  grafana.local   │
│  demo-app.local  │
│  argocd.local    │
└────────┬─────────┘
         │ :80 / :443
         ▼
┌─────────────────────────────────────────────────┐
│          Nginx Ingress Controller                │
│          (ingress-nginx namespace)                │
│                                                   │
│  ┌───────────────────────────────────────────┐   │
│  │  Hostname Routing                          │   │
│  │                                            │   │
│  │  grafana.local  → grafana:80 (monitoring)  │   │
│  │  demo-app.local → demo-app:8080 (default)  │   │
│  │  argocd.local   → argocd-server:443        │   │
│  └───────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `ingress-nginx/ingress-nginx` |
| Version | `4.8.3` |
| Namespace | `ingress-nginx` |

### Kind Integration

The controller is configured to work with Kind's port mapping:
- Kind maps host ports **80** and **443** to the control-plane node
- The node has the label `ingress-ready=true`
- The controller is scheduled on nodes with this label

## Usage

### Installation

```bash
# Install (part of bootstrap)
make install-ingress

# Verify
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### /etc/hosts Setup

Add entries for local DNS resolution:

```bash
# Add all platform hostnames
cat <<EOF | sudo tee -a /etc/hosts
127.0.0.1 grafana.local
127.0.0.1 demo-app.local
127.0.0.1 argocd.local
EOF
```

### Creating Ingress Resources

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  annotations:
    cert-manager.io/cluster-issuer: selfsigned-ca-issuer
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - my-service.local
    secretName: my-service-tls
  rules:
  - host: my-service.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 8080
```

## Troubleshooting

### Service Not Accessible

```bash
# Check ingress resources
kubectl get ingress -A

# Check controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50

# Verify /etc/hosts
cat /etc/hosts | grep local

# Test directly via port-forward
kubectl port-forward svc/<service-name> -n <namespace> 8080:<port>
```

### 502 Bad Gateway

```bash
# Check if backend pods are running
kubectl get pods -n <namespace> -l app=<app-name>

# Check endpoint resolution
kubectl get endpoints <service-name> -n <namespace>

# Describe the ingress for errors
kubectl describe ingress <ingress-name> -n <namespace>
```

### TLS Certificate Errors

Browser warnings about self-signed certificates are **expected** in this local setup. Either:
- Accept the risk in your browser
- Import the CA certificate into your system trust store

## References

- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kind Ingress Setup](https://kind.sigs.k8s.io/docs/user/ingress/)
- [Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
