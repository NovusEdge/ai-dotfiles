---
name: intent-check
description: Check if current work aligns with original user intent. Use at checkpoints (before commit/PR), manually via /intent-check, or when drift is suspected. Detects mid-task drift, initial misunderstanding, and scope creep.
---

# Intent Alignment Check

Detect drift from user intent. Triggers at checkpoints or manually.

## When to Run

- Before `git commit`
- Before creating/pushing a PR
- After completing a task marked `[checkpoint]` in a plan doc
- Manual: user invokes `/intent-check`
- When you suspect you may have drifted

## The Check

**Step 1: Gather intent sources**
- Original user message that started this task
- Any plan/spec docs referenced or created for this work
- Explicit acceptance criteria if present

**Step 2: Summarize current trajectory**
- What has been done
- What is currently in progress
- What you're about to do next

**Step 3: Compare**
Ask yourself:
- Does the current work directly serve the original request?
- Am I building what was asked, or something adjacent?
- Have I added scope beyond what was requested?
- Am I still solving the original problem?

## Structured Mode

Activates when:
- Plan doc contains `## Success Criteria` or `## Acceptance Criteria`
- User invokes `/intent-check --strict`

In structured mode, extract each criterion and verify explicitly:
```
[ ] Criterion 1: <status>
[ ] Criterion 2: <status>
...
```

## Output

**If aligned:**
> Intent check: aligned with original request. Continuing.

**If misaligned:**

```
## Intent Alignment Check

**Original intent:** <1-2 sentence summary of what was asked>

**Current trajectory:** <what you're actually doing>

**Drift detected:**
- <specific deviation 1>
- <specific deviation 2>

**Proposed correction:** <how to realign>

Proceed with correction? (y/n/discuss)
```

**STOP and wait for user decision before continuing.**

## Red Flags

These thoughts mean you should run an intent check:
- "While I'm here, I should also..."
- "This would be better if I also..."
- "The user probably also wants..."
- "This is related, so..."
- Changing approach without checking back with user
- Adding features not explicitly requested
