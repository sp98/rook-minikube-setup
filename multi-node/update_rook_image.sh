#!/bin/bash -e

# Update Rook Image in existing rook clusters.
# 1. Delete existing images on all nodes.
# 2. Build new local image.
# 3. Copy new build to all nodes

LOCAL_ROOK_IMAGE=quay.io/sp1098/rook:local

minikube ssh -n m02 -- docker image rm -f $LOCAL_ROOK_IMAGE
minikube ssh -n m03 -- docker image rm -f $LOCAL_ROOK_IMAGE
minikube ssh -n m04 -- docker image rm -f $LOCAL_ROOK_IMAGE

echo "**** Build new LSO image ****"
cd ~/go/src/github.com/rook/rook
for i in {1..5}; do make IMAGES="ceph" build && break || sleep 10; done

docker tag build-a69cca94/ceph-amd64:latest $LOCAL_ROOK_IMAGE

function copy_image_to_cluster(){
    local build_image=$1
    docker save "${build_image}" |  minikube ssh -n m02  docker load
    docker save "${build_image}" |  minikube ssh -n m03  docker load
    docker save "${build_image}" |  minikube ssh -n m04  docker load
}

function copy_images_to_minikube() {
      echo "**** copying rook image to minikube cluster ****"
      copy_image_to_cluster $LOCAL_ROOK_IMAGE
}

function sed_changes() {
      echo "**** updating manifest files in ceph directory ****"
      echo "**** change rook image name ****"
      sed -i "s/rook\/ceph:master/quay.io\/sp1098\/rook:local/" ./cluster/examples/kubernetes/ceph/operator.yaml
}
sed_changes
copy_images_to_minikube
