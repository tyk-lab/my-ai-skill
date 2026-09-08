---
name: code-reviewer
description: >-
  Review code changes when explicitly requested or before declaring material or
  high-risk implementation work complete. Report evidence-backed correctness,
  security, reliability, performance, data-integrity, architecture, and test
  issues. Skip automatic completion review for documentation-only or trivial
  mechanical changes unless they affect sensitive behavior; explicit review
  requests always apply.
---

# Code Reviewer

Perform an evidence-based technical review of a precisely defined change set.

Announce at the start, in the active conversation language, that the code-reviewer
skill is being used. A review is read-only unless the user separately authorizes
fixes; do not treat a review request as permission to modify code or external state.

## Phase 1: Scope the Review

1. Read applicable repository instructions and identify the stated intent and
   acceptance criteria.
2. Determine the exact review target from the request. For a working-tree review,
   account for staged, unstaged, and relevant untracked files. For a commit, range,
   branch, or PR review, use the requested target and correct base or merge-base;
   never assume the base branch is `main`.
3. Categorize the change and its risk. Treat authentication, authorization,
   secrets, command execution, external input, payments, persistence, migrations,
   concurrency, public contracts, IPC, and irreversible side effects as high risk
   when relevant. Do not infer low risk from a small diff.

## Phase 2: Read the Code

Start with the diff, then inspect only the surrounding definitions, callers,
consumers, contracts, and tests needed to validate the changed behavior. For
high-risk changes, follow the complete relevant control and data flow rather than
reviewing isolated lines.

Check for:

- **Correctness** — does the logic match the stated intent and preserve required invariants? are boundary and failure cases handled?
- **Security** — input validation, auth checks, secrets in code, SQL/command injection, XSS
- **Performance** — N+1 queries, missing indexes, blocking I/O in hot paths, unbounded loops
- **Error handling** — are errors handled or propagated at the correct boundary? do logs avoid sensitive data? are retries bounded and safe for the operation?
- **Data integrity** — transactions used correctly? race conditions? missing rollbacks?
- **Compatibility** — do public APIs, schemas, configuration, IPC, and persisted data remain compatible where required?
- **Test coverage** — are new paths tested? are edge cases covered?

Use two review layers so inexpensive convention checks do not crowd out subtle
behavioral defects:

- **Mechanical/convention layer** — run or inspect the project formatter, linter,
  type checker, and explicit repository conventions. Report failures separately.
  A naming or formatting issue belongs in the main findings only when it can
  cause misuse, semantic ambiguity, contract breakage, or a safety mistake.
- **Behavioral layer** — prioritize reachable but easy-to-miss defects in control
  flow, state transitions, boundary values, failure recovery, cleanup, ordering,
  cross-layer limits, authorization, and irreversible side effects. Trace these
  through the final externally observable result instead of stopping at an
  intermediate flag or configured value.

## Evidence Gate

Report a finding only when the reviewed change introduces or worsens a concrete
problem, or violates a requirement needed by the change. Verify the execution
path or invariant and cite the most relevant `file:line`. Unless the user requests
a broader audit, omit unrelated pre-existing problems.

For subtle issues, actively test competing explanations and boundary sequences,
but keep the reporting threshold unchanged: state the reachable trigger, the
violated contract or invariant, the actual outcome, and the material impact.
Review depth may increase without increasing low-value output.

Do not promote unsupported suspicions to findings. Put important uncertainties
caused by unavailable context or unrun validation under **Unverified risks**, with
the missing evidence stated explicitly. Include an unverified risk only when the
missing evidence could change a merge, release, deployment, or safety decision.

Missing tests are not automatically findings. Report a test gap when it leaves a
demonstrated defect without regression coverage, or when a critical safety/data
invariant lacks the minimum evidence needed for the decision at hand.

Prioritize review effort and output by **impact × reachability × confidence**.
Break ties using blast radius and irreversibility. Cover the highest-risk control
and data paths before spending time on bounded convention issues. A high-quality
finding is concise but decision-ready: it identifies the trigger, evidence,
violated invariant, observable impact, and smallest safe fix. Do not cap the
number of substantiated Critical/High findings, and do not dilute them with a long
tail of optional observations.

## Phase 3: Output Findings

Group findings by severity. Only include what was actually found — omit empty sections.

```
## Code Review

### 🔴 Critical (must fix before merging)
- [file:line] Issue — trigger/path; impact; smallest safe fix

### 🟠 High (should fix before merging)
- [file:line] Issue — trigger/path; impact; smallest safe fix

### 🟡 Medium (concrete but bounded risk)
- [file:line] Issue — trigger/path; impact; smallest safe fix

### Convention/tooling results
- Formatter, linter, type-checker, or explicit project-rule failures

### Unverified risks
- Missing evidence and the decision it prevents
```

Omit empty sections. Order findings by severity, then by confidence and likely
impact. Deduplicate findings with the same root cause. Do not pad
the review with praise or generic advice. If no issues are found, say: "No blocking
findings found in the reviewed scope." Do not equate a clean static review with
successful tests, CI, deployment validation, or merge readiness.

Do not output purely optional Low findings by default. Include them only when the
user explicitly requests style, maintainability, or cleanup feedback, and keep
them separate from correctness and risk findings.

## Phase 4: Recommend Next Step

- **Critical or High findings** → fix before merging and re-run the relevant review.
- **Medium findings only** → state the bounded risk and the validation or explicit risk acceptance needed to defer them.
- **No blocking findings** → state the reviewed scope, verification status, and residual risks; make no merge-readiness claim unless the required validation evidence is available.

## What to Prioritize

| Area | Always check | Check if relevant |
|------|-------------|-------------------|
| Security | Input validation, auth, secrets | Crypto, session, CSRF |
| Data | Transactions, nulls, type safety | Migrations, schema changes |
| Performance | DB queries, loops | Caching, concurrency |
| Reliability | Error propagation, cleanup | Retries, timeouts, idempotency |
| Tests | New paths covered | Edge cases, failure paths |

## What NOT to flag

- Style preferences already handled by a linter
- Naming or formatting preferences that cannot change semantics or cause misuse
- Generic best-practice advice not specific to this change
- Hypothetical future issues with no current evidence
- Pre-existing problems unrelated to and not worsened by the reviewed change

Do not suppress a current issue merely because a TODO mentions it. Report it when
the reviewed change triggers or worsens the problem, or when it blocks the stated
behavior.
