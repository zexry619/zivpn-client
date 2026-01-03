#!/bin/bash
# ZIVPN Quick Installer - Downloads binaries from GitHub Releases
# Usage: curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/quick-install.sh | bash

set -e

REPO="zexry619/zivpn-client"
VERSION="v1.0.0"  # Will be updated with actual release
INSTALL_DIR="/opt/zivpn"

echo "======================================="
echo "ZIVPN Client Quick Installer"
echo "======================================="
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        BINARY_SUFFIX="arm64"
        ;;
    x86_64|amd64)
        BINARY_SUFFIX="amd64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Architecture: $ARCH"
echo ""

# Check root
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/opt/zivpn"
    BIN_DIR="/usr/local/bin"
else
    INSTALL_DIR="$HOME/.zivpn"
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

echo "Installing to: $INSTALL_DIR"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR"/{client,scripts,docs}

# Download binaries from current repo (committed files)
echo "[1/4] Downloading ZIVPN binaries..."
GITHUB_RAW="https://github.com/$REPO/raw/main"

if command -v wget &> /dev/null; then
    DOWNLOAD="wget -qO"
elif command -v curl &> /dev/null; then
    DOWNLOAD="curl -fsSL -o"
else
    echo "❌ Error: wget or curl required"
    exit 1
fi

# Download client binary
echo "  Downloading hysteria-zivpn-$BINARY_SUFFIX..."
$DOWNLOAD "$INSTALL_DIR/client/hysteria-zivpn-$BINARY_SUFFIX" "$GITHUB_RAW/client/hysteria-zivpn-$BINARY_SUFFIX"

# Download loadbalancer
echo "  Downloading loadbalancer-$BINARY_SUFFIX..."
$DOWNLOAD "$INSTALL_DIR/client/loadbalancer-$BINARY_SUFFIX" "$GITHUB_RAW/client/loadbalancer-$BINARY_SUFFIX"

# Make executable
chmod +x "$INSTALL_DIR/client"/*

# Create symlinks
cd "$INSTALL_DIR/client"
ln -sf "hysteria-zivpn-$BINARY_SUFFIX" hysteria-zivpn
ln -sf "loadbalancer-$BINARY_SUFFIX" loadbalancer

# Download main script
echo "[2/4] Downloading zivpn.sh..."
$DOWNLOAD "$INSTALL_DIR/zivpn.sh" "https://raw.githubusercontent.com/$REPO/main/zivpn.sh"
chmod +x "$INSTALL_DIR/zivpn.sh"

# Download docs
echo "[3/4] Downloading documentation..."
$DOWNLOAD "$INSTALL_DIR/README.md" "https://raw.githubusercontent.com/$REPO/main/README.md" 2>/dev/null || true
$DOWNLOAD "$INSTALL_DIR/SIMPLE-GUIDE.md" "https://raw.githubusercontent.com/$REPO/main/SIMPLE-GUIDE.md" 2>/dev/null || true

# Install to PATH
echo "[4/4] Installing to PATH..."
ln -sf "$INSTALL_DIR/zivpn.sh" "$BIN_DIR/zivpn"

# Configure
echo ""
echo "Do you want to configure now? (y/n)"
read -r CONFIGURE

if [[ "$CONFIGURE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter VPS server (e.g., 123.45.67.89:36712):"
    read -r SERVER
    echo "Enter password:"
    read -r PASSWORD
    echo "Enter obfuscation key:"
    read -r OBFS_KEY
    
    sed -i "s|^SERVER=.*|SERVER=\"$SERVER\"|g" "$INSTALL_DIR/zivpn.sh"
    sed -i "s|^PASSWORD=.*|PASSWORD=\"$PASSWORD\"|g" "$INSTALL_DIR/zivpn.sh"
    sed -i "s|^OBFS_KEY=.*|OBFS_KEY=\"$OBFS_KEY\"|g" "$INSTALL_DIR/zivpn.sh"
    
    echo "✅ Configured!"
fi

echo ""
echo "======================================="
echo "✅ Installation Complete!"
echo "======================================="
echo ""
echo "Quick start:"
echo "  zivpn start    # Start ZIVPN"
echo "  zivpn status   # Check status"
echo "  zivpn test     # Test connection"
echo ""
echo "Documentation:"
echo "  cat $INSTALL_DIR/SIMPLE-GUIDE.md"
echo ""
