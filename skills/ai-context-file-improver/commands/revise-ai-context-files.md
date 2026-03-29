---
description: Update AI context files with learnings from this session
allowed-tools: Read, Edit, Glob
---

Review this session for learnings that would help the AI assistant work more effectively in this codebase. Update the relevant context file(s) with discovered context.

## Step 1: Reflect

What context was missing that would have helped the AI work more effectively?
- Commands that were used or discovered
- Code style patterns followed
- Testing approaches that worked
- Environment/configuration quirks
- Warnings or gotchas encountered

## Step 2: Find Context Files

```bash
find . \( \
  -name "CLAUDE.md" -o -name ".claude.local.md" \
  -o -name "AGENTS.md" \
  -o -name ".cursorrules" \
  -o -name ".windsurfrules" \
  -o -name "copilot-instructions.md" \
\) 2>/dev/null | head -20
```

Decide where each addition belongs:
- Shared file (e.g., `CLAUDE.md`, `AGENTS.md`, `.cursorrules`) — team-shared, checked into git
- Local override (e.g., `.claude.local.md`) — personal/local only (gitignored)

## Step 3: Draft Additions

**Keep it concise** — one line per concept. Context files are part of the AI's prompt, so brevity matters.

Format: `<command or pattern>` — `<brief description>`

Avoid:
- Verbose explanations
- Obvious information
- One-off fixes unlikely to recur

## Step 4: Show Proposed Changes

For each addition:

```
### Update: ./AGENTS.md

**Why:** [one-line reason]

\`\`\`diff
+ [the addition — keep it brief]
\`\`\`
```

## Step 5: Apply with Approval

Ask if the user wants to apply the changes. Only edit files they approve.
