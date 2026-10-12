#!/bin/sh
# Install or update agent skills from christian-chainalysis/skills.
#
#   curl -fsSL https://raw.githubusercontent.com/christian-chainalysis/skills/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- judge pr     # only some skills
#   curl -fsSL .../install.sh | sh -s -- --list       # show what is available
#
# Copies each skill into ~/.claude/skills (read by Claude Code and opencode),
# and into the Pi and Codex skills folders when they exist. A SKILL.md you edited by hand is kept
# as SKILL.md.bak before it is replaced.
set -eu

REPO="christian-chainalysis/skills"
REF="${SKILLS_REF:-main}"
URL="https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF"

# Claude Code and opencode both read ~/.claude/skills. Pi and Codex get a copy
# only when their folder already exists.
TARGETS="$HOME/.claude/skills
$HOME/.pi/agent/skills
$HOME/.codex/skills"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

curl -fsSL "$URL" | tar -xz -C "$TMP" || die "could not download $URL"
SRC=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)/skills
[ -d "$SRC" ] || die "no skills folder in the download"

AVAILABLE=$(ls "$SRC")

if [ "${1:-}" = "--list" ]; then
  say "$AVAILABLE"
  exit 0
fi

if [ "$#" -gt 0 ]; then
  WANTED="$*"
  for s in $WANTED; do
    [ -d "$SRC/$s" ] || die "unknown skill: $s (available: $(echo $AVAILABLE))"
  done
else
  WANTED=$AVAILABLE
fi

mkdir -p "$HOME/.claude/skills"

echo "$TARGETS" | while IFS= read -r dir; do
  [ -d "$dir" ] || continue
  for s in $WANTED; do
    dest="$dir/$s"
    # A symlinked skill folder or file belongs to the user's own setup. Leave it alone.
    if [ -L "$dest" ] || [ -L "$dest/SKILL.md" ]; then
      say "skip  $dest (symlink, managed elsewhere)"
      continue
    fi
    mkdir -p "$dest"
    if [ -f "$dest/SKILL.md" ]; then
      if cmp -s "$SRC/$s/SKILL.md" "$dest/SKILL.md"; then
        say "same  $dest"
        continue
      fi
      if [ -f "$dest/.installed" ] && cmp -s "$dest/SKILL.md" "$dest/.installed"; then
        :
      else
        cp "$dest/SKILL.md" "$dest/SKILL.md.bak"
        say "kept  $dest/SKILL.md.bak (it had local edits)"
      fi
    fi
    cp -R "$SRC/$s/." "$dest/"
    cp "$SRC/$s/SKILL.md" "$dest/.installed"
    say "ok    $dest"
  done
done

say ""
say "Done. Restart your agent so it loads the new skills."
say "Changes: https://github.com/$REPO/blob/main/CHANGELOG.md"
