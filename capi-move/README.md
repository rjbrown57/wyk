# CAPI Move Test Environment

This directory sets up two CAPI management clusters for testing `clusterctl move`.

## What This Environment Creates

- `kind-clusterapi-mgmt-a` and `kind-clusterapi-mgmt-b` management clusters
- CAPI core + CAPD + kubeadm providers on both management clusters
- CAPIH (`addon-provider-helm`) on both management clusters
- A `HelmChartProxy` named `cilium` on each management cluster during setup
- Kubeadm workload clusters that can be created on either management cluster

## Quick Start

```bash
cd /Users/lookfar/repos/github.com/rjbrown57/kcapi/capi-move

# Create mgmt clusters and initialize CAPI/CAPIH on both
make all

# Create a workload cluster on mgmt-a (default target)
make add-kubeadm-cluster WORKLOAD_CLUSTER_NAME=capi-move-1

# Create a workload cluster on mgmt-b
make add-kubeadm-cluster TARGET_MGMT_CLUSTER=clusterapi-mgmt-b WORKLOAD_CLUSTER_NAME=capi-move-2

# Rebuild merged kubeconfig from all kind clusters (standalone)
make get-config

# Show Cluster API Cluster objects on both mgmt clusters
make list-clusters

# Move CAPI objects from mgmt-a to mgmt-b
make move-cluster SOURCE_MGMT_CLUSTER=clusterapi-mgmt-a DEST_MGMT_CLUSTER=clusterapi-mgmt-b
```

## Command Notes

- `make setup-capi-on-both`:
  - installs CAPI with `--addon helm`
  - waits for provider/webhook readiness
  - applies templates from `../capi/config/dockerinfraprovider/` and `../capi/config/kubeadm/`
  - applies `HelmChartProxy/cilium` to each management cluster
- `make add-kubeadm-cluster`:
  - switches to target management context
  - applies workload cluster manifest from `../capi/config/clusters/capi1.yaml`
  - labels the workload cluster with `addons.cilium/enabled=true`
  - calls `make get-config`
- `make get-config`:
  - exports kubeconfig for every kind cluster to `~/.kube/<cluster>.kubeconfig.yaml`
  - merges them into `~/.kube/kubeconfig.yaml`

## Optional Overrides

- `TARGET_MGMT_CLUSTER` (default: `clusterapi-mgmt-a`)
- `SOURCE_MGMT_CLUSTER` (default: `clusterapi-mgmt-a`)
- `DEST_MGMT_CLUSTER` (default: `clusterapi-mgmt-b`)
- `WORKLOAD_CLUSTER_NAME` (default: `capi-move-1`)
- `NAMESPACE` (default: `default`)
- `K8S_VERSION` (default: `v1.34.0`)
- `CILIUM_HELM_VERSION` (default: `1.18.2`)

## Cleanup

```bash
make cleanup
```
