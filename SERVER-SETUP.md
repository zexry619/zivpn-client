# Server Setup Guide

## Quick Setup (Copy-Paste!)

```bash
# 1. Download server binary
curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server/hysteria-zivpn-amd64 -o /usr/local/bin/zivpn-server
chmod +x /usr/local/bin/zivpn-server

# 2. Create config directory
mkdir -p /etc/zivpn

# 3. Generate certificate
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/zivpn/server.key \
  -out /etc/zivpn/server.crt \
  -subj "/CN=zivpn" -days 36500

# 4. Create config
cat > /etc/zivpn/config.json <<'EOF'
{
  "listen": ":36712",
  "auth": {
    "type": "password",
    "password": "CHANGE_THIS_PASSWORD"
  },
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "CHANGE_THIS_OBFS_KEY"
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
    "maxConnReceiveWindow": 327680,
    "maxIdleTimeout": "30s"
  },
  "bandwidth": {
    "up": "1 gbps",
    "down": "1 gbps"
  },
  "speedTest": true
}
EOF

# 5. Edit config (IMPORTANT!)
nano /etc/zivpn/config.json
# Change password and obfs key!

# 6. Open firewall
ufw allow 36712/udp
# or: firewall-cmd --permanent --add-port=36712/udp && firewall-cmd --reload

# 7. Create systemd service
cat > /etc/systemd/system/zivpn-server.service <<'EOF'
[Unit]
Description=ZIVPN Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/zivpn-server server -c /etc/zivpn/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# 8. Start service
systemctl daemon-reload
systemctl enable zivpn-server
systemctl start zivpn-server

# 9. Check status
systemctl status zivpn-server
journalctl -u zivpn-server -f
```

## Performance Tuning

```bash
# Enable BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

# Increase UDP buffer
echo "net.core.rmem_max=2500000" >> /etc/sysctl.conf
echo "net.core.wmem_max=2500000" >> /etc/sysctl.conf

sysctl -p
```

## Verify

```bash
# Check if server is listening
netstat -tuln | grep 36712
# or: ss -tuln | grep 36712

# Test from client
nc -zuv YOUR_VPS_IP 36712
```
