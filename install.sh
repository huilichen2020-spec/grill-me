#!/usr/bin/env bash
# Install grill-me into EVERY Claude desktop-app skills session.
# Usage: ./install.sh   (also run by maintenance/deploy.sh from the post-commit hook)

set -e

PLUGIN_BASE=~/Library/Application\ Support/Claude/local-agent-mode-sessions/skills-plugin
# Every session, not `head -1`: that picked an arbitrary one when several existed
# and silently missed the active session (same bug fixed in
# research-workspace-skills/install.sh on 2026-07-15).
SESSIONS=$(find "$PLUGIN_BASE" -maxdepth 3 -name "skills" -type d 2>/dev/null || true)

if [ -z "$SESSIONS" ]; then
  echo "ERROR: Could not find an active skills session under $PLUGIN_BASE"
  exit 1
fi

SKILLS=(grill-me)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Sync-wipe guard (same check as research-workspace-skills/install.sh) ─────
# Cowork sessions edit the INSTALLED copies directly, and the rsync below is
# --delete, so a blind repo→live sync would erase those edits. Any live file
# present only live, or differing from the repo and equal to no committed or
# staged version,
# aborts the install. Rescue live → repo first, or FORCE_SYNC=1.
# Blob ids of every file this installer has deployed (gitignored). A live file
# equal to one of them is an earlier deploy even if it was never committed, so
# deploying uncommitted work does not trip the guard once the repo moves on.
DEPLOYED_BLOBS="${DEPLOYED_BLOBS:-$REPO_DIR/maintenance/.deployed-blobs}"

# 0 if live file $1 equals an earlier deploy or any committed or staged ("" =
# index) version of repo path $2: it then holds nothing the repo lacks.
known_to_repo() {
  local b h
  b=$(git -C "$REPO_DIR" hash-object --no-filters -- "$1" 2>/dev/null) || return 1
  [ -f "$DEPLOYED_BLOBS" ] && grep -qx "$b" "$DEPLOYED_BLOBS" && return 0
  for h in "" $(git -C "$REPO_DIR" log --format=%h -- "$2" 2>/dev/null); do
    [ "$(git -C "$REPO_DIR" rev-parse -q --verify "$h:$2" 2>/dev/null)" = "$b" ] && return 0
  done
  return 1
}

sync_wipe_guard() {
  local session="$1" bad=""
  for skill in "${SKILLS[@]}"; do
    local live="$session/$skill" repo="$REPO_DIR/$skill"
    [ -d "$live" ] && [ -d "$repo" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      local rel="${f#$live/}" rf="$repo/${f#$live/}"
      case "$rel" in __pycache__/*|*/__pycache__/*|*.pyc|.DS_Store|*/.DS_Store) continue;; esac
      [ -e "$rf" ] && cmp -s "$f" "$rf" && continue
      # Not equal to the repo file: fine only if it is an earlier deploy or a version
      # git knows. Anything else is an app-side edit, even when OLDER than the repo
      # file (until 2026-09-26 an `-nt` test let any later repo touch erase it).
      known_to_repo "$f" "$skill/$rel" && continue
      if [ ! -e "$rf" ]; then bad="$bad\n    live-only : $skill/$rel"
      elif [ "$f" -nt "$rf" ]; then bad="$bad\n    live-newer: $skill/$rel"
      else bad="$bad\n    live-edit : $skill/$rel (older than the repo copy: was it merged?)"; fi
    done < <(find "$live" \( -type f -o -type l \))
  done
  [ -n "$bad" ] || return 0
  # FORCE_SYNC=1 overrides every session; FORCE_SYNC=<part of one session's path,
  # e.g. d3ec146c> overrides only that one.
  case "${FORCE_SYNC:-0}" in
    1) return 0 ;;
    0) ;;
    *) case "$session" in *"$FORCE_SYNC"*) echo "  FORCE_SYNC: guard overridden for $session"; return 0 ;; esac ;;
  esac
  echo "  ABORT: live copies in $session hold edits the repo lacks:"; printf "%b\n" "$bad"
  echo "  Rescue first (never blind repo→live): commit the live bytes verbatim, then merge"
  echo "  on top. Override knowingly: FORCE_SYNC=<session id> for one session, FORCE_SYNC=1 for all."
  exit 1
}

# Guard EVERY session before writing to ANY.
while IFS= read -r SESSION; do
  sync_wipe_guard "$SESSION"
done <<< "$SESSIONS"

while IFS= read -r SESSION; do
  echo "  session: $SESSION"
  for skill in "${SKILLS[@]}"; do
    # --delete reconciles in place, so there is no window where the skill is missing.
    rsync -a --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
      "$REPO_DIR/$skill/" "$SESSION/$skill/"
    echo "    installed: $skill"
  done
done <<< "$SESSIONS"

# Remember what was just deployed (see DEPLOYED_BLOBS).
mkdir -p "$(dirname "$DEPLOYED_BLOBS")"
for skill in "${SKILLS[@]}"; do
  [ -d "$REPO_DIR/$skill" ] || continue
  find "$REPO_DIR/$skill" -type f ! -name .DS_Store ! -name '*.pyc' ! -path '*/__pycache__/*' \
    -exec git -C "$REPO_DIR" hash-object --no-filters -- {} + >> "$DEPLOYED_BLOBS"
done
sort -u -o "$DEPLOYED_BLOBS" "$DEPLOYED_BLOBS"

echo ""
echo "Done. Restart your Claude Code session to pick up changes."
