# Docker Networking for Kind Multi-Cluster Setup

This document explains the Docker networking considerations and solutions for running multiple Kind clusters with Open Cluster Management (OCM).

## Understanding Kind's Docker Networking

### Default Behavior
- Kind creates a Docker network named `kind`
- Each cluster gets its own subnet within this network
- Default Docker bridge network uses `172.17.0.0/16`
- Kind typically uses `172.18.0.0/16` for its networks

### Network Architecture
```
Host Machine
├── Docker Bridge Network (172.17.0.0/16)
├── Kind Network (172.18.0.0/16)
│   ├── Hub Cluster (10.10.0.0/16 pods, 10.11.0.0/16 services)
│   ├── Spoke 1 (10.20.0.0/16 pods, 10.21.0.0/16 services)
│   └── Spoke 2 (10.30.0.0/16 pods, 10.31.0.0/16 services)
└── Host Network (varies by system)
```

## Subnet Planning

### Our Subnet Allocation Strategy

| Cluster | Pod Subnet | Service Subnet | Docker Network | Purpose |
|---------|------------|----------------|----------------|---------|
| Hub | 10.10.0.0/16 | 10.11.0.0/16 | kind | Management cluster |
| Spoke 1 | 10.20.0.0/16 | 10.21.0.0/16 | kind | Worker cluster 1 |
| Spoke 2 | 10.30.0.0/16 | 10.31.0.0/16 | kind | Worker cluster 2 |

### Why These Subnets?

1. **Avoid Docker Defaults**: 
   - Docker bridge: `172.17.0.0/16`
   - Kind default: `172.18.0.0/16`

2. **Avoid Common VPN Ranges**:
   - Many VPNs use `10.0.0.0/8`
   - Our ranges are more specific to avoid conflicts

3. **Room for Growth**:
   - Each cluster gets `/16` (65,534 IPs)
   - Clear separation between clusters

## Port Management

### API Server Ports
- **Hub**: 6443 (standard Kubernetes)
- **Spoke 1**: 6444
- **Spoke 2**: 6445

### Application Ports
- **Hub**: 30000-30001
- **Spoke 1**: 30002-30003
- **Spoke 2**: 30004-30005

### Port Conflict Resolution
```bash
# Check for port conflicts
netstat -tulpn | grep -E ':(6443|6444|6445|30000|30001|30002|30003|30004|30005)'

# Check Docker port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

## Docker Daemon Configuration

### Default Address Pools (if needed)

If you encounter subnet conflicts, configure Docker daemon:

```bash
# Edit Docker daemon config
sudo nano /etc/docker/daemon.json
```

Add configuration:
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

Restart Docker:
```bash
sudo systemctl restart docker
```

### Alternative: Custom Docker Networks

Create dedicated networks for each cluster:

```bash
# Create custom networks
docker network create --driver bridge --subnet=10.10.0.0/16 kind-hub
docker network create --driver bridge --subnet=10.20.0.0/16 kind-spoke1
docker network create --driver bridge --subnet=10.30.0.0/16 kind-spoke2

# Update Kind configs to use custom networks
```

## Network Troubleshooting

### 1. Check Docker Networks
```bash
# List all Docker networks
docker network ls

# Inspect specific network
docker network inspect kind

# Check network connectivity
docker network connect kind <container-name>
```

### 2. Verify Subnet Allocation
```bash
# Check which subnets are in use
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
docker network inspect kind | grep Subnet
```

### 3. Test Inter-Cluster Connectivity
```bash
# From hub cluster, test connectivity to spoke
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub run test-pod --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local

# Check if clusters can reach each other
docker exec -it ocm-hub-control-plane ping -c 3 ocm-spoke1-control-plane
```

### 4. DNS Resolution Issues
```bash
# Check DNS in cluster
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub get pods -n kube-system | grep dns

# Test DNS resolution
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub run dns-test --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local
```

## Performance Considerations

### Network Performance
- Docker bridge networks have overhead
- Consider using `host` networking for performance-critical workloads
- Use `macvlan` for better performance (advanced)

### Resource Limits
```bash
# Check Docker network resource usage
docker system df
docker system prune  # Clean up unused networks
```

## Security Considerations

### Network Isolation
- Each cluster is isolated by default
- OCM provides secure communication between clusters
- Consider network policies for additional security

### Firewall Rules
```bash
# Allow required ports (if using host firewall)
sudo ufw allow 6443:6445/tcp  # API server ports
sudo ufw allow 30000:30005/tcp  # Application ports
```

## Advanced Networking Options

### 1. Custom CNI Plugins
```yaml
# In Kind config
networking:
  disableDefaultCNI: true
  # CNI will be installed separately
```

### 2. Multi-Network Support
```yaml
# Multiple networks per cluster
networking:
  disableDefaultCNI: true
  # Additional network configuration
```

### 3. Service Mesh Integration
- Istio, Linkerd, or Consul Connect
- Provides advanced networking capabilities
- Better observability and security

## Monitoring Network Health

### Cluster Network Status
```bash
# Check cluster networking
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub get nodes -o wide
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub get pods -n kube-system | grep -E '(cilium|flannel|calico)'
```

### Network Performance Metrics
```bash
# Monitor network usage
docker stats --no-stream
kubectl --kubeconfig=$HOME/.kube/kind-ocm-hub top nodes
```

## Best Practices

1. **Subnet Planning**: Always plan subnets to avoid conflicts
2. **Port Management**: Use unique ports for each cluster
3. **Resource Monitoring**: Monitor network resource usage
4. **Documentation**: Keep network configuration documented
5. **Testing**: Test connectivity between clusters regularly
6. **Backup**: Backup network configurations before changes

## Common Issues and Solutions

### Issue: Subnet Conflicts
**Solution**: Use different subnet ranges, configure Docker daemon

### Issue: Port Conflicts  
**Solution**: Use unique API server and application ports

### Issue: DNS Resolution Failures
**Solution**: Check CNI installation, verify DNS pods

### Issue: Slow Network Performance
**Solution**: Consider host networking or custom CNI plugins

### Issue: Inter-Cluster Communication Failures
**Solution**: Verify OCM configuration, check network policies
