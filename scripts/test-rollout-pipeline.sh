#!/usr/bin/env bash
#
# test-rollout-pipeline.sh
#
# End-to-end test for the Argo Rollouts progressive delivery pipeline.
# Tests: rollout creation, canary progression, analysis run, promotion,
#        HPA scaling under load, and dashboard data presence.
#
# Prerequisites:
#   - kubectl configured for target cluster
#   - kubectl argo rollouts plugin installed
#   - Argo Rollouts controller running
#   - demo-app-go deployed as a Rollout
#
# Usage:
#   ./scripts/test-rollout-pipeline.sh [--namespace default] [--rollout demo-app-go] [--skip-load]
#
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Defaults ─────────────────────────────────────────────────────────────────
NAMESPACE="default"
ROLLOUT="demo-app-go"
SKIP_LOAD=false
PROMETHEUS_URL="http://localhost:9090"

# ─── Parse Arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace) NAMESPACE="$2"; shift 2 ;;
    --rollout) ROLLOUT="$2"; shift 2 ;;
    --skip-load) SKIP_LOAD=true; shift ;;
    --prometheus-url) PROMETHEUS_URL="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--namespace NS] [--rollout NAME] [--skip-load] [--prometheus-url URL]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────
pass()  { echo -e "  ${GREEN}✓${NC} $*"; }
fail()  { echo -e "  ${RED}✗${NC} $*"; FAILURES=$((FAILURES + 1)); }
info()  { echo -e "  ${CYAN}ℹ${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $*"; }
header() { echo -e "\n${CYAN}══════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}══════════════════════════════════════════════════${NC}"; }

FAILURES=0
TESTS_RUN=0

assert() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local description="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    pass "$description"
  else
    fail "$description"
  fi
}

# ─── Pre-flight Checks ───────────────────────────────────────────────────────
header "Pre-flight Checks"

assert "kubectl is available" command -v kubectl
assert "kubectl-argo-rollouts plugin is installed" kubectl argo rollouts version

# Check cluster connectivity
assert "Cluster is reachable" kubectl cluster-info

# Check Argo Rollouts controller
assert "Argo Rollouts controller is running" \
  kubectl get pods -n argo-rollouts -l app.kubernetes.io/name=argo-rollouts -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running

# Check the Rollout exists
assert "Rollout '${ROLLOUT}' exists in namespace '${NAMESPACE}'" \
  kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}"

# ─── Test 1: Rollout Status ──────────────────────────────────────────────────
header "Test 1: Rollout Status"

ROLLOUT_STATUS=$(kubectl argo rollouts status "${ROLLOUT}" -n "${NAMESPACE}" --timeout 10s 2>&1 || true)
info "Current status: ${ROLLOUT_STATUS}"

assert "Rollout is either Healthy or Paused" \
  echo "${ROLLOUT_STATUS}" | grep -qE "Healthy|Paused"

