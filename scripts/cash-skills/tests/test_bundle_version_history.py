from __future__ import annotations

import ast
import hashlib
import os
import re
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
MANIFEST_PATH = ".cash-skills/manifest.tsv"


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


def sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def canonical_manifest_bytes(root: Path) -> bytes:
    runtime_paths = sorted(
        (
            path.relative_to(root).as_posix()
            for path in (root / ".cash-skills" / "lib" / "cash_cli").rglob("*.py")
        ),
        key=lambda value: value.encode("utf-8"),
    )
    records = [
        ("stable", STABLE_PATHS[0], 0o755),
        ("stable", STABLE_PATHS[1], 0o644),
        *(("runtime", relative, 0o644) for relative in runtime_paths),
        *(
            (
                "skill",
                f"{variant}/skills/cash-{skill}/SKILL.md",
                0o644,
            )
            for variant in (".agents", ".claude")
            for skill in SKILLS
        ),
    ]
    digests = {
        relative: sha256((root / relative).read_bytes())
        for _, relative, _ in records
    }
    runtime_stream = "".join(
        f"{relative}\t{digests[relative]}\t{mode:04o}\n"
        for kind, relative, mode in records
        if kind == "runtime"
    ).encode("utf-8")
    lines = [
        "format\tcash-portable-manifest-v1",
        f"bundle_version\t{(root / 'cash-skills.version').read_text(encoding='ascii').strip()}",
        f"runtime_generation\t{sha256(runtime_stream)}",
        *(
            f"{kind}\t{relative}\t{digests[relative]}\t"
            f"{'100755' if mode & 0o111 else '100644'}"
            for kind, relative, mode in records
        ),
    ]
    return ("\n".join(lines) + "\n").encode("utf-8")


def write_canonical_manifest(root: Path) -> None:
    manifest = root / MANIFEST_PATH
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_bytes(canonical_manifest_bytes(root))
    os.chmod(manifest, 0o644)


def write_launcher_transitions(
    root: Path,
    transitions: tuple[tuple[str, str, str], ...],
) -> None:
    installer = root / ".cash-skills" / "lib" / "cash_cli" / "installer.py"
    rows = "".join(f"    {transition!r},\n" for transition in transitions)
    installer.write_text(
        f"APPROVED_LAUNCHER_TRANSITIONS = (\n{rows})\n",
        encoding="utf-8",
    )


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


def launcher_transitions(root: Path) -> tuple[tuple[str, str, str], ...]:
    installer = root / ".cash-skills" / "lib" / "cash_cli" / "installer.py"
    try:
        module = ast.parse(installer.read_text(encoding="utf-8"))
    except (OSError, SyntaxError, UnicodeError) as error:
        raise HistoryError(f"cannot read launcher transitions: {error}") from error
    value: object | None = None
    for node in module.body:
        if (
            isinstance(node, ast.Assign)
            and any(
                isinstance(target, ast.Name)
                and target.id == "APPROVED_LAUNCHER_TRANSITIONS"
                for target in node.targets
            )
        ):
            try:
                value = ast.literal_eval(node.value)
            except (ValueError, TypeError, SyntaxError) as error:
                raise HistoryError("launcher transitions must be literal data") from error
            break
    if not isinstance(value, tuple):
        raise HistoryError("APPROVED_LAUNCHER_TRANSITIONS must be a tuple")
    transitions: list[tuple[str, str, str]] = []
    for entry in value:
        if (
            not isinstance(entry, tuple)
            or len(entry) != 3
            or not all(isinstance(field, str) for field in entry)
        ):
            raise HistoryError("launcher transition schema is invalid")
        old_digest, new_digest, introduced_version = entry
        if (
            re.fullmatch(r"[0-9a-f]{64}", old_digest) is None
            or re.fullmatch(r"[0-9a-f]{64}", new_digest) is None
        ):
            raise HistoryError("launcher transition digest is invalid")
        version(introduced_version.encode("ascii"))
        transitions.append((old_digest, new_digest, introduced_version))
    if len(transitions) != len(set(transitions)):
        raise HistoryError("launcher transition is duplicated")
    return tuple(transitions)


