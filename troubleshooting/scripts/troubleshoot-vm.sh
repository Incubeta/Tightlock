#!/bin/bash
# Troubleshooting script for Tightlock VM - uk-data-cli-superdrug

VM_NAME="tightlock-backend-eaxt"
ZONE="europe-west2-a"
PROJECT="uk-data-cli-superdrug"

echo "=== Step 1: Check if .env file exists and contains TIGHTLOCK_API_KEY ==="
gcloud compute ssh ${VM_NAME} --zone=${ZONE} --project=${PROJECT} -- \
  "cd /mnt/disks/tightlock/Tightlock && cat .env | grep TIGHTLOCK_API_KEY"

echo ""
echo "=== Step 2: Check if tightlock-api container is running ==="
gcloud compute ssh ${VM_NAME} --zone=${ZONE} --project=${PROJECT} -- \
  "sudo docker ps | grep tightlock-api"

echo ""
echo "=== Step 3: Check environment variable in running container ==="
gcloud compute ssh ${VM_NAME} --zone=${ZONE} --project=${PROJECT} -- \
  "sudo docker exec \$(sudo docker ps -q -f name=tightlock-api) printenv TIGHTLOCK_API_KEY"

echo ""
echo "=== Step 4: Check tightlock-api container logs ==="
gcloud compute ssh ${VM_NAME} --zone=${ZONE} --project=${PROJECT} -- \
  "sudo docker logs \$(sudo docker ps -q -f name=tightlock-api) --tail 50"

echo ""
echo "=== Step 5: Test API endpoint ==="
gcloud compute ssh ${VM_NAME} --zone=${ZONE} --project=${PROJECT} -- \
  "curl -v http://localhost:8081/api/v1/connect -H 'X-API-Key: test' 2>&1"
