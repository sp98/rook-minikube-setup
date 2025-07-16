#!/bin/bash -e

PROFILE_1="${PROFILE:-minicluster1}"
PROFILE_2="${PROFILE:-minicluster2}"

echo PROFILE_1 is $PROFILE_1
echo PROFILE_2 is $PROFILE_2

if [[ $1 == "destroy" ]]
then
	minikube --profile="vcluster_${PROFILE_1}_${PROFILE_1}_minikube" stop
	minikube --profile="vcluster_${PROFILE_1}_${PROFILE_1}_minikube" delete
    minikube --profile="vcluster_${PROFILE_2}_${PROFILE_2}_minikube" stop
	minikube --profile="vcluster_${PROFILE_2}_${PROFILE_2}_minikube" delete
fi


echo "*** Creating a minikube environment for local testing of Rook with profile $PROFILE ***"

minikube start --driver=kvm2 --extra-disks=6 --disk-size=10gb 
kubectl create namespace "${PROFILE_1}"
kubectl create namespace "${PROFILE_2}"

vcluster create "${PROFILE_1}" -n "${PROFILE_1}"
vcluster disconnect 
vcluster create "${PROFILE_2}" -n "${PROFILE_2}"
vcluster disconnect
