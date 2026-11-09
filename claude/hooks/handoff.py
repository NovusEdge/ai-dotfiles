#!/usr/bin/env python3
"""SessionStart hook: carry task state across /clear via a per-project handoff file."""
import json
import os
import sys
import time
from pathlib import Path

event = json.load(sys.stdin)
source = event.get("source", "")
project = os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()

# Kept outside the repo so handoffs never land in a commit.
root = Path.home() / ".claude" / "handoffs" / project.strip("/").replace("/", "-")
current = root / "current.md"

parts = [
    f"Handoff file: {current}\n"
    "The task list carries progress and commits carry changes. The handoff holds the rest: "
    "decisions and why, dead ends, open questions, the next step. Keep it under 30 lines.\n"
    "Write it, then tell the user in one line to /clear, at these boundaries only:\n"
    "- The user's new request is unrelated to the current work. Put that request in as the "
    "next step. If the user says to continue here, continue.\n"
    "- The same issue has failed two corrections. Record what the failures taught.\n"
    "- A spec or plan is done and implementation is next."
]

# resume and compact keep the conversation, so the handoff is already in context there.
if source in ("startup", "clear") and current.exists():
    age_h = (time.time() - current.stat().st_mtime) / 3600
    parts.append(
        f"Handoff from the previous session ({age_h:.1f}h old). "
        "Treat it as a lead, not as the user's current request:\n\n"
        + current.read_text()
    )
    archive = root / "archive"
    archive.mkdir(parents=True, exist_ok=True)
    current.rename(archive / time.strftime("%Y%m%d-%H%M%S.md"))

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(parts),
    }
}))
