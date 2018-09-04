#!/bin/bash

# Load e2e config file
set -a
set -e
source $1
set +a

# check mandatory variables
[ -z "$GOPATH" ] && echo "Need GOPATH for plugin build and test executions(e.g export GOPATH=\path\to)" && exit 1

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/scripts
. $SCRIPT_DIR/common.sh


# Do a bx login, user can also opt to skip this during dev-test
if [[ $TEST_BLUEMIX_LOGIN == "true" ]]; then
	bx_login
fi

# Incase of cluster_create value is "ifNotFound", then use the existing cluster (if there is one)
cluster_id=$(bx cs clusters | awk "/$PVG_CLUSTER_CRUISER/"'{print $2}')

# incase of cluster_create "always", delete the PREV cluster (if any)
if [[ -n "$cluster_id" && "$TEST_CLUSTER_CREATE" == "always" ]]; then
	# Delete the PVG_CLUSTER_CRUISER if it exists
	set +e
	rm_cluster $PVG_CLUSTER_CRUISER
	check_cluster_deleted $PVG_CLUSTER_CRUISER
	cluster_id=""
	set -e
fi

# Create cluster only if cluster is deleted/not found
if [[ -z "$cluster_id" && "$TEST_CLUSTER_CREATE" != "never" ]]; then

	# Create a cruiser
	cruiser_create $PVG_CLUSTER_CRUISER u1c.2x4 1
	
	# Put a small delay to let things settle
	sleep 30
	
	bx cs clusters
	
	# Verify cluster is up and running
	echo "Checking the cluster for deployed state..."
	check_cluster_state $PVG_CLUSTER_CRUISER
	
	echo "Checking the workers for deployed state..."
	check_worker_state $PVG_CLUSTER_CRUISER
	
	# Run sniff tests against cluster
	bx cs clusters
	bx cs cluster-get $PVG_CLUSTER_CRUISER
	bx cs workers $PVG_CLUSTER_CRUISER
	
	echo "Cluster creation is successful and ready to use"
fi

# Setup the kube configs, user can also opt to skip this during dev-test
if [[ $TEST_CLUSTER_CONFIG_DOWNLOAD == "true" ]]; then
	setKubeConfig $PVG_CLUSTER_CRUISER
	cat $KUBECONFIG
	echo "Kubeconfig file download was successful"
fi

# Update certpath from relative to full path, without which the golang test fail
addFullPathToCertsInKubeConfig
cat $KUBECONFIG
echo "Kubeclient has been configured successfully to access the cluster"

# Build Latest plugin images (if configured), otherwise use the existing one specified in conf
#if [[ $TEST_LATEST_IMAGE_BUILD == "true" ]]; then
#	cd $BLOCK_PLUGIN_HOME
#	make plugin-build-e2e
#	echo "Image build was successful"
#fi

# Install helm chart (if configured). During dev-test, user might skip this, if doesn't want an override
if [[ $TEST_HELM_INSTALL == "true" ]]; then
	install_block_plugin
	check_deployment_state "ibmcloud-block-storage-plugin" 
	#check_daemonset_state "ibmcloud-block-storage-driver"
fi

# Build binary (if configured), Otherwise conf must have the binary file location
if [[ $TEST_CODE_BUILD == "true" ]]; then
	cd $BLOCK_PLUGIN_HOME
	make test-binary-build-e2e
	echo "E2E test binary was created successfully"
fi

echo "Starting ibmcloud block storage plugin e2e tests "
# Call the go binary
$E2E_TEST_BINARY -kubeconfig $KUBECONFIG
echo "Finished ibmcloud block storage plugin e2e tests"

exit 0