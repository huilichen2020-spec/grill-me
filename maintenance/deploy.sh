#!/usr/bin/env bash
# One-command deploy for a skills repo: sync every skill into the Claude app's
# sessions, flag the ones that additionally need a manual UI install, and push
# to GitHub behind a secret-leak guard.
#
# Wired to .git/hooks/post-commit, so a commit deploys itself. Also safe to run
# by hand:  ./maintenance/deploy.sh [--no-push] [--quiet]
#
# Replaces the launchd auto-push watcher, which macOS TCC kills with exit 126
# (launchd agents cannot read ~/Documents). A git hook inherits the permissions
# of whoever ran git, so it just works.
#
# Exits 0 even on internal failure: a deploy problem must never look like a
# failed commit.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 0
NAME="$(basename "$REPO")"
LOG="/tmp/${NAME}-deploy.log"
STATE="maintenance/.deployed.json"

PUSH=1; QUIET=0; SYNC=1; FROM_HOOK=0
for arg in "$@"; do
  case "$arg" in
    --no-push) PUSH=0 ;;
    # Push without running install.sh. dotfiles-claude used this until 2026-09-26,
    # when its install.sh became idempotent and started deploying app-used skills
    # into the plugin sessions; its hook now runs the full deploy.
    --push-only) SYNC=0 ;;
    --from-hook) QUIET=1; FROM_HOOK=1 ;;
    --quiet) QUIET=1 ;;
  esac
done
say()  { [ "$QUIET" = "1" ] || echo "$@"; }
# warn() ALWAYS prints, even under --from-hook. Routing a block or a failure
# through say() makes it invisible in the only unattended path there is.
warn() { echo "$@" >&2; }
log()  { echo "$(date '+%F %T') $*" >> "$LOG"; }

# Files that must never reach a public remote, even if force-added past .gitignore.
# .skill/dist are here because the guard is PATH-based and cannot see inside a
# zip: a packaged bundle can carry a gitignored file straight past it.
LEAK_RE='corpus_txt/|\.local\.(md|json)$|(^|/)\.env($|\.)|credentials|\.pem$|\.key$|id_rsa|signature\.png$|secrets?\.(json|ya?ml)$|(^|/)\.secrets/|\.netrc$|\.skill$|(^|/)dist/'

# ── 1. Stale-lock sweep ────────────────────────────────────────────────────
# ANY .git lock older than 10 minutes with no git process alive is an abandoned
# operation. Naming only index/HEAD/main locks was not enough: on 2026-08-23
# comms-hub-skills was found holding HEAD.lock, next-index-9.lock AND
# objects/maintenance.lock from an aborted run two days earlier, which had
# silently stranded a finished commit unpushed that whole time. A live git's
# locks are always younger than 10 minutes, so they are never touched.
if [ -z "$(pgrep -x git 2>/dev/null)" ]; then
  while IFS= read -r lock; do
    [ -n "$lock" ] || continue
    rm -f "$lock" && log "cleared stale lock $lock"
    say "  cleared stale lock: $lock"
  done <<< "$(find .git -name '*.lock' -mmin +10 2>/dev/null)"
fi

# ── 2. Sync skills into every Claude app session ───────────────────────────
if [ "$SYNC" = "1" ] && [ -x ./install.sh ]; then
  if OUT=$(./install.sh 2>&1); then
    # Count DISTINCT skills, not lines: install.sh emits one line per skill per
    # session, so a plain grep -c reported 26 for 13 skills across 2 sessions.
    N=$(printf '%s\n' "$OUT" | awk '/installed:/{print $2}' | sort -u | wc -l | tr -d ' ')
    S=$(printf '%s\n' "$OUT" | grep -c 'session:' | tr -d ' ')
    say "  app sync: $N skill(s) → ${S:-?} session(s)"
    log "app sync ok ($N skills, $S sessions)"
    # install.sh warnings (a real file moved to a backup, a listed skill missing
    # from the repo) must reach her even under --from-hook, where say() is silent.
    W=$(printf '%s\n' "$OUT" | grep -E 'Backing up|\[warn\]' || true)
    [ -n "$W" ] && warn "$W"
  else
    warn "  app sync FAILED (see $LOG)"
    printf '%s\n' "$OUT" >> "$LOG"
    log "app sync FAILED"
  fi
