# Android Tailscale Split-Tunnel Setup Guide

**Goal**: Configure your Android phone to access vaultwarden via Tailscale while allowing apps to work normally (split-tunneling).

## Problem Statement

Without split-tunneling, all phone traffic would route through Tailscale, which can:
- Break apps that block VPN usage (banking, streaming)
- Increase battery drain
- Add latency to normal internet browsing

**Solution**: Configure Tailscale to only route traffic to your home network (10.0.0.0/24) and Tailscale domains.

---

## Step 1: Install Tailscale App

1. Open Google Play Store
2. Search for "Tailscale"
3. Install the official Tailscale app
4. Open app and sign in with your Tailscale account

---

## Step 2: Enable Split-Tunnel DNS

### Enable Tailscale DNS (MagicDNS)

1. Open Tailscale app
2. Tap **⋮** (three dots) → **Settings**
3. Find **"Use Tailscale DNS"** → Toggle **ON**
4. Find **"Override local DNS"** → Toggle **ON**

### Configure Split DNS (if available)

**Note**: This feature may be called "Split DNS" or "Search Domains" depending on app version.

1. Settings → **DNS Settings** or **Search Domains**
2. Add these domains to "Use Tailscale DNS for":
   - `*.ts.net`
   - `10.in-addr.arpa` (for reverse DNS)

3. For all other domains: Use normal carrier/WiFi DNS

**Note**: The `.ts.net` domain (like `your-server.your-tailnet.ts.net`) auto-resolves via Tailscale MagicDNS - no manual configuration needed!

**If Split DNS option is not available**: You'll need to enable full Tailscale DNS. Most apps will still work fine.

---

## Step 3: Accept Subnet Routes

Your router is advertising the home network subnet (10.0.0.0/24) to Tailscale.

1. Settings → **"Use subnet routes"** or **"Accept routes"** → Toggle **ON**

This allows your phone to access devices on 10.0.0.x via Tailscale.

---

## Step 4: Verify Configuration

### Check Tailscale Status

1. Open Tailscale app
2. Should show: **"Connected"** with green indicator
3. Tap on your server device → Should show status and last seen

### Test DNS Resolution

Install **Termux** (terminal app) from F-Droid or Play Store:

```bash
# Test .ts.net domain resolution
ping your-server.your-tailnet.ts.net
# Should return: Tailscale IP (100.x.x.x range)

# Test normal DNS (should use regular DNS, not Tailscale)
ping google.com
# Should work normally

# Check your public IP (should be carrier/WiFi IP, NOT Tailscale IP)
curl ifconfig.me
# Should show something like: 72.x.x.x (your carrier IP)
# NOT 100.x.x.x (would indicate all traffic going through Tailscale)
```

### Test LAN Access

```bash
# Should be able to ping your server directly
ping 10.0.0.x
# Should work via Tailscale subnet route

# Should be able to ping other LAN devices
ping 10.0.0.1  # Router
```

---

## Step 5: Install Bitwarden App

1. Open Play Store
2. Search for **"Bitwarden Password Manager"**
3. Install official Bitwarden app

---

## Step 6: Configure Bitwarden Server

1. Open Bitwarden app
2. On login screen, tap **⚙️ (Settings icon)** in top-left
3. Under **"Self-hosted Environment"**:
   - Server URL: `https://your-server.your-tailnet.ts.net`
   - Leave other fields blank
4. Tap **Save**

You should now see the login screen with "Logging into your-server.your-tailnet.ts.net" at the top.

**Note**: No certificate warnings expected - Tailscale provides a valid, trusted certificate!

---

## Step 7: Create Account (Via Admin Panel)

**Note**: Signups are disabled on the vaultwarden server for security.

### On Your Laptop (via Tailscale):

1. Navigate to: `https://your-server.your-tailnet.ts.net/admin`
2. Enter admin token (the plaintext version you generated)
3. Click **"Invite User"**
4. Enter your phone email address
5. Copy the invitation link

### On Your Phone:

1. Paste invitation link in browser
2. Create account with strong master password
3. **CRITICAL**: Write down master password somewhere safe (cannot be recovered!)
4. Enable 2FA (Settings → Two-step Login → Authenticator App)

### Back in Bitwarden App:

1. Login with email and master password
2. Enable biometric unlock (fingerprint/face)
3. Test creating a password entry

---

## Step 8: Enable Autofill

### Android Autofill Service:

1. Open Android **Settings**
2. **System** → **Languages & input** → **Autofill service**
3. Select **Bitwarden**

### Accessibility Service (Optional, for better compatibility):

1. Bitwarden app → **Settings** → **Auto-fill Services**
2. Enable **"Use Accessibility"**
3. Android will prompt to enable Bitwarden in Accessibility settings

### Test Autofill:

1. Open any app with a login (e.g., Twitter, Reddit)
2. Tap on username/password field
3. Should see Bitwarden popup with saved credentials

### Attachment Access:

**Note**: After importing from cloud Bitwarden, attachments require manual re-upload through the web interface.

