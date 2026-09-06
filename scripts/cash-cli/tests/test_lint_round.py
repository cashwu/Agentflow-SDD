import contextlib
import io
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock
from pathlib import Path

from cash_cli.main import main
from cash_cli.commands.lint_round import _git_changed


ROOT = Path(__file__).parents[3]
FIXTURES = ROOT / "scripts" / "cash-cli" / "tests" / "fixtures" / "lint_round"


def round_file(*, decision="passed", round_type="full", sections=True) -> str:
    parts = ["## Reviewer Findings", "## Rating", f"- `round_type`: `{round_type}`"]
    if sections:
        parts.append("## Fix Actions")
    parts.extend(["## Decision", decision, "Rationale."])
    return "\n".join(parts) + "\n"


class LintRoundTests(unittest.TestCase):
    def workspace(self) -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / ".cash.yaml").write_text("locale: zh-TW\n", encoding="utf-8")
        (root / "openspec").mkdir()
        (root / "openspec" / "config.yaml").write_text("schema: spec-driven\n", encoding="utf-8")
        (root / ".cash-workspace.lock").touch()
        change = root / "openspec" / "changes" / "demo"
        (change / "reviews").mkdir(parents=True)
        (change / "proposal.md").write_text(
            "## Impact\n- Affected code:\n  - .cash.yaml\n", encoding="utf-8"
        )
        self.previous_cwd = Path.cwd()
        self.previous_project_root = os.environ.pop("CASH_PROJECT_ROOT", None)
        os.chdir(root)
        self.addCleanup(os.chdir, self.previous_cwd)
        self.addCleanup(self._restore_project_root)
        return root

    def _restore_project_root(self) -> None:
        if self.previous_project_root is not None:
            os.environ["CASH_PROJECT_ROOT"] = self.previous_project_root

    def invoke(self, *args: str, stdin: str = "") -> tuple[int, str, str]:
        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            with mock.patch("sys.stdin", io.StringIO(stdin)):
                code = main(list(args))
        return code, stdout.getvalue(), stderr.getvalue()

    def write_round(self, root: Path, name: str, content: str | None = None) -> None:
        path = root / "openspec" / "changes" / "demo" / "reviews" / name
        path.write_text(content or round_file(), encoding="utf-8")

    def test_command_is_registered_and_unknown_extra_argument_is_rejected(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md")
        code, stdout, stderr = self.invoke("lint-round", "demo", "extra")
        self.assertEqual(code, 2)
        self.assertEqual(stdout, "")
        self.assertIn("invalid_arguments", stderr)

    def test_valid_single_change_json_has_four_checks_and_clean_stderr(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))
        self.assertEqual(stderr, "")
        payload = json.loads(stdout)
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["change"], "demo")
        self.assertEqual({item["id"] for item in payload["checks"]}, {
            "round_file_schema", "decision_value", "round_type_position", "grader_immutability"
        })

    def test_missing_sections_and_invalid_decision_fail_without_aborting_other_checks(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md", round_file(sections=False))
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        self.assertEqual(stderr, "")
        payload = json.loads(stdout)
        self.assertFalse(payload["ok"])
        ids = {item["id"] for item in payload["checks"]}
        self.assertIn("round_file_schema", ids)
        self.assertIn("decision_value", ids)
        self.assertIn("round_type_position", ids)

    def test_round_files_are_filtered_and_each_skill_starts_at_one(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        self.write_round(root, "apply-r2.md", round_file(decision="passed", round_type="micro"))
        self.write_round(root, "propose-r1.md")
        reviews = root / "openspec" / "changes" / "demo" / "reviews"
        (reviews / "loop-ledger.tsv").write_text("not a round\n", encoding="utf-8")
        (reviews / "accepted-risks.md").write_text("not a round\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, stdout)
        payload = json.loads(stdout)
        self.assertTrue(payload.get("ok"), (stdout, stderr))

    def test_no_round_files_skips_all_gates(self) -> None:
        root = self.workspace()
        _, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        payload = json.loads(stdout)
        self.assertTrue(payload.get("ok"), (stdout, stderr))
        self.assertEqual(stderr, "")
        self.assertTrue(all(item["status"] == "skip" for item in payload["checks"]))

    def test_static_fixture_directory_is_nonempty_and_contains_only_round_files(self) -> None:
        root = self.workspace()
        files = sorted(FIXTURES.glob("*-r[0-9]*.md"))
        self.assertTrue(files)
        self.assertTrue(all(path.name.startswith(("apply-r", "propose-r")) for path in files))
        reviews = root / "openspec" / "changes" / "demo" / "reviews"
        for path in files:
            shutil.copy2(path, reviews / path.name)
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))
        self.assertTrue(json.loads(stdout)["ok"])

    def test_immutability_ignores_verification_text_after_affected_code_tree(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code:\n  - safe.md\n- Verification: `.cash.yaml`\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        (root / ".cash.yaml").write_text("locale: zh-HK\n", encoding="utf-8")
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_tasks_delivery_supports_fullwidth_semicolon(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text("", encoding="utf-8")
        change.joinpath("tasks.md").write_text(
            "- [ ] delivery: .cash.yaml；verification: test\n", encoding="utf-8"
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

    def test_tasks_delivery_field_follows_task_description(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text("", encoding="utf-8")
        change.joinpath("tasks.md").write_text(
            "- [ ] 1.1 更新設定；delivery: .cash.yaml；verification: test\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

    def test_hook_workspace_error_is_gate_unavailable_for_json(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        previous = Path.cwd()
        os.chdir(temporary.name)
        self.addCleanup(os.chdir, previous)
        code, stdout, stderr = self.invoke("lint-round", "--hook", "--json")
        self.assertEqual(code, 1)
        self.assertEqual(stdout, "")
        self.assertIn("gate_unavailable", stderr)

    def test_hook_reentry_failure_and_success_matrix(self) -> None:
        root = self.workspace()
        root.joinpath("openspec/changes/demo/proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        protected = root / "scripts" / "cash-skills" / "blocks"
        protected.mkdir(parents=True)
        (protected / "review-gate.md").write_text("changed\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "--hook", stdin='{"stop_hook_active":true}')
        self.assertEqual(code, 1)
        self.assertEqual(stdout, "")
        self.assertIn("grader_immutability", stderr)
        code, stdout, stderr = self.invoke("lint-round", "--hook", "--json", stdin='{"stop_hook_active":true}')
        self.assertEqual(code, 1)
        self.assertFalse(json.loads(stdout)["ok"])
        self.assertIn("grader_immutability", stderr)

    def test_run_boundary_requires_contiguous_sequence_and_fourth_round_full(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        self.write_round(root, "apply-r2.md", round_file(decision="next_round", round_type="micro"))
        self.write_round(root, "apply-r3.md", round_file(decision="next_round", round_type="micro"))
        self.write_round(root, "apply-r4.md", round_file(decision="passed", round_type="full"))
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))
        reviews = root / "openspec" / "changes" / "demo" / "reviews"
        (reviews / "apply-r3.md").unlink()
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        self.assertIn("round_type_position", {item["id"] for item in json.loads(stdout)["checks"]})

    def test_lint_round_does_not_change_workspace_files(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md")

        def snapshot() -> dict[str, tuple[int, bytes]]:
            values = {}
            for path in root.rglob("*"):
                if ".git" in path.parts or "__pycache__" in path.parts or not path.is_file():
                    continue
                values[path.relative_to(root).as_posix()] = (path.stat().st_mode, path.read_bytes())
            return values

        before = snapshot()
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))
        self.assertEqual(snapshot(), before)

    def test_missing_r1_and_noncontiguous_round_numbers_fail(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r2.md", round_file())
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        self.assertIn("missing r1", json.loads(stdout)["checks"][2]["detail"])

        reviews = root / "openspec" / "changes" / "demo" / "reviews"
        (reviews / "apply-r2.md").unlink()
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        self.write_round(root, "apply-r3.md", round_file(round_type="micro"))
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        self.assertIn("missing r2", json.loads(stdout)["checks"][2]["detail"])

    def test_unparseable_previous_decision_and_duplicate_round_type_fail(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md", round_file(decision="not-a-decision"))
        self.write_round(root, "apply-r2.md", round_file(decision="passed", round_type="micro"))
        duplicate = round_file().replace("## Fix Actions", "- `round_type`: `full`\n## Fix Actions")
        self.write_round(root, "propose-r1.md", duplicate)
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        details = [item["detail"] for item in json.loads(stdout)["checks"] if item["id"] == "round_type_position"]
        self.assertTrue(any("decision prevents run boundary" in detail for detail in details))
        self.assertTrue(any("unparseable" in detail for detail in details))

    def test_hook_ignores_non_directory_and_invalid_change_names(self) -> None:
        root = self.workspace()
        (root / "openspec" / "changes" / ".DS_Store").write_text("file", encoding="utf-8")
        (root / "openspec" / "changes" / "Bad_Name").mkdir()
        code, stdout, stderr = self.invoke("lint-round", "--hook", "--json", stdin="{}")
        self.assertEqual(code, 0, (stdout, stderr))
        names = {item["change"] for item in json.loads(stdout)["checks"]}
        self.assertEqual(names, {"demo"})

    def test_missing_proposal_or_tasks_keeps_the_other_declaration_source(self) -> None:
        root = self.workspace()
        demo = root / "openspec" / "changes" / "demo"
        demo.joinpath("proposal.md").unlink()
        demo.joinpath("tasks.md").write_text(
            "- [ ] delivery: .cash.yaml；verification: test\n", encoding="utf-8"
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

        demo.joinpath("tasks.md").unlink()
        demo.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code:\n  - .cash.yaml\n", encoding="utf-8"
        )
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

    def test_parked_and_archived_declarations_do_not_cover_active_change(self) -> None:
        root = self.workspace()
        demo = root / "openspec" / "changes" / "demo"
        demo.joinpath("proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        parked = root / "openspec" / "changes" / ".parked" / "parked-change"
        parked.mkdir(parents=True)
        parked.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code:\n  - .cash.yaml\n", encoding="utf-8"
        )
        archived = root / "openspec" / "changes" / "archive" / "2026-01-01-old"
        archived.mkdir(parents=True)
        archived.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code:\n  - .cash.yaml\n", encoding="utf-8"
        )
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_specs_directory_declaration_covers_master_spec_file(self) -> None:
        root = self.workspace()
        demo = root / "openspec" / "changes" / "demo"
        demo.joinpath("proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        source = root / "openspec" / "changes" / "source-change"
        source.mkdir()
        source.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code:\n  - .cash.yaml\n  - openspec/specs/\n", encoding="utf-8"
        )
        master = root / "openspec" / "specs" / "cash-cli"
        master.mkdir(parents=True)
        (master / "spec.md").write_text("changed\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

    def test_bytecode_cache_does_not_trigger_grader_gate(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md")
        cache = root / ".cash-skills" / "lib" / "cash_cli" / "commands" / "__pycache__"
        cache.mkdir(parents=True)
        (cache / "lint_round.cpython-314.pyc").write_bytes(b"cache")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

    def test_immutability_active_is_derived_per_skill_and_protected_untracked_path_fails(self) -> None:
        root = self.workspace()
        (root / "openspec" / "changes" / "demo" / "proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "propose-r1.md")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        protected = root / "scripts" / "cash-skills" / "blocks"
        protected.mkdir(parents=True)
        (protected / "review-gate.md").write_text("changed\n", encoding="utf-8")
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        payload = json.loads(stdout)
        grader = next(item for item in payload["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_immutability_tasks_delivery_target_covers_protected_path(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        (change / "proposal.md").write_text("", encoding="utf-8")
        (change / "tasks.md").write_text(
            "- [ ] 1.1 delivery: .cash.yaml, scripts/cash-skills/blocks/review-gate.md; verification: test\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        protected = root / "scripts" / "cash-skills" / "blocks"
        protected.mkdir(parents=True)
        (protected / "review-gate.md").write_text("changed\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "pass")

    def test_scope_parsers_ignore_verification_and_fenced_examples(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text(
            "## Impact\n"
            "```markdown\n"
            "- Affected code: `.cash.yaml`\n"
            "```\n"
            "- Verification:\n"
            "  - Affected code: `.cash-skills/lib/cash_cli/commands/lint_round.py`\n"
            "- Affected code: .cash.yaml\n"
            "  - Example:\n"
            "    - `scripts/cash-skills/blocks/review-gate.md`\n"
            "  - Verification: `.cash-skills/lib/cash_cli/commands/lint_round.py`\n",
            encoding="utf-8",
        )
        change.joinpath("tasks.md").write_text(
            "- [ ] 1.1 delivery: .cash.yaml；verification: `.cash-skills/lib/cash_cli/commands/lint_round.py`\n"
            "```text\n"
            "- delivery: scripts/cash-skills/blocks/review-gate.md\n"
            "```\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        protected = root / "scripts" / "cash-skills" / "blocks"
        protected.mkdir(parents=True)
        (protected / "review-gate.md").write_text("changed\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2, (stdout, stderr))
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_scope_parser_accepts_same_line_affected_code(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code: .cash.yaml\n", encoding="utf-8"
        )
        self.write_round(root, "apply-r1.md")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))

    def test_scope_parser_ignores_notes_under_modified_entry(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text(
            "## Impact\n"
            "- Affected code:\n"
            "  - Modified: src/demo.py\n"
            "    - Notes: 保持 `.cash.yaml` 不變。\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        (root / ".cash.yaml").write_text("locale: zh-HK\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2, (stdout, stderr))
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_scope_parser_ignores_notes_subtree_under_modified_entry(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text(
            "## Impact\n"
            "- Affected code:\n"
            "  - Modified: src/demo.py\n"
            "    - Notes: 以下設定保持不變\n"
            "      - `.cash.yaml`\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        (root / ".cash.yaml").write_text("locale: zh-HK\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2, (stdout, stderr))
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_scope_parser_ignores_non_declaration_parent_subtrees_in_chinese(self) -> None:
        for parent in ("備註：以下設定保持不變", "以下設定保持不變"):
            with self.subTest(parent=parent):
                root = self.workspace()
                change = root / "openspec" / "changes" / "demo"
                change.joinpath("proposal.md").write_text(
                    "## Impact\n"
                    "- Affected code:\n"
                    "  - Modified: src/demo.py\n"
                    f"    - {parent}\n"
                    "      - `.cash.yaml`\n",
                    encoding="utf-8",
                )
                self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
                (root / ".cash.yaml").write_text("locale: zh-HK\n", encoding="utf-8")
                code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
                self.assertEqual(code, 2, (stdout, stderr))
                grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
                self.assertEqual(grader["status"], "fail")

    def test_scope_parser_ignores_notes_on_same_line_affected_code(self) -> None:
        root = self.workspace()
        change = root / "openspec" / "changes" / "demo"
        change.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code: Notes: 保持 `.cash.yaml` 不變\n",
            encoding="utf-8",
        )
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        (root / ".cash.yaml").write_text("locale: zh-HK\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2, (stdout, stderr))
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def _workspace_state(self, root: Path) -> dict[str, tuple[object, ...]]:
        state: dict[str, tuple[object, ...]] = {}
        for path in root.rglob("*"):
            if ".git" in path.parts:
                continue
            relative = path.relative_to(root).as_posix()
            mode = path.stat().st_mode
            if path.is_dir():
                state[relative] = ("dir", mode)
            elif path.is_file():
                state[relative] = ("file", mode, path.read_bytes())
        return state

    def _run_launcher_readonly_case(self, mode: str) -> set[str]:
        root = self.workspace()
        shutil.copytree(
            ROOT / ".cash-skills",
            root / ".cash-skills",
            ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "receipt.tsv"),
        )
        launcher = root / ".cash-skills" / "bin" / "cash"
        shutil.copytree(ROOT / ".agents", root / ".agents")
        shutil.copytree(ROOT / ".claude", root / ".claude")
        if mode == "receipt":
            (root / ".cash-skills" / "manifest.tsv").unlink()
            result = subprocess.run(
                [
                    os.environ.get("PYTHON", "python3"),
                    "-s",
                    "-P",
                    "-B",
                    "-m",
                    "cash_cli.installer",
                    "--init-receipt",
                ],
                cwd=root,
                env={**os.environ, "PYTHONPATH": str(root / ".cash-skills" / "lib")},
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        before = self._workspace_state(root)
        launcher_env = dict(os.environ)
        launcher_env.pop("PYTHONDONTWRITEBYTECODE", None)
        result = subprocess.run(
            [str(launcher), "lint-round", "demo", "--json"],
            cwd=root,
            env=launcher_env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        after = self._workspace_state(root)
        changed = set(before) ^ set(after)
        changed.update(path for path in set(before) & set(after) if before[path] != after[path])
        return changed

    def test_launcher_readonly_contract_covers_portable_and_receipt_targets(self) -> None:
        portable_changes = self._run_launcher_readonly_case("portable")
        self.assertEqual(portable_changes, set())
        receipt_changes = self._run_launcher_readonly_case("receipt")
        self.assertTrue(receipt_changes)
        self.assertTrue(all("__pycache__" in path or path.endswith(".pyc") for path in receipt_changes))

    def test_immutability_staged_protected_path_is_in_change_set(self) -> None:
        root = self.workspace()
        (root / "openspec" / "changes" / "demo" / "proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        protected = root / "scripts" / "cash-skills" / "blocks"
        protected.mkdir(parents=True)
        path = protected / "review-gate.md"
        path.write_text("changed\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(root), "add", "scripts/cash-skills/blocks/review-gate.md"], check=True)
        code, stdout, _ = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "fail")

    def test_hook_reads_stop_payload_and_returns_json_for_each_change(self) -> None:
        root = self.workspace()
        self.write_round(root, "apply-r1.md")
        parked = root / "openspec" / "changes" / ".parked" / "parked-change" / "reviews"
        parked.mkdir(parents=True)
        (parked / "apply-r1.md").write_text(round_file(decision="next_round"), encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "--hook", "--json", stdin='{"stop_hook_active":false}')
        self.assertEqual(code, 0)
        self.assertEqual(stderr, "")
        payload = json.loads(stdout)
        self.assertTrue(payload["ok"])
        self.assertTrue({item["change"] for item in payload["checks"]} >= {"demo", "parked-change"})

    def test_hook_fail_open_reports_invalid_json_and_never_exits_zero(self) -> None:
        self.workspace()
        code, stdout, stderr = self.invoke("lint-round", "--hook", stdin="{")
        self.assertEqual(code, 1)
        self.assertEqual(stdout, "")
        self.assertIn("gate_unavailable", stderr)

    def test_single_change_uses_declarations_from_other_nonparked_change(self) -> None:
        root = self.workspace()
        demo = root / "openspec" / "changes" / "demo"
        demo.joinpath("proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        source = root / "openspec" / "changes" / "source-change"
        source.mkdir()
        source.joinpath("proposal.md").write_text(
            "## Impact\n- Affected code:\n  - .cash.yaml\n", encoding="utf-8"
        )
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 0, (stdout, stderr))
        grader = next(item for item in json.loads(stdout)["checks"] if item["id"] == "grader_immutability")
        self.assertEqual(grader["status"], "pass")

    def test_hook_failure_stderr_contains_gate_detail_even_with_json(self) -> None:
        root = self.workspace()
        root.joinpath("openspec/changes/demo/proposal.md").write_text("", encoding="utf-8")
        self.write_round(root, "apply-r1.md", round_file(decision="next_round"))
        protected = root / "scripts" / "cash-skills" / "blocks"
        protected.mkdir(parents=True)
        (protected / "review-gate.md").write_text("changed\n", encoding="utf-8")
        code, stdout, stderr = self.invoke("lint-round", "--hook", "--json", stdin="{}")
        self.assertEqual(code, 2)
        self.assertFalse(json.loads(stdout)["ok"])
        self.assertIn("grader_immutability", stderr)
        self.assertIn("review-gate.md", stderr)

    def test_unreadable_round_file_is_a_gate_failure_not_an_exception(self) -> None:
        root = self.workspace()
        path = root / "openspec" / "changes" / "demo" / "reviews" / "apply-r1.md"
        path.write_bytes(b"\xff\xfe")
        code, stdout, stderr = self.invoke("lint-round", "demo", "--json")
        self.assertEqual(code, 2)
        self.assertEqual(stderr, "")
        payload = json.loads(stdout)
        self.assertFalse(payload["ok"])
        self.assertTrue(any(item["id"] == "round_type_position" and item["status"] == "fail" for item in payload["checks"]))

    def test_git_rename_record_keeps_both_paths(self) -> None:
        root = self.workspace()
        completed = subprocess.CompletedProcess(
            ["git"], 0, stdout=b"R  protected.md\0old.md\0", stderr=b""
        )
        with mock.patch("cash_cli.commands.lint_round.subprocess.run", return_value=completed):
            changed = _git_changed(type("Workspace", (), {"root": root})())
        self.assertEqual(changed, {"protected.md", "old.md"})


if __name__ == "__main__":
    unittest.main()
