#!/bin/bash
# ZIVPN Server - Full Reinstall (Uninstall + Install)
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server-reinstall.sh | sudo bash

set -e

GITHUB_RAW="https://raw.githubusercontent.com/zexry619/zivpn-client/main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================="
echo "   ZIVPN Server - Full Reinstall"
echo "======================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    echo "  Run: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server-reinstall.sh | sudo bash"
    exit 1
fi

# Check for auto-confirm when piped
AUTO_CONFIRM=false
if [ ! -t 0 ]; then
    AUTO_CONFIRM=true
fi

if [ "$AUTO_CONFIRM" = false ]; then
    echo -e "${BLUE}This will:${NC}"
    echo "  1. Uninstall existing ZIVPN server"
    echo "  2. Clean all configs and certificates"
    echo "  3. Install fresh ZIVPN server"
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
echo "   STEP 1: Uninstalling old server"
echo "======================================="
echo ""

# Stop service
if systemctl is-active --quiet zivpn-server 2>/dev/null; then
    echo "Stopping service..."
    systemctl stop zivpn-server
    echo -e "${GREEN}✓ Service stopped${NC}"
fi

# Disable service
if systemctl is-enabled --quiet zivpn-server 2>/dev/null; then
    systemctl disable zivpn-server > /dev/null 2>&1
    echo -e "${GREEN}✓ Service disabled${NC}"
fi

# Remove systemd service
if [ -f /etc/systemd/system/zivpn-server.service ]; then
    rm /etc/systemd/system/zivpn-server.service
    systemctl daemon-reload
    echo -e "${GREEN}✓ Service file removed${NC}"
fi

# Remove binary
if [ -f /usr/local/bin/zivpn-server ]; then
    rm /usr/local/bin/zivpn-server
    echo -e "${GREEN}✓ Binary removed${NC}"
fi

# Remove configs
if [ -d /etc/zivpn ]; then
    rm -rf /etc/zivpn
    echo -e "${GREEN}✓ Config directory removed${NC}"
fi

# Remove install dir
if [ -d /opt/zivpn ]; then
    rm -rf /opt/zivpn
    echo -e "${GREEN}✓ Install directory removed${NC}"
fi

echo ""
echo -e "${GREEN}✓ Uninstall complete${NC}"
echo ""
sleep 2

# Step 2: Install
echo "======================================="
echo "   STEP 2: Installing fresh server"
echo "======================================="
echo ""

# Download and run installer
echo "Downloading installer..."
curl -fsSL "$GITHUB_RAW/server-install.sh" -o /tmp/zivpn-install.sh
chmod +x /tmp/zivpn-install.sh

echo "Running installer..."
echo ""
bash /tmp/zivpn-install.sh

# Cleanup
rm -f /tmp/zivpn-install.sh

echo ""
echo "======================================="
echo "   ✓ Reinstall Complete!"
echo "======================================="
echo ""
