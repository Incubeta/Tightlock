# Troubleshooting "Invalid connection code" 500 Error

## Quick Diagnosis

Run the troubleshooting script:
```bash
./troubleshoot-vm.sh
```

## Common Issues & Fixes

### Issue 1: TIGHTLOCK_API_KEY Not Set in .env File

**Symptoms**: The .env file is missing or doesn't contain TIGHTLOCK_API_KEY

**Fix**:
```bash
# SSH into the VM
gcloud compute ssh tightlock-backend-eaxt --zone=europe-west2-a --project=uk-data-cli-superdrug

# Navigate to Tightlock directory
cd /mnt/disks/tightlock/Tightlock

# Check if .env exists
ls -la .env

# If missing, recreate it
sudo bash ./run_tightlock.sh -e prod -i non-interactive

# OR manually add the API key to .env
echo "TIGHTLOCK_API_KEY=your-api-key-here" | sudo tee -a .env
```

### Issue 2: Environment Variable Not Passed to Docker Container

**Symptoms**: .env file has the key, but the container doesn't see it

**Fix**:
```bash
# Restart the containers to pick up the .env file
cd /mnt/disks/tightlock/Tightlock
sudo docker-compose down
sudo docker-compose up -d

# Verify the variable is set in the container
sudo docker exec $(sudo docker ps -q -f name=tightlock-api) printenv TIGHTLOCK_API_KEY
```

### Issue 3: Wrong API Key in Client

**Symptoms**: Container has correct key, but client is using wrong one

**Steps**:
1. Get the correct API key from the VM:
```bash
gcloud compute ssh tightlock-backend-eaxt --zone=europe-west2-a --project=uk-data-cli-superdrug -- \
  "cd /mnt/disks/tightlock/Tightlock && cat .env | grep TIGHTLOCK_API_KEY"
```

2. Regenerate the connection code:
```bash
# Get the API key and VM IP
API_KEY="<key-from-above>"
VM_IP="<your-vm-external-ip>"

# Generate connection code (base64 encoded JSON)
echo "{\"apiKey\": \"${API_KEY}\", \"address\": \"${VM_IP}\"}" | base64
```

3. Update the connection code in:
   - uk-data-cli-superdrug configuration
   - 1pd-scheduler.dev workspace settings

### Issue 4: Security Check Failing

**Symptoms**: 500 error from security.py

**Cause**: The check in tightlock_api/app/security.py:30 is failing

**Debug**:
```bash
# Check the API logs for the actual error
sudo docker logs $(sudo docker ps -q -f name=tightlock-api) --tail 100 | grep -i error
```

**Common fixes**:
- TIGHTLOCK_API_KEY is None (not set in environment)
- X-API-Key header is missing from the request
- API key contains special characters causing parsing issues

### Issue 5: Port or Network Issues

**Symptoms**: Can't reach the API at all

**Check**:
```bash
# Test from within the VM
gcloud compute ssh tightlock-backend-eaxt --zone=europe-west2-a --project=uk-data-cli-superdrug -- \
  "curl http://localhost:8081/api/v1/connect -H 'X-API-Key: your-key' -v"

# Check if the port is exposed
gcloud compute ssh tightlock-backend-eaxt --zone=europe-west2-a --project=uk-data-cli-superdrug -- \
  "sudo netstat -tulpn | grep 80"

# Check firewall rules
gcloud compute firewall-rules list --project=uk-data-cli-superdrug | grep tightlock
```

## How to Get the Current Connection Code

```bash
# SSH into VM and get the API key
API_KEY=$(gcloud compute ssh tightlock-backend-eaxt --zone=europe-west2-a --project=uk-data-cli-superdrug -- \
  "cd /mnt/disks/tightlock/Tightlock && cat .env | grep TIGHTLOCK_API_KEY | cut -d'=' -f2")

# Get the external IP
VM_IP=$(gcloud compute instances describe tightlock-backend-eaxt \
  --zone=europe-west2-a \
  --project=uk-data-cli-superdrug \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Generate and display the connection code
echo "{\"apiKey\": \"${API_KEY}\", \"address\": \"${VM_IP}\"}" | base64
```

## Testing the API Manually

```bash
# Test with curl (replace YOUR_API_KEY and YOUR_VM_IP)
curl -X POST http://YOUR_VM_IP:8081/api/v1/connect \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -v

# Expected response: 200 OK with version info
# Error response: 401 if wrong key, 500 if server error
```

## Check Container Health

```bash
# List all containers
sudo docker ps -a

# Check specific container logs
sudo docker logs tightlock-api-1
sudo docker logs airflow-webserver-1

# Check container resource usage
sudo docker stats --no-stream
```

## If All Else Fails: Full Restart

```bash
cd /mnt/disks/tightlock/Tightlock

# Stop everything
sudo docker-compose down

# Remove old containers
sudo docker-compose rm -f

# Rebuild and restart
sudo docker-compose up -d --build

# Check logs
sudo docker-compose logs -f tightlock-api
```
