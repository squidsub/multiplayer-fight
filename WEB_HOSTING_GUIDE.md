# 🌐 Browser-Based Multiplayer Hosting Guide

Your game is now configured for **browser-based multiplayer**! Players just click a URL and play - no downloads needed.

---

## 🏗️ Architecture Overview

Your .io game has **two parts**:

1. **🖥️ Game Server** (Linux on AWS EC2) - Handles game logic and player connections
2. **🌐 Web Client** (HTML5 on AWS S3/CloudFront) - What players see in their browser

```
Player Browser → S3/CloudFront (HTML5 Game) → WebSocket → EC2 Server
```

---

## 🚀 Part 1: Deploy Game Server (EC2)

### Step 1: Export Server Build

**In Godot:**
1. **Project** → **Export** → **Add...** → **Linux/X11**
2. Settings:
   - ✅ Runnable
   - ✅ Embed PCK
   - Architecture: x86_64
3. **Export Project** → Save as `multiplayer-fight-server`

### Step 2: Launch AWS EC2 Instance

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2)
2. Click **Launch Instance**
3. Settings:
   - **Name:** `multiplayer-fight-server`
   - **OS:** Ubuntu Server 22.04 LTS
   - **Instance Type:** t2.small (or t2.micro for testing)
   - **Key Pair:** Create/select one
   - **Security Group:**
     - ✅ SSH (22) - Your IP
     - ✅ **Custom TCP (7777)** - 0.0.0.0/0 ⚠️ **IMPORTANT for WebSocket!**
4. **Launch**

**Save your EC2 Public IP:** e.g., `54.123.45.67`

### Step 3: Deploy Server

**Upload server:**
```bash
scp -i your-key.pem multiplayer-fight-server ubuntu@YOUR_EC2_IP:~/
```

**SSH into server:**
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

**Install dependencies and run:**
```bash
# Make executable
chmod +x multiplayer-fight-server

# Install Godot dependencies
sudo apt update
sudo apt install -y libgl1-mesa-glx libx11-6 libxcursor1 libxi6 libxrandr2

# Test run (foreground)
./multiplayer-fight-server --server

# Press Ctrl+C to stop

# Run as background service (production)
nohup ./multiplayer-fight-server --server > server.log 2>&1 &

# Check if running
ps aux | grep multiplayer-fight

# View logs
tail -f server.log
```

### Step 4: Create Systemd Service (Recommended)

```bash
sudo nano /etc/systemd/system/multiplayer-fight.service
```

**Paste:**
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

**Enable and start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable multiplayer-fight
sudo systemctl start multiplayer-fight
sudo systemctl status multiplayer-fight
```

---

## 🌐 Part 2: Host Web Client (S3 + CloudFront)

### Step 1: Export HTML5 Build

**In Godot:**
1. **Editor** → **Manage Export Templates** → Download Web templates
2. **Project** → **Export** → **Add...** → **Web**
3. **IMPORTANT Settings:**
   - ✅ **Export Type:** Regular
   - **HTML/Custom HTML Shell:** Browse to `index.html` (the one we created)
   - ✅ **Head Include:** Leave empty
4. Before exporting, open `Scenes/world.tscn`
5. Select **GameLauncher** node
6. Set **Server Address** = `YOUR_EC2_PUBLIC_IP` (e.g., `54.123.45.67`)
7. Click **Export Project** → Choose a folder (e.g., `web-build/`)
8. Export ALL files

**You'll get these files:**
- `index.html`
- `multiplayer-fight.js`
- `multiplayer-fight.wasm`
- `multiplayer-fight.pck`
- `multiplayer-fight.audio.worklet.js` (if exists)

### Step 2: Create S3 Bucket

1. Go to [AWS S3 Console](https://s3.console.aws.amazon.com)
2. Click **Create Bucket**
3. **Bucket Name:** `multiplayer-fight-game` (must be globally unique)
4. **Region:** US East (N. Virginia) - us-east-1
5. **Uncheck** ❌ "Block all public access"
6. ✅ Acknowledge warning
7. **Create Bucket**

### Step 3: Configure Bucket for Web Hosting

1. Click your bucket → **Properties** tab
2. Scroll down to **Static website hosting**
3. Click **Edit** → **Enable**
4. **Index document:** `index.html`
5. **Save changes**

### Step 4: Set Bucket Policy (Make Public)

1. Go to **Permissions** tab
2. Scroll to **Bucket policy** → **Edit**
3. Paste this (replace `YOUR-BUCKET-NAME`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

4. **Save changes**

### Step 5: Configure CORS (Required for SharedArrayBuffer)

1. **Permissions** tab → **Cross-origin resource sharing (CORS)** → **Edit**
2. Paste this:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": [
      "Cross-Origin-Opener-Policy",
      "Cross-Origin-Embedder-Policy"
    ]
  }
]
```

3. **Save changes**

### Step 6: Upload Files

**Option A: Via AWS Console**
1. Go to **Objects** tab
2. Click **Upload**
3. **Add files** → Select ALL files from your `web-build/` folder
4. Click **Upload**

**Option B: Via AWS CLI** (faster for updates)
```bash
# Install AWS CLI first: https://aws.amazon.com/cli/
aws configure  # Enter your AWS credentials

# Upload files
cd web-build
aws s3 sync . s3://YOUR-BUCKET-NAME/ --delete

# Set correct content types
aws s3 cp . s3://YOUR-BUCKET-NAME/ --recursive \
  --exclude "*" --include "*.wasm" \
  --content-type "application/wasm" \
  --metadata-directive REPLACE
```

