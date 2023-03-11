#!/bin/bash

set -e

kindConfig="./cilium.config"

forwardaddress="0.0.0.0"
promport="9090"
grafanaport="30280"
hubblecliport="4245"
hubbleuiport="12000"

# Create cluster
# Install cilium with ingress
# Enable hubble-ui
# Show cilium status
kindCreate() {
    kind create cluster --config=${kindConfig}
    cilium install --kube-proxy-replacement=strict
    printf "Brief sleep before enabling hubble-ui"
    sleep 10
    cilium hubble enable --ui
    cilium status
}


addPromStack(){
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        helm install kps -n prom-stack --create-namespace  prometheus-community/kube-prometheus-stack
        helm install promadapter prometheus-community/prometheus-adapter -n prom-stack -f promadapter.yaml
}


# https://github.com/cilium/cilium/blob/master/install/kubernetes/cilium/values.yaml
# https://docs.cilium.io/en/v1.13/installation/kind/

main() {
    case "${1}" in 
        "create")
            kindCreate
        ;;
        "full")
            kindCreate
            addPromStack
        ;;
        "delete")
            kind delete clusters kind
        ;;
        "addpromstack") 
            addPromStack
        ;;
        "promui") 
            printf "Portforwarding promui to %s:%s - ctrl+c to cancel\n" "${forwardAddress}" "${promport}"
            kubectl port-forward -n prom-stack service/kps-kube-prometheus-stack-prometheus --address "${forwardaddress}" "${promport}:${promport}"
        ;;
        "grafanaui")
            printf "Portforwarding grafana to %s:%s - ctrl+c to cancel\n" "${forwardAddress}" "${grafanaport}"
            kubectl port-forward -n prom-stack service/kps-grafana --address "${forwardaddress}" "${grafanaport}":80
        ;;
        "hubbleui") 
            printf "Portforwarding hubble ui to 127.0.0.1:%s - ctrl+c to cancel\n" "${hubbleuiport}"
            kubectl port-forward -n kube-system service/hubble-ui --address "${forwardaddress}" "${hubbleuiport}":80
        ;;
        "hubblecli") 
            printf "Portforwarding hubble port-forward to 127.0.0.1:%s - ctrl+c to cancel\n" "${hubblecliport}"
            cilium hubble port-forward --port-forward "${hubblecliport}"
        ;;
        "")
            printf "Options are create full delete hubbleui hubblecli addpromstack grafanaui promui\n"
        ;;
    esac
}

main "${@}"
