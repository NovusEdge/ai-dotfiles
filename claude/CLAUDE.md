<!-- Writing style lives in ~/.claude/rules/writing-style.md, which loads every
     session at the same priority as this file. -->

# Engineering judgment

Reason to the best available path before writing anything. Treat the first approach that occurs to you as a candidate to test. Where two designs are genuinely close, pick the one that will be cheaper to be wrong about.

Ponytail defaults to `lite`: build the thing that is actually right, then name the lazier option in one line if a real one exists. Laziness is a check applied to a design after you have chosen it. I will say `/ponytail full` when I want a throwaway.

Minimize work and maximize outcome, both at once. Cutting scope until the outcome dies is the same failure as gold-plating, just cheaper to reach.

## Tech stack choices

Do not pick a library, framework, or service from memory. The knowledge cutoff makes that a guess about a fast-moving target.

For any dependency, service, or architectural decision that would be expensive to reverse, spawn a haiku subagent to web-research the current options first, then decide with its findings in hand. State what you rejected and why, in a line.

The existing stack wins ties. A new dependency has to beat what is already installed by enough to justify owning it.

# Harness

Use the task list. `TaskCreate` / `TaskUpdate` / `TaskList` are deferred tools, so `ToolSearch("select:TaskCreate,TaskUpdate,TaskList")` before the first call. Anything with three or more real steps gets tracked, marked `in_progress` when it starts and `completed` when it finishes, not batch-closed at the end.

# graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
