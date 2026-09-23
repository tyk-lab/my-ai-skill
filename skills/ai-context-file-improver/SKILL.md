---
name: ai-context-file-improver
description: >-
  Audit and improve AI project context files across repositories. Use when the user asks to check, audit, update, improve, or fix project context/instruction files for any AI coding tool — including CLAUDE.md (Claude Code), AGENTS.md (OpenCode/Codex), .cursorrules (Cursor), .github/copilot-instructions.md (GitHub Copilot), .windsurfrules (Windsurf), and similar. Enforces stable-vs-dynamic ownership: dated current status belongs in PROGRESS/PROJECT_UPDATES, not AI instruction files. Also triggers on "project memory optimization", "AI context file maintenance", or "update my AI rules".
---

# AI Context File Improver

Audit, evaluate, and improve AI project context files to ensure your AI coding assistant has optimal project knowledge — regardless of which tool you use.

**This skill can write to project-level context files inside the current repository within the user's authorization.** Global user files are audit-only.

## Shared Execution Rules

These rules also apply to the lightweight workflow in `commands/revise-ai-context-files.md`.

- **Honor scope and authorization.** Audit requests are read-only. For requested implementation or an already approved proposal, proceed within that scope without asking again. Otherwise show proposed diffs and obtain approval before editing. No findings is a valid result; do not manufacture additions.
- **Preserve behavior when simplifying.** Retain explicit requirements, prohibitions, exceptions, safety conditions, and authorization boundaries. Do not delete them because a model should know them or to meet a line target. Consolidate duplicates only when the retained rule still reaches every intended task.
- **Keep dynamic state separate.** Current phases, candidates/hashes, run results, test counts, blockers, consumed authorization, and next actions belong in the project's existing progress, plan, or evidence records. Keep stable constraints and useful pointers in instruction files. `PROGRESS.md` and `PROJECT_UPDATES.md` are examples, not mandatory filenames; do not create a new documentation structure just to satisfy this skill.
- **Verify content, not just status.** Use a focused diff, relevant content read, or format parser after editing. `git status` alone does not prove correct content. Distinguish static inspection from commands actually executed; do not run builds, installs, migrations, or deployments merely to audit their documentation.

## Supported File Types

