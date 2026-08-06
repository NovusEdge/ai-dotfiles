#!/usr/bin/env bash
# Link tracked config into place. Idempotent, and re-running it repairs a link
# that something replaced with a plain file.
#
# ponytail: plain symlinks, no stow/chezmoi. Five files do not need a framework.
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

link claude/CLAUDE.md                    "$HOME/.claude/CLAUDE.md"
link claude/settings.json                "$HOME/.claude/settings.json"
link claude/rules/writing-style.md       "$HOME/.claude/rules/writing-style.md"
link claude/hooks/writing-style-check.py "$HOME/.claude/hooks/writing-style-check.py"
link ponytail/config.json                "$HOME/.config/ponytail/config.json"

chmod +x "$D/claude/hooks/writing-style-check.py"
python3 "$D/claude/hooks/writing-style-check.py" --self-check
