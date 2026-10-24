# Changelog

Newest first. Rerun `curl -fsSL christian-chainalysis.github.io/skills/install.sh | sh` to get these.

## 2026-10-24

- approach, explain, refine: always check whether a PR is part of a stack, using GitHub's stack list first, and work on the whole stack.
- split: plans a stack as one change. It can merge thin PRs, split thick ones, and gives one RESTACK INTO N PRS plan for the whole stack.

## 2026-10-15 (later)

- split: gives the same verdict on every run. It writes a decision record before the verdict, and KEEP AS IS now lists the big pieces it turned down and anything to fix first, such as a rebase or a migration collision.

## 2026-10-15

- split: new. Checks whether a big PR bundles several PRs. Says KEEP AS IS when it does not. When it does, shows each piece with code and test counts, a tree of PRs off main or stacked, and a prompt to paste into the author's agent.

## 2026-10-12 (later)

- Shorter install URL.
- The installer updates each skill wherever you already keep it, instead of always using `~/.claude/skills`.

## 2026-10-12

- Published as a public repo with a one-line installer.
- judge: finds linked GitHub stacks first and reviews the whole stack. Offers `gh stack link` when the PRs are not linked yet. Local test runs check out the top PR's own branch instead of squashing the stack. Fixes carry up the stack with `gh stack rebase --upstack`.
- pr: reads each repo's changeset and PR title rules from its docs and CI, instead of a fixed list of repos.
- commit: finds the repo's own format and lint commands instead of assuming pnpm.
