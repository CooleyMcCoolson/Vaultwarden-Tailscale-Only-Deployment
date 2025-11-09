#!/bin/bash
# Vaultwarden Docker Container Deployment Script
#
# This script deploys the vaultwarden container with maximum security hardening
#
# SECURITY: Admin token is hashed with Argon2id for security

# Configuration
# IMPORTANT: Replace this with your generated Argon2id hash!
# To generate: docker run --rm -it vaultwarden/server:alpine /vaultwarden hash --preset owasp
ADMIN_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$REPLACE_WITH_YOUR_HASHED_TOKEN'
CONTAINER_NAME="vaultwarden"
# IMPORTANT: Pin image to SHA256 digest to prevent tag poisoning
# To get digest: docker pull vaultwarden/server:1.32.5-alpine && docker inspect vaultwarden/server:1.32.5-alpine --format='{{index .RepoDigests 0}}'
IMAGE="vaultwarden/server:1.32.5-alpine@sha256:76d46d32ba4120b022e0a69487f9fd79fc52e2765b1650c5c51a5dd912a3c288"
DOMAIN="https://your-server.your-tailnet.ts.net"
DATA_PATH="/mnt/cache_nvme/appdata/vaultwarden/data"
GRAYLOG_HOST="YOUR_GRAYLOG_HOST:12201"  # Optional - remove --log-driver lines if not using

# Stop and remove existing container (if any)
echo "[INFO] Stopping existing container (if running)..."
docker stop ${CONTAINER_NAME} 2>/dev/null
docker rm ${CONTAINER_NAME} 2>/dev/null

# Deploy vaultwarden container
echo "[INFO] Deploying vaultwarden container..."
docker run -d \
  --name=${CONTAINER_NAME} \
  --hostname=${CONTAINER_NAME} \
  --user 99:100 \
  --network=traefik_proxy \
  -e PUID=99 \
  -e PGID=100 \
  -e TZ=America/New_York \
  -e DOMAIN=${DOMAIN} \
  -e SIGNUPS_ALLOWED=false \
  -e INVITATIONS_ALLOWED=true \
  -e WEBSOCKET_ENABLED=true \
  -e WEB_VAULT_ENABLED=true \
  -e ADMIN_TOKEN="${ADMIN_TOKEN}" \
  -e LOG_LEVEL=info \
  -e EXTENDED_LOGGING=true \
  -e LOGIN_RATELIMIT_MAX_BURST=10 \
  -e LOGIN_RATELIMIT_SECONDS=60 \
  -e ADMIN_RATELIMIT_MAX_BURST=3 \
  -e ADMIN_RATELIMIT_SECONDS=300 \
  -p 127.0.0.1:8097:80 \
  -v ${DATA_PATH}:/data:rw \
  --log-driver=gelf \
  --log-opt gelf-address=udp://${GRAYLOG_HOST} \
  --log-opt tag=vaultwarden \
  --security-opt no-new-privileges:true \
  --read-only \
  --tmpfs /tmp \
  --health-cmd="curl -f http://localhost:80/alive || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  --health-start-period=10s \
  --memory=512m \
  --cpus=1.0 \
  --restart=unless-stopped \
  ${IMAGE}

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Vaultwarden container deployed successfully!"
    echo ""
    echo "Container Details:"
    docker ps --filter name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "Next steps:"
    echo "1. Wait 10 seconds for health check to pass"
    echo "2. Check logs: docker logs ${CONTAINER_NAME}"
    echo "3. Test access: https://your-server.your-tailnet.ts.net (via Tailscale)"
    echo "4. Configure monitoring in Uptime Kuma (optional)"
    echo "5. Set up backup schedule in cron/User Scripts"
else
    echo "[ERROR] Failed to deploy vaultwarden container!"
    echo "Check docker logs for details."
    exit 1
fi

# Wait for health check
echo ""
echo "[INFO] Waiting for health check..."
sleep 15

HEALTH_STATUS=$(docker inspect ${CONTAINER_NAME} --format '{{.State.Health.Status}}' 2>/dev/null)
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo "[SUCCESS] Container is healthy!"
else
    echo "[WARNING] Container health status: ${HEALTH_STATUS}"
    echo "Check logs: docker logs ${CONTAINER_NAME}"
fi

exit 0
