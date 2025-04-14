#!/bin/bash

# ------------------------------------------------------------
# 🧩 Fixed ERPNext Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------

default_password="ict01@Unigroup"
server_ip=$(ip route get 1 | awk '{print $7; exit}')

print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

#sleepclear() {
#    sleep 3
#    clear
#}

clear

# ============================================================
# PHASE 1: SYSTEM PREPARATION (as root)
# ============================================================

print_step "Step 1: 🚀 System Preparation"
apt-get update -y && apt-get upgrade -y && apt-get install -y expect
sleep 3 && clear

# ============================================================
# PHASE 2: FRAPPE USER SETUP (as root)
# ============================================================

print_step "Step 2: 💼 Creating Frappe User"
adduser --gecos "" --disabled-password frappe
echo "frappe:$default_password" | chpasswd
usermod -aG sudo frappe

# Configure passwordless sudo for automation
echo "frappe ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/frappe
chmod 440 /etc/sudoers.d/frappe

# ============================================================
# PHASE 3: INSTALLATIONS (as frappe user)
# ============================================================

# Execute all subsequent commands as frappe user
su - frappe <<FRAPPE_EOF
#!/bin/bash

default_password="ict01@Unigroup"

print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo "\$1"
    echo "------------------------------------------------------------"
}

cd /home/frappe

# ------------------------------------------------------------
# SYSTEM PACKAGES
# ------------------------------------------------------------
print_step "Step 3: 🧬 Installing essential system packages"
sudo apt-get install -y git python3-dev python3-setuptools python3-pip python3.12-venv
sleep 3 && clear

# ------------------------------------------------------------
# MARIADB INSTALLATION (FIXED SECTION)
# ------------------------------------------------------------
print_step "Step 4-5: 📂 Installing and Securing MariaDB"
sudo apt-get install -y software-properties-common mariadb-server

# Secure MariaDB installation with proper password handling
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$default_password';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# MariaDB configuration
sudo bash -c "cat > /etc/mysql/my.cnf" <<CONFIG_EOF
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
CONFIG_EOF

sudo service mysql restart
sleep 3 && clear

# ------------------------------------------------------------
# ADDITIONAL SERVICES
# ------------------------------------------------------------
print_step "Step 6: 🧠 Installing Redis"
sudo apt-get install -y redis-server
sleep 3 && clear

print_step "Step 7: ⚙️ Installing Node.js 18.x using NVM"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
nvm install 18
sleep 3 && clear

print_step "Step 8: 🧵 Installing Yarn"
sudo apt-get install -y npm
sudo npm install -g yarn
sleep 3 && clear

print_step "Step 9: 🖨️ Installing wkhtmltopdf"
sudo apt-get install -y xvfb libfontconfig wkhtmltopdf
sleep 3 && clear

# ------------------------------------------------------------
# BENCH SETUP
# ------------------------------------------------------------
print_step "Step 10: 🏗️ Installing frappe-bench CLI"
sudo -H pip3 install frappe-bench --break-system-packages
sleep 3 && clear

print_step "Step 11: 🚀 Initializing bench"
bench init frappe-bench --frappe-branch version-15
cd frappe-bench
sleep 3 && clear

print_step "Step 12: 🏗️ Creating new site"
bench new-site erpnext.my-unigroup.local \\
    --admin-password "$default_password" \\
    --mariadb-root-password "$default_password"
sleep 3 && clear

print_step "Step 13: 📦 Getting apps"
bench get-app erpnext --branch version-15
bench get-app payments
bench get-app hrms
sleep 3 && clear

print_step "Step 14: 🧩 Installing apps"
bench --site erpnext.my-unigroup.local install-app erpnext
bench --site erpnext.my-unigroup.local install-app hrms
sleep 3 && clear

# ------------------------------------------------------------
# FINAL SETUP
# ------------------------------------------------------------
print_step "Step 15: 🚀 Starting ERPNext"
bench use erpnext.my-unigroup.local
bench start &
sleep 3 && clear

print_step "Step 16: ⚙️ System Configuration"
bench --site erpnext.my-unigroup.local set-maintenance-mode off
bench --site erpnext.my-unigroup.local enable-scheduler
sleep 3 && clear

FRAPPE_EOF

# ============================================================
# FINAL MESSAGE (back to root context)
# ============================================================

clear
echo "------------------------------------------------------------"
echo "🎉 ERPNext Installation Complete! 🎉"
echo "------------------------------------------------------------"
echo "Installation was successful!"
echo "You can now access ERPNext via: http://$server_ip:8000"
echo ""
echo "Default admin credentials:"
echo "Email: administrator@example.com"
echo "Password: $default_password"
echo "------------------------------------------------------------"
