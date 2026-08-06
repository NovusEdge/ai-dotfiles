#!/usr/bin/env python3
"""Stop hook: enforce ~/.claude/rules/writing-style.md against the turn's final message.

Blocking tier -> {"decision": "block", "reason": ...}  Claude revises before the turn ends.
Advisory tier -> {"systemMessage": ...}                Shown to the user only, turn ends.

Run with --self-check to execute the assertions at the bottom of this file.
"""

import json
import re
import sys

# ponytail: regex, not a parser. Prose has no grammar worth parsing here, and the
# code-span stripping below is what keeps the false-positive rate survivable.
# Upgrade path if it gets noisy: move the ambiguous tier to a small local model.

FLAGS = re.IGNORECASE

# High confidence. The negated half is explicit and adjacent, so a match is
# almost always the real construction.
BLOCKING = [
    ("em-dash", re.compile(r"—")),
    ("X isn't just Y", re.compile(r"\b(is|are|was|were)n'?t\s+just\b", FLAGS)),
    ("X is not just Y", re.compile(r"\b(is|are|was|were)\s+not\s+just\b", FLAGS)),
    ("it's not X, it's Y", re.compile(r"\bit'?s\s+not\b[^.!?\n]{1,80}?,\s*it'?s\b", FLAGS)),
    ("that's A, not B", re.compile(r"\b(that|this|it)('?s|\s+(is|was))\b[^.!?\n]{1,60}?,\s*not\b", FLAGS)),
    ("not because A, but because B", re.compile(r"\bnot because\b[^.!?\n]{1,80}?,\s*but\b", FLAGS)),
    ("less A, more B", re.compile(r"\bless\b[^.!?\n]{1,50}?,\s*more\b", FLAGS)),
    ("this isn't about A, it's about B", re.compile(r"\bisn'?t about\b[^.!?\n]{1,80}?,\s*it'?s about\b", FLAGS)),
    ("the real X isn't A, it's B", re.compile(r"\bthe real \w+\s+(is|was)n'?t\b", FLAGS)),
    # "..., not a discovery one" reads as the construction; the article is what
    # separates it from a plain corrective list like "tabs, not spaces".
    ("X, not a/an/the Y", re.compile(r",\s*not\s+(a|an|the)\s+\w+", FLAGS)),
]

# Frequently legitimate ("use tabs, not spaces"), so these warn without blocking.
ADVISORY = [
    (", not ...", re.compile(r",\s+not\s+", FLAGS)),
    ("rather than", re.compile(r"\brather than\b", FLAGS)),
]

FENCE = re.compile(r"```.*?```", re.DOTALL)
INDENTED = re.compile(r"^(?: {4}|\t).*$", re.MULTILINE)
INLINE = re.compile(r"`[^`\n]*`")
QUOTED = re.compile(r"^>.*$", re.MULTILINE)


def strip_code(text: str) -> str:
    """Remove spans where the banned forms are being quoted or are legitimate code."""
    for pattern in (FENCE, INDENTED, INLINE, QUOTED):
        text = pattern.sub(" ", text)
    return text


def scan(message: str):
    prose = strip_code(message or "")
    blocking = [name for name, rx in BLOCKING if rx.search(prose)]
    advisory = [name for name, rx in ADVISORY if rx.search(prose)]
    return blocking, advisory


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    # Already continuing because of this hook: warn only, so a phrasing the
    # regex cannot love never traps the turn.
    already_continuing = bool(payload.get("stop_hook_active"))
    blocking, advisory = scan(payload.get("last_assistant_message", ""))

    out = {}
    if blocking and not already_continuing:
        out["decision"] = "block"
        out["reason"] = (
            "Your message uses banned constructions from ~/.claude/rules/writing-style.md: "
            + "; ".join(blocking)
            + ". Rewrite the offending sentences so each states the real thing directly, "
            "with no negated half and no em-dash, then reply with the corrected message. "
            "Do not narrate the correction."
        )
    elif blocking:
        out["systemMessage"] = "writing-style (unresolved after retry): " + "; ".join(blocking)

    if advisory:
        note = "writing-style advisory: " + "; ".join(advisory)
        out["systemMessage"] = (out.get("systemMessage", "") + " | " + note).strip(" |")

    if out:
        json.dump(out, sys.stdout)
    return 0


def self_check() -> None:
    b, a = scan("That's a priority instruction, not a discovery one.")
    assert b, "appositive contrast should block"

    b, a = scan("That is a priority instruction, not a discovery one.")
    assert b, "uncontracted 'that is' must block too"

    b, a = scan("Settings are enforced, not a suggestion.")
    assert "X, not a/an/the Y" in b, b

    b, a = scan("This isn't just a refactor, the API changed too.")
    assert "X isn't just Y" in b, b

    b, a = scan("Use tabs, not spaces, in this file.")
    assert not b, b
    assert ", not ..." in a, a

    b, a = scan("The migration ran and every row landed. Qdrant is in sync.")
    assert not b and not a, (b, a)

    b, a = scan("Run `git commit -m 'fix, not feat'` to land it.")
    assert not b and not a, "inline code must be exempt"

    b, a = scan("Example:\n```\nlabel = 'it's not X, it's Y'\n```\nDone.")
    assert not b, "fenced code must be exempt"

    b, a = scan("Latency dropped from 900ms — now 120ms.")
    assert "em-dash" in b, b

    print("writing-style-check: all self-checks passed")


if __name__ == "__main__":
    if "--self-check" in sys.argv:
        self_check()
    else:
        sys.exit(main())
