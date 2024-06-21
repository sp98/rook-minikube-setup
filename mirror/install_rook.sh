#!/bin/bash -e

echo "*** Installing Rook on Devices on a local Minikube environment with profile $PROFILE ***"

RookImage="quay.io/sp1098/rook:local"
# CephImage="quay.io/ceph/ceph:v18.2.1"
CephImage="quay.ceph.io/ceph-ci/ceph:wip-nbalacha-rbd-consistency-groups"
DefaultCSIPluginImage="quay.io/cephcsi/cephcsi:v3.11.0"
DefaultRegistrarImage="registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.10.1"
DefaultProvisionerImage="registry.k8s.io/sig-storage/csi-provisioner:v4.0.1"
DefaultAttacherImage="registry.k8s.io/sig-storage/csi-attacher:v4.5.1"
DefaultSnapshotterImage="registry.k8s.io/sig-storage/csi-snapshotter:v7.0.2"
DefaultResizerImage="registry.k8s.io/sig-storage/csi-resizer:v1.10.1"
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


# build new rook image if its not present
if [[ "$(docker images -q ${RookImage} 2> /dev/null)" == "" ]]; then
        echo "**** Build new rook image ****"
        cd ~/go/src/github.com/rook/rook
        for i in {1..5}; do make IMAGES="ceph" build && break || sleep 10; done

        docker tag build-8df2d0f4/ceph-amd64:latest quay.io/sp1098/rook:local
fi



function copy_image_to_cluster(){
    local build_image=$1
    local final_image=$2
    docker save "${build_image}" | (eval "$(minikube --profile="${PROFILE}" docker-env --shell bash)" && docker load)
}


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
}


echo "**** Deploying Rook Cluster ****"
cd ~/go/src/github.com/rook/rook/deploy/examples

# update rook ceph manifest files to use local builds etc.
sed_changes

# copy relevant images to minikube/Kind cluster to save time in downloading these images inside the cluster.

copy_images_to_minikube


echo "**** Apply common ****"
kubectl create -f common.yaml --context=${PROFILE}


echo "**** Apply crds ****"
#kubectl create -f pre-k8s-1.16/crds.yaml
kubectl create -f crds.yaml --context=${PROFILE}

echo "**** Starting Rook Operator ****"
kubectl create -f operator.yaml --context=${PROFILE}

while [[ $(kubectl get pods -l app=rook-ceph-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n rook-ceph) != "True" ]]; do echo "waiting for rook operator pod" && sleep 5; done
OperatorPOD=$(kubectl get pod -l app=rook-ceph-operator -o custom-columns=:metadata.name -n rook-ceph)

echo "**** Creating Toolbox ****"
kubectl apply -f toolbox.yaml --context=${PROFILE}

while [[ $(kubectl get pods -l app=rook-ceph-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n rook-ceph) != "True" ]]; do echo "waiting for rook operator pod" && sleep 5; done
OperatorPOD=$(kubectl get pod -l app=rook-ceph-operator -o custom-columns=:metadata.name -n rook-ceph)

# cat <<EOF | kubectl --context=${PROFILE} apply -f -
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: my-cluster
  namespace: rook-ceph # namespace:cluster
spec:
  dataDirHostPath: /var/lib/rook
  cephVersion:
    # image: quay.io/ceph/ceph:v18.2.1
    image: quay.ceph.io/ceph-ci/ceph:wip-nbalacha-rbd-consistency-groups
    allowUnsupported: true
  mon:
    count: 1
    allowMultiplePerNode: true
  mgr:
    count: 1
    allowMultiplePerNode: true
  dashboard:
    enabled: true
  crashCollector:
    disable: true
  storage:
    useAllNodes: true
    useAllDevices: true
    #deviceFilter:
  monitoring:
    enabled: false
  healthCheck:
    daemonHealth:
      mon:
        interval: 45s
        timeout: 600s
  priorityClassNames:
    all: system-node-critical
    mgr: system-cluster-critical
  disruptionManagement:
    managePodBudgets: true
  cephConfig:
    global:
      osd_pool_default_size: "1"
      mon_warn_on_pool_no_redundancy: "false"
      bdev_flock_retry: "20"
      bluefs_buffered_io: "false"
      mon_data_avail_warn: "10"
---
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: builtin-mgr
  namespace: rook-ceph # namespace:cluster
spec:
  name: .mgr
  replicated:
    size: 1
    requireSafeReplicaSize: false
EOF

# cat <<EOF | kubectl --context=${PROFILE} apply -f -
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: mirrored-pool
  namespace: rook-ceph
spec:
  replicated:
    size: 1
  mirroring:
    enabled: true
    mode: image
EOF

echo "*** Successfully install Rook (OSD on devices) on Minikube Cluster  with profile $PROFILE ****"

