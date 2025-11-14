# 🌐 AWS Deployment Guide for Multiplayer Fight Game

## Overview
This guide walks you through hosting your Godot multiplayer game on AWS using an EC2 instance.

---

## 📋 Prerequisites
- AWS Account (Free tier is sufficient for testing)
- Your game exported as a Linux headless build
- Basic command line knowledge

---

## 🚀 Step-by-Step Deployment

### 1️⃣ Export Your Game for Linux Server

**In Godot:**
1. Go to **Editor** → **Manage Export Templates** → Download Linux templates
2. Go to **Project** → **Export**
3. Click **Add...** → **Linux/X11**
4. **Important Settings:**
   - ✅ Check **"Runnable"**
   - ✅ Check **"Embed PCK"**
   - Architecture: **x86_64**
5. Click **Export Project** → Save as `multiplayer-fight-server` (no .exe extension)

**Note:** You don't need to change `Is Server` in the scene anymore! The game now uses command-line arguments (`--server`) to run as a server.

### 2️⃣ Create an AWS EC2 Instance

**Launch Instance:**
1. Log into [AWS Console](https://console.aws.amazon.com)
2. Go to **EC2** → **Launch Instance**
3. **Settings:**
   - **Name:** `multiplayer-fight-server`
   - **OS:** **Ubuntu Server 22.04 LTS** (Free tier eligible)
   - **Instance Type:** `t2.micro` (free tier) or `t2.small` (better performance)
   - **Key Pair:** Create new key pair (download the `.pem` file - you'll need this!)
   - **Network Settings:**
     - ✅ Allow SSH (port 22)
     - ✅ **Add Rule:** Custom TCP, Port `7777`, Source: `0.0.0.0/0` (your game port!)
4. Click **Launch Instance**

**Save your public IP address** (e.g., `54.123.45.67`)

### 3️⃣ Connect to Your Server

**Windows (PowerShell):**
```powershell
# Navigate to where you saved your .pem file
cd C:\Users\YourName\Downloads

# Set permissions
icacls "your-key.pem" /inheritance:r
icacls "your-key.pem" /grant:r "%username%:R"

# Connect
ssh -i "your-key.pem" ubuntu@YOUR_PUBLIC_IP
```

**Or use PuTTY** (easier for Windows):
- Download [PuTTY](https://www.putty.org/)
- Convert `.pem` to `.ppk` using PuTTYgen
- Connect using your public IP and the `.ppk` key

### 4️⃣ Upload and Run Your Server

**Upload the server file:**
```bash
# On your local machine (new terminal/PowerShell window)
scp -i "your-key.pem" multiplayer-fight-server ubuntu@YOUR_PUBLIC_IP:~/
```

**On the server (SSH session):**
```bash
# Make it executable
chmod +x multiplayer-fight-server

# Install required libraries (for Godot)
sudo apt update
sudo apt install -y libgl1-mesa-glx libx11-6 libxcursor1 libxi6 libxrandr2

# Run the server with --server flag
nohup ./multiplayer-fight-server --server > server.log 2>&1 &

# Check if it's running
ps aux | grep multiplayer-fight

# View the log
tail -f server.log
```

**To keep it running permanently:**
```bash
# Create a systemd service
sudo nano /etc/systemd/system/multiplayer-fight.service
```

**Paste this:**
```ini
[Unit]
Description=Multiplayer Fight Game Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/multiplayer-fight-server --server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Then:**
```bash
# Start the service
sudo systemctl daemon-reload
sudo systemctl enable multiplayer-fight
sudo systemctl start multiplayer-fight

# Check status
sudo systemctl status multiplayer-fight
```

### 5️⃣ Export Client Version

**In Godot:**
1. Go to **Project** → **Export**
2. Select **Windows Desktop**
3. ✅ Check **"Embed PCK"**
4. Click **Export Project** → Save as `multiplayer-fight.exe`

**Then create `server_config.txt`:**
Create a text file next to the .exe with your server IP:
```
54.123.45.67
```

**Package for friends:**
- `multiplayer-fight.exe`
- `server_config.txt`

Zip these together and send to friends!

---

## 🌐 Give Your Friends This:

Your friends just need to:
1. Download `multiplayer-fight.exe`
2. Run it
3. They'll automatically connect to your server!

**Your Server Address:** `YOUR_AWS_PUBLIC_IP:7777`

---

## 💰 AWS Costs

- **Free Tier:** 750 hours/month for 12 months (t2.micro)
- **After Free Tier:** ~$8-15/month for t2.micro
- **Better Performance:** ~$15-30/month for t2.small

---

## 🔧 Troubleshooting

### Players can't connect:
1. **Check Security Group:** Make sure port 7777 is open in EC2 settings
2. **Check server is running:** `sudo systemctl status multiplayer-fight`
3. **Check server logs:** `sudo journalctl -u multiplayer-fight -f`

### Server crashed:
```bash
# Restart it
sudo systemctl restart multiplayer-fight

# View logs
sudo journalctl -u multiplayer-fight -n 50
```

### Update your game:
```bash
# On your local machine
scp -i "your-key.pem" multiplayer-fight-server ubuntu@YOUR_PUBLIC_IP:~/

# On the server
sudo systemctl restart multiplayer-fight
```

---

## 🎮 Alternative: Use a Custom Domain

Instead of an IP address, you can use a domain:
1. Buy a domain (e.g., from Namecheap, $10/year)
2. Point an **A record** to your AWS public IP
3. Update `server_address` in GameLauncher to `yourdomain.com`

---

## 📊 Monitor Your Server

**Check CPU/Memory usage:**
```bash
htop  # Install: sudo apt install htop
```

**Check active connections:**
```bash
netstat -an | grep 7777
```

---

## 🛡️ Security Best Practices

1. **Only open necessary ports** (22 for SSH, 7777 for game)
2. **Keep Ubuntu updated:** `sudo apt update && sudo apt upgrade`
3. **Consider using AWS Elastic IP** (so your IP doesn't change if you restart)

---

That's it! Your game is now live on AWS! 🚀

