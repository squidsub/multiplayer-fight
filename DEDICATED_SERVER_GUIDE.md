# 🖥️ Dedicated Server Deployment Guide

Your game is now ready for dedicated server deployment! Here's everything you need to know.

---

## 🎮 Three Ways to Run Your Game

### **1. As a Client (Normal Player)**
Just run the executable - it will automatically connect to the server specified in `server_config.txt`

```bash
# Windows
multiplayer-fight.exe

# Linux
./multiplayer-fight
```

### **2. As a Server (Using Command-Line)**
```bash
# Windows
multiplayer-fight.exe --server

# Linux
./multiplayer-fight --server
```

### **3. As a Client with Custom Server (Command-Line)**
```bash
# Connect to specific server
multiplayer-fight.exe --address=54.123.45.67

# Or short version
multiplayer-fight.exe -a=54.123.45.67
```

---

## 📝 Easy Configuration with `server_config.txt`

Instead of command-line args, you can create a `server_config.txt` file next to your game executable:

**server_config.txt:**
```
54.123.45.67
```

That's it! The game will read this file and connect to that server automatically.

---

## 🚀 Deployment Options

### **Option A: Simple EC2 Server (Recommended for Beginners)**

**Cost:** ~$8-15/month (or FREE for first year with AWS Free Tier)  
**Players:** Up to 50-100 players  
**Difficulty:** ⭐⭐ Easy

See `AWS_DEPLOYMENT_GUIDE.md` for complete EC2 setup instructions.

**Quick Steps:**
1. Export game as **Linux/X11 Headless**
2. Upload to AWS EC2 Ubuntu instance
3. Run: `./multiplayer-fight-server --server`
4. Done!

---

### **Option B: AWS GameLift (For Professional/Large Scale)**

**Cost:** ~$65+/month  
**Players:** 100s to 1000s  
**Difficulty:** ⭐⭐⭐⭐ Advanced

**Features:**
- Auto-scaling (spins up more servers when busy)
- Global server locations
- Built-in matchmaking
- Fleet management

**When to use:** When you expect 100+ concurrent players or want professional infrastructure.

---

### **Option C: Other Cloud Providers**

Your game will work on ANY Linux server:
- **DigitalOcean** - $4-12/month droplets
- **Linode** - $5-10/month instances
- **Google Cloud Platform** - Similar to AWS
- **Vultr** - $2.50-6/month instances
- **Your Own Computer** - Free (but must stay on 24/7)

---

## 📦 Export Instructions

### **For Linux Server (Headless - No Graphics):**

1. **Install Linux Export Templates:**
   - Editor → Manage Export Templates → Download

2. **Create Linux Export:**
   - Project → Export → Add... → Linux/X11
   - **Architecture:** x86_64
   - ✅ **Runnable**
   - ✅ **Embed PCK**
   - **Export Mode:** ❌ Regular build (not headless for now - Godot 4.x doesn't require it)

3. **Configure for Server:**
   - Open `Scenes/world.tscn`
   - Select **GameLauncher** node
   - ✅ Check **"Is Server"** = `true`

4. **Export:**
   - Click **Export Project**
   - Save as: `multiplayer-fight-server`
   - **No file extension!**

5. **Upload to Server:**
   ```bash
   scp -i your-key.pem multiplayer-fight-server ubuntu@YOUR_IP:~/
   ```

---

### **For Windows Client (For Friends):**

1. **Configure for Client:**
   - Open `Scenes/world.tscn`
   - Select **GameLauncher** node
   - ❌ Uncheck **"Is Server"** = `false`
   - Set **"Server Address"** = `YOUR_SERVER_IP`

2. **Export:**
   - Project → Export → Windows Desktop
   - ✅ **Embed PCK**
   - Click **Export Project**
   - Save as: `multiplayer-fight.exe`

3. **Package for Friends:**
   Create a folder with:
   ```
   multiplayer-fight.exe
   server_config.txt  (with your server IP inside)
   ```

   Zip it and send to friends!

---

## 🔧 Running on Server (Linux)

### **Simple Run (Foreground):**
```bash
chmod +x multiplayer-fight-server
./multiplayer-fight-server --server
```

### **Background Run:**
```bash
nohup ./multiplayer-fight-server --server > server.log 2>&1 &
```

### **Permanent Service (Best for Production):**

Create `/etc/systemd/system/multiplayer-fight.service`:
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

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable multiplayer-fight
sudo systemctl start multiplayer-fight

# Check status
sudo systemctl status multiplayer-fight

# View logs
sudo journalctl -u multiplayer-fight -f
```

---

## 🔍 Testing Your Setup

### **1. Test Locally First:**
```bash
# Terminal 1 - Start server
./multiplayer-fight --server

# Terminal 2 - Start client
./multiplayer-fight --address=localhost
```

### **2. Test on LAN:**
1. Start server on one computer
2. Find server's local IP: `ipconfig` (Windows) or `ifconfig` (Linux/Mac)
3. On another computer: `./multiplayer-fight --address=192.168.1.X`

### **3. Test on Internet:**
1. Deploy to cloud server
2. Update `server_config.txt` with server's public IP
3. Run client

---

## 🐛 Troubleshooting

### **"Connection Failed"**
- ✅ Check firewall allows port 7777
- ✅ Verify server is running: `ps aux | grep multiplayer-fight`
- ✅ Test with: `telnet YOUR_IP 7777`

### **"Server Not Found"**
- ✅ Check IP address in `server_config.txt`
- ✅ Ensure server started with `--server` flag
- ✅ Check AWS Security Group rules (port 7777 open)

### **Server Crashes:**
```bash
# View crash logs
sudo journalctl -u multiplayer-fight -n 100
```

### **High CPU Usage:**
- Normal for game servers
- Upgrade to t2.small or t2.medium on AWS

---

## 📊 Monitoring

### **Check Server Status:**
```bash
# Is it running?
systemctl status multiplayer-fight

# Resource usage
top
htop  # (install: sudo apt install htop)

# Active connections
netstat -an | grep 7777
ss -tuln | grep 7777
```

### **View Active Players:**
Currently connections are logged. You can add admin commands later for live monitoring.

---

## 🔐 Security Checklist

- ✅ Only open required ports (22 for SSH, 7777 for game)
- ✅ Use SSH keys, not passwords
- ✅ Keep system updated: `sudo apt update && sudo apt upgrade`
- ✅ Consider fail2ban for SSH protection
- ✅ Use AWS Security Groups / firewall rules

---

## 💰 Cost Estimates

### **AWS EC2:**
- **t2.micro** (Free tier): $0 for 12 months, then ~$8/month
- **t2.small**: ~$17/month (better performance)
- **t2.medium**: ~$34/month (for 50+ players)

### **DigitalOcean:**
- **Basic Droplet**: $4-6/month
- **CPU-Optimized**: $12-24/month

### **Your Own PC:**
- **Free** but:
  - Must run 24/7
  - Higher electricity cost
  - IP changes if router restarts (need dynamic DNS)

---

## 🎉 You're Ready!

Your game is now configured for dedicated server deployment. Choose your hosting method and follow the guides!

**Next Steps:**
1. Follow `AWS_DEPLOYMENT_GUIDE.md` to deploy on AWS
2. Export your client build with the server IP
3. Share with friends and start playing! 🎮

