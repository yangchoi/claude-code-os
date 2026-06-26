#!/usr/bin/env bash
# Memory health check.
#
# Run this against your memory directory to catch the failure modes that quietly
# break a memory-driven Claude Code system. Exit code 0 = healthy, 1 = problems.
#
# Usage:
#   scripts/memory-health-check.sh [memory-dir]
#
# Defaults to ~/.claude/projects/<cwd-slug>/memory/ if no argument is given,
# falling back to ./memory/ for repo-local setups.

set -euo pipefail

MEM_DIR="${1:-}"
if [ -z "$MEM_DIR" ]; then
  # Try the canonical Claude Code project memory path first.
  slug=$(pwd | sed 's|/|-|g')
  candidate="$HOME/.claude/projects/${slug}/memory"
  if [ -d "$candidate" ]; then
    MEM_DIR="$candidate"
  elif [ -d "./memory" ]; then
    MEM_DIR="./memory"
  else
    echo "Usage: $0 <memory-dir>" >&2
    echo "No memory dir given and none found at default locations." >&2
    exit 2
  fi
fi

if [ ! -d "$MEM_DIR" ]; then
  echo "Not a directory: $MEM_DIR" >&2
  exit 2
fi

INDEX="$MEM_DIR/MEMORY.md"
problems=0

echo "Checking $MEM_DIR"
echo

# --- Check 1: MEMORY.md size cap ---
# Past 200 lines, Claude Code truncates the auto-loaded index. The cutoff is
# silent — entries after line 200 are simply not loaded, and you only notice
# when a rule stops firing. Catching this early is the whole point.
if [ ! -f "$INDEX" ]; then
  echo "❌ No MEMORY.md found in $MEM_DIR"
  problems=$((problems + 1))
else
  lines=$(wc -l < "$INDEX" | tr -d ' ')
  if [ "$lines" -gt 200 ]; then
    echo "❌ MEMORY.md is $lines lines (cap: 200). Entries past 200 are truncated."
    echo "   Move detail out of the index. Each line should be ≤ ~150 chars."
    problems=$((problems + 1))
  elif [ "$lines" -gt 180 ]; then
    echo "⚠️  MEMORY.md is $lines lines — within 20 of the cap. Consider pruning."
  else
    echo "✓  MEMORY.md size: $lines / 200 lines"
  fi
fi

# --- Check 2: long index entries ---
# A single line over ~200 chars means the entry is trying to be a topic. Move
# the detail into its own file and keep the index line as a one-liner.
if [ -f "$INDEX" ]; then
  long=$(awk 'length > 200 { print NR": "length" chars: "substr($0, 1, 80)"..." }' "$INDEX")
  if [ -n "$long" ]; then
    echo "⚠️  Index lines over 200 chars (these belong in topic files):"
    echo "$long" | sed 's/^/   /'
  fi
fi

# --- Check 3: broken [[wiki-link]]s ---
# The system relies on cross-references. A [[name]] that points to a non-existent
# slug isn't fatal (sometimes you write the link before the note), but a stale
# link to a deleted note is silent rot.
if command -v grep >/dev/null; then
  links=$(grep -rhoE '\[\[[a-z0-9_-]+\]\]' "$MEM_DIR" 2>/dev/null | sort -u | sed 's/\[\[//; s/\]\]//')
  missing=""
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    # Match against `name:` frontmatter field. The slug in [[link]] should match
    # the file's declared name.
    if ! grep -rl "^name: ${slug}\$" "$MEM_DIR" >/dev/null 2>&1; then
      missing="${missing}${slug}\n"
    fi
  done <<< "$links"
  if [ -n "$missing" ]; then
    echo "ℹ️  [[wiki-link]]s without a matching note (write or remove these):"
    echo -e "$missing" | grep -v '^$' | sort -u | sed 's/^/   - /'
  fi
fi

# --- Check 4: notes without frontmatter ---
# Every note should declare its type. Notes without frontmatter aren't
# necessarily broken, but they don't participate in the type-based behaviors.
no_fm=$(find "$MEM_DIR" -maxdepth 2 -name "*.md" -not -name "MEMORY.md" | while read -r f; do
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "$f"
  fi
done)
if [ -n "$no_fm" ]; then
  echo "⚠️  Notes missing YAML frontmatter:"
  echo "$no_fm" | sed 's/^/   - /'
fi

# --- Summary ---
echo
if [ "$problems" -eq 0 ]; then
  echo "✓  Memory is healthy."
  exit 0
else
  echo "❌ $problems problem(s) found. Fix and re-run."
  exit 1
fi
