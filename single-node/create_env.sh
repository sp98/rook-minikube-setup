#!/bin/bash -e

echo "*** Creating a minikube environment for local testing of Rook ***"

# Create a minikube cluster
# minikube start  --cpus=4  --driver=virtualbox --memory=6g --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0

minikube delete 
minikube start --driver=kvm2 --extra-disks=3 --disk-size=10gb 

# --kubernetes-version v1.28.2

# minikube addons disable metrics-server