| Tool | Project-level | Global-level (audit-only) |
|------|--------------|---------------------------|
| Claude Code | `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/**/*.md` | `~/.claude/CLAUDE.md`, `~/.claude/rules/**/*.md` |
| OpenCode | `AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| OpenAI Codex | `AGENTS.override.md`, `AGENTS.md`, configured fallback files | `~/.codex/AGENTS.override.md`, `~/.codex/AGENTS.md` |
| Cursor | `.cursorrules` (legacy), `.cursor/rules/**/*.mdc` | User Rules in Cursor settings |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `AGENTS.md` where supported | Product/surface-specific personal instructions |
| Windsurf / Cascade | `.windsurfrules`, `.windsurf/rules/**/*.md`; `.devin/rules/**/*.md` where supported by the installed client | `~/.codeium/windsurf/memories/global_rules.md` where supported |

> **Tool behavior note:** Loading rules, fallback names, file formats, and precedence can change by tool and surface (for example, IDE chat, CLI, cloud agent, or code review). Verify the current tool's official loading rules before recommending file consolidation, fallback assumptions, migration steps, or cross-file alignment. For Codex, inspect `.codex/config.toml` when present to identify configured fallback names and byte limits; do not treat it as a context file unless the user asks to audit configuration.

## Workflow

### Phase 1: Discovery

Start with the requested files or subtree; scan the repository only for a repository-wide audit. For an exact file, inspect relevant in-repository ancestors and references only as needed to establish its loading scope. Discover candidates before reading their contents.

Run this single-line command from the selected audit root in PowerShell or a POSIX shell. Hidden and ignored candidates are included deliberately; explicit exclusions prune dependencies, generated content, Git internals, and `.my/`. Add known project-specific generated directories to the exclusions and configured fallback filenames as exact candidates when applicable.

```text
rg --files --hidden --no-ignore -g 'CLAUDE.md' -g 'CLAUDE.local.md' -g 'AGENTS.md' -g 'AGENTS.override.md' -g '.cursorrules' -g '.windsurfrules' -g '**/.claude/rules/**/*.md' -g '**/.cursor/rules/**/*.mdc' -g '**/.github/copilot-instructions.md' -g '**/.github/instructions/**/*.instructions.md' -g '**/.windsurf/rules/**/*.md' -g '**/.devin/rules/**/*.md' -g '!**/node_modules/**' -g '!**/.git/**' -g '!**/.my/**' -g '!**/dist/**' -g '!**/build/**' -g '!**/.venv/**' .
```

Honor active command-wrapper requirements. If `rg` is unavailable, use the environment's file search or native shell traversal with the same scope, hidden/ignored-file handling, and exclusions; prune excluded directories before descending. Do not follow directory links outside the authorized scope. Report unreadable or uninspected areas as coverage limits, not as an absence of rules.

Only process files inside the authorized repository scope by default. Do **not** inspect global user files unless the user explicitly requests their audit; those files remain **audit-only**. For each candidate, identify the tool/client, product surface, working directory, path/activation conditions, imports, and precedence using relevant configuration and official documentation. A discovered file is not necessarily active. Resolve references before following them, keep external targets outside the audit unless authorized, and report unknown loading behavior or uninspected global/ancestor rules as coverage limits. Compare jointly active rules for conflicts; compare different tools separately for shared project requirements. Do not expand a focused audit to every tool automatically.

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

Score against the file's actual responsibility and applicable inherited context. Mark irrelevant criteria **N/A**, explain why, and normalize: `100 × earned points / applicable maximum points`. A scoped security rule does not need build commands or an architecture map. No applicable criteria means no numerical score. If coverage is incomplete, mark the assessment provisional rather than claiming verified alignment.

**Quick Assessment Checklist:**

| Criterion | Points | Check |
|-----------|--------|-------|
| Commands/workflows documented | 15 | Are build/test/deploy commands present? |
| Architecture clarity | 15 | Can the AI understand the codebase structure? |
| Non-obvious patterns | 10 | Are gotchas and quirks documented? |
| Conciseness | 10 | No verbose explanations or obvious info? |
| Currency | 15 | Does it reflect current codebase and the selected tool surface's supported format/loading behavior? |
| Actionability | 15 | Are instructions concrete and their commands verified at a stated evidence level? |
| Leanness | 10 | No redundant, duplicate, or padded content? |
| Cross-file alignment | 10 | No unresolved conflicts or unnecessary duplication among jointly active rules? Use N/A if no comparison applies. |

**Quality Scores:**
- **A (90-100)**: Comprehensive, current, actionable, lean
- **B (70-89)**: Good coverage, minor gaps or slight bloat
- **C (50-69)**: Basic info, missing key sections or noticeable redundancy
- **D (30-49)**: Sparse, outdated, or heavily bloated
- **F (0-29)**: Missing or severely outdated/conflicted

**Length Guidelines:**

Use length as a review signal, not a pass/fail threshold. Only a verified limit of the selected client is a hard loading limit; state its unit and whether it applies per file or to the combined loaded context. Recommend trimming for demonstrated redundancy or loading cost while preserving required behavior. Splitting into automatically imported files does not reduce total loaded context; distinguish imports from references read on demand.

### Phase 2b: Cross-File Alignment Check

For runtime conflicts and duplication, compare only rules that can apply together to the same task, recording activation conditions and documented precedence. A valid scoped override is not an unresolved conflict. Separately check cross-tool coverage of shared project requirements; tool-specific differences are not defects by themselves.

1. **Duplicated rules** — same rule stated in multiple files verbatim or near-verbatim.
   → Consolidate only if the retained rule remains available in every intended scope; do not rely on an uninspected global file to justify deleting a shared project rule.

2. **Conflicting rules** — files that give contradictory instructions on the same topic (e.g., one says "always use tabs", another says "use 2-space indent").
   → Report unresolved contradictions after accounting for supported precedence and intentional exceptions; do not silently pick one.

3. **Scope misplacement** — project-specific rules in global files, or user preference rules in shared project files.
   → Recommend moving to the correct scope.

   Dated/current project state is also scope misplacement even when accurate: current phase, candidate identity/hash, run outcome/path, test counts, blockers, authorization consumption, and next actions belong in a dynamic progress/update file, not `AGENTS.md` or equivalent instruction files.

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
- Audit scope: repository-only | repository + user-requested global (audit-only)

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

**Evidence checked:**
- [Command/path/section used to verify the issue]

**Recommended additions:**
- [List what should be added]

**Priority:** High | Medium | Low
```

