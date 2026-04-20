# OpenWrt 360 V6 修复文件包

## 📁 文件结构
```
openwrt_fix_package/
├── .config                    # OpenWrt 编译配置（已优化）
├── openwrt-builder.yml       # GitHub Actions Workflow
└── files/                    # 预置配置文件
    ├── etc/
    │   ├── sysctl.d/
    │   │   └── 99-bbr.conf
    │   └── uci-defaults/
    │       ├── 94-mount-usb-docker  # USB 挂载脚本（新）
    │       ├── 95-install-extras    # 其他大包安装
    │       ├── 96-install-docker    # Docker 安装（已更新）
    │       ├── 97-fix-apk-feeds
    │       ├── 98-network-check
    │       └── 99-custom-ip
    └── root/
        └── flashing-guide.txt
```

## 🎯 核心改进

### 1. 固件大小控制（128MB 闪存友好）
- **分区配置**: `CONFIG_TARGET_ROOTFS_PARTSIZE=100`
- **大包处理**: Docker、Samba、AdGuardHome 等二进制编译进固件
- **数据分离**: 运行时数据存储在 USB 硬盘，不占用 overlay 空间

### 2. USB 存储集成
- **自动挂载**: 插入 USB 硬盘自动挂载并配置
- **数据目录**: Docker 数据、Samba 共享、AdGuardHome 数据都指向 USB
- **无 USB 模式**: 无 USB 时使用 overlay（约 100MB 限制）

### 3. 首次启动流程优化
```
启动顺序:
1. 系统启动
2. 检查 USB → 94-mount-usb-docker
3. 网络验证 → 98-network-check
4. 修复 feeds → 97-fix-apk-feeds  
5. 安装 Docker → 96-install-docker（等待 USB）
6. 安装其他包 → 95-install-extras
7. 设置 LAN IP → 99-custom-ip
```

### 4. 固件体积预算
```
Squashfs（只读系统）: ~30MB
├── 内核 + 基础系统: ~15MB
├── LuCI + 主题: ~10MB
└── 无线驱动等: ~5MB

Overlay（可写分区 100MB）:
├── Docker 二进制: 60MB
├── Samba4-server: 15MB
├── AdGuardHome: 10MB
├── Lucky: 5MB
├── 其他小包: 5MB
└── 系统配置: 5MB
总计: 100MB（刚好）
```

## 🚀 部署指南

### 方法 A：替换现有文件
```bash
# 备份原文件
cp -r /tmp/openwrt_fix_package/* /path/to/your/repo/
```

### 方法 B：手动应用修改
1. **更新 .config**:
   - 设置 `CONFIG_TARGET_ROOTFS_PARTSIZE=100`
   - 确保所有大包都设为 `y`（编译进固件）

2. **添加 USB 挂载脚本**:
   - 复制 `94-mount-usb-docker` 到 `files/etc/uci-defaults/`
   - 更新 `96-install-docker` 等待 USB 挂载

3. **更新 Workflow**:
   - 替换 `openwrt-builder.yml`
   - 重新触发构建

## 🔧 验证步骤

### 构建前检查
```bash
# 1. 检查固件大小预期
grep "PARTSIZE" .config  # 应为 100
grep "docker\|samba\|adguardhome" .config  # 应为 y

# 2. 检查脚本顺序
ls -la files/etc/uci-defaults/  # 94-99 顺序正确
```

### 构建后验证
1. **固件大小**: `sysupgrade.bin` ≤ 110MB
2. **功能完整**: 所有大包二进制都存在
3. **USB 支持**: 脚本自动检测和挂载

## 📝 注意事项

1. **USB 硬盘格式**: 推荐 ext4，支持 NTFS
2. **首次启动时间**: 安装大包需要 5-10 分钟
3. **无 USB 模式**: 功能受限但可用
4. **日志查看**: `/var/log/extras-install.log` 和 `/var/log/docker-install.log`

## 🆘 故障排除

### 问题：固件仍然过大
**解决**：检查是否仍有大包设为 `n`，应全部设为 `y` 编译进固件

### 问题：USB 未自动挂载
**解决**：
```bash
# SSH 登录后手动执行
sh /etc/uci-defaults/94-mount-usb-docker
# 查看日志
logread | grep "mount-usb-docker"
```

### 问题：Docker 启动失败
**解决**：
```bash
# 检查 Docker 服务状态
service dockerd status
# 查看详细日志
tail -f /var/log/docker-install.log
```

---

**构建成功后**，刷机指南见 `files/root/flashing-guide.txt`
