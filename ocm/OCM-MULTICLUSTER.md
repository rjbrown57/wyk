# OCM Multi-Cluster Setup with Kind

This guide explains how to set up a multi-cluster environment using Kind clusters with Open Cluster Management (OCM), accounting for Docker networking considerations.

## Overview

The setup creates:
- **Hub Cluster**: Central management cluster running OCM
- **Spoke Clusters**: Worker clusters that join the hub for management

## Docker Networking Considerations

### Subnet Allocation
To avoid IP conflicts, each cluster uses distinct subnet ranges:

| Cluster | Pod Subnet | Service Subnet | API Server Port |
|---------|------------|----------------|-----------------|
| Hub     | 10.10.0.0/16 | 10.11.0.0/16 | 6443 |
| Spoke 1 | 10.20.0.0/16 | 10.21.0.0/16 | 6444 |
| Spoke 2 | 10.30.0.0/16 | 10.31.0.0/16 | 6445 |

### Port Mapping
Each cluster exposes specific ports to avoid conflicts:
- Hub: 30000-30001
- Spoke 1: 30002-30003  
- Spoke 2: 30004-30005

## Prerequisites

Before starting, ensure you have the following installed:

1. **Docker**: Running and accessible
2. **Kind**: Kubernetes in Docker
3. **kubectl**: Kubernetes command-line tool
4. **clusteradm**: OCM command-line tool (installed automatically)

## Quick Start

### Option 1: Automated Setup (Recommended)

Run the complete setup script:

```bash
make ocm-setup-multicluster
```

This will:
1. Install prerequisites (clusteradm, cilium CLI)
2. Create hub cluster with OCM initialized
3. Create spoke clusters with CNI installed
4. Join spoke clusters to the hub

### Option 2: Manual Setup

#### Step 1: Create Hub Cluster

```bash
make ocm-create-hub
```

#### Step 2: Create Spoke Clusters

```bash
make ocm-create-spokes
```

#### Step 3: Join Spoke Clusters

```bash
make ocm-join-spokes
```

## Configuration Files

### Hub Cluster (`kind-hub.config`)
- Disables default CNI for custom networking
- Uses dual-stack IP family
- Mounts Docker socket for potential CAPI usage
- Exposes ports 30000-30001

### Spoke Clusters (`kind-spoke1.config`, `kind-spoke2.config`)
- Similar configuration to hub but with different subnets
- Each spoke has unique API server ports
- Different port mappings to avoid conflicts

## Available Make Targets

| Target | Description |
|--------|-------------|
| `make ocm-setup-multicluster` | Complete automated setup |
| `make ocm-create-hub` | Create hub cluster only |
| `make ocm-create-spokes` | Create spoke clusters only |
| `make ocm-join-spokes` | Join existing spokes to hub |
| `make ocm-status` | Check status of all clusters |
| `make ocm-cleanup` | Delete all OCM clusters |

## Cluster Management

### Switching Between Clusters

```bash
# Hub cluster
export KUBECONFIG=$HOME/.kube/kind-ocm-hub

# Spoke cluster 1
export KUBECONFIG=$HOME/.kube/kind-ocm-spoke1

# Spoke cluster 2
export KUBECONFIG=$HOME/.kube/kind-ocm-spoke2
```

### Checking Cluster Status

```bash
# From hub cluster context
kubectl get managedclusters

# Check detailed status
kubectl describe managedcluster ocm-spoke1
```

### Viewing Cluster Resources

```bash
# List all clusters and their status
make ocm-status

# Check nodes in specific cluster
kubectl --kubeconfig=$HOME/.kube/kind-ocm-spoke1 get nodes
```

## Networking Details

### Docker Network Configuration

By default, Kind creates a Docker network named `kind`. If you encounter subnet conflicts:

1. **Check existing Docker networks**:
   ```bash
   docker network ls
   ```

2. **Configure Docker daemon** (if needed):
   Add to `/etc/docker/daemon.json`:
   ```json
   {
     "default-address-pools": [
       {
         "base": "10.253.0.0/16",
         "size": 24
       }
     ]
   }
   ```
   Then restart Docker daemon.

### CNI Selection

The setup uses **Cilium** as the CNI plugin because:
- Better multi-cluster networking support
- Advanced networking features
- Good integration with OCM
- Dual-stack support

### Inter-Cluster Communication

For inter-cluster communication:
1. Ensure Docker networks allow traffic between clusters
2. Configure routing if needed
3. Use OCM's networking policies for application-level communication

## Troubleshooting

### Common Issues

1. **Subnet Conflicts**
   - Check Docker networks: `docker network ls`
   - Verify no overlapping subnets in configs

2. **Port Conflicts**
   - Ensure API server ports are unique (6443, 6444, 6445)
   - Check port mappings don't conflict

3. **Cluster Join Failures**
   - Verify hub cluster is running: `kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub get nodes`
   - Check OCM initialization: `kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub get pods -n open-cluster-management`

4. **CNI Issues**
   - Verify Cilium installation: `cilium status`
   - Check node readiness: `kubectl get nodes`

### Logs and Debugging

```bash
# Hub cluster logs
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub logs -n open-cluster-management -l app=cluster-manager

# Spoke cluster logs
kubectl --kubeconfig=$HOME/.kube/kind-ocm-spoke1 logs -n open-cluster-management-agent -l app=klusterlet
```

## Cleanup

To remove all OCM clusters:

```bash
make ocm-cleanup
```

Or manually:
```bash
kind delete cluster --name ocm-hub
kind delete cluster --name ocm-spoke1
kind delete cluster --name ocm-spoke2
```

## Next Steps

After successful setup:

1. **Deploy applications** across clusters using OCM placement policies
2. **Configure policies** for governance and compliance
3. **Set up observability** with OCM's monitoring capabilities
4. **Implement disaster recovery** strategies

## References

- [Open Cluster Management Documentation](https://open-cluster-management.io/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Docker Networking](https://docs.docker.com/network/)
