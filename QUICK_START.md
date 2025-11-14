# ⚡ Quick Start - Deploy Your .io Game in 30 Minutes

This guide will get your browser-based multiplayer game live on AWS as fast as possible.

---

## 📋 What You Need

- AWS Account ([Free tier eligible](https://aws.amazon.com/free))
- Your Godot project (already set up!)
- 30 minutes

---

## 🚀 Step 1: Export Your Game (5 minutes)

### Server Build (Linux)

1. Open Godot
2. **Project** → **Export** → **Add...** → **Linux/X11**
3. Check: ✅ Runnable, ✅ Embed PCK
4. Export as: `multiplayer-fight-server`

### Web Build (HTML5)

1. **Project** → **Export** → **Add...** → **Web**
2. **HTML/Custom HTML Shell:** Browse to `index.html` in your project
3. Open `Scenes/world.tscn` → Select `GameLauncher`
4. Set **Server Address** = `localhost` (we'll change this later)
5. Export to folder: `web-build/`

---

## 🖥️ Step 2: Deploy Server to EC2 (10 minutes)

### Create EC2 Instance

1. Go to [AWS EC2](https://console.aws.amazon.com/ec2)
2. **Launch Instance**
3. Quick settings:
   - **Name:** `game-server`
   - **OS:** Ubuntu 22.04
   - **Type:** t2.small
   - **Key Pair:** Create new (download the .pem file!)
   - **Security Group:** 
     - Add rule: **Custom TCP, Port 7777, Source: 0.0.0.0/0**
4. **Launch**

**IMPORTANT:** Copy your **Public IPv4 Address** (e.g., `54.123.45.67`)

### Upload and Run Server

```bash
# Upload server
scp -i your-key.pem multiplayer-fight-server ubuntu@YOUR_IP:~/

# Connect to server
ssh -i your-key.pem ubuntu@YOUR_IP

# Inside server:
chmod +x multiplayer-fight-server
sudo apt update
sudo apt install -y libgl1-mesa-glx libx11-6

# Run server
./multiplayer-fight-server --server
```

**✅ Server is now running!** (Keep this terminal open)

---

## 🌐 Step 3: Host Web Client on S3 (10 minutes)

### Create S3 Bucket

1. Go to [AWS S3](https://s3.console.aws.amazon.com)
2. **Create Bucket**
3. **Bucket name:** `my-fight-game` (pick something unique)
4. **Region:** US East (N. Virginia)
5. **UNCHECK** "Block all public access"
6. **Create**

### Enable Web Hosting

1. Click your bucket → **Properties**
2. Scroll to **Static website hosting** → **Edit**
3. **Enable**
4. **Index document:** `index.html`
5. **Save**

### Make Bucket Public

1. **Permissions** tab → **Bucket policy** → **Edit**
2. Paste (replace `YOUR-BUCKET-NAME`):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
  }]
}
```

3. **Save**

### Upload Game Files

1. **Objects** tab → **Upload**
2. **Add files** → Select ALL from `web-build/` folder
3. **Upload**

**⚠️ Before testing:** You need to update the server address!

---

## 🔧 Step 4: Connect Web to Server (5 minutes)

### Update Server Address

1. Back in Godot
2. Open `Scenes/world.tscn` → Select `GameLauncher`
3. Change **Server Address** to your EC2 IP: `54.123.45.67`
4. **Project** → **Export** → Select **Web**
5. **Export** (overwrite files)
6. Go back to S3, **delete old files**, upload new ones

### Get Your Game URL

1. In S3 bucket → **Properties**
2. Scroll to **Static website hosting**
3. Copy the **Bucket website endpoint**

Example: `http://my-fight-game.s3-website-us-east-1.amazonaws.com`

---

## 🎮 Step 5: Play! (NOW!)

1. Open your S3 website URL in browser
2. Game loads and connects to server
3. **Share URL with friends!**

---

## 🎉 You're Live!

Congratulations! Your game is now live on AWS!

**Your Setup:**
- ✅ Server: EC2 (handles game logic)
- ✅ Client: S3 (serves HTML5 game)
- ✅ Cost: ~$10-15/month (or FREE first year!)

---

## 🚨 Common Issues

### "Can't connect to server"

**Fix:**
1. Check EC2 security group allows port 7777
2. Verify server is running: In EC2 SSH, run `ps aux | grep multiplayer-fight`
3. Check server address in GameLauncher matches EC2 Public IP

### "Game won't load"

**Fix:**
1. Check S3 bucket is public (bucket policy)
2. Check all files uploaded correctly
3. Open browser console (F12) for errors

### "Server keeps stopping"

**Fix:** Set up systemd service (see `WEB_HOSTING_GUIDE.md`)

---

## 🎯 Next Steps

### Make Server Permanent

Right now, if you close the SSH terminal, the server stops. To keep it running 24/7:

```bash
# In SSH session
nohup ./multiplayer-fight-server --server > server.log 2>&1 &

# Or set up systemd service (recommended)
# See WEB_HOSTING_GUIDE.md section "Create Systemd Service"
```

### Add HTTPS (CloudFront)

Your game works but uses HTTP. For better security and speed:

1. Create CloudFront distribution pointing to S3
2. Add response headers for SharedArrayBuffer
3. Get HTTPS URL: `https://xxxxx.cloudfront.net`

**See `WEB_HOSTING_GUIDE.md` for complete CloudFront setup**

### Get Custom Domain

Instead of ugly AWS URLs:

1. Buy domain on Route 53 (~$12/year)
2. Point to CloudFront
3. Your game: `https://playfight.com` 🎮

---

## 💡 Tips

- **Testing locally:** Set server_address to `localhost` and run server on your PC
- **Updating game:** Just re-export and re-upload to S3
- **Monitoring:** Check EC2 logs: `tail -f server.log`
- **Scaling:** When you get 50+ players, upgrade to t2.medium

---

## 📚 Learn More

- **Full Guide:** `WEB_HOSTING_GUIDE.md` - Complete documentation
- **Troubleshooting:** Check server logs and browser console (F12)
- **Costs:** Monitor AWS billing dashboard

---

**Need help?** Open an issue or check the full guides!

🎉 **Enjoy your live .io game!**

