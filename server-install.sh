#!/bin/bash
# ZIVPN Server - One-Click Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server-install.sh | bash

set -e

GITHUB_REPO="https://github.com/zexry619/zivpn-client/raw/main"
INSTALL_DIR="/opt/zivpn"
BIN_PATH="/usr/local/bin/zivpn-server"
CONFIG_DIR="/etc/zivpn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================="
echo "   ZIVPN Server - One-Click Installer"
echo "======================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    echo "  Run: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server-install.sh | sudo bash"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        ARCH_SUFFIX="amd64"
        ;;
    aarch64|arm64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo -e "${RED}✗ Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Detected architecture: $ARCH_SUFFIX${NC}"
echo ""

# Step 1: Download binary
echo "[1/6] Downloading Hysteria binary..."
mkdir -p "$INSTALL_DIR"
wget --quiet --show-progress "$GITHUB_REPO/server/hysteria-zivpn-$ARCH_SUFFIX" -O "$BIN_PATH" || {
    echo -e "${RED}✗ Failed to download binary${NC}"
    exit 1
}
chmod +x "$BIN_PATH"
echo -e "${GREEN}✓ Binary installed: $BIN_PATH${NC}"
echo ""

# Step 2: Create directories
echo "[2/6] Creating directories..."
mkdir -p "$CONFIG_DIR"
echo -e "${GREEN}✓ Created: $CONFIG_DIR${NC}"
echo ""

# Step 3: Generate certificate
echo "[3/6] Generating TLS certificate..."
if [ ! -f "$CONFIG_DIR/server.crt" ]; then
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$CONFIG_DIR/server.key" \
        -out "$CONFIG_DIR/server.crt" \
        -subj "/CN=zivpn.local" \
        -days 36500 2>/dev/null
    chmod 600 "$CONFIG_DIR/server.key"
    echo -e "${GREEN}✓ Certificate generated${NC}"
else
    echo -e "${YELLOW}⚠ Certificate already exists, skipping...${NC}"
fi
echo ""

# Step 4: Interactive configuration
echo "[4/6] Server configuration..."
read -p "Enter server password [zivpn2025]: " SERVER_PASSWORD
SERVER_PASSWORD=${SERVER_PASSWORD:-zivpn2025}

read -p "Enter obfuscation key [hu\`\`hqb\`c]: " OBFS_KEY
OBFS_KEY=${OBFS_KEY:-"hu\`\`hqb\`c"}

read -p "Enter server port [36712]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-36712}

echo ""
echo -e "${GREEN}✓ Configuration:${NC}"
echo "  - Password: $SERVER_PASSWORD"
echo "  - Obfuscation: $OBFS_KEY"
echo "  - Port: $SERVER_PORT/UDP"
echo ""

# Step 5: Create config file
echo "[5/6] Creating configuration file..."
cat > "$CONFIG_DIR/config.json" <<EOF
{
  "listen": ":$SERVER_PORT",
  "tls": {
    "cert": "$CONFIG_DIR/server.crt",
    "key": "$CONFIG_DIR/server.key"
  },
  "auth": {
    "type": "password",
    "password": "$SERVER_PASSWORD"
  },
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "$OBFS_KEY"
    }
  },
  "quic": {
    "initStreamReceiveWindow": 131072,
    "maxStreamReceiveWindow": 131072,
    "initConnReceiveWindow": 327680,
    "maxConnReceiveWindow": 327680,
    "maxIdleTimeout": "30s",
    "keepAlivePeriod": "10s",
    "disablePathMTUDiscovery": false
  },
  "bandwidth": {
    "up": "1 gbps",
    "down": "1 gbps"
  },
  "ignoreClientBandwidth": false,
  "speedTest": true,
  "disableUDP": false
}
EOF
chmod 600 "$CONFIG_DIR/config.json"
echo -e "${GREEN}✓ Config saved: $CONFIG_DIR/config.json${NC}"
echo ""

# Step 6: Create systemd service
echo "[6/6] Creating systemd service..."
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
echo -e "${GREEN}✓ Systemd service created and enabled${NC}"
echo ""

# Configure firewall (detect UFW or firewalld)
echo "Configuring firewall..."
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow "$SERVER_PORT/udp" > /dev/null 2>&1
    echo -e "${GREEN}✓ UFW: Allowed port $SERVER_PORT/UDP${NC}"
elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-port="$SERVER_PORT/udp" > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
    echo -e "${GREEN}✓ Firewalld: Allowed port $SERVER_PORT/UDP${NC}"
else
    echo -e "${YELLOW}⚠ No firewall detected. Manually open port $SERVER_PORT/UDP${NC}"
fi
echo ""

# Start service
echo "Starting ZIVPN server..."
systemctl start zivpn-server
sleep 2

if systemctl is-active --quiet zivpn-server; then
    echo -e "${GREEN}✓ ZIVPN server is running!${NC}"
else
    echo -e "${RED}✗ Failed to start server. Check logs:${NC}"
    echo "  journalctl -u zivpn-server -n 50"
    exit 1
fi

echo ""
echo "======================================="
echo "   ✓ Installation Complete!"
echo "======================================="
echo ""
echo -e "${GREEN}📋 Server Details:${NC}"

# Get public IP (prefer IPv4)
PUBLIC_IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

echo "  Address: $PUBLIC_IP:$SERVER_PORT"
echo "  Password: $SERVER_PASSWORD"
echo "  Obfuscation: $OBFS_KEY"
echo ""
echo -e "${GREEN}📝 Management Commands:${NC}"
echo "  Start:   systemctl start zivpn-server"
echo "  Stop:    systemctl stop zivpn-server"
echo "  Restart: systemctl restart zivpn-server"
echo "  Status:  systemctl status zivpn-server"
echo "  Logs:    journalctl -u zivpn-server -f"
echo ""
echo -e "${GREEN}📁 Files:${NC}"
echo "  Binary: $BIN_PATH"
echo "  Config: $CONFIG_DIR/config.json"
echo "  Cert:   $CONFIG_DIR/server.crt"
echo "  Key:    $CONFIG_DIR/server.key"
echo ""
echo -e "${YELLOW}⚠ Save these credentials for your clients!${NC}"
echo ""
