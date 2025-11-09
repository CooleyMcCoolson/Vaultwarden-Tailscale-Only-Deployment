# Vaultwarden Tailscale-Only Deployment

**Production Password Manager - Maximum Security Configuration**

This repository contains the complete deployment configuration for a production-grade, self-hosted vaultwarden (Bitwarden-compatible) password manager with **zero public internet exposure**.

> **IMPORTANT**: This repository has been sanitized for public release. See [SANITIZATION_NOTE.md](SANITIZATION_NOTE.md) for required configuration changes before deployment.

## 🎯 Project Overview

**Access Model**: Tailscale VPN Only
**Security Level**: Maximum (Defense-in-Depth)
**Security Rating**: 9.5/10 (Hardened - SHA256 pinned, non-root, tested backups)

### Key Security Features
- ✅ **Zero Public Exposure** - Only accessible via Tailscale VPN
- ✅ **HTTPS Everywhere** - TLS with Tailscale-issued certificate (valid, no warnings)
- ✅ **Rate Limiting** - Brute force protection (Traefik: 100/min avg, 50 burst)
- ✅ **Read-Only Container** - Immutable filesystem
- ✅ **Resource Limits** - DoS prevention (512MB RAM, 1 CPU)
- ✅ **Automated Backups** - Daily encrypted backups (Restic AES-256, tested restore)
- ✅ **Container Hardening** - Non-root user (uid=99), SHA256 pinned image
- ✅ **Security Headers** - HSTS, CSP, X-Frame-Options (verified working)
- ✅ **Logging** - Graylog integration (alerts to be configured)

## 📋 Repository Contents

```
├── README.md                         # This file
├── SANITIZATION_NOTE.md              # Required configuration changes
├── docs/
│   └── android-tailscale-setup.md    # Mobile client configuration
├── config/
│   ├── docker/
│   │   └── vaultwarden-run.sh        # Docker container deployment script
│   └── traefik/
│       └── vaultwarden.yml           # Traefik routing configuration
├── scripts/
│   ├── backup-vaultwarden.sh         # Automated backup script
│   └── update-vaultwarden.sh         # Update script
└── .gitignore                        # Secrets excluded from git
```

## 🚀 Quick Start

### Prerequisites
- ✅ Docker host (Unraid, Linux, etc.)
- ✅ Tailscale VPN configured and connected
- ✅ Traefik reverse proxy running
- ✅ Basic Docker and networking knowledge

### Deployment Steps

1. **Clone this repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/VaultWarden-GitHub.git
   cd VaultWarden-GitHub
   ```

2. **Read SANITIZATION_NOTE.md** and replace all placeholders with your values

3. **Create directories**:
   ```bash
   mkdir -p /opt/vaultwarden/{data,backups,certs}
   # Adjust path for your environment
   ```

4. **TLS certificate**:
   - Automatically provided by Tailscale (valid, trusted certificate)
   - No manual certificate generation needed

5. **Deploy vaultwarden container**:
   ```bash
   sh config/docker/vaultwarden-run.sh
   ```

6. **Configure Traefik**:
   ```bash
   cp config/traefik/vaultwarden.yml /path/to/traefik/config/
   docker restart traefik
   ```

7. **Set up backups** (Optional):
   ```bash
   cp scripts/backup-vaultwarden.sh /path/to/scripts/
   # Schedule in cron or equivalent: Daily at 2:30 AM
   ```

### Post-Deployment Access

#### Step 1: Access Vaultwarden

1. Ensure Tailscale is **connected**
2. Open browser: `https://your-server.your-tailnet.ts.net`
3. You should see Vaultwarden login page (no certificate warnings)

**Note**: The `.ts.net` domain auto-resolves via Tailscale MagicDNS - no manual DNS configuration needed!

#### Step 2: Create User Account

**Via Admin Panel (Required - signups are disabled):**
1. Navigate to: `https://your-server.your-tailnet.ts.net/admin`
2. Enter admin token (plaintext version you generated)
3. Click "Invite User" → Enter email → Send invitation link
4. Use link to create account with strong master password

#### Step 3: Complete Setup

1. Login with new account
2. Create strong master password (20+ characters)
3. **Store password securely** - cannot be recovered if lost!
4. Enable 2FA (Settings → Two-step Login)

## 🏗️ Architecture

```
┌─────────────────┐
│  Mobile/Laptop  │
│  (Tailscale)    │
└────────┬────────┘
         │ VPN Tunnel
         ▼
┌─────────────────────┐
│  Router/Firewall    │
│  10.0.0.1           │
│  (Subnet Router)    │
└────────┬────────────┘
         │ LAN (10.0.0.0/24)
         ▼
┌──────────────────────────────┐
│  Server (10.0.0.x)           │
│  ┌────────────────────────┐  │
│  │  Traefik:443 (HTTPS)   │  │
│  │  - TLS Termination     │  │
│  │  - Security Headers    │  │
│  │  - Rate Limiting       │  │
│  └──────────┬─────────────┘  │
│             │ Docker Network │
│             ▼                 │
│  ┌─────────────────────────┐ │
│  │  vaultwarden:80         │ │
│  │  (127.0.0.1:8097)       │ │
│  │  - SQLite DB            │ │
│  │  - Attachments          │ │
│  │  - Encryption Keys      │ │
│  └─────────────────────────┘ │
└──────────────────────────────┘
```

