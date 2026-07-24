from __future__ import annotations

import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


SKILLS = (
    "analyze",
    "apply",
    "archive",
    "ask",
    "audit",
    "commit",
    "debug",
    "discuss",
    "drift",
    "ingest",
    "propose",
    "verify",
)
STABLE_PATHS = (".cash-skills/bin/cash", ".cash-workspace.lock")


class HistoryError(RuntimeError):
    pass


def git(root: Path, *arguments: str, check: bool = True) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=False,
        capture_output=True,
    )
    if check and result.returncode != 0:
        raise HistoryError(result.stderr.decode("utf-8", errors="replace").strip())
    return result.stdout


def version(value: bytes) -> tuple[str, str, str]:
    text = value.decode("ascii").strip()
    parts = text.split(".")
    if (
        len(parts) != 3
        or any(
            not part
            or not part.isdigit()
            or (len(part) > 1 and part.startswith("0"))
            for part in parts
        )
    ):
        raise HistoryError(f"invalid bundle version: {text}")
    return parts[0], parts[1], parts[2]


def version_greater(left: tuple[str, ...], right: tuple[str, ...]) -> bool:
    for candidate, baseline in zip(left, right, strict=True):
        if len(candidate) != len(baseline):
            return len(candidate) > len(baseline)
        if candidate != baseline:
            return candidate > baseline
    return False


def replaceable_paths(root: Path) -> list[str]:
    runtime = [
        path.relative_to(root).as_posix()
        for path in (root / ".cash-skills" / "lib" / "cash_cli").rglob("*.py")
    ]
    skills = [
        f"{variant}/skills/cash-{skill}/SKILL.md"
        for variant in (".agents", ".claude")
        for skill in SKILLS
    ]
    paths = sorted(runtime, key=lambda value: value.encode("utf-8")) + skills
    missing = [relative for relative in paths if not (root / relative).is_file()]
    if missing:
        raise HistoryError(f"bundle inventory is incomplete: {missing[0]}")
    return paths


def tree_paths(root: Path, commit: str) -> set[str]:
    return set(
        git(root, "ls-tree", "-r", "--name-only", commit)
        .decode("utf-8")
        .splitlines()
    )


def tree_mode(root: Path, commit: str, relative: str) -> int:
    row = git(root, "ls-tree", commit, "--", relative).decode("utf-8").strip()
    if not row:
        raise HistoryError(f"{relative} is missing from {commit}")
    return int(row.split()[0], 8) & 0o777


def current_mode(path: Path) -> int:
    return stat.S_IMODE(os.lstat(path).st_mode)


def assert_path_matches(root: Path, commit: str, relative: str) -> None:
    expected = git(root, "show", f"{commit}:{relative}")
    path = root / relative
    if path.read_bytes() != expected or current_mode(path) != tree_mode(root, commit, relative):
        raise HistoryError(
            f"{relative} changed without a strictly greater cash-skills.version"
        )


def introduction_commit(root: Path, current: tuple[str, ...]) -> str:
    introduction = ""
    for commit in git(root, "rev-list", "--first-parent", "HEAD").decode().splitlines():
        value = git(root, "show", f"{commit}:cash-skills.version", check=False)
        if not value:
            break
        if version(value) != current:
            break
        introduction = commit
    if not introduction:
        raise HistoryError("current bundle version has no first-parent introduction commit")
    return introduction


def path_introduction_commit(root: Path, relative: str) -> str:
    commits = (
        git(root, "rev-list", "--first-parent", "--reverse", "HEAD", "--", relative)
        .decode("ascii")
        .splitlines()
    )
    for commit in commits:
        if git(root, "ls-tree", commit, "--", relative).strip():
            return commit
    raise HistoryError(f"{relative} has no first-parent introduction commit")


