#!/bin/bash

# ------------------------------------------------------------
# 🧩 Cyberpanel Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------

MYSQL_ROOT_PASSWORD="ict01@Unigroup"
# Store server's primary IP in variable (silent)
server_ip=$(ip route get 1 | awk '{print $7; exit}')

# Function to print a horizontal line
print_line() {
    echo "─────────────────────────────────────────────────────────────"
}

clear
print_line
echo "⚠️ Please be ready to manually answer the prompts. The installation requires your input at certain stages. ⚠️"
echo "⚠️ The script will continue after the response is provided. ⚠️"
print_line
sleep 5

clear
# Step 1: Update and Upgrade System
print_line
echo "🛠️  Step 1: Updating and upgrading the system"
print_line

sudo apt update && sudo apt upgrade -y

sleep 3

clear
# Step 2: Install CyberPanel (Fully Automated without Logging)
print_line
echo "📦  Step 2: Installing CyberPanel"
print_line

# Use sudo to run the script to install
sudo su - -c "sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)"

