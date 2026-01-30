#!/bin/bash
# Docker 容器 ID 查名称工具
# 功能描述：根据容器 ID 前12位查询对应的容器名称
# 使用方法：curl -sL <url> | bash
# 注意事项：需要输入容器 ID

# 提示用户输入容器 ID
read -p "请输入容器的ID（前12位）: " container_id

# 截取前12位
short_id=$(echo $container_id | cut -c 1-12)

# 查询容器名称
container_name=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep "^$short_id" | awk '{print $2}')

# 判断是否找到了容器名称
if [ -z "$container_name" ]; then
    echo "未找到对应的容器名称"
else
    echo "容器名称是: $container_name"
fi
