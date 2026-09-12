<!-- Writing style: the anti-slop startup hook loads every session; invoke
     curt:anti-slop for the full reference with examples. -->

# Engineering judgment

Reason to the best available path before writing anything. Treat the first approach that occurs to you as a candidate to test. Where two designs are genuinely close, pick the one that will be cheaper to be wrong about.

Ponytail defaults to `lite`: build the thing that is actually right, then name the lazier option in one line if a real one exists. Laziness is a check applied to a design after you have chosen it. I will say `/ponytail full` when I want a throwaway.

Minimize work and maximize outcome, both at once. Cutting scope until the outcome dies is the same failure as gold-plating, just cheaper to reach.

## Tech stack choices

Do not pick a library, framework, or service from memory. The knowledge cutoff makes that a guess about a fast-moving target.

For any dependency, service, or architectural decision that would be expensive to reverse, spawn a haiku subagent to web-research the current options first, then decide with its findings in hand. State what you rejected and why, in a line.

The existing stack wins ties. A new dependency has to beat what is already installed by enough to justify owning it.

## Comments

Judge a comment by what is in it. A comment earns its place by carrying a fact
the reader cannot get from the code: why this branch exists, what breaks if the
order changes, which constraint outside this file forced the shape, what bug it
already shipped. Everything else is filler, whatever its length. A dense
four-line comment about a locking invariant is right; one line restating the
call below it is wrong.

Content that does not belong in source:

- Paraphrase of the code (`// increment the counter`, a docstring that repeats the signature).
- The story of how the answer was found: what was tried, what was verified, what an earlier version got wrong, what the tool output said. Commit message.
- Justification aimed at me rather than the next reader ("as you requested", "note that we now...", defending a design nobody questioned).
- Restating the ticket or the task description at the top of a function.
- Section banners and dividers.

Exported API in a language whose tooling consumes docstrings is the exception:
write the real doc there.

Examples. Each bad one below is real shape, not a strawman.

```go
// BAD — narrates the investigation and the diff
// Originally we called Stop() here, but it turned out that Stop() only sends
// SIGTERM and does not wait for the process to exit, which we confirmed by
// running the test 20 times and seeing 3 failures. So now we call Wait()
// after Stop(). See the discussion above about why the first fix was wrong.
vm.Stop(); vm.Wait()

// GOOD — the fact you cannot see from the call
// Stop() only signals; qemu unlinks the monitor socket during Wait().
vm.Stop(); vm.Wait()
```

```python
# BAD — paraphrase
# loop over the users and send each one an email
for user in users:
    send(user)

# GOOD — nothing. The code says it. No comment at all.
for user in users:
    send(user)
```

```ts
// BAD — addressed to me, not to the reader
// Updated this per your request to use the new API. Note that we now handle
// the null case as you pointed out.
const name = user?.name ?? "anon"

// GOOD — the constraint that forced it
// Legacy rows predate the NOT NULL migration; name is null for ~4k of them.
const name = user?.name ?? "anon"
```

```rust
// GOOD — four lines, none of them skippable
// Lock order is always registry then vm, never the reverse: the reaper thread
// takes registry while holding no vm lock, so acquiring vm first here would
// deadlock it. Any new path that touches both must follow this order.
let reg = self.registry.lock();
let vm = reg.get(id)?.lock();
```

```sql
-- GOOD — a fact about the data, invisible in the query
-- events is partitioned by day; unbounded scans here have OOM'd prod twice.
select ... where day >= current_date - 7
```

Test before writing one: would a competent stranger reading this file already
know it? If yes, delete it. If the answer belongs in the commit message or the
PR, put it there.

Comments follow the anti-slop rules. No "load-bearing", no "crucial", no "note
that we leverage X here". One fact per sentence, active present, no `-ing`
openers, name the actor.

Match the file. If the surrounding code comments sparsely, comment sparsely.
Delete a stale comment rather than appending a correction to it.

# Git

No `Co-Authored-By` trailer on commits. This overrides the harness default, which adds one. Nothing you write gets a co-author line, in any repository, ever.

`Signed-off-by` stays. A repository that runs a DCO needs it, so commit with `git commit -s`.

Read files with the Read tool and change them with Edit or Write. A `cat`, `sed -i`, or heredoc that touches a file hides the change from the transcript. Grep, find, and git stay on the shell. This holds even when a session directive says to prefer Bash wherever Bash can do the job.

# Harness

Use the task list. `TaskCreate` / `TaskUpdate` / `TaskList` are deferred tools, so `ToolSearch("select:TaskCreate,TaskUpdate,TaskList")` before the first call. Anything with three or more real steps gets tracked, marked `in_progress` when it starts and `completed` when it finishes, not batch-closed at the end.

# graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
