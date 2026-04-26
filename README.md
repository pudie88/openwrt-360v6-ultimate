---

# 🚀 360 V6 一键扩展脚本 [v11.3]

> 专为 **360 V6 / 小米 CR660x / IPQ6000** 设计。  
> **128M Flash + 512M RAM**，插上 U 盘 → WAN 上线 → 全自动部署 Docker/AdGuardHome/Samba。

---

## 📌 固件功能 vs 脚本扩展

| 类别 | 说明 |
|------|------|
| 🟦 **固件预编译** | ImmortalWrt 原生功能已内置：网络管理 / LuCI 界面 / SmartDNS / HomeProxy / 基础 Samba / 状态监控 / 系统设置等，**刷入即用** |
| 🟩 **本脚本扩展** | 专注解决小闪存瓶颈与重型应用部署：Docker / AGH 完整安装、`/tmp` 缓存重定向、自愈巡逻、Flash 智能保护、健康检查与卸载工具 |

---

## ✨ 核心特性

- **🛡️ Flash 零占用**：Docker / AGH 二进制全装 U 盘，系统仅存符号链接 (~5MB)
- **🔧 `/tmp` 爆满根治**：apk 缓存与临时目录自动重定向至 U 盘，大包安装不失败
- **🤖 全自动运维**：WAN / U 盘热插拔触发 + 5分钟自愈巡逻 + `360v6-health --fix` 一键修复
- **⚡ 智能保护**：Flash <20MB 中止 / <25MB 跳过 LuCI 插件，永不写爆
- **📦 运维工具集**：状态查询、健康检查、完整卸载，告别盲猜

---

## 🚀 快速开始

### 方案一：首次开机自动运行（推荐）
1. **准备 U 盘**：≥2GB，格式 ext4（Docker 要求）或 FAT32/NTFS
2. **插入 U 盘**：插入路由器 USB 口
3. **刷入固件并重启**：固件已包含本脚本，重启后自动部署
4. **等待部署**：WAN 上线后自动运行，全程约 **5-12 分钟**

### 方案二：手动部署
```bash
# 1. 上传脚本到路由器
scp 96-install-extras root@192.168.2.1:/etc/uci-defaults/

# 2. 执行部署
ssh root@192.168.2.1
sh /etc/uci-defaults/96-install-extras

# 3. 验证状态
360v6-status
```

---

## 📁 目录结构

```
U 盘 (/mnt/sda1/)                    │ 系统 (/)
├── .downloads/                      │ ├── /etc/install-{extras,usb}-done  # 完成标记
│   ├── docker-28.1.0.tgz           │ ├── /etc/install-state/             # 失败计数
│   └── AdGuardHome_linux_arm64.tar.gz│ └── /usr/bin/                      # 运维工具
├── docker-bin/                      │     ├── 360v6-status
├── docker-data/                     │     ├── 360v6-health
├── adguardhome-bin/                 │     └── 360v6-uninstall
├── AdGuardHome/{config,data}/       │
└── swapfile                         │
```

---

## 🛠️ 常用命令

| 功能 | 命令 |
|------|------|
| 查看状态/版本/完成时间 | `360v6-status` |
| 健康检查 | `360v6-health` |
| 健康检查并自动修复 | `360v6-health --fix` |
| 实时日志 | `logread -f \| grep -E "install-main\|usb-extras\|hotplug"` |
| 完全卸载 | `360v6-uninstall` |
| 手动重跑基础环境 | `rm -f /etc/install-extras-done /etc/install-state/phase1-failures && /usr/lib/install-extras/run.sh` |
| 手动重跑重型应用 | `rm -f /etc/install-usb-done && /usr/lib/install-extras/install-usb.sh --force` |

---

## 🌐 服务访问

| 服务 | 地址 | 默认凭据 | 说明 |
|------|------|----------|------|
| LuCI 管理 | `http://192.168.2.1` | root / (空) | 固件内置系统管理界面 |
| AdGuardHome | `http://192.168.2.1:3000` | 首次访问需配置 | 无配置时自动进入 setup 模式 |
| Samba 共享 | `\\192.168.2.1` | root / (空) | Flash ≥64MB 时自动扩展安装 |
| Docker CLI | SSH 登录后执行 | `docker ps` | 需要先部署 U 盘 |

> 💡 **AGH 首次配置**：部署完成后访问 `:3000` 端口完成 Web 配置，配置保存后自动接管 DNS。

---

## 🔧 部署策略

### Flash 分级保护

| Flash 剩余 | 行为 |
|-----------|------|
| < 20MB | ❌ 中止安装，防止变砖 |
| 20-25MB | ✅ 安装基础工具，跳过所有 LuCI 界面包 |
| 25-64MB | ✅ 安装基础工具 + LuCI 界面包 |
| ≥ 64MB | ✅ 完整安装（含 Samba4 + LuCI） |

### Docker 版本自动探测

支持版本（按优先级）：
```
28.1.0 → 28.0.4 → 27.5.1 → 26.1.4 → 25.0.5 → 24.0.7
```

自动测试可用性，优先使用最新稳定版。

---

## ⚠️ 注意事项 & 快速排查

### 重要提醒
- **请勿中断**：首次运行需下载解压，断电/拔盘可能导致锁残留
- **日志输出**：脚本使用 `logger`，终端无回显属正常
- **Swap 自动挂载**：已写入 `/etc/fstab`，重启无需手动 `swapon`
- **Docker 需要 ext4**：overlay2 驱动要求 U 盘格式为 ext4/f2fs

### 常见问题

| 问题 | 解决 |
|------|------|
| 服务未启动 | 运行 `360v6-health --fix` 自动修复 |
| 安装卡住 | `rm -f /tmp/install-*.lock` 清理残留锁后重试 |
| Flash 告急 | `apk cache clean` 清理缓存，脚本会自动降级 |
| AGH 无法访问 | `iptables -I INPUT -p tcp --dport 3000 -j ACCEPT` |
| Docker 启动失败 | 检查 U 盘格式：`mount \| grep sda`，应为 ext4 |

---

## 🗑️ 卸载

```bash
# 执行卸载脚本
360v6-uninstall

# 按提示确认后自动清理：
# - 停止并禁用服务
# - 恢复 dnsmasq DNS（端口 53）
# - 删除 init.d 脚本、symlink、配置文件
# - 删除状态文件、hotplug、cron 条目
# - 删除运维工具
# - 可选清理 U 盘下载缓存
```

> 📌 U 盘上的 `docker-data/` 和 `AdGuardHome/` 数据**默认保留**，卸载时可选清理。


> **一句话总结：插上 U 盘 → 连接 WAN → 去睡觉。**  
> 醒来即享 Docker + 去广告 + 文件共享，运维零干预。🎉
