# Trivy Operator - Continuous Security Scanning

Trivy Operator provides automated security scanning for Kubernetes clusters, identifying vulnerabilities, misconfigurations, and compliance issues.

## Overview

Trivy Operator continuously scans:
- **Container Images**: CVE vulnerabilities in application dependencies
- **Kubernetes Configurations**: Misconfigurations and security best practices
- **RBAC**: Overly permissive roles and bindings
- **Exposed Secrets**: Hardcoded credentials in ConfigMaps/Secrets
- **Compliance**: CIS Kubernetes Benchmark compliance

## Architecture

```
┌─────────────────────────────────────────────────────┐
│            Trivy Operator Controller                │
│  - Watches workloads (Deployments, StatefulSets)   │
│  - Schedules vulnerability scans                    │
│  - Creates VulnerabilityReport CRDs                 │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   Scan Jobs (Pods)   │
        │  - Pull image         │
        │  - Run trivy scan     │
        │  - Generate report    │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Custom Resources    │
        │  - VulnerabilityReport│
        │  - ConfigAuditReport │
        │  - RbacAssessment    │
        │  - ExposedSecretReport│
        └──────────┬───────────┘
                   │
                   ├────────┬─────────────┐
                   ▼        ▼             ▼
            ┌──────────┐ ┌──────────┐ ┌──────────┐
            │Prometheus│ │  Grafana │ │   CLI    │
            │ (Metrics)│ │(Dashboard│ │ (kubectl)│
            └──────────┘ └──────────┘ └──────────┘
```

## Custom Resources

### VulnerabilityReport

Generated for each container image, listing CVEs:

```yaml
apiVersion: aquasecurity.github.io/v1alpha1
kind: VulnerabilityReport
metadata:
  name: pod-demo-app-go-abc123-demo-app
  namespace: default
spec:
  summary:
    criticalCount: 0
    highCount: 2
    mediumCount: 15
    lowCount: 45
    unknownCount: 3
  vulnerabilities:
  - vulnerabilityID: CVE-2023-1234
    severity: HIGH
    title: "Buffer overflow in libfoo"
    primaryLink: https://nvd.nist.gov/...
    fixedVersion: "1.2.3"
```

### ConfigAuditReport

Checks Kubernetes resources against security best practices:

```yaml
apiVersion: aquasecurity.github.io/v1alpha1
kind: ConfigAuditReport
metadata:
  name: deployment-demo-app-go
  namespace: default
spec:
  summary:
    criticalCount: 0
    highCount: 0
    mediumCount: 2
    lowCount: 5
  checks:
  - checkID: KSV003
    title: "Default capabilities not dropped"
    severity: MEDIUM
    category: Security
```

### RbacAssessment

Identifies overly permissive RBAC configurations:

```yaml
apiVersion: aquasecurity.github.io/v1alpha1
kind: RbacAssessmentReport
spec:
  summary:
    criticalCount: 1
    highCount: 3
  checks:
  - checkID: RBAC-001
    title: "Cluster admin role bound to service account"
    severity: CRITICAL
```

### ExposedSecretReport

Detects hardcoded secrets in resources:

```yaml
apiVersion: aquasecurity.github.io/v1alpha1
kind: ExposedSecretReport
spec:
  summary:
    criticalCount: 2
  secrets:
  - category: Credential
    title: "AWS Access Key"
    severity: CRITICAL
```

## Scanning Schedule

### Automatic Scans

- **Vulnerability Scans**: Daily (every 24h)
- **Config Audits**: Daily (every 24h)
- **RBAC Assessment**: Daily (every 24h)
- **Compliance**: Every 6 hours
- **On Deployment**: Immediate scan when workload is created/updated

### Manual Scans

```bash
# Trigger vulnerability scan for specific workload
kubectl annotate deployment demo-app-go \
  trivy-operator.aquasecurity.github.io/scan-now=$(date +%s) \
  -n default

# Force rescan of all workloads
kubectl delete vulnerabilityreports --all -n default
```

## Viewing Reports

### CLI (kubectl)

```bash
# List vulnerability reports
kubectl get vulnerabilityreports -A

# Get detailed report for specific pod
kubectl get vulnerabilityreport <name> -n <namespace> -o yaml

# Show summary
kubectl get vulnerabilityreport <name> -n <namespace> \
  -o jsonpath='{.report.summary}'

# List config audit reports
kubectl get configauditreports -A

# Show high/critical config issues
kubectl get configauditreports -A \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.report.summary}{"\n"}{end}' | \
  grep -E 'high|critical'

# List RBAC assessments
kubectl get rbacassessmentreports -A

# Check for exposed secrets
kubectl get exposedsecretreports -A
```

### Dashboard (Grafana)

Create dashboards showing:
- Total vulnerabilities by severity
- Vulnerability trends over time
- Top vulnerable images
- Config audit failures
- RBAC issues
- Compliance score

### Prometheus Metrics

```promql
# Total vulnerabilities by severity
trivy_image_vulnerabilities{severity="CRITICAL"}
trivy_image_vulnerabilities{severity="HIGH"}

# Images with critical CVEs
count(trivy_image_vulnerabilities{severity="CRITICAL"} > 0)

# Config audit failures
trivy_resource_configaudits{severity="HIGH"}

# Exposed secrets count
trivy_exposed_secrets_total
```

## Security Policies

### Block Deployments with Critical CVEs

Create admission controller policy (using OPA/Gatekeeper or Kyverno):

