#!/bin/bash
 
# 脚本名称: clear_proxy.sh
# 功能: 彻底检查并清除系统代理设置
# 使用方法: sudo bash clear_proxy.sh
 
set -e
 
# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
 
# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}
 
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
 
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
 
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
 
# 检查权限
check_permission() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "正在以root权限运行脚本"
    else
        log_warn "建议使用sudo运行此脚本以获得完整功能"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}
 
# 显示当前代理状态
show_current_proxy_status() {
    log_info "=== 当前代理状态检查 ==="
    
    # 环境变量
    log_info "1. 检查环境变量:"
    env | grep -i proxy | while read line; do
        log_warn "   $line"
    done
    
    # APT代理
    log_info "2. 检查APT代理配置:"
    if [[ -d /etc/apt/apt.conf.d ]]; then
        find /etc/apt/apt.conf.d -name "*" -type f | xargs grep -l -i proxy 2>/dev/null | while read file; do
            log_warn "   发现APT代理配置: $file"
            grep -i proxy "$file" | while read line; do
                log_warn "     $line"
            done
        done
    fi
    
    # Git代理
    log_info "3. 检查Git代理配置:"
    if command -v git &> /dev/null; then
        git config --global --list | grep -i proxy | while read line; do
            log_warn "   $line"
        done
    fi
    
    # npm代理
    log_info "4. 检查npm代理配置:"
    if command -v npm &> /dev/null; then
        npm_proxy=$(npm config get proxy 2>/dev/null)
        npm_https_proxy=$(npm config get https-proxy 2>/dev/null)
        if [[ "$npm_proxy" != "null" ]]; then
            log_warn "   npm proxy: $npm_proxy"
        fi
        if [[ "$npm_https_proxy" != "null" ]]; then
            log_warn "   npm https-proxy: $npm_https_proxy"
        fi
    fi
    
    # 系统代理(GNOME)
    log_info "5. 检查系统代理设置(GNOME):"
    if command -v gsettings &> /dev/null; then
        gsettings get org.gnome.system.proxy mode 2>/dev/null && \
        log_warn "   当前系统代理模式: $(gsettings get org.gnome.system.proxy mode)"
    fi
    
    # 网络管理器代理
    log_info "6. 检查NetworkManager代理设置:"
    if command -v nmcli &> /dev/null; then
        nmcli connection show --active | grep -v "DEVICE" | while read conn; do
            proxy_method=$(nmcli connection show "$(echo $conn | awk '{print $1}')" | grep proxy.method | awk '{print $2}')
            if [[ "$proxy_method" != "none" ]]; then
                log_warn "   连接 $(echo $conn | awk '{print $1}') 使用代理方法: $proxy_method"
            fi
        done
    fi
    
    echo
}
 
# 清除环境变量代理
clear_env_proxy() {
    log_info "=== 清除环境变量代理 ==="
    
    # 当前session
    unset http_proxy https_proxy ftp_proxy all_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY no_proxy NO_PROXY 2>/dev/null || true
    log_success "已清除当前session的环境变量"
    
    # 用户配置文件
    user_files=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile" 
        "$HOME/.profile"
        "$HOME/.zshrc"
        "$HOME/.bash_logout"
    )
    
    for file in "${user_files[@]}"; do
        if [[ -f "$file" ]]; then
            if grep -q -i "proxy" "$file" 2>/dev/null; then
                log_warn "在 $file 中发现代理设置，创建备份: $file.bak"
                cp "$file" "$file.bak"
                # 删除代理相关行
                sed -i.bak -e '/proxy/Id' "$file" 2>/dev/null || true
                log_success "已清理 $file"
            fi
        fi
    done
    
    # 系统配置文件
    system_files=(
        "/etc/environment"
        "/etc/profile"
        "/etc/bash.bashrc"
    )
    
    for file in "${system_files[@]}"; do
        if [[ -f "$file" ]]; then
            if sudo grep -q -i "proxy" "$file" 2>/dev/null; then
                log_warn "在 $file 中发现代理设置，创建备份: $file.bak"
                sudo cp "$file" "$file.bak"
                sudo sed -i.bak -e '/proxy/Id' "$file" 2>/dev/null || true
                log_success "已清理 $file"
            fi
        fi
    done
}
 
