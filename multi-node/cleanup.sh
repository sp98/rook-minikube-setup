#!/bin/bash -e

# Cleaning Rook from a minikube cluster
# Steps:
# 1. Add cleanup policy to the ceph cluster CR.
# 2. Delete the ceph cluster CR.
# 3. Wait for the cleanup jobs to complete.
# 4. Delete the ceph cluster CR
# 5. Delete the operator
# 6. Delete the common yaml

echo "**** add clean up policy ****"
kubectl get cephclusters.ceph.rook.io rook-ceph -n rook-ceph -o yaml | sed -z "s/cleanupPolicy:/&\n \ \ \ confirmation: yes-really-destroy-data/2" |  kubectl replace -f -

sleep 5

echo "**** delete ceph cluster ****"
kubectl delete cephclusters.ceph.rook.io  rook-ceph -n rook-ceph

echo "**** wait for all three clean up jobs to complete ****"
while [[ $(kubectl get jobs -n rook-ceph -l app=rook-ceph-cleanup -o 'jsonpath={..status.conditions[?(@.type=="Complete")].status}') != "True True True" ]]; do echo "waiting for clean up jobs" && sleep 5; done

echo "**** Deploying Rook Cluster ****"
cd ~/go/src/github.com/rook/rook/cluster/examples/kubernetes/ceph

echo "**** delete Rook Operator ****"
kubectl delete -f operator.yaml

while [[ $(kubectl get pods -l app=rook-ceph-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n rook-ceph) == "True" ]]; do echo "waiting for rook operator pod to be deleted" && sleep 5; done

echo "**** delete common ****"
kubectl delete -f crds.yaml

echo "**** delete common ****"
kubectl delete -f common.yaml
