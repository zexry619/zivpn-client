#!/bin/bash
# ZIVPN All-in-One Binary
# Single file yang jalankan semua (8 Hysteria + Load Balancer)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Config (EDIT INI!)
SERVER="your-server.com:36712"
PASSWORD="your-password-here"
OBFS_KEY="your-obfs-key"

# Advanced config (biasanya tidak perlu diubah)
START_PORT=1080
NUM_INSTANCES=8
LB_PORT=7777

# ==========================================
# JANGAN EDIT DIBAWAH INI!
# ==========================================

usage() {
    cat <<EOF
ZIVPN All-in-One v1.0

Usage:
  $0 start    - Start ZIVPN (8 tunnels + load balancer)
  $0 stop     - Stop all ZIVPN processes
  $0 status   - Show status
  $0 test     - Test connection

Config (edit di line 8-10):
  SERVER   : $SERVER
  PASSWORD : ${PASSWORD:0:3}***
  OBFS_KEY : ${OBFS_KEY:0:3}***

EOF
    exit 1
}

check_config() {
    if [[ "$SERVER" == "your-server.com:36712" ]]; then
        echo "❌ Error: Config belum diubah!"
        echo ""
        echo "Edit file ini dan ubah:"
        echo "  SERVER=\"your-server.com:36712\"     ← IP/domain VPS"
        echo "  PASSWORD=\"your-password-here\"      ← Password server"
        echo "  OBFS_KEY=\"your-obfs-key\"           ← Obfuscation key"
        echo ""
        exit 1
    fi
}

start_zivpn() {
    check_config
    
    echo "======================================="
    echo "ZIVPN All-in-One Launcher"
    echo "======================================="
    echo "Server: $SERVER"
    echo "Instances: $NUM_INSTANCES"
    echo "Load Balancer: 127.0.0.1:$LB_PORT"
    echo "======================================="
    echo ""
    
    # Check if already running
    if pgrep -f "hysteria-zivpn" > /dev/null; then
        echo "⚠ ZIVPN sudah jalan! Stop dulu dengan: $0 stop"
        exit 1
    fi
    
    # Cari binary
    HYSTERIA_BIN=""
    LB_BIN=""
    
    # Priority 1: Check bin/ subdirectory (for installer)
    if [ -f "$SCRIPT_DIR/bin/hysteria-zivpn" ]; then
        HYSTERIA_BIN="$SCRIPT_DIR/bin/hysteria-zivpn"
        LB_BIN="$SCRIPT_DIR/bin/loadbalancer"
    # Priority 2: Check same directory
    elif [ -f "$SCRIPT_DIR/hysteria-zivpn" ]; then
        HYSTERIA_BIN="$SCRIPT_DIR/hysteria-zivpn"
        LB_BIN="$SCRIPT_DIR/loadbalancer"
    # Priority 3: Check arch-specific binaries
    elif [ -f "$SCRIPT_DIR/hysteria-zivpn-arm64" ]; then
        HYSTERIA_BIN="$SCRIPT_DIR/hysteria-zivpn-arm64"
        LB_BIN="$SCRIPT_DIR/loadbalancer-arm64"
    elif [ -f "$SCRIPT_DIR/hysteria-zivpn-amd64" ]; then
        HYSTERIA_BIN="$SCRIPT_DIR/hysteria-zivpn-amd64"
        LB_BIN="$SCRIPT_DIR/loadbalancer-amd64"
    # Priority 4: Check in PATH
    elif command -v hysteria-zivpn &> /dev/null; then
        HYSTERIA_BIN="hysteria-zivpn"
        LB_BIN="loadbalancer"
    else
        echo "❌ Error: Binary hysteria-zivpn tidak ditemukan!"
        echo "Pastikan file ini ada di folder yang sama dengan binary."
        echo ""
        echo "Lokasi yang dicek:"
        echo "  - $SCRIPT_DIR/bin/"
        echo "  - $SCRIPT_DIR/"
        echo "  - System PATH"
        exit 1
    fi
    
    # Create temp configs
    CONFIG_DIR="/tmp/zivpn-configs-$$"
    mkdir -p "$CONFIG_DIR"
    
    PID_FILE="/tmp/zivpn-pids-$$.txt"
    > "$PID_FILE"
    
    TUNNEL_LIST=""
    
    # Start Hysteria instances
    echo "Starting Hysteria instances..."
    for i in $(seq 0 $((NUM_INSTANCES - 1))); do
        PORT=$((START_PORT + i))
        CONFIG="$CONFIG_DIR/client-$PORT.json"
        
        # Generate config
        cat > "$CONFIG" <<EOFCONFIG
{
  "server": "$SERVER",
  "auth": "$PASSWORD",
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "$OBFS_KEY"
    }
  },
  "tls": {
    "insecure": true
  },
  "quic": {
    "initStreamReceiveWindow": 131072,
    "maxStreamReceiveWindow": 131072,
    "initConnReceiveWindow": 327680,
    "maxConnReceiveWindow": 327680,
    "maxIdleTimeout": "30s"
  },
  "socks5": {
    "listen": "127.0.0.1:$PORT"
  },
  "bandwidth": {
    "up": "50 mbps",
    "down": "100 mbps"
  }
}
EOFCONFIG
        
        echo "  [CORE-$i] Starting on port $PORT..."
        $HYSTERIA_BIN client -c "$CONFIG" > /tmp/zivpn-core-$i.log 2>&1 &
        PID=$!
        echo "$PID" >> "$PID_FILE"
        TUNNEL_LIST="$TUNNEL_LIST,127.0.0.1:$PORT"
        
        # BusyBox compatible sleep (OpenWrt)
        sleep 1
    done
    
    TUNNEL_LIST="${TUNNEL_LIST:1}"
    
    echo ""
    echo "Waiting for initialization..."
    sleep 3
    
    # Start Load Balancer
    echo "Starting Load Balancer on port $LB_PORT..."
    $LB_BIN -lport "$LB_PORT" -tunnel "$TUNNEL_LIST" > /tmp/zivpn-lb.log 2>&1 &
    LB_PID=$!
    echo "$LB_PID" >> "$PID_FILE"
    
    # Save PID file location
    echo "$PID_FILE" > /tmp/zivpn-pidfile-location.txt
    
    sleep 2
    
    # Verify
    RUNNING=0
    for i in $(seq 0 $((NUM_INSTANCES - 1))); do
        PORT=$((START_PORT + i))
        if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
            RUNNING=$((RUNNING + 1))
        fi
    done
    
    echo ""
    echo "======================================="
    if [ $RUNNING -eq $NUM_INSTANCES ]; then
        echo "✅ ZIVPN Started Successfully!"
        echo "======================================="
        echo ""
        echo "Status:"
        echo "  Hysteria: $RUNNING/$NUM_INSTANCES running"
        echo "  Load Balancer: ACTIVE (port $LB_PORT)"
        echo ""
        echo "Test:"
        echo "  $0 test"
        echo ""
        echo "Stop:"
        echo "  $0 stop"
    else
        echo "⚠ Started with warnings!"
        echo "======================================="
        echo "Running: $RUNNING/$NUM_INSTANCES instances"
        echo "Check logs: ls -lh /tmp/zivpn-*.log"
    fi
    echo ""
}

