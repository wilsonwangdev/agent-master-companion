---
name: File Access Boundary
type: rule
severity: critical
verified: 2026-04-24
trigger: any code that reads, writes, or displays files from the user's filesystem
---

# File Access Boundary

## Rule

This application operates on a strict whitelist. Only files explicitly registered as "non-sensitive instruction/context/rule" types may be scanned, read, or displayed. All other files are invisible to the application.

## Whitelist — Allowed File Types

Instruction files (exact name match at project root or nested):
- `CLAUDE.md`, `AGENTS.md`, `codex.md`
- `.cursorrules`, `.windsurfrules`, `.clinerules`, `.roomodes`
- `.augment-guidelines`
- `.aiderignore`

Instruction directories (recurse contents, depth limit 3):
- `.cursor/rules/`
- `.clinerules/` (when directory, not file)
- `.amazonq/rules/`
- `.github/instructions/`
- `.roo/`

Context files (specific subdirectories only):
- `.claude/memory/*.md`
- `.claude/plans/*.md`
- `.devin/rules.md`

## Blocklist — Never Access

Any file matching these patterns must never be read, cached, or displayed:
- `settings.json`, `settings.local.json`
- `config.*` (config.ts, config.yaml, config.json, config.toml)
- `.aider.conf.yaml`
- `*.key`, `*.pem`, `*.env`, `*.secret`
- `credentials*`, `token*`
- Any file inside `~/.config/codex/`, `~/.continue/` (config directories)
- `.devin/config.json`
- `.claude/settings.json`, `.claude/settings.local.json`

## Implementation

The `AgentFileRegistry` must enforce this boundary. Every file access path in the application must go through the registry's whitelist check. Direct `FileManager` reads that bypass the registry are a rule violation.

## Rationale

Agent configuration files frequently contain API keys, tokens, and credentials. By defining the product boundary at the feature level (we only handle instruction/context files), we eliminate the entire class of credential exposure risks rather than trying to detect and mask them after reading.