**Accessing attachments on mobile**:
1. Open Bitwarden app
2. Navigate to item with attachment
3. Tap "Attachments" section
4. Tap attachment to download/view
5. Requires Tailscale connection to download

**If attachments are missing**:
- This is expected after import - attachments must be manually re-uploaded via web vault
- See main README.md section "Importing from Cloud Bitwarden" for details

---

## Step 9: Battery Optimization

Tailscale will increase battery usage slightly. To minimize impact:

### Prevent Android from Killing Tailscale:

1. Open Android **Settings**
2. **Apps** → **Tailscale**
3. **Battery** → Select **"Unrestricted"** or **"Not optimized"**

This prevents Android from killing the VPN connection when the screen is off.

### Expected Battery Impact:

- **With split-tunneling**: ~5-10% extra drain per day
- **Without split-tunneling**: ~15-20% extra drain per day

---

## Troubleshooting

### your-server.your-tailnet.ts.net Won't Resolve

**Problem**: "Could not resolve host" or "DNS failure"

**Root Cause**: Tailscale DNS not properly configured

**Solutions**:
1. Verify Tailscale is **Connected** (not just enabled)
2. Check **Use Tailscale DNS** is ON in Tailscale settings
3. Try restarting Tailscale app
4. Try disconnecting and reconnecting Tailscale

**Note**: The `.ts.net` domain should auto-resolve via Tailscale MagicDNS. No manual DNS configuration or hosts file entries needed!

### Apps Detect VPN and Refuse to Work

**Problem**: Banking app shows "VPN detected, disable to continue"

**Solutions**:
1. Verify split-tunneling is configured (see Step 2-3)
2. Temporarily disable Tailscale for that app
3. Check if app-specific VPN bypass is available in Tailscale settings (may not be available on Android)

**Note**: Some banking apps detect ANY VPN, even with split-tunneling. You may need to disconnect Tailscale temporarily.

### Can't Access Other Devices on Home Network

**Problem**: Can access vaultwarden but not other 10.0.0.x devices

**Solutions**:
1. Verify "Accept subnet routes" is ON
2. Check your router is advertising routes: On laptop, `tailscale status | grep subnet`
3. Try accessing via Tailscale IP instead of LAN IP

### Bitwarden App Shows "Connection Error"

**Symptoms**: Can't sync, shows offline

**Solutions**:
1. Verify Tailscale is connected
2. Test in browser: Open Chrome, navigate to `https://your-server.your-tailnet.ts.net`
3. No certificate warnings should appear (Tailscale cert is valid)
4. Check vaultwarden container status (from laptop):
   ```bash
   ssh root@your-server "docker ps | grep vaultwarden"
   ```

### High Battery Drain

**Problem**: Phone battery draining faster than expected

**Solutions**:
1. Verify split-tunneling is configured properly
2. Check Tailscale is not routing ALL traffic:
   ```bash
   curl ifconfig.me  # Should show carrier IP, not Tailscale IP
   ```
3. Reduce Tailscale connection frequency (Settings → may vary by app version)
4. Use "On Demand" mode if available (connects only when accessing local network)

---

## Advanced: On-Demand Mode (If Available)

Some Tailscale versions support "On-Demand" VPN:

1. Settings → **VPN on Demand** → **Enable**
2. Add rule: **"Connect when accessing *.yourdomain.local"**
3. Add rule: **"Connect when accessing 10.0.0.0/24"**
4. Default: **"Disconnect"**

This connects Tailscale only when you access home resources, saving battery.

**Note**: Feature availability varies by Tailscale app version and Android version.

---

## Security Reminders

✅ **DO**:
- Use a strong, unique master password (20+ characters)
- Enable 2FA (TOTP)
- Enable biometric unlock for convenience
- Keep Tailscale connected when accessing vaultwarden
- Keep Bitwarden app updated

❌ **DON'T**:
- Share your master password with anyone
- Use the same master password as other accounts
- Disable 2FA after enabling it
- Access vaultwarden without Tailscale (won't work anyway)
- Store master password in another password manager (circular dependency)

---

## Testing Checklist

- [ ] Tailscale shows "Connected"
- [ ] Can ping your-server.your-tailnet.ts.net
- [ ] Can access https://your-server.your-tailnet.ts.net in phone browser
- [ ] No certificate warnings (Tailscale cert is valid)
- [ ] Apps work normally (not routing through VPN)
- [ ] Bitwarden app can sync
- [ ] Autofill works in apps
- [ ] Battery drain is acceptable (<10% extra per day)
- [ ] Biometric unlock works
- [ ] Attachments accessible in mobile app
- [ ] 2FA is enabled (optional but recommended)

---

## Support

If you encounter issues:
1. Check this troubleshooting guide
2. Review container logs (from laptop)
3. Check vaultwarden container health
4. Consult Tailscale documentation: https://tailscale.com/kb/
5. Check Bitwarden forums: https://community.bitwarden.com/

**Remember**: This is a self-hosted solution. You are your own support!

---

**Last Updated**: 2025-11-09
**Status**: Sanitized for public release
