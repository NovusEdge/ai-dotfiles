#!/usr/bin/env bash
# Copy the live settings and MCP servers back into the repo, and list anything
# in ~/.claude this repo does not track yet. Review with git diff, then commit.
set -euo pipefail

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
C="$HOME/.claude"

to_placeholder() { jq -S --arg h "$HOME" 'walk(if type == "string" then gsub($h; "@HOME@") else . end)'; }

to_placeholder <"$C/settings.json" >"$D/claude/settings.json"

# MCP env vars and headers usually hold tokens, and this repo is on GitHub.
jq '.mcpServers // {}' "$HOME/.claude.json" | to_placeholder >"$D/claude/mcp.json.new"
secret=$(jq -r 'to_entries[] | select(((.value.env // {}) | length) > 0 or ((.value.headers // {}) | length) > 0) | .key' "$D/claude/mcp.json.new")
if [ -n "$secret" ]; then
  rm "$D/claude/mcp.json.new"
  echo "STOP  MCP servers with env or headers, add them by hand without secrets: $secret" >&2
  exit 1
fi
mv "$D/claude/mcp.json.new" "$D/claude/mcp.json"

# skills/synced is managed by claude.ai; graphify is written by `graphify install`.
for f in "$C"/skills/* "$C"/commands/* "$C"/hooks/*; do
  [ -L "$f" ] && continue
  case "${f##*/}" in synced|graphify) continue ;; esac
  rel="claude/${f#"$C"/}"
  echo "UNTRACKED  $f  ->  mv it to $D/$rel, then ./install.sh"
done

git -C "$D" status --short
