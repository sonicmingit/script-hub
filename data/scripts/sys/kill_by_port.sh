#!/bin/bash
# 端口进程查杀工具
# 功能描述：输入端口号，查询占用该端口的进程信息，并提供杀死进程的选项
# 使用方法：curl -sL <url> | bash，然后根据提示输入端口号
# 适用系统：Linux (需要 lsof 或 ss 命令)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}========== 端口进程查杀工具 ==========${NC}"
echo ""

# 读取端口号
read -p "请输入要查询的端口号: " PORT </dev/tty

# 验证输入是否为数字
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}错误：请输入有效的端口号（纯数字）${NC}"
    exit 1
fi

# 查找占用端口的进程
echo ""
echo -e "${YELLOW}正在查询端口 $PORT 的占用情况...${NC}"
echo ""

# 优先使用 lsof，如果没有则使用 ss
if command -v lsof &> /dev/null; then
    PROCESS_INFO=$(lsof -i :$PORT -t 2>/dev/null)
    if [ -n "$PROCESS_INFO" ]; then
        PID=$(echo "$PROCESS_INFO" | head -n 1)
        # 获取详细进程信息
        DETAIL=$(ps -p $PID -o pid,ppid,user,%cpu,%mem,stat,start,time,comm --no-headers 2>/dev/null)
        CMDLINE=$(ps -p $PID -o args --no-headers 2>/dev/null)
    fi
elif command -v ss &> /dev/null; then
    # 使用 ss 命令获取 PID
    PROCESS_INFO=$(ss -tlnp | grep ":$PORT " | grep -oP 'pid=\K[0-9]+' | head -n 1)
    if [ -n "$PROCESS_INFO" ]; then
        PID=$PROCESS_INFO
        DETAIL=$(ps -p $PID -o pid,ppid,user,%cpu,%mem,stat,start,time,comm --no-headers 2>/dev/null)
        CMDLINE=$(ps -p $PID -o args --no-headers 2>/dev/null)
    fi
else
    echo -e "${RED}错误：未找到 lsof 或 ss 命令，无法查询端口${NC}"
    exit 1
fi

# 判断是否找到进程
if [ -z "$PID" ]; then
    echo -e "${GREEN}端口 $PORT 目前没有被任何进程占用。${NC}"
    exit 0
fi

# 显示进程信息
echo -e "${GREEN}找到占用端口 $PORT 的进程：${NC}"
echo ""
echo -e "  ${CYAN}PID:${NC}       $PID"
echo -e "  ${CYAN}详情:${NC}      $DETAIL"
echo -e "  ${CYAN}命令行:${NC}    $CMDLINE"
echo ""

# 询问是否杀死
read -p "是否杀死该进程？(y/N): " CONFIRM </dev/tty

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}正在终止进程 $PID ...${NC}"
    
    # 先尝试优雅终止
    kill $PID 2>/dev/null
    
    sleep 1
    
    # 检查进程是否还在
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${YELLOW}进程未响应，尝试强制终止 (kill -9)...${NC}"
        kill -9 $PID 2>/dev/null
        sleep 1
    fi
    
    # 最终检查
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${RED}进程终止失败，可能需要 root 权限。${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ 进程 $PID 已成功终止！${NC}"
    fi
else
    echo -e "${CYAN}已取消操作。${NC}"
fi

echo ""
