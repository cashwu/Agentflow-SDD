#!/usr/bin/env fish

# Regenerate the Cash skill variants from their single sources.
#
# Stage 1 injects scripts/cash-skills/blocks/review-gate.md into the
# <!-- REVIEW-GATE:BEGIN --> / <!-- REVIEW-GATE:END --> region of the .claude
# cash-propose and cash-apply skills.
# Stage 2 generates every .agents/skills/cash-*/SKILL.md from its .claude
# counterpart using the declarative rules in scripts/cash-skills/variant-rules.yaml.
#
# Usage: generate.fish [target-root]   (default: the repository root)

set -g target_root
if test (count $argv) -gt 0
    set target_root (path resolve $argv[1])
else
    set target_root (path resolve (dirname (status filename))/../..)
end

if not test -d "$target_root"
    echo "generate: target root is not a directory: $target_root" >&2
    exit 1
end

python3 -c '
import re
import sys
from pathlib import Path

GATE_BEGIN = "<!-- REVIEW-GATE:BEGIN -->"
GATE_END = "<!-- REVIEW-GATE:END -->"
GATE_SKILLS = ("cash-propose", "cash-apply")


def die(message):
    print("generate: " + message, file=sys.stderr)
    raise SystemExit(1)


# --- minimal YAML subset reader -------------------------------------------------
# Supports exactly what variant-rules.yaml needs: nested block mappings, block
# sequences of scalars or mappings, double-quoted or plain scalars, and literal
# block scalars introduced by "|". Anything else raises instead of being guessed at.

def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def skip_filler(lines, i):
    while i < len(lines) and (not lines[i].strip() or lines[i].lstrip().startswith("#")):
        i += 1
    return i


UNSUPPORTED_SCALAR_LEADS = ("\x27", "{", "[", "&", "*", ">")


def read_scalar(text):
    value = text.strip()
    if len(value) >= 2 and value[0] == "\"" and value[-1] == "\"":
        return value[1:-1]
    if value[:1] in UNSUPPORTED_SCALAR_LEADS:
        die("unsupported YAML scalar form: " + value[:40])
    return value


def read_literal(lines, i, parent_indent):
    """Read a "|" block scalar whose body starts at line i.

    The body indent is fixed at parent_indent + 2 rather than inferred from the
    first content line, so patch text whose own first line is indented keeps that
    indentation instead of having it stripped as block indent.
    """
    body = []
    block_indent = parent_indent + 2
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            body.append("")
            i += 1
            continue
        if indent_of(line) <= parent_indent:
            break
        if indent_of(line) < block_indent:
            die("literal block is dedented at line " + str(i + 1))
        body.append(line[block_indent:])
        i += 1
    while body and body[-1] == "":
        body.pop()
    return "\n".join(body) + "\n", i


def read_mapping(lines, i, indent):
    result = {}
    while True:
        i = skip_filler(lines, i)
        if i >= len(lines):
            break
        line = lines[i]
        if indent_of(line) < indent:
            break
        if indent_of(line) > indent:
            die("unexpected indentation at line " + str(i + 1))
        body = line.strip()
        if body.startswith("- "):
            break
        if ":" not in body:
            die("expected a mapping key at line " + str(i + 1))
        key, _, rest = body.partition(":")
        key = key.strip()
        rest = rest.strip()
        if rest == "|":
            value, i = read_literal(lines, i + 1, indent)
        elif rest:
            value, i = read_scalar(rest), i + 1
        else:
            child = skip_filler(lines, i + 1)
            if child >= len(lines) or indent_of(lines[child]) <= indent:
                die("key " + key + " at line " + str(i + 1) + " has no value")
            value, i = read_node(lines, child)
        result[key] = value
    return result, i


def read_sequence(lines, i, indent):
    items = []
    while True:
        i = skip_filler(lines, i)
        if i >= len(lines):
            break
        line = lines[i]
        if indent_of(line) < indent:
            break
        if indent_of(line) > indent or not line.strip().startswith("- "):
            die("expected a sequence item at line " + str(i + 1))
        body = line.strip()[2:]
        if body[:1] in UNSUPPORTED_SCALAR_LEADS:
            die("unsupported YAML sequence item form: " + body[:40])
        if body.startswith("\"") or ":" not in body:
            items.append(read_scalar(body))
            i += 1
            continue
        # Re-indent the inline first key so the item parses as a plain mapping.
        lines[i] = " " * (indent + 2) + body
        item, i = read_mapping(lines, i, indent + 2)
        items.append(item)
    return items, i


def read_node(lines, i):
    indent = indent_of(lines[i])
    if lines[i].strip().startswith("- "):
        return read_sequence(lines, i, indent)
    return read_mapping(lines, i, indent)


