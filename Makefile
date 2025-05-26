# Makefile for setting up Kind clusters with Cluster API

# Define variables
MGMT_CLUSTER_NAME ?= clusterapi-mgmt
WORKLOAD_CLUSTER_NAME ?= capi1
KUBECONFIG_PATH ?= $(HOME)/.kube/$(WORKLOAD_CLUSTER_NAME).kubeconfig.yaml
K8S_VERSION ?= 1.33.1

# Default target
all: create-mgmt-cluster setup-capi sleep add-cluster sleep get-config

cleanup: delete-workload-cluster delete-mgmt-cluster remove-config

sleep:
	@echo "Sleeping for 30 seconds..."
	sleep 30

setup-capi:
	@echo "Setting up Cluster API with Kind..."
	export CLUSTER_TOPOLOGY=true
	clusterctl init --infrastructure docker

add-cluster: gen-cluster apply-cluster

gen-cluster:
	clusterctl generate cluster $(WORKLOAD_CLUSTER_NAME) --flavor development \
  --kubernetes-version $(K8S_VERSION) \
  --control-plane-machine-count=3 \
  --worker-machine-count=3 \
  > cluster.yaml

apply-cluster:
	@echo "Adding workload cluster: $(WORKLOAD_CLUSTER_NAME)..."
	kubectl apply -f cluster.yaml

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
