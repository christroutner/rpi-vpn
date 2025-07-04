#!/bin/bash

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Wait for VPN tunnel to be established (tun0 interface)
# This script should be called after OpenVPN is running
VPN_INTERFACE="tun0"
WIFI_INTERFACE="wlan0"
ETHERNET_INTERFACE="eth0"

# Check if VPN interface exists
if ! ip link show $VPN_INTERFACE > /dev/null 2>&1; then
    echo "VPN interface $VPN_INTERFACE not found. Waiting..."
    # Wait up to 30 seconds for VPN to establish
    for i in {1..30}; do
        if ip link show $VPN_INTERFACE > /dev/null 2>&1; then
            echo "VPN interface $VPN_INTERFACE found!"
            break
        fi
        sleep 1
    done
    
    if ! ip link show $VPN_INTERFACE > /dev/null 2>&1; then
        echo "ERROR: VPN interface $VPN_INTERFACE not found after 30 seconds"
        exit 1
    fi
fi

# Enable NAT for VPN to Ethernet (route through VPN)
iptables -t nat -A POSTROUTING -o $VPN_INTERFACE -j MASQUERADE

# Allow forwarding from eth0 to VPN
iptables -A FORWARD -i $ETHERNET_INTERFACE -o $VPN_INTERFACE -j ACCEPT

# Allow established connections back from VPN
iptables -A FORWARD -i $VPN_INTERFACE -o $ETHERNET_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow the Pi itself to access the internet through VPN
iptables -A OUTPUT -o $VPN_INTERFACE -j ACCEPT
iptables -A INPUT -i $VPN_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow local traffic on eth0
iptables -A INPUT -i $ETHERNET_INTERFACE -j ACCEPT
iptables -A OUTPUT -o $ETHERNET_INTERFACE -j ACCEPT

# Allow DHCP traffic
iptables -A INPUT -i $ETHERNET_INTERFACE -p udp --dport 67 -j ACCEPT
iptables -A OUTPUT -o $ETHERNET_INTERFACE -p udp --sport 67 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4

echo "VPN routing rules applied successfully!"
echo "All traffic from $ETHERNET_INTERFACE will be routed through $VPN_INTERFACE"
