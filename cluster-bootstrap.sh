#!/bin/bash

BOOTSTRAP_PATH=cluster/bootstrap
CLUSTER_NAME=k3d-dev
SKIP_CILIUM_TESTS=true
GATEWAY_API_VERSION="1.2.0"

export K3D_FIX_MOUNTS=1
export K3D_FIX_DNS=0

k3d cluster create --config $BOOTSTRAP_PATH/k3d/values.yaml

MASTER_NODE_IP=$(kubectl --context $CLUSTER_NAME get node/$CLUSTER_NAME-server-0 -o wide --no-headers | awk '{ print $6 }')
echo "Master Node IP: $MASTER_NODE_IP"

# Install Cilium with Helm
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.18.2 --set k8sServiceHost=$MASTER_NODE_IP --values $BOOTSTRAP_PATH/cilium/values.yaml --namespace kube-system
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