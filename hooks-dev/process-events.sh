#!/usr/bin/env bash

if [[ $1 == "--config" ]]; then
	cat <<EOF
{
  "configVersion":"v1",
  "kubernetes":[
    {
      "apiVersion": "events.k8s.io/v1",
      "kind": "Event",

      "namespace": {
        "nameSelector": {
          "matchNames": ["default"]
        }
      },

      "fieldSelector": {
        "matchExpressions": [
          {
            "field": "metadata.namespace",
            "operator": "Equals",
            "value": "default"
          }
        ]
      }

    }
  ]
}
EOF
else
	type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})
	if [[ $type == "Event" ]]; then
		echo "Got Event: "
		jq '.[0].object' ${BINDING_CONTEXT_PATH}
		#podName=$(jq -r '.[0].object.metadata.name' $BINDING_CONTEXT_PATH)
		#echo "Pod '${podName}' added"
	fi
fi
