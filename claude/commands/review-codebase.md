# Codebase Review

Comprehensive codebase review with parallel analysis agents, blast radius tracking, false positive learning, and AI/LLM-aware analysis.

## Mode Selection

Parse `$ARGUMENTS` to determine review mode:

| Argument | Mode | Description |
|----------|------|-------------|
| (empty) | `full` | Complete codebase analysis |
| `quick` | `quick` | Changed files since last review |
| `incremental` | `incremental` | Uncommitted changes only |
| `branch` | `branch` | All changes on current branch vs base |
| `focused:<area>` | `focused` | Deep-dive specific area |
| `impact:<path>` | `impact` | Blast radius analysis for a file/module |

**Mode Configuration:**

| Mode | Scope | Agents | Model |
|------|-------|--------|-------|
| `quick` | Files since last review | 4 (Logic, Errors, Invariants, Impact) | haiku |
| `full` | Entire codebase | 10 (all) | sonnet |
| `incremental` | Uncommitted changes | 5 (Logic, Errors, Perf, Invariants, Impact) | sonnet |
| `branch` | `git diff <base>..HEAD` | 8 (all except Security, Docs) + Plan | sonnet |
| `focused:<area>` | Specific subsystem | 1-4 (relevant) | sonnet |
| `impact:<path>` | Dependency graph of path | 2 (Impact, Errors) | sonnet |

**Auto-detection:** If current branch is not `main`/`master`/`develop` AND a phase plan exists, default to `branch` mode.

---

## Phase 1: Context Loading

### 1.1 Project Context

Read if present:
- `CLAUDE.md`, `README.md`
- `context/architecture.md`, `context/directives.md`
- `pyproject.toml`, `package.json`, `Cargo.toml` (for dependency graph)

### 1.2 Branch + Plan Detection

```bash
git branch --show-current
```

Probe for active plan (stop at first match):
```
context/plans/<branch-slug>*.md
.planning/phases/*/PLAN.md
docs/plans/<branch-slug>*.md
PLAN.md
```

If found, extract: scope items, deferred items, acceptance criteria, target files.

### 1.3 Invariants

```bash
[ -f "context/review/invariants.md" ] && echo "Load invariants"
```

### 1.4 Previous Reviews + False Positive Log

```bash
ls -t context/review/codebase-review-*.md 2>/dev/null | head -1
[ -f "context/review/false-positives.md" ] && echo "Load FP log"
```

The false positive log (`context/review/false-positives.md`) tracks findings marked as not-an-issue. Format:

```markdown
### FP-001
**Pattern**: `grep -n "except Exception:" | except: pass`
**Context**: Acceptable in daemon cleanup loops
**Added**: 2026-04-15
```

Agents MUST check this log and suppress matching patterns.

### 1.5 Linter/SAST Baseline

Run existing tooling first (if configured):
```bash
[ -f "ruff.toml" ] || [ -f "pyproject.toml" ] && uv run ruff check --output-format=json src/ 2>/dev/null
[ -f "eslint.config.js" ] && npx eslint --format=json src/ 2>/dev/null
[ -f ".semgrep.yml" ] && semgrep --json --config=auto 2>/dev/null
```

Store output for agents to reference. Do NOT re-report issues already flagged by linters.

### 1.6 Dependency Graph Construction

Build import graph for blast radius analysis:
```bash
# Python
grep -rh "^from\|^import" src/ | sort | uniq -c | sort -rn > /tmp/import-freq.txt

# For impact mode: trace reverse dependencies
# Agent 8 handles this dynamically
```

### 1.7 Scope Changed Files

```bash
# quick: since last review
LAST_DATE=$(ls -t context/review/codebase-review-*.md 2>/dev/null | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
[ -n "$LAST_DATE" ] && git log --since="$LAST_DATE" --name-only --pretty=format: | sort -u

# incremental
git diff --name-only HEAD

# branch
BASE=$(git merge-base HEAD main 2>/dev/null || echo main)
git diff --name-only "$BASE"..HEAD
```

Compute per file:
- Net LOC delta
- Test coverage delta (if coverage report available)
- Import count (blast radius indicator)

---

## Phase 2: Parallel Agents

Launch agents in parallel. Skip based on mode and context.

### Agent 1: Logic & Spec Conformance (ALL MODES)

```
Cross-reference implementation against specifications.

1. Extract documented formulas, thresholds, weights from docs
2. Find corresponding implementation, verify match
3. Check data flow matches architecture docs
4. Flag: code does Y but docs say X

Skip patterns in false-positives.md.

Output:
| Discrepancy | Doc Location | Code Location | Documented | Actual | Severity |
```

### Agent 2: Performance & Query Analysis (full, incremental, branch)

```
Find performance bottlenecks.

1. N+1 queries: loops calling DB per iteration
2. Batch gaps: sequential ops that could batch
3. Connection management: pooling, leaks
4. Index coverage: filtered columns, FKs
5. Cache opportunities: repeated computations, API calls
6. Async anti-patterns: blocking in async context

Skip if already flagged by linter output.

Output:
| Issue | Location | Current | Recommended | Impact | Effort |
```

