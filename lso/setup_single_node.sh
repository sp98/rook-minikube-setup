#!/bin/bash -e

cd ~/go/src/github.com/openshift/local-storage-operator



# Update operator.yaml file to use correct local images using "sed"
function sed_changes() {
    sed -i "s/local-storage-operator:/lso:/" ./Makefile
    sed -i "s/quay.io\/openshift\/origin-local-storage-operator/quay.io\/sp1098\/lso/" ./config/manager/manager.yaml
    sed -i "s/quay.io\/openshift\/origin-local-storage-diskmaker/quay.io\/sp1098\/local-diskmaker/" ./config/manager/manager.yaml
}

# Push images to minikube
function copy_image_to_cluster() {
    local build_image=$1
    local final_image=$2
    docker save "${build_image}" | (eval "$(minikube docker-env --shell bash)" && docker load && docker tag "${build_image}" "${final_image}")
}

function copy_images() {
      echo "copying lso images"
      copy_image_to_cluster quay.io/sp1098/lso quay.io/sp1098/lso
      copy_image_to_cluster quay.io/sp1098/local-diskmaker quay.io/sp1098/local-diskmaker
      #copy_image_to_cluster quay.io/openshift/origin-local-storage-static-provisioner quay.io/openshift/origin-local-storage-static-provisioner
}

 sed_changes

# Build new LSO images
if [ "$1" == "NEW_BUILD" ]; then

    sed_changes

    # Create Env Variables.
    export REGISTRY=quay.io/sp1098/

    # Delete existing LSO operator and Diskmaker images
    docker image rm -f quay.io/sp1098/lso quay.io/sp1098/local-diskmaker

    # Create LSO operator and Diskmaker images.
    for i in {1..5}; do make images && break || sleep 5; done

    # Remove any dandling images
    docker images | grep none | awk '{ print $3; }' | xargs docker rmi -f

fi

# if [ "$2" == "PUSH_IMAGES" ]; then
#     make push-images
# fi


copy_images

# Start operator.yaml
kubectl create -f ./config/rbac/
kubectl create -f ./config/rbac/diskmaker/
kubectl create -f ./config/rbac/monitoring/
kubectl create -f ./config/crd/bases/
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumes.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumesets.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumediscoveries.yaml
# kubectl create -f ./config/crd/bases/local.storage.openshift.io_localvolumediscoveryresults.yaml
kubectl create -f ./config/manager/manager.yaml
