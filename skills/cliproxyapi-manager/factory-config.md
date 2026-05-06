# Factory CLI (Droid) 配置指南

## 配置文件

### ~/.factory/config.json

```json
{
  "custom_models": [
    {
      "model_display_name": "CC: Opus 4.7 (High)",
      "model": "claude-opus-4-7-thinking-32000",
      "base_url": "http://localhost:8317",
      "api_key": "dummy-not-used",
      "provider": "anthropic"
    },
    {
      "model_display_name": "CC: Opus 4.7",
      "model": "claude-opus-4-7",
      "base_url": "http://localhost:8317",
      "api_key": "dummy-not-used",
      "provider": "anthropic"
    },
    {
      "model_display_name": "CC: Sonnet 4.6",
      "model": "claude-sonnet-4-6",
      "base_url": "http://localhost:8317",
      "api_key": "dummy-not-used",
      "provider": "anthropic"
    },
    {
      "model_display_name": "CC: Sonnet 4.6 (Low)",
      "model": "claude-sonnet-4-6-thinking-4000",
      "base_url": "http://localhost:8317",
      "api_key": "dummy-not-used",
      "provider": "anthropic"
    },
    {
      "model_display_name": "CC: Sonnet 4.6 (Medium)",
      "model": "claude-sonnet-4-6-thinking-10000",
      "base_url": "http://localhost:8317",
      "api_key": "dummy-not-used",
      "provider": "anthropic"
    },
    {
      "model_display_name": "CC: Sonnet 4.6 (High)",
      "model": "claude-sonnet-4-6-thinking-32000",
      "base_url": "http://localhost:8317",
      "api_key": "dummy-not-used",
      "provider": "anthropic"
    },
    {
      "model_display_name": "GPT-5.5",
      "model": "gpt-5.5",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.5 (Low)",
      "model": "gpt-5.5(low)",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.5 (High)",
      "model": "gpt-5.5(high)",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.4",
      "model": "gpt-5.4",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.4 (High)",
      "model": "gpt-5.4(high)",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.4 Mini",
      "model": "gpt-5.4-mini",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.4 Mini (High)",
      "model": "gpt-5.4-mini(high)",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.3 Codex",
      "model": "gpt-5.3-codex",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.3 Codex (High)",
      "model": "gpt-5.3-codex(high)",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "GPT-5.3 Codex Spark",
      "model": "gpt-5.3-codex-spark",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "Gemini 3.1 Pro",
      "model": "gemini-3.1-pro-preview",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "Gemini 3.1 Flash Image",
      "model": "gemini-3.1-flash-image-preview",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "Gemini 2.5 Pro",
      "model": "gemini-2.5-pro",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "Gemini 2.5 Flash",
      "model": "gemini-2.5-flash",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "Gemini 2.5 Flash Lite",
      "model": "gemini-2.5-flash-lite",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    },
    {
      "model_display_name": "Kimi for Coding",
      "model": "kimi-for-coding",
      "base_url": "http://localhost:8317/v1",
      "api_key": "dummy-not-used",
      "provider": "openai"
    }
  ]
}
```

### 配置说明

**Claude 模型** (`provider: "anthropic"`):
- 使用 `base_url: "http://localhost:8317"` (不带 `/v1`)
- 支持 thinking 模式: `-thinking-4000`, `-thinking-10000`, `-thinking-32000`

**OpenAI/Gemini/Kimi 模型** (`provider: "openai"`):
- 使用 `base_url: "http://localhost:8317/v1"` (带 `/v1`)

**模型命名规则**:
- GPT-5.x 推理控制: `gpt-5.5(low)`, `gpt-5.5(high)`, `gpt-5.5(xhigh)`
- Claude thinking: `claude-opus-4-7-thinking-32000`

## 使用方式

1. 启动 CLIProxyAPI: `systemctl --user start cliproxyapi`
2. 启动 droid: `droid`
3. 切换模型: `/model` 然后选择

## 参考

- [VibeProxy Factory Setup](https://github.com/automazeio/vibeproxy/blob/main/FACTORY_SETUP.md)
