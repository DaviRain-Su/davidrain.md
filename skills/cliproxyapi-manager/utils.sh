#!/bin/bash
# CLIProxyAPI 管理工具

CONFIG="${CLIPROXY_CONFIG:-$HOME/.cli-proxy-api/config.yaml}"
SKILL_DIR="$HOME/.pi/agent/skills/cliproxyapi-manager"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

help() {
    echo -e "${BLUE}=== CLIProxyAPI 管理工具 ===${NC}"
    echo ""
    echo "用法: source $SKILL_DIR/utils.sh [命令]"
    echo ""
    echo -e "${GREEN}服务管理:${NC}"
    echo "  start       启动服务"
    echo "  stop        停止服务"
    echo "  restart     重启服务"
    echo "  status      查看状态"
    echo "  log         查看日志 (实时)"
    echo "  enable      设置开机自启"
    echo "  disable     取消开机自启"
    echo ""
    echo -e "${GREEN}认证管理:${NC}"
    echo "  login-codex    Codex OAuth 登录"
    echo "  login-claude   Claude OAuth 登录"
    echo "  login-gemini   Gemini OAuth 登录"
    echo "  list-auths     查看已保存的认证"
    echo ""
    echo -e "${GREEN}API 测试:${NC}"
    echo "  models      查看可用模型"
    echo "  test        测试 API 调用"
    echo ""
    echo -e "${GREEN}配置:${NC}"
    echo "  edit        编辑配置文件"
    echo "  info        显示服务信息"
    echo ""
    echo "环境变量:"
    echo "  CLIPROXY_CONFIG  配置文件路径 (默认: ~/.cli-proxy-api/config.yaml)"
}

start() {
    echo -e "${BLUE}启动 CLIProxyAPI...${NC}"
    if systemctl --user start cliproxyapi; then
        sleep 2
        status
    else
        echo -e "${RED}✗ 启动失败${NC}"
        return 1
    fi
}

stop() {
    echo -e "${BLUE}停止 CLIProxyAPI...${NC}"
    systemctl --user stop cliproxyapi
    echo -e "${GREEN}✓ 已停止${NC}"
}

restart() {
    echo -e "${BLUE}重启 CLIProxyAPI...${NC}"
    if systemctl --user restart cliproxyapi; then
        sleep 2
        status
    else
        echo -e "${RED}✗ 重启失败${NC}"
        return 1
    fi
}

status() {
    echo -e "${BLUE}=== 服务状态 ===${NC}"
    systemctl --user status cliproxyapi --no-pager
    echo ""
    echo -e "${BLUE}=== 端口监听 ===${NC}"
    ss -tlnp 2>/dev/null | grep 8317 || netstat -tlnp 2>/dev/null | grep 8317 || echo "  8317: 未监听"
}

log() {
    echo -e "${YELLOW}按 Ctrl+C 退出日志${NC}"
    journalctl --user -u cliproxyapi -f
}

enable_service() {
    systemctl --user enable cliproxyapi
    echo -e "${GREEN}✓ 已设置开机自启${NC}"
}

disable_service() {
    systemctl --user disable cliproxyapi
    echo -e "${YELLOW}✓ 已取消开机自启${NC}"
}

login_codex() {
    echo -e "${BLUE}=== Codex OAuth 登录 ===${NC}"
    echo "这会打开浏览器让你登录 OpenAI 账号"
    echo ""
    cliproxyapi -config "$CONFIG" -codex-login
}

login_claude() {
    echo -e "${BLUE}=== Claude OAuth 登录 ===${NC}"
    echo "这会打开浏览器让你登录 Claude 账号"
    echo ""
    cliproxyapi -config "$CONFIG" -claude-login
}

login_gemini() {
    echo -e "${BLUE}=== Gemini OAuth 登录 ===${NC}"
    echo "这会打开浏览器让你登录 Google 账号"
    echo ""
    cliproxyapi -config "$CONFIG" -login
}

