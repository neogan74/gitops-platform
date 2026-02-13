#!/usr/bin/env bash
# =============================================================================
# Kyverno Policy Enforcement Verification
# =============================================================================
# This script verifies that all Kyverno ClusterPolicies are actively enforcing
# by attempting to create non-compliant pods and confirming they are REJECTED.
#
# Usage: ./verify-policies.sh
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  Kyverno Policy Enforcement Verification${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Run a test that should FAIL (pod rejected by policy)
expect_denied() {
  local test_name="$1"
  local policy_name="$2"
  shift 2
  TOTAL=$((TOTAL + 1))

  echo -e "${YELLOW}▶ Test ${TOTAL}: ${test_name}${NC}"
  echo -e "  Policy: ${policy_name}"
  echo -n "  Result: "

  # Attempt to create the pod — we expect this to fail
  if output=$(kubectl "$@" 2>&1); then
    echo -e "${RED}✘ FAIL — Pod was ALLOWED (should have been rejected)${NC}"
    echo -e "  Output: ${output}"
    # Cleanup the accidentally created resource
    kubectl delete pod "$(echo "$output" | grep -oP '(?<=pod/)\S+')" --ignore-not-found &>/dev/null || true
    FAIL=$((FAIL + 1))
  else
    if echo "$output" | grep -qi "blocked\|denied\|violated\|not allowed\|forbidden\|validation error"; then
      echo -e "${GREEN}✔ PASS — Pod correctly REJECTED${NC}"
      echo -e "  Message: $(echo "$output" | grep -i 'message\|blocked\|denied\|violated\|not allowed\|forbidden\|validation error' | head -1 | sed 's/^[[:space:]]*/    /')"
      PASS=$((PASS + 1))
    else
      echo -e "${RED}✘ FAIL — Command failed but NOT due to policy enforcement${NC}"
      echo -e "  Output: ${output}"
      FAIL=$((FAIL + 1))
    fi
  fi
  echo ""
}

# Run a test that should SUCCEED (compliant pod)
expect_allowed() {
  local test_name="$1"
  shift
  TOTAL=$((TOTAL + 1))

  echo -e "${YELLOW}▶ Test ${TOTAL}: ${test_name}${NC}"
  echo -n "  Result: "

  if output=$(kubectl "$@" 2>&1); then
    echo -e "${GREEN}✔ PASS — Compliant pod was ALLOWED${NC}"
    PASS=$((PASS + 1))
    # Cleanup
    kubectl delete pod test-compliant-pod --namespace=default --ignore-not-found &>/dev/null || true
  else
    echo -e "${RED}✘ FAIL — Compliant pod was REJECTED (should have been allowed)${NC}"
    echo -e "  Output: ${output}"
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

summary() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  Summary: ${PASS}/${TOTAL} passed${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}  ✔ All policies are correctly enforcing!${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}  ✘ ${FAIL} test(s) failed — review output above.${NC}"
    echo ""
    return 1
  fi
}

# =============================================================================
# Pre-flight checks
# =============================================================================
header

echo -e "${BOLD}Pre-flight checks:${NC}"

# Check kubectl connectivity
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}✘ Cannot connect to Kubernetes cluster. Is your kubeconfig set?${NC}"
  exit 1
fi
echo -e "  ${GREEN}✔${NC} kubectl connected"

# Check Kyverno is running
if ! kubectl get pods -n kyverno -l app.kubernetes.io/component=admission-controller -o name 2>/dev/null | grep -q pod; then
  echo -e "${RED}✘ Kyverno admission controller not found in 'kyverno' namespace.${NC}"
  exit 1
fi
echo -e "  ${GREEN}✔${NC} Kyverno admission controller running"

# List active policies
echo ""
echo -e "${BOLD}Active ClusterPolicies:${NC}"
kubectl get clusterpolicies -o custom-columns="NAME:.metadata.name,ACTION:.spec.validationFailureAction,READY:.status.ready" 2>/dev/null || true
echo ""

# =============================================================================
# Tests
# =============================================================================

# Test 1: disallow-latest-tag
expect_denied \
  "Disallow Latest Tag — pod with nginx:latest should be REJECTED" \
  "disallow-latest-tag" \
  run test-latest-tag --image=nginx:latest --restart=Never --dry-run=server -o yaml

# Test 2: require-labels (no 'app' label)
expect_denied \
  "Require Labels — pod without 'app' label should be REJECTED" \
  "require-labels" \
  run test-missing-labels --image=nginx:1.27 --restart=Never --dry-run=server -o yaml

# Test 3: restrict-host-path
expect_denied \
  "Restrict Host Path — pod with hostPath volume should be REJECTED" \
  "restrict-host-path" \
  apply --dry-run=server -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-host-path
  namespace: default
  labels:
    app: policy-test
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      volumeMounts:
        - name: host-vol
          mountPath: /host-data
  volumes:
    - name: host-vol
      hostPath:
        path: /tmp
        type: Directory
EOF

# Test 4: Compliant pod should be allowed
expect_allowed \
  "Compliant pod (valid tag, has 'app' label, no hostPath) should be ALLOWED" \
  run test-compliant-pod --image=nginx:1.27 --restart=Never --labels=app=policy-test --dry-run=server -o yaml

# =============================================================================
# Summary
# =============================================================================
summary
