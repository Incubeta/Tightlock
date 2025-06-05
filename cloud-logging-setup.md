# Cloud Logging Setup for Tightlock

This document explains how to configure Cloud Logging to capture errors from Docker containers, particularly the tightlock-api container.

## Overview

The solution consists of:

1. Configuring Docker containers to use the json-file logging driver with appropriate tags
2. Setting up a Stackdriver logging agent container to collect and process Docker logs
3. Creating Fluentd configuration files to properly format and forward logs to Google Cloud Logging

## Files Created/Modified

### 1. docker-compose.yaml

- Added logging configuration to the tightlock-api and airflow containers
- Added a stackdriver-logging service that mounts Docker logs and our custom configuration

### 2. fluentd-config/docker-containers.conf

This configuration file tells the Stackdriver agent how to collect and process Docker container logs:

- Captures logs from all Docker containers
- Adds container metadata to logs
- Special handling for tightlock-api and airflow containers to properly set severity levels
- Forwards logs to Google Cloud Logging

### 3. fluentd-config/google-fluentd.conf

This is the main configuration file for the Stackdriver logging agent:

- Includes our Docker container configuration
- Sets system-wide logging parameters
- Configures buffer settings for Google Cloud Logging

## How It Works

1. Docker containers write logs to json-file log files
2. The Stackdriver logging agent container mounts these log files
3. The agent processes the logs according to our configuration
4. Logs are forwarded to Google Cloud Logging with proper metadata and severity levels

## Applying Changes

To apply these changes on your VM:

1. Copy the updated docker-compose.yaml file to your VM
2. Create the fluentd-config directory and copy the configuration files
3. Restart the Docker containers:

```bash
docker-compose down
docker-compose up -d
```

## Verifying the Setup

After applying the changes, you can verify that logs are being properly sent to Google Cloud Logging:

1. Generate some errors in the tightlock-api container
2. Check the Google Cloud Logging console for your project
3. Filter logs by resource type "container" and service name "tightlock-api"

## Troubleshooting

If logs are not appearing in Google Cloud Logging:

1. Check that the stackdriver-logging container is running:
   ```bash
   docker ps | grep stackdriver-logging
   ```

2. Check the logs of the stackdriver-logging container:
   ```bash
   docker logs stackdriver-logging
   ```

3. Verify that the VM has the necessary permissions to write to Google Cloud Logging
