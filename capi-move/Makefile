# Makefile for testing clusterctl move with two CAPI management clusters

.PHONY: \
	help \
	all \
	create-mgmt-clusters \
	create-mgmt-cluster-a \
	create-mgmt-cluster-b \
	setup-capi-on-both \
	setup-capi-a \
	setup-capi-b \
	wait-providers-a \
	wait-providers-b \
	add-kubeadm-cluster \
	get-config \
	deliver-cilium \
	list-clusters \
	move-cluster \
	cleanup

MGMT_CLUSTER_A ?= clusterapi-mgmt-a
MGMT_CLUSTER_B ?= clusterapi-mgmt-b
TARGET_MGMT_CLUSTER ?= $(MGMT_CLUSTER_A)
SOURCE_MGMT_CLUSTER ?= $(MGMT_CLUSTER_A)
DEST_MGMT_CLUSTER ?= $(MGMT_CLUSTER_B)
WORKLOAD_CLUSTER_NAME ?= capi-move-1
NAMESPACE ?= default
K8S_VERSION ?= v1.34.0
KIND_CONFIG ?= kind.config
CAPI_CONFIG_DIR ?= ../capi/config
CILIUM_HELM_VERSION ?= 1.18.2
CILIUM_SELECTOR_KEY ?= addons.cilium/enabled
CILIUM_SELECTOR_VALUE ?= true

all: create-mgmt-clusters setup-capi-on-both
	@echo "Two management clusters created and initialized for CAPI move tests."

help:
	@echo "CAPI Move Test Commands:"
	@echo ""
	@echo "Bootstrap:"
	@echo "  make all                     - Create and initialize both management clusters"
	@echo "  make create-mgmt-clusters    - Create both Kind management clusters"
	@echo "  make setup-capi-on-both      - Initialize CAPI on both management clusters"
	@echo ""
	@echo "Workload and move tests:"
	@echo "  make add-kubeadm-cluster     - Create one kubeadm workload cluster on TARGET_MGMT_CLUSTER"
	@echo "  make get-config              - Merge kubeconfigs from all Kind clusters"
	@echo "  make deliver-cilium          - Deliver Cilium Helm chart via CAPIH HelmChartProxy"
	@echo "  make list-clusters           - Show CAPI Cluster objects on both management clusters"
	@echo "  make move-cluster            - Move objects from SOURCE_MGMT_CLUSTER to DEST_MGMT_CLUSTER"
	@echo ""
	@echo "Cleanup:"
	@echo "  make cleanup                 - Delete both management clusters"
	@echo ""
	@echo "Variables:"
	@echo "  MGMT_CLUSTER_A=$(MGMT_CLUSTER_A)"
	@echo "  MGMT_CLUSTER_B=$(MGMT_CLUSTER_B)"
	@echo "  TARGET_MGMT_CLUSTER=$(TARGET_MGMT_CLUSTER)"
	@echo "  SOURCE_MGMT_CLUSTER=$(SOURCE_MGMT_CLUSTER)"
	@echo "  DEST_MGMT_CLUSTER=$(DEST_MGMT_CLUSTER)"
	@echo "  WORKLOAD_CLUSTER_NAME=$(WORKLOAD_CLUSTER_NAME)"
	@echo "  NAMESPACE=$(NAMESPACE)"
	@echo "  K8S_VERSION=$(K8S_VERSION)"
	@echo "  CILIUM_HELM_VERSION=$(CILIUM_HELM_VERSION)"
	@echo "  CILIUM_SELECTOR_KEY=$(CILIUM_SELECTOR_KEY)"
	@echo "  CILIUM_SELECTOR_VALUE=$(CILIUM_SELECTOR_VALUE)"

create-mgmt-clusters: create-mgmt-cluster-a create-mgmt-cluster-b
	@echo "Created management clusters: $(MGMT_CLUSTER_A), $(MGMT_CLUSTER_B)"

create-mgmt-cluster-a:
	@echo "Creating Kind management cluster: $(MGMT_CLUSTER_A)"
	kind create cluster --name $(MGMT_CLUSTER_A) --config $(KIND_CONFIG)

create-mgmt-cluster-b:
	@echo "Creating Kind management cluster: $(MGMT_CLUSTER_B)"
	kind create cluster --name $(MGMT_CLUSTER_B) --config $(KIND_CONFIG)

setup-capi-on-both: setup-capi-a setup-capi-b
	@echo "CAPI initialized on both management clusters"

