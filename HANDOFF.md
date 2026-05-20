# HANDOFF — HoverNote

> Fresh-context handoff. Read this + `DESIGN.md` + `PLAN.md` before working.

## Goal

A Mac menu-bar app: a sage-glass Markdown notes panel that slides in from the
right screen edge. SwiftUI, macOS 14+, native materials. **North star: the
0.4-second body state change when the panel slides out.** Design *is* the
product — interaction/animation craft is judged at Bear / Things 3 / Linear
tier; "generic" is a failure (this bar is non-negotiable, see Memory below).

Repo: `git@github.com:oliverxuzy-ai/HoverNote.git` · branch `main` ·
direct-to-main flow (no PRs). Local-only `changes.md` is auto-appended by a
`pre-push` git hook (gitignored, not in repo).

## Current progress

**Shipped & public on GitHub** — `v0.3.0` is the current "Latest" release.
Auto-release: every push to `main` runs `.github/workflows/release.yml`, which
derives the next version from conventional commits since the last tag
(`feat` → minor, `fix` → patch, docs/chore → no release), builds the signed-to-run
`.dmg`, and publishes a public release with `feat`/`fix`-bucketed notes.

Milestone log (M0–M4 plus continuous shipping after):

- **M0–M2**: xcodegen scaffold, NSPanel single-spring slide + 3-layer glass +
  triple shadow, file storage (`~/Documents/SideNote/<ULID>.md`, YAML
  frontmatter, FSEvents sync, atomic writes), search, CRUD.
- **M3**: General Sans + JetBrains Mono bundled & runtime-registered;
  micro-motion tokens; edge-hover trigger (CGEventTap + Accessibility,
  opt-in via Preferences).
- **M4**: `.dmg` pipeline works; `v0.1.0` cut → un-drafted → made public.
- **Post-M4 (in `v0.2.x` / `v0.3.0`)**: live Markdown editing (Bear-style,
  no edit/preview toggle — regex highlighter + custom `NSLayoutManager`
  drawing real `•` bullets and clickable `☐/☑` to-do; markers recede but
  text is intact); `swift-markdown` dependency removed; swipe-to-pin
  (right) / swipe-to-delete (left) with **trackpad two-finger** (custom
  `scrollWheel`) + mouse drag (`NSPanGestureRecognizer`); ordered lists with
  hanging indent; slash command menu (`/` → Heading/list/to-do/quote/code);
  user-configurable reveal hotkey (key recorder in Preferences); hover
  feedback on every button; product rename to **HoverNote** (display name
  only — internal module / scheme / Xcode target stay `SideNote`); MIT
  `LICENSE`; README rewrite (EN + zh-CN) + app-icon hero.

29 unit tests green (storage round-trip, ULID, highlighter regex
tokenization, feature suite). HotKey is the only remaining SPM dependency.

## What worked

- **Verify with `xcodebuild`, ignore SourceKit** — SourceKit constantly
  false-flags "cannot find type X" cross-file. Only `xcodebuild` is truth.
- Build/test: `xcodegen generate` then
  `xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug build|test`.
- `.dmg`: `xcodebuild -configuration Release archive` → copy
  `HoverNote.app` from `*.xcarchive/Products/Applications/` → `create-dmg`
  (route A = ad-hoc "Sign to Run Locally", no exportArchive).
- Live editing without breaking cursor/undo: only change *attributes* (and
  draw glyphs in a custom layout manager), never mutate the text buffer.
- Hand-rolled gestures over libraries — keeps zero extra deps and full
  control of feel (project ethos).
- Every behavior/scope change is logged in `DESIGN.md` Decisions Log — keep
  doing this; it is the project's discipline.

## What didn't work / gotchas

- **`NSPanGestureRecognizer.allowedScrollTypesMask` does NOT exist on macOS**
  (UIKit-only). Trackpad two-finger swipe MUST be handled via
  `scrollWheel(with:)` (precise deltas + phase). Mouse drag via pan recognizer.
- **`.frame(width: 0)` does NOT clip in SwiftUI** — a `Color` background
  bled outside as colored bands behind every card. Fix: conditionally render
  + `.clipped()` (see `SwipeableCard.swift`).
- **Concurrent xcodebuild on shared DerivedData corrupts codesign** (the
  embedded test bundle ends up unsigned → "Command CodeSign failed"). Don't
  run a background archive while foreground-building. Fix: `rm -rf` the
  project's DerivedData dir and rebuild.
- `create-dmg` fails if a stale `/Volumes/HoverNote` is mounted — detach
  first. And zsh aborts a `&&` chain if a glob (`/Volumes/HoverNote*`) has
  no match — guard globs.
- Auto-mode classifier blocks `git push origin main` and `gh release` even
  on this solo repo. Ask the user to allow inline, or have them add a
  permission rule for `git push origin main` in this repo's settings.
- PP Editorial New (display font) is gated behind an email/click on
  pangrampangram.com — cannot be fetched programmatically.

## Next steps

Owner-only assets (not code) that would close the remaining visible gaps:

1. **PP Editorial New display font**: drop `PPEditorialNew-Regular.otf` +
   `PPEditorialNew-Italic.otf` into `SideNote/Resources/Fonts/` (code
   auto-detects by PostScript name; until then headlines fall back to system
   serif — see `EditorFont`/`Typography`). Push lands a `feat:` commit and
   the workflow cuts the next minor automatically.
2. **README hero screenshot**: drop a wide PNG at `docs/assets/hero.png`
   (suggested 2400×1500 @2x, panel slid out over a desktop wallpaper) and
   uncomment the `<img>` line in `README.md` + `README.zh-CN.md`. The slot
   already exists in both files.
3. **30-second demo GIF/MP4**: slide-in → switch note → create → pin →
   slide-out. Pin it under the hero or in the "What it is" section.
4. **Custom Open Graph social-preview image**: 1280×640 sage banner so
   Twitter/Slack link previews stop using GitHub's default.

Open follow-ups the user may raise: image thumbnails on cards (v1.1; no
image attachments in v1), search-ring focus rendering, further animation
polish.

## Map

- `SideNote/Features/Editor/LiveMarkdownEditor.swift` — live editor,
  `MarkdownLayoutManager`, `MarkdownTextView`, highlighter regexes.
- `SideNote/Features/Sidebar/SwipeableCard.swift` — swipe (scrollWheel +
  pan), action tiles. `NoteCard.swift` — card visuals (current = original
  layout + small footer pin).
- `SideNote/DesignSystem/` — `DesignTokens` (colors/motion), `Typography`,
  `FontRegistration`, `Interactions` (button styles).
- `SideNote/Core/` — `Storage` (NoteStore/NoteFile/FrontmatterCodec/ULID),
  `Triggers` (PanelController/HotkeyService/EdgeHoverService), `Window`.
- `DESIGN.md` = visual source of truth (sage monochrome, **no warm/red** —
  delete swipe uses near-black). `PLAN.md` = milestone log.

## Memory

Persistent feedback memory recorded: this user holds HoverNote to
Bear/Things-tier interaction craft; lead with the crafted version, never the
first thing that compiles; respect DESIGN.md's ban on decorative loaders
(local IO is instant — no shimmer/spinners).
