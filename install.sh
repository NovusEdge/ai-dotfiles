#!/usr/bin/env bash
# Put this repo's Claude Code setup in place on this machine. Idempotent: re-run
# it after a pull. Run ./sync.sh first on a machine whose live config may be
# newer than the repo, or this refuses to overwrite settings.json.
#
# Files Claude Code only reads are symlinked. settings.json is copied, because
# Claude Code rewrites it on every /config or plugin change and the rewrite
# replaces a symlink with a plain file. Paths that differ per machine are stored
# as @HOME@ and filled in here.
#
# ponytail: plain symlinks and the claude CLI, no stow/chezmoi.
set -euo pipefail

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
C="$HOME/.claude"

link() {
  local src="$D/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then
      rm -rf "$dst" && ln -s "$src" "$dst"
    else
      # A real file that differs holds edits the repo lacks; clobbering it would
      # lose them.
      echo "SKIP  $dst differs from $src. Diff them, keep what you want in the repo, delete $dst, re-run." >&2
      return 0
    fi
  else
    ln -s "$src" "$dst"
  fi
  echo "link  $dst"
}

fill_home() { jq --arg h "$HOME" 'walk(if type == "string" then gsub("@HOME@"; $h) else . end)' "$1"; }

git -C "$D" submodule update --init --quiet

link claude/CLAUDE.md               "$C/CLAUDE.md"
link claude/output-styles/plain.md  "$C/output-styles/plain.md"
for f in "$D"/claude/hooks/*;    do link "claude/hooks/${f##*/}"    "$C/hooks/${f##*/}"; done
for f in "$D"/claude/skills/*;   do link "claude/skills/${f##*/}"   "$C/skills/${f##*/}"; done
for f in "$D"/claude/commands/*; do link "claude/commands/${f##*/}" "$C/commands/${f##*/}"; done
link ponytail/config.json           "$HOME/.config/ponytail/config.json"
link fonts/satoshi/Satoshi-Variable.woff2       "$HOME/.local/share/fonts/Satoshi/Satoshi-Variable.woff2"
link fonts/satoshi/Satoshi-VariableItalic.woff2 "$HOME/.local/share/fonts/Satoshi/Satoshi-VariableItalic.woff2"
chmod +x "$D"/claude/hooks/*

want=$(mktemp)
trap 'rm -f "$want"' EXIT
fill_home "$D/claude/settings.json" >"$want"
if [ -f "$C/settings.json" ] && [ ! -L "$C/settings.json" ] \
   && ! diff -q <(jq -S . "$C/settings.json") "$want" >/dev/null && [ "${FORCE:-}" != 1 ]; then
  echo "STOP  $C/settings.json differs from the repo. Run ./sync.sh and commit, or FORCE=1 ./install.sh to overwrite." >&2
  exit 1
fi
rm -f "$C/settings.json" && cp "$want" "$C/settings.json"
echo "copy  $C/settings.json"

# The hooks named in settings.json run on every tool call; a broken one would
# fail every session, so smoke-test them here.
echo '{"tool_name":"Edit","tool_input":{"file_path":"x"}}' | python3 "$D/claude/hooks/docket-guard-ledger.py" >/dev/null
echo '{"tool_name":"Read","tool_input":{}}' | python3 "$D/claude/hooks/skill-nudge.py" >/dev/null

if ! command -v claude >/dev/null; then
  echo "SKIP  plugins and MCP: install Claude Code (curl -fsSL https://claude.ai/install.sh | bash), then re-run." >&2
else
  # Plugins and MCP servers belong to the personal account in ~/.claude; the
  # other accounts symlink its plugins dir.
  cl() { env -u CLAUDE_CONFIG_DIR claude "$@"; }
  known="$C/plugins/known_marketplaces.json"
  installed="$C/plugins/installed_plugins.json"
  jq -r '.extraKnownMarketplaces | to_entries[] | [.key, .value.source.source, (.value.source.repo // .value.source.path // .value.source.url)] | @tsv' "$want" |
  while IFS=$'\t' read -r name kind src; do
    [ -f "$known" ] && jq -e --arg n "$name" 'has($n)' "$known" >/dev/null && continue
    if [ "$kind" = directory ] && [ ! -d "$src" ]; then echo "SKIP  marketplace $name: $src not on this machine" >&2; continue; fi
    cl plugin marketplace add "$src" && echo "mkt   $name"
  done
  jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' "$want" |
  while read -r p; do
    [ -f "$installed" ] && jq -e --arg p "$p" '.plugins | has($p)' "$installed" >/dev/null && continue
    jq -e --arg m "${p#*@}" 'has($m)' "$known" >/dev/null 2>&1 || { echo "SKIP  plugin $p: marketplace not added" >&2; continue; }
    cl plugin install "$p" && echo "plug  $p" || echo "FAIL  plugin $p" >&2
  done

  have=$(jq -c '.mcpServers // {}' "$HOME/.claude.json" 2>/dev/null || echo '{}')
  fill_home "$D/claude/mcp.json" | jq -c 'to_entries[]' |
  while read -r e; do
    name=$(jq -r .key <<<"$e"); def=$(jq -c .value <<<"$e")
    jq -e --arg n "$name" 'has($n)' <<<"$have" >/dev/null && continue
    cmd=$(jq -r '.command // empty' <<<"$def")
    if [ -n "$cmd" ] && ! command -v "$cmd" >/dev/null; then echo "SKIP  mcp $name: $cmd not on this machine" >&2; continue; fi
    cl mcp add-json -s user "$name" "$def" && echo "mcp   $name"
  done
fi

if command -v go >/dev/null; then
  (cd "$D/claude-pick" && go install .) && echo "go    claude-pick"
else
  echo "SKIP  claude-pick: install Go, then re-run." >&2
fi
line="source $D/claude-pick/claude.zsh"
if ! grep -qF "claude-pick/claude.zsh" "$HOME/.zshrc" 2>/dev/null; then
  printf '\n# claude account picker and profiles\n%s\n' "$line" >>"$HOME/.zshrc"
  echo "zshrc $line"
fi
