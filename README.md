# 🎮 Multiplayer Fight - Browser-Based .io Game

A fast-paced 2D multiplayer fighting game built with Godot Engine. **Play directly in your browser** - no downloads needed! Players are automatically assigned to Red or Blue teams and battle it out!

## ✨ Features

- 🌐 **Browser-based** - Play instantly, no downloads
- ⚔️ **Team-based multiplayer** - Auto-assigned to Red or Blue team
- 🎯 **Dedicated server support** - AWS cloud deployment ready
- 🪜 **Ladder climbing** - Navigate vertical spaces
- 👊 **Combat system** - Punch animations and health system
- 🏃 **Smooth movement** - Walk, run, and jump mechanics
- 📱 **Cross-platform** - Works on desktop, mobile browsers

## 🚀 Quick Start

### 🎮 Playing the Game (Browser)

**Just want to play?**
1. Visit the hosted URL: `https://yourgame.com`
2. Game loads in browser and auto-connects to server
3. You'll be automatically assigned to a team - start fighting!

### 🖥️ Hosting the Game

Your game has **two parts**:

**1. Game Server (EC2)** - Handles multiplayer logic
```bash
./multiplayer-fight-server --server
```

**2. Web Client (S3 + CloudFront)** - What players see in browser
- Export as HTML5
- Upload to AWS S3
- Serve via CloudFront CDN

**See `WEB_HOSTING_GUIDE.md` for complete setup!**

## 🎮 Controls

- **A/D** - Move left/right
- **W** - Climb ladders / Jump
- **SPACE** - Jump
- **SHIFT** - Sprint (run)
- **F** - Punch

## 📁 Project Structure

```
multiplayer-fight/
├── Scenes/
│   ├── world.tscn          # Main game scene
│   ├── RedGuy.tscn         # Red team player
│   └── BlueGuy.tscn        # Blue team player
├── Scripts/
│   ├── game_launcher.gd    # Handles server/client startup
│   ├── network_manager.gd  # Multiplayer networking
│   ├── red_guy_movement.gd # Red player controller
│   └── blue_guy_movement.gd# Blue player controller
├── Sprites/
│   ├── RedGuy/            # Red player animations
│   └── BlueGuy/           # Blue player animations
├── server_config.txt      # Server IP configuration
└── *.md                   # Documentation guides
```

## 📚 Documentation

### 🎯 New to AWS? Start Here:
- **[QUICK_START.md](QUICK_START.md)** - ⚡ **Deploy in 30 minutes** - Simplified step-by-step

### 📖 Complete Guides:
- **[WEB_HOSTING_GUIDE.md](WEB_HOSTING_GUIDE.md)** - 🌐 Full browser hosting guide (EC2 + S3 + CloudFront)
- **[AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)** - Alternative: Desktop client deployment
- **[DEDICATED_SERVER_GUIDE.md](DEDICATED_SERVER_GUIDE.md)** - Server reference guide

## 🛠️ Development

**Built with:**
- Godot Engine 4.5
- GDScript
- WebSocket multiplayer networking (browser compatible!)

**Requirements:**
- Godot 4.5 or later
- Port 7777 open for WebSocket connections

## 🌐 Deployment Options

### ☁️ Browser-Based (.io style) - **RECOMMENDED**
- **Game Server:** AWS EC2 (~$10-20/month)
- **Web Client:** AWS S3 + CloudFront (almost FREE)
- **Total:** ~$10-20/month for 50+ players
- **Players:** Just click URL and play!

See **`WEB_HOSTING_GUIDE.md`** for complete step-by-step instructions.

### 🖥️ Desktop Client (Alternative)
- Download .exe files
- Requires manual distribution
- See `AWS_DEPLOYMENT_GUIDE.md`

## 🔧 Configuration

### Server Address

Edit `server_config.txt`:
```
your-server-ip-here
```

### Command-Line Arguments

```bash
# Start as server
./multiplayer-fight --server

# Connect to custom server
./multiplayer-fight --address=54.123.45.67

# Short version
./multiplayer-fight -s
./multiplayer-fight -a=54.123.45.67
```

## 🐛 Troubleshooting

### Can't connect to server
1. Check `server_config.txt` has correct IP
2. Verify port 7777 is open
3. Ensure server is running

### Server crashes
```bash
# Check logs (Linux systemd)
sudo journalctl -u multiplayer-fight -f

# Or check server.log if running with nohup
tail -f server.log
```

## 📝 License

This project is for educational and personal use.

## 🎉 Credits

Created as a multiplayer .io-style game with Godot Engine.

---

**Ready to deploy?** Check out the deployment guides in this repository!

