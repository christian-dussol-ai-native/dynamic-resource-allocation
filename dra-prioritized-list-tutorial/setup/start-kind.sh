#!/usr/bin/env bash
set -euo pipefail

# Install kind if missing
if ! command -v kind >/dev/null 2>&1; then
  echo "kind not found. Installing kind v0.31.0..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
fi

echo "Creating Kind cluster 'dra-test'..."
kind create cluster \
  --name dra-test \
  --config 01-cluster-setup/kind-dra-config.yaml \
  --image kindest/node:v1.35.1

echo "Cluster dra-test created."
