#!/usr/bin/env bash
# Deletes the local TeamCity simulation: the vind cluster and everything in it.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
vcluster delete "${CLUSTER_NAME:-teamcity}" --driver docker
rm -f kubeconfig.yaml
