# External Secrets Operator

External Secrets Operator (ESO) synchronizes secrets from external providers (Vault, AWS Secrets Manager, etc.) into Kubernetes Secrets.

## Current Configuration

This platform uses the **Fake provider** for local demonstration. In production, swap to Vault or AWS Secrets Manager.

### Available Demo Secrets

| Key | Description |
|-----|-------------|
| `demo-api-key` | Sample API key |
| `demo-db-password` | Sample database password |
| `demo-redis-password` | Sample Redis password |

## Adding New Secrets

### 1. Add to SecretStore (Fake provider)

Edit `secretstore.yaml`:

```yaml
data:
  - key: "my-new-secret"
    value: "secret-value"
    version: "v1"
```

### 2. Create ExternalSecret

Create in your application directory:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: demo-store
    kind: ClusterSecretStore
  target:
    name: my-app-secrets  # K8s Secret name
  data:
    - secretKey: my-key   # Key in K8s Secret
      remoteRef:
        key: my-new-secret  # Key in SecretStore
```

### 3. Use in Deployment

```yaml
env:
  - name: MY_SECRET
    valueFrom:
      secretKeyRef:
        name: my-app-secrets
        key: my-key
```

## Production Migration

Replace `secretstore.yaml` with Vault or AWS configuration:

```yaml
# Vault example
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: demo-store
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
```

## Troubleshooting

```bash
# Check ESO pods
kubectl get pods -n external-secrets

# Check SecretStore status
kubectl get clustersecretstore demo-store -o yaml

# Check ExternalSecret sync status
kubectl get externalsecret -A

# View ESO logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

## Resources

- [External Secrets Docs](https://external-secrets.io/)
- [Supported Providers](https://external-secrets.io/latest/provider/aws-secrets-manager/)
