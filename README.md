# ZIVPN Client

**Hysteria v1.3.5 - 100% Exact Replica dari Android ZIVPN**

Multi-tunnel VPN client dengan 8 instance parallel + load balancer untuk kecepatan maksimal.

## 🚀 Quick Install (1 Command!)

### OpenWrt / Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/zexry619/zivpn-client/main/install.sh | bash
```

### Manual Install:
```bash
# 1. Clone repository
git clone https://github.com/zexry619/zivpn-client.git
cd zivpn-client

# 2. Edit config
nano zivpn.sh
# Ubah baris 8-10:
#   SERVER="your-vps.com:36712"
#   PASSWORD="your-password"
#   OBFS_KEY="your-obfs-key"

# 3. Run
chmod +x zivpn.sh
./zivpn.sh start
```

## 📖 Documentation

- [SIMPLE-GUIDE.md](SIMPLE-GUIDE.md) - Quick start guide (Bahasa Indonesia)
- [SERVER-SETUP.md](SERVER-SETUP.md) - VPS server setup
- [docs/README.md](docs/README.md) - Full documentation

## 🎯 Features

- ✅ 8 parallel tunnels (ports 1080-1087)
- ✅ Automatic load balancing (port 7777)
- ✅ 100% compatible with Android ZIVPN
- ✅ QUIC protocol with optimized parameters
- ✅ Salamander obfuscation
- ✅ Zero configuration (edit 3 lines only!)

## 🔧 Commands

```bash
./zivpn.sh start    # Start ZIVPN
./zivpn.sh stop     # Stop ZIVPN
./zivpn.sh status   # Show status
./zivpn.sh test     # Test connection
./zivpn.sh restart  # Restart
```

## 📊 Architecture

```
[Apps/Browser]
      ↓
[OpenClash:7890]
      ↓
[Load Balancer:7777]
      ↓ (Round-Robin)
┌─────┴────────────┐
│ Hysteria #1:1080 │
│ Hysteria #2:1081 │
│ Hysteria #3:1082 │
│ Hysteria #4:1083 │
│ Hysteria #5:1084 │
│ Hysteria #6:1085 │
│ Hysteria #7:1086 │
│ Hysteria #8:1087 │
└──────────────────┘
      ↓ (Internet)
  [VPS Server:36712]
```

## ⚙️ System Requirements

- **OS**: OpenWrt, Linux (any distro)
- **Arch**: ARM64 (aarch64) or x86_64
- **RAM**: 64 MB minimum
- **Storage**: 50 MB free space

## 🔒 Security

- Salamander obfuscation enabled by default
- QUIC protocol with strong encryption
- No logs policy

## 📝 License

MIT License - Based on [Hysteria v1.3.5](https://github.com/apernet/hysteria)

## 🙏 Credits

- Original Android ZIVPN implementation
- [Hysteria Project](https://github.com/apernet/hysteria) by Aperture Internet Laboratory

---

**Build Date**: 2026-01-03  
**Version**: v1.3.5-exact  
**Commit**: 405572dc6e33
