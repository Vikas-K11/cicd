#!/usr/bin/env bash
set -euo pipefail

# Ensure variables are set
if [ -z "${STAGING_BUCKET_NAME:-}" ]; then
  echo "Error: STAGING_BUCKET_NAME environment variable must be defined."
  exit 1
fi

STAGING_URL="${STAGING_URL:-http://${STAGING_BUCKET_NAME}.s3-website-us-east-1.amazonaws.com}"

echo "=== Deploying to Staging ==="
echo "Target S3 Bucket: $STAGING_BUCKET_NAME"
echo "Staging URL: $STAGING_URL"

# Sync dist/ directory to Staging S3 Bucket
echo "Syncing build output to staging bucket..."
aws s3 sync dist/ "s3://$STAGING_BUCKET_NAME" --delete --no-progress

# Post-deploy smoke check
echo "Waiting 5 seconds for propagation..."
sleep 5

echo "Executing staging post-deploy smoke check..."
max_attempts=5
attempt=1
success=false

while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt of $max_attempts: Curling $STAGING_URL"
  status_code=$(curl -o /dev/null -s -w "%{http_code}" -k "$STAGING_URL")
  
  if [ "$status_code" -eq 200 ]; then
    echo "✔ Smoke check successful! Received HTTP 200 OK."
    success=true
    break
  else
    echo "⚠ Received HTTP status $status_code. Retrying in 5 seconds..."
    sleep 5
    attempt=$((attempt + 1))
  fi
done

if [ "$success" = false ]; then
  echo "❌ Error: Smoke check failed after $max_attempts attempts."
  exit 1
fi

echo "=== Staging Deployment Completed Successfully ==="
