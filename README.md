# NDX Architecture Update System

Automated architecture documentation for the NDX (National Digital Exchange) Innovation Sandbox ecosystem.

📖 **[Browse the documentation](https://co-cddo.github.io/ndx-try-arch/)**

## What This System Does

This repository maintains living documentation of the NDX/ISB infrastructure by:

- **Discovering** all related GitHub repositories and AWS resources
- **Analyzing** code, configurations, and infrastructure-as-code
- **Generating** comprehensive architecture documentation
- **Tracking** changes and detecting drift over time

The system is designed to be run periodically by AI agents following structured prompts.

## Quick Start

1. **Read the main instructions**: [`update.prompt`](update.prompt) - this is the primary execution guide
2. **Run validation**: `./scripts/validate.sh --all` to check documentation quality
3. **View generated docs**: Browse the [`docs/`](docs/) directory

## Documentation

| Document | Description |
|----------|-------------|
| [`docs/`](docs/) | Generated architecture documentation |
| [`docs/00-index.md`](docs/00-index.md) | Documentation index and navigation |
| [`AGENTS.md`](AGENTS.md) | AI agent instructions for maintaining docs |
| [`update.prompt`](update.prompt) | Main execution instructions |

## Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate.sh` | Run quality gates and validation checks |
| `scripts/diff-state.sh` | Show changes since last documentation capture |
| `scripts/regenerate.sh` | Force documentation regeneration |

## For AI Agents

If you're an AI agent working on this repository:

1. **Start here**: Read [`AGENTS.md`](AGENTS.md) for orientation
2. **Execute tasks**: Follow [`update.prompt`](update.prompt) for structured workflows
3. **Validate work**: Run `./scripts/validate.sh --all` before committing

## Repository Structure

```
ndx-try-arch/
├── update.prompt          # Main execution instructions
├── AGENTS.md              # AI agent instructions
├── README.md              # This file
├── docs/                  # Generated documentation (committed)
│   ├── *.md               # Documentation files
│   └── .meta/             # Provenance and metadata
├── repos/                 # Cloned repositories (gitignored)
├── .state/                # Runtime state (gitignored)
└── scripts/               # Helper scripts
```

## License

Internal use only - Crown Copyright.
