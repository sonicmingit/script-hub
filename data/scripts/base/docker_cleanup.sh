#!/bin/bash
# ===================================================
# 脚本名称: Docker 清理工具
# 功能描述: 清理 Docker 未使用的资源，释放磁盘空间
# 清理内容: 停止的容器、悬空镜像、未使用的网络和卷
# 使用方法: curl -sL <url> | bash
# 注意事项: 会删除未使用的资源，请确认后再运行
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ 错误: Docker 未安装${NC}"
        exit 1
    fi
    
    # 检查 Docker 服务是否运行
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ 错误: Docker 服务未运行${NC}"
        exit 1
    fi
}

# 获取 Docker 磁盘使用
get_docker_usage() {
    docker system df 2>/dev/null | tail -n +2 | awk '{total += $4} END {print total}'
}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        🐳 Docker 清理工具  🐳${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

check_docker

# 显示清理前状态
echo -e "${YELLOW}📊 清理前 Docker 磁盘使用:${NC}"
docker system df
echo ""

# 1. 删除停止的容器
echo -e "${GREEN}🗑️  清理停止的容器...${NC}"
stopped=$(docker ps -aq -f status=exited | wc -l)
if [ "$stopped" -gt 0 ]; then
    docker container prune -f
    echo "   已删除 $stopped 个停止的容器"
else
    echo "   没有停止的容器需要清理"
fi

# 2. 删除悬空镜像
echo -e "${GREEN}🖼️  清理悬空镜像...${NC}"
dangling=$(docker images -q -f dangling=true | wc -l)
if [ "$dangling" -gt 0 ]; then
    docker image prune -f
    echo "   已删除 $dangling 个悬空镜像"
else
    echo "   没有悬空镜像需要清理"
fi

# 3. 删除未使用的网络
echo -e "${GREEN}🌐 清理未使用的网络...${NC}"
docker network prune -f 2>/dev/null
echo "   已清理未使用的网络"

# 4. 删除未使用的卷（可选，默认不删除）
echo -e "${YELLOW}💾 未使用的卷:${NC}"
unused_volumes=$(docker volume ls -q -f dangling=true | wc -l)
if [ "$unused_volumes" -gt 0 ]; then
    echo "   发现 $unused_volumes 个未使用的卷"
    echo "   如需删除，请手动运行: docker volume prune -f"
else
    echo "   没有未使用的卷"
fi

# 5. 清理构建缓存
echo -e "${GREEN}🔧 清理构建缓存...${NC}"
docker builder prune -f 2>/dev/null
echo "   已清理构建缓存"

echo ""
echo -e "${YELLOW}📊 清理后 Docker 磁盘使用:${NC}"
docker system df
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        ✅ Docker 清理完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 提示更激进的清理方式
echo -e "${YELLOW}💡 提示: 如需更彻底的清理，可运行:${NC}"
echo "   docker system prune -a --volumes -f"
echo "   (⚠️ 这将删除所有未使用的镜像和卷)"
echo ""
