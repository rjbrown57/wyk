# Would you kindly? (Wyk)

* `./wyk` to create a kind cluster and install argo
* `./wyk addApps` to install metrics-server and vpa via argo
* `./wyk portForward` forward argo UI

## Harbor

* Add an alias via /etc/hosts for localhost to core.harbor.domain
* sudo kubectl port-forward service/harbor -n kube-system 443:443
* you can now push to harbor e.g. `docker push core.harbor.domain/library/nginx:latest`

## Links

* https://pkg.go.dev/sigs.k8s.io/kind/pkg/apis/config/v1alpha4
* https://kind.sigs.k8s.io/docs/user/quick-start/
* https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-kubectl-binary-with-curl-on-macos
* https://www.haproxy.com/documentation/kubernetes/latest/usage/ingress/
* https://learn.hashicorp.com/tutorials/vault/kubernetes-minikube
