# Agent Master Companion

A macOS menubar utility for agent practitioners. Provides visual browsing and management of agent-related instruction/context/rule files across projects and user-level configurations.

## Current Plan

See `PLAN.md` for the full implementation plan. Check which phase is current and continue from there. Phase 0 (harness setup) is complete. Phase 1 (Xcode project scaffold) is next.

## Developer Context

The primary developer has zero macOS client development experience. Agent should provide detailed explanations for Swift/SwiftUI/AppKit concepts, Xcode workflows, and macOS-specific patterns. Don't assume familiarity with Interface Builder, code signing, or Apple frameworks.

## Tech Stack

- Swift + SwiftUI (UI) + AppKit (menubar/tray integration)
- macOS only, menubar-only app (no Dock icon)
- Non-sandboxed (needs filesystem access to dotfiles)
- Xcode project (not Swift Package Manager CLI)

## Project Structure

```
AgentMasterCompanion/
  App.swift              — @main entry, NSApplication config
  AppDelegate.swift      — NSStatusItem, popover management
  Views/                 — SwiftUI views
    Explorer/            — Agent file browser views
    ScratchPad/          — Scratch pad views
  Models/                — Data models and registry
  Services/              — File scanning, storage
  Resources/             — Assets, icons
rules/                   — Agent rules (quality-gated)
```

## Build & Run

```bash
# Build (command line)
xcodebuild -project AgentMasterCompanion.xcodeproj -scheme AgentMasterCompanion -arch arm64 -arch x86_64 build

# Run from Xcode
# Open AgentMasterCompanion.xcodeproj, Cmd+R
```

## Release Workflow

```bash
# 1. Ensure all release PRs are merged to main
git checkout main && git pull

# 2. Create release tag on main
git tag v0.2.0
git push origin v0.2.0

# 3. GitHub Actions will automatically:
#    - build universal app (arm64 + x86_64)
#    - inject version from git tag into built Info.plist
#    - package DMG
#    - generate SHA-256 checksum
#    - publish GitHub Release
```

Notes:
- Source `Info.plist` uses placeholder version `0.0.0-dev`
- Real version is injected at build time from the latest git tag
- Do not manually bump `CFBundleShortVersionString` for releases
- Verify every release by downloading the DMG and checking the app's About panel shows the tag version

## Safety — Product Boundary

This app operates on a strict whitelist of non-sensitive agent files only:
- Instruction files: `CLAUDE.md`, `AGENTS.md`, `codex.md`, `.cursorrules`, `.windsurfrules`, `.clinerules`, `.roomodes`, `.augment-guidelines`, `.devin/rules.md`
- Instruction directories: `.cursor/rules/`, `.clinerules/`, `.amazonq/rules/`, `.github/instructions/`
- Context files: `.claude/memory/*.md`, `.claude/plans/*.md`
- Ignore rules: `.aiderignore`

Never read, cache, or display configuration/credential files:
- `settings.json`, `settings.local.json`, `config.*`, `*.key`, `*.pem`, `*.env`
- `.aider.conf.yaml`, `.config/codex/config.toml`, `.continue/config.*`, `.devin/config.json`

See `rules/file-access-boundary.md` for the full rule.

## Safety — PII & Privacy

- App is fully offline, zero network requests
- No telemetry, no data collection
- File content is never cached; only paths and metadata are stored
- See `rules/pii-protection.md`

## Safety — Sensitive Patterns

- `.gitguard` contains patterns that pre-commit hook will reject
- Never write API keys, tokens, usernames, or account names into project files

## Git Workflow

- Never push directly to `main`. Always: branch → commit → push → PR.
- Branch naming: `feat/`, `fix/`, `infra/`, `ui/`, `build/`, `docs/`
- Atomic commits with prefixes: `feat:`, `fix:`, `infra:`, `ui:`, `build:`, `docs:`
- Message explains why, not what
- One concern per branch and per PR
- Before starting work: `git fetch -p && ./scripts/clean-branches.sh`
- After PR merge: run `./scripts/clean-branches.sh` to delete stale local branches
- See `rules/git-workflow.md` for full rules

## Commit Conventions

- `feat:` — new feature or capability
- `fix:` — bug fix
- `infra:` — project infrastructure (CI/CD, settings, configs, harness)
- `ui:` — UI/UX changes
- `build:` — build system, distribution, packaging
- `docs:` — documentation

## Key Pointers

- Rules define agent constraints → `rules/`
- This project is related to but independent from `agent-master` (knowledge base)
- Agent practices from `agent-master` are consumed via standard copy, not submodule
