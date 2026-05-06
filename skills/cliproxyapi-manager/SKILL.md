# cliproxyapi-manager

管理 CLIProxyAPI 服务的 skill，支持 OAuth 登录、服务管理、配置管理。

## 功能

- 安装/更新 CLIProxyAPI
- OAuth 登录（Codex/Claude/Gemini）
- 服务启动/停止/重启
- 设置 systemd 用户服务开机自启
- 查看状态、日志、可用模型
- API 测试

## 依赖

- Go 1.25+
- sing-box（用于代理，可选但推荐）

## 快速开始

### 1. 安装 CLIProxyAPI

```bash
bash ~/.pi/agent/skills/cliproxyapi-manager/install.sh
```

或手动编译：

```bash
cd /tmp
git clone https://github.com/router-for-me/CLIProxyAPI.git
cd CLIProxyAPI
go build -o cliproxyapi ./cmd/server
cp cliproxyapi ~/.local/bin/
```

### 2. 配置

编辑配置文件：

```bash
nano ~/.cli-proxy-api/config.yaml
```

基础配置：

```yaml
host: "127.0.0.1"
port: 8317

remote-management:
  allow-remote: false
  secret-key: "your-management-secret"
  disable-control-panel: false

auth-dir: "~/.cli-proxy-api"

api-keys:
  - "your-api-key-here"

# 通过 sing-box 代理（推荐）
proxy-url: "socks5://127.0.0.1:7897"

request-retry: 3

routing:
  strategy: "round-robin"
  session-affinity: false
```

### 3. OAuth 登录

**Codex (OpenAI):**
```bash
cliproxyapi -config ~/.cli-proxy-api/config.yaml -codex-login
```

**Claude:**
```bash
cliproxyapi -config ~/.cli-proxy-api/config.yaml -claude-login
```

**Gemini:**
```bash
cliproxyapi -config ~/.cli-proxy-api/config.yaml -login
```

**不自动打开浏览器（远程服务器）:**
```bash
cliproxyapi -config ~/.cli-proxy-api/config.yaml -codex-login -no-browser
```

### 4. 启动服务

```bash
# 启动并设置开机自启
systemctl --user enable --now cliproxyapi

# 查看状态
systemctl --user status cliproxyapi
```

## 常用命令

### 服务管理

```bash
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh start     # 启动
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh stop      # 停止
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh restart   # 重启
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh status    # 查看状态
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh log       # 实时日志
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh enable    # 开机自启
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh disable   # 取消开机自启
```

### 认证管理

```bash
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh login-codex    # Codex 登录
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh login-claude   # Claude 登录
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh login-gemini   # Gemini 登录
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh list-auths     # 查看认证
```

### API 测试

```bash
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh models     # 查看可用模型
source ~/.pi/agent/skills/cliproxyapi-manager/utils.sh test       # 测试 API
```

## 使用 API

服务启动后，API 地址：`http://127.0.0.1:8317`

### 在 Cursor 中使用

1. 打开 Cursor Settings → Models
2. 开启 OpenAI API
3. API Key: `your-api-key-here`
4. Base URL: `http://127.0.0.1:8317/v1`

### 在 VSCode 中使用

安装 Continue 或类似插件，配置：
- Provider: OpenAI
- API Key: `your-api-key-here`
- API Base URL: `http://127.0.0.1:8317/v1`
- Model: `gpt-5.4`

### 命令行测试

```bash
# 获取模型列表
curl http://127.0.0.1:8317/v1/models \
  -H "Authorization: Bearer your-api-key-here"

# 聊天完成
curl http://127.0.0.1:8317/v1/chat/completions \
  -H "Authorization: Bearer your-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5.4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## 配置说明

### 支持的认证方式

1. **OAuth 登录**（推荐）
   - Codex: OpenAI 账号登录
   - Claude: Claude 账号登录
   - Gemini: Google 账号登录

2. **API Key**
   - Gemini API Key
   - Claude API Key
   - Codex API Key
   - OpenRouter 等兼容提供商

### 多账号负载均衡

配置多个 OAuth 账号或 API Key，自动轮询：

```yaml
# 多个 Codex OAuth 账号（通过多次登录生成）
# 文件保存在 ~/.cli-proxy-api/codex-*.json

# 多个 Gemini API Key
gemini-api-key:
  - api-key: "AIzaSy...01"
  - api-key: "AIzaSy...02"

# 多个 Claude API Key
claude-api-key:
  - api-key: "sk-ant-...01"
  - api-key: "sk-ant-...02"
```

### 代理设置

通过 sing-box 或其他代理：

```yaml
# SOCKS5 代理
proxy-url: "socks5://127.0.0.1:7897"

# HTTP 代理
proxy-url: "http://127.0.0.1:7897"

# 带认证的代理
proxy-url: "socks5://user:pass@host:port"
```

## 故障排查

```bash
# 检查服务状态
systemctl --user status cliproxyapi

# 查看日志
journalctl --user -u cliproxyapi -f

# 检查端口占用
ss -tlnp | grep 8317

# 测试 API 连通性
curl http://127.0.0.1:8317/v1/models \
  -H "Authorization: Bearer your-api-key-here"

# 检查认证文件
ls -la ~/.cli-proxy-api/

# 验证配置
cliproxyapi -config ~/.cli-proxy-api/config.yaml
```

## 更新

```bash
# 重新编译最新版
cd /tmp/CLIProxyAPI
git pull
go build -o cliproxyapi ./cmd/server
cp cliproxyapi ~/.local/bin/
systemctl --user restart cliproxyapi
```

## Factory CLI (Droid) 代理支持

Factory CLI 的命令名是 `droid`，安装方式：

```bash
curl -fsSL https://app.factory.ai/cli | sh
```

### 证书验证错误修复

如果遇到 `unknown certificate verification error`，使用代理启动脚本：

```bash
# 使用代理启动 droid
source ~/.pi/agent/skills/cliproxyapi-manager/droid-proxy.sh

# 或直接运行
cd ~/.pi/agent/skills/cliproxyapi-manager
./droid-proxy.sh

# 登录
droid login
```

脚本会自动设置代理环境变量：
- `http_proxy=http://127.0.0.1:7897`
- `https_proxy=http://127.0.0.1:7897`

### 永久设置（推荐）

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# Factory CLI 代理
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
```

然后重新加载配置：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

## 参考

- [CLIProxyAPI 文档](https://help.router-for.me/)
- [CLIProxyAPI GitHub](https://github.com/router-for-me/CLIProxyAPI)
- [Codex 配置文档](https://help.router-for.me/configuration/provider/codex.html)
- [Factory CLI](https://app.factory.ai/)
