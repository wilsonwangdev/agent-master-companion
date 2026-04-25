# Agent Master Companion

A lightweight macOS menubar utility for agent practitioners. Browse and manage agent instruction files (CLAUDE.md, .cursorrules, rules, skills, memory, etc.) across your projects from the status bar.

## Features

- **Agent File Explorer** — Scan any project folder to discover and browse agent-related instruction/context/rule files. Supports Claude Code, Cursor, Copilot, Codex, Cline, Roo Code, Aider, Continue.dev, Amazon Q, Augment, Devin, and Windsurf.
- **Scratch Pad** — Jot down thoughts while waiting for agent responses. Select notes to compose your next prompt.

## Privacy

- Fully offline — zero network requests, no telemetry
- Only reads instruction/context/rule files (CLAUDE.md, .cursorrules, etc.)
- Never reads configuration or credential files (settings.json, config.yaml, API keys)
- File content is never cached; only paths and metadata are stored
- Open source — fully auditable

## Install

Download the latest `.dmg` from [GitHub Releases](https://github.com/user/agent-master-companion/releases), open it, and drag the app to Applications.

> First launch: macOS may show "unidentified developer" warning. Right-click the app > Open to bypass.

## Requirements

- macOS 14.0 (Sonoma) or later
- Intel or Apple Silicon Mac (Universal Binary)

## Development

```bash
# Open in Xcode
open AgentMasterCompanion.xcodeproj

# Build from command line
xcodebuild -project AgentMasterCompanion.xcodeproj -scheme AgentMasterCompanion build
```

## Related

- [agent-master](https://github.com/user/agent-master) — AI Native knowledge base for agent practitioners
