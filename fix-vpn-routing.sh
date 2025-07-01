#!/bin/bash

echo "=== Quick VPN Routing Fix ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "1. Ensuring IP forwarding is enabled..."
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "IP forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"

echo ""
echo "2. Checking if VPN is connected..."
if ! ip link show tun0 &> /dev/null; then
    echo "ERROR: VPN interface tun0 not found!"
    echo "Please ensure OpenVPN is running first."
    exit 1
fi
echo "VPN interface found: tun0"

echo ""
echo "3. Applying routing rules..."
# Use the improved routing script
if [ -f "/usr/local/bin/setup-vpn-routing-improved.sh" ]; then
    /usr/local/bin/setup-vpn-routing-improved.sh
else
    # Fallback to basic routing
    echo "Using basic routing setup..."
    
    # Flush existing rules
    iptables -F
    iptables -t nat -F
    iptables -X
    
    # Set default policies
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    # Enable NAT for VPN to Ethernet
    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    
    # Allow forwarding from eth0 to VPN
    iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
    
    # Allow established connections back from VPN
    iptables -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    # Allow local traffic on eth0
    iptables -A INPUT -i eth0 -j ACCEPT
    iptables -A OUTPUT -o eth0 -j ACCEPT
    
    # Allow DHCP and DNS traffic
    iptables -A INPUT -i eth0 -p udp --dport 67 -j ACCEPT
    iptables -A OUTPUT -o eth0 -p udp --sport 67 -j ACCEPT
    iptables -A INPUT -i eth0 -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -o eth0 -p udp --sport 53 -j ACCEPT
    
    # Save rules
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4
fi

echo ""
echo "4. Checking DHCP server..."
if systemctl is-active --quiet isc-dhcp-server; then
    echo "DHCP server is running"
else
    echo "Starting DHCP server..."
    systemctl start isc-dhcp-server
    systemctl enable isc-dhcp-server
fi

echo ""
echo "5. Testing connectivity..."
echo "Testing ping to 8.8.8.8..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "✓ Internet connectivity working"
else
    echo "✗ Internet connectivity failed"
fi

echo ""
echo "6. Checking for connected devices..."
arp -a | grep eth0 || echo "No devices currently connected to eth0"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "If devices still can't connect:"
echo "1. Make sure the device is set to DHCP/automatic IP"
echo "2. Try disconnecting and reconnecting the Ethernet cable"
echo "3. Check the device's network settings"
echo "4. Run the troubleshooting script: ./troubleshoot-vpn.sh" 