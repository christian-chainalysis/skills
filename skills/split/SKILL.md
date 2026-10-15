---
name: split
description: Check whether a big PR is really several PRs bundled into one, and say plainly when it is not. When a split is worth it, shows each piece with code and test line counts, a tree of PRs off main or stacked, and a copy and paste prompt for the author's agent. Use when the user types /split, or asks whether a PR is too big, should be broken up or stacked, or wants to push back on a PR's size.
---

# Split

A big PR is sometimes several PRs bundled into one: the change in the title, plus features and fixes the author's agent picked up along the way. This skill finds out whether that is true. When it is, it shows the pieces so a human gets it from a screenshot, and gives the author's agent exact steps to split them.

KEEP AS IS is a full, valid answer, and often the right one. Size alone is never a reason to split. One feature that hangs together is fine at any size. A split is a request for the author's time, so every split must earn it. A report that splits only when splitting is truly worth it is a report people trust.

The report goes to the author, so it states facts about the code, never about the person.

## Resolve the target

- Run `gh auth status` before the first `gh` call. If `gh` is missing, give `brew install gh`. If logged out, ask the user to run `gh auth login` in their own terminal.
- A PR URL: pass `-R <owner>/<repo>` from the URL to every `gh` call, because the current folder may be another repo.
- A PR number or URL: check that PR.
- Several PRs from one stack: check each on its own, bottom to top.
- One PR from a stack: check only that PR.
- A merged or closed PR: say so in one line, and give the human part only. No prompt.
- No argument: the current branch's PR, or `git diff origin/<default>...HEAD` when there is none.
- Never check out, commit, push, or comment. This skill only reads. To compare with main, run `git fetch` and read `git show origin/<default>:<path>`.

## Steps

1. Read the PR title, description, linked issue, and review comments, human and bot. Note any open finding and which change it lands on.
2. Count. Run `gh pr diff <n> | python3 <skill-dir>/scripts/count.py`. It prints every hunk with its added lines and kind (code, tests, docs, other), then totals. Its numbers are the source of truth. If it exits with an error, fix the `gh` call before going on.
3. Find the minimum core: the fewest hunks that deliver the title. Every other change is a candidate. Done means every hunk is core or in a named candidate.
4. Write a decision record before any verdict. One row per candidate: name, code lines, and pass or fail on each bar test, with the fact that decided it. Every fail cites a fact from the diff or main, never a feeling.
5. Check main. Run `git log --oneline <merge-base>..origin/<default> -- <changed files>`. If main already holds a candidate, mark it `On main via #N` and drop it.
6. The verdict follows the record. No candidate passed: KEEP AS IS. Otherwise SPLIT, then find dependencies.

## Pieces

- CORE: the smallest change that delivers the title, and everything it needs to work. Always piece 1. It keeps the original PR, so its review history stays.
- FEATURE: new behavior the core works without.
- FIX: a bug fix for behavior on main. These are often "found while testing".
- REFACTOR: a restructure with no behavior change that the core does not need.

The removal test decides what is core: if this change were removed, would the PR still deliver its title? If yes, the change is a candidate. Use the title and the problem it solves, never the description's list of changes. The author's agent writes that list, and it lists everything the branch holds. Being listed proves nothing.

These are core even when they could be removed:

- Ways to reach the core's behavior that users need, such as keyboard or touch input for a drag feature.
- A different layer of the same feature, such as the backend endpoint the new UI calls.

A second surface is another screen or entry point that gets the same change, such as a schedule dialog beside a run page. Decide it from main, not the description:

- For a fix: if the second surface shows the bug the title names on main, the fewest lines that fix it there are core. Otherwise its changes are a candidate.
- For a feature: the same feature on a second surface is core, unless the title names only one surface.
- Anything beyond the fewest lines, such as a rewrite or new behavior, is a candidate.
- Lines the core needs only to compile after the PR deletes something, such as a renamed call site, are core.

The core never loses what main shows. A candidate whose removal would drop something main's page has today fails the clean test.

## The bar

A candidate earns its own PR only when it passes all three tests. When a test is a coin flip, it fails. Apply each test on its facts, and never lean on this rule to skip checking.

1. Separate. Both checks hold. The core's own tests would pass without the candidate. The candidate has a PR title of its own that does not restate the core's title.
2. Clean. Moving it means moving lines, not rewriting logic. Splitting a hunk by lines is fine. Fixing a merge conflict, or giving its tests a new file with a copied helper, is fine. Needing new logic to make either branch work is not. If the core's code would need a new place, order, or wrapper once the candidate leaves, that is new logic. Every branch would pass checks alone.
3. Worth it. Splitting saves the reviewer real effort, or keeps a real risk apart. Count it as worth it when the piece has at least about 30 lines of code, or carries a risk on its own: an unresolved review finding, a migration, a security or data change, or a change to a shared contract. A small unrelated FIX also counts when it applies cleanly to main, because a revert should take only the fix. Applies cleanly means every line the fix changes is identical on main, so the agent can apply it line for line.

A resolved or outdated review finding is not a risk. A "fix" that changes nothing on main is not a FIX. Check main's code before calling it one.

Pieces that fail the bar stay in the core.

