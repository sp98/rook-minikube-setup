#!/bin/bash -e

echo "*** Installing Rook on Devices on a local Minikube environment ***"

echo "**** deleting existing images ****"
docker image rm -f build-8df2d0f4/ceph-amd64:latest
docker image rm -f quay.io/sp1098/rook:local

#CephImage="quay.io/ceph/ceph:v17.2.6"
# CephImage="quay.io/ceph/ceph:v18.2.2"
# CephImage="quay.ceph.io/ceph-ci/ceph:wip-athakkar-testing-2023-12-08-1309"
# cephImage="quay.io/guits/ceph-volume:bs-rdr"
cephImage="quay.ceph.io/ceph-ci/ceph:wip-aclamk-bs-compression-recompression-test"
# CephImage="quay.ceph.io/ceph-ci/ceph:wip-aclamk-os-bluestore-rdr-quincy"
# CephImage="quay.io/guits/ceph-volume:bs-rdr"
# CephImage="quay.ceph.io/ceph-ci/ceph:wip-aclamk-os-bluestore-rdr-quincy"
DefaultCSIPluginImage="quay.io/cephcsi/cephcsi:v3.11.0"
DefaultRegistrarImage="registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.10.0"
DefaultProvisionerImage="registry.k8s.io/sig-storage/csi-provisioner:v4.0.0"
DefaultAttacherImage="registry.k8s.io/sig-storage/csi-attacher:v4.5.0"
DefaultSnapshotterImage="registry.k8s.io/sig-storage/csi-snapshotter:v7.0.1"
DefaultResizerImage="registry.k8s.io/sig-storage/csi-resizer:v1.10.0"
DefaultVolumeReplicationImage="quay.io/csiaddons/k8s-sidecar:v0.8.0"

function pull_dependent_images(){
    if [[ "$(docker images -q ${DefaultCSIPluginImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultCSIPluginImage
    fi

    if [[ "$(docker images -q ${DefaultRegistrarImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultRegistrarImage
    fi

    if [[ "$(docker images -q ${DefaultProvisionerImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultProvisionerImage
    fi

    if [[ "$(docker images -q ${DefaultAttacherImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultAttacherImage
    fi

    if [[ "$(docker images -q ${DefaultSnapshotterImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultSnapshotterImage
    fi

    if [[ "$(docker images -q ${DefaultResizerImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultResizerImage
    fi

    if [[ "$(docker images -q ${DefaultVolumeReplicationImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultVolumeReplicationImage
    fi

    if [[ "$(docker images -q ${CephImage} 2> /dev/null)" == "" ]]; then
          docker pull $CephImage
    fi
}

pull_dependent_images


echo "**** Build new rook image ****"
cd ~/go/src/github.com/rook/rook
for i in {1..5}; do make IMAGES="ceph" build && break || sleep 10; done

docker tag build-8df2d0f4/ceph-amd64:latest quay.io/sp1098/rook:local

function copy_image_to_cluster(){
    local build_image=$1
    local final_image=$2
    docker save "${build_image}" | (eval "$(minikube docker-env --shell bash)" && docker load)
}

# && docker tag "${build_image}" "${final_image}"


function copy_images_to_minikube() {
      echo "**** copying rook image to minikube cluster ****"
      copy_image_to_cluster quay.io/sp1098/rook:local


      echo "**** copying ceph image to minikube cluster ****"
      copy_image_to_cluster $CephImage

      echo "**** copying ceph dependencies ****"
      copy_image_to_cluster $DefaultCSIPluginImage
      copy_image_to_cluster $DefaultRegistrarImage
      copy_image_to_cluster $DefaultProvisionerImage
      copy_image_to_cluster $DefaultAttacherImage
      copy_image_to_cluster $DefaultSnapshotterImage
      copy_image_to_cluster $DefaultResizerImage
      copy_image_to_cluster $DefaultVolumeReplicationImage
}

function sed_changes() {
      echo "**** updating manifest files in ceph directory ****"
      sed -i "s/rook\/ceph:master/quay.io\/sp1098\/rook:local/" ./operator.yaml
      sed -i "s/allowMultiplePerNode: false/allowMultiplePerNode: true/" ./cluster.yaml
      if [ "$2" == "OSD_ON_DEVICE" ]; then
            echo "**** change rook image name ****"
      #      sed -i "s/rook\/ceph:master/quay.io\/sp1098\/rook:local/" ./operator.yaml
           sed -i "s/allowMultiplePerNode: false/allowMultiplePerNode: true/" ./cluster/examples/kubernetes/ceph/cluster.yaml
      fi

       if [ "$2" == "OSD_ON_PVC" ]; then
           sed -i "s/allowMultiplePerNode: false/allowMultiplePerNode: true/" ./cluster-on-pvc.yaml
           sed -i "s/storageClassName: gp2/storageClassName: foobar/" ./cluster-on-pvc.yaml
      #      sed -i "s/count: 3/count: 1/2" ./cluster/examples/kubernetes/ceph/cluster-on-pvc.yaml
      fi

      #sed -i "s/image: rook\/ceph:master/image: sp1098\/rook-test:latest/" ./cluster/examples/kubernetes/ceph/operator.yaml
}


echo "**** Deploying Rook Cluster ****"
cd ~/go/src/github.com/rook/rook/deploy/examples

# update rook ceph manifest files to use local builds etc.
sed_changes "$2"

# copy relevant images to minikube/Kind cluster to save time in downloading these images inside the cluster.

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
kubectl create -f cluster.yaml  --validate=false
fi

if [ "$1" == "OSD_ON_PVC" ]; then
echo "**** Creating ceph Cluster with OSD on PVC ****"
cd /home/sapillai/scripts/rook-minikube-setup/single-node
kubectl create -f cluster-on-local-pvc.yaml
# kubectl create -f cluster_kms_vault.yaml
fi

echo "*** Successfully install Rook (OSD on devices) on Minikube Cluster ****"

echo "*** watching rook operator logs ****"
kubectl logs --follow $OperatorPOD -n rook-ceph
