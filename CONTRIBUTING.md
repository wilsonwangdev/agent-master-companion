# Contributing

Thanks for your interest in Agent Master Companion. This document covers everything you need to get started.

## Development Environment

- macOS 13.0 (Ventura) or later
- Xcode 15+ (Swift 5, SwiftUI)
- No additional dependencies — the project uses only Apple frameworks

```bash
# Clone and open
git clone https://github.com/wilsonwangdev/agent-master-companion.git
cd agent-master-companion
open AgentMasterCompanion.xcodeproj

# Build and run: Cmd+R in Xcode
```

## Branch and PR Workflow

- Never push directly to `main`. Always: branch → commit → push → PR.
- Branch naming: `feat/`, `fix/`, `infra/`, `ui/`, `build/`, `docs/`
- One concern per branch and per PR.
- PRs are squash-merged. Intermediate commits are development process, not project history.
- After PR merge: `./scripts/clean-branches.sh` to delete stale local branches.

See `rules/git-workflow.md` for full rules.

## Commit Conventions

Atomic commits with prefixes. Message explains why, not what.

| Prefix | Use |
|--------|-----|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `infra:` | CI/CD, settings, configs, harness |
| `ui:` | UI/UX changes |
| `build:` | Build system, distribution, packaging |
| `docs:` | Documentation |

## Safety Boundaries

This app operates on a strict whitelist of non-sensitive agent files. Before contributing, understand these constraints:

- **Only whitelisted file patterns** are scanned and displayed (see `Models/AgentFileRegistry.swift`)
- **Never read configuration or credential files** (`settings.json`, `config.*`, `*.key`, `*.env`)
- **App is fully offline** — no network requests, no telemetry, no data collection
- **File content is never cached** — only paths and metadata are stored

See `rules/file-access-boundary.md` for the full rule.

## Building and Testing

```bash
# Command-line build
xcodebuild -project AgentMasterCompanion.xcodeproj \
  -scheme AgentMasterCompanion build

# Run from Xcode: Cmd+R

# Build DMG for distribution
./scripts/build_dmg.sh
```

There is no automated test suite yet. Verify changes manually in Xcode.

## Release Process

Releases are triggered by git tags. See the Release Workflow section in `CLAUDE.md`.

```bash
git checkout main && git pull
git tag v0.X.0
git push origin v0.X.0
# GitHub Actions builds and publishes automatically
```

## macOS UI Guidelines

Follow `rules/macos-hig-compliance.md` for concrete values:
- Minimum 24x24pt click targets
- 8pt spacing grid
- `.truncationMode(.middle)` + `.help()` for file paths
- `.contentShape(Rectangle())` for full-width list row clicks

## Adding Support for New Agent Tools

To add a new agent tool to the scanner:

1. Add a case to `AgentTool` enum in `Models/AgentTool.swift`
2. Add file patterns to `AgentFileRegistry.patterns` in `Models/AgentFileRegistry.swift`
3. Mark sensitive files as `isSensitive: true` — they will be excluded from scanning