## Dependencies

For each piece that passed, list the symbols, types, props, and files it uses that another piece adds or changes. Grep the diff to confirm each one.

- No dependency: the piece goes off main.
- Uses another piece: it stacks on that piece.
- Shares a test harness or fixture that another piece adds: count that as a dependency, unless the prompt tells the agent to make a new file.
- The core needs something from a piece: that piece fails the clean test and stays in the core.

## Numbers

- Counts are lines added. Comment lines are inside the code count, not on top of it.
- If the script puts a file in the wrong kind, such as a test helper counted as code, move it silently.
- A piece made of whole hunks uses the exact script count.
- A piece made from part of a hunk is an estimate. Round it to the nearest 5.
- The core takes the remainder, so the pieces add up to the totals.
- Write 1,000 and up with a comma. Never write `~`.
- Add `comments N` to a piece's counts only when its comments pass 5% of its code and number 5 or more.
- Show only kinds a piece has. Never show `other`. It still counts toward the totals.

## Report

Two parts. The top part is for the human and must make sense in a screenshot. The bottom part is for the author's agent and must work with no other context. KEEP AS IS has only the top part.

Formatting, because the user pastes into Slack and screenshots it:

- Plain text. No bold, markdown headings, or tables.
- Put the human part in one plain triple-backtick block so it screenshots as one image.
- Put the prompt in its own plain triple-backtick block. Never nest backticks inside it. Write code names bare.
- Between the two blocks, put the divider shown under Agent prompt, so the user knows where to start copying.
- Every line must be actionable. No summary of the change. One idea per bullet, 12 words at most.
- Nothing after the last block.
- Shorten the title: drop the conventional commit prefix and any stack marker like (1/6).
- One blank line after the title. No blank line between the verdict and piece 1.

### KEEP AS IS

```
#4120 export reports as CSV

KEEP AS IS
- Column picker: not separate. Export tests need it.
```

- No summary of the change.
- One `Turned down` bullet per candidate with 30 or more code lines, three at most: `- <candidate>: not <test>. <deciding fact>.` These let the reader check the call.
- Add a bullet for anything the author must act on, such as `- <change> is on main via #N. Rebase first.` Act-on bullets come first.
- A migration number or file that collides with main is an act-on bullet. Check `git ls-tree origin/<default>` for the migration folder.
- Five bullets at most in all.
- No candidates of that size and nothing to act on: the verdict line alone.
- No prompt.

### SPLIT INTO N PRS

```
#4188 add saved filters to the alerts table

SPLIT INTO 3 PRS
1. CORE
Saved filters on the alerts table  |  code 390  |  tests 560  |  docs 30

2. FEATURE
Share a saved filter by link  |  code 170  |  tests 220
- New public route. Needs its own security review.

3. FIX
Date picker drops the time zone  |  code 50  |  tests 60

SPLIT
main
├── 1 Core (this PR)
│   └── 2 Share by link
└── 3 Date picker fix
```

- N counts the core. Only pieces that passed the bar appear.
- The title and counts carry each piece. Add one bullet only when the reason it passed is not obvious, such as a security risk or a review finding.
- Candidates with 30 or more code lines that failed the bar get a `Turned down` bullet under the core, as in KEEP AS IS.
- The tree shows every piece. Children stack on their parent. Children of `main` go off main.
- Never recommend cutting a feature. That is the author's call.

Agent prompt: write it for an agent that has never seen this PR. Name exact files, symbols, hunks, and test names, because a vague prompt gets a vague split.

Put this divider as plain text between the two blocks, exactly:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AGENT PROMPT
Copy the whole block below into the author's agent.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Then the prompt block, in this shape:

```
Split PR #<n> (<head branch>) into <N> PRs. Move code only. Change no behavior.

Keep PR #<n> as piece 1 so its review history stays. Remove pieces 2 to <N> from its branch.

Piece 1, <title>. Stays on <head branch>, base main.
- Keep: <files and symbols, one per line>
- Also keep: <lines the core needs from other pieces, or main code the PR deleted that the core still uses, and why>
- Remove: <what moves out, by file and symbol>

Piece 2, <title>. New branch off <main or piece's branch>.
- Contains: <files, symbols, hunks>
- Tests: <test files or test names that move with it>
- Depends on: <symbols from another piece, or "nothing">

<one block per piece>

For every branch:
- Run the repo's checks and tests. Each branch must pass alone, not only at the top of the stack.
- If a piece cannot move without rewriting code, stop and put it back in piece 1. Report which one.
- Follow the repo's PR rules in AGENTS.md, such as one changeset per PR. Piece 1 keeps the existing changeset, reworded to cover only piece 1. Other pieces get new ones.
- Write a PR description for that piece alone.
- For stacked pieces, use gh stack if available. Otherwise set each PR's base to the branch below it.

Then update PR #<n>'s description to list the new PRs, and report each PR URL with its added line count.
```

## Rules

- Every number traces to the script output or a hand split of one named hunk.
- Every dependency traces to a symbol you found in the diff. Mark anything you could not confirm `(unverified)`.
- The same PR must get the same verdict on every run. If a call depends on wording or mood rather than a fact, find the fact.
