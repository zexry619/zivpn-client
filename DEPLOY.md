# 🚀 Quick Deploy Guide

## For End Users

### OpenWrt Router:
```bash
# One command install
curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/install.sh | bash

# Follow prompts to configure server, password, and obfs key
# Then start:
zivpn start
```

### Manual Method:
```bash
# Download
git clone https://github.com/zexry619/zivpn-client.git
cd zivpn-client

# Configure (edit 3 lines only!)
nano zivpn.sh
# Line 8: SERVER="your-vps.com:36712"
# Line 9: PASSWORD="your-password"
# Line 10: OBFS_KEY="your-obfs-key"

# Run
./zivpn.sh start
```

## Test Installation

```bash
# Check status
zivpn status

# Test connection
zivpn test

# View logs
tail -f /tmp/zivpn-*.log
```

## Integration with OpenClash

Edit `/etc/openclash/config.yaml`:
```yaml
proxies:
  - name: "ZIVPN"
    type: socks5
    server: 127.0.0.1
    port: 7777
    udp: true

proxy-groups:
  - name: "Proxy"
    type: select
    proxies:
      - "ZIVPN"

rules:
  - MATCH,Proxy
```

Restart: `/etc/init.d/openclash restart`

## Troubleshooting

### Connection Failed
```bash
# Check if server is reachable
nc -zuv YOUR_VPS_IP 36712

# Check logs
cat /tmp/zivpn-core-*.log
```

### Some Instances Not Starting
```bash
# Restart
zivpn restart

# Check ports
netstat -tuln | grep "108[0-7]"
```

## Uninstall

```bash
# Stop service
zivpn stop

# Remove files
sudo rm -rf /opt/zivpn
sudo rm /usr/local/bin/zivpn

# Or for user install:
rm -rf ~/.zivpn
rm ~/.local/bin/zivpn
```

## Support

- Issues: https://github.com/zexry619/zivpn-client/issues
- Docs: https://github.com/zexry619/zivpn-client/blob/main/SIMPLE-GUIDE.md
