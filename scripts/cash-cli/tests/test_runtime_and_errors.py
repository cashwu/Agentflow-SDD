import contextlib
import io
import json
import unittest

from cash_cli.errors import CashError
from cash_cli.main import dispatch, emit_json


class RuntimeAndErrorsTests(unittest.TestCase):
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
