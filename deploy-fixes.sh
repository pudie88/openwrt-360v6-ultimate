#!/bin/bash
# deploy-fixes.sh
# 自动部署修复文件到当前目录

set -e

echo "=== OpenWrt 360 V6 修复部署脚本 ==="

# 检查目标目录
if [ ! -f ".git/config" ] && [ ! -f "README.md" ]; then
    echo "⚠️  当前目录可能不是 OpenWrt 项目根目录"
    read -p "继续？(y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# 备份原文件
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
echo "备份原文件到: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -f .config "$BACKUP_DIR/" 2>/dev/null || true
cp -f .github/workflows/openwrt-builder.yml "$BACKUP_DIR/" 2>/dev/null || true
[ -d "files" ] && cp -rf "files" "$BACKUP_DIR/" 2>/dev/null || true

# 部署新文件
echo "部署新配置..."
cp -f ../openwrt_fix_package/.config .config
cp -f ../openwrt_fix_package/openwrt-builder.yml .github/workflows/openwrt-builder.yml

echo "部署预置文件..."
mkdir -p files/etc/uci-defaults files/etc/sysctl.d files/root
cp -rf ../openwrt_fix_package/files/* files/

echo "设置脚本权限..."
chmod +x files/etc/uci-defaults/*

echo "✅ 部署完成！"
echo ""
echo "下一步操作："
echo "1. 检查文件: git status"
echo "2. 提交更改: git add . && git commit -m '修复: 优化固件大小，添加USB存储支持'"
echo "3. 推送并触发构建: git push"
echo ""
echo "重要：确保 .config 中的大包都设为 y（已编译进固件）"
