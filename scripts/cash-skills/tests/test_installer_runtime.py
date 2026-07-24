from __future__ import annotations

import os
import fcntl
import hashlib
import shutil
import stat
import subprocess
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

    def install(self, target: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        failure = environment.pop("TEST_CASH_INSTALL_FAIL_AFTER", None)
        if failure is not None:
            environment["CASH_INSTALL_FAIL_AFTER"] = failure
        return subprocess.run(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target), *arguments],
            cwd=ROOT,
            text=True,
            capture_output=True,
            env=environment,
        )

    def run_installer(
        self,
        arguments: list[str],
        *,
        home: Path,
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["HOME"] = str(home)
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
    ) -> subprocess.CompletedProcess[str]:
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

    def test_publication_failure_rolls_back_replaceable_state_only(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        os.environ["TEST_CASH_INSTALL_FAIL_AFTER"] = "1"
        self.addCleanup(os.environ.pop, "TEST_CASH_INSTALL_FAIL_AFTER", None)

        result = self.install(target)

        self.assertEqual(result.returncode, 1)
        self.assertTrue((target / ".cash-workspace.lock").is_file())
        self.assertTrue((target / ".cash-skills" / "bin" / "cash").is_file())
        self.assertFalse((target / ".cash-skills" / "receipt.tsv").exists())
        self.assertFalse((target / ".cash.yaml").exists())
        self.assertFalse((target / ".cash-skills" / "state").exists())

        os.environ.pop("TEST_CASH_INSTALL_FAIL_AFTER", None)
        recovered = self.install(target)
        self.assertEqual(recovered.returncode, 0, recovered.stderr)

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
        os.environ["CASH_INSTALL_FAIL_AFTER"] = "47"
        self.addCleanup(os.environ.pop, "CASH_INSTALL_FAIL_AFTER", None)

        result = self.install_from(source, target)

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
        os.environ["CASH_INSTALL_CRASH_AFTER_QUARANTINE"] = "1"
        self.addCleanup(
            os.environ.pop,
            "CASH_INSTALL_CRASH_AFTER_QUARANTINE",
            None,
        )

        crashed = self.install_from(source, target)

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
        os.environ.pop("CASH_INSTALL_CRASH_AFTER_QUARANTINE")
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
