# dotfiles

Tracked config, symlinked into place by `./install.sh`.

| Repo path | Links to | What it is |
|---|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | User-scope instructions: engineering judgment, tech stack, harness |
| `claude/rules/writing-style.md` | `~/.claude/rules/writing-style.md` | Writing style, including the banned contrast construction |
| `claude/hooks/writing-style-check.py` | `~/.claude/hooks/writing-style-check.py` | Stop hook enforcing the style rules on Claude's own output |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings, hooks, plugins |
| `ponytail/config.json` | `~/.config/ponytail/config.json` | Ponytail default mode (`lite`) |

## Setup on a new machine

```bash
git clone <remote> ~/.dotfiles && ~/.dotfiles/install.sh
```

## Editing

Edit through the live paths in `~/.claude/`. The symlinks mean `git -C ~/.dotfiles status` sees the change immediately.

`~/.claude/settings.local.json` stays untracked on purpose, since it holds per-machine permission grants.

## Watch out

Claude Code rewrites `settings.json` when you toggle things through `/config` or the plugin manager. If a write ever replaces the symlink with a real file, `install.sh` refuses to clobber it and tells you which path to check. Diff it against the repo copy, keep what you want, then delete the file and re-run.

## Style hook

```bash
claude/hooks/writing-style-check.py --self-check
```

Blocking patterns end the turn and force a rewrite. Advisory patterns print a warning and let the turn finish. Fenced code, inline code spans, indented blocks, and quoted lines are exempt, so the banned forms can be quoted while discussing them.
