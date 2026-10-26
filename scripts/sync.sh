#!/bin/sh
# Copy the published skills, with their scripts and other files, from a source folder into this repo, then show the diff.
# Usage: scripts/sync.sh [source dir]   (default: ~/dev/dotfiles/home/.config/agents/skills)
# Then review, add a CHANGELOG line, commit, and push.
set -eu

SRC="${1:-$HOME/dev/dotfiles/home/.config/agents/skills}"
ROOT=$(cd "$(dirname "$0")/.." && pwd)

for dir in "$ROOT"/skills/*/; do
  s=$(basename "$dir")
  [ -f "$SRC/$s/SKILL.md" ] || { echo "missing: $SRC/$s/SKILL.md" >&2; exit 1; }
  cp -RL "$SRC/$s/." "$ROOT/skills/$s/"
  find "$ROOT/skills/$s" \( -name .DS_Store -o -name '*.backup' -o -name '__pycache__' \) -exec rm -rf {} +
done

# Block anything that looks like a private name or secret before it goes public.
# leak-guard reads a private term list kept outside this repo.
command -v leak-guard >/dev/null || { echo "blocked: leak-guard is not installed." >&2; exit 1; }
(cd "$ROOT" && leak-guard tree) || { echo "blocked: fix the lines above in the source first." >&2; exit 1; }
if grep -rniE "/Users/|api[_-]?key|token=" "$ROOT/skills"; then
  echo "blocked: the lines above look private. Fix them in the source first." >&2
  exit 1
fi

git -C "$ROOT" status --short
git -C "$ROOT" diff --stat
