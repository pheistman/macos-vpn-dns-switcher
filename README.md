# macOS VPN DNS Auto-Switcher

Automatically manage DNS settings on macOS when connecting/disconnecting from your work VPN. This solution switches between your work VPN DNS (1.1.1.1) and your local Pi-hole DNS (192.168.1.79) seamlessly.

## The Problem

When connecting to a work VPN on macOS:
- VPN overrides DNS to 1.1.1.1
- Local network resources (like Pi-hole) become inaccessible
- When disconnecting from VPN, DNS doesn't revert to Pi-hole
- Manual DNS changes are tedious and error-prone

## The Solution

This project provides an automated background service that:
- ✅ Monitors your VPN connection status
- ✅ Automatically switches to VPN DNS (1.1.1.1) when connected
- ✅ Automatically switches back to Pi-hole DNS (192.168.1.79) when disconnected
- ✅ Runs in the background as a macOS LaunchAgent
- ✅ Starts automatically on login
- ✅ Rotates logs daily at 2 AM (keeps 7 days of compressed logs)

## Prerequisites

- macOS (tested on macOS 10.14+)
- Admin access to modify network settings
- Pi-hole running at 192.168.1.79 (or adjust configuration)

## Installation

1. **Clone or download this repository**

2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Verify the service is running:**
   ```bash
   launchctl list | grep dnsmonitor
   ```

That's it! The service is now monitoring your VPN connection.

## Configuration

If your setup differs, edit the configuration in `scripts/dns-monitor.sh`:

```bash
PIHOLE_DNS="192.168.1.79"    # Your Pi-hole IP
VPN_DNS="1.1.1.1"            # Your VPN DNS
CHECK_INTERVAL=5             # Check every 5 seconds
```

After making changes, reinstall the service:
```bash
./install.sh
```

## Manual DNS Control

Use the provided script for manual DNS control:

```bash
# Switch to Pi-hole DNS
./scripts/set-dns.sh pihole

# Switch to router default DNS (192.168.1.1)
./scripts/set-dns.sh default

# Switch to automatic DHCP DNS
./scripts/set-dns.sh auto

# Show current DNS settings
./scripts/set-dns.sh show
```

## Monitoring & Logs

View real-time logs:
```bash
# Main application log
tail -f ~/Library/Logs/dns-monitor.log

# Standard output
tail -f ~/Library/Logs/dns-monitor-stdout.log

# Error log
tail -f ~/Library/Logs/dns-monitor-stderr.log
```

### Log Rotation

Logs are automatically rotated daily at 2:00 AM:
- Rotated logs are compressed and dated (e.g., `dns-monitor.log.20251110.gz`)
- Last 7 days of logs are kept
- Old logs are automatically deleted

Manual log rotation:
```bash
./scripts/rotate-logs.sh
```

View archived logs:
```bash
# List archived logs
ls -lh ~/Library/Logs/dns-monitor*.log*.gz

# View a compressed log
zcat ~/Library/Logs/dns-monitor.log.20251110.gz
```

## Service Management

```bash
# Stop the DNS monitor
launchctl unload ~/Library/LaunchAgents/com.user.dnsmonitor.plist

# Start the DNS monitor
launchctl load ~/Library/LaunchAgents/com.user.dnsmonitor.plist

# Check DNS monitor status
launchctl list | grep dnsmonitor

# Stop log rotation
launchctl unload ~/Library/LaunchAgents/com.user.dnsmonitor.logrotate.plist

# Start log rotation
launchctl load ~/Library/LaunchAgents/com.user.dnsmonitor.logrotate.plist
```

## Uninstallation

To remove the DNS monitor service:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will:
- Stop the background service
- Stop the log rotation service
- Remove the LaunchAgent configurations
- Clean up state files
- Preserve log files (you can delete manually if needed)

## How It Works

1. **DNS Monitor Script** (`scripts/dns-monitor.sh`)
   - Runs continuously in the background
   - Checks DNS every 5 seconds
   - Detects VPN connection by looking for VPN DNS (1.1.1.1)
   - Automatically switches DNS when state changes

2. **Log Rotation Script** (`scripts/rotate-logs.sh`)
   - Runs daily at 2:00 AM
   - Compresses and archives old logs
   - Keeps 7 days of history
   - Automatically cleans up old archives

3. **LaunchAgents** (`config/*.plist`)
   - DNS Monitor: Ensures the monitor runs at login and auto-restarts
   - Log Rotation: Schedules daily log rotation
   - Manages logging for both services

4. **Manual Control Script** (`scripts/set-dns.sh`)
   - Provides manual override capabilities
   - Useful for testing or special situations

## Troubleshooting

### Service not starting
Check the error log:
```bash
cat ~/Library/Logs/dns-monitor-stderr.log
```

### DNS not switching
1. Verify the service is running:
   ```bash
   launchctl list | grep dnsmonitor
   ```

2. Check the main log for errors:
   ```bash
   tail -f ~/Library/Logs/dns-monitor.log
   ```

3. Verify your network service name:
   ```bash
   networksetup -listallnetworkservices
   ```

### Permission issues
The script needs permission to change network settings. You may be prompted for your password when the service tries to change DNS.

### VPN detection not working
If your VPN uses a different DNS than 1.1.1.1, update the `VPN_DNS` variable in `scripts/dns-monitor.sh`.

## Project Structure

```
.
├── .github/
│   └── copilot-instructions.md    # Project checklist and guidelines
├── config/
│   ├── com.user.dnsmonitor.plist          # DNS Monitor LaunchAgent
│   ├── com.user.dnsmonitor.logrotate.plist # Log Rotation LaunchAgent
│   └── dns-monitor-logrotate.conf         # Log rotation config
├── scripts/
│   ├── dns-monitor.sh             # Main monitoring script
│   ├── set-dns.sh                 # Manual DNS control script
│   └── rotate-logs.sh             # Log rotation script
├── install.sh                      # Installation script
├── setup-sudo.sh                   # Sudo configuration for passwordless DNS changes
├── uninstall.sh                    # Uninstallation script
└── README.md                       # This file
```

## Network Configuration Notes

Your Vodafone Ultra Hub is configured with:
- Primary DNS: 192.168.1.79 (Pi-hole)
- However, DHCP still advertises 192.168.1.1 to clients

This solution works around that limitation by explicitly setting DNS on your MacBook Pro, ensuring you always use Pi-hole when not on VPN.

## License

This project is provided as-is for personal use.

## Contributing

Feel free to submit issues or pull requests if you find bugs or have improvements!
