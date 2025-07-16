#!/bin/bash -e

echo "*** Installing Rook on Devices on a local multinode Minikube environment ***"

echo "**** deleting existing images ****"
docker image rm -f build-b11aa2f7/ceph-amd64:latest
docker image rm -f quay.io/sp1098/rook:local

# CephImage="quay.ceph.io/ceph-ci/ceph:main"
CephImage="quay.io/ceph/ceph:v19.2.2"
# CephImage="quay.io/guits/ceph-volume:bs-rdr"


DefaultCSIPluginImage="quay.io/cephcsi/cephcsi:v3.12.0"
DefaultRegistrarImage="registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.11.1"
DefaultProvisionerImage="registry.k8s.io/sig-storage/csi-provisioner:v5.0.1"
DefaultAttacherImage="registry.k8s.io/sig-storage/csi-attacher:v4.6.1"
DefaultSnapshotterImage="registry.k8s.io/sig-storage/csi-snapshotter:v8.0.1"
DefaultResizerImage="registry.k8s.io/sig-storage/csi-resizer:v1.11.1"
DefaultCSIAddonsImage="quay.io/csiaddons/k8s-sidecar:v0.9.1"

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

    if [[ "$(docker images -q ${DefaultCSIAddonsImage} 2> /dev/null)" == "" ]]; then
          docker pull $DefaultCSIAddonsImage
    fi

    if [[ "$(docker images -q ${CephImage} 2> /dev/null)" == "" ]]; then
          docker pull $CephImage
    fi
}

# pull_dependent_images

echo "**** Build new rook image ****"
cd ~/go/src/github.com/rook/rook
for i in {1..5}; do make IMAGES="ceph" build && break || sleep 10; done

docker tag build-b11aa2f7/ceph-amd64:latest quay.io/sp1098/rook:local
docker image push quay.io/sp1098/rook:local

function copy_image_to_cluster(){
    local build_image=$1
    minikube image load "${build_image}"
}

function copy_images_to_minikube() {
      echo "**** copying rook image to minikube cluster ****"
      copy_image_to_cluster quay.io/sp1098/rook:local
      # copy_image_to_cluster rook/ceph:master

      echo "**** copying ceph image to minikube cluster ****"
      copy_image_to_cluster $CephImage

      echo "**** copying ceph dependencies ****"
      copy_image_to_cluster $DefaultCSIPluginImage
      copy_image_to_cluster $DefaultRegistrarImage
      copy_image_to_cluster $DefaultProvisionerImage
      copy_image_to_cluster $DefaultAttacherImage
      copy_image_to_cluster $DefaultSnapshotterImage
      copy_image_to_cluster $DefaultResizerImage
      copy_image_to_cluster $DefaultCSIAddonsImage
}

function sed_changes() {
      echo "**** updating manifest files in ceph directory ****"

      echo "**** change rook image name ****"
      sed -i "s/docker.io\/rook\/ceph:master/quay.io\/sp1098\/rook:local/" ./operator.yaml

      if [ "$2" == "OSD_ON_PVC" ]; then
           echo "**** change storage class name ****"
           sed -i "s/storageClassName: gp2/storageClassName: local-storage/" ./cluster-on-pvc.yaml
      fi
}


echo "**** Deploying Rook Cluster ****"
cd ~/go/src/github.com/rook/rook/deploy/examples

# update rook ceph manifest files to use local builds etc.
sed_changes "$2"

# copy relevant images to minikube/Kind cluster to save time in downloading these images inside the cluster.

# copy_images_to_minikube


echo "**** Apply common ****"
kubectl create -f common.yaml


echo "**** Apply crds ****"
#kubectl create -f pre-k8s-1.16/crds.yaml
kubectl create -f crds.yaml

echo "**** Install Prometheus operator ****"
# kubectl create -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.71.1/bundle.yaml
# kubectl create -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.81.0/bundle.yaml -n rook-ceph

# while [[ $(kubectl get pods -l  app.kubernetes.io/name=prometheus-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for prometheus operator pod" && sleep 5; done
# kubectl create -f ./monitoring/rbac.yaml
# kubectl create -f ./monitoring/localrules.yaml
# kubectl create -f ./monitoring/prometheus-service.yaml
# kubectl create -f ./monitoring/prometheus.yaml

# while [[ $(kubectl get pods -n rook-ceph -l  app.kubernetes.io/name=prometheus  -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for prometheus instance to be running" && sleep 5; done
echo "**** Starting Rook Operator ****"
kubectl create -f operator.yaml

while [[ $(kubectl get pods -l app=rook-ceph-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n rook-ceph) != "True" ]]; do echo "waiting for rook operator pod" && sleep 5; done
OperatorPOD=$(kubectl get pod -l app=rook-ceph-operator -o custom-columns=:metadata.name -n rook-ceph)

echo "**** Creating Toolbox ****"
kubectl apply -f toolbox-operator-image.yaml


if [ "$1" == "OSD_ON_DEVICE" ]; then
echo "**** Creating ceph Cluster with OSD on Devices ****"
kubectl create -f cluster.yaml  --validate=false
fi

if [ "$1" == "OSD_ON_PVC" ]; then
echo "**** Creating ceph Cluster with OSD on PVC ****"
cd /home/sp/scripts/rook-minikube-setup/multi-node
kubectl create -f cluster-on-pvc3.yaml
fi

echo "*** Successfully install Rook (OSD on devices) on Minikube Cluster ****"

echo "*** watching rook operator logs ****"
kubectl logs --follow $OperatorPOD -n rook-ceph
