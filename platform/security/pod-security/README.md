# Pod Security Standards

Pod Security Standards (PSS) provide a built-in way to enforce security best practices at the namespace level.

## Security Levels

### Privileged
**Namespaces**: `kube-system`, `istio-system`

**Description**: Unrestricted policy for system components that require elevated permissions.

**Use Cases**:
- System daemons (kube-proxy, CNI plugins)
- Service mesh data plane (Istio ztunnel)
- Infrastructure controllers

### Baseline
**Namespaces**: `monitoring`, `argocd`, `argo-rollouts`

**Description**: Minimally restrictive policy that prevents known privilege escalations.

**Restrictions**:
- No host namespaces (hostNetwork, hostPID, hostIPC)
- No privileged containers
- Limited volume types
- No host path mounts

**Use Cases**:
- Monitoring stack (Prometheus, Grafana)
- GitOps controllers
- Platform services

### Restricted
**Namespaces**: `default`, `staging`, `production`

**Description**: Heavily restricted policy following current Pod hardening best practices.

**Restrictions** (includes all baseline restrictions plus):
- Must run as non-root
- No privilege escalation
- Drop all capabilities
- Seccomp profile required
- Read-only root filesystem recommended

**Use Cases**:
- Application workloads
- User services
- Production applications

## Enforcement Modes

- **enforce**: Policy violations will cause the pod to be rejected
- **audit**: Violations are logged but pods are allowed
- **warn**: Violations trigger user-facing warnings but pods are allowed

## Implementation

```bash
# Apply namespace labels
kubectl apply -f platform/security/pod-security/namespace-labels.yaml

# Verify PSS configuration
kubectl get namespaces -L pod-security.kubernetes.io/enforce,pod-security.kubernetes.io/audit

# Test with a non-compliant pod
kubectl run test --image=nginx --privileged=true -n production
# Should be rejected in production (restricted)
```

## Compliance

Our demo-app-go is fully compliant with restricted PSS:
- ✅ Runs as non-root (UID 1000)
- ✅ No privilege escalation
- ✅ All capabilities dropped
- ✅ Read-only root filesystem
- ✅ Seccomp profile (runtime default)

## References

- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
