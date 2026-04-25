---
name: PII Protection
type: rule
severity: critical
verified: 2026-04-24
trigger: writing any content to files that may be committed or published
---

# PII Protection

## Rule

Before writing any content to project files, the agent MUST redact all Personally Identifiable Information (PII) including but not limited to: usernames, email addresses, account names, IP addresses, tokens, and any other information that could identify a person.

## Rationale

Tool outputs (CLI, logs, API responses) frequently contain PII that must be filtered before persisting. This rule was adopted from agent-master after a real PII leak incident where a GitHub username was committed to a public repository.

## Correct Behavior

```
# Wrong — exposes real username
"authenticated account (real-username) does not match target"

# Correct — redacted
"the currently authenticated account did not match the target account"
```

## Scope

- All files in the repository
- PR descriptions and commit messages
- Any output that may be visible to others
