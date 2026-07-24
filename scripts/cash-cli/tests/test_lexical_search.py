import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands.search import search_payload
from cash_cli.errors import CashError
from cash_cli.workspace import Workspace


class LexicalSearchTests(unittest.TestCase):
    def make_workspace(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Workspace]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / ".cash.yaml").write_text("locale: tw\n", encoding="utf-8")
        (root / ".cash-workspace.lock").touch(mode=0o644)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        return temporary, root, Workspace.discover(root)

    def test_heading_body_and_path_weighting_is_deterministic(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        docs = root / "openspec" / "specs"
        (docs / "archive-safety").mkdir(parents=True)
        (docs / "heading").mkdir()
        (docs / "body").mkdir()
        (docs / "archive-safety" / "spec.md").write_text(
            "# Other\n\nNo body match.\n",
            encoding="utf-8",
        )
        (docs / "heading" / "spec.md").write_text(
            "# Archive safety\n\nOther text.\n",
            encoding="utf-8",
        )
        (docs / "body" / "spec.md").write_text(
            "# Other\n\nArchive safety is required.\n",
            encoding="utf-8",
        )

        results = search_payload(workspace, "archive safety", limit=3)["results"]

        self.assertEqual(
            [item["path"] for item in results],
            [
                "openspec/specs/archive-safety/spec.md",
                "openspec/specs/heading/spec.md",
                "openspec/specs/body/spec.md",
            ],
        )
        self.assertTrue(all(len(item["excerpt"]) <= 240 for item in results))

    def test_unicode_query_limit_and_zero_result(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        docs = root / "openspec" / "specs"
        for name in ("alpha", "beta"):
            (docs / name).mkdir(parents=True)
            (docs / name / "spec.md").write_text(
                f"# {name}\n\n繁體中文 搜尋內容。\n",
                encoding="utf-8",
            )

        one = search_payload(workspace, "繁體中文", limit=1)
        none = search_payload(workspace, "完全不存在", limit=10)

        self.assertEqual(len(one["results"]), 1)
        self.assertEqual(none, {"results": []})

    def test_equal_scores_use_path_byte_order(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        docs = root / "openspec" / "specs"
        for name in ("zeta", "alpha"):
            (docs / name).mkdir(parents=True)
            (docs / name / "spec.md").write_text(
                "# Same\n\nshared token\n",
                encoding="utf-8",
            )

        results = search_payload(workspace, "shared", limit=10)["results"]

        self.assertEqual(
            [item["path"] for item in results],
            [
                "openspec/specs/alpha/spec.md",
                "openspec/specs/zeta/spec.md",
            ],
        )

    def test_symlink_file_and_directory_are_rejected_before_sentinel_read(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        outside = root.parent / f"{root.name}-sentinel"
        outside.mkdir()
        self.addCleanup(lambda: outside.rmdir())
        sentinel = outside / "secret.md"
        sentinel.write_text("# Secret\n\nroot-outside-secret\n", encoding="utf-8")
        self.addCleanup(sentinel.unlink)
        specs = root / "openspec" / "specs"
        specs.mkdir()
        (specs / "external.md").symlink_to(sentinel)

        with self.assertRaises(CashError) as file_error:
            search_payload(workspace, "root-outside-secret", limit=10)
        self.assertEqual(file_error.exception.code, "unsafe_path")

        (specs / "external.md").unlink()
        (specs / "external").symlink_to(outside, target_is_directory=True)
        with self.assertRaises(CashError) as directory_error:
            search_payload(workspace, "root-outside-secret", limit=10)
        self.assertEqual(directory_error.exception.code, "unsafe_path")

    def test_invalid_query_and_limit_are_domain_errors(self) -> None:
        temporary, _, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        for query, limit in (("", 10), ("valid", 0), ("valid", 101)):
            with self.subTest(query=query, limit=limit):
                with self.assertRaises(CashError):
                    search_payload(workspace, query, limit=limit)


if __name__ == "__main__":
    unittest.main()
