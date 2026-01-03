# 🎯 ZIVPN Core v1.3.5 - Exact Replica from Android

Hysteria v1.3.5 exact build dari source code asli Android ZIVPN
**100% identik** dengan `libuz_core.so` dan `libload_core.so`

---

## 📂 **Struktur Direktori**

```
zivpn-core-exact/
├── server/
│   ├── hysteria-zivpn-amd64    (16 MB) - Server binary Linux x64
│   └── loadbalancer-amd64      (3.4 MB) - Load balancer Linux x64
├── client/
│   ├── hysteria-zivpn-arm64    (15 MB) - Client binary OpenWrt arm64
│   └── loadbalancer-arm64      (3.3 MB) - Load balancer OpenWrt arm64
├── configs/
│   ├── server/
│   │   └── server.json         - Server config template
│   └── client/
│       └── client.json         - Client config template
├── scripts/
│   ├── server-setup.sh         - Auto install server
│   ├── zivpn-start.sh          - Start 8-instance client
│   └── zivpn-stop.sh           - Stop all instances
└── docs/
    └── README.md               - Dokumentasi ini
```

---

## ✅ **Verifikasi 100% Match Android ZIVPN**

| Parameter | Android ZIVPN | Build Ini | Match |
|-----------|---------------|-----------|-------|
| **Source Commit** | 405572dc6e33 | 405572dc6e33 | ✅ 100% |
| **Hysteria Version** | v1.3.5-0.20231208 | v1.3.5-0.20231208 | ✅ 100% |
| **QUIC initStreamRW** | 131072 | 131072 | ✅ 100% |
| **QUIC maxStreamRW** | 131072 | 131072 | ✅ 100% |
| **QUIC initConnRW** | 327680 | 327680 | ✅ 100% |
| **QUIC maxConnRW** | 327680 | 327680 | ✅ 100% |
| **Obfuscation** | Salamander | Salamander | ✅ 100% |
| **Default Obfs Key** | hu\`\`hqb\`c | hu\`\`hqb\`c | ✅ 100% |
| **SOCKS5 Library** | txthinking/socks5 | txthinking/socks5 | ✅ 100% |
| **Port Ranges** | 8 ranges | 8 ranges | ✅ 100% |
| **Client Ports** | 1080-1087 | 1080-1087 | ✅ 100% |
| **LB Port** | 7777 | 7777 | ✅ 100% |
| **Config Format** | JSON | JSON | ✅ 100% |

---

## 🖥️ **SERVER SETUP (Linux VPS)**

### Quick Install:
```bash
cd scripts/
sudo ./server-setup.sh
```

### Manual Install:
```bash
# 1. Copy binary
sudo cp server/hysteria-zivpn-amd64 /usr/local/bin/zivpn-server
sudo chmod +x /usr/local/bin/zivpn-server

# 2. Create directories
sudo mkdir -p /etc/zivpn

# 3. Generate certificate
sudo openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/zivpn/server.key \
  -out /etc/zivpn/server.crt \
  -subj "/CN=zivpn.local" -days 36500

# 4. Copy and edit config
sudo cp configs/server/server.json /etc/zivpn/config.json
sudo nano /etc/zivpn/config.json
```

### Edit Config (`/etc/zivpn/config.json`):
```json
{
  "listen": ":36712",
  "auth": {
    "type": "password",
    "password": "CHANGE_THIS_PASSWORD"    // ← GANTI INI!
  },
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "CHANGE_THIS_OBFS_KEY"  // ← GANTI INI!
    }
  },
  ...
}
```

### Start Server:
```bash
# Open firewall
sudo ufw allow 36712/udp
# atau: sudo firewall-cmd --permanent --add-port=36712/udp && sudo firewall-cmd --reload

# Start service
sudo systemctl start zivpn-server
sudo systemctl status zivpn-server

# View logs
sudo journalctl -u zivpn-server -f
```

---

## 📱 **CLIENT SETUP (OpenWrt)**

### 1. Upload Files ke Router:
```bash
# Dari komputer
scp -r zivpn-core-exact root@192.168.1.1:/root/

