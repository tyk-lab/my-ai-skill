---
description: Update AI context files with learnings from this session
allowed-tools: Read, Edit, Glob
---

# Revise AI Context Files

Review this session for learnings that would help the AI assistant work more effectively in this codebase. Update the relevant context file(s) with discovered context.

## Step 1: Reflect

What context was missing that would have helped the AI work more effectively?

- Commands that were used or discovered
- Code style patterns followed
- Testing approaches that worked
- Environment/configuration quirks
- Warnings or gotchas encountered

## Step 2: Find Context Files

Use the command style that fits the current environment:

```bash
# rg (preferred)
rg --files -g 'CLAUDE.md' -g '.claude.local.md' -g 'AGENTS.md' -g 'AGENTS.override.md' \
  -g '.cursorrules' -g '.windsurfrules' -g '.github/copilot-instructions.md' \
  -g '.github/instructions/**/*.instructions.md' -g '**/.cursor/rules/**/*.mdc' \
  -g '!node_modules/**' -g '!.git/**'

# POSIX fallback
find . \( \
  -name "CLAUDE.md" -o -name ".claude.local.md" \
  -o -name "AGENTS.md" -o -name "AGENTS.override.md" \
  -o -name ".cursorrules" \
  -o -name ".windsurfrules" \
  -o -name "copilot-instructions.md" \
  -o -path "*/.cursor/rules/*.mdc" \
  -o -path "*/.github/instructions/*.instructions.md" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
```

```powershell
# PowerShell fallback
Get-ChildItem -Recurse -Force -File |
  Where-Object {
    $_.FullName -notmatch '\\(node_modules|\.git|dist|build)\\' -and
    ($_.Name -in @('CLAUDE.md', '.claude.local.md', 'AGENTS.md', 'AGENTS.override.md', '.cursorrules', '.windsurfrules', 'copilot-instructions.md') -or
     $_.FullName -match '[\\/]\.cursor[\\/]rules[\\/].+\.mdc$' -or
     $_.FullName -match '[\\/]\.github[\\/]instructions[\\/].+\.instructions\.md$')
  }
```

Decide where each addition belongs:

- Shared file (e.g., `CLAUDE.md`, `AGENTS.md`, `.cursorrules`) — team-shared, checked into git
- Local override (e.g., `.claude.local.md`) — personal/local only (gitignored)

## Step 3: Draft Additions

**Keep it concise** — one line per concept when possible. Context files are part of the AI's prompt, so brevity matters, but keep high-frequency operational rules inline when they are easier to follow that way.

Format: `<command or pattern>` — `<brief description>`

Avoid:

- Verbose explanations
- Obvious information
- One-off fixes unlikely to recur
- Low-frequency background that belongs in a pointer file once it grows beyond ~5 lines

## Step 4: Show Proposed Changes

For each addition:

```markdown
### Update: ./AGENTS.md

**Why:** [one-line reason]

\`\`\`diff
+ [the addition — keep it brief]
\`\`\`
```

Do not edit yet. First show every proposed diff.

## Step 5: Apply with One Approval

Ask once whether to apply the displayed diffs. Only edit files the user approves, then verify the write with a targeted read or `git diff`.
