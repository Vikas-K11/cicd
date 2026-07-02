#!/usr/bin/env bash
set -euo pipefail

# Ensure variables are set
if [ -z "${BLUE_BUCKET_NAME:-}" ] || \
   [ -z "${GREEN_BUCKET_NAME:-}" ] || \
   [ -z "${BLUE_BUCKET_ENDPOINT:-}" ] || \
   [ -z "${GREEN_BUCKET_ENDPOINT:-}" ] || \
   [ -z "${SSM_PARAMETER_NAME:-}" ]; then
  echo "Error: Required environment variables (BLUE_BUCKET_NAME, GREEN_BUCKET_NAME, BLUE_BUCKET_ENDPOINT, GREEN_BUCKET_ENDPOINT, SSM_PARAMETER_NAME) are missing."
  exit 1
fi

PRODUCTION_URL="${PRODUCTION_URL:-}"

echo "=== Starting Blue-Green Production Deployment ==="

# 1. Determine active and inactive colors
echo "Querying SSM parameter store for active production color..."
active_color=$(aws ssm get-parameter --name "$SSM_PARAMETER_NAME" --query "Parameter.Value" --output text)
echo "Current active color: $active_color"

if [ "$active_color" = "blue" ]; then
  inactive_color="green"
  target_bucket="$GREEN_BUCKET_NAME"
  target_endpoint="$GREEN_BUCKET_ENDPOINT"
elif [ "$active_color" = "green" ]; then
  inactive_color="blue"
  target_bucket="$BLUE_BUCKET_NAME"
  target_endpoint="$BLUE_BUCKET_ENDPOINT"
else
  echo "Error: Invalid active color returned from SSM: $active_color"
  exit 1
fi

echo "Targeting inactive environment color: $inactive_color"
echo "Target S3 Bucket: $target_bucket"
echo "Target S3 Endpoint: http://$target_endpoint"

# 2. Deploy to inactive S3 bucket
echo "Syncing build output to inactive bucket ($target_bucket)..."
aws s3 sync dist/ "s3://$target_bucket" --delete --no-progress

# 3. Smoke check the inactive bucket directly
echo "Executing smoke check on the inactive S3 origin: http://$target_endpoint"
max_attempts=5
attempt=1
success=false

while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt of $max_attempts: Curling http://$target_endpoint"
  status_code=$(curl -o /dev/null -s -w "%{http_code}" "http://$target_endpoint")
  
  if [ "$status_code" -eq 200 ]; then
    echo "✔ Inactive origin smoke check successful! Received HTTP 200 OK."
    success=true
    break
  else
    echo "⚠ Received HTTP status $status_code. Retrying in 5 seconds..."
    sleep 5
    attempt=$((attempt + 1))
  fi
done

if [ "$success" = false ]; then
  echo "❌ Error: Smoke check failed on inactive origin. Aborting deployment."
  exit 1
fi

# 4. Update SSM active color tracker
echo "Updating SSM parameter active color to: $inactive_color..."
aws ssm put-parameter \
  --name "$SSM_PARAMETER_NAME" \
  --value "$inactive_color" \
  --type "String" \
  --overwrite

echo "✔ SSM parameter store updated."

# 5. Print summary to Job Summary
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat <<EOF >> "$GITHUB_STEP_SUMMARY"
## 🚀 Production Deployment Completed (Blue-Green Switch)

| Step | Detail |
|---|---|
| **Deploy Target** | \`$inactive_color\` (\`$target_bucket\`) |
| **Previous Version** | \`$active_color\` |
| **Staging URL** | http://$target_endpoint |

### ↩️ Rollback Instructions
To rollback to the previous version (\`$active_color\`), run:
\`\`\`bash
export SSM_PARAMETER_NAME="$SSM_PARAMETER_NAME"
./scripts/rollback.sh
\`\`\`
EOF
fi

echo "=== Production deployment to $inactive_color environment complete! ==="
