from __future__ import annotations

import re
import sys
from pathlib import Path


COMMANDS = (
    "list|status|instructions|new|validate|analyze|drift|search|park|unpark|"
    "sync|archive|task|touched|in-progress|update"
)
EXECUTABLE_LEGACY = re.compile(
    rf"(?<![A-Za-z0-9_.-])spectra[ \t]+(?:{COMMANDS})\b",
    re.IGNORECASE,
)
SKILL_INVOCATION = re.compile(
    r"(?<![A-Za-z0-9_.-])(?:\$|/)spectra-[a-z]",
    re.IGNORECASE,
)
PROCESS_INVOCATION = re.compile(
    r"(?:subprocess\.(?:run|Popen)|exec|system)\s*\([^)\n]*[\"']spectra[\"']",
    re.IGNORECASE,
)


def iter_live_files(root: Path) -> list[Path]:
    fixed = [
        root / "install-cash-skills.fish",
        root / "AGENTS.md",
        root / "CLAUDE.md",
        root / "CASH-SKILLS.md",
        root / ".cash.yaml",
    ]
    globbed: list[Path] = []
    for pattern in (
        ".agents/skills/cash-*/**/*",
        ".claude/skills/cash-*/**/*",
        "scripts/cash-skills/variant-parity/**/*",
        "scripts/cash-skills/tests/**/*",
        ".cash-skills/**/*",
        "scripts/cash-cli/**/*",
        "openspec/specs/**/*",
    ):
        globbed.extend(root.glob(pattern))
    return sorted(
        {
            path
            for path in fixed + globbed
            if path.is_file()
            and "__pycache__" not in path.parts
            and path.suffix != ".pyc"
            and ".cash-skills/state" not in path.as_posix()
        },
        key=lambda path: path.relative_to(root).as_posix().encode("utf-8"),
    )


def is_spec_guard_context(text: str) -> bool:
    return any(
        marker in text
        for marker in (
            "MUST NOT",
            "SHALL NOT",
            "不得",
            "不執行",
            "不包含",
            "移除",
            "拒絕",
            "使測試失敗",
            "不存在",
            "零呼叫",
        )
    )


def scheduled_master_titles(root: Path) -> dict[str, set[str]]:
    scheduled: dict[str, set[str]] = {}
    requirement = re.compile(r"### Requirement: (.+)")
    rename_from = re.compile(r"- FROM: `### Requirement: (.+)`")
    for change in (root / "openspec/changes").iterdir():
        if (
            not change.is_dir()
            or change.is_symlink()
            or change.name in {"archive", ".parked"}
        ):
            continue
        specs = change / "specs"
        if not specs.is_dir() or specs.is_symlink():
            continue
        for delta in specs.glob("*/spec.md"):
            operation = ""
            capability = delta.parent.name
            titles = scheduled.setdefault(capability, set())
            for line in delta.read_text(encoding="utf-8").splitlines():
                if line.startswith("## ") and line.endswith(" Requirements"):
                    operation = line[3 : -13]
                    continue
                if (
                    operation in {"MODIFIED", "REMOVED"}
                    and (match := requirement.fullmatch(line)) is not None
                ):
                    titles.add(match.group(1))
                if (
                    operation == "RENAMED"
                    and (match := rename_from.fullmatch(line)) is not None
                ):
                    titles.add(match.group(1))
    return scheduled


def enclosing_requirement(text: str, offset: int) -> str | None:
    title: str | None = None
    for line in text[:offset].splitlines():
        if line.startswith("### Requirement: "):
            title = line.removeprefix("### Requirement: ")
    return title


def main() -> int:
    root = Path(sys.argv[1]).resolve()
    failures: list[str] = []
    detector = Path(__file__).resolve()
    detector_paths = {
        detector,
        root / "scripts/cash-skills/tests/skill-checks.fish",
    }
    config_allow = {
        root / ".cash-skills/lib/cash_cli/installer.py",
        root / "scripts/cash-skills/tests/test_installer_runtime.py",
        *detector_paths,
    }
    touched_allow = {
        root / ".cash-skills/lib/cash_cli/commands/tasks.py",
        root / "scripts/cash-cli/tests/test_creation_task_lifecycle.py",
        root / "scripts/cash-cli/tests/test_sync_archive_transaction.py",
        *detector_paths,
    }
    historical_spec_roots = {root / "openspec/specs"}
    scheduled = scheduled_master_titles(root)

    for path in iter_live_files(root):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            failures.append(f"{path.relative_to(root)}: non-UTF-8 live file")
            continue
        relative = path.relative_to(root).as_posix()
        in_historical_master = any(parent in path.parents for parent in historical_spec_roots)
        if path not in detector_paths:
            for label, pattern in (
                ("executable legacy command", EXECUTABLE_LEGACY),
                ("legacy skill invocation", SKILL_INVOCATION),
                ("legacy process invocation", PROCESS_INVOCATION),
            ):
                for match in pattern.finditer(text):
                    start = text.rfind("\n", 0, match.start()) + 1
                    end = text.find("\n", match.end())
                    line_text = text[start : len(text) if end < 0 else end]
                    if in_historical_master:
                        capability = path.parent.name
                        title = enclosing_requirement(text, match.start())
                        if (
                            is_spec_guard_context(line_text)
                            or title in scheduled.get(capability, set())
                        ):
                            continue
                    line = text.count("\n", 0, match.start()) + 1
                    failures.append(f"{relative}:{line}: {label}")
            for match in re.finditer(
                r"Requires[ \t]+spectra[ \t]+CLI",
                text,
                re.IGNORECASE,
            ):
                start = text.rfind("\n", 0, match.start()) + 1
                end = text.find("\n", match.end())
                line_text = text[start : len(text) if end < 0 else end]
                if in_historical_master:
                    capability = path.parent.name
                    title = enclosing_requirement(text, match.start())
                    if (
                        is_spec_guard_context(line_text)
                        or title in scheduled.get(capability, set())
                    ):
                        continue
                failures.append(f"{relative}: legacy compatibility declaration")

        if ".spectra.yaml" in text and path not in config_allow and not in_historical_master:
            failures.append(f"{relative}: unmanaged legacy config literal")
        if ".spectra/touched" in text and path not in touched_allow and not in_historical_master:
            failures.append(f"{relative}: unmanaged legacy touched-state literal")
        if (
            ".spectra/snapshots" in text
            and path not in detector_paths
            and not in_historical_master
        ):
            failures.append(f"{relative}: legacy snapshot runtime literal")

    for variant in (".agents", ".claude"):
        retired = sorted((root / variant / "skills").glob("spectra-*"))
        if retired:
            failures.append(f"{variant}: retired canonical directories remain")

    if failures:
        print("\n".join(f"FAIL: {failure}" for failure in failures), file=sys.stderr)
        return 1
    print("PASS: exact live include-root namespace scan")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
