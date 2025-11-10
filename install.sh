#!/bin/bash

# Installation script for DNS Monitor
# This script sets up the DNS monitoring service

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.user.dnsmonitor.plist"
LOGROTATE_PLIST_NAME="com.user.dnsmonitor.logrotate.plist"
MONITOR_SCRIPT="$SCRIPT_DIR/scripts/dns-monitor.sh"
SET_DNS_SCRIPT="$SCRIPT_DIR/scripts/set-dns.sh"
LOGROTATE_SCRIPT="$SCRIPT_DIR/scripts/rotate-logs.sh"

echo "======================================"
echo "DNS Monitor Installation"
echo "======================================"
echo ""

# Check if running with sufficient privileges
if [[ $EUID -eq 0 ]]; then
   echo "Error: Do not run this script with sudo. It will prompt for password when needed."
   exit 1
fi

# Create LaunchAgents directory if it doesn't exist
if [[ ! -d "$LAUNCH_AGENTS_DIR" ]]; then
    echo "Creating LaunchAgents directory..."
    mkdir -p "$LAUNCH_AGENTS_DIR"
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$MONITOR_SCRIPT"
chmod +x "$SET_DNS_SCRIPT"
chmod +x "$LOGROTATE_SCRIPT"

# Update the plist file with actual paths
echo "Configuring LaunchAgent..."
PLIST_CONTENT=$(cat "$SCRIPT_DIR/config/$PLIST_NAME")
PLIST_CONTENT="${PLIST_CONTENT//__SCRIPT_PATH__/$MONITOR_SCRIPT}"
PLIST_CONTENT="${PLIST_CONTENT//__HOME__/$HOME}"

# Write the updated plist to LaunchAgents
echo "$PLIST_CONTENT" > "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Unload existing service if running
echo "Checking for existing service..."
if launchctl list | grep -q "com.user.dnsmonitor"; then
    echo "Unloading existing service..."
    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
fi

# Load the LaunchAgent
echo "Loading DNS Monitor service..."
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Configure log rotation
echo "Configuring log rotation..."
LOGROTATE_PLIST_CONTENT=$(cat "$SCRIPT_DIR/config/$LOGROTATE_PLIST_NAME")
LOGROTATE_PLIST_CONTENT="${LOGROTATE_PLIST_CONTENT//__SCRIPT_PATH__/$LOGROTATE_SCRIPT}"
LOGROTATE_PLIST_CONTENT="${LOGROTATE_PLIST_CONTENT//__HOME__/$HOME}"

# Write the updated log rotation plist
echo "$LOGROTATE_PLIST_CONTENT" > "$LAUNCH_AGENTS_DIR/$LOGROTATE_PLIST_NAME"

# Unload existing log rotation service if running
if launchctl list | grep -q "com.user.dnsmonitor.logrotate"; then
    launchctl unload "$LAUNCH_AGENTS_DIR/$LOGROTATE_PLIST_NAME" 2>/dev/null || true
fi

# Load the log rotation service
echo "Loading log rotation service..."
launchctl load "$LAUNCH_AGENTS_DIR/$LOGROTATE_PLIST_NAME"

# Create logs directory
mkdir -p "$HOME/Library/Logs"

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "The DNS Monitor is now running and will:"
echo "  - Automatically start on login"
echo "  - Monitor your VPN connection status"
echo "  - Switch to VPN DNS (1.1.1.1) when connected"
echo "  - Switch to Pi-hole DNS (192.168.1.79) when disconnected"
echo "  - Rotate logs daily at 2 AM (keeps 7 days)"
echo ""
echo "Manual Controls:"
echo "  Set to Pi-hole:  ./scripts/set-dns.sh pihole"
echo "  Set to default:  ./scripts/set-dns.sh default"
echo "  Set to auto:     ./scripts/set-dns.sh auto"
echo "  Show current:    ./scripts/set-dns.sh show"
echo ""
echo "View Logs:"
echo "  tail -f ~/Library/Logs/dns-monitor.log"
echo "  tail -f ~/Library/Logs/dns-monitor-stdout.log"
echo "  tail -f ~/Library/Logs/dns-monitor-stderr.log"
echo ""
echo "Service Management:"
echo "  Stop:    launchctl unload ~/Library/LaunchAgents/$PLIST_NAME"
echo "  Start:   launchctl load ~/Library/LaunchAgents/$PLIST_NAME"
echo "  Status:  launchctl list | grep dnsmonitor"
echo ""
