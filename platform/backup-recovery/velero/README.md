# Velero — Backup & Disaster Recovery

Velero provides backup, restore, and disaster recovery capabilities for Kubernetes cluster resources and persistent volumes.

## Overview

Velero can back up entire namespaces (including all resources, PVCs, and secrets) to an S3-compatible storage backend. In this platform, it uses **MinIO** as the local backup target.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              backup-recovery namespace                       │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   Velero Server                       │  │
│  │                                                      │  │
│  │  ┌──────────────┐  ┌──────────────────────────────┐  │  │
│  │  │ Velero Core  │  │ AWS S3 Plugin (init cont.)   │  │  │
│  │  │              │  │ velero-plugin-for-aws:v1.9.0  │  │  │
│  │  └──────────────┘  └──────────────────────────────┘  │  │
│  └──────────────────────────┬───────────────────────────┘  │
│                             │                               │
│                     S3 API (port 9000)                      │
│                             │                               │
│  ┌──────────────────────────▼───────────────────────────┐  │
│  │                    MinIO                              │  │
│  │  Bucket: velero                                       │  │
│  │  Region: minio                                        │  │
│  │  Path style: forced (s3ForcePathStyle: true)          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `vmware-tanzu/velero` |
| Version | `5.1.5` |
| Namespace | `backup-recovery` |
| Provider | `aws` (via MinIO) |

### Backup Storage Location

| Setting | Value |
|---------|-------|
| Bucket | `velero` |
| Region | `minio` |
| S3 URL | `http://minio.backup-recovery.svc:9000` |
| Path style | `true` (required for MinIO) |

### Credentials

```
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
```

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 500m |
| Memory | 128Mi | 512Mi |

## Usage

### Create a Backup

```bash
# Install Velero CLI
brew install velero

# Backup a specific namespace
velero backup create production-backup --include-namespaces production

# Backup with labels
velero backup create app-backup --selector app=demo-app-go

# Backup everything
velero backup create full-cluster-backup

# Check backup status
velero backup describe production-backup
velero backup logs production-backup
```

### Schedule Recurring Backups

```bash
# Daily backup of production
velero schedule create daily-production \
  --schedule="0 2 * * *" \
  --include-namespaces production \
  --ttl 168h  # 7 days retention

# List schedules
velero schedule get
```

### Restore from Backup

```bash
# Restore entire backup
velero restore create --from-backup production-backup

# Restore to a different namespace
velero restore create --from-backup production-backup \
  --namespace-mappings production:production-restored

# Check restore status
velero restore describe <restore-name>
velero restore logs <restore-name>
```

### Disaster Recovery Drill

```bash
# 1. Create backup
velero backup create dr-test --include-namespaces production
velero backup describe dr-test  # Wait for completion

# 2. Delete the namespace (simulate disaster)
kubectl delete namespace production

# 3. Restore from backup
velero restore create --from-backup dr-test

# 4. Verify restoration
kubectl get all -n production
kubectl get pods -n production
```

### List & Manage Backups

```bash
# List all backups
velero backup get

# Delete a backup
velero backup delete <backup-name>

# Delete expired backups
velero backup delete --all --confirm
```

## Troubleshooting

### Backup Failed

```bash
# Check Velero logs
kubectl logs -n backup-recovery deployment/velero --tail=50

# Check backup details
velero backup describe <backup-name> --details

# Check BackupStorageLocation status
velero backup-location get
kubectl get backupstoragelocation -n backup-recovery
```

### Restore Partially Failed

```bash
# Check restore logs
velero restore logs <restore-name>

# Common issues:
# - CRDs not present (install CRDs first, then restore)
# - PVC storage class mismatch
# - Namespace already exists with conflicting resources
```

### MinIO Connection Issues

```bash
# Verify MinIO is accessible
kubectl exec -n backup-recovery deployment/velero -- \
  wget -qO- http://minio.backup-recovery.svc:9000/minio/health/live

# Check credentials
kubectl get secret -n backup-recovery velero-server-credentials -o yaml
```

## Best Practices

1. **Test restores regularly** — A backup is worthless if restore doesn't work
2. **Set TTL on backups** — Prevent storage exhaustion
3. **Include resource labels** — Makes selective backup/restore easier
4. **Backup before upgrades** — Always create a backup before platform changes
5. **Document recovery procedures** — Include in your runbooks

## References

- [Velero Documentation](https://velero.io/docs/)
- [Velero + MinIO Setup](https://velero.io/docs/v1.12/contributions/minio/)
- [Velero CLI Reference](https://velero.io/docs/v1.12/velero-cli/)
- [Disaster Recovery Patterns](https://kubernetes.io/docs/tasks/administer-cluster/)
