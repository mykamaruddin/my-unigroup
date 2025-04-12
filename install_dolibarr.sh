#!/bin/bash

# ------------------------------------------------------------
# 🧩 Dolibarr Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------

MYSQL_ROOT_PASSWORD="ict01@Unigroup"
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Function to print horizontal line
print_line() {
    echo "======================================"
}

# Step 1: Update and Upgrade System
clear
echo -e "🔧 Step 1: Updating and upgrading system packages"
sudo apt update -y && sudo apt upgrade -y
print_line

# Step 2: Installing PHP and required PHP extensions
clear
echo -e "📦 Step 2: Installing PHP and required extensions"
sudo apt install -y php php-cli php-mysql php-common php-zip php-mbstring php-xmlrpc php-curl php-soap php-gd php-xml php-intl php-ldap
print_line

# Step 3: Installing Apache PHP module
clear
echo -e "🧩 Step 3: Installing Apache PHP module (libapache2-mod-php)"
sudo apt install -y libapache2-mod-php
print_line

# Step 4: Configuring PHP settings in php.ini
clear
echo -e "🛠️  Step 4: Configuring PHP settings"

# Automatically configure php.ini settings
sudo sed -i 's/^;date.timezone =.*/date.timezone = Asia\/Kuala_Lumpur/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^memory_limit =.*/memory_limit = 256M/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^upload_max_filesize =.*/upload_max_filesize = 64M/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^display_errors =.*/display_errors = On/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^log_errors =.*/log_errors = Off/' /etc/php/*/apache2/php.ini

print_line

clear
echo "Step 5: 🔐 Securing MariaDB installation..."
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
print_line

clear
echo "Step 6: 🛢️ Creating Dolibarr database and user..."
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE dolibarr;
CREATE USER 'dolibarr_user'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF
print_line

# Step 5: Download the newest Dolibarr release
clear
echo -e "📥 Step 5: Downloading the latest Dolibarr release"

# Get the latest release tag for Dolibarr
release_tag=$(curl -s https://api.github.com/repos/Dolibarr/dolibarr/releases/latest | grep tag_name | cut -d '"' -f 4)

# Download the latest release
wget https://github.com/Dolibarr/dolibarr/archive/$release_tag.tar.gz

print_line

# Step 6: Extracting the Dolibarr archive
clear
echo -e "📂 Step 6: Extracting the Dolibarr archive"
# Extract the downloaded Dolibarr tarball
tar xvf $release_tag.tar.gz

print_line

# Step 7: Moving Dolibarr files to /srv/dolibarr
clear
echo -e "🚚 Step 7: Moving Dolibarr to /srv directory"
# Move extracted Dolibarr directory
sudo mv dolibarr-$release_tag /srv/dolibarr

print_line

# Step 8: Setting ownership to www-data
clear
echo -e "🔒 Step 8: Setting permissions for Dolibarr directory"


# Set correct ownership
sudo chown -R www-data:www-data /srv/dolibarr

print_line

# Step 9: Installing Apache2 and enabling mod_rewrite
clear
echo -e "🌐 Step 9: Installing Apache2 and enabling URL rewriting"

# Install Apache2
sudo apt -y install apache2

# Enable Apache rewrite module
sudo a2enmod rewrite

print_line

# Step 10: Creating Apache Virtual Host configuration for Dolibarr
clear
echo -e "📝 Step 10: Creating Apache Virtual Host for Dolibarr"
print_line

# Write custom Apache virtual host config
sudo bash -c 'cat > /etc/apache2/sites-enabled/dolibarr.conf <<EOF
<VirtualHost *:80>
    ServerAdmin ict@my-unigroup.com
    ServerName $server_ip
    ServerAlias dolibarr.my-unigroup.local
    DocumentRoot /srv/dolibarr/htdocs/

    <Directory /srv/dolibarr/htdocs/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/dolibarr_error.log
    CustomLog /var/log/apache2/dolibarr_access.log combined
</VirtualHost>
EOF'

print_line

# Step 11: Restarting Apache to apply changes
clear
echo -e "🔁 Step 11: Restarting Apache web server"

# Restart Apache to apply the new virtual host
sudo systemctl restart apache2

print_line

# Step 12: Installation complete – Access Dolibarr via browser
clear
echo -e "✅ Step 12: Dolibarr installation base is complete!"
print_line

# Display access URL
echo -e "🌐 Please open your browser and navigate to:"
echo -e "👉 http://$server_ip"
echo -e "to complete the Dolibarr web-based installation wizard."
print_line
