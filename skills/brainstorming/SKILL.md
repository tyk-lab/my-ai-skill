---
name: brainstorming
description: "Explores user intent, requirements and design before implementation through structured questioning. Use for medium/high-complexity creative work: new features, significant component changes, or behavioral modifications that need design exploration. Not for simple clarification with 1-3 unknowns (use ask-questions-if-underspecified instead)."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through structured collaborative dialogue using the question tool for deeper exploration.

Start by understanding the current project context, then systematically clarify requirements and design intent. Use the question tool to gather batches of related questions, deepening understanding before moving to design phases. Once you understand what you're building, present the design in small sections (120-250 words), checking after each section whether it looks right so far.

## Question Tool

If the current runtime supports interactive tools, pick any available tool suitable for collecting user input — common examples include `AskUserQuestion`, `ask_user`, `request_user_input`, `question`, and similar. Choose whichever one works; there is no required order. If none are available, ask the same questions directly in chat (plain text).

## When to Use

- New feature development requiring design decisions
- Significant changes to existing architecture or behavior
- Tasks with multiple viable approaches needing exploration
- Medium/high-complexity work where scope, design, or direction is unclear

## When NOT to Use

- Simple/low-risk tasks with minor ambiguity → use ask-questions-if-underspecified instead
- Bug fixes with clear reproduction steps
- Tasks where the user provided a detailed spec or step-by-step instructions
- Single-file, obvious changes (rename, typo fix, config tweak)

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Use the question tool (see "Question Tool Priority" above) to ask 3-5 structured questions that clarify:
  - Purpose and user goals
  - Scope and constraints
  - Success criteria and acceptance
  - Integration points with existing features
- Structure questions with multiple choice, numbered format, and fast-path options (e.g., "Reply: defaults" or "1a 2b 3c")
- Focus on understanding: purpose, constraints, success criteria, and why this matters now

**⛔ Gate: Confirm understanding before proceeding**

Do not move to design or implementation until you can answer all three:
- **Goal + motivation:** What is the user trying to achieve, and why does it matter now? (Not just "add a feature" — what problem does it solve?)
- **Done criteria:** What would the user check to know this is working correctly?
- **Scope + constraints:** What is explicitly in or out, and what hard constraints apply?

"Confirmed" means you can write a 2-sentence summary that the user would agree is correct — not just that they answered your questions. If their answers are vague ("make it better", "just make it work"), that counts as unclear — ask a follow-up that rephrases the question more concretely. Do not guess or assume.

If two rounds of questions haven't resolved one of these three, surface the ambiguity explicitly: "I'm still unclear on [X]. Without knowing this, the design could go in very different directions. Can you give me a concrete example?"

**Check for contradictions before exploring approaches:**
Before proposing anything, scan the answers for internal conflicts — e.g., "minimal scope" but a constraint that forces large changes, or "fast delivery" but a quality bar that requires extensive testing. Surface any conflict explicitly: "Your answers point in two directions on [X] — which takes priority?" Resolve contradictions before moving on; don't paper over them in the design.

**Exploring approaches:**
- Based on answers, use the question tool again if the technical direction is genuinely unclear (e.g., two architectures have meaningfully different tradeoffs). Skip this if the approach is already obvious from the answers.
  - Architecture patterns to consider
  - Performance/scalability vs complexity tradeoffs
  - Dependency and compatibility choices
- If there are meaningful tradeoffs, propose 2-3 different approaches with clear trade-offs; otherwise present one recommended approach and briefly note why alternatives were not chosen.
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into small sections (typically 120-250 words; go longer only for complex sections), and ask after each section whether it looks right so far
- **Scope the coverage to the task complexity.** Always cover architecture and data flow. Add components, error handling, testing, and integration only if they are genuinely non-obvious for the task at hand — don't cover all six for a simple feature.
- If the user says a section is wrong, ask one targeted question to identify the divergence, then revise. If after two corrections a section still doesn't land, step back: "It sounds like we may have a different picture of [X] — can you describe what you had in mind?" Don't keep iterating on assumptions.
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation (if user requests):**
- Ask the user if they want the design documented and where to save it
- Default location: `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design document to git if user confirms

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Use using-git-worktrees skill to create isolated workspace
- Use writing-plans skill to create detailed implementation plan

## Key Principles

- **Use the question tool strategically** - Batch 3-5 related questions to deepen understanding across multiple domains at once
- **Open-ended first, multiple-choice to confirm** - When the user hasn't formed an opinion yet, ask open-ended questions to discover intent. Once direction is clearer, switch to multiple-choice to efficiently pin down specifics.
- **Structure for clarity** - Numbered questions, lettered options, default recommendations, compact reply format
- **Resolve contradictions before designing** - If answers conflict, surface the tension explicitly and resolve it before proposing anything
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives proportionally** - Provide multiple options when tradeoffs are real; avoid forced option lists when one direction is clearly dominant
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Fast-path responses** - Example: "Reply: defaults" to accept all recommendations, or "1a 2c 3b" for specific choices

## Escalation / De-escalation

- If the task turns out to be a simple, low-ambiguity change, don't force the full brainstorming process — wrap up quickly and proceed.
- If this skill was entered from **ask-questions-if-underspecified** because two rounds of clarification weren't enough, treat the prior answers as context and start from the Gate check.
- If you can confidently summarize Goal + Done + Scope/constraints in 2 sentences and there is only one practical implementation direction, de-escalate and proceed without forcing extra design loops.

## Question Template

When using the question tool, structure questions like this:

```
1) What is the primary user goal?
   a) [goal A] (default)
   b) [goal B]
   c) [goal C]

2) Should this integrate with [existing system]?
   a) Yes, tight integration (default)
   b) Yes, loose integration
   c) No, standalone
   d) Not sure - use default

3) Performance priority?
   a) Speed is critical
   b) Balanced (default)
   c) Not a concern

Reply: defaults (or 1a 2b 3c)
```