### Step 7: Set Correct Headers (CRITICAL!)

**For SharedArrayBuffer support, you need special headers. Two options:**

#### **Option A: Use CloudFront (Recommended)**

1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront)
2. Click **Create Distribution**
3. **Origin Domain:** Select your S3 bucket
4. **Origin Path:** Leave empty
5. **Viewer Protocol Policy:** Redirect HTTP to HTTPS
6. Scroll to **Response Headers Policy** → **Create New Policy**
7. **Name:** `multiplayer-fight-headers`
8. **Custom Headers:**
   - `Cross-Origin-Opener-Policy`: `same-origin`
   - `Cross-Origin-Embedder-Policy`: `require-corp`
9. **Create Distribution**
10. Wait 5-15 minutes for deployment

**Your game URL:** `https://XXXXX.cloudfront.net`

#### **Option B: Use Lambda@Edge (Advanced)**

If you need dynamic headers, use Lambda@Edge functions attached to CloudFront.

### Step 8: Test Your Game!

1. Open your CloudFront URL or S3 website endpoint
2. Game should load in browser
3. It will auto-connect to your EC2 server
4. Share the URL with friends!

---

## 🎮 Alternative Hosting: AWS Amplify

**Easier setup, but slightly more expensive:**

### Using AWS Amplify

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify)
2. Click **New App** → **Host web app** → **Deploy without Git**
3. **App Name:** `multiplayer-fight`
4. Drag & drop your `web-build/` folder
5. Click **Save and Deploy**
6. **Configure Custom Headers:**
   - Go to **App Settings** → **Custom Headers**
   - Add:
   ```
   customHeaders:
     - pattern: '**/*'
       headers:
         - key: 'Cross-Origin-Embedder-Policy'
           value: 'require-corp'
         - key: 'Cross-Origin-Opener-Policy'
           value: 'same-origin'
   ```

**Your game URL:** `https://main.XXXXX.amplifyapp.com`

---

## 🔧 Configuration

### Update Server Address After Deployment

**Option 1: Rebuild with new IP**
- Change `server_address` in GameLauncher
- Re-export HTML5
- Re-upload to S3

**Option 2: Use URL Parameters** (Dynamic)
Players can override server:
```
https://yourgame.com/?server=54.123.45.67
```

---

## 💰 Cost Estimates

### AWS Services:

**EC2 (Game Server):**
- t2.micro: FREE (first year), then ~$8/month
- t2.small: ~$17/month (better for 20+ players)

**S3 (File Hosting):**
- Storage: ~$0.023/GB (~$0.10/month for your game)
- Data Transfer: First 100GB/month FREE

**CloudFront (CDN):**
- Data Transfer: First 1TB/month FREE
- Requests: ~$0.01 per 10,000 requests

**Total for small game:** ~$10-20/month

---

## 🐛 Troubleshooting

### "Connection Failed" in Browser

**Check:**
1. EC2 Security Group allows port 7777
2. Server is running: `sudo systemctl status multiplayer-fight`
3. WebSocket URL is correct: `ws://YOUR_IP:7777`
4. Browser console for errors (F12)

### "SharedArrayBuffer is not defined"

**Fix:**
- Make sure CORS headers are set in S3
- Use CloudFront with response headers policy
- Test with: `https://` (not `http://`)

### Game Loads but Doesn't Connect

**Check:**
1. Server address in GameLauncher is correct
2. Server is actually running: `netstat -an | grep 7777`
3. Firewall allows WebSocket connections
4. Browser console shows WebSocket connection attempts

### Slow Loading

**Solutions:**
- Use CloudFront for faster delivery
- Enable gzip compression
- Optimize game assets (reduce texture sizes)

---

## 🚀 Production Checklist

Before launching to public:

- ✅ CloudFront distribution created (for HTTPS + speed)
- ✅ EC2 systemd service configured (auto-restart)
- ✅ Security group only allows necessary ports
- ✅ Custom domain configured (optional)
- ✅ AWS budget alerts set up
- ✅ Server monitoring configured
- ✅ Backup strategy for server

---

## 📊 Monitoring

### Server Health

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_IP

# Check service status
sudo systemctl status multiplayer-fight

# View live logs
sudo journalctl -u multiplayer-fight -f

# Check active connections
netstat -an | grep 7777 | grep ESTABLISHED | wc -l

# CPU/Memory usage
htop
```

### S3 Metrics

- Go to S3 → Your bucket → **Metrics** tab
- Monitor: Requests, Data Transfer, Error Rate

### CloudFront Metrics

- Go to CloudFront → Your distribution → **Monitoring**
- Monitor: Requests, Data Transfer, Cache Hit Rate

---

## 🌍 Custom Domain (Optional)

### Using Route 53

1. Buy domain in Route 53 (~$12/year)
2. Create hosted zone
3. Add CNAME record:
   - Name: `play` (or `game`)
   - Type: CNAME
   - Value: Your CloudFront distribution URL
4. Your game: `https://play.yourdomain.com`

### SSL Certificate (Free with AWS)

1. Go to AWS Certificate Manager
2. Request certificate for `yourdomain.com` and `*.yourdomain.com`
3. Verify via email or DNS
4. Attach certificate to CloudFront distribution

---

## 🎉 You're Live!

Your .io game is now live on the web! Share the URL and let people play! 🚀

**Next Steps:**
- Add analytics (Google Analytics, AWS CloudWatch)
- Set up auto-scaling for EC2 (when you get popular!)
- Add leaderboards
- Implement game analytics

---

**Need help?** Check server logs and browser console (F12) for errors.

