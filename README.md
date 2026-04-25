# 360 V6 终极版一键扩展脚本

> 专为 **128M Flash + 512M RAM** 设备设计的全自动部署脚本  
> 适合想「躺平」的用户 —— 插上 U 盘，剩下的交给脚本

---

## 📦 功能一览

| 功能 | 说明 |
|------|------|
| 🛡️ Flash 三档保护 | <20MB 中止安装、<25MB 跳过 LuCI、<64MB 跳过 Samba，绝不写爆 |
| 💾 自动 Swap | U 盘上创建 256MB Swap，激活成功后才写入 fstab |
| 🐳 Docker | 可执行文件+数据全装 U 盘，Flash 零占用，procd 管理 |
| 🚫 AdGuardHome | 可执行文件+配置+数据全装 U 盘，重刷不丢失 |
| 💾 Samba | Flash ≥25MB 时自动安装，并修复 dbus/avahi 崩溃 |
| 🌐 DNS 容错 | 临时注入公共 DNS，退出时精确恢复原配置 |
| 🔌 热插拔重试 | 安装失败自动注册，WAN UP 后重试，每5分钟自愈巡逻 |
| ⚡ I/O 优化 | deadline 调度器 + swappiness=10 + min_free_kbytes=16MB |

---

## 🚀 快速开始

### 1. 准备一个 U 盘

| 项目 | 要求 |
|------|------|
| 容量 | **≥4GB**（推荐 8GB+，Docker 镜像较占空间） |
| 格式 | ext4 / FAT32 / NTFS 均可 |
| 作用 | 存放 Docker、AdGuardHome、Swap 数据 |

### 2. 插入 U 盘，重启设备

```bash
# 刷完系统后，插入 U 盘，执行：
reboot
```

### 3. 等待 5-10 分钟

脚本会在 WAN 口连接后自动运行，无需任何人工干预。

### 4. 验证安装

```bash
# 查看状态
360v6-status

# 查看实时日志
logread -f | grep -E 'main|usb'

# 验证服务
/etc/init.d/dockerd status
/etc/init.d/adguardhome status
```

---

## 📁 文件布局

### U 盘目录结构

```
U 盘根目录/
├── swapfile                    # 256MB Swap 文件
├── .tmp/                       # apk 临时解压目录
├── .apk-cache/                 # apk 包缓存
├── docker-system/              # Docker 可执行文件（--root 安装）
│   └── usr/bin/dockerd
├── docker-data/                # Docker 数据目录（镜像、容器、卷）
├── adguardhome-system/         # AGH 可执行文件（--root 安装）
│   └── usr/bin/AdGuardHome
├── adguardhome-config/         # AGH 配置文件
│   └── AdGuardHome.yaml
└── adguardhome-data/           # AGH 运行数据（过滤器、日志）
```

### 系统内部文件

```
/etc/
├── install-extras-done         # 基础环境完成标记
├── install-usb-done            # 重型应用完成标记
├── install-usb-mount           # U 盘挂载点固化路径
├── install-state/              # 重试计数目录
│   ├── phase1-failures
│   └── phase2-failures
└── hotplug.d/
    ├── iface/96-install-extras # WAN 上线触发器
    └── block/96-install-usb    # U 盘插入触发器
```

---

## ⚙️ 安装的软件包

### 基础工具（必装）

| 软件包 | 说明 |
|--------|------|
| `bash` | 更好的 Shell 环境 |
| `htop` | 交互式进程查看器 |
| `lsblk` | 列出块设备信息 |
| `smartmontools` | 硬盘健康检测 |
| `fdisk` | 磁盘分区工具 |

### 重型应用（安装到 U 盘）

| 软件包 | 说明 |
|--------|------|
| `docker` + `dockerd` | 容器运行环境 |
| `adguardhome` | DNS 去广告服务 |

### 可选 LuCI（Flash ≥25MB）

| 软件包 | 说明 |
|--------|------|
| `luci-app-samba4` + 中文包 | Samba 网页管理界面 |
| `luci-app-dockerman` + 中文包 | Docker 网页管理界面 |
| `luci-app-adguardhome` | AdGuardHome 网页管理界面 |

### 可选 Samba（Flash ≥25MB）

| 软件包 | 说明 |
|--------|------|
| `samba4-server` | Windows 文件共享服务 |

---

## 🔧 故障排除

