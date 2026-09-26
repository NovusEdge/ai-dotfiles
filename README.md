# dotfiles

Tracked config, symlinked into place by `./install.sh`.

| Repo path | Links to | What it is |
|---|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | User-scope instructions: engineering judgment, tech stack, harness |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings, hooks, plugins |
| `claude/hooks/docket-guard-ledger.py` | `~/.claude/hooks/docket-guard-ledger.py` | PreToolUse hook: asks before a tool writes a docket ledger |
| `claude/hooks/handoff.py` | `~/.claude/hooks/handoff.py` | SessionStart hook: per-project handoff file carried across `/clear` |
| `claude/output-styles/plain.md` | `~/.claude/output-styles/plain.md` | Output style for chat replies |
| `ponytail/config.json` | `~/.config/ponytail/config.json` | Ponytail default mode (`off`) |

`settings.json` holds work environment details in `autoMode.environment`. Keep this repo private.

## Setup on a new machine

```bash
git clone git@github.com:NovusEdge/ai-dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh
```

## Editing

Edit through the live paths in `~/.claude/`. The symlinks mean `git -C ~/.dotfiles status` sees the change immediately.

`~/.claude/settings.local.json` stays untracked on purpose, since it holds per-machine permission grants.

## Watch out

Claude Code rewrites `settings.json` when you toggle things through `/config` or the plugin manager. If a write ever replaces the symlink with a real file, `install.sh` refuses to clobber it and tells you which path to check. Diff it against the repo copy, keep what you want, then delete the file and re-run.

## Ledger guard

A docket ledger is append-only and validated on every read, so a record written around the CLI can break it in ways nothing reports until the next session start. The hook returns an `ask` decision whenever a tool call targets one, and names the command that does the job properly.

Edit, Write, MultiEdit and NotebookEdit match on the file path. Bash matches by allowlist: a `docket` call or a plain reader passes, and anything else naming a ledger asks. An inline interpreter, a heredoc, a command substitution or an `eval` always asks, because none of them says what it will do.

It fails open. A malformed payload, an unknown tool or an unresolvable path exits silently.

The docket plugin ships the same script; this copy covers repositories that do not have it installed.

```bash
echo '{"tool_name":"Edit","tool_input":{"file_path":".docket/ledger.jsonl"}}' \
  | claude/hooks/docket-guard-ledger.py
```
