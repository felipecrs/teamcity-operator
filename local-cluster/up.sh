#!/usr/bin/env bash
# Starts the local multi-node TeamCity simulation: makes sure the vind cluster
# (vCluster in Docker) runs, then hands over to `tilt up`, which deploys and
# watches everything else. Tilt resolves its Kubernetes connection once at
# startup, which is why the cluster comes first.
#
# Usage: local-cluster/up.sh [tilt up flags...]
# Teardown: local-cluster/down.sh

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
export CLUSTER_NAME="${CLUSTER_NAME:-teamcity}"

for tool in docker vcluster tilt helm kubectl python3; do
  if ! command -v "$tool" &>/dev/null; then
    echo "error: $tool is required but not installed" >&2
    exit 1
  fi
done

if ! docker info &>/dev/null; then
  echo "error: the Docker daemon is not running" >&2
  exit 1
fi

status=$(vcluster list --driver docker --output json | python3 -c '
import json, sys
print(next((c["Status"] for c in json.load(sys.stdin) if c["Name"] == sys.argv[1]), ""))
' "$CLUSTER_NAME")

case "$status" in
running) ;;
"")
  echo "==> Creating the vind cluster '$CLUSTER_NAME'..."
  vcluster create "$CLUSTER_NAME" --driver docker --values vind.yaml --connect=false
  ;;
*)
  echo "==> Resuming the vind cluster '$CLUSTER_NAME' ($status)..."
  vcluster resume "$CLUSTER_NAME" --driver docker
  ;;
esac

# Your own kubeconfig gets the cluster too, as the current context, for
# troubleshooting with kubectl and friends.
vcluster connect "$CLUSTER_NAME" --driver docker
# Tilt uses a kubeconfig of its own, so switching contexts leaves it alone.
vcluster connect "$CLUSTER_NAME" --driver docker --print >kubeconfig.yaml
export KUBECONFIG="$PWD/kubeconfig.yaml"

exec tilt up "$@"
