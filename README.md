# side-note

A Mac sidebar Markdown notebook that slides in from screen edge.
Designed to be the most quietly beautiful notes app on macOS.

> **North star**: the 0.4-second body state change when the panel slides out from screen edge.
> Everything in this project serves that single moment.

---

## Status

**Pre-code.** Design system locked, implementation not started.

- ✅ Design direction (`/office-hours`, 2026-05-14)
- ✅ Visual system (`/design-consultation`, 2026-05-14, 3 iterations)
- ✅ `DESIGN.md` — single source of truth for every visual decision
- ⏳ SwiftUI scaffolding
- ⏳ v1 features (see below)

If you're reading this and the repo has nothing but `.md` files: that's
deliberate. Every visual decision is locked before a line of Swift exists.

---

## What it is

A native macOS app, macOS 14+, written in SwiftUI. It lives in your menu bar
and slides out from the right edge of the screen on a global hotkey or
edge-hover. You write Markdown. You pin notes. You close it. The app
disappears off-screen the same way it came.

It's not trying to be the most powerful note-taking tool. It's trying to be
the one your shoulders relax around.

### Comparable to (and how it differs)

- **SideNotes** — same UX category. side-note's bet is design polish,
  not feature parity.
- **Bear, Drafts, Things 3** — same craft tier, different category. We borrow
  their care for typography and material.
- **Apple Notes** — built into the OS. side-note is for people who want a
  separate, intentional writing surface that doesn't get tangled with iCloud
  family photos and grocery lists.
- **Obsidian** — not the same product. Obsidian is a vault. side-note is a
  drawer.

### What makes it different

1. **Sage monochrome palette.** No warm color anywhere. One sage hue at
   different intensities does the entire visual job. See `DESIGN.md`.
2. **Editorial serif headlines.** PP Editorial New for note titles. Mode-switch
   your brain from "terminal" to "writing" the moment you read the title.
3. **A real slide-in.** 320ms spring, 12pt content parallax. The panel and the
   contents are two layers. Your eye reads layers, not motion.
4. **Local-first, plain Markdown files.** Every note is a `.md` file with YAML
   frontmatter in `~/Documents/SideNote/`. Open in Obsidian or any text editor.
   No proprietary database, no sync, no lock-in.

---

## Design system

Everything visual lives in [`DESIGN.md`](DESIGN.md). The short version:

| Layer       | Value                                                                   |
|-------------|-------------------------------------------------------------------------|
| Canvas      | `#F1F2E9` static target, `NSVisualEffectView` + 92% opacity for vibrancy |
| Accent      | `#6E8060` refined rosemary sage (only color in the system)              |
| Surface     | `rgba(255, 255, 255, 0.55)` translucent cards on canvas                 |
| Display     | PP Editorial New (Pangram Pangram, free)                                |
| Body        | General Sans (Fontshare, free)                                          |
| Mono        | JetBrains Mono                                                          |
| Base unit   | 4pt (macOS HIG)                                                         |
| Slide-in    | 320ms spring + 12pt parallax                                            |

If you're working on this codebase, read `DESIGN.md` before changing any
visual code. No deviation without explicit reason.

---

## Building from source

This project uses [xcodegen](https://github.com/yonaskolb/XcodeGen) to keep the
Xcode project as a declarative file (`project.yml`) instead of a binary blob.
`SideNote.xcodeproj` is intentionally gitignored.

```bash
# one-time setup
brew install xcodegen

# every time after cloning, or after editing project.yml
xcodegen generate

# open in Xcode and run
open SideNote.xcodeproj
# then ⌘R
```

Requirements:

- Xcode 15+ (tested on 26.4)
- macOS 14.0+ (Sonoma) as deployment target
- No Apple Developer account needed for local dev (ad-hoc "Sign to Run Locally")

## v1 scope

### In

- Slide-in / slide-out panel triggered by menu bar icon, global hotkey, or
  edge hover (any combination, user-toggled)
- Markdown rendering (v1 subset: H1–H3, paragraph, lists, inline code, code
  blocks, blockquote, bold/italic, links)
- Pin notes (frontmatter `pinned: true`, sage ceramic pin element)
- Tags (frontmatter `tags: [...]`)
- Title-and-tag search (`⌘F`)
- Basic note ops: new (`⌘N`), delete (`⌘⌫` to Trash), rename via title edit
- Light theme only (sage monochrome)
- Two-way sync with external Markdown editors via FSEvents
- Self-signed `.dmg` distribution via GitHub Releases

### Explicitly out (for now)

- Dark theme — needs its own mood board first
- Cloud sync — local-first, single-device for v1
- iOS / cross-platform — Mac only
- AI features — user explicitly rejected "AI-native" framing in office-hours
- Mac App Store — `CGEventTap` (used for edge-hover trigger) cannot run in
  the App Store sandbox. Path forked at v2.
- Notarization — accepted Gatekeeper prompt on first launch for v1
- Tables, images, task lists in Markdown — v1.1
- Pin physics (drag-and-bounce) — v1.1

### Out forever (probably)

- Tags-as-folders, nested categories, anything that asks the user to
  pre-classify their notes. The app encourages writing, not organizing.

---

## Stack

- **Language**: Swift 5.10+ / SwiftUI
- **Min target**: macOS 14.0 (Sonoma)
- **Markdown AST**: `apple/swift-markdown`
- **Hotkey**: `soffes/HotKey`
- **Storage**: filesystem (`~/Documents/SideNote/*.md`)
- **No Rust, no Electron, no Tauri.** Native materials are the whole point.

---

## Roadmap

### v1 (~3–4 weeks solo)

Ship the light theme. Sage monochrome. Make it beautiful enough to record a
30-second demo video without cringing.

### v1.1

Markdown subset expansion (images, tables, task lists). Pin physics. Polish
animation states.

### v2

Dark theme (separate mood board → separate `/design-consultation`).
Notarization. Sparkle auto-update. Possibly iOS companion.

---

## Project artifacts

User-private design history, not in this repo:

- `~/.gstack/projects/side-note/zhengyangxu-unknown-design-20260514-194317.md`
  — full design doc with rationale and decision log
- `~/.gstack/projects/side-note/mood-board-light.png` — 8 references that
  defined the light theme
- `~/.gstack/projects/side-note/designs/design-system-20260514/` — preview
  iterations + `approved.json`

These shaped what's in this repo but aren't part of the codebase.

---

## Acknowledgments

- **Kinfolk** — for proving that sage can be a brand
- **Things 3 (Cultured Code)** — for the bar on Mac native craft
- **Linear** — for showing that monochrome design systems are not boring
- **PP Editorial New (Pangram Pangram)** — the typeface
- **General Sans (Indian Type Foundry)** — the typeface
- **SideNotes** — for being the category-defining workhorse we're trying to
  out-design

---

## License

TBD. Personal project. Will likely be MIT when the code lands.

---

*Built with patience by [@oliverxuzy](https://github.com/oliverxuzy-ai).*
