# Changelog

Newest first. Rerun the install command to get these.

## 2026-10-12

- Published as a public repo with a one-line installer.
- judge: finds linked GitHub stacks first and reviews the whole stack. Offers `gh stack link` when the PRs are not linked yet. Local test runs check out the top PR's own branch instead of squashing the stack. Fixes carry up the stack with `gh stack rebase --upstack`.
- pr: reads each repo's changeset and PR title rules from its docs and CI, instead of a fixed list of repos.
- commit: finds the repo's own format and lint commands instead of assuming pnpm.
