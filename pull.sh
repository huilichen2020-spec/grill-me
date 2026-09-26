#!/usr/bin/env bash
# Copy ONE skill from the ACTIVE desktop-app session into this repo (the reverse of install.sh).
# Usage: ./pull.sh <skill-name>
#
# Safety (2026-09-26, after a near-miss): the old version picked the first session `find` returned — the inactive
# one — and `rm -rf`'d the repo dir over uncommitted work. Now: the active session is the one whose manifest.json
# is newest; the pull refuses while the repo copy has uncommitted changes (commit or stash first, or PULL_FORCE=1);
# and the repo copy is snapshotted to ../_live-snapshots/ before anything is replaced.
set -e
SKILL="$1"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -z "$SKILL" ]; then
  echo "Usage: ./pull.sh <skill-name>"
  echo "Skills: $(sed -n '/^SKILLS=(/,/)/p' "$REPO_DIR/install.sh" | grep -v '^\s*#' | tr -d '()' | sed 's/SKILLS=//' | tr '\n' ' ')"
  exit 1
fi
PLUGIN_BASE="$HOME/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin"
MANIFEST=$(ls -t "$PLUGIN_BASE"/*/*/manifest.json 2>/dev/null | head -1)
[ -n "$MANIFEST" ] || { echo "ERROR: no app session with a manifest.json under $PLUGIN_BASE"; exit 1; }
SESSION="$(dirname "$MANIFEST")"
SRC="$SESSION/skills/$SKILL"
[ -d "$SRC" ] || { echo "ERROR: '$SKILL' is not in the active session ($SESSION/skills)"; exit 1; }
DEST="$REPO_DIR/$SKILL"
if [ -d "$DEST" ] && [ -n "$(git -C "$REPO_DIR" status --porcelain -- "$SKILL")" ] && [ "${PULL_FORCE:-0}" != "1" ]; then
  echo "REFUSED: $SKILL has uncommitted changes in the repo:"; git -C "$REPO_DIR" status --short -- "$SKILL" | head -20
  echo "Commit or stash them first (a pull replaces the whole directory), or PULL_FORCE=1 ./pull.sh $SKILL after a look."
  exit 1
fi
if [ -d "$DEST" ]; then
  SNAP="$REPO_DIR/../_live-snapshots/pull-$(basename "$REPO_DIR")-$SKILL-$(date +%Y%m%d-%H%M%S).tgz"
  mkdir -p "$(dirname "$SNAP")"; tar -czf "$SNAP" -C "$REPO_DIR" "$SKILL"; echo "snapshot of the repo copy: $SNAP"
fi
rsync -a --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$SRC/" "$DEST/"
echo "Pulled: $SKILL  (from session $(basename "$(dirname "$SESSION")"))"
echo; echo "Changes vs HEAD:"; git -C "$REPO_DIR" diff --stat HEAD -- "$SKILL" 2>/dev/null || true; git -C "$REPO_DIR" status --short -- "$SKILL"
echo; echo "Next: review, then git add -A $SKILL && git commit  (the post-commit hook deploys and pushes behind the leak guard; never push by hand)."
