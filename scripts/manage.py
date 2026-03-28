#!/usr/bin/env python3
"""
DavidRain Skill 管理系统

功能：
1. 生成索引 - 更新所有 Skill 的 README 和主索引
2. 拆分文档 - 当 Skill 过大时自动拆分
3. 验证结构 - 检查 Skill 格式是否正确
4. 创建模板 - 基于模板创建新 Skill

用法：
    python manage.py --update-index          # 更新索引
    python manage.py --split <skill-path>    # 拆分 Skill
    python manage.py --validate              # 验证所有 Skill
    python manage.py --create <name> <category>  # 创建新 Skill
"""

import os
import sys
import re
import argparse
from datetime import datetime
from pathlib import Path

# 颜色输出
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_status(msg, status="info"):
    color = {"success": Colors.GREEN, "warning": Colors.YELLOW, 
             "error": Colors.RED, "info": Colors.BLUE}.get(status, Colors.BLUE)
    print(f"{color}[{status.upper()}]{Colors.END} {msg}")

# ========== 1. 生成索引 ==========

def extract_skill_info(skill_path):
    """从 SKILL.md 提取信息"""
    with open(skill_path, 'r') as f:
        content = f.read()
    
    # 提取 YAML frontmatter
    frontmatter_match = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not frontmatter_match:
        return None
    
    fm = frontmatter_match.group(1)
    
    # 解析字段
    info = {}
    info['name'] = re.search(r'^name:\s*(.+)$', fm, re.M)
    info['description'] = re.search(r'^description:\s*(.+)$', fm, re.M)
    info['version'] = re.search(r'^version:\s*(.+)$', fm, re.M)
    
    for key in info:
        info[key] = info[key].group(1).strip() if info[key] else "N/A"
    
    # 提取第一个 H1 作为标题
    h1_match = re.search(r'^#\s+(.+)$', content, re.M)
    info['title'] = h1_match.group(1) if h1_match else info['name']
    
    return info

def generate_index():
    """生成所有 Skill 的索引"""
    print_status("开始生成索引...", "info")
    
    base_dir = Path(__file__).parent.parent
    skills_data = {
        'principles': [],
        'crafts': [],
        'experiences': []
    }
    
    # 扫描所有 Skill
    for category in skills_data.keys():
        category_path = base_dir / category
        if not category_path.exists():
            continue
            
        for skill_dir in category_path.iterdir():
            if skill_dir.is_dir():
                skill_file = skill_dir / "SKILL.md"
                if skill_file.exists():
                    info = extract_skill_info(skill_file)
                    if info:
                        info['path'] = f"{category}/{skill_dir.name}"
                        info['category'] = category
                        skills_data[category].append(info)
    
    # 生成主索引文件
    index_content = generate_main_index(skills_data)
    with open(base_dir / "INDEX.md", "w") as f:
        f.write(index_content)
    
    # 更新主 SKILL.md
    update_main_skill(skills_data)
    
    print_status(f"索引生成完成！共 {sum(len(v) for v in skills_data.values())} 个 Skill", "success")

def generate_main_index(skills_data):
    """生成主索引文件"""
    content = f"""# DavidRain Skill 索引

> 自动生成于 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 快速导航

"""
    
    category_names = {
        'principles': 'Principles（方法论）',
        'crafts': 'Crafts（技术技能）',
        'experiences': 'Experiences（实战经验）'
    }
    
    for category, skills in skills_data.items():
        if not skills:
            continue
            
        content += f"### {category_names.get(category, category)}\n\n"
        content += "| Skill | 描述 | 版本 |\n"
        content += "|-------|------|------|\n"
        
        for skill in sorted(skills, key=lambda x: x['name']):
            content += f"| [{skill['name']}](./{skill['path']}/SKILL.md) | {skill['description'][:50]}... | {skill['version']} |\n"
        
        content += "\n"
    
    content += """## 使用方式

```python
# 加载主 Skill
skill_view("davidrain")

# 加载特定子 Skill
skill_view("elon-musk-methods")
skill_view("sui-move-patterns")
skill_view("hackathon-playbook")
```

## 添加新 Skill

```bash
python scripts/manage.py --create <skill-name> <category>
```

---

*此文件由 manage.py 自动生成，请勿手动编辑*
"""
    
    return content

