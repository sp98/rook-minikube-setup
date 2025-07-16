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

# ./create_minikube_vcluster.sh

# PROFILE=vcluster_minicluster1_minicluster1_minikube ./install_rook_minicluster_1.sh
# PROFILE=vcluster_minicluster2_minicluster2_minikube ./install_rook_minicluster_2.sh

sudo virsh net-define /usr/share/libvirt/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default

PROFILE=minicluster1 ./create_minikube.sh
PROFILE=minicluster2 ./create_minikube.sh

PROFILE=minicluster1 ./install_rook.sh
cd /"${SCRIPT_DIR}"/mirror
PROFILE=minicluster2 ./install_rook.sh
cd /"${SCRIPT_DIR}"/mirror

sleep 8m

PRIMARY_CLUSTER=minicluster1 SECONDARY_CLUSTER=minicluster2 ./enable_mirroring.sh
sleep 1m
PRIMARY_CLUSTER=minicluster2 SECONDARY_CLUSTER=minicluster1 ./enable_mirroring.sh
