import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands import tasks
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
    def enter_workspace(self) -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        subprocess.run(["git", "-C", str(root), "config", "user.email", "test@example.com"], check=True)
        subprocess.run(["git", "-C", str(root), "config", "user.name", "Test"], check=True)
        (root / ".cash.yaml").write_text(
            "locale: tw\ntdd: true\naudit: true\nparallel_tasks: false\n",
            encoding="utf-8",
        )
        (root / "openspec").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        lock = root / ".cash-workspace.lock"
        lock.touch()
        os.chmod(lock, 0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "src").mkdir()
        (root / "src" / "a.py").write_text("a = 1\n", encoding="utf-8")
        (root / "unrelated.txt").write_text("clean\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(root), "commit", "-qm", "baseline"], check=True)
        previous = Path.cwd()
        os.chdir(root)
        self.addCleanup(os.chdir, previous)
        return root

    def assert_execute_error(
        self,
        code: str,
        command: str,
        arguments: list[str],
    ) -> CashError:
        with self.assertRaises(CashError) as raised:
            tasks.execute(command, arguments)
        self.assertEqual(raised.exception.code, code)
        return raised.exception

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

    def write_touched_state(
        self,
        root: Path,
        entries: list[dict[str, object]],
        *,
        name: str = "demo",
        legacy: bool = False,
    ) -> Path:
        state_path = root / ".cash-skills" / "state" / "touched" / f"{name}.json"
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state = {
            "version": 1,
            "change": name,
            "legacy_import": (
                {
                    "path": f".spectra/touched/{name}.json",
                    "sha256": "0" * 64,
                    "st_dev": 1,
                    "st_ino": 1,
                }
                if legacy
                else None
            ),
            "touched": entries,
            "files": sorted(
                {path for entry in entries for path in entry["files"]},
                key=lambda path: path.encode("utf-8"),
            ),
        }
        state_path.write_text(
            json.dumps(state, ensure_ascii=False, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )
        return state_path

    def test_realign_inserted_task_uses_description_without_changing_payload(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        tasks_path = root / "openspec" / "changes" / "demo" / "tasks.md"
        tasks_path.write_text(
            "- [ ] 1.0 Prepare\n- [ ] 1.1 Change a\n- [ ] 1.2 Add b\n",
            encoding="utf-8",
        )
        self.write_touched_state(
            root,
            [{"task_id": "1", "task_desc": "1.1 Change a", "files": ["src/a.py"]}],
        )

        state = tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(state["touched"], [
            {"task_id": "2", "task_desc": "1.1 Change a", "files": ["src/a.py"]}
        ])

    def test_realign_missing_description_fails_closed_with_description(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        self.write_touched_state(
            root,
            [{"task_id": "1", "task_desc": "1.1 Removed", "files": []}],
        )

        with self.assertRaises(CashError) as raised:
            tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(raised.exception.code, "touched_invalid")
        self.assertIn("1.1 Removed", str(raised.exception))

    def test_realign_reserved_review_loop_entry_is_unchanged(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        entry = {"task_id": "review-loop", "task_desc": "Review loop outputs", "files": []}
        self.write_touched_state(root, [entry])

        state = tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(state["touched"], [entry])

    def test_realign_missing_tasks_file_returns_original_state(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        (root / "openspec" / "changes" / "demo" / "tasks.md").unlink()
        state_path = self.write_touched_state(
            root,
            [{"task_id": "9", "task_desc": "unknown", "files": []}],
        )
        expected = json.loads(state_path.read_text(encoding="utf-8"))

        self.assertEqual(tasks.load_or_import_touched(workspace, "demo"), expected)

    def test_realign_duplicate_resulting_ids_fail_closed(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        self.write_touched_state(
            root,
            [
                {"task_id": "1", "task_desc": "1.1 Change a", "files": []},
                {"task_id": "2", "task_desc": "1.1 Change a", "files": []},
            ],
        )

        with self.assertRaises(CashError) as raised:
            tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(raised.exception.code, "touched_invalid")

    def test_realign_legacy_collision_discards_all_changes(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        state_path = self.write_touched_state(
            root,
            [
                {"task_id": "2", "task_desc": "legacy unknown", "files": []},
                {"task_id": "1", "task_desc": "1.2 Add b", "files": []},
            ],
            legacy=True,
        )
        before = state_path.read_bytes()
        expected = json.loads(before)

        self.assertEqual(tasks.load_or_import_touched(workspace, "demo"), expected)
        self.assertEqual(state_path.read_bytes(), before)

    def test_realign_order_only_change_is_persisted_by_ensure(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        state_path = self.write_touched_state(
            root,
            [
                {"task_id": "2", "task_desc": "1.2 Add b", "files": []},
                {"task_id": "1", "task_desc": "1.1 Change a", "files": []},
            ],
        )
        before = state_path.read_bytes()

        ensure_touched(workspace, "demo")

        self.assertNotEqual(state_path.read_bytes(), before)
        state = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual([entry["task_id"] for entry in state["touched"]], ["1", "2"])

    def test_realign_read_only_load_does_not_write_state(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        tasks_path = root / "openspec" / "changes" / "demo" / "tasks.md"
        tasks_path.write_text("- [ ] 1.0 Prepare\n- [ ] 1.1 Change a\n", encoding="utf-8")
        state_path = self.write_touched_state(
            root,
            [{"task_id": "1", "task_desc": "1.1 Change a", "files": []}],
        )
        before = state_path.read_bytes()

        state = tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(state["touched"][0]["task_id"], "2")
        self.assertEqual(state_path.read_bytes(), before)

    def test_realign_ensure_persists_changed_attribution(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        tasks_path = root / "openspec" / "changes" / "demo" / "tasks.md"
        tasks_path.write_text("- [ ] 1.0 Prepare\n- [ ] 1.1 Change a\n", encoding="utf-8")
        state_path = self.write_touched_state(
            root,
            [{"task_id": "1", "task_desc": "1.1 Change a", "files": []}],
        )

        ensure_touched(workspace, "demo")

        self.assertEqual(
            json.loads(state_path.read_text(encoding="utf-8"))["touched"][0]["task_id"],
            "2",
        )

    def test_realign_record_persists_change_when_review_union_is_noop(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        tasks_path = root / "openspec" / "changes" / "demo" / "tasks.md"
        tasks_path.write_text("- [ ] 1.0 Prepare\n- [ ] 1.1 Change a\n", encoding="utf-8")
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        state_path = self.write_touched_state(
            root,
            [
                {"task_id": "1", "task_desc": "1.1 Change a", "files": []},
                {
                    "task_id": "review-loop",
                    "task_desc": "Review loop outputs",
                    "files": ["openspec/signals/demo.md"],
                },
            ],
        )

        self.assertEqual(
            tasks.execute("touched", ["record", "demo", "--path", "openspec/signals/demo.md"]),
            0,
        )
        self.assertEqual(
            json.loads(state_path.read_text(encoding="utf-8"))["touched"][0]["task_id"],
            "2",
        )

    def test_realign_ensure_noop_preserves_bytes_inode_and_mtime(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        state_path = self.write_touched_state(
            root,
            [{"task_id": "1", "task_desc": "1.1 Change a", "files": []}],
        )
        before = state_path.read_bytes()
        before_stat = state_path.stat()

        ensure_touched(workspace, "demo")

        after_stat = state_path.stat()
        self.assertEqual(state_path.read_bytes(), before)
        self.assertEqual(after_stat.st_ino, before_stat.st_ino)
        self.assertEqual(after_stat.st_mtime_ns, before_stat.st_mtime_ns)

    def test_realign_legacy_unknown_description_is_preserved(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        entry = {"task_id": "7", "task_desc": "legacy unknown", "files": ["src/a.py"]}
        self.write_touched_state(root, [entry], legacy=True)

        state = tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(state["touched"], [entry])

    def test_realign_task_parse_failure_returns_original_state(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        (root / "openspec" / "changes" / "demo" / "tasks.md").write_text(
            "- [ ] Missing label\n",
            encoding="utf-8",
        )
        state_path = self.write_touched_state(
            root,
            [{"task_id": "9", "task_desc": "unknown", "files": []}],
        )
        expected = json.loads(state_path.read_text(encoding="utf-8"))

        self.assertEqual(tasks.load_or_import_touched(workspace, "demo"), expected)

    def test_realign_parked_change_uses_parked_tasks(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        active = root / "openspec" / "changes" / "demo"
        parked = root / "openspec" / "changes" / ".parked" / "demo"
        active.rename(parked)
        (parked / "tasks.md").write_text(
            "- [ ] 1.0 Prepare\n- [ ] 1.1 Change a\n",
            encoding="utf-8",
        )
        self.write_touched_state(
            root,
            [{"task_id": "1", "task_desc": "1.1 Change a", "files": []}],
        )

        state = tasks.load_or_import_touched(workspace, "demo")

        self.assertEqual(state["touched"][0]["task_id"], "2")

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

    def test_explicit_parallel_completion_preserves_each_tasks_files(self) -> None:
        # Both workers finish before either records completion: the first must
        # not claim the second worker's file, regardless of completion order.
        for order in (("1", "2"), ("2", "1")):
            with self.subTest(order=order):
                temporary, root, workspace = self.make_workspace()
                self.addCleanup(temporary.cleanup)
                self.add_ready_change(root)
                start_in_progress(workspace, "demo")
                (root / "src/a.py").write_text("a = 2\n")
                (root / "src/b.py").write_text("b = 1\n")
                for task_id in order:
                    path = "src/a.py" if task_id == "1" else "src/b.py"
                    touched = mark_task_done(workspace, "demo", task_id, [path])
                self.assertEqual(
                    {entry["task_id"]: entry["files"] for entry in touched["touched"]},
                    {"1": ["src/a.py"], "2": ["src/b.py"]},
                )
                self.assertEqual(touched["files"], ["src/a.py", "src/b.py"])
                self.assertEqual(mark_task_done(workspace, "demo", order[-1], [path]), touched)

    def test_explicit_completion_does_not_consume_sibling_snapshot(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        start_in_progress(workspace, "demo")
        (root / "src/a.py").write_text("a = 2\n")
        (root / "src/b.py").write_text("b = 1\n")
        mark_task_done(workspace, "demo", "1", ["src/a.py"])
        touched = mark_task_done(workspace, "demo", "2")
        self.assertEqual(touched["touched"][1]["files"], ["src/b.py"])

    def test_explicit_completion_records_restoration_to_clean(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        source = root / "src/a.py"
        original = source.read_bytes()
        source.write_text("a = 99\n")
        start_in_progress(workspace, "demo")
        source.write_bytes(original)
        (root / "src/b.py").write_text("b = 1\n")
        touched = mark_task_done(workspace, "demo", "1", ["src/a.py"])
        self.assertEqual(touched["files"], ["src/a.py"])
        snapshot = json.loads((root / ".cash-skills/state/snapshots/demo.json").read_text())
        self.assertNotIn("src/a.py", [entry["path"] for entry in snapshot["paths"]])
        touched = mark_task_done(workspace, "demo", "2")
        self.assertEqual(touched["touched"][1]["files"], ["src/b.py"])

    def test_explicit_completion_retry_after_commit_is_task_scoped(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        start_in_progress(workspace, "demo")
        (root / "src/a.py").write_text("a = 2\n")
        expected = mark_task_done(workspace, "demo", "1", ["src/a.py"])
        subprocess.run(["git", "-C", str(root), "add", "src/a.py"], check=True)
        subprocess.run(["git", "-C", str(root), "commit", "-qm", "complete source"], check=True)
        self.assertEqual(mark_task_done(workspace, "demo", "1", ["src/a.py"]), expected)
        # Once the consumed baseline is cleared, another task cannot claim a
        # clean path solely because task 1 already owns it.
        before = (root / "openspec/changes/demo/tasks.md").read_bytes()
        with self.assertRaises(CashError):
            mark_task_done(workspace, "demo", "2", ["src/a.py"])
        self.assertEqual((root / "openspec/changes/demo/tasks.md").read_bytes(), before)

    def test_explicit_shared_file_and_empty_task(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        start_in_progress(workspace, "demo")
        (root / "src/a.py").write_text("a = 2\n")
        empty = mark_task_done(workspace, "demo", "1", [])
        self.assertEqual(empty["files"], [])
        mark_task_done(workspace, "demo", "2", ["src/a.py"])
        touched = mark_task_done(workspace, "demo", "1", ["src/a.py"])
        self.assertEqual([entry["files"] for entry in touched["touched"]], [["src/a.py"], ["src/a.py"]])

    def test_invalid_explicit_paths_do_not_mark_or_publish_state(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        start_in_progress(workspace, "demo")
        (root / "src/a.py").write_text("a = 2\n")
        task_file = root / "openspec/changes/demo/tasks.md"
        before = task_file.read_bytes()
        snapshot = root / ".cash-skills/state/snapshots/demo.json"
        baseline = snapshot.read_bytes()
        for bad in ("../outside", "src/missing.py", "./src/a.py", "openspec/changes/demo/tasks.md", ".cash-skills/state/snapshots/demo.json", "unrelated.txt"):
            with self.subTest(path=bad), self.assertRaises(CashError):
                mark_task_done(workspace, "demo", "1", ["src/a.py", bad])
            self.assertEqual(task_file.read_bytes(), before)
            self.assertEqual(snapshot.read_bytes(), baseline)
            self.assertFalse((root / ".cash-skills/state/touched/demo.json").exists())

    def test_explicit_paths_include_deleted_and_renamed_paths(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        self.add_ready_change(root)
        start_in_progress(workspace, "demo")
        subprocess.run(["git", "-C", str(root), "mv", "src/a.py", "src/新 名.py"], check=True)
        (root / "unrelated.txt").unlink()
        touched = mark_task_done(workspace, "demo", "1", ["src/a.py", "src/新 名.py", "unrelated.txt"])
        self.assertEqual(touched["files"], ["src/a.py", "src/新 名.py", "unrelated.txt"])

    def test_task_cli_explicit_flags_and_parallel_guard(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        task_file = root / "openspec/changes/demo/tasks.md"
        task_file.write_text(task_file.read_text().replace("- [ ]", "- [ ] [P]"))
        tasks.execute("in-progress", ["add", "demo"])
        (root / "src/a.py").write_text("a = 2\n")
        self.assert_execute_error("invalid_arguments", "task", ["done", "--change", "demo", "1"])
        self.assert_execute_error("invalid_arguments", "task", ["done", "--change", "demo", "1", "--no-files", "--path", "src/a.py"])
        self.assert_execute_error("invalid_arguments", "task", ["done", "--change", "demo", "1", "--path"])
        tasks.execute("task", ["done", "--change", "demo", "1", "--path", "src/a.py"])
        tasks.execute("task", ["done", "--change", "demo", "2", "--no-files"])
        touched = json.loads((root / ".cash-skills/state/touched/demo.json").read_text())
        self.assertEqual([entry["files"] for entry in touched["touched"]], [["src/a.py"], []])
        self.assertEqual(task_file.read_text().count("- [x]"), 2)

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

    def test_touched_record_without_snapshot_creates_review_loop_entry(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")

        self.assertEqual(tasks.execute("touched", ["ensure", "demo"]), 0)
        self.assertFalse(
            (root / ".cash-skills" / "state" / "snapshots" / "demo.json").exists()
        )
        self.assertEqual(
            tasks.execute(
                "touched",
                ["record", "demo", "--path", "openspec/signals/demo.md"],
            ),
            0,
        )

        state = json.loads(
            (
                root / ".cash-skills" / "state" / "touched" / "demo.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(
            state["touched"],
            [
                {
                    "task_id": "review-loop",
                    "task_desc": "Review loop outputs",
                    "files": ["openspec/signals/demo.md"],
                }
            ],
        )
        self.assertEqual(state["files"], ["openspec/signals/demo.md"])
        self.assertFalse(
            (root / ".cash-skills" / "state" / "snapshots" / "demo.json").exists()
        )

    def test_touched_record_preserves_per_task_entry_and_builds_unique_union(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        tasks.execute("in-progress", ["add", "demo"])
        (root / "src" / "a.py").write_text("a = 2\n", encoding="utf-8")
        tasks.execute("task", ["done", "--change", "demo", "1"])
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        before = json.loads(state_path.read_text(encoding="utf-8"))
        per_task = json.loads(json.dumps(before["touched"][0]))

        self.assertEqual(
            tasks.execute(
                "touched",
                [
                    "record",
                    "demo",
                    "--path",
                    "openspec/signals/demo.md",
                    "--path",
                    "src/a.py",
                ],
            ),
            0,
        )

        after = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(after["touched"][0], per_task)
        self.assertEqual(
            after["touched"][1],
            {
                "task_id": "review-loop",
                "task_desc": "Review loop outputs",
                "files": ["openspec/signals/demo.md", "src/a.py"],
            },
        )
        self.assertEqual(after["files"], ["openspec/signals/demo.md", "src/a.py"])

    def test_touched_record_noop_preserves_bytes_inode_and_mtime(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        tasks.execute("touched", ["ensure", "demo"])
        arguments = ["record", "demo", "--path", "openspec/signals/demo.md"]
        tasks.execute("touched", arguments)
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        before_bytes = state_path.read_bytes()
        before_stat = state_path.stat()

        self.assertEqual(tasks.execute("touched", arguments), 0)

        after_stat = state_path.stat()
        self.assertEqual(state_path.read_bytes(), before_bytes)
        self.assertEqual(after_stat.st_ino, before_stat.st_ino)
        self.assertEqual(after_stat.st_mtime_ns, before_stat.st_mtime_ns)

    def test_touched_record_requires_complete_path_arguments_without_writes(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"

        for arguments in (["record", "demo"], ["record", "demo", "--path"]):
            with self.subTest(arguments=arguments):
                self.assert_execute_error("invalid_arguments", "touched", arguments)
                self.assertFalse(state_path.exists())

    def test_touched_record_rejects_unsafe_paths_without_writes(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        tasks.execute("touched", ["ensure", "demo"])
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        before = state_path.read_bytes()
        unsafe_paths = (
            str(root / "src" / "a.py"),
            "src/../src/a.py",
            ".git/config",
            ".cash-skills/state/touched/demo.json",
            "./.git/config",
            "./.cash-skills/state/touched/demo.json",
        )

        for path in unsafe_paths:
            with self.subTest(path=path):
                self.assert_execute_error(
                    "touched_invalid",
                    "touched",
                    ["record", "demo", "--path", path],
                )
                self.assertEqual(state_path.read_bytes(), before)

    def test_touched_record_rejects_ignored_prefixes_but_accepts_runtime_files(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        runtime = root / ".cash-skills" / "lib" / "cash_cli" / "commands" / "tasks.py"
        runtime.parent.mkdir(parents=True)
        runtime.write_text("# runtime\n", encoding="utf-8")
        (root / ".cash-skills" / "receipt.tsv").write_text("receipt\n", encoding="utf-8")
        tasks.execute("touched", ["ensure", "demo"])
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        before = state_path.read_bytes()

        for path in (
            "openspec/changes/demo/design.md",
            ".cash-skills/receipt.tsv",
        ):
            with self.subTest(path=path):
                self.assert_execute_error(
                    "touched_invalid",
                    "touched",
                    ["record", "demo", "--path", path],
                )
                self.assertEqual(state_path.read_bytes(), before)

        self.assertEqual(
            tasks.execute(
                "touched",
                [
                    "record",
                    "demo",
                    "--path",
                    ".cash-skills/lib/cash_cli/commands/tasks.py",
                ],
            ),
            0,
        )
        state = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(
            state["files"],
            [".cash-skills/lib/cash_cli/commands/tasks.py"],
        )

    def test_touched_record_rejects_missing_and_directory_paths_without_writes(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        tasks.execute("touched", ["ensure", "demo"])
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        before = state_path.read_bytes()

        for path in ("src/missing.py", "src"):
            with self.subTest(path=path):
                self.assert_execute_error(
                    "touched_invalid",
                    "touched",
                    ["record", "demo", "--path", path],
                )
                self.assertEqual(state_path.read_bytes(), before)

    def test_touched_record_rejects_missing_change_without_creating_state(self) -> None:
        root = self.enter_workspace()
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        state_path = root / ".cash-skills" / "state" / "touched" / "absent-change.json"

        self.assert_execute_error(
            "change_not_found",
            "touched",
            [
                "record",
                "absent-change",
                "--path",
                "openspec/signals/demo.md",
            ],
        )

        self.assertFalse(state_path.exists())

    def test_touched_record_requires_ensure_without_importing_legacy_state(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        legacy = root / ".spectra" / "touched" / "demo.json"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(
            '{"change":"demo","touched":[]}',
            encoding="utf-8",
        )
        legacy_bytes = legacy.read_bytes()
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"

        self.assert_execute_error(
            "touched_invalid",
            "touched",
            ["record", "demo", "--path", "openspec/signals/demo.md"],
        )

        self.assertFalse(state_path.exists())
        self.assertEqual(legacy.read_bytes(), legacy_bytes)

    def test_touched_record_does_not_modify_tasks_or_snapshot(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        tasks.execute("in-progress", ["add", "demo"])
        tasks.execute("touched", ["ensure", "demo"])
        tasks_path = root / "openspec" / "changes" / "demo" / "tasks.md"
        snapshot_path = root / ".cash-skills" / "state" / "snapshots" / "demo.json"
        tasks_bytes = tasks_path.read_bytes()
        snapshot_bytes = snapshot_path.read_bytes()

        self.assertEqual(
            tasks.execute(
                "touched",
                ["record", "demo", "--path", "openspec/signals/demo.md"],
            ),
            0,
        )

        self.assertEqual(tasks_path.read_bytes(), tasks_bytes)
        self.assertEqual(snapshot_path.read_bytes(), snapshot_bytes)

    def test_touched_record_mixed_paths_is_atomic(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signals = root / "openspec" / "signals"
        signals.mkdir()
        (signals / "one.md").write_text("# One\n", encoding="utf-8")
        (signals / "two.md").write_text("# Two\n", encoding="utf-8")
        tasks.execute("touched", ["ensure", "demo"])
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        before = state_path.read_bytes()

        self.assert_execute_error(
            "touched_invalid",
            "touched",
            [
                "record",
                "demo",
                "--path",
                "openspec/signals/one.md",
                "--path",
                "src/missing.py",
                "--path",
                "openspec/signals/two.md",
            ],
        )

        self.assertEqual(state_path.read_bytes(), before)

    def test_touched_record_preserves_existing_task_order(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        tasks.execute("touched", ["ensure", "demo"])
        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        task_ids = sorted((str(index) for index in range(1, 11)), key=str.encode)
        (root / "openspec" / "changes" / "demo" / "tasks.md").write_text(
            "".join(f"- [ ] 1.{index} Task {index}\n" for index in range(1, 11)),
            encoding="utf-8",
        )
        per_task_entries = [
            {
                "task_id": task_id,
                "task_desc": f"1.{int(task_id)} Task {int(task_id)}",
                "files": [],
            }
            for task_id in task_ids
        ]
        state = json.loads(state_path.read_text(encoding="utf-8"))
        state["touched"] = per_task_entries
        state_path.write_text(
            json.dumps(state, ensure_ascii=False, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )

        self.assertEqual(
            tasks.execute(
                "touched",
                ["record", "demo", "--path", "openspec/signals/demo.md"],
            ),
            0,
        )

        updated = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(updated["touched"][:10], per_task_entries)
        self.assertEqual(updated["touched"][10]["task_id"], "review-loop")

    def test_touched_record_canonicalizes_relative_path_aliases(self) -> None:
        root = self.enter_workspace()
        self.add_ready_change(root)
        signal = root / "openspec" / "signals" / "demo.md"
        signal.parent.mkdir()
        signal.write_text("# Demo\n", encoding="utf-8")
        tasks.execute("touched", ["ensure", "demo"])

        for path in ("./openspec/signals/demo.md", "openspec//signals/demo.md"):
            with self.subTest(path=path):
                self.assertEqual(
                    tasks.execute(
                        "touched",
                        ["record", "demo", "--path", path],
                    ),
                    0,
                )

        state_path = root / ".cash-skills" / "state" / "touched" / "demo.json"
        state = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(state["files"], ["openspec/signals/demo.md"])

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
