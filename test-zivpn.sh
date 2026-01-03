#!/bin/bash
# ZIVPN - Complete Test Suite

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================="
echo "   ZIVPN Complete Test Suite"
echo "========================================="
echo ""

# Detect if client or server
IS_CLIENT=false
IS_SERVER=false

if [ -f ~/zivpn/zivpn.sh ] || [ -f ./zivpn.sh ]; then
    IS_CLIENT=true
fi

if systemctl list-units --type=service 2>/dev/null | grep -q "zivpn-server"; then
    IS_SERVER=true
fi

echo "🔹 Environment:"
if [ "$IS_CLIENT" = true ]; then
    echo "  ✅ Client detected"
fi
if [ "$IS_SERVER" = true ]; then
    echo "  ✅ Server detected"
fi
echo ""

# ========================================
# CLIENT TESTS
# ========================================
if [ "$IS_CLIENT" = true ]; then
    echo "========================================="
    echo "   CLIENT TESTS"
    echo "========================================="
    echo ""
    
    # Test 1: Check binaries
    echo "[1/6] Checking binaries..."
    if [ -f ~/zivpn/bin/hysteria-zivpn ]; then
        echo "  ✅ hysteria-zivpn found"
    else
        echo "  ❌ hysteria-zivpn NOT found"
    fi
    
    if [ -f ~/zivpn/bin/loadbalancer ]; then
        echo "  ✅ loadbalancer found"
    else
        echo "  ❌ loadbalancer NOT found"
    fi
    echo ""
    
    # Test 2: Check processes
    echo "[2/6] Checking processes..."
    HYSTERIA_COUNT=$(pgrep -f "hysteria-zivpn" | wc -l)
    LB_COUNT=$(pgrep -f "loadbalancer" | wc -l)
    echo "  Hysteria instances: $HYSTERIA_COUNT/8"
    echo "  Load Balancer: $LB_COUNT/1"
    
    if [ "$HYSTERIA_COUNT" -eq 8 ] && [ "$LB_COUNT" -eq 1 ]; then
        echo -e "  ${GREEN}✅ All processes running${NC}"
    else
        echo -e "  ${RED}❌ Some processes missing${NC}"
        echo "  Run: ~/zivpn/zivpn.sh start"
    fi
    echo ""
    
    # Test 3: Check ports
    echo "[3/6] Checking ports..."
    if ss -tlnp 2>/dev/null | grep -q ":7777"; then
        echo "  ✅ Load Balancer (7777) listening"
    else
        echo "  ❌ Load Balancer (7777) NOT listening"
    fi
    
    ACTIVE_TUNNELS=0
    for port in {1080..1087}; do
        if ss -tlnp 2>/dev/null | grep -q ":$port"; then
            ((ACTIVE_TUNNELS++))
        fi
    done
    echo "  Active tunnels (1080-1087): $ACTIVE_TUNNELS/8"
    echo ""
    
    # Test 4: Check config
    echo "[4/6] Checking config..."
    if [ -f ~/zivpn/zivpn.sh ]; then
        SERVER=$(grep "^SERVER=" ~/zivpn/zivpn.sh | cut -d'"' -f2)
        PASSWORD=$(grep "^PASSWORD=" ~/zivpn/zivpn.sh | cut -d'"' -f2)
        echo "  Server: $SERVER"
        echo "  Password: ${PASSWORD:0:3}***"
    fi
    echo ""
    
    # Test 5: Check Hysteria logs
    echo "[5/6] Checking Hysteria logs..."
    if [ -f /tmp/zivpn-core-0.log ]; then
        echo "  Last 3 log lines:"
        tail -3 /tmp/zivpn-core-0.log | sed 's/^/    /'
        
        if grep -qi "error\|fail" /tmp/zivpn-core-0.log 2>/dev/null; then
            echo -e "  ${YELLOW}⚠ Errors found in logs${NC}"
        fi
    else
        echo "  ⚠ No logs found (may not be started)"
    fi
    echo ""
    
    # Test 6: Test connection
    echo "[6/6] Testing SOCKS5 connection..."
    echo -n "  Testing Load Balancer (7777): "
    if timeout 5 curl -s --socks5 127.0.0.1:7777 https://ifconfig.me > /tmp/zivpn-test-ip.txt 2>&1; then
        IP=$(cat /tmp/zivpn-test-ip.txt)
        echo -e "${GREEN}✅ Working!${NC}"
        echo "  External IP: $IP"
        rm -f /tmp/zivpn-test-ip.txt
    else
        echo -e "${RED}❌ Failed${NC}"
        cat /tmp/zivpn-test-ip.txt 2>/dev/null | head -3 | sed 's/^/    /'
        rm -f /tmp/zivpn-test-ip.txt
    fi
    echo ""
    
    # Test individual tunnel
    echo -n "  Testing individual tunnel (1080): "
    if timeout 5 curl -s --socks5 127.0.0.1:1080 https://ifconfig.me > /tmp/zivpn-test-tunnel.txt 2>&1; then
        IP=$(cat /tmp/zivpn-test-tunnel.txt)
        echo -e "${GREEN}✅ Working!${NC}"
        echo "  External IP: $IP"
        rm -f /tmp/zivpn-test-tunnel.txt
    else
        echo -e "${RED}❌ Failed${NC}"
        cat /tmp/zivpn-test-tunnel.txt 2>/dev/null | head -3 | sed 's/^/    /'
        rm -f /tmp/zivpn-test-tunnel.txt
    fi
    echo ""
