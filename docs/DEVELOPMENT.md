# Development Guide

This document contains development-oriented information for contributors and maintainers of the TeamCity Kubernetes Operator.

## Prerequisites

If this is the first time opening this project in your IDE, make sure that Go module integration is enabled so dependencies from `go.mod` are downloaded automatically.

Required Go version:
```
go version go1.20.4
```

Required version of minikube (if you use minikube for local testing). See the official docs for setup: https://minikube.sigs.k8s.io/docs/start/
```
minikube version: v1.30.1
```

To run locally/debug (configure minikube as your current kube context):
```
minikube start
kubectl config current-context
minikube
```

## Local webhook setup

In the root of the project run the following:

Setup directory for certificates (`certs` directory is already ignored in git, so it makes sense to use it):
```bash
mkdir -p certs
export CAROOT=$(pwd)/certs
```
`mkcert` is used to manage certificates and can be installed using:

Mac:
```bash
brew install mkcert
```
Linux:
```bash
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
```
Then, a new Root CA needs to be installed and certificates are generated. Note the name that is provided. If the developer uses a Kind cluster instead of minikube then `host.docker.internal` should be used instead (or as an additional SAN).

```bash
mkcert -install # this command will require sudo password
mkcert -cert-file=$CAROOT/tls.crt -key-file=$CAROOT/tls.key host.minikube.internal
```

This will place a few files in `certs` directory.

## Project layout

```
├── api
│   └── v1alpha1 # structs that represent CRDs. run `make generate` to generate YAML CRDs into config/crd/bases
├── bin 
│   └── k8s
│       └── 1.26.0-darwin-arm64 # results of `make build`
├── cmd # contains main.go – operator's entry point 
├── config # contains YAML resources for the operator to function
│   ├── crd
│   │   ├── bases
│   │   └── patches
│   ├── default
│   ├── manager
│   ├── manifests
│   ├── prometheus # prometheus resources; normally should not be touched
│   ├── rbac # required RBAC resources
│   ├── samples # sample YAML resources for testing
│   └── scorecard # OLM; normally should not be touched
│       ├── bases
│       └── patches
├── hack # boilerplate; normally should not be touched
└── internal # operator internals
    ├── controller # reconciler loop
    ├── metadata # helpers for labels and annotations
    └── resource # builders for each resource 
```

## Run/Debug

Use the run configuration "Run controller" in Run or Debug mode.

This run configuration assumes minikube is running and a context with the name `minikube` exists.

## Run/Debug with webhooks

Use the run configuration "Run controller with webhooks" in Run or Debug mode.

This run configuration assumes minikube is running, a context with the name `minikube` exists, and steps in Local webhook setup are completed.

## Test

```shell
make test # finds all test files and runs ginkgo tests
```

## Deployment (from source)

```shell
make deploy # installs controller to the selected kube context
```

## Local cluster simulation

`local-cluster/up.sh` starts a local multi-node TeamCity on a [vind](https://github.com/loft-sh/vind) cluster (vCluster in Docker), driven by [Tilt](https://tilt.dev). It creates or resumes the cluster, makes it your current kube context, and runs `tilt up`, which:

- builds the operator from the current source tree and deploys it with its chart;
- installs cert-manager, Traefik, a Percona PostgreSQL database, and an NFS server with csi-driver-nfs for ReadWriteMany volumes;
- deploys a three-node TeamCity behind HAProxy, sharing its data directory over NFS (`local-cluster/charts/teamcity`), and build agent pod templates (`local-cluster/charts/teamcity-agents`);
- loads the Kotlin DSL in `local-cluster/.teamcity` as the Root project settings: a Kubernetes cloud profile that starts agents as pods, and an example pipeline. TeamCity picks up edits within a minute or so.

TeamCity is at `http://teamcity.<machine IP>.nip.io` and `http://localhost:8111`, both linked from the Tilt UI to the super user login, whose token is `super`. Host port 80 must be free. Buttons in the Tilt UI run the example pipeline, reload the DSL when TeamCity stopped applying it, and run `helm test`.

`local-cluster/down.sh` deletes the cluster.
