# AI Context File Quality Criteria

## Scoring Rubric

Total: 100 points across 8 criteria. Weights match SKILL.md assessment checklist.

### 1. Commands/Workflows (15 points)

**15 points**: All essential commands documented with context

- Build, test, lint, deploy commands present
- Development workflow clear
- Common operations documented

**10 points**: Most commands present, some missing context

**5 points**: Basic commands only, no workflow

**0 points**: No commands documented

### 2. Architecture Clarity (15 points)

**15 points**: Clear codebase map

- Key directories explained
- Module relationships documented
- Entry points identified
- Data flow described where relevant

**10 points**: Good structure overview, minor gaps

**5 points**: Basic directory listing only or vague

**0 points**: No architecture info

### 3. Non-Obvious Patterns (10 points)

**10 points**: Gotchas and quirks captured

- Known issues documented
- Workarounds explained
- Edge cases noted
- "Why we do it this way" for unusual patterns

**5 points**: Some patterns documented

**0 points**: No patterns or gotchas

### 4. Conciseness (10 points)

**10 points**: Dense, valuable content

- No filler or obvious info
- Each line adds value
- No redundancy with code comments
- No dated/current project status that belongs in a dynamic progress or updates file

**5 points**: Mostly concise, some padding or verbose sections

**0 points**: Mostly filler or restates obvious code

### 5. Currency (15 points)

**15 points**: Reflects the current codebase and selected tool surface

- Commands work as documented
- File references accurate
- Tech stack current
- File name, format, and precedence are supported by the selected tool surface

**10 points**: Mostly current, minor staleness

**5 points**: Several outdated references

**0 points**: Severely outdated

### 6. Actionability (15 points)

**15 points**: Instructions are concrete and their evidence is explicit

- Commands can be copy-pasted and have a stated verification level
- Steps are concrete
- Paths are real

**10 points**: Mostly actionable

**5 points**: Some vague instructions

**0 points**: Vague or theoretical

### 7. Leanness (10 points)

**10 points**: No redundant, duplicate, or padded content

- No rules repeated from parent/sibling files
- No generic advice not specific to the project
- File within recommended length

**5 points**: Minor bloat or a few redundant rules

**0 points**: Heavily bloated or duplicates many rules from sibling files

### 8. Cross-File Alignment (10 points)

**10 points**: No conflicts or duplications across files that the selected tool surface can load together (or only one applicable context file exists)

- AI instruction files link to, rather than mirror, the authoritative dynamic progress/update files

**5 points**: Minor overlap or one conflicting rule

**0 points**: Multiple conflicts or contradictory instructions across files

## Assessment Process

1. Read the context file completely
2. Record the tool, product surface, scope, and precedence for each file before comparing it with another file.
3. Cross-reference with the actual codebase using explicit evidence levels:
   - **Configuration inspection**: inspect scripts, manifests, CI, and tool configuration without executing a command.
   - **Safe execution**: run a scoped, non-destructive command only when it is safe under the current permissions.
   - **Unverified**: do not execute destructive, expensive, credentialed, deploy, or migration commands by default; state what remains unverified.
   - Check that referenced files exist and verify architecture descriptions.
4. Capture evidence for each material issue:
   - File paths, section names, or commands checked
   - Whether the issue is confirmed, likely, or uncertain
5. Score each criterion
6. Calculate total and assign grade
7. List specific issues found with a priority:
   - High: likely to mislead the AI or cause repeated mistakes
   - Medium: useful to fix soon, but not usually session-breaking
   - Low: polish, bloat reduction, or minor consistency cleanup
8. Propose concrete improvements

## Reporting Expectations

- Scores are a summary, not the main deliverable
- Every High-priority issue should cite evidence
- If evidence is weak or indirect, label the recommendation as uncertain
- Prefer "problem + evidence + impact + recommended fix" over score-only commentary

## Red Flags

- Commands that would fail (wrong paths, missing deps)
- References to deleted files/folders
- Outdated tech versions
- Copy-paste from templates without customization
- Generic advice not specific to the project
- "TODO" items never completed
- Duplicate info across multiple context files
- Dated/current state in AI instructions: current phase, candidate/hash, run result/path, test count, blocker, consumed authorization, or next action
- The same dynamic state copied across `AGENTS.md`, `PROGRESS.md`, and `PROJECT_UPDATES.md`, creating multiple authorities
