#!/bin/bash -e



INDEX_IMAGE=quay.io/sp1098/sp1098-index:test
BUNDLE=quay.io/sp1098/local-storage-bundle:bundle

# STEP 1 - Build LSO image
cd ~/go/src/github.com/openshift/local-storage-operator

# Delete existing LSO operator and Diskmaker images
docker image rm -f quay.io/sp1098/lso:test quay.io/sp1098/local-diskmaker:test quay.io/sp1098/lso quay.io/sp1098/local-diskmaker


# Update operator.yaml file to use correct local images using "sed"
function sed_changes() {
    sed -i "s/local-storage-operator:/lso:/" ./Makefile
    sed -i "s/quay.io\/openshift\/origin-local-storage-operator/quay.io\/sp1098\/lso/" ./config/manager/manager.yaml
    sed -i "s/quay.io\/openshift\/origin-local-storage-diskmaker/quay.io\/sp1098\/local-diskmaker/" ./config/manager/manager.yaml
    sed -i "s/quay.io\/openshift\/origin-local-storage-operator/quay.io\/sp1098\/lso/" ./opm-bundle/manifests/local-storage-operator.clusterserviceversion.yaml
    sed -i "s/quay.io\/openshift\/origin-local-storage-diskmaker/quay.io\/sp1098\/local-diskmaker/" ./opm-bundle/manifests/local-storage-operator.clusterserviceversion.yaml
    sed -i "s/quay.io\/gnufied\/gnufied-index:1.0.0/quay.io\/sp1098\/sp1098-index:test/" ./examples/olm/catalog-create-subscribe.yaml
}

sed_changes

# Create Env Variables.
export REGISTRY=quay.io/sp1098/

# Create LSO operator and Diskmaker images.
for i in {1..5}; do make images && break || sleep 5; done


# STEP 2- PUSH LSO IMAGES
make push-images
# Remove any dandling images
docker images | grep none | awk '{ print $3; }' | xargs docker rmi


STEP 3 - Edit LSO and diskmaker images in cluster service version.

cd opm-bundle

docker build -f ./bundle.Dockerfile -t $BUNDLE .

docker image push $BUNDLE

opm index add --bundles $BUNDLE --tag $INDEX_IMAGE --container-tool docker

docker image push $INDEX_IMAGE

cd ~/go/src/github.com/openshift/local-storage-operator

oc create -f ./examples/olm/catalog-create-subscribe.yaml
