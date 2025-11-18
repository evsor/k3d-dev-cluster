#!/bin/bash

########################################
# K3D Dev Cluster Bootstrap Script
########################################

# Cluster Configuration Variables
export KUBE_API_IP="0.0.0.0"
export KUBE_API_PORT="6443"
export CLUSTER_SUBNET=172.20.0.0/16
export NODES_SUBNET=10.42.0.0/16

# k3d fixes
export K3D_FIX_MOUNTS=1
export K3D_FIX_DNS=0

# script variables
BOOTSTRAP_PATH=cluster/bootstrap
CLUSTER_NAME=k3d-dev
SKIP_CILIUM_TESTS=true

# Render config files with envsubst
cat $BOOTSTRAP_PATH/k3d/values.yaml | envsubst > /tmp/k3d-values.yaml
cat $BOOTSTRAP_PATH/cilium/values.yaml | envsubst > /tmp/cilium-values.yaml

# Create k3d cluster
k3d cluster create --config /tmp/k3d-values.yaml

# Get Master Node IP
MASTER_NODE_IP=$(kubectl --context $CLUSTER_NAME get node/$CLUSTER_NAME-server-0 -o wide --no-headers | awk '{ print $6 }')
echo "Master Node IP: $MASTER_NODE_IP"

# Install Gateway API CRDs
helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm --version v0.0.0-latest --set crds.gatewayAPI.enabled=true | kubectl apply --server-side -f -

# Install Cilium with Helm
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.18.2 --set k8sServiceHost=$MASTER_NODE_IP --values /tmp/cilium-values.yaml --namespace kube-system
cilium status --wait

if [ "$SKIP_CILIUM_TESTS" == "false" ]; then
  echo "Running Cilium connectivity tests..."
  cilium connectivity test
else
  echo "Skipping Cilium connectivity tests."
fi

# Install ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-cd argo/argo-cd --namespace argocd --create-namespace --values $BOOTSTRAP_PATH/argocd/values.yaml --wait --timeout 5m

# Add root ArgoCD Application
kubectl apply -f $BOOTSTRAP_PATH/argocd/argocd-root.yaml