### Q1: 安装到一半断电/断网了怎么办？

**A:** 脚本会自动重试：
- 基础环境：下次 WAN 上线时自动重试
- 重型应用：每 5 分钟自愈巡逻（cron），失败自动重试

### Q2: 拔掉 U 盘会怎样？

**A:** 
- Docker 和 AdGuardHome 会停止工作
- 系统本身不受影响
- 重新插回 U 盘并重启即可恢复

### Q3: 如何重新运行脚本？

```bash
# 清除完成标记，重启即可
rm -f /etc/install-extras-done /etc/install-usb-done
rm -rf /etc/install-state/*
reboot
```

### Q4: Flash 使用率超 85% 怎么办？

```bash
apk cache clean              # 清理 apk 缓存
rm -rf /tmp/*                # 清理临时文件
```

### Q5: 如何查看安装进度？

```bash
# 实时监控
logread -f | grep -E 'main|usb|hotplug|self-heal'

# 查看状态
360v6-status
```

### Q6: Docker/AGH 启动失败？

```bash
# 检查 U 盘挂载
grep " /mnt/sda1 " /proc/mounts

# 检查固化路径
cat /etc/install-usb-mount

# 手动重启服务
/etc/init.d/dockerd restart
/etc/init.d/adguardhome restart
```

---

## 📜 运行日志示例

```
[12:30:01] ▶ v6.0 基础环境启动
[12:30:11] ✅ 网络就绪，临时 DNS 已注入
[12:30:15] 📊 Flash 剩余: 43384KB
[12:30:20] ✅ apk update 成功
[12:30:25] 📦 bash htop lsblk smartmontools fdisk
[12:31:10] ✅ 基础环境完成！Flash: 42%
[12:31:15] ✅ U 盘已挂载: /mnt/sda1，触发重型应用...
[12:31:20] ▶ 重型应用部署 | 缓存:/mnt/sda1/.apk-cache
[12:31:25] ⏳ 创建 256MB Swap...
[12:32:00] ✅ Swap 已激活
[12:32:10] 📦 Docker 部署
[12:34:00] ✅ Docker 已启动
[12:34:10] 📦 AdGuardHome 部署
[12:35:30] ✅ AGH 已启动
[12:35:35] 🎉 重型应用完成 [Docker:OK AGH:OK]
```

---

## ⚠️ 注意事项

| 序号 | 注意事项 |
|------|----------|
| 1 | **首次运行需要 5-10 分钟**，取决于网络速度和 U 盘写入速度 |
| 2 | **建议 U 盘 ≥8GB**，Docker 镜像和容器较占空间 |
| 3 | **不要在生产环境随意拔 U 盘**，Docker/AGH 依赖它 |
| 4 | **Swap 已自动写入 fstab**，重启后自动挂载 |
| 5 | **Flash 保护阈值**：<20MB 中止安装 / <25MB 跳过 LuCI / <64MB 跳过 Samba |

---

## 🔍 自愈机制说明

| 机制 | 触发条件 | 动作 |
|------|----------|------|
| WAN 热插拔 | WAN 口上线 + 基础环境未完成 | 触发 `run.sh` |
| U 盘热插拔 | U 盘插入 + 重型应用未完成 | 触发 `install-usb.sh` |
| 定时自愈 | 每 5 分钟 (cron) | 检查 U 盘状态，失败自动重试 |
| 锁清理 | 检测到僵尸进程 | 自动清理过期锁文件 |

---

## 📊 Flash 保护阈值说明

| 剩余空间 | 行为 |
|----------|------|
| < 20MB | ❌ 直接中止安装，防止变砖 |
| 20-25MB | ✅ 只装基础工具，跳过所有 LuCI |
| 25-64MB | ✅ 基础工具 + Samba，跳过 LuCI |
| ≥ 64MB | ✅ 完整安装（含 Samba + 所有 LuCI） |

---

## 🎯 一句话总结

> **插上 ≥8GB 的 U 盘，重启，然后去睡觉。**  
> 醒来 Samba、Docker、AdGuardHome 全自动部署完毕，Flash 剩余空间不受影响。

---

## 📝 版本历史

| 版本 | 主要更新 |
|------|----------|
| v6.0 | 最终稳定版：自愈机制 + 锁优化 + DNS 保底 + procd 集成 |

---

**Made with ❤️ for 360 V6 & IPQ6000**
