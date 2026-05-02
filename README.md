# 🚀 openwrt-360v6-plus 一键扩展脚本 [V1.2]

> 专为 **360 V6 / 小米 CR660x / IPQ6000** 设计。  
> **128M Flash + 512M RAM**，无 U 盘 = 基础版（包管理器工具），插 U 盘 = 全自动 Docker + AdGuardHome 部署。

---

## 📌 固件功能 vs 脚本扩展

| 类别 | 说明 |
|------|------|
| 🟦 **固件预编译** | ImmortalWrt 原生功能：网络管理 / LuCI 界面 / SmartDNS / HomeProxy / 基础 Samba / 状态监控 / 系统设置等 |
| 🟩 **脚本扩展** | 插 U 盘后自动触发：Docker / AdGuardHome 完整安装、Swap 自动配置、健康检查与卸载工具 |

> ⚠️ **无 U 盘时**：脚本仅安装基础工具包（bash/htop/lsblk/smartmontools/fdisk/curl），不部署 Docker/AGH

---

## ✨ 核心特性 [V1.2]

- **🛡️ Flash 零占用**：Docker / AGH 二进制全装 U 盘，系统仅存符号链接 (~5MB)
- **🤖 全自动运维**：WAN / U 盘热插拔触发 + 健康检查自动修复 (`--fix`)
- **⚡ 智能容错增强**：
  - `_wget_retry` 支持**断点续传** + **5 次重试** + **指数退避间隔**
  - `_download_agh` 多源轮询（ghfast/ghproxy/直连），**支持跨源续传**
  - 组件失败计数（最多 3 次）+ 完整性校验（gzip -t）
- **💾 Swap 坏块检测**：激活后执行写入验证，检测坏块自动禁用并重建
- **🐳 Docker 就绪检测**：循环等待最多 20s，消除"初始化中"误报
- **📦 运维工具集**：`360v6-status` / `360v6-health` / `360v6-uninstall` / `agh-finalize`
- **🔐 密码安全**：`agh-finalize` 支持交互式密码输入（stty -echo），避免明文暴露进程列表

---

## 🚀 快速开始

### 方案一：无 U 盘 - 基础版
1. 刷入固件（已预置本脚本）
2. 连接 WAN 口，首次联网自动触发基础部署
3. 安装基础工具：`bash` `htop` `lsblk` `smartmontools` `fdisk` `curl`

### 方案二：插 U 盘 - 全自动扩展部署
1. **准备 U 盘**：≥2GB，**推荐 ext4 格式**（Docker overlay2 需要）
2. **插入 U 盘**：插入路由器 USB 口
3. **连接 WAN**：脚本自动触发，全程约 **5-12 分钟**
4. **验证状态**：`360v6-status`

### 方案三：手动部署（已有固件）
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
U 盘 (/mnt/sda1/)                      │ 系统 (/)
├── .downloads/                        │ ├── /etc/install-{extras,usb}-done   # 完成标记
│   ├── docker-28.1.0.tgz             │ ├── /etc/install-state/              # 失败计数/自愈状态
│   └── AdGuardHome_linux_arm64.tar.gz│ │   ├── docker-failures
├── docker-bin/                        │ │   ├── agh-failures
│   ├── docker                         │ │   ├── phase1-failures
│   ├── dockerd                        │ │   ├── docker-done
│   └── ...                            │ │   └── agh-done
├── docker-data/                       │ ├── /usr/bin/
├── adguardhome-bin/                   │ │   ├── 360v6-status
│   └── AdGuardHome                    │ │   ├── 360v6-health
├── AdGuardHome/                       │ │   ├── 360v6-uninstall
│   └── data/                          │ │   └── agh-finalize
│       └── {config,logs,...}          │ ├── /etc/init.d/dockerd
└── swapfile (256MB)                   │ └── /etc/hotplug.d/{iface,block}/
                                        └── 96-install-extras  # hotplug 触发器
```

---

## 🛠️ 常用命令

| 功能 | 命令 |
|------|------|
| 查看状态/版本/完成时间 | `360v6-status` |
| 健康检查 | `360v6-health` |
| 健康检查并自动修复 | `360v6-health --fix` |
| 实时日志 | `logread -f \| grep -E "install-main\|usb-extras\|agh-finalize"` |
| 完全卸载 | `360v6-uninstall` |
| 手动重跑基础环境 | `rm -f /etc/install-extras-done /etc/install-state/phase1-failures && /usr/lib/install-extras/run.sh` |
| 手动重跑重型应用 | `rm -f /etc/install-usb-done && /usr/lib/install-extras/install-usb.sh --force` |
| AGH 配置完成后接管 DNS | `agh-finalize <用户名>` （密码交互式输入） |

---

## 🌐 服务访问

| 服务 | 地址 | 默认凭据 | 说明 |
|------|------|----------|------|
| LuCI 管理 | `http://192.168.2.1` | root / (空) | 固件内置系统管理界面 |
| HomeProxy | LuCI 内配置 | - | 代理基础版，无需 U 盘 |
| AdGuardHome | `http://192.168.2.1:3000` | 首次访问需配置 | 需插 U 盘；向导完成后执行 `agh-finalize` 接管 DNS |
| Docker CLI | SSH 登录后执行 | `docker ps` | 需要先部署 U 盘 |

