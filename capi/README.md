# Cluster API (CAPI) Configuration

This directory contains all the configuration and scripts for setting up and managing Cluster API with Kind clusters.

## Structure

```
capi/
├── Makefile              # CAPI-specific Makefile with all CAPI commands
├── kind.config           # Kind cluster configuration for CAPI management cluster
├── config/               # CAPI configuration files
│   ├── clusters/         # Cluster definitions
│   ├── dockerinfraprovider/ # Docker infrastructure provider configs
│   ├── kubeadm/          # Kubeadm bootstrap and control plane configs
│   └── rke2/             # RKE2 configurations
└── charts/               # Helm charts for CAPI
    └── kcapi/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            └── clusters/
                └── cluster.yaml
```

## Usage

From the repository root:
```bash
# Show CAPI help
make capi

# Run CAPI commands
make capi-setup-capi
make capi-create-mgmt-cluster
make capi-cleanup
```

Or from within this directory:
```bash
cd capi
make help
make setup-capi
make create-mgmt-cluster
```

## Key Commands

- `make setup-capi` - Setup Cluster API with Docker provider and Kubeadm
- `make create-mgmt-cluster` - Create Kind management cluster
- `make get-config` - Get and merge kubeconfigs from all clusters
- `make cleanup` - Clean up workload and management clusters

## Variables

- `MGMT_CLUSTER_NAME` - Name of the management cluster (default: clusterapi-mgmt)
- `WORKLOAD_CLUSTER_NAME` - Name of the workload cluster (default: capi1)
- `K8S_VERSION` - Kubernetes version to use (default: 1.34.0)
