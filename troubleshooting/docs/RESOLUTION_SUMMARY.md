# Tightlock 500 Error - Resolution Summary

## Root Cause Identified ✅

The "Invalid connection code" 500 error was caused by **FULL DISK SPACE** on the VM.

### Issues Found and Fixed:

1. **Disk Space**: VM had only 10GB disk which was completely full
   - ✅ **FIXED**: Resized disk to 50GB
   - ✅ **FIXED**: VM rebooted to apply filesystem expansion

2. **Firewall Rules**: Missing ports in firewall
   - ✅ **FIXED**: Added ports 22, 80, 8080, and 8081 to tightlock-firewall

3. **API Status**: API is now **WORKING** ✅
   - Confirmed by successful 401 "Invalid API Key" response (vs previous 500 errors)
   - Containers are running
   - Authentication layer is functional

## Current Status

- VM: `tightlock-backend-eaxt` in `europe-west2-a`
- Project: `uk-data-cli-superdrug`
- External IP: `35.246.91.186`
- Disk: Resized from 10GB → 50GB ✅
- API: **RESPONDING** ✅
- Containers: **RUNNING** ✅

## What You Need To Do

### Option 1: Get API Key via Google Cloud Console (RECOMMENDED)

1. Go to: https://console.cloud.google.com/compute/instances?project=uk-data-cli-superdrug

2. Find `tightlock-backend-eaxt` and click **SSH** button (opens browser SSH)

3. Run these commands:
   ```bash
   cd /mnt/disks/tightlock/Tightlock
   cat .env | grep TIGHTLOCK_API_KEY
   ```

4. Copy the API key value

5. Get the VM IP:
   ```bash
   curl ifconfig.me
   ```
   (Should be: 35.246.91.186)

6. Generate the connection code:
   ```bash
   echo "{\"apiKey\": \"YOUR_API_KEY_HERE\", \"address\": \"35.246.91.186\"}" | base64
   ```

7. Update this connection code in:
   - uk-data-cli-superdrug configuration
   - 1pd-scheduler.dev workspace settings

### Option 2: Use gcloud from Your Machine

If you have gcloud configured with appropriate permissions:

```bash
# Get the API key
gcloud compute ssh tightlock-backend-eaxt \
  --zone=europe-west2-a \
  --project=uk-data-cli-superdrug \
  --command="cd /mnt/disks/tightlock/Tightlock && cat .env | grep TIGHTLOCK_API_KEY"

# Then generate connection code as shown above
```

### Option 3: Check Terraform Outputs

If you have the Terraform state from the original deployment:

```bash
cd installer/gcp
terraform output Connection_Code
```

## Verify the Fix

Once you have the correct API key, test it:

```bash
curl -X POST http://35.246.91.186:80/api/v1/connect \
  -H "X-API-Key: YOUR_ACTUAL_API_KEY" \
  -H "Content-Type: application/json"
```

Expected response:
```json
{"version":"<version-number>"}
```

## Check Container Health

To verify all containers are healthy (via Cloud Console SSH):

```bash
# Check running containers
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Check disk usage (should now have plenty of space)
df -h /

# Check logs if needed
cd /mnt/disks/tightlock/Tightlock
sudo docker-compose logs -f tightlock-api
```

## Prevention - Monitor Disk Usage

To prevent this from happening again, you should:

1. **Set up disk usage alerts** in Google Cloud Console:
   - Go to Monitoring → Alerting
   - Create alert for disk usage > 80%

2. **Regular cleanup** of Docker resources:
   ```bash
   sudo docker system prune -f
   ```

3. **Consider increasing disk further** if usage grows:
   ```bash
   gcloud compute disks resize tightlock-backend-eaxt \
     --size=100 \
     --zone=europe-west2-a \
     --project=uk-data-cli-superdrug
   ```

## Summary

The 500 error was **NOT** an "Invalid connection code" problem - it was the API failing due to no disk space.

Now that disk space is resolved:
- API is working ✅
- Containers are running ✅
- You just need to retrieve the correct API key and update your client configuration

## Need Help?

If you encounter any issues:

1. Check API is responding:
   ```bash
   curl -X POST http://35.246.91.186:80/api/v1/connect \
     -H "X-API-Key: test" -H "Content-Type: application/json"
   ```
   Should return: `{"detail":"Invalid API Key"}` (this is good!)

2. Check container logs via Cloud Console SSH:
   ```bash
   cd /mnt/disks/tightlock/Tightlock
   sudo docker-compose logs --tail=100 tightlock-api
   ```

3. Restart containers if needed:
   ```bash
   cd /mnt/disks/tightlock/Tightlock
   sudo docker-compose restart
   ```
