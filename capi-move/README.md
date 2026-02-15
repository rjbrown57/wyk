# CAPI Move Test Environment (RKE2)

This directory sets up two CAPI management clusters for testing `clusterctl move` with RKE2 workloads.

## What This Environment Creates

- `kind-clusterapi-mgmt-a` and `kind-clusterapi-mgmt-b` management clusters
- CAPI core + CAPD + CAPRKE2 providers on both management clusters
- CAPIH (`addon-provider-helm`) on both management clusters
- A `HelmChartProxy` named `cilium` on each management cluster during setup
- RKE2 workload clusters generated from the local `cluster-template.yaml`

## Quick Start

```bash
cd /Users/lookfar/repos/github.com/rjbrown57/kcapi/capi-move

# Create mgmt clusters and initialize CAPI/CAPIH/CAPRKE2 on both
make all

# Create an RKE2 workload cluster on mgmt-a
make add-rke2-cluster TARGET_MGMT_CLUSTER=clusterapi-mgmt-a RKE2_CLUSTER_NAME=capi-move-rke2-1

# Rebuild merged kubeconfig for both management clusters
make get-config

# Show Cluster API Cluster objects on both mgmt clusters
make list-clusters

# Move CAPI objects from mgmt-a to mgmt-b
make move-cluster SOURCE_MGMT_CLUSTER=clusterapi-mgmt-a DEST_MGMT_CLUSTER=clusterapi-mgmt-b
```

## Command Notes

- `make setup-capi-on-both`:
  - runs `clusterctl init` with `--infrastructure docker --addon helm --bootstrap rke2 --control-plane rke2 --wait-providers`
  - applies `HelmChartProxy/cilium` to each management cluster
- `make add-rke2-cluster`:
  - switches to target management context
  - generates a cluster manifest from local template:
    - `/Users/lookfar/repos/github.com/rjbrown57/kcapi/capi-move/cluster-template.yaml`
  - writes it to `move-outputs/<cluster-name>.yaml`
  - applies it to the target management cluster
  - labels the cluster with `addons.cilium/enabled=true`
  - calls `make get-config`
- `make get-config`:
  - exports kubeconfig for `clusterapi-mgmt-a` and `clusterapi-mgmt-b` to `~/.kube/*.kubeconfig.yaml`
  - merges them into `~/.kube/kubeconfig.yaml`
  - syncs merged kubeconfig to `~/.kube/config`

## Optional Overrides

- `TARGET_MGMT_CLUSTER` (default: `clusterapi-mgmt-a`)
- `SOURCE_MGMT_CLUSTER` (default: `clusterapi-mgmt-a`)
- `DEST_MGMT_CLUSTER` (default: `clusterapi-mgmt-b`)
- `RKE2_CLUSTER_NAME` (default: `capi-move-rke2-1`)
- `NAMESPACE` (default: `default`)
- `RKE2_VERSION` (default: `v1.30.2+rke2r1`)
- `KIND_IMAGE_VERSION` (default: `v1.30.0`)
- `CONTROL_PLANE_MACHINE_COUNT` (default: `3`)
- `WORKER_MACHINE_COUNT` (default: `1`)
- `RKE2_CNI` (default: `none`, disables Canal)
- `RKE2_DOCKER_TEMPLATE_PATH` (default: `cluster-template.yaml`)
- `CILIUM_HELM_VERSION` (default: `1.18.2`)

## Cleanup

```bash
make cleanup
```