def update_main_skill(skills_data):
    """更新主 SKILL.md 的子 Skill 列表"""
    base_dir = Path(__file__).parent.parent
    skill_file = base_dir / "SKILL.md"
    
    with open(skill_file, 'r') as f:
        content = f.read()
    
    # 生成新的子 Skill 表格
    category_names = {
        'principles': 'Principles（方法论）',
        'crafts': 'Crafts（技术技能）',
        'experiences': 'Experiences（实战经验）'
    }
    
    new_section = "## 子 Skill 目录\n\n"
    
    for category, skills in skills_data.items():
        if not skills:
            continue
            
        new_section += f"### {category_names.get(category, category)}\n\n"
        new_section += "| Skill | 描述 | 适用场景 |\n"
        new_section += "|-------|------|----------|\n"
        
        for skill in sorted(skills, key=lambda x: x['name']):
            desc = skill['description'][:40] + "..." if len(skill['description']) > 40 else skill['description']
            new_section += f"| `{skill['name']}` | {desc} | 待补充 |\n"
        
        new_section += "\n"
    
    # 替换旧的子 Skill 部分
    pattern = r'## 子 Skill 目录.*?(?=---|$)'
    if re.search(pattern, content, re.DOTALL):
        content = re.sub(pattern, new_section + "\n---\n", content, flags=re.DOTALL)
    
    with open(skill_file, 'w') as f:
        f.write(content)

# ========== 2. 拆分文档 ==========

