#!/bin/bash
# ZIVPN Client - One-Click Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/client-install.sh | bash

set -e

GITHUB_REPO="https://github.com/zexry619/zivpn-client/raw/main"
INSTALL_DIR="$HOME/zivpn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================="
echo "   ZIVPN Client - One-Click Installer"
echo "======================================="
echo ""

# Detect architecture and OS
ARCH=$(uname -m)
OS=$(uname -s)

case "$ARCH" in
    x86_64|amd64)
        ARCH_SUFFIX="amd64"
        ;;
    aarch64|arm64|armv8*)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo -e "${RED}✗ Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Detected: $OS $ARCH_SUFFIX${NC}"
echo ""

# Check for auto-confirm when piped
AUTO_CONFIRM=false
if [ ! -t 0 ]; then
    AUTO_CONFIRM=true
fi

# Step 1: Download binaries
echo "[1/4] Downloading binaries..."
mkdir -p "$INSTALL_DIR/bin"

echo "  - Downloading Hysteria client..."
wget --quiet --show-progress "$GITHUB_REPO/client/hysteria-zivpn-$ARCH_SUFFIX" -O "$INSTALL_DIR/bin/hysteria-zivpn" || {
    echo -e "${RED}✗ Failed to download Hysteria${NC}"
    exit 1
}

echo "  - Downloading Load Balancer..."
wget --quiet --show-progress "$GITHUB_REPO/client/loadbalancer-$ARCH_SUFFIX" -O "$INSTALL_DIR/bin/loadbalancer" || {
    echo -e "${RED}✗ Failed to download Load Balancer${NC}"
    exit 1
}

chmod +x "$INSTALL_DIR/bin/"*
echo -e "${GREEN}✓ Binaries downloaded${NC}"
echo ""

# Step 2: Download main script
echo "[2/4] Downloading zivpn.sh..."
wget --quiet "$GITHUB_REPO/zivpn.sh" -O "$INSTALL_DIR/zivpn.sh" || {
    echo -e "${RED}✗ Failed to download zivpn.sh${NC}"
    exit 1
}
chmod +x "$INSTALL_DIR/zivpn.sh"
echo -e "${GREEN}✓ Script installed${NC}"
echo ""

# Step 3: Interactive configuration
echo "[3/4] Configuration..."
echo ""

# Always ask for config (even when piped) - use /dev/tty to read from terminal
if [ -t 0 ]; then
    # Normal input (not piped)
    read -p "Enter server address (IP:PORT) [YOUR_SERVER:36712]: " SERVER_ADDR
    read -p "Enter password [your-password]: " PASSWORD
    read -p "Enter obfuscation key [hu\`\`hqb\`c]: " OBFS_KEY
else
    # Piped input - read from terminal directly
    echo "⚠ Piped input detected. Reading config from terminal..."
    read -p "Enter server address (IP:PORT) [YOUR_SERVER:36712]: " SERVER_ADDR < /dev/tty
    read -p "Enter password [your-password]: " PASSWORD < /dev/tty
    read -p "Enter obfuscation key [hu\`\`hqb\`c]: " OBFS_KEY < /dev/tty
fi

# Set defaults if empty
SERVER_ADDR=${SERVER_ADDR:-YOUR_SERVER:36712}
PASSWORD=${PASSWORD:-your-password}
OBFS_KEY=${OBFS_KEY:-"hu\`\`hqb\`c"}

# Update zivpn.sh with config
sed -i "s|^SERVER=.*|SERVER=\"$SERVER_ADDR\"|" "$INSTALL_DIR/zivpn.sh"
sed -i "s|^PASSWORD=.*|PASSWORD=\"$PASSWORD\"|" "$INSTALL_DIR/zivpn.sh"
sed -i "s|^OBFS_KEY=.*|OBFS_KEY=\"$OBFS_KEY\"|" "$INSTALL_DIR/zivpn.sh"

echo -e "${GREEN}✓ Configuration saved${NC}"
echo ""

# Step 4: Add to PATH (optional)
echo "[4/4] Setting up PATH..."

# Always add to PATH automatically
ADD_PATH="Y"

if [[ "$ADD_PATH" =~ ^[Yy]$ ]]; then
    # Detect shell
    SHELL_RC="$HOME/.bashrc"
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi

    # Add to PATH if not already there
    if ! grep -q "export PATH=\"\$HOME/zivpn/bin:\$PATH\"" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# ZIVPN Client" >> "$SHELL_RC"
        echo "export PATH=\"\$HOME/zivpn/bin:\$PATH\"" >> "$SHELL_RC"
        echo "alias zivpn='$INSTALL_DIR/zivpn.sh'" >> "$SHELL_RC"
        echo -e "${GREEN}✓ Added to PATH ($SHELL_RC)${NC}"
    else
        echo -e "${YELLOW}⚠ Already in PATH${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Skipped PATH setup${NC}"
fi
echo ""

echo "======================================="
echo "   ✓ Installation Complete!"
echo "======================================="
echo ""
echo -e "${GREEN}📋 Configuration:${NC}"
echo "  Server: $SERVER_ADDR"
echo "  Password: $PASSWORD"
echo "  Obfuscation: $OBFS_KEY"
echo ""
echo -e "${GREEN}📝 Usage:${NC}"
echo "  Start:   $INSTALL_DIR/zivpn.sh start"
echo "  Stop:    $INSTALL_DIR/zivpn.sh stop"
echo "  Status:  $INSTALL_DIR/zivpn.sh status"
echo "  Test:    $INSTALL_DIR/zivpn.sh test"
echo ""
echo -e "${GREEN}📁 Files:${NC}"
echo "  Location: $INSTALL_DIR/"
echo "  Config:   $INSTALL_DIR/zivpn.sh (edit lines 8-10)"
echo ""

if [[ "$ADD_PATH" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠ Reload shell or run:${NC}"
    echo "  source $SHELL_RC"
    echo ""
    echo -e "${GREEN}Then you can use:${NC}"
    echo "  zivpn start"
    echo ""
fi