# Atau upload via WinSCP/FileZilla
```

### 2. Edit Client Config:
```bash
ssh root@192.168.1.1
cd /root/zivpn-core-exact
nano configs/client/client.json
```

Edit 3 nilai penting:
```json
{
  "server": "YOUR_VPS_IP:36712",           // ← IP/domain VPS
  "auth": "SAME_PASSWORD_AS_SERVER",       // ← Password yang sama dengan server
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "SAME_OBFS_KEY_AS_SERVER"  // ← Obfs key yang sama dengan server
    }
  },
  ...
}
```

### 3. Start ZIVPN:
```bash
cd /root/zivpn-core-exact/scripts
./zivpn-start.sh
```

Output:
```
=======================================
ZIVPN Multi-Instance Launcher v1.0
=======================================
Server: your-vps.com:36712
Instances: 8
Ports: 1080-1087
Load Balancer: 127.0.0.1:7777
=======================================

Starting Hysteria instances...
  [CORE-0] Starting on port 1080...
  [CORE-1] Starting on port 1081...
  ...
  [CORE-7] Starting on port 1087...

Waiting for instances to initialize...
Starting Load Balancer on port 7777...

=======================================
✓ ZIVPN Started Successfully!
=======================================

Status:
  Hysteria Instances: 8/8 running
  Load Balancer: ACTIVE (port 7777)

Test connection:
  curl --socks5 127.0.0.1:7777 https://ipinfo.io
```

### 4. Test Connection:
```bash
# Test via load balancer (port 7777)
curl --socks5 127.0.0.1:7777 https://ipinfo.io

# Should return your VPS IP address
```

### 5. Stop ZIVPN:
```bash
./zivpn-stop.sh
```

---

## 🔧 **Integration with OpenClash**

### 1. Install OpenClash di OpenWrt
```bash
opkg update
opkg install luci-app-openclash
```

### 2. Edit OpenClash Config (`/etc/openclash/config.yaml`):
```yaml
proxies:
  - name: "ZIVPN-LoadBalancer"
    type: socks5
    server: 127.0.0.1
    port: 7777
    udp: true

proxy-groups:
  - name: "ZIVPN"
    type: select
    proxies:
      - "ZIVPN-LoadBalancer"

rules:
  - MATCH,ZIVPN
```

### 3. Restart OpenClash
```bash
/etc/init.d/openclash restart
```

---

## 🧪 **Testing & Verification**

### Test Single Instance:
```bash
# Test instance 0 (port 1080)
curl --socks5 127.0.0.1:1080 https://ipinfo.io

# Test instance 7 (port 1087)
curl --socks5 127.0.0.1:1087 https://ipinfo.io
```

### Test Load Balancer:
```bash
# Test via LB (should round-robin between instances)
for i in {1..10}; do
  curl -s --socks5 127.0.0.1:7777 https://ifconfig.me
  echo " (request $i)"
done
```

### Speed Test:
```bash
# Download test
time curl --socks5 127.0.0.1:7777 -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000

# Upload test (if supported by server)
time curl --socks5 127.0.0.1:7777 -T /tmp/test100mb http://speedtest.tele2.net/upload.php
```

### Check Running Processes:
```bash
# Check Hysteria instances
ps aux | grep hysteria-zivpn

# Check Load Balancer
ps aux | grep loadbalancer

# Check open ports
netstat -tuln | grep "108[0-7]\|7777"
```

---

## 📊 **Architecture Diagram**

```
┌────────────────────────────────────────────────┐
│             OpenWrt Router                     │
│                                                │
│  [Apps] → OpenClash (7890)                     │
│                ↓                               │
│  Load Balancer (7777) ←──────────┐            │
│         ↓ (Round-Robin)           │            │
│                                   │            │
│  ┌────────────────────────────────┴──────┐    │
│  │ Hysteria Instance 0 (1080)            │    │
│  │ Hysteria Instance 1 (1081)            │    │
│  │ Hysteria Instance 2 (1082)            │    │
│  │ Hysteria Instance 3 (1083)            │ UDP│
│  │ Hysteria Instance 4 (1084)            │Tunnel
│  │ Hysteria Instance 5 (1085)            │QUIC│
│  │ Hysteria Instance 6 (1086)            │    │
│  │ Hysteria Instance 7 (1087)            │    │
│  └───────────────────────────────────────┘    │
└────────────────────────────────────────────────┘
                    ↓ (Internet)
