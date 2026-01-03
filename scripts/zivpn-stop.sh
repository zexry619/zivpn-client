#!/bin/bash
# ZIVPN Stop Script
# Stops all Hysteria instances and Load Balancer

echo "Stopping ZIVPN..."

PID_FILE="/tmp/zivpn-pids.txt"

if [ -f "$PID_FILE" ]; then
    while IFS= read -r pid; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            echo "  Killed process $pid"
        fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
fi

# Fallback: kill by name
pkill -f hysteria-zivpn 2>/dev/null
pkill -f loadbalancer 2>/dev/null

# Clean up temp configs
rm -rf /tmp/zivpn-configs

echo "✓ ZIVPN stopped"
