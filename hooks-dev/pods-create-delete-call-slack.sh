#!/usr/bin/env bash

# Define the secret details
SECRET_NAMESPACE="default"
SECRET_NAME="webhook-secret"
SECRET_KEY="webhook-url"

if [[ $1 == "--config" ]]; then
	cat <<EOF
configVersion: v1
kubernetes:
- name: pods
  apiVersion: v1
  kind: Pod
  executeHookOnEvent: ["Added", "Deleted"]
EOF
else
	# Retrieve the webhook URL from the secret
	WEBHOOK_URL=$(kubectl get secret $SECRET_NAME -n $SECRET_NAMESPACE -o jsonpath="{.data.$SECRET_KEY}" | base64 --decode)

	if [[ -z "$WEBHOOK_URL" ]]; then
		echo "Error: WEBHOOK_URL is empty or the secret does not exist."
		exit 1
	fi

	# Debug: Show the BINDING_CONTEXT_PATH content
	echo "Binding context path content:"
	cat $BINDING_CONTEXT_PATH

	# Iterate over binding contexts
	jq -c '.[]' $BINDING_CONTEXT_PATH | while read i; do
		watchEvent=$(echo $i | jq -r .watchEvent)
		podName=$(echo $i | jq -r .object.metadata.name)
		podNamespace=$(echo $i | jq -r .object.metadata.namespace)

		echo "Watch Event: $watchEvent"
		echo "Pod Name: $podName"
		echo "Pod Namespace: $podNamespace"

		if [[ $watchEvent == "Added" ]]; then
			creationTimestamp=$(echo $i | jq -r .object.metadata.creationTimestamp)
			image=$(echo $i | jq -r .object.spec.containers[0].image)

			# Fetch related events
			events=$(kubectl get events --field-selector involvedObject.name=$podName -n $podNamespace -o json | jq -r '.items | map("Time: \(.lastTimestamp), Message: \(.message)") | join("\n")')

			if [[ -z "$events" ]]; then
				events="No events found."
			fi

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
      "text": "A new pod has been created.\n\nPod Name: $podName\nNamespace: $podNamespace\nCreation Timestamp: $creationTimestamp\nImage: $image\nEvents:\n$events",
      "icon_url": "https://example.com/path/to/icon.png"
    }'
EOF

			echo "CRD created for created pod '${podName}' with webhook URL."

		elif [[ $watchEvent == "Deleted" ]]; then
			deletionTimestamp=$(echo $i | jq -r .object.metadata.deletionTimestamp)

			# Create a YAML for the CRD
			cat <<EOF | kubectl apply -f -
apiVersion: http.crossplane.io/v1alpha2
kind: DisposableRequest
metadata:
  name: slack-webhook-deletion-$podName
spec:
  deletionPolicy: Orphan
  forProvider:
    url: $WEBHOOK_URL
    method: POST
    body: '{
      "channel": "#app-notify",
      "username": "webhookbot",
      "text": "A pod has been deleted.\n\nPod Name: $podName\nNamespace: $podNamespace\nDeletion Timestamp: $deletionTimestamp",
      "icon_emoji": ":ghost:"
    }'
EOF

			echo "CRD created for deleted pod '${podName}' with webhook URL."
		else
			echo "Unhandled watch event: $watchEvent"
		fi
	done
fi
