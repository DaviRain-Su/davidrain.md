#!/usr/bin/env python3
"""
sing-box 配置生成器
从节点信息生成完整的 sing-box JSON 配置

支持协议: Shadowsocks, VMess, VLESS, Trojan

用法:
    python3 generate-config.py --output ~/sing-box-config.json
    
    # 交互式输入节点
    python3 generate-config.py --interactive --output ~/sing-box-config.json
"""

import json
import argparse
import sys
from typing import List, Dict, Any


def create_dns_config() -> Dict[str, Any]:
    """创建 DNS 配置"""
    return {
        "servers": [
            {
                "tag": "dns-local",
                "address": "udp://114.114.114.114",
                "detour": "direct-out"
            },
            {
                "tag": "google",
                "address": "https://8.8.8.8/dns-query"
            }
        ],
        "rules": [
            {
                "query_type": ["HTTPS", "PTR", "SRV", "TXT"],
                "action": "reject"
            },
            {
                "rule_set": "geosite-cn",
                "server": "dns-local"
            },
            {
                "rule_set": "geoip-cn",
                "server": "dns-local"
            }
        ],
        "final": "google"
    }


def create_inbounds_config() -> List[Dict[str, Any]]:
    """创建入站配置"""
    return [
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "0.0.0.0",
            "listen_port": 7897
        },
        {
            "type": "tun",
            "tag": "tun-in",
            "address": [
                "172.19.16.1/30",
                "fdfe:dcba:9876::1/126"
            ],
            "auto_route": True,
            "strict_route": True,
            "stack": "system",
            "auto_redirect": True,
            "route_exclude_address": [
                "192.168.0.0/16",
                "10.0.0.0/8",
                "172.16.0.0/12"
            ]
        }
    ]


def create_outbound(node: Dict[str, Any], index: int) -> Dict[str, Any]:
    """根据节点信息创建出站配置"""
    protocol = node.get("protocol", "shadowsocks").lower()
    tag = node.get("tag", f"proxy-{protocol}-{index}")
    
    if protocol == "shadowsocks":
        return {
            "type": "shadowsocks",
            "tag": tag,
            "server": node["server"],
            "server_port": node["port"],
            "method": node.get("method", "aes-256-gcm"),
            "password": node["password"]
        }
    elif protocol == "vmess":
        outbound = {
            "type": "vmess",
            "tag": tag,
            "server": node["server"],
            "server_port": node["port"],
            "uuid": node["uuid"],
            "security": node.get("security", "auto"),
            "alter_id": node.get("alter_id", 0)
        }
        # 添加 TLS 配置（如果需要）
        if node.get("tls"):
            outbound["tls"] = {
                "enabled": True,
                "server_name": node.get("sni", node["server"])
            }
        # 添加传输配置（ws/grpc 等）
        if node.get("transport"):
            outbound["transport"] = node["transport"]
        return outbound
    elif protocol == "vless":
        outbound = {
            "type": "vless",
            "tag": tag,
            "server": node["server"],
            "server_port": node["port"],
            "uuid": node["uuid"]
        }
        if node.get("tls"):
            outbound["tls"] = {
                "enabled": True,
                "server_name": node.get("sni", node["server"])
            }
        if node.get("transport"):
            outbound["transport"] = node["transport"]
        return outbound
    elif protocol == "trojan":
        outbound = {
            "type": "trojan",
            "tag": tag,
            "server": node["server"],
            "server_port": node["port"],
            "password": node["password"]
        }
        if node.get("tls"):
            outbound["tls"] = {
                "enabled": True,
                "server_name": node.get("sni", node["server"])
            }
        return outbound
    else:
        raise ValueError(f"不支持的协议: {protocol}")


def create_route_config(outbound_tags: List[str]) -> Dict[str, Any]:
    """创建路由配置"""
    proxy_domains = [
        "claude.ai", "claude.com", "anthropic.com",
        "chatgpt.com", "openai.com", "grok.com",
        "google.com", "googleapis.com", "x.ai",
        "slack.com", "manus.im", "intercom.com",
        "posthog.com", "wisprflow.ai", "linear.app",
        "gumloop.com", "granola.ai", "ampcode.com",
        "typeless.com", "rudderstack.com", "typeless-static.com",
        "verisoul.ai", "alchemy.com"
    ]
    
    direct_domains = [
        "tailscale.com", "tailscale.io", "ts.net",
        "speedtest.net", ".chime.aws", ".local",
        "factory.ai", "okx.com", "bitget.com",
        "binance.com", "bitgetapps.com"
    ]
    
    return {
        "rules": [
            {"action": "sniff"},
            {"protocol": "dns", "action": "hijack-dns"},
            {"domain_suffix": direct_domains, "action": "route", "outbound": "direct-out"},
            {"ip_cidr": ["100.64.0.0/10", "fd7a:115c:a1e0::/48"], "action": "route", "outbound": "direct-out"},
            {"ip_is_private": True, "action": "route", "outbound": "direct-out"},
            {"rule_set": "geosite-cn", "action": "route", "outbound": "direct-out"},
            {"rule_set": "geoip-cn", "action": "route", "outbound": "direct-out"},
            {"domain_suffix": proxy_domains, "action": "route", "outbound": "proxy"}
        ],
        "rule_set": [
            {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-cn.srs"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-cn.srs"
            }
        ],
        "final": "proxy-hk",
        "auto_detect_interface": True
    }