## 🔐 Security Model

### Defense-in-Depth Layers

1. **Network Layer**
   - Tailscale VPN required (WireGuard-based encryption)
   - No public port forwarding
   - Container port bound to localhost only

2. **Transport Layer**
   - TLS 1.2+ (HTTPS)
   - Tailscale-issued certificate (valid, trusted)
   - HSTS with preload

3. **Application Layer**
   - Master password (client-side encryption)
   - Optional 2FA (TOTP)
   - Admin token (64-char random, Argon2id hashed)
   - Signups disabled

4. **Container Layer**
   - Read-only filesystem (--read-only)
   - No new privileges (--security-opt no-new-privileges)
   - Resource limits (512MB RAM, 1 CPU)
   - Non-root user (--user 99:100, verified uid=99)
   - SHA256 image pinning (prevents tag poisoning)

5. **Monitoring Layer**
   - Graylog log aggregation (centralized logging)
   - Docker health checks (30s intervals)
   - Future: Alert configuration for failed logins

## 💾 Backup Strategy

**Primary Backup: Restic (Recommended)**
- **Encryption**: AES-256 via Restic
- **Frequency**: Daily automated backups
- **Destination**: Off-site backup server
- **Last Tested**: Restore procedure verified successfully
- **Path**: Entire `/opt/vaultwarden/` directory

**Secondary Backup: Local Script (Optional)**
- **Script**: `scripts/backup-vaultwarden.sh`
- **Purpose**: Additional local backup for quick restore
- **Features**: Integrity checking with tar verification
- **Frequency**: Daily automated backups (2:30 AM recommended)
- **Retention**: 7 days local (configurable)

**What's Backed Up**:
- SQLite database (db.sqlite3 + WAL files)
- RSA encryption keys (**CRITICAL** - cannot recover without these!)
- Attachments and sends
- Configuration files

**Recovery Objectives**:
- **RTO** (Recovery Time): 30 minutes
- **RPO** (Recovery Point): 24 hours

**Backup Verification**: ✅ Restore procedure tested and working

## 📥 Importing from Cloud Bitwarden

### Before You Begin

**CRITICAL SECURITY WARNING**: Export files contain ALL your passwords in plaintext (even if "encrypted"). DELETE immediately after import!

### Export Process

1. Log into cloud Bitwarden (bitwarden.com)
2. Go to Tools → Export Vault
3. Select **"Encrypted .json (with file attachments)"** format
4. Click "Confirm Format" and enter master password
5. Download will include:
   - `bitwarden_export_YYYYMMDDHHMMSS.json` - Encrypted password data
   - Individual attachment files (if any exist)

### Import Process

1. Access your vaultwarden instance: `https://your-server.your-tailnet.ts.net`
2. Login with your new account
3. Go to Tools → Import Data
4. Select format: "Bitwarden (json)"
5. Choose the exported .json file
6. Click "Import Data"
7. Verify import success: Check password count matches cloud Bitwarden

### Attachment Limitation (IMPORTANT)

**Known Issue**: Bitwarden encrypted exports include attachment FILES but NOT database metadata linking them to items.

**Impact**: Attachments must be manually re-uploaded through the web interface after import.

**Process**:
1. Export includes attachment files (saved alongside .json file)
2. Import the .json file (imports passwords but NOT attachment associations)
3. For each item with attachments:
   - Open the item in web vault
   - Click "Attachments"
   - Upload the corresponding file(s) manually
   - Delete original exported attachment file

**Note**: This is a limitation of Bitwarden's export format, not vaultwarden.

### Post-Import Security

**IMMEDIATELY** after successful import:

1. **Delete export files**:
   ```bash
   # On Windows
   del bitwarden_export_*.json
   del bitwarden_export_*_attachments\*

   # On Linux/Mac
   rm bitwarden_export_*.json
   rm -rf bitwarden_export_*_attachments/
   ```

2. **Verify deletion**: Empty Recycle Bin / Trash

3. **Verify import**: Check password count matches original

4. **Optional**: Export a new backup from your self-hosted instance

## 📱 Client Setup

### Android Tailscale Split-Tunnel Configuration

See [docs/android-tailscale-setup.md](docs/android-tailscale-setup.md) for detailed mobile configuration.

**Quick Summary**:
1. Install Tailscale app
2. Settings → Use Tailscale DNS → **ON**
3. Settings → Accept subnet routes → **ON**
4. Settings → Split DNS → Use Tailscale DNS only for: `*.ts.net`

### Bitwarden App Setup
1. Install Bitwarden app from Play Store/App Store
2. Tap ⚙️ icon on login screen
3. Server URL: `https://your-server.your-tailnet.ts.net`
4. Save, then login/create account

