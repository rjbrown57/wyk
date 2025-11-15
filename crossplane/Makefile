# Makefile for Crossplane setup and management

.PHONY: all help setup-crossplane install-crossplane install-kubernetes-provider create-mgmt-cluster delete-mgmt-cluster get-config delete-clusters cleanup

# Define variables
MGMT_CLUSTER_NAME ?= crossplane-mgmt
CROSSPLANE_VERSION ?= 2.0.4
CROSSPLANE_NAMESPACE ?= crossplane-system

# Default target
all: create-mgmt-cluster setup-crossplane
	@echo "Created kind cluster and installed Crossplane with Kubernetes provider"

help:
	@echo "Crossplane Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup-crossplane           - Install Crossplane and Kubernetes provider"
	@echo "  make install-crossplane         - Install Crossplane via Helm"
	@echo "  make install-kubernetes-provider - Install Crossplane Kubernetes provider"
	@echo "  make create-mgmt-cluster        - Create Kind management cluster"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make get-config          - Get and merge kubeconfigs from all clusters"
	@echo "  make delete-clusters     - Delete all Kind clusters"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  make cleanup             - Clean up management cluster"
	@echo "  make delete-mgmt-cluster - Delete management cluster"
	@echo ""
	@echo "Variables:"
	@echo "  MGMT_CLUSTER_NAME=$(MGMT_CLUSTER_NAME)"
	@echo "  CROSSPLANE_VERSION=$(CROSSPLANE_VERSION)"
	@echo "  CROSSPLANE_NAMESPACE=$(CROSSPLANE_NAMESPACE)"

cleanup: delete-mgmt-cluster

install-crossplane-cli:
	@echo "Installing Crossplane client..."
	curl -sL https://raw.githubusercontent.com/crossplane/crossplane/main/install.sh | sh
	@echo "Crossplane client installed successfully."

setup-crossplane: install-crossplane install-crossplane-basics install-xrd install-composition
	@echo "Crossplane setup complete!"

install-crossplane:
	@echo "Installing Crossplane via Helm..."
	helm repo add crossplane-stable https://charts.crossplane.io/stable
	helm repo update
	helm upgrade crossplane \
	    --install \
		--namespace $(CROSSPLANE_NAMESPACE) \
		--create-namespace \
		--version $(CROSSPLANE_VERSION) \
		crossplane-stable/crossplane \
		--wait
	@echo "Waiting for Crossplane to be ready..."
	kubectl wait --for=condition=ready pod -l app=crossplane -n $(CROSSPLANE_NAMESPACE) --timeout=300s
	@echo "Crossplane installed successfully."

install-crossplane-basics:
	@echo "Installing Crossplane Kubernetes provider..."
	kubectl apply -f 0_crossplane_basics/kubernetes.yaml
	kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-kubernetes --timeout=300s
	kubectl apply -f 0_crossplane_basics/providerconfig.yaml
	kubectl apply -f 0_crossplane_basics/go_templating.yaml
	kubectl apply -f 0_crossplane_basics/autoready.yaml

install-xrd:
	@echo "Installing Crossplane XRD..."
	kubectl apply -f 1_xrd/project-xrd.yaml

install-composition:
	@echo "Installing Crossplane composition..."
	kubectl apply -f 3_composition/composition.yaml
	@echo "Crossplane composition installed successfully. You can now create a project instance using the following command:"
	@echo "kubectl apply -f 4_instances/project.yaml"

# Utility targets

get-config:
	@CLUSTER_LIST=""; \
	for cluster in $$(kind get clusters); do \
		kind get kubeconfig --name $$cluster > $(HOME)/.kube/$$cluster.kubeconfig.yaml; \
		CLUSTER_LIST="$$CLUSTER_LIST:$(HOME)/.kube/$$cluster.kubeconfig.yaml"; \
	done; \
	CLUSTER_LIST=$${CLUSTER_LIST#:}; \
	echo "CLUSTER_LIST: $$CLUSTER_LIST"; \
	export KUBECONFIG="$$CLUSTER_LIST" && \
	kubectl config view --flatten > $(HOME)/.kube/kubeconfig.yaml; \
	echo "Kubeconfig merged."; \
	echo "export KUBECONFIG=$(HOME)/.kube/kubeconfig.yaml"

delete-clusters:
	for cluster in $$(kind get clusters); do \
		kind delete cluster --name $$cluster; \
	done

# Target to create the Kind management cluster
create-mgmt-cluster:
	@echo "Creating Kind management cluster: $(MGMT_CLUSTER_NAME)..."
	kind create cluster --name $(MGMT_CLUSTER_NAME) --config kind.config

# Target to delete the Kind management cluster
delete-mgmt-cluster:
	@echo "Deleting Kind management cluster: $(MGMT_CLUSTER_NAME)..."
	kind delete cluster --name $(MGMT_CLUSTER_NAME)
	@echo "Management cluster deleted."

