# Build Context

Initialize project context structure with templates and essential files for Claude Code workflows.

## What This Does

1. Creates `context/` directory structure
2. Copies template files from `~/.claude/templates/`
3. Creates `CLAUDE.md` if it doesn't exist
4. Sets up `.claude/commands/` for project-specific commands
5. Optionally analyzes codebase to pre-fill templates

---

## Phase 1: Check Current State

First, assess what already exists:

```bash
# Check for existing context
[ -d "context" ] && echo "context/ exists"
[ -f "CLAUDE.md" ] && echo "CLAUDE.md exists"
[ -f "README.md" ] && echo "README.md exists"
[ -d ".claude/commands" ] && echo ".claude/commands/ exists"

# Check for git
[ -d ".git" ] && echo "Git repo"
```

If files exist, ask user:
- **Overwrite**: Replace with fresh templates
- **Merge**: Keep existing, add missing sections
- **Skip**: Leave existing files alone

---

## Phase 2: Create Directory Structure

```bash
mkdir -p context/review
mkdir -p context/brainstorm
mkdir -p context/archive
mkdir -p .claude/commands
```

Structure:
```
project/
├── context/
│   ├── directives.md      # Coding standards and guidelines
│   ├── architecture.md    # System design (optional)
│   ├── review/            # Codebase review outputs
│   ├── brainstorm/        # Brainstorm session outputs
│   └── archive/           # Old/superseded docs
├── .claude/
│   └── commands/          # Project-specific slash commands
└── CLAUDE.md              # Project overview for Claude
```

---

## Phase 3: Copy Templates

### From `~/.claude/templates/`:

1. **directives.md** → `context/directives.md`
   - Project coding standards
   - Architecture principles
   - Testing requirements
   - Security guidelines

2. **CLAUDE.md** → `CLAUDE.md` (project root)
   - Project overview template
   - Tech stack documentation
   - Key files reference

---

## Phase 4: Analyze and Pre-fill (Optional)

Parse `$ARGUMENTS` for `--analyze` flag.

If `--analyze` is present, launch an agent to analyze the codebase:

### Codebase Analyzer Agent

**Model**: haiku

```
Analyze this codebase to extract information for context templates.

1. Tech Stack Detection:
   - Check package.json, requirements.txt, go.mod, Cargo.toml, etc.
   - Identify framework (FastAPI, Express, Next.js, etc.)
   - List databases from config files
   - Identify test framework

2. Project Structure:
   - Map directory structure
   - Identify main source directories
   - Identify test directories
   - Identify config locations

3. Patterns in Use:
   - Check for DI patterns (constructors, factories)
   - Check error handling patterns
   - Check naming conventions (files, functions)
   - Check import organization

4. Key Files:
   - Entry points (main.py, index.ts, main.go)
   - Configuration files
   - Core business logic locations

Output as structured data that can populate templates.
```

After analysis, update the template files with detected information.

---

## Phase 5: Output Summary

After setup, display:

```
## Context Built

**Created:**
- context/directives.md (template - customize for your project)
- context/review/ (for codebase review outputs)
- context/brainstorm/ (for brainstorm session outputs)
- CLAUDE.md (template - customize for your project)
- .claude/commands/ (for project-specific commands)

**Next Steps:**

1. Edit `CLAUDE.md` to describe your project
   - Add project overview
   - Document tech stack
   - List key files

2. Edit `context/directives.md` to define standards
   - Set naming conventions
   - Define error handling patterns
   - Specify testing requirements

3. Add project-specific commands to `.claude/commands/`
   - Copy from ~/.claude/commands/ if needed
   - Customize for your project

**Useful Commands:**
- /review-codebase - Run a codebase review
- /brainstorm - Start a brainstorming session
- /update-context - Sync templates with latest versions
```

---

## Arguments

| Argument | Effect |
|----------|--------|
| (empty) | Create structure with templates |
| `--analyze` | Also analyze codebase to pre-fill templates |
| `--force` | Overwrite existing files without asking |
| `--minimal` | Only create directory structure, no templates |

---

## Important Notes

- **Non-destructive by default**: Won't overwrite existing files without confirmation
- **Templates are starting points**: User should customize for their project
- **Git-friendly**: All created files should be committed
- **Complements CLAUDE.md**: Works alongside existing project instructions
