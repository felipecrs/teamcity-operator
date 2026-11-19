#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ -f kubeconfig.yaml ]; then
  # Stop TeamCity, the NFS client, then the NFS server, gracefully: otherwise
  # the kernel spends minutes on NFS timeouts while the cluster stops.
  export KUBECONFIG="$PWD/kubeconfig.yaml"
  kubectl -n teamcity delete teamcity teamcity --cascade=foreground --timeout=3m >/dev/null 2>&1 || true
  kubectl -n nfs scale deployment nfs-server --replicas=0 >/dev/null 2>&1 &&
    kubectl -n nfs wait --for=delete pod -l app=nfs-server --timeout=2m >/dev/null 2>&1 || true
  unset KUBECONFIG
fi
k3d cluster delete teamcity
# The node can outlive that: once it stopped, delete again to remove what is
# left, volumes included.
while [ "$(docker inspect -f '{{.State.Running}}' k3d-teamcity-server-0 2>/dev/null)" = true ]; do sleep 2; done
k3d cluster delete teamcity >/dev/null 2>&1
kubectl config delete-context k3d-teamcity >/dev/null 2>&1 || true
rm -f kubeconfig.yaml