fi

# ── 2b. Pull Cowork artifacts into the repo (manual runs only) ─────────────
# Inherited from the launchd watcher this script replaces. Skipped when invoked
# from the post-commit hook: it commits, and committing inside post-commit
# re-enters the hook.
if [ "$FROM_HOOK" = "0" ] && [ "$SYNC" = "1" ]; then
  sync_artifact() {
    local SRC="$1" DST="$2" LABEL="$3"
    if [ -f "$SRC" ] && ! cmp -s "$SRC" "$DST"; then
      mkdir -p "$(dirname "$DST")"
      cp "$SRC" "$DST"
      # --only <path>: commit THIS artifact alone. A bare `git commit` sweeps
      # whatever else happens to be staged into a commit labelled "auto-sync",
      # which both mislabels the change and can publish work that was staged
      # for review, not for pushing.
      git add "$DST" && git commit --quiet --only -- "$DST" \
        -m "auto-sync: $LABEL updated from Cowork artifact" \
        && { say "  artifact synced + committed: $LABEL"; log "auto-committed $LABEL"; }
    fi
  }
  # Sync ONLY artifacts this repo ALREADY tracks. A hardcoded name list made
  # every repo carrying this script adopt the same artifacts: on 2026-08-23 it
  # introduced grant-opportunity-radar and email-todo-list into dotfiles-claude,
  # which owns neither. Discovering from artifacts/ keeps each artifact in the
  # repo that actually owns it, and adding a NEW one stays a deliberate act.
  if [ -d artifacts ]; then
    for dir in artifacts/*/; do
      [ -d "$dir" ] || continue
      A=$(basename "$dir")
      SRC="$HOME/Documents/Claude/Artifacts/$A/index.html"
      [ -f "$SRC" ] || continue
      # Match whichever filename this repo already uses for it.
      for DST in "$dir$A.html" "${dir}index.html"; do
        [ -f "$DST" ] && sync_artifact "$SRC" "$DST" "$A"
      done
    done
  fi
fi

# ── 3. Which skills need a MANUAL UI install? ──────────────────────────────
# In-place file edits load without any UI step, but the app's registry caches
# each skill's name + description: a NEW skill, or a CHANGED description, needs
# a real UI install before triggering reflects the change. Everything else is
# already live from step 2. This compares fingerprints against the last deploy.
NEEDS_UI=""
[ "$SYNC" = "1" ] && NEEDS_UI=$(python3 - "$REPO" "$STATE" <<'PY'
import hashlib, json, os, re, sys
repo, state_path = sys.argv[1], sys.argv[2]
try:
    import yaml
except ImportError:
    yaml = None

def frontmatter(p):
    try:
        raw = open(p, encoding="utf-8").read()
    except OSError:
        return None
    m = re.match(r"^---\n(.*?)\n---", raw, re.S)
    if not m:
        return None
    block = m.group(1)
    if yaml:
        try:
            d = yaml.safe_load(block) or {}
            return d.get("name"), re.sub(r"\s+", " ", str(d.get("description", ""))).strip()
        except Exception:
            pass
    name = re.search(r"^name:\s*(.+)$", block, re.M)
    desc = re.search(r"^description:\s*(.+)$", block, re.M | re.S)
    return (name.group(1).strip() if name else None,
            re.sub(r"\s+", " ", desc.group(1)).strip() if desc else "")

cands = [(d, d) for d in sorted(os.listdir(repo))]
# Skills kept under skills/ (dotfiles-claude) reach the app only when install.sh
# lists them in PLUGIN_SKILLS; the rest are Claude-Code-only via the ~/.claude link.
try:
    src = re.sub(r"#[^\n]*", "", open(os.path.join(repo, "install.sh"), encoding="utf-8").read())
    m = re.search(r"^\s*PLUGIN_SKILLS=\(([^)]*)\)", src, re.M)
    cands += [(n, os.path.join("skills", n)) for n in (m.group(1).split() if m else [])]
except OSError:
    pass
cur, where = {}, {}
for d, rel in cands:
    sk = os.path.join(repo, rel, "SKILL.md")
    if not os.path.isfile(sk):
        continue
    fm = frontmatter(sk)
    if not fm or not fm[0]:
        continue
    cur[d] = hashlib.sha256(f"{fm[0]}\x00{fm[1]}".encode()).hexdigest()[:16]
    where[d] = rel

sp = os.path.join(repo, state_path)
try:
    prev = json.load(open(sp))
except Exception:
    prev = {}

changed = [d for d, h in cur.items() if prev.get(d) != h]
os.makedirs(os.path.dirname(sp), exist_ok=True)
json.dump(cur, open(sp, "w"), indent=2, sort_keys=True)
# First run has no prior state: don't demand a UI install for every skill.
print("\n".join(f"{d}\t{where[d]}" for d in changed) if prev else "")
PY
)

if [ -n "$NEEDS_UI" ]; then
  mkdir -p dist
  COUNT=0
  while IFS=$'\t' read -r skill path; do
    [ -z "$skill" ] && continue
    rm -f "dist/$skill.skill"
    # Build from what git TRACKS, not from a hand-maintained exclusion list.
    # An -x list is a denylist that has to anticipate every secret; git already
    # knows what is ignored, so nothing gitignored can be bundled by construction
    # (a zip -x "**/..." glob also silently missed top-level *.local.md).
    # Zip from the skill's parent dir so entries are <skill>/..., also for skills/<skill>.
    ( cd "$(dirname "${path:-$skill}")" && git ls-files -- "$skill" | zip -q "$REPO/dist/$skill.skill" -@ ) 2>/dev/null
    COUNT=$((COUNT + 1))
  done <<< "$NEEDS_UI"
  warn "  UI install needed ($COUNT): $(printf '%s\n' "$NEEDS_UI" | cut -f1 | tr '\n' ' ')"
  warn "    packaged → $REPO/dist/  (name or description changed; registry needs the refresh)"
  log "needs UI install: $(printf '%s\n' "$NEEDS_UI" | cut -f1 | tr '\n' ' ')"
