---
name: Git Workflow
type: rule
severity: high
verified: 2026-04-24
trigger: any git branch, commit, or PR operation
---

# Git Workflow

## Rule

### Branches

- Branch from `main`, name with prefix: `feat/`, `fix/`, `infra/`, `ui/`, `build/`, `docs/`
- One concern per branch. Never mix unrelated changes.
- Delete local branches after PR merge or close. Run `git fetch -p` to prune stale remote refs.

### Commits

- Atomic: one logical change per commit
- Prefixed message: `feat:`, `fix:`, `infra:`, `ui:`, `build:`, `docs:`
- Message explains why, not what

### Pull Requests

- Never push directly to `main` — always branch + PR
- One concern per PR. If a PR description needs multiple unrelated sections, split it.
- PR title follows commit prefix convention

### Hygiene

- After PR merge: delete merged local branches
- Before starting work: `git fetch -p && git branch -v` to see stale branches
