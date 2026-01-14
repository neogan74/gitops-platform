# Falco - Runtime Security Monitoring

Falco provides runtime security monitoring by detecting abnormal behavior and potential security threats in Kubernetes clusters.

## Overview

Falco uses eBPF (extended Berkeley Packet Filter) to monitor system calls and Kubernetes audit logs in real-time, detecting:

- Shell execution in containers
- Privilege escalation attempts
- Sensitive file access (credentials, keys)
- Package manager usage in running containers
- Network reconnaissance tools
- Unexpected process execution
- Container escape attempts
- Crypto mining activity

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Kubernetes Nodes                   │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Falco DaemonSet (eBPF)                  │  │
│  │  - Monitors system calls                 │  │
│  │  - Applies detection rules               │  │
│  │  - Generates security events             │  │
│  └────────────┬─────────────────────────────┘  │
└───────────────┼─────────────────────────────────┘
                │
                ▼
        ┌───────────────┐
        │  Falco Logs   │
        │  (JSON)       │
        └───────┬───────┘
                │
                ├──────────────┬───────────────┐
                ▼              ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Prometheus│   │  Loki    │   │  Alerts  │
        │ (Metrics) │   │  (Logs)  │   │ (Slack)  │
        └──────────┘   └──────────┘   └──────────┘
```

## Default Rules

Falco comes with comprehensive default rules covering:

### Process Execution
- Shell spawned in container
- Non-whitelisted processes
- Package managers (apt, yum, apk)
- Compiler execution

### File System
- Write to /etc, /bin, /usr/bin
- Read from /etc/shadow, /etc/passwd
- SSH key access
- Certificate file access

### Network
- Unexpected outbound connections
- Network tools (netcat, nmap)
- Port scanning detection

### Privilege Escalation
- Setuid/setgid usage
- Capability changes
- User namespace creation

### Kubernetes
- Privileged pod creation
- HostNetwork/HostPID usage
- ConfigMap/Secret access

## Custom Rules

We've added custom rules for our platform:

### Shell Spawned in Container
Detects when a shell is executed inside a container (potential interactive access or reverse shell).

**Priority**: WARNING

**Use Case**: Detect unauthorized access or debugging in production

### Privilege Escalation via Setuid
Detects chmod commands that set the setuid bit (privilege escalation vector).

**Priority**: CRITICAL

**Use Case**: Prevent privilege escalation attacks

### Sensitive File Access
Detects access to credential files, SSH keys, or authentication tokens.

**Priority**: WARNING

**Use Case**: Identify credential theft attempts

### Package Management in Container
Detects package managers running in containers (unusual in production).

**Priority**: WARNING

**Use Case**: Detect runtime modifications or malware installation

### Network Tool Execution
Detects network reconnaissance tools like netcat, nmap, socat.

**Priority**: WARNING

**Use Case**: Identify lateral movement or data exfiltration

## Deployment

```bash
# Deploy via ArgoCD
kubectl apply -f platform/security/falco/application.yaml

# Verify Falco is running
kubectl get pods -n falco

# Check Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50
```

## Testing Falco Rules

### Test Shell Execution Detection

```bash
# Get a demo app pod
POD=$(kubectl get pods -n default -l app=demo-app-go -o name | head -1)

# Execute shell (should trigger alert)
kubectl exec -it $POD -n default -- /bin/sh
```

**Expected Output** in Falco logs:
```json
{
  "output": "Shell spawned in container (user=root container_id=abc123 ...)",
  "priority": "Warning",
  "rule": "Shell Spawned in Container",
  "tags": ["container", "shell", "mitre_execution"]
}
```

### Test Sensitive File Access

```bash
# Try to read /etc/shadow (should trigger alert)
kubectl exec $POD -n default -- cat /etc/shadow 2>/dev/null || true
```

### Test Package Manager Detection

```bash
# Try to install package (should trigger alert)
kubectl exec $POD -n default -- apk add curl
```

### Test Network Tool Detection

```bash
# Try to use netcat (if installed)
kubectl exec $POD -n default -- nc -l 8888
```

## Monitoring Falco Events

### View Real-Time Events

```bash
# Stream Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco -f

