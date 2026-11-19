#!/bin/sh
# Starts the k3d cluster unless it runs already, makes it your current kube
# context, then runs tilt up (with any arguments given).
set -eu
cd "$(dirname "$0")"

k3d cluster get teamcity >/dev/null 2>&1 || k3d cluster create --config k3d.yaml
k3d cluster start teamcity
k3d kubeconfig merge teamcity --kubeconfig-merge-default --kubeconfig-switch-context >/dev/null
# Tilt gets its own kubeconfig, so switching contexts leaves it alone.
k3d kubeconfig get teamcity >kubeconfig.yaml
export KUBECONFIG="$PWD/kubeconfig.yaml"
exec tilt up "$@"
