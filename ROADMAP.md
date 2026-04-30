# Roadmap

## Released

### v0.1.0 — Scaffold + Release Pipeline

- [x] macOS menubar app scaffold (NSStatusItem + NSPopover + SwiftUI)
- [x] Tab navigation (Project / User / Scratch Pad)
- [x] GitHub Actions release workflow (tag → build → DMG → Release)
- [x] Ad-hoc code signing

### v0.2.0 — Core Features

- [x] Agent file registry (12 tools, whitelist-based)
- [x] Project-level file scanner with glob matching
- [x] File tree view grouped by tool
- [x] File viewer with read/edit toggle
- [x] User-level config status view
- [x] Claude Code memory scanning (user-level `~/.claude/projects/`)
- [x] User-level memory grouped by project (DisclosureGroup)
- [x] Scratch Pad with auto-save and prompt composer
- [x] Right-click context menu (About with project links, Quit)
- [x] Tab click target and HIG compliance improvements
- [x] Version injection from git tags at build time

## Planned

### v0.3.0 — Visual Polish

- [ ] App icon and menubar icon design
- [ ] Popover size optimization
- [ ] Dark mode contrast improvements
- [ ] File viewer line numbers (read-only mode)
- [ ] Save feedback indicator
- [ ] Scratch Pad note list preview
- [ ] Composer copy animation

### v0.4.0 — Product Site + Documentation

- [ ] Product landing page (GitHub Pages)
- [ ] Installation guide with Gatekeeper instructions
- [ ] Screenshot assets

### v1.0.0 — Signed Distribution

- [ ] Apple Developer Program enrollment
- [ ] Developer ID signing + notarization
- [ ] Homebrew Cask formula
- [ ] Sparkle 2 auto-update integration
- [ ] Global hotkey to toggle popover
