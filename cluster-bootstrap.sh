#!/bin/bash

CLUSTER_NAME=k3d-dev
SKIP_CILIUM_TESTS=true
GATEWAY_API_VERSION="1.2.0"

export K3D_FIX_MOUNTS=1
export K3D_FIX_DNS=0

k3d cluster create --config values/k3d.yaml

MASTER_NODE_IP=$(kubectl --context $CLUSTER_NAME get node/$CLUSTER_NAME-server-0 -o wide --no-headers | awk '{ print $6 }')
echo "Master Node IP: $MASTER_NODE_IP"

# Install Gateway API CRDs
GATEWAY_API_CRDS=(
  "standard/gateway.networking.k8s.io_gatewayclasses.yaml"
  "standard/gateway.networking.k8s.io_gateways.yaml"
  "standard/gateway.networking.k8s.io_httproutes.yaml"
  "standard/gateway.networking.k8s.io_referencegrants.yaml"
  "standard/gateway.networking.k8s.io_grpcroutes.yaml"
  "experimental/gateway.networking.k8s.io_tlsroutes.yaml"
)

for crd in "${GATEWAY_API_CRDS[@]}"; do
  kubectl apply -f "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v$GATEWAY_API_VERSION/config/crd/${crd}"
done

# Set kube context
kubectl config use-context $CLUSTER_NAME
# Install Cilium with Helm
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.18.2 --set k8sServiceHost=$MASTER_NODE_IP --values values/cilium.yaml --namespace kube-system
# Alternatively, use Cilium CLI
#cilium install --version 1.18.2 --context=$CLUSTER_NAME --set k8sServiceHost=$MASTER_NODE_IP --values values/cilium.yaml
cilium status --wait

if [ "$SKIP_CILIUM_TESTS" == "false" ]; then
  echo "Running Cilium connectivity tests..."
  cilium connectivity test
else
  echo "Skipping Cilium connectivity tests."
fi

# Install LB pool and Gateway resources
kubectl apply -f gateway-api/lb-pool.yaml
kubectl apply -f gateway-api/gateway.yaml

# Install ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-cd argo/argo-cd --namespace argocd --create-namespace --values values/argocd.yaml --wait --timeout 5m

# Add root ArgoCD Application
kubectl apply -f apps/argocd-root.yaml