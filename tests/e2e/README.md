# armada-storage-e2e

[![Build Status](https://travis.ibm.com/alchemy-containers/armada-storage-e2e.svg?token=ptbMq1PWtBZJZhvq3cph&branch=master)](https://travis.ibm.com/alchemy-containers/armada-storage-e2e)

This repo is for end2end testing of repo alchemy-containers/armada-storage-file-plugin

**Gate Dashboard**: https://ops.ibmcontainers.com/pvg/armada

**Bom File**: alchemy-containers/DevOps-Visualization-Enablement/blob/master/armada-bom.yml

**Armada-Ansible BOM file (for storage file plugin image version)**: alchemy-containers/armada-ansible/blob/master/common/bom/armada-ansible-bom.yml

**Jenkin Job for build and promotion of *storage file plugin* image**: https://alchemy-containers-jenkins.swg-devops.com:8443/job/Containers-Volumes/job/armada-storage-file-plugin/

## armada-storage-e2e on development environment (ex: devmex)

	***Get a 16.04 instance for the setup. Also, make sure you open a VPN connection to the environment from another session.***

1. Install go

	You need [go](https://golang.org/doc/install) in your path (see [here](development.md#go-versions) for supported versions), please make sure it is installed and in your ``$PATH``.
	
	```sh
	GO_VERSION=1.7.4
	curl -o go${GO_VERSION}.linux-amd64.tar.gz https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
	tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
	export GOPATH=<Go Path location>
	export PATH=/usr/local/go/bin:$PATH
	```
	
2. Installing CF CLI

	```sh
	wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
	echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
	
	apt-get update
	apt-get install cf-cli
	```
	
3. Installing Bluemix CLI

	```sh
	BLUEMIX_CLI_URL="http://ftp.icap.cdl.ibm.com/OERuntime/BluemixCLIs/CliProvider/bluemix-cli"
	export BM_CLI_LATEST=$(curl -sSL ${BLUEMIX_CLI_URL}/ | grep 'amd64' | grep 'tar.gz' | grep 'Bluemix_CLI_[0-9]' | tail -n 1 | sed -e 's/^.*href="//' -e 's/">.*//') \
	&& curl -s ${BLUEMIX_CLI_URL}/${BM_CLI_LATEST} | tar -xvz \
	&& cd Bluemix_CLI \
	&& ./install_bluemix_cli \
	&& bx config --check-version false \
	&& bx config --usage-stats-collect false \
	&& bx --version
	```
	
4. Install Bluemix containers and registry plugin

	```sh
	bx plugin repo-add stage https://plugins.stage1.ng.bluemix.net \
	&& bx plugin install cs -r stage \
	&& bx plugin install container-registry -r stage \
	&& bx plugin list
	```
	
5. Login to Bluemix CLI supplying your IBM ID and password. Select the appropriate organization (typically the same as your IBM ID). Note, selection of a space is not required.

	```sh
	Export the needed variables:
	
	export PVG_BX_USER=<>
	export PVG_BX_PWD=<>
	bx login -a https://api.stage1.ng.bluemix.net -u $PVG_BX_USER -p $PVG_BX_PWD -c alchstag@us.ibm.com -o AlchemyStaging -s pipeline
	```

6. Login to the Container Service plugin in the Bluemix CLI. Note you will be asked to supply your IBM ID (email) and password once again. This is known issue (see below).

	```sh
	#export ARMADA_API_ENDPOINT=<API Endpoint>
	bx cs init --host $ARMADA_API_ENDPOINT
	```
  
7. To provision a paid (cruiser) cluster run the following. The paid cluster provisions worker nodes (VMs) into your account. The number of worker nodes is based on the integer supplied in the --workers parameter. The paid size currently is an hourly, public, 2 core, 4GB VSI. 

	```sh
	# Before running this script, export the needed variables
	#export PVG_SL_USERNAME=<SL account user name>
	#export PVG_SL_API_KEY=<SL API Key>
	#export PVG_CRUISER_PRIVATE_VLAN=<Private VLAN>
	#export PVG_CRUISER_PUBLIC_VLAN=<Public VLAN>
	#export FREE_DATACENTER=<Datacenter name: mex01>
	#export PVG_CLUSTER_CRUISER=testcluster
	bx cs credentials-set --softlayer-username $PVG_SL_USERNAME --softlayer-api-key $PVG_SL_API_KEY
	# Create a cruiser
	bx cs cluster-create --name $PVG_CLUSTER_CRUISER --datacenter $FREE_DATACENTER \
	    --public-vlan $PVG_CRUISER_PUBLIC_VLAN --private-vlan $PVG_CRUISER_PRIVATE_VLAN \
	    --workers 3 --machine-type u1c.2x4
	```
	
8. To list your clusters run the following

	```
	bx cs clusters
	```
	Note: Wait for the cluster for getting the ready state
	
9. Set the kubeconfig

	```
	configfile=$(bx cs cluster-config $PVG_CLUSTER_CRUISER | grep ^export | cut -d '=' -f 2)
	export KUBECONFIG=$configfile
	```

10. Now, run the following commands to perform the e2e test execution.
	
	```
	cd $GOPATH/src/github.ibm.com/alchemy-containers/armada-storage-e2e
	export PVG_PHASE=armada-prestage
	sed -i "s/PVG_PHASE/"$PVG_PHASE"/g" common/constants.go
	export API_SERVER=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
	make KUBECONFIGPATH=$KUBECONFIG PVG_PHASE=$PVG_PHASE armada-storage-e2e-test
	
	Note: Remove the "exit 0" to avoid session logouts from the above two scripts.
	```
	
## armada-storage-e2e Local Setup [for k8s 1.6.*]

	***Get a Jupiter 16.04 instance for the setup.***

1. Docker

	At least [Docker](https://docs.docker.com/installation/#installation)
	1.10+. Ensure the Docker daemon is running and can be contacted (try `docker
	ps`).  Some of the Kubernetes components need to run as root, which normally
	works fine with docker.

2. etcd

	You need an [etcd](https://github.com/coreos/etcd/releases) in your path, please make sure it is installed and in your ``$PATH``.
	
	```sh
	ETCD_VER=v3.1.5
	
	# choose either URL
	GOOGLE_URL=https://storage.googleapis.com/etcd
	GITHUB_URL=https://github.com/coreos/etcd/releases/download
	DOWNLOAD_URL=${GOOGLE_URL}
	
	rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	rm -rf /tmp/test-etcd && mkdir -p /tmp/test-etcd
	
	curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/test-etcd --strip-components=1
	
	/tmp/test-etcd/etcd --version
	<<COMMENT
	etcd Version: 3.1.5
	Git SHA: 20490ca
	Go Version: go1.7.5
	Go OS/Arch: linux/amd64
	COMMENT
	
	ETCDCTL_API=3 /tmp/test-etcd/etcdctl version
	<<COMMENT
	etcdctl version: 3.1.5
	API version: 3.1
	COMMENT
	
	ln -s /tmp/test-etcd/etcd /usr/bin/etcd
	
	# start a local etcd server
	#/tmp/test-etcd/etcd
	
	# write,read to etcd
	#ETCDCTL_API=3 /tmp/test-etcd/etcdctl --endpoints=localhost:2379 put foo bar
	#ETCDCTL_API=3 /tmp/test-etcd/etcdctl --endpoints=localhost:2379 get foo
	```

3. Install go

	You need [go](https://golang.org/doc/install) in your path (see [here](development.md#go-versions) for supported versions), please make sure it is installed and in your ``$PATH``.
	
	```sh
	GO_VERSION=1.7.4
	curl -o go${GO_VERSION}.linux-amd64.tar.gz https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
	tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
	export GOPATH=<Go Path location>
	export PATH=/usr/local/go/bin:$PATH
	```

4. OpenSSL

	You need [OpenSSL](https://www.openssl.org/) installed.  If you do not have the `openssl` command available, the script will print an appropriate error.

5. CFSSL

	The [CFSSL](https://cfssl.org/) binaries (cfssl, cfssljson) must be installed and available on your ``$PATH``.
	
	The easiest way to get it is something similar to the following:
	
	```
	$ go get -u github.com/cloudflare/cfssl/cmd/...
	$ PATH=$PATH:$GOPATH/bin
	```

6. Download `kubectl`

	At this point you should have a running Kubernetes cluster. You can test it out
	by downloading the kubectl binary for `${K8S_VERSION}` (in this example: `{{page.version}}.0`).

  	Downloads:

	  - `linux/amd64`: http://storage.googleapis.com/kubernetes-release/release/{{page.version}}.0/bin/linux/amd64/kubectl
	
	  The generic download path is:
	
	```
	http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/${GOOS}/${GOARCH}/${K8S_BINARY}
	```
	
	  An example install with `linux/amd64`:
	
	```
	curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	mv ./kubectl /usr/local/bin/kubectl
	```

7. Clone the kubernetes repository of required version

	In order to run kubernetes you must have the kubernetes code on the local machine. Cloning this repository or downloading ZIP of specific version is sufficient.
	
	```sh
	$git clone https://github.com/kubernetes/kubernetes.git
	git checkout <commit hash of version>
	for example to checkout 1.6.1 version: git checkout b0b7a323cc5a4a2019b2e9520c21c7830b7f708e
	
	```
8. Starting the cluster

	In a separate tab of your terminal, run the following (since one needs sudo access to start/stop Kubernetes daemons, it is easier to run the entire script as root):
	
	```sh
	cd kubernetes
	hack/local-up-cluster.sh
	```
	
	This will build and start a lightweight local cluster, consisting of a master and a single node. Type Control-C to shut it down.
	
9. Test it out

	To start using your cluster, you can open up another terminal/tab and run:
	
	```sh
	export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
	kubectl get nodes
	```
	
	This should print:
	
	```sh
	NAME        STATUS    AGE
	127.0.0.1   Ready     1h
  	```

10. Once the cluster is ready, use the following ReadMe and attach the storage plugin to cluster.
	
	[Attach the storage plugin to cluster] (https://github.ibm.com/alchemy-containers/armada-storage-file-plugin/blob/master/deploy/README_FOR_CRUISER.md)


13. Download the source code of e2e git.

	```sh
	go get github.ibm.com/alchemy-containers/armada-storage-e2e
	cd $GOPATH/src/github.ibm.com/alchemy-containers/armada-storage-e2e
	``` 

13. Now, run the following commands to perform the e2e test execution (in another terminal).
	**Make sure kuneconfig gile has absolute paths**
	```sh
	make KUBECONFIGPATH=/var/run/kubernetes/admin.kubeconfig armada-storage-e2e-test
	```

## Debugging storage plugin in gates

1. Export the needed variables

	```sh
	export PVG_BX_USER=<>
	export PVG_BX_PWD=<>
	export ARMADA_API_ENDPOINT=https://api-prestage.cont.bluemix.net
	export PVG_BX_DASH_S=<>
	export PVG_BX_DASH_O=<>
	export PVG_BX_DASH_C=<>
	export PVG_BX_DASH_A=https://api.stage1.ng.bluemix.net
	```

2. Login to bluemix

	```sh
	bx login -a $PVG_BX_DASH_A -u $PVG_BX_USER -p $PVG_BX_PWD -c $PVG_BX_DASH_C -o $PVG_BX_DASH_O -s $PVG_BX_DASH_S
	bx cs init --host $ARMADA_API_ENDPOINT
	```

3. List the clusters

	```sh
	bx cs clusters
	```
	
4. Set the needed cluster name to PVG_CLUSTER_CRUISER

	```sh
	PVG_CLUSTER_CRUISER=<>
	```

5. Get cluster and worker details

	```sh
	bx cs cluster-get $PVG_CLUSTER_CRUISER
	bx cs workers $PVG_CLUSTER_CRUISER
	```

6. Extract cluster config details and export it

	```sh
	configfile=$(bx cs cluster-config $PVG_CLUSTER_CRUISER | grep ^export | cut -d '=' -f 2)
	cat $configfile
	export KUBECONFIG=$configfile
	```
	
7. Get the pod details of cluster

	```sh
	kubectl get pods -n kube-system
	```

8. Get the logs of stroage plugin pod

	```sh
	kubectl  logs <Storage Plugin Pod ID> -n kube-system
	```

## Known issues/Trouble shooting

1. If you see following error in stroage pod logs, it means storage pod is not able to talk to SoftLayer API. It must be a networking issue. Post the error in #armada-gates channel.

	```sh
	{"level":"error","ts":"2017-03-10T16:52:58Z","msg":"http_client_basic.go:89: Error occurred","error":"Get https://1186049_contdep%40us.ibm.com:XXXXX@api.softlayer.com/rest/v3/SoftLayer_Location_Datacenter/getDatacenters: dial tcp: lookup api.softlayer.com on 10.10.10.10:53: dial udp 10.10.10.10:53: i/o timeout"}
	{"level":"error","ts":"2017-03-10T16:52:58Z","msg":"http_client_basic.go:89: Error occurred","error":"Get https://1186049_contdep%40us.ibm.com:XXXXX@api.softlayer.com/rest/v3/SoftLayer_Location_Datacenter/getDatacenters: dial tcp: lookup api.softlayer.com on 10.10.10.10:53: dial udp 10.10.10.10:53: i/o timeout"}
	```

2. If e2e tests logs has the following entries, it must be SoftLayer account quota issue. Post the error in #armada-gates channel or clean the file shares of account `https://1186049_contdep@us.ibm.com` using our container volumes utils script.

	```sh
	Storage creation failed with error: Your order will exceed the maximum number of storage volumes allowed. Please contact Sales.
	```

## Vagrant setup for testing latest stroage plugin

	Refer this: https://github.ibm.com/alchemy-containers/armada-ansible#deploying
