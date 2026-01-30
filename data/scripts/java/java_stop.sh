#!/bin/bash

# 定义变量
JAR_NAME="your-jar-file.jar"

# 获取Jar包的进程ID
PID=$(ps -ef | grep $JAR_NAME | grep -v grep | awk '{print $2}')

# 停止进程
if [ -n "$PID" ]; then
    kill $PID
    echo "停止成功，进程ID: $PID"
else
    echo "未找到运行中的Jar包进程"
fi
