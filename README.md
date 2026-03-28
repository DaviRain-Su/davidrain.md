# DavidRain Skill

个人经验库 Skill - 包含方法论、技术技能和实战经验的可执行知识系统。

## 核心理念

> **经验不是经历，而是对经历的反思。**

这个 Skill 系统分为三个层次：

| 层次 | 问题 | 内容 | 对应目录 |
|------|------|------|----------|
| **Principles** | Why? | 思维模式、决策框架、管理哲学 | `principles/` |
| **Crafts** | How? | 技术技能、工具使用、最佳实践 | `crafts/` |
| **Experiences** | What? | 实战案例、踩坑记录、复盘总结 | `experiences/` |

## 快速开始

### 使用 Skill

```python
# 加载主 Skill
skill_view("davidrain")

# 加载特定子 Skill
skill_view("elon-musk-methods")    # Elon Musk 方法论
skill_view("sui-move-patterns")    # Sui Move 开发技巧
skill_view("hackathon-playbook")   # Hackathon 攻略
```

### 添加新经验

```bash
# 1. 创建新 Skill
python scripts/manage.py --create <skill-name> <category>

# 2. 编辑生成的 SKILL.md

# 3. 更新索引
python scripts/manage.py --update-index

# 4. 提交
git add .
git commit -m "添加 <skill-name> Skill"
```

## 目录结构

```
davidrain-skill/
├── SKILL.md                    # 主入口
├── INDEX.md                    # 自动生成的索引
├── README.md                   # 本文件
│
├── principles/                 # 方法论（Why）
│   └── elon-musk-methods/      # Elon Musk 管理哲学
│       ├── SKILL.md
│       └── references/
│
├── crafts/                     # 技术技能（How）
│   └── sui-move-patterns/      # Sui Move 开发模式
│       ├── SKILL.md
│       ├── references/
│       └── templates/
│
├── experiences/                # 实战经验（What）
│   └── hackathon-playbook/     # Hackathon 攻略
│       ├── SKILL.md
│       ├── references/
│       └── templates/
│
├── scripts/                    # 管理脚本
│   └── manage.py               # Skill 管理工具
│
└── templates/                  # 文件模板
    └── skill-template.md       # 新 Skill 模板
```

## 管理脚本

### 更新索引
```bash
python scripts/manage.py --update-index
```

### 验证 Skill 格式
```bash
python scripts/manage.py --validate
```

### 拆分大文档
```bash
python scripts/manage.py --split <path/to/SKILL.md>
```

### 创建新 Skill
```bash
python scripts/manage.py --create <name> <category>
# category: principles | crafts | experiences
```

## 设计原则

### 1. 可执行性
每个 Skill 必须能直接指导行动，不只是理论知识。

### 2. 模块化
每个 Skill 独立存在，可以单独加载使用。

### 3. 可验证
包含检查清单（Checklist）和验证步骤。

### 4. 渐进式
从简单开始，逐步深化。

## 与 Cloud Code / Cursor 集成

可以在 `.cursorrules` 中添加：

```yaml
skills:
  - davidrain
  - elon-musk-methods
  - sui-move-patterns
  - hackathon-playbook

triggers:
  - pattern: "如何做.*决策"
    skill: elon-musk-methods
  - pattern: "Move|合约"
    skill: sui-move-patterns
  - pattern: "Hackathon|黑客松"
    skill: hackathon-playbook
```

## 贡献

这个 Skill 系统是活的文档：

- 每次项目结束 → 更新 Experiences
- 每次技术突破 → 更新 Crafts
- 每次认知升级 → 更新 Principles

## License

MIT

---

*Created by DavidRain*
