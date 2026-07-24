import os
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from cash_cli.commands.archive import archive_change, sync_change
from cash_cli.commands.tasks import ensure_touched
from cash_cli.errors import CashError
from cash_cli.spec_merge import _task_paths
from cash_cli.workspace import Workspace


class SyncArchiveTransactionTests(unittest.TestCase):
    def test_trace_path_extraction_never_crosses_lines(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tasks = Path(directory) / "tasks.md"
            tasks.write_text(
                "- [x] 1.1 run `validate`\n"
                "- [x] 1.2 update `src/demo.py`；以 `tests/demo_test.py` 驗證\n",
                encoding="utf-8",
            )

            workspace = Workspace(Path(directory))
            self.assertEqual(
                _task_paths(workspace, tasks),
                ["tests/demo_test.py"],
            )

    def make_workspace(
        self,
        *,
        tasks_done: bool = True,
        collision: bool = False,
    ) -> tuple[tempfile.TemporaryDirectory[str], Path, Workspace]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / ".cash.yaml").write_text("locale: tw\n", encoding="utf-8")
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        master = root / "openspec" / "specs" / "demo"
        master.mkdir(parents=True)
        collision_block = (
            "\n### Requirement: New behavior\n\n"
            "系統 SHALL 保留既有目的地。\n\n"
            "#### Scenario: Destination\n\n- **WHEN** 執行\n- **THEN** 成功\n"
            if collision
            else ""
        )
        (master / "spec.md").write_text(
            "# demo Specification\n\n## Purpose\n\nDemo.\n\n## Requirements\n\n"
            "### Requirement: Old behavior\n\n"
            "系統 SHALL 提供舊行為。\n\n"
            "#### Scenario: Old\n\n- **WHEN** 執行\n- **THEN** 舊結果\n"
            f"{collision_block}",
            encoding="utf-8",
        )
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        change = root / "openspec" / "changes" / "demo-change"
        delta = change / "specs" / "demo"
        delta.mkdir(parents=True)
        (change / ".openspec.yaml").write_text(
            "schema: spec-driven\ncreated: 2026-07-24\n",
            encoding="utf-8",
        )
        (change / "proposal.md").write_text(
            "## Summary\n\nDemo\n\n## Capabilities\n\nDemo\n\n"
            "## Impact\n\n- Modified: `src/demo.py`\n",
            encoding="utf-8",
        )
        (change / "design.md").write_text(
            "## Implementation Contract\n\nDemo behavior.\n",
            encoding="utf-8",
        )
        mark = "x" if tasks_done else " "
        (change / "tasks.md").write_text(
            f"## 1. Work\n\n- [{mark}] 1.1 Modify `src/demo.py`；"
            "以 `tests/demo_test.py` 驗證\n",
            encoding="utf-8",
        )
        (delta / "spec.md").write_text(
            "## ADDED Requirements\n\n"
            "### Requirement: Added behavior\n\n"
            "系統 SHALL 新增行為。\n\n"
            "#### Scenario: Added\n\n- **WHEN** 執行\n- **THEN** 新增\n\n"
            "## MODIFIED Requirements\n\n"
            "### Requirement: Old behavior\n\n"
            "系統 SHALL 提供修改後行為。\n\n"
            "#### Scenario: Modified\n\n- **WHEN** 執行\n- **THEN** 修改\n\n"
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Old behavior`\n"
            "- TO: `### Requirement: New behavior`\n",
            encoding="utf-8",
        )
        return temporary, root, Workspace.discover(root)

    def test_sync_applies_fixed_phases_and_is_idempotent(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)

        first = sync_change(workspace, "demo-change")
        master = root / "openspec" / "specs" / "demo" / "spec.md"
        first_bytes = master.read_bytes()
        second = sync_change(workspace, "demo-change")

        text = first_bytes.decode()
        self.assertNotIn("### Requirement: Old behavior", text)
        self.assertIn("### Requirement: New behavior", text)
        self.assertIn("### Requirement: Added behavior", text)
        self.assertIn("系統 SHALL 提供修改後行為。", text)
        self.assertIn("source: demo-change", text)
        self.assertIn("  - src/demo.py", text)
        self.assertIn("  - tests/demo_test.py", text)
        self.assertFalse(first["already_synced"])
        self.assertTrue(second["already_synced"])
        self.assertEqual(master.read_bytes(), first_bytes)

    def test_rename_destination_collision_is_zero_write(self) -> None:
        temporary, root, workspace = self.make_workspace(collision=True)
        self.addCleanup(temporary.cleanup)
        master = root / "openspec" / "specs" / "demo" / "spec.md"
        before = master.read_bytes()

        with self.assertRaises(CashError) as raised:
            sync_change(workspace, "demo-change")

        self.assertEqual(raised.exception.code, "requirement_collision")
        self.assertEqual(master.read_bytes(), before)

    def test_duplicate_rename_destination_is_zero_write(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        master = root / "openspec" / "specs" / "demo" / "spec.md"
        master.write_text(
            master.read_text(encoding="utf-8")
            + "\n### Requirement: Second behavior\n\n"
            "系統 SHALL 提供第二行為。\n\n"
            "#### Scenario: Second\n\n- **WHEN** 執行\n- **THEN** 成功\n",
            encoding="utf-8",
        )
        delta = root / "openspec" / "changes" / "demo-change" / "specs" / "demo"
        (delta / "spec.md").write_text(
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Old behavior`\n"
            "- TO: `### Requirement: Merged behavior`\n\n"
            "- FROM: `### Requirement: Second behavior`\n"
            "- TO: `### Requirement: Merged behavior`\n",
            encoding="utf-8",
        )
        before = master.read_bytes()

        with self.assertRaises(CashError) as raised:
            sync_change(workspace, "demo-change")

        self.assertEqual(raised.exception.code, "requirement_collision")
        self.assertIn("claimed by multiple renames", raised.exception.message)
        self.assertEqual(master.read_bytes(), before)
        self.assertEqual(before.count(b"### Requirement:"), 2)

    def test_archive_creates_missing_archive_parent_directory(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        archive_root = root / "openspec" / "changes" / "archive"
        archive_root.rmdir()
        self.assertFalse(archive_root.exists())

        result = archive_change(workspace, "demo-change")

        destination = root / str(result["destination"])
        self.assertTrue(destination.is_dir())
        self.assertFalse((root / "openspec" / "changes" / "demo-change").exists())

    def test_archive_after_sync_does_not_merge_twice(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        sync_change(workspace, "demo-change")
        master = root / "openspec" / "specs" / "demo" / "spec.md"
        synced = master.read_bytes()

        result = archive_change(workspace, "demo-change")

        self.assertEqual(master.read_bytes(), synced)
        self.assertFalse((root / "openspec" / "changes" / "demo-change").exists())
        destination = root / result["destination"]
        self.assertTrue((destination / "archive-manifest.json").is_file())

    def test_skip_specs_and_mark_tasks_complete_share_archive_transaction(self) -> None:
        temporary, root, workspace = self.make_workspace(tasks_done=False)
        self.addCleanup(temporary.cleanup)
        master = root / "openspec" / "specs" / "demo" / "spec.md"
        before = master.read_bytes()

        result = archive_change(
            workspace,
            "demo-change",
            skip_specs=True,
            mark_tasks_complete=True,
        )

        self.assertEqual(master.read_bytes(), before)
        archived_tasks = root / result["destination"] / "tasks.md"
        self.assertIn("- [x] 1.1", archived_tasks.read_text(encoding="utf-8"))

    def test_archive_move_failure_rolls_back_master_and_checkboxes(self) -> None:
        temporary, root, workspace = self.make_workspace(tasks_done=False)
        self.addCleanup(temporary.cleanup)
        master = root / "openspec" / "specs" / "demo" / "spec.md"
        before_master = master.read_bytes()
        tasks = root / "openspec" / "changes" / "demo-change" / "tasks.md"
        before_tasks = tasks.read_bytes()
        real_rename = os.rename

        def fail_archive_move(
            source: os.PathLike[str],
            destination: os.PathLike[str],
            **kwargs,
        ) -> None:
            if Path(source).name == "demo-change":
                raise OSError("injected move failure")
            real_rename(source, destination, **kwargs)

        with mock.patch("cash_cli.workspace.os.rename", side_effect=fail_archive_move):
            with self.assertRaises(OSError):
                archive_change(
                    workspace,
                    "demo-change",
                    mark_tasks_complete=True,
                )

        self.assertEqual(master.read_bytes(), before_master)
        self.assertEqual(tasks.read_bytes(), before_tasks)
        self.assertTrue(tasks.parent.is_dir())

    def test_direct_archive_ensure_is_part_of_failed_transaction(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        legacy = root / ".spectra" / "touched" / "demo-change.json"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(
            json.dumps({"change": "demo-change", "touched": []}),
            encoding="utf-8",
        )
        real_rename = os.rename

        def fail_archive_move(
            source: os.PathLike[str],
            destination: os.PathLike[str],
            **kwargs,
        ) -> None:
            if Path(source).name == "demo-change":
                raise OSError("injected move failure")
            real_rename(source, destination, **kwargs)

        with mock.patch("cash_cli.workspace.os.rename", side_effect=fail_archive_move):
            with self.assertRaises(OSError):
                archive_change(workspace, "demo-change", skip_specs=True)

        self.assertTrue(legacy.is_file())
        self.assertFalse(
            (
                root
                / ".cash-skills"
                / "state"
                / "touched"
                / "demo-change.json"
            ).exists()
        )

    def test_archive_removes_only_matching_imported_legacy_inode(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        legacy = root / ".spectra" / "touched" / "demo-change.json"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(
            json.dumps({"change": "demo-change", "touched": []}),
            encoding="utf-8",
        )
        ensure_touched(workspace, "demo-change")

        result = archive_change(workspace, "demo-change", skip_specs=True)

        self.assertEqual(result["legacyCleanup"], "removed")
        self.assertFalse(legacy.exists())

    def test_archive_preserves_same_bytes_on_replaced_legacy_inode(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        legacy = root / ".spectra" / "touched" / "demo-change.json"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(
            json.dumps({"change": "demo-change", "touched": []}),
            encoding="utf-8",
        )
        ensure_touched(workspace, "demo-change")
        content = legacy.read_bytes()
        replacement = legacy.with_suffix(".replacement")
        replacement.write_bytes(content)
        os.replace(replacement, legacy)

        result = archive_change(workspace, "demo-change", skip_specs=True)

        self.assertEqual(result["legacyCleanup"], "preserved_drift")
        self.assertEqual(legacy.read_bytes(), content)


if __name__ == "__main__":
    unittest.main()
