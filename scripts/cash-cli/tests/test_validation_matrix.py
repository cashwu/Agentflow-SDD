import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands.validate import validate_all, validate_change
from cash_cli.commands.archive import sync_change
from cash_cli.workspace import Workspace


class ValidationMatrixTests(unittest.TestCase):
    def make_workspace(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Workspace]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / ".cash.yaml").write_text("locale: tw\n", encoding="utf-8")
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "openspec" / "specs" / "existing").mkdir(parents=True)
        (root / "openspec" / "specs" / "existing" / "spec.md").write_text(
            "# Existing\n\n"
            "### Requirement: Existing behavior\n\n"
            "系統 SHALL 保留既有行為。\n\n"
            "#### Scenario: Existing\n\n"
            "- **WHEN** 執行\n- **THEN** 成功\n\n"
            "### Requirement: Removed behavior\n\n"
            "系統 SHALL 提供待移除行為。\n\n"
            "#### Scenario: Removed\n\n"
            "- **WHEN** 執行\n- **THEN** 成功\n",
            encoding="utf-8",
        )
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        return temporary, root, Workspace.discover(root)

    def add_change(self, root: Path, name: str, spec: str) -> Path:
        change = root / "openspec" / "changes" / name
        (change / "specs" / "existing").mkdir(parents=True)
        (change / ".openspec.yaml").write_text(
            "schema: spec-driven\ncreated: 2026-07-24\n",
            encoding="utf-8",
        )
        (change / "proposal.md").write_text(
            "## Summary\n\nDemo\n\n## Capabilities\n\nDemo\n\n## Impact\n\n- `src/demo.py`\n",
            encoding="utf-8",
        )
        (change / "design.md").write_text(
            "## Implementation Contract\n\n可觀察行為。\n",
            encoding="utf-8",
        )
        (change / "tasks.md").write_text(
            "## 1. Work\n\n- [ ] 1.1 實作並驗證 `src/demo.py`\n",
            encoding="utf-8",
        )
        (change / "specs" / "existing" / "spec.md").write_text(spec, encoding="utf-8")
        return change

    def test_each_delta_operation_is_accepted(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        valid = (
            "## ADDED Requirements\n\n"
            "### Requirement: Added behavior\n\n"
            "系統 SHALL 新增行為。\n\n"
            "#### Scenario: Added\n\n- **WHEN** 執行\n- **THEN** 成功\n\n"
            "## MODIFIED Requirements\n\n"
            "### Requirement: Existing behavior\n\n"
            "系統 SHALL 修改既有行為。\n\n"
            "#### Scenario: Modified\n\n- **WHEN** 執行\n- **THEN** 成功\n\n"
            "## REMOVED Requirements\n\n"
            "### Requirement: Removed behavior\n\n"
            "**Reason**: 已由新行為取代。\n\n"
            "#### Scenario: Removed\n\n- **WHEN** 執行\n- **THEN** 不再提供\n\n"
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Existing behavior`\n"
            "- TO: `### Requirement: Renamed behavior`\n"
        )
        self.add_change(root, "valid", valid)

        self.assertEqual(validate_change(workspace, "valid"), [])

    def test_missing_scenario_is_finding(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(
            root,
            "missing-scenario",
            "## ADDED Requirements\n\n"
            "### Requirement: Added behavior\n\n"
            "系統 SHALL 新增行為。\n",
        )

        findings = validate_change(workspace, "missing-scenario")

        self.assertIn("spec_missing_scenario", {item["code"] for item in findings})

    def test_modified_and_renamed_titles_must_match_master_byte_for_byte(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(
            root,
            "bad-title",
            "## MODIFIED Requirements\n\n"
            "### Requirement: Existing Behavior\n\n"
            "系統 SHALL 修改行為。\n\n"
            "#### Scenario: Modified\n\n- **WHEN** 執行\n- **THEN** 成功\n\n"
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Missing behavior`\n"
            "- TO: `### Requirement: New behavior`\n",
        )

        findings = validate_change(workspace, "bad-title")

        codes = [item["code"] for item in findings]
        self.assertEqual(codes.count("requirement_identity_mismatch"), 2)

    def test_renamed_destination_collisions_are_findings(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(
            root,
            "dup-rename",
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Existing behavior`\n"
            "- TO: `### Requirement: Merged behavior`\n\n"
            "- FROM: `### Requirement: Removed behavior`\n"
            "- TO: `### Requirement: Merged behavior`\n",
        )

        findings = validate_change(workspace, "dup-rename")

        collisions = [
            item for item in findings if item["code"] == "operation_collision"
        ]
        self.assertEqual(len(collisions), 1)
        self.assertIn("claimed by multiple renames", collisions[0]["message"])

    def test_renamed_destination_may_not_shadow_existing_or_added_title(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(
            root,
            "shadow-rename",
            "## ADDED Requirements\n\n"
            "### Requirement: Added behavior\n\n"
            "系統 SHALL 新增行為。\n\n"
            "#### Scenario: Added\n\n- **WHEN** 執行\n- **THEN** 成功\n\n"
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Existing behavior`\n"
            "- TO: `### Requirement: Added behavior`\n\n"
            "- FROM: `### Requirement: Removed behavior`\n"
            "- TO: `### Requirement: Existing behavior`\n",
        )

        findings = validate_change(workspace, "shadow-rename")

        messages = [
            item["message"]
            for item in findings
            if item["code"] == "operation_collision"
        ]
        self.assertTrue(
            any("collides with ADDED" in message for message in messages),
            messages,
        )
        self.assertTrue(
            any("already exists in master spec" in message for message in messages),
            messages,
        )

    def test_duplicate_task_labels_are_rejected(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        change = self.add_change(
            root,
            "duplicate-task",
            "## ADDED Requirements\n\n"
            "### Requirement: Added behavior\n\n"
            "系統 SHALL 新增行為。\n\n"
            "#### Scenario: Added\n\n- **WHEN** 執行\n- **THEN** 成功\n",
        )
        (change / "tasks.md").write_text(
            "## 1. Work\n\n- [ ] 1.1 First\n- [ ] 1.1 Second\n",
            encoding="utf-8",
        )

        findings = validate_change(workspace, "duplicate-task")

        self.assertIn("duplicate_task_id", {item["code"] for item in findings})

    def test_validate_all_is_sorted_and_aggregates_findings(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        invalid_spec = (
            "## ADDED Requirements\n\n"
            "### Requirement: Added behavior\n\n"
            "系統 SHALL 新增行為。\n"
        )
        self.add_change(root, "zeta", invalid_spec)
        self.add_change(root, "alpha", invalid_spec)

        result = validate_all(workspace)

        self.assertEqual([item["name"] for item in result], ["alpha", "zeta"])
        self.assertTrue(all(item["findings"] for item in result))

    def test_valid_sync_manifest_switches_identity_validation_to_post_sync_state(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        change = self.add_change(
            root,
            "synced",
            "## MODIFIED Requirements\n\n"
            "### Requirement: Existing behavior\n\n"
            "系統 SHALL 提供同步後行為。\n\n"
            "#### Scenario: Synced\n\n- **WHEN** 執行\n- **THEN** 成功\n\n"
            "## REMOVED Requirements\n\n"
            "### Requirement: Removed behavior\n\n"
            "**Reason**: 行為已退役。\n\n"
            "#### Scenario: Removed\n\n- **WHEN** 執行\n- **THEN** 不再提供\n\n"
            "## RENAMED Requirements\n\n"
            "- FROM: `### Requirement: Existing behavior`\n"
            "- TO: `### Requirement: Current behavior`\n",
        )
        (change / "tasks.md").write_text(
            "## 1. Work\n\n- [x] 1.1 Existing behavior `src/demo.py`\n",
            encoding="utf-8",
        )

        sync_change(workspace, "synced")

        self.assertEqual(validate_change(workspace, "synced"), [])


if __name__ == "__main__":
    unittest.main()
