#!/bin/bash
# ZIVPN Server - Uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server-uninstall.sh | sudo bash

set -e

BIN_PATH="/usr/local/bin/zivpn-server"
CONFIG_DIR="/etc/zivpn"
INSTALL_DIR="/opt/zivpn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================="
echo "   ZIVPN Server - Uninstaller"
echo "======================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    echo "  Run: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/server-uninstall.sh | sudo bash"
    exit 1
fi

# Confirm uninstall
echo -e "${YELLOW}⚠  This will remove:${NC}"
echo "  - Binary: $BIN_PATH"
echo "  - Config: $CONFIG_DIR/"
echo "  - Service: /etc/systemd/system/zivpn-server.service"
echo ""
read -p "Continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi
echo ""

# Stop and disable service
echo "[1/5] Stopping service..."
if systemctl is-active --quiet zivpn-server 2>/dev/null; then
    systemctl stop zivpn-server
    echo -e "${GREEN}✓ Service stopped${NC}"
else
    echo -e "${YELLOW}⚠ Service not running${NC}"
fi

if systemctl is-enabled --quiet zivpn-server 2>/dev/null; then
    systemctl disable zivpn-server
    echo -e "${GREEN}✓ Service disabled${NC}"
else
    echo -e "${YELLOW}⚠ Service not enabled${NC}"
fi
echo ""

# Remove systemd service
echo "[2/5] Removing systemd service..."
if [ -f /etc/systemd/system/zivpn-server.service ]; then
    rm /etc/systemd/system/zivpn-server.service
    systemctl daemon-reload
    echo -e "${GREEN}✓ Service file removed${NC}"
else
    echo -e "${YELLOW}⚠ Service file not found${NC}"
fi
echo ""

# Remove binary
echo "[3/5] Removing binary..."
if [ -f "$BIN_PATH" ]; then
    rm "$BIN_PATH"
    echo -e "${GREEN}✓ Binary removed: $BIN_PATH${NC}"
else
    echo -e "${YELLOW}⚠ Binary not found${NC}"
fi
echo ""

# Remove config directory
echo "[4/5] Removing config directory..."
if [ -d "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
    echo -e "${GREEN}✓ Config removed: $CONFIG_DIR${NC}"
else
    echo -e "${YELLOW}⚠ Config directory not found${NC}"
fi
echo ""

# Remove install directory (optional)
echo "[5/5] Removing install directory..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Install directory removed: $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}⚠ Install directory not found${NC}"
fi
echo ""

# Close firewall port (optional)
echo "Firewall cleanup (optional)..."
read -p "Close firewall port 36712/UDP? [y/N]: " CLOSE_FW
if [[ "$CLOSE_FW" =~ ^[Yy]$ ]]; then
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        ufw delete allow 36712/udp > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ UFW: Port 36712/UDP closed${NC}"
    elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --remove-port=36712/udp > /dev/null 2>&1 || true
        firewall-cmd --reload > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ Firewalld: Port 36712/UDP closed${NC}"
    else
        echo -e "${YELLOW}⚠ No firewall detected${NC}"
    fi
fi
echo ""

echo "======================================="
echo "   ✓ Uninstall Complete!"
echo "======================================="
echo ""
echo -e "${GREEN}ZIVPN Server has been completely removed.${NC}"
echo ""
