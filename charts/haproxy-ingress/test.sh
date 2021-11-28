#!/bin/bash

printf "Create nginx deployment\n"
kubectl --namespace default create deployment nginx --image nginx:latest
printf "Expose nginx deployment\n"
kubectl --namespace default expose deployment nginx --port=80

printf "Create nginx ingress\n"
kubectl apply -f ./charts/haproxy-ingress/ingress.yaml

#curl -k https://echoserver.local:30101