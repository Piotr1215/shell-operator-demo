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
- 🚀 Enables building custom control planes

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
- 💻 Lightweight alternative to full-scale clusters for local testing

---

## Setting Up Our Environment

Let's start by setting up our Kind cluster with Crossplane:

```bash
__show_file_temp_pane.sh ./justfile
```

1. Set up a `KIND` cluster using `terraform`
2. Install `Crossplane` with required providers
3. Create necessary providers (http and kubernetes provider)

---

## Shell Operator: Pod Watcher Scripts on Add

Let's look at our hook scripts for monitoring pod creation and deletion:

Let's see the pod Creation Hook:

```bash
__show_file_temp_pane.sh ./hooks/pods-create-call-slack.sh
```

---

## Shell Operator: Pod Watcher Scripts on Deletion

Let's see the pod Deletion Hook:

```bash
__show_file_temp_pane.sh ./hooks/pods-delete-call-slack.sh
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

```bash
__show_file_temp_pane.sh ./yaml/http-request.yaml
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
- Pods, secrets, http provider CRDs in all namespaces
 
```bash
__show_file_temp_pane.sh ./yaml/rbac.yaml
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

## Check Slack for creation notification

Let's see if notifications will work as expected:

```bash
/home/decoder/dev/dotfiles/scripts/__layouts.sh 2
xdg-open https://app.slack.com/client/TS5R3QA6N/C072HULDL80
```

---

## Demo Time: Pod Monitoring in Action

Let's create and delete some pods to see our Shell Operator in action!

1. Create a test pod:

```bash
kubectl run test-pod-nginx --image=nginx
```

---
## Delete the test pod:

```bash
kubectl delete pod test-pod-nginx
```

---

## Conclusion

- 🐚 Shell Operator simplifies Kubernetes event handling
- 🔗 Crossplane and Terraform provide robust infrastructure management
- 🚀 Kind offers a great local development environment
- 🔔 Real-time notifications enhance cluster observability
