#!/bin/bash
# ZIVPN Client - Uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/client-uninstall.sh | bash

set -e

INSTALL_DIR="$HOME/zivpn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================="
echo "   ZIVPN Client - Uninstaller"
echo "======================================="
echo ""

# Check for auto-confirm when piped
AUTO_CONFIRM=false
if [ ! -t 0 ]; then
    AUTO_CONFIRM=true
fi

if [ "$AUTO_CONFIRM" = false ]; then
    echo -e "${YELLOW}⚠  This will remove:${NC}"
    echo "  - Installation: $INSTALL_DIR/"
    echo "  - PATH entries in shell RC files"
    echo ""
    read -p "Continue? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
else
    echo -e "${GREEN}Auto-confirm mode (piped input detected)${NC}"
    echo "Removing ZIVPN Client..."
fi
echo ""

# Step 1: Stop running instances
echo "[1/3] Stopping ZIVPN..."
if [ -f "$INSTALL_DIR/zivpn.sh" ]; then
    "$INSTALL_DIR/zivpn.sh" stop 2>/dev/null || {
        # Manual cleanup if script fails
        pkill -f "hysteria-zivpn" 2>/dev/null || true
        pkill -f "loadbalancer" 2>/dev/null || true
        echo -e "${GREEN}✓ Processes stopped${NC}"
    }
else
    echo -e "${YELLOW}⚠ zivpn.sh not found, attempting manual stop...${NC}"
    pkill -f "hysteria-zivpn" 2>/dev/null || true
    pkill -f "loadbalancer" 2>/dev/null || true
fi
echo ""

# Step 2: Remove installation directory
echo "[2/3] Removing files..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Removed: $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}⚠ Directory not found: $INSTALL_DIR${NC}"
fi
echo ""

# Step 3: Clean up shell RC files
echo "[3/3] Cleaning up shell configuration..."
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$RC" ]; then
        # Remove ZIVPN lines
        sed -i '/# ZIVPN Client/,+2d' "$RC" 2>/dev/null || true
        echo -e "${GREEN}✓ Cleaned: $RC${NC}"
    fi
done
echo ""

echo "======================================="
echo "   ✓ Uninstall Complete!"
echo "======================================="
echo ""
echo -e "${GREEN}ZIVPN Client has been removed.${NC}"
echo ""
echo -e "${YELLOW}⚠ Reload your shell:${NC}"
echo "  source ~/.bashrc  # or ~/.zshrc"
echo ""
