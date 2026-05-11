---
name: code-reviewer
description: >-
  TRIGGER when: significant code changes have been made (multiple files, new features, security-sensitive logic) and work is about to be declared complete. Analyzes for security, performance, reliability, and architectural issues. SKIP for: readability/style cleanup (use code-simplifier), single-line fixes, or documentation-only changes.
---

# Code Reviewer

Perform a structured technical review of code changes before declaring work complete.

**Announce at start:** "I'm using the code-reviewer skill to review the changes."

## Phase 1: Scope the Review

1. Identify changed files: `git diff --name-only main` (or relevant base branch)
2. Categorize changes: new feature / bug fix / refactor / config / security
3. Note the risk level: touches auth / payments / data migration / public API → **high risk**; everything else → standard

## Phase 2: Read the Code

Read each changed file. For high-risk files, read the full context, not just the diff.

Check for:

- **Correctness** — does the logic match the stated intent? edge cases handled?
- **Security** — input validation, auth checks, secrets in code, SQL/command injection, XSS
- **Performance** — N+1 queries, missing indexes, blocking I/O in hot paths, unbounded loops
- **Error handling** — errors caught and logged? silent failures? retries where needed?
- **Data integrity** — transactions used correctly? race conditions? missing rollbacks?
- **Test coverage** — are new paths tested? are edge cases covered?

## Phase 3: Output Findings

Group findings by severity. Only include what was actually found — omit empty sections.

```
## Code Review

### 🔴 Critical (must fix before merging)
- [file:line] Issue — why it matters + suggested fix

### 🟡 Warning (should fix, low risk to defer)
- [file:line] Issue — why it matters + suggested fix

### 🔵 Minor (optional, non-blocking)
- [file:line] Suggestion

### ✅ Looks good
- [What was done well — be specific]
```

If no issues found, say so explicitly: "No issues found. Ready to merge."

## Phase 4: Recommend Next Step

- **Critical issues found** → "Fix these before merging. Re-run review after."
- **Warnings only** → "Safe to merge with awareness of these risks. Your call."
- **Clean** → "Approved. Proceed with verification-before-completion."

## What to Prioritize

| Area | Always check | Check if relevant |
|------|-------------|-------------------|
| Security | Input validation, auth, secrets | Crypto, session, CSRF |
| Data | Transactions, nulls, type safety | Migrations, schema changes |
| Performance | DB queries, loops | Caching, concurrency |
| Reliability | Error handling, retries | Timeouts, circuit breakers |
| Tests | New paths covered | Edge cases, failure paths |

## What NOT to flag

- Style preferences already handled by a linter
- Generic best-practice advice not specific to this change
- Hypothetical future issues with no current evidence
- Anything already noted in existing TODOs the author is aware of
