import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands.search import search_payload
from cash_cli.errors import CashError
from cash_cli.workspace import Workspace


ROOT = Path(__file__).resolve().parents[3]


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

    def test_walk_prunes_excluded_directory_before_reading_files(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        included = root / "openspec" / "included"
        excluded = root / "openspec" / "excluded"
        included.mkdir()
        excluded.mkdir()
        (included / "valid.md").write_text("valid\n", encoding="utf-8")
        (excluded / "invalid.md").write_bytes(b"\xff")

        documents = workspace.walk_text_files(
            "openspec",
            exclude_directory=lambda parts: parts == ("openspec", "excluded"),
        )

        self.assertEqual(dict(documents)["openspec/included/valid.md"], "valid\n")
        self.assertNotIn("openspec/excluded/invalid.md", dict(documents))


class LauncherLexicalSearchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (self.root / "openspec" / "changes" / "archive").mkdir()
        (self.root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        installed = subprocess.run(
            [
                "fish",
                "--no-config",
                str(ROOT / "install-cash-skills.fish"),
                "--target",
                str(self.root),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(installed.returncode, 0, installed.stderr)
        specs = self.root / "openspec" / "specs"
        specs.mkdir()
        (specs / "sample.md").write_text(
            "# Openspec\n\nA searchable document.\n",
            encoding="utf-8",
        )
        (specs / "dash.md").write_text(
            "# Dash\n\n-query\n",
            encoding="utf-8",
        )
        self.launcher = self.root / ".cash-skills" / "bin" / "cash"

    def cash(self, *arguments: str) -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(
            [str(self.launcher), *arguments],
            cwd=self.root,
            capture_output=True,
        )

    def test_flag_position_does_not_change_query(self) -> None:
        trailing = self.cash("search", "openspec", "--limit", "5", "--json")
        leading = self.cash("search", "--limit", "5", "openspec", "--json")

        self.assertEqual(trailing.returncode, 0, trailing.stderr)
        self.assertEqual(leading.returncode, 0, leading.stderr)
        self.assertEqual(leading.stdout, trailing.stdout)

    def test_invalid_positional_counts_and_unknown_long_option_fail(self) -> None:
        for arguments in (
            ("search", "--limit", "5", "--json"),
            ("search", "alpha", "beta", "--limit", "5", "--json"),
            ("search", "alpha", "--bogus", "--limit", "5", "--json"),
        ):
            with self.subTest(arguments=arguments):
                result = self.cash(*arguments)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(
                    json.loads(result.stdout)["error"]["code"],
                    "invalid_arguments",
                )

    def test_single_dash_query_is_positional(self) -> None:
        result = self.cash("search", "-query", "--limit", "5", "--json")

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_limit_defaults_and_invalid_values_are_distinct(self) -> None:
        defaulted = self.cash("search", "openspec", "--json")
        missing = self.cash("search", "openspec", "--limit", "--json")
        non_integer = self.cash("search", "openspec", "--limit", "abc", "--json")
        out_of_range = self.cash("search", "openspec", "--limit", "0", "--json")

        self.assertEqual(defaulted.returncode, 0, defaulted.stderr)
        self.assertLessEqual(len(json.loads(defaulted.stdout)["results"]), 10)
        for result in (missing, non_integer, out_of_range):
            self.assertEqual(result.returncode, 2)
            self.assertEqual(
                json.loads(result.stdout)["error"]["code"],
                "invalid_limit",
            )
        missing_message = json.loads(missing.stdout)["error"]["message"]
        non_integer_message = json.loads(non_integer.stdout)["error"]["message"]
        out_of_range_message = json.loads(out_of_range.stdout)["error"]["message"]
        self.assertNotEqual(missing_message, non_integer_message)
        self.assertNotEqual(missing_message, out_of_range_message)

    def test_scope_selects_exact_document_sets_and_prunes_archived_reviews(self) -> None:
        token = "scopetoken"
        master = self.root / "openspec" / "specs" / "scope.md"
        active = self.root / "openspec" / "changes" / "active" / "proposal.md"
        archived = (
            self.root
            / "openspec"
            / "changes"
            / "archive"
            / "2026-01-01-old"
        )
        archived_proposal = archived / "proposal.md"
        archived_review = archived / "reviews" / "apply-r1.md"
        code_review = archived / "code-reviews" / "notes.md"
        archive_sibling_review = (
            self.root
            / "openspec"
            / "changes"
            / "archive-copy"
            / "demo"
            / "reviews"
            / "notes.md"
        )
        for path in (
            master,
            active,
            archived_proposal,
            archived_review,
            code_review,
            archive_sibling_review,
        ):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f"# {token}\n", encoding="utf-8")

        specs = self.cash(
            "search", token, "--scope", "specs", "--limit", "100", "--json"
        )
        active_result = self.cash(
            "search", token, "--scope", "active", "--limit", "100", "--json"
        )
        default_result = self.cash("search", token, "--limit", "100", "--json")
        all_result = self.cash(
            "search", token, "--scope", "all", "--limit", "100", "--json"
        )

        for result in (specs, active_result, default_result, all_result):
            self.assertEqual(result.returncode, 0, result.stderr)
        specs_paths = {item["path"] for item in json.loads(specs.stdout)["results"]}
        active_paths = {
            item["path"] for item in json.loads(active_result.stdout)["results"]
        }
        default_paths = {
            item["path"] for item in json.loads(default_result.stdout)["results"]
        }
        all_paths = {item["path"] for item in json.loads(all_result.stdout)["results"]}
        self.assertEqual(specs_paths, {"openspec/specs/scope.md"})
        self.assertEqual(default_paths, active_paths)
        self.assertEqual(
            all_paths - active_paths,
            {
                "openspec/changes/archive/2026-01-01-old/reviews/apply-r1.md",
            },
        )
        self.assertIn(
            "openspec/changes/archive/2026-01-01-old/proposal.md",
            active_paths,
        )
        self.assertIn(
            "openspec/changes/archive/2026-01-01-old/code-reviews/notes.md",
            active_paths,
        )
        self.assertIn(
            "openspec/changes/archive-copy/demo/reviews/notes.md",
            active_paths,
        )
        (archived / "reviews" / "invalid.md").write_bytes(b"\xff")
        for scope in ("active", "specs"):
            result = self.cash(
                "search", token, "--scope", scope, "--limit", "100", "--json"
            )
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_invalid_scope_fails(self) -> None:
        result = self.cash("search", "openspec", "--scope", "bogus", "--json")

        self.assertEqual(result.returncode, 2)
        self.assertEqual(
            json.loads(result.stdout)["error"]["code"],
            "invalid_scope",
        )

    def test_missing_specs_directory_returns_empty_results(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / "openspec" / "changes" / ".parked").mkdir(parents=True)
        (root / "openspec" / "changes" / "archive").mkdir()
        (root / "openspec" / "config.yaml").write_text(
            "schema: spec-driven\n",
            encoding="utf-8",
        )
        installed = subprocess.run(
            [
                "fish",
                "--no-config",
                str(ROOT / "install-cash-skills.fish"),
                "--target",
                str(root),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(installed.returncode, 0, installed.stderr)
        specs = root / "openspec" / "specs"
        specs.mkdir()
        (specs / "fixture.md").write_text("fixture\n", encoding="utf-8")
        shutil.rmtree(specs)
        active = root / "openspec" / "changes" / "active"
        active.mkdir()
        (active / "proposal.md").write_text("missing\n", encoding="utf-8")

        result = subprocess.run(
            [
                str(root / ".cash-skills" / "bin" / "cash"),
                "search",
                "missing",
                "--scope",
                "specs",
                "--json",
            ],
            cwd=root,
            capture_output=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"results": []})


if __name__ == "__main__":
    unittest.main()
