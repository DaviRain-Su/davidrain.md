#!/bin/bash
# sing-box 管理工具 - 完整版

CONFIG="${SINGBOX_CONFIG:-$HOME/sing-box-config.json}"
SKILL_DIR="$HOME/.pi/agent/skills/sing-box-manager"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

help() {
    echo -e "${BLUE}=== sing-box 管理工具 ===${NC}"
    echo ""
    echo "用法: source $SKILL_DIR/utils.sh [命令]"
    echo ""
    echo -e "${GREEN}服务管理:${NC}"
    echo "  check       验证配置"
    echo "  start       启动服务"
    echo "  stop        停止服务"
    echo "  restart     重启服务"
    echo "  status      查看状态"
    echo "  log         查看日志 (实时)"
    echo "  enable      设置开机自启"
    echo "  disable     取消开机自启"
    echo ""
    echo -e "${GREEN}代理测试:${NC}"
    echo "  test        测试代理连接"
    echo "  api         查看节点状态"
    echo "  latency     测试节点延迟"
    echo ""
    echo -e "${GREEN}终端代理:${NC}"
    echo "  proxy-on    开启终端代理环境变量"
    echo "  proxy-off   关闭终端代理环境变量"
    echo ""
    echo -e "${GREEN}面板与配置:${NC}"
    echo "  panel       打开 yacd 面板"
    echo "  edit        编辑配置文件"
    echo "  gen         生成新配置 (交互式)"
    echo "  template    从模板复制配置"
    echo ""
    echo -e "${GREEN}系统信息:${NC}"
    echo "  info        显示 sing-box 信息"
    echo "  version     显示 sing-box 版本"
    echo ""
    echo "环境变量:"
    echo "  SINGBOX_CONFIG  配置文件路径 (默认: ~/sing-box-config.json)"
}

check() {
    echo -e "${BLUE}验证配置: $CONFIG${NC}"
    if sing-box check -c "$CONFIG" 2>&1; then
        echo -e "${GREEN}✓ 配置验证通过${NC}"
    else
        echo -e "${RED}✗ 配置有误${NC}"
        return 1
    fi
}

start() {
    echo -e "${BLUE}启动 sing-box...${NC}"
    if sudo systemctl start sing-box; then
        sleep 1
        status
    else
        echo -e "${RED}✗ 启动失败${NC}"
        return 1
    fi
}

stop() {
    echo -e "${BLUE}停止 sing-box...${NC}"
    sudo systemctl stop sing-box
    echo -e "${GREEN}✓ 已停止${NC}"
}

restart() {
    echo -e "${BLUE}重启 sing-box...${NC}"
    if sudo systemctl restart sing-box; then
        sleep 1
        status
    else
        echo -e "${RED}✗ 重启失败${NC}"
        return 1
    fi
}

status() {
    echo -e "${BLUE}=== 服务状态 ===${NC}"
    sudo systemctl status sing-box --no-pager
    echo ""
    echo -e "${BLUE}=== 端口监听 ===${NC}"
    ss -tlnp 2>/dev/null | grep -E '7897|9090' || netstat -tlnp 2>/dev/null | grep -E '7897|9090' || echo "  7897 (mixed): 检查中..."
}

log() {
    echo -e "${YELLOW}按 Ctrl+C 退出日志${NC}"
    sudo journalctl -u sing-box -f
}

enable_service() {
    sudo systemctl enable sing-box
    echo -e "${GREEN}✓ 已设置开机自启${NC}"
}

disable_service() {
    sudo systemctl disable sing-box
    echo -e "${YELLOW}✓ 已取消开机自启${NC}"
}

