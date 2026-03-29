---
name: ai-context-file-improver
description: Audit and improve AI project context files across repositories. Use when the user asks to check, audit, update, improve, or fix project context/instruction files for any AI coding tool — including CLAUDE.md (Claude Code), AGENTS.md (OpenCode/Codex), .cursorrules (Cursor), .github/copilot-instructions.md (GitHub Copilot), .windsurfrules (Windsurf), and similar. Also triggers on "project memory optimization", "AI context file maintenance", or "update my AI rules".
---

# AI Context File Improver

Audit, evaluate, and improve AI project context files to ensure your AI coding assistant has optimal project knowledge — regardless of which tool you use.

**This skill can write to context files.** After presenting a quality report and getting user approval, it updates files with targeted improvements.

## Supported File Types

| Tool | Project-level | Global-level |
|------|--------------|--------------|
| Claude Code | `CLAUDE.md`, `.claude.local.md` | `~/.claude/CLAUDE.md` |
| OpenCode | `AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| OpenAI Codex | `AGENTS.md` | — |
| Cursor | `.cursorrules`, `.cursor/rules/*.md` | `~/.cursor/rules/` |
| GitHub Copilot | `.github/copilot-instructions.md` | — |
| Windsurf | `.windsurfrules` | — |

> **Note:** OpenCode falls back to `CLAUDE.md` if `AGENTS.md` is absent. Prioritize `AGENTS.md` for new projects targeting OpenCode.

## Workflow

### Phase 1: Discovery

Find all AI context files in the repository:

```bash
find . \( \
  -name "CLAUDE.md" -o -name ".claude.local.md" \
  -o -name "AGENTS.md" \
  -o -name ".cursorrules" \
  -o -name ".windsurfrules" \
  -o -name "copilot-instructions.md" \
\) 2>/dev/null | head -50
# Also check .cursor/rules/ directory if it exists
```

Identify which tool(s) the project uses based on the files found and any tooling config in the repo (e.g., `.vscode/`, `opencode.json`, `.cursor/`). If multiple tools are used, process all their files.

**File Types & Locations:**

| Type | Purpose |
|------|---------|
| Project root | Primary project context (shared with team, checked into git) |
| Local overrides | Personal/local settings (gitignored, not shared) |
| Global defaults | User-wide defaults across all projects |
| Package-specific | Module-level context in monorepos |
| Subdirectory | Feature/domain-specific context |

### Phase 2: Quality Assessment

For each context file found, evaluate against quality criteria. See [references/quality-criteria.md](references/quality-criteria.md) for detailed rubrics.

**Quick Assessment Checklist:**

| Criterion | Weight | Check |
|-----------|--------|-------|
| Commands/workflows documented | High | Are build/test/deploy commands present? |
| Architecture clarity | High | Can the AI understand the codebase structure? |
| Non-obvious patterns | Medium | Are gotchas and quirks documented? |
| Conciseness | Medium | No verbose explanations or obvious info? |
| Currency | High | Does it reflect current codebase state? |
| Actionability | High | Are instructions executable, not vague? |

**Quality Scores:**
- **A (90-100)**: Comprehensive, current, actionable
- **B (70-89)**: Good coverage, minor gaps
- **C (50-69)**: Basic info, missing key sections
- **D (30-49)**: Sparse or outdated
- **F (0-29)**: Missing or severely outdated

### Phase 3: Quality Report Output

**Always output the quality report before making any updates.**

Format:

```
## AI Context File Quality Report

### Summary
- Files found: X
- Tools detected: X
- Average score: X/100
- Files needing update: X

### File-by-File Assessment

#### 1. ./AGENTS.md (OpenCode/Codex — Project Root)
**Score: XX/100 (Grade: X)**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Commands/workflows | X/20 | ... |
| Architecture clarity | X/20 | ... |
| Non-obvious patterns | X/15 | ... |
| Conciseness | X/15 | ... |
| Currency | X/15 | ... |
| Actionability | X/15 | ... |

**Issues:**
- [List specific problems]

**Recommended additions:**
- [List what should be added]
```

### Phase 4: Targeted Updates

After outputting the quality report, ask user for confirmation before updating.

**Update Guidelines (Critical):**

1. **Propose targeted additions only** — focus on genuinely useful information:
   - Commands or workflows discovered during analysis
   - Gotchas or non-obvious patterns found in code
   - Package relationships that weren't clear
   - Testing approaches that work
   - Configuration quirks

2. **Keep it minimal** — avoid:
   - Restating what's obvious from the code
   - Generic best practices not specific to the project
   - One-off fixes unlikely to recur
   - Verbose explanations when a one-liner suffices

3. **Show diffs** — for each change, show:
   - Which file to update
   - The specific addition (as a diff or quoted block)
   - Brief explanation of why this helps

**Diff Format:**

```markdown
### Update: ./AGENTS.md

**Why:** Build command was missing, causing confusion about how to run the project.

\`\`\`diff
+ ## Quick Start
+
+ \`\`\`bash
+ npm install
+ npm run dev  # Start development server on port 3000
+ \`\`\`
\`\`\`
```

### Phase 5: Apply Updates

After user approval, apply changes using the Edit tool. Preserve existing content structure.

## Templates

See [references/templates.md](references/templates.md) for context file templates by project type.

## Common Issues to Flag

1. **Stale commands**: Build commands that no longer work
2. **Missing dependencies**: Required tools not mentioned
3. **Outdated architecture**: File structure that's changed
4. **Missing environment setup**: Required env vars or config
5. **Broken test commands**: Test scripts that have changed
6. **Undocumented gotchas**: Non-obvious patterns not captured

## Tips to Share with Users

When presenting recommendations, remind users:

- **Keep it concise**: Context files should be human-readable; dense is better than verbose
- **Actionable commands**: All documented commands should be copy-paste ready
- **Local overrides**: Use tool-specific local files (for example, `.claude.local.md`) for personal preferences not shared with the team (add to `.gitignore`)
- **Multi-tool projects**: If multiple AI tools are used, maintain separate context files — do not consolidate into one, as each tool has different syntax and loading behavior
- **Review periodically**: Context files go stale as the codebase evolves; review after major refactors or dependency changes

## What Makes a Great Context File

**Key principles:**
- Concise and human-readable
- Actionable commands that can be copy-pasted
- Project-specific patterns, not generic advice
- Non-obvious gotchas and warnings

**Recommended sections** (use only what's relevant):
- Commands (build, test, dev, lint)
- Architecture (directory structure)
- Key Files (entry points, config)
- Code Style (project conventions)
- Environment (required vars, setup)
- Testing (commands, patterns)
- Gotchas (quirks, common mistakes)
- Workflow (when to do what)
