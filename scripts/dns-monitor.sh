#!/bin/bash

# DNS Monitor Script for macOS VPN Connection
# Monitors VPN connection state and automatically switches DNS settings

# Configuration
PIHOLE_DNS="192.168.1.79"
SECONDARY_DNS="192.168.1.1"
VPN_DNS="1.1.1.1"
LOG_FILE="$HOME/Library/Logs/dns-monitor.log"
STATE_FILE="$HOME/.vpn-dns-state"
CHECK_INTERVAL=5  # Check every 5 seconds

# Get the primary network service (usually Wi-Fi or Ethernet)
get_primary_service() {
    networksetup -listnetworkserviceorder | grep -A 1 "(1)" | tail -n 1 | sed 's/.*Device: \(.*\))/\1/'
}

# Get current DNS servers
get_current_dns() {
    local service=$(get_primary_service)
    scutil --dns | grep "nameserver\[0\]" | head -n 1 | awk '{print $3}'
}

# Check if VPN is connected by looking for the VPN DNS
is_vpn_connected() {
    local current_dns=$(get_current_dns)
    if [[ "$current_dns" == "$VPN_DNS" ]]; then
        return 0  # VPN is connected
    else
        return 1  # VPN is not connected
    fi
}

# Flush DNS cache aggressively
flush_dns_cache() {
    echo "$(date): Flushing DNS cache..." >> "$LOG_FILE"
    dscacheutil -flushcache 2>/dev/null
    killall -HUP mDNSResponder 2>/dev/null
    killall mDNSResponderHelper 2>/dev/null
    discoveryutil udnsflushcaches 2>/dev/null
    discoveryutil mdnsflushcaches 2>/dev/null
}

# Set DNS to Pi-hole  
set_pihole_dns() {
    local service=$(networksetup -listallnetworkservices | grep -v "^An asterisk" | grep -E "Wi-Fi|Ethernet" | head -n 1)
    echo "$(date): Setting DNS to Pi-hole ($PIHOLE_DNS) with secondary ($SECONDARY_DNS) on service: $service" >> "$LOG_FILE"
    
    local result=$(sudo networksetup -setdnsservers "$service" "$PIHOLE_DNS" "$SECONDARY_DNS" 2>&1)
    if [[ -n "$result" ]]; then
        echo "$(date): networksetup output: $result" >> "$LOG_FILE"
    fi
    
    # Verify it was set
    local verify=$(networksetup -getdnsservers "$service" 2>&1)
    echo "$(date): DNS verification: $verify" >> "$LOG_FILE"
    
    flush_dns_cache
}

# Set DNS to VPN (this happens automatically, but we can force it if needed)
set_vpn_dns() {
    echo "$(date): VPN connected, DNS set to $VPN_DNS" >> "$LOG_FILE"
    flush_dns_cache
}

# Log startup
echo "$(date): DNS Monitor started" >> "$LOG_FILE"

# Initialize state
if [[ ! -f "$STATE_FILE" ]]; then
    echo "unknown" > "$STATE_FILE"
fi

# Main monitoring loop
while true; do
    if is_vpn_connected; then
        # VPN is connected - let VPN manage DNS
        if [[ $(cat "$STATE_FILE") != "vpn" ]]; then
            set_vpn_dns
            echo "vpn" > "$STATE_FILE"
        fi
    else
        # VPN is disconnected - enforce Pi-hole DNS
        current_dns=$(networksetup -getdnsservers "Wi-Fi" | head -n 1)
        
        # If DNS is not set to Pi-hole, set it
        if [[ "$current_dns" != "$PIHOLE_DNS" ]] && [[ "$current_dns" != "There aren't any DNS Servers set on Wi-Fi." ]]; then
            if [[ $(cat "$STATE_FILE") != "pihole" ]]; then
                set_pihole_dns
                echo "pihole" > "$STATE_FILE"
            fi
        elif [[ "$current_dns" == "There aren't any DNS Servers set on Wi-Fi." ]] || [[ -z "$current_dns" ]]; then
            # No DNS set at all, set to Pi-hole
            set_pihole_dns
            echo "pihole" > "$STATE_FILE"
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done
