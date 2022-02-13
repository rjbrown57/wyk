#!/bin/bash

kindConfig="./kind.config"
chartDir="./charts/"

# V1 bash version

# Create cluster
kindCreate() {
    # Create Kind Cluster
    sudo kind create cluster --config=${kindConfig}

    # Add ArgoCD
    helm repo add argo https://argoproj.github.io/argo-helm
    helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace
}

portForward() {
    kubectl port-forward service/argocd-server -n argocd 8080:443 &
}

getCreds() {
    pass=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    printf "Credentials = admin:%s\n" "${pass}"
    printf "Log in at https://localhost:8080\n"
}

addApps() {
    # Install Argo Pros
    helm upgrade --install argoprojs charts/argoProjs -n argocd

    # Install Argo Apps
    helm upgrade --install argoapps charts/argoApps -n argocd
}

main() {
    case "${1}" in 
        "create"|"")
            kindCreate
        ;;
        "getCreds")
            getCreds
        ;;
        "portForward")
            portForward
        ;;
        "addApps")
            addApps
        ;;
        "delete")
            kind delete clusters kind
    esac
}

main "${@}"
