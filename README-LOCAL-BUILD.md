# 360-v6 70MB精简固件本地编译指南

## 📋 配置状态
- ✅ 配置文件已优化到约70MB
- ✅ 保留 sing-box
- ✅ 移除 Docker/Samba/AdGuardHome/Lucky
- ✅ PARTSIZE=20（最小overlay分区）
- ✅ USB安装脚本已准备

## 🚀 快速开始

### 方法一：一键编译脚本
```bash
# 1. 克隆仓库（如果尚未克隆）
git clone https://github.com/pudie88/360-v6.git
cd 360-v6

# 2. 给予执行权限
chmod +x local-build.sh

# 3. 运行编译
./local-build.sh
```

### 方法二：手动步骤
```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classpath libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python3 python2.7-dev python3-pip \
    python3-setuptools python3-dev rsync subversion swig time \
    xsltproc zlib1g-dev unzip wget curl

# 2. 克隆OpenWrt
git clone https://github.com/openwrt/openwrt.git --depth=1 -b openwrt-24.10
cd openwrt

# 3. 应用配置
cp ../.config .
make defconfig

# 4. 下载组件
make download

# 5. 更新feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 6. 编译（根据CPU核心数调整）
make -j$(($(nproc) - 1)) V=s
```

## ⏱️ 预计时间
- 依赖安装：5-10分钟
- 源码下载：2-5分钟
- 组件下载：5-15分钟
- 编译时间：1-3小时（取决于CPU性能）

## 💾 系统要求
- **内存**: ≥8GB（推荐16GB）
- **存储**: ≥50GB可用空间
- **CPU**: 4核以上（越多越快）
- **系统**: Ubuntu 20.04+/Debian 11+

## 📦 编译结果
编译成功后，固件位于：
```
openwrt/bin/targets/qualcommax/ipq60xx/
```
包含：
- `openwrt-qualcommax-ipq60xx-qihoo_360v6-squashfs-sysupgrade.bin`（系统升级）
- `openwrt-qualcommax-ipq60xx-qihoo_360v6-squashfs-nand-factory.ubi`（工厂刷机）

## 🔧 USB安装方案
### 固件特性：
- 核心固件 ≤70MB
- 保留 sing-box 代理功能
- 精简 LuCI 界面
- 中文支持

### USB扩展安装：
1. 将USB存储格式化为 ext4
2. 将 `files/packages/` 目录复制到USB
3. 刷入精简固件
4. 系统启动后自动安装USB中的重型包

## 🛠️ 故障排除
### 1. 编译失败（内存不足）
```bash
# 减少并行编译数量
make -j2 V=s
```

### 2. 下载失败（网络问题）
```bash
# 重新下载
make download
# 或手动下载dl目录中的文件
```

### 3. 依赖问题
```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade

# 安装缺失的包
sudo apt-get install -y <缺失的包名>
```

## 📄 文件说明
- `.config` - 70MB精简配置文件
- `local-build.sh` - 一键编译脚本
- `files/etc/uci-defaults/94-usb-packages-install` - USB自动安装脚本
- `.github/workflows/openwrt-builder.yml` - GitHub Actions工作流

## 🤝 帮助
1. 查看详细日志：`tail -100 build.log`
2. 检查错误：`grep -i "error\|fail\|stop" build.log`
3. 验证配置：`cat .config | grep -E "PARTSIZE|sing-box"`
4. 报告问题：GitHub Issues

---
**编译愉快！如果遇到问题，随时提问。**