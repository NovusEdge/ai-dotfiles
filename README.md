# claude-pick

Run several Claude Code accounts side by side on Linux. Typing `claude` opens a
picker of your accounts, each shown with its email, and launches the one you choose.
Every account shares the same plugins, skills, hooks, CLAUDE.md, history and memory
from `~/.claude`; only the login and account state are kept apart.

## Install

```zsh
git clone git@github.com:NovusEdge/claude-pick.git ~/Projects/Personal/claude-pick
cd ~/Projects/Personal/claude-pick && go install .
echo 'source ~/Projects/Personal/claude-pick/claude.zsh' >> ~/.zshrc
```

It needs zsh, jq, and `~/go/bin` on your PATH.

The repo is private, so `go install github.com/NovusEdge/claude-pick@latest` works
only with `GOPRIVATE=github.com/NovusEdge/*` set and SSH access to GitHub; cloning
as above avoids that.

## Use

- `claude` opens the picker. Enter or a number launches an account, Esc quits.
  The account you used last is selected first.
- Press `n` in the picker to add an account: type a name, and Claude starts in a
  fresh `~/.claude-<name>` and asks you to log in. It appears in the picker from then on.
- `claude-profile <name>` and `claude-personal` launch an account without the picker.

The picker is skipped inside a running session, for `claude -p`, and for subcommands
such as `claude mcp`; those run as the personal account (`~/.claude`).

## How it works

Each extra account is a folder `~/.claude-<name>` used as `CLAUDE_CONFIG_DIR`. It
holds its own `.credentials.json` and `.claude.json`, and symlinks everything else
from `~/.claude`, so changes to your setup reach every account. A new account copies
the MCP servers from `~/.claude.json` once; servers added later go to one account only.

On macOS Claude Code keeps OAuth logins in the Keychain rather than the config
folder, so this approach does not separate logins there.