### Agent 3: Error Handling & Resilience (ALL MODES)

```
Identify missing error handling.

1. Silent failures: return [] in except, bare except: pass
2. Retry gaps: external APIs, transient DB errors
3. Input validation: bounds, NaN/Inf, null/empty
4. Race conditions: concurrent writes, check-then-act
5. Resource cleanup: unclosed in error paths

Check false-positives.md for acceptable patterns.

Output:
| Issue | Location | Failure Mode | Severity | Fix |
```

### Agent 4: Security Review (full mode)

```
Security analysis.

1. Injection: SQL, NoSQL, shell, template
2. Auth/authz: bypass, missing checks, ownership
3. Secrets: hardcoded, logged, exposed
4. Input validation: path traversal, SSRF
5. Data exposure: sensitive in responses, verbose errors

Output:
| Vulnerability | Location | Vector | Severity | Remediation |
```

### Agent 5: Architecture & Regression (full, branch)

```
Check architecture and previous fixes.

1. Regression check: P0/P1 from last review still fixed?
2. Pattern consistency: same patterns within same category
3. Dependency patterns: consistent retries, timeouts
4. Dead code: unused imports, unreachable paths
5. Type coverage: missing hints on public APIs

Output:
| Issue | Location | Pattern | Recommendation |
```

### Agent 6: Plan Conformance (branch, full if plan exists)

Skip if no plan found.

```
Cross-reference plan against implementation.

1. Scope coverage: each plan item has evidence in diff
2. Scope creep: diff changes not in plan
3. Deferred respected: deferred items NOT in diff
4. Acceptance criteria: tests prove each criterion
5. File coverage: named files were touched

Output:
| Plan Item | Status | Evidence | Severity | Note |

Status: covered | partial | missing | creep | deferred-violated
```

### Agent 7: Invariant Check (if invariants.md exists)

```
Enforce declared invariants.

For each invariant:
1. Run verify method (grep, code path, test)
2. Record violations with file:line
3. Flag stale verify methods as "verify-broken"

Output:
| Invariant | Location | Violation | Severity | Rationale |
```

### Agent 8: Blast Radius & Impact (ALL MODES)

**New agent.** Critical for understanding change risk.

```
Analyze dependency graph and change impact.

1. For each changed file, trace:
   - Direct importers (1-hop)
   - Transitive importers (2-hop, flag if >20)
   - Test coverage of importers

2. Identify high-impact files:
   - Imported by >10 modules
   - Part of hot path (from CLAUDE.md or perf targets)
   - Shared utilities, base classes

3. Flag risky patterns:
   - Changes to widely-imported module without tests
   - Breaking interface changes (removed exports, signature changes)
   - Changes to files with no test importers

Output:
| Changed File | Direct Importers | Transitive | Test Coverage | Risk Level |
```

### Agent 9: AI/LLM Code Review (if LLM code detected)

**New agent.** Activate if codebase imports anthropic, openai, google.generativeai, langchain, etc.

```
AI/LLM-specific review.

1. Prompt injection:
   - User input concatenated into prompts
   - Missing input sanitization before LLM
   - System prompts exposed to users

2. Output handling:
   - LLM output used unsanitized (code execution, SQL, shell)
   - Missing output validation
   - JSON parsing without fallback

3. Token/cost management:
   - Unbounded input (no truncation)
   - Missing token counting before calls
   - No cost tracking/limits

4. Reliability:
   - Missing retries on rate limits
   - No timeout on LLM calls
   - Hallucination not validated against source

5. Caching:
   - Identical prompts not cached
   - Cache invalidation missing

Output:
| Issue | Location | Risk | Severity | Fix |
```

### Agent 10: Documentation Freshness (full mode)

**New agent.**

```
Check documentation staleness.

1. API docs vs implementation:
   - Docstrings match function signatures
   - README examples actually work
   - API docs list current endpoints

2. Architecture docs:
   - Component diagrams match codebase
   - Data flow docs match code paths

3. Stale references:
   - Docs reference deleted files/functions
   - TODO comments older than 6 months
   - Links to non-existent resources

Output:
| Doc | Issue | Staleness | Severity | Fix |
```

### Agent 11: Accessibility (if frontend code detected)

Activate if React, Vue, Svelte, HTML files present.

```
Accessibility audit.

1. ARIA: missing labels, invalid roles
2. Keyboard: focus traps, missing tab index
3. Color contrast: text on backgrounds
4. Alt text: images without alt
5. Semantic HTML: div soup, missing landmarks

Output:
| Issue | Location | WCAG | Severity | Fix |
```

---

## Phase 2.5: Cross-Agent Synthesis

After agents complete, run synthesis:

