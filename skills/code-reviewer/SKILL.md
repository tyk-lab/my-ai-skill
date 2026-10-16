---
name: code-reviewer
description: >-
  Review code changes when explicitly requested or before completing implementation
  that changes behavior, interfaces, state, data, or security boundaries. Scale
  review depth to risk. Report evidence-backed correctness,
  security, reliability, performance, data-integrity, architecture, and test
  issues. Skip automatic completion review for documentation-only or trivial
  mechanical changes unless they affect sensitive behavior. Requests with staging
  or commit intent belong to commit-gatekeeper when available. Focused state or
  data-flow audits belong to stateflow-reviewer when available.
---

# Code Reviewer

Perform an evidence-based technical review of a precisely defined change set.

Announce at the start, in the active conversation language, that the code-reviewer
skill is being used. A standalone review request is read-only unless fixes are
authorized. During an already authorized implementation task, findings caused by
that task may be fixed within the existing scope without renewed permission.
An independent reviewer remains read-only and returns findings to the implementer.
Neither review mode authorizes unrelated changes or external mutations.

## Routing Boundaries

- **Commit or staging intent:** when `commit-gatekeeper` is available, it owns the
  complete workflow: scope, staging, review depth, documentation checks,
  validation, blocking decisions, and commit execution. Do not start a parallel
  standalone `code-reviewer` pass for requests such as "审核并提交", "严审提交",
  `review and commit`, `stage`, or `pre-commit`. If the user explicitly invokes
  `$code-reviewer` together with commit intent, or the gatekeeper explicitly
  delegates a review pass, return one review result to the gatekeeper; the
  gatekeeper remains the sole owner of commit blocking and execution.
- **Focused state-flow audit:** when `stateflow-reviewer` is available, requests
  limited to state transitions, lifecycle, events, scheduling, side effects,
  data flow, or counterexamples use that specialist instead of this skill.
- **Broad code review with stateful risk:** this skill remains the primary review.
  If `stateflow-reviewer` is also used as a specialist input, integrate and
  deduplicate its findings into one report rather than running two independent
  user-facing review flows.
- **Standalone and completion review:** explicit code review without commit intent,
  and automatic review before completing a behavior-changing implementation,
  continue to use this skill.

## Phase 1: Scope the Review

1. Read applicable repository instructions and identify the stated intent and
   acceptance criteria.
2. Determine the exact review target from the request. For a working-tree review,
   account for staged, unstaged, and relevant untracked files. For a commit, range,
   branch, or PR review, use the requested target and correct base or merge-base;
   never assume the base branch is `main`.
   For automatic completion review, target the current task's changes and necessary
   related code; do not include unrelated user changes merely because they are in
   the same working tree.
3. Categorize the change and its risk. Treat authentication, authorization,
   secrets, command execution, external input, payments, persistence, migrations,
   concurrency, public contracts, IPC, and irreversible side effects as high risk
   when relevant. Do not infer low risk from a small diff.

## Phase 2: Read the Code

Start with the diff, then inspect only the surrounding definitions, callers,
consumers, contracts, and tests needed to validate the changed behavior. For
high-risk changes, follow the complete relevant control and data flow rather than
reviewing isolated lines.

Check the following dimensions where relevant to the changed behavior:

- **Correctness** — does the logic match the stated intent and preserve required invariants? are boundary and failure cases handled?
- **Security** — input validation, auth checks, secrets in code, SQL/command injection, XSS
- **Performance** — N+1 queries, missing indexes, blocking I/O in hot paths, unbounded loops
- **Error handling** — are errors handled or propagated at the correct boundary? do logs avoid sensitive data? are retries bounded and safe for the operation?
- **Data integrity** — transactions used correctly? race conditions? missing rollbacks?
- **Compatibility** — do public APIs, schemas, configuration, IPC, and persisted data remain compatible where required?
- **Test coverage** — are new paths tested? are edge cases covered?

Use two review layers so inexpensive convention checks do not crowd out subtle
behavioral defects:

- **Mechanical/convention layer** — reuse valid formatter, linter, type-checker,
  and project-convention results. Run additional relevant checks only when needed,
  using modes that do not rewrite reviewed files; do not install missing tools or
  dependencies just to perform a review. Report failures separately.
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

Before confirming a finding, check relevant callers, upstream validation,
guards, configuration, and documented contracts for evidence that prevents the
suspected failure or makes the behavior intentional. A missing local check or a
suspicious pattern alone does not establish a reachable defect. For subtle issues,
test competing explanations and boundary sequences within the review scope.

Support each confirmed finding with a reproduction result or a sufficiently
complete static execution path: reachable trigger, expected behavior grounded in
a requirement or contract, observed or logically derived outcome, and material
impact. Identify which kind of evidence supports the conclusion; never describe
static inference as an executed test. If a necessary premise is unknown, keep the
conclusion conditional rather than asserting a defect.

Apply this evidence threshold to progress updates as well as the final report.
Say a root cause is confirmed only when the evidence connects the proposed cause
to the symptom and distinguishes relevant competing explanations. Otherwise label
it a candidate cause and name the missing check. A failed tool command alone does
not establish a product defect; distinguish validation setup failures from failures
of the reviewed behavior. Review depth may increase without increasing low-value
output.

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
the review with praise or generic advice. If no issues are found, say: "No
substantiated issues found in the reviewed scope," and identify the scope and
checks performed. This does not prove that no defects exist. Use "No blocking
findings" only when any non-blocking findings remain explicitly reported. Do not
equate a clean static review with successful tests, CI, deployment validation, or
merge readiness.

Do not output purely optional Low findings by default. Include them only when the
user explicitly requests style, maintainability, or cleanup feedback, and keep
them separate from correctness and risk findings.

## Phase 4: Recommend Next Step

- **Critical or High findings** → fix before merging and re-run the relevant review.
- **Medium findings only** → state the bounded risk and the validation or explicit risk acceptance needed to defer them.
- **No blocking findings** → state the reviewed scope, verification status, and residual risks; make no merge-readiness claim unless the required validation evidence is available.

## What NOT to flag

- Style preferences already handled by a linter
- Naming or formatting preferences that cannot change semantics or cause misuse
- Generic best-practice advice not specific to this change
- Hypothetical future issues with no current evidence
- Pre-existing problems unrelated to and not worsened by the reviewed change

Do not suppress a current issue merely because a TODO mentions it. Report it when
the reviewed change triggers or worsens the problem, or when it blocks the stated
behavior.
