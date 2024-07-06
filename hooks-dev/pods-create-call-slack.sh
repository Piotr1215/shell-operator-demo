#!/usr/bin/env bash

# Define the secret details
SECRET_NAMESPACE="default"
SECRET_NAME="webhook-secret"
SECRET_KEY="webhook-url"

if [[ $1 == "--config" ]]; then
	cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: v1
  kind: Pod
  executeHookOnEvent: ["Added"]
EOF
else
	# Retrieve the webhook URL from the secret
	WEBHOOK_URL=$(kubectl get secret $SECRET_NAME -n $SECRET_NAMESPACE -o jsonpath="{.data.$SECRET_KEY}" | base64 --decode)

	if [[ -z "$WEBHOOK_URL" ]]; then
		echo "Error: WEBHOOK_URL is empty or the secret does not exist."
		exit 1
	fi

	# Iterate over all events in the binding context
	for i in $(seq 0 $(($(jq length $BINDING_CONTEXT_PATH) - 1))); do
		podName=$(jq -r .[$i].object.metadata.name $BINDING_CONTEXT_PATH)
		podNamespace=$(jq -r .[$i].object.metadata.namespace $BINDING_CONTEXT_PATH)
		creationTimestamp=$(jq -r .[$i].object.metadata.creationTimestamp $BINDING_CONTEXT_PATH)
		image=$(jq -r .[$i].object.spec.containers[0].image $BINDING_CONTEXT_PATH)
		events=$(kubectl get events --field-selector involvedObject.name=$podName -n $podNamespace -o json | jq -r '.items[] | "Time: \(.lastTimestamp), Message: \(.message)"')

		# Create a YAML for the CRD
		cat <<EOF | kubectl apply -f -
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
      "text": "A new pod has been created.\n\nPod Name: $podName\nNamespace: $podNamespace\nCreation Timestamp: $creationTimestamp\nImage: $image\nEvents: $events",
      "icon_url": "https://example.com/path/to/icon.png"
    }'
EOF

		echo "CRD created for created pod '${podName}' with webhook URL."
	done
fi
