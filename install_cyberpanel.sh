#!/bin/bash

# ------------------------------------------------------------
# 🧩 Cyberpanel Auto-Installer for Ubuntu 24.04 (Headless)
# ------------------------------------------------------------

MYSQL_ROOT_PASSWORD="ict01@Unigroup"
# Store server's primary IP in variable (silent)
server_ip=$(ip route get 1 | awk '{print $7; exit}')

# Function to print a horizontal line
print_line() {
    echo "─────────────────────────────────────────────────────────────"
}

# Step 1: Update and Upgrade System
print_line
echo "🛠️  Step 1: Updating and upgrading the system"
print_line

sudo apt update && sudo apt upgrade -y

sleep 3
clear

# Step 2: Install CyberPanel (Fully Automated without Logging)
print_line
echo "📦  Step 2: Installing CyberPanel"
print_line

# Use sudo to run the script and pass the necessary answers to the installer
sudo su - -c "sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)"

# Step 2: Wait for the prompt for "Please enter the number[1-2]:"
sleep 15  # Wait for the prompt to appear

# Step 3: Simulate pressing '1' and Enter to select "Install CyberPanel"
printf "1\n" > /dev/tty

# Step 4: Wait for the next prompt for "Please enter the number[1-3]:"
sleep 5

# Step 5: Simulate pressing '1' and Enter to select "Install CyberPanel with OpenLiteSpeed"
printf "1\n" > /dev/tty

# Step 6: Wait for the "Full installation" prompt
sleep 5

# Step 7: Simulate pressing 'Y' and Enter to confirm "Full installation"
printf "Y\n" > /dev/tty

# Step 8: Wait for the "Do you want to setup Remote MySQL?" prompt
sleep 5

# Step 9: Simulate pressing 'N' and Enter to not setup Remote MySQL
printf "N\n" > /dev/tty

# Step 10: Wait for the "Press Enter to continue with latest version" prompt
sleep 5

# Step 11: Simulate pressing Enter (no input needed)
printf "\n" > /dev/tty

# Step 12: Wait for the "Choose [d/r/s]" prompt for password
sleep 5

# Step 13: Simulate pressing 'r' and Enter to randomly generate the admin password
printf "r\n" > /dev/tty

# Step 14: Wait for the "Install Memcached" prompt
sleep 5

# Step 15: Simulate pressing 'Y' and Enter to install Memcached
printf "Y\n" > /dev/tty

# Step 16: Wait for the "Install Redis" prompt
sleep 5

# Step 17: Simulate pressing 'Y' and Enter to install Redis
printf "Y\n" > /dev/tty

# Step 18: Wait for the "Setup WatchDog" prompt
sleep 5

# Step 19: Simulate pressing 'Yes' and Enter to setup WatchDog
printf "Yes\n" > /dev/tty

# Step 20: Wait for the installation to complete (final step)
sleep 5
clear

# Step 3: Reboot System Automatically
#print_line
#echo "🔁  Step 3: Rebooting the system to complete setup"
#print_line

#sleep 3
#sudo reboot
