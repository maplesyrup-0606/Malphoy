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

### 2. Build and run

```bash
swift build -c release
.build/release/Malphoy
```

### 3. Configure the to-do file

Create the config directory and `.env` file:

```bash
mkdir -p ~/.config/malphoy
echo 'MALPHOY_TODOS_PATH=/absolute/path/to/your/todos.md' > ~/.config/malphoy/.env
```

Make sure the markdown file exists before launching. If you're using Obsidian, symlink your vault file to the same path:

```bash
ln -s /path/to/ObsidianVault/todos.md /absolute/path/to/your/todos.md
```

Or point `MALPHOY_TODOS_PATH` directly at the file inside your vault.

### 4. Grant Accessibility permission

Malphoy registers a global hotkey (`⌘Space`) using the Carbon API. macOS requires Accessibility access for this:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Add Malphoy (or your terminal / Xcode if running from there)

Without this, `⌘Space` won't trigger the launcher.

### 5. Auto-launch on login (optional)

To have Malphoy start automatically:

1. Build a release binary: `swift build -c release`
2. Copy it somewhere permanent: `cp .build/release/Malphoy ~/Applications/Malphoy`
3. Open **System Settings → General → Login Items**
4. Add `~/Applications/Malphoy`

### Notes

- The app hides from the Dock and app switcher by design — it runs as a background agent
- `⌘Space` may conflict with Spotlight. Disable Spotlight's shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Spotlight** if needed
