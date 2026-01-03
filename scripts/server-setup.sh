#!/bin/bash
# ZIVPN Server Setup Script
# Install and configure ZIVPN Hysteria server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "======================================="
echo "ZIVPN Server Setup"
echo "======================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# 1. Install binary
echo "[1/5] Installing binary..."
cp "$BASE_DIR/server/hysteria-zivpn-amd64" /usr/local/bin/zivpn-server
chmod +x /usr/local/bin/zivpn-server
echo "✓ Binary installed to /usr/local/bin/zivpn-server"

# 2. Create directories
echo "[2/5] Creating directories..."
mkdir -p /etc/zivpn
echo "✓ Created /etc/zivpn"

# 3. Generate certificate
echo "[3/5] Generating TLS certificate..."
if [ ! -f /etc/zivpn/server.crt ]; then
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout /etc/zivpn/server.key \
        -out /etc/zivpn/server.crt \
        -subj "/CN=zivpn.local" \
        -days 36500 2>/dev/null
    chmod 600 /etc/zivpn/server.key
    echo "✓ Certificate generated"
else
    echo "✓ Certificate already exists"
fi

# 4. Copy config
echo "[4/5] Installing config..."
cp "$BASE_DIR/configs/server/server.json" /etc/zivpn/config.json
echo "✓ Config installed to /etc/zivpn/config.json"

# 5. Create systemd service
echo "[5/5] Creating systemd service..."
cat > /etc/systemd/system/zivpn-server.service <<'EOF'
[Unit]
Description=ZIVPN Hysteria Server v1.3.5
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

systemctl daemon-reload
systemctl enable zivpn-server
echo "✓ Systemd service created and enabled"

echo ""
echo "======================================="
echo "✓ Installation Complete!"
echo "======================================="
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Edit config file:"
echo "   nano /etc/zivpn/config.json"
echo ""
echo "   Change these values:"
echo "   - password: Set a strong password"
echo "   - obfs.salamander.password: Set obfuscation key"
echo ""
echo "2. Open firewall port 36712/UDP:"
echo "   ufw allow 36712/udp"
echo "   # or: firewall-cmd --permanent --add-port=36712/udp"
echo "   # then: firewall-cmd --reload"
echo ""
echo "3. Start server:"
echo "   systemctl start zivpn-server"
echo ""
echo "4. Check status:"
echo "   systemctl status zivpn-server"
echo "   journalctl -u zivpn-server -f"
echo ""
