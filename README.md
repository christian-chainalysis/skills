# Skills

Six agent skills for everyday code work. They work in Claude Code, opencode, Pi, and Codex.

| Skill | What it does |
| --- | --- |
| `/commit` | Splits your changes into small conventional commits, after running the repo's format and lint fixers. |
| `/pr` | Ships a branch: commits, rebases, runs the checks CI runs, adds a changeset, pushes, and opens the PR. Splits big changes into a stack of small PRs. |
| `/refine` | Removes noise a change added (comments that restate code, tests that cannot fail, debug leftovers) before review. Never changes behavior. |
| `/approach` | Checks whether a PR or plan solves the problem the right way, and proves alternatives in a throwaway worktree. |
| `/explain` | Explains a concept, PR, diff, or error with an example from your own code. |
| `/judge` | Reviews a branch, PR, or stack as a hostile reviewer. Reports only what is broken, each with the fix. |

## Install or update

Run this from any folder. Run it again to get new versions.

```sh
curl -fsSL christian-chainalysis.github.io/skills/install.sh | sh
```

Only some skills: add `| sh -s -- judge pr` instead of `| sh`.

The script finds each skill wherever you already keep it (the Claude Code, opencode, Pi, Codex, Cursor, or shared `~/.agents` skills folders) and updates it in place. A skill you don't have yet goes into `~/.claude/skills`, which Claude Code and opencode both read. To put new skills somewhere else, set `SKILLS_DIR=/path` before `sh`. Restart your agent after you install.

If you edited a `SKILL.md` by hand, the script saves your copy as `SKILL.md.bak` first. It skips any skill that is a symlink, because that belongs to your own setup.

## What you need

- `git` and the GitHub CLI (`gh`), logged in with `gh auth login`.
- For stacked PRs: git 2.38 or later and `gh extension install github/gh-stack`.

The skills check for these the first time they need them, and tell you how to install what is missing.

## Changes

See [CHANGELOG.md](CHANGELOG.md).
