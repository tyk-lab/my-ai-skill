---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation using structured questioning and request_user_input tool."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through structured collaborative dialogue using `request_user_input` for deeper exploration.

Start by understanding the current project context, then systematically clarify requirements and design intent. Use `request_user_input` to gather batches of related questions, deepening understanding before moving to design phases. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Use `request_user_input` (if available) to ask 3-5 structured questions that clarify:
  - Purpose and user goals
  - Scope and constraints
  - Success criteria and acceptance
  - Integration points with existing features
- Structure questions with multiple choice, numbered format, and fast-path options (e.g., "Reply: defaults" or "1a 2b 3c")
- If `request_user_input` unavailable, ask one question at a time in natural dialogue
- Focus on understanding: purpose, constraints, success criteria, and why this matters now

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

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

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