list_auths() {
    echo -e "${BLUE}=== 已保存的认证 ===${NC}"
    local auth_dir=$(grep "auth-dir:" "$CONFIG" 2>/dev/null | awk '{print $2}' | sed 's/~/$HOME/')
    auth_dir="${auth_dir:-$HOME/.cli-proxy-api}"
    auth_dir=$(eval echo "$auth_dir")
    
    if [ -d "$auth_dir" ]; then
        echo "认证目录: $auth_dir"
        echo ""
        for f in "$auth_dir"/*.json; do
            [ -f "$f" ] || continue
            local name=$(basename "$f" .json)
            echo "  ✓ $name"
        done
    else
        echo -e "${YELLOW}认证目录不存在: $auth_dir${NC}"
    fi
}

models() {
    echo -e "${BLUE}=== 可用模型 ===${NC}"
    local api_key=$(grep "api-keys:" -A1 "$CONFIG" 2>/dev/null | tail -1 | sed 's/.*- "//;s/".*//')
    api_key="${api_key:-your-api-key-here}"
    
    local response=$(curl -s --max-time 10 http://127.0.0.1:8317/v1/models \
        -H "Authorization: Bearer $api_key" 2>/dev/null)
    
    if [ -n "$response" ]; then
        echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for model in data.get('data', []):
    print(f'  - {model[\"id\"]}')
" 2>/dev/null || echo "$response"
    else
        echo -e "${RED}API 未响应，请确认服务已启动${NC}"
    fi
}

test_api() {
    echo -e "${BLUE}=== 测试 API ===${NC}"
    local api_key=$(grep "api-keys:" -A1 "$CONFIG" 2>/dev/null | tail -1 | sed 's/.*- "//;s/".*//')
    api_key="${api_key:-your-api-key-here}"
    
    echo ""
    echo "1. 获取模型列表:"
    curl -s --max-time 10 http://127.0.0.1:8317/v1/models \
        -H "Authorization: Bearer $api_key" | python3 -c "
import sys, json
data = json.load(sys.stdin)
count = len(data.get('data', []))
print(f'  ✓ 成功，共 {count} 个模型')
" 2>/dev/null || echo -e "  ${RED}✗ 失败${NC}"
    
    echo ""
    echo "2. 测试聊天完成:"
    local response=$(curl -s --max-time 30 http://127.0.0.1:8317/v1/chat/completions \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d '{"model": "gpt-5.4", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 50}' 2>/dev/null)
    
    if echo "$response" | grep -q '"choices"'; then
        local content=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'][:50])" 2>/dev/null)
        echo "  ✓ 成功"
        echo "  回复: $content..."
    else
        echo -e "  ${RED}✗ 失败${NC}"
        echo "  响应: $response"
    fi
}

edit_config() {
    local editor="${EDITOR:-nano}"
    echo -e "${BLUE}编辑配置: $CONFIG${NC}"
    $editor "$CONFIG"
}

info() {
    echo -e "${BLUE}=== CLIProxyAPI 信息 ===${NC}"
    echo ""
    echo -e "${GREEN}版本:${NC}"
    cliproxyapi --help 2>/dev/null | head -1 || echo "  未安装"
    echo ""
    echo -e "${GREEN}配置文件:${NC}"
    echo "  $CONFIG"
    if [ -f "$CONFIG" ]; then
        echo "  存在: ✓"
    else
        echo "  存在: ✗"
    fi
    echo ""
    echo -e "${GREEN}服务状态:${NC}"
    systemctl --user is-active cliproxyapi 2>/dev/null || echo "  未运行"
    echo ""
    echo -e "${GREEN}开机自启:${NC}"
    systemctl --user is-enabled cliproxyapi 2>/dev/null || echo "  未设置"
    echo ""
    echo -e "${GREEN}API 地址:${NC}"
    echo "  http://127.0.0.1:8317"
    echo ""
    echo -e "${GREEN}认证文件:${NC}"
    list_auths
}

# 主入口
case "${1:-help}" in
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    status) status ;;
    log) log ;;
    enable) enable_service ;;
    disable) disable_service ;;
    login-codex) login_codex ;;
    login-claude) login_claude ;;
    login-gemini) login_gemini ;;
    list-auths) list_auths ;;
    models) models ;;
    test) test_api ;;
    edit) edit_config ;;
    info) info ;;
    *) help ;;
esac
