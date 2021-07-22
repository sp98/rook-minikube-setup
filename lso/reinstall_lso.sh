#!/bin/bash -e

# Update Rook Image in existing rook clusters.
# 1. Delete LSO manifests.
# 1. Delete all PVs
# 1. Clean symlink directory
# 1. Delete existing images on all nodes.
# 2. Build new local image.
# 3. Copy new build to all nodes

echo "clean up LSO cluster"

cd ~/go/src/github.com/openshift/local-storage-operator


kubectl delete -f ./config/manager/manager.yaml
kubectl delete -f ./config/crd/bases/
kubectl delete -f ./config/rbac/
kubectl delete -f ./config/rbac/diskmaker/
kubectl delete -f ./config/rbac/monitoring/

sleep 10s

echo "Deleting local pvs if any"
SC="local"
oc get pv | grep $SC | awk '{print $1}'| xargs kubectl delete pv

echo "Deleting storage class"
oc delete sc $SC

echo "Deleting symlink dirs if any"
    minikube ssh -n m02 -- sudo rm -rf /mnt/local-storage/${SC}/
minikube ssh -n m03 -- sudo rm -rf /mnt/local-storage/${SC}/
minikube ssh -n m04 -- sudo rm -rf /mnt/local-storage/${SC}/

echo "Deleting existing images in minikube"
LOCAL_DISMAKER_IMAGE=quay.io/sp1098/local-diskmaker
LOCAL_LSO_IMAGE=quay.io/sp1098/lso

minikube ssh -n m02 -- docker image rm -f $LOCAL_DISMAKER_IMAGE $LOCAL_LSO_IMAGE
minikube ssh -n m03 -- docker image rm -f $LOCAL_DISMAKER_IMAGE $LOCAL_LSO_IMAGE
minikube ssh -n m04 -- docker image rm -f $LOCAL_DISMAKER_IMAGE $LOCAL_LSO_IMAGE


function sed_changes() {
    sed -i "s/local-storage-operator:/lso:/" ./Makefile
    sed -i "s/quay.io\/openshift\/origin-local-storage-operator/quay.io\/sp1098\/lso/" ./config/manager/manager.yaml
    sed -i "s/quay.io\/openshift\/origin-local-storage-diskmaker/quay.io\/sp1098\/local-diskmaker/" ./config/manager/manager.yaml
}


# Push images to minikube
function copy_image_to_cluster() {
    local build_image=$1
    local final_image=$2
    docker save "${build_image}" |  minikube ssh -n m02  docker load
    docker save "${build_image}" |  minikube ssh -n m03  docker load
    docker save "${build_image}" |  minikube ssh -n m04  docker load
    # docker save "${build_image}" | (eval "$(minikube docker-env --shell bash)" && docker load && docker tag "${build_image}" "${final_image}")
}

function copy_images() {
      echo "copying lso images"
      copy_image_to_cluster quay.io/sp1098/lso quay.io/sp1098/lso
      copy_image_to_cluster quay.io/sp1098/local-diskmaker quay.io/sp1098/local-diskmaker
}

sed_changes

# Create Env Variables.
export REGISTRY=quay.io/sp1098/

# Delete existing LSO operator and Diskmaker images
docker image rm -f quay.io/sp1098/lso quay.io/sp1098/local-diskmaker

# Create LSO operator and Diskmaker images.
for i in {1..5}; do make images && break || sleep 5; done

# Remove any dandling images
docker images | grep none | awk '{ print $3; }' | xargs docker rmi -f


sed_changes
copy_images


# Start operator.yaml
# Start operator.yaml
kubectl create -f ./config/rbac/
kubectl create -f ./config/rbac/diskmaker/
kubectl create -f ./config/rbac/monitoring/
kubectl create -f ./config/crd/bases/
kubectl create -f ./config/manager/manager.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumes.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumesets.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumediscoveries.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumediscoveryresults.yaml
