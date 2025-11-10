#!/bin/bash

# Setup script to configure passwordless sudo for DNS management
# This allows the DNS monitor to change network settings without password prompts

SUDOERS_FILE="/etc/sudoers.d/dns-monitor"
USERNAME=$(whoami)

echo "======================================"
echo "DNS Monitor - Sudo Configuration"
echo "======================================"
echo ""
echo "This script will configure passwordless sudo for networksetup commands."
echo "This is required for the DNS monitor to automatically switch DNS settings."
echo ""
echo "The script will add a rule to /etc/sudoers.d/dns-monitor"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Create sudoers content
SUDOERS_CONTENT="# Allow $USERNAME to run networksetup for DNS changes without password
$USERNAME ALL=(ALL) NOPASSWD: /usr/sbin/networksetup -setdnsservers *
$USERNAME ALL=(ALL) NOPASSWD: /usr/sbin/dscacheutil -flushcache
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/killall -HUP mDNSResponder
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/killall mDNSResponderHelper
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/discoveryutil udnsflushcaches
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/discoveryutil mdnsflushcaches
"

echo "Creating sudoers file..."
echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null

# Set correct permissions
sudo chmod 0440 "$SUDOERS_FILE"

# Validate the sudoers file
if sudo visudo -c -f "$SUDOERS_FILE"; then
    echo ""
    echo "✅ Sudoers file created successfully!"
    echo ""
    echo "You can now run the install script to set up the DNS monitor."
    echo ""
else
    echo ""
    echo "❌ Error: Invalid sudoers file. Removing it."
    sudo rm "$SUDOERS_FILE"
    exit 1
fi
