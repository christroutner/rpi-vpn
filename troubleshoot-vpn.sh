#!/bin/bash

echo "=== VPN Troubleshooting Script ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "WARNING: This script should be run as root for complete diagnostics"
    echo "Some checks may not work properly without root privileges"
    echo ""
fi

echo "1. Checking OpenVPN service status..."
if command -v systemctl &> /dev/null; then
    systemctl status openvpn-client.service --no-pager -l
else
    echo "systemctl not available"
fi
echo ""

echo "2. Checking network interfaces..."
ip addr show
echo ""

echo "3. Checking routing table..."
ip route show
echo ""

echo "4. Checking iptables rules..."
echo "NAT rules:"
iptables -t nat -L -v -n
echo ""
echo "Forwarding rules:"
iptables -L FORWARD -v -n
echo ""

echo "5. Checking IP forwarding status..."
echo "IP forwarding enabled: $(cat /proc/sys/net/ipv4/ip_forward)"
echo ""

echo "6. Checking if tun0 interface exists and is up..."
if ip link show tun0 &> /dev/null; then
    echo "tun0 interface exists"
    ip addr show tun0
else
    echo "ERROR: tun0 interface not found!"
fi
echo ""

echo "7. Checking DHCP server status..."
if command -v systemctl &> /dev/null; then
    systemctl status isc-dhcp-server --no-pager -l
else
    echo "systemctl not available"
fi
echo ""

echo "8. Testing connectivity from Pi..."
echo "Testing DNS resolution:"
nslookup google.com 8.8.8.8
echo ""
echo "Testing ping to internet:"
ping -c 3 8.8.8.8
echo ""

echo "9. Checking for any connected devices on eth0..."
arp -a
echo ""

echo "10. Checking eth0 interface configuration..."
ip addr show eth0
echo ""

echo "=== Troubleshooting Complete ==="
echo ""
echo "Common issues and solutions:"
echo "1. If tun0 doesn't exist: VPN connection failed"
echo "2. If IP forwarding is 0: Run 'echo 1 > /proc/sys/net/ipv4/ip_forward'"
echo "3. If iptables rules are missing: Run the setup-vpn-routing.sh script"
echo "4. If DHCP server is not running: Start with 'sudo systemctl start isc-dhcp-server'"
echo "5. If routing table doesn't show VPN routes: VPN may not be properly configured" 