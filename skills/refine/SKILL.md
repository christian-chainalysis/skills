---
name: refine
description: Clean up a branch, PR, or stack of PRs before review by removing noise the change added, like comments that restate the code, tests that cannot fail, debug leftovers, and dead code. Never changes behavior. Shows a short plan and waits for OK. Use when the user types /refine, or asks to clean up, tidy, trim, or refine a branch or change before opening a PR.
---

# Refine

Remove noise from the change so reviewers only read what matters. Agents over-write comments and tests. This skill cuts them back.

Never change behavior. If a removal could change what the code does, leave it.

## Scope

- Default: the current branch against the default branch. `DEFAULT=$(git remote show origin | sed -n 's/.*HEAD branch: //p')`, then `git fetch origin` and diff against `origin/$DEFAULT...HEAD`, plus uncommitted work.
- Only touch lines this change added or modified. Never clean up code the change did not touch, even if it is noisy.
- If the user names files or a path, refine only those.
- If the user names a PR, or the current branch's PR is part of a stack, refine the stack. See Stacks.

Best time to refine is before /pr, on the single branch. One pass, no stack to rebase. Refining an open stack works, but costs a rebase and a force push.

## Stacks

Stacks need the GitHub CLI, logged in, and git 2.38 or later for `--update-refs`. Check with `gh auth status` and `git --version`. If one is missing, give the fix: `brew install gh`, `gh auth login` in the user's own terminal, or `brew install git`. Offer to run the install after a yes, then check again. If the user declines, refine only the current branch.

Detect the stack the same way the judge skill does. First run `gh api "repos/<owner>/<repo>/stacks?pull_request=<n>"`. A non-empty result lists the stack bottom to top. An empty result means the PRs are not linked, so follow each PR's base branch down to the default branch and find PRs based on each head going up.

- Refine each PR against its own base (`gh pr diff <n>`), so each removal lands on the PR that added the line.
- Show one plan for the whole stack. Use the same sections, with one line per PR under the top section:

```
REMOVE ~780 LINES ACROSS 4 PRS
- #101: ~120 comments
- #102: ~300 comments, 4 tautological tests
- #103: ~310 comments, ~50 debug logs
- #104: nothing to remove
```

- After the OK, commit each PR's removals on its own branch, bottom up. After each commit, carry it up: check out the top branch and run `git rebase --update-refs <branch>`.
- Run checks on every changed branch.
- Push every changed branch with `--force-with-lease`.
- If any PR has approvals, warn before pushing: a force push may dismiss them, depending on repo settings.
- Update the size table in each PR body, following the pr skill's format.

## What to remove

**Comments**

Remove:

- Comments that restate the code: `// set loading to true` above `setLoading(true)`.
- Comments that narrate the change: "added this", "new helper", "updated to use X", "fix for the bug".
- Section banners and dividers that add nothing: `// ===== Handlers =====` in a short file.
- Commented-out code.
- JSDoc that only repeats the parameter names and types TypeScript already shows.

Keep:

- Comments that explain why: a non-obvious reason, a workaround, a browser quirk, a link to an issue.
- Warnings: "Do not reorder, X depends on this."
- Doc comments on exported APIs, if the repo writes them elsewhere.
- Lint and type directives: `eslint-disable`, `@ts-expect-error`, `oxlint-ignore`.
- License headers.

**Tests**

Remove tests that cannot fail or prove nothing:

- Tautological tests: the expected value is computed the same way the code computes it, so the test passes by construction. Real expected values come from somewhere else: a literal, a worked example, the spec.
- Tests that assert a mock returns what the test told it to return.
- Tests that restate a constant or a default value.
- Render tests that assert nothing about the output.
- Exact duplicates of another test with a different name.

Flag, but do not remove, implementation-coupled tests: tests that mock the repo's own modules, assert call counts, or check internals instead of behavior. Fixing them means rewriting, which is not refine's job. List them in the report so the user can decide.

Keep every test that checks real behavior, even if it is verbose. When unsure, keep it.

**Stories**

Remove stories that duplicate another story with no visible difference. Keep every story that shows a distinct state.

**Leftovers**

Remove:

- Debug logging: `console.log`, `print`, `debugger`.
- Unused imports, variables, and functions the change added.
- TODOs the change added with no issue link. Ask the user whether to delete each one or link an issue.

## Steps

1. Read the full diff and each changed file.
2. Build the list of removals. Group them by file.
3. Show the plan and wait for the user's OK. Never remove anything before the OK.

4. After the OK, make the removals. If the user excludes items, skip them.
5. Run the repo's format, lint, type check, and the tests for the changed files. Everything must pass. If a removal breaks something, put it back.
6. Commit with `chore: remove redundant comments and tests`, following the /commit message rules. Keep it in its own commit, apart from feature work.

## Plan format

The user should be able to approve or reject the plan in 10 seconds. Use these sections, in this order, with one blank line between them. Bullets start directly under each title. Skip any section that is empty.

```
REMOVE ~780 LINES
- ~620 comments in 34 files
- ~110 lines in 9 tests that cannot fail
- ~50 lines of unused imports and debug logs

EXAMPLES
- files-panel.tsx:42 "// set the active filter" above setActiveFilter()
- use-pins.test.ts:18 asserts the mock returns the mocked value

FLAGGED, NOT REMOVED
- use-pins.test.ts:40 mocks the repo's own pins store

ASK
- chat-store.ts:88 TODO with no issue: delete or link?
```

- One idea per bullet, 15 words at most.
- EXAMPLES: two or three at most, the ones that best show each category.
- FLAGGED, NOT REMOVED: implementation-coupled tests and anything else worth a look that refine will not touch.
- ASK: only questions that need an answer before removing, like TODOs.
- No paragraphs, no bold, no markdown headings. Nothing after the last section.

## Report format

After the removals and checks pass, report in the same style:

```
REMOVED ~760 LINES
- ~610 comments, ~100 test lines, ~50 imports and logs
- Kept 2 removals that broke checks

COMMITTED
- chore: remove redundant comments and tests
```

## Rules

- When in doubt, keep it. A missed comment costs a reviewer five seconds. A deleted warning can cost a bug.
- Never rewrite code to make it shorter. That is a refactor, not a refine.
- Never rename, reorder, or reformat beyond what the repo's formatter does.
