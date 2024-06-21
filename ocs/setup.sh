
#!/bin/bash -e

cd /home/sapillai/go/src/github.com/ocs-operator

export REGISTRY_NAMESPACE=sp1098
export IMAGE_TAG=kms


# make ocs-operator
# podman push quay.io/$REGISTRY_NAMESPACE/ocs-operator:$IMAGE_TAG

# make ocs-metrics-exporter
# podman push quay.io/$REGISTRY_NAMESPACE/ocs-metrics-exporter:$IMAGE_TAG


# make operator-bundle
# podman push quay.io/$REGISTRY_NAMESPACE/ocs-operator-bundle:$IMAGE_TAG


# make operator-catalog
# podman push quay.io/$REGISTRY_NAMESPACE/ocs-operator-catalog:$IMAGE_TAG


oc create ns openshift-storage

cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
    - openshift-storage
EOF

cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ocs-catalogsource
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/sp1098/ocs-operator-catalog:kms
  displayName: OpenShift Container Storage
  publisher: Red Hat
EOF


cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ocs-subscription
  namespace: openshift-storage
spec:
  channel: alpha
  name: ocs-operator
  source: ocs-catalogsource
  sourceNamespace: openshift-marketplace
EOF

cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: noobaa-subscription
  namespace: openshift-storage
spec:
  channel: alpha
  name: noobaa-operator
  source: ocs-catalogsource
  sourceNamespace: openshift-marketplace
EOF



1. Ping Boris for adding you to the rhceph-dev org
2. Update your pull secrets in your ocp cluster if required
3. Create the icsp.yaml
$ podman run --entrypoint cat quay.io/rhceph-dev/ocs-registry:4.16.0-57 /icsp.yaml | oc apply -f -
4. Crate the catalogsource with the registry image
$ cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: odf-catalogsource
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/rhceph-dev/ocs-registry:4.16.0-57
  displayName: OpenShift Data Foundation
  publisher: Red Hat
EOF
5. Install ODF from UI
