# Makefile for Open Cluster Management (OCM) setup and management
# https://open-cluster-management.io/docs/getting-started/quick-start/
# https://github.com/open-cluster-management-io/ocm/tree/main/deploy/cluster-manager/chart/cluster-manager

.PHONY: all help ocm-prereqs ocm-init ocm-add-manager-chart ocm-create-hub ocm-create-spokes ocm-join-spokes ocm-cleanup ocm-status

# Default target
all: ocm-create-hub ocm-create-spokes ocm-join-spokes
	@echo "OCM multi-cluster environment created and configured"

help:
	@echo "Open Cluster Management (OCM) Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make ocm-prereqs          - Install OCM prerequisites (clusteradm, helm repos)"
	@echo "  make ocm-init             - Initialize OCM on current cluster"
	@echo "  make ocm-create-hub       - Create OCM hub cluster"
	@echo "  make ocm-create-spokes    - Create OCM spoke clusters"
	@echo "  make ocm-join-spokes      - Join spoke clusters to hub"
	@echo ""
	@echo "Management Commands:"
	@echo "  make ocm-status           - Show OCM multi-cluster status"
	@echo "  make ocm-add-manager-chart - Install OCM cluster manager chart"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  make ocm-cleanup          - Clean up OCM multi-cluster environment"
	@echo "  make cleanup              - Alias for ocm-cleanup"
	@echo ""
	@echo "Documentation:"
	@echo "  OCM Quick Start: https://open-cluster-management.io/docs/getting-started/quick-start/"
	@echo "  OCM GitHub: https://github.com/open-cluster-management-io/ocm"

cleanup: ocm-cleanup

ocm-prereqs:
	@echo "Installing OCM prerequisites..."
	curl -L https://raw.githubusercontent.com/open-cluster-management-io/clusteradm/main/install.sh | bash
	helm repo add ocm https://open-cluster-management.io/helm-charts
	helm repo update

ocm-init:
	@echo "Initializing OCM..."
	# #--output-file=ocm-init.yaml add if you want to see all the stuff :)
	clusteradm init 

ocm-add-manager-chart:
	helm install cluster-manager  --version 1.0.0 ocm/cluster-manager --namespace=open-cluster-management --create-namespace

ocm-create-hub:
# network is shared with the hub and spokes
	@echo "🏗️  Creating OCM hub cluster..."
	kind create cluster --name ocm-hub --config kind-hub.config
	@echo "🔧 Installing Cilium CNI on hub cluster..."
	kubectl config use-context kind-ocm-hub && cilium install --version 1.18.0
	@echo "🔧 Initializing OCM on hub cluster..."
	kubectl config use-context kind-ocm-hub && clusteradm init --wait
	@echo "✅ OCM hub cluster created and configured"

ocm-create-spokes:
	@echo "🏗️  Creating spoke clusters..."
	kind create cluster --name ocm-spoke1 --config kind-spoke1.config
	@echo "🔧 Installing Cilium CNI on spoke clusters..."
	kubectl config use-context kind-ocm-spoke1 && cilium install --version 1.14.5
	@echo "✅ Spoke clusters created and configured"

ocm-join-spokes:
	@echo "🔗 Joining spoke clusters to hub..."
	./scripts/join-cluster.sh ocm-spoke1
	@echo "✅ Spoke clusters joined to hub"
	clusteradm accept --clusters ocm-spoke1

ocm-cleanup:
	@echo "🧹 Cleaning up OCM multi-cluster environment..."
	kind delete cluster --name ocm-hub 2>/dev/null || true
	kind delete cluster --name ocm-spoke1 2>/dev/null || true
	kind delete cluster --name ocm-spoke2 2>/dev/null || true
	@echo "✅ OCM multi-cluster environment cleaned up"

ocm-status:
	@echo "📊 OCM Multi-Cluster Status:"
	@echo "Hub Cluster:"
	@kubectl config use-context kind-ocm-hub 2>/dev/null && kubectl get managedclusters 2>/dev/null || echo "Hub cluster not found or not accessible"
	@echo ""
	@echo "Spoke Cluster 1:"
	@kubectl config use-context kind-ocm-spoke1 2>/dev/null && kubectl get nodes 2>/dev/null || echo "Spoke 1 not found or not accessible"
	@echo ""
	@echo "Spoke Cluster 2:"
	@kubectl config use-context kind-ocm-spoke2 2>/dev/null && kubectl get nodes 2>/dev/null || echo "Spoke 2 not found or not accessible"
