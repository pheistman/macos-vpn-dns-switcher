#!/bin/bash

# Manual DNS Setter Script
# Allows manual switching between Pi-hole and default DNS

PIHOLE_DNS="192.168.1.79"
SECONDARY_DNS="192.168.1.1"
DEFAULT_DNS="192.168.1.1"

# Get the primary network service
get_network_service() {
    networksetup -listallnetworkservices | grep -v "^An asterisk" | grep -E "Wi-Fi|Ethernet" | head -n 1
}

# Flush DNS cache aggressively
flush_dns_cache() {
    echo "Flushing DNS cache..."
    sudo dscacheutil -flushcache 2>/dev/null
    sudo killall -HUP mDNSResponder 2>/dev/null
    sudo killall mDNSResponderHelper 2>/dev/null
    sudo discoveryutil udnsflushcaches 2>/dev/null
    sudo discoveryutil mdnsflushcaches 2>/dev/null
    echo "✅ DNS cache flushed"
}

case "$1" in
    pihole)
        SERVICE=$(get_network_service)
        echo "Setting DNS to Pi-hole ($PIHOLE_DNS) with secondary ($SECONDARY_DNS) on $SERVICE..."
        networksetup -setdnsservers "$SERVICE" "$PIHOLE_DNS" "$SECONDARY_DNS"
        flush_dns_cache
        echo "DNS set to Pi-hole with fallback"
        ;;
    default)
        SERVICE=$(get_network_service)
        echo "Setting DNS to default ($DEFAULT_DNS) on $SERVICE..."
        networksetup -setdnsservers "$SERVICE" "$DEFAULT_DNS"
        flush_dns_cache
        echo "DNS set to default"
        ;;
    auto)
        SERVICE=$(get_network_service)
        echo "Setting DNS to automatic (DHCP) on $SERVICE..."
        networksetup -setdnsservers "$SERVICE" "Empty"
        flush_dns_cache
        echo "DNS set to automatic"
        ;;
    show)
        SERVICE=$(get_network_service)
        echo "Current DNS servers for $SERVICE:"
        networksetup -getdnsservers "$SERVICE"
        ;;
    *)
        echo "Usage: $0 {pihole|default|auto|show}"
        echo ""
        echo "Commands:"
        echo "  pihole  - Set DNS to Pi-hole ($PIHOLE_DNS) with secondary ($SECONDARY_DNS)"
        echo "  default - Set DNS to router ($DEFAULT_DNS)"
        echo "  auto    - Set DNS to automatic (DHCP)"
        echo "  show    - Show current DNS settings"
        exit 1
        ;;
esac
