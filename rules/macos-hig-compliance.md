---
name: macOS HIG Compliance
type: rule
severity: high
verified: 2026-04-30
trigger: any SwiftUI view creation or modification
---

# macOS HIG Compliance

## Rule

All UI must meet Apple Human Interface Guidelines standards for macOS. This rule provides concrete values for agent-assisted development.

## Click Targets

Minimum 24x24 pt for all interactive elements. SwiftUI plain-style image buttons default to ~17pt — always pad.

```swift
// WRONG — hit area too small
Button(action: {}) { Image(systemName: "chevron.left") }
    .buttonStyle(.plain)

// RIGHT — explicit minimum hit area
Button(action: {}) {
    Image(systemName: "chevron.left")
        .frame(minWidth: 24, minHeight: 24)
        .contentShape(Rectangle())
}
.buttonStyle(.plain)
```

For list rows and full-width buttons, use `.contentShape(Rectangle())` to extend the hit area to the full row.

## Spacing (8pt Grid)

| Token | Value | Use |
|-------|-------|-----|
| Tight | 4 pt | Between related inline elements |
| Standard | 8 pt | Default gap |
| Related group | 12 pt | Between label and content |
| Section | 16 pt | Between sections, default padding |
| View margin | 20 pt | Content inset from edges |

## Button Sizes

| controlSize | Height | Use |
|-------------|--------|-----|
| `.mini` | ~16 pt | Table cells |
| `.small` | ~22 pt | Sidebars, secondary actions |
| `.regular` | ~28 pt | Standard (default) |
| `.large` | ~32 pt | Primary actions |

## List Row Heights

| Style | Height |
|-------|--------|
| `.sidebar` | ~28 pt |
| `.plain` / `.inset` | ~24 pt |

## Text Truncation

- File paths: always `.truncationMode(.middle)` + `.help(fullPath)` tooltip
- File names: `.truncationMode(.tail)` (default)
- All truncated text: `.lineLimit(1)`

## Popover Sizing

- Typical: 260-320 pt wide
- Maximum: ~500 pt wide
- Content padding: 16-20 pt
- Always set explicit `.frame()` on root view to prevent layout recursion

## DisclosureGroup

- System-managed disclosure arrow (~9 pt)
- Indent per level: ~20 pt
- Row height matches list style (~28 pt for sidebar)
