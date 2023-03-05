# Would you kindly? (Wyk)

a shell script + config file to quickly create a cilium based kind cluster. Use https://github.com/rjbrown/binman to fetch required deps. Adjust the number of workers by editing the "cilium.config" file

* `./wyk create` to create a kind cluster with cilium cni
* `./wyk delete` to delete
* `./wyk hubbleui` to portforward hubble ui default port 12000
* `./wyk hubblecli` to portforward hubble cli default port 4245