def split_skill(skill_path):
    """拆过大的 Skill 为多个子文件"""
    skill_path = Path(skill_path)
    if not skill_path.exists():
        print_status(f"Skill 不存在: {skill_path}", "error")
        return
    
    with open(skill_path, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    if len(lines) < 200:
        print_status(f"Skill 只有 {len(lines)} 行，无需拆分", "warning")
        return
    
    print_status(f"开始拆分 {skill_path} ({len(lines)} 行)...", "info")
    
    # 创建目录结构
    skill_dir = skill_path.parent
    refs_dir = skill_dir / "references"
    templates_dir = skill_dir / "templates"
    refs_dir.mkdir(exist_ok=True)
    templates_dir.mkdir(exist_ok=True)
    
    # 解析结构，提取主要章节
    sections = []
    current_section = None
    
    for line in lines:
        if line.startswith('## '):
            if current_section:
                sections.append(current_section)
            current_section = {'title': line[3:], 'content': [line], 'level': 2}
        elif line.startswith('### ') and current_section:
            current_section['content'].append(line)
        elif current_section:
            current_section['content'].append(line)
    
    if current_section:
        sections.append(current_section)
    
    # 保留核心内容在主文件，其他移到 references
    main_sections = sections[:3]  # 前 3 个章节保留在主文件
    ref_sections = sections[3:]   # 其余移到 references
    
    # 生成主文件
    main_content = []
    
    # 保留 frontmatter
    frontmatter_match = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if frontmatter_match:
        main_content.append('---')
        main_content.append(frontmatter_match.group(1))
        main_content.append('---')
        main_content.append('')
    
    # 添加主章节
    for section in main_sections:
        main_content.extend(section['content'])
        main_content.append('')
    
    # 添加 references 链接
    if ref_sections:
        main_content.append('## 详细参考')
        main_content.append('')
        main_content.append('更多信息请查看：')
        main_content.append('')
        for section in ref_sections:
            filename = section['title'].lower().replace(' ', '-').replace('(', '').replace(')', '') + '.md'
            main_content.append(f"- [{section['title']}](./references/{filename})")
        main_content.append('')
    
    # 写回主文件
    with open(skill_path, 'w') as f:
        f.write('\n'.join(main_content))
    
    # 写入 reference 文件
    for section in ref_sections:
        filename = section['title'].lower().replace(' ', '-').replace('(', '').replace(')', '') + '.md'
        ref_path = refs_dir / filename
        with open(ref_path, 'w') as f:
            f.write(f"# {section['title']}\n\n")
            f.write('\n'.join(section['content'][1:]))  # 跳过标题行
        print_status(f"创建 reference: {filename}", "success")
    
    print_status("拆分完成！", "success")

# ========== 3. 验证结构 ==========

def validate_skills():
    """验证所有 Skill 的格式"""
    print_status("开始验证 Skill 结构...", "info")
    
    base_dir = Path(__file__).parent.parent
    errors = []
    
    for category in ['principles', 'crafts', 'experiences']:
        category_path = base_dir / category
        if not category_path.exists():
            continue
            
        for skill_dir in category_path.iterdir():
            if not skill_dir.is_dir():
                continue
                
            skill_file = skill_dir / "SKILL.md"
            
            # 检查文件存在
            if not skill_file.exists():
                errors.append(f"{skill_dir.name}: 缺少 SKILL.md")
                continue
            
            with open(skill_file, 'r') as f:
                content = f.read()
            
            # 检查 frontmatter
            if not re.search(r'^---\s*\n', content):
                errors.append(f"{skill_dir.name}: 缺少 YAML frontmatter")
            
            # 检查必需字段
            required_fields = ['name:', 'description:', 'version:']
            for field in required_fields:
                if field not in content:
                    errors.append(f"{skill_dir.name}: 缺少字段 {field}")
            
            # 检查内容长度
            lines = content.split('\n')
            if len(lines) < 20:
                errors.append(f"{skill_dir.name}: 内容过短 ({len(lines)} 行)")
    
    if errors:
        print_status(f"发现 {len(errors)} 个问题:", "error")
        for error in errors:
            print(f"  - {error}")
    else:
        print_status("所有 Skill 验证通过！", "success")

# ========== 4. 创建模板 ==========

def create_skill(name, category):
    """基于模板创建新 Skill"""
    base_dir = Path(__file__).parent.parent
    
    # 验证类别
    if category not in ['principles', 'crafts', 'experiences']:
        print_status(f"无效的类别: {category}", "error")
        print("有效类别: principles, crafts, experiences")
        return
    
    # 创建目录
    skill_dir = base_dir / category / name
    if skill_dir.exists():
        print_status(f"Skill 已存在: {name}", "error")
        return
    
    skill_dir.mkdir(parents=True)
    (skill_dir / "references").mkdir()
    (skill_dir / "templates").mkdir()
    
    # 读取模板
    template_path = base_dir / "templates" / "skill-template.md"
    if template_path.exists():
        with open(template_path, 'r') as f:
            template = f.read()
    else:
        template = generate_default_template()
    
    # 填充模板
    content = template.replace('{{name}}', name)
    content = content.replace('{{category}}', category)
    content = content.replace('{{date}}', datetime.now().strftime('%Y-%m-%d'))
    
    # 写入文件
    skill_file = skill_dir / "SKILL.md"
    with open(skill_file, 'w') as f:
        f.write(content)
    
    print_status(f"创建 Skill: {name}", "success")
    print(f"  路径: {skill_file}")
    print(f"  类别: {category}")
    print(f"\n下一步:")
    print(f"  1. 编辑 {skill_file}")
    print(f"  2. 运行 python manage.py --update-index")

def generate_default_template():
    """生成默认模板"""
    return """---
name: {{name}}
description: 描述这个 Skill 的用途和内容
version: 1.0.0
author: DavidRain
license: MIT
metadata:
  hermes:
    tags: [tag1, tag2, tag3]
    related_skills: [davidrain]
    category: {{category}}
---

# {{name}}

简要介绍这个 Skill 的内容和用途。

---

## 一、何时使用这个 Skill

使用场景：
- ✅ 场景 1
- ✅ 场景 2
- ✅ 场景 3

---

## 二、核心内容

### 主题 1

详细说明...

### 主题 2

详细说明...

---

## 三、实践检查清单

- [ ] 检查项 1
- [ ] 检查项 2
- [ ] 检查项 3

---

## 四、常见问题

**Q: 问题 1？**
A: 回答...

**Q: 问题 2？**
A: 回答...

---

*创建时间: {{date}}*
"""

# ========== 主函数 ==========

def main():
    parser = argparse.ArgumentParser(description='DavidRain Skill 管理系统')
    parser.add_argument('--update-index', action='store_true', help='更新所有索引')
    parser.add_argument('--split', metavar='PATH', help='拆分指定的 Skill')
    parser.add_argument('--validate', action='store_true', help='验证所有 Skill')
    parser.add_argument('--create', nargs=2, metavar=('NAME', 'CATEGORY'), help='创建新 Skill')
    
    args = parser.parse_args()
    
    if args.update_index:
        generate_index()
    elif args.split:
        split_skill(args.split)
    elif args.validate:
        validate_skills()
    elif args.create:
        create_skill(args.create[0], args.create[1])
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
