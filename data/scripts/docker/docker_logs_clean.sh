#!/bin/bash
# Docker 日志清理脚本
# 功能描述：一键清空所有 Docker 容器的日志文件，释放磁盘空间
# 使用方法：curl -sL <url> | sudo bash
# 注意事项：需要 root 权限执行

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}========== Docker 日志清理 ==========${NC}"
echo ""

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误：需要 root 权限执行${NC}"
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误：Docker 未安装${NC}"
    exit 1
fi

# 初始化统计
total_size=0
cleaned_count=0

# 查找所有容器日志
logs=$(find /var/lib/docker/containers/ -name "*-json.log" 2>/dev/null)

if [ -z "$logs" ]; then
    echo -e "${YELLOW}未找到任何 Docker 容器日志${NC}"
    exit 0
fi

echo -e "${YELLOW}正在清理容器日志...${NC}"
echo ""

for log in $logs; do
    # 获取容器 ID
    container_id=$(basename $(dirname $log) | cut -c 1-12)
    
    # 获取容器名称
    container_name=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep "^$container_id" | awk '{print $2}')
    
    # 获取日志大小
    log_size=$(du -sh "$log" 2>/dev/null | awk '{print $1}')
    log_bytes=$(du -b "$log" 2>/dev/null | awk '{print $1}')
    
    if [ -n "$log_bytes" ] && [ "$log_bytes" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} $container_name ($container_id) - ${YELLOW}$log_size${NC}"
        
        # 清空日志
        cat /dev/null > "$log"
        
        total_size=$((total_size + log_bytes))
        cleaned_count=$((cleaned_count + 1))
    fi
done

echo ""
echo -e "${CYAN}==========================================${NC}"
echo -e "${GREEN}✅ 清理完成！${NC}"
echo -e "  清理容器数: ${YELLOW}$cleaned_count${NC}"
echo -e "  释放空间:   ${YELLOW}$(numfmt --to=iec $total_size 2>/dev/null || echo "${total_size} bytes")${NC}"
echo ""