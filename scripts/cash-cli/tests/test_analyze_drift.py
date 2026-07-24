import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from cash_cli.commands.analyze import analyze_payload
from cash_cli.commands.drift import drift_payload, render_report
from cash_cli.errors import CashError
from cash_cli.workspace import Workspace


class AnalyzeDriftTests(unittest.TestCase):
    def make_workspace(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Workspace]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        subprocess.run(["git", "-C", str(root), "config", "user.email", "test@example.com"], check=True)
        subprocess.run(["git", "-C", str(root), "config", "user.name", "Test"], check=True)
        (root / ".cash.yaml").write_text("locale: tw\n", encoding="utf-8")
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        return temporary, root, Workspace.discover(root)

    def add_change(self, root: Path, *, complete: bool) -> Path:
        change = root / "openspec" / "changes" / "demo"
        change.mkdir()
        (change / ".openspec.yaml").write_text(
            "schema: spec-driven\ncreated: 2026-07-24\n",
            encoding="utf-8",
        )
        (change / "proposal.md").write_text(
            "## Summary\n\nDemo\n\n## Capabilities\n\n- demo\n\n"
            "## Impact\n\n- Modified: `src/demo.py`\n",
            encoding="utf-8",
        )
        if complete:
            (change / "design.md").write_text(
                "## Implementation Contract\n\nDemo behavior.\n",
                encoding="utf-8",
            )
            spec = change / "specs" / "demo"
            spec.mkdir(parents=True)
            (spec / "spec.md").write_text(
                "## ADDED Requirements\n\n"
                "### Requirement: Demo behavior\n\n"
                "系統 SHALL 運作。\n\n"
                "#### Scenario: Demo\n\n"
                "- **WHEN** 執行\n- **THEN** 成功\n\n"
                "##### Example: Demo values\n\n"
                "- **GIVEN** `demo`\n- **WHEN** 執行\n- **THEN** `ok`\n",
                encoding="utf-8",
            )
            (change / "tasks.md").write_text(
                "## 1. Work\n\n- [ ] 1.1 Implement Demo behavior in `src/demo.py`\n",
                encoding="utf-8",
            )
        return change

    def test_analysis_insufficient_artifacts_is_skipped(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, complete=False)

        payload = analyze_payload(workspace, "demo")

        self.assertEqual(payload["change_id"], "demo")
        self.assertIn("design", payload["artifacts_missing"])
        self.assertTrue(
            any(
                dimension["status"] == "Skipped (insufficient artifacts)"
                for dimension in payload["dimensions"]
            )
        )

    def test_clean_analysis_has_stable_empty_arrays(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, complete=True)

        payload = analyze_payload(workspace, "demo")

        self.assertEqual(
            [item["dimension"] for item in payload["dimensions"]],
            ["Coverage", "Consistency", "Ambiguity", "Gaps"],
        )
        self.assertEqual(payload["findings"], [])
        self.assertEqual(payload["artifacts_missing"], [])
        self.assertEqual(payload["artifacts_analyzed"], ["proposal", "design", "specs", "tasks"])

    def test_drift_shape_allows_only_last_commit_null(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, complete=True)

        payload = drift_payload(workspace, "demo")

        self.assertIsNone(payload["last_commit"])
        self.assertEqual(payload["commits_since_created"], 0)
        self.assertIsInstance(payload["dimensions"], list)
        self.assertIsInstance(payload["broken_anchors"], list)
        self.assertIsInstance(payload["tasks_maybe_resolved"], list)
        self.assertIsInstance(payload["tasks_blocked_external"], list)
        self.assertTrue(payload["primary_recommendation"].startswith("$cash-"))
        report = render_report(payload)
        self.assertIn(f"Severity: {payload['severity']}", report)
        self.assertIn(payload["primary_recommendation"], report)

    def test_missing_impact_path_is_broken_anchor_and_blocked_task(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, complete=True)

        payload = drift_payload(workspace, "demo")

        self.assertEqual(payload["broken_anchors"][0]["anchor"], "src/demo.py")
        self.assertEqual(payload["tasks_blocked_external"][0]["paths"], ["src/demo.py"])

    def test_git_launch_failure_is_execution_error(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, complete=True)

        with mock.patch(
            "cash_cli.commands.drift.subprocess.run",
            side_effect=FileNotFoundError("git"),
        ):
            with self.assertRaises(CashError) as raised:
                drift_payload(workspace, "demo")

        self.assertEqual(raised.exception.exit_code, 1)


if __name__ == "__main__":
    unittest.main()
