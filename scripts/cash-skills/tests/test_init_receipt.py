from __future__ import annotations

import fcntl
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
INSTALLER = ROOT / "install-cash-skills.fish"
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
SKILL_PATHS = tuple(
    f"{variant}/skills/cash-{skill}/SKILL.md"
    for variant in (".agents", ".claude")
    for skill in SKILLS
)
RECEIPT_PATH = ".cash-skills/receipt.tsv"
MANIFEST_PATH = ".cash-skills/manifest.tsv"
INTERPRETER_FLAGS = ("-s", "-P", "-B")


class InitReceiptTests(unittest.TestCase):
    def make_installed_target(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        """An installed target that stands in for a fresh git clone of one."""
        temporary = tempfile.TemporaryDirectory()
        target = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(target)], check=True)
        (target / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (target / "openspec" / "changes" / "archive").mkdir()
        (target / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        installed = subprocess.run(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target)],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(installed.returncode, 0, installed.stderr)
        return temporary, target

    def make_source_copy(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        """A canonical source repository copy, receipt removed."""
        temporary = tempfile.TemporaryDirectory()
        source = Path(temporary.name)
        for relative in (
            "install-cash-skills.fish",
            "cash-skills.version",
            ".cash.yaml",
            ".cash-workspace.lock",
            "AGENTS.md",
            "CLAUDE.md",
            "CASH-SKILLS.md",
            "scripts/cash-skills/legacy-spectra-digests.tsv",
        ):
            destination = source / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        shutil.copytree(ROOT / ".cash-skills", source / ".cash-skills")
        for variant in (".agents", ".claude"):
            for skill in sorted((ROOT / variant / "skills").glob("cash-*")):
                shutil.copytree(skill, source / skill.relative_to(ROOT))
        (source / RECEIPT_PATH).unlink(missing_ok=True)
        shutil.rmtree(source / ".cash-skills" / "state", ignore_errors=True)
        (source / "openspec").mkdir()
        (source / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        os.chmod(source / "openspec" / "config.yaml", 0o644)
        subprocess.run(["git", "init", "-q", str(source)], check=True)
        return temporary, source

    def init(
        self,
        root: Path,
        *arguments: str,
        cwd: Path | None = None,
        relative_library: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment.pop("PYTHONDONTWRITEBYTECODE", None)
        environment["PYTHONPATH"] = (
            ".cash-skills/lib" if relative_library else str(root / ".cash-skills" / "lib")
        )
        # The documented isolation flags are part of what is under test: `-P`
        # keeps the target root off `sys.path`, `-B` keeps a failed run from
        # writing bytecode into the target.
        return subprocess.run(
            [sys.executable, *INTERPRETER_FLAGS, "-m", "cash_cli.installer", "--init-receipt", *arguments],
            cwd=str(cwd or root),
            text=True,
            capture_output=True,
            env=environment,
        )

    def launcher_result(self, target: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(target / ".cash-skills" / "bin" / "cash"), "list", "--json"],
            cwd=str(target),
            text=True,
            capture_output=True,
        )

    def self_install(
        self,
        source: Path,
        *arguments: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "fish",
                "--no-config",
                str(source / "install-cash-skills.fish"),
                "--self",
                *arguments,
            ],
            cwd=str(source),
            text=True,
            capture_output=True,
        )

    def receipt_state(self, root: Path) -> tuple[bytes, int, int, int]:
        receipt = root / RECEIPT_PATH
        metadata = receipt.stat()
        return (
            receipt.read_bytes(),
            stat.S_IMODE(metadata.st_mode),
            metadata.st_ino,
            metadata.st_mtime_ns,
        )

    def assert_no_temporaries(self, root: Path) -> None:
        residue = sorted(
            path.name
            for path in (root / ".cash-skills").iterdir()
            if path.name.startswith(".cash-install-")
        )
        self.assertEqual(residue, [])

    def assert_failure(
        self,
        result: subprocess.CompletedProcess[str],
        code: str,
    ) -> dict[str, str]:
        self.assertEqual(result.returncode, 1, result.stdout)
        document = json.loads(result.stdout)
        self.assertEqual(document["error"]["code"], code, result.stdout)
        return document["error"]

    def test_fresh_clone_initializes_a_launcher_valid_receipt(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        receipt = target / RECEIPT_PATH
        receipt.unlink()
        blocked = self.launcher_result(target)
        self.assertEqual(blocked.returncode, 1)
        self.assertIn('"code":"bootstrap_invalid"', blocked.stdout)

        result = self.init(target, relative_library=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "initialized\n")
        self.assertTrue(receipt.is_file())
        self.assertEqual(stat.S_IMODE(receipt.stat().st_mode), 0o644)
        rows = receipt.read_text(encoding="utf-8").splitlines()
        self.assertEqual(rows[0], f"version\t{self.bundle_version()}")
        self.assertRegex(rows[1], r"^runtime_generation\t[0-9a-f]{64}$")
        self.assertEqual(sum(row.startswith("stable\t") for row in rows), 2)
        self.assertGreater(sum(row.startswith("runtime\t") for row in rows), 0)
        self.assertEqual(sum(row.startswith("skill\t") for row in rows), 24)
        launched = self.launcher_result(target)
        self.assertEqual(launched.returncode, 0, launched.stderr)
        self.assertEqual(launched.stdout, '{"changes":[]}\n')
        self.assert_no_temporaries(target)

    def bundle_version(self) -> str:
        return (ROOT / "cash-skills.version").read_text(encoding="ascii").strip()

    def test_installed_receipt_is_reproduced_byte_for_byte(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        self.assertFalse((target / MANIFEST_PATH).exists())
        installed = self.receipt_state(target)

        result = self.init(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "current\n")
        self.assertEqual(self.receipt_state(target), installed)
        self.assertFalse((target / MANIFEST_PATH).exists())

    def test_repeated_initialization_is_current_and_zero_write(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()
        first = self.init(target)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(first.stdout, "initialized\n")
        before = self.receipt_state(target)

        repeated = self.init(target)

        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertEqual(repeated.stdout, "current\n")
        self.assertEqual(self.receipt_state(target), before)
        self.assert_no_temporaries(target)

    def test_umask_skewed_clone_is_normalized_and_signs(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()
        launcher = ".cash-skills/bin/cash"
        skewed = [(launcher, 0o775), (".cash-workspace.lock", 0o664)]
        skewed.extend((relative, 0o664) for relative in SKILL_PATHS)
        skewed.extend(
            (path.relative_to(target).as_posix(), 0o664)
            for path in (target / ".cash-skills" / "lib" / "cash_cli").rglob("*.py")
        )
        for relative, mode in skewed:
            os.chmod(target / relative, mode)

        result = self.init(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "initialized\n")
        for relative, _ in skewed:
            expected = 0o755 if relative == launcher else 0o644
            self.assertEqual(
                stat.S_IMODE((target / relative).stat().st_mode),
                expected,
                relative,
            )
        launched = self.launcher_result(target)
        self.assertEqual(launched.returncode, 0, launched.stderr)

    def test_outside_worktree_top_level_fails_closed(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()

        result = self.init(target, cwd=target / "openspec")

        self.assert_failure(result, "init_outside_worktree")
        self.assertFalse((target / RECEIPT_PATH).exists())
        self.assert_no_temporaries(target)

    def test_canonical_source_repository_is_rejected(self) -> None:
        temporary, source = self.make_source_copy()
        self.addCleanup(temporary.cleanup)

        result = self.init(source)

        error = self.assert_failure(result, "init_source_repo")
        self.assertIn("./install-cash-skills.fish --self", error["message"])
        self.assertFalse((source / RECEIPT_PATH).exists())

    def test_vendored_target_rejects_receipt_initialization_without_writes(self) -> None:
        for receipt_residue in (False, True):
            with self.subTest(receipt_residue=receipt_residue):
                temporary, target = self.make_installed_target()
                self.addCleanup(temporary.cleanup)
                receipt = target / RECEIPT_PATH
                if not receipt_residue:
                    receipt.unlink()
                    receipt_before = None
                else:
                    receipt_before = self.receipt_state(target)
                manifest = target / MANIFEST_PATH
                manifest.write_bytes(b"portable manifest marker\n")
                os.chmod(manifest, 0o644)
                manifest_before = (
                    manifest.read_bytes(),
                    stat.S_IMODE(manifest.stat().st_mode),
                    manifest.stat().st_ino,
                    manifest.stat().st_mtime_ns,
                )

                result = self.init(target)

                self.assert_failure(result, "init_vendored_bundle")
                self.assertEqual(
                    (
                        manifest.read_bytes(),
                        stat.S_IMODE(manifest.stat().st_mode),
                        manifest.stat().st_ino,
                        manifest.stat().st_mtime_ns,
                    ),
                    manifest_before,
                )
                if receipt_before is None:
                    self.assertFalse(receipt.exists())
                else:
                    self.assertEqual(self.receipt_state(target), receipt_before)
                self.assert_no_temporaries(target)

    def test_source_self_publishes_manifest_and_removes_receipt_residue(self) -> None:
        temporary, source = self.make_source_copy()
        self.addCleanup(temporary.cleanup)
        manifest = source / MANIFEST_PATH
        receipt = source / RECEIPT_PATH
        manifest.unlink()
        receipt.write_bytes(b"source receipt residue\n")
        os.chmod(receipt, 0o644)
        receipt_before = self.receipt_state(source)
        stable_paths = (
            source / ".cash-workspace.lock",
            source / ".cash-skills" / "bin" / "cash",
            source / ".agents" / "skills" / "cash-apply" / "SKILL.md",
        )
        stable_before = {
            path: (
                path.read_bytes(),
                stat.S_IMODE(path.stat().st_mode),
                path.stat().st_ino,
                path.stat().st_mtime_ns,
            )
            for path in stable_paths
        }

        dry_run = self.self_install(source, "--dry-run")

        self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
        self.assertIn("Result: would-bootstrap", dry_run.stdout)
        self.assertFalse(manifest.exists())
        self.assertEqual(self.receipt_state(source), receipt_before)

        bootstrapped = self.self_install(source)

        self.assertEqual(bootstrapped.returncode, 0, bootstrapped.stderr)
        self.assertIn("Result: bootstrap", bootstrapped.stdout)
        self.assertTrue(manifest.is_file())
        self.assertEqual(stat.S_IMODE(manifest.stat().st_mode), 0o644)
        self.assertFalse(receipt.exists())
        manifest_before = (
            manifest.read_bytes(),
            stat.S_IMODE(manifest.stat().st_mode),
            manifest.stat().st_ino,
            manifest.stat().st_mtime_ns,
        )

        current = self.self_install(source)

        self.assertEqual(current.returncode, 0, current.stderr)
        self.assertIn("Result: current", current.stdout)
        self.assertEqual(
            (
                manifest.read_bytes(),
                stat.S_IMODE(manifest.stat().st_mode),
                manifest.stat().st_ino,
                manifest.stat().st_mtime_ns,
            ),
            manifest_before,
        )
        self.assertFalse(receipt.exists())
        for path, before in stable_before.items():
            self.assertEqual(
                (
                    path.read_bytes(),
                    stat.S_IMODE(path.stat().st_mode),
                    path.stat().st_ino,
                    path.stat().st_mtime_ns,
                ),
                before,
            )

    def test_missing_or_invalid_openspec_config_fails_closed(self) -> None:
        for case in ("missing", "invalid"):
            with self.subTest(case=case):
                temporary, target = self.make_installed_target()
                self.addCleanup(temporary.cleanup)
                (target / RECEIPT_PATH).unlink()
                config = target / "openspec" / "config.yaml"
                if case == "missing":
                    config.unlink()
                else:
                    config.write_text("schema: unknown\n", encoding="utf-8")

                result = self.init(target)

                self.assert_failure(result, "init_config_invalid")
                self.assertFalse((target / RECEIPT_PATH).exists())
                if case == "invalid":
                    self.assertEqual(
                        config.read_text(encoding="utf-8"),
                        "schema: unknown\n",
                    )

    def test_missing_inventory_fails_closed(self) -> None:
        cases = (
            ("lock", ".cash-workspace.lock"),
            ("skill", SKILL_PATHS[0]),
            ("launcher", ".cash-skills/bin/cash"),
            ("runtime", ".cash-skills/lib/cash_cli/resources.py"),
        )
        for label, relative in cases:
            with self.subTest(case=label):
                temporary, target = self.make_installed_target()
                self.addCleanup(temporary.cleanup)
                (target / RECEIPT_PATH).unlink()
                (target / relative).unlink()

                result = self.init(target)

                error = self.assert_failure(result, "init_inventory_invalid")
                self.assertIn(relative, error["message"])
                self.assertFalse((target / RECEIPT_PATH).exists())

    def test_runtime_inventory_difference_fails_closed(self) -> None:
        # The expected runtime set must be independent of what is on disk;
        # deriving it from the same `rglob` makes the comparison vacuous and
        # signs a self-consistent but wrong receipt in both directions.
        cases = (
            ("missing", ".cash-skills/lib/cash_cli/spec_merge.py"),
            ("extra", ".cash-skills/lib/cash_cli/stray_helper.py"),
        )
        for label, relative in cases:
            with self.subTest(case=label):
                temporary, target = self.make_installed_target()
                self.addCleanup(temporary.cleanup)
                (target / RECEIPT_PATH).unlink()
                if label == "missing":
                    (target / relative).unlink()
                else:
                    (target / relative).write_text("HELPER = 1\n", encoding="utf-8")
                    os.chmod(target / relative, 0o644)

                result = self.init(target)

                error = self.assert_failure(result, "init_inventory_invalid")
                self.assertIn(relative, error["message"])
                self.assertFalse((target / RECEIPT_PATH).exists())
                self.assert_no_temporaries(target)

    def test_every_runtime_member_is_classified(self) -> None:
        # `installer` itself plus the `config`/`errors`/`main` chain reached
        # through `cash_cli/__init__.py` are import-time dependencies, so their
        # absence kills the `-m` load before any check can run. Asserting the
        # split keeps the asymmetry visible: a member silently moving between
        # the two groups fails here.
        sys.path.insert(0, str(ROOT / ".cash-skills" / "lib"))
        from cash_cli.installer import BUNDLE_RUNTIME_PATHS

        import_time = {
            ".cash-skills/lib/cash_cli/config.py",
            ".cash-skills/lib/cash_cli/errors.py",
            ".cash-skills/lib/cash_cli/installer.py",
            ".cash-skills/lib/cash_cli/main.py",
        }
        self.assertTrue(import_time <= set(BUNDLE_RUNTIME_PATHS))
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        held = Path(temporary.name).parent / "held-runtime-module.py"
        for relative in BUNDLE_RUNTIME_PATHS:
            with self.subTest(module=relative):
                (target / RECEIPT_PATH).unlink(missing_ok=True)
                (target / relative).rename(held)
                try:
                    result = self.init(target)
                finally:
                    held.rename(target / relative)
                    os.chmod(target / relative, 0o644)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertFalse((target / RECEIPT_PATH).exists())
                if relative in import_time:
                    self.assertEqual(result.stdout, "")
                    self.assertIn("No module named", result.stderr)
                else:
                    error = self.assert_failure(result, "init_inventory_invalid")
                    self.assertIn(relative, error["message"])

    def test_non_regular_managed_shape_fails_closed_without_chmod(self) -> None:
        # The skewed path precedes the unsafe one in receipt order, so the
        # assertion only holds when shape validation completes for the whole
        # inventory before the first chmod.
        for shape in ("symlink", "fifo", "hardlink"):
            with self.subTest(shape=shape):
                temporary, target = self.make_installed_target()
                self.addCleanup(temporary.cleanup)
                (target / RECEIPT_PATH).unlink()
                skewed = target / SKILL_PATHS[0]
                os.chmod(skewed, 0o664)
                unsafe = target / SKILL_PATHS[-1]
                unsafe.unlink()
                if shape == "symlink":
                    unsafe.symlink_to(skewed)
                elif shape == "fifo":
                    os.mkfifo(unsafe)
                else:
                    outside = target / "outside-skill.md"
                    outside.write_bytes(b"outside\n")
                    os.link(outside, unsafe)

                result = self.init(target)

                self.assert_failure(result, "init_inventory_invalid")
                self.assertFalse((target / RECEIPT_PATH).exists())
                self.assertEqual(stat.S_IMODE(skewed.stat().st_mode), 0o664)

    def test_umask_skewed_source_repository_is_rejected(self) -> None:
        temporary, source = self.make_source_copy()
        self.addCleanup(temporary.cleanup)
        for path in source.rglob("*"):
            if ".git" in path.relative_to(source).parts or not path.is_file():
                continue
            executable = stat.S_IMODE(path.stat().st_mode) & 0o100
            os.chmod(path, 0o775 if executable else 0o664)

        result = self.init(source)

        error = self.assert_failure(result, "init_source_repo")
        self.assertIn("./install-cash-skills.fish --self", error["message"])
        self.assertFalse((source / RECEIPT_PATH).exists())

    def test_non_regular_receipt_fails_closed_without_blocking(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        receipt = target / RECEIPT_PATH
        receipt.unlink()
        os.mkfifo(receipt)

        result = subprocess.run(
            [
                sys.executable,
                *INTERPRETER_FLAGS,
                "-m",
                "cash_cli.installer",
                "--init-receipt",
            ],
            cwd=str(target),
            text=True,
            capture_output=True,
            env={
                **os.environ,
                "PYTHONPATH": str(target / ".cash-skills" / "lib"),
            },
            timeout=30,
        )

        self.assert_failure(result, "init_write_failed")
        self.assertTrue(stat.S_ISFIFO(os.lstat(receipt).st_mode))

    def test_non_empty_stable_lock_fails_closed(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()
        lock = target / ".cash-workspace.lock"
        lock.write_bytes(b"junk\n")

        result = self.init(target)

        error = self.assert_failure(result, "init_inventory_invalid")
        self.assertIn(".cash-workspace.lock", error["message"])
        self.assertFalse((target / RECEIPT_PATH).exists())
        self.assertEqual(lock.read_bytes(), b"junk\n")

    def test_failed_initialization_writes_no_bytecode(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()

        result = self.init(target, cwd=target / "openspec")

        self.assert_failure(result, "init_outside_worktree")
        self.assertEqual(
            sorted(
                path.relative_to(target).as_posix()
                for path in target.rglob("__pycache__")
            ),
            [],
        )

    def test_documented_command_ignores_a_shadowing_module(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()
        (target / "uuid.py").write_text(
            "raise SystemExit('SHADOWED')\n",
            encoding="utf-8",
        )

        result = self.init(target, relative_library=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "initialized\n")
        self.assertNotIn("SHADOWED", result.stderr)

    def test_initialization_waits_for_the_stable_lock(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()
        environment = os.environ.copy()
        environment.pop("PYTHONDONTWRITEBYTECODE", None)
        environment["PYTHONPATH"] = str(target / ".cash-skills" / "lib")
        descriptor = os.open(target / ".cash-workspace.lock", os.O_RDWR)
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        process = subprocess.Popen(
            [sys.executable, *INTERPRETER_FLAGS, "-m", "cash_cli.installer", "--init-receipt"],
            cwd=str(target),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
        try:
            time.sleep(1.0)
            self.assertIsNone(process.poll())
            self.assertFalse((target / RECEIPT_PATH).exists())
        finally:
            fcntl.flock(descriptor, fcntl.LOCK_UN)
            os.close(descriptor)
        stdout, stderr = process.communicate(timeout=30)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertEqual(stdout, "initialized\n")
        self.assertTrue((target / RECEIPT_PATH).is_file())
        self.assert_no_temporaries(target)

    def test_manifest_published_while_waiting_for_lock_rejects_without_writes(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        receipt = target / RECEIPT_PATH
        receipt.unlink()
        skewed = target / SKILL_PATHS[0]
        os.chmod(skewed, 0o664)
        environment = os.environ.copy()
        environment.pop("PYTHONDONTWRITEBYTECODE", None)
        environment["PYTHONPATH"] = str(target / ".cash-skills" / "lib")
        descriptor = os.open(target / ".cash-workspace.lock", os.O_RDWR)
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        process = subprocess.Popen(
            [sys.executable, *INTERPRETER_FLAGS, "-m", "cash_cli.installer", "--init-receipt"],
            cwd=str(target),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
        try:
            time.sleep(1.0)
            self.assertIsNone(process.poll())
            manifest = target / MANIFEST_PATH
            manifest.write_bytes(b"concurrently published manifest\n")
            os.chmod(manifest, 0o644)
        finally:
            fcntl.flock(descriptor, fcntl.LOCK_UN)
            os.close(descriptor)
        stdout, stderr = process.communicate(timeout=30)
        result = subprocess.CompletedProcess(process.args, process.returncode, stdout, stderr)

        self.assert_failure(result, "init_vendored_bundle")
        self.assertFalse(receipt.exists())
        self.assertEqual(stat.S_IMODE(skewed.stat().st_mode), 0o664)
        self.assert_no_temporaries(target)

    def test_init_receipt_is_mutually_exclusive_with_other_modes(self) -> None:
        temporary, target = self.make_installed_target()
        self.addCleanup(temporary.cleanup)
        (target / RECEIPT_PATH).unlink()
        for arguments in (
            ("--self",),
            ("--all",),
            ("--list",),
            ("--target", str(target)),
            ("--register", str(target)),
            ("--unregister", str(target)),
            ("--force",),
            ("--dry-run",),
        ):
            with self.subTest(arguments=arguments):
                result = self.init(target, *arguments)

                self.assertEqual(result.returncode, 2, result.stdout)
                self.assertFalse((target / RECEIPT_PATH).exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
