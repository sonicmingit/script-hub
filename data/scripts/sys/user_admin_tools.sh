#!/bin/bash
# Linux 用户管理工具
# 功能描述：交互式创建或删除系统用户，创建时自动赋予 sudo 权限
# 使用方法：curl -sL <url> | sudo bash
# 注意事项：需要 root 权限执行
 
set -e
 
# ====== 颜色定义（美化输出）======
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
 
# ====== root 检查 ======
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}❌ 请使用root或sudo权限执行此脚本${NC}" >&2
  exit 1
fi
 
# ====== 工具函数 ======
has_wheel_group() {
  getent group wheel >/dev/null 2>&1
}
 
grant_sudo() {
  local username="$1"
 
  if has_wheel_group; then
    usermod -aG wheel "$username"
    echo -e "${GREEN}🛡️ 用户 $username 已加入 wheel 组（sudo权限）${NC}"
  else
    # 更安全：使用 /etc/sudoers.d，不直接改 /etc/sudoers
    local sudo_file="/etc/sudoers.d/${username}"
    echo "${username} ALL=(ALL) ALL" > "$sudo_file"
    chmod 0440 "$sudo_file"
    echo -e "${GREEN}🛡️ 已写入 ${sudo_file}（sudo权限）${NC}"
  fi
}
 
create_user_flow() {
  # 1) 输入用户名（默认 sonic）
  read -p "📝 输入用户名（默认：sonic）: " username
  username=${username:-sonic}
 
  # 用户名合法性简单校验（避免奇怪字符）
  if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo -e "${RED}❌ 用户名不合法：$username${NC}"
    exit 1
  fi
 
  # 2) 检查用户是否已存在
  if id "$username" &>/dev/null; then
    echo -e "${YELLOW}⚠️ 用户 $username 已存在，跳过创建${NC}"
  else
    useradd -m -s /bin/bash "$username"
    echo -e "${GREEN}✅ 用户 $username 创建成功${NC}"
  fi
 
  # 3) 输入密码（默认 123456）
  read -p "🔑 输入密码（默认：123456）: " password
  password=${password:-123456}
  echo "$username:$password" | chpasswd
  echo -e "${GREEN}✅ 已设置用户 $username 密码${NC}"
 
  # 4) 赋sudo权限
  grant_sudo "$username"
 
  # 5) 默认密码告警
  if [ "$password" = "123456" ]; then
    echo -e "${RED}🚨 警告：使用了默认密码 123456，建议立即修改！${NC}"
  fi
 
  # 6) 验证提示
  echo -e "\n${GREEN}✨ 用户 $username 创建完成，建议验证：${NC}"
  echo -e "  ${YELLOW}su - $username${NC}  →  ${YELLOW}sudo whoami${NC}（应返回root）"
}
 
list_deletable_users() {
  # 列出“普通用户”：UID>=1000 且排除 root/nobody
  # 注：不同发行版普通用户起始UID可能不同，你也可以按需调整阈值
  awk -F: '($3>=1000)&&($1!="nobody")&&($1!="root") {print $1}' /etc/passwd
}
 
delete_user_flow() {
  echo -e "${YELLOW}📋 当前可删除的普通用户列表（UID>=1000，已排除root/nobody）：${NC}"
 
  mapfile -t users < <(list_deletable_users)
 
  if [ "${#users[@]}" -eq 0 ]; then
    echo -e "${YELLOW}⚠️ 未找到可删除的普通用户${NC}"
    return 0
  fi
 
  # 展示编号列表
  for i in "${!users[@]}"; do
    idx=$((i+1))
    echo "  [$idx] ${users[$i]}"
  done
 
  echo
  read -p "🗑️ 请输入要删除的用户编号（例如 1），或输入 0 取消: " choice
 
  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ 输入不是数字，已退出${NC}"
    exit 1
  fi
 
  if [ "$choice" -eq 0 ]; then
    echo -e "${YELLOW}已取消删除操作${NC}"
    return 0
  fi
 
  if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#users[@]}" ]; then
    echo -e "${RED}❌ 编号超出范围${NC}"
    exit 1
  fi
 
  local username="${users[$((choice-1))]}"
 
  # 二次确认（防误删）
  read -p "⚠️ 确认删除用户 [$username] 及其家目录数据？输入 YES 继续: " confirm
  if [ "$confirm" != "YES" ]; then
    echo -e "${YELLOW}已取消删除操作${NC}"
    return 0
  fi
 
  # 1) 再次确认用户存在
  if ! id "$username" &>/dev/null; then
    echo -e "${RED}❌ 用户 $username 不存在，无法删除${NC}"
    exit 1
  fi
 
  echo -e "${YELLOW}🔒 锁定用户：$username${NC}"
  usermod -L "$username" || true
 
  echo -e "${YELLOW}🧹 终止用户所有进程：$username${NC}"
  pkill -u "$username" || true
  sleep 1
  pkill -9 -u "$username" || true
 
  echo -e "${YELLOW}🗑️ 删除用户及家目录：$username${NC}"
  userdel -r "$username"
 
  # 清理 sudoers.d（如果存在）
  if [ -f "/etc/sudoers.d/${username}" ]; then
    rm -f "/etc/sudoers.d/${username}"
  fi
 
  echo -e "${GREEN}✅ 已删除用户：$username${NC}"
}
 
# ====== 主菜单 ======
echo -e "${GREEN}=== 用户管理工具（创建/删除）===${NC}"
echo "  [1] 创建管理员用户（赋sudo权限）"
echo "  [2] 删除用户（列出用户后选择删除）"
echo "  [0] 退出"
echo
 
read -p "请选择操作编号: " action
 
case "$action" in
  1)
    create_user_flow
    ;;
  2)
    delete_user_flow
    ;;
  0)
    echo "已退出"
    ;;
  *)
    echo -e "${RED}❌ 无效选择${NC}"
    exit 1
    ;;
esac
