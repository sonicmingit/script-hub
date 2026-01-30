#!/bin/bash

# rsync增量备份 - 用于将 /data/ 目录增量备份到 /data2/backup/data 目录，并记录备份日志

# 使用方法:
# 1. 将脚本内容保存为 backupData.sh。
# 2. 赋予脚本执行权限：chmod +x backupData.sh
# 3. 运行脚本：./backupData.sh

# 备份源目录和目标目录
SOURCE_DIR="/data/"
BACKUP_DIR="/data2/backup/data/"

# 检查备份目录是否存在，如果不存在则创建
if [ ! -d "$BACKUP_DIR" ]; then
  sudo mkdir -p "$BACKUP_DIR"
fi

# 日志文件路径
LOG_FILE="${BACKUP_DIR}backupData.log"

# 检查日志文件是否存在，如果不存在则创建
if [ ! -f "$LOG_FILE" ]; then
  sudo touch "$LOG_FILE"
  sudo chmod 666 "$LOG_FILE"  # 确保所有用户都有读写权限
fi

# 获取当前时间并格式化
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# 执行增量备份
sudo rsync -av --progress --delete "$SOURCE_DIR" "$BACKUP_DIR"

# 如果备份成功，则记录时间到日志文件
if [ $? -eq 0 ]; then
  # 创建临时文件存放新的日志内容
  TMP_LOG=$(mktemp)
  echo "$CURRENT_TIME $SOURCE_DIR -> $BACKUP_DIR 备份成功。" > "$TMP_LOG"
  # 追加现有的日志内容到临时文件中
  if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE" >> "$TMP_LOG"
  fi
  # 将临时文件替换为日志文件
  sudo mv "$TMP_LOG" "$LOG_FILE"
else
  # 如果备份失败，直接追加失败时间到日志文件
  echo "$CURRENT_TIME $SOURCE_DIR -> $BACKUP_DIR 备份失败。" >> "$LOG_FILE"
fi

