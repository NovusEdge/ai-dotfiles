# Sourced from ~/.zshrc. Needs claude-pick on PATH and jq.

# One task list per repo (per worktree), so todos survive /clear and are shared
# by parallel sessions in the same checkout. Default is one list per session.
#
# Interactive launches with no account chosen show a picker: "personal" is ~/.claude,
# and every ~/.claude-<name> holding a login is another account. A session exports
# CLAUDE_CONFIG_DIR (or CLAUDE_NO_PICK for personal), so a claude started inside one
# never asks. Subcommands and -p skip the picker and run as personal.
claude() {
  if [[ -z $CLAUDE_CONFIG_DIR$CLAUDE_NO_PICK && -t 0 && -t 1 &&
        $1 != (-p|--print|-v|--version|-h|--help|mcp|config|update|doctor|install|plugin|auth|setup-token) ]]; then
    local p
    p=$(claude-pick) || return 1
    if [[ $p == personal ]]; then claude-personal "$@"; else claude-profile $p "$@"; fi
    return
  fi
  local root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  CLAUDE_CODE_TASK_LIST_ID=${CLAUDE_CODE_TASK_LIST_ID:-${${root#/}//\//-}} command claude "$@"
}

# Same setup, different login. ~/.claude-<name> symlinks every entry of ~/.claude
# except the credentials and the daemon (which runs as one account). Linking runs on
# each launch so new entries in ~/.claude show up. Its .claude.json is a real file
# because it holds the account; it starts with the mcpServers of ~/.claude.json and
# does not follow later `claude mcp add --scope user` changes.
# Personal unsets rather than pointing at ~/.claude: with the var set, Claude reads
# .claude.json from inside the dir instead of ~/.claude.json and loses its state.
claude-personal() { (unset CLAUDE_CONFIG_DIR; CLAUDE_NO_PICK=1 claude "$@") }
claude-profile() {
  local d=$HOME/.claude-$1 f; shift
  mkdir -p $d
  [[ -e $d/.claude.json ]] || jq '{mcpServers: (.mcpServers // {})}' ~/.claude.json >$d/.claude.json
  for f in ~/.claude/*(DN); do
    case ${f:t} in .credentials.json|daemon*|mcp-needs-auth-cache.json) continue ;; esac
    [[ -e $d/${f:t} || -L $d/${f:t} ]] || ln -s $f $d/${f:t}
  done
  CLAUDE_CONFIG_DIR=$d claude "$@"
}
claude-nimble() { claude-profile nimble "$@" }
