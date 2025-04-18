#!/bin/bash

# ------------------------------------------------------------
# 🧩 Fixed MintHCM Auto-Installer for Ubuntu 24.04 (Headless) + Docker
# ------------------------------------------------------------

# Default password and server IP
default_password="ict01@Unigroup"
server_ip=$(ip route get 1 | awk '{print $7; exit}')

# Function to print steps with enhanced cosmetic formatting
print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo -e "\033[1;34m$1\033[0m"  # Bold blue color for step titles
    echo "------------------------------------------------------------"
}

# Clear screen at the start
clear

# ============================================================
# PHASE 1: SYSTEM PREPARATION (as root)
# ============================================================

print_step "Step 1: 🚀 System Preparation"
echo -e "\033[1;33m- Removing any previous .sh files...\033[0m"
rm *.sh

echo -e "\033[1;33m- Updating system packages...\033[0m"
apt-get update -y && apt-get upgrade -y 

echo -e "\033[1;33m- Installing dependencies...\033[0m"
apt-get install -y expect

echo -e "\033[1;32m✔️ System preparation completed!\033[0m"
sleep 3 && clear

# ============================================================
# PHASE 2: DOWNLOAD DOCKER COMPOSE FILES
# ============================================================

print_step "Step 2: 📥 Downloading Docker Compose Files"

echo -e "\033[1;33m- Downloading docker-compose.yml...\033[0m"
curl -sSL https://raw.githubusercontent.com/minthcm/minthcm/master/docker/docker-compose.yml -o /home/ict/docker-compose.yml

echo -e "\033[1;33m- Downloading .env file...\033[0m"
curl -sSL https://raw.githubusercontent.com/minthcm/minthcm/master/docker/.env -o /home/ict/.env

echo -e "\033[1;32m✔️ Docker Compose files downloaded!\033[0m"
sleep 2 && clear

# ============================================================
# PHASE 3: DEPLOY DOCKER COMPOSE
# ============================================================

print_step "Step 3: 🚢 Deploying Docker Compose"
docker-compose up -d

echo -e "\033[1;32m✔️ Docker Compose deployed successfully!\033[0m"

# ============================================================
# PHASE 4: ACCESS INFORMATION AND REBOOT
# ============================================================

print_step "Step 4: 🌐 Access Information & Reboot"

# Display MintHCM access details
echo -e "\033[1;33m- Access MintHCM via: \033[1;32mhttp://$server_ip\033[0m"
echo -e "\033[1;33m- Initial username: \033[1;32madmin\033[0m"
echo -e "\033[1;33m- Initial password: \033[1;32mminthcm\033[0m"
echo -e "\033[1;33m- Please keep this information safe.\033[0m"

# Wait for 1 minutes before rebooting
echo -e "\033[1;33m- The system will reboot in 1 minutes. Please make sure you've noted down the access details.\033[0m"
sleep 60  # 1 minutes

# Reboot the system
echo -e "\033[1;32m✔️ Rebooting the system now...\033[0m"
reboot now
