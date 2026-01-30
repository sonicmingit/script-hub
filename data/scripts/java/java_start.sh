#!/bin/bash

# 定义变量
JAR_NAME="your-jar-file.jar"
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d').log"

# 读取第一个参数作为环境配置，默认为 prod
PROFILE=${1:-prod}

# 检查 logs 目录是否存在，如果不存在则创建
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# 启动 Jar 包，并将日志输出到日志文件
nohup java -jar $JAR_NAME --spring.profiles.active=$PROFILE > $LOG_FILE 2>&1 &

# 获取进程 ID
PID=$!

# 输出启动结果
if ps -p $PID > /dev/null; then
    echo "启动成功，进程ID: $PID，使用配置: $PROFILE"
else
    echo "启动失败，请检查日志文件: $LOG_FILE"
fi