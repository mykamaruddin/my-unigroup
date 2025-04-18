#!/bin/bash

# install_unigroup.sh
# Ubuntu LTS Node Setup Script for MYK Nodes

set -e  # Exit on error

# Step 1: Ensure script is run as root
echo "------------------------------------------------------------"
echo "Step 1: Checking for root permissions..."
echo "------------------------------------------------------------"
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root. Try: sudo ./install_unigroup.sh"
   exit 1
fi
clear

# Step 2: Prompt for base hostname
echo "------------------------------------------------------------"
echo "Step 2: Setting Hostname..."
echo "------------------------------------------------------------"
read -rp "Enter the base hostname for this node (e.g., dns-01): " BASE_HOSTNAME
FULL_HOSTNAME="${BASE_HOSTNAME}.my-unigroup.local"
echo "🧩 Setting hostname to '$FULL_HOSTNAME'..."
hostnamectl set-hostname "$FULL_HOSTNAME"
sleep 3
clear

# Step 3: Set Timezone
echo "------------------------------------------------------------"
echo "Step 3: Setting Timezone..."
echo "------------------------------------------------------------"
echo "🌐 Setting timezone to Asia/Kuala_Lumpur..."
timedatectl set-timezone Asia/Kuala_Lumpur
sleep 3
clear

# Step 4: Prompt for last octet of IP address
echo "------------------------------------------------------------"
echo "Step 4: Configuring IP Address..."
echo "------------------------------------------------------------"
read -rp "Enter the last octet of the IP address (e.g., 24 for 10.9.19.24): " LAST_OCTET
echo "📡 Using provided IP last octet: $LAST_OCTET"
sleep 3
clear

# Step 5: Rebuild /etc/hosts
echo "------------------------------------------------------------"
echo "Step 5: Rebuilding /etc/hosts..."
echo "------------------------------------------------------------"
cat <<EOF > /etc/hosts
127.0.0.1 localhost
127.0.1.${LAST_OCTET} ${BASE_HOSTNAME}
10.9.19.${LAST_OCTET} ${FULL_HOSTNAME} ${BASE_HOSTNAME}

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
echo "✅ /etc/hosts updated:"
cat /etc/hosts
sleep 3
clear

# Step 6: Disable cloud-init network config
echo "------------------------------------------------------------"
echo "Step 6: Disabling cloud-init network config..."
echo "------------------------------------------------------------"
cat <<EOF > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}
EOF
echo "✅ Cloud-init network config disabled in 99-disable-network-config.cfg"
sleep 3
clear

# Step 7: Detect network adapter
echo "------------------------------------------------------------"
echo "Step 7: Detecting network adapter..."
echo "------------------------------------------------------------"
ADAPTER_ID=$(ip -o link show | awk -F': ' '!/lo|docker/ {print $2; exit}')
echo "✅ Detected network adapter: $ADAPTER_ID"
sleep 3
clear

# Step 8: Replace netplan config
echo "------------------------------------------------------------"
echo "Step 8: Writing netplan configuration..."
echo "------------------------------------------------------------"
cd /etc/netplan/
rm -f ./*
cat <<EOF > /etc/netplan/00-installer-config.yaml
network:
  version: 2
  ethernets:
    ${ADAPTER_ID}:
      dhcp4: false
      addresses:
        - 10.9.19.${LAST_OCTET}/24
      nameservers:
        addresses:
          - 10.9.19.200
          - 10.9.19.210
          - 8.8.8.8
          - 8.8.4.4
      routes:
        - to: 0.0.0.0/0
          via: 10.9.19.80
EOF
sleep 3
clear

# Step 9: Write /etc/network/interfaces
echo "------------------------------------------------------------"
echo "Step 9: Configuring /etc/network/interfaces..."
echo "------------------------------------------------------------"
cat <<EOF > /etc/network/interfaces
auto ${ADAPTER_ID}
iface ${ADAPTER_ID} inet static
    address 10.9.19.${LAST_OCTET}
    netmask 255.255.255.0
    gateway 10.9.19.80
    dns-nameservers 10.9.19.200 10.9.19.210 8.8.8.8 8.8.4.4
EOF
echo "✅ /etc/network/interfaces written with static config for $ADAPTER_ID"
sleep 3
clear

# Step 10: Install Cockpit
echo "------------------------------------------------------------"
echo "Step 10: Installing Cockpit..."
echo "------------------------------------------------------------"
sudo apt update -y
sudo apt install cockpit -y
sudo systemctl enable --now cockpit.socket
echo "✅ Cockpit installed and running. Access it via: https://<your-server-ip>:9090"
sleep 3
clear

# Step 11: Install Netdata
echo "------------------------------------------------------------"
echo "Step 11: Installing Netdata..."
echo "------------------------------------------------------------"
wget -q https://get.netdata.cloud/kickstart.sh -O ./kickstart.sh
sudo bash ./kickstart.sh --yes
rm -f ./kickstart.sh
echo "✅ Netdata installation complete."
sleep 3
clear

# Step 12: Install Docker & Docker Compose
echo "------------------------------------------------------------"
echo "Step 12: Installing Docker & Docker Compose..."
echo "------------------------------------------------------------"
sudo apt update -y
sudo apt install docker.io -y
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "✅ Docker and Docker Compose installed successfully."
sleep 3
clear

# Step 13: Install Webmin
echo "------------------------------------------------------------"
echo "Step 13: Installing Webmin..."
echo "------------------------------------------------------------"
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list'
sudo apt-get update -y
sudo apt-get -y install webmin
echo "✅ Webmin installed successfully. Access it via: https://<your-server-ip>:10000"
sleep 3
clear

# Step 14: Final System Updates
echo "------------------------------------------------------------"
echo "Step 14: Final System Update and Cleanup..."
echo "------------------------------------------------------------"
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install -f -y
sudo apt autoremove -y
rm *.sh
echo "✅ System update, cleanup, and network configuration complete."
sleep 3
clear

# Step 15: Final Message and Shutdown
echo "------------------------------------------------------------"
echo "Step 15: Finishing Setup..."
echo "------------------------------------------------------------"
echo "⚠️ System is shutting down. Please create a snapshot before rebooting this server back up."
sleep 5
shutdown now
