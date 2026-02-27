---
name: brainstorming
description: "Explores user intent, requirements and design before implementation through structured questioning. Use for medium/high-complexity creative work: new features, significant component changes, or behavioral modifications that need design exploration."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through structured collaborative dialogue using `request_user_input` for deeper exploration.

Start by understanding the current project context, then systematically clarify requirements and design intent. Use `request_user_input` to gather batches of related questions, deepening understanding before moving to design phases. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

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
- Use `request_user_input` (if available) to ask 3-5 structured questions that clarify:
  - Purpose and user goals
  - Scope and constraints
  - Success criteria and acceptance
  - Integration points with existing features
- Structure questions with multiple choice, numbered format, and fast-path options (e.g., "Reply: defaults" or "1a 2b 3c")
- If `request_user_input` unavailable, state that briefly and ask the same questions directly in chat
- Focus on understanding: purpose, constraints, success criteria, and why this matters now

**⛔ Gate: Confirm understanding before proceeding**

Do not move to design or implementation until you have confirmed:
- The user's actual goal and why it matters now
- What "done" looks like (acceptance criteria)
- Key constraints and scope boundaries

If any of these are unclear after the first round of questions, ask follow-up questions. Do not guess or assume.

**Exploring approaches:**
- Based on answers, use `request_user_input` again if needed to explore technical direction:
  - Architecture patterns to consider
  - Performance/scalability vs complexity tradeoffs
  - Dependency and compatibility choices
- Propose 2-3 different approaches with clear trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far (as follow-up, not requiring `request_user_input` unless multiple-choice validation needed)
- Cover: architecture, components, data flow, error handling, testing, integration
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

- **Use request_user_input strategically** - Batch 3-5 related questions to deepen understanding across multiple domains at once
- **Structure for clarity** - Numbered questions, lettered options, default recommendations, compact reply format
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Fast-path responses** - Example: "Reply: defaults" to accept all recommendations, or "1a 2c 3b" for specific choices

## Request User Input Template

When using `request_user_input`, structure questions like this:

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
