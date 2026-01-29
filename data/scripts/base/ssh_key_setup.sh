#!/bin/bash
# ===================================================
# 脚本名称: SSH 密钥配置工具
# 功能描述: 生成 SSH 密钥对并配置免密登录
# 使用方法: curl -sL <url> | bash
# 注意事项: 交互式脚本，需要输入目标服务器信息
# ===================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        🔐 SSH 密钥配置工具  🔐${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"

# 检查是否已有密钥
echo -e "${YELLOW}🔍 检查现有 SSH 密钥...${NC}"
if [ -f "$KEY_FILE" ]; then
    echo -e "  ${GREEN}✓${NC} 已存在 SSH 密钥: $KEY_FILE"
    echo ""
    echo -e "${YELLOW}是否要生成新的密钥? (这将覆盖现有密钥)${NC}"
    read -p "输入 y 继续，其他键跳过: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "  跳过密钥生成"
        KEY_EXISTS=true
    else
        KEY_EXISTS=false
    fi
else
    echo -e "  ${YELLOW}!${NC} 未找到 SSH 密钥"
    KEY_EXISTS=false
fi
echo ""

# 创建 .ssh 目录
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo -e "${GREEN}✓${NC} 创建目录: $SSH_DIR"
fi

# 生成密钥
if [ "$KEY_EXISTS" != "true" ]; then
    echo -e "${YELLOW}🔑 生成 SSH 密钥对...${NC}"
    echo ""
    
    # 获取邮箱
    read -p "输入邮箱 (用于密钥注释，可留空): " email
    if [ -z "$email" ]; then
        email="$(whoami)@$(hostname)"
    fi
    
    # 生成密钥
    ssh-keygen -t rsa -b 4096 -C "$email" -f "$KEY_FILE" -N ""
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ SSH 密钥生成成功!${NC}"
        chmod 600 "$KEY_FILE"
        chmod 644 "$KEY_FILE.pub"
    else
        echo -e "${RED}✗ 密钥生成失败${NC}"
        exit 1
    fi
fi

echo ""

# 显示公钥
echo -e "${YELLOW}📋 您的公钥内容:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$KEY_FILE.pub"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 配置免密登录
echo -e "${YELLOW}🔗 配置免密登录到远程服务器${NC}"
echo ""
read -p "是否要配置免密登录? (y/n): " setup_remote

if [ "$setup_remote" = "y" ] || [ "$setup_remote" = "Y" ]; then
    read -p "输入远程服务器地址 (如: user@192.168.1.100): " remote_host
    
    if [ -n "$remote_host" ]; then
        echo ""
        echo -e "${YELLOW}正在复制公钥到 $remote_host ...${NC}"
        echo "(需要输入远程服务器密码)"
        echo ""
        
        ssh-copy-id -i "$KEY_FILE.pub" "$remote_host"
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ 免密登录配置成功!${NC}"
            echo -e "  现在可以使用 ${CYAN}ssh $remote_host${NC} 免密登录"
        else
            echo -e "${RED}✗ 配置失败，请检查服务器地址和密码${NC}"
        fi
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        ✅ 配置完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}💡 使用提示:${NC}"
echo "  查看公钥:     cat ~/.ssh/id_rsa.pub"
echo "  复制到服务器: ssh-copy-id user@server"
echo "  测试连接:     ssh user@server"
echo ""
