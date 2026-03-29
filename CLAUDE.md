# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

本仓库是用户 tyk 的个人 AI Agent Skills 集合（`my-ai-skill`），用于统一管理跨 IDE/Agent 工具（Claude Code、Cursor、Codex、GitHub Copilot、Kimi CLI 等）使用的技能。

Skills 以文件夹形式存储在 `skills/` 目录，每个文件夹至少包含一个 `SKILL.md`（技能定义文件）。`.skill-lock.json` 是技能注册表，记录每个 skill 的来源仓库、安装时间、文件哈希等元数据。

## Skills CLI 常用命令

```bash
# 安装来自某仓库的所有 skills
npx skills add <owner/repo>

# 按需安装指定 skill
npx skills add vercel-labs/agent-skills -s react-best-practices

# 指定目标 Agent
npx skills add vercel-labs/agent-skills -a claude-code

# 全局安装（所有项目生效）
npx skills add vercel-labs/agent-skills -g

# 查看已安装 / 检查更新 / 更新 / 移除
npx skills list
npx skills check
npx skills update
npx skills remove <skill-name>
```

关闭匿名遥测：`DISABLE_TELEMETRY=1`

## 仓库结构

- `skills/<skill-name>/SKILL.md` — 技能定义主文件，包含 frontmatter（name、description、tools）和执行指令
- `skills/<skill-name>/references/` — 部分 skill 携带的参考文档
- `skills/<skill-name>/scripts/` — 部分 skill 携带的辅助脚本
- `.skill-lock.json` — 技能注册表（版本锁定）
- `readme.md` — Skills 生态使用说明（中文）

## 技能来源

| 来源 | 描述 |
|---|---|
| `vercel-labs/agent-skills` | Vercel 官方技能集（react-best-practices、web-design-guidelines 等） |
| `obra/superpowers` | 开发工作流技能（brainstorming、writing-plans、executing-plans 等） |
| `anthropics/skills` | Anthropic 官方（skill-creator、mcp-builder） |
| `sickn33/antigravity-awesome-skills` | 社区精选（file-organizer、code-reviewer、requesting-code-review 等） |
| `local-workspace` | 本地自定义技能（frontend-design、code-simplifier、ai-context-file-improver 等） |

## 修改技能

- 修改 `SKILL.md` 时保持现有 frontmatter 格式（`name`、`description`、`tools` 字段）
- 本地自定义 skill（`sourceType: "local"`）不受 `npx skills update` 影响，可自由编辑
- 从远程来源安装的 skill 在执行 `npx skills update` 时会被覆盖，若需持久化自定义改动应将 `sourceType` 改为 `local`

## 新增本地技能

在 `skills/` 下新建文件夹，添加 `SKILL.md`，然后手动在 `.skill-lock.json` 中注册：

```json
"<skill-name>": {
  "source": "local-workspace",
  "sourceType": "local",
  "sourceUrl": "",
  "skillPath": "skills/<skill-name>/SKILL.md",
  "skillFolderHash": "",
  "installedAt": "<ISO8601时间>",
  "updatedAt": "<ISO8601时间>"
}
```
