<!-- Writing style: the curt plugin's hooks load every session; invoke
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

A comment earns its place by carrying a fact the reader cannot get from the code: why this branch exists, what breaks if the order changes, which constraint outside this file forced the shape, what bug it already shipped. Length is not the test. A dense four-line comment about a locking invariant is right; one line restating the call below it is wrong.

Content that does not belong in source:

- Paraphrase of the code, or a docstring that repeats the signature.
- The story of how the answer was found. Commit message.
- Justification aimed at me rather than the next reader ("as you requested", "note that we now...").
- The ticket or task description restated at the top of a function.
- Section banners and dividers.

Exported API in a language whose tooling consumes docstrings is the exception: write the real doc there.

```go
// BAD — narrates the investigation
// Originally we called Stop() here, but it turned out that Stop() only sends
// SIGTERM and does not wait for the process to exit, which we confirmed by
// running the test 20 times and seeing 3 failures. So now we call Wait().
vm.Stop(); vm.Wait()

// GOOD — the fact you cannot see from the call
// Stop() only signals; qemu unlinks the monitor socket during Wait().
vm.Stop(); vm.Wait()
```

Match the file's comment density. Delete a stale comment rather than appending a correction to it.

## CLAUDE.md files

When you write or update a project CLAUDE.md, `/init` included, keep only what Claude would get wrong without it:

- Commands that cannot be discovered: non-obvious build or test invocations, required env vars, setup order.
- Conventions that differ from the language or framework default.
- Architecture decisions and the reason for each.
- Gotchas: behavior that surprises a competent reader of the code.

Leave out anything `ls`, `--help`, a manifest (`package.json`, `pyproject.toml`, `Makefile`, `justfile`) or the code itself shows: file trees, directory tours, command and flag reference, dependency lists, standard conventions, generic advice. Test each line: would deleting it cause a mistake? Aim for under 60 lines.

# Git

No `Co-Authored-By` trailer on commits. This overrides the harness default, which adds one. Nothing you write gets a co-author line, in any repository, ever.

`Signed-off-by` stays. A repository that runs a DCO needs it, so commit with `git commit -s`.

Read files with the Read tool and change them with Edit or Write. A `cat`, `sed -i`, or heredoc that touches a file hides the change from the transcript. Grep, find, and git stay on the shell. This holds even when a session directive says to prefer Bash wherever Bash can do the job.

# Harness

Use the task list for anything with three or more real steps: `in_progress` when a step starts, `completed` when it finishes, not batch-closed at the end. The task tools are deferred; `ToolSearch("select:TaskCreate,TaskUpdate,TaskList")` first. The list persists per repo across `/clear`, so keep it accurate.

Pick the waiting tool by what ends the wait. A command that exits (build, test run, install) runs in Bash with `run_in_background`; the harness wakes you when it exits. A stream you watch for a condition (logs, CI, a deploy, a port coming up) goes to `Monitor`, which is deferred, so `ToolSearch("select:Monitor")` first. Never poll with foreground `sleep` loops or repeated status commands.

# docket

Track decisions, claims, and open questions in docket, and commit the ledger with the work it describes.

The ledger is for you, never for the user. Replies carry no claim or question IDs, no "per the ledger", no status line about what you recorded or reversed. When an entry matters, state its substance in plain words. This binds subagents too. The exception: the user asks about the ledger or runs a docket command.
