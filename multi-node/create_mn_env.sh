#!/bin/bash -e

echo "*** Creating a minikube environment for local testing of Rook ***"

# Create a minikube cluster

minikube delete 
minikube start -n 3 --driver=kvm2 --extra-disks=1  --disk-size=10gb 

