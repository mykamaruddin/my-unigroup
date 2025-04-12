#!/bin/bash

# ------------------------------------------------------------
# 🧩 Snipe-IT Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------

MYSQL_ROOT_PASSWORD="ict01@Unigroup"
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Composer & Git Fixes
export COMPOSER_ALLOW_SUPERUSER=1
git config --global --add safe.directory /var/www/snipe-it
composer config --global github-protocols https
mkdir -p ~/.ssh
ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null

clear
echo "Step 1: 🛠️ Updating and upgrading system packages..."
sudo apt update -y && sudo apt upgrade -y
echo "------------------------------------------------------------"

clear
echo "Step 2: 📦 Installing core packages..."
sudo apt-get install unzip git apache2 mariadb-server mariadb-client php php-common php-bcmath php-bz2 php-intl php-gd php-mbstring php-mysql php-zip php-opcache php-intl php-json php-mysqli php-readline php-tokenizer php-curl php-ldap curl expect -y
echo "------------------------------------------------------------"

clear
echo "Step 3: 🔧 Enabling Apache mod_rewrite..."
sudo a2enmod rewrite
sudo systemctl restart apache2
echo "------------------------------------------------------------"

clear
echo "Step 4: 🔐 Securing MariaDB installation..."
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
echo "------------------------------------------------------------"

clear
echo "Step 5: 🛢️ Creating Snipe-IT database and user..."
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE snipe_it;
CREATE USER 'snipe_it_user'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON snipe_it.* TO 'snipe_it_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF
echo "------------------------------------------------------------"

clear
echo "Step 6: 📥 Cloning Snipe-IT repo and configuring..."
cd /var/www/
sudo git clone https://github.com/snipe/snipe-it snipe-it
cd /var/www/snipe-it
sudo cp .env.example .env
sudo sed -i "s|APP_URL=.*|APP_URL=http://$IP_ADDRESS|" .env
sudo sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE='Asia/Kuala_Lumpur'|" .env
sudo sed -i "s|DB_DATABASE=.*|DB_DATABASE=snipe_it|" .env
sudo sed -i "s|DB_USERNAME=.*|DB_USERNAME=snipe_it_user|" .env
sudo sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_ROOT_PASSWORD|" .env
sudo sed -i "s|APP_ENV=.*|APP_ENV=local|" .env
echo "------------------------------------------------------------"

clear
echo "Step 7: 📦 Installing Composer..."
cd /var/www/snipe-it
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
echo "------------------------------------------------------------"

clear
echo "Step 8: 📦 Running Composer install..."
cd /var/www/snipe-it
yes | composer install --no-dev --prefer-source --no-plugins --no-scripts
composer install
echo "------------------------------------------------------------"

clear
echo "Step 9: 🔐 Setting permissions..."
sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 777 storage
echo "------------------------------------------------------------"

clear
echo "Step 10: 🔑 Generating application key..."
expect <<EOF
spawn sudo php artisan key:generate
expect "Are you sure you want to run this command?"
send "\t"
send "\r"
expect eof
EOF
echo "------------------------------------------------------------"

clear
echo "Step 11: 🌐 Configuring Apache virtual host..."
sudo a2dissite 000-default.conf
sudo bash -c "cat > /etc/apache2/sites-available/snipe-it.conf <<EOL
<VirtualHost *:80>
    ServerName $IP_ADDRESS
    DocumentRoot /var/www/snipe-it/public
    <Directory /var/www/snipe-it/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
</VirtualHost>
EOL"
sudo a2ensite snipe-it.conf
sudo apachectl configtest
sudo systemctl restart apache2
echo "------------------------------------------------------------"

clear
echo "🎉 Setup complete! You can now access Snipe-IT at: http://$IP_ADDRESS"
echo "------------------------------------------------------------"
