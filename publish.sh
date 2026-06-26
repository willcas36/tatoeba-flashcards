#!/usr/bin/env bash
# Publish the Tatoeba flashcards userscript so Tampermonkey auto-updates every device.
# Copies the canonical file -> repo, commits, and pushes to willcas36/tatoeba-flashcards.
set -euo pipefail

SRC="$HOME/.config/Tampermonkey/tatoeba-flashcards.user.js"
DIR="$HOME/repos/tatoeba-flashcards"
DST="$DIR/tatoeba-flashcards.user.js"

[ -f "$SRC" ] || { echo "Source not found: $SRC"; exit 1; }

# Syntax gate before publishing anything.
node --check "$SRC"

# Read the version from the header for the commit message.
VER=$(grep -m1 -E '^// @version' "$SRC" | awk '{print $3}')

cp "$SRC" "$DST"
cd "$DIR"

if git diff --quiet -- "$DST"; then
  echo "No changes to publish (repo already matches the source)."
  exit 0
fi

git add -A
git commit -q -m "release: v${VER}"
git push -q origin main
echo "Published v${VER} -> https://github.com/willcas36/tatoeba-flashcards"
echo "Tampermonkey will pick it up on its next update check (devices already installed from the raw URL)."
