# Pi VPN

This repository contains notes and config files for turning a Raspberry Pi minicomputer into a dedicated VPN. It works as follows:
- The Pi connects to an internet source via it's `wlan0` wi-fi.
- The Pi runs OpenVPN client at startup.
- The Pi shares its VPN internet connection to any device plugged into its `eth0` ethernet port.

## Setup DHCP

This project is based on a Raspberry Pi B+ running Ubuntu 22.04.5 LTS Desktop.

At the end of this section, the Pi will:
- Obtain an internet connection through WiFi
- Will assign an IP address to any device plugged into the Ethernet port.
- Will share the internet connection to the device plugged into the Ethernet port.

### Setup Preparation
- Remove undesired packages
  - `sudo apt remove update-manager unattended-upgrades`
- Connect to local WiFi
- Update apt
  - `sudo apt update`
- Install SSH server
  - `sudo apt install openssh-server`

### Configuration

- Install OpenVPN and networking tools
  - `sudo apt install openvpn network-manager network-manager-gnome iptables-persistent isc-dhcp-server`

- Install additional networking utilities
  - `sudo apt install bridge-utils net-tools`

- Copy the 01-netcfg.yml file:
  - `sudo nano /etc/netplan/01-netcfg.yml`
  - `sudo rm /etc/netplan/01-network-manager-all.yaml`
  - `sudo netplan apply`

- Configure IP Forwarding
  - `echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf`
  - `sudo sysctl -p`

- Configure NAT and Routing
  - `sudo nano /usr/local/bin/setup-vpn-routing.sh`
  - Copy the contents of the setup-vpn-routing.sh file.
  - `sudo chmod +x /usr/local/bin/setup-vpn-routing.sh`

- Configure DHCP Server for Ethernet Clients
  - `sudo nano /etc/dhcp/dhcpd.conf`
  - Append the contents of the dhcpd.conf file to the end of the file on the Pi.

- Configure DHCP serer interface:
  - `sudo nano /etc/default/isc-dhcp-server`
  - Set: `INTERFACESv4="eth0"`

- Something
  - Plug the Pi into an ethernet switch so that it generates an IP address.
  - `sudo netplan apply`


- Start and enable DHCP server:
  - `sudo systemctl enable isc-dhcp-server`
  - `sudo systemctl start isc-dhcp-server`
  - `sudo systemctl status isc-dhcp-server`

## Setup OpenVPN Server

You'll need to rent a Virtual Private Server (VPS) from a cloud service provider like Amazon, Digital Ocean, Vultr, or Hetzner. It should be running the same version of Ubuntu (22 LTS). Log in with an SSH terminal.

- Prepare to install OpenVPN 
  - `wget https://git.io/vpn -O openvpn-install.sh`
  - `chmod +x openvpn-install.sh`
  - `sudo ./openvpn-install.sh`

- Copy the client.ovpn from the Server to the Pi. scp is useful here. Example:
  - `scp user@5.5.5.5:/home/user/client.ovpn .`

## Setup OpenVPN Client

The Raspberry Pi is the VPN client in this setup. Run the following commands:

- Install OpenVPN:
  - `sudo apt update`
  - `sudo apt install openvpn`

- Start the VPN on the Raspberry Pi:
  - `sudo openvpn --client --config client.ovpn`

