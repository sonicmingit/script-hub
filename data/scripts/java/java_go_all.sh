#!/bin/bash
set -e

# ========= 可配置项 =========
JAR_NAME="your-jar-file.jar"
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d').log"

# 第一个参数：Spring profile，默认 prod
PROFILE=${1:-prod}

# ========= 工具函数 =========
get_pid() {
  # 通过 jar 名称定位进程（与原 stop 脚本一致的思路，但更稳一点）
  ps -ef | grep -F "$JAR_NAME" | grep -v grep | awk '{print $2}' | head -n 1
}

start_app() {
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
  fi

  echo "未检测到运行进程，准备启动：$JAR_NAME，profile=$PROFILE"
  nohup java -jar "$JAR_NAME" --spring.profiles.active="$PROFILE" > "$LOG_FILE" 2>&1 &

  sleep 1
  local pid
  pid=$(get_pid)

  if [ -n "$pid" ]; then
    echo "启动成功 ✅ 进程ID: $pid，使用配置: $PROFILE"
    echo "日志文件: $LOG_FILE"
  else
    echo "启动失败 ❌ 请检查日志文件: $LOG_FILE"
    exit 1
  fi
}

stop_app() {
  local pid="$1"
  echo "检测到运行中进程，准备停止：$JAR_NAME，PID=$pid"

  # 先尝试优雅停止
  kill "$pid" || true

  # 等待最多 15 秒
  for i in {1..15}; do
    if ps -p "$pid" > /dev/null 2>&1; then
      sleep 1
    else
      echo "停止成功 ✅ 进程ID: $pid"
      return 0
    fi
  done

  # 仍未退出则强杀
  echo "进程未在 15 秒内退出，执行强制停止（kill -9）..."
  kill -9 "$pid" || true
  echo "已强制停止 ✅ 进程ID: $pid"
}

# ========= 主流程 =========
PID=$(get_pid)

if [ -n "$PID" ]; then
  stop_app "$PID"
else
  start_app
fi
