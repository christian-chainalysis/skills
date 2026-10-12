#!/bin/sh
# Install or update agent skills from christian-chainalysis/skills.
#
#   curl -fsSL christian-chainalysis.github.io/skills/install.sh | sh
#   curl -fsSL christian-chainalysis.github.io/skills/install.sh | sh -s -- judge pr   # only some
#   curl -fsSL christian-chainalysis.github.io/skills/install.sh | sh -s -- --list     # what is available
#
# Updates each skill wherever a copy already lives, in any agent's skills folder.
# A skill with no copy yet goes into ~/.claude/skills, which Claude Code and
# opencode both read. A SKILL.md you edited by hand is kept as SKILL.md.bak.
# Symlinked skills belong to your own setup and are left alone.
set -eu

REPO="christian-chainalysis/skills"
REF="${SKILLS_REF:-main}"
URL="https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF"
DEFAULT_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"

# Every folder an agent reads skills from.
ROOTS="$HOME/.claude/skills
$HOME/.config/opencode/skills
$HOME/.config/opencode/skill
$HOME/.config/agents/skills
$HOME/.agents/skills
$HOME/.pi/agent/skills
$HOME/.codex/skills
$HOME/.cursor/skills"

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

install_to() { # $1 skill, $2 destination folder
  s=$1
  dest=$2
  if [ -L "$dest" ] || [ -L "$dest/SKILL.md" ]; then
    say "skip  $dest (symlink, managed elsewhere)"
    return
  fi
  mkdir -p "$dest"
  if [ -f "$dest/SKILL.md" ]; then
    if cmp -s "$SRC/$s/SKILL.md" "$dest/SKILL.md"; then
      say "same  $dest"
      return
    fi
    if ! { [ -f "$dest/.installed" ] && cmp -s "$dest/SKILL.md" "$dest/.installed"; }; then
      cp "$dest/SKILL.md" "$dest/SKILL.md.bak"
      say "kept  $dest/SKILL.md.bak (it had local edits)"
    fi
  fi
  cp -R "$SRC/$s/." "$dest/"
  cp "$SRC/$s/SKILL.md" "$dest/.installed"
  say "ok    $dest"
}

for s in $WANTED; do
  found=0
  for root in $ROOTS; do
    if [ -e "$root/$s/SKILL.md" ] || [ -L "$root/$s" ]; then
      found=1
      install_to "$s" "$root/$s"
    fi
  done
  [ "$found" -eq 1 ] || install_to "$s" "$DEFAULT_DIR/$s"
done

say ""
say "Done. Restart your agent so it loads the new skills."
say "Changes: https://github.com/$REPO/blob/main/CHANGELOG.md"
