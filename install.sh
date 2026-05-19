#!/bin/bash
set -e

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP="/Applications/Malphoy.app"
CONFIG_DIR="$HOME/.config/malphoy"
ENV_FILE="$CONFIG_DIR/.env"

echo ""
echo "${BOLD}Malphoy Installer${NC}"
echo "────────────────────────────────────────"
echo ""

# ── 1. Build ────────────────────────────────
echo "${BOLD}[1/3] Building...${NC}"
swift build -c release
echo "${GREEN}✓ Build complete${NC}"
echo ""

# ── 2. Install ──────────────────────────────
echo "${BOLD}[2/3] Installing to $APP...${NC}"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Malphoy "$APP/Contents/MacOS/Malphoy"
cp Info.plist "$APP/Contents/Info.plist"
echo "${GREEN}✓ Installed${NC}"
echo ""

# ── 3. Configure ────────────────────────────
echo "${BOLD}[3/3] Configuration${NC}"
echo ""
mkdir -p "$CONFIG_DIR"

# To-do file
CURRENT_PATH=""
if [[ -f "$ENV_FILE" ]]; then
    CURRENT_PATH=$(grep "MALPHOY_TODOS_PATH" "$ENV_FILE" 2>/dev/null | cut -d= -f2-)
fi

if [[ -n "$CURRENT_PATH" ]]; then
    echo "To-do file is currently linked to:"
    echo "  ${DIM}$CURRENT_PATH${NC}"
    echo ""
    read -p "Change it? (y/N): " CHANGE_TODO
    CHANGE_TODO="${CHANGE_TODO:-N}"
else
    CHANGE_TODO="y"
fi

if [[ "$CHANGE_TODO" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter the path to your to-do Markdown file."
    echo "${DIM}Tip: drag the file into this window to paste its path.${NC}"
    echo "${DIM}Leave blank to skip.${NC}"
    echo ""
    read -p "Path: " TODO_PATH

    if [[ -n "$TODO_PATH" ]]; then
        # Trim surrounding whitespace and quotes, expand ~
        TODO_PATH=$(echo "$TODO_PATH" | xargs)
        TODO_PATH="${TODO_PATH/#\~/$HOME}"

        if [[ -f "$TODO_PATH" ]]; then
            echo "MALPHOY_TODOS_PATH=$TODO_PATH" > "$ENV_FILE"
            echo "${GREEN}✓ Linked to: $TODO_PATH${NC}"
        else
            echo "${YELLOW}⚠ File not found at that path — skipping todo link.${NC}"
            echo "  You can set it later by editing: $ENV_FILE"
        fi
    else
        echo "${DIM}Skipped.${NC}"
    fi
fi

echo ""

# ── Launch ──────────────────────────────────
echo "Launching Malphoy..."
pkill Malphoy 2>/dev/null || true
sleep 0.5
open "$APP"
echo "${GREEN}✓ Running${NC}"

# ── Next steps ──────────────────────────────
echo ""
echo "────────────────────────────────────────"
echo "${BOLD}Setup complete${NC}"
echo ""
echo "${BOLD}Required: grant Accessibility access${NC}"
echo "Without it, the Cmd+Space hotkey won't work."
echo ""
read -p "Open Accessibility settings now? (Y/n): " OPEN_PREFS
OPEN_PREFS="${OPEN_PREFS:-Y}"
if [[ "$OPEN_PREFS" =~ ^[Yy]$ ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    echo "Add Malphoy from the list, then toggle it on."
fi

echo ""
echo "${BOLD}Optional: launch on login${NC}"
read -p "Open Login Items settings? (y/N): " OPEN_LOGIN
OPEN_LOGIN="${OPEN_LOGIN:-N}"
if [[ "$OPEN_LOGIN" =~ ^[Yy]$ ]]; then
    open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    echo "Click + and add $APP"
fi

echo ""
echo "Press ${BOLD}Cmd+Space${NC} to open the launcher."
echo ""
