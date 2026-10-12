---
name: pr
description: All-in-one "ship this branch". Branches off main if you're working directly on it (keeping the PR scoped), commits, rebases, refreshes deps, runs CI-equivalent checks, handles changesets, pushes, and opens the PR. Splits large changes into a stack of small, logical PRs that are reviewed and merged together, so no one ships a mega-PR. Safe for designers and non-engineers to use.
---

# PR Creation Workflow

Commit, rebase, validate, handle changeset, push, and create a pull request.

**Note on the default branch:** examples below say `main`. If the repo's default branch differs, compute it once with `DEFAULT=$(git remote show origin | sed -n 's/.*HEAD branch: //p')` and use it everywhere `main` appears.

## Tools

The user may be a teammate who installed this skill without its tools. Check each tool the first time a step needs it. When one is missing or too old, stop and help the user fix it:

1. Say in one line what the tool does for them.
2. Give the exact install or fix command from the table.
3. Ask whether to run it. Run it only after a yes. Commands that open a browser, like `gh auth login`, must run in the user's own terminal, so give the command and wait.
4. Run the check again to confirm.
5. If the user declines, use the fallback. If there is none, stop and say what is blocked.

| Tool | Check | Install or fix | Fallback |
|---|---|---|---|
| GitHub CLI | `gh --version` | `brew install gh` on macOS. Other systems: https://cli.github.com | None. This skill cannot push PRs without it. |
| gh login | `gh auth status` | `gh auth login` in the user's terminal | None. |
| git 2.38+ | `git --version` | `brew install git` on macOS | Single PRs work. Stacks need it. |
| gh stack | `gh stack --help` | `gh extension install github/gh-stack` | Build the stack without it. See Stacked PRs. |
| Package manager | Matches the lockfile, for example `pnpm --version` | `corepack enable`, or the repo's README | None for checks. Do not push code that was not checked. |

## Workflow

### 0. Ensure you're on a feature branch (not main)

Agent sessions often make changes directly on the default branch without branching first. Before anything else, check and correct this:

- Get the default branch: `DEFAULT=$(git remote show origin | sed -n 's/.*HEAD branch: //p')` (usually `main`)
- Get the current branch: `git branch --show-current`
- **If you are already on a feature branch, skip to Step 1.**
- **If you are on the default branch**, you need to move the work onto a new branch and leave the default branch pristine. First, `git fetch origin`, then distinguish two kinds of work. They are NOT treated the same, because the PR must stay scoped to the current task:
  - **Uncommitted working changes** (`git status --porcelain`): this is the current task. It rides onto the new branch. Good.
  - **Local commits already on the default branch ahead of the remote** (`git log origin/$DEFAULT..HEAD --oneline`): this is a SCOPE RISK. These may be unrelated leftovers from a previous session. **Do not silently bundle them into the PR.** Show them to the user and ask which (if any) belong to this PR before continuing. If they don't belong, the user should move or drop them first. Only proceed once scope is clear.
  - If there's neither uncommitted work nor relevant commits, stop. There is nothing to PR.

  Once scope is clear, in this order (safer than checking out main and pulling):
  1. `git checkout -b <branch-name>` carries the working changes (and any commits the user confirmed belong here). Derive the name from the work itself (the diff / commit messages), using `feat/`, `fix/`, or `chore/` (kebab-case, concise). Show the proposed name and proceed unless the user objects.
  2. `git branch -f $DEFAULT origin/$DEFAULT` repoints the local default branch back to the remote so it stays clean. Safe because you're no longer on it. (Skip if local default had no extra commits.)
  3. Continue to Step 1. The rebase in Step 3 replays your work onto the latest default branch. It is a no-op if nothing new landed.

**Why this order** (vs. "branch → checkout main → pull"): you never check out the default branch while your working tree is dirty (which risks conflicts), and you never have to stash. The new branch takes the changes with it, `git branch -f` updates the default ref without a checkout, and `fetch` + the Step 3 rebase handle "did anything land upstream" cleanly.

**Scope is the goal.** In the normal flow, where you start tasks from a clean, up-to-date main, local `main` has no ahead-commits, so only your current uncommitted work moves to the branch and the PR stays tightly scoped. The ahead-commit check above is the safety net for when that wasn't the case.

