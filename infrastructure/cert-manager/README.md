# cert-manager — TLS Certificate Management

cert-manager automates the creation, renewal, and management of TLS certificates for all platform services.

## Overview

In this platform, cert-manager provides **self-signed TLS certificates** for local development. In production, it integrates with Let's Encrypt or other ACME providers for trusted certificates.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  cert-manager                        │
│                                                      │
│  ┌────────────────┐   ┌──────────────────────────┐  │
│  │  cert-manager  │   │  ClusterIssuer           │  │
│  │  controller    │──▶│  selfsigned-ca-issuer     │  │
│  └────────────────┘   └──────────────┬───────────┘  │
│                                      │              │
│                              Issues certificates    │
│                                      │              │
│         ┌────────────────────────────┼────────┐     │
│         ▼                            ▼        ▼     │
│  ┌──────────┐              ┌──────────┐ ┌────────┐  │
│  │grafana-tls│             │argocd-tls│ │ other  │  │
│  └──────────┘              └──────────┘ └────────┘  │
└─────────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `jetstack/cert-manager` |
| Version | `v1.13.3` |
| CRDs | Installed automatically |
| Namespace | `cert-manager` |

### ClusterIssuer

The platform uses a **self-signed CA issuer** for local development:

```yaml
# cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-ca-issuer
```

Services reference this issuer via annotations:
```yaml
annotations:
  cert-manager.io/cluster-issuer: selfsigned-ca-issuer
```

## Usage

### Installation

```bash
# Install cert-manager (part of bootstrap)
make install-cert-manager

# Verify installation
kubectl get pods -n cert-manager
kubectl get clusterissuers
```

### Verify Certificates

```bash
# List all certificates
kubectl get certificates -A

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# View certificate details
kubectl get secret <cert-tls-secret> -n <namespace> -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

### Services Using TLS

| Service | Secret Name | Hostname |
|---------|-------------|----------|
| Grafana | `grafana-tls` | `grafana.local` |
| ArgoCD | Built-in TLS | `argocd.local` |

## Production Migration

To switch from self-signed to Let's Encrypt:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: you@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

## Troubleshooting

### Certificate Not Issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager --tail=50

# Check certificate request status
kubectl get certificaterequests -A
kubectl describe certificaterequest <name> -n <namespace>

# Check order and challenge status (ACME)
kubectl get orders -A
kubectl get challenges -A
```

### Certificate Expired

```bash
# Force renewal by deleting the secret
kubectl delete secret <cert-tls-secret> -n <namespace>
# cert-manager will automatically re-issue
```

## References

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Self-Signed Issuers](https://cert-manager.io/docs/configuration/selfsigned/)
- [Let's Encrypt Integration](https://cert-manager.io/docs/configuration/acme/)
