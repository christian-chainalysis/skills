---
name: explain
description: Teach a concept, PR, stack of PRs, diff, thread, or error to someone who is lost but not slow. Gives the core idea, a worked example from the user's own code, and why it matters, in short plain lines with the real technical terms. A personal understanding loop, not a critique. Use when the user types /explain, says they are lost, confused, or do not get something, or asks what something is or how it works.
---

# Explain

The user is lost, not slow. They are an experienced engineer who is new to this specific thing. Teach them the mental model, not a list of facts. Success means they could apply the idea to the next case on their own.

Do not critique, recommend, or flag issues. Finding problems is the approach and judge skills' job.

## Get the latest code

Before reading anything, if the current branch is the default branch and `git status --porcelain` is empty, run `git pull --ff-only`. If the pull fails, read `origin/<default>` instead. Do not mention any of this in the answer.

On any other branch, with uncommitted work, or when explaining a specific PR, leave the checkout alone and read the code as it is.

## Format

Three sections, in this order, with one blank line between them. Bullets start directly under each title.

```
THE IDEA
- The one rule or model that makes everything else make sense.

EXAMPLE
- The idea in action, using real names from the user's code.

WHY IT MATTERS
- What breaks or gets harder without the idea.
```

In WHY IT MATTERS, the first bullet is the main reason the design was chosen. Side effects and consequences come after it, if at all.

- About 8 bullets total. The user will ask for more depth if they want it.
- Section titles are plain uppercase text. No bold, markdown headings, or tables, because the user pastes this into Slack. Code goes in plain triple-backtick blocks.
- Nothing after the last section. No summary, no warnings, no "does that make sense?", no offers.

## Short lines

- One idea per bullet.
- 15 words per bullet at most. If a bullet runs longer, split it or cut it.
- If a bullet repeats another, cut it.

## Find the idea first

Before writing, find the single idea everything else follows from. Usually it is a rule, a constraint, or a model. Put it first. History, file paths, and implementation details appear only if the example needs them.

Test: if the user remembered only THE IDEA, could they predict the right answer for a new case? If not, you wrote a fact, not the idea.

## Example

- Use the user's real code, packages, or PR, not `foo` and `bar`.
- Show the idea deciding something: a problem it caused, or a choice it forced.
- Two or three bullets. It makes the idea concrete. It is not a walkthrough.

## Terms and analogies

- Keep the real technical terms. Never swap one for a vague word.
- Define only terms specific to this repo or domain, or likely new to the user, in a short clause after the term.
- Do not define everyday engineering terms: PR, stacked PR, regex, changeset, Storybook, peer dependency, hook, and the like.
- Use an analogy only when every part maps to something real. Name the real term beside it: "shelves (layers)". If any part would mislead, drop it.
- Once a word belongs to the analogy, use it for nothing else. If "shelf" means layer, never use "shelf" for anything else.

## Language

1. One name per thing. Never rotate between synonyms.
2. One idea per sentence. A subordinate clause is fine only when it shows cause.
3. Active voice. Name who acts: "the script rejects it", not "it is rejected".
4. Verbs, not nominalizations: "analyze the log", not "perform an analysis of the log".
5. Short common words: use, start, help, get, show, about, before, after, make sure.
6. Plain verbs over phrasal verbs: "remove", not "take off". "Start", not "spin up".
7. No marketing adjectives: seamless, robust, powerful, comprehensive, streamlined, delve.
8. No semicolons. No em-dashes. Few hyphens.
9. American spelling. No emojis.

## Format reference

This shows the shape and length to aim for. Copy the shape, not the topic, wording, or analogy.

```
THE IDEA
- React matches list items between renders by their key.
- Same key means same item, so React keeps its state.

EXAMPLE
- A todo list uses the array index as each item's key.
- Delete the first todo, and every index shifts by one.
- React now pairs each checkbox state with the wrong todo.

WHY IT MATTERS
- A stable key, like the todo's id, keeps state with the right item.
```

## PRs and stacks

For a PR, the first bullet of THE IDEA says what the change lets users do, in plain product terms. The next bullets give the approach the PR takes. EXAMPLE shows it with a concrete case from the diff. WHY IT MATTERS is why this approach fits.

For a stack, teach the whole stack's idea first. Then add one short section per PR, bottom to top, after WHY IT MATTERS:

```
#2974 RESERVE KEY NAMES
- Two or three bullets on what this PR adds to the idea.
```

Per-PR bullets name the role each PR plays in the idea. Leave out UI behavior, sort orders, edge cases, and button states everywhere, including per-PR sections.

## Long threads

If the user is lost in a long conversation, THE IDEA is where things stand. EXAMPLE is the key decision and what drove it. WHY IT MATTERS is what that decision protects. If they seem unsure what they are trying to do, suggest the approach skill in one line.
