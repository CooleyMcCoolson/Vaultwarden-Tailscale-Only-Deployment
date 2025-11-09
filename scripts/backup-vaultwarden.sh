#!/bin/bash
# Vaultwarden Backup Script
# Runs daily at 2:30 AM via cron/User Scripts
# Backs up entire data directory (includes SQLite DB + WAL files, attachments, sends, keys)

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/cache_nvme/appdata/vaultwarden/backups"
DATA_DIR="/mnt/cache_nvme/appdata/vaultwarden/data"

echo "[INFO] Starting vaultwarden backup at $(date)"

# Create tar archive of entire data directory
# SQLite DB + WAL files ensure consistency even while running
tar -czf "${BACKUP_DIR}/vaultwarden-backup-${BACKUP_DATE}.tar.gz" -C "${DATA_DIR}" .

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Backup created: ${BACKUP_DIR}/vaultwarden-backup-${BACKUP_DATE}.tar.gz"
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/vaultwarden-backup-${BACKUP_DATE}.tar.gz" | cut -f1)
    echo "[INFO] Backup size: ${BACKUP_SIZE}"
else
    echo "[ERROR] Backup failed!"
    exit 1
fi

# Keep last 7 daily backups
DELETED=$(find "${BACKUP_DIR}" -name "vaultwarden-backup-*.tar.gz" -mtime +7 -delete -print | wc -l)
if [ $DELETED -gt 0 ]; then
    echo "[INFO] Deleted $DELETED old backup(s)"
fi

# Verify archive integrity
if tar -tzf "${BACKUP_DIR}/vaultwarden-backup-${BACKUP_DATE}.tar.gz" >/dev/null 2>&1; then
    echo "[SUCCESS] Backup integrity verified"
else
    echo "[ERROR] Backup integrity check failed!"
    exit 1
fi

echo "[INFO] Backup completed successfully at $(date)"
exit 0
