---
name: macOS Code Signing for Distribution
type: rule
severity: high
verified: 2026-04-30
trigger: any build script, xcodebuild, or distribution-related change
---

# macOS Code Signing for Distribution

## Rule

When building macOS apps for distribution (DMG, ZIP, GitHub Releases), always use ad-hoc signing as the minimum baseline. Never completely disable code signing.

## Signing Levels

| Level | Identity | User Experience | Cost |
|-------|----------|----------------|------|
| Notarized | Developer ID + notarization | Opens directly | $99/yr |
| Developer ID | Developer ID certificate | "Unverified developer", can open | $99/yr |
| Ad-hoc | `CODE_SIGN_IDENTITY="-"` | "Cannot verify", Open Anyway in Settings | Free |
| None | `CODE_SIGNING_ALLOWED=NO` | "Move to Trash", no direct open option | - |

## Correct Build Flags

```bash
# Ad-hoc signing (v0 minimum)
CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES

# WRONG — produces unsigned binary, worst Gatekeeper experience
CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Why

Agents generating build scripts tend to copy `CODE_SIGNING_ALLOWED=NO` from search results. This produces completely unsigned binaries that macOS Gatekeeper treats as maximum threat — users see "Move to Trash" with no option to open. Ad-hoc signing (`-`) is free, requires no Apple Developer account, and downgrades the warning to "Open Anyway" in System Settings.

This distinction cost us a release rebuild (v0.1.0 → v0.1.1).
