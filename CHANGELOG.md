# Changelog

Newest first. Rerun `curl -fsSL christian-chainalysis.github.io/skills/install.sh | sh` to get these.

## 2026-10-26

- pr: UI changes get before and after screenshots uploaded straight into the PR description with `gh pr edit --attach`. It checks the two images differ and never commits images to the repo.
- pr: every PR body gets a Proof section matched to what the PR claims: screenshots or video for UI, a before and after repro for a fix, numbers for speed. "Tests pass" and "CI is green" no longer count as proof on their own.
- judge: lists each claim in the PR body that has no proof under a new Proof gaps section. Proof that contradicts the code is a finding.

## 2026-10-24

- approach, explain, refine: always check whether a PR is part of a stack, using GitHub's stack list first, and work on the whole stack.
- split: plans a stack as one change. It can merge thin PRs, split thick ones, and gives one RESTACK INTO N PRS plan for the whole stack.
- judge: weighs how likely a race or security failure is against what the fix costs. Rare cases with a costly fix go under Unverified so you decide.

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
