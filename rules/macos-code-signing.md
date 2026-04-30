---
name: macOS Code Signing for Distribution
type: rule
severity: high
verified: 2026-04-30
trigger: any build script, xcodebuild, or distribution-related change
---

# macOS Code Signing for Distribution

## Rule

When building macOS apps for distribution, always use ad-hoc signing as the minimum baseline. Never completely disable code signing.

## Signing Levels

| Level | Identity | User Experience | Cost |
|-------|----------|----------------|------|
| Notarized | Developer ID + notarization | Opens directly, no warning | $99/yr |
| Developer ID | Developer ID certificate | "Unverified developer" warning, can open | $99/yr |
| Ad-hoc | `CODE_SIGN_IDENTITY="-"` | Gatekeeper warning, open via System Settings | Free |
| None | `CODE_SIGNING_ALLOWED=NO` | Gatekeeper warning, same flow as ad-hoc on Sequoia | - |

## Reality Check (macOS Sequoia+)

On macOS Sequoia and later, ad-hoc signing and unsigned apps produce **the same user experience**: Gatekeeper blocks the app, user must go to System Settings → Privacy & Security → "Open Anyway". The historical distinction (ad-hoc = softer warning, unsigned = "Move to Trash" only) no longer holds.

Ad-hoc signing is still the correct default because:
- It guarantees binary integrity (tamper detection)
- It is required for Apple Silicon hardened runtime in the future
- It costs nothing and has no downside

But it does **not** improve the first-launch experience compared to unsigned builds. The only way to eliminate the Gatekeeper warning is Developer ID signing + notarization ($99/yr Apple Developer Program).

## Correct Build Flags

```bash
# Ad-hoc signing (v0 minimum)
CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES
```
