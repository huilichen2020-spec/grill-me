#!/usr/bin/env bash
# Install grill-me into the active Claude Cowork skills session.
# Usage: ./install.sh

set -e

PLUGIN_BASE=~/Library/Application\ Support/Claude/local-agent-mode-sessions/skills-plugin
SESSION=$(find "$PLUGIN_BASE" -maxdepth 3 -name "skills" -type d 2>/dev/null | head -1)

if [ -z "$SESSION" ]; then
  echo "ERROR: Could not find an active skills session under $PLUGIN_BASE"
  exit 1
fi

SKILLS=(grill-me)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

for skill in "${SKILLS[@]}"; do
  dest="$SESSION/$skill"
  rm -rf "$dest"
  rsync -a --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$REPO_DIR/$skill/" "$dest/"
  echo "  installed: $skill"
done

echo ""
echo "Done. Restart your Claude Code session to pick up changes."
