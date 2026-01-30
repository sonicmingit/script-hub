#!/bin/bash
# 一键更换 Docker 镜像源配置
# 功能描述：交互式输入 Docker 镜像源地址，自动更新 /etc/docker/daemon.json
# 默认镜像源：DaoCloud、1ms.run
# 注意事项：需要 root 权限执行，修改后会自动重启 Docker 服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认镜像源
DEFAULT_MIRRORS='["https://docker.m.daocloud.io","https://docker.1ms.run"]'

echo ""
echo -e "${CYAN}========== 一键更换 Docker 镜像源 ==========${NC}"
echo ""

# 检查是否有 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误：需要 root 权限才能修改 Docker 配置${NC}"
    echo -e "请使用 ${CYAN}sudo${NC} 或以 root 用户运行此脚本"
    exit 1
fi

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误：未检测到 Docker，请先安装 Docker${NC}"
    exit 1
fi

# 显示当前配置
DAEMON_JSON="/etc/docker/daemon.json"
echo -e "${YELLOW}当前 Docker 镜像源配置：${NC}"
if [ -f "$DAEMON_JSON" ]; then
    if command -v jq &> /dev/null; then
        jq '.["registry-mirrors"] // "未配置"' "$DAEMON_JSON" 2>/dev/null || cat "$DAEMON_JSON"
    else
        grep -o '"registry-mirrors"[^]]*]' "$DAEMON_JSON" 2>/dev/null || echo "  (无镜像源配置)"
    fi
else
    echo "  daemon.json 文件不存在（将创建）"
fi
echo ""

# 读取用户输入
echo -e "${CYAN}请输入新的镜像源地址（多个用空格分隔）${NC}"
echo -e "${YELLOW}直接回车使用默认：${NC}"
echo "  - https://docker.m.daocloud.io"
echo "  - https://docker.1ms.run"
echo ""
read -p "输入镜像源: " INPUT_MIRRORS </dev/tty

# 处理镜像源
if [ -z "$INPUT_MIRRORS" ]; then
    MIRRORS_JSON=$DEFAULT_MIRRORS
    echo -e "${GREEN}使用默认镜像源${NC}"
else
    # 将空格分隔的 URL 转换为 JSON 数组
    MIRRORS_JSON='['
    FIRST=true
    for mirror in $INPUT_MIRRORS; do
        if [ "$FIRST" = true ]; then
            MIRRORS_JSON+="\"$mirror\""
            FIRST=false
        else
            MIRRORS_JSON+=",\"$mirror\""
        fi
    done
    MIRRORS_JSON+=']'
fi

echo ""
echo -e "${YELLOW}准备设置镜像源：${NC}$MIRRORS_JSON"
echo ""

# 备份原配置
if [ -f "$DAEMON_JSON" ]; then
    BACKUP_FILE="${DAEMON_JSON}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$DAEMON_JSON" "$BACKUP_FILE"
    echo -e "${GREEN}✓${NC} 已备份原配置到：$BACKUP_FILE"
fi

# 确保目录存在
mkdir -p /etc/docker

# 更新或创建 daemon.json
if [ -f "$DAEMON_JSON" ] && command -v jq &> /dev/null; then
    # 使用 jq 合并配置（保留其他设置）
    TMP_FILE=$(mktemp)
    jq --argjson mirrors "$MIRRORS_JSON" '.["registry-mirrors"] = $mirrors' "$DAEMON_JSON" > "$TMP_FILE"
    mv "$TMP_FILE" "$DAEMON_JSON"
else
    # 直接写入新配置
    cat > "$DAEMON_JSON" << EOF
{
  "registry-mirrors": $MIRRORS_JSON
}
EOF
fi

echo -e "${GREEN}✓${NC} 配置文件已更新"

# 显示最终配置
echo ""
echo -e "${YELLOW}最终配置内容：${NC}"
cat "$DAEMON_JSON"
echo ""

# 重启 Docker 服务
echo -e "${YELLOW}正在重启 Docker 服务...${NC}"
if systemctl restart docker 2>/dev/null; then
    echo -e "${GREEN}✅ Docker 服务已重启！${NC}"
elif service docker restart 2>/dev/null; then
    echo -e "${GREEN}✅ Docker 服务已重启！${NC}"
else
    echo -e "${RED}⚠ Docker 重启失败，请手动执行：systemctl restart docker${NC}"
    exit 1
fi

# 验证配置
echo ""
echo -e "${YELLOW}验证 Docker 配置...${NC}"
sleep 2
if docker info 2>/dev/null | grep -q "Registry Mirrors"; then
    echo -e "${GREEN}✅ 镜像源配置已生效：${NC}"
    docker info 2>/dev/null | grep -A 5 "Registry Mirrors" | head -6
else
    echo -e "${YELLOW}⚠ 无法确认镜像源是否生效，请手动验证：docker info | grep -A 5 'Registry Mirrors'${NC}"
fi

echo ""
echo -e "${GREEN}完成！${NC}"
echo ""