# Filter by priority
kubectl logs -n falco -l app.kubernetes.io/name=falco -f | grep -i "priority.*critical"

# Filter by rule
kubectl logs -n falco -l app.kubernetes.io/name=falco -f | grep "Shell Spawned"
```

### Query in Grafana

Falco metrics are exported to Prometheus and can be visualized in Grafana:

```promql
# Total alerts by rule
sum by (rule) (rate(falco_events_total[5m]))

# Critical alerts
sum(rate(falco_events_total{priority="Critical"}[5m]))

# Alerts by container
sum by (k8s_pod_name) (rate(falco_events_total[5m]))
```

### Loki Integration

Falco logs can be ingested by Loki for long-term storage and querying:

```logql
{namespace="falco"} |~ "priority.*Critical"
{namespace="falco"} | json | priority = "Warning"
{namespace="falco"} | json | rule =~ "Shell.*"
```

## Alert Configuration

### Enable Falcosidekick for Webhooks

Uncomment in `application.yaml`:

```yaml
falcosidekick:
  enabled: true
  config:
    slack:
      webhookurl: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
      minimumpriority: "warning"
      messageformat: "json"
```

### Alert Destinations

Falcosidekick supports:
- **Slack**: Team notifications
- **PagerDuty**: Incident management
- **Webhooks**: Custom integrations
- **Email**: SMTP notifications
- **AWS SNS/SQS**: Cloud integration
- **Elasticsearch**: SIEM integration

## Tuning Rules

### Reduce False Positives

Create allowlists in custom rules:

```yaml
- list: allowed_images
  items: [demo-app-go, nginx, redis]

- list: build_images
  items: [golang, node, python]
```

### Adjust Priority Levels

```yaml
# In application.yaml
priority: warning  # Only alert on warning or higher
```

### Disable Noisy Rules

```yaml
# Add to customRules
- rule: Shell Spawned in Container
  enabled: false  # Disable if too noisy
```

## Performance Impact

Falco uses eBPF which has minimal overhead:
- **CPU**: ~100m per node (1-2%)
- **Memory**: ~128-512Mi per node
- **Network**: Negligible
- **Disk I/O**: Minimal (log rotation)

## Security Best Practices

### 1. Alert Prioritization
- **Critical**: Immediate response required
- **Warning**: Investigation needed
- **Notice**: Informational

### 2. Response Workflow
1. Receive alert
2. Check pod/container details
3. Review command execution
4. Determine if legitimate or attack
5. Take action (kill pod, block IP, patch)

### 3. Regular Review
- Review alerts weekly
- Tune rules to reduce false positives
- Update allowlists for new applications
- Keep Falco rules updated

### 4. Integration with Incident Response
- Connect to SIEM for correlation
- Automate response actions
- Document investigation procedures

## Common Detections

### Crypto Mining
```
Process spawning (xmrig, minerd, cpuminer)
High CPU usage patterns
Outbound connections to mining pools
```

### Container Escape Attempts
```
Access to host filesystem mounts
Manipulation of cgroup settings
Privileged operations
```

### Data Exfiltration
```
Large outbound data transfers
Compression tools (tar, gzip)
Network tools (curl, wget) in unusual contexts
```

### Reverse Shells
```
Shell spawning with redirected I/O
Netcat connections
Python/Perl reverse shell patterns
```

## Troubleshooting

### Falco Not Starting

```bash
# Check DaemonSet status
kubectl get daemonset -n falco

# Check driver loading
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i "driver"

# Verify kernel version supports eBPF
uname -r  # Should be 4.14+ for eBPF
```

### No Events Generated

```bash
# Check if rules are loaded
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i "rules"

# Verify priority threshold
kubectl get configmap -n falco -o yaml | grep priority

# Test with known trigger
kubectl exec -it <pod> -- /bin/sh
```

### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n falco

# Reduce buffering
# Edit values in application.yaml:
outputs_queue:
  capacity: 500000  # Reduce from 1000000
```

## References

- [Falco Documentation](https://falco.org/docs/)
- [Falco Rules](https://github.com/falcosecurity/rules)
- [eBPF Guide](https://ebpf.io/what-is-ebpf/)
- [Falcosidekick](https://github.com/falcosecurity/falcosidekick)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