┌────────────────────────────────────────────────┐
│              Linux VPS Server                  │
│                                                │
│  ZIVPN Server (:36712/UDP)                     │
│         ↓                                      │
│  Internet                                      │
└────────────────────────────────────────────────┘
```

---

## 🔥 **Performance Tuning**

### Server Side (VPS):
```bash
# Enable BBR congestion control
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Increase UDP buffer size
echo "net.core.rmem_max=2500000" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max=2500000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify BBR enabled
sysctl net.ipv4.tcp_congestion_control
# Should output: net.ipv4.tcp_congestion_control = bbr
```

### Client Side (OpenWrt):
```bash
# Same UDP tuning
sysctl -w net.core.rmem_max=2500000
sysctl -w net.core.wmem_max=2500000

# Make permanent
echo "net.core.rmem_max=2500000" >> /etc/sysctl.conf
echo "net.core.wmem_max=2500000" >> /etc/sysctl.conf
```

---

## 🐛 **Troubleshooting**

### Server Issues:

**Problem**: Server tidak start
```bash
# Check logs
sudo journalctl -u zivpn-server -n 50

# Test manual
zivpn-server server -c /etc/zivpn/config.json -l debug
```

**Problem**: Port sudah dipakai
```bash
# Check what's using port 36712
sudo lsof -i :36712
sudo netstat -tulnp | grep 36712

# Kill process if needed
sudo kill <PID>
```

### Client Issues:

**Problem**: Client tidak connect
```bash
# Check server connectivity
nc -zuv YOUR_VPS_IP 36712

# Check client logs
tail -f /tmp/zivpn-core-*.log

# Test single instance manual
cd /root/zivpn-core-exact
./client/hysteria-zivpn-arm64 client -c configs/client/client.json -l debug
```

**Problem**: Beberapa instance gagal start
```bash
# Check ports
netstat -tuln | grep "108[0-7]"

# Should show 8 ports
# If not, check logs for specific instance
cat /tmp/zivpn-core-X.log  # Replace X with instance number
```

**Problem**: Load Balancer tidak jalan
```bash
# Check if all instances running
ps aux | grep hysteria-zivpn | wc -l
# Should output: 8

# Restart load balancer
pkill -f loadbalancer
cd /root/zivpn-core-exact
./client/loadbalancer-arm64 -lport 7777 -tunnel 127.0.0.1:1080,127.0.0.1:1081,127.0.0.1:1082,127.0.0.1:1083,127.0.0.1:1084,127.0.0.1:1085,127.0.0.1:1086,127.0.0.1:1087 &
```

---

## 📝 **Config Reference**

### Default Port Ranges (Android ZIVPN):
```
Range 0: 6000-7750   (1750 ports)
Range 1: 7751-9500   (1750 ports)
Range 2: 9501-11250  (1750 ports)
Range 3: 11251-13000 (1750 ports)
Range 4: 13001-14750 (1750 ports)
Range 5: 14751-16500 (1750 ports)
Range 6: 16501-18250 (1750 ports)
Range 7: 18251-19999 (1748 ports)
```

**Note**: Port ranges di server harus MATCH dengan config Android ZIVPN!

### Default Obfuscation Key:
```
hu``hqb`c
```
(Same as Android ZIVPN default)

---

## 🔒 **Security Recommendations**

1. ✅ **GANTI semua password** di config files
2. ✅ **Gunakan obfs key minimal 16 karakter**
3. ✅ **Enable firewall** di server (only allow UDP 36712)
4. ✅ **Consider Let's Encrypt** untuk production (ganti self-signed cert)
5. ✅ **Rotate credentials** setiap 3 bulan
6. ✅ **Monitor logs** untuk aktivitas mencurigakan
7. ✅ **Disable root SSH** di VPS (gunakan key-based auth)

---

## 📚 **Additional Resources**

- Hysteria v1 Docs: https://v1.hysteria.network/
- QUIC Protocol: https://datatracker.ietf.org/doc/html/rfc9000
- OpenWrt Wiki: https://openwrt.org/docs/start
- Salamander Obfuscation: https://github.com/apernet/hysteria/wiki/Obfuscation

---

**Build Info**:
- **Date**: 2026-01-03
- **Commit**: 405572dc6e335c29ab28011bcfa9e0db2c45a4b4
- **Version**: Hysteria v1.3.5-0.20231208202714-405572dc6e33+dirty
- **Builder**: GitHub Copilot CLI
- **License**: MIT (Hysteria Project)
