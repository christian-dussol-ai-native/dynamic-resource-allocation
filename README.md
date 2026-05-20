# dynamic-resource-allocation

This repository contains a set of tutorials focused on **Dynamic Resource Allocation (DRA)** for Kubernetes.

The first available tutorial is located in `dra-prioritized-list-tutorial/` and covers the **Prioritized List**, a DRA pattern that lets you declare hardware preferences such as:

- "Give me an H100. If unavailable, try an A100. Otherwise, use an L4."

## Repository contents

- `dra-prioritized-list-tutorial/`: a step-by-step tutorial to set up a Kind cluster, install the DRA example driver, define mock DeviceClasses, and test the Prioritized List fallback cascade.

## First tutorial: Prioritized List

This tutorial explains how to:

- create a Kind cluster with DRA enabled
- install `kubernetes-sigs/dra-example-driver`
- define mock DeviceClasses representing multiple GPU tiers
- use a `ResourceClaimTemplate` with `firstAvailable`
- observe fallback behavior when higher-tier classes are unavailable

To get started, open `dra-prioritized-list-tutorial/README.md`.
