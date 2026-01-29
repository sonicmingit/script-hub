#!/bin/bash
# ===================================================
# 脚本名称: 磁盘清理工具
# 功能描述: 清理系统临时文件和缓存，释放磁盘空间
# 清理内容: 系统缓存、日志、临时文件、包管理器缓存
# 使用方法: curl -sL <url> | bash
# 注意事项: 建议使用 root 权限运行以获得最佳清理效果
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠️  建议使用 root 权限运行以获得最佳清理效果${NC}"
        echo ""
    fi
}

# 获取磁盘使用情况
get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}'
}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        🧹 磁盘清理工具  🧹${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

check_root

# 清理前空间
echo -e "${YELLOW}📊 清理前磁盘使用: $(get_disk_usage)${NC}"
echo ""

# 统计释放空间
freed=0

# 1. 清理系统临时文件
echo -e "${GREEN}🗑️  清理临时文件...${NC}"
if [ -d /tmp ]; then
    tmp_size=$(du -sh /tmp 2>/dev/null | cut -f1)
    find /tmp -type f -atime +7 -delete 2>/dev/null
    echo "   已清理 /tmp 中超过7天的文件"
fi

if [ -d /var/tmp ]; then
    find /var/tmp -type f -atime +7 -delete 2>/dev/null
    echo "   已清理 /var/tmp 中超过7天的文件"
fi

# 2. 清理系统日志
echo -e "${GREEN}📋 清理旧日志...${NC}"
if [ -d /var/log ]; then
    # 清理旧的压缩日志
    find /var/log -name "*.gz" -delete 2>/dev/null
    find /var/log -name "*.old" -delete 2>/dev/null
    find /var/log -name "*.[0-9]" -delete 2>/dev/null
    echo "   已清理压缩和轮转的旧日志"
fi

# 使用 journalctl 清理（如果存在）
if command -v journalctl &> /dev/null; then
    journalctl --vacuum-time=7d 2>/dev/null
    echo "   已清理超过7天的 journald 日志"
fi

# 3. 清理包管理器缓存
echo -e "${GREEN}📦 清理包管理器缓存...${NC}"

# APT (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    apt-get clean 2>/dev/null
    apt-get autoclean 2>/dev/null
    echo "   已清理 APT 缓存"
fi

# YUM/DNF (CentOS/RHEL/Fedora)
if command -v yum &> /dev/null; then
    yum clean all 2>/dev/null
    echo "   已清理 YUM 缓存"
elif command -v dnf &> /dev/null; then
    dnf clean all 2>/dev/null
    echo "   已清理 DNF 缓存"
fi

# 4. 清理用户缓存
echo -e "${GREEN}👤 清理用户缓存...${NC}"
if [ -d ~/.cache ]; then
    cache_size=$(du -sh ~/.cache 2>/dev/null | cut -f1)
    # 只清理超过30天的缓存
    find ~/.cache -type f -atime +30 -delete 2>/dev/null
    echo "   已清理用户缓存中超过30天的文件"
fi

# 5. 清理缩略图缓存
if [ -d ~/.cache/thumbnails ]; then
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    echo "   已清理缩略图缓存"
fi

echo ""
echo -e "${YELLOW}📊 清理后磁盘使用: $(get_disk_usage)${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        ✅ 清理完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