### Phase 4: Targeted Updates

After outputting the quality report, draft targeted diffs. Do not edit yet.

> **Scope limit**: Only modify files inside the repository. Never write to global user files (`~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.cursor/rules/`, etc.) even if they were read at the user's explicit request.

**Update Guidelines (Critical):**

0. **Trim demonstrated redundancy** — remove low-value content when justified, without requiring equal deletions for useful additions. Preserve the behavior required by Shared Execution Rules. Possible removals:
   - Generic explanations that add no project-specific constraint
   - Duplicated rules that exist in a parent/sibling file
   - Overly verbose explanations that can be compressed to one line
   - Outdated sections that no longer reflect the codebase
   Check verified client loading limits before adding or relocating content; do not use an invented line cap.

   **Prefer path references over inline content for low-frequency material** — if any rule explanation, workflow description, or reference material grows beyond ~5 lines, consider moving it to a dedicated file (e.g., `.claude/commands.md`, `docs/architecture.md`) and replace it with a one-line pointer such as `See docs/architecture.md`. Keep high-frequency operational rules inline when they are important to get right at a glance. The context file should stay focused, but it does not need to become a pointer-only index.

1. **Propose targeted additions only** — focus on genuinely useful information:
   - Commands or workflows discovered during analysis
   - Gotchas or non-obvious patterns found in code
   - Package relationships that weren't clear
   - Testing approaches that work
   - Configuration quirks

   Apply the dynamic-state ownership rule in **Shared Execution Rules**; reuse existing authoritative records and verify pointers before inserting them.

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

### Phase 5: Apply Approved Diffs

Apply the authorization rules in **Shared Execution Rules**: when implementation is already authorized, apply changes within that scope without asking again; otherwise ask once after showing the proposed diffs. Preserve existing content structure, then verify a focused diff or relevant content read and any affected format. Report what was actually verified and what remains unverified.

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
7. **Excess loading cost**: Demonstrated redundancy or a verified client loading limit requires trimming or scoped loading
8. **Duplicate rules**: Same rule repeated across multiple context files
9. **Conflicting rules**: Different files give contradictory instructions on the same topic
10. **Scope misplacement**: Project rules in global file, or personal preferences in shared file
11. **Verbose rules**: A low-value rule explained in 5+ lines that could be one line or a pointer without loss of clarity
12. **Dynamic state in instructions**: Dates, current phases, candidates, run results, test counts, blockers, or next steps copied into AGENTS/CLAUDE/rules instead of linked from their dynamic authority

## Tips to Share with Users

When presenting recommendations, remind users:

- **Keep it concise**: Context files should be human-readable; dense is better than verbose
- **Actionable commands**: All documented commands should be copy-paste ready
- **Local overrides**: Use supported local files (for example, `CLAUDE.local.md`) and the user's existing exclusion policy; do not change `.gitignore` as an automatic side effect
- **Multi-tool projects**: Verify each tool's current loading behavior before recommending one shared file, multiple thin adapter files, or a mixed strategy
- **Review periodically**: Context files go stale as the codebase evolves; review after major refactors or dependency changes

## What Makes a Great Context File

**Key principles:**
- Concise and human-readable
- Actionable commands that can be copy-pasted
- Project-specific patterns, not generic advice
- Non-obvious gotchas and warnings
- Stable information only; link to dynamic progress/update authorities instead of copying current state

**Recommended sections** (use only what's relevant):
- Commands (build, test, dev, lint)
- Architecture (directory structure)
- Key Files (entry points, config)
- Code Style (project conventions)
- Environment (required vars, setup)
- Testing (commands, patterns)
- Gotchas (quirks, common mistakes)
- Workflow (when to do what)
