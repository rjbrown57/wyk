# KCAPI 

This repo contains a make file for experimenting with CAPI.

* https://cluster-api.sigs.k8s.io/user/quick-start

* Can deploy two flavors of Bootstrap/Control Plane provider

| Component     | Provider(s) |
| ------------- | ------ |
| InfraProvider | docker |
| ControlPlaneProvider | kubeadm,rke2 |
| BootstrapProvider | kubeadm,rke2 |

## Steps

To deploy from scratch run the following steps

* make create-mgmt-cluster
* make setup-capi
* make add-cluster
* make get-config # Set kubeconfig
* make install-cni

At this point 2 node k8s cluster should be up. You can view this with `clusterctl describe cluster capi1` with the management cluster as your active context

## Links

* https://cluster-api.sigs.k8s.io/user/quick-start
* https://caprke2.docs.rancher.com/
* https://github.com/kubernetes-sigs/cluster-api/tree/main/test/infrastructure/docker