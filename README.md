```markdown
# 360 V6 一键扩展脚本

> 专为 **128M Flash + 512M RAM** 设计的全自动部署脚本  
> 插上 U 盘，重启，剩下的交给脚本

---

## 功能一览

| 功能 | 说明 |
|------|------|
| Flash 双档保护 | <20MB 中止安装，<25MB 跳过 Samba，绝不写爆 |
| 自动 Swap | U 盘上创建 256MB Swap，激活成功才写入 fstab |
| Docker | 可执行文件 + 数据全装 U 盘，Flash 零占用，procd 管理 |
| AdGuardHome | 可执行文件 + 配置 + 数据全装 U 盘，重刷不丢失 |
| Samba | Flash ≥25MB 时自动安装，含 LuCI 管理界面和中文包 |
| DNS 容错 | 临时注入公共 DNS，退出时精确恢复原配置并重启 dnsmasq |
| 热插拔重试 | WAN 上线触发、U 盘插入触发、每 5 分钟 cron 自愈巡逻 |
| I/O 优化 | swappiness=10，减少换页频率 |

---

## 快速开始

### 1. 准备一个 U 盘

| 项目 | 要求 |
|------|------|
| 容量 | **≥4GB**（推荐 8GB+，Docker 镜像较占空间） |
| 格式 | ext4 / FAT32 / NTFS 均可 |
| 用途 | 存放 Docker、AdGuardHome、Swap 数据 |

### 2. 插入 U 盘，重启设备

```bash
reboot
```

### 3. 等待 5-10 分钟

脚本在 WAN 口连接后自动运行，无需人工干预。

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

## 文件布局

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

/usr/lib/install-extras/
├── run.sh                      # Phase 1：基础环境安装
└── install-usb.sh              # Phase 2：重型应用安装 + 自愈

/usr/bin/
└── 360v6-status                # 状态查询工具
```

---

## 安装的软件包

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

### 可选 Samba（Flash ≥25MB）

| 软件包 | 说明 |
|--------|------|
| `samba4-server` | Windows 文件共享服务 |
| `luci-app-samba4` | Samba LuCI 管理界面 |
| `luci-i18n-samba4-zh-cn` | 中文语言包 |

---

## Flash 保护阈值

| 剩余空间 | 行为 |
|----------|------|
| < 20MB | 中止安装，防止变砖 |
| 20-25MB | 只装基础工具（bash/htop/lsblk/smartmontools/fdisk） |
| ≥ 25MB | 基础工具 + Samba4（含 LuCI 管理界面和中文包） |

---

## 自愈机制

| 机制 | 触发条件 | 动作 |
|------|----------|------|
| WAN 热插拔 | WAN 口上线 + 基础环境未完成 | 触发 `run.sh` |
| U 盘热插拔 | U 盘插入 + 基础已完成 + 重型未完成 | 触发 `install-usb.sh` |
| 定时自愈 | 每 5 分钟（cron） | 检查 U 盘状态，验证锁进程，失败自动重试 |
| 锁清理 | 检测到僵尸进程（kill -0 失败） | 自动清理过期锁文件，允许重新运行 |

---

## 运行流程

```
WAN 上线 ──→ hotplug 触发 run.sh
                │
                ├─ 等待网络（最长 3 分钟）
                ├─ 注入公共 DNS
                ├─ apk update（HTTPS 失败自动降级 HTTP）
                ├─ 安装基础工具
                ├─ 修复 avahi/dbus
                ├─ 标记 /etc/install-extras-done
                │
                ├─ 检测到 U 盘？──→ 后台启动 install-usb.sh
                │                      │
                │                      ├─ 创建 Swap（256MB）
                │                      ├─ 安装 Docker 到 U 盘
                │                      ├─ 安装 AGH 到 U 盘
                │                      ├─ 启动 procd 服务
                │                      └─ 标记 /etc/install-usb-done
                │
                └─ 未检测到 U 盘？──→ 等待 U 盘热插拔
                                          │
U 盘插入 ──→ hotplug 触发 install-usb.sh ──┘

cron 每 5 分钟 ──→ 自愈巡逻 ──→ 清理僵尸锁 ──→ 重试安装
```

---

## 故障排除

### Q1: 安装到一半断电/断网了怎么办？

脚本会自动重试：
- 基础环境：下次 WAN 上线时自动重试
- 重型应用：每 5 分钟自愈巡逻（cron），检测到僵尸锁会自动清理后重试

### Q2: 拔掉 U 盘会怎样？

- Docker 和 AdGuardHome 会停止工作
- 系统本身不受影响
- 重新插回 U 盘并重启即可恢复

### Q3: 如何重新运行脚本？

```bash
rm -f /etc/install-extras-done /etc/install-usb-done
rm -f /tmp/install-main.lock /tmp/install-usb.lock
rm -rf /etc/install-state/*
reboot
```

### Q4: 如何查看安装进度？

```bash
# 实时监控
logread -f | grep -E 'main|usb|self-heal'

# 查看状态
360v6-status
```

### Q5: Docker / AGH 启动失败？

```bash
# 检查 U 盘挂载
grep " /mnt/sda1 " /proc/mounts

# 检查固化路径
cat /etc/install-usb-mount

# 手动重启服务
/etc/init.d/dockerd restart
/etc/init.d/adguardhome restart
```

### Q6: Flash 使用率偏高？

```bash
apk cache clean
rm -rf /tmp/*
```

---

## 注意事项

| 序号 | 注意事项 |
|------|----------|
| 1 | 首次运行需要 **5-10 分钟**，取决于网络速度和 U 盘写入速度 |
| 2 | 建议 U 盘 **≥8GB**，Docker 镜像和容器较占空间 |
| 3 | 不要在运行时拔 U 盘，Docker 和 AGH 依赖它 |
| 4 | Swap 已自动写入 fstab，重启后自动激活 |
| 5 | Docker 数据根目录在 U 盘（`docker-data/`），重刷系统不丢失容器数据 |
| 6 | AGH 配置和过滤规则在 U 盘（`adguardhome-config/` + `adguardhome-data/`），重刷不丢失 |

---

## 版本历史

| 版本 | 主要更新 |
|------|----------|
| v4.2 Final | 自愈锁验证（kill -0）、trap 时序修复、空间不足清理临时文件、PATH 修复 |
| v4.1 Optimal Merge | 两阶段部署、热插拔触发、procd 集成、U 盘离线安装 |

---

**Made for 360 V6 & IPQ6000**
```
