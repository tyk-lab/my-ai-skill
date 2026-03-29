---
name: ask-questions-if-underspecified
description: Clarify requirements before implementing. Use this skill whenever a request has multiple plausible interpretations, key details are missing, or you feel uncertain about scope, objective, or constraints — even if the task seems simple. When in doubt, ask first.
---

# Ask Questions If Underspecified

## When to Use

Use this skill when a request has multiple plausible interpretations or key details (objective, scope, constraints, environment, or safety) are unclear.

This is the default clarification path for simple/low-risk tasks. If the task appears medium/high complexity, route to brainstorming instead.

Use this quick routing rubric:
- Stay in this skill when clarification is mostly about one local change and 1-3 key unknowns.
- Route to `brainstorming` when any of these are true:
  - More than one subsystem or user flow is affected.
  - There are multiple viable designs with meaningful tradeoffs.
  - "Done" requires architecture-level decisions, not just parameter choices.
  - Two clarification rounds still do not produce a stable implementation direction.

## When NOT to Use

Do not use this skill when the request is already clear, or when a quick, low-risk discovery read can answer the missing details.

## Goal

Ask the minimum set of clarifying questions needed to avoid wrong work. Use the question tool (see tool priority below) for 1-3 short structured questions. Do not start implementing until the must-have questions are answered (or the user explicitly approves proceeding with stated assumptions).

## Question Tool Priority

Try tools in this order — use the first one available in the current environment:
1. `AskUserQuestion`
2. `ask_user`
3. `request_user_input` (only when supported in the current collaboration mode)
4. None available → briefly state that no structured question tool is available, then ask the same questions directly in chat.

Before calling any question tool, verify both:
- The tool exists in the current runtime.
- The current mode allows it (for example, some environments disable `request_user_input` outside Plan mode).

## Workflow

### 1) Decide whether the request is underspecified

First, perform a quick, low-risk exploration of the project context (read relevant files, configs, existing patterns) to understand the current state. Do not make changes during this step.

Then, treat a request as underspecified if some or all of the following are not clear:
- Define the objective (what should change vs stay the same)
- Define "done" (acceptance criteria, examples, edge cases)
- Define scope (which files/components/users are in/out)
- Define constraints (compatibility, performance, style, deps, time)
- Identify environment (language/runtime versions, OS, build/test runner)
- Clarify safety/reversibility (data migration, rollout/rollback, risk)

If multiple plausible interpretations exist, assume it is underspecified.

**Dimension priority:** You cannot always ask about all six dimensions. Prioritize in this order: (1) objective and "done" — without these you can't start; (2) scope — wrong scope wastes the most work; (3) safety/reversibility — if the operation is destructive; (4) constraints and environment — often inferable from the project; (5) everything else. Skip dimensions you can answer with a quick discovery read.

### 2) Ask must-have questions first (keep it small)

Ask 1-3 high-leverage questions per question tool call. Prefer questions that eliminate whole branches of work — a single good question can make three others unnecessary.

Tool requirement:
- If clarification is required, use the question tool (see "Question Tool Priority" above) instead of plain chat questions.
- If no question tool is available, briefly state this and ask the same questions directly in chat.

**Second-round rule:** Once the first-round answers arrive, check whether they resolved all ambiguity. If new uncertainty surfaces from those answers, send a second, tighter round (1-2 questions max). Do not open-end this loop — if two rounds have not resolved things, the task may need the brainstorming skill instead.

Make questions easy to answer:
- Optimize for scannability (short, numbered questions; avoid paragraphs)
- Offer multiple-choice options when possible
- Suggest reasonable defaults when appropriate (mark them clearly as the default/recommended choice; bold the recommended choice in the list, or if you present options in a code block, put a bold "Recommended" line immediately above the block and also tag defaults inside the block)
- Include a fast-path response (e.g., reply `defaults` to accept all recommended/default choices)
- Include a low-friction "not sure" option when helpful (e.g., "Not sure - use default")
- Separate "Need to know" from "Nice to know" if that reduces friction
- Structure options so the user can respond with compact decisions (e.g., `1b 2a 3c`); restate the chosen options in plain language to confirm

### 3) Pause before acting

Until must-have answers arrive:
- Do not run commands, edit files, produce a detailed plan, or begin implementation in any form
- If the question tool was used, wait for its answers before continuing
- Do perform a clearly labeled, low-risk discovery step only if it does not commit you to a direction (e.g., inspect repo structure, read relevant config files)

If the user explicitly asks you to proceed without answers:
- State your assumptions as a short numbered list
- Ask for confirmation; proceed only after they confirm or correct them

### 4) Confirm interpretation, then proceed

Once you have answers, restate the requirements in 1-3 sentences (including key constraints and what success looks like), then start work.

If the user says the restatement is wrong, ask one targeted question to identify where the understanding diverged, then restate again. If after two corrections you still can't align, the task likely needs the brainstorming skill for a deeper design conversation.

## Question templates

- "Before I start, I need: (1) ..., (2) ..., (3) .... If you don't care about (2), I will assume ...."
- "Which of these should it be? A) ... B) ... C) ... (pick one)"
- "What would you consider 'done'? For example: ..."
- "Any constraints I must follow (versions, performance, style, deps)? If none, I will target the existing project defaults."
- Use numbered questions with lettered options and a clear reply format

```text
1) Scope?
   a) Minimal change (default)
   b) Refactor while touching the area
   c) Not sure - use default

2) Compatibility target?
   a) Current project defaults (default)
   b) Also support older versions: <specify>
   c) Not sure - use default

Reply: defaults (or 1a 2a)
```

## Anti-patterns

- Don't ask questions you can answer with a quick, low-risk discovery read (e.g., configs, existing patterns, docs).
- Don't default to multiple-choice when the user hasn't formed an opinion yet — an open-ended "What are you trying to achieve?" is better than forcing a premature A/B/C choice. Use multiple-choice to confirm direction, not to discover it.
- Don't ignore contradictions in the user's answers — if their scope answer conflicts with their constraint answer, surface the conflict before proceeding: "You said scope is minimal change, but the constraint you mentioned would require touching X — which takes priority?"

## Escalation

If after two rounds of questions the task is still unclear, or if the answers reveal significant design decisions ahead, route to the **brainstorming** skill instead of continuing to clarify in circles.
