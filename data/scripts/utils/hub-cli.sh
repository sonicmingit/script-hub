#!/bin/bash
# ===================================================
# Script Hub - 独立命令行客户端 (v1.1)
# ===================================================

SERVER_URL="$1"
if [ -z "$SERVER_URL" ]; then
    echo "使用方法: bash hub-cli.sh <服务器地址>"
    echo "示例: bash hub-cli.sh http://10.0.10.1:7524"
    exit 1
fi

# 确保最后没有斜杠
SERVER_URL="${SERVER_URL%/}"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

JSON_DATA=""

# 获取数据
fetch_data() {
    JSON_DATA=$(curl -s --connect-timeout 5 "${SERVER_URL}/api/cli")
    if [ $? -ne 0 ] || [ -z "$JSON_DATA" ]; then
        echo -e "${RED}❌ 无法连接到服务器${NC}"
        exit 1
    fi
}

# Python 交互辅助函数
py_cmd() {
    python3 -c "
import json, sys
try:
    data = json.loads('''$JSON_DATA''')
    $1
except Exception as e:
    pass
"
}

main_menu() {
    while true; do
        clear
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}        📜 Script Hub - 命令行客户端${NC}"
        echo -e "${CYAN}        服务器: ${SERVER_URL}${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}📂 全部脚本分类:${NC}"
        
        # 获取分类
        local cats=$(python3 -c "
import json
data = json.loads('''$JSON_DATA''')
for i, cat in enumerate(sorted(data['data'].keys()), 1):
    count = len(data['data'][cat])
    print(f'{i}|{cat}|{count}')
")

        if [ -z "$cats" ]; then
            echo "没有找到任何分类"
            exit 1
        fi

        # 显示分类
        local cat_names=()
        while IFS='|' read -r idx name count; do
            cat_names+=("$name")
            echo -e "  ${GREEN}$idx.${NC} $name ${CYAN}($count 个脚本)${NC}"
        done <<< "$cats"

        echo ""
        echo -e "  ${RED}0. 退出${NC}"
        echo ""
        read -p "请输入选项: " choice
        
        if [[ "$choice" == "0" ]]; then exit 0; fi
        
        # 验证
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#cat_names[@]}" ]; then
            continue
        fi

        script_menu "${cat_names[$((choice-1))]}"
    done
}

script_menu() {
    local cat="$1"
    while true; do
        clear
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}📂 分类: ${GREEN}$cat${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # 获取该分类下的脚本
        local scripts=$(python3 -c "
import json
data = json.loads('''$JSON_DATA''')
items = data['data'].get('$cat', [])
for i, s in enumerate(items, 1):
    desc = s.get('description', '')[:40]
    print(f\"{i}|{s['name']}|{s['path']}|{s['extension']}|{desc}\")
")

        local paths=()
        local exts=()
        local names=()
        while IFS='|' read -r idx sname spath sext sdesc; do
            paths+=("$spath")
            exts+=("$sext")
            names+=("$sname")
            desc_text=""
            if [ -n "$sdesc" ]; then desc_text=" - $sdesc"; fi
            echo -e "  ${GREEN}$idx.${NC} $sname${CYAN}$desc_text${NC}"
        done <<< "$scripts"

        echo ""
        echo -e "  ${RED}0. 返回上级${NC}"
        echo ""
        read -p "请选择脚本: " s_choice

        if [[ "$s_choice" == "0" ]]; then break; fi
        if ! [[ "$s_choice" =~ ^[0-9]+$ ]] || [ "$s_choice" -lt 1 ] || [ "$s_choice" -gt "${#paths[@]}" ]; then
            continue
        fi

        local sel_path="${paths[$((s_choice-1))]}"
        local sel_ext="${exts[$((s_choice-1))]}"
        local sel_name="${names[$((s_choice-1))]}"
        
        run_script "$sel_name" "$sel_path" "$sel_ext"
    done
}

run_script() {
    local name="$1"
    local path="$2"
    local ext="$3"
    local url="${SERVER_URL}/api/raw/${path}"
    
    local cmd=""
    if [[ "$ext" == ".sh" ]]; then
        cmd="curl -sL '$url' | bash"
    elif [[ "$ext" == ".py" ]]; then
        cmd="curl -sL '$url' | python3"
    else
        cmd="wget '$url'"
    fi

    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 准备执行: ${GREEN}$name${NC}"
    echo -e "${CYAN}命令: $cmd${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1. 立即运行"
    echo "2. 仅显示命令"
    echo "0. 取消"
    echo ""
    read -p "请选择操作: " op

    if [[ "$op" == "1" ]]; then
        echo ""
        echo -e "${YELLOW}--- 执行开始 ---${NC}"
        eval "$cmd"
        echo -e "${YELLOW}--- 执行结束 ---${NC}"
        echo ""
        read -p "按回车键继续..."
    elif [[ "$op" == "2" ]]; then
        echo ""
        echo -e "${GREEN}$cmd${NC}"
        echo ""
        read -p "按回车键继续..."
    fi
}

echo "正在连接服务器..."
fetch_data
main_menu
