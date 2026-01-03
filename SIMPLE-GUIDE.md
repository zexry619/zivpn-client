# 🚀 ZIVPN - Panduan Super Simple

## 📦 Isi Folder

```
zivpn-core-exact/
├── zivpn.sh               ← SCRIPT UTAMA (1 file ini saja!)
├── client/
│   ├── hysteria-zivpn     ← Tunnel VPN
│   └── loadbalancer       ← Pembagi beban
└── server/
    ├── hysteria-zivpn-amd64
    └── loadbalancer-amd64
```

## 🎯 Cara Pakai SIMPLE (3 Langkah!)

### **LANGKAH 1: Setup Server (VPS)**

```bash
# 1. Login ke VPS
ssh root@your-vps.com

# 2. Install binary
cd /home/zekri/Downloads/zivpn-core-exact/server
chmod +x hysteria-zivpn-amd64
cp hysteria-zivpn-amd64 /usr/local/bin/zivpn-server

# 3. Buat config
mkdir -p /etc/zivpn
cat > /etc/zivpn/config.json <<'EOF'
{
  "listen": ":36712",
  "auth": {
    "type": "password",
    "password": "GantiPassword123"
  },
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "GantiObfsKey456"
    }
  },
  "tls": {
    "cert": "/etc/zivpn/server.crt",
    "key": "/etc/zivpn/server.key"
  },
  "quic": {
    "initStreamReceiveWindow": 131072,
    "maxStreamReceiveWindow": 131072,
    "initConnReceiveWindow": 327680,
    "maxConnReceiveWindow": 327680
  },
  "bandwidth": {
    "up": "1 gbps",
    "down": "1 gbps"
  }
}
EOF

# 4. Generate certificate
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/zivpn/server.key \
  -out /etc/zivpn/server.crt \
  -subj "/CN=zivpn" -days 36500

# 5. Buka firewall
ufw allow 36712/udp
# atau: firewall-cmd --permanent --add-port=36712/udp && firewall-cmd --reload

# 6. Start server
zivpn-server server -c /etc/zivpn/config.json
# (Tekan Ctrl+C untuk stop, atau jalankan di background dengan screen/tmux)
```

---

### **LANGKAH 2: Setup Client (OpenWrt)**

```bash
# 1. Upload folder ke OpenWrt
scp -r /home/zekri/Downloads/zivpn-core-exact root@192.168.1.1:/root/

# 2. Login ke OpenWrt
ssh root@192.168.1.1

# 3. Edit config di zivpn.sh
cd /root/zivpn-core-exact
nano zivpn.sh

# Ubah baris 8-10:
SERVER="123.45.67.89:36712"      # ← Ganti dengan IP VPS
PASSWORD="GantiPassword123"       # ← Same dengan server
OBFS_KEY="GantiObfsKey456"       # ← Same dengan server

# Simpan: Ctrl+X, Y, Enter
```

---

### **LANGKAH 3: Jalankan!**

```bash
cd /root/zivpn-core-exact
./zivpn.sh start
```

**Output:**
```
=======================================
ZIVPN All-in-One Launcher
=======================================
Server: 123.45.67.89:36712
Instances: 8
Load Balancer: 127.0.0.1:7777
=======================================

Starting Hysteria instances...
  [CORE-0] Starting on port 1080...
  [CORE-1] Starting on port 1081...
  ...
  [CORE-7] Starting on port 1087...

Waiting for initialization...
Starting Load Balancer on port 7777...

=======================================
✅ ZIVPN Started Successfully!
=======================================

Status:
  Hysteria: 8/8 running
  Load Balancer: ACTIVE (port 7777)
```

---

## 📝 Command Lengkap

```bash
./zivpn.sh start    # Start ZIVPN
./zivpn.sh stop     # Stop ZIVPN
./zivpn.sh status   # Cek status
./zivpn.sh test     # Test koneksi
./zivpn.sh restart  # Restart
```

---

## 🧪 Test Koneksi

```bash
# Otomatis test
./zivpn.sh test

# Manual test
curl --socks5 127.0.0.1:7777 https://ipinfo.io
```

**Harusnya return IP VPS!**

---

## 🔧 Integrasi dengan OpenClash

Edit `/etc/openclash/config.yaml`:

```yaml
proxies:
  - name: "ZIVPN"
    type: socks5
    server: 127.0.0.1
    port: 7777
    udp: true

proxy-groups:
  - name: "Proxy"
    type: select
    proxies:
      - "ZIVPN"

rules:
  - MATCH,Proxy
```

Restart OpenClash:
```bash
/etc/init.d/openclash restart
```

---

## ❓ FAQ

### Q: Kenapa ada 2 file binary (hysteria + loadbalancer)?

**A:** Karena Android ZIVPN pakai 2 cara:
- **hysteria-zivpn** = Tunnel VPN utama (8 instance)
- **loadbalancer** = Pembagi trafik otomatis ke 8 tunnel

Analoginya:
- **8 tunnel** = 8 jalur tol paralel
- **Load balancer** = Gerbang tol yang distribusi mobil ke 8 jalur

Hasil: **Speed 8x lebih cepat!**

### Q: Bisa pakai 1 file saja?

**A:** Script `zivpn.sh` sudah otomatis jalankan keduanya! Tinggal:
```bash
./zivpn.sh start
```
Selesai! 8 tunnel + load balancer langsung jalan.

### Q: Kenapa error "Binary not found"?

**A:** Pastikan file `zivpn.sh` ada di **folder yang sama** dengan folder `client/`:
```
zivpn-core-exact/
├── zivpn.sh        ← Script di sini
└── client/
    ├── hysteria-zivpn
    └── loadbalancer
```

### Q: Port 7777 sudah dipakai?

**A:** Edit `zivpn.sh` baris 15:
```bash
LB_PORT=8888  # Ganti ke port lain
```

---

## 🐛 Troubleshooting

### Problem: Gagal connect

```bash
# 1. Cek status
./zivpn.sh status

# 2. Cek logs
tail -f /tmp/zivpn-*.log

# 3. Test server dari client
nc -zuv YOUR_VPS_IP 36712
```

### Problem: Beberapa instance down

```bash
# Restart
./zivpn.sh restart
```

---

## 🎉 DONE!

Sekarang internet kamu lewat 8 tunnel parallel ke VPS!

**Test speed:**
```bash
curl --socks5 127.0.0.1:7777 -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000
```