fi

# ── 3b. Drift check: every repo skill must be listed or explicitly retired ──
# install.sh only touches names it is given, so a skill that is in the repo but
# in neither array is never updated — its deployed copy ages silently while the
# repo moves on. That lesson was written in install.sh's own comments and drifted
# anyway (essay-assessor, ra-draft-editor, ra-notes-synthesizer, found 2026-08-23),
# which is why it is a check here and not another paragraph there.
if [ "$SYNC" = "1" ] && [ -f install.sh ]; then
  UNLISTED=$(python3 - "$REPO" <<'PY'
import os, re, sys
repo = sys.argv[1]
src = open(os.path.join(repo, "install.sh"), encoding="utf-8").read()
# Strip comments FIRST. Matching arrays before stripping truncates them at the
# first ")" — which lives inside an inline comment like "# -> ... (ported in)",
# silently hiding every entry after it (2026-08-23: ra-audit-veritas and
# research-idea-incubator were reported unlisted while sitting in RETIRED).
src = re.sub(r"#[^\n]*", "", src)
named = set()
for m in re.finditer(r"^[A-Z_]+=\(([^)]*)\)", src, re.M):
    named.update(re.findall(r"[A-Za-z][A-Za-z0-9_-]{2,}", m.group(1)))
# Dot-prefixed dirs are deliberate archives (e.g. .uoft-admin-archived-<ts>),
# not live skills; flagging them would make this check cry wolf every run.
have = {d for d in os.listdir(repo)
        if not d.startswith(".")
        and os.path.isfile(os.path.join(repo, d, "SKILL.md"))}
print(" ".join(sorted(have - named)))
PY
)
  if [ -n "$UNLISTED" ]; then
    say ""
    warn "  ⚠ DRIFT: skill(s) in the repo but in no install.sh array — never synced:"
    warn "      $UNLISTED"
    warn "      Add to SKILLS (to ship) or RETIRED (to purge) in install.sh."
    log "DRIFT unlisted skills: $UNLISTED"
  fi