def load_rules(path):
    lines = path.read_text(encoding="utf-8").split("\n")
    start = skip_filler(lines, 0)
    if start >= len(lines):
        die("variant-rules.yaml is empty")
    rules, _ = read_node(lines, start)
    return rules


# --- transformations ------------------------------------------------------------

def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def inject_gate(path, block_lines):
    lines = path.read_text(encoding="utf-8").split("\n")
    begins = [n for n, line in enumerate(lines) if line == GATE_BEGIN]
    ends = [n for n, line in enumerate(lines) if line == GATE_END]
    if len(begins) != 1 or len(ends) != 1:
        die(str(path) + " must contain exactly one REVIEW-GATE anchor pair")
    if begins[0] > ends[0]:
        die(str(path) + " has its REVIEW-GATE anchors in the wrong order")
    merged = lines[: begins[0] + 1] + block_lines + lines[ends[0] :]
    write_text(path, "\n".join(merged))


def strip_frontmatter_keys(text, keys, label):
    lines = text.split("\n")
    if not lines or lines[0] != "---":
        die(label + " does not start with a frontmatter block")
    try:
        end = lines.index("---", 1)
    except ValueError:
        die(label + " has an unterminated frontmatter block")
    kept = []
    dropping = False
    for line in lines[1:end]:
        indented = line[:1].isspace()
        if dropping and indented:
            # Indented continuation of a dropped key: remove it together with
            # its key, so a block-form value leaves no orphaned lines behind.
            continue
        dropping = not indented and any(line.startswith(key + ":") for key in keys)
        if not dropping:
            kept.append(line)
    return "\n".join(lines[:1] + kept + lines[end:])


def remove_section(text, heading, terminator, label):
    lines = text.split("\n")
    if lines.count(heading) == 0:
        return text
    if lines.count(heading) > 1:
        die(label + " contains more than one " + heading + " section")
    start = lines.index(heading)
    # Bound the terminator search at the next heading: an unterminated section
    # must be a loud error, never a silent deletion up to some later `---`.
    limit = next(
        (n for n in range(start + 1, len(lines)) if lines[n].startswith("## ")),
        len(lines),
    )
    stop = next((n for n in range(start + 1, limit) if lines[n] == terminator), None)
    if stop is None:
        die(label + " has a " + heading + " section without its " + terminator + " terminator")
    if start > 0 and lines[start - 1] == "":
        start -= 1
    del lines[start : stop + 1]
    return "\n".join(lines)


def apply_patch(text, patch, label):
    for field in ("id", "find", "replace"):
        if field not in patch:
            die(label + " has a patch without a " + field + " field")
    found = patch["find"]
    hits = text.count(found)
    if hits != 1:
        die(label + " patch " + patch["id"] + " matched " + str(hits) + " times; expected exactly 1")
    return text.replace(found, patch["replace"])


root = Path(sys.argv[1])
rules = load_rules(root / "scripts/cash-skills/variant-rules.yaml")
if sorted(rules) != ["skills", "universal"]:
    die("variant-rules.yaml top-level keys must be exactly skills and universal")
universal = rules["universal"]
per_skill = rules["skills"]
skills = sorted(p.name for p in (root / ".claude/skills").iterdir() if p.name.startswith("cash-"))
for name, entry in per_skill.items():
    # A misspelled skill name or entry key would otherwise drop its patches silently.
    if name not in skills:
        die("variant-rules.yaml declares an unknown skill: " + name)
    if sorted(entry) != ["description", "patches"]:
        die("variant-rules.yaml entry " + name + " must have exactly description and patches")

block_path = root / "scripts/cash-skills/blocks/review-gate.md"
block_lines = block_path.read_text(encoding="utf-8").rstrip("\n").split("\n")
for skill in GATE_SKILLS:
    inject_gate(root / ".claude/skills" / skill / "SKILL.md", block_lines)

prefix = universal["invocation_prefix"]
pattern = re.compile(prefix["boundary"] + re.escape(prefix["from"]))
replacement = prefix["to"]
frontmatter_keys = universal["frontmatter_remove_keys"]
sections = universal["remove_sections"]

for skill in skills:
    label = ".claude/skills/" + skill + "/SKILL.md"
    text = (root / ".claude/skills" / skill / "SKILL.md").read_text(encoding="utf-8")
    text = strip_frontmatter_keys(text, frontmatter_keys, label)
    for section in sections:
        text = remove_section(text, section["heading"], section["terminator"], label)
    text = pattern.sub(lambda match: replacement, text)
    entry = per_skill.get(skill)
    for patch in (entry["patches"] if entry else []):
        text = apply_patch(text, patch, label)
    write_text(root / ".agents/skills" / skill / "SKILL.md", text)

print("generate: " + str(len(skills)) + " skills written under " + str(root / ".agents/skills"))
' "$target_root"
or exit 1