---

## 🔧 部署策略

### U 盘空间要求
- **最小要求**：≥1GB 可用空间（脚本启动时检查）
- **推荐格式**：ext4（Docker overlay2 驱动需要 overlay 文件系统支持）

### Docker 版本自动探测

支持版本（按优先级）：
```
28.1.0 → 27.5.1 → 26.1.4
```

自动测试可用性，优先使用最新稳定版，下载失败时自动降级。

### 完整性保护机制

| 机制 | 说明 |
|------|------|
| **gzip -t 校验** | 下载完成后校验 tgz 完整性，拦截截断文件/错误页面 |
| **断点续传** | 已下载 >1MB 时自动续传，节省流量 + 提高成功率 |
| **多源轮询** | ghfast.top → ghproxy → GitHub 直连，自动切换可用源 |
| **跨源续传** | 换源时保留已有数据，支持从不同源继续下载 |
| **空目录检测** | tar 解压后检查是否有文件被移动，防止静默失败 |
| **失败计数** | 组件失败 ≥3 次后自动跳过，避免无限重试 |

### DNS 冲突检测

基于 `netstat` 直接检测 dnsmasq 实际端口占用：
```bash
netstat -lnup | awk '$4 ~ /:53$/ && $NF ~ /dnsmasq/'
```
避免 UCI 配置未设置 port 时误报冲突。

### AGH 密码安全

```bash
# 推荐方式：交互式输入（密码不回显）
agh-finalize admin

# 不推荐：明文传参（会出现在进程列表）
agh-finalize admin mypassword
```

---

## 🔄 自愈机制

### 触发条件
- U 盘已插入但重型应用未完成（`/etc/install-usb-done` 不存在）
- 距上次自愈 ≥300 秒
- 组件失败次数未达上限（docker-failures <3 且 agh-failures <3）

### 执行逻辑
- 检测 U 盘挂载点
- 清理残留锁文件
- 重新执行 `/usr/lib/install-extras/install-usb.sh`

> 自愈由 crontab 或外部触发器调用：`/usr/lib/install-extras/install-usb.sh --self-heal`

---

## ⚠️ 注意事项 & 快速排查

### 重要提醒
- **无 U 盘 = 基础工具包**：仅安装 bash/htop/lsblk/smartmontools/fdisk/curl
- **插 U 盘 = 全自动扩展**：断电/拔盘可能导致锁残留
- **日志输出**：脚本使用 `logger`，终端无回显属正常
- **Swap**：首次插 U 盘时自动创建 256MB swapfile 并激活（重启后需重新激活），**V1.2 新增坏块检测**
- **Docker 需要 overlay 支持**：U 盘格式建议 ext4，否则降级为 vfs 驱动

### 常见问题

| 问题 | 解决 |
|------|------|
| 服务未启动 | 运行 `360v6-health --fix` 自动修复 |
| 安装卡住 | `rm -f /tmp/install-*.lock` 清理残留锁后重试 |
| Flash 告急 | `apk cache clean` 清理缓存 |
| AGH 无法访问向导 | 检查防火墙：`iptables -I INPUT -p tcp --dport 3000 -j ACCEPT` |
| Docker 启动失败 | 检查 U 盘格式：`mount \| grep sda`，建议 ext4 |
| AGH 密码明文暴露 | 使用 `agh-finalize <用户名>`（省略密码参数）交互式输入 |
| DNS 冲突（53 端口占用）| 运行 `360v6-health --fix` 自动禁用 dnsmasq 端口 |
| AGH 下载失败 | 检查网络，脚本会自动轮询多源；仍失败可手动执行 `360v6-upgrade --agh` |

---

## 🗑️ 卸载

```bash
# 执行卸载脚本
360v6-uninstall

# 按提示确认后自动清理：
# - 停止并禁用 dockerd / AdGuardHome
# - 恢复 dnsmasq DNS 端口（删除 port=0 配置）
# - 删除 /usr/bin 下的 symlink
# - 删除 /etc/init.d/dockerd
# - 删除状态文件（/etc/install-*-done、/etc/install-state/*）
# - 删除 hotplug 脚本
# - 删除 agh-finalize、360v6-* 工具
```

> 📌 **数据保留**：U 盘上的 `docker-data/`、`AdGuardHome/`、`swapfile` 及 `.downloads/` **默认保留**，如需清理请手动删除。



> **一句话总结：插 U 盘 → 连 WAN → 等 10 分钟 → 访问 3000 端口配 AGH → 执行 agh-finalize → 享受去广告 + Docker。**  
> 运维工具全配齐，健康检查一键修，卸载不残留。🎉
