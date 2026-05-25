#!/usr/bin/env bash
#
# Walk down the DRA Prioritized List cascade.
#
# Scenario:
#   1. Start with all three DeviceClasses (H100, A100, L4) available.
#      The scheduler should pick mock-h100 first.
#   2. Delete mock-h100. Re-create the pod.
#      The scheduler should now pick mock-a100.
#   3. Delete mock-a100. Re-create the pod.
#      The scheduler should descend to mock-l4.
#
# This demonstrates the core promise of Prioritized List:
# declarative heterogeneity-aware allocation.

set -euo pipefail

CASCADE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../03-cascade-test" && pwd)"

restore_deviceclasses() {
  echo "Restoring DeviceClasses from manifest..."
  kubectl apply -f "${CASCADE_DIR}/deviceclasses.yaml"
}

step() {
  echo ""
  echo "============================================================"
  echo "==> $1"
  echo "============================================================"
}

show_state() {
  echo "--- DeviceClasses currently present:"
  kubectl get deviceclass -o name 2>/dev/null || echo "    (none)"
  echo "--- Pod status:"
  kubectl get pod dra-cascade-test -o wide 2>/dev/null || echo "    (no pod)"
  echo "--- ResourceClaim status:"
  kubectl get resourceclaim 2>/dev/null || echo "    (none)"
}

make_deviceclass_unavailable() {
  local dc="$1"
  echo "Making DeviceClass ${dc} unavailable..."
  kubectl patch deviceclass "${dc}" --type=json -p '[{"op":"replace","path":"/spec/selectors/0/cel/expression","value":"false"}]'
}

reset_pod() {
  echo "Resetting pod and ResourceClaim..."
  kubectl delete -f "${CASCADE_DIR}/test-pod.yaml" --ignore-not-found
  kubectl delete -f "${CASCADE_DIR}/resourceclaim-prioritized.yaml" --ignore-not-found
  sleep 2
  kubectl apply -f "${CASCADE_DIR}/resourceclaim-prioritized.yaml"
  kubectl apply -f "${CASCADE_DIR}/test-pod.yaml"
  echo "Waiting for pod to schedule (max 30s)..."
  kubectl wait --for=condition=PodScheduled pod/dra-cascade-test --timeout=30s || {
    echo "Pod did NOT schedule. Inspect with: kubectl describe pod dra-cascade-test"
    return 1
  }
}

step "Step 1: All three DeviceClasses present (expect mock-h100)"
restore_deviceclasses
show_state
reset_pod
echo ""
echo "Scheduler events:"
kubectl describe pod dra-cascade-test | grep -A 10 "Events:" || true

step "Step 2: Disable mock-h100 (expect fallback to mock-a100)"
make_deviceclass_unavailable mock-h100
reset_pod
echo ""
echo "Scheduler events:"
kubectl describe pod dra-cascade-test | grep -A 10 "Events:" || true

step "Step 3: Disable mock-a100 (expect fallback to mock-l4)"
make_deviceclass_unavailable mock-a100
reset_pod
echo ""
echo "Scheduler events:"
kubectl describe pod dra-cascade-test | grep -A 10 "Events:" || true

step "Done — the cascade walked all the way down to mock-l4."
echo "Final state:"
show_state
