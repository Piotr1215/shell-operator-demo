set export
set shell := ["bash", "-uc"]
                                 
yaml          := justfile_directory() + "/yaml"
kind          := justfile_directory() + "/tf-kind"

default:
  just --list --unsorted

build:
  CGO_ENABLED=1 go build ../shell-operator/cmd/shell-operator/

debug:
  ./shell-operator start --hooks-dir /home/decoder/dev/shell-operator-blog/hooks --tmp-dir /home/decoder/dev/shell-operator-blog/tmp --log-type color

# * setup kind cluster with crossplane, ArgoCD and launch argocd in browser
setup: setup_kind setup_crossplane create_providers

setup_shell_operator:
  kubectl apply -f {{yaml}}/rbac.yaml
  kubectl apply -f {{yaml}}/shell-operator-pod.yaml

# setup kind cluster
setup_kind:
  #!/usr/bin/env bash
  set -euo pipefail

  cd {{kind}} && terraform apply -auto-approve

create_providers:
  envsubst < {{yaml}}/providers.yaml | kubectl apply -f - 
  kubectl wait --for condition=healthy --timeout=300s provider.pkg --all
  envsubst < {{yaml}}/provider-configs.yaml | kubectl apply -f -
  envsubst < {{yaml}}/functions.yaml | kubectl apply -f -

# apply http request
apply_http_request:
  envsubst < {{yaml}}/http-request.yaml | kubectl apply -f -

# setup crossplane
setup_crossplane xp_namespace='crossplane-system':
  #!/usr/bin/env bash
  if kubectl get namespace {{xp_namespace}} > /dev/null 2>&1; then
    echo "Namespace {{xp_namespace}} already exists"
  else
    echo "Creating namespace {{xp_namespace}}"
    kubectl create namespace {{xp_namespace}}
  fi

  echo "Installing crossplane version"
  helm repo add crossplane-stable https://charts.crossplane.io/stable
  helm repo update
  helm upgrade --install crossplane \
       --namespace {{xp_namespace}} crossplane-stable/crossplane \
       --set args='{"--enable-realtime-compositions","--enable-usages"}' \
       --devel
  kubectl wait --for condition=Available=True --timeout=300s deployment/crossplane --namespace {{xp_namespace}}
