#!/bin/bash

# 🚀 Step 1: Get the IP address of this server and store it
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "🔍 Server IP Address: $IP_ADDRESS"

# 📁 Step 2: Create directory for Manager.io
mkdir -p /usr/share/manager-server

# 🌐 Step 3: Download the latest ManagerServer release
wget https://github.com/Manager-io/Manager/releases/latest/download/ManagerServer-linux-x64.tar.gz -O /usr/share/manager-server/ManagerServer-linux-x64.tar.gz

# 📦 Step 4: Extract the downloaded archive
tar xvzf /usr/share/manager-server/ManagerServer-linux-x64.tar.gz -C /usr/share/manager-server

# ⚙️ Step 5: Create a systemd service file
cat <<EOF | tee /etc/systemd/system/manager-server.service
[Unit]
After=network.target

[Service]
LimitNOFILE=1048576
ExecStart=/usr/share/manager-server/ManagerServer -port 8080
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

# 🔄 Step 6: Reload systemd to recognize the new service
systemctl daemon-reload

# ▶️ Step 7: Start the ManagerServer service
systemctl start manager-server

# 📌 Step 8: Enable ManagerServer to start on boot
systemctl enable manager-server

# 🌐 Step 9: Output access URL
echo "✅ Manager.io Server is running!"
echo "🌐 Access it at: http://$IP_ADDRESS:8080"
