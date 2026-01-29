#!/bin/bash
# ===================================================
# 脚本名称: 目录备份工具
# 功能描述: 将指定目录打包备份，支持压缩和时间戳命名
# 使用方法: curl -sL <url> | bash -s -- /path/to/backup
# 参数说明: 第一个参数为要备份的目录路径
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查参数
if [ -z "$1" ]; then
    echo ""
    echo -e "${RED}❌ 错误: 请指定要备份的目录${NC}"
    echo ""
    echo "使用方法:"
    echo "  curl -sL <url> | bash -s -- /path/to/backup"
    echo "  curl -sL <url> | bash -s -- /path/to/backup /path/to/dest"
    echo ""
    exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="${2:-$(pwd)}"  # 默认备份到当前目录

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ 错误: 目录不存在: $SOURCE_DIR${NC}"
    exit 1
fi

# 生成备份文件名
DIR_NAME=$(basename "$SOURCE_DIR")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="${DIR_NAME}_backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="$DEST_DIR/$BACKUP_NAME"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        📦 目录备份工具  📦${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}📋 备份信息:${NC}"
echo "  源目录:     $SOURCE_DIR"
echo "  目标位置:   $DEST_DIR"
echo "  备份文件:   $BACKUP_NAME"
echo ""

# 获取源目录大小
SOURCE_SIZE=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1)
echo -e "${YELLOW}📊 源目录大小: $SOURCE_SIZE${NC}"
echo ""

# 确认备份
echo -e "${YELLOW}开始备份...${NC}"
echo ""

# 执行备份
START_TIME=$(date +%s)

# 使用 tar 进行备份
if tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # 获取备份文件大小
    BACKUP_SIZE=$(du -sh "$BACKUP_PATH" 2>/dev/null | cut -f1)
    
    echo -e "${GREEN}✅ 备份成功!${NC}"
    echo ""
    echo -e "${YELLOW}📋 备份结果:${NC}"
    echo "  备份文件: $BACKUP_PATH"
    echo "  原始大小: $SOURCE_SIZE"
    echo "  压缩后:   $BACKUP_SIZE"
    echo "  耗时:     ${DURATION}秒"
    
    # 计算压缩率
    if command -v bc &> /dev/null; then
        # 需要更精确的计算时使用
        echo ""
    fi
else
    echo -e "${RED}❌ 备份失败!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        ✅ 备份完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}💡 提示:${NC}"
echo "  解压命令: tar -xzf $BACKUP_NAME"
echo "  查看内容: tar -tzf $BACKUP_NAME"
echo ""
