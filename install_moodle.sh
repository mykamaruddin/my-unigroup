#!/bin/bash

# ------------------------------------------------------------
# 📦 Moodle Auto-Installer for Ubuntu 24.04 (Headless Server)
# ------------------------------------------------------------

default_password="ict01@Unigroup"
server_ip=$(ip route get 1 | awk '{print $7; exit}')

print_step() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

clear

# ============================================================
# PHASE 1: SYSTEM PREPARATION
# ============================================================

print_step "Step 1: 🚀 System Preparation"
apt update -y && apt upgrade -y
apt install -y expect
sleep 2 && clear

# ============================================================
# PHASE 2: INSTALL REQUIRED PACKAGES
# ============================================================

print_step "Step 2: 📦 Installing Required Packages"
apt install -y apache2 mariadb-server php-cli php-intl php-xmlrpc php-soap php-mysql \
php-zip php-gd php-tidy php-mbstring php-curl php-xml php-pear php-bcmath libapache2-mod-php
sleep 2 && clear

# ============================================================
# PHASE 3: ENABLE SERVICES
# ============================================================

print_step "Step 3: ⚙️ Enabling Apache2 & MariaDB"
systemctl enable apache2
systemctl enable mariadb
sleep 2 && clear

# ============================================================
# PHASE 4: CONFIGURE MARIADB
# ============================================================

print_step "Step 4: 🛠️ Configuring MariaDB"
sed -i '/^\[mysqld\]/a innodb_file_format = Barracuda\n\
default_storage_engine = innodb\n\
innodb_large_prefix = 1\n\
innodb_file_per_table = 1' /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl restart mariadb
sleep 2 && clear

# ============================================================
# PHASE 5: SECURE MARIADB
# ============================================================

print_step "Step 5: 🔐 Securing MariaDB"

expect <<EOF
spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "n\r"
expect "Change the root password?"
send "Y\r"
expect "New password:"
send "$default_password\r"
expect "Re-enter new password:"
send "$default_password\r"
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

sleep 2 && clear

# ============================================================
# PHASE 6: CREATE MOODLE DATABASE
# ============================================================

print_step "Step 6: 🧰 Creating Moodle Database"

mysql -u root -p"$default_password" <<MYSQL_SCRIPT
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON moodle.* TO 'moodle'@'localhost' IDENTIFIED BY '${default_password}';
FLUSH PRIVILEGES;
QUIT
MYSQL_SCRIPT

sleep 2 && clear

# ============================================================
# PHASE 7: UPDATE PHP CONFIGURATION
# ============================================================

print_step "Step 7: 🧪 Tuning PHP Configuration"

PHPINI="/etc/php/8.3/apache2/php.ini"

sed -i "s/^memory_limit = .*/memory_limit = 256M/" "$PHPINI"
sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 60M/" "$PHPINI"
sed -i "s/^max_execution_time = .*/max_execution_time = 300/" "$PHPINI"
sed -i "s@^;date.timezone =.*@date.timezone = Asia/Kuala_Lumpur@" "$PHPINI"
sed -i "s/^max_input_vars = .*/max_input_vars = 5000/" "$PHPINI"

systemctl restart apache2
sleep 2 && clear

# ============================================================
# PHASE 8: DOWNLOAD & SETUP MOODLE
# ============================================================

print_step "Step 8: ⬇️ Downloading & Setting Up Moodle"

cd /var/www
wget https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz
tar xvf moodle-latest-404.tgz
mkdir -p /var/www/moodledata
chown -R www-data:www-data /var/www/moodle /var/www/moodledata
chmod u+rwx /var/www/moodle /var/www/moodledata
sleep 2 && clear

# ============================================================
# PHASE 9: CONFIGURE APACHE FOR MOODLE
# ============================================================

print_step "Step 9: 🌐 Configuring Apache for Moodle"

a2enmod rewrite

cat <<EOF > /etc/apache2/sites-available/moodle.conf
<VirtualHost *:80>
 DocumentRoot /var/www/moodle/
 ServerName moodle.my-unigroup.local
 ServerAdmin ict@my-unigroup.com

 <Directory /var/www/moodle/>
 Options +FollowSymlinks
 AllowOverride All
 Require all granted
 </Directory>

 ErrorLog /var/log/apache2/moodle_error.log
 CustomLog /var/log/apache2/moodle_access.log combined
</VirtualHost>
EOF

a2ensite moodle.conf
apachectl configtest
systemctl restart apache2
sleep 2 && clear

# ============================================================
# DONE 🎉
# ============================================================

print_step "✅ Installation Complete!"
echo ""
echo "🌐 Access Moodle at: http://$server_ip or http://moodle.my-unigroup.local"
echo "🔑 Moodle DB Password: $default_password"
echo ""