```
Input: raw findings from all agents + false-positives.md

Tasks:

1. Dedupe: same (file, line-range, issue) from multiple agents -> merge
   - Add "reported-by" field (e.g., "Perf + Impact")

2. Filter false positives:
   - Check each finding against false-positives.md patterns
   - Suppress matches, note as "FP-suppressed: X"

3. Correlate:
   - Link related findings
   - N+1 that's also a race -> one finding, higher severity
   - Escalate: invariant + plan violation = P0

4. Re-rank with escalation rules:
   - Invariant with prior incident -> +1 tier
   - Plan deferred-violated -> minimum P1
   - Hot path (perf targets) -> +1 tier
   - High blast radius (>10 importers) -> +1 tier
   - Test-only code -> -1 tier
   - Already flagged by linter -> -1 tier (already caught)

5. Cluster into 3-7 themes

6. Effort estimate: S (<1h), M (1-4h), L (>4h), XL (multi-day)

Output: final findings list for report
```

---

## Phase 3: Output

### 3.1 Write Report

File: `context/review/codebase-review-YYYY-MM-DD.md`

```markdown
# Codebase Review - YYYY-MM-DD

**Mode**: [mode]
**Branch**: [name]  **Base**: [merge-base]
**Plan**: [path or "none"]
**Linter baseline**: [X issues from ruff/eslint/semgrep]

## Executive Summary

| Category | P0 | P1 | P2 | P3 | FP-Suppressed |
|----------|----|----|----|----|---------------|
| Logic | X | X | X | X | X |
| Performance | X | X | X | X | X |
| Error Handling | X | X | X | X | X |
| Security | X | X | X | X | X |
| Architecture | X | X | X | X | X |
| Plan Conformance | X | X | X | X | X |
| Invariants | X | X | X | X | X |
| Blast Radius | X | X | X | X | X |
| AI/LLM | X | X | X | X | X |
| Docs | X | X | X | X | X |
| Accessibility | X | X | X | X | X |
| **Total** | **X** | **X** | **X** | **X** | **X** |

## Themes

1. **[Theme]** - N findings, P0-P1 skew. [one-line summary]
2. ...

## Blast Radius Hotspots

| File | Importers | Risk | Changes This Review |
|------|-----------|------|---------------------|

## Regression Status

[P0/P1 from previous that regressed or remain unfixed]

## Plan Conformance

| Plan Item | Status | Evidence | Note |

## Invariants

| Invariant | Violations | Notes |

## FP-Suppressed

[Findings suppressed due to false-positives.md patterns]

---

## Findings

### Category: [Name]

| ID | Priority | Location | Issue | Reported-By | Correlation | Blast Radius | Recommendation | Effort | Verify Exists | Verify Fixed |
```

### 3.2 Priority Definitions

| Priority | Criteria |
|----------|----------|
| **P0** | Data corruption, security vuln, crash, high blast radius + no tests |
| **P1** | Logic error, >10x perf hit, missing retry causing >5% failures |
| **P2** | Missing validation, arch drift, edge case failures |
| **P3** | Code quality, minor optimization, docs |

### 3.3 Console Summary

```
## Review Complete

**File**: context/review/codebase-review-YYYY-MM-DD.md
**Mode**: [mode]  **Branch**: [branch]  **Plan**: [path]

### Summary
P0: X  P1: X  P2: X  P3: X  FP-Suppressed: X

### Blast Radius Hotspots
1. [file] - N importers, [risk level]
2. ...

### Themes
1. [theme] - N findings
2. ...

### Top 5 Issues (effort-weighted)
1. [P0/S] Location: summary
2. ...

### Plan: Covered X/Y | Missing X | Creep X
### Invariants: Violations X | Verify-broken X
### Regressions: [count or "none"]
```

---

## False Positive Management

When user marks a finding as not-an-issue:

1. Add to `context/review/false-positives.md`:
```markdown
### FP-XXX
**Pattern**: [grep pattern or code signature]
**Context**: [why this is acceptable]
**Finding ID**: [original finding]
**Added**: YYYY-MM-DD
```

2. Future reviews suppress matching patterns
3. Review FP log quarterly for stale entries

---

## Focused Mode Targets

`focused:<area>` accepts:

**Subsystem**: `api`, `database`, `services`, `infra`, `tests`

**Phase**: `focused:phase-N` - Load plan, scope to plan files + branch changes

**Path**: `focused:file:<path>` or `focused:path:<glob>` - File + 1-hop importers

**Invariant**: `focused:invariant:<name>` - Single invariant, repo-wide

**Impact**: `impact:<path>` - Full blast radius analysis for a module

---

## Integration Hooks

### Pre-review: Run Linters

If project has linter config, run it first. Do not duplicate linter findings.

### Post-review: Suggested Automation

After review, suggest adding to CI:
- Invariant checks that found violations
- Blast radius thresholds for critical paths
- AI/LLM patterns if issues found

---

## Important Notes

- **Analysis Only**: Do NOT make changes
- **Ask Before Fixing**: Present findings, wait for approval
- **Verify Everything**: Every finding needs Verify Exists + Verify Fixed
- **Learn from FPs**: Suppress known false positives
- **Blast Radius First**: Prioritize high-impact files
- **Complement Linters**: Don't duplicate, add insight
