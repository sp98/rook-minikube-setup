#!/bin/bash -e

PROFILE="${PROFILE:-minicluster1}"
echo PROFILE is $PROFILE

if [[ $1 == "destroy" ]]
then
	minikube --profile="${PROFILE}" stop
	minikube --profile="${PROFILE}" delete
fi


echo "*** Creating a minikube environment for local testing of Rook with profile $PROFILE ***"

minikube start --driver=kvm2 --extra-disks=3 --disk-size=10gb  --profile="${PROFILE}"