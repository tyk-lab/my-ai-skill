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

Find all AI context files in the repository. Use the command style that fits the current environment; the examples below are starting points, not a requirement to run Bash on every system.

```bash
rg --files -g 'CLAUDE.md' -g '.claude.local.md' -g 'AGENTS.md' \
  -g '.cursorrules' -g '.windsurfrules' \
  -g '.github/copilot-instructions.md' -g '.cursor/rules/*.md' \
  -g '!node_modules/**' -g '!.git/**' -g '!dist/**' -g '!build/**'

# POSIX fallback
find . \( \
  -name "CLAUDE.md" -o -name ".claude.local.md" \
  -o -name "AGENTS.md" \
  -o -name ".cursorrules" \
  -o -name ".windsurfrules" \
  -o -name "copilot-instructions.md" \
  -o -path "*/.cursor/rules/*.md" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
```

```powershell
# PowerShell fallback
Get-ChildItem -Recurse -Force -File -Include CLAUDE.md,.claude.local.md,AGENTS.md,.cursorrules,.windsurfrules,copilot-instructions.md |
  Where-Object { $_.FullName -notmatch '\\(node_modules|\.git|dist|build)\\' }
Get-ChildItem -Recurse -Force -File -Path .cursor/rules -Filter *.md -ErrorAction SilentlyContinue
```

Only process files found inside the repository. Do **not** inspect or read global user files (`~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.cursor/rules/`, etc.) unless the user explicitly asks to audit their global rules. Identify which tool(s) the project uses based on the files found and any tooling config in the repo (e.g., `.vscode/`, `opencode.json`, `.cursor/`). If multiple tools are used, process all their project-level files.

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

| Criterion | Points | Check |
|-----------|--------|-------|
| Commands/workflows documented | 15 | Are build/test/deploy commands present? |
| Architecture clarity | 15 | Can the AI understand the codebase structure? |
| Non-obvious patterns | 10 | Are gotchas and quirks documented? |
| Conciseness | 10 | No verbose explanations or obvious info? |
| Currency | 15 | Does it reflect current codebase state? |
| Actionability | 15 | Are instructions executable, not vague? |
| Leanness | 10 | No redundant, duplicate, or padded content? |
| Cross-file alignment | 10 | No conflicts or duplications across sibling context files? Use full credit when only one context file exists. |

**Quality Scores:**
- **A (90-100)**: Comprehensive, current, actionable, lean
- **B (70-89)**: Good coverage, minor gaps or slight bloat
- **C (50-69)**: Basic info, missing key sections or noticeable redundancy
- **D (30-49)**: Sparse, outdated, or heavily bloated
- **F (0-29)**: Missing or severely outdated/conflicted

**Length Guidelines:**

| File scope | Recommended length | Hard limit |
|---|---|---|
| Global user rules (`~/.claude/CLAUDE.md`) | 60–120 lines | 200 lines |
| Project root (`CLAUDE.md` / `AGENTS.md`) | 80–150 lines | 250 lines |
| Subdirectory / package-specific | 20–60 lines | 100 lines |

If a file exceeds the hard limit, flag it and recommend splitting into focused sections or moving stable rules to a shared parent file.

### Phase 2b: Cross-File Alignment Check

When multiple context files are found (e.g., global CLAUDE.md + project AGENTS.md, or CLAUDE.md + .cursorrules), compare them for:

1. **Duplicated rules** — same rule stated in multiple files verbatim or near-verbatim.
   → Flag and recommend keeping it only in the most appropriate scope (global vs project).

2. **Conflicting rules** — files that give contradictory instructions on the same topic (e.g., one says "always use tabs", another says "use 2-space indent").
   → Flag the conflict explicitly; do not silently pick one.

3. **Scope misplacement** — project-specific rules in global files, or user preference rules in shared project files.
   → Recommend moving to the correct scope.

4. **Coverage gaps introduced by split** — a rule exists in one tool's file but is missing from another tool's file for the same project.
   → Flag only if the gap is likely to cause inconsistent AI behavior across tools.

Output a dedicated **Cross-File Alignment** section in the quality report listing each issue with: which files are involved, what the conflict/duplicate is, and recommended resolution.

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
| Commands/workflows | X/15 | ... |
| Architecture clarity | X/15 | ... |
| Non-obvious patterns | X/10 | ... |
| Conciseness | X/10 | ... |
| Currency | X/15 | ... |
| Actionability | X/15 | ... |
| Leanness | X/10 | ... |
| Cross-file alignment | X/10 | ... |

**Issues:**
- [List specific problems]

**Recommended additions:**
- [List what should be added]
```

### Phase 4: Targeted Updates

After outputting the quality report, ask user for confirmation before updating.

> **Scope limit**: Only modify files inside the repository. Never write to global user files (`~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.cursor/rules/`, etc.) even if they were read at the user's explicit request.

**Update Guidelines (Critical):**

0. **Trim before adding** — if the file is at or above the recommended length, identify what to remove first before proposing any additions. Possible removals:
   - Rules that are obvious or already enforced by the AI by default
   - Duplicated rules that exist in a parent/sibling file
   - Overly verbose explanations that can be compressed to one line
   - Outdated sections that no longer reflect the codebase
   Never add content that pushes the file past the hard limit without removing equivalent content.

   **Prefer path references over inline content** — if any rule explanation, workflow description, or reference material exceeds ~5 lines, move it to a dedicated file (e.g., `.claude/commands.md`, `docs/architecture.md`) and replace with a one-line pointer: `See docs/architecture.md`. The context file should be a clean index of intent and pointers, not a documentation dump. Only inline what must be visible at a glance with no better home.

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

After user approval, apply changes using the current environment's available editing mechanism. Preserve existing content structure, then verify the write with a targeted file read, `git diff`, or `git status`.

## Templates

See [references/templates.md](references/templates.md) for context file templates by project type.

## Additional Resources

- [references/quality-criteria.md](references/quality-criteria.md) — detailed scoring rubrics for the quality report.
- [references/update-guidelines.md](references/update-guidelines.md) — stricter guidance for deciding what to add or remove.
- [references/templates.md](references/templates.md) — starter templates by project type.
- [commands/revise-ai-context-files.md](commands/revise-ai-context-files.md) — lightweight command workflow for updating context files with learnings from a completed session.

## Common Issues to Flag

1. **Stale commands**: Build commands that no longer work
2. **Missing dependencies**: Required tools not mentioned
3. **Outdated architecture**: File structure that's changed
4. **Missing environment setup**: Required env vars or config
5. **Broken test commands**: Test scripts that have changed
6. **Undocumented gotchas**: Non-obvious patterns not captured
7. **File too long**: Exceeds recommended length; candidate sections for trimming or splitting
8. **Duplicate rules**: Same rule repeated across multiple context files
9. **Conflicting rules**: Different files give contradictory instructions on the same topic
10. **Scope misplacement**: Project rules in global file, or personal preferences in shared file
11. **Verbose rules**: A rule explained in 3+ lines that could be one line without loss of clarity

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
