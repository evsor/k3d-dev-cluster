#!/bin/bash

CLUSTER_NAME=dev

echo "Deleting k3d cluster"
k3d cluster delete $CLUSTER_NAME

echo "Cleanup complete."