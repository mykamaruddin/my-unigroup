#!/bin/bash

# ------------------------------------------------------------
# 🧩 Odoo 18 Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------
print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

sleep_clear() {
    sleep 3
    clear
}

# ============================================================
# PHASE 1: SYSTEM PREPARATION (as root)
# ============================================================
print_step "🛠️  Starting Odoo 18 Installation on Ubuntu 24.04"


# Configuration variables
ODOO_VERSION="18.0"
ODOO_USER="odoo18"
ODOO_PASSWORD="ict01@Unigroup"
DB_USER="odoo18"
DB_PASSWORD="ict01@Unigroup"
ADMIN_PASSWORD="ict01@Unigroup"
SERVER_IP="10.9.19.26"
FQDN="odoo.my-unigroup.local"

sleep_clear

# ============================================================
# PHASE 2: SYSTEM UPDATE & DEPENDENCIES
# ============================================================
print_step "🔧 STEP 1: Updating System Packages"
apt update -y && apt upgrade -y
sleep_clear

# ============================================================
# PHASE 3: PYTHON INSTALLATION
# ============================================================
print_step "🐍 STEP 2: Installing Python and Dependencies"
apt install -y build-essential wget git python3-pip python3-dev python3-venv \
python3-wheel python3 libfreetype6-dev libxml2-dev libzip-dev libsasl2-dev \
python3-setuptools libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libldap2-dev \
libtiff5-dev libopenjp2-7-dev

echo ""
echo "✅ Python version:"
python3 -V
sleep_clear

# ============================================================
# PHASE 4: NODE.JS & WKHTMLTOPDF
# ============================================================
print_step "📦 STEP 3: Installing NPM and Node CSS Plugins"
apt install -y npm
npm install -g less less-plugin-clean-css
apt install -y node-less
sleep_clear

print_step "📄 STEP 4: Installing Wkhtmltopdf"
apt install -y wkhtmltopdf
ln -s /usr/local/bin/wkhtmltopdf /usr/bin
sleep_clear

# ============================================================
# PHASE 5: DATABASE SETUP
# ============================================================
print_step "🗄️  STEP 5: Installing PostgreSQL"
apt install -y postgresql
systemctl start postgresql && systemctl enable postgresql
sleep_clear

print_step "👤 STEP 6: Creating Odoo System and Database User"
useradd -m -U -r -d /opt/odoo18 -s /bin/bash odoo18
su - postgres -c "createuser -s odoo18"
su - postgres -c "psql -c \"ALTER USER odoo18 WITH PASSWORD '$DB_PASSWORD';\""
sleep_clear

# ============================================================
# PHASE 6: ODOO INSTALLATION
# ============================================================
print_step "🚀 STEP 7: Installing Odoo 18"
su - odoo18 -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch $ODOO_VERSION /opt/odoo18/odoo18"
su - odoo18 -c "python3 -m venv odoo18-venv"
su - odoo18 -c "source odoo18-venv/bin/activate && pip install --upgrade pip && pip install wheel && pip install -r odoo18/requirements.txt && deactivate"

print_step "📂 Creating Directories and Setting Permissions"
mkdir /opt/odoo18/odoo18-custom-addons
chown -R odoo18:odoo18 /opt/odoo18/odoo18-custom-addons
mkdir -p /var/log/odoo18/ && touch /var/log/odoo18/odoo18.log
chown -R odoo18:odoo18 /var/log/odoo18/
sleep_clear

# ============================================================
# PHASE 7: CONFIGURATION FILES
# ============================================================
print_step "⚙️  STEP 8: Creating Odoo Configuration File"
cat > /etc/odoo18.conf <<EOL
[options]
admin_passwd = $ADMIN_PASSWORD
db_host = False
db_port = False
db_user = $DB_USER
db_password = $DB_PASSWORD
xmlrpc_port = 8069
logfile = /var/log/odoo18/odoo18.log
addons_path = /opt/odoo18/odoo18/addons,/opt/odoo18/odoo18-custom-addons
proxy_mode = True
without_demo = True
data_dir = /var/lib/odoo18
EOL

chown odoo18:odoo18 /etc/odoo18.conf
mkdir -p /var/lib/odoo18
chown odoo18:odoo18 /var/lib/odoo18
sleep_clear

print_step "🛠️  STEP 9: Creating Odoo Service File"
cat > /etc/systemd/system/odoo18.service <<EOL
[Unit]
Description=odoo18
After=postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo18
PermissionsStartOnly=true
User=odoo18
Group=odoo18
ExecStart=/opt/odoo18/odoo18-venv/bin/python3 /opt/odoo18/odoo18/odoo-bin -c /etc/odoo18.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOL
sleep_clear

# ============================================================
# PHASE 8: FINAL SETUP
# ============================================================
print_step "🚦 STEP 10: Starting Odoo Service"
systemctl daemon-reload
systemctl start odoo18 && systemctl enable odoo18

print_step "🔥 Configuring Firewall"
apt install -y ufw
ufw allow 22/tcp
ufw allow 8069/tcp
ufw --force enable
sleep_clear

# ============================================================
# INSTALLATION COMPLETE
# ============================================================
print_step "🎉 Installation Completed Successfully!"
echo ""
echo "🌐 Odoo 18 is now installed and running"
echo "   Access it at: http://$SERVER_IP:8069"
echo "   or http://$FQDN:8069"
echo ""
echo "🔑 Master password: $ADMIN_PASSWORD"
echo ""
echo "📋 Additional Commands:"
echo "   Check status: systemctl status odoo18"
echo "   View logs: journalctl -u odoo18 -f"
echo "   Restart service: systemctl restart odoo18"
echo ""
echo "------------------------------------------------------------"
