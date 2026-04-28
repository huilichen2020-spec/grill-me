#!/usr/bin/env bash
# Copy the active skill from the plugin session into this repo.
# Usage: ./pull.sh
set -e

SKILL=grill-me
PLUGIN_BASE=~/Library/Application\ Support/Claude/local-agent-mode-sessions/skills-plugin
SESSION=$(find "$PLUGIN_BASE" -maxdepth 3 -name "skills" -type d 2>/dev/null | head -1)

if [ -z "$SESSION" ]; then
  echo "ERROR: Could not find active skills session"
  exit 1
fi

SRC="$SESSION/$SKILL"
if [ ! -d "$SRC" ]; then
  echo "ERROR: Skill '$SKILL' not in session ($SESSION)"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$REPO_DIR/$SKILL"

rm -rf "$DEST"
cp -r "$SRC" "$DEST"
find "$DEST" -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

echo "Pulled: $SKILL"
echo ""
git -C "$REPO_DIR" diff --stat HEAD -- "$SKILL" 2>/dev/null || true
git -C "$REPO_DIR" status --short -- "$SKILL"
echo ""
echo "Review, then commit:"
echo "  git add $SKILL && git commit -m 'update $SKILL from cowork' && git push"
