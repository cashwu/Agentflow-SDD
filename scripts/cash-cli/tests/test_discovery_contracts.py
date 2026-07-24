import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands.discovery import (
    apply_payload,
    artifact_instruction_payload,
    list_payload,
    skill_payload,
    status_payload,
)
from cash_cli.commands.analyze import analyze_payload
from cash_cli.commands.archive import sync_change
from cash_cli.commands.drift import drift_payload
from cash_cli.errors import CashError
from cash_cli.validation import validate_change
from cash_cli.workspace import Workspace


class DiscoveryContractTests(unittest.TestCase):
    def make_workspace(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Workspace]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / ".cash.yaml").write_text(
            "locale: tw\ntdd: true\naudit: true\nparallel_tasks: true\n",
            encoding="utf-8",
        )
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n"
            "context: |\n"
            "  Repository context\n"
            "rules:\n"
            "  tasks:\n"
            "    - Keep tasks small\n",
            encoding="utf-8",
        )
        return temporary, root, Workspace.discover(root)

    def add_change(
        self,
        root: Path,
        name: str,
        *,
        parked: bool = False,
        artifacts: tuple[str, ...] = ("proposal", "design", "specs", "tasks"),
        done: bool = False,
    ) -> Path:
        parent = root / "openspec" / "changes"
        if parked:
            parent = parent / ".parked"
        change = parent / name
        change.mkdir()
        (change / ".openspec.yaml").write_text(
            "schema: spec-driven\ncreated: 2026-07-23\n",
            encoding="utf-8",
        )
        if "proposal" in artifacts:
            (change / "proposal.md").write_text(
                "## Summary\n\nA concise demo summary.\n",
                encoding="utf-8",
            )
        if "design" in artifacts:
            (change / "design.md").write_text(
                "## Implementation Contract\n\nObservable behavior.\n",
                encoding="utf-8",
            )
        if "specs" in artifacts:
            spec = change / "specs" / "demo"
            spec.mkdir(parents=True)
            (spec / "spec.md").write_text(
                "## ADDED Requirements\n\n"
                "### Requirement: Demo\n\n"
                "系統 SHALL 運作。\n\n"
                "#### Scenario: Demo\n\n"
                "- **WHEN** 執行\n- **THEN** 成功\n",
                encoding="utf-8",
            )
        if "tasks" in artifacts:
            mark = "x" if done else " "
            (change / "tasks.md").write_text(
                f"## 1. Work\n\n- [{mark}] 1.1 Implement demo\n",
                encoding="utf-8",
            )
        return change

    def test_empty_and_sorted_active_and_parked_lists(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.assertEqual(list_payload(workspace, parked=False), {"changes": []})
        self.assertEqual(list_payload(workspace, parked=True), {"parked": []})
        self.add_change(root, "zeta")
        self.add_change(root, "alpha", parked=True, done=True)
        self.add_change(root, "beta")

        active = list_payload(workspace, parked=False)
        parked = list_payload(workspace, parked=True)

        self.assertEqual([item["name"] for item in active["changes"]], ["beta", "zeta"])
        self.assertEqual(list(active), ["changes"])
        self.assertEqual([item["name"] for item in parked["parked"]], ["alpha"])
        self.assertEqual(parked["parked"][0]["completedTasks"], 1)

    def test_status_uses_graph_order_and_readiness(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, "demo", artifacts=("proposal",))

        payload = status_payload(workspace, "demo")

        self.assertEqual(
            [artifact["id"] for artifact in payload["artifacts"]],
            ["proposal", "design", "specs", "tasks"],
        )
        self.assertEqual(
            [artifact["status"] for artifact in payload["artifacts"]],
            ["done", "ready", "ready", "blocked"],
        )
        self.assertEqual(payload["artifacts"][3]["missingDeps"], ["design", "specs"])
        self.assertFalse(payload["isComplete"])

    def test_artifact_instructions_include_context_rules_dependencies_and_unlocks(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, "demo", artifacts=("proposal",))

        payload = artifact_instruction_payload(workspace, "demo", "tasks")

        self.assertEqual(payload["context"], "Repository context")
        self.assertEqual(payload["rules"], ["Keep tasks small"])
        self.assertEqual(
            [dependency["id"] for dependency in payload["dependencies"]],
            ["proposal", "design", "specs"],
        )
        self.assertEqual(payload["unlocks"], [])
        self.assertTrue(all(set(item) == {"id", "done", "path", "description"} for item in payload["dependencies"]))

    def test_apply_blocked_ready_and_all_done_shapes(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_change(root, "blocked", artifacts=("proposal", "design", "specs"))
        self.add_change(root, "ready")
        self.add_change(root, "done", done=True)

        blocked = apply_payload(workspace, "blocked")
        ready = apply_payload(workspace, "ready")
        done = apply_payload(workspace, "done")

        self.assertEqual(blocked["state"], "blocked")
        self.assertEqual(blocked["missingArtifacts"], ["tasks"])
        self.assertEqual(ready["state"], "ready")
        self.assertEqual(ready["progress"], {"total": 1, "complete": 0, "remaining": 1})
        self.assertEqual(
            ready["tasks"],
            [{"id": "1", "description": "1.1 Implement demo", "done": False, "parallel": False}],
        )
        self.assertEqual(done["state"], "all_done")
        self.assertEqual(done["missingArtifacts"], [])
        for payload in (blocked, ready, done):
            self.assertEqual(
                set(payload["preflight"]),
                {"status", "missingFiles", "driftedFiles", "staleness"},
            )
            self.assertNotIn(None, _walk(payload))

    def test_preflight_missing_modified_file_is_critical(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        change = self.add_change(root, "demo")
        (change / "design.md").write_text(
            "## Implementation Contract\n\nModified: `src/missing.py`\n",
            encoding="utf-8",
        )

        preflight = apply_payload(workspace, "demo")["preflight"]

        self.assertEqual(preflight["status"], "critical")
        self.assertEqual(
            preflight["missingFiles"],
            [{"path": "src/missing.py", "source": "design.md"}],
        )

    def test_preflight_existing_modified_file_is_warning(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        change = self.add_change(root, "demo")
        (root / "src").mkdir()
        (root / "src" / "app.py").write_text("print('ok')\n", encoding="utf-8")
        (change / "design.md").write_text(
            "## Implementation Contract\n\nModified: `src/app.py`\n",
            encoding="utf-8",
        )

        preflight = apply_payload(workspace, "demo")["preflight"]

        self.assertEqual(preflight["status"], "warnings")
        self.assertEqual(preflight["driftedFiles"], ["src/app.py"])

    def test_skill_instructions_have_exact_shape(self) -> None:
        for skill in ("tdd", "audit"):
            payload = skill_payload(skill)
            self.assertEqual(set(payload), {"skill", "locale", "instruction"})
            self.assertTrue(payload["instruction"])

    def test_all_artifact_readers_reject_external_change_symlink(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        outside = Path(temporary.name).parent / f"{root.name}-outside"
        outside.mkdir()
        self.addCleanup(lambda: outside.rmdir())
        sentinel = outside / "proposal.md"
        sentinel.write_text("EXTERNAL-SENTINEL\n", encoding="utf-8")
        self.addCleanup(sentinel.unlink)
        (root / "openspec" / "changes" / "unsafe").symlink_to(
            outside,
            target_is_directory=True,
        )

        readers = (
            lambda: status_payload(workspace, "unsafe"),
            lambda: analyze_payload(workspace, "unsafe"),
            lambda: drift_payload(workspace, "unsafe"),
            lambda: validate_change(workspace, "unsafe"),
            lambda: sync_change(workspace, "unsafe"),
        )
        for reader in readers:
            with self.subTest(reader=reader):
                with self.assertRaises(CashError) as raised:
                    reader()
                self.assertEqual(raised.exception.code, "unsafe_path")
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "EXTERNAL-SENTINEL\n")


def _walk(value: object) -> list[object]:
    values = [value]
    if isinstance(value, dict):
        for nested in value.values():
            values.extend(_walk(nested))
    elif isinstance(value, list):
        for nested in value:
            values.extend(_walk(nested))
    return values


if __name__ == "__main__":
    unittest.main()