def generate_config(nodes: List[Dict[str, Any]]) -> Dict[str, Any]:
    """生成完整配置"""
    # 创建出站配置
    outbounds = [
        {"type": "direct", "tag": "direct-out"}
    ]
    
    node_tags = []
    for i, node in enumerate(nodes):
        outbound = create_outbound(node, i)
        outbounds.append(outbound)
        node_tags.append(outbound["tag"])
    
    # 添加 selector
    all_outbounds = node_tags + ["direct-out"]
    outbounds.append({
        "type": "selector",
        "tag": "proxy",
        "outbounds": all_outbounds
    })
    outbounds.append({
        "type": "selector",
        "tag": "proxy-hk",
        "outbounds": all_outbounds
    })
    
    return {
        "log": {"level": "info"},
        "experimental": {
            "cache_file": {
                "enabled": True,
                "store_fakeip": True
            },
            "clash_api": {
                "external_controller": "127.0.0.1:9090",
                "secret": "",
                "default_mode": "rule"
            }
        },
        "dns": create_dns_config(),
        "inbounds": create_inbounds_config(),
        "outbounds": outbounds,
        "route": create_route_config(node_tags)
    }


def interactive_input() -> List[Dict[str, Any]]:
    """交互式输入节点信息"""
    nodes = []
    print("=== sing-box 节点配置 ===")
    print("支持的协议: shadowsocks, vmess, vless, trojan")
    print("输入空协议结束")
    print()
    
    while True:
        protocol = input("协议 (shadowsocks/vmess/vless/trojan/空=结束): ").strip().lower()
        if not protocol:
            break
        
        if protocol not in ["shadowsocks", "vmess", "vless", "trojan"]:
            print(f"不支持的协议: {protocol}")
            continue
        
        node = {"protocol": protocol}
        node["server"] = input("服务器地址: ").strip()
        node["port"] = int(input("端口: ").strip())
        node["tag"] = input("节点标签 (如 proxy-jp): ").strip()
        
        if protocol in ["shadowsocks", "trojan"]:
            node["password"] = input("密码: ").strip()
            if protocol == "shadowsocks":
                node["method"] = input("加密方式 (默认 aes-256-gcm): ").strip() or "aes-256-gcm"
        elif protocol in ["vmess", "vless"]:
            node["uuid"] = input("UUID: ").strip()
            node["security"] = input("加密方式 (默认 auto): ").strip() or "auto"
            node["alter_id"] = int(input("Alter ID (默认 0): ").strip() or "0")
        
        tls = input("是否启用 TLS? (y/N): ").strip().lower()
        if tls == "y":
            node["tls"] = True
            node["sni"] = input("SNI 域名 (默认服务器地址): ").strip() or node["server"]
        
        transport = input("传输方式 (tcp/ws/grpc/httpupgrade/空): ").strip()
        if transport:
            node["transport"] = {"type": transport}
            if transport == "ws":
                path = input("WebSocket 路径 (默认 /): ").strip() or "/"
                node["transport"]["path"] = path
        
        nodes.append(node)
        print(f"✓ 已添加节点: {node['tag']}")
        print()
    
    return nodes


def parse_nodes_from_text(text: str) -> List[Dict[str, Any]]:
    """从文本解析节点信息（简化版，支持常见格式）"""
    nodes = []
    # 这里可以实现从分享链接解析 (ss://, vmess://, vless://, trojan://)
    # 目前返回空列表，需要手动输入或使用交互模式
    return nodes


def main():
    parser = argparse.ArgumentParser(description="sing-box 配置生成器")
    parser.add_argument("--output", "-o", default="~/sing-box-config.json",
                        help="输出文件路径 (默认: ~/sing-box-config.json)")
    parser.add_argument("--interactive", "-i", action="store_true",
                        help="交互式输入节点信息")
    parser.add_argument("--from-template", "-t", action="store_true",
                        help="从模板复制并修改")
    
    args = parser.parse_args()
    
    output_path = args.output.replace("~", "/home/davirain")
    
    if args.from_template:
        import shutil
        template = "/home/davirain/.pi/agent/skills/sing-box-manager/config-template.json"
        shutil.copy(template, output_path)
        print(f"✓ 已从模板复制配置到: {output_path}")
        print("请编辑配置文件替换为你的节点信息")
        return
    
    if args.interactive:
        nodes = interactive_input()
    else:
        # 尝试从环境变量或标准输入读取
        nodes = parse_nodes_from_text("")
        if not nodes:
            print("未提供节点信息，使用交互模式...")
            nodes = interactive_input()
    
    if not nodes:
        print("错误: 没有配置任何节点")
        sys.exit(1)
    
    config = generate_config(nodes)
    
    with open(output_path, "w") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ 配置已保存到: {output_path}")
    print(f"  共 {len(nodes)} 个节点")
    for node in nodes:
        print(f"  - {node['tag']}: {node['protocol']}://{node['server']}:{node['port']}")
    print("\n验证配置:")
    print(f"  sing-box check -c {output_path}")
    print("\n启动服务:")
    print("  sudo systemctl restart sing-box")


if __name__ == "__main__":
    main()
