#!/usr/bin/env python3
"""Count the lines a diff adds, by kind and by hunk.

Reads a unified diff on stdin, such as `gh pr diff 123 | count.py`.
Prints each hunk with its file, kind, and added lines, then totals by kind.
Kinds: code, tests, docs, other. Comment lines in code are counted apart.
"""

import re
import sys
from collections import defaultdict

TEST = re.compile(
    r"(\.test\.|\.spec\.|_test\.|test_[^/]*\.py$|/__tests__/|/tests?/|\.stories\.|/fixtures?/|/__mocks__/|/testdata/|/e2e/|/test-utils/|/mocks/|test-fixtures\.|test-support\.)"
)
DOCS = re.compile(r"(\.mdx?$|\.rst$|\.txt$|^docs/|/docs/|^\.changeset/)")
OTHER = re.compile(
    r"(\.lock$|lock\.(json|yaml)$|\.snap$|\.svg$|\.png$|\.jpe?g$|\.gif$|\.ico$|\.webp$|\.woff2?$|/generated/|\.gen\.|(^|/)\.gitignore$|(^|/)\.knip-baseline\.json$)"
)
COMMENT = re.compile(r"^\s*(//|/\*|\*(?!\*)|\*/|#(?![!{\[])|<!--|\{/\*|--\s)")


def kind_of(path: str) -> str:
    if OTHER.search(path):
        return "other"
    if TEST.search(path):
        return "tests"
    if DOCS.search(path):
        return "docs"
    return "code"


def main() -> None:
    hunks = []
    path = None
    current = None
    for line in sys.stdin:
        line = line.rstrip("\n")
        if line.startswith("diff --git "):
            path = None
            current = None
            continue
        if line.startswith("+++ "):
            target = line[4:]
            path = None if target == "/dev/null" else re.sub(r"^b/", "", target)
            continue
        if line.startswith("--- "):
            continue
        if path is None:
            continue
        if line.startswith("@@"):
            m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@ ?(.*)", line)
            current = {
                "path": path,
                "kind": kind_of(path),
                "start": int(m.group(1)) if m else 0,
                "context": (m.group(2) if m else "").strip()[:60],
                "added": 0,
                "removed": 0,
                "comments": 0,
            }
            hunks.append(current)
            continue
        if current is None:
            continue
        if line.startswith("+"):
            current["added"] += 1
            if current["kind"] == "code" and COMMENT.match(line[1:]):
                current["comments"] += 1
        elif line.startswith("-"):
            current["removed"] += 1

    if not hunks:
        sys.exit("count.py: no diff on stdin. Check the gh pr diff command and the repo.")

    print("added\tremoved\tcomments\tkind\tfile:line\tcontext")
    for h in hunks:
        print(
            f"{h['added']}\t{h['removed']}\t{h['comments']}\t{h['kind']}\t{h['path']}:{h['start']}\t{h['context']}"
        )

    totals = defaultdict(int)
    comments = 0
    for h in hunks:
        totals[h["kind"]] += h["added"]
        comments += h["comments"]
    print()
    print("TOTALS (lines added)")
    for kind in ("code", "tests", "docs", "other"):
        print(f"{kind}\t{totals[kind]}")
    print(f"comments in code\t{comments}")
    print(f"all\t{sum(totals.values())}")


if __name__ == "__main__":
    main()
