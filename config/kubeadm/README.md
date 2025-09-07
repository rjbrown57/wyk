## Kubeadm-based Cluster API templates

These manifests define the control plane, bootstrap, and `ClusterClass` for a Kubeadm-driven Kubernetes cluster under Cluster API (CAPI). They are intended to be referenced by a `Cluster` to create a conformant cluster using Kubeadm for control plane and node bootstrapping.

- Apply order: files are prefixed with numbers. All `01_` templates can be applied in parallel, then apply `02_` (ClusterClass), then `03_` (Cluster).
- Scope: these are reusable templates and a `Cluster` definition; the templates alone do not provision a cluster until referenced.
 - Docker infrastructure used: `DockerClusterTemplate/docker-cluster`, `DockerMachineTemplate/docker-default`, `DockerMachinePoolTemplate/docker-default-worker-machinepooltemplate`.

### 01_kubeadmconfigtemplate_default-worker-bootstraptemplate.yaml
Creates: `KubeadmConfigTemplate` named `kubeadm-docker-default-worker-bootstraptemplate` in `default` namespace.

- Purpose in CAPI: Provides the bootstrap configuration for worker nodes when using `MachineDeployment`s (or `MachinePool`s). This template supplies the Kubeadm join configuration and kubelet settings used to initialize worker nodes consistently across the deployment.

### 01_kubeadmcontrolplanetemplate_control-plane.yaml
Creates: `KubeadmControlPlaneTemplate` named `kubeadm-docker-control-plane` in `default` namespace.

- Purpose in CAPI: Defines the control plane bootstrap and configuration via Kubeadm, including API server settings and kubelet args. It is referenced by the `ClusterClass` `controlPlane.templateRef` and drives creation and upgrades of the control plane across replicas.

### 02_clusterclass.yaml
Creates: `ClusterClass` named `kubeadm-docker` in `default` namespace.

- Purpose in CAPI: Acts as the cluster blueprint that wires together infrastructure templates and Kubeadm templates for control plane and workers. It standardizes cluster creation by referencing the appropriate templates and providing optional patches and variables.
  - References the following Docker infrastructure provider templates:
    - Infrastructure (cluster): `DockerClusterTemplate/docker-cluster`
    - Control plane machine infra: `DockerMachineTemplate/docker-default`
    - Worker machine pool infra (optional): `DockerMachinePoolTemplate/docker-default-worker-machinepooltemplate`
  - References the following Kubeadm templates:
    - Control plane: `KubeadmControlPlaneTemplate/kubeadm-docker-control-plane`
    - Worker bootstrap: `KubeadmConfigTemplate/kubeadm-docker-default-worker-bootstraptemplate`
  - Worker classes:
    - `machineDeployments[0].class: default-worker` (uses the worker bootstrap and `DockerMachineTemplate/docker-default`)


### 03_cluster_capi1.yaml
Creates: `Cluster` named `capi1` in `default` namespace.

- Purpose in CAPI: Represents an actual cluster instance using the `kubeadm-docker` `ClusterClass`. It specifies version, control plane size, and worker topology, and provides values for any variables consumed by the `ClusterClass` patches.

## Usage

- make create-mgmt-cluster
- make setup-capi
- Apply Prereqs from dockerinfraprovider directory
- Apply templates first (in parallel):
  - `kubectl apply -f config/kubeadm/01_kubeadmconfigtemplate_default-worker-bootstraptemplate.yaml`
  - `kubectl apply -f config/kubeadm/01_kubeadmcontrolplanetemplate_control-plane.yaml`
- Then apply the `ClusterClass`:
  - `kubectl apply -f config/kubeadm/02_clusterclass.yaml`
- Finally, create the `Cluster`:
  - `kubectl apply -f config/kubeadm/03_cluster_capi1.yaml`


