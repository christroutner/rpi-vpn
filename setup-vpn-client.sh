#!/bin/bash

# Setup script for OpenVPN client on Raspberry Pi
# This script configures the Pi to route all traffic through VPN

set -e

echo "Setting up OpenVPN client for Raspberry Pi..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Check if client.ovpn exists
if [ ! -f "client.ovpn" ]; then
    echo "ERROR: client.ovpn file not found in current directory"
    echo "Please copy your OpenVPN client configuration file to this directory"
    exit 1
fi

# Install OpenVPN if not already installed
if ! command -v openvpn &> /dev/null; then
    echo "Installing OpenVPN..."
    apt update
    apt install -y openvpn
fi

# Copy client configuration
echo "Copying OpenVPN client configuration..."
cp client.ovpn /etc/openvpn/

# Make sure the routing script is executable
chmod +x /usr/local/bin/setup-vpn-routing.sh

# Copy systemd service
echo "Setting up systemd service..."
cp openvpn-client.service /etc/systemd/system/

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable openvpn-client.service

# Create iptables rules directory if it doesn't exist
mkdir -p /etc/iptables

echo ""
echo "Setup complete! The VPN client will start automatically on boot."
echo ""
echo "To start the VPN now, run:"
echo "  sudo systemctl start openvpn-client.service"
echo ""
echo "To check the status, run:"
echo "  sudo systemctl status openvpn-client.service"
echo ""
echo "To view logs, run:"
echo "  sudo journalctl -u openvpn-client.service -f"
echo ""
echo "To test the connection, connect a device to the Pi's Ethernet port"
echo "and check if it gets an IP address and can access the internet." 