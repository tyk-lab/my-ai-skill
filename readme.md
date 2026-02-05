# Skills 生态（Vercel / skills CLI / Agent Skills）要点

- 官方介绍（Vercel Changelog）：https://vercel.com/changelog/introducing-skills-the-open-agent-skills-ecosystem
- 官方技能集合（vercel-labs/agent-skills）：https://github.com/vercel-labs/agent-skills
- `skills` CLI（安装/参数/机制）：https://github.com/vercel-labs/skills

## 安装与管理（常用命令）

- 安装官方集合：

```bash
npx skills add vercel-labs/agent-skills
```

- 列出该仓库提供的 skills：

```bash
npx skills add vercel-labs/agent-skills --list
```

- 按需安装（避免“全家桶”污染上下文）：

```bash
npx skills add vercel-labs/agent-skills -s react-best-practices -s web-design-guidelines
```

- 指定安装给某个/某些 Agent：

```bash
npx skills add vercel-labs/agent-skills -a codex
# 或
npx skills add vercel-labs/agent-skills -a cursor -a claude-code
```

- 全局安装（所有项目生效）：

```bash
npx skills add vercel-labs/agent-skills -g
```

- 查看 / 检查 / 更新 / 移除：

```bash
npx skills list
npx skills check
npx skills update
npx skills remove web-design-guidelines
```

## 使用与触发方式

- 通常：直接用自然语言描述任务；Agent 可能会根据 skill 的 `description` 自动决定是否调用
- 部分工具支持显式点名（例如在提示词里写 `$skill-name`）或通过 UI/命令选择（不同 Agent 交互略不同）

### Codex（CLI / IDE 插件）

- 扫描位置：仓库或用户目录的 `.agents\skills`（每个 skill 是一个文件夹，至少包含 `SKILL.md`）
- 触发：显式（`/skills` 或 `$skill-name`）/ 隐式（按 `description` 自动）
- 禁用：可在 `~/.codex/config.toml` 禁用某个 skill（不删除）
- 排查：如果“装了但看不到”，确认 skill 文件夹在 `$HOME\.agents\skills\` 或仓库根目录 `.agents\skills\`，然后重启 Codex

参考：https://developers.openai.com/codex/skills/

### Cursor / Claude Code / Copilot 等

- 多数情况下装好后自动可用；常见操作是重启/重新加载，让工具重新扫描 skills 目录
- `skills` CLI 通常会放到各工具约定的目录，并支持 symlink（推荐）或 copy

## 更多 skills + 安全与遥测

- 去 skills.sh 看分类/排行榜，然后安装：

```bash
npx skills add <owner/repo>
```

- 安全：官方提示会做例行审计，但无法保证每个 skill 都安全；安装前建议查看仓库里的 `SKILL.md` 和 `scripts/`
- 匿名遥测：CLI 默认可能会收集匿名遥测用于排行榜；可用环境变量关闭：

```bash
DISABLE_TELEMETRY=1
```

参考：
- https://skills.sh/
- https://skills.sh/docs
- https://skills.sh/docs/cli
