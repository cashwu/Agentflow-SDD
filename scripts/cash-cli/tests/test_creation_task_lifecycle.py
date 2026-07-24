import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands.create import create_artifact, create_change
from cash_cli.commands.tasks import (
    ensure_touched,
    git_fingerprints,
    mark_task_done,
    start_in_progress,
)
from cash_cli.errors import CashError
from cash_cli.workspace import Workspace


class CreationTaskLifecycleTests(unittest.TestCase):
    def make_workspace(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Workspace]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        subprocess.run(["git", "-C", str(root), "config", "user.email", "test@example.com"], check=True)
        subprocess.run(["git", "-C", str(root), "config", "user.name", "Test"], check=True)
        (root / ".cash.yaml").write_text(
            "locale: tw\ntdd: true\naudit: true\nparallel_tasks: false\n",
            encoding="utf-8",
        )
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        (root / "src").mkdir()
        (root / "src" / "a.py").write_text("a = 1\n", encoding="utf-8")
        (root / "unrelated.txt").write_text("clean\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(root), "commit", "-qm", "baseline"], check=True)
        return temporary, root, Workspace.discover(root)

    def add_ready_change(self, root: Path, name: str = "demo") -> None:
        change = root / "openspec" / "changes" / name
        (change / "specs" / "demo").mkdir(parents=True)
        (change / ".openspec.yaml").write_text(
            "schema: spec-driven\ncreated: 2026-07-24\n",
            encoding="utf-8",
        )
        (change / "proposal.md").write_text("## Summary\n\nDemo\n", encoding="utf-8")
        (change / "design.md").write_text(
            "## Implementation Contract\n\nDemo\n",
            encoding="utf-8",
        )
        (change / "specs" / "demo" / "spec.md").write_text(
            "## ADDED Requirements\n\n"
            "### Requirement: Demo\n\n"
            "系統 SHALL 運作。\n\n"
            "#### Scenario: Demo\n\n- **WHEN** 執行\n- **THEN** 成功\n",
            encoding="utf-8",
        )
        (change / "tasks.md").write_text(
            "## 1. Work\n\n"
            "- [ ] 1.1 Change a\n"
            "- [ ] 1.2 Add b\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "-C", str(root), "add", f"openspec/changes/{name}"], check=True)
        subprocess.run(["git", "-C", str(root), "commit", "-qm", "add change"], check=True)

    def test_create_change_and_dependency_gated_artifacts(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)

        create_change(workspace, "new-demo", agent="codex")
        with self.assertRaises(CashError):
            create_artifact(workspace, "new-demo", "tasks", None, b"tasks")
        create_artifact(workspace, "new-demo", "proposal", None, b"## Summary\n\nDemo\n")

        self.assertTrue((root / "openspec" / "changes" / "new-demo" / "proposal.md").is_file())
        with self.assertRaises(CashError):
            create_change(workspace, "new-demo", agent="codex")

    def test_spec_command_alias_creates_capability_delta(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)

        create_change(workspace, "new-demo", agent="codex")
        create_artifact(workspace, "new-demo", "proposal", None, b"## Summary\n\nDemo\n")
        create_artifact(
            workspace,
            "new-demo",
            "spec",
            "demo-capability",
            b"## ADDED Requirements\n",
        )

        self.assertEqual(
            (
                root
                / "openspec"
                / "changes"
                / "new-demo"
                / "specs"
                / "demo-capability"
                / "spec.md"
            ).read_bytes(),
            b"## ADDED Requirements\n",
        )

    def test_resume_does_not_absorb_pending_changes(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        (root / "unrelated.txt").write_text("pre-existing dirty\n", encoding="utf-8")
        start_in_progress(workspace, "demo")
        (root / "src" / "a.py").write_text("a = 2\n", encoding="utf-8")

        start_in_progress(workspace, "demo")
        touched = mark_task_done(workspace, "demo", "1")

        self.assertEqual(touched["files"], ["src/a.py"])
        self.assertNotIn("unrelated.txt", touched["files"])
        tasks = (root / "openspec" / "changes" / "demo" / "tasks.md").read_text()
        self.assertIn("- [x] 1.1 Change a", tasks)
        self.assertIn("- [ ] 1.2 Add b", tasks)

    def test_multiple_tasks_accumulate_stable_union(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        start_in_progress(workspace, "demo")
        (root / "src" / "a.py").write_text("a = 2\n", encoding="utf-8")
        mark_task_done(workspace, "demo", "1")
        (root / "src" / "b.py").write_text("b = 1\n", encoding="utf-8")

        touched = mark_task_done(workspace, "demo", "2")

        self.assertEqual(touched["files"], ["src/a.py", "src/b.py"])
        self.assertEqual([item["task_id"] for item in touched["touched"]], ["1", "2"])

        repeated = mark_task_done(workspace, "demo", "2")
        self.assertEqual(repeated, touched)

    def test_git_fingerprints_cover_staged_untracked_delete_and_rename_ends(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        (root / "src" / "new.py").write_text("new = True\n", encoding="utf-8")
        subprocess.run(
            ["git", "-C", str(root), "mv", "src/a.py", "src/renamed.py"],
            check=True,
        )
        (root / "unrelated.txt").unlink()

        fingerprints = git_fingerprints(workspace)

        self.assertIn("src/new.py", fingerprints)
        self.assertIn("src/a.py", fingerprints)
        self.assertIn("src/renamed.py", fingerprints)
        self.assertIn("unrelated.txt", fingerprints)

    def test_legacy_import_is_validated_once_and_provenance_is_preserved(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        legacy = root / ".spectra" / "touched" / "demo.json"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(
            json.dumps(
                {
                    "change": "demo",
                    "touched": [
                        {
                            "task_id": "1",
                            "task_desc": "Change a",
                            "files": ["src/a.py"],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )

        imported = ensure_touched(workspace, "demo")
        legacy.write_text('{"malformed":true}', encoding="utf-8")
        ensured_again = ensure_touched(workspace, "demo")

        self.assertEqual(imported, ensured_again)
        self.assertEqual(imported["files"], ["src/a.py"])
        self.assertEqual(imported["legacy_import"]["path"], ".spectra/touched/demo.json")
        self.assertEqual(imported["legacy_import"]["st_ino"], legacy.stat().st_ino)

    def test_malformed_legacy_state_fails_before_cash_state_is_written(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        legacy = root / ".spectra" / "touched" / "demo.json"
        legacy.parent.mkdir(parents=True)
        legacy.write_text('{"change":"other","touched":[]}', encoding="utf-8")

        with self.assertRaises(CashError):
            ensure_touched(workspace, "demo")

        self.assertFalse(
            (root / ".cash-skills" / "state" / "touched" / "demo.json").exists()
        )


if __name__ == "__main__":
    unittest.main()
