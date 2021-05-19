#!/bin/bash -e

echo "*** Creating a minikube environment for local testing of Rook ***"

# Create a minikube cluster
minikube start  --cpus=4  --driver=virtualbox --memory=6g --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0

#minikube start  --driver=virtualbox --extra-config=kubeadm.node-name=my
#--extra-config=kubeadm.node-name=my
#--bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0

# Add storage to a minikube cluster
echo "*** adding storage device in minikube ***"
cd ~/
cp new-minikube-disk/NewVirtualDisk1.vdi  minikube/
VBoxManage storageattach minikube --storagectl "SATA" --device 0 --port 2 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk1.vdi


if [ "$1" == "OSD_ON_PVC" ]; then
    cp new-minikube-disk/NewVirtualDisk2.vdi  minikube/
    cp new-minikube-disk/NewVirtualDisk3.vdi  minikube/
    cp new-minikube-disk/NewVirtualDisk4.vdi  minikube/

    VBoxManage storageattach minikube --storagectl "SATA" --device 0 --port 3 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk2.vdi
    VBoxManage storageattach minikube --storagectl "SATA" --device 0 --port 4 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk3.vdi
    VBoxManage storageattach minikube --storagectl "SATA" --device 0 --port 5 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk4.vdi
fi

minikube addons disable metrics-server
