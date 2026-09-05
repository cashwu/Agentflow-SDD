from __future__ import annotations

import base64
import json
import os
import fcntl
import hashlib
import importlib.util
import marshal
import shlex
import shutil
import signal
import stat
import struct
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
INSTALLER = ROOT / "install-cash-skills.fish"
VERSION_CONTROL_PREMISE = (
    "if .cash-skills/receipt.tsv is tracked by version control, untrack it first because it is machine-local identity"
)
LAUNCHER_INIT_RECEIPT_COMMAND = (
    "Run PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer"
    " --init-receipt from the project root; " + VERSION_CONTROL_PREMISE
)
INSTALLER_INIT_RECEIPT_COMMAND = (
    "Run PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer"
    " --init-receipt in that project; " + VERSION_CONTROL_PREMISE
)
DRIFTED_RECORD_NEXT_STEP = (
    "Restore that record to the content the receipt records, or reinstall"
    " from a trusted source, then retry"
)


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

    def make_bare_target(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary = tempfile.TemporaryDirectory()
        target = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(target)], check=True)
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
        timeout: float | None = None,
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
            timeout=timeout,
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
        (source / ".cash-skills" / "manifest.tsv").unlink(missing_ok=True)
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

    def vendor(
        self,
        target: Path,
        *arguments: str,
        source: Path = ROOT,
        env: dict[str, str] | None = None,
        timeout: float | None = None,
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
            [
                "fish",
                "--no-config",
                str(source / "install-cash-skills.fish"),
                "--vendor",
                str(target),
                *arguments,
            ],
            cwd=source,
            text=True,
            capture_output=True,
            env=environment,
            timeout=timeout,
        )

    def assert_vendored(
        self,
        target: Path,
        *arguments: str,
        source: Path = ROOT,
    ) -> subprocess.CompletedProcess[str]:
        result = self.vendor(target, *arguments, source=source)
        self.assertEqual(
            result.returncode,
            0,
            "repo-vendored publication contract is missing:\n"
            f"stdout={result.stdout}\nstderr={result.stderr}",
        )
        self.assertTrue(
            (target / ".cash-skills" / "manifest.tsv").is_file(),
            "successful --vendor must publish .cash-skills/manifest.tsv",
        )
        self.assertFalse(
            (target / ".cash-skills" / "receipt.tsv").exists(),
            "successful --vendor must not leave a machine-local receipt",
        )
        return result

    def workspace_snapshot(
        self,
        target: Path,
    ) -> dict[str, tuple[str, int, int, bytes | None]]:
        snapshot: dict[str, tuple[str, int, int, bytes | None]] = {}
        for path in sorted(
            (candidate for candidate in target.rglob("*") if ".git" not in candidate.parts),
            key=lambda candidate: os.fsencode(candidate.relative_to(target)),
        ):
            metadata = os.lstat(path)
            relative = path.relative_to(target).as_posix()
            if stat.S_ISREG(metadata.st_mode):
                content: bytes | None = path.read_bytes()
                kind = "file"
            elif stat.S_ISDIR(metadata.st_mode):
                content = None
                kind = "directory"
            elif stat.S_ISLNK(metadata.st_mode):
                content = os.readlink(path).encode()
                kind = "symlink"
            else:
                content = None
                kind = "other"
            snapshot[relative] = (
                kind,
                stat.S_IMODE(metadata.st_mode),
                metadata.st_mtime_ns,
                content,
            )
        return snapshot

    def set_manifest_bundle_version(self, target: Path, version: str) -> None:
        manifest = target / ".cash-skills" / "manifest.tsv"
        lines = manifest.read_text(encoding="utf-8").split("\n")
        for index, line in enumerate(lines):
            if line.startswith("bundle_version\t"):
                lines[index] = f"bundle_version\t{version}"
                break
        else:
            self.fail("portable manifest has no bundle_version record")
        manifest.write_text("\n".join(lines), encoding="utf-8")

    def register_batch_targets(self, home: Path, *targets: Path) -> None:
        for target in targets:
            registered = self.run_installer(["--register", str(target)], home=home)
            self.assertEqual(registered.returncode, 0, registered.stderr)

    def run_target_cash(
        self,
        target: Path,
        *arguments: str,
        timeout: float | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(target / ".cash-skills" / "bin" / "cash"), *arguments],
            cwd=target,
            text=True,
            capture_output=True,
            timeout=timeout,
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

    def canonical_guidance(self, source: Path, relative: str) -> bytes:
        content = (source / relative).read_bytes()
        start = content.index(b"<!-- CASH:START -->")
        end_marker = b"<!-- CASH:END -->"
        end = content.index(end_marker, start) + len(end_marker)
        if content[end : end + 1] == b"\n":
            end += 1
        return content[start:end]

    def assert_guidance_install(
        self,
        target: Path,
        relative: str,
        before: bytes,
        expected: bytes,
    ) -> bytes:
        guidance = target / relative
        guidance.write_bytes(before)
        os.chmod(guidance, 0o600)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(guidance.read_bytes(), expected)
        self.assertEqual(stat.S_IMODE(guidance.stat().st_mode), 0o600)
        return guidance.read_bytes()

    def assert_guidance_failure_before_write(
        self,
        content: bytes,
        *,
        expected_diagnostic: str,
    ) -> None:
        for arguments in ((), ("--force",)):
            with self.subTest(arguments=arguments):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                guidance = target / "AGENTS.md"
                guidance.write_bytes(content)
                os.chmod(guidance, 0o600)

                result = self.install(target, *arguments)

                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(expected_diagnostic, result.stderr)
                self.assertIn("AGENTS.md", result.stderr)
                self.assertNotIn("source AGENTS.md", result.stderr)
                self.assertEqual(guidance.read_bytes(), content)
                self.assertEqual(stat.S_IMODE(guidance.stat().st_mode), 0o600)
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertFalse((target / ".cash-skills").exists())

    def test_guidance_mixed_legacy_suffix_converges(self) -> None:
        canonical = self.canonical_guidance(ROOT, "AGENTS.md")
        legacy = (
            b"<!-- SPECTRA:START v1.0.2 -->\n"
            b"legacy guidance\n"
            b"<!-- SPECTRA:END -->\n"
        )
        stale_cash = (
            b"<!-- CASH:START -->\n"
            b"stale Cash guidance\n"
            b"<!-- CASH:END -->\n"
        )
        suffix = b"project-owned suffix\n"
        fixtures = (
            (legacy + stale_cash + suffix, canonical + suffix),
            (
                b"project-owned prefix\n" + legacy + stale_cash + suffix,
                b"project-owned prefix\n" + canonical + suffix,
            ),
        )
        for relative in ("AGENTS.md", "CLAUDE.md"):
            canonical = self.canonical_guidance(ROOT, relative)
            for index, (before, expected) in enumerate(fixtures):
                with self.subTest(relative=relative, fixture=index):
                    temporary, target = self.make_target()
                    self.addCleanup(temporary.cleanup)
                    actual = self.assert_guidance_install(
                        target,
                        relative,
                        before,
                        expected.replace(
                            self.canonical_guidance(ROOT, "AGENTS.md"),
                            canonical,
                        ),
                    )
                    self.assertNotIn(b"SPECTRA:", actual)
                    self.assertEqual(actual.count(b"<!-- CASH:START -->"), 1)
                    self.assertEqual(actual.count(b"<!-- CASH:END -->"), 1)

    def test_guidance_legacy_only_suffix_migrates(self) -> None:
        legacy = (
            b"<!-- SPECTRA:START v1.0.2 -->\n"
            b"legacy guidance\n"
            b"<!-- SPECTRA:END -->\n"
        )
        prefix = b"project-owned prefix\n"
        suffix = b"project-owned suffix\n"
        for relative in ("AGENTS.md", "CLAUDE.md"):
            with self.subTest(relative=relative):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                canonical = self.canonical_guidance(ROOT, relative)
                actual = self.assert_guidance_install(
                    target,
                    relative,
                    prefix + legacy + suffix,
                    prefix + canonical + suffix,
                )
                self.assertNotIn(b"SPECTRA:", actual)
                self.assertEqual(actual.count(b"<!-- CASH:START -->"), 1)
                self.assertEqual(actual.count(b"<!-- CASH:END -->"), 1)

    def test_guidance_unsuffixed_markers_keep_existing_span_behavior(self) -> None:
        canonical = self.canonical_guidance(ROOT, "AGENTS.md")
        before = (
            b"project-owned prefix\n"
            b"<!-- SPECTRA:START -->\n"
            b"legacy guidance\n"
            b"<!-- SPECTRA:END -->\n"
            b"<!-- CASH:START -->\n"
            b"stale Cash guidance\n"
            b"<!-- CASH:END -->\n"
            b"project-owned suffix\n"
        )
        expected = (
            b"project-owned prefix\n"
            + canonical
            + b"project-owned suffix\n"
        )
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        self.assert_guidance_install(target, "AGENTS.md", before, expected)

    def test_guidance_suffix_applies_to_all_marker_kinds(self) -> None:
        canonical = self.canonical_guidance(ROOT, "AGENTS.md")
        cases = (
            (
                b"project-owned prefix\n"
                b"<!-- SPECTRA:START -->\n"
                b"legacy guidance\n"
                b"<!-- SPECTRA:END release -->\n"
                b"<!-- CASH:START -->\n"
                b"stale Cash guidance\n"
                b"<!-- CASH:END -->\n"
                b"project-owned suffix\n",
                b"project-owned prefix\n"
                + canonical
                + b"project-owned suffix\n",
            ),
            (
                b"project-owned prefix\n"
                b"<!-- CASH:START versioned -->\n"
                b"stale Cash guidance\n"
                b"<!-- CASH:END versioned -->\n"
                b"project-owned suffix\n",
                b"project-owned prefix\n"
                + canonical
                + b"project-owned suffix\n",
            ),
        )
        for index, (before, expected) in enumerate(cases):
            with self.subTest(case=index):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                actual = self.assert_guidance_install(
                    target, "AGENTS.md", before, expected
                )
                self.assertEqual(actual.count(b"<!-- CASH:START -->"), 1)
                self.assertEqual(actual.count(b"<!-- CASH:END -->"), 1)
                self.assertNotIn(b"CASH:START versioned", actual)
                self.assertNotIn(b"CASH:END versioned", actual)
                self.assertNotIn(b"SPECTRA:", actual)

        outputs = []
        for marker_suffix in (b"v1.0.2", b"arbitrary opaque suffix"):
            temporary, target = self.make_target()
            self.addCleanup(temporary.cleanup)
            before = (
                b"<!-- SPECTRA:START "
                + marker_suffix
                + b" -->\nlegacy guidance\n<!-- SPECTRA:END -->\n"
                b"<!-- CASH:START -->\nstale\n<!-- CASH:END -->\n"
            )
            outputs.append(
                self.assert_guidance_install(
                    target, "AGENTS.md", before, canonical
                )
            )
        self.assertEqual(outputs[0], outputs[1])

    def test_suffixed_malformed_guidance_fails_closed(self) -> None:
        cases = (
            (
                "isolated",
                b"<!-- SPECTRA:START versioned -->\nlegacy\n",
                "duplicate or unbalanced SPECTRA guidance marker",
            ),
            (
                "duplicate",
                b"<!-- SPECTRA:START one -->\n"
                b"<!-- SPECTRA:START two -->\nlegacy\n",
                "duplicate or unbalanced SPECTRA guidance marker",
            ),
            (
                "reversed",
                b"<!-- SPECTRA:END versioned -->\nlegacy\n"
                b"<!-- SPECTRA:START versioned -->\n",
                "reversed SPECTRA guidance marker",
            ),
            (
                "non-independent",
                b"<!-- SPECTRA:START versioned --> trailing\nlegacy\n"
                b"<!-- SPECTRA:END versioned -->\n",
                "malformed SPECTRA guidance marker",
            ),
            (
                "nested",
                b"<!-- CASH:START versioned -->\n"
                b"<!-- SPECTRA:START versioned -->\n"
                b"nested\n"
                b"<!-- CASH:END versioned -->\n"
                b"<!-- SPECTRA:END versioned -->\n",
                "nested guidance markers",
            ),
            (
                "carriage-return-in-suffix",
                b"<!-- SPECTRA:START versioned\rproject-owned -->\n"
                b"legacy\n"
                b"<!-- SPECTRA:END versioned -->\n",
                "duplicate or unbalanced SPECTRA guidance marker",
            ),
        )
        for label, content, diagnostic in cases:
            with self.subTest(case=label):
                self.assert_guidance_failure_before_write(
                    content,
                    expected_diagnostic=diagnostic,
                )

    def test_guidance_suffix_does_not_cross_comment_boundary(self) -> None:
        canonical = self.canonical_guidance(ROOT, "AGENTS.md")
        prefix = b"project-owned prefix <!-- CASH:START "
        before = (
            prefix
            + b"<!-- CASH:START -->\n"
            b"stale Cash guidance\n"
            b"<!-- CASH:END -->\n"
            b"project-owned suffix\n"
        )
        expected = prefix + canonical + b"project-owned suffix\n"
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        self.assert_guidance_install(target, "AGENTS.md", before, expected)

    def test_source_canonical_markers_reject_suffixes_before_target_write(self) -> None:
        for marker in (b"CASH:START", b"CASH:END"):
            with self.subTest(marker=marker):
                source_temp, source, _ = self.make_source_bundle()
                target_temp, target = self.make_target()
                self.addCleanup(source_temp.cleanup)
                self.addCleanup(target_temp.cleanup)
                guidance = source / "AGENTS.md"
                guidance.write_bytes(
                    guidance.read_bytes().replace(
                        b"<!-- " + marker + b" -->",
                        b"<!-- " + marker + b" versioned -->",
                        1,
                    )
                )

                result = self.install_from(source, target)

                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn("source AGENTS.md", result.stderr)
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertFalse((target / ".cash-skills").exists())
                self.assertFalse((target / "AGENTS.md").exists())
                self.assertFalse((target / "CLAUDE.md").exists())

    def test_source_marker_span_failure_names_source_guidance(self) -> None:
        source_temp, source, _ = self.make_source_bundle()
        target_temp, target = self.make_target()
        self.addCleanup(source_temp.cleanup)
        self.addCleanup(target_temp.cleanup)
        guidance = source / "AGENTS.md"
        content = guidance.read_bytes()
        guidance.write_bytes(
            content.replace(
                b"<!-- CASH:START -->",
                b"<!-- CASH:START -->\n<!-- CASH:START -->",
                1,
            )
        )

        result = self.install_from(source, target)

        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("duplicate or unbalanced CASH guidance marker", result.stderr)
        self.assertIn("source AGENTS.md", result.stderr)
        self.assertFalse((target / ".cash-workspace.lock").exists())
        self.assertFalse((target / ".cash-skills").exists())
        self.assertFalse((target / "AGENTS.md").exists())
        self.assertFalse((target / "CLAUDE.md").exists())

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

    def test_bundle_version_constant_matches_the_version_file(self) -> None:
        sys.path.insert(0, str(ROOT / ".cash-skills" / "lib"))
        from cash_cli.installer import BUNDLE_VERSION

        file_version = (ROOT / "cash-skills.version").read_text(encoding="ascii")
        self.assertEqual(
            BUNDLE_VERSION,
            file_version.removesuffix("\n"),
            f"BUNDLE_VERSION={BUNDLE_VERSION!r} but cash-skills.version={file_version!r}",
        )

    def test_bundle_runtime_paths_matches_the_source_inventory(self) -> None:
        sys.path.insert(0, str(ROOT / ".cash-skills" / "lib"))
        from cash_cli.installer import BUNDLE_RUNTIME_PATHS, source_inventory

        _, records, _ = source_inventory(ROOT)
        derived = tuple(
            record.path for record in records if record.kind == "runtime"
        )
        self.assertEqual(
            BUNDLE_RUNTIME_PATHS,
            derived,
            "BUNDLE_RUNTIME_PATHS is out of step with the source runtime inventory: "
            f"missing={sorted(set(derived) - set(BUNDLE_RUNTIME_PATHS))} "
            f"extra={sorted(set(BUNDLE_RUNTIME_PATHS) - set(derived))}",
        )

    def test_vendor_fresh_reports_update_and_portable_launcher_ignores_stale_receipt(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)

        result = self.assert_vendored(target)
        self.assertIn("Result: update", result.stdout)
        receipt = target / ".cash-skills" / "receipt.tsv"
        receipt.write_bytes(b"version\tstale\n")
        os.chmod(receipt, 0o600)
        before = self.workspace_snapshot(target)

        launched = self.run_target_cash(target, "list", "--json")

        self.assertEqual(launched.returncode, 0, launched.stdout + launched.stderr)
        self.assertEqual(launched.stdout, '{"changes":[]}\n')
        self.assertEqual(self.workspace_snapshot(target), before)

    def test_portable_help_and_generation_share_the_stable_lock(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assert_vendored(target)
        lock = target / ".cash-workspace.lock"

        with lock.open("rb") as lock_file:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
            process = subprocess.Popen(
                [str(target / ".cash-skills" / "bin" / "cash"), "--help"],
                cwd=target,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.addCleanup(lambda: process.poll() is None and process.kill())
            time.sleep(0.2)
            self.assertIsNone(
                process.poll(),
                "portable help must wait for the stable generation lock",
            )
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)

        stdout, stderr = process.communicate(timeout=20)
        self.assertEqual(process.returncode, 0, stdout + stderr)
        invalid = target / ".cash-skills" / "manifest.tsv"
        invalid.write_bytes(b"format\tbroken\n")
        failed_help = self.run_target_cash(target, "--help")
        self.assertEqual(failed_help.returncode, 1)
        self.assertIn("error[manifest_invalid]", failed_help.stderr)

    def test_portable_import_ignores_valid_timestamp_pyc_and_writes_nothing(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assert_vendored(target)
        runtime = target / ".cash-skills" / "lib" / "cash_cli" / "errors.py"
        marker = target / "malicious-pyc-ran"
        metadata = runtime.stat()
        payload = (
            "from pathlib import Path\n"
            f"Path({str(marker)!r}).write_text('ran')\n"
        )
        self.assertLess(len(payload.encode()), metadata.st_size)
        payload += "#" + ("x" * (metadata.st_size - len(payload.encode()) - 1))
        code = compile(payload, str(runtime), "exec")
        pyc = Path(importlib.util.cache_from_source(str(runtime)))
        pyc.parent.mkdir(parents=True, exist_ok=True)
        pyc.write_bytes(
            importlib.util.MAGIC_NUMBER
            + struct.pack(
                "<III",
                0,
                int(metadata.st_mtime),
                metadata.st_size,
            )
            + marshal.dumps(code)
        )
        before = self.workspace_snapshot(target)

        launched = self.run_target_cash(target, "list", "--json")

        self.assertEqual(launched.returncode, 0, launched.stdout + launched.stderr)
        self.assertFalse(marker.exists(), "portable import executed unverified .pyc bytes")
        self.assertEqual(self.workspace_snapshot(target), before)

    def test_manifest_present_unsafe_shapes_fail_before_open_without_receipt_fallback(
        self,
    ) -> None:
        for shape in ("fifo", "broken-symlink", "directory", "hard-link"):
            with self.subTest(shape=shape):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                self.assert_vendored(target)
                manifest = target / ".cash-skills" / "manifest.tsv"
                receipt = target / ".cash-skills" / "receipt.tsv"
                receipt.write_bytes(b"version\tvalid-looking-residue\n")
                manifest.unlink()
                if shape == "fifo":
                    os.mkfifo(manifest)
                elif shape == "broken-symlink":
                    manifest.symlink_to(target / "missing-manifest")
                elif shape == "directory":
                    manifest.mkdir()
                else:
                    outside = target / "manifest-hardlink-source"
                    outside.write_bytes(b"format\tcash-portable-manifest-v1\n")
                    os.link(outside, manifest)

                launched = self.run_target_cash(target, "list", "--json", timeout=2)

                self.assertEqual(launched.returncode, 1)
                self.assertIn('"code":"manifest_invalid"', launched.stdout)
                self.assertNotIn('"code":"receipt_invalid"', launched.stdout)

    def test_executable_manifest_and_manifest_schema_drift_fail_closed(self) -> None:
        mutations = ("executable", "schema", "duplicate", "unknown-kind")
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                self.assert_vendored(target)
                manifest = target / ".cash-skills" / "manifest.tsv"
                if mutation == "executable":
                    os.chmod(manifest, 0o755)
                else:
                    lines = manifest.read_text(encoding="utf-8").splitlines()
                    if mutation == "schema":
                        lines[0] = "format\tcash-portable-manifest-v999"
                    elif mutation == "duplicate":
                        lines.append(lines[-1])
                    else:
                        fields = lines[-1].split("\t")
                        fields[0] = "unknown"
                        lines[-1] = "\t".join(fields)
                    manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")

                launched = self.run_target_cash(target, "list", "--json")

                self.assertEqual(launched.returncode, 1)
                self.assertIn('"code":"manifest_invalid"', launched.stdout)

    def test_portable_runtime_expected_set_rejects_missing_and_extra_python(
        self,
    ) -> None:
        for mutation in ("missing", "extra"):
            with self.subTest(mutation=mutation):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                self.assert_vendored(target)
                runtime_root = target / ".cash-skills" / "lib" / "cash_cli"
                if mutation == "missing":
                    (runtime_root / "errors.py").unlink()
                else:
                    (runtime_root / "unexpected.py").write_text(
                        "VALUE = 1\n",
                        encoding="utf-8",
                    )

                launched = self.run_target_cash(target, "list", "--json")

                self.assertEqual(launched.returncode, 1)
                self.assertIn('"code":"manifest_invalid"', launched.stdout)
                expected_path = "errors.py" if mutation == "missing" else "unexpected.py"
                self.assertIn(expected_path, launched.stdout)

    def test_portable_stable_drift_uses_manifest_error_contract(self) -> None:
        for path, mutation in (
            (".cash-skills/bin/cash", "non-executable"),
            (".cash-workspace.lock", "executable"),
            (".cash-workspace.lock", "hard-link"),
        ):
            with self.subTest(path=path, mutation=mutation):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                self.assert_vendored(target)
                managed = target / path
                if mutation == "non-executable":
                    os.chmod(managed, 0o644)
                elif mutation == "executable":
                    os.chmod(managed, 0o755)
                else:
                    content = managed.read_bytes()
                    managed.unlink()
                    source = target / "lock-hardlink-source"
                    source.write_bytes(content)
                    os.chmod(source, 0o644)
                    os.link(source, managed)
                command = [str(target / ".cash-skills" / "bin" / "cash")]
                if path.endswith("/cash") and mutation == "non-executable":
                    command.insert(0, sys.executable)
                launched = subprocess.run(
                    [*command, "list", "--json"],
                    cwd=target,
                    text=True,
                    capture_output=True,
                )

                self.assertEqual(launched.returncode, 1)
                self.assertIn('"code":"manifest_invalid"', launched.stdout)
                self.assertNotIn('"code":"bootstrap_invalid"', launched.stdout)

    def test_portable_git_logical_modes_accept_umask_classes_and_zero_write(
        self,
    ) -> None:
        for group_writable in (False, True):
            with self.subTest(group_writable=group_writable):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                self.assert_vendored(target)
                for path in target.rglob("*"):
                    if ".git" in path.parts or not path.is_file():
                        continue
                    mode = stat.S_IMODE(path.stat().st_mode)
                    if group_writable:
                        os.chmod(path, mode | stat.S_IWGRP)
                    else:
                        os.chmod(path, mode & ~stat.S_IWGRP)
                before = self.workspace_snapshot(target)

                launched = self.run_target_cash(target, "list", "--json")

                self.assertEqual(launched.returncode, 0, launched.stdout + launched.stderr)
                self.assertEqual(self.workspace_snapshot(target), before)

    def test_vendor_preflight_reports_all_git_excluded_planned_paths_before_write(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        (target / ".gitignore").write_text(
            ".cash-skills/\n.agents/\n.claude/\nAGENTS.md\nCLAUDE.md\n",
            encoding="utf-8",
        )

        result = self.vendor(target, "--force")

        self.assertEqual(result.returncode, 1)
        for expected in (
            ".cash-skills/bin/cash",
            ".agents/skills/cash-apply/SKILL.md",
            ".claude/skills/cash-apply/SKILL.md",
            "AGENTS.md",
            "CLAUDE.md",
        ):
            self.assertIn(expected, result.stderr)
        self.assertFalse((target / ".cash-skills" / "manifest.tsv").exists())
        self.assertFalse((target / ".cash-workspace.lock").exists())

    def test_vendor_git_queries_disable_fsmonitor_and_fail_closed_on_index_error(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        marker = target / "fsmonitor-ran"
        monitor = target / "fsmonitor.sh"
        monitor.write_text(
            "#!/bin/sh\n"
            f"printf ran > {shlex.quote(str(marker))}\n",
            encoding="utf-8",
        )
        os.chmod(monitor, 0o755)
        subprocess.run(
            ["git", "-C", str(target), "config", "core.fsmonitor", str(monitor)],
            check=True,
        )

        result = self.vendor(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(marker.exists(), "vendor preflight executed core.fsmonitor")

        broken_temp, broken = self.make_target()
        self.addCleanup(broken_temp.cleanup)
        (broken / ".git" / "index").write_bytes(b"invalid index\n")
        rejected = self.vendor(broken)
        self.assertEqual(rejected.returncode, 1)
        self.assertIn("cannot query Git index", rejected.stderr)

    def test_vendor_receiptless_exact_partial_force_and_unknown_extra_adoption(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        installed = self.install(target)
        self.assertEqual(installed.returncode, 0, installed.stderr)
        receipt = target / ".cash-skills" / "receipt.tsv"
        receipt.unlink()
        launcher_inode = (target / ".cash-skills" / "bin" / "cash").stat().st_ino

        adopted = self.assert_vendored(target)

        self.assertIn("Result: update", adopted.stdout)
        self.assertEqual(
            (target / ".cash-skills" / "bin" / "cash").stat().st_ino,
            launcher_inode,
        )

        partial_temp, partial = self.make_target()
        self.addCleanup(partial_temp.cleanup)
        installed = self.install(partial)
        self.assertEqual(installed.returncode, 0, installed.stderr)
        (partial / ".cash-skills" / "receipt.tsv").unlink()
        (partial / ".cash-skills" / "lib" / "cash_cli" / "errors.py").unlink()
        conflict = self.vendor(partial)
        self.assertEqual(conflict.returncode, 0, conflict.stderr)
        self.assertIn("Result: conflict", conflict.stdout)
        forced = self.assert_vendored(partial, "--force")
        self.assertIn("Result: update", forced.stdout)

        extra_temp, extra = self.make_target()
        self.addCleanup(extra_temp.cleanup)
        installed = self.install(extra)
        self.assertEqual(installed.returncode, 0, installed.stderr)
        (extra / ".cash-skills" / "receipt.tsv").unlink()
        (extra / ".cash-skills" / "lib" / "cash_cli" / "extra.py").write_text(
            "VALUE = 1\n",
            encoding="utf-8",
        )
        rejected = self.vendor(extra, "--force")
        self.assertEqual(rejected.returncode, 1)
        self.assertIn("extra.py", rejected.stderr)

    def test_vendor_current_update_receipt_conversion_and_direct_mode_rejection(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assert_vendored(target)
        before = self.workspace_snapshot(target)
        current = self.assert_vendored(target)
        self.assertIn("Result: current", current.stdout)
        self.assertEqual(self.workspace_snapshot(target), before)

        receipt_temp, receipt_target = self.make_target()
        self.addCleanup(receipt_temp.cleanup)
        direct = self.install(receipt_target)
        self.assertEqual(direct.returncode, 0, direct.stderr)
        self.assert_vendored(receipt_target)
        self.assertFalse((receipt_target / ".cash-skills" / "receipt.tsv").exists())

        rejected = self.install(target)
        self.assertEqual(rejected.returncode, 1)
        self.assertIn("--vendor", rejected.stderr)

    def test_vendor_updates_across_runtime_inventory_changes(self) -> None:
        for mutation in ("source-added", "source-removed"):
            with self.subTest(mutation=mutation):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                self.assert_vendored(target)
                manifest = target / ".cash-skills" / "manifest.tsv"
                lines = manifest.read_text(encoding="utf-8").splitlines()
                runtime_rows = [
                    line for line in lines[3:] if line.startswith("runtime\t")
                ]
                if mutation == "source-added":
                    removed = runtime_rows[-1]
                    relative = removed.split("\t")[1]
                    lines.remove(removed)
                    (target / relative).unlink()
                else:
                    relative = ".cash-skills/lib/cash_cli/retired.py"
                    content = b"RETIRED = True\n"
                    (target / relative).write_bytes(content)
                    added = (
                        f"runtime\t{relative}\t{hashlib.sha256(content).hexdigest()}"
                        "\t100644"
                    )
                    skill_index = next(
                        index
                        for index, line in enumerate(lines)
                        if line.startswith("skill\t")
                    )
                    lines.insert(skill_index, added)
                headers = lines[:3]
                stable = [
                    line for line in lines[3:] if line.startswith("stable\t")
                ]
                runtime = sorted(
                    (
                        line
                        for line in lines[3:]
                        if line.startswith("runtime\t")
                    ),
                    key=lambda line: line.split("\t")[1].encode("utf-8"),
                )
                skills = [
                    line for line in lines[3:] if line.startswith("skill\t")
                ]
                lines = [*headers, *stable, *runtime, *skills]
                lines[1] = "bundle_version\t2.11.0"
                runtime_rows = sorted(
                    (
                        line.split("\t")
                        for line in lines[3:]
                        if line.startswith("runtime\t")
                    ),
                    key=lambda row: row[1].encode("utf-8"),
                )
                stream = "".join(
                    f"{row[1]}\t{row[2]}\t0644\n" for row in runtime_rows
                ).encode("utf-8")
                lines[2] = (
                    "runtime_generation\t" + hashlib.sha256(stream).hexdigest()
                )
                manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")

                updated = self.vendor(target)

                self.assertEqual(updated.returncode, 0, updated.stderr)
                self.assertIn("Result: update", updated.stdout)
                expected = mutation == "source-added"
                self.assertEqual((target / relative).exists(), expected)
                launched = self.run_target_cash(target, "list", "--json")
                self.assertEqual(
                    launched.returncode,
                    0,
                    launched.stdout + launched.stderr,
                )

    def test_vendor_rejects_runtime_symlink_directory_instead_of_current(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assert_vendored(target)
        outside = target / "outside-runtime"
        outside.mkdir()
        symlink = target / ".cash-skills" / "lib" / "cash_cli" / "linked"
        symlink.symlink_to(outside, target_is_directory=True)

        result = self.vendor(target)

        self.assertEqual(result.returncode, 1)
        self.assertIn("runtime directory is a symlink", result.stderr)

    def test_vendor_revalidates_source_and_target_plans_after_lock_wait(
        self,
    ) -> None:
        for mutation in ("source-runtime", "target-guidance"):
            with self.subTest(mutation=mutation):
                source_temp, source, _ = self.make_source_bundle()
                self.addCleanup(source_temp.cleanup)
                target_temp, target = self.make_target()
                self.addCleanup(target_temp.cleanup)
                barrier = Path(target_temp.name) / "git-preflight"
                ready = barrier.with_suffix(".ready")
                release = barrier.with_suffix(".release")
                shim_directory = Path(target_temp.name) / "git-shim"
                shim_directory.mkdir()
                git = shutil.which("git")
                self.assertIsNotNone(git)
                shim = shim_directory / "git"
                shim.write_text(
                    "#!/bin/sh\n"
                    "pause=0\n"
                    'for argument in "$@"; do\n'
                    '  if [ "$argument" = "ls-files" ]; then pause=1; fi\n'
                    "done\n"
                    f"if [ \"$pause\" = 1 ] && [ ! -e {shlex.quote(str(ready))} ]; then\n"
                    f"  printf 'ready\\n' > {shlex.quote(str(ready))}\n"
                    f"  while [ ! -e {shlex.quote(str(release))} ]; do sleep 0.01; done\n"
                    "fi\n"
                    f"exec {shlex.quote(str(git))} \"$@\"\n",
                    encoding="utf-8",
                )
                os.chmod(shim, 0o755)
                environment = {
                    name: value
                    for name, value in os.environ.items()
                    if not name.startswith("CASH_INSTALL_")
                    and not name.startswith("TEST_CASH_INSTALL_")
                }
                environment["PATH"] = (
                    str(shim_directory)
                    + os.pathsep
                    + environment.get("PATH", "")
                )
                process = subprocess.Popen(
                    [
                        "fish",
                        "--no-config",
                        str(source / "install-cash-skills.fish"),
                        "--vendor",
                        str(target),
                    ],
                    cwd=source,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=environment,
                )
                self.addCleanup(
                    lambda process=process: (
                        process.poll() is None and process.kill()
                    )
                )
                deadline = time.monotonic() + 10
                while (
                    not ready.exists()
                    and process.poll() is None
                    and time.monotonic() < deadline
                ):
                    time.sleep(0.01)
                self.assertTrue(ready.exists(), "Git preflight barrier was not reached")
                self.assertIsNone(process.poll())
                if mutation == "source-runtime":
                    changed = (
                        source
                        / ".cash-skills"
                        / "lib"
                        / "cash_cli"
                        / "errors.py"
                    )
                    changed.write_bytes(changed.read_bytes() + b"\n")
                else:
                    (target / "AGENTS.md").write_text(
                        "concurrent project guidance\n",
                        encoding="utf-8",
                    )
                release.write_text("release\n", encoding="utf-8")

                stdout, stderr = process.communicate(timeout=20)
                self.assertEqual(process.returncode, 1, stdout + stderr)
                self.assertIn("changed before lock acquisition", stderr)
                self.assertFalse(
                    (target / ".cash-skills" / "manifest.tsv").exists()
                )
                if mutation == "target-guidance":
                    self.assertEqual(
                        (target / "AGENTS.md").read_text(encoding="utf-8"),
                        "concurrent project guidance\n",
                    )

    def test_launcher_transition_and_journal_v3_contract_surface_is_explicit(
        self,
    ) -> None:
        sys.path.insert(0, str(ROOT / ".cash-skills" / "lib"))
        from cash_cli import installer

        self.assertTrue(
            hasattr(installer, "APPROVED_LAUNCHER_TRANSITIONS"),
            "skipped-version launcher migration requires "
            "APPROVED_LAUNCHER_TRANSITIONS",
        )
        transitions = installer.APPROVED_LAUNCHER_TRANSITIONS
        self.assertTrue(transitions)
        for transition in transitions:
            self.assertEqual(len(transition), 3)
            old_digest, new_digest, introduced_version = transition
            self.assertRegex(old_digest, r"^[0-9a-f]{64}$")
            self.assertRegex(new_digest, r"^[0-9a-f]{64}$")
            self.assertRegex(introduced_version, r"^[0-9]+\.[0-9]+\.[0-9]+$")
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        journal = json.loads(
            installer.InstallTransaction(target)._journal(0).decode("utf-8")
        )
        self.assertEqual(
            journal["version"],
            3,
            "launcher/receipt/cutover recovery requires journal schema v3",
        )

    def test_schema_v2_recovery_remains_supported_before_vendor_classification(
        self,
    ) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        published = b"half-published\n"
        (target / ".cash-workspace.lock").touch(mode=0o644)
        journal = self.seed_publishing_journal(
            target,
            [(".gitignore", None, 0o644, published)],
            version=2,
        )

        result = self.vendor(target)

        self.assertEqual(
            result.returncode,
            0,
            "schema v2 recovery must run before vendored target classification: "
            + result.stderr,
        )
        self.assertFalse(journal.exists())
        self.assertTrue((target / ".cash-skills" / "manifest.tsv").is_file())

    def test_vendor_faults_before_and_after_manifest_recover_to_one_complete_gate(
        self,
    ) -> None:
        for path, expected_gate in (
            (".cash-skills/lib/cash_cli/errors.py", "receipt-or-bootstrap"),
            (".cash-skills/manifest.tsv", "portable"),
            (".cash-skills/receipt.tsv", "portable"),
        ):
            with self.subTest(path=path):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                if path == ".cash-skills/receipt.tsv":
                    installed = self.install(target)
                    self.assertEqual(installed.returncode, 0, installed.stderr)
                result = self.vendor(
                    target,
                    env={
                        "TEST_CASH_INSTALL_TEST_HOOKS": "1",
                        "TEST_CASH_INSTALL_FAIL_AFTER_PATH": path,
                    },
                )
                self.assertEqual(result.returncode, 1)
                recovered = self.vendor(target)
                self.assertEqual(recovered.returncode, 0, recovered.stderr)
                manifest = target / ".cash-skills" / "manifest.tsv"
                receipt = target / ".cash-skills" / "receipt.tsv"
                if expected_gate == "portable":
                    self.assertTrue(manifest.is_file())
                    self.assertFalse(receipt.exists())
                    launched = self.run_target_cash(target, "list", "--json")
                    self.assertEqual(
                        launched.returncode,
                        0,
                        launched.stdout + launched.stderr,
                    )
                else:
                    self.assertTrue(manifest.is_file())

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

    def test_bare_target_bootstraps_openspec_config(self) -> None:
        temporary, target = self.make_bare_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: update", result.stdout)
        sys.path.insert(0, str(ROOT / ".cash-skills" / "lib"))
        from cash_cli.config import parse_openspec_config
        from cash_cli.installer import OPENSPEC_CONFIG_BASELINE

        config = target / "openspec" / "config.yaml"
        metadata = config.stat()
        self.assertTrue(stat.S_ISREG(metadata.st_mode))
        self.assertEqual(metadata.st_nlink, 1)
        self.assertEqual(stat.S_IMODE(metadata.st_mode), 0o644)
        self.assertEqual(config.read_bytes(), OPENSPEC_CONFIG_BASELINE)
        parse_openspec_config(
            config.read_text(encoding="utf-8"),
            path="openspec/config.yaml",
        )
        self.assertEqual(
            {entry.name for entry in (target / "openspec").iterdir()},
            {"config.yaml"},
        )
        receipt = (target / ".cash-skills" / "receipt.tsv").read_text(
            encoding="utf-8"
        )
        self.assertNotIn("openspec/config.yaml", receipt)

    def test_bootstrapped_openspec_config_is_zero_write_and_current(self) -> None:
        temporary, target = self.make_bare_target()
        self.addCleanup(temporary.cleanup)
        installed = self.install(target)
        self.assertEqual(installed.returncode, 0, installed.stderr)
        config = target / "openspec" / "config.yaml"
        before = (config.read_bytes(), config.stat().st_ino)

        repeated = self.install(target)

        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertIn("Result: current", repeated.stdout)
        self.assertEqual((config.read_bytes(), config.stat().st_ino), before)

    def test_existing_valid_openspec_config_is_preserved_byte_for_byte(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        config = target / "openspec" / "config.yaml"
        existing = (
            b"schema: spec-driven\n"
            b"context: |\n"
            b"  Keep this project-owned context.\n"
            b"rules:\n"
            b"  proposal:\n"
            b"    - Keep this project-owned rule.\n"
        )
        config.write_bytes(existing)
        before_inode = config.stat().st_ino

        result = self.install(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(config.read_bytes(), existing)
        self.assertEqual(config.stat().st_ino, before_inode)

    def test_openspec_config_unsafe_shapes_fail_closed_before_any_write(self) -> None:
        for shape in ("symlink", "directory", "hardlink", "fifo"):
            for arguments in ((), ("--force",)):
                with self.subTest(shape=shape, arguments=arguments):
                    temporary, target = self.make_bare_target()
                    self.addCleanup(temporary.cleanup)
                    openspec = target / "openspec"
                    openspec.mkdir()
                    config = openspec / "config.yaml"
                    if shape == "symlink":
                        outside = target / "outside-config.yaml"
                        outside.write_bytes(b"schema: spec-driven\n")
                        config.symlink_to(outside)
                    elif shape == "directory":
                        config.mkdir()
                    elif shape == "hardlink":
                        original = target / "original-config.yaml"
                        original.write_bytes(b"schema: spec-driven\n")
                        os.link(original, config)
                    else:
                        os.mkfifo(config)

                    result = self.install(
                        target,
                        *arguments,
                        timeout=5,
                    )

                    self.assertEqual(result.returncode, 1, result.stdout)
                    self.assertFalse((target / ".cash-workspace.lock").exists())
                    self.assertFalse((target / ".cash-skills").exists())
                    self.assertFalse((target / ".cash.yaml").exists())
                    metadata = os.lstat(config)
                    if shape == "symlink":
                        self.assertTrue(stat.S_ISLNK(metadata.st_mode))
                    elif shape == "directory":
                        self.assertTrue(stat.S_ISDIR(metadata.st_mode))
                    elif shape == "hardlink":
                        self.assertEqual(metadata.st_nlink, 2)
                    else:
                        self.assertTrue(stat.S_ISFIFO(metadata.st_mode))

    def test_invalid_openspec_config_fails_closed_even_with_force(self) -> None:
        for arguments in ((), ("--force",)):
            with self.subTest(arguments=arguments):
                temporary, target = self.make_target()
                self.addCleanup(temporary.cleanup)
                config = target / "openspec" / "config.yaml"
                invalid = b"schema: unknown\n"
                config.write_bytes(invalid)

                result = self.install(target, *arguments, timeout=5)

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("invalid target openspec/config.yaml", result.stderr)
                self.assertEqual(config.read_bytes(), invalid)
                self.assertFalse((target / ".cash-workspace.lock").exists())
                self.assertFalse((target / ".cash-skills").exists())

    def test_bare_target_dry_run_reports_update_without_writes(self) -> None:
        temporary, target = self.make_bare_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(target, "--dry-run", timeout=5)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Result: update", result.stdout)
        self.assertFalse((target / "openspec").exists())
        self.assertFalse((target / ".cash-workspace.lock").exists())
        self.assertFalse((target / ".cash-skills").exists())

    def test_source_self_does_not_bootstrap_missing_openspec_config(self) -> None:
        for arguments in ((), ("--dry-run",)):
            with self.subTest(arguments=arguments):
                temporary, source = self.make_self_source()
                self.addCleanup(temporary.cleanup)
                config = source / "openspec" / "config.yaml"
                config.unlink()
                receipt = source / ".cash-skills" / "receipt.tsv"

                result = self.self_install(source, *arguments)

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertFalse(config.exists())
                self.assertFalse(receipt.exists())

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

    def test_publication_failure_rolls_back_bootstrapped_openspec_config(self) -> None:
        temporary, target = self.make_bare_target()
        self.addCleanup(temporary.cleanup)

        result = self.install(
            target,
            env={
                "TEST_CASH_INSTALL_TEST_HOOKS": "1",
                "TEST_CASH_INSTALL_FAIL_AFTER_PATH": ".gitignore",
            },
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "injected publication failure after .gitignore",
            result.stderr,
        )
        self.assertFalse((target / "openspec" / "config.yaml").exists())
        self.assertFalse((target / ".cash-skills" / "receipt.tsv").exists())

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
        self.assertIn("target-specific inode identity", result.stderr)
        self.assertNotIn("device", result.stderr)
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
        manifest = source / ".cash-skills" / "manifest.tsv"
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
        self.assertFalse(manifest.exists())

        bootstrapped = self.self_install(source)
        self.assertEqual(bootstrapped.returncode, 0, bootstrapped.stderr)
        self.assertIn("Result: bootstrap", bootstrapped.stdout)
        self.assertTrue(manifest.is_file())
        self.assertFalse(receipt.exists())
        expected_manifest = manifest.read_bytes()
        manifest.write_text("format\tbroken\n", encoding="utf-8")
        invalid = subprocess.run(
            [str(launcher), "list", "--json"],
            cwd=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(invalid.returncode, 1)
        self.assertIn('"code":"manifest_invalid"', invalid.stdout)
        repaired = self.self_install(source)
        self.assertEqual(repaired.returncode, 0, repaired.stderr)
        self.assertIn("Result: bootstrap", repaired.stdout)
        self.assertEqual(manifest.read_bytes(), expected_manifest)
        self.assertFalse(receipt.exists())
        first_manifest = (
            manifest.read_bytes(),
            stat.S_IMODE(manifest.stat().st_mode),
            manifest.stat().st_ino,
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
                manifest.read_bytes(),
                stat.S_IMODE(manifest.stat().st_mode),
                manifest.stat().st_ino,
            ),
            first_manifest,
        )
        for path, snapshot in before.items():
            self.assertEqual(
                (path.read_bytes(), stat.S_IMODE(path.stat().st_mode), path.stat().st_ino),
                snapshot,
            )
        self.assertFalse((source / ".cash-skills" / "state").exists())
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

    def test_register_accepts_missing_openspec_config_without_creating_it(self) -> None:
        home = tempfile.TemporaryDirectory()
        temporary, target = self.make_bare_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(temporary.cleanup)

        result = self.run_installer(
            ["--register", str(target)],
            home=Path(home.name),
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((target / "openspec" / "config.yaml").exists())
        registry = (
            Path(home.name)
            / ".config"
            / "cash-skills"
            / "projects.txt"
        )
        self.assertEqual(registry.read_text(encoding="utf-8"), f"{target.resolve()}\n")

    def test_register_rejects_unsafe_or_invalid_openspec_config_without_write(
        self,
    ) -> None:
        for shape in ("symlink", "invalid"):
            with self.subTest(shape=shape):
                home = tempfile.TemporaryDirectory()
                temporary, target = self.make_bare_target()
                self.addCleanup(home.cleanup)
                self.addCleanup(temporary.cleanup)
                openspec = target / "openspec"
                openspec.mkdir()
                config = openspec / "config.yaml"
                if shape == "symlink":
                    outside = target / "outside-config.yaml"
                    outside.write_bytes(b"schema: spec-driven\n")
                    config.symlink_to(outside)
                else:
                    config.write_bytes(b"schema: unknown\n")

                result = self.run_installer(
                    ["--register", str(target)],
                    home=Path(home.name),
                )

                self.assertEqual(result.returncode, 1, result.stdout)
                if shape == "invalid":
                    self.assertIn(
                        "invalid target openspec/config.yaml",
                        result.stderr,
                    )
                registry = (
                    Path(home.name)
                    / ".config"
                    / "cash-skills"
                    / "projects.txt"
                )
                self.assertFalse(registry.exists())

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

    def test_batch_dispatches_vendored_and_receipt_targets(self) -> None:
        home = tempfile.TemporaryDirectory()
        vendored_temp, vendored = self.make_target()
        receipt_temp, receipt = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(vendored_temp.cleanup)
        self.addCleanup(receipt_temp.cleanup)
        self.register_batch_targets(Path(home.name), vendored, receipt)
        self.assert_vendored(vendored)
        self.set_manifest_bundle_version(vendored, "2.20.0")
        (vendored / ".cash-skills" / "receipt.tsv").write_bytes(b"version\t2.20.0\n")

        batch = self.run_installer(["--all"], home=Path(home.name))

        self.assertEqual(batch.returncode, 0, batch.stderr)
        self.assertIn(f"updated: {vendored.resolve()} (vendored)", batch.stdout)
        self.assertIn(f"updated: {receipt.resolve()}\n", batch.stdout)
        self.assertNotIn(f"{receipt.resolve()} (vendored)", batch.stdout)
        self.assertIn("updated=2", batch.stdout)
        self.assertIn("failed=0", batch.stdout)
        self.assertTrue((vendored / ".cash-skills" / "manifest.tsv").is_file())
        self.assertFalse(
            (vendored / ".cash-skills" / "receipt.tsv").exists(),
            "batch vendored dispatch must clear the machine-local receipt residue",
        )
        self.assertTrue((receipt / ".cash-skills" / "receipt.tsv").is_file())

    def test_batch_dry_run_reports_would_update_for_vendored_target(self) -> None:
        home = tempfile.TemporaryDirectory()
        temporary, target = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(temporary.cleanup)
        self.register_batch_targets(Path(home.name), target)
        self.assert_vendored(target)
        self.set_manifest_bundle_version(target, "2.20.0")
        residue = target / ".cash-skills" / "receipt.tsv"
        residue.write_bytes(b"version\t2.20.0\n")
        before = self.workspace_snapshot(target)

        batch = self.run_installer(["--all", "--dry-run"], home=Path(home.name))

        self.assertEqual(batch.returncode, 0, batch.stderr)
        self.assertIn(f"would-update: {target.resolve()} (vendored)", batch.stdout)
        self.assertIn("would-update=1", batch.stdout)
        self.assertTrue(
            residue.is_file(),
            "a dry-run early return must not delete the receipt residue",
        )
        self.assertEqual(self.workspace_snapshot(target), before)

    def test_batch_unsafe_manifest_shape_fails_closed_without_blocking(self) -> None:
        expectations = {
            "symlink": ("symlink managed boundary: .cash-skills/manifest.tsv", False),
            "fifo": ("target is managed by a portable manifest; use --vendor", False),
            "directory": ("target is managed by a portable manifest; use --vendor", False),
            "hard-link": ("unsafe regular file identity", True),
        }
        for shape, (diagnostic, vendored) in expectations.items():
            with self.subTest(shape=shape):
                home = tempfile.TemporaryDirectory()
                temporary, target = self.make_target()
                self.addCleanup(home.cleanup)
                self.addCleanup(temporary.cleanup)
                self.register_batch_targets(Path(home.name), target)
                self.assert_vendored(target)
                manifest = target / ".cash-skills" / "manifest.tsv"
                content = manifest.read_bytes()
                manifest.unlink()
                if shape == "symlink":
                    manifest.symlink_to(target / "missing-manifest")
                elif shape == "fifo":
                    os.mkfifo(manifest)
                elif shape == "directory":
                    manifest.mkdir()
                else:
                    outside = target / "manifest-hardlink-source"
                    outside.write_bytes(content)
                    os.link(outside, manifest)
                before = self.workspace_snapshot(target)

                # Bounded so that a dispatch regression which sends a FIFO
                # manifest down the vendored path fails here instead of
                # blocking forever inside read_regular.
                batch = self.run_installer(
                    ["--all"],
                    home=Path(home.name),
                    timeout=60,
                )

                self.assertEqual(batch.returncode, 1, batch.stdout)
                self.assertIn(diagnostic, batch.stderr)
                suffix = " (vendored)" if vendored else ""
                self.assertIn(f"failed: {target.resolve()}{suffix}\n", batch.stdout)
                if not vendored:
                    self.assertNotIn(f"{target.resolve()} (vendored)", batch.stdout)
                self.assertIn("failed=1", batch.stdout)
                self.assertEqual(self.workspace_snapshot(target), before)

    def test_batch_probe_exception_does_not_abort_remaining_records(self) -> None:
        home = tempfile.TemporaryDirectory()
        broken_temp, broken = self.make_target()
        healthy_temp, healthy = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(broken_temp.cleanup)
        self.addCleanup(healthy_temp.cleanup)
        self.register_batch_targets(Path(home.name), broken, healthy)
        # --register refuses the canonical source, so the only way a source
        # record reaches the batch is a hand-edited registry; probe must leave
        # it on the receipt path so the existing non-source diagnostic stands.
        registry = Path(home.name) / ".config" / "cash-skills" / "projects.txt"
        registry.write_text(
            registry.read_text(encoding="utf-8") + f"{ROOT}\n",
            encoding="utf-8",
        )
        (broken / ".cash-skills").write_bytes(b"not a directory\n")

        batch = self.run_installer(["--all"], home=Path(home.name))

        self.assertEqual(batch.returncode, 1, batch.stdout)
        self.assertIn(f"failed: {broken.resolve()}\n", batch.stdout)
        self.assertIn("managed parent is not a directory", batch.stderr)
        self.assertIn(f"updated: {healthy.resolve()}\n", batch.stdout)
        self.assertIn("Summary:", batch.stdout)
        self.assertNotIn("Traceback (most recent call last)", batch.stderr)
        self.assertIn(f"failed: {ROOT}\n", batch.stdout)
        self.assertIn("target must be an existing non-source directory", batch.stderr)
        self.assertNotIn("vendor target must be", batch.stderr)

    def test_batch_force_converges_only_replaceable_vendored_bytes(self) -> None:
        home = tempfile.TemporaryDirectory()
        drifted_temp, drifted = self.make_target()
        newer_temp, newer = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(drifted_temp.cleanup)
        self.addCleanup(newer_temp.cleanup)
        self.register_batch_targets(Path(home.name), drifted, newer)
        self.assert_vendored(drifted)
        self.assert_vendored(newer)
        self.set_manifest_bundle_version(newer, "9.0.0")
        newer_residue = newer / ".cash-skills" / "receipt.tsv"
        newer_residue.write_bytes(b"version\t2.20.0\n")
        newer_before = self.workspace_snapshot(newer)
        managed = ".cash-skills/lib/cash_cli/errors.py"
        canonical = (ROOT / managed).read_bytes()
        (drifted / managed).write_bytes(canonical + b"# drift\n")
        owned = drifted / "project-owned.txt"
        owned.write_bytes(b"project owned bytes\n")
        residue = drifted / ".cash-skills" / "receipt.tsv"
        residue.write_bytes(b"version\t2.20.0\n")
        before = self.workspace_snapshot(drifted)

        conflicted = self.run_installer(["--all"], home=Path(home.name))

        self.assertEqual(conflicted.returncode, 1, conflicted.stdout)
        self.assertIn(f"conflict: {drifted.resolve()} (vendored)\n", conflicted.stdout)
        self.assertIn(f"newer: {newer.resolve()} (vendored)\n", conflicted.stdout)
        self.assertTrue(
            residue.is_file(),
            "a conflict early return must not delete the receipt residue",
        )
        self.assertEqual(self.workspace_snapshot(drifted), before)
        self.assertEqual(self.workspace_snapshot(newer), newer_before)

        forced = self.run_installer(["--all", "--force"], home=Path(home.name))

        self.assertEqual(forced.returncode, 0, forced.stderr)
        self.assertIn(f"updated: {drifted.resolve()} (vendored)\n", forced.stdout)
        self.assertIn(f"newer: {newer.resolve()} (vendored)\n", forced.stdout)
        self.assertEqual((drifted / managed).read_bytes(), canonical)
        self.assertEqual(owned.read_bytes(), b"project owned bytes\n")
        self.assertFalse(
            residue.exists(),
            "a committed vendored publication must clear the receipt residue",
        )
        self.assertEqual(
            self.workspace_snapshot(newer),
            newer_before,
            "a newer early return must stay zero-write even under --force",
        )

    def test_register_accepts_manifest_present_target(self) -> None:
        home = tempfile.TemporaryDirectory()
        temporary, target = self.make_target()
        self.addCleanup(home.cleanup)
        self.addCleanup(temporary.cleanup)
        self.assert_vendored(target)
        before = self.workspace_snapshot(target)

        registered = self.run_installer(["--register", str(target)], home=Path(home.name))
        repeated = self.run_installer(["--register", str(target)], home=Path(home.name))

        self.assertEqual(registered.returncode, 0, registered.stderr)
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        registry = Path(home.name) / ".config" / "cash-skills" / "projects.txt"
        records = registry.read_text(encoding="utf-8").split("\n")
        self.assertEqual(records.count(str(target.resolve())), 1)
        self.assertEqual(self.workspace_snapshot(target), before)

    def test_batch_vendor_dispatch_requires_manifest_at_classification(self) -> None:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        sys.path.insert(0, str(ROOT / ".cash-skills" / "lib"))
        from cash_cli.installer import InstallerError, install_vendored_target

        before = self.workspace_snapshot(target)
        with self.assertRaises(InstallerError) as raised:
            install_vendored_target(
                ROOT,
                str(target),
                dry_run=False,
                force=False,
                require_manifest=True,
            )

        self.assertIn("portable manifest disappeared", str(raised.exception))
        self.assertFalse((target / ".cash-skills" / "manifest.tsv").exists())
        self.assertEqual(self.workspace_snapshot(target), before)

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

    # --- Stable receipt identity 比對條件與 gate 診斷 -------------------------

    def digest_of(self, path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def edit_receipt(self, receipt: Path, edit) -> None:
        rows = receipt.read_text(encoding="utf-8").splitlines()
        for index, row in enumerate(rows):
            fields = row.split("\t")
            replacement = edit(fields)
            if replacement is not None:
                rows[index] = "\t".join(replacement)
        receipt.write_text("\n".join(rows) + "\n", encoding="utf-8")

    def renumber_stable_devices(self, receipt: Path) -> None:
        def edit(fields: list[str]) -> list[str] | None:
            if fields[0] != "stable":
                return None
            fields[4] = str(int(fields[4]) + 2)
            return fields

        self.edit_receipt(receipt, edit)

    def set_stable_device(self, receipt: Path, relative: str, value: str) -> None:
        def edit(fields: list[str]) -> list[str] | None:
            if fields[0] != "stable" or fields[1] != relative:
                return None
            fields[4] = value
            return fields

        self.edit_receipt(receipt, edit)

    def drift_stable_inode(self, receipt: Path, relative: str) -> None:
        def edit(fields: list[str]) -> list[str] | None:
            if fields[0] != "stable" or fields[1] != relative:
                return None
            fields[5] = str(int(fields[5]) + 1)
            return fields

        self.edit_receipt(receipt, edit)

    def launcher_receipt_error(self, target: Path) -> str:
        launched = self.run_target_cash(target, "list", "--json")
        self.assertEqual(
            launched.returncode,
            1,
            f"launcher was expected to fail:\nstdout={launched.stdout}",
        )
        self.assertIn('"code":"receipt_invalid"', launched.stdout)
        return json.loads(launched.stdout)["error"]["message"]

    def installer_error_message(
        self,
        result: subprocess.CompletedProcess[str],
    ) -> str:
        for line in result.stderr.splitlines():
            if line.startswith("Error: "):
                return line.removeprefix("Error: ")
        self.fail(
            "installer did not report an error line:\n"
            f"stdout={result.stdout}\nstderr={result.stderr}"
        )

    def synthesize_receipt(self, root: Path) -> Path:
        runtime = sorted(
            (
                path.relative_to(root).as_posix()
                for path in (root / ".cash-skills" / "lib" / "cash_cli").rglob("*.py")
            ),
            key=lambda value: value.encode("utf-8"),
        )
        skills = [
            f"{variant}/skills/{skill.name}/SKILL.md"
            for variant in (".agents", ".claude")
            for skill in sorted((root / variant / "skills").glob("cash-*"))
        ]
        version = (root / "cash-skills.version").read_text(encoding="utf-8").strip()
        runtime_stream = "".join(
            f"{relative}\t{self.digest_of(root / relative)}\t0644\n"
            for relative in runtime
        )
        rows = [
            f"version\t{version}",
            "runtime_generation\t"
            + hashlib.sha256(runtime_stream.encode("utf-8")).hexdigest(),
        ]
        for relative in (".cash-skills/bin/cash", ".cash-workspace.lock"):
            metadata = os.lstat(root / relative)
            mode = "0755" if relative == ".cash-skills/bin/cash" else "0644"
            rows.append(
                f"stable\t{relative}\t{self.digest_of(root / relative)}\t{mode}"
                f"\t{metadata.st_dev}\t{metadata.st_ino}"
            )
        rows.extend(
            f"runtime\t{relative}\t{self.digest_of(root / relative)}\t0644"
            for relative in runtime
        )
        rows.extend(
            f"skill\t{relative}\t{self.digest_of(root / relative)}\t0644"
            for relative in skills
        )
        receipt = root / ".cash-skills" / "receipt.tsv"
        receipt.write_text("\n".join(rows) + "\n", encoding="utf-8")
        os.chmod(receipt, 0o644)
        return receipt

    def installed_receipt_target(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Path]:
        temporary, target = self.make_target()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(self.install(target).returncode, 0)
        return temporary, target, target / ".cash-skills" / "receipt.tsv"

    def test_stable_device_renumbering_passes_the_launcher_gate(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.renumber_stable_devices(receipt)

        launched = self.run_target_cash(target, "list", "--json")

        self.assertEqual(
            launched.returncode,
            0,
            "a stable record whose device alone differs must not be rejected:\n"
            f"stdout={launched.stdout}\nstderr={launched.stderr}",
        )
        self.assertNotIn("receipt_invalid", launched.stdout)

    def test_stable_device_renumbering_passes_direct_dry_run_preflight(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.renumber_stable_devices(receipt)

        result = self.install(target, "--dry-run")

        self.assertEqual(
            result.returncode,
            0,
            "direct preflight must not reject a device-only stable difference:\n"
            f"stdout={result.stdout}\nstderr={result.stderr}",
        )
        self.assertNotIn("drift", result.stderr)

    def test_stable_device_renumbering_passes_vendor_dry_run_preflight(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.renumber_stable_devices(receipt)

        result = self.vendor(target, "--dry-run")

        self.assertEqual(
            result.returncode,
            0,
            "--vendor preflight must not reject a device-only stable difference:\n"
            f"stdout={result.stdout}\nstderr={result.stderr}",
        )
        self.assertNotIn("drift", result.stderr)

    def test_stable_device_renumbering_completes_a_vendor_migration(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.renumber_stable_devices(receipt)

        result = self.assert_vendored(target)

        self.assertIn(
            "Result: ",
            result.stdout,
            "the migration must complete under its existing classification",
        )

    def test_launcher_stable_content_drift_is_not_offered_reissue(self) -> None:
        _, target, _ = self.installed_receipt_target()
        (target / ".cash-workspace.lock").write_bytes(b"drift\n")

        message = self.launcher_receipt_error(target)

        self.assertIn(
            "content drift",
            message,
            f"digest mismatch must be classified as content drift: {message}",
        )
        self.assertIn(".cash-workspace.lock", message)
        self.assertNotIn("--init-receipt", message)

    def test_installer_stable_content_drift_is_not_offered_reissue(self) -> None:
        _, target, _ = self.installed_receipt_target()
        (target / ".cash-workspace.lock").write_bytes(b"drift\n")

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn(
            "stable receipt content drift",
            message,
            f"digest mismatch must be classified as content drift: {message}",
        )
        self.assertIn(".cash-workspace.lock", message)
        self.assertNotIn("--init-receipt", message)

    def test_launcher_stable_identity_drift_offers_the_full_command(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")

        message = self.launcher_receipt_error(target)

        self.assertIn("stable record identity drift", message)
        self.assertIn(".cash-skills/bin/cash", message)
        self.assertIn(
            LAUNCHER_INIT_RECEIPT_COMMAND,
            message,
            f"identity drift must carry the full recovery command: {message}",
        )

    def test_installer_stable_identity_drift_offers_the_full_command(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn("stable receipt identity drift", message)
        self.assertIn(".cash-skills/bin/cash", message)
        self.assertIn(
            INSTALLER_INIT_RECEIPT_COMMAND,
            message,
            f"identity drift must carry the full recovery command: {message}",
        )

    def test_launcher_identity_guidance_states_the_version_control_premise(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")

        message = self.launcher_receipt_error(target)

        self.assertIn(
            "tracked by version control",
            message,
            f"guidance must state the version-control premise: {message}",
        )
        self.assertIn("machine-local", message)
        self.assertNotIn("fresh clone", message)

    def test_installer_identity_guidance_states_the_version_control_premise(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")

        for label, result in (
            ("direct", self.install(target)),
            ("vendor", self.vendor(target)),
        ):
            with self.subTest(path=label):
                message = self.installer_error_message(result)
                self.assertIn(
                    "tracked by version control",
                    message,
                    f"guidance must state the version-control premise: {message}",
                )
                self.assertIn("machine-local", message)
                self.assertNotIn("fresh clone", message)

    def test_stable_mode_drift_is_classified_as_identity_drift(self) -> None:
        _, target, _ = self.installed_receipt_target()
        os.chmod(target / ".cash-workspace.lock", 0o600)

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn("stable receipt identity drift", message)
        self.assertIn(
            INSTALLER_INIT_RECEIPT_COMMAND,
            message,
            f"mode drift is the authorized reissue entry point: {message}",
        )

    def test_launcher_content_and_identity_drift_is_content_drift(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        (target / ".cash-workspace.lock").write_bytes(b"drift\n")
        self.drift_stable_inode(receipt, ".cash-workspace.lock")

        message = self.launcher_receipt_error(target)

        self.assertIn(
            "content drift",
            message,
            f"digest is the sole classification axis: {message}",
        )
        self.assertNotIn("--init-receipt", message)

    def test_installer_content_and_identity_drift_is_content_drift(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        (target / ".cash-workspace.lock").write_bytes(b"drift\n")
        self.drift_stable_inode(receipt, ".cash-workspace.lock")

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn(
            "stable receipt content drift",
            message,
            f"digest is the sole classification axis: {message}",
        )
        self.assertNotIn("--init-receipt", message)

    def test_launcher_runtime_drift_supersedes_identity_drift(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")
        drifted = ".cash-skills/lib/cash_cli/errors.py"
        (target / drifted).write_bytes(
            (target / drifted).read_bytes() + b"# drift\n"
        )

        message = self.launcher_receipt_error(target)

        self.assertIn("stable record identity drift: .cash-skills/bin/cash", message)
        self.assertIn(f"runtime record drift: {drifted}", message)
        self.assertIn(
            DRIFTED_RECORD_NEXT_STEP,
            message,
            f"an unmet premise must still name a next step: {message}",
        )
        self.assertNotIn("--init-receipt", message)

    def test_installer_runtime_drift_supersedes_identity_drift(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")
        drifted = ".cash-skills/lib/cash_cli/errors.py"
        (target / drifted).write_bytes(
            (target / drifted).read_bytes() + b"# drift\n"
        )

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn(
            "stable receipt identity drift: .cash-skills/bin/cash in "
            f"{Path(target).resolve()}",
            message,
        )
        self.assertIn(f"runtime record drift: {drifted}", message)
        self.assertIn(
            DRIFTED_RECORD_NEXT_STEP,
            message,
            f"an unmet premise must still name a next step: {message}",
        )
        self.assertNotIn("--init-receipt", message)

    def test_deferred_identity_drift_defers_to_the_existing_exit(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")
        linked = ".cash-skills/lib/cash_cli/errors.py"
        os.link(target / linked, target / "errors-hard-link.py")

        launched = self.run_target_cash(target, "list", "--json")

        self.assertEqual(launched.returncode, 1)
        self.assertIn('"code":"receipt_invalid"', launched.stdout)
        message = json.loads(launched.stdout)["error"]["message"]
        self.assertIn(
            linked,
            message,
            f"the existing exit must name the record it rejected: {message}",
        )
        self.assertNotIn("--init-receipt", message)

    def test_installer_identity_guidance_names_the_target_not_the_source(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")
        resolved = str(Path(target).resolve())

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn(
            "Run ",
            message,
            f"identity guidance must carry a command: {message}",
        )
        prose, command = message.split("Run ", 1)
        self.assertIn(
            resolved,
            prose,
            f"the prose must name the target project: {message}",
        )
        self.assertNotIn(
            resolved,
            command,
            f"the command must not embed the absolute target path: {message}",
        )
        self.assertFalse(message.startswith(f"{target}: "))
        self.assertFalse(message.startswith(f"{resolved}: "))
        self.assertNotIn("from the project root", message)

    def test_source_repository_hint_precedes_the_identity_drift_hint(self) -> None:
        temporary, source = self.make_self_source()
        self.addCleanup(temporary.cleanup)
        receipt = self.synthesize_receipt(source)
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")

        launched = self.run_target_cash(source, "list", "--json")

        self.assertEqual(launched.returncode, 1, launched.stdout)
        self.assertIn('"code":"receipt_invalid"', launched.stdout)
        message = json.loads(launched.stdout)["error"]["message"]
        self.assertIn(
            "./install-cash-skills.fish --self",
            message,
            f"the source-layout hint must keep precedence: {message}",
        )
        self.assertNotIn("--init-receipt", message)

    def test_launcher_rejects_a_negative_stable_device_by_shape(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.set_stable_device(receipt, ".cash-skills/bin/cash", "-1")

        message = self.launcher_receipt_error(target)

        self.assertIn(
            "receipt identity is invalid",
            message,
            f"a negative device must fail the shape gate, not a comparison: {message}",
        )
        self.assertNotIn("drift", message)

    def test_installer_rejects_a_negative_stable_device_by_shape(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.set_stable_device(receipt, ".cash-skills/bin/cash", "-1")

        result = self.install(target)
        message = self.installer_error_message(result)

        self.assertIn("receipt stable identity is invalid", message)

    def test_identity_drift_fails_before_acquiring_the_exclusive_lock(self) -> None:
        _, target, receipt = self.installed_receipt_target()
        self.drift_stable_inode(receipt, ".cash-skills/bin/cash")
        before = receipt.read_bytes()
        holds = tempfile.TemporaryDirectory()
        self.addCleanup(holds.cleanup)
        hold = Path(holds.name).resolve() / "hold"
        ready = Path(f"{hold}.ready")
        release = Path(f"{hold}.release")
        environment = {
            name: value
            for name, value in os.environ.items()
            if not name.startswith("CASH_INSTALL_")
            and not name.startswith("TEST_CASH_INSTALL_")
        }
        environment["CASH_INSTALL_TEST_HOOKS"] = "1"
        environment["CASH_INSTALL_HOLD_FILE"] = str(hold)
        child = subprocess.Popen(
            ["fish", "--no-config", str(INSTALLER), "--target", str(target)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            start_new_session=True,
        )
        crossed = False
        unfinished = False
        release_failed = False
        communicated = False
        cleanup_errors: list[str] = []
        stdout = stderr = ""
        try:
            deadline = time.monotonic() + 60
            while child.poll() is None:
                if ready.exists():
                    crossed = True
                    break
                if time.monotonic() >= deadline:
                    unfinished = True
                    break
                time.sleep(0.01)
            if crossed and not release.exists():
                try:
                    release.write_bytes(b"release\n")
                except OSError as error:
                    release_failed = True
                    cleanup_errors.append(f"release: {type(error).__name__}: {error}")
            if not release_failed:
                try:
                    stdout, stderr = child.communicate(timeout=2 if crossed else 60)
                    communicated = True
                except subprocess.TimeoutExpired:
                    unfinished = True
        finally:
            # install-cash-skills.fish `exec`s python3, so child.pid is the
            # installer itself and its process group is its own session. Signal
            # the group rather than the pid so a wrapper that ever stops using
            # `exec` cannot leave a descendant holding the workspace lock.
            # Cleanup failures are captured independently so that one failed step
            # cannot skip process-group reclamation or replace the primary failure.
            if not communicated:
                if not release.exists():
                    try:
                        release.write_bytes(b"release\n")
                        release_failed = False
                    except OSError as error:
                        release_failed = True
                        cleanup_errors.append(
                            f"release: {type(error).__name__}: {error}"
                        )
                if not release_failed and not unfinished:
                    try:
                        stdout, stderr = child.communicate(timeout=2 if crossed else 20)
                        communicated = True
                    except subprocess.TimeoutExpired:
                        pass
                if not communicated:
                    try:
                        os.killpg(child.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                    except OSError as error:
                        cleanup_errors.append(
                            f"SIGTERM: {type(error).__name__}: {error}"
                        )
                    try:
                        stdout, stderr = child.communicate(timeout=10)
                        communicated = True
                    except subprocess.TimeoutExpired:
                        try:
                            os.killpg(child.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        except OSError as error:
                            cleanup_errors.append(
                                f"SIGKILL: {type(error).__name__}: {error}"
                            )
                        try:
                            stdout, stderr = child.communicate(timeout=10)
                            communicated = True
                        except subprocess.TimeoutExpired as error:
                            cleanup_errors.append(
                                f"communicate: {type(error).__name__}: {error}"
                            )

        self.assertFalse(
            crossed,
            "identity drift must fail before the exclusive lock boundary",
        )
        self.assertFalse(unfinished, "the installer did not finish within the deadline")
        self.assertFalse(
            cleanup_errors,
            f"the child session was not reclaimed: {'; '.join(cleanup_errors)}",
        )
        self.assertEqual(child.returncode, 1, f"stdout={stdout}\nstderr={stderr}")
        self.assertIn("stable receipt identity drift", stderr)
        self.assertEqual(receipt.read_bytes(), before)



if __name__ == "__main__":
    unittest.main()
