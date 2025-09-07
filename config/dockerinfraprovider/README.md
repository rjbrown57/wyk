## Docker Infrastructure Provider (CAPD) templates

These manifests define templates for the Cluster API Docker infrastructure provider (often called CAPD). They are used by a `ClusterClass`/`Cluster` to create a local, Docker-backed Kubernetes cluster for development and testing.

- Apply order: all files here are prefixed with `01_` and can be applied in parallel before any `ClusterClass` or `Cluster` that references them.
- Scope: these are reusable templates; they do not provision a cluster on their own until referenced by higher-level objects.

### 01_dockerclustertemplate.yaml
Creates: `DockerClusterTemplate` named `docker-cluster` in `default` namespace.

- Purpose in CAPI: Provides the cluster-scoped infrastructure template for CAPD. A `Cluster` (usually via a `ClusterClass` `infrastructure.templateRef`) uses this to create a `DockerCluster`, which represents the underlying networking and lifecycle for the management of Docker containers that back the cluster.

### 01_dockermachinetemplate.yaml
Creates: `DockerMachineTemplate` named `docker-default` in `default` namespace.

- Purpose in CAPI: Generic machine infrastructure template used for nodes (control plane or workers) depending on where it is referenced. Commonly referenced by a `KubeadmControlPlaneTemplate` (for control plane) or by `MachineDeployment`s (for workers). The `extraMounts` section exposes the host Docker socket in node containers to support operations like pulling images and running workloads.

### 01_dockermachinepooltemplate.yaml
Creates: `DockerMachinePoolTemplate` named `docker-default-worker-machinepooltemplate` in `default` namespace.

- Purpose in CAPI: Supplies the infrastructure template for worker nodes when using `MachinePool`s instead of `MachineDeployment`s. A `MachinePoolClass` (via a `ClusterClass`) or a direct `MachinePool` references this to create and manage a scalable pool of worker `DockerMachine`s.

## Usage

- Apply these templates first:
  - `kubectl apply -f config/dockerinfraprovider/`
  
- Then apply your `ClusterClass` and `Cluster` that reference these template names (e.g., via `infrastructure.templateRef` and `machineInfrastructure.templateRef`).


