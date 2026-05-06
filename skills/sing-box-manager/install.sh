#!/bin/bash
set -e

echo "=== sing-box 安装脚本 ==="

# 检查是否已安装
if command -v sing-box &> /dev/null; then
    echo "sing-box 已安装:"
    sing-box version
    read -p "是否重新安装/更新? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "取消安装"
        exit 0
    fi
fi

# 检测系统
if [[ -f /etc/debian_version ]]; then
    echo "检测到 Debian/Ubuntu 系统"
    
    # 下载安装
    cd /tmp
    echo "下载 sing-box..."
    curl -fsSL -o sing-box.deb "https://github.com/SagerNet/sing-box/releases/download/v1.11.10/sing-box_1.11.10_linux_amd64.deb"
    
    echo "安装..."
    sudo dpkg -i sing-box.deb || sudo apt-get install -f -y
    
    rm -f sing-box.deb
else
    echo "不支持自动安装，请手动下载: https://github.com/SagerNet/sing-box/releases"
    exit 1
fi

echo ""
echo "=== 安装完成 ==="
sing-box version

# 创建配置目录
mkdir -p ~/.config/sing-box

# 检查配置文件
if [[ -f ~/sing-box-config.json ]]; then
    echo ""
    echo "发现配置文件: ~/sing-box-config.json"
    sing-box check -c ~/sing-box-config.json && echo "配置验证通过"
fi

echo ""
echo "常用命令:"
echo "  sing-box check -c ~/sing-box-config.json    # 验证配置"
echo "  sudo systemctl start sing-box               # 启动服务"
echo "  sudo systemctl enable sing-box              # 开机自启"
echo "  sudo journalctl -u sing-box -f              # 查看日志"
