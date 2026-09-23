---
description: Update AI context files with learnings from this session
allowed-tools: Read, Edit, Glob
---

# Revise AI Context Files

Review this session for durable learnings that would help future work. Before proceeding, read [../SKILL.md](../SKILL.md) and apply its **Shared Execution Rules**, discovery boundaries, loading analysis, and content verification. This entrypoint shortens the report, not the authorization or dynamic-state rules. If no useful stable learning remains, report that no update is needed.

## Step 1: Reflect

What context was missing that would have helped the AI work more effectively?

- Commands that were used or discovered
- Code style patterns followed
- Testing approaches that worked
- Environment/configuration quirks
- Warnings or gotchas encountered

## Step 2: Find Context Files

Use **Phase 1: Discovery** in [../SKILL.md](../SKILL.md); do not maintain a separate filename list or discovery command here. With only Read/Glob tools, use equivalent bounded discovery including hidden and ignored candidates and the same exclusions; report tool coverage limitations.

Select the file whose loading scope reaches the intended task. Shared project rules and personal local overrides have different owners; honor the user's existing exclusion policy. Route current run outcomes, blockers, counts, and next actions to existing dynamic records, not instruction files.

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

## Step 5: Apply Within Authorization

Follow **Shared Execution Rules** in [../SKILL.md](../SKILL.md): reuse existing implementation approval; otherwise ask once for the displayed diffs. Apply only authorized changes and verify content with a targeted read or diff. Preserve explicit constraints and exceptions when simplifying.
