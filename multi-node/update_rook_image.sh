#!/bin/bash -e

# Update Rook Image in existing rook clusters.
# 1. Delete existing images on all nodes.
# 2. Build new local image.
# 3. Copy new build to all nodes

LOCAL_ROOK_IMAGE=quay.io/sp1098/rook:local

minikube ssh -n m02 -- docker image rm -f $LOCAL_ROOK_IMAGE
minikube ssh -n m03 -- docker image rm -f $LOCAL_ROOK_IMAGE
minikube ssh -- docker image rm -f $LOCAL_ROOK_IMAGE

echo "**** Build new LSO image ****"
cd ~/go/src/github.com/rook/rook
for i in {1..5}; do make IMAGES="ceph" build && break || sleep 10; done

docker tag build-b11aa2f7/ceph-amd64:latest $LOCAL_ROOK_IMAGE

function copy_image_to_cluster(){
    local build_image=$1
    minikube image load "${build_image}"
}

function copy_images_to_minikube() {
      echo "**** copying rook image to minikube cluster ****"
      copy_image_to_cluster $LOCAL_ROOK_IMAGE
}

function sed_changes() {
      echo "**** updating manifest files in ceph directory ****"
      echo "**** change rook image name ****"
      sed -i "s/docker.io\/rook\/ceph:master/quay.io\/sp1098\/rook:local/" ./operator.yaml
}

cd ~/go/src/github.com/rook/rook/deploy/examples

sed_changes
copy_images_to_minikube


echo "**** Apply common ****"
kubectl create -f common.yaml


echo "**** Apply crds ****"
#kubectl create -f pre-k8s-1.16/crds.yaml
kubectl create -f crds.yaml

echo "**** Starting Rook Operator ****"
kubectl create -f operator.yaml

while [[ $(kubectl get pods -l app=rook-ceph-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n rook-ceph) != "True" ]]; do echo "waiting for rook operator pod" && sleep 5; done
OperatorPOD=$(kubectl get pod -l app=rook-ceph-operator -o custom-columns=:metadata.name -n rook-ceph)

echo "**** Creating Toolbox ****"
kubectl apply -f toolbox.yaml

if [ "$1" == "OSD_ON_DEVICE" ]; then
echo "**** Creating ceph Cluster with OSD on Devices ****"
# cd /home/sapillai/scripts/rook-minikube-setup/single-node
# kubectl create -f cluster_metadata.yaml  --validate=false
kubectl create -f cluster-test.yaml  --validate=false
fi

if [ "$1" == "OSD_ON_PVC" ]; then
echo "**** Creating ceph Cluster with OSD on PVC ****"
cd /home/sp/scripts/rook-minikube-setup/single-node
kubectl create -f cluster-on-local-pvc.yaml
# kubectl create -f cluster_kms_vault.yaml
fi

echo "*** Successfully install Rook (OSD on devices) on Minikube Cluster ****"

echo "*** watching rook operator logs ****"
kubectl logs --follow $OperatorPOD -n rook-ceph
