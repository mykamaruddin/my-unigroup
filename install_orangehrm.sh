#!/bin/bash

set -e

# Variables
DB_NAME="orangehrm"
DB_USER="orangehrm_user"
DB_PASS='ict01@Unigroup'
ORANGEHRM_DIR="/var/www/html/orangehrm"
ORANGEHRM_URL="https://github.com/orangehrm/orangehrm/releases/download/v5.7/orangehrm-5.7.zip"
FQDN="orangehrm.my-unigroup.local"
SERVER_IP="10.9.19.26"

echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "🧼 Removing default MySQL if present..."
sudo apt remove --purge -y mysql-server mysql-client mysql-common || true
sudo rm -rf /etc/mysql /var/lib/mysql
sudo apt autoremove -y

echo "➕ Adding PHP 8.1 repository..."
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

echo "📦 Installing PHP 8.1 and extensions..."
sudo apt install -y php8.1 php8.1-{cli,curl,gd,mbstring,mysql,xml,zip,ldap} libapache2-mod-php8.1

echo "🔧 Setting PHP 8.1 as default..."
sudo update-alternatives --set php /usr/bin/php8.1

echo "➕ Adding MariaDB repository for version 10.11..."
sudo apt install -y curl gnupg
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.11

echo "📦 Installing MariaDB 10.11..."
sudo apt update
sudo apt install -y mariadb-server

echo "🔧 Enabling Apache modules..."
sudo a2enmod rewrite

echo "🚀 Starting and enabling MariaDB..."
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "🛠️ Creating MariaDB database and user..."
sudo mariadb -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mariadb -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

echo "⬇️ Downloading OrangeHRM 5.7..."
sudo mkdir -p $ORANGEHRM_DIR
cd /tmp
wget -O orangehrm.zip "$ORANGEHRM_URL"
unzip orangehrm.zip -d orangehrm_temp
sudo cp -r orangehrm_temp/orangehrm-5.7/* $ORANGEHRM_DIR
rm -rf orangehrm_temp orangehrm.zip

echo "🔐 Setting file permissions..."
sudo chown -R www-data:www-data $ORANGEHRM_DIR
sudo chmod -R 755 $ORANGEHRM_DIR

echo "📝 Creating Apache virtual host for OrangeHRM..."
cat << EOF | sudo tee /etc/apache2/sites-available/orangehrm.conf
<VirtualHost *:80>
    ServerAdmin ict@my-unigroup.com
    ServerName ${SERVER_IP}
    DocumentRoot ${ORANGEHRM_DIR}

    <Directory ${ORANGEHRM_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/orangehrm_error.log
    CustomLog \${APACHE_LOG_DIR}/orangehrm_access.log combined
</VirtualHost>
EOF

echo "🔗 Enabling site and restarting Apache..."
sudo a2ensite orangehrm.conf
sudo systemctl reload apache2

echo "📘 Updating /etc/hosts for local FQDN resolution..."
if ! grep -q "$FQDN" /etc/hosts; then
    echo "${SERVER_IP} ${FQDN}" | sudo tee -a /etc/hosts
fi

echo "✅ OrangeHRM 5.7 installed!"
echo "🌐 Access it at: http://${SERVER_IP}"
