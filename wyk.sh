#!/bin/bash

kindConfig="./cilium.config"

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


# https://github.com/cilium/charts
# https://docs.cilium.io/en/v1.13/installation/kind/

main() {
    case "${1}" in 
        "create")
            kindCreate
        ;;
        "delete")
            kind delete clusters kind
        ;;
        "hubbleui") 
	    printf "Portforwarding hubble ui to 127.0.0.1:%s - ctrl+c to cancel\n" "${hubbleuiport}"
            cilium hubble ui --port-forward "${hubbleuiport}"
        ;;
        "hubblecli") 
	    printf "Portforwarding hubble port-forward to 127.0.0.1:%s - ctrl+c to cancel\n" "${hubblecliport}"
            cilium hubble port-forward --port-forward "${hubblecliport}"
	;;
        "")
            printf "Options are create delete hubbleui hubblecli\n"
        ;;
    esac
}

main "${@}"
