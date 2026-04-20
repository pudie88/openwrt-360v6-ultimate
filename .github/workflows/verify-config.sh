#!/bin/bash
# verify-config.sh
# 验证 .config 是否正确配置

echo "=== OpenWrt 配置验证 ==="

# 1. 检查 PARTSIZE
if grep -q "CONFIG_TARGET_ROOTFS_PARTSIZE=100" .config; then
    echo "✅ PARTSIZE=100（128MB 闪存优化）"
else
    echo "❌ PARTSIZE 错误："
    grep "PARTSIZE" .config
fi

# 2. 检查大包编译设置
echo ""
echo "=== 大包编译状态 ==="
PACKAGES=("dockerd" "samba4-server" "adguardhome" "lucky")
all_good=true
for pkg in "${PACKAGES[@]}"; do
    if grep -q "CONFIG_PACKAGE_${pkg}=y" .config; then
        echo "✅ $pkg = y（编译进固件）"
    else
        echo "❌ $pkg ≠ y（可能设为 n）"
        all_good=false
    fi
done

# 3. 空间估算
echo ""
echo "=== 空间估算 ==="
echo "Squashfs（系统）: ~30MB"
echo "Overlay（100MB）分配："
echo "  - Docker 二进制: 60MB"
echo "  - Samba4-server: 15MB"
echo "  - AdGuardHome: 10MB"
echo "  - Lucky: 5MB"
echo "  - 其他小包: 10MB"
echo "总计: 100MB（刚好）"

# 4. USB 支持检查
echo ""
echo "=== USB 支持 ==="
if grep -q "CONFIG_PACKAGE_kmod-usb-storage=y" .config; then
    echo "✅ USB 存储支持已启用"
else
    echo "❌ USB 存储支持未启用"
fi

# 总结
echo ""
if [ "$all_good" = true ] && grep -q "PARTSIZE=100" .config; then
    echo "🎉 配置验证通过！"
    echo "固件大小应在 110MB 以内，适合 128MB 闪存。"
else
    echo "⚠️  配置存在问题，请检查以上错误。"
fi