setup-capi-a:
	@echo "Initializing CAPI on kind-$(MGMT_CLUSTER_A)"
	CLUSTER_TOPOLOGY=true clusterctl --kubeconfig-context kind-$(MGMT_CLUSTER_A) init --infrastructure docker --addon helm
	$(MAKE) wait-providers-a
	kubectl --context kind-$(MGMT_CLUSTER_A) apply -f $(CAPI_CONFIG_DIR)/dockerinfraprovider/
	kubectl --context kind-$(MGMT_CLUSTER_A) apply -f $(CAPI_CONFIG_DIR)/kubeadm/
	$(MAKE) deliver-cilium TARGET_MGMT_CLUSTER=$(MGMT_CLUSTER_A)

setup-capi-b:
	@echo "Initializing CAPI on kind-$(MGMT_CLUSTER_B)"
	CLUSTER_TOPOLOGY=true clusterctl --kubeconfig-context kind-$(MGMT_CLUSTER_B) init --infrastructure docker --addon helm
	$(MAKE) wait-providers-b
	kubectl --context kind-$(MGMT_CLUSTER_B) apply -f $(CAPI_CONFIG_DIR)/dockerinfraprovider/
	kubectl --context kind-$(MGMT_CLUSTER_B) apply -f $(CAPI_CONFIG_DIR)/kubeadm/
	$(MAKE) deliver-cilium TARGET_MGMT_CLUSTER=$(MGMT_CLUSTER_B)

