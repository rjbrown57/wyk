#!/bin/bash

# Script to join a spoke cluster to the OCM hub cluster
# Usage: ./join-cluster.sh <spoke-cluster-name>

set -e

SPOKE_CLUSTER_NAME=${1:-"ocm-spoke1"}
HUB_CONTEXT="kind-ocm-hub"
SPOKE_CONTEXT="kind-$SPOKE_CLUSTER_NAME"

echo "Joining cluster '$SPOKE_CLUSTER_NAME' to OCM hub..."

# Check if clusteradm is installed
if ! command -v clusteradm &> /dev/null; then
    echo "Error: clusteradm is not installed. Please run 'make ocm-prereqs' first."
    exit 1
fi

# Check if hub cluster context exists and is accessible
if ! kubectl config get-contexts | grep -q "$HUB_CONTEXT"; then
    echo "Error: Hub cluster context '$HUB_CONTEXT' not found."
    echo "Please ensure the hub cluster is created and contexts are merged."
    exit 1
fi

# Check if spoke cluster context exists and is accessible
if ! kubectl config get-contexts | grep -q "$SPOKE_CONTEXT"; then
    echo "Error: Spoke cluster context '$SPOKE_CONTEXT' not found."
    echo "Please ensure the spoke cluster is created and contexts are merged."
    exit 1
fi

echo "Using hub context: $HUB_CONTEXT"
echo "Using spoke context: $SPOKE_CONTEXT"

# Switch to hub cluster context
kubectl config use-context "$HUB_CONTEXT"

# Verify hub cluster is accessible
if ! kubectl get nodes &> /dev/null; then
    echo "Error: Cannot access OCM hub cluster. Please ensure it's running and accessible."
    exit 1
fi

# Get the join token and API server from the hub
echo "Getting join token from hub cluster..."
JOIN_DATA=$(clusteradm get token --context "$HUB_CONTEXT" -o json)

if [ -z "$JOIN_DATA" ]; then
    echo "Error: Failed to get join token from hub cluster."
    echo "Make sure OCM is properly initialized on the hub cluster."
    exit 1
fi

echo "Join data received from hub cluster"

# Extract token and API server from JSON
HUB_TOKEN=$(echo "$JOIN_DATA" | jq -r '.["hub-token"]')

if [ -z "$HUB_TOKEN" ] || [ "$HUB_TOKEN" = "null" ]; then
    echo "Error: Could not extract hub token from clusteradm output."
    echo "Please check the OCM hub cluster setup."
    exit 1
fi

# Look up the hub API server IP via docker network
# -f '{{(index .NetworkSettings.Networks "kind-shared").IPAddress}}' ocm-hub-control-plane 
HUB_APISERVER=$(docker inspect ocm-hub-control-plane --format='{{(index .NetworkSettings.Networks "kind").IPAddress}}')

echo "Adjusted hub API server address: $HUB_APISERVER"

# Build the join command
JOIN_COMMAND="clusteradm join --hub-token $HUB_TOKEN --hub-apiserver https://$HUB_APISERVER:6443 --cluster-name $SPOKE_CLUSTER_NAME"

echo "Built join command: $JOIN_COMMAND"

# Switch to spoke cluster context
kubectl config use-context "$SPOKE_CONTEXT"

# Verify spoke cluster is accessible
if ! kubectl get nodes &> /dev/null; then
    echo "Error: Cannot access spoke cluster. Please ensure it's running and accessible."
    exit 1
fi

echo "Joining spoke cluster to hub..."
echo "Executing join command..."

# Execute the join command
eval "$JOIN_COMMAND"

echo "Cluster '$SPOKE_CLUSTER_NAME' join command executed successfully."
echo "Please wait a few minutes for the cluster to appear in the hub cluster."

# Switch back to hub cluster to check status
kubectl config use-context "$HUB_CONTEXT"

echo "Checking cluster status..."
echo "You can monitor the cluster status with:"
echo "kubectl config use-context $HUB_CONTEXT && kubectl get managedclusters"
echo ""
echo "To check the cluster's detailed status:"
echo "kubectl config use-context $HUB_CONTEXT && kubectl describe managedcluster $SPOKE_CLUSTER_NAME"
