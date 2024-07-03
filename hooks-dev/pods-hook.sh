#!/usr/bin/env bash

if [[ $1 == "--config" ]]; then
	cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: v1
  kind: Pod
  executeHookOnEvent: ["Added"]
EOF
else
	podName=$(jq -r .[0].object.metadata.name $BINDING_CONTEXT_PATH)
	podNamespace=$(jq -r .[0].object.metadata.namespace $BINDING_CONTEXT_PATH)
	kubectl label -n "${podNamespace}" po/"${podName}" pod-event=added
	echo "Label added to '${podName}'"
fi
