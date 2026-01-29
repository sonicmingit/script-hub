#!/bin/bash
# ===================================================
# Script Hub - 脚本列表 (非交互式 v1.3)
# ===================================================

SERVER_URL="__SERVER_URL__"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# 创建临时文件
JSON_FILE=$(mktemp)
trap "rm -f $JSON_FILE" EXIT

# 获取数据到文件
curl -s --connect-timeout 5 "${SERVER_URL}/api/cli" -o "$JSON_FILE"

if [ $? -ne 0 ] || [ ! -s "$JSON_FILE" ]; then
    echo -e "${RED}❌ 无法从服务器获取数据: ${SERVER_URL}${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}        📜 Script Hub - 脚本一览表${NC}"
echo -e "${CYAN}        服务器: ${SERVER_URL}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 使用 Python 从文件可靠读取 JSON
python3 -c "
import json, sys
try:
    with open('$JSON_FILE', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if not data.get('success'):
        print('\033[0;31m服务器返回失败: ' + str(data.get('error', '未知错误')) + '\033[0m')
        sys.exit(1)
    
    categories = data.get('data', {})
    if not categories:
        print('  没有任何脚本。')
        sys.exit(0)

    for cat_name in sorted(categories.keys()):
        # 过滤掉非法分类
        display_cat = cat_name if cat_name and cat_name != 'undefined' else '未分类'
        print(f'\033[1;33m[{display_cat}]\033[0m')
        
        scripts = categories[cat_name]
        for s in scripts:
            # 安全获取字段
            name = s.get('name', '未命名')
            path = s.get('path')
            ext = s.get('extension', '')
            desc = s.get('description', '')
            
            if not path:
                continue
                
            raw_url = f'${SERVER_URL}/raw/{path}'
            
            # 根据后缀生成一键命令
            cmd = ''
            if ext == '.sh':
                cmd = f'curl -sL {raw_url} | bash'
            elif ext == '.py':
                cmd = f'curl -sL {raw_url} | python3'
            else:
                cmd = f'wget {raw_url}'
            
            print(f'  \033[0;32m• {name}\033[0m')
            if desc:
                # 处理多行描述，只取第一行
                first_line_desc = desc.split('\n')[0]
                print(f'    \033[0;90m{first_line_desc}\033[0m')
            print(f'    \033[0;36m{cmd}\033[0m')
            print('')
except Exception as e:
    print(f'\033[0;31m解析出错: {str(e)}\033[0m')
    # 打印部分原始数据用于排错
    try:
        with open('$JSON_FILE', 'r') as f:
            print('\033[0;90m原始数据预览: ' + f.read()[:100] + '...\033[0m')
    except:
        pass
"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}提示: 直接复制蓝色命令到终端即可执行。${NC}"
echo ""
