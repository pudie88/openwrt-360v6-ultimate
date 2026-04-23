# 360 V6 - 自动 U 盘 Overlay 扩容 固件
1. **自动检测 U 盘**：首次插入 U 盘时自动格式化为 ext4
2. **自动扩容 overlay**：将 U 盘配置为 `/overlay` 存储空间
3. **自动安装应用**：重启后自动安装 Docker、AdGuardHome、Samba 等重型应用
4. **拔盘安全**：拔掉 U 盘后基础路由功能不受影响（仅附加服务失效）

---

## 工作原理（两阶段设计）

### 第一阶段：扩容（无 U 盘 → 插入 U 盘 → 重启）

```
无 U 盘启动 → 脚本检测无 U 盘 → 跳过扩容，无应用安装
插入 U 盘 → 脚本检测到 U 盘 → 格式化为 ext4 → 复制配置 → 写入 fstab → 重启
```

### 第二阶段：安装（重启后，U 盘已成为 /overlay）

```
重启 → U 盘成为 /overlay → 检测到扩容标记 → 安装所有应用到 U 盘
```

### Docker / AdGuardHome 数据目录

```
/overlay/docker-data/      # Docker 镜像和容器数据
/overlay/adguardhome/      # AdGuardHome 配置和日志
```

---


## 使用说明

### 首次安装（无 U 盘）

1. 刷机启动 360 V6
2. 系统正常启动，仅安装基础工具（htop、smartmontools 等）
3. Docker/AdGuardHome 暂不安装（闪存空间有限）

### 插入 U 盘（自动扩容）

1. 插入 U 盘（推荐 ≥8GB，ext4 格式会被保留，非 ext4 会被格式化）
2. 等待约 30 秒，系统检测到 U 盘
3. 自动执行：
   - 格式化为 ext4（如不是）
   - 复制当前配置到 U 盘
   - 写入 fstab
   - **自动重启**
4. 重启后 U 盘成为 `/overlay`，空间变为 U 盘容量

### 自动安装重型应用

重启后脚本会继续执行：

1. 检测到 U 盘 overlay 已激活
2. 自动安装：
   - `docker` + `dockerd` + `luci-app-dockerman`
   - `adguardhome` + `luci-app-adguardhome`
   - `samba4-server` + `luci-app-samba4`
3. 配置数据目录指向 `/overlay/xxx`
4. 所有服务自动启动

### 验证安装

```bash
# 检查 overlay 是否在 U 盘上
df -h /overlay
# 应该显示 U 盘的总大小（如 28GB）

# 检查 Docker
docker info

# 检查 AdGuardHome
/etc/init.d/adguardhome status

# 检查 Samba
/etc/init.d/samba4 status
```

---

## 拔掉 U 盘会发生什么？

| 场景 | 影响 |
|------|------|
| **拔掉 U 盘后启动** | 系统正常启动，/overlay 回落到闪存（配置丢失） |
| **运行中拔掉 U 盘** | 系统会立即重启（保护机制） |
| **基础路由功能** | ✅ 永远正常（WiFi、DHCP、防火墙） |
| **Docker/AGH/Samba** | ❌ 服务失效，插回 U 盘后恢复 |

> 基础网络功能不受影响，不会变砖。

---

## 故障排查

### 脚本没有自动执行

```bash
# 检查 hotplug 触发器是否存在
ls -la /etc/hotplug.d/iface/99-install-extras

# 手动执行脚本
/usr/lib/install-extras/run.sh
```

### U 盘没有被格式化

```bash
# 检查 e2fsprogs 是否安装
which mkfs.ext4

# 手动格式化
mkfs.ext4 /dev/sda1
```

### Overlay 没有切换到 U 盘

```bash
# 检查 fstab 配置
cat /etc/config/fstab

# 检查当前 overlay 设备
mount | grep overlay
```

### 重新触发安装

```bash
# 删除完成标记，下次 WAN UP 重新执行
rm -f /etc/install-extras-done

# 或手动执行
/usr/lib/install-extras/run.sh
```

---

## 脚本核心特性

| 特性 | 实现方式 |
|------|----------|
| 网络检测 | ping 223.5.5.5 / 8.8.8.8，最多等待 60 次 |
| DNS 注入 | 强制写入 223.5.5.5 / 8.8.8.8 到 /etc/resolv.conf |
| U 盘挂载检测 | 检查 /mnt/sda1、/mnt/sda、/mnt/usb |
| 格式化 | mkfs.ext4 -F -L "owrt-overlay" |
| fstab 配置 | UUID 挂载，避免设备名漂移 |
| Docker 安装 | dockerd 使用 `--force-broken-world` |
| 数据目录 | 全部指向 `/overlay/xxx` |

---

## 体积说明

编译时只需增加约 **200KB**（e2fsprogs），其他工具会由脚本在首次运行时安装到 U 盘，不占用闪存空间。

---

## 兼容性

| 项目 | 状态 |
|------|------|
| 360 V6 (IPQ6000) | ✅ 测试通过 |
| ImmortalWrt 23.05+ | ✅ 支持 |
| APK 包管理器 | ✅ 支持 |
| U 盘格式 | ext4（自动格式化） |
| 最小 U 盘容量 | 1GB（推荐 ≥8GB） |

---


需要我调整或补充任何内容吗？