def launcher_first_appearance(
    root: Path,
    digest: str,
) -> tuple[str | None, str, str]:
    commits = (
        git(root, "rev-list", "--first-parent", "--reverse", "HEAD")
        .decode("ascii")
        .splitlines()
    )
    for commit in commits:
        content = git(
            root,
            "show",
            f"{commit}:{STABLE_PATHS[0]}",
            check=False,
        )
        if content and sha256(content) == digest:
            parent = f"{commit}^"
            old_content = git(
                root,
                "show",
                f"{parent}:{STABLE_PATHS[0]}",
                check=False,
            )
            if not old_content:
                raise HistoryError("launcher transition has no previous launcher")
            introduced = git(root, "show", f"{commit}:cash-skills.version")
            return commit, sha256(old_content), introduced.decode("ascii").strip()
    head_content = git(root, "show", f"HEAD:{STABLE_PATHS[0]}")
    current_version = (root / "cash-skills.version").read_text(
        encoding="ascii"
    ).strip()
    return None, sha256(head_content), current_version


def check_launcher_history(
    root: Path,
    current_version: tuple[str, ...],
) -> None:
    launcher = root / STABLE_PATHS[0]
    introduction = path_introduction_commit(root, STABLE_PATHS[0])
    original = git(root, "show", f"{introduction}:{STABLE_PATHS[0]}")
    if (
        launcher.read_bytes() == original
        and current_mode(launcher) == tree_mode(root, introduction, STABLE_PATHS[0])
    ):
        return
    if current_mode(launcher) != 0o755:
        raise HistoryError("launcher Git mode changed outside an approved transition")
    new_digest = sha256(launcher.read_bytes())
    _, old_digest, introduced_version = launcher_first_appearance(root, new_digest)
    transition = (old_digest, new_digest, introduced_version)
    if transition not in launcher_transitions(root):
        raise HistoryError("launcher change is not an exact approved transition")
    if version_greater(
        version(introduced_version.encode("ascii")),
        current_version,
    ):
        raise HistoryError("launcher transition was introduced by a newer bundle")


