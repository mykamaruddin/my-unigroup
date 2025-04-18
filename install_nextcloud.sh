#!/bin/bash

# ------------------------------------------------------------
# 🧩 Nextcloud Auto-Installer for Ubuntu 24.04
# ------------------------------------------------------------

default_password="ict01@Unigroup"
server_ip=$(ip route get 1 | awk '{print $7; exit}')
log_file="/var/log/nextcloud_install.log"

print_step() {
    echo -e "\n------------------------------------------------------------"
    echo -e "$1"
    echo -e "------------------------------------------------------------"
    echo -e "$1" >> "$log_file"
}

exec > >(tee -a "$log_file") 2>&1
clear

# ============================================================
# Step 1: 🚀 System Preparation
# ============================================================
print_step "Step 1: 🚀 Updating and Upgrading the System"
apt-get update -y && apt-get upgrade -y && apt-get install -y expect
sleep 3 && clear

# ============================================================
# Step 2: 🔧 Install Apache and PHP
# ============================================================
print_step "Step 2: 🔧 Installing Apache and PHP"
apt-get install -y apache2
apt-get install -y php php-common libapache2-mod-php php-bz2 php-gd php-mysql \
php-curl php-mbstring php-imagick php-zip php-common php-xml php-json \
php-bcmath php-intl php-gmp zip unzip wget

sleep 3 && clear

# ============================================================
# Step 3: 🔄 Enable Apache Modules
# ============================================================
print_step "Step 3: 🔄 Enabling Apache Modules"
a2enmod env rewrite dir mime headers setenvif ssl
systemctl restart apache2
systemctl enable apache2
sleep 3 && clear

# ============================================================
# Step 4: 🚜 Install and Configure MariaDB
# ============================================================
print_step "Step 4: 🚜 Installing MariaDB"
apt-get install -y mariadb-server

print_step "Creating Nextcloud Database and User"
mysql -u root <<EOF
CREATE USER 'ncloud'@'localhost' IDENTIFIED BY '${default_password}';
CREATE DATABASE ncloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON ncloud.* TO 'ncloud'@'localhost';
FLUSH PRIVILEGES;
EOF

systemctl restart mariadb
systemctl enable mariadb
sleep 3 && clear

# ============================================================
# Step 5: 📂 Download and Extract Nextcloud
# ============================================================
print_step "Step 5: 📂 Downloading Nextcloud"
cd /var/www/html
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
rm -rf latest.zip
chown -R www-data:www-data /var/www/html/nextcloud/
sleep 3 && clear

# ============================================================
# Step 6: 🧱 Nextcloud Silent Installation
# ============================================================
print_step "Step 6: 🧱 Running Nextcloud Installation"
cd /var/www/html/nextcloud
sudo -u www-data php occ maintenance:install --database "mysql" \
--database-name "ncloud" --database-user "ncloud" \
--database-pass "${default_password}" --admin-user "admin" \
--admin-pass "${default_password}"
sleep 3 && clear

# ============================================================
# Step 7: 📅 Set Trusted Domains
# ============================================================
print_step "Step 7: 📅 Configuring Trusted Domains"
config_file="/var/www/html/nextcloud/config/config.php"

awk -v ip="${server_ip}" '
BEGIN { updated=0 }
/.*trusted_domains.*/ {
    print "  '\''trusted_domains'\'' => ";
    print "  array (";
    print "    0 => '\''localhost'\'',";
    print "    1 => '\''" ip "'\'',";
    print "    2 => '\''nextcloud.my-unigroup.local'\'',";
    print "  ),";
    skip=1;
    updated=1;
    next
}
/^\s*\)/ && skip { skip=0; next }
skip == 0 { print }
END {
    if (updated == 0) {
        print "ERROR: Could not update trusted_domains block."
    }
}
' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
sleep 3 && clear

# ============================================================
# Step 8: 🌐 Apache Virtual Host Config
# ============================================================
print_step "Step 8: 🌐 Configuring Apache Virtual Host"
cat <<EOF > /etc/apache2/sites-enabled/000-default.conf
<VirtualHost *:80>
    ServerAdmin ict@my-unigroup.com
    ServerName ${server_ip}
    DocumentRoot /var/www/html/nextcloud

    <Directory /var/www/html/nextcloud>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

systemctl restart apache2
sleep 3 && clear

# ============================================================
# Step 9: 🔐 Fix config/ directory permissions
# ============================================================
print_step "Step 9: 🔐 Setting Correct Permissions for config/"
chown -R www-data:www-data /var/www/html/nextcloud/config/
chmod 750 /var/www/html/nextcloud/config/
chmod 640 /var/www/html/nextcloud/config/config.php
systemctl restart apache2
rm *.sh
sleep 3 && clear

# ============================================================
# Step 10: 📲 Display Access Info
# ============================================================
print_step "📲 Installation Complete!"
echo -e "\nAccess your Nextcloud instance at: http://${server_ip}/"
echo -e "Username: admin"
echo -e "Password: ${default_password}"
echo -e "\nInstallation log saved to: $log_file"