**Note**: Create account via admin panel first (signups disabled)

## 🔧 Maintenance

### Regular Tasks

**Daily** (Automated):
- Backups at 2:30 AM
- Health checks every 30 seconds
- Log shipping to Graylog (if configured)

**Weekly**:
- Review logs for suspicious activity
- Verify backup sizes

**Monthly**:
- Test backup restore
- Check for vaultwarden updates
- Review user accounts

**Annually**:
- Rotate admin token
- Review security posture

### Updating Vaultwarden

```bash
# Use the provided update script
sh scripts/update-vaultwarden.sh

# Or manually:
# 1. Backup first!
sh scripts/backup-vaultwarden.sh

# 2. Pull new image
docker pull vaultwarden/server:latest

# 3. Recreate container
docker stop vaultwarden && docker rm vaultwarden
sh config/docker/vaultwarden-run.sh

# 4. Verify
docker ps | grep vaultwarden
curl https://your-server.your-tailnet.ts.net
```

## 📊 Monitoring

### Health Checks
- **Docker**: Built-in health check every 30 seconds
- **Graylog**: Centralized logging with alerts (optional)

### Important Metrics
- Login success/failure rates
- Container resource usage
- Backup completion status
- API response times

### Graylog Queries (if using)
```
# Failed logins
tag:vaultwarden AND message:"Invalid password"

# Admin access
tag:vaultwarden AND message:"/admin"

# Errors
tag:vaultwarden AND level:ERROR
```

## 🔧 Troubleshooting

### DNS Resolution Issues

**Problem**: `your-server.your-tailnet.ts.net` won't resolve

**Mobile/Mac/Linux Solution**: Ensure Tailscale DNS is enabled
1. Open Tailscale app/settings
2. Enable "Use Tailscale DNS" or "Accept DNS"
3. Verify Tailscale is connected (not just enabled)

**Windows Solution**: Add hosts file entry
1. Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
2. Add line: `100.x.x.x your-server.your-tailnet.ts.net`
3. Save file
4. Flush DNS cache: `ipconfig /flushdns`

**Note**: Windows may not properly resolve `.ts.net` domains via Tailscale DNS.

### Certificate Warnings

**Problem**: Browser shows certificate warning

**Expected**: No certificate warnings with Tailscale hostname

**If you see a warning**:
1. Verify you're accessing `https://your-server.your-tailnet.ts.net` (NOT the IP address)
2. Check Tailscale is connected and DNS is working
3. On Windows: Verify hosts file entry is correct
4. Try hard refresh: Ctrl+Shift+R

**Note**: Accessing via IP will show certificate warning due to hostname mismatch - this is expected.

### Container Health Check

**Verify container is running:**
```bash
docker ps | grep vaultwarden
docker inspect vaultwarden | grep -A5 Health
```

**Check logs:**
```bash
docker logs vaultwarden --tail 50
```

**Restart container:**
```bash
docker restart vaultwarden
```

---

## 🚨 Emergency Procedures

### If Server is Compromised
1. Disconnect: `docker stop vaultwarden`
2. Export vault from trusted client
3. Change all passwords from clean device
4. Restore from backup to clean system
5. Investigate logs

### If Master Password is Lost
⚠️ **NO RECOVERY POSSIBLE**

Options:
- Use emergency access (if configured)
- Use password hint
- Last resort: Reset account (loses all data)

## ⚠️ Important Notes

### This is NOT Bitwarden
- Vaultwarden is an **unofficial** Bitwarden-compatible server
- Do NOT report issues to official Bitwarden channels
- See: https://github.com/dani-garcia/vaultwarden

### Tailscale HTTPS Certificate
- Valid, trusted certificate issued by Tailscale
- No browser warnings or manual certificate installation needed
- Automatic renewal handled by Tailscale

### Data Responsibility
- YOU are responsible for backups
- Test restore procedures regularly
- Keep admin token secure
- **RSA keys cannot be recovered if lost!**

## 🤝 Contributing

This is a reference homelab deployment. If you're adapting for your own use:
1. Change all IP addresses and domains
2. Generate new admin token (see SANITIZATION_NOTE.md)
3. Configure TLS certificates for your environment
4. Review and adapt security settings
5. Test thoroughly before production use

## 📄 License

MIT License - Use at your own risk

## 🔗 References

- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Traefik v3 Docs](https://doc.traefik.io/traefik/)
- [Bitwarden Clients](https://bitwarden.com/download/)

---

**Last Updated**: 2025-11-09
**Status**: Sanitized for public release - Production-ready hardened configuration
**Security Rating**: 9.5/10 (All critical vulnerabilities addressed)
**Hardening Status**:
- ✅ Container running as non-root (uid=99)
- ✅ Docker image pinned to SHA256 digest
- ✅ Backup restore tested successfully
- ✅ Rate limiting active (Traefik middleware)
- ✅ Security headers verified working
- ✅ No plaintext secrets in repository
