# MinIO — S3-Compatible Object Storage

MinIO provides local S3-compatible storage used as the backup target for Velero disaster recovery.

## Overview

MinIO serves as a locally-hosted alternative to AWS S3, enabling Velero backups without cloud dependencies. This makes the entire backup/restore workflow self-contained within the Kind cluster.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              backup-recovery namespace                   │
│                                                         │
│  ┌────────────────────────┐   ┌──────────────────────┐ │
│  │        Velero           │──▶│       MinIO          │ │
│  │  (Backup controller)   │   │  (S3 storage)        │ │
│  │                        │   │                      │ │
│  │  Uses AWS S3 plugin    │   │  • Port: 9000 (API)  │ │
│  │  to talk to MinIO      │   │  • Port: 9001 (UI)   │ │
│  └────────────────────────┘   │  • Bucket: velero     │ │
│                               │  • Storage: 5Gi PVC   │ │
│                               └──────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `bitnami/minio` |
| Version | `12.8.14` |
| Namespace | `backup-recovery` |

### Credentials

| Setting | Value |
|---------|-------|
| Root user | `minio` |
| Root password | `minio123` |
| Default bucket | `velero` |

> ⚠️ **Demo credentials only.** Change in production.

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 512Mi |
| CPU | 100m | 500m |
| Storage | 5Gi PVC | — |

## Usage

### Access MinIO Console

```bash
# Port-forward MinIO UI
kubectl port-forward -n backup-recovery svc/minio 9001:9001

# Access: http://localhost:9001
# Login: minio / minio123
```

### Verify Storage

```bash
# Check MinIO pod
kubectl get pods -n backup-recovery -l app.kubernetes.io/name=minio

# Check PVC
kubectl get pvc -n backup-recovery

# Test S3 access (using mc CLI)
mc alias set local http://localhost:9000 minio minio123
mc ls local/velero/
```

## Troubleshooting

### MinIO Not Starting

```bash
# Check pod status
kubectl describe pod -n backup-recovery -l app.kubernetes.io/name=minio

# Check PVC binding
kubectl get pvc -n backup-recovery

# Common issue: insufficient storage on Kind node
docker exec gitops-platform-control-plane df -h
```

### Velero Can't Connect

```bash
# Verify MinIO service
kubectl get svc minio -n backup-recovery

# Test connectivity from Velero pod
kubectl exec -n backup-recovery deployment/velero -- \
  curl -s http://minio.backup-recovery.svc:9000/minio/health/live
```

## References

- [MinIO Documentation](https://min.io/docs/minio/kubernetes/upstream/)
- [MinIO Helm Chart (Bitnami)](https://github.com/bitnami/charts/tree/main/bitnami/minio)
