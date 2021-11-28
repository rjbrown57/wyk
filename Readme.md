# Would you kindly? (Wyk)

configureable Kind development set ups

* Prometheus -> https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
  * Add configuration to disable parts of stack via values.yaml overrides
  * Grafana login 
* Prom Push Gateway
  * Still needs configuration to end up in prometheus
* Vault

## To Do
Convert to golang and render kind config via template. Turn on ports for appropriate charts as requested by config file.

### Cilium
Will mutate kind config to disable default cni

### Opa Gatekeer
Deploy OPA gatekeeper for policy development

### Ingress 
Choose an ingress solution and hopefully get rid of extraPortMappings in kind config. Some progress with HaProxy but it's not directing traffic unless host is set to "*"

## Links

* https://pkg.go.dev/sigs.k8s.io/kind/pkg/apis/config/v1alpha4
* https://kind.sigs.k8s.io/docs/user/quick-start/
* https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-kubectl-binary-with-curl-on-macos
* https://www.haproxy.com/documentation/kubernetes/latest/usage/ingress/
* https://learn.hashicorp.com/tutorials/vault/kubernetes-minikube
