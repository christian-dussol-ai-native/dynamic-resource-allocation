#!/usr/bin/env bash
#
# Install the kubernetes-sigs/dra-example-driver in the current cluster.
#
# This driver simulates GPUs without requiring any hardware. It publishes
# ResourceSlices that describe mock devices, participates in the DRA allocation
# cycle, but does NOT run any real GPU workload.

set -euo pipefail

REPO_URL="https://github.com/kubernetes-sigs/dra-example-driver.git"
CLONE_DIR="${CLONE_DIR:-/tmp/dra-example-driver}"
NAMESPACE="${NAMESPACE:-dra-example-driver}"

echo "==> Cloning dra-example-driver..."
if [ ! -d "${CLONE_DIR}" ]; then
  git clone "${REPO_URL}" "${CLONE_DIR}"
else
  echo "    Already cloned at ${CLONE_DIR}, pulling latest..."
  (cd "${CLONE_DIR}" && git pull --ff-only)
fi

echo "==> Installing cert-manager (required by the driver's webhook)..."
# Comment out if your cluster already has cert-manager.
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager wait --for=condition=Available deployment --all --timeout=120s

echo "==> Installing the example driver..."
# Path may differ — verify in the upstream repo.
# Common entry points:
#   ./demo/scripts/install-dra-example-driver.sh
#   helm install dra-example-driver ./deployments/helm/dra-example-driver -n ${NAMESPACE} --create-namespace
INSTALL_SCRIPT="${CLONE_DIR}/demo/scripts/install-dra-example-driver.sh"

if [ -x "${INSTALL_SCRIPT}" ]; then
  "${INSTALL_SCRIPT}"
else
  echo "    Install script not found at expected path; falling back to Helm."
  helm install dra-example-driver \
    "${CLONE_DIR}/deployments/helm/dra-example-driver" \
    --namespace "${NAMESPACE}" \
    --create-namespace
fi

echo "==> Waiting for driver pods to be ready..."
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod --all --timeout=120s || {
  echo "    Pods not ready in time. Investigate with:"
  echo "    kubectl -n ${NAMESPACE} get pods"
  echo "    kubectl -n ${NAMESPACE} describe pod <pod-name>"
  exit 1
}

echo "==> Verifying ResourceSlices are published..."
kubectl get resourceslices

echo ""
echo "Done. The driver is publishing mock GPUs."
echo "Next: apply DeviceClasses from 03-cascade-test/deviceclasses.yaml"
