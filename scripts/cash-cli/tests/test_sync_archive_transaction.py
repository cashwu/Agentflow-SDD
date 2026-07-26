import os
import json
import datetime as dt
import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from cash_cli.commands.archive import archive_change, sync_change
from cash_cli.commands.tasks import ensure_touched
from cash_cli.errors import CashError
from cash_cli.spec_merge import _paths_in_section, _task_paths
from cash_cli.workspace import Workspace


class SyncArchiveTransactionTests(unittest.TestCase):
    def extract_code_paths(self, proposal: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "proposal.md"
            path.write_text(proposal, encoding="utf-8")
            return _paths_in_section(
                Workspace(Path(directory)),
                path,
                "## Impact",
                "- Affected code:",
            )

    def extract_test_paths(self, tasks: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "tasks.md"
            path.write_text(tasks, encoding="utf-8")
            return _task_paths(Workspace(Path(directory)), path)

    def test_trace_code_paths_accept_plain_affected_code_path(self) -> None:
        self.assertEqual(
            self.extract_code_paths(
                "## Impact\n\n"
                "- Affected code:\n"
                "  - Modified:\n"
                "    - scripts/cash-cli/plain.py\n"
            ),
            ["scripts/cash-cli/plain.py"],
        )

    def test_trace_code_paths_deduplicate_plain_and_code_span_path(self) -> None:
        self.assertEqual(
            self.extract_code_paths(
                "## Impact\n\n"
                "- Affected code:\n"
                "  - Modified:\n"
                "    - scripts/cash-cli/shared.py and `scripts/cash-cli/shared.py`\n"
            ),
            ["scripts/cash-cli/shared.py"],
        )

    def test_trace_code_paths_ignore_non_ascii_plain_prose(self) -> None:
        self.assertEqual(
            self.extract_code_paths(
                "## Impact\n\n"
                "- Affected code:\n"
                "  - Modified:\n"
                "    - 這是中文/散文片語\n"
            ),
            [],
        )

    def test_trace_code_paths_exclude_affected_specs(self) -> None:
        self.assertEqual(
            self.extract_code_paths(
                "## Impact\n\n"
                "- Affected specs:\n"
                "  - `openspec/specs/demo/spec.md`\n"
                "- Affected code:\n"
                "  - Modified:\n"
                "    - `scripts/cash-cli/demo.py`\n"
            ),
            ["scripts/cash-cli/demo.py"],
        )

    def test_trace_test_paths_scan_all_verification_tokens(self) -> None:
        self.assertEqual(
            self.extract_test_paths(
                "- [ ] 1.1 實作；以 `python3 scripts/cash-cli/tests/test_demo.py` 驗證\n"
                "- [ ] 1.2 實作；以 `fish scripts/cash-cli/tests/cli-checks.fish demo` 驗證\n"
            ),
            [
                "scripts/cash-cli/tests/cli-checks.fish",
                "scripts/cash-cli/tests/test_demo.py",
            ],
        )

    def test_trace_test_paths_ignore_other_tokens_in_code_span(self) -> None:
        self.assertEqual(
            self.extract_test_paths(
                "- [ ] 1.1 實作；以 `scripts/cash-cli/tests/test_demo.py --verbose demo` 驗證\n"
            ),
            ["scripts/cash-cli/tests/test_demo.py"],
        )

    def test_trace_test_paths_preserve_bare_check_script_mappings(self) -> None:
        self.assertEqual(
            self.extract_test_paths(
                "- [ ] 1.1 實作；以 `cli-checks.fish` 驗證\n"
                "- [ ] 1.2 實作；以 `skill-checks.fish` 驗證\n"
            ),
            [
                "scripts/cash-cli/tests/cli-checks.fish",
                "scripts/cash-skills/tests/skill-checks.fish",
            ],
        )

    def test_trace_test_paths_exclude_delivery_fish_script(self) -> None:
        self.assertEqual(
            self.extract_test_paths(
                "- [ ] 1.1 實作；以 `scripts/cash-cli/install-helper.fish` 驗證\n"
            ),
            [],
        )

    def test_trace_test_paths_canonicalize_dot_slash_prefix(self) -> None:
        self.assertEqual(
            self.extract_test_paths(
                "- [ ] 1.1 實作；以 `./scripts/cash-cli/tests/test_demo.py` 驗證\n"
            ),
            ["scripts/cash-cli/tests/test_demo.py"],
        )

    def test_trace_code_paths_canonicalize_repeated_prefixes_and_suffixes(self) -> None:
        values = self.extract_code_paths(
            "## Impact\n\n"
            "- Affected code:\n"
            "  - Modified:\n"
            "    - `./scripts/cash-cli/one.py`\n"
            "    - `././scripts/cash-cli/two.py`\n"
            "    - `scripts/cash-cli/three/`\n"
            "    - `scripts/cash-cli/four//`\n"
        )

        self.assertEqual(
            values,
            [
                "scripts/cash-cli/four",
                "scripts/cash-cli/one.py",
                "scripts/cash-cli/three",
                "scripts/cash-cli/two.py",
            ],
        )
        self.assertTrue(all(not value.startswith("./") for value in values))
        self.assertTrue(all(not value.endswith("/") for value in values))

    def test_trace_test_paths_exclude_non_path_punctuation(self) -> None:
        self.assertEqual(
            self.extract_test_paths(
                "- [ ] 1.1 實作；以 `scripts/cash-cli/tests/x.py::test_y` "
                "與 `--rootdir=scripts/cash-cli/tests/z` 驗證\n"
            ),
            [],
        )

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
            "## Impact\n\n"
            "- Affected specs:\n"
            "  - demo\n"
            "- Affected code:\n"
            "  - Modified: `src/demo.py`\n",
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

    def test_archive_manifest_records_touched_files(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        files = ["src/demo.py", "tests/demo_test.py"]
        touched = {
            "version": 1,
            "change": "demo-change",
            "legacy_import": None,
            "touched": [
                {
                    "task_id": "1.1",
                    "task_desc": "Modify `src/demo.py`",
                    "files": files,
                }
            ],
            "files": files,
        }
        state = root / ".cash-skills" / "state" / "touched" / "demo-change.json"
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(
            json.dumps(touched, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        expected_digest = hashlib.sha256(
            json.dumps(touched, ensure_ascii=False, separators=(",", ":")).encode(
                "utf-8"
            )
        ).hexdigest()

        result = archive_change(workspace, "demo-change", skip_specs=True)

        manifest = json.loads(
            (root / result["destination"] / "archive-manifest.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(manifest["touched_files"], files)
        self.assertEqual(manifest["touched_digest"], expected_digest)

    def test_archive_manifest_touched_files_is_empty_without_state(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)

        result = archive_change(workspace, "demo-change", skip_specs=True)

        manifest = json.loads(
            (root / result["destination"] / "archive-manifest.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(manifest["touched_files"], [])

    def test_archive_manifest_other_fields_unchanged(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)

        result = archive_change(workspace, "demo-change", skip_specs=True)

        manifest = json.loads(
            (root / result["destination"] / "archive-manifest.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(manifest["version"], 1)
        self.assertEqual(manifest["change"], "demo-change")
        self.assertEqual(
            manifest["destination"],
            f"openspec/changes/archive/{dt.date.today().isoformat()}-demo-change",
        )
        self.assertEqual(manifest["specs_synced"], False)
        self.assertEqual(
            manifest["delta_digests"],
            {
                "openspec/changes/demo-change/specs/demo/spec.md": (
                    "355e2db1ea62582a628dcfa25bdaa18112fb3e3ee59b8a1f822c13151b543caa"
                )
            },
        )
        self.assertEqual(
            manifest["master_digests"],
            {
                "openspec/specs/demo/spec.md": (
                    "0a5f36486f71521cadce1950ced272f4858183adfed91eba77c9144178961539"
                )
            },
        )
        self.assertEqual(manifest["legacy_cleanup"], "not_imported")


if __name__ == "__main__":
    unittest.main()
