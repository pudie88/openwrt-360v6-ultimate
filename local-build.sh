#!/bin/bash
# 360-v6 70MB精简固件本地编译脚本
# 在 Ubuntu/Debian 上运行

echo "🚀 开始编译 360-v6 70MB精简固件"
echo "========================================"

# 安装依赖
echo "📦 安装编译依赖..."
sudo apt-get update
sudo apt-get install -y build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classpath libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python3 python2.7-dev python3-pip \
    python3-setuptools python3-dev rsync subversion swig time \
    xsltproc zlib1g-dev unzip wget curl

# 克隆 OpenWrt 源码
echo "📁 克隆 OpenWrt 源码..."
if [ ! -d "openwrt" ]; then
    git clone https://github.com/openwrt/openwrt.git --depth=1 -b openwrt-24.10
else
    echo "⚠️ openwrt目录已存在，跳过克隆"
fi

cd openwrt

# 下载必要组件
echo "📥 下载组件..."
make download
find . -maxdepth 1 -name "*.patch" -exec rm {} \;

# 应用配置文件
echo "⚙️  应用配置..."
cp ../.config .
make defconfig

# 更新 feeds
echo "🔄 更新 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 验证配置
echo "✅ 验证配置..."
if grep -q "^CONFIG_TARGET_ROOTFS_PARTSIZE=20" .config; then
    echo "  ✅ PARTSIZE=20"
else
    echo "  ❌ PARTSIZE配置错误"
    exit 1
fi

if grep -q "^CONFIG_PACKAGE_sing-box=y" .config; then
    echo "  ✅ sing-box已启用"
else
    echo "  ❌ sing-box未启用"
    exit 1
fi

# 开始编译
echo "🔨 开始编译固件..."
echo "CPU核心数: $(nproc)"
echo "内存: $(free -h | grep Mem | awk '{print $2}')"

# 使用多核编译（留一个核心给系统）
CORES=$(( $(nproc) - 1 ))
if [ $CORES -lt 1 ]; then
    CORES=1
fi

echo "使用 ${CORES} 个核心编译"
make -j${CORES} V=s 2>&1 | tee build.log

# 检查编译结果
echo "📊 编译完成检查..."
if find bin/targets -name "*.bin" -o -name "*.img" 2>/dev/null | head -1; then
    echo "🎉 编译成功！"
    
    # 显示固件大小
    echo "=== 固件大小 ==="
    find bin/targets -name "*.bin" -o -name "*.img" 2>/dev/null | while read f; do
        size_bytes=$(stat -c%s "$f" 2>/dev/null || echo "0")
        size_mb=$((size_bytes / 1024 / 1024))
        echo "$(basename $f): ${size_mb}MB"
    done
    
    echo "========================================"
    echo "✅ 固件位置: $(pwd)/bin/targets/"
    echo "📦 下一步:"
    echo "  1. 刷入路由器"
    echo "  2. 通过USB安装重型软件包"
    echo "  3. 运行: opkg install /mnt/sda1/packages/*.ipk"
else
    echo "❌ 编译失败"
    echo "查看日志: tail -50 build.log"
    exit 1
fi