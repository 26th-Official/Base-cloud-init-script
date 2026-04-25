#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating system ==="
sudo apt update
sudo apt upgrade -y

echo "=== Installing base packages ==="
sudo apt install -y 
ca-certificates wget curl gnupg 
fail2ban unattended-upgrades 
software-properties-common haveged

echo "=== Configuring Fail2Ban ==="
sudo install -m 0644 /dev/null /etc/fail2ban/jail.local
sudo tee /etc/fail2ban/jail.local >/dev/null <<'EOF'
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 1h
findtime = 10m
EOF
sudo systemctl enable --now fail2ban

echo "=== Enabling unattended upgrades ==="
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

echo "=== Timezone & time sync ==="
sudo timedatectl set-timezone UTC
sudo systemctl enable --now systemd-timesyncd

echo "=== Installing Tailscale ==="
curl -fsSL https://tailscale.com/install.sh | sh
echo ">>> Run this when ready:"
echo ">>>   sudo tailscale up --authkey=YOUR_AUTH_KEY --ssh"

echo "=== Installing Node.js (NodeSource LTS) ==="
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== Installing latest Git ==="
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
sudo apt install -y git

echo "=== Installing Docker ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] 
https://download.docker.com/linux/ubuntu 
$(. /etc/os-release && echo $VERSION_CODENAME) stable" | 
sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Adding user to docker group ==="
sudo usermod -aG docker "$USER"

echo "=== Done ==="
echo "Re-login (or new SSH session) for docker group to apply."
