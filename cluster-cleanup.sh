#!/bin/bash

CLUSTER_NAME=dev


# Remove route to Load Balancer IP with safety checks
LB_IP=$(kubectl get gateway shared-gateway -o jsonpath='{.status.addresses[0].value}' -n default)
echo "Load Balancer IP: $LB_IP"
IFACE=$(ip -o addr show | awk -v ip="172.20" '$0 ~ ip {print $2'} | head -n1)
echo "iface: $IFACE"

if [[ -z "$LB_IP" ]]; then
	echo "Error: Load Balancer IP not found. Skipping route deletion."
elif [[ -z "$IFACE" ]]; then
	echo "Error: Network interface not found for subnet 172.20.*.* Skipping route deletion."
else
	if ip route show | grep -q "^$LB_IP "; then
		sudo ip route del $LB_IP dev $IFACE && echo "Route deleted." || echo "Failed to delete route."
	else
		echo "Route for $LB_IP does not exist. Skipping."
	fi
fi

echo "Deleting k3d cluster"
k3d cluster delete $CLUSTER_NAME

echo "Cleanup complete."