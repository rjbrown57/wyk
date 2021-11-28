#!/bin/bash

kindConfig="./kind.config"
chartDir="./charts/"

# V1 bash version

# Create cluster
kindCreate() {
    sudo kind create cluster --config=${kindConfig}
}

# https://haproxy-ingress.github.io/docs/getting-started/

#export 
#kubectl --namespace ingress-controller port-forward $POD_NAME 8080:80
#echo "Visit http://127.0.0.1:8080 to access your application."

# Test Ingress with
#$ kubectl --namespace default create deployment echoserver --image k8s.gcr.io/echoserver:1.3
#$ kubectl --namespace default expose deployment echoserver --port=8080
# kubectl --namespace default create ingress echoserver\
#  --annotation kubernetes.io/ingress.class=haproxy\
#  --rule="echoserver.local/*=echoserver:8080"

installVPA() {
  helm upgrade --install metrics-server charts/metrics-server 
  helm upgrade --install vpa charts/vpa 
}

installHAProxy() {
  helm upgrade --install haproxy-ingress charts/haproxy-ingress\
  --create-namespace --namespace ingress-controller\
  --version 0.13.4
}

installKubeProm() {
  helm upgrade --install kube-prom charts/kube-prometheus-stack\
  --create-namespace --namespace prom

  helm upgrade --install prom-adapter charts/prometheus-adapter -n prom

  helm upgrade --install pg charts/prometheus-pushgateway\
  --namespace prom
}

installVault() {
  helm upgrade --install vault charts/vault\
  --create-namespace --namespace vault
}

portForward() {
    kubectl -n vault port-forward service/vault 38200:8200 &
    kubectl port-forward -n prom service/kube-prom-kube-prometheus-prometheus 39090:9090 &
    kubectl port-forward -n prom service/pg-prometheus-pushgateway 39091:9091 &
    kubectl port-forward -n prom service/kube-prom-kube-prometheus-alertmanager 39093:9093 &
    kubectl port-forward -n prom service/kube-prom-grafana 32080:80 &   
    printf "Return to end port-forward\n"
    read hold
    pkill -i kubectl
}

main() {
    case "${1}" in 
        "" | "fullinstall")
            kindCreate
            #installHAProxy
            installVPA
            installKubeProm
            #installVault
        ;;
        "postinstall")
            installHAProxy
            installKubeProm
            installVault        
        ;;
        "portforward")
            portForward
        ;;
        "delete")
            kind delete clusters kind
    esac
}

main "${@}"
