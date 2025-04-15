#!/bin/bash

# ------------------------------------------------------------
# 📋 Focalboard Auto-Installer for Ubuntu (via Docker)
# ------------------------------------------------------------

# Optional: Default server IP fetch
server_ip=$(ip route get 1 | awk '{print $7; exit}')

print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

clear

# ============================================================
# PHASE 1: SYSTEM UPDATE & PREPARATION
# ============================================================

print_step "Step 1: 🔄 Updating System Packages"
apt-get update -y && apt-get upgrade -y
sleep 2 && clear

# ============================================================
# PHASE 2: DOCKER INSTALLATION
# ============================================================

print_step "Step 2: 🐳 Installing Docker"
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
sleep 2 && clear

# ============================================================
# PHASE 3: SELECTING HOST PORT
# ============================================================

print_step "Step 3: 🔧 Configure Port for Focalboard"
read -p "🌐 Enter the host port you want to use for Focalboard (default: 80): " user_port
user_port=${user_port:-80}

# ============================================================
# PHASE 4: RUNNING FOCALBOARD
# ============================================================

print_step "Step 4: 🚀 Launching Focalboard with Docker"
echo ""
echo "✅ Focalboard will be running on: http://${server_ip}:${user_port}" once this process finished
echo ""
sleep 5
docker run -d -p ${user_port}:8000 mattermost/focalboard

