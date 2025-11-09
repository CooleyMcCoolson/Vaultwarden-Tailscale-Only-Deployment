#!/bin/bash
# Vaultwarden Update Script
# Run this quarterly or when security updates are announced
#
# Usage: ./update-vaultwarden.sh [version]
# Example: ./update-vaultwarden.sh 1.33.0
#          ./update-vaultwarden.sh latest

set -e  # Exit on error

VERSION="${1:-latest}"
BACKUP_DIR="/mnt/cache_nvme/appdata/vaultwarden/backups"
# IMPORTANT: Replace this with your generated Argon2id hash!
ADMIN_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$REPLACE_WITH_YOUR_HASHED_TOKEN'

echo "=========================================="
echo "Vaultwarden Update Script"
echo "=========================================="
echo ""
echo "Target version: $VERSION"
echo "Current time: $(date)"
echo ""

# Step 1: Check current version
echo "[1/8] Checking current version..."
CURRENT_VERSION=$(docker inspect vaultwarden --format '{{.Config.Image}}' 2>/dev/null || echo "Not running")
echo "Current: $CURRENT_VERSION"
echo ""

# Step 2: Pull new image
echo "[2/8] Pulling new image..."
if [ "$VERSION" = "latest" ]; then
    docker pull vaultwarden/server:alpine
else
    docker pull vaultwarden/server:$VERSION-alpine
fi
echo ""

# Step 3: Create backup BEFORE updating
echo "[3/8] Creating pre-update backup..."
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "${BACKUP_DIR}/pre-update-${BACKUP_DATE}.tar.gz" -C /mnt/cache_nvme/appdata/vaultwarden/data .
echo "Backup created: pre-update-${BACKUP_DATE}.tar.gz"
echo ""

# Step 4: Show changelog reminder
echo "[4/8] IMPORTANT: Have you read the changelog?"
echo "Visit: https://github.com/dani-garcia/vaultwarden/releases"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Step 5: Stop and remove old container
echo "[5/8] Stopping current container..."
docker stop vaultwarden
docker rm vaultwarden
echo ""

# Step 6: Deploy new version
echo "[6/8] Deploying new version..."
IMAGE="vaultwarden/server:${VERSION}-alpine"
if [ "$VERSION" = "latest" ]; then
    IMAGE="vaultwarden/server:alpine"
fi

docker run -d \
  --name=vaultwarden \
  --hostname=vaultwarden \
  --network=traefik_proxy \
  -e PUID=99 \
  -e PGID=100 \
  -e TZ=America/New_York \
  -e DOMAIN=https://your-server.your-tailnet.ts.net \
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
  -v /mnt/cache_nvme/appdata/vaultwarden/data:/data:rw \
  --log-driver=gelf \
  --log-opt gelf-address=udp://YOUR_GRAYLOG_HOST:12201 \
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

echo ""

# Step 7: Wait for health check
echo "[7/8] Waiting for container to become healthy..."
sleep 15

HEALTH=$(docker inspect vaultwarden --format '{{.State.Health.Status}}')
if [ "$HEALTH" = "healthy" ]; then
    echo "✅ Container is healthy!"
else
    echo "⚠️  WARNING: Container health status: $HEALTH"
    echo "Check logs: docker logs vaultwarden"
fi
echo ""

# Step 8: Verification tests
echo "[8/8] Running verification tests..."

# Test 1: HTTPS access
echo "  - Testing HTTPS access..."
if curl -f https://your-server.your-tailnet.ts.net > /dev/null 2>&1; then
    echo "    ✅ HTTPS working"
else
    echo "    ❌ HTTPS FAILED!"
fi

# Test 2: Check logs for errors
echo "  - Checking logs for errors..."
ERROR_COUNT=$(docker logs vaultwarden 2>&1 | grep -i error | wc -l)
if [ $ERROR_COUNT -eq 0 ]; then
    echo "    ✅ No errors in logs"
else
    echo "    ⚠️  Found $ERROR_COUNT error(s) in logs"
fi

# Test 3: Show version
echo "  - New version:"
docker inspect vaultwarden --format '    {{.Config.Image}}'

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test login in browser: https://your-server.your-tailnet.ts.net"
echo "2. Verify your passwords are accessible"
echo "3. Test sync on mobile devices"
echo "4. If anything is broken, rollback:"
echo "   docker stop vaultwarden && docker rm vaultwarden"
echo "   tar -xzf ${BACKUP_DIR}/pre-update-${BACKUP_DATE}.tar.gz -C /mnt/cache_nvme/appdata/vaultwarden/data"
echo "   # Then redeploy old version"
echo ""
echo "Update log: $(date) - Updated to $VERSION" >> /mnt/cache_nvme/appdata/vaultwarden/update-log.txt
