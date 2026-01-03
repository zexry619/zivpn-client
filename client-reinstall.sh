#!/bin/bash
# ZIVPN Client - Full Reinstall (Uninstall + Install)
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/client-reinstall.sh | bash

set -e

GITHUB_RAW="https://raw.githubusercontent.com/zexry619/zivpn-client/main"
INSTALL_DIR="$HOME/zivpn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================="
echo "   ZIVPN Client - Full Reinstall"
echo "======================================="
echo ""

# Check for auto-confirm when piped
AUTO_CONFIRM=false
if [ ! -t 0 ]; then
    AUTO_CONFIRM=true
fi

if [ "$AUTO_CONFIRM" = false ]; then
    echo -e "${BLUE}This will:${NC}"
    echo "  1. Stop running ZIVPN instances"
    echo "  2. Remove all files and configs"
    echo "  3. Install fresh ZIVPN client"
    echo ""
    read -p "Continue? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
else
    echo -e "${GREEN}Auto-confirm mode (piped input detected)${NC}"
    echo "Starting full reinstall..."
fi
echo ""

# Step 1: Uninstall
echo "======================================="
echo "   STEP 1: Uninstalling old client"
echo "======================================="
echo ""

# Stop running instances
if [ -f "$INSTALL_DIR/zivpn.sh" ]; then
    echo "Stopping ZIVPN..."
    "$INSTALL_DIR/zivpn.sh" stop 2>/dev/null || {
        pkill -f "hysteria-zivpn" 2>/dev/null || true
        pkill -f "loadbalancer" 2>/dev/null || true
    }
    echo -e "${GREEN}✓ Stopped${NC}"
fi

# Remove files
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Files removed${NC}"
fi

# Clean shell RC files
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$RC" ]; then
        sed -i '/# ZIVPN Client/,+2d' "$RC" 2>/dev/null || true
    fi
done
echo -e "${GREEN}✓ Shell config cleaned${NC}"

echo ""
echo -e "${GREEN}✓ Uninstall complete${NC}"
echo ""
sleep 2

# Step 2: Install
echo "======================================="
echo "   STEP 2: Installing fresh client"
echo "======================================="
echo ""

# Download and run installer
echo "Downloading installer..."
curl -fsSL "$GITHUB_RAW/client-install.sh" -o /tmp/zivpn-client-install.sh
chmod +x /tmp/zivpn-client-install.sh

echo "Running installer..."
echo ""
bash /tmp/zivpn-client-install.sh

# Cleanup
rm -f /tmp/zivpn-client-install.sh

echo ""
echo "======================================="
echo "   ✓ Reinstall Complete!"
echo "======================================="
echo ""