fi

# ========================================
# SERVER TESTS
# ========================================
if [ "$IS_SERVER" = true ]; then
    echo "========================================="
    echo "   SERVER TESTS"
    echo "========================================="
    echo ""
    
    # Test 1: Service status
    echo "[1/5] Checking service status..."
    if systemctl is-active --quiet zivpn-server; then
        echo -e "  ${GREEN}✅ Service running${NC}"
    else
        echo -e "  ${RED}❌ Service NOT running${NC}"
        echo "  Start: systemctl start zivpn-server"
    fi
    echo ""
    
    # Test 2: Port listening
    echo "[2/5] Checking port..."
    if ss -lnup 2>/dev/null | grep -q ":36712"; then
        echo "  ✅ Listening on 36712/UDP"
    else
        echo "  ❌ NOT listening on 36712/UDP"
    fi
    echo ""
    
    # Test 3: Check config
    echo "[3/5] Checking config..."
    if [ -f /etc/zivpn/config.json ]; then
        echo "  ✅ Config exists: /etc/zivpn/config.json"
        PORT=$(grep -o '"listen"[^}]*' /etc/zivpn/config.json | grep -o ':[0-9]*' | tr -d ':')
        echo "  Port: ${PORT:-36712}"
    else
        echo "  ❌ Config NOT found"
    fi
    echo ""
    
    # Test 4: Internet connectivity
    echo "[4/5] Checking internet connectivity..."
    if timeout 3 ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo "  ✅ Internet reachable"
    else
        echo "  ❌ Internet NOT reachable"
    fi
    
    if timeout 3 curl -s https://ifconfig.me > /dev/null 2>&1; then
        echo "  ✅ HTTPS working"
    else
        echo "  ❌ HTTPS failed"
    fi
    echo ""
    
    # Test 5: Recent logs
    echo "[5/5] Recent server activity..."
    if journalctl -u zivpn-server --no-pager -n 5 --since "1 minute ago" 2>/dev/null | grep -q .; then
        journalctl -u zivpn-server --no-pager -n 5 --since "1 minute ago" 2>/dev/null | tail -5 | sed 's/^/  /'
    else
        echo "  No recent activity (last 1 minute)"
    fi
    echo ""
    
    # Check for errors
    if journalctl -u zivpn-server --no-pager -n 50 2>/dev/null | grep -qi "error\|fail"; then
        echo -e "  ${YELLOW}⚠ Recent errors found:${NC}"
        journalctl -u zivpn-server --no-pager -n 50 2>/dev/null | grep -i "error\|fail" | tail -3 | sed 's/^/    /'
    fi
    echo ""
fi

echo "========================================="
echo "   Summary"
echo "========================================="

if [ "$IS_CLIENT" = true ]; then
    echo ""
    echo "📝 Client Commands:"
    echo "  Start:   ~/zivpn/zivpn.sh start"
    echo "  Stop:    ~/zivpn/zivpn.sh stop"
    echo "  Status:  ~/zivpn/zivpn.sh status"
    echo "  Restart: ~/zivpn/zivpn.sh restart"
    echo ""
    echo "  Test: curl --socks5 127.0.0.1:7777 https://ifconfig.me"
fi

if [ "$IS_SERVER" = true ]; then
    echo ""
    echo "📝 Server Commands:"
    echo "  Start:   systemctl start zivpn-server"
    echo "  Stop:    systemctl stop zivpn-server"
    echo "  Status:  systemctl status zivpn-server"
    echo "  Logs:    journalctl -u zivpn-server -f"
fi

echo ""
echo "========================================="
