# Makefile for setting up Kind clusters with Cluster API

.PHONY: all setup-capi setup-capi-rke2 create-mgmt-cluster delete-workload-cluster delete-mgmt-cluster remove-config install-cni sleep

# Define variables
MGMT_CLUSTER_NAME ?= clusterapi-mgmt
WORKLOAD_CLUSTER_NAME ?= capi1
KUBECONFIG_PATH ?= $(HOME)/.kube/$(WORKLOAD_CLUSTER_NAME).kubeconfig.yaml
K8S_VERSION ?= 1.34.0

# Default target
all: create-mgmt-cluster setup-capi
	@echo "Created kind cluster and installed Cluster API + Kubeadm + Docker provider"

cleanup: delete-workload-cluster delete-mgmt-cluster remove-config

setup-capi:
	@echo "Setting up Cluster API with Kind..."
	@echo "Initializing Cluster API with Docker provider and Kubeadm Bootstrap/Control Plane provider"
	export CLUSTER_TOPOLOGY=true && \
	clusterctl init --infrastructure docker

setup-capi-rke2:
	@echo "Initializing Cluster API RKE2 Bootstrap/Control Plane provider"
	clusterctl init --bootstrap rke2 --control-plane rke2

# Utility targets

get-config:
	kind get kubeconfig --name $(WORKLOAD_CLUSTER_NAME) > $(KUBECONFIG_PATH)
	@echo "Kubeconfig for $(WORKLOAD_CLUSTER_NAME) saved to $(KUBECONFIG_PATH)"

remove-config:
	@echo "Removing kubeconfig for $(WORKLOAD_CLUSTER_NAME)..."
	rm -f $(KUBECONFIG_PATH)
	@echo "Kubeconfig removed."

install-cni:
	@echo "Installing Cilium CNI..."
	kubectl config use-context kind-$(WORKLOAD_CLUSTER_NAME)
	cilium install

delete-workload-cluster:
	@echo "Deleting workload cluster: $(WORKLOAD_CLUSTER_NAME)..."
	clusterctl delete cluster $(WORKLOAD_CLUSTER_NAME)
	@echo "Workload cluster deleted."

# Target to create the Kind management cluster
create-mgmt-cluster:
	@echo "Creating Kind management cluster: $(MGMT_CLUSTER_NAME)..."
	kind create cluster --name $(MGMT_CLUSTER_NAME) --config kind.config

# Target to delete the Kind management cluster
delete-mgmt-cluster:
	@echo "Deleting Kind management cluster: $(MGMT_CLUSTER_NAME)..."
	kind delete cluster --name $(MGMT_CLUSTER_NAME)
	@echo "Management cluster deleted."

sleep:
	@echo "Sleeping for 30 seconds..."
	sleep 30
