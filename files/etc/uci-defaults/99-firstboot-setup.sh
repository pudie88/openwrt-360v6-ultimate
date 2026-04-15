#!/bin/sh
# 99-firstboot-setup.sh — runs once on first boot via uci-defaults

# ── 网络：LAN IP ─────────────────────────────────────────────────
uci set network.lan.ipaddr='192.168.2.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# ── 系统：主机名 + 时区 ──────────────────────────────────────────
uci set system.@system[0].hostname='OpenWrt'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

# ── NTP ──────────────────────────────────────────────────────────
if ! uci -q get system.ntp > /dev/null 2>&1; then
  uci set system.ntp='timeserver'
fi
uci -q delete system.ntp.server || true
uci add_list system.ntp.server='ntp.aliyun.com'
uci add_list system.ntp.server='ntp.tencent.com'
uci add_list system.ntp.server='cn.pool.ntp.org'
uci commit system
if [ -x /etc/init.d/sysntpd ]; then
  /etc/init.d/sysntpd restart 2>/dev/null || true
fi

# ── DHCP：调优 dnsmasq ───────────────────────────────────────────
uci set dhcp.@dnsmasq[0].cachesize='1000'
uci set dhcp.@dnsmasq[0].ednspacket_max='1232'
# AdGuardHome 运行在 3053，dnsmasq 转发到它
uci set dhcp.@dnsmasq[0].port='53'
uci add_list dhcp.@dnsmasq[0].server='127.0.0.1#3053'
uci commit dhcp

# ── CPU 超频：设为 performance governor ──────────────────────────
# IPQ6010 cpufreq 节点，开机后写入 performance 模式
# 若 governor 节点不存在（内核未加载）则静默跳过
for cpu_gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  [ -f "$cpu_gov" ] && echo performance > "$cpu_gov" 2>/dev/null || true
done
# 通过 rc.local 持久化（uci-defaults 只跑一次，但 rc.local 每次启动都跑）
mkdir -p /etc/rc.d
cat > /etc/rc.local << 'EOF'
#!/bin/sh
# CPU performance governor (IPQ6010 超频)
for cpu_gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  [ -f "$cpu_gov" ] && echo performance > "$cpu_gov" 2>/dev/null || true
done
exit 0
EOF
chmod +x /etc/rc.local

# ── Docker：创建数据目录（U盘挂载后可迁移） ──────────────────────
mkdir -p /opt/docker
# Docker daemon 配置：日志限制 + 数据目录
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "data-root": "/opt/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# ── FileBrowser：创建工作目录 ─────────────────────────────────────
mkdir -p /opt/filebrowser

exit 0
