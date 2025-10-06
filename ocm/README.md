# Open Cluster Management (OCM) Configuration

This directory contains all the configuration and scripts for setting up and managing Open Cluster Management multi-cluster environments with Kind clusters.

## Structure

```
ocm/
├── Makefile              # OCM-specific Makefile with all OCM commands
├── kind-hub.config       # Kind configuration for OCM hub cluster
├── kind-spoke1.config    # Kind configuration for OCM spoke cluster 1
├── kind-spoke2.config    # Kind configuration for OCM spoke cluster 2
├── OCM-MULTICLUSTER.md   # OCM multi-cluster documentation
└── scripts/              # OCM-related scripts
    ├── join-cluster.sh   # Script to join spoke clusters to hub
    └── DOCKER-NETWORKING.md # Docker networking documentation
```

## Usage

From the repository root:
```bash
# Show OCM help
make ocm

# Run OCM commands
make ocm-create-hub
make ocm-create-spokes
make ocm-join-spokes
make ocm-status
```

Or from within this directory:
```bash
cd ocm
make help
make ocm-create-hub
make ocm-create-spokes
make ocm-join-spokes
```

## Key Commands

- `make ocm-prereqs` - Install OCM prerequisites (clusteradm, helm repos)
- `make ocm-create-hub` - Create OCM hub cluster
- `make ocm-create-spokes` - Create OCM spoke clusters
- `make ocm-join-spokes` - Join spoke clusters to hub
- `make ocm-status` - Show OCM multi-cluster status
- `make ocm-cleanup` - Clean up OCM multi-cluster environment

## Workflow

1. **Install Prerequisites**: `make ocm-prereqs`
2. **Create Hub Cluster**: `make ocm-create-hub`
3. **Create Spoke Clusters**: `make ocm-create-spokes`
4. **Join Spokes to Hub**: `make ocm-join-spokes`
5. **Check Status**: `make ocm-status`

## Documentation

- [OCM Quick Start Guide](https://open-cluster-management.io/docs/getting-started/quick-start/)
- [OCM GitHub Repository](https://github.com/open-cluster-management-io/ocm)

## Networking

The OCM setup uses custom Docker networking to enable communication between hub and spoke clusters. See `scripts/DOCKER-NETWORKING.md` for detailed networking configuration and troubleshooting.
