from __future__ import annotations

import base64
import json
import os
import fcntl
import hashlib
import shlex
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


class InstallerRuntimeTests(unittest.TestCase):
    def make_target(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary = tempfile.TemporaryDirectory()
        target = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(target)], check=True)
        (target / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (target / "openspec" / "changes" / "archive").mkdir()
        (target / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        return temporary, target

    def install(
        self,
        target: Path,
        *arguments: str,
        timeout: float | None = None,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        environment = {
            name: value
            for name, value in os.environ.items()
            if not name.startswith("CASH_INSTALL_")
            and not name.startswith("TEST_CASH_INSTALL_")
        }
        requested = dict(env or {})
        for name in tuple(requested):
            if name.startswith("TEST_CASH_INSTALL_"):
                requested[name.removeprefix("TEST_")] = requested.pop(name)
        environment.update(requested)
        return subprocess.run(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target), *arguments],
            cwd=ROOT,
            text=True,
            capture_output=True,
            env=environment,
            timeout=timeout,
        )

    def run_installer(
        self,
        arguments: list[str],
        *,
        home: Path,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        environment = {
            name: value
            for name, value in os.environ.items()
            if not name.startswith("CASH_INSTALL_")
            and not name.startswith("TEST_CASH_INSTALL_")
        }
        environment["HOME"] = str(home)
        environment.update(env or {})
        return subprocess.run(
            ["fish", "--no-config", str(INSTALLER), *arguments],
            cwd=ROOT,
            text=True,
            capture_output=True,
            env=environment,
        )

    def install_from(
        self,
        source: Path,
        target: Path,
        *arguments: str,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        environment = {
            name: value
            for name, value in os.environ.items()
            if not name.startswith("CASH_INSTALL_")
            and not name.startswith("TEST_CASH_INSTALL_")
        }
        environment.update(env or {})
        return subprocess.run(
            [
                "fish",
                "--no-config",
                str(source / "install-cash-skills.fish"),
                "--target",
                str(target),
                *arguments,
            ],
            cwd=source,
            text=True,
            capture_output=True,
            env=environment,
        )

    def make_source_bundle(
        self,
    ) -> tuple[tempfile.TemporaryDirectory[str], Path, dict[str, bytes]]:
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
        ):
            destination = source / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        shutil.copytree(ROOT / ".cash-skills", source / ".cash-skills")
        for variant in (".agents", ".claude"):
            for cash_skill in sorted((ROOT / variant / "skills").glob("cash-*")):
                shutil.copytree(
                    cash_skill,
                    source / cash_skill.relative_to(ROOT),
                )
        bodies: dict[str, bytes] = {}
        manifest = ["version\t1"]
        for variant in (".agents", ".claude"):
            for skill in (
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
            ):
                relative = f"{variant}/skills/spectra-{skill}"
                body = f"legacy baseline: {relative}\n".encode()
                bodies[relative] = body
                manifest.append(
                    f"skill\t{relative}\t{hashlib.sha256(body).hexdigest()}"
                )
        manifest_path = source / "scripts" / "cash-skills" / "legacy-spectra-digests.tsv"
        manifest_path.parent.mkdir(parents=True)
        manifest_path.write_text("\n".join(manifest) + "\n", encoding="utf-8")
        os.chmod(manifest_path, 0o644)
        return temporary, source, bodies

    def make_self_source(
        self,
    ) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary, source, _ = self.make_source_bundle()
        (source / ".cash-skills" / "receipt.tsv").unlink(missing_ok=True)
        shutil.rmtree(source / ".cash-skills" / "state", ignore_errors=True)
        (source / "openspec").mkdir()
        (source / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        (source / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (source / "openspec" / "changes" / "archive").mkdir()
        subprocess.run(["git", "init", "-q", str(source)], check=True)
        return temporary, source

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
            cwd=source,
            text=True,
            capture_output=True,
        )

    def seed_legacy_baselines(self, target: Path, bodies: dict[str, bytes]) -> None:
        for relative, body in bodies.items():
            skill = target / relative / "SKILL.md"
            skill.parent.mkdir(parents=True)
            skill.write_bytes(body)
            os.chmod(skill, 0o644)

    def copy_skills(self, target: Path) -> list[tuple[str, str]]:
        records: list[tuple[str, str]] = []
        for variant in (".agents", ".claude"):
            for source in sorted((ROOT / variant / "skills").glob("cash-*/SKILL.md")):
                relative = source.relative_to(ROOT)
                destination = target / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, destination)
                os.chmod(destination, 0o644)
                records.append(
                    (
                        relative.as_posix(),
                        hashlib.sha256(source.read_bytes()).hexdigest(),
                    )
                )
        return records

    def seed_publishing_journal(
        self,
        target: Path,
        operations: list[tuple[str, bytes | None, int, bytes]],
        *,
        version: int = 2,
    ) -> Path:
        rows = []
        for relative, before, mode, published in operations:
            path = target / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(published)
            os.chmod(path, mode)
            rows.append(
                {
                    "kind": "write",
                    "path": relative,
                    "exists": before is not None,
                    "content": (
                        base64.b64encode(before).decode("ascii")
                        if before is not None
                        else None
                    ),
                    "mode": mode if before is not None else None,
                }
            )
        journal = target / ".cash-skills" / "state" / "installer" / "journal.json"
        journal.parent.mkdir(parents=True, exist_ok=True)
        journal.write_text(
            json.dumps(
                {
                    "version": version,
                    "phase": "publishing",
                    "published": len(rows),
                    "operations": rows,
                },
                separators=(",", ":"),
            )
            + "\n",
            encoding="utf-8",
        )
        os.chmod(journal, 0o600)
        return journal

    def make_python_shim(
        self,
        directory: Path,
        name: str,
        *,
        qualified: bool,
        marker: Path | None = None,
        pid_marker: Path | None = None,
    ) -> None:
        shim = directory / name
        selected = (
            f"printf '%s\\n' {shlex.quote(name)} > {shlex.quote(str(marker))}\n"
            if marker is not None
            else ""
        )
        pid_selected = (
            f"printf '%s\\n' $$ > {shlex.quote(str(pid_marker))}\n"
            if pid_marker is not None
            else ""
        )
        shim.write_text(
            "#!/bin/sh\n"
            "is_probe=0\n"
            'for argument in "$@"; do\n'
            '  if [ "$argument" = "-c" ]; then is_probe=1; fi\n'
            "done\n"
            f"if [ \"$is_probe\" = 1 ] && [ {1 if qualified else 0} = 0 ]; then\n"
            "  exit 1\n"
            "fi\n"
            'if [ "$is_probe" = 0 ]; then\n'
            f"{selected}"
            f"{pid_selected}"
            "fi\n"
            f"exec {shlex.quote(sys.executable)} \"$@\"\n",
            encoding="utf-8",
        )
        os.chmod(shim, 0o755)

    def test_fresh_install_receipt_and_direct_launcher(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: update", result.stdout)
        launcher = target / ".cash-skills" / "bin" / "cash"
        lock = target / ".cash-workspace.lock"
        self.assertEqual(stat.S_IMODE(launcher.stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE(lock.stat().st_mode), 0o644)
        receipt = (target / ".cash-skills" / "receipt.tsv").read_text(encoding="utf-8")
        rows = receipt.splitlines()
        self.assertTrue(rows[0].startswith("version\t"))
        self.assertRegex(rows[1], r"^runtime_generation\t[0-9a-f]{64}$")
        self.assertEqual(sum(row.startswith("stable\t") for row in rows), 2)
        self.assertGreater(sum(row.startswith("runtime\t") for row in rows), 0)
        self.assertEqual(sum(row.startswith("skill\t") for row in rows), 24)
        self.assertIn(f"\t{lock.stat().st_dev}\t{lock.stat().st_ino}", receipt)
        launched = subprocess.run(
            [str(launcher), "list", "--json"],
            cwd=target / "openspec",
            text=True,
            capture_output=True,
        )
        self.assertEqual(launched.returncode, 0, launched.stderr)
        self.assertEqual(launched.stdout, '{"changes":[]}\n')

    def test_fresh_target_receives_version_control_exclusions(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        gitignore = target / ".gitignore"
        self.assertEqual(
            gitignore.read_bytes(),
            b".cash-skills/receipt.tsv\n.cash-skills/state/\n__pycache__/\n",
        )
        self.assertEqual(stat.S_IMODE(gitignore.stat().st_mode), 0o644)
        ignored = subprocess.run(
            [
                "git",
                "-C",
                str(target),
                "check-ignore",
                "--",
                ".cash-skills/receipt.tsv",
                ".cash-skills/state/installer/journal.json",
            ],
            text=True,
            capture_output=True,
        )
        self.assertEqual(
            ignored.stdout.splitlines(),
            [".cash-skills/receipt.tsv", ".cash-skills/state/installer/journal.json"],
        )

    def test_existing_gitignore_keeps_bytes_and_appends_only_missing_rules(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        gitignore = target / ".gitignore"
        existing = b"# project rules\nnode_modules\n\n__pycache__/\n"
        gitignore.write_bytes(existing)
        os.chmod(gitignore, 0o600)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            gitignore.read_bytes(),
            existing + b".cash-skills/receipt.tsv\n.cash-skills/state/\n",
        )
        self.assertEqual(stat.S_IMODE(gitignore.stat().st_mode), 0o600)

    def test_gitignore_append_preserves_line_terminators_and_encoding(self) -> None:
        rules = (
            b".cash-skills/receipt.tsv",
            b".cash-skills/state/",
            b"__pycache__/",
        )
        cases = (
            ("no-trailing-terminator", b"node_modules", b"\n"),
            ("empty-file", b"", b"\n"),
            ("single-line-no-terminator", b"build", b"\n"),
            ("crlf", b"node_modules\r\nbuild\r\n", b"\r\n"),
            ("non-utf8-pathname", b"caf\xe9/**\n", b"\n"),
            ("equivalent-spellings", b".cash-skills/\n.cash-skills/state\n", b"\n"),
            ("rooted-and-glob", b"/.cash-skills/state/\n*.tsv\n", b"\n"),
        )
        for label, existing, terminator in cases:
            with self.subTest(case=label):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                gitignore = target / ".gitignore"
                gitignore.write_bytes(existing)
                separator = b"" if not existing or existing.endswith(b"\n") else terminator

                result = self.install(target)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    gitignore.read_bytes(),
                    existing
                    + separator
                    + b"".join(rule + terminator for rule in rules),
                )

    def test_gitignore_unsafe_shapes_fail_closed_before_any_write(self) -> None:
        for shape in ("symlink", "directory", "hardlink", "fifo"):
            for arguments in ((), ("--force",)):
                with self.subTest(shape=shape, arguments=arguments):
                    temporary, target = self.make_target()
                    self.addCleanup(temporary.cleanup)
                    gitignore = target / ".gitignore"
                    if shape == "symlink":
                        outside = target / "outside-rules"
                        outside.write_bytes(b"node_modules\n")
                        gitignore.symlink_to(outside)
                    elif shape == "directory":
                        gitignore.mkdir()
                    elif shape == "fifo":
                        os.mkfifo(gitignore)
                    else:
                        original = target / "original-rules"
                        original.write_bytes(b"node_modules\n")
                        os.link(original, gitignore)

                    # A FIFO must fail closed rather than block on open, so the
                    # timeout is part of the assertion.
                    result = self.install(target, *arguments, timeout=60)

                    self.assertEqual(result.returncode, 1, result.stdout)
                    self.assertIn(".gitignore", result.stderr)
                    self.assertFalse((target / ".cash-workspace.lock").exists())
                    self.assertFalse((target / ".cash-skills").exists())
                    self.assertFalse((target / ".cash.yaml").exists())

    def test_complete_gitignore_rules_are_zero_write_and_current(self) -> None:
        seeds = (
            ("installed-lf", None),
            (
                "seeded-crlf",
                b"node_modules\r\n.cash-skills/receipt.tsv\r\n"
                b".cash-skills/state/\r\n__pycache__/\r\n",
            ),
        )
        for label, seed in seeds:
            with self.subTest(case=label):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                gitignore = target / ".gitignore"
                if seed is not None:
                    gitignore.write_bytes(seed)
                self.assertEqual(self.install(target).returncode, 0)
                if seed is not None:
                    self.assertEqual(gitignore.read_bytes(), seed)
                before = (
                    gitignore.read_bytes(),
                    gitignore.stat().st_ino,
                    gitignore.stat().st_mtime_ns,
                )

                result = self.install(target)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Result: current", result.stdout)
                self.assertEqual(
                    (
                        gitignore.read_bytes(),
                        gitignore.stat().st_ino,
                        gitignore.stat().st_mtime_ns,
                    ),
                    before,
                )

    def test_gitignore_dry_run_is_zero_write(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        gitignore = target / ".gitignore"
        gitignore.write_bytes(b"node_modules\n")
        before = (gitignore.read_bytes(), gitignore.stat().st_mtime_ns)

        result = self.install(target, "--dry-run")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: update", result.stdout)
        self.assertEqual(
            (gitignore.read_bytes(), gitignore.stat().st_mtime_ns),
            before,
        )

    def test_publication_failure_rolls_back_the_gitignore_operation(self) -> None:
        for label, existing in (("created", None), ("appended", b"node_modules\n")):
            with self.subTest(case=label):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                gitignore = target / ".gitignore"
                if existing is not None:
                    gitignore.write_bytes(existing)

                result = self.install(
                    target,
                    env={
                        "TEST_CASH_INSTALL_TEST_HOOKS": "1",
                        "TEST_CASH_INSTALL_FAIL_AFTER_PATH": ".gitignore",
                    },
                )

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(".gitignore", result.stderr)
                if existing is None:
                    self.assertFalse(gitignore.exists())
                else:
                    self.assertEqual(gitignore.read_bytes(), existing)
                self.assertFalse((target / ".cash-skills" / "receipt.tsv").exists())
                self.assertFalse((target / ".cash-skills" / "state").exists())

    def test_version_controlled_receipt_is_reported_without_index_changes(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        subprocess.run(
            ["git", "-C", str(target), "config", "user.email", "test@example.com"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(target), "config", "user.name", "Test"],
            check=True,
        )
        self.assertEqual(self.install(target).returncode, 0)
        subprocess.run(
            ["git", "-C", str(target), "add", "-f", "--", ".cash-skills/receipt.tsv"],
            check=True,
        )
        index = target / ".git" / "index"
        before = index.read_bytes()

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: current", result.stdout)
        self.assertIn(".cash-skills/receipt.tsv is tracked by version control", result.stderr)
        self.assertIn("git rm --cached .cash-skills/receipt.tsv", result.stderr)
        self.assertNotIn("tracked by version control", result.stdout)
        self.assertEqual(index.read_bytes(), before)

    def test_receipt_diagnostic_is_one_line_per_target_across_reclassification(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        subprocess.run(
            ["git", "-C", str(target), "config", "user.email", "test@example.com"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(target), "config", "user.name", "Test"],
            check=True,
        )
        self.assertEqual(self.install(target).returncode, 0)
        subprocess.run(
            ["git", "-C", str(target), "add", "-f", "--", ".cash-skills/receipt.tsv"],
            check=True,
        )
        gitignore = target / ".gitignore"
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            gitignore.write_bytes(b"concurrent\n")
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn("Result: update", stdout)
        self.assertEqual(
            gitignore.read_bytes(),
            b"concurrent\n.cash-skills/receipt.tsv\n.cash-skills/state/\n__pycache__/\n",
        )
        self.assertEqual(stderr.count("is tracked by version control"), 1, stderr)

    def test_receipt_diagnostic_does_not_run_repository_configured_programs(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        hook = target / "fsmonitor-hook.sh"
        hook.write_text(
            "#!/bin/sh\necho FSMONITOR-HOOK-EXECUTED >&2\nexit 1\n",
            encoding="utf-8",
        )
        os.chmod(hook, 0o755)
        subprocess.run(
            ["git", "-C", str(target), "config", "core.fsmonitor", "./fsmonitor-hook.sh"],
            check=True,
        )

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("FSMONITOR-HOOK-EXECUTED", result.stderr)
        self.assertNotIn("FSMONITOR-HOOK-EXECUTED", result.stdout)

    def test_untracked_and_unqueryable_targets_report_no_receipt_diagnostic(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)

        untracked = self.install(target)

        self.assertEqual(untracked.returncode, 0, untracked.stderr)
        self.assertIn("Result: current", untracked.stdout)
        self.assertNotIn("tracked by version control", untracked.stderr)

        (target / ".git" / "index").write_bytes(b"not an index\n")

        unqueryable = self.install(target)

        self.assertEqual(unqueryable.returncode, 0, unqueryable.stderr)
        self.assertIn("Result: current", unqueryable.stdout)
        self.assertNotIn("tracked by version control", unqueryable.stderr)

    def test_second_install_is_current_and_preserves_stable_inodes(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        launcher = target / ".cash-skills" / "bin" / "cash"
        lock = target / ".cash-workspace.lock"
        identities = (launcher.stat().st_ino, lock.stat().st_ino)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: current", result.stdout)
        self.assertEqual((launcher.stat().st_ino, lock.stat().st_ino), identities)

    def test_source_self_bootstrap_is_actionable_and_idempotent(self) -> None:
        temporary, source = self.make_self_source()
        self.addCleanup(temporary.cleanup)
        launcher = source / ".cash-skills" / "bin" / "cash"
        receipt = source / ".cash-skills" / "receipt.tsv"
        managed = (
            source / ".cash-workspace.lock",
            launcher,
            source / ".cash.yaml",
            source / ".agents" / "skills" / "cash-apply" / "SKILL.md",
        )
        before = {
            path: (path.read_bytes(), stat.S_IMODE(path.stat().st_mode), path.stat().st_ino)
            for path in managed
        }

        json_failure = subprocess.run(
            [str(launcher), "list", "--json"],
            cwd=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(json_failure.returncode, 1)
        self.assertIn('"code":"bootstrap_invalid"', json_failure.stdout)
        self.assertIn("./install-cash-skills.fish --self", json_failure.stdout)
        text_failure = subprocess.run(
            [str(launcher), "list"],
            cwd=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(text_failure.returncode, 1)
        self.assertIn("./install-cash-skills.fish --self", text_failure.stderr)

        dry_run = self.self_install(source, "--dry-run")
        self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
        self.assertIn("Result: would-bootstrap", dry_run.stdout)
        self.assertFalse(receipt.exists())

        bootstrapped = self.self_install(source)
        self.assertEqual(bootstrapped.returncode, 0, bootstrapped.stderr)
        self.assertIn("Result: bootstrap", bootstrapped.stdout)
        self.assertTrue(receipt.is_file())
        expected_receipt = receipt.read_bytes()
        receipt.write_text("version\tbroken\n", encoding="utf-8")
        invalid = subprocess.run(
            [str(launcher), "list", "--json"],
            cwd=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(invalid.returncode, 1)
        self.assertIn('"code":"receipt_invalid"', invalid.stdout)
        self.assertIn("./install-cash-skills.fish --self", invalid.stdout)
        repaired = self.self_install(source)
        self.assertEqual(repaired.returncode, 0, repaired.stderr)
        self.assertIn("Result: bootstrap", repaired.stdout)
        self.assertEqual(receipt.read_bytes(), expected_receipt)
        first_receipt = (
            receipt.read_bytes(),
            stat.S_IMODE(receipt.stat().st_mode),
            receipt.stat().st_ino,
        )
        validated = subprocess.run(
            [str(launcher), "validate", "--all", "--json"],
            cwd=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(validated.returncode, 0, validated.stderr)
        self.assertEqual(
            validated.stdout,
            '{"valid":true,"changes":[],"findings":[]}\n',
        )

        current = self.self_install(source)
        self.assertEqual(current.returncode, 0, current.stderr)
        self.assertIn("Result: current", current.stdout)
        self.assertEqual(
            (
                receipt.read_bytes(),
                stat.S_IMODE(receipt.stat().st_mode),
                receipt.stat().st_ino,
            ),
            first_receipt,
        )
        for path, snapshot in before.items():
            self.assertEqual(
                (path.read_bytes(), stat.S_IMODE(path.stat().st_mode), path.stat().st_ino),
                snapshot,
            )
        self.assertFalse((source / ".cash-skills" / "state").exists())
        receipt.unlink()
        self.assertFalse(receipt.exists())

    def test_source_self_rejects_unsafe_boundary_and_incompatible_modes(self) -> None:
        for arguments in (
            ("--force",),
            ("--target", "/tmp/not-used"),
            ("--all",),
            ("--list",),
        ):
            with self.subTest(arguments=arguments):
                temporary, source = self.make_self_source()
                self.addCleanup(temporary.cleanup)
                result = self.self_install(source, *arguments)
                self.assertEqual(result.returncode, 2)
                self.assertFalse((source / ".cash-skills" / "receipt.tsv").exists())

        temporary, source = self.make_self_source()
        self.addCleanup(temporary.cleanup)
        source_override = self.self_install(source, "--source", source.as_posix())
        self.assertEqual(source_override.returncode, 2)
        self.assertFalse((source / ".cash-skills" / "receipt.tsv").exists())

        temporary, source = self.make_self_source()
        self.addCleanup(temporary.cleanup)
        os.chmod(source / ".cash-workspace.lock", 0o600)
        unsafe = self.self_install(source)
        self.assertEqual(unsafe.returncode, 1)
        self.assertIn(".cash-workspace.lock", unsafe.stderr)
        self.assertFalse((source / ".cash-skills" / "receipt.tsv").exists())

    def test_source_self_ignores_hostile_cwd_python_module(self) -> None:
        temporary, source = self.make_self_source()
        hostile = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(hostile.cleanup)
        hostile_root = Path(hostile.name)
        hostile_package = hostile_root / "cash_cli"
        hostile_package.mkdir()
        (hostile_package / "__init__.py").write_text("", encoding="utf-8")
        (hostile_package / "installer.py").write_text(
            "print('SHADOWED')\n",
            encoding="utf-8",
        )

        result = subprocess.run(
            [
                "fish",
                "--no-config",
                str(source / "install-cash-skills.fish"),
                "--self",
                "--dry-run",
            ],
            cwd=hostile_root,
            text=True,
            capture_output=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: would-bootstrap", result.stdout)
        self.assertNotIn("SHADOWED", result.stdout)
        self.assertFalse((source / ".cash-skills" / "receipt.tsv").exists())

    def test_entrypoint_falls_back_to_versioned_python_and_prefers_generic_name(self) -> None:
        candidates = (
            "python3",
            "python",
            "python3.14",
            "python3.13",
            "python3.12",
            "python3.11",
        )
        for case, qualified, expected in (
            ("versioned-fallback", {"python3.14"}, "python3.14"),
            ("generic-preferred", {"python3", "python3.14"}, "python3"),
        ):
            with self.subTest(case=case):
                temporary, target = self.make_target()
                shims = tempfile.TemporaryDirectory()
                self.addCleanup(temporary.cleanup)
                self.addCleanup(shims.cleanup)
                shim_dir = Path(shims.name)
                marker = shim_dir / "selected"
                for candidate in candidates:
                    self.make_python_shim(
                        shim_dir,
                        candidate,
                        qualified=candidate in qualified,
                        marker=marker,
                    )
                fish_dir = Path(shutil.which("fish") or "/usr/bin/fish").parent
                environment = os.environ.copy()
                environment["PATH"] = (
                    f"{shim_dir}{os.pathsep}{fish_dir}{os.pathsep}/usr/bin:/bin"
                )

                result = subprocess.run(
                    [
                        "fish",
                        "--no-config",
                        str(INSTALLER),
                        "--target",
                        str(target),
                    ],
                    cwd=ROOT,
                    text=True,
                    capture_output=True,
                    env=environment,
                )

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(marker.read_text(encoding="utf-8"), f"{expected}\n")

    def test_entrypoint_rejects_when_no_candidate_meets_minimum_version(self) -> None:
        temporary, target = self.make_target()
        shims = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(shims.cleanup)
        shim_dir = Path(shims.name)
        for candidate in (
            "python3",
            "python",
            "python3.14",
            "python3.13",
            "python3.12",
            "python3.11",
        ):
            self.make_python_shim(shim_dir, candidate, qualified=False)
        fish_dir = Path(shutil.which("fish") or "/usr/bin/fish").parent
        environment = os.environ.copy()
        environment["PATH"] = (
            f"{shim_dir}{os.pathsep}{fish_dir}{os.pathsep}/usr/bin:/bin"
        )

        result = subprocess.run(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            env=environment,
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("requires Python 3.11+", result.stderr)
        self.assertFalse((target / ".cash-workspace.lock").exists())
        self.assertFalse((target / ".cash-skills").exists())

    def test_entrypoint_execs_python_and_disables_user_site(self) -> None:
        temporary, target = self.make_target()
        shims = tempfile.TemporaryDirectory()
        hold = tempfile.TemporaryDirectory()
        user_base = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(shims.cleanup)
        self.addCleanup(hold.cleanup)
        self.addCleanup(user_base.cleanup)
        shim_dir = Path(shims.name)
        interpreter_pid = shim_dir / "interpreter-pid"
        self.make_python_shim(
            shim_dir,
            "python3",
            qualified=True,
            pid_marker=interpreter_pid,
        )
        for candidate in (
            "python",
            "python3.14",
            "python3.13",
            "python3.12",
            "python3.11",
        ):
            self.make_python_shim(shim_dir, candidate, qualified=False)
        side_effect = Path(user_base.name) / "user-site-loaded"
        site_environment = os.environ.copy()
        site_environment["PYTHONUSERBASE"] = user_base.name
        discovered_site = subprocess.run(
            [
                sys.executable,
                "-s",
                "-P",
                "-c",
                "import site; print(site.getusersitepackages())",
            ],
            text=True,
            capture_output=True,
            check=True,
            env=site_environment,
        )
        site_packages = Path(discovered_site.stdout.strip())
        site_packages.mkdir(parents=True)
        (site_packages / "usercustomize.py").write_text(
            "from pathlib import Path\n"
            f"Path({str(side_effect)!r}).touch()\n"
            "print('PROBE_USERCUSTOMIZE_RAN')\n",
            encoding="utf-8",
        )
        hold_path = Path(hold.name) / "entrypoint"
        fish_dir = Path(shutil.which("fish") or "/usr/bin/fish").parent
        environment = os.environ.copy()
        environment.update(
            {
                "PATH": (
                    f"{shim_dir}{os.pathsep}{fish_dir}{os.pathsep}/usr/bin:/bin"
                ),
                "PYTHONUSERBASE": user_base.name,
                "CASH_INSTALL_TEST_HOOKS": "1",
                "CASH_INSTALL_HOLD_FILE": str(hold_path),
            }
        )
        process = subprocess.Popen(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
        deadline = time.monotonic() + 10
        while not Path(f"{hold_path}.ready").exists():
            self.assertIsNone(process.poll())
            self.assertLess(time.monotonic(), deadline)
            time.sleep(0.01)
        Path(f"{hold_path}.release").touch()
        stdout, stderr = process.communicate(timeout=10)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn("Result: update", stdout)
        self.assertEqual(
            int(interpreter_pid.read_text(encoding="utf-8")),
            process.pid,
        )
        self.assertFalse(side_effect.exists())
        self.assertNotIn("PROBE_USERCUSTOMIZE_RAN", stdout)

    def test_source_self_revalidates_openspec_config_after_lock_wait(self) -> None:
        temporary, source = self.make_self_source()
        self.addCleanup(temporary.cleanup)
        lock_descriptor = os.open(source / ".cash-workspace.lock", os.O_RDWR)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(source / "install-cash-skills.fish"),
                "--self",
            ],
            cwd=source,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            (source / "openspec" / "config.yaml").write_text(
                "schema: invalid\n",
                encoding="utf-8",
            )
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 1, stdout)
        self.assertIn("invalid target openspec/config.yaml", stderr)
        self.assertFalse((source / ".cash-skills" / "receipt.tsv").exists())

    def test_supported_legacy_config_migrates_without_deletion(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        legacy = target / ".spectra.yaml"
        legacy.write_text(
            "locale: tw\ntdd: true\naudit: false\nparallel_tasks: true\nspec_dir: openspec\n",
            encoding="utf-8",
        )

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(legacy.is_file())
        self.assertEqual(
            (target / ".cash.yaml").read_text(encoding="utf-8"),
            "locale: tw\ntdd: true\naudit: false\nparallel_tasks: true\n",
        )

    def test_commented_legacy_config_template_migrates(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        legacy = target / ".spectra.yaml"
        legacy.write_text(
            "# Spectra application config\n"
            "# See: https://github.com/spectra-app/spectra\n"
            "\n"
            "# OpenSpec directory path (relative to project root)\n"
            "# spec_dir: docs/specs\n"
            "\n"
            "# Language for AI-generated artifacts\n"
            "locale: tw\n"
            "\n"
            "# Workflow toggles\n"
            "tdd: true\n"
            "audit: true\n"
            "parallel_tasks: true\n"
            "\n"
            "# Claude Code skill effort levels (low/medium/high/max)\n"
            "# claude_effort:\n"
            "#   apply: high\n",
            encoding="utf-8",
        )

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(legacy.is_file())
        self.assertEqual(
            (target / ".cash.yaml").read_text(encoding="utf-8"),
            "locale: tw\ntdd: true\naudit: true\nparallel_tasks: true\n",
        )

    def test_existing_cash_config_is_preserved_byte_for_byte(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        content = b"locale: en\ntdd: false\naudit: true\nparallel_tasks: false\n"
        (target / ".cash.yaml").write_bytes(content)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((target / ".cash.yaml").read_bytes(), content)

    def test_non_git_target_fails_without_publication(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        target = Path(temporary.name)
        (target / "openspec").mkdir()
        (target / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )

        result = self.install(target)

        self.assertEqual(result.returncode, 1)
        self.assertFalse((target / ".cash-workspace.lock").exists())
        self.assertFalse((target / ".cash-skills").exists())

    def test_invalid_cash_config_fails_before_stable_prefix(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        (target / ".cash.yaml").write_text("unknown: true\n", encoding="utf-8")

        result = self.install(target)

        self.assertEqual(result.returncode, 1)
        self.assertFalse((target / ".cash-workspace.lock").exists())
        self.assertFalse((target / ".cash-skills").exists())

    def test_dry_run_is_zero_write(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        before = sorted(path.relative_to(target).as_posix() for path in target.rglob("*"))

        result = self.install(target, "--dry-run")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: update", result.stdout)
        after = sorted(path.relative_to(target).as_posix() for path in target.rglob("*"))
        self.assertEqual(after, before)

    def test_receipt_less_full_skill_inventory_is_adopted_without_replacement(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.copy_skills(target)
        sample = target / ".agents" / "skills" / "cash-apply" / "SKILL.md"
        inode = sample.stat().st_ino

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sample.stat().st_ino, inode)
        self.assertTrue((target / ".cash-skills" / "receipt.tsv").is_file())

    def test_known_legacy_receipt_migrates_to_runtime_receipt(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        records = self.copy_skills(target)
        receipt = target / ".cash-skills" / "receipt.tsv"
        receipt.parent.mkdir(parents=True)
        receipt.write_text(
            "version\t1.2.0\n"
            + "".join(f"sha256\t{digest}\t{path}\n" for path, digest in records),
            encoding="utf-8",
        )

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        migrated = receipt.read_text(encoding="utf-8")
        self.assertIn("runtime_generation\t", migrated)
        self.assertNotIn("\nsha256\t", migrated)

    def test_publishing_journal_recovers_before_conflict_and_replans_gitignore(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        receipt = target / ".cash-skills" / "receipt.tsv"
        receipt_rows = receipt.read_text(encoding="utf-8").splitlines()
        receipt_rows[0] = "version\t1.0.0"
        receipt.write_text("\n".join(receipt_rows) + "\n", encoding="utf-8")
        runtime_relative = ".cash-skills/lib/cash_cli/installer.py"
        runtime_before = (target / runtime_relative).read_bytes()
        gitignore_before = (target / ".gitignore").read_bytes()
        journal = self.seed_publishing_journal(
            target,
            [
                (".gitignore", gitignore_before, 0o644, b"half-published-ignore\n"),
                (runtime_relative, runtime_before, 0o644, b"half-published-runtime\n"),
            ],
        )

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unfinished installer journal", result.stderr)
        self.assertIn("Result: update", result.stdout)
        self.assertNotIn("Result: conflict", result.stdout)
        self.assertNotIn("installation inputs changed after lock acquisition", result.stderr)
        self.assertFalse(journal.exists())
        self.assertEqual((target / runtime_relative).read_bytes(), runtime_before)
        self.assertEqual((target / ".gitignore").read_bytes(), gitignore_before)

    def test_recovery_reclassifies_unrelated_drift_as_conflict(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        runtime_relative = ".cash-skills/lib/cash_cli/installer.py"
        runtime_before = (target / runtime_relative).read_bytes()
        journal = self.seed_publishing_journal(
            target,
            [(runtime_relative, runtime_before, 0o644, b"half-published-runtime\n")],
        )
        skill = target / ".agents" / "skills" / "cash-apply" / "SKILL.md"
        drift = skill.read_bytes() + b"\nunrelated drift\n"
        skill.write_bytes(drift)

        result = self.install(target)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("Result: conflict", result.stdout)
        self.assertFalse(journal.exists())
        self.assertEqual((target / runtime_relative).read_bytes(), runtime_before)
        self.assertEqual(skill.read_bytes(), drift)

    def test_publishing_journal_precedes_receiptless_and_legacy_early_returns(self) -> None:
        for fixture in ("receiptless", "legacy"):
            with self.subTest(fixture=fixture):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                launcher = target / ".cash-skills" / "bin" / "cash"
                launcher.parent.mkdir(parents=True)
                shutil.copy2(ROOT / ".cash-skills" / "bin" / "cash", launcher)
                shutil.copy2(ROOT / ".cash-workspace.lock", target / ".cash-workspace.lock")
                if fixture == "receiptless":
                    relative = ".agents/skills/cash-apply/SKILL.md"
                    journal = self.seed_publishing_journal(
                        target,
                        [(relative, None, 0o644, (ROOT / relative).read_bytes())],
                    )
                else:
                    records = self.copy_skills(target)
                    receipt = target / ".cash-skills" / "receipt.tsv"
                    receipt.parent.mkdir(parents=True, exist_ok=True)
                    original = (
                        "version\t1.2.0\n"
                        + "".join(
                            f"sha256\t{digest}\t{path}\n" for path, digest in records
                        )
                    ).encode()
                    published_rows = original.decode("utf-8").splitlines()
                    first_fields = published_rows[1].split("\t")
                    first_fields[1] = "0" * 64
                    published_rows[1] = "\t".join(first_fields)
                    receipt.write_text(
                        "\n".join(published_rows) + "\n",
                        encoding="utf-8",
                    )
                    journal = self.seed_publishing_journal(
                        target,
                        [
                            (
                                ".cash-skills/receipt.tsv",
                                original,
                                0o644,
                                receipt.read_bytes(),
                            )
                        ],
                    )

                result = self.install(target)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Result: update", result.stdout)
                self.assertFalse(journal.exists())
                self.assertNotIn("inventory is partial", result.stderr)
                self.assertNotIn("legacy receipt drift", result.stderr)

    def test_newer_target_reports_journal_without_recovery(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        receipt = target / ".cash-skills" / "receipt.tsv"
        rows = receipt.read_text(encoding="utf-8").splitlines()
        rows[0] = "version\t999999999999999999999.0.0"
        before = ("\n".join(rows) + "\n").encode()
        receipt.write_bytes(before)
        journal = self.seed_publishing_journal(
            target,
            [(".gitignore", b"before\n", 0o644, b"published\n")],
        )
        journal_before = journal.read_bytes()
        lock = target / ".cash-workspace.lock"
        identity = (lock.stat().st_dev, lock.stat().st_ino)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: newer", result.stdout)
        self.assertIn("unfinished installer journal", result.stderr)
        self.assertIn("newer installer", result.stderr)
        self.assertEqual(journal.read_bytes(), journal_before)
        self.assertEqual((target / ".gitignore").read_bytes(), b"published\n")
        self.assertEqual((lock.stat().st_dev, lock.stat().st_ino), identity)

    def test_journal_boundaries_fail_closed_without_creating_lock(self) -> None:
        for shape in ("unknown-version", "symlink", "dangling-symlink", "missing-lock"):
            with self.subTest(shape=shape):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                lock = target / ".cash-workspace.lock"
                if shape != "missing-lock":
                    shutil.copy2(ROOT / ".cash-workspace.lock", lock)
                journal_path = (
                    target / ".cash-skills" / "state" / "installer" / "journal.json"
                )
                if shape == "unknown-version":
                    self.seed_publishing_journal(
                        target,
                        [(".gitignore", None, 0o644, b"published\n")],
                        version=999,
                    )
                elif shape == "missing-lock":
                    self.seed_publishing_journal(
                        target,
                        [(".gitignore", None, 0o644, b"published\n")],
                    )
                else:
                    journal_path.parent.mkdir(parents=True)
                    destination = (
                        target / "missing-journal"
                        if shape == "dangling-symlink"
                        else target / "outside-journal"
                    )
                    if shape == "symlink":
                        destination.write_text("{}\n", encoding="utf-8")
                    journal_path.symlink_to(destination)

                result = self.install(target)

                self.assertEqual(result.returncode, 1, result.stdout)
                if shape == "unknown-version":
                    self.assertIn("matching or newer installer", result.stderr)
                elif shape in {"symlink", "dangling-symlink"}:
                    self.assertIn("unsafe installer journal", result.stderr)
                else:
                    self.assertIn("stable workspace lock", result.stderr)
                    self.assertFalse(lock.exists())

    def test_journal_diagnostic_precedes_all_dry_and_real_classifications(self) -> None:
        for dry_run in (True, False):
            for classification in ("current", "update", "newer", "conflict"):
                with self.subTest(dry_run=dry_run, classification=classification):
                    temporary, target = self.make_target()
                    self.addCleanup(temporary.cleanup)
                    self.assertEqual(self.install(target).returncode, 0)
                    receipt = target / ".cash-skills" / "receipt.tsv"
                    if classification == "update":
                        (target / ".cash.yaml").unlink()
                    elif classification == "newer":
                        rows = receipt.read_text(encoding="utf-8").splitlines()
                        rows[0] = "version\t999999999999999999999.0.0"
                        receipt.write_text("\n".join(rows) + "\n", encoding="utf-8")
                    elif classification == "conflict":
                        skill = (
                            target / ".agents" / "skills" / "cash-apply" / "SKILL.md"
                        )
                        skill.write_bytes(skill.read_bytes() + b"\nconflict\n")
                    gitignore = target / ".gitignore"
                    gitignore_before = gitignore.read_bytes()
                    journal = self.seed_publishing_journal(
                        target,
                        [
                            (
                                ".gitignore",
                                gitignore_before,
                                0o644,
                                gitignore_before,
                            )
                        ],
                    )
                    before = journal.read_bytes()

                    arguments = ("--dry-run",) if dry_run else ()
                    result = self.install(target, *arguments)

                    expected_code = 2 if classification == "conflict" else 0
                    self.assertEqual(result.returncode, expected_code, result.stderr)
                    self.assertIn(f"Result: {classification}", result.stdout)
                    self.assertIn("unfinished installer journal", result.stderr)
                    if dry_run or classification == "newer":
                        self.assertEqual(journal.read_bytes(), before)
                    else:
                        self.assertFalse(journal.exists())
                    self.assertEqual(gitignore.read_bytes(), gitignore_before)

    def test_publication_failure_rolls_back_replaceable_state_only(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(
            target,
            env={
                "TEST_CASH_INSTALL_TEST_HOOKS": "1",
                "TEST_CASH_INSTALL_FAIL_AFTER": "1",
            },
        )

        self.assertEqual(result.returncode, 1)
        self.assertTrue((target / ".cash-workspace.lock").is_file())
        self.assertTrue((target / ".cash-skills" / "bin" / "cash").is_file())
        self.assertFalse((target / ".cash-skills" / "receipt.tsv").exists())
        self.assertFalse((target / ".cash.yaml").exists())
        self.assertFalse((target / ".cash-skills" / "state").exists())

        recovered = self.install(target)
        self.assertEqual(recovered.returncode, 0, recovered.stderr)

    def test_fault_injection_hooks_are_inert_without_exact_enable_switch(self) -> None:
        for switch in (None, "0", "true"):
            with self.subTest(switch=switch):
                temporary, target = self.make_target()
                hold = tempfile.TemporaryDirectory()
                self.addCleanup(temporary.cleanup)
                self.addCleanup(hold.cleanup)
                hold_path = Path(hold.name) / "inert"
                Path(f"{hold_path}.release").touch()
                environment = {
                    "CASH_INSTALL_FAIL_AFTER": "1",
                    "CASH_INSTALL_FAIL_AFTER_PATH": ".cash.yaml",
                    "CASH_INSTALL_HOLD_FILE": str(hold_path),
                    "CASH_INSTALL_PUBLICATION_HOLD_FILE": str(hold_path),
                    "CASH_INSTALL_CRASH_AFTER_QUARANTINE": "1",
                }
                if switch is not None:
                    environment["CASH_INSTALL_TEST_HOOKS"] = switch

                result = self.install(target, env=environment)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Result: update", result.stdout)
                self.assertFalse(Path(f"{hold_path}.ready").exists())

    def test_hold_hook_configuration_fails_closed_before_first_target_write(self) -> None:
        for shape in (
            "relative",
            "missing-parent",
            "symlink-parent",
            "ready-exists",
            "release-exists",
            "duplicate",
            "duplicate-alias",
        ):
            with self.subTest(shape=shape):
                temporary, target = self.make_target()
                hold = tempfile.TemporaryDirectory()
                self.addCleanup(temporary.cleanup)
                self.addCleanup(hold.cleanup)
                base = Path(hold.name)
                hold_path = base / "hold"
                publication_path = base / "publication"
                if shape == "relative":
                    hold_path = Path(os.path.relpath(hold_path, ROOT))
                    (base / "hold.release").touch()
                elif shape == "missing-parent":
                    hold_path = base / "missing" / "hold"
                elif shape == "symlink-parent":
                    real = base / "real"
                    real.mkdir()
                    linked = base / "linked"
                    linked.symlink_to(real, target_is_directory=True)
                    hold_path = linked / "hold"
                    Path(f"{hold_path}.release").touch()
                elif shape == "ready-exists":
                    Path(f"{hold_path}.ready").touch()
                    Path(f"{hold_path}.release").touch()
                elif shape == "release-exists":
                    Path(f"{hold_path}.release").touch()
                elif shape == "duplicate":
                    publication_path = hold_path
                    Path(f"{hold_path}.release").touch()
                elif shape == "duplicate-alias":
                    alias = base / "alias"
                    alias.mkdir()
                    publication_path = alias / ".." / "hold"
                    Path(f"{hold_path}.release").touch()
                environment = {
                    "CASH_INSTALL_TEST_HOOKS": "1",
                    "CASH_INSTALL_HOLD_FILE": str(hold_path),
                }
                if shape in {"duplicate", "duplicate-alias"}:
                    environment["CASH_INSTALL_PUBLICATION_HOLD_FILE"] = str(
                        publication_path
                    )

                result = self.install(target, env=environment, timeout=5)

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("invalid installer test hook", result.stderr)
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertFalse((target / ".cash-skills").exists())

    def test_hold_hook_revalidates_late_ready_and_release_shapes(self) -> None:
        for shape in ("ready", "release", "release-symlink"):
            with self.subTest(shape=shape):
                temporary, target = self.make_target()
                hold = tempfile.TemporaryDirectory()
                self.addCleanup(temporary.cleanup)
                self.addCleanup(hold.cleanup)
                lock = target / ".cash-workspace.lock"
                shutil.copy2(ROOT / ".cash-workspace.lock", lock)
                descriptor = os.open(lock, os.O_RDONLY)
                fcntl.flock(descriptor, fcntl.LOCK_EX)
                hold_path = Path(hold.name) / "late"
                environment = os.environ.copy()
                environment.update(
                    {
                        "CASH_INSTALL_TEST_HOOKS": "1",
                        "CASH_INSTALL_HOLD_FILE": str(hold_path),
                    }
                )
                process = subprocess.Popen(
                    [
                        "fish",
                        "--no-config",
                        str(INSTALLER),
                        "--target",
                        str(target),
                    ],
                    cwd=ROOT,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=environment,
                )
                try:
                    time.sleep(0.2)
                    late = Path(f"{hold_path}.{shape.split('-')[0]}")
                    if shape == "release-symlink":
                        destination = Path(hold.name) / "release-target"
                        destination.touch()
                        late.symlink_to(destination)
                    else:
                        late.touch()
                finally:
                    fcntl.flock(descriptor, fcntl.LOCK_UN)
                    os.close(descriptor)
                stdout, stderr = process.communicate(timeout=10)

                self.assertEqual(process.returncode, 1, stdout)
                # 斷言階段標記而非通用字串：preflight 與等待點對同一形狀都會
                # fail closed，若只比對通用字串，時序失準（late 檔在 preflight
                # 之前就建立）會讓本測試靜默退化成 preflight 案例的重複。
                self.assertIn("appeared after preflight", stderr)
                self.assertNotIn("already exists", stderr)
                self.assertFalse((target / ".cash-skills" / "receipt.tsv").exists())
                if late.is_symlink():
                    self.assertTrue(late.is_symlink())

    def test_hold_hooks_are_accounted_independently(self) -> None:
        temporary, target = self.make_target()
        hold = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(hold.cleanup)
        first = Path(hold.name) / "locked"
        second = Path(hold.name) / "publication"
        environment = os.environ.copy()
        environment.update(
            {
                "CASH_INSTALL_TEST_HOOKS": "1",
                "CASH_INSTALL_HOLD_FILE": str(first),
                "CASH_INSTALL_PUBLICATION_HOLD_FILE": str(second),
            }
        )
        process = subprocess.Popen(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
        deadline = time.monotonic() + 10
        while not Path(f"{first}.ready").exists():
            self.assertIsNone(process.poll())
            self.assertLess(time.monotonic(), deadline)
            time.sleep(0.01)
        Path(f"{first}.release").touch()
        while not Path(f"{second}.ready").exists():
            self.assertIsNone(process.poll())
            self.assertLess(time.monotonic(), deadline)
            time.sleep(0.01)
        Path(f"{second}.release").touch()
        stdout, stderr = process.communicate(timeout=10)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn("Result: update", stdout)

    def test_consumed_hold_hook_is_skipped_on_reentry_and_later_batch_targets(self) -> None:
        for flow in ("reentry", "batch"):
            with self.subTest(flow=flow):
                home = tempfile.TemporaryDirectory()
                first_temp, first = self.make_target()
                self.addCleanup(home.cleanup)
                self.addCleanup(first_temp.cleanup)
                second_temp = None
                if flow == "batch":
                    second_temp, second = self.make_target()
                    self.addCleanup(second_temp.cleanup)
                    for target in (first, second):
                        registered = self.run_installer(
                            ["--register", str(target)],
                            home=Path(home.name),
                        )
                        self.assertEqual(registered.returncode, 0, registered.stderr)
                    arguments = ["--all"]
                else:
                    (first / "AGENTS.md").write_text("before\n", encoding="utf-8")
                    arguments = ["--target", str(first)]
                hold = tempfile.TemporaryDirectory()
                self.addCleanup(hold.cleanup)
                hold_path = Path(hold.name) / flow
                environment = os.environ.copy()
                environment["HOME"] = home.name
                environment.update(
                    {
                        "CASH_INSTALL_TEST_HOOKS": "1",
                        "CASH_INSTALL_HOLD_FILE": str(hold_path),
                    }
                )
                process = subprocess.Popen(
                    ["fish", "--no-config", str(INSTALLER), *arguments],
                    cwd=ROOT,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=environment,
                )
                deadline = time.monotonic() + 10
                while not Path(f"{hold_path}.ready").exists():
                    self.assertIsNone(process.poll())
                    self.assertLess(time.monotonic(), deadline)
                    time.sleep(0.01)
                if flow == "reentry":
                    (first / "AGENTS.md").write_text("concurrent\n", encoding="utf-8")
                Path(f"{hold_path}.release").touch()
                stdout, stderr = process.communicate(timeout=15)

                self.assertEqual(process.returncode, 0, stderr)
                if flow == "batch":
                    self.assertTrue(
                        (second / ".cash-skills" / "receipt.tsv").is_file()
                    )
                else:
                    self.assertTrue(
                        (first / "AGENTS.md")
                        .read_text(encoding="utf-8")
                        .startswith("concurrent\n")
                    )

    def test_non_integer_failure_hook_fails_before_first_target_write(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(
            target,
            env={
                "CASH_INSTALL_TEST_HOOKS": "1",
                "CASH_INSTALL_FAIL_AFTER": "not-an-integer",
            },
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("invalid installer test hook", result.stderr)
        self.assertFalse((target / ".cash-workspace.lock").exists())
        self.assertFalse((target / ".cash-skills").exists())

    def test_invalid_receipt_is_execution_error_not_domain_result(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        receipt = target / ".cash-skills" / "receipt.tsv"
        receipt.write_text("version\t1.2.1\nunknown\trow\n", encoding="utf-8")

        result = self.install(target)

        self.assertEqual(result.returncode, 1)
        self.assertNotIn("Result:", result.stdout)

    def test_newer_receipt_returns_before_parsing_future_cash_config(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        receipt = target / ".cash-skills" / "receipt.tsv"
        lines = receipt.read_text(encoding="utf-8").splitlines()
        lines[0] = "version\t999999999999999999999.0.0"
        receipt.write_text("\n".join(lines) + "\n", encoding="utf-8")
        (target / ".cash.yaml").write_text("future_key: future_value\n", encoding="utf-8")

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: newer", result.stdout)

    def test_managed_mode_drift_is_conflict_without_force(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        skill = target / ".agents" / "skills" / "cash-apply" / "SKILL.md"
        os.chmod(skill, 0o600)

        result = self.install(target)

        self.assertEqual(result.returncode, 2)
        self.assertIn("Result: conflict", result.stdout)

    def test_launcher_rejects_missing_or_unknown_receipt_inventory(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        receipt = target / ".cash-skills" / "receipt.tsv"
        rows = receipt.read_text(encoding="utf-8").splitlines()
        rows.pop()
        receipt.write_text("\n".join(rows) + "\n", encoding="utf-8")
        (target / "install-cash-skills.fish").write_text(
            "#!/usr/bin/env fish\n",
            encoding="utf-8",
        )
        os.chmod(target / "install-cash-skills.fish", 0o755)
        (target / "cash-skills.version").write_text("2.0.0\n", encoding="utf-8")

        launched = subprocess.run(
            [str(target / ".cash-skills" / "bin" / "cash"), "list", "--json"],
            cwd=target,
            text=True,
            capture_output=True,
        )

        self.assertEqual(launched.returncode, 1)
        self.assertIn('"code":"receipt_invalid"', launched.stdout)
        self.assertNotIn("./install-cash-skills.fish --self", launched.stdout)
        self.assertEqual(launched.stderr, "")

    def test_launcher_rejects_noncanonical_stable_receipt_mode(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        receipt = target / ".cash-skills" / "receipt.tsv"
        rows = receipt.read_text(encoding="utf-8").splitlines()
        for index, row in enumerate(rows):
            if row.startswith("stable\t"):
                fields = row.split("\t")
                fields[3] = fields[3].removeprefix("0")
                rows[index] = "\t".join(fields)
        receipt.write_text("\n".join(rows) + "\n", encoding="utf-8")

        launched = subprocess.run(
            [str(target / ".cash-skills" / "bin" / "cash"), "list", "--json"],
            cwd=target,
            text=True,
            capture_output=True,
        )

        self.assertEqual(launched.returncode, 1)
        self.assertIn('"code":"receipt_invalid"', launched.stdout)
        self.assertIn("receipt mode is invalid", launched.stdout)

    def test_launcher_missing_lock_uses_json_error_contract(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        (target / ".cash-workspace.lock").unlink()

        launched = subprocess.run(
            [str(target / ".cash-skills" / "bin" / "cash"), "list", "--json"],
            cwd=target,
            text=True,
            capture_output=True,
        )

        self.assertEqual(launched.returncode, 1)
        self.assertIn('"code":"bootstrap_invalid"', launched.stdout)
        self.assertNotIn("./install-cash-skills.fish --self", launched.stdout)
        self.assertEqual(launched.stderr, "")

    def test_register_validates_target_before_registry_write(self) -> None:
        home = tempfile.TemporaryDirectory()
        invalid = tempfile.TemporaryDirectory()
        self.addCleanup(home.cleanup)
        self.addCleanup(invalid.cleanup)

        rejected = self.run_installer(
            ["--register", invalid.name],
            home=Path(home.name),
        )

        self.assertEqual(rejected.returncode, 1)
        self.assertFalse(
            (
                Path(home.name)
                / ".config"
                / "cash-skills"
                / "projects.txt"
            ).exists()
        )

        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        accepted = self.run_installer(
            ["--register", str(target)],
            home=Path(home.name),
        )
        listed = self.run_installer(["--list"], home=Path(home.name))
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertEqual(listed.stdout, f"{target.resolve()}\n")

    def test_register_rejects_source_without_registry_write(self) -> None:
        home = tempfile.TemporaryDirectory()
        self.addCleanup(home.cleanup)

        result = self.run_installer(
            ["--register", ROOT.as_posix()],
            home=Path(home.name),
        )

        self.assertEqual(result.returncode, 1)
        self.assertIn("non-source", result.stderr)
        self.assertFalse(
            (Path(home.name) / ".config" / "cash-skills" / "projects.txt").exists()
        )

    def test_empty_string_value_modes_fail_before_registry_or_target_access(self) -> None:
        for mode in ("--target", "--register", "--unregister"):
            for extra in ((), ("--dry-run",), ("--force",)):
                with self.subTest(mode=mode, extra=extra):
                    home = tempfile.TemporaryDirectory()
                    temporary, target = self.make_target()
                    self.addCleanup(home.cleanup)
                    self.addCleanup(temporary.cleanup)
                    registry = (
                        Path(home.name)
                        / ".config"
                        / "cash-skills"
                        / "projects.txt"
                    )
                    registry.parent.mkdir(parents=True)
                    registry.write_bytes(
                        f"{target.resolve()}\n/private/tmp/../tmp/invalid\n".encode()
                    )
                    before = (
                        registry.stat().st_ino,
                        registry.stat().st_mtime_ns,
                        registry.read_bytes(),
                    )

                    result = self.run_installer(
                        [mode, "", *extra],
                        home=Path(home.name),
                    )

                    self.assertEqual(result.returncode, 2, result.stdout)
                    self.assertIn(f"{mode} requires a non-empty value", result.stderr)
                    self.assertNotIn("registry line", result.stderr)
                    self.assertEqual(
                        (
                            registry.stat().st_ino,
                            registry.stat().st_mtime_ns,
                            registry.read_bytes(),
                        ),
                        before,
                    )
                    self.assertFalse((target / ".cash-workspace.lock").exists())
                    self.assertFalse((target / ".cash-skills").exists())
                    self.assertFalse((target / ".cash.yaml").exists())
                    self.assertFalse((target / "AGENTS.md").exists())
                    self.assertFalse((target / "CLAUDE.md").exists())

    def test_boolean_mode_compatibility_rules_remain_unchanged(self) -> None:
        home = tempfile.TemporaryDirectory()
        temporary, target = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(temporary.cleanup)

        invalid_list = self.run_installer(
            ["--list", "--dry-run"],
            home=Path(home.name),
        )
        invalid_register = self.run_installer(
            ["--register", str(target), "--force"],
            home=Path(home.name),
        )

        self.assertEqual(invalid_list.returncode, 2, invalid_list.stdout)
        self.assertEqual(invalid_register.returncode, 2, invalid_register.stdout)
        self.assertFalse(
            (Path(home.name) / ".config" / "cash-skills" / "projects.txt").exists()
        )
        self.assertFalse((target / ".cash-workspace.lock").exists())

    def test_registry_modes_ignore_exact_empty_lines(self) -> None:
        first_temp, first = self.make_target()
        second_temp, second = self.make_target()
        third_temp, third = self.make_target()
        self.addCleanup(first_temp.cleanup)
        self.addCleanup(second_temp.cleanup)
        self.addCleanup(third_temp.cleanup)
        cases = (
            (
                "list",
                ["--list"],
                f"{first.resolve()}\n{second.resolve()}\n",
                None,
            ),
            ("all", ["--all", "--dry-run"], None, None),
            (
                "register",
                ["--register", str(third)],
                f"registered: {third.resolve()}\n",
                (
                    f"{first.resolve()}\n"
                    f"{second.resolve()}\n"
                    f"{third.resolve()}\n"
                ).encode(),
            ),
            (
                "unregister",
                ["--unregister", str(first)],
                f"unregistered: {first.resolve()}\n",
                f"{second.resolve()}\n".encode(),
            ),
        )
        for label, arguments, expected_stdout, expected_registry in cases:
            with self.subTest(mode=label):
                home = tempfile.TemporaryDirectory()
                self.addCleanup(home.cleanup)
                registry = (
                    Path(home.name)
                    / ".config"
                    / "cash-skills"
                    / "projects.txt"
                )
                registry.parent.mkdir(parents=True)
                original = (
                    f"\n{first.resolve()}\n\n{second.resolve()}\n\n"
                ).encode()
                registry.write_bytes(original)
                before = (
                    registry.stat().st_ino,
                    registry.stat().st_mtime_ns,
                    registry.read_bytes(),
                )

                result = self.run_installer(arguments, home=Path(home.name))

                self.assertEqual(result.returncode, 0, result.stderr)
                if expected_stdout is not None:
                    self.assertEqual(result.stdout, expected_stdout)
                if expected_registry is None:
                    self.assertEqual(
                        (
                            registry.stat().st_ino,
                            registry.stat().st_mtime_ns,
                            registry.read_bytes(),
                        ),
                        before,
                    )
                else:
                    self.assertEqual(registry.read_bytes(), expected_registry)

    def test_registry_modes_reject_control_records_with_line_number(self) -> None:
        cases = (
            ("list-crlf", ["--list"], b"/private/tmp/second\r\n"),
            ("all-crlf", ["--all"], b"/private/tmp/second\r\n"),
            (
                "register-crlf",
                ["--register", "/private/tmp/not-reached"],
                b"/private/tmp/second\r\n",
            ),
            (
                "unregister-crlf",
                ["--unregister", "/private/tmp/not-reached"],
                b"/private/tmp/second\r\n",
            ),
            (
                "list-embedded-cr",
                ["--list"],
                b"/private/tmp/second\r/private/tmp/third\n",
            ),
            ("list-space-only", ["--list"], b"   \n"),
            ("list-tab", ["--list"], b"\t\n"),
        )
        for label, arguments, invalid_line in cases:
            with self.subTest(case=label):
                home = tempfile.TemporaryDirectory()
                temporary, target = self.make_target()
                self.addCleanup(home.cleanup)
                self.addCleanup(temporary.cleanup)
                registry = (
                    Path(home.name)
                    / ".config"
                    / "cash-skills"
                    / "projects.txt"
                )
                registry.parent.mkdir(parents=True)
                registry.write_bytes(
                    f"{target.resolve()}\n".encode() + invalid_line
                )
                before = (
                    registry.stat().st_ino,
                    registry.stat().st_mtime_ns,
                    registry.read_bytes(),
                )

                result = self.run_installer(arguments, home=Path(home.name))

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("registry line 2", result.stderr)
                self.assertEqual(
                    (
                        registry.stat().st_ino,
                        registry.stat().st_mtime_ns,
                        registry.read_bytes(),
                    ),
                    before,
                )
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertFalse((target / ".cash-skills").exists())
                self.assertFalse((target / ".cash.yaml").exists())

    def test_registry_modes_reject_dangling_registry_boundaries(self) -> None:
        modes = (
            ("list", ["--list"]),
            ("all", ["--all"]),
            ("register", ["--register"]),
            ("unregister", ["--unregister"]),
        )
        for boundary in ("registry", "config-parent"):
            for label, base_arguments in modes:
                with self.subTest(boundary=boundary, mode=label):
                    home = tempfile.TemporaryDirectory()
                    temporary, target = self.make_target()
                    self.addCleanup(home.cleanup)
                    self.addCleanup(temporary.cleanup)
                    home_path = Path(home.name)
                    if boundary == "registry":
                        registry = (
                            home_path
                            / ".config"
                            / "cash-skills"
                            / "projects.txt"
                        )
                        registry.parent.mkdir(parents=True)
                        registry.symlink_to(home_path / "missing-registry")
                        boundary_path = registry
                    else:
                        config = home_path / ".config"
                        config.symlink_to(home_path / "missing-config")
                        boundary_path = config
                    arguments = list(base_arguments)
                    if label in {"register", "unregister"}:
                        arguments.append(str(target))

                    result = self.run_installer(arguments, home=home_path)

                    self.assertEqual(result.returncode, 1, result.stdout)
                    self.assertIn("symlink managed boundary", result.stderr)
                    self.assertTrue(boundary_path.is_symlink())
                    self.assertFalse((target / ".cash-workspace.lock").exists())
                    self.assertFalse((target / ".cash-skills").exists())
                    self.assertFalse((target / ".cash.yaml").exists())

    def test_registry_rejects_noncanonical_and_symlink_records(self) -> None:
        temporary, target = self.make_target()
        link_home = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(link_home.cleanup)
        linked_target = Path(link_home.name) / "linked-target"
        linked_target.symlink_to(target, target_is_directory=True)
        records = (
            "/private/tmp/../tmp/project",
            "//",
            "/private/tmp//project",
            "/private/tmp/project/",
            "/private/tmp/./project",
            str(linked_target),
        )
        for record in records:
            with self.subTest(record=record):
                home = tempfile.TemporaryDirectory()
                self.addCleanup(home.cleanup)
                registry = (
                    Path(home.name)
                    / ".config"
                    / "cash-skills"
                    / "projects.txt"
                )
                registry.parent.mkdir(parents=True)
                registry.write_text(
                    f"/private/tmp/valid\n{record}\n",
                    encoding="utf-8",
                )
                before = (
                    registry.stat().st_ino,
                    registry.stat().st_mtime_ns,
                    registry.read_bytes(),
                )

                result = self.run_installer(["--list"], home=Path(home.name))

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("registry line 2", result.stderr)
                self.assertEqual(
                    (
                        registry.stat().st_ino,
                        registry.stat().st_mtime_ns,
                        registry.read_bytes(),
                    ),
                    before,
                )

    def test_invalid_later_registry_record_blocks_all_target_writes(self) -> None:
        home = tempfile.TemporaryDirectory()
        first_temp, first = self.make_target()
        linked_temp, linked = self.make_target()
        link_home = tempfile.TemporaryDirectory()
        self.addCleanup(home.cleanup)
        self.addCleanup(first_temp.cleanup)
        self.addCleanup(linked_temp.cleanup)
        self.addCleanup(link_home.cleanup)
        linked_target = Path(link_home.name) / "linked-target"
        linked_target.symlink_to(linked, target_is_directory=True)
        registry = (
            Path(home.name)
            / ".config"
            / "cash-skills"
            / "projects.txt"
        )
        registry.parent.mkdir(parents=True)
        registry.write_text(
            f"{first.resolve()}\n{linked_target}\n",
            encoding="utf-8",
        )
        before = (
            registry.stat().st_ino,
            registry.stat().st_mtime_ns,
            registry.read_bytes(),
        )

        result = self.run_installer(["--all"], home=Path(home.name))

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("registry line 2", result.stderr)
        self.assertEqual(
            (
                registry.stat().st_ino,
                registry.stat().st_mtime_ns,
                registry.read_bytes(),
            ),
            before,
        )
        self.assertFalse((first / ".cash-workspace.lock").exists())
        self.assertFalse((first / ".cash-skills").exists())
        self.assertFalse((first / ".cash.yaml").exists())

    def test_registry_modes_reject_missing_record_below_symlink_parent(self) -> None:
        modes = (
            ("list", ["--list"]),
            ("all", ["--all"]),
            ("register", ["--register"]),
            ("unregister", ["--unregister"]),
        )
        for label, base_arguments in modes:
            with self.subTest(mode=label):
                home = tempfile.TemporaryDirectory()
                first_temp, first = self.make_target()
                argument_temp, argument = self.make_target()
                linked_temp, linked = self.make_target()
                link_home = tempfile.TemporaryDirectory()
                self.addCleanup(home.cleanup)
                self.addCleanup(first_temp.cleanup)
                self.addCleanup(argument_temp.cleanup)
                self.addCleanup(linked_temp.cleanup)
                self.addCleanup(link_home.cleanup)
                linked_parent = Path(link_home.name).resolve() / "linked-parent"
                linked_parent.symlink_to(linked, target_is_directory=True)
                unsafe_record = linked_parent / "missing-target"
                registry = (
                    Path(home.name)
                    / ".config"
                    / "cash-skills"
                    / "projects.txt"
                )
                registry.parent.mkdir(parents=True)
                registry.write_text(
                    f"{first.resolve()}\n{unsafe_record}\n",
                    encoding="utf-8",
                )
                before = (
                    registry.stat().st_ino,
                    registry.stat().st_mtime_ns,
                    registry.read_bytes(),
                )
                arguments = list(base_arguments)
                if label in {"register", "unregister"}:
                    arguments.append(str(argument))

                result = self.run_installer(arguments, home=Path(home.name))

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("registry line 2", result.stderr)
                self.assertEqual(
                    (
                        registry.stat().st_ino,
                        registry.stat().st_mtime_ns,
                        registry.read_bytes(),
                    ),
                    before,
                )
                self.assertFalse((first / ".cash-workspace.lock").exists())
                self.assertFalse((first / ".cash-skills").exists())
                self.assertFalse((first / ".cash.yaml").exists())

    def test_unregister_missing_record_is_a_persistent_no_op(self) -> None:
        home = tempfile.TemporaryDirectory()
        temporary, target = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(temporary.cleanup)
        self.assertEqual(
            self.run_installer(
                ["--register", str(target)],
                home=Path(home.name),
            ).returncode,
            0,
        )
        self.assertEqual(
            self.run_installer(
                ["--unregister", str(target)],
                home=Path(home.name),
            ).returncode,
            0,
        )
        registry = (
            Path(home.name)
            / ".config"
            / "cash-skills"
            / "projects.txt"
        )
        before = (registry.stat().st_ino, registry.stat().st_mtime_ns, registry.read_bytes())

        repeated = self.run_installer(
            ["--unregister", str(target)],
            home=Path(home.name),
        )

        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertEqual(
            (registry.stat().st_ino, registry.stat().st_mtime_ns, registry.read_bytes()),
            before,
        )

    def test_unregister_with_missing_registry_creates_no_state(self) -> None:
        home = tempfile.TemporaryDirectory()
        temporary, target = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(temporary.cleanup)

        result = self.run_installer(
            ["--unregister", str(target)],
            home=Path(home.name),
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(
            (
                Path(home.name)
                / ".config"
                / "cash-skills"
                / "projects.txt"
            ).exists()
        )

    def test_batch_reports_each_target_and_summary(self) -> None:
        home = tempfile.TemporaryDirectory()
        first_temp, first = self.make_target()
        second_temp, second = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(first_temp.cleanup)
        self.addCleanup(second_temp.cleanup)
        for target in (first, second):
            result = self.run_installer(
                ["--register", str(target)],
                home=Path(home.name),
            )
            self.assertEqual(result.returncode, 0, result.stderr)

        batch = self.run_installer(["--all"], home=Path(home.name))

        self.assertEqual(batch.returncode, 0, batch.stderr)
        self.assertIn(f"updated: {first.resolve()}", batch.stdout)
        self.assertIn(f"updated: {second.resolve()}", batch.stdout)
        self.assertIn("updated=2", batch.stdout)

    def test_concurrent_installer_loser_reclassifies_under_same_lock(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        commands = [
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ]
            for _ in range(3)
        ]
        processes = [
            subprocess.Popen(
                command,
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            for command in commands
        ]

        completed = [process.communicate(timeout=20) for process in processes]
        codes = [process.returncode for process in processes]

        self.assertEqual(codes, [0, 0, 0], completed)
        outputs = [stdout for stdout, _ in completed]
        self.assertEqual(sum("Result: update" in output for output in outputs), 1)
        self.assertEqual(sum("Result: current" in output for output in outputs), 2)

    def test_installer_waits_for_running_launcher_lock(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        guidance = target / "AGENTS.md"
        guidance.write_text("project-owned preface\n", encoding="utf-8")
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        time.sleep(0.2)
        self.assertIsNone(process.poll())

        fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
        os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn("Result: update", stdout)

    def test_lock_wait_replans_concurrent_guidance_edit(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        guidance = target / "AGENTS.md"
        guidance.write_text("before\n", encoding="utf-8")
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            guidance.write_text("concurrent\n", encoding="utf-8")
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn("Result: update", stdout)
        self.assertTrue(
            guidance.read_text(encoding="utf-8").startswith("concurrent\n")
        )

    def test_post_lock_gitignore_edit_reclassifies_without_overwrite(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        gitignore = target / ".gitignore"
        gitignore.write_bytes(b"node_modules\n")
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            gitignore.write_bytes(b"node_modules\nconcurrent\n")
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn("Result: update", stdout)
        self.assertEqual(
            gitignore.read_bytes(),
            b"node_modules\nconcurrent\n"
            b".cash-skills/receipt.tsv\n.cash-skills/state/\n__pycache__/\n",
        )

    def test_publication_gitignore_edit_fails_closed_without_overwrite(self) -> None:
        temporary, target = self.make_target()
        hold = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(hold.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        gitignore = target / ".gitignore"
        gitignore.write_bytes(b"node_modules\n")
        hold_path = Path(hold.name) / "publication"
        environment = os.environ.copy()
        environment["CASH_INSTALL_TEST_HOOKS"] = "1"
        environment["CASH_INSTALL_PUBLICATION_HOLD_FILE"] = str(hold_path)
        installer = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
        deadline = time.monotonic() + 10
        while not Path(f"{hold_path}.ready").exists():
            self.assertIsNone(installer.poll())
            self.assertLess(time.monotonic(), deadline)
            time.sleep(0.01)
        gitignore.write_bytes(b"node_modules\nconcurrent\n")
        Path(f"{hold_path}.release").touch()
        stdout, stderr = installer.communicate(timeout=20)

        self.assertEqual(installer.returncode, 1, stdout)
        self.assertIn("installation inputs changed after lock acquisition", stderr)
        self.assertEqual(gitignore.read_bytes(), b"node_modules\nconcurrent\n")

    def test_lock_wait_rejects_concurrent_invalid_target_config(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        guidance = target / "AGENTS.md"
        guidance.write_text("project-owned preface\n", encoding="utf-8")
        receipt = target / ".cash-skills" / "receipt.tsv"
        runtime = target / ".cash-skills" / "lib" / "cash_cli" / "resources.py"
        before = (receipt.read_bytes(), runtime.read_bytes(), guidance.read_bytes())
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            (target / "openspec" / "config.yaml").write_text(
                "schema: invalid\n",
                encoding="utf-8",
            )
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 1, stdout)
        self.assertIn("invalid target openspec/config.yaml", stderr)
        self.assertEqual(
            (receipt.read_bytes(), runtime.read_bytes(), guidance.read_bytes()),
            before,
        )

    def test_lock_wait_reclassifies_concurrent_managed_drift(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        runtime = target / ".cash-skills" / "lib" / "cash_cli" / "resources.py"
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            runtime.write_bytes(runtime.read_bytes() + b"\n# concurrent drift\n")
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 2, stderr)
        self.assertIn("Result: conflict", stdout)
        self.assertTrue(runtime.read_bytes().endswith(b"# concurrent drift\n"))

    def test_lock_wait_rejects_concurrent_equal_version_source_drift(self) -> None:
        source_temp, source, _ = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        self.assertEqual(self.install_from(source, target).returncode, 0)
        source_runtime = (
            source / ".cash-skills" / "lib" / "cash_cli" / "resources.py"
        )
        lock_descriptor = os.open(target / ".cash-workspace.lock", os.O_RDONLY)
        fcntl.flock(lock_descriptor, fcntl.LOCK_SH)
        process = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(source / "install-cash-skills.fish"),
                "--target",
                str(target),
            ],
            cwd=source,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            time.sleep(0.2)
            source_runtime.write_bytes(
                source_runtime.read_bytes() + b"\n# source drift\n"
            )
        finally:
            fcntl.flock(lock_descriptor, fcntl.LOCK_UN)
            os.close(lock_descriptor)
        stdout, stderr = process.communicate(timeout=20)

        self.assertEqual(process.returncode, 1, stdout)
        self.assertIn("equal-version source integrity drift", stderr)
        launched = subprocess.run(
            [str(target / ".cash-skills" / "bin" / "cash"), "list", "--json"],
            cwd=target,
            text=True,
            capture_output=True,
        )
        self.assertEqual(launched.returncode, 0, launched.stdout)

    def test_new_launcher_waits_for_installer_publication_lock(self) -> None:
        temporary, target = self.make_target()
        hold = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.addCleanup(hold.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        (target / "AGENTS.md").write_text("project-owned preface\n", encoding="utf-8")
        hold_path = Path(hold.name) / "publication"
        environment = os.environ.copy()
        environment["CASH_INSTALL_TEST_HOOKS"] = "1"
        environment["CASH_INSTALL_HOLD_FILE"] = str(hold_path)
        installer = subprocess.Popen(
            [
                "fish",
                "--no-config",
                str(INSTALLER),
                "--target",
                str(target),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
        deadline = time.monotonic() + 10
        while not Path(f"{hold_path}.ready").exists():
            self.assertIsNone(installer.poll())
            self.assertLess(time.monotonic(), deadline)
            time.sleep(0.01)
        launcher = subprocess.Popen(
            [str(target / ".cash-skills" / "bin" / "cash"), "list", "--json"],
            cwd=target / "openspec",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        time.sleep(0.2)
        self.assertIsNone(launcher.poll())

        Path(f"{hold_path}.release").touch()
        installer_stdout, installer_stderr = installer.communicate(timeout=20)
        launcher_stdout, launcher_stderr = launcher.communicate(timeout=20)

        self.assertEqual(installer.returncode, 0, installer_stderr)
        self.assertIn("Result: update", installer_stdout)
        self.assertEqual(launcher.returncode, 0, launcher_stderr)
        self.assertEqual(launcher_stdout, '{"changes":[]}\n')

    def test_exact_legacy_baselines_are_removed_in_install_transaction(self) -> None:
        source_temp, source, bodies = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        self.seed_legacy_baselines(target, bodies)

        result = self.install_from(source, target)

        self.assertEqual(result.returncode, 0, result.stderr)
        for relative in bodies:
            self.assertFalse((target / relative).exists(), relative)
        self.assertTrue((target / ".cash-skills" / "receipt.tsv").is_file())

    def test_legacy_customization_is_preserved_without_blocking_install(self) -> None:
        source_temp, source, bodies = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        self.seed_legacy_baselines(target, bodies)
        changed = target / ".agents" / "skills" / "spectra-apply" / "SKILL.md"
        changed.write_text("customized\n", encoding="utf-8")

        result = self.install_from(source, target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(changed.read_text(encoding="utf-8"), "customized\n")
        self.assertIn("preserved", result.stderr)
        self.assertIn(".agents/skills/spectra-apply", result.stderr)
        self.assertTrue((target / ".cash-skills" / "receipt.tsv").is_file())
        for relative in bodies:
            if relative == ".agents/skills/spectra-apply":
                continue
            self.assertFalse((target / relative).exists(), relative)

    def test_legacy_mode_drift_is_preserved_without_blocking_install(self) -> None:
        source_temp, source, bodies = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        self.seed_legacy_baselines(target, bodies)
        skill = target / ".agents" / "skills" / "spectra-apply" / "SKILL.md"
        before = skill.read_bytes()
        os.chmod(skill, 0o600)

        result = self.install_from(source, target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(skill.is_file())
        self.assertEqual(skill.read_bytes(), before)
        self.assertEqual(stat.S_IMODE(skill.stat().st_mode), 0o600)
        self.assertIn("preserved", result.stderr)

    def test_failure_after_legacy_quarantine_restores_all_legacy_paths(self) -> None:
        source_temp, source, bodies = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        self.seed_legacy_baselines(target, bodies)

        result = self.install_from(
            source,
            target,
            env={
                "CASH_INSTALL_TEST_HOOKS": "1",
                "CASH_INSTALL_FAIL_AFTER": "47",
            },
        )

        self.assertEqual(result.returncode, 1)
        for relative, body in bodies.items():
            self.assertEqual((target / relative / "SKILL.md").read_bytes(), body)
        self.assertFalse((target / ".cash-skills" / "receipt.tsv").exists())

    def test_crash_during_committed_quarantine_cleanup_resumes_forward(self) -> None:
        source_temp, source, bodies = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        self.seed_legacy_baselines(target, bodies)

        crashed = self.install_from(
            source,
            target,
            env={
                "CASH_INSTALL_TEST_HOOKS": "1",
                "CASH_INSTALL_CRASH_AFTER_QUARANTINE": "1",
            },
        )

        self.assertEqual(crashed.returncode, 98)
        journal = (
            target
            / ".cash-skills"
            / "state"
            / "installer"
            / "journal.json"
        )
        self.assertTrue(journal.is_file())
        quarantines = list(target.rglob(".cash-legacy-*"))
        self.assertGreater(len(quarantines), 0)
        self.assertLess(len(quarantines), len(bodies))
        recovered = self.install_from(source, target)
        self.assertEqual(recovered.returncode, 0, recovered.stderr)
        self.assertFalse(journal.exists())
        for relative in bodies:
            self.assertFalse((target / relative).exists(), relative)

    def test_legacy_boundary_unsafe_shapes_fail_closed(self) -> None:
        mutations = ("hardlink", "extra", "symlink")
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                source_temp, source, bodies = self.make_source_bundle()
                target_temp, target = self.make_target()
                self.addCleanup(source_temp.cleanup)
                self.addCleanup(target_temp.cleanup)
                self.seed_legacy_baselines(target, bodies)
                skill_dir = target / ".agents" / "skills" / "spectra-apply"
                skill = skill_dir / "SKILL.md"
                if mutation == "hardlink":
                    os.link(skill, target / "legacy-hardlink")
                elif mutation == "extra":
                    (skill_dir / "extra.txt").write_text("extra\n", encoding="utf-8")
                else:
                    outside = target / "legacy-outside"
                    outside.mkdir()
                    (outside / "SKILL.md").write_bytes(
                        bodies[".agents/skills/spectra-apply"]
                    )
                    shutil.rmtree(skill_dir)
                    skill_dir.symlink_to(outside, target_is_directory=True)

                result = self.install_from(source, target)

                self.assertEqual(result.returncode, 1)
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertTrue(skill.is_file())

    def test_unsupported_legacy_config_shapes_fail_before_write(self) -> None:
        cases = (
            "unknown: true\n",
            "spec_dir: docs/specs\n",
            "tools:\n  - claude\n",
            "locale: tw\nlocale: en\n",
            "tdd: \"true\"\n",
            "# comment\nclaude_slash_commands: false\n",
            "# comment\nclaude_effort:\n  apply: high\n",
            "# comment\n  locale: tw\n",
            "# spec_dir: docs/specs\nspec_dir: docs/specs\n",
        )
        for content in cases:
            with self.subTest(content=content):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                (target / ".spectra.yaml").write_text(content, encoding="utf-8")

                result = self.install(target)

                self.assertEqual(result.returncode, 1)
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertFalse((target / ".cash.yaml").exists())


if __name__ == "__main__":
    unittest.main()
