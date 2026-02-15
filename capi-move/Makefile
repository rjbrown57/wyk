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
	add-rke2-cluster \
	get-config \
	deliver-cilium \
	list-clusters \
	move-cluster \
	delete-capi-clusters \
	cleanup

MGMT_CLUSTER_A ?= clusterapi-mgmt-a
MGMT_CLUSTER_B ?= clusterapi-mgmt-b
TARGET_MGMT_CLUSTER ?= $(MGMT_CLUSTER_A)
SOURCE_MGMT_CLUSTER ?= $(MGMT_CLUSTER_A)
DEST_MGMT_CLUSTER ?= $(MGMT_CLUSTER_B)
RKE2_CLUSTER_NAME ?= capi-move-rke2-1
NAMESPACE ?= default
RKE2_VERSION ?= v1.34.2+rke2r1
KIND_IMAGE_VERSION ?= v1.34.0
CONTROL_PLANE_MACHINE_COUNT ?= 1
WORKER_MACHINE_COUNT ?= 1
RKE2_CNI ?= none
KIND_CONFIG ?= kind.config
CAPI_CONFIG_DIR ?= ../capi/config
# https://raw.githubusercontent.com/rancher/cluster-api-provider-rke2/refs/heads/main/examples/templates/docker/cluster-template.yaml
RKE2_DOCKER_TEMPLATE_PATH ?= cluster-template.yaml
MOVE_OUTPUTS_DIR ?= move-outputs
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
	@echo "  make add-rke2-cluster        - Create one RKE2 workload cluster on TARGET_MGMT_CLUSTER"
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
	@echo "  RKE2_CLUSTER_NAME=$(RKE2_CLUSTER_NAME)"
	@echo "  NAMESPACE=$(NAMESPACE)"
	@echo "  RKE2_VERSION=$(RKE2_VERSION)"
	@echo "  KIND_IMAGE_VERSION=$(KIND_IMAGE_VERSION)"
	@echo "  CONTROL_PLANE_MACHINE_COUNT=$(CONTROL_PLANE_MACHINE_COUNT)"
	@echo "  WORKER_MACHINE_COUNT=$(WORKER_MACHINE_COUNT)"
	@echo "  RKE2_CNI=$(RKE2_CNI)"
	@echo "  RKE2_DOCKER_TEMPLATE_PATH=$(RKE2_DOCKER_TEMPLATE_PATH)"
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
	CLUSTER_TOPOLOGY=true clusterctl --kubeconfig-context kind-$(MGMT_CLUSTER_A) init --infrastructure docker --addon helm --bootstrap rke2 --control-plane rke2 --wait-providers
	$(MAKE) deliver-cilium TARGET_MGMT_CLUSTER=$(MGMT_CLUSTER_A)

setup-capi-b:
	@echo "Initializing CAPI on kind-$(MGMT_CLUSTER_B)"
	CLUSTER_TOPOLOGY=true clusterctl --kubeconfig-context kind-$(MGMT_CLUSTER_B) init --infrastructure docker --addon helm --bootstrap rke2 --control-plane rke2 --wait-providers
	$(MAKE) deliver-cilium TARGET_MGMT_CLUSTER=$(MGMT_CLUSTER_B)

add-rke2-cluster:
	@echo "Switching kubectl context to kind-$(TARGET_MGMT_CLUSTER)"
	kubectl config use-context kind-$(TARGET_MGMT_CLUSTER)
	@echo "Generating RKE2 Docker cluster manifest for $(RKE2_CLUSTER_NAME)"
	@mkdir -p $(MOVE_OUTPUTS_DIR)
	@CONTROL_PLANE_MACHINE_COUNT=$(CONTROL_PLANE_MACHINE_COUNT) \
	WORKER_MACHINE_COUNT=$(WORKER_MACHINE_COUNT) \
	RKE2_VERSION=$(RKE2_VERSION) \
	KIND_IMAGE_VERSION=$(KIND_IMAGE_VERSION) \
	clusterctl --kubeconfig-context kind-$(TARGET_MGMT_CLUSTER) generate cluster \
		--from $(RKE2_DOCKER_TEMPLATE_PATH) \
		-n $(NAMESPACE) \
		$(RKE2_CLUSTER_NAME) > $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml
	@echo "Setting RKE2 CNI to $(RKE2_CNI) in generated manifest"
	@sed -E 's/(cni:[[:space:]]*)canal/\1$(RKE2_CNI)/g' $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml > $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml.tmp
	@mv $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml.tmp $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml
	@echo "Applying generated manifest $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml"
	kubectl --context kind-$(TARGET_MGMT_CLUSTER) apply -f $(MOVE_OUTPUTS_DIR)/$(RKE2_CLUSTER_NAME).yaml
	@echo "Labeling cluster $(RKE2_CLUSTER_NAME) for Cilium delivery"
	kubectl --context kind-$(TARGET_MGMT_CLUSTER) label cluster $(RKE2_CLUSTER_NAME) $(CILIUM_SELECTOR_KEY)=$(CILIUM_SELECTOR_VALUE) --overwrite
	$(MAKE) get-config

