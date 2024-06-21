#!/bin/bash

PRIMARY_CLUSTER="${PRIMARY_CLUSTER:-minicluster1}"
SECONDARY_CLUSTER="${SECONDARY_CLUSTER:-minicluster2}"

SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME=$(kubectl get cephblockpools.ceph.rook.io mirrored-pool --context="${SECONDARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.info.rbdMirrorBootstrapPeerSecretName}')
SECONDARY_CLUSTER_SECRET=$(kubectl get secret -n rook-ceph "${SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME}" --context=${SECONDARY_CLUSTER} -o jsonpath='{.data.token}'| base64 -d)
SECONDARY_CLUSTER_SITE_NAME=$(kubectl get cephblockpools.ceph.rook.io mirrored-pool --context=${SECONDARY_CLUSTER} -nrook-ceph -o jsonpath='{.status.mirroringInfo.site_name}')


kubectl -n rook-ceph create secret generic --context="${PRIMARY_CLUSTER}" "${SECONDARY_CLUSTER_SITE_NAME}" \
        --from-literal=token=${SECONDARY_CLUSTER_SECRET} \
        --from-literal=pool=mirrored-pool

cat <<EOF | kubectl --context="${PRIMARY_CLUSTER}" apply -f -
apiVersion: ceph.rook.io/v1
kind: CephRBDMirror
metadata:
  name: my-rbd-mirror
  namespace: rook-ceph
spec:
  count: 1
EOF

kubectl -n rook-ceph patch --context="${PRIMARY_CLUSTER}" cephblockpool mirrored-pool --type merge -p '{"spec":{"mirroring":{"peers": {"secretNames": ["'${SECONDARY_CLUSTER_SITE_NAME}'"]}}}}'

if kubectl --context="${PRIMARY_CLUSTER}" -n rook-ceph  get pods | grep -q rbd-mirror
then
        echo "Found rbd mirror pod, Great!"
else
        echo "Did not find rbd mirror pod, :("
        exit 1
fi

if [[ $(kubectl get cephblockpools.ceph.rook.io mirrored-pool --context="${PRIMARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.mirroringStatus.summary.summary.daemon_health}') != "OK" ]]
then 
        echo "daemon health not OK"
        exit 1
fi

if [[ $(kubectl get cephblockpools.ceph.rook.io mirrored-pool --context="${PRIMARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.mirroringStatus.summary.summary.health}') != "OK" ]]
then 
        echo "health not OK"
        exit 1
fi
if [[ $(kubectl get cephblockpools.ceph.rook.io mirrored-pool --context="${PRIMARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.mirroringStatus.summary.summary.image_health}') != "OK" ]]
then 
        echo "image health not OK"
        exit 1
fi


exit 0
