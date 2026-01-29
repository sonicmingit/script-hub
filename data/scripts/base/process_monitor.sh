#!/bin/bash
# ===================================================
# 脚本名称: 进程监控工具
# 功能描述: 查看系统资源占用最高的进程
# 显示内容: CPU/内存占用TOP进程、僵尸进程检测
# 使用方法: curl -sL <url> | bash
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        📊 进程监控工具  📊${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 系统负载
echo -e "${YELLOW}⚡ 系统负载:${NC}"
load=$(cat /proc/loadavg 2>/dev/null)
load_1=$(echo $load | awk '{print $1}')
load_5=$(echo $load | awk '{print $2}')
load_15=$(echo $load | awk '{print $3}')
cpu_cores=$(nproc 2>/dev/null || echo 1)
echo "  1分钟:  $load_1"
echo "  5分钟:  $load_5"
echo "  15分钟: $load_15"
echo "  CPU核心: $cpu_cores"

# 判断负载是否过高
load_int=$(echo "$load_1" | cut -d. -f1)
if [ "$load_int" -gt "$cpu_cores" ]; then
    echo -e "  状态:   ${RED}负载过高!${NC}"
else
    echo -e "  状态:   ${GREEN}正常${NC}"
fi
echo ""

# CPU 占用最高的进程
echo -e "${YELLOW}🔥 CPU 占用 TOP 10:${NC}"
echo -e "${CYAN}  %CPU    PID  USER       COMMAND${NC}"
ps aux --sort=-%cpu | head -11 | tail -10 | awk '{printf "  %-6s %-5s %-10s %s\n", $3, $2, $1, $11}'
echo ""

# 内存占用最高的进程
echo -e "${YELLOW}💾 内存占用 TOP 10:${NC}"
echo -e "${CYAN}  %MEM    PID  USER       COMMAND${NC}"
ps aux --sort=-%mem | head -11 | tail -10 | awk '{printf "  %-6s %-5s %-10s %s\n", $4, $2, $1, $11}'
echo ""

# 进程统计
echo -e "${YELLOW}📈 进程统计:${NC}"
total=$(ps aux | wc -l)
running=$(ps aux | awk '$8=="R" {count++} END {print count+0}')
sleeping=$(ps aux | awk '$8~/S/ {count++} END {print count+0}')
zombie=$(ps aux | awk '$8=="Z" {count++} END {print count+0}')
echo "  总进程数: $total"
echo "  运行中:   $running"
echo "  睡眠中:   $sleeping"

if [ "$zombie" -gt 0 ]; then
    echo -e "  僵尸进程: ${RED}$zombie${NC}"
    echo ""
    echo -e "${RED}⚠️  发现僵尸进程:${NC}"
    ps aux | awk '$8=="Z" {print "  PID: " $2 " - " $11}'
else
    echo -e "  僵尸进程: ${GREEN}0${NC}"
fi
echo ""

# 长时间运行的进程
echo -e "${YELLOW}⏰ 运行时间最长的进程 TOP 5:${NC}"
echo -e "${CYAN}  ELAPSED    PID  COMMAND${NC}"
ps -eo pid,etime,comm --sort=-etime | head -6 | tail -5 | awk '{printf "  %-10s %-5s %s\n", $2, $1, $3}'
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        ✅ 监控完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}💡 提示:${NC}"
echo "  实时监控: top 或 htop"
echo "  结束进程: kill -9 <PID>"
echo ""
