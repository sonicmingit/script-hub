#!/bin/bash
# ==============================================================================
# 脚本名称: Docker 私有仓库信任自动配置工具
# 
# 功能描述:
#   本脚本用于自动将私有镜像仓库（HTTP协议）添加到 Docker 的信任列表
#   (insecure-registries) 中，解决推送镜像时出现的 "http: server gave HTTP
#   response to HTTPS client" 报错问题。
#
# 核心特性:
#   1. ✅ 安全无损：使用 Python 标准库解析 JSON，完美保留 daemon.json 中原有的
#         其他配置（如国内镜像加速器、日志配置等），避免 sed 暴力修改导致格式错误。
#   2. 🔄 幂等性：支持多次运行，自动检测去重，不会重复添加相同地址。
#   3. ⚡ 即时生效：配置完成后自动重载 Docker 服务，并筛选 docker info 结果进行验证。
#
# 使用说明:
#   1. 修改下方 [配置区域] 中的 REGISTRY_URL 变量为你实际的仓库地址。
#   2. 赋予执行权限: chmod +x setup_registry.sh
#   3. 运行脚本: ./setup_registry.sh
#
# 依赖环境:
#   - Python 3.x (Linux 系统通常默认内置)
#   - Docker Engine
#   - sudo 权限
# ==============================================================================

# =================配置区域=================
# [请在此处修改你的私有仓库地址]
REGISTRY_URL="10.0.1.30:12375"

# Docker 配置文件路径 (通常不需要修改)
CONFIG_FILE="/etc/docker/daemon.json"
# =========================================

echo "🚀 开始配置 Docker 信任私有仓库: $REGISTRY_URL ..."

# 1. 检查或创建配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📄 配置文件不存在，正在创建新文件..."
    echo "{ \"insecure-registries\": [\"$REGISTRY_URL\"] }" | sudo tee "$CONFIG_FILE" > /dev/null
else
    echo "📄 配置文件已存在，正在安全追加配置..."
    # 使用 Python 安全插入配置，避免破坏原有 JSON 结构
    sudo python3 -c "
import json
import os

target = '$REGISTRY_URL'
path = '$CONFIG_FILE'

try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

# 确保键存在
if 'insecure-registries' not in data:
    data['insecure-registries'] = []

# 追加地址（去重）
current_list = data['insecure-registries']
if target not in current_list:
    current_list.append(target)
    print(f'➕ 已添加规则: {target}')
else:
    print(f'✅ 规则已存在: {target} (跳过)')

# 写入文件
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
"
fi

# 2. 重载 Docker 服务
echo "🔄 正在重载 Docker 服务..."
if sudo systemctl reload docker; then
    echo "✅ Docker 重载成功！"
    
    echo ""
    echo "================= 验证结果 ================="
    # 3. 自动筛选并显示配置结果 (-A 5 表示显示匹配行及其后5行)
    sudo docker info 2>/dev/null | grep -A 5 "Insecure Registries"
    echo "============================================"
    
    # 简单的逻辑判断给用户反馈
    if sudo docker info 2>/dev/null | grep -q "$REGISTRY_URL"; then
        echo "🎉 验证通过！配置已生效。"
        echo "💡 使用提示：现在你可以使用 'docker push $REGISTRY_URL/你的镜像名' 推送镜像了。"
    else
        echo "❌ 警告：未在 docker info 中检测到该地址，请检查 Docker 是否正常重启。"
    fi
else
    echo "❌ Docker 重载失败，请检查配置文件格式 /etc/docker/daemon.json"
    exit 1
fi