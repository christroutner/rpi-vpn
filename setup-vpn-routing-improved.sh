#!/bin/bash

# Improved VPN routing script with better error handling and debugging

set -e

echo "Setting up VPN routing rules..."

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

# Define interfaces
VPN_INTERFACE="tun0"
WIFI_INTERFACE="wlan0"
ETHERNET_INTERFACE="eth0"

# Wait for VPN interface with better error handling
echo "Waiting for VPN interface $VPN_INTERFACE..."
for i in {1..60}; do
    if ip link show $VPN_INTERFACE > /dev/null 2>&1; then
        echo "VPN interface $VPN_INTERFACE found!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "ERROR: VPN interface $VPN_INTERFACE not found after 60 seconds"
        echo "Checking available interfaces:"
        ip link show
        exit 1
    fi
    sleep 1
done

# Get VPN interface IP address
VPN_IP=$(ip addr show $VPN_INTERFACE | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$VPN_IP" ]; then
    echo "ERROR: Could not get VPN interface IP address"
    exit 1
fi
echo "VPN interface IP: $VPN_IP"

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

# Allow DNS traffic
iptables -A INPUT -i $ETHERNET_INTERFACE -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -o $ETHERNET_INTERFACE -p udp --sport 53 -j ACCEPT

# Allow ICMP (ping) for troubleshooting
iptables -A INPUT -i $ETHERNET_INTERFACE -p icmp -j ACCEPT
iptables -A OUTPUT -o $ETHERNET_INTERFACE -p icmp -j ACCEPT

# Save rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "VPN routing rules applied successfully!"
echo "All traffic from $ETHERNET_INTERFACE will be routed through $VPN_INTERFACE"
echo ""
echo "Current routing table:"
ip route show
echo ""
echo "Current iptables NAT rules:"
iptables -t nat -L -v
echo ""
echo "Current forwarding rules:"
iptables -L FORWARD -v 