stop_zivpn() {
    echo "Stopping ZIVPN..."
    
    # Try to read PID file
    if [ -f /tmp/zivpn-pidfile-location.txt ]; then
        PID_FILE=$(cat /tmp/zivpn-pidfile-location.txt)
        if [ -f "$PID_FILE" ]; then
            while IFS= read -r pid; do
                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" 2>/dev/null
                    echo "  ✓ Killed process $pid"
                fi
            done < "$PID_FILE"
            rm -f "$PID_FILE"
        fi
        rm -f /tmp/zivpn-pidfile-location.txt
    fi
    
    # Fallback: kill by name
    pkill -f hysteria-zivpn 2>/dev/null && echo "  ✓ Killed hysteria instances"
    pkill -f loadbalancer 2>/dev/null && echo "  ✓ Killed load balancer"
    
    # Clean up
    rm -rf /tmp/zivpn-configs-* 2>/dev/null
    
    echo "✅ ZIVPN stopped"
}

status_zivpn() {
    echo "======================================="
    echo "ZIVPN Status"
    echo "======================================="
    echo ""
    
    # Check Hysteria instances
    HYSTERIA_COUNT=$(pgrep -f "hysteria-zivpn" | wc -l)
    echo "Hysteria Instances: $HYSTERIA_COUNT/8"
    
    if [ $HYSTERIA_COUNT -gt 0 ]; then
        echo ""
        echo "Running ports:"
        for i in $(seq 0 7); do
            PORT=$((1080 + i))
            if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
                echo "  ✅ Port $PORT: ACTIVE"
            else
                echo "  ❌ Port $PORT: DOWN"
            fi
        done
    fi
    
    # Check Load Balancer
    if pgrep -f "loadbalancer" > /dev/null; then
        echo ""
        echo "Load Balancer: ✅ RUNNING (port 7777)"
    else
        echo ""
        echo "Load Balancer: ❌ STOPPED"
    fi
    
    echo ""
    echo "Logs:"
    ls -lh /tmp/zivpn-*.log 2>/dev/null || echo "  No logs found"
    echo ""
}

test_zivpn() {
    echo "Testing ZIVPN connection..."
    echo ""
    
    # Check if running
    if ! pgrep -f "loadbalancer" > /dev/null; then
        echo "❌ ZIVPN tidak jalan! Start dulu dengan: $0 start"
        exit 1
    fi
    
    # Test via load balancer
    echo "Testing via Load Balancer (port 7777)..."
    if command -v curl &> /dev/null; then
        IP=$(curl -s --socks5 127.0.0.1:7777 --max-time 10 https://ifconfig.me 2>/dev/null)
        if [ -n "$IP" ]; then
            echo "✅ Connection OK!"
            echo "   Your IP: $IP"
        else
            echo "❌ Connection FAILED!"
            echo "   Check logs: tail -f /tmp/zivpn-*.log"
        fi
    else
        echo "⚠ curl not installed, cannot test"
    fi
    echo ""
}

# Main
case "${1:-}" in
    start)
        start_zivpn
        ;;
    stop)
        stop_zivpn
        ;;
    status)
        status_zivpn
        ;;
    test)
        test_zivpn
        ;;
    restart)
        stop_zivpn
        sleep 2
        start_zivpn
        ;;
    *)
        usage
        ;;
esac
