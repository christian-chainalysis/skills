---
name: commit
description: Split git changes into logical, well-formatted conventional commits. Runs the repo's format and lint fixers first, then groups changes by type. Use when the user types /commit or asks to commit or split changes into commits.
---

# Git Commit Workflow

Split the current changes into logical, well-formatted commits.

## Workflow

1. Run `git status` and `git diff` to understand all changes
2. **Run the repo's format and lint fixers** before staging anything. Always, no exceptions. Find them in the repo's `AGENTS.md` or `README.md`, then the scripts in `package.json`, `pyproject.toml`, or `Makefile`, for example `pnpm format:fix && pnpm lint`. Run only scripts that exist. A pre-commit hook does not count, because it only sees staged files
3. Analyze and group changes by type (see grouping rules below)
4. For each logical group:
   - Stage only the relevant files
   - Create a commit with a properly formatted message
5. After all commits, show a summary of what was created

## Commit Message Style

- Use conventional commit prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `perf:`, `test:`, `style:`, `revert:`
- Scoped prefixes allowed: `feat(auth):`, `fix(nav):`
- First character after `prefix: ` MUST be lowercase, even for proper nouns (e.g., `feat: add React support` not `feat: Add React support`)
- Concise, not overly verbose
- Focus on what changed, not why (unless non-obvious)

### Good Examples

- `feat: update nav icons to match design system`
- `feat(sidebar): redesign layout and spacing`
- `fix: correct mobile nav drawer z-index`
- `chore: remove unused imports`

### Bad Examples

- `fix: Update navigation icons` (capital after prefix)
- `updated the nav icons` (missing prefix)
- `feat: update navigation icons to match the new design system specifications` (too verbose)

## Commit Grouping

When multiple changes exist, batch by type in this order:

1. **Backend changes** - always separate from frontend, own commit(s)
2. **Icon/asset changes** - group icon swaps, image updates
3. **Styling/layout changes** - group related visual updates
4. **Functionality changes** - group behavioral changes
5. **Refactors** - group code cleanup that doesn't change behavior

## Exclusions

Do NOT include in commit messages:

- Any agent or tool attribution footer
- Co-authored-by lines
