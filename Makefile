
#/*******************************************************************************
# * Licensed Materials - Property of IBM
# * IBM Cloud Container Service, 5737-D43
# * (C) Copyright IBM Corp. 2017, 2018 All Rights Reserved.
# * US Government Users Restricted Rights - Use, duplication or
# * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# ******************************************************************************/

IMAGE = registry.ng.bluemix.net/akgunjal/armada-block-volume-attacher
#registry.ng.bluemix.net/akgunjal/armada-storage-portworx-volume-attacher
#armada-master/armada-storage-portworx-volume-attacher
VERSION := latest
SYSTEMUTIL_DIR=vendor/github.ibm.com/alchemy-containers/ibmc-storage-common-resources-lib

.PHONY: all
all: driver

.PHONY: driver
driver: deps buildgo buildimage

.PHONY: deps
deps:
	echo "Installing dependencies ..."
	glide install --strip-vendor

.PHONY: buildgo
buildgo:
	GOOS=linux GOARCH=amd64 go build

.PHONY: build-driver-image
buildimage:
	$(MAKE) -C $(SYSTEMUTIL_DIR) build-systemutil
	cp $(SYSTEMUTIL_DIR)/systemutil images/
	docker build -t $(IMAGE):$(VERSION) -f Dockerfile .
#	cd images/ ;\
#	docker build -t $(IMAGE):$(VERSION) -f Dockerfile .
#        --build-arg git_commit_id=${GIT_COMMIT_SHA} \
#        --build-arg git_remote_url=${GIT_REMOTE_URL} \
#        --build-arg build_date=${BUILD_DATE} \
#        --build-arg jenkins_build_id=${BUILD_ID} \
#        --build-arg jenkins_build_number=${BUILD_NUMBER} \
#				--build-arg this_build_id=https://travis.ibm.com/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID} \
#	 -t $(IMAGE):$(VERSION) -f ./images/Dockerfile .

