#!/bin/bash
# Fix firewall rules for Tightlock on uk-data-cli-superdrug

PROJECT="uk-data-cli-superdrug"
NETWORK="tightlock-network"

echo "=== Current firewall rules ==="
gcloud compute firewall-rules list --project=${PROJECT} --filter="network:${NETWORK}"

echo ""
echo "=== Adding SSH to tightlock firewall ==="
# Update the existing tightlock-firewall rule to include SSH
gcloud compute firewall-rules update tightlock-firewall \
  --project=${PROJECT} \
  --allow=tcp:22,tcp:80,tcp:8080,tcp:8081 \
  --description="Updated to include SSH and API port 8081"

echo ""
echo "=== Verifying updated rules ==="
gcloud compute firewall-rules describe tightlock-firewall --project=${PROJECT}

echo ""
echo "=== Testing SSH connectivity ==="
gcloud compute ssh tightlock-backend-eaxt \
  --zone=europe-west2-a \
  --project=${PROJECT} \
  --command="echo 'SSH connection successful!'"

echo ""
echo "=== Checking if Docker containers are running ==="
gcloud compute ssh tightlock-backend-eaxt \
  --zone=europe-west2-a \
  --project=${PROJECT} \
  --command="sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
