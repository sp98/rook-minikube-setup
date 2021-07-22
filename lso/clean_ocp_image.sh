#!/bin/bash -e

for i in $(oc get nodes|grep worker|awk '{print$1}'); do oc debug node/$i -- chroot /host podman image rm -f quay.io/sp1098/lso:latest quay.io/sp1098/local-diskmaker:latest quay.io/sp1098/local-storage-bundle:v1 quay.io/sp1098/sp1098-index:v1 quay.io/sp1098/local-storage-bundle:bundle quay.io/sp1098/sp1098-index:test; done
