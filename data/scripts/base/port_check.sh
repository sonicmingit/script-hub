#!/bin/bash
# ===================================================
# 脚本名称: 端口检测工具
# 功能描述: 检测常用端口占用情况并显示占用进程
# 使用方法: curl -sL <url> | bash
# 可选参数: curl -sL <url> | bash -s -- 8080 (检测指定端口)
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 常用端口列表
COMMON_PORTS=(22 80 443 3000 3306 5432 6379 8080 8443 9000 27017)

# 检测单个端口
check_port() {
    local port=$1
    local result=""
    
    if command -v ss &> /dev/null; then
        result=$(ss -tlnp 2>/dev/null | grep ":$port " | head -1)
    elif command -v netstat &> /dev/null; then
        result=$(netstat -tlnp 2>/dev/null | grep ":$port " | head -1)
    fi
    
    if [ -n "$result" ]; then
        # 端口被占用
        process=$(echo "$result" | grep -oP 'users:\(\("\K[^"]+' 2>/dev/null || echo "未知")
        echo -e "  ${RED}●${NC} 端口 ${YELLOW}$port${NC} ${RED}已占用${NC} - 进程: $process"
        return 1
    else
        echo -e "  ${GREEN}○${NC} 端口 ${YELLOW}$port${NC} ${GREEN}空闲${NC}"
        return 0
    fi
}

# 获取端口详细信息
get_port_details() {
    local port=$1
    echo -e "${GREEN}📋 端口 $port 详细信息:${NC}"
    
    if command -v ss &> /dev/null; then
        ss -tlnp | grep ":$port " | while read line; do
            echo "  $line"
        done
    elif command -v netstat &> /dev/null; then
        netstat -tlnp 2>/dev/null | grep ":$port " | while read line; do
            echo "  $line"
        done
    fi
    
    # 使用 lsof 获取更多信息
    if command -v lsof &> /dev/null; then
        lsof -i :$port 2>/dev/null | tail -n +2 | while read line; do
            echo "  $line"
        done
    fi
}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        🔍 端口检测工具  🔍${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否指定了端口
if [ -n "$1" ]; then
    # 检测指定端口
    echo -e "${YELLOW}检测指定端口: $1${NC}"
    echo ""
    check_port $1
    echo ""
    get_port_details $1
else
    # 检测常用端口
    echo -e "${YELLOW}检测常用端口:${NC}"
    echo ""
    
    occupied=0
    free=0
    
    for port in "${COMMON_PORTS[@]}"; do
        if check_port $port; then
            ((free++))
        else
            ((occupied++))
        fi
    done
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  📊 统计: ${GREEN}空闲 $free${NC} | ${RED}占用 $occupied${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

echo ""
echo -e "${YELLOW}💡 提示:${NC}"
echo "  检测指定端口: curl -sL <url> | bash -s -- 8080"
echo "  查看所有监听端口: ss -tlnp 或 netstat -tlnp"
echo ""