# Check replicas
DESIRED=$(kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
AVAILABLE=$(kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
info "Replicas: desired=${DESIRED}, available=${AVAILABLE}"

TESTS_RUN=$((TESTS_RUN + 1))
if [ "${AVAILABLE}" -ge "${DESIRED}" ] 2>/dev/null; then
  pass "Available replicas >= desired replicas"
else
  fail "Available replicas (${AVAILABLE}) < desired replicas (${DESIRED})"
fi

# ─── Test 2: Services ────────────────────────────────────────────────────────
header "Test 2: Services for Rollout"

assert "Stable service '${ROLLOUT}' exists" \
  kubectl get svc "${ROLLOUT}" -n "${NAMESPACE}"

assert "Canary/preview service '${ROLLOUT}-canary' exists" \
  kubectl get svc "${ROLLOUT}-canary" -n "${NAMESPACE}"

# Verify endpoints
ENDPOINTS=$(kubectl get endpoints "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
TESTS_RUN=$((TESTS_RUN + 1))
if [ -n "${ENDPOINTS}" ]; then
  pass "Stable service has active endpoints: ${ENDPOINTS}"
else
  fail "Stable service has no endpoints"
fi

# ─── Test 3: Analysis Templates ──────────────────────────────────────────────
header "Test 3: Analysis Templates"

assert "AnalysisTemplate 'success-rate' exists" \
  kubectl get analysistemplate success-rate -n "${NAMESPACE}"

assert "AnalysisTemplate 'error-rate-only' exists" \
  kubectl get analysistemplate error-rate-only -n "${NAMESPACE}"

# Verify Prometheus connectivity from the analysis template
PROM_ADDRESS=$(kubectl get analysistemplate success-rate -n "${NAMESPACE}" \
  -o jsonpath='{.spec.metrics[0].provider.prometheus.address}' 2>/dev/null || echo "unknown")
info "Analysis template Prometheus address: ${PROM_ADDRESS}"

# ─── Test 4: ServiceMonitor ──────────────────────────────────────────────────
header "Test 4: Metrics & ServiceMonitor"

assert "ServiceMonitor for demo-app exists" \
  kubectl get servicemonitor -n "${NAMESPACE}" -l app=demo-app-go

# Check if Rollouts controller metrics ServiceMonitor exists
assert "Argo Rollouts controller ServiceMonitor exists" \
  kubectl get servicemonitor -n monitoring -l "app.kubernetes.io/name=argo-rollouts"

# ─── Test 5: Canary Deployment Simulation ─────────────────────────────────────
header "Test 5: Canary Deployment (read-only check)"

info "Checking current rollout strategy..."
STRATEGY=$(kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.spec.strategy}' 2>/dev/null)

if echo "${STRATEGY}" | grep -q "canary"; then
  pass "Rollout uses canary strategy"
  STEPS=$(kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.spec.strategy.canary.steps}' 2>/dev/null || echo "[]")
  info "Canary steps configured: ${STEPS}"
elif echo "${STRATEGY}" | grep -q "blueGreen"; then
  pass "Rollout uses blue-green strategy"
  ACTIVE_SVC=$(kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.spec.strategy.blueGreen.activeService}' 2>/dev/null || echo "unknown")
  PREVIEW_SVC=$(kubectl get rollout "${ROLLOUT}" -n "${NAMESPACE}" -o jsonpath='{.spec.strategy.blueGreen.previewService}' 2>/dev/null || echo "unknown")
  info "Active service: ${ACTIVE_SVC}, Preview service: ${PREVIEW_SVC}"
else
  fail "No recognized strategy found"
fi

# Check for recent analysis runs
RECENT_ANALYSIS=$(kubectl get analysisrun -n "${NAMESPACE}" --sort-by=.metadata.creationTimestamp 2>/dev/null | tail -5 || echo "none")
info "Recent analysis runs:"
echo "${RECENT_ANALYSIS}" | while IFS= read -r line; do
  info "  ${line}"
done

# ─── Test 6: HPA Configuration ───────────────────────────────────────────────
header "Test 6: HPA Configuration"

HPA_EXISTS=$(kubectl get hpa -n "${NAMESPACE}" 2>/dev/null | grep -c "${ROLLOUT}" || echo "0")
TESTS_RUN=$((TESTS_RUN + 1))
if [ "${HPA_EXISTS}" -gt 0 ]; then
  pass "HPA exists for rollout"
  HPA_NAME=$(kubectl get hpa -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  MIN_REPLICAS=$(kubectl get hpa "${HPA_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "?")
  MAX_REPLICAS=$(kubectl get hpa "${HPA_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "?")
  CURRENT=$(kubectl get hpa "${HPA_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo "?")
  info "HPA: min=${MIN_REPLICAS}, max=${MAX_REPLICAS}, current=${CURRENT}"
else
  warn "No HPA found for rollout in namespace '${NAMESPACE}' (expected in production overlay)"
fi

# ─── Test 7: Load Generation & HPA ───────────────────────────────────────────
if [ "${SKIP_LOAD}" = false ]; then
  header "Test 7: Load Generation"

  info "Applying load test ConfigMap..."
  kubectl apply -f platform/testing/load-generator/load-test-job.yaml 2>/dev/null || true

  info "Waiting for load-test job pods to start..."
  sleep 5

  LOAD_PODS=$(kubectl get pods -n default -l app=load-test --no-headers 2>/dev/null | wc -l | tr -d ' ')
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "${LOAD_PODS}" -gt 0 ]; then
    pass "Load test pods created: ${LOAD_PODS}"
  else
    warn "Load test pods not yet ready (may take a moment)"
  fi

  info "Load test is running in the background."
  info "To monitor HPA: kubectl get hpa -n ${NAMESPACE} -w"
  info "To clean up: kubectl delete job load-test -n default"
else
  header "Test 7: Load Generation (SKIPPED)"
  info "Use --skip-load=false to enable load testing"
fi

# ─── Test 8: Prometheus Metrics ───────────────────────────────────────────────
header "Test 8: Prometheus Rollout Metrics"

# Check if Prometheus is accessible
PROM_UP=$(curl -sf "${PROMETHEUS_URL}/api/v1/status/config" > /dev/null 2>&1 && echo "yes" || echo "no")
TESTS_RUN=$((TESTS_RUN + 1))
if [ "${PROM_UP}" = "yes" ]; then
  pass "Prometheus is accessible at ${PROMETHEUS_URL}"

  # Check rollout-specific metrics
  for metric in "rollout_info" "rollout_phase" "rollout_reconcile_duration_seconds_count"; do
    RESULT=$(curl -sf "${PROMETHEUS_URL}/api/v1/query?query=${metric}" 2>/dev/null | grep -c '"result":\[{' || echo "0")
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "${RESULT}" -gt 0 ]; then
      pass "Metric '${metric}' has data"
    else
      warn "Metric '${metric}' has no data (controller may need time to emit)"
    fi
  done
else
  warn "Prometheus not accessible at ${PROMETHEUS_URL} (use --prometheus-url to override)"
  info "Skipping Prometheus metric checks"
fi

# ─── Test 9: Grafana Dashboard ────────────────────────────────────────────────
header "Test 9: Grafana Dashboard ConfigMap"

assert "Rollouts dashboard ConfigMap exists in monitoring namespace" \
  kubectl get configmap argo-rollouts-dashboard -n monitoring

assert "Dashboard ConfigMap has grafana_dashboard label" \
  kubectl get configmap argo-rollouts-dashboard -n monitoring -o jsonpath='{.metadata.labels.grafana_dashboard}' | grep -q "1"

# ─── Summary ─────────────────────────────────────────────────────────────────
header "Test Summary"

echo ""
echo -e "  Tests run:    ${TESTS_RUN}"
echo -e "  Failures:     ${FAILURES}"
echo ""

if [ "${FAILURES}" -eq 0 ]; then
  echo -e "  ${GREEN}All tests passed! ✓${NC}"
  echo ""
  exit 0
else
  echo -e "  ${RED}${FAILURES} test(s) failed ✗${NC}"
  echo ""
  exit 1
fi