get-config:
	@mkdir -p $(HOME)/.kube; \
	CLUSTER_LIST=""; \
	for mgmt in $(MGMT_CLUSTER_A) $(MGMT_CLUSTER_B); do \
		if kind get clusters | rg -x "$$mgmt" >/dev/null; then \
			kind get kubeconfig --name $$mgmt > $(HOME)/.kube/$$mgmt.kubeconfig.yaml; \
			CLUSTER_LIST="$$CLUSTER_LIST:$(HOME)/.kube/$$mgmt.kubeconfig.yaml"; \
		fi; \
	done; \
	for mgmt in $(MGMT_CLUSTER_A) $(MGMT_CLUSTER_B); do \
		if ! kind get clusters | rg -x "$$mgmt" >/dev/null; then \
			continue; \
		fi; \
		for entry in $$(kubectl --context kind-$$mgmt get clusters.cluster.x-k8s.io -A -o jsonpath='{range .items[*]}{.metadata.namespace}:{.metadata.name}{"\n"}{end}' 2>/dev/null); do \
			ns=$${entry%%:*}; \
			cluster=$${entry##*:}; \
			[ -z "$$cluster" ] && continue; \
			out="$(HOME)/.kube/$$mgmt-$$cluster.kubeconfig.yaml"; \
			if clusterctl --kubeconfig-context kind-$$mgmt get kubeconfig "$$cluster" -n "$$ns" > "$$out" 2>/dev/null; then \
				lb_container="$$cluster-lb"; \
				host_port=$$(docker port "$$lb_container" 6443/tcp 2>/dev/null | head -n1 | awk -F: '{print $$NF}'); \
				if [ -n "$$host_port" ]; then \
					cluster_name=$$(kubectl --kubeconfig "$$out" config view -o jsonpath='{.clusters[0].name}' 2>/dev/null); \
					if [ -n "$$cluster_name" ]; then \
						kubectl --kubeconfig "$$out" config set-cluster "$$cluster_name" --server="https://127.0.0.1:$$host_port" >/dev/null; \
						echo "Rewrote $$cluster kubeconfig endpoint to https://127.0.0.1:$$host_port"; \
					fi; \
				else \
					echo "Warning: could not find host LB port for $$cluster (container $$lb_container)"; \
				fi; \
				CLUSTER_LIST="$$CLUSTER_LIST:$$out"; \
				echo "Added workload kubeconfig for $$cluster from $$mgmt"; \
			fi; \
		done; \
	done; \
	CLUSTER_LIST=$${CLUSTER_LIST#:}; \
	if [ -z "$$CLUSTER_LIST" ]; then \
		echo "No management/workload kubeconfigs were found."; \
		exit 1; \
	fi; \
	echo "CLUSTER_LIST: $$CLUSTER_LIST"; \
	KUBECONFIG="$$CLUSTER_LIST" kubectl config view --flatten > $(HOME)/.kube/kubeconfig.yaml; \
	cp $(HOME)/.kube/kubeconfig.yaml $(HOME)/.kube/config; \
	echo "Kubeconfig merged to $(HOME)/.kube/kubeconfig.yaml and synced to $(HOME)/.kube/config"; \
	echo "Contexts:"; \
	KUBECONFIG="$(HOME)/.kube/kubeconfig.yaml" kubectl config get-contexts -o name

deliver-cilium:
	@echo "Applying HelmChartProxy for Cilium on kind-$(TARGET_MGMT_CLUSTER)"
	@until kubectl --context kind-$(TARGET_MGMT_CLUSTER) get crd helmchartproxies.addons.cluster.x-k8s.io >/dev/null 2>&1; do \
		echo "Waiting for HelmChartProxy CRD on kind-$(TARGET_MGMT_CLUSTER)..."; \
		sleep 2; \
	done
	kubectl --context kind-$(TARGET_MGMT_CLUSTER) -n caaph-system wait --for=condition=Available deployment/caaph-controller-manager --timeout=300s
	@until [ -n "$$(kubectl --context kind-$(TARGET_MGMT_CLUSTER) -n caaph-system get endpoints caaph-webhook-service -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; do \
		echo "Waiting for caaph-webhook-service endpoints on kind-$(TARGET_MGMT_CLUSTER)..."; \
		sleep 2; \
	done
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

cleanup: delete-capi-clusters
	@echo "Deleting management clusters $(MGMT_CLUSTER_A) and $(MGMT_CLUSTER_B)"
	kind delete cluster --name $(MGMT_CLUSTER_A)
	kind delete cluster --name $(MGMT_CLUSTER_B)

delete-capi-clusters:
	@echo "Deleting CAPI Cluster objects from management clusters"
	-kubectl --context kind-$(MGMT_CLUSTER_A) delete clusters.cluster.x-k8s.io -A --all --ignore-not-found=true
	-kubectl --context kind-$(MGMT_CLUSTER_B) delete clusters.cluster.x-k8s.io -A --all --ignore-not-found=true
