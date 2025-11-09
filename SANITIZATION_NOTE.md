# Sanitization Notice

This repository has been sanitized for public release. You **MUST** replace the following placeholders with your own values before deploying.

## Required Changes Before Deployment

### 1. Admin Token (CRITICAL)
- [ ] Replace `YOUR_ADMIN_TOKEN_HERE_GENERATE_WITH_VAULTWARDEN_HASH` with your generated plaintext token
- [ ] Replace `$argon2id$v=19$m=65540,t=3,p=4$REPLACE_WITH_YOUR_HASHED_TOKEN` with your hashed token

**How to Generate:**
```bash
# This generates BOTH plaintext and hashed versions
docker run --rm -it vaultwarden/server:alpine /vaultwarden hash --preset owasp

# Output will show:
# Plaintext: abc123xyz... (save this for admin login)
# Hashed: $argon2id$v=19... (use this in deployment scripts)
```

**IMPORTANT**:
- The **plaintext** token is used to login to `/admin` panel
- The **hashed** token is used in the deployment scripts
- Save BOTH securely (e.g., in a password manager)

### 2. Network Configuration
- [ ] Replace `your-server.your-tailnet.ts.net` with your actual Tailscale hostname
- [ ] Replace `10.0.0.x` IP addresses with your actual network IPs
- [ ] Update `your-server-name` with your actual server name

**How to Find Your Tailscale Hostname:**
```bash
# On your server, run:
tailscale status

# Look for a line like:
# 100.x.x.x  your-server-name  your-login@  linux  -
# Your hostname will be: your-server-name.your-tailnet.ts.net
```

### 3. Email and Logging
- [ ] Replace `your-email@example.com` with your email for user invitations
- [ ] Replace `YOUR_GRAYLOG_HOST:12201` with your Graylog server (or remove if not using)

### 4. File Paths
- [ ] Review all paths and update to match your environment:
  - `/mnt/cache_nvme/appdata/vaultwarden/` → Your data directory
  - `/mnt/user/appdata/traefik/config/` → Your Traefik config directory

## Files That Need Updating

1. **config/docker/vaultwarden-run.sh**
   - ADMIN_TOKEN (hashed version)
   - DOMAIN (Tailscale hostname)
   - GRAYLOG_HOST (if using Graylog)
   - DATA_PATH (your data directory)

2. **config/traefik/vaultwarden.yml**
   - Host rule (Tailscale hostname)
   - Certificate paths (if not using Tailscale certs)

3. **scripts/update-vaultwarden.sh**
   - ADMIN_TOKEN (hashed version)
   - Domain (Tailscale hostname)
   - Graylog host (if using)

4. **scripts/backup-vaultwarden.sh**
   - BACKUP_DIR and DATA_DIR paths

5. **README.md**
   - All references to example hostnames and IPs
   - Your actual deployment date
   - Your server specifications

## Verification Checklist

After making changes, verify no secrets remain:

```bash
# Check for the example admin token (should return nothing)
grep -r "YOUR_ADMIN_TOKEN_HERE" .

# Check for example domains (should return nothing)
grep -r "your-server.your-tailnet.ts.net" .

# Check for example IPs in documentation (OK if in examples)
grep -r "10.0.0." .
```

## Security Recommendations

1. **Never commit real secrets to git** - even in private repos
2. **Use environment variables** for sensitive values in production
3. **Rotate admin token** every 6-12 months
4. **Enable 2FA** on all admin accounts
5. **Keep backups encrypted** and off-site

## Getting Help

- **Vaultwarden**: https://github.com/dani-garcia/vaultwarden/wiki
- **Tailscale**: https://tailscale.com/kb/
- **Traefik**: https://doc.traefik.io/traefik/

## License

This configuration is provided as-is under MIT License. Use at your own risk.

---

**Last Sanitized**: 2025-11-09
**Original Author**: Sanitized for public release
