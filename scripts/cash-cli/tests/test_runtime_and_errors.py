import contextlib
import io
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.errors import CashError
from cash_cli.main import COMMANDS, dispatch, emit_json, main


class RuntimeAndErrorsTests(unittest.TestCase):
    def enter_workspace(self) -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / ".cash.yaml").write_text("locale: tw\n", encoding="utf-8")
        (root / "openspec").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        lock = root / ".cash-workspace.lock"
        lock.touch()
        os.chmod(lock, 0o644)
        previous = Path.cwd()
        os.chdir(root)
        self.addCleanup(os.chdir, previous)
        return root

    def test_unicode_json_is_stable_and_unescaped(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            emit_json({"message": "繁體中文", "ok": True})

        self.assertEqual(output.getvalue(), '{"message":"繁體中文","ok":true}\n')

    def test_unknown_command_is_domain_error(self) -> None:
        with self.assertRaises(CashError) as raised:
            dispatch(["update"])

        self.assertEqual(raised.exception.code, "unknown_command")
        self.assertEqual(raised.exception.exit_code, 2)
        self.assertIn("--help", raised.exception.message)
        for command in COMMANDS:
            self.assertNotIn(command, raised.exception.message)

    def test_help_flags_list_sorted_commands(self) -> None:
        expected = sorted(COMMANDS)
        for flag in ("--help", "-h"):
            with self.subTest(flag=flag):
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    exit_code = main([flag, "--json"])

                self.assertEqual(exit_code, 0)
                self.assertEqual(json.loads(output.getvalue()), {"commands": expected})

    def test_help_without_json_is_human_readable(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = main(["--help"])

        self.assertEqual(exit_code, 0)
        self.assertFalse(output.getvalue().lstrip().startswith("{"))
        for command in COMMANDS:
            self.assertIn(command, output.getvalue())

    def test_missing_command_points_to_help_without_listing_commands(self) -> None:
        error_output = io.StringIO()
        with contextlib.redirect_stderr(error_output):
            exit_code = main([])

        self.assertEqual(exit_code, 2)
        self.assertIn("error[missing_command]", error_output.getvalue())
        self.assertIn("--help", error_output.getvalue())
        for command in COMMANDS:
            self.assertNotIn(command, error_output.getvalue())

    def test_handler_unknown_commands_keep_existing_messages(self) -> None:
        self.enter_workspace()
        cases = (
            (["new", "bogus", "artifact-id"], "Unknown new mode: bogus"),
            (
                ["instructions", "--skill", "bogus"],
                "Unknown discipline: bogus",
            ),
        )
        for arguments, expected_message in cases:
            with self.subTest(arguments=arguments):
                error_output = io.StringIO()
                with contextlib.redirect_stderr(error_output):
                    exit_code = main(arguments)

                self.assertEqual(exit_code, 2)
                self.assertIn("error[unknown_command]", error_output.getvalue())
                self.assertIn(expected_message, error_output.getvalue())
                self.assertNotIn("--help", error_output.getvalue())
                self.assertFalse(
                    all(command in error_output.getvalue() for command in COMMANDS)
                )

    def test_nonleading_help_flag_is_dispatched_to_handler(self) -> None:
        self.enter_workspace()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = main(["list", "--help"])

        self.assertEqual(exit_code, 0)
        self.assertEqual(json.loads(output.getvalue()), {"changes": []})
        self.assertNotIn("Commands:", output.getvalue())

    def test_error_json_has_stable_shape(self) -> None:
        error = CashError("bad_input", "輸入錯誤", exit_code=2, path="demo")

        self.assertEqual(
            json.loads(error.as_json()),
            {
                "error": {
                    "code": "bad_input",
                    "message": "輸入錯誤",
                    "path": "demo",
                }
            },
        )

    def test_supported_command_families_are_dispatched_without_spectra(self) -> None:
        for command in (
            "list",
            "status",
            "instructions",
            "new",
            "task",
            "in-progress",
            "touched",
            "park",
            "unpark",
            "validate",
            "analyze",
            "drift",
            "archive",
            "sync",
            "search",
        ):
            with self.subTest(command=command):
                handler = dispatch([command], execute=False)
                self.assertTrue(callable(handler))
                self.assertNotIn("spectra", handler.__module__)


if __name__ == "__main__":
    unittest.main()
