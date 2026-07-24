from __future__ import annotations

import datetime as dt
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
FIXTURES = ROOT / "scripts" / "cash-cli" / "fixtures" / "positive-lifecycle"


class PositiveLifecycleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(
            ["git", "-C", str(self.root), "config", "user.email", "test@example.invalid"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(self.root), "config", "user.name", "Cash Test"],
            check=True,
        )
        (self.root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (self.root / "openspec" / "changes" / "archive").mkdir()
        (self.root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        installed = subprocess.run(
            [
                "fish",
                "--no-config",
                str(ROOT / "install-cash-skills.fish"),
                "--target",
                str(self.root),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(installed.returncode, 0, installed.stderr)
        (self.root / "src").mkdir()
        (self.root / "src" / "demo.py").write_text("VALUE = 1\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
        subprocess.run(
            ["git", "-C", str(self.root), "commit", "-qm", "baseline"],
            check=True,
        )
        tool_bin = self.root / ".test-bin"
        tool_bin.mkdir()
        for executable in ("python3", "git"):
            resolved = shutil.which(executable)
            self.assertIsNotNone(resolved)
            (tool_bin / executable).symlink_to(resolved)
        self.environment = os.environ.copy()
        self.environment["PATH"] = str(tool_bin)
        self.environment["PYTHONDONTWRITEBYTECODE"] = "1"
        self.launcher = self.root / ".cash-skills" / "bin" / "cash"

    def cash(
        self,
        *arguments: str,
        stdin: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.launcher), *arguments],
            cwd=self.root / "openspec",
            input=stdin,
            text=True,
            capture_output=True,
            env=self.environment,
        )

    def assert_cash_ok(
        self,
        *arguments: str,
        stdin: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        result = self.cash(*arguments, stdin=stdin)
        self.assertEqual(
            result.returncode,
            0,
            f"{arguments}\nstdout={result.stdout}\nstderr={result.stderr}",
        )
        return result

    def test_complete_cash_lifecycle_without_spectra_binary(self) -> None:
        empty_list = (FIXTURES / "empty-list.json").read_text(encoding="utf-8")
        self.assertEqual(self.assert_cash_ok("list", "--json").stdout, empty_list)
        self.assert_cash_ok("new", "change", "demo", "--agent", "codex")
        self.assert_cash_ok(
            "new",
            "artifact",
            "proposal",
            "--change",
            "demo",
            "--stdin",
            stdin=(
                "## Summary\n\n需要可驗證的完整流程。\n\n"
                "## Capabilities\n\n### New Capabilities\n\n"
                "- `demo`: Demo lifecycle.\n\n"
                "### Modified Capabilities\n\n(none)\n\n"
                "## Impact\n\n- Affected specs: demo\n"
                "- Affected code:\n  - Modified: `src/demo.py`\n"
            ),
        )
        self.assert_cash_ok(
            "new",
            "artifact",
            "design",
            "--change",
            "demo",
            "--stdin",
            stdin=(
                "## Context\n\nDemo lifecycle.\n\n"
                "## Implementation Contract\n\n"
                "CLI MUST update `src/demo.py` and archive atomically.\n"
            ),
        )
        self.assert_cash_ok(
            "new",
            "artifact",
            "spec",
            "demo",
            "--change",
            "demo",
            "--stdin",
            stdin=(
                "## ADDED Requirements\n\n"
                "### Requirement: Demo lifecycle\n\n"
                "系統 SHALL 提供完整 lifecycle。\n\n"
                "#### Scenario: Complete flow\n\n"
                "- **WHEN** 執行 Cash lifecycle\n"
                "- **THEN** change 被安全封存\n"
            ),
        )
        self.assert_cash_ok(
            "new",
            "artifact",
            "tasks",
            "--change",
            "demo",
            "--stdin",
            stdin=(
                "## 1. Implementation\n\n"
                "- [ ] 1.1 修改 `src/demo.py`；"
                "以 `scripts/cash-cli/tests/cli-checks.fish` 驗證完整 lifecycle\n"
            ),
        )
        apply = json.loads(
            self.assert_cash_ok(
                "instructions",
                "apply",
                "--change",
                "demo",
                "--json",
            ).stdout
        )
        self.assertEqual(apply["state"], "ready")
        self.assertEqual(apply["missingArtifacts"], [])
        self.assertEqual(apply["progress"], {"total": 1, "complete": 0, "remaining": 1})
        self.assert_cash_ok("in-progress", "add", "demo")
        (self.root / "src" / "demo.py").write_text("VALUE = 2\n", encoding="utf-8")
        self.assert_cash_ok("task", "done", "--change", "demo", "1")
        self.assert_cash_ok("validate", "demo")
        analyze = json.loads(self.assert_cash_ok("analyze", "demo", "--json").stdout)
        self.assertEqual(
            sorted(analyze),
            [
                "artifacts_analyzed",
                "artifacts_missing",
                "change_id",
                "dimensions",
                "findings",
            ],
        )
        drift = json.loads(self.assert_cash_ok("drift", "demo", "--json").stdout)
        self.assertEqual(drift["change_id"], "demo")
        self.assertIn(drift["severity"], ("light", "medium", "heavy"))
        self.assert_cash_ok("sync", "demo")
        archived = self.assert_cash_ok("archive", "demo")
        self.assertEqual(archived.stdout, "archive complete: demo\n")

        archive = (
            self.root
            / "openspec"
            / "changes"
            / "archive"
            / f"{dt.date.today().isoformat()}-demo"
        )
        self.assertTrue(archive.is_dir())
        self.assertFalse((self.root / "openspec" / "changes" / "demo").exists())
        master = self.root / "openspec" / "specs" / "demo" / "spec.md"
        master_text = master.read_text(encoding="utf-8")
        expected_master = (
            (FIXTURES / "master-spec.md")
            .read_text(encoding="utf-8")
            .replace("@DATE@", dt.date.today().isoformat())
        )
        self.assertEqual(master_text, expected_master)
        self.assertIn("- [x] 1.1 修改", (archive / "tasks.md").read_text(encoding="utf-8"))
        manifest = json.loads((archive / "archive-manifest.json").read_text())
        self.assertEqual(manifest["change"], "demo")
        self.assertEqual(manifest["legacy_cleanup"], "not_imported")
        archive_tree = "\n".join(
            sorted(
                str(path.relative_to(archive)) + ("/" if path.is_dir() else "")
                for path in archive.rglob("*")
            )
        ) + "\n"
        self.assertEqual(
            archive_tree,
            (FIXTURES / "archive-tree.txt").read_text(encoding="utf-8"),
        )
        self.assertEqual(self.assert_cash_ok("list", "--json").stdout, empty_list)


if __name__ == "__main__":
    unittest.main()
