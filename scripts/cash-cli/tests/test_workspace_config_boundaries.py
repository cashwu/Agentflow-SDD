import hashlib
import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.config import ConfigError, parse_cash_config, parse_openspec_config
from cash_cli.errors import CashError
from cash_cli.workspace import Workspace


class WorkspaceConfigBoundaryTests(unittest.TestCase):
    def make_workspace(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(
            ["git", "init", "-q", str(root)],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        (root / ".cash.yaml").write_text(
            "locale: tw\ntdd: true\naudit: false\nparallel_tasks: true\n",
            encoding="utf-8",
        )
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n"
            "context: |\n"
            "  Python project\n"
            "rules:\n"
            "  tasks:\n"
            "    - Keep tasks small\n",
            encoding="utf-8",
        )
        return temporary, root

    def test_nested_cwd_resolves_git_root(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        nested = root / "src" / "module"
        nested.mkdir(parents=True)

        workspace = Workspace.discover(nested)

        self.assertEqual(workspace.root, root.resolve())

    def test_cash_config_accepts_only_explicit_subset(self) -> None:
        self.assertEqual(
            parse_cash_config(
                "locale: tw\ntdd: true\naudit: false\nparallel_tasks: true\n",
                path=".cash.yaml",
            ),
            {
                "locale": "tw",
                "tdd": True,
                "audit": False,
                "parallel_tasks": True,
            },
        )
        rejected = (
            "tdd: True\n",
            "tdd: true # inline\n",
            "tdd: true\ntdd: false\n",
            "unknown: true\n",
            "locale: 'tw'\n",
            "rules:\n  nested: true\n",
            "tdd:\ttrue\n",
        )
        for content in rejected:
            with self.subTest(content=content):
                with self.assertRaises(ConfigError):
                    parse_cash_config(content, path=".cash.yaml")

    def test_openspec_config_preserves_context_and_rule_order(self) -> None:
        parsed = parse_openspec_config(
            "schema: spec-driven\n"
            "context: |\n"
            "  line one\n"
            "  line two\n"
            "rules:\n"
            "  proposal:\n"
            "    - First\n"
            "    - Second\n",
            path="openspec/config.yaml",
        )

        self.assertEqual(parsed["context"], "line one\nline two")
        self.assertEqual(parsed["rules"]["proposal"], ["First", "Second"])

    def test_rule_text_may_contain_yaml_indicator_characters(self) -> None:
        parsed = parse_openspec_config(
            "schema: spec-driven\n"
            "rules:\n"
            "  tasks:\n"
            "    - Mark independent tasks with [P] only when they are parallel.\n"
            '    - Do not rely on vague phrases such as "handle edge cases".\n'
            "    - Use {braces} and *stars* inside prose freely.\n",
            path="openspec/config.yaml",
        )

        self.assertEqual(
            parsed["rules"]["tasks"],
            [
                "Mark independent tasks with [P] only when they are parallel.",
                'Do not rely on vague phrases such as "handle edge cases".',
                "Use {braces} and *stars* inside prose freely.",
            ],
        )

    def test_leading_yaml_indicator_in_rule_text_is_rejected(self) -> None:
        leading = ("[flow, seq]", '"quoted"', "'quoted'", "&anchor x", "*alias", "!tag x", "{a: b}")
        for text in leading:
            with self.subTest(text=text):
                with self.assertRaises(ConfigError):
                    parse_openspec_config(
                        "schema: spec-driven\n"
                        "rules:\n"
                        "  tasks:\n"
                        f"    - {text}\n",
                        path="openspec/config.yaml",
                    )

    def test_trailing_comment_in_rule_text_is_rejected(self) -> None:
        with self.assertRaises(ConfigError):
            parse_openspec_config(
                "schema: spec-driven\n"
                "rules:\n"
                "  tasks:\n"
                "    - Keep tasks small # inline comment\n",
                path="openspec/config.yaml",
            )

    def test_read_rejects_symlink_component(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        outside = root.parent / f"{root.name}-sentinel"
        outside.write_text("secret", encoding="utf-8")
        self.addCleanup(outside.unlink)
        (root / "openspec" / "external.md").symlink_to(outside)
        workspace = Workspace.discover(root)

        with self.assertRaises(CashError) as raised:
            workspace.read_text("openspec/external.md")

        self.assertEqual(raised.exception.code, "unsafe_path")

    def test_unsafe_change_names_are_rejected(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        workspace = Workspace.discover(root)

        for name in ("../outside", "/absolute", "2026-07-23-demo"):
            with self.subTest(name=name):
                with self.assertRaises(CashError):
                    workspace.change_path(name)

    def test_reader_fails_closed_on_unfinished_journal(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        journal = (
            root
            / ".cash-skills"
            / "state"
            / "transactions"
            / "unfinished"
            / "journal.json"
        )
        journal.parent.mkdir(parents=True)
        journal.write_text('{"state":"prepared","operations":[]}\n', encoding="utf-8")
        workspace = Workspace.discover(root)

        with self.assertRaises(CashError) as raised:
            workspace.assert_readable()

        self.assertEqual(raised.exception.code, "recovery_required")

    def test_transaction_revalidates_and_atomically_publishes(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        target = root / "openspec" / "state.txt"
        target.write_text("before", encoding="utf-8")
        workspace = Workspace.discover(root)
        transaction = workspace.transaction()
        transaction.write("openspec/state.txt", b"after")

        transaction.commit()

        self.assertEqual(target.read_text(encoding="utf-8"), "after")
        self.assertFalse(workspace.transactions.exists())

    def test_mutation_rejects_hard_link_target(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        target = root / "openspec" / "state.txt"
        target.write_text("before", encoding="utf-8")
        os.link(target, root / "openspec" / "other.txt")
        workspace = Workspace.discover(root)
        transaction = workspace.transaction()

        with self.assertRaises(CashError) as raised:
            transaction.write("openspec/state.txt", b"after")

        self.assertEqual(raised.exception.code, "unsafe_path")

    def test_missing_lock_is_execution_error_and_does_not_repair(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        (root / ".cash-workspace.lock").unlink()

        with self.assertRaises(CashError) as raised:
            Workspace.discover(root)

        self.assertEqual(raised.exception.exit_code, 1)
        self.assertFalse((root / ".cash-workspace.lock").exists())

    def test_lock_baseline_is_empty_regular_0644_file(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        lock_path = root / ".cash-workspace.lock"
        mode = stat.S_IMODE(os.lstat(lock_path).st_mode)

        self.assertEqual(mode, 0o644)
        self.assertEqual(lock_path.read_bytes(), b"")

    def test_launcher_validates_stable_identity_and_runtime_generation(self) -> None:
        temporary, root = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        source_root = Path(__file__).resolve().parents[3]
        cash_root = root / ".cash-skills"
        (cash_root / "bin").mkdir(parents=True)
        shutil.copy2(source_root / ".cash-skills" / "bin" / "cash", cash_root / "bin" / "cash")
        shutil.copytree(
            source_root / ".cash-skills" / "lib",
            cash_root / "lib",
            ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
        )
        os.chmod(cash_root / "bin" / "cash", 0o755)
        runtime_records: list[tuple[str, str, str]] = []
        for path in sorted((cash_root / "lib").rglob("*.py")):
            relative = path.relative_to(root).as_posix()
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            runtime_records.append((relative, digest, "0644"))
        stream = "".join(
            f"{path}\t{digest}\t{mode}\n"
            for path, digest, mode in runtime_records
        ).encode()
        generation = hashlib.sha256(stream).hexdigest()
        launcher = cash_root / "bin" / "cash"
        lock = root / ".cash-workspace.lock"
        lines = [
            "version\t0.1.0",
            f"runtime_generation\t{generation}",
            (
                "stable\t.cash-skills/bin/cash\t"
                f"{hashlib.sha256(launcher.read_bytes()).hexdigest()}\t0755\t"
                f"{launcher.stat().st_dev}\t{launcher.stat().st_ino}"
            ),
            (
                "stable\t.cash-workspace.lock\t"
                f"{hashlib.sha256(lock.read_bytes()).hexdigest()}\t0644\t"
                f"{lock.stat().st_dev}\t{lock.stat().st_ino}"
            ),
        ]
        lines.extend(
            f"runtime\t{path}\t{digest}\t{mode}"
            for path, digest, mode in runtime_records
        )
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
                relative = f"{variant}/skills/cash-{skill}/SKILL.md"
                content = (source_root / relative).read_bytes()
                lines.append(
                    f"skill\t{relative}\t{hashlib.sha256(content).hexdigest()}\t0644"
                )
        (cash_root / "receipt.tsv").write_text("\n".join(lines) + "\n", encoding="utf-8")
        os.chmod(cash_root / "receipt.tsv", 0o644)

        result = subprocess.run(
            [str(launcher), "update", "--json"],
            cwd=root,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 2)
        self.assertIn('"code":"unknown_command"', result.stdout)

        (cash_root / "lib" / "cash_cli" / "errors.py").write_text(
            "# drift\n",
            encoding="utf-8",
        )
        drifted = subprocess.run(
            [str(launcher), "update", "--json"],
            cwd=root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(drifted.returncode, 1)
        payload = json.loads(drifted.stdout)
        self.assertEqual(payload["error"]["code"], "receipt_invalid")
        self.assertIn("runtime record drift", payload["error"]["message"])
        self.assertEqual(drifted.stderr, "")


if __name__ == "__main__":
    unittest.main()
