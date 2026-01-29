#!/bin/bash
# ===================================================
# 脚本名称: 网络连通性测试工具
# 功能描述: 测试网络连通性、DNS解析、常用服务可达性
# 使用方法: curl -sL <url> | bash
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试目标
PING_TARGETS=("8.8.8.8" "114.114.114.114" "1.1.1.1")
DNS_TARGETS=("google.com" "baidu.com" "github.com")
HTTP_TARGETS=("https://www.baidu.com" "https://www.google.com" "https://github.com")

# Ping 测试
ping_test() {
    local target=$1
    if ping -c 1 -W 3 "$target" &> /dev/null; then
        local latency=$(ping -c 1 -W 3 "$target" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
        echo -e "  ${GREEN}✓${NC} $target ${GREEN}可达${NC} (${latency})"
        return 0
    else
        echo -e "  ${RED}✗${NC} $target ${RED}不可达${NC}"
        return 1
    fi
}

# DNS 解析测试
dns_test() {
    local domain=$1
    local result=""
    
    if command -v nslookup &> /dev/null; then
        result=$(nslookup "$domain" 2>/dev/null | grep -A1 'Name:' | tail -1 | awk '{print $2}')
    elif command -v dig &> /dev/null; then
        result=$(dig +short "$domain" 2>/dev/null | head -1)
    elif command -v host &> /dev/null; then
        result=$(host "$domain" 2>/dev/null | head -1 | awk '{print $NF}')
    fi
    
    if [ -n "$result" ] && [ "$result" != ";;" ]; then
        echo -e "  ${GREEN}✓${NC} $domain → ${GREEN}$result${NC}"
        return 0
    else
        echo -e "  ${RED}✗${NC} $domain ${RED}解析失败${NC}"
        return 1
    fi
}

# HTTP 连通测试
http_test() {
    local url=$1
    local domain=$(echo "$url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    
    if command -v curl &> /dev/null; then
        local start=$(date +%s%N)
        local status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
        local end=$(date +%s%N)
        local duration=$(( (end - start) / 1000000 ))
        
        if [ "$status" -ge 200 ] && [ "$status" -lt 400 ]; then
            echo -e "  ${GREEN}✓${NC} $domain ${GREEN}HTTP $status${NC} (${duration}ms)"
            return 0
        else
            echo -e "  ${RED}✗${NC} $domain ${RED}HTTP $status${NC}"
            return 1
        fi
    else
        echo -e "  ${YELLOW}?${NC} $domain ${YELLOW}curl 未安装${NC}"
        return 1
    fi
}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        🌐 网络连通性测试  🌐${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 本机网络信息
echo -e "${YELLOW}📍 本机网络信息:${NC}"
if command -v ip &> /dev/null; then
    default_ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    echo "  本机IP:   $default_ip"
    echo "  网关:     $gateway"
elif command -v ifconfig &> /dev/null; then
    echo "  本机IP:   $(ifconfig | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)"
fi
echo ""

# Ping 测试
echo -e "${YELLOW}🔔 Ping 测试:${NC}"
ping_success=0
for target in "${PING_TARGETS[@]}"; do
    if ping_test "$target"; then
        ((ping_success++))
    fi
done
echo ""

# DNS 解析测试
echo -e "${YELLOW}🔍 DNS 解析测试:${NC}"
dns_success=0
for domain in "${DNS_TARGETS[@]}"; do
    if dns_test "$domain"; then
        ((dns_success++))
    fi
done
echo ""

# HTTP 连通测试
echo -e "${YELLOW}🌍 HTTP 连通测试:${NC}"
http_success=0
for url in "${HTTP_TARGETS[@]}"; do
    if http_test "$url"; then
        ((http_success++))
    fi
done
echo ""

# 汇总
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  📊 测试结果汇总:"
echo -e "     Ping:  ${GREEN}$ping_success${NC}/${#PING_TARGETS[@]} 成功"
echo -e "     DNS:   ${GREEN}$dns_success${NC}/${#DNS_TARGETS[@]} 成功"
echo -e "     HTTP:  ${GREEN}$http_success${NC}/${#HTTP_TARGETS[@]} 成功"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
