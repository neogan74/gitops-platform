# Kyverno — Policy Enforcement (Policy-as-Code)

Kyverno is a Kubernetes-native policy engine that validates, mutates, and generates resources based on customizable policies.

## Overview

Kyverno enforces organizational policies directly as Kubernetes resources (no new language to learn — just YAML). Policies are applied as admission webhooks, meaning non-compliant resources are **rejected at creation time**.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    kyverno namespace                         │
│                                                             │
│  ┌────────────────────────┐  ┌──────────────────────────┐  │
│  │ Admission Controller   │  │ Background Controller    │  │
│  │ (1 replica)            │  │ (1 replica)              │  │
│  │                        │  │                          │  │
│  │ • Validates admission  │  │ • Scans existing         │  │
│  │   requests             │  │   resources              │  │
│  │ • Enforces policies    │  │ • Policy report          │  │
│  │   in real-time         │  │   generation             │  │
│  └────────────────────────┘  └──────────────────────────┘  │
│                                                             │
│  ┌────────────────────────┐  ┌──────────────────────────┐  │
│  │ Cleanup Controller     │  │ Reports Controller       │  │
│  │ (1 replica)            │  │ (1 replica)              │  │
│  └────────────────────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         │
                    Webhook call
                         │
┌────────────────────────▼────────────────────────────────────┐
│                Kubernetes API Server                         │
│                                                             │
│  kubectl apply -f pod.yaml                                  │
│        │                                                    │
│        ▼                                                    │
│  ┌──────────────┐    ┌──────────────┐   ┌──────────────┐  │
│  │ Authenticate │ →  │  Authorize   │ → │   Admit      │  │
│  └──────────────┘    └──────────────┘   │  (Kyverno)   │  │
│                                          │              │  │
│                                          │  ✅ Allow    │  │
│                                          │  ❌ Deny     │  │
│                                          └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Policies

All policies use `validationFailureAction: Enforce` — violations are **blocked**, not just reported.

### 1. Disallow Latest Tag (`disallow-latest-tag.yaml`)

| Setting | Value |
|---------|-------|
| Category | Best Practices |
| Severity | Medium |
| Target | All Pods (containers, init, ephemeral) |
| Rule | Image tag must NOT be `:latest` |

**Rationale:** The `:latest` tag is mutable — the same tag can point to different images over time, making deployments unpredictable and debugging nearly impossible.

### 2. Require Labels (`require-labels.yaml`)

| Setting | Value |
|---------|-------|
| Category | Best Practices |
| Severity | Medium |
| Target | All Pods |
| Rule | Must have `app` label |

**Rationale:** Labels are essential for service discovery, monitoring, network policies, and cost attribution. The `app` label is the minimum required identifier.

### 3. Restrict Host Path (`restrict-host-path.yaml`)

| Setting | Value |
|---------|-------|
| Category | Security |
| Severity | High |
| Target | All Pods |
| Rule | `spec.volumes[*].hostPath` must be null |

**Rationale:** HostPath volumes expose the node's filesystem to containers, enabling container escape, data exfiltration, and host compromise.

## Configuration

### Helm Chart

| Setting | Value |
|---------|-------|
| Chart | `kyverno/kyverno` |
| Version | `3.1.4` |
| Namespace | `kyverno` |

### Controller Replicas

All controllers run with **1 replica** (appropriate for demo/dev; increase for production HA).

## Usage

### Check Policy Status

```bash
# List all cluster policies
kubectl get clusterpolicies

# View policy details
kubectl describe clusterpolicy disallow-latest-tag

# Check policy reports
kubectl get policyreport -A
kubectl get clusterpolicyreport
```

### Verify Policy Enforcement

Run the included verification script:

```bash
./platform/security/kyverno/tests/verify-policies.sh
```

Or test manually:

```bash
# Test 1: Should be REJECTED (latest tag)
kubectl run test-latest --image=nginx:latest --dry-run=server

# Test 2: Should be REJECTED (missing app label)
kubectl run test-labels --image=nginx:1.27 --dry-run=server

# Test 3: Should be ALLOWED (compliant)
kubectl run test-ok --image=nginx:1.27 --labels=app=test --dry-run=server
```

### View Policy Violations in Reports

```bash
# Background scan results
kubectl get policyreport -A -o wide

# Detailed violations
kubectl describe policyreport -n <namespace>
```

## Adding New Policies

Create a new `ClusterPolicy` in the `policies/` directory:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: my-new-policy
  annotations:
    policies.kyverno.io/title: My New Policy
    policies.kyverno.io/category: Custom
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: Enforce  # or Audit
  rules:
    - name: my-rule
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "Helpful error message for users"
        pattern:
          # ... your validation pattern
```

The `kyverno-policies` ArgoCD Application will automatically sync it.

## Useful Policy Ideas

| Policy | Description |
|--------|-------------|
| Require resource limits | Ensure all containers set CPU/memory limits |
| Restrict image registries | Only allow images from trusted registries |
| Require probes | Mandate liveness/readiness probes |
| Disallow privileged | Block privileged containers |
| Require non-root | Enforce `runAsNonRoot: true` |

## Troubleshooting

### Legitimate Pods Being Rejected

```bash
# Check which policy is blocking
# The error message includes the policy name and validation message

# Temporarily switch to Audit mode
kubectl patch clusterpolicy <policy-name> --type merge \
  -p '{"spec":{"validationFailureAction":"Audit"}}'

# Don't forget to switch back to Enforce after fixing
```

### Kyverno Webhook Unavailable

```bash
# Check admission controller
kubectl get pods -n kyverno -l app.kubernetes.io/component=admission-controller

# Check webhook configuration
kubectl get validatingwebhookconfigurations | grep kyverno

# Restart if needed
kubectl rollout restart deployment kyverno-admission-controller -n kyverno
```

### Policy Reports Not Generating

```bash
# Check background controller
kubectl get pods -n kyverno -l app.kubernetes.io/component=background-controller
kubectl logs -n kyverno -l app.kubernetes.io/component=background-controller --tail=20

# Check reports controller
kubectl get pods -n kyverno -l app.kubernetes.io/component=reports-controller
```

## References

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Policies Library](https://kyverno.io/policies/)
- [Policy Reporter UI](https://github.com/kyverno/policy-reporter)
- [Kubernetes Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
