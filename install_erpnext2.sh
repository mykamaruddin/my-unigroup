#!/bin/bash

# ------------------------------------------------------------
# 🧩 ERPNext Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------

default_password="ict01@Unigroup"
# Store server's primary IP in variable (silent)
server_ip=$(ip route get 1 | awk '{print $7; exit}')

# Helper function to create clean visual breaks and step display
print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

# Helper function to pause and clear the screen
pause_and_clear() {
    sleep 3
    clear
}

clear

# Step 2.1 : Continue Installation
print_step "Step 2.1: 🧬Continue installation"
su frappe
cd /home/frappe
pause_and_clear

# Step 3 : Installing essential system packages
print_step "Step 3: 🧬 Installing essential system packages"
sudo apt-get install -y git
sudo apt-get install -y python3-dev
sudo apt-get install -y python3-setuptools python3-pip
sudo apt install -y python3.12-venv
pause_and_clear

# Step 4: Install and MariaDB
print_step "Step 4: 📂 Installing MariaDB"
sudo apt-get install -y software-properties-common
sudo apt install -y mariadb-server

# Step 5: Securing and Updating MariaDB installation...
print_step "Step 5: 🔐 Securing MariaDB installation..."
MYSQL_ROOT_PASSWORD=$default_password
expect <<EOF
spawn sudo mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "Y\r"
expect "Change the root password?"
send "Y\r"
expect "New password:"
send "$MYSQL_ROOT_PASSWORD\r"
expect "Re-enter new password:"
send "$MYSQL_ROOT_PASSWORD\r"
expect "Remove anonymous users?"
send "Y\r"
expect "Disallow root login remotely?"
send "Y\r"
expect "Remove test database and access to it?"
send "Y\r"
expect "Reload privilege tables now?"
send "Y\r"
expect eof
EOF

# Update MariaDB character set
sudo bash -c "cat >> /etc/mysql/my.cnf" <<EOF
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF

sudo service mysql restart
pause_and_clear

# Step 6: 🧠 Installing Redis (in-memory data store)
print_step "Step 6: 🧠 Installing Redis (in-memory data store)"
sudo apt-get install -y redis-server
pause_and_clear

# Step 7: ⚙️ Installing Node.js 18.x using NVM
print_step "Step 7: ⚙️ Installing Node.js 18.x using NVM"
sudo apt install -y curl
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.profile
nvm install 18
pause_and_clear

# Step 8: 🧵 Installing Yarn
print_step "Step 8: 🧵 Installing Yarn"
sudo apt-get install -y npm
sudo npm install -g yarn
pause_and_clear

# Step 9: 🖨️ Installing wkhtmltopdf (PDF rendering engine)
print_step "Step 9: 🖨️ Installing wkhtmltopdf"
sudo apt-get install -y xvfb libfontconfig wkhtmltopdf
pause_and_clear

# Step 10: 🏗️ Installing frappe-bench CLI
print_step "Step 10: 🏗️ Installing frappe-bench CLI"
sudo -H pip3 install frappe-bench --break-system-packages
bench --version
pause_and_clear

# Step 11: 🚀 Initializing the frappe bench with Frappe version-15
print_step "Step 11: 🚀 Initializing the frappe bench with Frappe version-15"
bench init frappe-bench --frappe-branch version-15
cd frappe-bench/
chmod -R o+rx /home/frappe
pause_and_clear

# Step 12: 🏗️ Creating new ERPNext site
print_step "Step 12: 🏗️ Creating new ERPNext site"
bench new-site erpnext.my-unigroup.local --admin-password "$default_password" --mariadb-root-password "$default_password"
pause_and_clear

# Step 13: 📦 Getting ERPNext, Payments, and HRMS apps
print_step "Step 13: 📦 Getting ERPNext, Payments, and HRMS apps"
bench get-app erpnext --branch version-15
bench get-app payments
bench get-app hrms
pause_and_clear

# Step 14: 🧩 Installing ERPNext and HRMS apps to the site
print_step "Step 14: 🧩 Installing ERPNext and HRMS apps to the site"
bench --site erpnext.my-unigroup.local install-app erpnext
bench --site erpnext.my-unigroup.local install-app hrms
pause_and_clear

# Step 15: 🚀 Starting ERPNext system
print_step "Step 13: 🚀 Starting ERPNext system"
bench use erpnext.my-unigroup.local
bench start
pause_and_clear

# Step 16: ⚙️ Disable maintenance mode and enable scheduler
print_step "Step 16: ⚙️ Disabling maintenance mode and enabling scheduler"
bench --site erpnext.my-unigroup.local set-maintenance-mode off
bench --site erpnext.my-unigroup.local enable-scheduler
pause_and_clear

# Final Step: Inform the user of the IP address for future access
clear
echo "------------------------------------------------------------"
echo "🎉 ERPNext Installation Complete! 🎉"
echo "------------------------------------------------------------"
echo "Installation was successful!"
echo "You can now access ERPNext via: http://$server_ip:8080"
echo "------------------------------------------------------------"
pause_and_clear
