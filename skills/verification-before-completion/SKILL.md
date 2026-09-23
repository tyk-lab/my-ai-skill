---
name: verification-before-completion
description: Verify deliverable claims after a material change and immediately before stating work is complete, fixed, built, tested, or ready to commit/create a PR. Use after changing code, configuration, dependencies, deliverable content, external state, or observable behavior; do not use for discussion, planning, read-only investigation, or routine progress updates that make no completion claim.
---

# Verification Before Completion

Use this skill as the final evidence gate for a changed deliverable. State unverified work plainly; do not imply it is complete or correct.

## Scope

A material change alters a requested deliverable or its observable behavior: for example, code, configuration, dependency, documentation, generated output, or an external system state. Reading, investigating, planning, or reporting progress is not a material change.

## Workflow

1. List the completion claims you will make.
2. Select the smallest currently valid evidence that directly supports each claim, including evidence already gathered during implementation or review.
3. Reuse evidence covering the latest relevant state; run additional checks only when coverage is insufficient, relevant inputs changed, or results are ambiguous.
4. Report the result, plus anything still unverified.

Evidence stays valid until the relevant implementation, configuration, dependency, test target, or validation environment changes. A validation environment change means a relevant runtime, toolchain, dependency set, target service, or test configuration change—not an unrelated file, chat message, or elapsed time.

## Map claims to evidence

| Claim | Minimum evidence |
| --- | --- |
| Requested implementation is present | Reuse an explicit successful write/edit result that identifies the target and applied change. If the result is absent or ambiguous, inspect the focused diff or changed artifact; for a new or untracked file, confirm existence and inspect or parse the relevant content. |
| Tests pass | The applicable test command completes with no failures |
| Build succeeds | The applicable build command exits successfully |
| Bug fixed | The original reproduction or a targeted regression test passes |
| Requirements met | Check each stated acceptance requirement against the artifact and relevant test results |
| Ready to commit or open a PR | Verify the intended working-tree and staged/branch scope, then run the checks appropriate to the changed risk |

Do not substitute one kind of evidence for another: a clean diff does not prove behavior, and a passing linter does not prove a build.

An explicit write/edit success proves that the reported change was applied; it does not by itself prove behavior or full requirement compliance. Use the corresponding behavioral or acceptance evidence for those stronger claims.

## Choose proportionate verification

- Documentation or low-risk metadata: inspect the focused diff and validate the relevant format or link when applicable.
- Localized code change with no behavior change: run the nearest relevant lint, type-check, build, or targeted test.
- Behavior change or bug fix: run the original reproduction or a targeted behavioral/regression test. Lint, type-check, and build results are supplementary evidence, not proof of behavior.
- Cross-cutting, security-sensitive, or release-bound change: run targeted checks and broader validation warranted by the impact or required by the project. Size dependency/configuration validation by actual behavioral impact and risk; the file category alone does not require a broader test run.
- Hardware, third-party service, or manual UI behavior: perform the available check and explicitly name the unverified portion and residual risk.

Prefer existing validation commands and tests. Creating or updating a regression test is part of implementation when it has lasting value and is within scope; do not generate persistent tests, fixtures, snapshots, or test data merely to close this completion gate. If a temporary validation artifact is genuinely necessary, follow active project instructions for its location, tracking, cleanup, and confirmation of removal.

Partial verification is useful evidence with limited scope. Report its scope; do not extrapolate it into a stronger claim.

A failed or unavailable check does not by itself prove that the deliverable is defective. Distinguish an observed behavior failure from a validation setup failure or missing evidence. Report what the result establishes and what remains unknown; do not turn an inability to verify success into a confirmed defect or root-cause claim. Likewise, a passing check supports only the behavior and conditions it covers, not the absence of all defects.

## Reporting

Keep the report close to the claim and concise:

```markdown
Verification: `<command or inspection>` → <key result>
Unverified: <item, reason, and residual risk; omit if none>
```

Do not use bare “complete”. Say “implementation complete” only when the requested artifact is present, and say “requirements verified complete” only after checking every stated acceptance requirement. Only say “fixed”, “passing”, “ready to commit”, or equivalent when the listed evidence supports that exact statement. Otherwise describe the current state without a completion claim.

## Do not trigger for

- Planning, design discussion, or explaining code
- Read-only investigation or review
- Intermediate progress updates that make no completion claim, such as “the edit is in progress”
- A request that made no material change and does not assert a deliverable is complete
