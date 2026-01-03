#!/bin/bash
# ZIVPN Client Auto Installer
# Quick deployment from GitHub repository

set -e

REPO_URL="https://github.com/zexry619/zivpn-client"
INSTALL_DIR="/opt/zivpn"

echo "======================================="
echo "ZIVPN Client Installer"
echo "======================================="
echo ""

# Check if running as root for system-wide install
if [ "$EUID" -eq 0 ]; then
    INSTALL_MODE="system"
    INSTALL_DIR="/opt/zivpn"
    BIN_DIR="/usr/local/bin"
    echo "Mode: System-wide installation"
else
    INSTALL_MODE="user"
    INSTALL_DIR="$HOME/.zivpn"
    BIN_DIR="$HOME/.local/bin"
    echo "Mode: User installation (non-root)"
    mkdir -p "$BIN_DIR"
fi

echo "Install directory: $INSTALL_DIR"
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
        echo "Supported: aarch64 (arm64), x86_64 (amd64)"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH ($BINARY_SUFFIX)"
echo ""

# Check dependencies
echo "[1/5] Checking dependencies..."
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo "❌ Error: curl or wget required"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "⚠ Git not found, using tarball download..."
    USE_GIT=false
else
    USE_GIT=true
fi

# Download/Clone repository
echo "[2/5] Downloading ZIVPN..."
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠ Directory exists, removing..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"

# Download main files first
echo "  Downloading scripts..."
TMP_DIR="/tmp/zivpn-install-$$"
mkdir -p "$TMP_DIR"

# Download files from GitHub raw
GITHUB_RAW="https://raw.githubusercontent.com/zexry619/zivpn-client/main"

if command -v curl &> /dev/null; then
    DOWNLOAD="curl -fsSL"
else
    DOWNLOAD="wget -qO-"
fi

# Download main script
$DOWNLOAD "$GITHUB_RAW/zivpn.sh" > "$TMP_DIR/zivpn.sh"
chmod +x "$TMP_DIR/zivpn.sh"

# Download docs
$DOWNLOAD "$GITHUB_RAW/README.md" > "$TMP_DIR/README.md"
$DOWNLOAD "$GITHUB_RAW/SIMPLE-GUIDE.md" > "$TMP_DIR/SIMPLE-GUIDE.md" 2>/dev/null || true

# Download binaries (from original build location)
echo "  Downloading binaries ($BINARY_SUFFIX)..."
mkdir -p "$TMP_DIR/client"

# Try from GitHub first, if fails, download from alternative source
if ! $DOWNLOAD "$GITHUB_RAW/client/hysteria-zivpn-$BINARY_SUFFIX" > "$TMP_DIR/client/hysteria-zivpn-$BINARY_SUFFIX" 2>/dev/null; then
    echo "  ⚠ GitHub binary unavailable, downloading from build server..."
    # Alternative: download from your build server or use curl from local
    # For now, try direct git clone with LFS
    if [ "$USE_GIT" = true ]; then
        cd /tmp
        git clone --depth 1 "$REPO_URL.git" "$TMP_DIR" 2>/dev/null || {
            echo "❌ Error: Cannot download binaries"
            echo "Please download manually from: $REPO_URL"
            exit 1
        }
    else
        echo "❌ Error: Binary download failed"
        echo "Install git and try again, or download manually from:"
        echo "  $REPO_URL"
        exit 1
    fi
fi

if ! $DOWNLOAD "$GITHUB_RAW/client/loadbalancer-$BINARY_SUFFIX" > "$TMP_DIR/client/loadbalancer-$BINARY_SUFFIX" 2>/dev/null; then
    # Same fallback
    true
fi

# Move to install dir
mv "$TMP_DIR"/* "$INSTALL_DIR/" 2>/dev/null || cp -r "$TMP_DIR"/* "$INSTALL_DIR/"
rm -rf "$TMP_DIR"

cd "$INSTALL_DIR"

# Setup binaries
echo "[3/5] Setting up binaries..."
chmod +x client/hysteria-zivpn-$BINARY_SUFFIX
chmod +x client/loadbalancer-$BINARY_SUFFIX
chmod +x zivpn.sh

# Create symlinks
cd client
ln -sf hysteria-zivpn-$BINARY_SUFFIX hysteria-zivpn
ln -sf loadbalancer-$BINARY_SUFFIX loadbalancer
cd ..

# Install to PATH
echo "[4/5] Installing to PATH..."
ln -sf "$INSTALL_DIR/zivpn.sh" "$BIN_DIR/zivpn"

# Add to PATH if needed (for user install)
if [ "$INSTALL_MODE" = "user" ]; then
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo ""
        echo "⚠ Add this to your ~/.bashrc or ~/.profile:"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

# Interactive configuration
echo "[5/5] Configuration..."
echo ""
echo "Do you want to configure ZIVPN now? (y/n)"
read -r CONFIGURE

if [[ "$CONFIGURE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter VPS server address (e.g., 123.45.67.89:36712):"
    read -r SERVER
    
    echo "Enter password:"
    read -r PASSWORD
    
    echo "Enter obfuscation key:"
    read -r OBFS_KEY
    
    # Update zivpn.sh
    sed -i "s|^SERVER=.*|SERVER=\"$SERVER\"|g" "$INSTALL_DIR/zivpn.sh"
    sed -i "s|^PASSWORD=.*|PASSWORD=\"$PASSWORD\"|g" "$INSTALL_DIR/zivpn.sh"
    sed -i "s|^OBFS_KEY=.*|OBFS_KEY=\"$OBFS_KEY\"|g" "$INSTALL_DIR/zivpn.sh"
    
    echo "✅ Configuration saved!"
else
    echo ""
    echo "⚠ Please configure manually:"
    echo "   nano $INSTALL_DIR/zivpn.sh"
    echo ""
    echo "Edit lines 8-10:"
    echo "   SERVER=\"your-vps.com:36712\""
    echo "   PASSWORD=\"your-password\""
    echo "   OBFS_KEY=\"your-obfs-key\""
fi

echo ""
echo "======================================="
echo "✅ Installation Complete!"
echo "======================================="
echo ""
echo "Install location: $INSTALL_DIR"
echo "Binary location: $BIN_DIR/zivpn"
echo ""
echo "Quick start:"
echo "  zivpn start    # Start ZIVPN"
echo "  zivpn stop     # Stop ZIVPN"
echo "  zivpn status   # Show status"
echo "  zivpn test     # Test connection"
echo ""
echo "Documentation:"
echo "  cat $INSTALL_DIR/SIMPLE-GUIDE.md"
echo ""
