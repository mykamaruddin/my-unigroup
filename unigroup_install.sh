#!/bin/bash

# setup_myk_nodes.sh
# Ubuntu LTS Node Setup Script for MYK Nodes

set -e  # Exit on error

### Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root. Try: sudo ./setup_myk_nodes.sh"
   exit 1
fi

### Prompt for base hostname
read -rp "Enter the base hostname for this node (e.g., dns-01): " BASE_HOSTNAME

# Append domain to form full hostname
FULL_HOSTNAME="${BASE_HOSTNAME}.my-unigroup.local"

echo "🧩 Setting hostname to '$FULL_HOSTNAME'..."
hostnamectl set-hostname "$FULL_HOSTNAME"

### Set Timezone
echo "🌐 Setting timezone to Asia/Kuala_Lumpur..."
timedatectl set-timezone Asia/Kuala_Lumpur

sleep 3  # Pause for 3 seconds

### Prompt for the last octet of the IP address
read -rp "Enter the last octet of the IP address (e.g., 24 for 10.9.19.24): " LAST_OCTET
sleep 3  # Pause for 3 seconds

echo "📡 Using provided IP last octet: $LAST_OCTET"
sleep 3  # Pause for 3 seconds

### Rebuild /etc/hosts
echo "🛠️ Replacing /etc/hosts..."

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

sleep 3  # Pause for 3 seconds

### Disable cloud-init network config
echo "📛 Disabling cloud-init network config..."

cat <<EOF > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}
EOF

echo "✅ Cloud-init network config disabled in 99-disable-network-config.cfg"
sleep 3  # Pause for 3 seconds

### Detect network adapter
echo "🌐 Detecting primary network adapter..."
ADAPTER_ID=$(ip -o link show | awk -F': ' '!/lo|docker/ {print $2; exit}')
echo "✅ Detected network adapter: $ADAPTER_ID"
sleep 3  # Pause for 3 seconds

### Replace netplan config
echo "🧼 Clearing existing netplan configs..."
cd /etc/netplan/
rm -f ./*

echo "📝 Writing new static IP config to 00-installer-config.yaml..."

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

sleep 3  # Pause for 3 seconds

### Configure legacy /etc/network/interfaces
echo "🧾 Writing /etc/network/interfaces for interface $ADAPTER_ID..."

cat <<EOF > /etc/network/interfaces
auto ${ADAPTER_ID}
iface ${ADAPTER_ID} inet static
    address 10.9.19.${LAST_OCTET}
    netmask 255.255.255.0
    gateway 10.9.19.80
    dns-nameservers 10.9.19.200 10.9.19.210 8.8.8.8 8.8.4.4
EOF

echo "✅ /etc/network/interfaces written with static config for $ADAPTER_ID"

sleep 3  # Pause for 3 seconds

### Install Cockpit
echo "🔧 Installing Cockpit..."
sudo apt update -y
sudo apt install cockpit -y

echo "🖱️ Enabling and starting Cockpit service..."
sudo systemctl enable --now cockpit.socket

echo "✅ Cockpit installed and running. Access it via: https://<your-server-ip>:9090"

sleep 3  # Pause for 3 seconds

### Download and run Netdata installer
echo "🌐 Downloading Netdata installer script..."
sudo wget https://get.netdata.cloud/kickstart.sh -O /tmp/kickstart.sh

echo "⚙️ Running Netdata installer..."
sudo bash /tmp/kickstart.sh

echo "✅ Netdata installation complete."

sleep 3  # Pause for 3 seconds

### Install Docker and Docker Compose
echo "🔧 Installing Docker..."
sudo apt update -y
sudo apt install docker.io -y

echo "🖱️ Adding user to docker group..."
sudo usermod -aG docker $USER

echo "⬇️ Downloading Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

echo "⚙️ Making Docker Compose executable..."
sudo chmod +x /usr/local/bin/docker-compose

echo "✅ Docker and Docker Compose installed successfully."

sleep 3  # Pause for 3 seconds

### Install Webmin
echo "🌐 Adding Webmin GPG key..."
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -

echo "📦 Adding Webmin repository..."
sudo sh -c 'echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list'

echo "🔄 Updating package list..."
sudo apt-get update -y

echo "🔧 Installing Webmin..."
sudo apt-get -y install webmin

echo "✅ Webmin installed successfully. Access it via: https://<your-server-ip>:10000"

sleep 3  # Pause for 3 seconds

### Final system updates and cleanup
echo "🔄 Updating and upgrading system packages..."
sudo apt update -y && sudo apt upgrade -y

### Check for and install any missing dependencies
echo "🔧 Checking and installing missing dependencies..."
sudo apt-get install -f -y

echo "🧹 Removing unnecessary packages..."
sudo apt autoremove -y

### Apply netplan configuration
### echo "⚙️ Applying netplan configuration..."
### sudo netplan apply

echo "✅ System update, cleanup, network configuration complete. It will now shutdown for snapshot"
sleep 3  # Pause for 3 seconds

sudo shutdown now