def check_history(root: Path) -> None:
    current = version((root / "cash-skills.version").read_bytes())
    head_value = git(root, "show", "HEAD:cash-skills.version", check=False)
    if not head_value:
        raise HistoryError("HEAD has no cash-skills.version")
    head = version(head_value)
    paths = replaceable_paths(root)
    head_tree = tree_paths(root, "HEAD")
    for relative in STABLE_PATHS:
        if relative in head_tree:
            assert_path_matches(
                root,
                path_introduction_commit(root, relative),
                relative,
            )
    if current != head:
        if not version_greater(current, head):
            raise HistoryError("bundle version must strictly increase")
        return
    introduction = introduction_commit(root, current)
    expected_paths = {
        relative
        for relative in tree_paths(root, introduction)
        if (
            relative.startswith(".cash-skills/lib/cash_cli/")
            and relative.endswith(".py")
        )
        or (
            relative.startswith((".agents/skills/cash-", ".claude/skills/cash-"))
            and relative.endswith("/SKILL.md")
        )
    }
    if set(paths) != expected_paths:
        raise HistoryError("replaceable inventory changed without a version bump")
    for relative in paths:
        assert_path_matches(root, introduction, relative)


class BundleHistoryTests(unittest.TestCase):
    def make_repo(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        git(root, "init", "-q")
        git(root, "config", "user.email", "test@example.com")
        git(root, "config", "user.name", "Test")
        (root / "cash-skills.version").write_text("1.0.0\n", encoding="ascii")
        launcher = root / ".cash-skills" / "bin" / "cash"
        launcher.parent.mkdir(parents=True)
        launcher.write_text("#!/bin/sh\n", encoding="utf-8")
        os.chmod(launcher, 0o755)
        lock = root / ".cash-workspace.lock"
        lock.touch(mode=0o644)
        runtime = root / ".cash-skills" / "lib" / "cash_cli" / "main.py"
        runtime.parent.mkdir(parents=True)
        runtime.write_text("VALUE = 1\n", encoding="utf-8")
        for variant in (".agents", ".claude"):
            for skill in SKILLS:
                path = root / variant / "skills" / f"cash-{skill}" / "SKILL.md"
                path.parent.mkdir(parents=True)
                path.write_text(f"name: cash-{skill}\n", encoding="utf-8")
        git(root, "add", ".")
        git(root, "commit", "-qm", "bundle 1.0.0")
        return temporary, root

    def test_same_version_drift_fails(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        (root / ".cash-skills" / "lib" / "cash_cli" / "main.py").write_text(
            "VALUE = 2\n",
            encoding="utf-8",
        )
        with self.assertRaises(HistoryError):
            check_history(root)

    def test_same_version_mode_and_inventory_drift_fail(self) -> None:
        for drift in ("mode", "inventory"):
            with self.subTest(drift=drift):
                temporary, root = self.make_repo()
                self.addCleanup(temporary.cleanup)
                runtime = root / ".cash-skills" / "lib" / "cash_cli"
                if drift == "mode":
                    os.chmod(runtime / "main.py", 0o600)
                else:
                    (runtime / "extra.py").write_text(
                        "EXTRA = True\n",
                        encoding="utf-8",
                    )
                with self.assertRaises(HistoryError):
                    check_history(root)

    def test_strict_version_bump_allows_replaceable_change(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        (root / ".cash-skills" / "lib" / "cash_cli" / "main.py").write_text(
            "VALUE = 2\n",
            encoding="utf-8",
        )
        (root / "cash-skills.version").write_text(
            "100000000000000000000.0.0\n",
            encoding="ascii",
        )
        check_history(root)

    def test_stable_bootstrap_drift_fails_even_with_version_bump(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        (root / ".cash-skills" / "bin" / "cash").write_text(
            "#!/bin/sh\nexit 1\n",
            encoding="utf-8",
        )
        (root / "cash-skills.version").write_text("1.0.1\n", encoding="ascii")
        with self.assertRaises(HistoryError):
            check_history(root)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(BundleHistoryTests)
    result = unittest.TextTestRunner().run(suite)
    if not result.wasSuccessful():
        raise SystemExit(1)
    check_history(Path(__file__).resolve().parents[3])
    print("PASS: bundle version history")
