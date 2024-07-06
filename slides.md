---
theme: theme.json
author: Cloud-Native Corner 
date: MMMM dd, YYYY
paging: Slide %d / %d
---

```bash
~~~./intro.sh

~~~
```

---

# Project Goal: Real-time Pod Monitoring

Our objective is to implement a system that:

- 🔍 Monitors Kubernetes pod lifecycle events
- 🚀 Detects pod creation and deletion in real-time
- 📢 Sends instant notifications to Slack
- 🔧 Utilizes Shell Operator for event handling
- 🔗 Integrates with Crossplane for extensibility

---

## Shell Operator: Kubernetes Event Watcher

- 🐚 Simplifies Kubernetes automation
- 🔍 Watches for specific events
- 🚀 Executes shell scripts in response
- 🔧 Ideal for custom operators and controllers

---

## Crossplane: Cloud Native Control Plane

- ☁️ Infrastructure as Code for multiple clouds
- 📦 Extends Kubernetes with custom resources
- 🔌 Provides a consistent API for cloud services
- 🚀 Enables GitOps for infrastructure

---

## Terraform: Infrastructure as Code

- 🏗️ Declarative infrastructure provisioning
- ☁️ Supports multiple cloud providers
- 🔄 Manages infrastructure state
- 🚀 Used here to set up our local Kind cluster

---

## Kind: Kubernetes in Docker

- 🐳 Runs Kubernetes clusters using Docker containers
- 🚀 Perfect for local development and testing
- 🔧 Easily configurable and reproducible
- 💻 Lightweight alternative to full-scale clusters

---

## Setting Up Our Environment

Let's start by setting up our Kind cluster with Crossplane:

This command will:
1. Set up a `KIND` cluster using `terraform`
2. Install `Crossplane` with required providers
3. Create necessary providers (http and kubernetes provider)

---

## Shell Operator: Pod Watcher Scripts on Add

Let's look at our hook scripts for monitoring pod creation and deletion:

Pod Creation Hook:

```bash
#!/usr/bin/env bash
# Hook configuration
if [[ $1 == "--config" ]]; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: v1
  kind: Pod
  executeHookOnEvent: ["Added"]
EOF
else
  # Webhook logic for pod creation
  WEBHOOK_URL=$(kubectl get secret webhook-secret -n default -o jsonpath="{.data.webhook-url}" | base64 --decode)
  
  for i in $(seq 0 $(($(jq length $BINDING_CONTEXT_PATH) - 1))); do
    podName=$(jq -r .[$i].object.metadata.name $BINDING_CONTEXT_PATH)
    # ... 
  done
fi
```

---

## Shell Operator: Pod Watcher Scripts on Deletion

Pod Deletion Hook:

```bash
#!/usr/bin/env bash
# Hook configuration
if [[ $1 == "--config" ]]; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: v1
  kind: Pod
  executeHookOnEvent: ["Deleted"]
EOF
else
  # Webhook logic for pod deletion
  WEBHOOK_URL=$(kubectl get secret webhook-secret -n default -o jsonpath="{.data.webhook-url}" | base64 --decode)
  
  for i in $(seq 0 $(($(jq length $BINDING_CONTEXT_PATH) - 1))); do
    podName=$(jq -r .[$i].object.metadata.name $BINDING_CONTEXT_PATH)
    # ... 
  done
fi
```

---

## Create http request to send notification to Slack

Crossplane http provider CRD that sends a POST request to Slack webhook:

```yaml
apiVersion: http.crossplane.io/v1alpha2
kind: DisposableRequest
metadata:
  name: slack-webhook-creation-$podName
spec:
  deletionPolicy: Orphan
  forProvider:
    url: $WEBHOOK_URL
    method: POST
    body: '{
      "channel": "#app-notify",
      "username": "webhookbot",
      "text": "...",
      "icon_emoji": ":ghost:"
    }'
```

---

## Create Dockerfile with shell hooks

`Dockerfile` is built on top of the shell-operator image and contains our hooks
in the `/hooks` directory:

```Dockerfile
~~~cat Dockerfile

~~~
```

---

## Build and push the Shell Operator Docker Image

To package our Shell Operator with the hook scripts:

```bash
docker build -t piotrzan/shell-operator:monitor-pods .
docker push piotrzan/shell-operator:monitor-pods
```

Make sure you're logged in to your container registry first!

---

## RBAC Rules for Shell Operator

Key permissions:
- List, watch, and get pods in all namespaces
- Access to events for logging
 
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitor-pods-acc
  namespace: default 

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-manager-clusterrole
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "watch"]
```

---

## Shell Operator Kubernetes Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shell-operator
  namespace: default
spec:
  containers:
    - name: shell-operator
      image: piotrzan/shell-operator:monitor-pods
      imagePullPolicy: Always
  serviceAccountName: monitor-pods-acc
```

---

## Apply necessary RBAC rules:

This will apply rbac and shell-operator pod to the current cluster.

```bash
just setup_shell_operator
```

---

## Demo Time: Pod Monitoring in Action

Let's create and delete some pods to see our Shell Operator in action!

1. Create a test pod:

```bash
kubectl run test-pod --image=nginx
```

---

## Check Slack for creation notification

```bash
xdg-open https://app.slack.com/client/TS5R3QA6N/C072HULDL80
```

---

## Delete the test pod:

```bash
kubectl delete pod test-pod
```

---

## Conclusion

- 🐚 Shell Operator simplifies Kubernetes event handling
- 🔗 Crossplane and Terraform provide robust infrastructure management
- 🚀 Kind offers a great local development environment
- 🔔 Real-time notifications enhance cluster observability

