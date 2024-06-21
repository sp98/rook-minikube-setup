#!/bin/bash

SCRIPT_DIR=$PWD
cd "${SCRIPT_DIR}"/mirror

echo "${SCRIPT_DIR}"

if [[ $1 == "destroy" ]]
then
	PROFILE=minicluster1 ./create_minikube.sh destroy
	PROFILE=minicluster2 ./create_minikube.sh destroy
	exit 0
fi

PROFILE=minicluster1 ./create_minikube.sh
PROFILE=minicluster2 ./create_minikube.sh

PROFILE=minicluster1 ./install_rook.sh
cd /"${SCRIPT_DIR}"/mirror
PROFILE=minicluster2 ./install_rook.sh
cd /"${SCRIPT_DIR}"/mirror

sleep 2m

PRIMARY_CLUSTER=minicluster1 SECONDARY_CLUSTER=minicluster2 ./enable_mirroring.sh
PRIMARY_CLUSTER=minicluster2 SECONDARY_CLUSTER=minicluster1 ./enable_mirroring.sh
