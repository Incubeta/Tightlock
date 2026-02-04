#!/bin/bash
# Fix disk space issues on Tightlock VM

PROJECT="uk-data-cli-superdrug"
VM_NAME="tightlock-backend-eaxt"
ZONE="europe-west2-a"
DISK_NAME="tightlock-backend-eaxt"
NEW_SIZE="50"  # GB - increase to 50GB (can be adjusted)

echo "=== Current disk size ==="
gcloud compute disks describe ${DISK_NAME} --zone=${ZONE} --project=${PROJECT} --format="get(sizeGb)"

echo ""
echo "=== Resizing disk to ${NEW_SIZE}GB ==="
echo "Note: This operation can be done while the VM is running"
gcloud compute disks resize ${DISK_NAME} \
  --size=${NEW_SIZE} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --quiet

echo ""
echo "=== Waiting for SSH keys to propagate (30 seconds) ==="
sleep 30

echo ""
echo "=== Expanding the filesystem to use the new disk space ==="
# Try to SSH and expand the filesystem
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="sudo growpart /dev/sda 1 && sudo resize2fs /dev/sda1"

echo ""
echo "=== Checking disk usage after resize ==="
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="df -h /"

echo ""
echo "=== Cleaning up Docker resources ==="
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="sudo docker system prune -f"

echo ""
echo "=== Checking /mnt/disks/tightlock/Tightlock directory ==="
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="cd /mnt/disks/tightlock/Tightlock && du -sh * 2>/dev/null | sort -rh | head -20"

echo ""
echo "=== Restarting Docker containers ==="
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="cd /mnt/disks/tightlock/Tightlock && sudo docker-compose restart"

echo ""
echo "=== Checking container status ==="
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="sudo docker ps --format 'table {{.Names}}\t{{.Status}}'"

echo ""
echo "=== Getting TIGHTLOCK_API_KEY ==="
gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT} \
  --command="cd /mnt/disks/tightlock/Tightlock && cat .env | grep TIGHTLOCK_API_KEY"

echo ""
echo "=== Done! ==="
