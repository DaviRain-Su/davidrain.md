# sing-box-manager

管理 sing-box 代理服务的完整方案，支持从节点信息生成配置、服务管理、节点切换、状态监控。

## 功能

- 从节点信息（图片/文字）解析并生成 sing-box 配置
- 安装/更新 sing-box
- 启动/停止/重启服务
- 设置 systemd 开机自启
- 节点切换与延迟测试
- 查看运行状态、日志、流量
- Clash API 面板监控
- 终端代理环境变量快速切换

## 文件结构

```
sing-box-manager/
├── SKILL.md              # 本文件
├── config-template.json  # 当前使用的配置模板（含6节点）
├── install.sh            # 一键安装 sing-box
├── utils.sh              # 常用命令封装
└── generate-config.py    # 从节点信息生成配置
```

## 快速开始

### 1. 安装 sing-box

```bash
bash ~/.pi/agent/skills/sing-box-manager/install.sh
```

### 2. 生成配置（从节点信息）

提供节点信息图片或文字，运行：

```bash
python3 ~/.pi/agent/skills/sing-box-manager/generate-config.py \
  --output ~/sing-box-config.json
```

或直接复制模板修改：

```bash
cp ~/.pi/agent/skills/sing-box-manager/config-template.json ~/sing-box-config.json
# 编辑 ~/sing-box-config.json 替换为你的节点信息
```

### 3. 启动服务

```bash
# 验证配置
sing-box check -c ~/sing-box-config.json

# 启动并设置开机自启
sudo systemctl enable --now sing-box

# 查看状态
sudo systemctl status sing-box --no-pager
```

## 常用命令速查

### 服务管理

```bash
source ~/.pi/agent/skills/sing-box-manager/utils.sh start     # 启动
source ~/.pi/agent/skills/sing-box-manager/utils.sh stop      # 停止
source ~/.pi/agent/skills/sing-box-manager/utils.sh restart   # 重启
source ~/.pi/agent/skills/sing-box-manager/utils.sh status    # 查看状态
source ~/.pi/agent/skills/sing-box-manager/utils.sh log       # 实时日志
source ~/.pi/agent/skills/sing-box-manager/utils.sh enable    # 开机自启
source ~/.pi/agent/skills/sing-box-manager/utils.sh disable   # 取消开机自启
```

### 代理测试

```bash
source ~/.pi/agent/skills/sing-box-manager/utils.sh test      # 测试代理连接
source ~/.pi/agent/skills/sing-box-manager/utils.sh api       # 查看节点状态
```

### 终端代理切换

```bash
source ~/.pi/agent/skills/sing-box-manager/utils.sh proxy-on  # 开启终端代理
source ~/.pi/agent/skills/sing-box-manager/utils.sh proxy-off # 关闭终端代理
```

### 面板

```bash
source ~/.pi/agent/skills/sing-box-manager/utils.sh panel     # 启动本地 yacd 面板
```

## 节点配置说明

当前模板包含6个节点，按优先级排序：

| 顺序 | 节点标签 | 协议 | 服务器 | 地区 |
|------|----------|------|--------|------|
| 1 | proxy-vmess-2 | VMess | 45.78.63.89 | **日本大阪** ⭐ |
| 2 | proxy-ss-1 | Shadowsocks | 67.209.179.232 | 美国 |
| 3 | proxy-ss-2 | Shadowsocks | 67.209.183.7 | 美国 |
| 4 | proxy-vmess-1 | VMess | 93.179.99.201 | 美国 |
| 5 | proxy-vmess-3 | VMess | 162.248.74.16 | 美国 |
| 6 | proxy-vmess-4 | VMess | 45.62.106.182 | 美国 |

### 切换默认节点

编辑 `~/sing-box-config.json`，找到 `proxy` 和 `proxy-hk` 的 `outbounds` 数组，把想用的节点移到第一个：

```json
{
  "type": "selector",
  "tag": "proxy",
  "outbounds": ["proxy-vmess-2", "proxy-ss-1", "proxy-ss-2", ...]
}
```

然后重启服务：

```bash
sudo systemctl restart sing-box
```

## 代理设置

服务启动后：

- **HTTP/SOCKS 代理**: `http://127.0.0.1:7897`
- **TUN 模式**: 自动接管系统流量（需要 sudo）

### 浏览器/应用代理

在浏览器或应用中设置代理为 `http://127.0.0.1:7897` 或 `socks5://127.0.0.1:7897`

### 系统全局代理（GNOME）

Settings → Network → Network Proxy → Manual → HTTP: `127.0.0.1:7897`

### 终端临时使用

```bash
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=socks5://127.0.0.1:7897
```

## Clash API 面板

配置已内置 Clash API（端口 9090）：

- **在线面板**: https://yacd.metacubex.one/
  - API Base URL: `http://127.0.0.1:9090`
  - Secret: 留空

- **本地面板**:
  ```bash
  source ~/.pi/agent/skills/sing-box-manager/utils.sh panel
  # 打开 http://localhost:1234
  ```

## 配置说明

生成的配置包含：

- **DNS**: 国内外分流，国内用 114.114.114.114，国外用 8.8.8.8
- **入站**: mixed (7897) + tun (透明代理)
- **出站**: 多个代理节点 + selector 自动切换
- **路由规则**:
  - 国内域名/IP 直连
  - 指定域名（AI、社交等）走代理
  - 其余默认走代理
- **规则集**: geosite-cn, geoip-cn 自动更新

## 故障排查

```bash
# 检查配置语法
sing-box check -c ~/sing-box-config.json

# 查看详细日志
sudo journalctl -u sing-box -n 100 --no-pager

# 测试代理是否工作
curl -x http://127.0.0.1:7897 https://www.google.com

# 查看当前出口 IP
curl -x http://127.0.0.1:7897 https://ip.sb

# 检查端口占用
ss -tlnp | grep -E '7897|9090'

# 检查服务是否开机自启
sudo systemctl is-enabled sing-box
```

## 更新

```bash
# 更新 sing-box
bash ~/.pi/agent/skills/sing-box-manager/install.sh

# 更新规则集（自动）
# sing-box 启动时会自动下载远程规则集
```

## 参考

- [sing-box 文档](https://sing-box.sagernet.org/)
- [Clash API 文档](https://github.com/Dreamacro/clash/wiki/external-controller-API-reference)
