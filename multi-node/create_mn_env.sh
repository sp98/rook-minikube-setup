#!/bin/bash -e

echo "*** Creating a minikube environment for local testing of Rook ***"

# Create a minikube cluster

minikube start -n 4 --driver=virtualbox
# --kubernetes-version v1.15.0
# Add storage to a minikube cluster
echo "*** adding storage device in minikube ***"
cd ~/
cp new-minikube-disk/NewVirtualDisk1.vdi  minikube/
VBoxManage storageattach minikube-m02 --storagectl "SATA" --device 0 --port 2 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk1.vdi

# cp new-minikube-disk/NewVirtualDisk2.vdi  minikube/
# VBoxManage storageattach minikube-m02 --storagectl "SATA" --device 0 --port 3 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk2.vdi

cp new-minikube-disk/NewVirtualDisk3.vdi  minikube/
VBoxManage storageattach minikube-m03 --storagectl "SATA" --device 0 --port 2 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk3.vdi

# cp new-minikube-disk/NewVirtualDisk4.vdi  minikube/
# VBoxManage storageattach minikube-m03 --storagectl "SATA" --device 0 --port 3 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk4.vdi

cp new-minikube-disk/NewVirtualDisk5.vdi  minikube/
VBoxManage storageattach minikube-m04 --storagectl "SATA" --device 0 --port 2 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk5.vdi

# cp new-minikube-disk/NewVirtualDisk6.vdi  minikube/
# VBoxManage storageattach minikube-m04 --storagectl "SATA" --device 0 --port 3 --type hdd --medium /home/sapillai/minikube/NewVirtualDisk6.vdi


# Check if all nodes are ready
sleep 20s

kubectl taint nodes minikube  special=true:NoSchedule
