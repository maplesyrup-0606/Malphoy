# Malphoy

A minimal, keyboard-driven macOS launcher. No mouse needed, no bloat.

---

## Overview

Malphoy is a personal productivity launcher for macOS. Summoned with a hotkey, it gives you fast access to apps, files, todos, and a calculator — all from a single keyboard-driven interface.

---

## Design

- **Dark, frosted glass** window — transparent dark background using `NSVisualEffectView`
- **No title bar**, rounded corners
- **Centered** on screen
- **~680×450** default size
- **Fully keyboard driven** — no mouse required at any point

---

## Hotkey

| Key | Action |
|-----|--------|
| `⌘Space` | Toggle show / hide |
| `Escape` | Dismiss |
| `Tab` | Cycle through tabs |
| `↑ / ↓` | Navigate results |
| `Enter` | Confirm / launch / act |

---

## Tabs

Pressing `Tab` cycles through four modes in order:

**Apps → Files → To-do → Calculator**

The window always opens on **Apps** regardless of which tab was last active.

---

## Apps

Search and launch applications instantly.

- **Search scope** — `/Applications`, `~/Applications`, `/System/Applications` (includes Utilities)
- **Top 8 results** shown, updated on every keypress
- **Pure fuzzy match** — no recency bias, strictly match quality
- `Enter` — launches the selected app

---

## Files

Search your home directory and reveal files in Finder.

- **Search scope** — `~` (home directory), recursive
- **Excludes** hidden files and folders (anything prefixed with `.`)
- **Top 8 results**, fuzzy match, updates on every keypress
- `Enter` — reveals the selected file's location in Finder

---

## To-do

A lightweight persistent task list.

- **Type + Enter** — creates a new to-do item
- **Enter on an existing item** — toggles done / not done
- No priorities or due dates
- **Reads and writes a markdown file** — standard Obsidian task syntax (`- [ ]` / `- [x]`)
- Path configured via `~/.config/malphoy/.env`

---

## Calculator

A live expression evaluator.

- Results appear **as you type** — no need to press Enter to evaluate
- Supports:
  - Basic arithmetic — `+`, `-`, `*`, `/`
  - Functions — `sqrt`, `sin`, `cos`, `tan`, `log`, etc.
  - Percentages — e.g. `15% of 200`
- `Enter` — copies the result to clipboard
- No external dependencies — powered by `NSExpression` (built into Foundation)

---

## Tech Stack

- **Swift** — primary language
- **AppKit** — window management (`NSPanel`), app launching (`NSWorkspace`)
- **Foundation** — `NSMetadataQuery` for file search, `NSExpression` for calculator
- **FSEvents** — app index updates when `/Applications` changes
- No third-party dependencies

---

## Platform

- macOS only
- Personal use — no App Store distribution, no signing required
- Built with Swift Package Manager — no Xcode project file required

---

## Installation

### 1. Clone

```bash
git clone <your-repo-url>
cd Malphoy
```

### 2. Build the app bundle

```bash
swift build -c release
mkdir -p /Applications/Malphoy.app/Contents/MacOS
cp .build/release/Malphoy /Applications/Malphoy.app/Contents/MacOS/Malphoy
```

An `Info.plist` is required alongside the binary so macOS treats it as a proper background app (no Terminal window, no Dock icon):

```
/Applications/Malphoy.app/
  Contents/
    MacOS/
      Malphoy
    Info.plist
```

The `Info.plist` is already committed in the repo. Copy it into place:

```bash
cp Info.plist /Applications/Malphoy.app/Contents/Info.plist
```

Then launch:

```bash
open /Applications/Malphoy.app
```

> **Rebuilding:** After any `swift build -c release`, re-run the `cp` for the binary only — the `Info.plist` stays in place.

### 3. Configure the to-do file

```bash
mkdir -p ~/.config/malphoy
echo 'MALPHOY_TODOS_PATH=/absolute/path/to/your/todos.md' > ~/.config/malphoy/.env
```

Point `MALPHOY_TODOS_PATH` at any markdown file. If you use Obsidian, point it directly at the file inside your vault — no symlink needed.

### 4. Grant Accessibility permission

Malphoy registers a global hotkey (`⌘Space`) using the Carbon API. macOS requires Accessibility access for this:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Add **Malphoy**

Without this, `⌘Space` won't trigger the launcher.

### 5. Auto-launch on login (optional)

1. Open **System Settings → General → Login Items**
2. Click `+` and add `/Applications/Malphoy.app`

It will start silently on login with no Dock icon or Terminal window.

### Notes

- The app hides from the Dock and app switcher by design — it runs as a background agent
- `⌘Space` may conflict with Spotlight. Disable Spotlight's shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Spotlight** if needed
