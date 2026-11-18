#!/bin/sh
# Starts the vind cluster unless it runs already, adds it to your kubeconfig
# as the current context, then runs tilt up (with any arguments given).
set -eu
cd "$(dirname "$0")"

case $(docker inspect -f '{{.State.Status}}' vcluster.cp.teamcity 2>/dev/null || true) in
running) ;;
'') vcluster create teamcity --driver docker --values vind.yaml --connect=false ;;
*) vcluster resume teamcity --driver docker ;;
esac

vcluster connect teamcity --driver docker
# Tilt gets its own kubeconfig, so switching contexts leaves it alone.
vcluster connect teamcity --driver docker --print >kubeconfig.yaml
export KUBECONFIG="$PWD/kubeconfig.yaml"
exec tilt up "$@"
