# ai-dotfiles

My Claude Code setup: instructions, settings, hooks, skills, commands, plugins, MCP servers and the account picker. One clone and one script set up a machine.

## New machine

```bash
curl -fsSL https://claude.ai/install.sh | bash     # Claude Code, if missing
git clone git@github.com:NovusEdge/ai-dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
exec zsh && claude                                  # picker; press n to add each account
```

It needs `jq`, `python3`, `go` (for the picker) and zsh. The script is idempotent, so re-run it after every pull. Each step it skips prints `SKIP` with the reason, such as a missing tool or a local-only marketplace path.

Logins never leave a machine. The picker creates `~/.claude-<name>` per account and asks you to log in once.

## Day to day

Edit through the live paths in `~/.claude/`. Most of them are symlinks into this repo, so `git status` sees the change immediately. `settings.json` and the MCP servers are the exception:

```bash
~/.dotfiles/sync.sh        # live settings.json + MCP servers -> repo; lists untracked skills/commands/hooks
git -C ~/.dotfiles diff    # review, then commit
```

On a machine whose live settings are newer than the repo, `install.sh` stops rather than overwrite them. Run `sync.sh` first, or use `FORCE=1 ./install.sh` to take the repo's version.

## What goes where

| Repo path | On the machine | How |
|---|---|---|
| `claude/CLAUDE.md`, `claude/output-styles/` | `~/.claude/…` | symlink |
| `claude/hooks/*`, `claude/skills/*`, `claude/commands/*` | `~/.claude/…` | symlink per entry |
| `claude/settings.json` | `~/.claude/settings.json` | copied, `@HOME@` filled in |
| `claude/settings.json` plugins and marketplaces | `~/.claude/plugins/` | `claude plugin marketplace add` / `install` |
| `claude/mcp.json` | user-scope MCP servers in `~/.claude.json` | `claude mcp add-json -s user` |
| `claude-pick/` | `~/go/bin/claude-pick`, sourced from `~/.zshrc` | `go install` |
| `ponytail/config.json` | `~/.config/ponytail/config.json` | symlink |
| `fonts/` | `~/.local/share/fonts/` | symlink |

`settings.json` is copied rather than linked because Claude Code rewrites it on every `/config` or plugin change, and that rewrite replaces a symlink with a plain file.

Never tracked: `.credentials.json`, `.claude.json` (account state), `settings.local.json` (per-machine grants), history, transcripts, `skills/synced` (managed by claude.ai) and `skills/graphify` (written by `graphify install`). `sync.sh` refuses MCP servers that carry `env` or `headers`, since those usually hold tokens. Add such servers by hand.

`settings.json` holds work environment details in `autoMode.environment`. Keep this repo private.

## Skills that fire

`claude/hooks/skill-nudge.py` (PreToolUse) denies the first call in a session that one of these skills covers and names the skill. Claude loads it, then retries the call, which passes. A skill already in the transcript, or one it has already asked for, never blocks.

| Call | Skill |
|---|---|
| Write a code file, or an Edit that adds a def/func/class | `drygate:drygate` |
| Edit a `.md`/`.txt` file | `curt:anti-slop` |
| … whose name has design, architecture, adr or rfc | `software-architecture:architecture` first |
| Edit `SKILL.md`, `CLAUDE.md`, `AGENTS.md`, or agents/commands/output-styles `.md` | `asd-ste100` |
| `gh pr create` | `code-review` |

Memory, `.claude*`, `.docket`, scratchpad and `/tmp` files are exempt. Edit the patterns at the top of the hook to change the rules. Ponytail runs in `lite` mode through its own SessionStart hook (`ponytail/config.json`).

The product-management plugins from `nimble-fox` are off globally, because ~25 extra skill descriptions in every session crowd out the ones above. Projects that want them enable them in their own `.claude/settings.json`.

## Accounts

`claude` opens a picker of accounts (see `claude-pick/README.md`). Every `~/.claude-<name>` symlinks everything from `~/.claude` except its login, so this repo configures all accounts at once. Plugins and MCP servers are installed for the personal account; new accounts copy its MCP servers when they are created.

## Ledger guard

`claude/hooks/docket-guard-ledger.py` returns an `ask` decision whenever a tool call would write a docket ledger around the CLI. A ledger is append-only and validated on every read, so a hand edit can break it in ways nothing reports until the next session start. The docket plugin ships the same script; this copy covers machines without it. It fails open.
