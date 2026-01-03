# ZIVPN Client - Cara Pakai

## ✅ ZIVPN Sudah Jalan!

Kalau kamu sudah run `zivpn.sh start` dan muncul "ZIVPN Started Successfully", berarti tunnel sudah aktif di:
- **Port: 7777**
- **Protocol: SOCKS5**
- **Host: 127.0.0.1**

Sekarang tinggal setting aplikasi untuk pakai proxy ini.

---

## 🌐 Cara Pakai

### 1. **Browser (Firefox/Chrome) - Manual**

#### Firefox:
1. Settings → Network Settings → Manual proxy configuration
2. SOCKS Host: `127.0.0.1`
3. Port: `7777`
4. SOCKS v5: ✓
5. Proxy DNS when using SOCKS v5: ✓

#### Chrome/Brave:
```bash
# Linux/Mac - jalankan browser dengan proxy
google-chrome --proxy-server="socks5://127.0.0.1:7777"
brave-browser --proxy-server="socks5://127.0.0.1:7777"
```

---

### 2. **System-Wide (Recommended) - Menggunakan Proxy Manager**

#### **A. FoxyProxy (Firefox Extension)**
1. Install FoxyProxy: https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/
2. Add proxy:
   - Title: `ZIVPN`
   - Type: `SOCKS5`
   - Hostname: `127.0.0.1`
   - Port: `7777`
3. Click icon → Enable "ZIVPN"

#### **B. SwitchyOmega (Chrome Extension)**
1. Install: https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif
2. New Profile → Protocol: `socks5`
3. Server: `127.0.0.1`, Port: `7777`
4. Apply changes

---

### 3. **Command Line Tools**

#### **curl**
```bash
curl --socks5 127.0.0.1:7777 https://ifconfig.me
```

#### **wget**
```bash
export http_proxy="socks5://127.0.0.1:7777"
export https_proxy="socks5://127.0.0.1:7777"
wget -qO- https://ifconfig.me
```

#### **git**
```bash
git config --global http.proxy socks5://127.0.0.1:7777
git config --global https.proxy socks5://127.0.0.1:7777
```

---

### 4. **System-Wide (Linux) - proxychains**

Install proxychains:
```bash
# Fedora
sudo dnf install proxychains-ng

# Ubuntu/Debian
sudo apt install proxychains4
```

Configure:
```bash
sudo nano /etc/proxychains.conf
```

Edit bagian akhir:
```conf
[ProxyList]
socks5  127.0.0.1 7777
```

Use:
```bash
proxychains firefox
proxychains curl https://ifconfig.me
proxychains youtube-dl https://...
```

---

### 5. **Aplikasi Android (Termux/OpenWrt)**

#### **Termux** (Requires Root):
```bash
# Install netcat-openbsd
pkg install netcat-openbsd

# Redirect all traffic
su -c "iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-ports 7777"
```

#### **OpenWrt Router** (System-Wide):
Di router OpenWrt, install OpenClash atau Passwall, lalu:
```yaml
# OpenClash config
proxies:
  - name: "ZIVPN"
    type: socks5
    server: 127.0.0.1
    port: 7777
    udp: true
```

---

## 🧪 Test Koneksi

```bash
# Test via zivpn.sh
~/zivpn/zivpn.sh test

# Manual test dengan curl
curl --socks5 127.0.0.1:7777 https://ifconfig.me
# Harusnya muncul IP server VPS kamu

# Test DNS leak
curl --socks5 127.0.0.1:7777 https://1.1.1.1/cdn-cgi/trace
```

---

## 📊 Status & Management

```bash
# Start
~/zivpn/zivpn.sh start

# Stop
~/zivpn/zivpn.sh stop

# Status
~/zivpn/zivpn.sh status

# Restart
~/zivpn/zivpn.sh restart

# Test
~/zivpn/zivpn.sh test
```

---

## 🔧 Auto-Start (Optional)

### **Systemd Service (Linux)**
```bash
cat > ~/.config/systemd/user/zivpn.service <<EOF
[Unit]
Description=ZIVPN Client
After=network-online.target

[Service]
Type=forking
ExecStart=$HOME/zivpn/zivpn.sh start
ExecStop=$HOME/zivpn/zivpn.sh stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Enable & start
systemctl --user daemon-reload
systemctl --user enable zivpn.service
systemctl --user start zivpn.service
```

### **Cron (Boot)**
```bash
crontab -e
# Tambah:
@reboot sleep 10 && $HOME/zivpn/zivpn.sh start
```

---

## ❓ Troubleshooting

### Port 7777 sudah dipakai?
```bash
# Check port
ss -tlnp | grep 7777
# atau
lsof -i :7777

# Ganti port di zivpn.sh (line 11)
nano ~/zivpn/zivpn.sh
# LB_PORT=8888  # Ubah ke port lain
```

### Koneksi lambat?
```bash
# Check status
~/zivpn/zivpn.sh status

# Restart
~/zivpn/zivpn.sh restart
```

### Test individual tunnel:
```bash
# Test salah satu tunnel (port 1080-1087)
curl --socks5 127.0.0.1:1080 https://ifconfig.me
```

---

## 🚀 Tips Performa

1. **Multi-Thread Download**: ZIVPN load balance otomatis ke 8 tunnel
2. **Low Latency**: Hysteria QUIC protocol, optimal untuk gaming
3. **UDP Support**: SOCKS5 di port 7777 support UDP untuk gaming/VoIP

---

## 📖 Documentation

- GitHub: https://github.com/zexry619/zivpn-client
- Issues: https://github.com/zexry619/zivpn-client/issues

---

**Happy Tunneling! 🚀**
