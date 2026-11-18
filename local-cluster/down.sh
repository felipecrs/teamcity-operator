#!/bin/sh
set -eu
cd "$(dirname "$0")"
vcluster delete teamcity --driver docker
rm -f kubeconfig.yaml