### 1. Commit local changes

- Run `git status` to check for uncommitted changes
- If dirty, run `/commit` to stage and commit all changes first
- If clean, still run format/lint checks and commit any resulting changes

### 1b. Decide: one PR or a stack

A stack is one unit of work, split only so humans and agents can review it in readable pieces. The team reviews and approves every PR in the stack, then merges the whole stack in one sitting. Nobody merges part of a stack. Think of PRs in a stack like logical commits: each has one purpose, and together they tell the story of the change.

Measure the diff with `git diff origin/$DEFAULT...HEAD --numstat`. Sort lines into three counts:

- **Code:** everything that ships: UI, styles, endpoints, logic, and config, minus comment lines.
- **Comments:** added comment lines in production files. Count them with `git diff -U0 origin/$DEFAULT...HEAD -- <production files> | grep -E '^\+\s*(//|/\*|\*|#|\{/\*|<!--)'`. This is an estimate. Say "~".
- **Tests and stories:** tests, stories, fixtures, mocks, and snapshots.

Ignore lockfiles, generated files, and changesets entirely. Size rules use the code count only. Comments, tests, and stories stay in the PR with the code they belong to and never count toward its size.

This skill measures. It never edits code to shrink a count. Cleanup is the refine skill's job.

Split along seams, not line counts. A stack makes sense when the diff has two or more parts that each:

- Have one purpose that fits in a PR title.
- Build and pass checks alone, so the default branch never breaks as the stack merges bottom up.
- Are easier to review apart than together.

Good seams, in the order they usually stack:

1. Pure refactors, moves, and renames with no behavior change. Split these out even in small changes. Mixed with behavior changes, they hide the real diff.
2. Mechanical changes: codemods, dependency bumps, generated code.
3. Foundations: types, schemas, migrations, helpers, constants.
4. Core logic, with its tests.
5. UI and wiring that exposes it to users.
6. Cleanup: removing old code paths.

Do not split when:

- A reviewer could not judge a part without reading the next PR.
- The split would separate code from its tests or stories. Never make a PR of only tests or only stories for code in another PR.
- The change is one cohesive unit, like one new component with its tests, even if it is large.
- The parts would each be tiny (under about 50 lines) and share one purpose.

Size guide, in code lines:

- Under about 400 code lines total: one PR, unless a refactor is mixed with a behavior change.
- Aim for 200 to 500 code lines per PR.
- A PR over about 800 code lines needs another look for seams. If it is one cohesive unit with no clean seam, keep it whole and say why in the PR body. A bad split is worse than a big PR.
- Check every PR, not just the total. Ten PRs where one still holds 4,000 code lines does not help.

### New UI (additive work)

Most new UI only adds code. That splits well, because new code can land before anything uses it:

1. Foundations: tokens, types, helpers, icons the new UI needs.
2. Each new component on its own, with its stories and tests. No page renders it yet, so it changes nothing users see.
3. Wiring: render the new components in the page. If the feature is not ready for users, put it behind the repo's feature flag.

### One feature, one stack

Every PR for one feature goes in one stack, even parts that do not depend on each other, like two separate components. A separate PR off the default branch loses its link to the feature, and someone may merge it alone. Order independent parts in whatever sequence reads best, usually smallest or most basic first.

Work that is truly unrelated to the feature does not belong in the stack. Leave it out and tell the user it needs its own PR.

### Stack length

There is no hard cap. Every PR must earn its place under the seam rules above. Ten PRs is fine for a large refactor if each one is a real seam.

Past about 8 PRs, add one line to the plan saying why the stack needs that many. Also check whether the work splits into phases that are each useful to users on their own. If so, suggest shipping phase one as its own stack first. Long stacks cost reviewers context and cost the author a rebase of every branch above any change.

### Show the plan

If a split makes sense, show the plan in plain words and wait for the user's OK. The user may not be an engineer, so say what each PR does, not how:

```
This is about 4,600 lines: ~2,000 code, ~300 comments, ~2,300 tests and stories.
I'd split it into 5 PRs, reviewed and merged together, bottom up.

1. feat(files): add sort menu (~250 code)
2. feat(files): add category chips (~400 code)
3. feat(files): store file pins per user (~300 code)
4. feat(files): rebuild file rows and tree (~550 code)
5. feat(files): show the new panel in chat (~250 code)
```

