#!/bin/bash
# Droid (Factory CLI) 代理启动脚本
# 解决证书验证错误问题

# 设置代理环境变量
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export ALL_PROXY=socks5://127.0.0.1:7897

# 可选：设置不验证证书（仅用于测试，不推荐）
# export NODE_TLS_REJECT_UNAUTHORIZED=0

# 找到 droid 命令
DROID_CMD="${DROID_CMD:-$(which droid 2>/dev/null)}"

if [ -z "$DROID_CMD" ]; then
    # 检查常见位置
    for path in \
        "$HOME/.local/bin/droid" \
        "/usr/local/bin/droid" \
        "/usr/bin/droid"
    do
        if [ -f "$path" ]; then
            DROID_CMD="$path"
            break
        fi
    done
fi

if [ -z "$DROID_CMD" ]; then
    echo "错误: 找不到 droid 命令"
    echo ""
    echo "Factory CLI (droid) 可能通过以下方式安装:"
    echo "  curl -fsSL https://app.factory.ai/cli | sh"
    echo ""
    echo "请检查安装位置或重新安装"
    exit 1
fi

echo "使用代理启动 Factory CLI (droid)..."
echo "  代理: http://127.0.0.1:7897"
echo "  命令: $DROID_CMD"
echo ""

# 启动 droid
exec "$DROID_CMD" "$@"