```yaml
# Example Kyverno policy
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-critical-vulnerabilities
spec:
  validationFailureAction: enforce
  rules:
  - name: check-vulnerabilities
    match:
      resources:
        kinds:
        - Deployment
        - StatefulSet
    validate:
      message: "Image has CRITICAL vulnerabilities"
      deny:
        conditions:
        - key: "{{request.object.metadata.annotations.\"trivy.critical\" || '0'}}"
          operator: GreaterThan
          value: 0
```

### Require Config Audit Compliance

```yaml
# Deny deployments that fail config audit
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-security-config
spec:
  validationFailureAction: enforce
  rules:
  - name: check-security-context
    match:
      resources:
        kinds:
        - Deployment
    validate:
      message: "Must run as non-root with dropped capabilities"
      pattern:
        spec:
          template:
            spec:
              securityContext:
                runAsNonRoot: true
              containers:
              - securityContext:
                  allowPrivilegeEscalation: false
                  capabilities:
                    drop: ["ALL"]
```

## Vulnerability Database

### Update Frequency

Trivy automatically updates its vulnerability database:
- **Check**: Every 12 hours
- **Download**: When new database is available
- **Source**: GitHub Container Registry (ghcr.io/aquasecurity/trivy-db)

### Offline Mode

For air-gapped environments:

```bash
# Download DB externally
trivy image --download-db-only

# Mount DB in operator
# Update values in application.yaml:
trivy:
  dbRepositoryInsecure: true
  dbRepository: internal-registry.local/trivy-db
```

## Compliance Scanning

### CIS Kubernetes Benchmark

Trivy checks compliance with CIS benchmarks:

```bash
# View compliance reports
kubectl get ciskubebenchreports -A

# Get detailed compliance report
kubectl get ciskubebenchreport cluster -o yaml

# Check specific control
kubectl get ciskubebenchreport cluster -o yaml | grep -A 10 "1.1.1"
```

### NSA/CISA Kubernetes Hardening Guide

Additional checks for NSA recommendations.

## Demo App Scanning Results

Our demo-app-go should have minimal vulnerabilities:

```bash
# Check demo app vulnerabilities
kubectl get vulnerabilityreports -n default \
  -l app=demo-app-go

# Expected results:
# - Base image: alpine:3.19 (minimal CVEs)
# - Go binary: Static compilation (no dynamic libraries)
# - No package manager in final image
# - Estimated: 0 CRITICAL, 0-2 HIGH, 5-10 MEDIUM/LOW
```

## Integration with CI/CD

### Pre-deployment Scanning

Scan images before deployment:

```bash
# In CI pipeline (GitHub Actions, GitLab CI)
trivy image --severity HIGH,CRITICAL \
  --exit-code 1 \
  localhost:5001/demo-app-go:v1.0.0

# Exit code 1 if vulnerabilities found, fails pipeline
```

### GitHub Actions Example

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'localhost:5001/demo-app-go:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'

- name: Upload Trivy results to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

## Best Practices

### 1. Regular Updates
- Keep Trivy Operator updated
- Monitor for new CVEs in running images
- Update base images regularly

### 2. Prioritize Remediation
- **CRITICAL**: Fix immediately
- **HIGH**: Fix within 1 week
- **MEDIUM**: Fix within 1 month
- **LOW**: Fix during regular updates

### 3. Automate Response
- Alert on CRITICAL vulnerabilities
- Block deployments with known exploits
- Auto-create tickets for HIGH CVEs

### 4. Supply Chain Security
- Scan images in CI before deployment
- Use minimal base images (alpine, distroless)
- Verify image signatures (Cosign/Notary)

### 5. Compliance Monitoring
- Run CIS benchmarks regularly
- Track compliance trends
- Document exceptions and compensating controls

## Troubleshooting

### Scans Not Running

```bash
# Check operator logs
kubectl logs -n trivy-system -l app.kubernetes.io/name=trivy-operator

# Verify CRDs are installed
kubectl get crd | grep aquasecurity

# Check scan job status
kubectl get jobs -n trivy-system
```

### Database Update Failures

```bash
# Check network access to ghcr.io
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -I https://ghcr.io

# Manually trigger DB update
kubectl delete pod -n trivy-system -l app=trivy-operator
```

### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n trivy-system

# Reduce scan frequency
# Edit application.yaml:
vulnerabilityReport:
  scanInterval: 48h  # Increase from 24h

# Limit concurrent scans
trivy:
  resources:
    limits:
      cpu: 500m  # Reduce from 1000m
```

### Reports Not Appearing

```bash
# Check if workloads are excluded
kubectl get -n trivy-system configmap trivy-operator -o yaml | \
  grep excludeNamespaces

# Verify image can be pulled
kubectl run test --image=demo-app-go:v1.0.0 --dry-run=client

# Check RBAC permissions
kubectl auth can-i create vulnerabilityreports --as=system:serviceaccount:trivy-system:trivy-operator
```

## Cost Optimization

### Reduce Scan Frequency

For non-production environments:

```yaml
# Less frequent scans in dev
vulnerabilityReport:
  scanInterval: 72h  # 3 days
configAuditScan:
  scanInterval: 72h
```

### Exclude Non-Critical Namespaces

```yaml
excludeNamespaces: "kube-system,kube-public,kube-node-lease,dev-testing,sandbox"
```

### Cache Vulnerability Database

Use persistent volume for DB cache:

```yaml
trivy:
  storageSize: 10Gi  # Larger cache
```

## References

- [Trivy Operator Documentation](https://aquasecurity.github.io/trivy-operator/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NSA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- [CVE Database](https://nvd.nist.gov/)
