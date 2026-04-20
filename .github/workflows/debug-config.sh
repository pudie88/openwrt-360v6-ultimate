#!/bin/bash
# debug-config.sh
# 调试 .config 文件问题

echo "=== 调试信息 ==="
echo "当前目录: $(pwd)"
echo "文件存在: $(ls -la .config 2>/dev/null && echo '是' || echo '否')"
echo "文件大小: $(stat -c%s .config 2>/dev/null || echo 'N/A') bytes"
echo "文件权限: $(ls -la .config 2>/dev/null | awk '{print $1}')"

echo ""
echo "=== 文件内容检查（前10行）==="
head -10 .config 2>/dev/null | cat -A || echo "无法读取文件"

echo ""
echo "=== 查找 USB 配置 ==="
grep -n -i "usb" .config 2>/dev/null || echo "未找到 USB 配置"

echo ""
echo "=== 严格查找 CONFIG_PACKAGE_kmod-usb-storage=y ==="
# 多种查找方式
echo "1. 精确查找:"
grep -n "^CONFIG_PACKAGE_kmod-usb-storage=y" .config 2>/dev/null || echo "  未找到（精确）"

echo "2. 宽松查找:"
grep -n "CONFIG_PACKAGE_kmod-usb-storage=y" .config 2>/dev/null || echo "  未找到（宽松）"

echo "3. 查看第95行附近:"
sed -n '90,100p' .config 2>/dev/null || echo "  无法读取"

echo ""
echo "=== 文件编码检查 ==="
file .config 2>/dev/null || echo "file 命令不可用"
hexdump -C .config | head -5 2>/dev/null || echo "hexdump 不可用"
