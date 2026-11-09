# Update Context

Sync and update project context files with latest templates and detected changes.

## What This Does

1. Compares project context files with global templates
2. Identifies missing sections or outdated patterns
3. Optionally re-analyzes codebase for changes
4. Updates files while preserving customizations

---

## Phase 1: Inventory Current Context

Check what context files exist and their state:

```bash
# Required files
[ -f "CLAUDE.md" ] && echo "CLAUDE.md exists"
[ -f "context/directives.md" ] && echo "directives.md exists"

# Optional files
[ -f "context/architecture.md" ] && echo "architecture.md exists"
[ -f "context/roadmap.md" ] && echo "roadmap.md exists"

# Output directories
[ -d "context/review" ] && echo "review/ exists"
[ -d "context/brainstorm" ] && echo "brainstorm/ exists"

# Template comparison
echo "Template version check..."
```

---

## Phase 2: Parse Arguments

| Argument | Effect |
|----------|--------|
| (empty) | Show diff between current and templates |
| `--apply` | Apply updates (with confirmation) |
| `--sections` | Only add missing sections, don't modify existing |
| `--analyze` | Re-analyze codebase and suggest updates |
| `--sync-commands` | Sync global commands to project |

---

## Phase 3: Template Comparison

### Compare with Global Templates

For each context file, compare against `~/.claude/templates/`:

```
Comparing context/directives.md with template...

Sections in template but missing locally:
- [ ] Performance Guidelines
- [ ] Security Requirements > Data Protection

Sections locally but not in template (custom):
- [x] Domain Rules > PSI Algorithm

Sections that differ:
- Error Handling (local has customizations)
```

### Section-Level Diff

Don't just diff files - compare at the section level:
1. Parse both files by markdown headers
2. Identify missing sections
3. Identify extra (custom) sections
4. Identify modified sections

---

## Phase 4: Codebase Re-analysis (if --analyze)

Launch analyzer agent to detect changes:

### Change Detection Agent

**Model**: haiku

```
Re-analyze codebase and compare with existing context files.

1. New Dependencies:
   - Compare current package files with what's documented
   - Flag new frameworks, libraries, databases

2. Structure Changes:
   - New directories not documented
   - Moved or renamed directories
   - Deleted directories still documented

3. Pattern Drift:
   - New patterns introduced not in directives
   - Documented patterns no longer used

4. Key Files:
   - New entry points
   - New configuration files
   - Deprecated files still documented

Output changes as actionable updates to context files.
```

---

## Phase 5: Generate Update Plan

Present update plan to user:

```
## Context Update Plan

### CLAUDE.md

**Add:**
- Tech Stack > Redis (detected in docker-compose.yml)
- Key Files > pipelines/jobs/new_job.py

**Update:**
- Project Structure (new directories detected)

**Remove:**
- Nothing flagged for removal

### context/directives.md

**Add Sections:**
- Performance Guidelines (from template)
- Security Requirements > Input Validation (from template)

**Preserve Custom Sections:**
- Domain Rules > PSI Algorithm
- Project-Specific Rules

### New Files Suggested

- context/architecture.md (template available)

---

Apply these updates? [y/N]
```

---

## Phase 6: Apply Updates (if --apply or confirmed)

### Update Strategy

1. **Missing Sections**: Append from template
2. **Outdated Sections**: Show diff, ask to replace or keep
3. **Custom Sections**: Always preserve
4. **New Files**: Copy from templates

### Backup First

```bash
# Create backup before modifying
cp context/directives.md context/archive/directives-$(date +%Y%m%d).md
```

### Merge Logic

```python
# Pseudocode for merge
for section in template_sections:
    if section not in local_sections:
        append_section(local_file, section)
    elif section.content != local_section.content:
        if is_custom_section(local_section):
            keep_local()
        else:
            prompt_user_for_choice()
```

---

## Phase 7: Sync Commands (if --sync-commands)

Copy global commands to project:

```bash
# List global commands
ls ~/.claude/commands/

# Copy selected commands
cp ~/.claude/commands/review-codebase.md .claude/commands/
cp ~/.claude/commands/brainstorm.md .claude/commands/
```

Ask user which commands to sync:

```
## Available Global Commands

- [x] review-codebase.md (already exists locally - skip)
- [ ] brainstorm.md (not in project)
- [ ] build-context.md (not needed locally)
- [ ] update-context.md (not needed locally)

Sync brainstorm.md to .claude/commands/? [y/N]
```

---

## Phase 8: Output Summary

```
## Context Updated

**Modified:**
- context/directives.md
  - Added: Performance Guidelines
  - Added: Security Requirements > Input Validation
  - Preserved: Domain Rules > PSI Algorithm

**Unchanged:**
- CLAUDE.md (no updates needed)

**Backups:**
- context/archive/directives-20240130.md

**Synced Commands:**
- .claude/commands/brainstorm.md

**Recommendations:**
- Consider adding context/architecture.md for system design docs
- Review the new sections in directives.md and customize

Run `/review-codebase quick` to verify context accuracy.
```

---

## Validation

After updates, optionally validate:

1. **Lint context files**: Check markdown formatting
2. **Cross-reference**: Ensure CLAUDE.md and directives.md align
3. **Completeness**: Flag critical sections still using placeholders

```
## Validation

[WARN] CLAUDE.md > Tech Stack has placeholder values
[WARN] context/directives.md > Testing Standards incomplete
[OK] All sections have content
[OK] No broken internal links
```

---

## Important Notes

- **Preserves customizations**: Custom sections are never overwritten
- **Backups created**: Before any modification
- **Non-destructive**: Shows plan before applying
- **Idempotent**: Safe to run multiple times