test_proxy() {
    echo -e "${BLUE}=== 代理测试 ===${NC}"
    echo ""
    
    echo -e "${GREEN}1. HTTP 代理测试 (Google):${NC}"
    curl -s -o /dev/null -w "  状态码: %{http_code}, 耗时: %{time_total}s\n" \
        -x http://127.0.0.1:7897 --max-time 15 https://www.google.com
    
    echo ""
    echo -e "${GREEN}2. 直连测试 (Baidu):${NC}"
    curl -s -o /dev/null -w "  状态码: %{http_code}, 耗时: %{time_total}s\n" \
        --max-time 10 https://www.baidu.com
    
    echo ""
    echo -e "${GREEN}3. 当前出口 IP (通过代理):${NC}"
    local ip=$(curl -s -x http://127.0.0.1:7897 --max-time 10 https://ip.sb 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "  $ip"
        # 查询 IP 地区
        local info=$(curl -s --max-time 5 "https://ipinfo.io/$ip" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"  {d.get('city','')}, {d.get('region','')}, {d.get('country','')}\")" 2>/dev/null)
        [ -n "$info" ] && echo "  $info"
    else
        echo -e "  ${RED}获取失败${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}4. 服务状态:${NC}"
    local service_status=$(sudo systemctl is-active sing-box 2>/dev/null)
    if [ "$service_status" = "active" ]; then
        echo -e "  ${GREEN}运行中${NC}"
    else
        echo -e "  ${RED}未运行 ($service_status)${NC}"
    fi
}

api() {
    echo -e "${BLUE}=== 节点状态 ===${NC}"
    local response=$(curl -s --max-time 5 http://127.0.0.1:9090/proxies 2>/dev/null)
    if [ -n "$response" ]; then
        echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
proxies = data.get('proxies', {})

print('\n代理选择器:')
for name in ['proxy', 'proxy-hk']:
    if name in proxies:
        p = proxies[name]
        now = p.get('now', 'N/A')
        print(f'  {name}: 当前使用 -> {now}')

print('\n节点列表:')
for name, info in sorted(proxies.items()):
    if name.startswith('proxy-') and info.get('type') != 'Selector':
        delay = 'N/A'
        if info.get('history'):
            delay = info['history'][-1].get('delay', 'N/A')
        status = '✓' if info.get('alive', True) else '✗'
        print(f'  {status} {name}: {delay}ms')
" 2>/dev/null || echo "  API 响应解析失败"
    else
        echo -e "  ${RED}API 未响应，请确认服务已启动${NC}"
    fi
}

latency() {
    echo -e "${BLUE}=== 节点延迟测试 ===${NC}"
    echo "正在测试..."
    
    # 通过 API 触发延迟测试
    local proxies=$(curl -s --max-time 5 http://127.0.0.1:9090/proxies 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for name in data.get('proxies', {}):
    if name.startswith('proxy-') and data['proxies'][name].get('type') != 'Selector':
        print(name)
" 2>/dev/null)
    
    if [ -z "$proxies" ]; then
        echo -e "${RED}无法获取节点列表${NC}"
        return 1
    fi
    
    for proxy in $proxies; do
        # 通过 API 测试延迟
        curl -s -X PUT "http://127.0.0.1:9090/proxies/$proxy/delay" \
            -H "Content-Type: application/json" \
            -d '{"url":"http://www.google.com/generate_204","timeout":5000}' \
            --max-time 10 > /dev/null 2>&1
    done
    
    sleep 2
    echo ""
    api
}

panel() {
    if [ -d ~/yacd/yacd-gh-pages ]; then
        echo -e "${BLUE}启动本地 yacd 面板...${NC}"
        cd ~/yacd/yacd-gh-pages
        if ! pgrep -f "python3 -m http.server 1234" > /dev/null; then
            python3 -m http.server 1234 > /dev/null 2>&1 &
            echo "  面板服务已启动"
        else
            echo "  面板服务已在运行"
        fi
        echo ""
        echo -e "${GREEN}打开浏览器访问:${NC}"
        echo "  http://localhost:1234"
        echo ""
        echo "API 设置:"
        echo "  API Base URL: http://127.0.0.1:9090"
        echo "  Secret: (留空)"
    else
        echo -e "${YELLOW}本地面板未安装${NC}"
        echo ""
        echo "安装方式:"
        echo "  cd /tmp && curl -LO https://github.com/haishanh/yacd/archive/gh-pages.zip"
        echo "  unzip gh-pages.zip -d ~/yacd"
        echo ""
        echo -e "${GREEN}或使用在线面板:${NC}"
        echo "  https://yacd.metacubex.one/"
        echo "  API Base URL: http://127.0.0.1:9090"
    fi
}

edit_config() {
    local editor="${EDITOR:-nano}"
    echo -e "${BLUE}编辑配置: $CONFIG${NC}"
    $editor "$CONFIG"
    echo ""
    check
}

generate_config() {
    echo -e "${BLUE}生成新配置...${NC}"
    python3 "$SKILL_DIR/generate-config.py" --interactive --output "$CONFIG"
}

copy_template() {
    echo -e "${BLUE}从模板复制配置...${NC}"
    cp "$SKILL_DIR/config-template.json" "$CONFIG"
    echo -e "${GREEN}✓ 已复制到: $CONFIG${NC}"
    echo "请编辑配置文件替换为你的节点信息"
}

info() {
    echo -e "${BLUE}=== sing-box 信息 ===${NC}"
    echo ""
    echo -e "${GREEN}版本:${NC}"
    sing-box version 2>/dev/null || echo "  未安装"
    echo ""
    echo -e "${GREEN}配置文件:${NC}"
    echo "  $CONFIG"
    if [ -f "$CONFIG" ]; then
        echo "  存在: ✓"
        local nodes=$(grep -c '"tag": "proxy-' "$CONFIG" 2>/dev/null)
        echo "  节点数: $nodes"
    else
        echo "  存在: ✗"
    fi
    echo ""
    echo -e "${GREEN}服务状态:${NC}"
    sudo systemctl is-active sing-box 2>/dev/null || echo "  未知"
    echo ""
    echo -e "${GREEN}代理地址:${NC}"
    echo "  HTTP:  http://127.0.0.1:7897"
    echo "  SOCKS: socks5://127.0.0.1:7897"
    echo ""
    echo -e "${GREEN}API 地址:${NC}"
    echo "  http://127.0.0.1:9090"
    echo ""
    echo -e "${GREEN}Skill 目录:${NC}"
    echo "  $SKILL_DIR"
}

version() {
    sing-box version
}

proxy_on() {
    export http_proxy=http://127.0.0.1:7897
    export https_proxy=http://127.0.0.1:7897
    export all_proxy=socks5://127.0.0.1:7897
    export HTTP_PROXY=http://127.0.0.1:7897
    export HTTPS_PROXY=http://127.0.0.1:7897
    export ALL_PROXY=socks5://127.0.0.1:7897
    echo -e "${GREEN}✓ 终端代理已开启${NC}"
    echo "  http_proxy=$http_proxy"
    echo "  https_proxy=$https_proxy"
    echo ""
    echo "测试: curl https://ip.sb"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo -e "${YELLOW}✓ 终端代理已关闭${NC}"
}

# 主入口
case "${1:-help}" in
    check) check ;;
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    status) status ;;
    log) log ;;
    enable) enable_service ;;
    disable) disable_service ;;
    test) test_proxy ;;
    api) api ;;
    latency) latency ;;
    panel) panel ;;
    edit) edit_config ;;
    gen) generate_config ;;
    template) copy_template ;;
    info) info ;;
    version) version ;;
    proxy-on) proxy_on ;;
    proxy-off) proxy_off ;;
    *) help ;;
esac
