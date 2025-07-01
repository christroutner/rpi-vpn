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

The Raspberry Pi is the VPN client in this setup. This will route all traffic from devices connected to the Ethernet port through the VPN connection.

### Automatic Setup (Recommended)

1. **Copy your OpenVPN client configuration file** to the Pi:
   - Copy your `client.ovpn` file to the Pi (use scp or copy/paste)
   - Make sure it's in the same directory as the setup script
   - Copy the `openvpn-client.service` file to the same directory.

2. **Run the automated setup script**:
   ```bash
   sudo chmod +x setup-vpn-client.sh
   sudo ./setup-vpn-client.sh
   ```

3. **Start the VPN service**:
   ```bash
   sudo systemctl start openvpn-client.service
   ```

4. **Check the status**:
   ```bash
   sudo systemctl status openvpn-client.service
   ```

### Manual Setup

If you prefer to set up manually:

1. **Install OpenVPN**:
   ```bash
   sudo apt update
   sudo apt install openvpn
   ```

2. **Copy your client configuration**:
   ```bash
   sudo cp client.ovpn /etc/openvpn/
   ```

3. **Set up the routing script**:
   ```bash
   sudo chmod +x /usr/local/bin/setup-vpn-routing.sh
   ```

4. **Start OpenVPN with routing**:
   ```bash
   sudo openvpn --config /etc/openvpn/client.ovpn --script-security 2 --up /usr/local/bin/setup-vpn-routing.sh
   ```

### Testing the Setup

1. **Connect a device** to the Pi's Ethernet port
2. **Check if it gets an IP address** (should be in 192.168.4.x range)
3. **Test internet connectivity** on the connected device
4. **Verify VPN routing** by checking the device's public IP (should match your VPN server's location)

### Troubleshooting

If devices connected to the Ethernet port can't access the internet:

1. **Run the quick fix script**:
   ```bash
   sudo chmod +x fix-vpn-routing.sh
   sudo ./fix-vpn-routing.sh
   ```

2. **Run the troubleshooting script**:
   ```bash
   sudo chmod +x troubleshoot-vpn.sh
   sudo ./troubleshoot-vpn.sh
   ```

3. **Manual checks**:
   - **Check VPN status**: `sudo systemctl status openvpn-client.service`
   - **View VPN logs**: `sudo journalctl -u openvpn-client.service -f`
   - **Check routing**: `sudo iptables -t nat -L -v`
   - **Test VPN interface**: `ip addr show tun0`
   - **Check IP forwarding**: `cat /proc/sys/net/ipv4/ip_forward`
   - **Restart service**: `sudo systemctl restart openvpn-client.service`

4. **Common issues**:
   - **IP forwarding disabled**: Run `echo 1 > /proc/sys/net/ipv4/ip_forward`
   - **Missing iptables rules**: Run the routing script manually
   - **DHCP server not running**: `sudo systemctl start isc-dhcp-server`
   - **VPN interface not found**: Check OpenVPN configuration and connection

