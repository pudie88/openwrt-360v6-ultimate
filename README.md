# 360 V6 一键扩展脚本

> 专为 **128M Flash + 512M RAM** 设备设计的全自动部署脚本  
> 适合想“躺平”的用户 —— 插上 U 盘，剩下的交给脚本

---

## 📦 功能一览

| 功能 | 说明 |
|------|------|
| 🛡️ Flash 三档保护 | <15MB 跳过所有 LuCI，<30MB 跳过可选插件，绝不写爆 |
| 💾 自动 Swap | U 盘上创建 256MB Swap，不碰 Flash |
| 📦 Docker | 数据目录自动迁至 U 盘，daemon.json 已优化 |
| 🚫 AdGuardHome | 配置+数据自动迁至 U 盘，重刷不丢失 |
| 💾 Samba | 自动安装并修复 dbus/avahi 崩溃问题 |
| 🌐 DNS 容错 | 临时注入公共 DNS，绕过 SmartDNS 启动时序 |
| 🔌 热插拔重试 | 安装失败自动注册，WAN UP 后重试 |
| ⚡ I/O 优化 | deadline 调度器 + swappiness=10 |

---

## 🚀 快速开始

### 1. 准备一个 U 盘
- 容量：**≥256MB**（推荐 1GB+）
- 格式：ext4 / FAT32 / NTFS 均可
- 作用：存放 Docker、AdGuardHome、Swap 数据

### 2. 插入 U 盘，重启设备
```bash
# 刷完系统后，插入 U 盘，执行：
reboot
```

### 3. 等待 5-10 分钟
脚本会在 WAN 口连接后自动运行，无需任何人工干预。

### 4. 验证安装
```bash
# 检查完成标记
ls /etc/install-extras-done

# 查看日志
logread | grep install-extras

# 验证服务
/etc/init.d/dockerd status
/etc/init.d/adguardhome status
```

---

## 📁 文件布局

```
U 盘根目录/
├── swapfile                 # 256MB Swap 文件
├── docker-data/             # Docker 数据目录（镜像、容器、卷）
└── AdGuardHome/
    ├── config/              # adguardhome.yaml 配置
    └── data/                # 过滤器、查询日志等运行数据

系统内部/
├── /etc/install-extras-done        # 完成标记（存在即表示已部署）
├── /usr/lib/install-extras/run.sh  # 主脚本
└── /etc/hotplug.d/iface/99-install-extras  # 热插拔触发器
```

---

## 🧪 支持设备

| 设备 | Flash | RAM | 状态 |
|------|-------|-----|------|
| 360 V6 | 128MB | 512MB | ✅ 完美 |
| 小米 CR660x | 128MB | 512MB | ✅ 完美 |
| 其他 128M+512M OpenWrt | — | — | ✅ 理论上兼容 |

---

## ⚙️ 安装的软件包

### 必装（不受 Flash 影响）
- `smartmontools`、`bash`、`htop`、`fdisk`、`lsblk`、`samba4-server`

### 条件安装（U 盘必须存在）
- `docker` + `dockerd`
- `adguardhome`

### 条件安装（Flash ≥30MB 剩余空间）
- `luci-app-samba4` + 中文包
- `luci-app-dockerman` + 中文包
- `luci-app-adguardhome`

---

## 🔧 常见问题

### Q1: 安装到一半断电/断网了怎么办？
**A:** 脚本会自动注册热插拔触发器，下次 WAN 口连接时会自动重试。

### Q2: 拔掉 U 盘会怎样？
**A:** Docker 和 AdGuardHome 会停止工作，但系统本身不受影响。重新插回并重启即可恢复。

### Q3: 如何重新运行脚本？
**A:** 
```bash
rm -f /etc/install-extras-done
reboot
```

### Q4: Flash 使用率超 85% 怎么办？
```bash
apk cache clean   # 清理 apk 缓存
```

---

## 📜 运行日志示例

```
[12:30:01] ▶ Final v3.2 启动 | 128M Flash 保护模式
[12:30:11] ✅ 网络就绪，临时 DNS 已注入
[12:30:15] ✅ U 盘已挂载: /mnt/sda1
[12:30:20] ⚡ I/O 调度器: mq-deadline
[12:30:25] ✅ Swap 256MB 已启用
[12:30:40] ✅ apk update 成功
[12:31:10] 📦 安装: docker
[12:32:45] ✅ Docker 已启动 | 数据目录: /mnt/sda1/docker-data
[12:33:20] ✅ AdGuardHome 已启动 | 配置+数据: /mnt/sda1/AdGuardHome
[12:33:25] 🎉 Final v3.2 部署完成！Flash 使用率: 42%
```

---

## ⚠️ 注意事项

1. **不要在生产环境随意拔 U 盘**（Docker/AGH 依赖它）
2. **首次运行需要 5-10 分钟**（取决于网络速度）
3. **建议保留至少 30MB Flash 剩余空间**，否则 LuCI 插件会被跳过
4. **Swap 文件不自动挂载**（每次开机需手动 `swapon`，或写入 `/etc/fstab`）

---

## 📝 手动添加 fstab 挂载 Swap（可选）

```bash
echo "/mnt/sda1/swapfile swap swap defaults 0 0" >> /etc/fstab
```

---

## 🎯 一句话总结

> **插上 U 盘，重启，然后去睡觉。**  
> 醒来 Samba、Docker、AdGuardHome 全自动部署完毕。

