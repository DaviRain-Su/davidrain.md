#!/bin/bash
set -e

echo "=== CLIProxyAPI 安装脚本 ==="

# 检查是否已安装
if command -v cliproxyapi &> /dev/null; then
    echo "CLIProxyAPI 已安装:"
    cliproxyapi --help 2>&1 | head -1
    read -p "是否重新安装/更新? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "取消安装"
        exit 0
    fi
fi

# 检查 Go
if ! command -v go &> /dev/null; then
    echo "错误: 未安装 Go"
    echo "请安装 Go 1.25+"
    exit 1
fi

GO_VERSION=$(go version | grep -o 'go[0-9.]*' | head -1)
echo "Go 版本: $GO_VERSION"

# 克隆并编译
echo ""
echo "下载源码..."
cd /tmp
if [ -d "CLIProxyAPI" ]; then
    cd CLIProxyAPI
    git pull
else
    git clone https://github.com/router-for-me/CLIProxyAPI.git
    cd CLIProxyAPI
fi

echo ""
echo "编译..."
go build -o cliproxyapi ./cmd/server

# 安装
echo ""
echo "安装到 ~/.local/bin..."
mkdir -p ~/.local/bin
cp cliproxyapi ~/.local/bin/

# 创建配置目录
mkdir -p ~/.cli-proxy-api

# 创建默认配置（如果不存在）
if [ ! -f ~/.cli-proxy-api/config.yaml ]; then
    echo ""
    echo "创建默认配置..."
    cat > ~/.cli-proxy-api/config.yaml << 'EOF'
host: "127.0.0.1"
port: 8317

remote-management:
  allow-remote: false
  secret-key: "your-management-secret"
  disable-control-panel: false

auth-dir: "~/.cli-proxy-api"

api-keys:
  - "your-api-key-here"

proxy-url: "socks5://127.0.0.1:7897"

request-retry: 3

routing:
  strategy: "round-robin"
  session-affinity: false
EOF
fi

# 创建 systemd 服务
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/cliproxyapi.service << 'EOF'
[Unit]
Description=CLIProxyAPI Service
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/bin/cliproxyapi -config %h/.cli-proxy-api/config.yaml
Restart=on-failure
RestartSec=10
Environment="HOME=%h"

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload

echo ""
echo "=== 安装完成 ==="
cliproxyapi --help 2>&1 | head -1

echo ""
echo "配置文件: ~/.cli-proxy-api/config.yaml"
echo ""
echo "下一步:"
echo "  1. 编辑配置: nano ~/.cli-proxy-api/config.yaml"
echo "  2. 设置 API 密钥和管理密钥"
echo "  3. OAuth 登录: cliproxyapi -config ~/.cli-proxy-api/config.yaml -codex-login"
echo "  4. 启动服务: systemctl --user enable --now cliproxyapi"
echo ""
echo "常用命令:"
echo "  systemctl --user start|stop|restart|status cliproxyapi"
echo "  journalctl --user -u cliproxyapi -f"