fi

# ── 4. Push, behind the leak guard ─────────────────────────────────────────
if [ "$PUSH" = "1" ]; then
  BRANCH=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
  if [ -z "$BRANCH" ]; then
    say "  push skipped: detached HEAD"
  elif ! git remote get-url origin >/dev/null 2>&1; then
    say "  push skipped: no origin remote"
  else
    git fetch --quiet origin "$BRANCH" 2>/dev/null
    NEW_BRANCH=0
    if git rev-parse --verify --quiet "origin/$BRANCH" >/dev/null 2>&1; then
      RANGE="origin/$BRANCH..$BRANCH"
    else
      # Branch never pushed: rev-list on a nonexistent ref fails and used to
      # report "nothing to push", stranding the branch forever. Scan its whole
      # history and push with --set-upstream instead.
      NEW_BRANCH=1
      RANGE="$BRANCH"
    fi
    AHEAD=$(git rev-list --count "$RANGE" 2>/dev/null || echo 0)

    if [ "$AHEAD" = "0" ]; then
      say "  push: nothing to push"
    else
      # WALK every commit in the range, do not diff its two endpoints.
      # `git diff A..B` is the two-ENDPOINT form: it compares the tree at A with
      # the tree at B and never visits what happened in between. A secret added
      # in one unpushed commit and `git rm --cached`-ed in the next therefore
      # nets to zero and is INVISIBLE — while still being fully readable in the
      # pushed history. Verified end-to-end against a bare remote 2026-08-23:
      # the guard passed and the manuscript text was recoverable from the clone.
      # That is also the most likely path here, since removing the file is
      # exactly what one does after this guard blocks a push.
      if TOUCHED=$(git log -m --format= --name-only "$RANGE" 2>/dev/null); then
        RISKY=$(printf '%s\n' "$TOUCHED" | sort -u | grep -E "$LEAK_RE" || true)
      else
        # FAIL CLOSED: an unresolvable range must never read as "clean".
        RISKY="<could not resolve $RANGE — refusing to push>"
      fi

      if [ -n "$RISKY" ]; then
        # warn(), never say(): under --from-hook QUIET=1, and a SILENT block is
        # what lets the next commit ship the secret.
        warn ""
        warn "  ✋ PUSH BLOCKED — unpushed commits touch protected paths:"
        warn "$(printf '%s\n' "$RISKY" | sed 's/^/       /')"
        warn "     Commits stay LOCAL. Purge the path from history (git filter-repo"
        warn "     or reset+recommit) before pushing — deleting it in a NEW commit"
        warn "     does not help: the earlier commit still carries the content."
        log "PUSH BLOCKED: $(printf '%s' "$RISKY" | tr '\n' ' ')"
      elif [ "$NEW_BRANCH" = "1" ] && git push --quiet --set-upstream origin "$BRANCH" 2>>"$LOG"; then
        say "  pushed $AHEAD commit(s) → NEW origin/$BRANCH"
        log "pushed $AHEAD commit(s) (new branch)"
      elif [ "$NEW_BRANCH" = "0" ] && git push --quiet origin "$BRANCH" 2>>"$LOG"; then
        say "  pushed $AHEAD commit(s) → origin/$BRANCH"
        log "pushed $AHEAD commit(s)"
      else
        warn "  push FAILED (offline? see $LOG) — commits are safe locally"
        log "push FAILED"
      fi
    fi
  fi
fi

exit 0
