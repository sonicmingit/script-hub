#!/bin/bash
# Docker 容器日志清理工具
# 功能描述：查找并清空所有 Docker 容器的日志文件，释放磁盘空间
# 使用方法：curl -sL <url> | sudo bash
# 注意事项：需要 root 权限执行

echo "======== 开始清理 Docker 容器日志 ========"

# 初始化总清理容量
total_cleared_size=0

# 查询所有容器的ID和名称
logs=$(find /var/lib/docker/containers/ -name *-json.log)
for log in $logs
do
    # 获取容器的ID，并截取前12位
    container_id=$(basename $(dirname $log) | cut -c 1-12)

    # 获取容器名称
    container_name=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep "^$container_id" | awk '{print $2}')

    # 获取日志文件的大小
    log_size=$(du -sh $log | awk '{print $1}')

    # 输出被清理的日志文件和容器名称
    echo "正在清理容器日志：容器名称：$container_name ($container_id)，日志文件大小：$log_size"
    
    # 清空日志文件
    cat /dev/null > $log

    # 累加清理的容量
    total_cleared_size=$((total_cleared_size + $(du -b $log | awk '{print $1}')))
done

# 输出总清理容量
echo "总共清理了：$(numfmt --to=iec $total_cleared_size)"

echo "======== 完成 Docker 容器日志清理 ========"

