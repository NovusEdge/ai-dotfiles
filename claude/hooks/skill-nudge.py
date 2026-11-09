#!/usr/bin/env python3
"""Make the code-quality and writing skills load before the work they cover.

A skill fires only when its one-line description wins against ~120 others, so
these rarely did. This PreToolUse hook denies the first call that needs one, names
the skill, and lets the retry through. Each skill is asked for at most once per
session: one that is already in the transcript, or was asked for before, passes.

Fails open: any error, unknown tool or unreadable payload exits silently.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

CODE_EXT = {
    ".py", ".go", ".rs", ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".java",
    ".kt", ".swift", ".c", ".cc", ".cpp", ".h", ".hpp", ".rb", ".php", ".cs",
    ".sh", ".zsh", ".bash", ".lua", ".zig", ".svelte", ".vue",
}
PROSE_EXT = {".md", ".mdx", ".rst", ".txt"}
# Text another model will act on, where a misreading costs more than style.
AGENT_TEXT = re.compile(r"(^|/)(SKILL|CLAUDE|AGENTS)\.md$|/(agents|commands|output-styles)/[^/]+\.md$")
DESIGN_DOC = re.compile(r"(design|architecture|adr|rfc)", re.I)
# Memory, plans and scratch files are notes to self, not prose anyone reads.
NOTES = re.compile(r"/\.claude[^/]*/|^/tmp/|/\.docket/|/scratchpad/")
NEW_DEFINITION = re.compile(r"^\s*(def|class|func|fn|function|interface|type|struct|impl)\s", re.M)

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "claude-skill-nudge"


def wanted(tool: str, inp: dict) -> list[tuple[str, str]]:
    if tool == "Bash":
        if re.search(r"\bgh\s+pr\s+create\b", inp.get("command", "")):
            return [("code-review", "a PR is about to open; review the diff first")]
        return []
    if tool not in ("Edit", "Write", "MultiEdit"):
        return []
    path = inp.get("file_path", "")
    if not path or NOTES.search(path):
        return []
    ext = Path(path).suffix.lower()
    if ext in PROSE_EXT:
        if AGENT_TEXT.search(path):
            return [("asd-ste100", "this file is instructions another agent will parse")]
        out = [("curt:anti-slop", "this is prose someone will read")]
        if DESIGN_DOC.search(Path(path).name):
            out.insert(0, ("software-architecture:architecture", "this is a design document"))
        return out
    if ext in CODE_EXT:
        new_text = inp.get("content") or inp.get("new_string") or "".join(
            e.get("new_string", "") for e in inp.get("edits", [])
        )
        if tool == "Write" or NEW_DEFINITION.search(new_text):
            return [("drygate:drygate", "new code: check for existing code to reuse first")]
    return []


def main() -> None:
    p = json.load(sys.stdin)
    want = wanted(p.get("tool_name", ""), p.get("tool_input") or {})
    if not want:
        return
    STATE.mkdir(parents=True, exist_ok=True)
    seen_file = STATE / f"{p.get('session_id', 'none')}.json"
    seen = set(json.loads(seen_file.read_text())) if seen_file.exists() else set()
    want = [(s, why) for s, why in want if s not in seen]
    if not want:
        return
    transcript = Path(p.get("transcript_path") or "/nonexistent")
    text = transcript.read_text(errors="ignore") if transcript.is_file() else ""
    missing = [(s, why) for s, why in want if f'"skill":"{s}"' not in text and f"<command-name>/{s}</command-name>" not in text]
    seen.update(s for s, _ in want)
    seen_file.write_text(json.dumps(sorted(seen)))
    if not missing:
        return
    lines = [f"- {s}: {why}" for s, why in missing]
    reason = (
        "Load these skills with the Skill tool, follow them, then retry this exact call "
        "(it will pass; this check asks once per session):\n" + "\n".join(lines)
    )
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