wait-providers-a:
	@echo "Waiting for CAPI/CAPD controllers and webhooks on kind-$(MGMT_CLUSTER_A)"
	kubectl --context kind-$(MGMT_CLUSTER_A) -n capi-system wait --for=condition=Available deployment/capi-controller-manager --timeout=300s
	kubectl --context kind-$(MGMT_CLUSTER_A) -n capd-system wait --for=condition=Available deployment/capd-controller-manager --timeout=300s
	kubectl --context kind-$(MGMT_CLUSTER_A) -n capi-kubeadm-bootstrap-system wait --for=condition=Available deployment/capi-kubeadm-bootstrap-controller-manager --timeout=300s
	kubectl --context kind-$(MGMT_CLUSTER_A) -n capi-kubeadm-control-plane-system wait --for=condition=Available deployment/capi-kubeadm-control-plane-controller-manager --timeout=300s
	@until kubectl --context kind-$(MGMT_CLUSTER_A) get crd helmchartproxies.addons.cluster.x-k8s.io >/dev/null 2>&1; do \
		echo "Waiting for HelmChartProxy CRD on kind-$(MGMT_CLUSTER_A)..."; \
		sleep 2; \
	done
	@until [ -n "$$(kubectl --context kind-$(MGMT_CLUSTER_A) -n capd-system get endpoints capd-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for capd-webhook-service endpoints on kind-$(MGMT_CLUSTER_A)..."; \
		sleep 2; \
	done
	@until [ -n "$$(kubectl --context kind-$(MGMT_CLUSTER_A) -n capi-kubeadm-bootstrap-system get endpoints capi-kubeadm-bootstrap-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for capi-kubeadm-bootstrap-webhook-service endpoints on kind-$(MGMT_CLUSTER_A)..."; \
		sleep 2; \
	done
	@until [ -n "$$(kubectl --context kind-$(MGMT_CLUSTER_A) -n capi-kubeadm-control-plane-system get endpoints capi-kubeadm-control-plane-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for capi-kubeadm-control-plane-webhook-service endpoints on kind-$(MGMT_CLUSTER_A)..."; \
		sleep 2; \
	done

wait-providers-b:
	@echo "Waiting for CAPI/CAPD controllers and webhooks on kind-$(MGMT_CLUSTER_B)"
	kubectl --context kind-$(MGMT_CLUSTER_B) -n capi-system wait --for=condition=Available deployment/capi-controller-manager --timeout=300s
	kubectl --context kind-$(MGMT_CLUSTER_B) -n capd-system wait --for=condition=Available deployment/capd-controller-manager --timeout=300s
	kubectl --context kind-$(MGMT_CLUSTER_B) -n capi-kubeadm-bootstrap-system wait --for=condition=Available deployment/capi-kubeadm-bootstrap-controller-manager --timeout=300s
	kubectl --context kind-$(MGMT_CLUSTER_B) -n capi-kubeadm-control-plane-system wait --for=condition=Available deployment/capi-kubeadm-control-plane-controller-manager --timeout=300s
	@until kubectl --context kind-$(MGMT_CLUSTER_B) get crd helmchartproxies.addons.cluster.x-k8s.io >/dev/null 2>&1; do \
		echo "Waiting for HelmChartProxy CRD on kind-$(MGMT_CLUSTER_B)..."; \
		sleep 2; \
	done
	@until [ -n "$$(kubectl --context kind-$(MGMT_CLUSTER_B) -n capd-system get endpoints capd-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for capd-webhook-service endpoints on kind-$(MGMT_CLUSTER_B)..."; \
		sleep 2; \
	done
	@until [ -n "$$(kubectl --context kind-$(MGMT_CLUSTER_B) -n capi-kubeadm-bootstrap-system get endpoints capi-kubeadm-bootstrap-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for capi-kubeadm-bootstrap-webhook-service endpoints on kind-$(MGMT_CLUSTER_B)..."; \
		sleep 2; \
	done
	@until [ -n "$$(kubectl --context kind-$(MGMT_CLUSTER_B) -n capi-kubeadm-control-plane-system get endpoints capi-kubeadm-control-plane-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for capi-kubeadm-control-plane-webhook-service endpoints on kind-$(MGMT_CLUSTER_B)..."; \
		sleep 2; \
	done

add-kubeadm-cluster:
	@echo "Switching kubectl context to kind-$(TARGET_MGMT_CLUSTER)"
	kubectl config use-context kind-$(TARGET_MGMT_CLUSTER)
	@echo "Creating workload cluster $(WORKLOAD_CLUSTER_NAME) on kind-$(TARGET_MGMT_CLUSTER)"
	sed \
		-e 's/name: capi1/name: $(WORKLOAD_CLUSTER_NAME)/' \
		-e 's/version: 1.34.0/version: $(K8S_VERSION)/' \
		$(CAPI_CONFIG_DIR)/clusters/capi1.yaml | kubectl --context kind-$(TARGET_MGMT_CLUSTER) apply -f -
	@echo "Labeling cluster $(WORKLOAD_CLUSTER_NAME) for Cilium delivery"
	kubectl --context kind-$(TARGET_MGMT_CLUSTER) label cluster $(WORKLOAD_CLUSTER_NAME) $(CILIUM_SELECTOR_KEY)=$(CILIUM_SELECTOR_VALUE) --overwrite
	$(MAKE) get-config

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

deliver-cilium:
	@echo "Applying HelmChartProxy for Cilium on kind-$(TARGET_MGMT_CLUSTER)"
	printf '%s\n' \
		'apiVersion: addons.cluster.x-k8s.io/v1alpha1' \
		'kind: HelmChartProxy' \
		'metadata:' \
		'  name: cilium' \
		'  namespace: $(NAMESPACE)' \
		'spec:' \
		'  clusterSelector:' \
		'    matchLabels:' \
		'      $(CILIUM_SELECTOR_KEY): "$(CILIUM_SELECTOR_VALUE)"' \
		'  repoURL: https://helm.cilium.io' \
		'  chartName: cilium' \
		'  releaseName: cilium' \
		'  namespace: kube-system' \
		'  version: $(CILIUM_HELM_VERSION)' | kubectl --context kind-$(TARGET_MGMT_CLUSTER) apply -f -

list-clusters:
	@echo "Clusters in kind-$(MGMT_CLUSTER_A):"
	kubectl --context kind-$(MGMT_CLUSTER_A) get clusters.cluster.x-k8s.io -A || true
	@echo ""
	@echo "Clusters in kind-$(MGMT_CLUSTER_B):"
	kubectl --context kind-$(MGMT_CLUSTER_B) get clusters.cluster.x-k8s.io -A || true

move-cluster:
	@echo "Moving CAPI objects from kind-$(SOURCE_MGMT_CLUSTER) to kind-$(DEST_MGMT_CLUSTER) in namespace $(NAMESPACE)"
	clusterctl move \
		--from-context kind-$(SOURCE_MGMT_CLUSTER) \
		--to-context kind-$(DEST_MGMT_CLUSTER) \
		--namespace $(NAMESPACE)

cleanup:
	@echo "Deleting management clusters $(MGMT_CLUSTER_A) and $(MGMT_CLUSTER_B)"
	kind delete cluster --name $(MGMT_CLUSTER_A)
	kind delete cluster --name $(MGMT_CLUSTER_B)
