#!/usr/bin/env bash
set -euo pipefail

if ! command -v kind >/dev/null 2>&1; then
  echo "kind is not installed. Unable to delete cluster."
  exit 1
fi

echo "Deleting Kind cluster 'dra-test'..."
kind delete cluster --name dra-test

echo "Cluster dra-test deleted."
