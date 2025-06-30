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

# Enable NAT for WiFi to Ethernet
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# Allow forwarding from eth0 to wlan0
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

# Allow established connections back
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow the Pi itself to access the internet (important!)
iptables -A OUTPUT -o wlan0 -j ACCEPT
iptables -A INPUT -i wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
