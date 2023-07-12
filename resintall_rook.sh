
#!/bin/bash -e

function sed_changes() {
      echo "**** updating manifest files in ceph directory ****"

      echo "**** change rook image name ****"
      sed -i "s/rook\/ceph:master/quay.io\/sp1098\/rook:local/" ./cluster/examples/kubernetes/ceph/operator.yaml

      if [ "$2" == "OSD_ON_PVC" ]; then
           echo "**** change storage class name ****"
           sed -i "s/storageClassName: gp2/storageClassName: foobar/" ./cluster/examples/kubernetes/ceph/cluster-on-pvc.yaml
      fi
}

sed_changes

echo "**** Deploying Rook Cluster ****"
cd ~/go/src/github.com/rook/rook/deploy/examples

echo "**** Apply common ****"
kubectl create -f common.yaml

echo "**** Apply crds ****"
kubectl create -f crds.yaml

echo "**** Starting Rook Operator ****"
kubectl create -f operator.yaml

while [[ $(kubectl get pods -l app=rook-ceph-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n rook-ceph) != "True" ]]; do echo "waiting for rook operator pod" && sleep 5; done
OperatorPOD=$(kubectl get pod -l app=rook-ceph-operator -o custom-columns=:metadata.name -n rook-ceph)

echo "**** Creating Toolbox ****"
kubectl apply -f toolbox.yaml

echo "**** Creating ceph Cluster with OSD on Devices ****"
kubectl create -f cluster.yaml

echo "*** Successfully install Rook (OSD on devices) on Minikube Cluster ****"

echo "*** watching rook operator logs ****"
kubectl logs --follow $OperatorPOD -n rook-ceph
