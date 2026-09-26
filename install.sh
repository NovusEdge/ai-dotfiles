#!/usr/bin/env bash
# Link tracked config into place. Idempotent, and re-running it repairs a link
# that something replaced with a plain file.
#
# ponytail: plain symlinks, no stow/chezmoi. Eight files do not need a framework.
# Upgrade path: if this grows past ~20 links or needs per-host variants, switch
# to stow.
set -euo pipefail

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$D/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    # A real file here means an app rewrote the symlink away. Clobbering it
    # would silently discard whatever it wrote, so stop and let a human look.
    echo "SKIP  $dst is a real file, not a link. Diff it against $src, then delete it and re-run." >&2
    return 0
  else
    ln -s "$src" "$dst"
  fi
  echo "link  $dst"
}

link claude/CLAUDE.md                     "$HOME/.claude/CLAUDE.md"
link claude/settings.json                 "$HOME/.claude/settings.json"
link claude/hooks/docket-guard-ledger.py  "$HOME/.claude/hooks/docket-guard-ledger.py"
link claude/hooks/handoff.py              "$HOME/.claude/hooks/handoff.py"
link claude/output-styles/plain.md        "$HOME/.claude/output-styles/plain.md"
link ponytail/config.json                 "$HOME/.config/ponytail/config.json"
link fonts/satoshi/Satoshi-Variable.woff2       "$HOME/.local/share/fonts/Satoshi/Satoshi-Variable.woff2"
link fonts/satoshi/Satoshi-VariableItalic.woff2 "$HOME/.local/share/fonts/Satoshi/Satoshi-VariableItalic.woff2"

chmod +x "$D/claude/hooks/docket-guard-ledger.py"
# settings.json names this hook, so a run that cannot execute it leaves every
# session without the guard.
echo '{"tool_name":"Edit","tool_input":{"file_path":"x"}}' \
  | python3 "$D/claude/hooks/docket-guard-ledger.py" >/dev/null