# 清除APT代理
clear_apt_proxy() {
    log_info "=== 清除APT代理配置 ==="
    
    if [[ -d /etc/apt/apt.conf.d ]]; then
        find /etc/apt/apt.conf.d -name "*" -type f -exec sudo grep -l -i proxy {} \; 2>/dev/null | while read file; do
            log_warn "发现APT代理配置文件: $file"
            sudo cp "$file" "$file.bak"
            sudo sed -i '/proxy/Id' "$file" 2>/dev/null || true
            log_success "已清理 $file"
        done
    fi
}
 
# 清除Git代理
clear_git_proxy() {
    log_info "=== 清除Git代理配置 ==="
    
    if command -v git &> /dev/null; then
        git config --global --unset http.proxy 2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
        git config --global --unset url.https://.insteadOf 2>/dev/null || true
        log_success "已清除Git全局代理设置"
    fi
}
 
# 清除npm代理
clear_npm_proxy() {
    log_info "=== 清除npm代理配置 ==="
    
    if command -v npm &> /dev/null; then
        npm config delete proxy 2>/dev/null || true
        npm config delete https-proxy 2>/dev/null || true
        npm config delete noproxy 2>/dev/null || true
        log_success "已清除npm代理设置"
    fi
}
 
# 清除系统代理设置
clear_system_proxy() {
    log_info "=== 清除系统代理设置 ==="
    
    # GNOME系统代理
    if command -v gsettings &> /dev/null; then
        gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null && \
        log_success "已关闭GNOME系统代理"
    fi
    
    # NetworkManager代理
    if command -v nmcli &> /dev/null; then
        nmcli connection show --active | grep -v "DEVICE" | while read conn; do
            conn_name=$(echo $conn | awk '{print $1}')
            nmcli connection modify "$conn_name" proxy.method none 2>/dev/null && \
            log_success "已为连接 $conn_name 关闭代理"
        done
    fi
}
 
# 清除其他代理配置
clear_other_proxy() {
    log_info "=== 清除其他代理配置 ==="
    
    # 检查是否有全局代理配置文件
    other_proxy_files=$(sudo find /etc -name "*proxy*" -type f 2>/dev/null | grep -v "bak$")
    if [[ -n "$other_proxy_files" ]]; then
        echo "$other_proxy_files" | while read file; do
            log_warn "发现可能的代理配置文件: $file"
            # 备份并注释掉代理设置
            sudo cp "$file" "$file.bak"
            sudo sed -i 's/^[^#]/# &/' "$file" 2>/dev/null || true
        done
        log_success "已处理其他代理配置文件"
    fi
}
 
# 重启网络服务（可选）
restart_network_services() {
    log_info "=== 重启网络服务 ==="
    
    read -p "是否重启网络服务? (建议重启使更改生效) (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v systemctl &> /dev/null; then
            sudo systemctl restart NetworkManager 2>/dev/null && log_success "已重启NetworkManager" || true
            sudo systemctl restart networking 2>/dev/null && log_success "已重启networking服务" || true
        fi
        log_success "建议重新登录或重启计算机使所有更改生效"
    fi
}
 
# 验证清理结果
verify_cleanup() {
    log_info "=== 验证清理结果 ==="
    
    log_info "检查剩余代理设置:"
    remaining=$(env | grep -i proxy || true)
    if [[ -z "$remaining" ]]; then
        log_success "环境变量代理已清除"
    else
        log_warn "仍有环境变量代理:"
        echo "$remaining"
    fi
    
    log_info "测试网络连接:"
    if curl -I --connect-timeout 10 https://www.google.com >/dev/null 2>&1; then
        log_success "网络连接正常"
    else
        log_warn "网络连接测试失败，但代理设置已清除"
    fi
}
 
# 主函数
main() {
    echo "=== 代理设置清理脚本 ==="
    echo "此脚本将检查并清除系统中的各种代理设置"
    echo "======================================"
    
    check_permission
    show_current_proxy_status
    
    read -p "是否继续清理代理设置? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    clear_env_proxy
    clear_apt_proxy
    clear_git_proxy
    clear_npm_proxy
    clear_system_proxy
    clear_other_proxy
    
    verify_cleanup
    restart_network_services
    
    log_success "代理清理完成!"
    log_info "请重新启动终端或重新登录使所有更改生效"
}
 
# 执行主函数
main "$@"