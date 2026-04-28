#!/usr/bin/env python3
"""
skill_inventory.py — Parse a skill's structure into a context packet.

Reads SKILL.md frontmatter, all reference files in references/, and
script files in scripts/. Returns structured JSON describing the
skill — the "context packet" that grill-me Wave 2/3 questions
reference.

Usage:
  python3 skill_inventory.py /path/to/skill/dir
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def parse_frontmatter(skill_md_text: str) -> tuple[dict, str]:
    """Return (frontmatter_dict, body)."""
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", skill_md_text, re.DOTALL)
    if not m:
        return {}, skill_md_text
    frontmatter_raw = m.group(1)
    body = m.group(2)

    # Cheap YAML-ish parser; handles "key: value" and "key: |" / ">"
    fm = {}
    lines = frontmatter_raw.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        m2 = re.match(r"^(\w[\w-]*):\s*(.*)$", line)
        if not m2:
            i += 1
            continue
        key = m2.group(1)
        rest = m2.group(2).strip()
        if rest in (">", "|", ">-", "|-"):
            block = []
            i += 1
            while i < len(lines) and (lines[i].startswith(" ") or lines[i].startswith("\t")):
                block.append(lines[i].strip())
                i += 1
            fm[key] = " ".join(block)
        else:
            # Strip surrounding quotes
            if rest.startswith('"') and rest.endswith('"'):
                rest = rest[1:-1]
            fm[key] = rest
            i += 1
    return fm, body


def extract_trigger_phrases(description: str) -> list[str]:
    """Pull out quoted trigger phrases like "do this", 'or that'."""
    phrases = re.findall(r"['\"]([^'\"]{4,80})['\"]", description)
    return list(dict.fromkeys(phrases))  # dedup, preserve order


def summarize_reference_file(path: Path) -> dict:
    """Read a reference file; extract title, line count, first-paragraph
    summary, top-level headings."""
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return {"name": path.name, "error": "could not read"}

    lines = text.splitlines()
    line_count = len(lines)

    # Title = first H1; if none, filename
    h1_m = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    title = h1_m.group(1).strip() if h1_m else path.stem.replace("-", " ").title()

    # Top-level H2s for navigation
    h2s = re.findall(r"^##\s+(.+)$", text, re.MULTILINE)

    # First paragraph (after frontmatter or H1)
    body_start = 0
    if h1_m:
        body_start = h1_m.end()
    rest = text[body_start:].lstrip("\n")
    first_para = ""
    for line in rest.split("\n"):
        if line.startswith("#") or line.startswith("---"):
            break
        if line.strip() and not first_para:
            first_para = line.strip()
        elif first_para and not line.strip():
            break
        elif first_para:
            first_para += " " + line.strip()
        if len(first_para) > 300:
            break

    return {
        "name": path.name,
        "title": title,
        "line_count": line_count,
        "h2_sections": h2s[:15],
        "first_paragraph": first_para[:400],
    }


def summarize_script(path: Path) -> dict:
    """Pull module docstring + top-level function names from a Python file."""
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return {"name": path.name, "error": "could not read"}

    lines = text.splitlines()
    line_count = len(lines)

    # Module docstring (first triple-quoted string)
    docstring = ""
    m = re.search(r'^("""|\'\'\')(.*?)\1', text, re.DOTALL | re.MULTILINE)
    if m:
        docstring = m.group(2).strip().split("\n")[0][:200]
    elif "'''" in text or '"""' in text:
        # Try multi-line docstring
        m2 = re.search(r'^(?:"""|\'\'\')(.+?)(?:"""|\'\'\')',
                       text, re.DOTALL | re.MULTILINE)
        if m2:
            docstring = m2.group(1).strip().split("\n")[0][:200]

    # Top-level function names
    funcs = re.findall(r"^def\s+(\w+)", text, re.MULTILINE)

    return {
        "name": path.name,
        "line_count": line_count,
        "docstring_summary": docstring,
        "functions": funcs[:20],
    }


def find_cross_skill_refs(skill_dir: Path) -> list[str]:
    """Look across all .md files for mentions of OTHER skills."""
    other_skill_pattern = re.compile(
        r"\b(ra-[a-z\-]+|comms-[a-z\-]+|outreach-[a-z\-]+|"
        r"calendar-invite|signature-stamp|inbox-triage|uoft-admin|"
        r"vix-trading-assistant|skill-creator|skill-refinement|"
        r"download-research-articles|humanizer|innovation-diagnosis|"
        r"docx|pptx|xlsx|pdf|canvas-design)\b"
    )
    refs = set()
    for md in skill_dir.rglob("*.md"):
        try:
            text = md.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        # Don't count the current skill's own name
        own_name = skill_dir.name
        for m in other_skill_pattern.finditer(text):
            name = m.group(1)
            if name != own_name:
                refs.add(name)
    return sorted(refs)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("skill_dir", help="Path to the skill directory")
    args = ap.parse_args()

    skill_dir = Path(args.skill_dir).expanduser().resolve()
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        print(f"Error: {skill_md} not found", file=sys.stderr)
        return 1

    fm, body = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
    description = fm.get("description", "")

    inventory = {
        "skill_name": fm.get("name", skill_dir.name),
        "skill_path": str(skill_dir),
        "frontmatter": {
            "name": fm.get("name"),
            "description_chars": len(description),
            "description_under_limit": len(description) < 1024,
            "license": fm.get("license"),
            "compatibility": fm.get("compatibility"),
        },
        "skill_md": {
            "total_lines": len(skill_md.read_text().splitlines()),
            "body_lines": len(body.splitlines()),
            "h2_sections": re.findall(r"^##\s+(.+)$", body, re.MULTILINE)[:20],
        },
        "trigger_phrases_in_description": extract_trigger_phrases(description),
        "references": [],
        "scripts": [],
        "cross_skill_references": find_cross_skill_refs(skill_dir),
    }

    refs_dir = skill_dir / "references"
    if refs_dir.is_dir():
        for f in sorted(refs_dir.iterdir()):
            if f.is_file() and f.suffix == ".md":
                inventory["references"].append(summarize_reference_file(f))

    scripts_dir = skill_dir / "scripts"
    if scripts_dir.is_dir():
        for f in sorted(scripts_dir.iterdir()):
            if f.is_file() and f.suffix == ".py":
                inventory["scripts"].append(summarize_script(f))

    print(json.dumps(inventory, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
