#!/usr/bin/env python3
"""
locate_skill.py — Find a skill by name across all known locations.

Searches three layers in order:
  1. Canonical repos under ~/Documents/Claude/Skills/*/
  2. Claude Code plugins under ~/.claude/plugins/*/skills/*/
  3. Active cowork session under ~/Library/.../skills-plugin/.../skills/*/

Cross-references against the cowork manifest.json to determine if
the skill is Anthropic-managed (read-only) or user-created.

Returns JSON describing the skill's location + deploy method.

Usage:
  python3 locate_skill.py {skill-name}
  python3 locate_skill.py ra-draft-editor
  python3 locate_skill.py outreach-email
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from pathlib import Path

HOME = Path.home()
CANONICAL_REPOS_BASE = HOME / "Documents" / "Claude" / "Skills"
CC_PLUGINS_BASE = HOME / ".claude" / "plugins"
COWORK_SESSIONS_BASE = (
    HOME
    / "Library"
    / "Application Support"
    / "Claude"
    / "local-agent-mode-sessions"
    / "skills-plugin"
)


def find_in_canonical_repos(skill_name: str) -> list[Path]:
    """Look for {skill_name}/ as a top-level child under each repo,
    or as a subdirectory matching the standard repo layout."""
    matches = []
    if not CANONICAL_REPOS_BASE.exists():
        return matches
    for repo_dir in CANONICAL_REPOS_BASE.iterdir():
        if not repo_dir.is_dir() or repo_dir.name.startswith("."):
            continue
        # Direct child: ~/Documents/Claude/Skills/{repo}/{skill-name}/SKILL.md
        candidate = repo_dir / skill_name / "SKILL.md"
        if candidate.exists():
            matches.append(candidate.parent)
        # Some repos vendor skills in subfolders; walk one level deeper
        for child in repo_dir.iterdir():
            if child.is_dir() and child.name == skill_name:
                if (child / "SKILL.md").exists():
                    if child not in matches:
                        matches.append(child)
    return matches


def find_in_cc_plugins(skill_name: str) -> list[Path]:
    matches = []
    if not CC_PLUGINS_BASE.exists():
        return matches
    pattern = str(CC_PLUGINS_BASE / "*" / "skills" / skill_name / "SKILL.md")
    for path in glob.glob(pattern):
        matches.append(Path(path).parent)
    return matches


def find_in_cowork_session(skill_name: str) -> list[Path]:
    matches = []
    if not COWORK_SESSIONS_BASE.exists():
        return matches
    pattern = str(
        COWORK_SESSIONS_BASE / "*" / "*" / "skills" / skill_name / "SKILL.md"
    )
    for path in glob.glob(pattern):
        matches.append(Path(path).parent)
    return matches


def read_manifest_for_skill(skill_name: str) -> dict | None:
    """Find the cowork session manifest.json and look up this skill."""
    pattern = str(COWORK_SESSIONS_BASE / "*" / "*" / "manifest.json")
    for path in glob.glob(pattern):
        try:
            data = json.loads(Path(path).read_text())
        except (json.JSONDecodeError, OSError):
            continue
        for s in data.get("skills", []):
            if s.get("name") == skill_name:
                return s
    return None


def deploy_method_for_path(canonical_path: Path | None) -> str:
    """Heuristic: how does a skill at this path get deployed?"""
    if canonical_path is None:
        return "unknown — skill not located"
    p = str(canonical_path)
    if "/.claude/plugins/" in p:
        return "manual edit at this path; CC plugin is the canonical source"
    if "Documents/Claude/Skills" in p:
        # Check for install.sh in the repo root
        repo_root = canonical_path
        for _ in range(3):
            if (repo_root / "install.sh").exists():
                return f"install.sh at {repo_root}/install.sh + .skill UI register"
            if repo_root.parent == repo_root:
                break
            repo_root = repo_root.parent
        return f"manual edit at {canonical_path}"
    if "local-agent-mode-sessions" in p:
        return "ephemeral (synced from manifest); edit will be wiped"
    return "unknown"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("skill_name", help="Skill name to locate")
    ap.add_argument(
        "--quiet", action="store_true", help="JSON-only output to stdout"
    )
    args = ap.parse_args()

    name = args.skill_name

    canonical = find_in_canonical_repos(name)
    cc_plugin = find_in_cc_plugins(name)
    cowork = find_in_cowork_session(name)
    manifest_entry = read_manifest_for_skill(name)

    # Decide canonical_path: prefer canonical repo > CC plugin > cowork
    canonical_path = canonical[0] if canonical else (
        cc_plugin[0] if cc_plugin else None
    )
    canonical_repo = None
    if canonical:
        # Find which repo it's in (the parent that contains a .git directory)
        p = canonical[0]
        while p != p.parent:
            if (p / ".git").exists():
                canonical_repo = p.name
                break
            p = p.parent

    is_anthropic = (
        manifest_entry is not None
        and manifest_entry.get("creatorType") == "anthropic"
    )

    out = {
        "skill_name": name,
        "found": bool(canonical or cc_plugin or cowork),
        "active_path": str(cowork[0]) if cowork else None,
        "canonical_path": str(canonical_path) if canonical_path else None,
        "canonical_repo": canonical_repo,
        "cc_plugin_path": str(cc_plugin[0]) if cc_plugin else None,
        "deploy_method": deploy_method_for_path(canonical_path),
        "is_anthropic_managed": is_anthropic,
        "skill_id": manifest_entry.get("skillId") if manifest_entry else None,
        "manifest_description_chars": (
            len(manifest_entry.get("description", ""))
            if manifest_entry else None
        ),
        "all_canonical_matches": [str(p) for p in canonical],
        "all_cc_plugin_matches": [str(p) for p in cc_plugin],
        "all_cowork_matches": [str(p) for p in cowork],
    }

    print(json.dumps(out, indent=2))
    if not args.quiet and not out["found"]:
        print(f"\nSkill '{name}' not found. Add the repo to "
              f"references/skill-locations.md if it's a new collection.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