After the OK, follow Stacked PRs below instead of steps 2 through 7. Otherwise continue with step 2.

### 2. Sync with remote

- Record the current tip first so later steps can tell what the sync/rebase pulled in: `BEFORE=$(git rev-parse HEAD)`
- Run `git fetch origin`
- **Only if this branch already exists on the remote** (`git rev-parse --verify --quiet origin/$(git branch --show-current)`): check whether it has new commits with `git log HEAD..origin/$(git branch --show-current) --oneline`, and if so run `git pull --rebase`. Skip this entirely for a brand-new branch that was just created in Step 0 (it has no upstream yet).
- If conflicts occur, resolve them (see conflict handling below), then continue

### 3. Rebase against the default branch

- Run `git rebase origin/main`
- If conflicts occur, resolve them (see conflict handling below), then continue
- If this branch is part of an existing stack (its PR's base is another feature branch), follow Update a stack below instead.

### 4. Pre-push validation

**First, refresh dependencies if the sync/rebase changed them.** If anything pulled in since `$BEFORE` (recorded in Step 2) touched the lockfile (`git diff $BEFORE..HEAD --name-only | grep -E 'pnpm-lock.yaml|package-lock.json|yarn.lock|bun.lockb'`), run the matching install (`pnpm i` / `npm i` / `yarn` / `bun i`) before validating. Otherwise typecheck/lint can fail or pass misleadingly against stale `node_modules`. If the lockfile didn't change, skip it.

Then run the same checks CI runs, so nothing reaches the PR that CI would reject. The repo is the source of truth for which commands those are. Never assume a command exists, such as `pnpm lint` or `tsc`. Repos differ: one uses pnpm, the next npm, another Python.

Find the checks in this order, and stop once you know them:

1. The repo's `AGENTS.md` or `CLAUDE.md`, then `README.md` and `CONTRIBUTING.md`. Look for a section on checks, linting, or "before you push".
2. The CI workflow under `.github/workflows/` that runs on pull requests. The commands in its steps are what CI actually runs.
3. The package manager from the lockfile (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb`, `uv.lock`), and the scripts in `package.json` or `pyproject.toml`. Run only scripts that exist.
4. Pre-commit hooks: `.husky/`, `.pre-commit-config.yaml`, or a `lint-staged` config.

Run the checks in parallel where possible. Tell the user in one line which checks you ran and where you found them.

If any check fails, fix the issue, commit the fix, and re-run.

### 5. Handle changeset BEFORE pushing

- Run `git diff main --name-only` to see what changed
- If the repo has no `.changeset/` directory, it does not use changesets. Skip this step.
- Otherwise, learn the repo's rules before you write one. Read, in order:
  1. The repo's `AGENTS.md`, `CONTRIBUTING.md`, and any release doc such as `docs/RELEASING.md`. These often set the bump for each kind of change, and they override the defaults below.
  2. The changeset check under `.github/workflows/` (often `changeset-check.yaml`). It shows which paths need a changeset, such as `apps/` and `packages/`, and the escape hatch, such as a `skip-changeset` label.
  3. Existing changesets in `git log` for the format, including whether the repo wants an empty changeset (`---` then `---` with a summary) for docs, CI, or test-only changes.
- Defaults when the repo is silent: add a changeset when the change touches a publishable package. Use `patch` for fixes, `minor` for backward-compatible features, and `major` only for breaking changes. If a workflow enforces changesets, treat one as required whenever code (not just docs or config) changed.
- Check if a changeset already exists: look for new `.changeset/*.md` files (excluding README.md) in `git diff main --name-only`
- If no changeset exists and one is needed, create one:
  - Write `.changeset/<branch-name>.md` with appropriate package bumps and summary
  - Commit it: `git add .changeset/ && git commit -m "chore: add changeset"`

### 6. Push the branch

- Run `git push --force-with-lease -u origin HEAD`
- Use `--force-with-lease` since we rebased (safe force push)

### 7. Create the PR

- Analyze commits on this branch vs main: `git log main..HEAD --oneline`
- Run `gh pr create` with title and body

## Stacked PRs

Needs git 2.38 or later and the `gh stack` extension. Check both first, as in Tools.

`gh stack` registers the PRs as a stack on GitHub. That turns on the stack panel and the "Enqueue stack" button, and it makes merging and rebasing one command. Tell the user this when you offer to install it.

If the user declines `gh stack`, build the stack anyway. Skip the `gh stack` steps below and use the steps marked "Without gh stack". Tell the user that GitHub will not show the stack panel and that they will merge the PRs one at a time.

The steps below assume the repo squash-merges and deletes branches after merge, which is common. They also work with merge commits.

### Build the stack

Name branches `<topic>/<n>-<slug>`, for example `billing-export/1-schema`.

1. Save the current tip: `ORIG=$(git rev-parse HEAD)`. The original branch stays untouched and holds the full work as a backup.
2. `git fetch origin`, then `git checkout -b <topic>/1-<slug>` and `git reset origin/$DEFAULT`. The branch now sits on the default branch, with all changes uncommitted in the working tree.
3. For each PR, bottom up:
   - Stage only that PR's files and commit them, following the /commit message rules.
   - Then `git checkout -b <topic>/<n+1>-<slug>` for the next PR. The remaining changes carry over.
   - If one file has changes for two PRs, write the earlier PR's version by hand and commit it. The later PR gets the final version with `git checkout $ORIG -- <file>`. Prefer file-level seams so this is rare.
4. On the top branch, `git diff $ORIG` must be empty. If it is not, stop and fix it. Nothing may be lost or added.
5. Check out each branch and run step 4 (checks) and step 5 (changeset) for it. Never skip this. Many repos run their main CI workflow only on PRs that target the default branch (`pull_request: branches: [main]`), so upper PRs get no build, lint, or test checks until the PR below merges. These local checks are the only checks those PRs get before review. Each PR must pass alone and needs its own changeset if it touches publishable packages. If you fix a lower branch, commit the fix there, then check out the top branch and run `git rebase --update-refs <fixed-branch>` to carry it up.
6. Track the stack locally: `gh stack init <branch-1> <branch-2> ... <branch-n>`, bottom up. This adopts the existing branches. Later `gh stack sync` and `gh stack rebase` calls depend on it. Without gh stack, skip this step.
7. Push every branch: `git push --force-with-lease -u origin <branch>`.
8. Create PRs bottom up with `gh pr create`. The first uses `--base $DEFAULT`. Each later PR uses the branch below it as `--base`. Title and body follow the formats below. Use `gh pr create`, not `gh stack submit`, so the titles and bodies follow this skill's formats.
9. Link the PRs into a stack on GitHub: `gh stack link <pr-1> <pr-2> ... <pr-n>`, bottom up. Without gh stack, skip this step.
10. Add the stack header to the top of every PR body with `gh pr edit <n> --body-file <file>`. See PR Body Format.

Tell the user the original branch still holds the full work and can be deleted once the stack merges.

### Merge a stack

Merge only after every PR in the stack is approved. Then merge the whole stack in one sitting.

If the user asks /pr to merge the stack:

1. Confirm every PR is approved with `gh pr view <n> --json reviewDecision`. Stop and list any PR that is not approved.
2. Run `gh stack merge <top-pr> --yes`. If the default branch has a merge queue, this adds the whole stack to the queue. The user can also click "Enqueue stack" on the top PR, which does the same thing.
3. Watch the stack with `gh pr view <n> --json state` on each PR until all are merged.

Merge queues that merge one PR at a time with squash can stall partway through a stack. If a PR stays open after the PR below it merged, merge the rest bottom up:

1. Run `gh stack sync` on the stack. It rebases the open PRs onto the new default branch and pushes them.
2. Let CI pass on the bottom open PR, then run `gh pr merge <n> --auto` to put it in the queue.
3. Repeat until the stack is merged.

If the repo has no merge queue and the stack merge fails, use the same bottom-up loop.

**Without gh stack:** merge the bottom PR with `gh pr merge <n> --auto`. After it merges, update the stack as below, let CI pass on the next PR, and merge it. Repeat up the stack.

### Update a stack

- **A lower PR changed:** commit on its branch. Then run `gh stack rebase --upstack` to carry the change up, and `gh stack push` to push every branch.
- **A lower PR merged:** run `gh stack sync`. It fetches, rebases the remaining branches onto the default branch with `--onto` for the squash merge, pushes them, and updates the stack on GitHub. If GitHub did not retarget the next PR, run `gh pr edit <n> --base $DEFAULT`. Run `gh stack sync --prune` to delete merged local branches.
- If a rebase hits a conflict, follow Conflict Handling below, then run `gh stack rebase --continue`.
- Update the stack table in each remaining PR body.

**Without gh stack:**

- **A lower PR changed:** commit on its branch. Check out the top branch and run `git rebase --update-refs <changed-branch>`. Push every branch with `--force-with-lease`.
- **A lower PR merged:** the squash merge gives the default branch one new commit, but the next branch still holds the old commits. From the top branch, run `git fetch origin` and `git rebase --update-refs --onto origin/$DEFAULT <merged-branch>`, using the local copy of the merged branch. Push every branch. If GitHub did not retarget the next PR, run `gh pr edit <n> --base $DEFAULT`. Delete the merged local branch.

## Conflict Handling

If conflicts occur during rebase:

1. Run `git status` to list conflicted files
2. Show the conflict markers in each file
3. Ask the user how to resolve each conflict. Do NOT auto-resolve
4. After resolution: `git add <resolved-file>` then `git rebase --continue`
5. If user wants to abort: `git rebase --abort`

## PR Title Format

- Use conventional commit prefix: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `perf:`, `test:`, `style:`, `revert:`
- If the repo lints PR titles (a workflow such as `pr-title.yaml`, or DangerJS), its allowed prefixes win. Some reject `ci:` or `build:`, so use `chore(ci):` there.
- Scoped prefixes allowed: `feat(auth):`, `fix(nav):`
- Lowercase first letter after prefix, even for proper nouns. Title linters often enforce this.
- Concise and descriptive
- Examples:
  - `feat: add a share dialog for reports`
  - `fix(sidebar): correct drawer z-index on mobile`
  - `chore: update dev dependencies`
- In a stack, end the title with its position: `feat(billing): export invoices as CSV (2/3)`. This makes a stack easy to spot in a PR list. Squash merge uses the title as the commit message, so the position also lands in main's history. That is fine: it shows the commit was part of a stack.

## PR Body Format

### Size breakdown

Every PR body starts with a size line, so reviewers know how much is shipping code before they open the diff. Use the counts from step 1b:

```
Size: ~250 code, ~40 comments, ~650 tests and stories
```

In a stack, the header replaces the size line and shows every PR:

```
Stack 2 of 3. Review all, then merge together bottom up.

| # | PR | Code | Comments | Tests and stories |
|---|---|---|---|---|
| 1 | #101 refactor(billing): extract invoice helpers | ~180 | ~20 | ~90 |
| 2 | #102 feat(billing): export invoices as CSV (this PR) | ~250 | ~40 | ~650 |
| 3 | #103 feat(billing): add export button | ~400 | ~60 | ~500 |

CI runs on each PR once the PR below it merges. Checks passed locally on every branch.
```

Mark the current PR with `(this PR)`. Update the table in every PR body when the stack changes.

Tell the user in the terminal, not in the PR body, when a PR has:

- More than about 3 times as many test and story lines as code lines. Often fine, since stories are verbose. It can also mean duplicated fixtures or snapshot tests. Suggest running the refine skill.
- More than about 1 comment line for every 5 code lines. That usually means comments restate the code. Suggest running the refine skill.

### Description

After the size line or stack header, write the shortest description that lets a reviewer judge the PR. Describe the code as it is now. Leave out how you got there: abandoned approaches, review rounds, and what an earlier commit did.

Default shape, plain prose or a few bullets:

- **Problem:** what was broken or missing, in one or two sentences. For a fix, include the root cause when it is not obvious.
- **Change:** what this PR does about it, and any new dependency or pattern.

Add these only when they apply: trade-offs a reviewer would question, migration steps, follow-up work, and screenshots for UI changes. Leave out testing tables unless the user asks for them.

## Exclusions

Do NOT include:

- Coworkers' names. Describe the change, not who asked for it or who reviewed it.
- Any agent or tool attribution footer, like "Generated with Claude Code"
- Co-authored-by lines
- Excessive markdown formatting
