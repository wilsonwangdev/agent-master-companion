---
name: External System Diagnosis
type: rule
severity: high
verified: 2026-04-24
trigger: any issue involving external platforms (Xcode, macOS APIs, Apple Developer tools, GitHub Actions, third-party frameworks)
---

# External System Diagnosis

## Rule

When diagnosing issues with external systems, follow this strict order. Do not skip steps.

### 1. Local evidence first

- `git log --oneline -10` — check recent commits for prior attempts
- Read the relevant files that were recently changed
- Check Xcode build logs and console output

### 2. Official tools second

- Use official CLI (`xcodebuild`, `xcrun`, `codesign`, `gh`, etc.) to query real state
- Check Xcode Organizer for build/archive status
- Check deployment logs, environment variables

### 3. Official documentation third

- Consult Apple's official docs for the specific API or framework
- Check Swift/SwiftUI release notes for version-specific behavior
- Check troubleshooting pages specifically

### 4. Inference last

- Only after steps 1-3 fail to resolve, begin experimentation
- Each experiment should be minimal and reversible

## Rationale

Adapted from agent-master. Agents that skip reading recent commits and jump to guessing waste time repeating failed approaches. Local evidence and official tools provide ground truth before inference.

## Anti-Patterns

- Jumping to documentation without checking what was already tried locally
- Guessing at solutions without using available CLI tools to query actual state
- Treating build errors as novel without checking if they were already encountered
