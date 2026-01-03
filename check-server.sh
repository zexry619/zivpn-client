#!/bin/bash
# ZIVPN Server - Connectivity & Configuration Check

echo "========================================="
echo "ZIVPN Server - Connectivity Check"
echo "========================================="
echo ""

# 1. Check server internet
echo "🔹 Server Internet Connectivity:"
echo -n "  Google DNS (8.8.8.8): "
if timeout 3 ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Reachable"
else
    echo "❌ Failed"
fi

echo -n "  Cloudflare (1.1.1.1): "
if timeout 3 ping -c 1 1.1.1.1 > /dev/null 2>&1; then
    echo "✅ Reachable"
else
    echo "❌ Failed"
fi

echo -n "  HTTPS to ifconfig.me: "
if timeout 5 curl -s https://ifconfig.me > /dev/null 2>&1; then
    echo "✅ Reachable"
else
    echo "❌ Failed"
fi

echo -n "  HTTPS to api.hy2.io: "
if timeout 5 curl -s -o /dev/null -w "%{http_code}" https://api.hy2.io 2>/dev/null | grep -q "200\|301\|302"; then
    echo "✅ Reachable"
else
    echo "❌ Failed"
fi
echo ""

# 2. Check IP forwarding
echo "🔹 Kernel IP Forwarding:"
IPV4_FORWARD=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
if [ "$IPV4_FORWARD" = "1" ]; then
    echo "  ✅ IPv4 forwarding: ENABLED"
else
    echo "  ❌ IPv4 forwarding: DISABLED"
    echo "     Fix: sysctl -w net.ipv4.ip_forward=1"
fi
echo ""

# 3. Check iptables
echo "🔹 Firewall Rules:"
if command -v iptables &>/dev/null; then
    FORWARD_POLICY=$(iptables -L FORWARD -n 2>/dev/null | head -1 | awk '{print $4}')
    echo "  FORWARD chain policy: $FORWARD_POLICY"
    
    if [ "$FORWARD_POLICY" = "DROP" ]; then
        echo "  ⚠️  FORWARD is DROP - will block proxy traffic!"
        echo "     Fix: iptables -P FORWARD ACCEPT"
    fi
    
    # Count FORWARD rules
    FORWARD_RULES=$(iptables -L FORWARD -n 2>/dev/null | tail -n +3 | wc -l)
    echo "  FORWARD rules: $FORWARD_RULES"
fi
echo ""

# 4. Check NAT
echo "🔹 NAT Configuration:"
if command -v iptables &>/dev/null; then
    if iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q MASQUERADE; then
        echo "  ✅ MASQUERADE enabled"
    else
        echo "  ⚠️  No MASQUERADE rule (may cause issues)"
        echo "     Hysteria server mode usually doesn't need NAT"
    fi
fi
echo ""

# 5. Check DNS
echo "🔹 DNS Resolution:"
if timeout 3 nslookup api.hy2.io > /dev/null 2>&1; then
    echo "  ✅ DNS working"
    DNS_IP=$(nslookup api.hy2.io 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
    echo "     api.hy2.io resolves to: $DNS_IP"
else
    echo "  ❌ DNS failed"
fi
echo ""

# 6. Check ZIVPN server status
echo "🔹 ZIVPN Server Status:"
if systemctl is-active --quiet zivpn-server 2>/dev/null; then
    echo "  ✅ Service running"
    
    # Check if listening
    if ss -lnup 2>/dev/null | grep -q ":36712"; then
        echo "  ✅ Listening on port 36712/UDP"
    else
        echo "  ❌ Not listening on port 36712/UDP"
    fi
else
    echo "  ❌ Service not running"
    echo "     Start: systemctl start zivpn-server"
fi
echo ""

# 7. Check recent errors
echo "🔹 Recent Server Errors (last 5):"
if journalctl -u zivpn-server --no-pager -n 50 2>/dev/null | grep -i "error\|fail" | tail -5 | grep -q .; then
    journalctl -u zivpn-server --no-pager -n 50 2>/dev/null | grep -i "error\|fail" | tail -5 | sed 's/^/  /'
else
    echo "  ✅ No recent errors"
fi
echo ""

echo "========================================="
echo "🔧 Quick Fixes:"
echo ""
echo "Enable IP forwarding:"
echo "  sysctl -w net.ipv4.ip_forward=1"
echo "  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf"
echo ""
echo "Allow forwarding (if needed):"
echo "  iptables -P FORWARD ACCEPT"
echo ""
echo "Restart server:"
echo "  systemctl restart zivpn-server"
echo ""
echo "View live logs:"
echo "  journalctl -u zivpn-server -f"
echo "========================================="
