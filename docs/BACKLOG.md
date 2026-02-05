# Project Backlog

This document outlines potential future enhancements and tasks for the GitOps Platform.

## High Priority

### 1. Secret Management Integration
**Description:**
Currently, the platform relies on manual secret management or unencrypted secrets in Git (for demo purposes). We need to implement a robust secret management solution to follow GitOps best practices where secrets can be safely stored in Git.

**Proposed Solution:**
- Implement **External Secrets Operator** (ESO) or **Sealed Secrets**.
- ESO is preferred for production-readiness as it integrates with external providers (AWS Secrets Manager, Vault, etc.), though for this local setup, a "Fake" provider or integration with a local Vault instance could be demonstrated.
- Alternatively, Sealed Secrets is easier for purely Git-based workflows without external dependencies.

**Acceptance Criteria:**
- [x] Secret management operator is installed via ArgoCD.
- [x] A demo secret is safely committed to the repo (encrypted or reference).
- [x] The secret is successfully synced and available as a Kubernetes Secret in the cluster.
- [x] Documentation added on how to add new secrets.

### 2. Policy Enforcement (Policy-as-Code)
**Description:**
While Pod Security Standards are good, a dynamic admission controller is needed for fine-grained policy enforcement (e.g., ensuring specific labels, restricting ingress classes, registry whitelisting).

**Proposed Solution:**
- Implement **Kyverno** or **OPA Gatekeeper**.
- Kyverno is often preferred for Kubernetes-native simplicity.

**Acceptance Criteria:**
- [x] Kyverno/Gatekeeper installed via ArgoCD.
- [x] Basic policies applied (e.g., "Require Labels", "Disallow :latest tag", "Restrict HostPath").
- [ ] Verify that a non-compliant pod is rejected by the admission controller.

### 3. Backup and Disaster Recovery
**Description:**
A production platform needs a strategy for backing up cluster state and persistent volumes.

**Proposed Solution:**
- Implement **Velero**.
- Configure it to use MinIO (local S3 compatible storage) since this is a Kind-based lab.

**Acceptance Criteria:**
- [x] MinIO installed and configured as a backup target.
- [x] Velero installed via ArgoCD.
- [x] Successful backup of a namespace.
- [x] Successful restore of the namespace after deletion.

## Medium Priority

### 4. Cost Management and Visibility
**Description:**
Understanding resource costs is a key SRE responsibility.

**Proposed Solution:**
- Implement **OpenCost** or **Kubecost**.

**Acceptance Criteria:**
- [x] OpenCost installed via ArgoCD.
- [x] Dashboards visible in Grafana showing resource allocation/costs (even if using dummy pricing data).

### 5. Chaos Engineering Integration
**Description:**
To validate the reliability claims (Argo Rollouts, etc.), we should introduce controlled faults.

**Proposed Solution:**
- Implement **Chaos Mesh** or **Litmus Chaos**.

**Acceptance Criteria:**
- [x] Chaos tool installed via ArgoCD.
- [x] A "Pod Kill" experiment configured to run against the demo app.
- [x] Verify that Argo Rollouts/ReplicaSets handle the failure gracefully without downtime.

## Low Priority / Future Improvements

### 6. Automated Dependency Updates
**Description:**
Keep Helm charts and container images up to date automatically.

**Proposed Solution:**
- Configure **Renovate Bot** (self-hosted or config for GitHub App).

**Acceptance Criteria:**
- [ ] Renovate configuration file added to the repository.
- [ ] (If self-hosted) Renovate cronjob running in the cluster checking for updates.

### 7. Documentation generator
**Description:**
Automate the generation of documentation from system state or component versions.

**Proposed Solution:**
- Scripts to parse `Chart.yaml` or `kustomization.yaml` files and update a "Component Versions" table in README.

## Phase 4: SLO Dashboards (Next Priority)

### 8. SLO/SLI Implementation
**Description:**
Implement Service Level Objectives monitoring using the instrumented metrics from the demo application.

**Proposed Solution:**
- Create Grafana dashboards for SLO tracking.
- Configure Prometheus rules for error budgets.

**Acceptance Criteria:**
- [ ] SLO overview dashboard created.
- [ ] Error budget tracking enabled.
- [ ] Service health monitoring visible.
- [ ] Alerting rules configured.

## Immediate Improvements

### 9. Rollouts Visualization & Testing
**Description:**
Enhance the visibility of progressive delivery and verify the pipeline under load.

**Acceptance Criteria:**
- [ ] Install kubectl argo rollouts plugin.
- [ ] Create Grafana dashboards for rollouts.
- [ ] Test complete deployment pipeline.
- [ ] Generate load for HPA testing.

### 10. Security Alerting
**Description:**
Connect Falco events to an alerting channel.

**Acceptance Criteria:**
- [ ] Configure Falcosidekick alerts (Slack/PagerDuty).

## Future Roadmap (Week 4+)

### 11. Advanced Observability
**Description:**
Expand the observability stack beyond metrics.

**Acceptance Criteria:**
- [ ] Add Loki (Logs) to observability stack.
- [ ] Add Tempo (Traces) to observability stack.
- [ ] OpenTelemetry integration.

### 12. Service Mesh Traffic Management
**Description:**
Utilize Istio for advanced traffic control beyond basic mTLS.

**Acceptance Criteria:**
- [ ] Implement advanced traffic shifting/splitting.
- [ ] Circuit breaking and fault injection experiments.

### 13. Advanced Platform Features
**Acceptance Criteria:**
- [ ] GitOps for applications directory refactoring.
- [ ] Multi-cluster setup exploration.
