# Tatoeba — Flashcards (Sentence Mining)

Anki-style flashcards over Tatoeba.org's filtered sentence search. For mobile (iOS Safari) and desktop study of Spanish ↔ English.

## Install / Auto-update

1. Install [Tampermonkey](https://www.tampermonkey.net/).
2. Open the raw script and Tampermonkey will offer to install:
   <https://raw.githubusercontent.com/Will-cast/tatoeba-flashcards/main/tatoeba-flashcards.user.js>
3. Done. The script declares `@updateURL` / `@downloadURL`, so Tampermonkey checks this repo periodically and auto-updates every device once installed.

## Cross-device sync

- **Script + updates** — this repo (via `@updateURL`).
- **User config** (profiles, filters, controls) — synced separately through a private GitHub Gist configured inside the app.
