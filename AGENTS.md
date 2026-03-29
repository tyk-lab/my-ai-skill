# Repository Guidelines

## Project Structure & Module Organization
This repository manages reusable AI skills for multiple agent tools.
- `skills/<skill-name>/SKILL.md`: required entry file for each skill.
- `skills/<skill-name>/references/`: optional reference docs used by the skill.
- `skills/<skill-name>/scripts/`: optional helper scripts.
- `.skill-lock.json`: skill registry and source metadata.
- `readme.md`, `CLAUDE.md`: ecosystem usage and repository-specific guidance.

Keep each skill self-contained in its own folder. Avoid adding unrelated files at repository root.

## Build, Test, and Development Commands
Use `npx skills` commands as the primary workflow:
- `npx skills list`: show installed skills.
- `npx skills check`: detect outdated or invalid skill entries.
- `npx skills update`: update skills from upstream sources.
- `npx skills add <owner/repo> -s <skill-name>`: install a specific skill.
- `npx skills remove <skill-name>`: remove a skill safely.

When validating local edits, run `npx skills check` before opening a PR.

## Coding Style & Naming Conventions
- Use Markdown for documentation and keep instructions concise, imperative, and actionable.
- Preserve frontmatter fields in `SKILL.md` (`name`, `description`, `tools`) when present.
- Use kebab-case for skill folder names (for example, `design-guide`, `requesting-code-review`).
- Keep examples realistic and command snippets executable.
- Use LF (`\n`) line endings consistently.

## Testing Guidelines
There is no single unit-test framework for this repository. Validation is content and structure based:
- Run `npx skills check` after modifying skill files.
- If a skill includes scripts, run only the script relevant to your change.
- For instruction changes, verify referenced paths exist and example commands work.

## Commit & Pull Request Guidelines
Follow the existing Conventional Commit pattern seen in history:
- `feat: ...`, `fix: ...`, `refactor: ...`
- Optional scope is recommended for skill-specific work, e.g. `feat(skills): ...`

PRs should include:
- Purpose and summary of changed skills.
- Any lockfile changes (`.skill-lock.json`) and why they occurred.
- Validation evidence (for example, `npx skills check` output).
- Screenshots only when UI/document rendering changes are relevant.

## Security & Configuration Tips
Review third-party skill `scripts/` before execution. Set `DISABLE_TELEMETRY=1` if telemetry must be disabled in your environment.