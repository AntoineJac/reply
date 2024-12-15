#!/bin/bash

# Check if the Control Plane Group Name, Region and spat token are passed as arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <control_plane_group_name> <region> <spat_token>"
  exit 1
fi

# Define the control plane group name and spat_token from the argument. Possible options of region are be us,eu and au
CONTROL_PLANE_GROUP_NAME=$1
REGION=$2
SPAT_TOKEN=$3
CERT_PATH="./KongAir_Internal_CP_Group_Internal.crt"  # Path to your .crt file
KEY_PATH="./KongAir_Internal_CP_Group_Internal.key"    # Path to your .key file

# Check if the certificate and key files exist
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  echo "Error: Certificate or key file not found."
  exit 1
fi

# Define the API URL with parameterized control plane group ID and Region
API_URL="https://$REGION.api.konghq.com/v2/control-planes/?filter%5Bname%5D=$CONTROL_PLANE_GROUP_NAME"

# Define the authorization token
AUTH_TOKEN="$SPAT_TOKEN"

# Fetch the data from the API using curl with the Authorization header
response=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" "$API_URL")

# Use jq to parse the response and extract control_plane_group_id, control_plane_group_endpoint and telemetry_endpoint from nested config under data and remove https from the front
control_plane_group_endpoint=$(echo "$response" | jq -r '.data[0].config.control_plane_endpoint' | sed 's|https://||')
telemetry_endpoint=$(echo "$response" | jq -r '.data[0].config.telemetry_endpoint' | sed 's|https://||')
control_plane_group_id=$(echo "$response" | jq -r '.data[0].id')

# Check if the values were extracted properly
if [ -z "$control_plane_group_endpoint" ] || [ -z "$telemetry_endpoint" ] || [ -z "$control_plane_group_id" ]; then
  echo "Error: Failed to fetch control_plane_group_endpoint, telemetry_endpoint, or control_plane_group_id"
  exit 1
fi

# Display the extracted values
echo "Control Plane Group Endpoint: $control_plane_group_endpoint"
echo "Telemetry Endpoint: $telemetry_endpoint"
echo "Control Plane Group ID: $control_plane_group_id"

# Read certificate file and escape newlines
CERT_CONTENT=$(awk '{printf "%s\\n", $0}' "$CERT_PATH")

# Post the client certificate to the Kong API
CERTIFICATE_POST_URL="https://$REGION.api.konghq.com/v2/control-planes/${control_plane_group_id}/dp-client-certificates"

curl --request POST \
  --url "$CERTIFICATE_POST_URL" \
  --header "Authorization: Bearer $AUTH_TOKEN" \
  --header 'Content-Type: application/json' \
  --header 'accept: application/json' \
  --data "{\"cert\":\"$CERT_CONTENT\"}"

# Check if the certificate upload succeeded
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload certificate to Kong API."
  exit 1
fi

# Deploy the Kong Gateway Data Plane in the above control plane group

# Create the kong namespace
kubectl create namespace kong-internal

# Add the kong repo
helm repo add kong https://charts.konghq.com
helm repo update

# Create the Kubernetes secret for the certificates
kubectl create secret tls kong-cluster-cert -n kong-internal --cert="$CERT_PATH" --key="$KEY_PATH"


# Use the values in the Helm chart
helm upgrade --install my-kong kong/kong \
  --set env.cluster_control_plane=$control_plane_group_endpoint:443 \
  --set env.cluster_server_name=$control_plane_group_endpoint \
  --set env.cluster_telemetry_endpoint=$telemetry_endpoint:443 \
  --set env.cluster_telemetry_server_name=$telemetry_endpoint \
  --namespace kong-internal --values ./values.yaml

# Check if Helm upgrade/install succeeded
if [ $? -eq 0 ]; then
  echo "Kong Helm chart upgraded successfully with the fetched endpoints."
else
  echo "Error: Failed to upgrade Kong Helm chart."
  exit 1
fi