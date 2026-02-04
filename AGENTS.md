# AGENTS.md - AI Agent Instructions for NDX Architecture Documentation

> **Standard**: Ralph Loop compatible | Claude Code compatible | Aider compatible

## Purpose

This repository maintains architecture documentation for the NDX (National Digital Exchange) Innovation Sandbox ecosystem. AI agents should use this file to understand how to maintain and update the documentation.

## Repository Structure

```
ndx-try-arch/
├── update.prompt                     # Main instructions (read this first)
├── AGENTS.md                         # This file - AI agent instructions
│
├── docs/                             # COMMITTED - The deliverables
│   ├── *.md                          # Documentation files (numbered 00-99)
│   └── .meta/                        # Documentation metadata
│       ├── manifest.json             # What docs exist, their sources
│       ├── captured-state.json       # What was documented (SHAs, timestamps)
│       ├── dependency-graph.json     # Doc → Source dependencies
│       └── quality-report.json       # Last validation results
│
├── repos/                            # GITIGNORED - Ephemeral clones
│   └── */                            # Individual repo clones (regenerated)
│
├── .state/                           # GITIGNORED - Runtime state
│   ├── prd.json                      # Task tracking (Ralph Loop format)
│   ├── progress.log                  # Session log
│   └── cache/                        # Analysis cache
│
└── scripts/                          # Helper scripts
    ├── diff-state.sh                 # Show changes since last capture
    ├── regenerate.sh                 # Force doc regeneration
    └── validate.sh                   # Run quality gates
```

## Key Files

| File | Purpose | Committed? |
|------|---------|-----------|
| `update.prompt` | Main execution instructions | Yes |
| `docs/.meta/captured-state.json` | What was documented (provenance) | Yes |
| `docs/.meta/manifest.json` | Document inventory and metadata | Yes |
| `.state/prd.json` | Task tracking (ephemeral) | No |

## Workflow

### 1. Understand Current State
```bash
# Read captured state to see what was already documented
cat docs/.meta/captured-state.json

# Check for changes since last run
./scripts/diff-state.sh
```

### 2. Discover Current Sources
- Clone/update repositories from `co-cddo` GitHub org
- Query AWS organization for accounts and SCPs
- Compare discovered state to captured state

### 3. Regenerate Changed Docs
- Use dependency graph to find affected documents
- Only regenerate docs whose sources have changed
- Update `captured-state.json` with new SHAs

### 4. Validate and Commit
- Run quality gates (structure, content, links, mermaid)
- Update `quality-report.json`
- Commit all changes atomically

## State Machine

The update process follows this state machine:

```
INIT → DISCOVER → ANALYZE → SYNC → GENERATE → VALIDATE → COMMIT → COMPLETE
                     ↓                              ↓
                  FAILED ←←←←←←←←←←←←←←←←←←←← ROLLBACK
```

See `update.prompt` for detailed state transitions.

## Completion Criteria

Output `<promise>COMPLETE</promise>` only when ALL of these are true:

1. **All tasks passed** - `.state/prd.json` has no stories with `"status": "failed"`
2. **Quality gates passed** - `docs/.meta/quality-report.json` shows no critical issues
3. **State captured** - `docs/.meta/captured-state.json` reflects current source SHAs
4. **Changes committed** - All documentation changes are in a git commit

## Error Handling

On error:
1. Log to `.state/errors.log`
2. Do NOT output completion promise
3. Describe error and suggested fix
4. Set task status to `"failed"` in `.state/prd.json`

## Quick Reference

### View Changes
```bash
./scripts/diff-state.sh --verbose
```

### Re-run All Tasks
```bash
rm -rf .state/
```

### Force Regenerate All Docs
```bash
rm docs/.meta/captured-state.json
rm -rf .state/
```

### Regenerate Single Doc
```bash
./scripts/regenerate.sh 10-isb-core-architecture.md
```

### Full Clean Slate
```bash
rm -rf repos/ .state/
rm docs/.meta/*.json
```

### Run Validation
```bash
./scripts/validate.sh --all
```

## Documentation Categories

| Range | Category | Description |
|-------|----------|-------------|
| 00-09 | inventory | Discovery and overview |
| 10-19 | isb-core | ISB core components |
| 20-29 | isb-satellites | ISB extension repos |
| 30-39 | websites | NDX websites |
| 40-49 | infrastructure | LZA and Terraform |
| 50-59 | cicd | CI/CD pipelines |
| 60-69 | security | Security and compliance |
| 70-79 | data | Data flows and integrations |
| 80-89 | architecture | Master diagrams |
| 90-99 | meta | Issues and metadata |

## Quality Gates

Each document must pass:

1. **Structure** - H1 title, executive summary, proper headings
2. **Content** - Minimum word count, Mermaid diagrams, no TODOs
3. **Links** - All internal links resolve
4. **Coverage** - All sources documented

## Important Notes

- **READ-ONLY for AWS** - Document issues, do NOT fix them
- **Idempotent** - Each task can be re-run safely
- **Atomic Commits** - Commit after each completed phase
- **Source Citations** - Always cite source files and repos
- **No Premature Exit** - Continue until all tasks pass

## Contact

This documentation system is maintained by the NDX team at CDDO.
