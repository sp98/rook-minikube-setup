#!/bin/bash -e

# STEP 1 - Build LSO image
cd ~/go/src/github.com/openshift/local-storage-operator

# Delete existing LSO operator and Diskmaker images
docker image rm -f quay.io/sp1098/lso:latest quay.io/sp1098/local-diskmaker:latest quay.io/sp1098/sp1098-index:v1 quay.io/sp1098/local-storage-bundle:v1

./hack/sync_bundle -o quay.io/sp1098/lso:latest -d quay.io/sp1098/local-diskmaker:latest  -b quay.io/sp1098/local-storage-bundle:v1  -i quay.io/sp1098/sp1098-index:v1  bundle


sed -i "s/quay.io\/gnufied\/gnufied-index:1.0.0/quay.io\/sp1098\/sp1098-index:v1/" ./examples/olm/catalog-create-subscribe.yaml

oc create -f ./examples/olm/catalog-create-subscribe.yaml
