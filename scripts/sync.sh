#!/bin/sh
# Copy the published skills from a source folder into this repo, then show the diff.
# Usage: scripts/sync.sh [source dir]   (default: ~/dev/dotfiles/home/.config/agents/skills)
# Then review, add a CHANGELOG line, commit, and push.
set -eu

SRC="${1:-$HOME/dev/dotfiles/home/.config/agents/skills}"
ROOT=$(cd "$(dirname "$0")/.." && pwd)

for dir in "$ROOT"/skills/*/; do
  s=$(basename "$dir")
  [ -f "$SRC/$s/SKILL.md" ] || { echo "missing: $SRC/$s/SKILL.md" >&2; exit 1; }
  cp "$SRC/$s/SKILL.md" "$ROOT/skills/$s/SKILL.md"
done

# Block anything that looks like a private name or secret before it goes public.
if grep -rniE "${SKILLS_BLOCKLIST:-chainalysis|/Users/|api[_-]?key|token=}" "$ROOT/skills"; then
  echo "blocked: the lines above look private. Fix them in the source first." >&2
  exit 1
fi

git -C "$ROOT" status --short
git -C "$ROOT" diff --stat
