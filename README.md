# k3d-dev-cluster

A reproducible local Kubernetes development environment using [k3d](https://k3d.io/), [k3s](https://k3s.io/), [Cilium](https://cilium.io/) and Gateway API support.

## Features

- Single or multi-node k3d cluster (1 server, 2 agents by default)
- Cilium CNI with kube-proxy replacement and custom pod/service CIDRs
- Gateway API CRDs auto-installed
- ArgoCD deployment to bootstrap additional cluster components
- Customizable via YAML values files

## Prerequisites

- Docker
- k3d
- kubectl
- helm
- cilium CLI


## Quick Start

```bash
./cluster-bootstrap.sh
```

This will:
- Create the k3d cluster
- Install Gateway API CRDs
- Install Cilium
- (Optionally) run Cilium connectivity tests
- Install ArgoCD
- Configure the host routing table for the Load Balancer IP

## Cleanup

To remove the resources created by the bootstrap script:

```bash
./cluster-cleanup.sh
```

This will:
- Remove the route to the Load Balancer IP
- Delete the k3d cluster

## Configuration

- **Cluster config:** `values/k3d.yaml`
- **Cilium config:** `values/cilium.yaml`
- **ArgoCD config:** `values/argocd.yaml`