def check_history(root: Path) -> None:
    current = version((root / "cash-skills.version").read_bytes())
    head_value = git(root, "show", "HEAD:cash-skills.version", check=False)
    if not head_value:
        raise HistoryError("HEAD has no cash-skills.version")
    head = version(head_value)
    paths = replaceable_paths(root)
    manifest = root / MANIFEST_PATH
    if (
        not manifest.is_file()
        or current_mode(manifest) != 0o644
        or manifest.read_bytes() != canonical_manifest_bytes(root)
    ):
        raise HistoryError("portable manifest is not canonical")
    head_tree = tree_paths(root, "HEAD")
    if STABLE_PATHS[1] in head_tree:
        assert_path_matches(
            root,
            path_introduction_commit(root, STABLE_PATHS[1]),
            STABLE_PATHS[1],
        )
    if STABLE_PATHS[0] in head_tree:
        check_launcher_history(root, current)
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
        write_launcher_transitions(root, ())
        for variant in (".agents", ".claude"):
            for skill in SKILLS:
                path = root / variant / "skills" / f"cash-{skill}" / "SKILL.md"
                path.parent.mkdir(parents=True)
                path.write_text(f"name: cash-{skill}\n", encoding="utf-8")
        write_canonical_manifest(root)
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
        write_canonical_manifest(root)
        check_history(root)

    def test_manifest_must_be_canonical_and_version_bound(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        manifest = root / MANIFEST_PATH
        manifest.write_bytes(
            manifest.read_bytes().replace(
                b"format\tcash-portable-manifest-v1\n",
                b"format\tcash-portable-manifest-v2\n",
            )
        )
        with self.assertRaisesRegex(HistoryError, "manifest"):
            check_history(root)

        write_canonical_manifest(root)
        (root / ".cash-skills" / "lib" / "cash_cli" / "main.py").write_text(
            "VALUE = 2\n",
            encoding="utf-8",
        )
        (root / "cash-skills.version").write_text("1.0.1\n", encoding="ascii")
        with self.assertRaisesRegex(HistoryError, "manifest"):
            check_history(root)

    def test_canonical_manifest_allows_versioned_inventory_change(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        (root / ".cash-skills" / "lib" / "cash_cli" / "main.py").write_text(
            "VALUE = 2\n",
            encoding="utf-8",
        )
        (root / "cash-skills.version").write_text("1.0.1\n", encoding="ascii")
        write_canonical_manifest(root)
        check_history(root)

    def test_exact_approved_launcher_transition_is_allowed(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        launcher = root / ".cash-skills" / "bin" / "cash"
        old_digest = sha256(launcher.read_bytes())
        launcher.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
        new_digest = sha256(launcher.read_bytes())
        write_launcher_transitions(root, ((old_digest, new_digest, "1.0.1"),))
        (root / "cash-skills.version").write_text("1.0.1\n", encoding="ascii")
        write_canonical_manifest(root)
        check_history(root)

    def test_launcher_transition_must_match_exact_digests_and_version(self) -> None:
        for field in ("old_digest", "new_digest", "introduced_version"):
            with self.subTest(field=field):
                temporary, root = self.make_repo()
                self.addCleanup(temporary.cleanup)
                launcher = root / ".cash-skills" / "bin" / "cash"
                old_digest = sha256(launcher.read_bytes())
                launcher.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
                new_digest = sha256(launcher.read_bytes())
                transition = {
                    "old_digest": ("0" * 64, new_digest, "1.0.1"),
                    "new_digest": (old_digest, "f" * 64, "1.0.1"),
                    "introduced_version": (old_digest, new_digest, "1.0.2"),
                }[field]
                write_launcher_transitions(root, (transition,))
                (root / "cash-skills.version").write_text(
                    "1.0.1\n",
                    encoding="ascii",
                )
                write_canonical_manifest(root)
                with self.assertRaises(HistoryError):
                    check_history(root)

    def test_launcher_introduced_version_must_match_first_new_bytes(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        launcher = root / ".cash-skills" / "bin" / "cash"
        old_digest = sha256(launcher.read_bytes())
        launcher.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
        new_digest = sha256(launcher.read_bytes())
        (root / "cash-skills.version").write_text("1.0.1\n", encoding="ascii")
        write_launcher_transitions(root, ())
        write_canonical_manifest(root)
        git(root, "add", ".")
        git(root, "commit", "-qm", "launcher bytes first appear")

        (root / "cash-skills.version").write_text("1.0.2\n", encoding="ascii")
        write_launcher_transitions(root, ((old_digest, new_digest, "1.0.2"),))
        write_canonical_manifest(root)
        with self.assertRaises(HistoryError):
            check_history(root)

    def test_workspace_lock_is_permanently_immutable(self) -> None:
        for drift in ("bytes", "mode"):
            with self.subTest(drift=drift):
                temporary, root = self.make_repo()
                self.addCleanup(temporary.cleanup)
                lock = root / ".cash-workspace.lock"
                if drift == "bytes":
                    lock.write_text("changed\n", encoding="utf-8")
                else:
                    os.chmod(lock, 0o600)
                (root / "cash-skills.version").write_text(
                    "1.0.1\n",
                    encoding="ascii",
                )
                write_canonical_manifest(root)
                with self.assertRaises(HistoryError):
                    check_history(root)

    def test_unapproved_launcher_drift_fails_even_with_version_bump(self) -> None:
        temporary, root = self.make_repo()
        self.addCleanup(temporary.cleanup)
        (root / ".cash-skills" / "bin" / "cash").write_text(
            "#!/bin/sh\nexit 1\n",
            encoding="utf-8",
        )
        (root / "cash-skills.version").write_text("1.0.1\n", encoding="ascii")
        write_canonical_manifest(root)
        with self.assertRaises(HistoryError):
            check_history(root)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(BundleHistoryTests)
    result = unittest.TextTestRunner().run(suite)
    if not result.wasSuccessful():
        raise SystemExit(1)
    check_history(Path(__file__).resolve().parents[3])
    print("PASS: bundle version history")
