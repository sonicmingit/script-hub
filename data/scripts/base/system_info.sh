#!/bin/bash
# ===================================================
# 脚本名称: 系统信息查看工具
# 功能描述: 一键查看服务器关键系统信息
# 包含信息: 主机名、系统版本、内核、CPU、内存、磁盘、网络
# 使用方法: curl -sL <url> | bash
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 分隔线
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 标题
print_header() {
    echo -e "${GREEN}$1${NC}"
}

echo ""
print_separator
echo -e "${GREEN}        🖥️  系统信息查看工具  🖥️${NC}"
print_separator
echo ""

# 基本信息
print_header "📍 基本信息"
echo "  主机名:     $(hostname)"
echo "  当前用户:   $(whoami)"
echo "  当前时间:   $(date '+%Y-%m-%d %H:%M:%S')"
echo "  运行时长:   $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo ""

# 系统版本
print_header "🐧 系统版本"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  发行版:     $PRETTY_NAME"
elif [ -f /etc/redhat-release ]; then
    echo "  发行版:     $(cat /etc/redhat-release)"
else
    echo "  发行版:     未知"
fi
echo "  内核版本:   $(uname -r)"
echo "  系统架构:   $(uname -m)"
echo ""

# CPU 信息
print_header "⚡ CPU 信息"
if [ -f /proc/cpuinfo ]; then
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    cpu_cores=$(grep -c "processor" /proc/cpuinfo)
    echo "  型号:       $cpu_model"
    echo "  核心数:     $cpu_cores"
fi
# CPU 使用率
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' 2>/dev/null || echo "N/A")
echo "  使用率:     ${cpu_usage}%"
echo ""

# 内存信息
print_header "💾 内存信息"
if command -v free &> /dev/null; then
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_used=$(free -h | awk '/^Mem:/ {print $3}')
    mem_available=$(free -h | awk '/^Mem:/ {print $7}')
    mem_percent=$(free | awk '/^Mem:/ {printf("%.1f", $3/$2 * 100)}')
    echo "  总内存:     $mem_total"
    echo "  已使用:     $mem_used (${mem_percent}%)"
    echo "  可用:       $mem_available"
fi
echo ""

# 磁盘信息
print_header "💿 磁盘信息"
df -h | grep -E '^/dev/' | awk '{printf "  %-12s %6s / %-6s (%s)\n", $1, $3, $2, $5}'
echo ""

# 网络信息
print_header "🌐 网络信息"
# 获取主要网卡 IP
if command -v ip &> /dev/null; then
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | while read ip; do
        echo "  本机IP:     $ip"
    done
elif command -v ifconfig &> /dev/null; then
    ifconfig | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | while read ip; do
        echo "  本机IP:     $ip"
    done
fi
# 外网 IP
public_ip=$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || curl -s --connect-timeout 3 icanhazip.com 2>/dev/null || echo "获取失败")
echo "  公网IP:     $public_ip"
echo ""

print_separator
echo -e "${GREEN}        ✅ 信息收集完成${NC}"
print_separator
echo ""
