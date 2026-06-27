#!/usr/bin/env bash
# Publish one userscript from the monorepo so Tampermonkey auto-updates every device.
# Usage: ./publish.sh <script-folder>     e.g. ./publish.sh tatoeba-flashcards
# Single source of truth: this repo. Edit the .user.js, bump its @version, then publish.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Collect available script folders (each holds <folder>/<folder>.user.js).
scripts=()
for d in "$DIR"/*/; do
  name="$(basename "$d")"
  [ -f "$d/$name.user.js" ] && scripts+=("$name")
done

if [ ${#scripts[@]} -eq 0 ]; then
  echo "No scripts found in $DIR"
  exit 1
fi

# Pure-bash arrow-key picker (no dependency). Menu -> stderr, chosen value -> stdout.
arrow_pick() {
  local options=("$@") sel=0 key
  printf '\e[?25l' >&2 # hide cursor
  while true; do
    local i
    for i in "${!options[@]}"; do
      if [ "$i" -eq "$sel" ]; then
        printf '\e[7m  %s  \e[0m\n' "${options[$i]}" >&2 # highlighted row
      else
        printf '    %s\n' "${options[$i]}" >&2
      fi
    done
    IFS= read -rsn1 key
    if [ "$key" = $'\e' ]; then
      read -rsn2 -t 1 key # entero: bash 3.2 (macOS) no acepta timeouts fraccionales
      case "$key" in
        '[A') ((sel > 0)) && ((sel--)) ;;                        # up
        '[B') ((sel < ${#options[@]} - 1)) && ((sel++)) ;;       # down
      esac
    elif [ -z "$key" ]; then
      break # Enter
    fi
    printf '\e[%dA' "${#options[@]}" >&2 # cursor back up to redraw in place
  done
  printf '\e[?25h' >&2 # show cursor
  printf '%s\n' "${options[$sel]}"
}

NAME="${1:-}"

# No argument -> interactive picker (fzf if installed, else arrow-key bash picker).
if [ -z "$NAME" ]; then
  echo "Pick a script to publish (↑/↓ + Enter):" >&2
  if command -v fzf >/dev/null 2>&1; then
    NAME="$(printf '%s\n' "${scripts[@]}" | fzf --height=~40% --prompt='publish > ')"
  else
    NAME="$(arrow_pick "${scripts[@]}")"
  fi
  [ -z "$NAME" ] && {
    echo "Cancelled."
    exit 1
  }
fi

FILE="$DIR/$NAME/$NAME.user.js"
if [ ! -f "$FILE" ]; then
  echo "Not found: $FILE"
  printf '  - %s\n' "${scripts[@]}"
  exit 1
fi

# Push as the personal account (two gh accounts live on this machine).
if command -v gh >/dev/null 2>&1; then
  gh auth switch -u willcas36 -h github.com >/dev/null 2>&1 || true
fi

# Syntax gate.
node --check "$FILE"

# Version from the header for the commit message.
VER=$(grep -m1 -E '^// @version' "$FILE" | awk '{print $NF}')

cd "$DIR"
git add "$NAME"

if git diff --cached --quiet; then
  echo "No changes to publish in '$NAME' (already up to date)."
  exit 0
fi

git commit -q -m "release($NAME): v${VER}"
git push -q origin main
echo "Published $NAME v${VER}"
echo "  -> https://raw.githubusercontent.com/willcas36/userscripts/main/$NAME/$NAME.user.js"
echo "Tampermonkey picks it up on its next update check (devices installed from the raw URL)."
