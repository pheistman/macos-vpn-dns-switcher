#!/bin/bash

# Uninstallation script for DNS Monitor

set -e

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.user.dnsmonitor.plist"
LOGROTATE_PLIST_NAME="com.user.dnsmonitor.logrotate.plist"

echo "======================================"
echo "DNS Monitor Uninstallation"
echo "======================================"
echo ""

# Check if the service is loaded
if launchctl list | grep -q "com.user.dnsmonitor"; then
    echo "Stopping DNS Monitor service..."
    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
    echo "Service stopped."
else
    echo "DNS Monitor service is not currently running."
fi

# Check if the log rotation service is loaded
if launchctl list | grep -q "com.user.dnsmonitor.logrotate"; then
    echo "Stopping log rotation service..."
    launchctl unload "$LAUNCH_AGENTS_DIR/$LOGROTATE_PLIST_NAME"
    echo "Log rotation service stopped."
else
    echo "Log rotation service is not currently running."
fi

# Remove the plist file
if [[ -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME" ]]; then
    echo "Removing DNS Monitor LaunchAgent configuration..."
    rm "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
    echo "Configuration removed."
else
    echo "DNS Monitor LaunchAgent configuration not found."
fi

# Remove the log rotation plist file
if [[ -f "$LAUNCH_AGENTS_DIR/$LOGROTATE_PLIST_NAME" ]]; then
    echo "Removing log rotation LaunchAgent configuration..."
    rm "$LAUNCH_AGENTS_DIR/$LOGROTATE_PLIST_NAME"
    echo "Log rotation configuration removed."
else
    echo "Log rotation LaunchAgent configuration not found."
fi

# Clean up state file
if [[ -f "$HOME/.vpn-dns-state" ]]; then
    echo "Removing state file..."
    rm "$HOME/.vpn-dns-state"
fi

echo ""
echo "======================================"
echo "Uninstallation Complete!"
echo "======================================"
echo ""
echo "Note: Log files in ~/Library/Logs/ have been preserved."
echo "You can manually delete them if desired:"
echo "  rm ~/Library/Logs/dns-monitor*.log"
echo ""
