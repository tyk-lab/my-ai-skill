# AI Context File Update Guidelines

## Core Principle

Only add stable information that will genuinely help the AI assistant in future sessions. The context window is precious — every line must earn its place. Current project state must stay in its dynamic authority and be linked, not copied, from AI instruction files.

## What TO Add

### 1. Commands/Workflows Discovered

```markdown
## Build

`npm run build:prod` - Full production build with optimization
`npm run build:dev` - Fast dev build (no minification)
```

Why: Saves future AI sessions from discovering these again.

### 2. Gotchas and Non-Obvious Patterns

```markdown
## Gotchas

- Tests must run sequentially (`--runInBand`) due to shared DB state
- `yarn.lock` is authoritative; delete `node_modules` if deps mismatch
```

Why: Prevents repeating debugging sessions.

### 3. Package Relationships

```markdown
## Dependencies

The `auth` module depends on `crypto` being initialized first.
Import order matters in `src/bootstrap.ts`.
```

Why: Architecture knowledge that isn't obvious from code.

### 4. Testing Approaches That Worked

```markdown
## Testing

For API endpoints: Use `supertest` with the test helper in `tests/setup.ts`
Mocking: Factory functions in `tests/factories/` (not inline mocks)
```

Why: Establishes patterns that work.

### 5. Configuration Quirks

```markdown
## Config

- `NEXT_PUBLIC_*` vars must be set at build time, not runtime
- Redis connection requires `?family=0` suffix for IPv6
```

Why: Environment-specific knowledge.

## What NOT to Add

### 1. Obvious Code Info

Bad:
```markdown
The `UserService` class handles user operations.
```

The class name already tells us this.

### 2. Generic Best Practices

Bad:
```markdown
Always write tests for new features.
Use meaningful variable names.
```

This is universal advice, not project-specific.

### 3. One-Off Fixes

Bad:
```markdown
We fixed a bug in commit abc123 where the login button didn't work.
```

Won't recur; clutters the file.

### 4. Verbose Explanations

Bad:
```markdown
The authentication system uses JWT tokens. JWT (JSON Web Tokens) are
an open standard (RFC 7519) that defines a compact and self-contained
way for securely transmitting information between parties as a JSON
object. In our implementation, we use the HS256 algorithm which...
```

Good:
```markdown
Auth: JWT with HS256, tokens in `Authorization: Bearer <token>` header.
```

### 5. Dated or Current Project State

Bad:
```markdown
## Current status (2026-08-14)
- Candidate Z failed; T2 is blocked; next run is AA.
```

This becomes stale and creates a second authority.

Good:
```markdown
## Dynamic state
- Read `.project-plans/PROGRESS.md` before acting; human-facing updates are in `.project-handbook/PROJECT_UPDATES.md`.
```

Keep stable safety invariants in the instruction file, but route current phase, candidates, hashes, run outcomes, test counts, blockers, consumed authorization, and next actions to their dynamic owners.

## Diff Format for Updates

For each suggested change:

### 1. Identify the File

```
File: ./AGENTS.md
Section: Commands (new section after ## Architecture)
```

### 2. Show the Change

```diff
 ## Architecture
 ...

+## Commands
+
+| Command | Purpose |
+|---------|---------|
+| `npm run dev` | Dev server with HMR |
+| `npm run build` | Production build |
+| `npm test` | Run test suite |
```

### 3. Explain Why

> **Why this helps:** The build commands weren't documented, causing
> confusion about how to run the project. This saves future sessions
> from needing to inspect `package.json`.

## Validation Checklist

Before finalizing an update, verify:

- [ ] Each addition is project-specific
- [ ] No generic advice or obvious info
- [ ] Each command has an explicit evidence level: configuration inspection, safe execution, or unverified
- [ ] Destructive, expensive, credentialed, deploy, and migration commands were not executed by default
- [ ] File paths are accurate
- [ ] Would the AI assistant find this helpful in a new session?
- [ ] Is this the most concise way to express the info?
- [ ] No dated/current state is copied into an AI instruction file; it links to the dynamic authority instead
