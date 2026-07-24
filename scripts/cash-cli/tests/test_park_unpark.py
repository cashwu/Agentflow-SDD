import subprocess
import tempfile
import unittest
from pathlib import Path

from cash_cli.commands.lifecycle import park_change, unpark_change
from cash_cli.errors import CashError
from cash_cli.workspace import Workspace


class ParkUnparkTests(unittest.TestCase):
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
        change = root / "openspec" / "changes" / "demo"
        change.mkdir()
        (change / "proposal.md").write_text("## Summary\n\nDemo\n", encoding="utf-8")
        return temporary, root, Workspace.discover(root)

    def test_round_trip_preserves_change_bytes(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        before = (root / "openspec" / "changes" / "demo" / "proposal.md").read_bytes()

        park_change(workspace, "demo")
        unpark_change(workspace, "demo")

        active = root / "openspec" / "changes" / "demo"
        self.assertEqual((active / "proposal.md").read_bytes(), before)
        self.assertFalse((root / "openspec" / "changes" / ".parked" / "demo").exists())

    def test_park_creates_missing_parked_parent_directory(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        parked_root = root / "openspec" / "changes" / ".parked"
        parked_root.rmdir()
        self.assertFalse(parked_root.exists())

        park_change(workspace, "demo")

        self.assertTrue((parked_root / "demo").is_dir())
        self.assertFalse((root / "openspec" / "changes" / "demo").exists())

    def test_destination_collision_preserves_source(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        (root / "openspec" / "changes" / ".parked" / "demo").mkdir()

        with self.assertRaises(CashError) as raised:
            park_change(workspace, "demo")

        self.assertEqual(raised.exception.code, "change_identity_collision")
        self.assertTrue((root / "openspec" / "changes" / "demo").is_dir())

    def test_symlink_parked_parent_is_rejected(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        parked = root / "openspec" / "changes" / ".parked"
        parked.rmdir()
        outside = root / "outside"
        outside.mkdir()
        parked.symlink_to(outside, target_is_directory=True)

        with self.assertRaises(CashError):
            park_change(workspace, "demo")

        self.assertTrue((root / "openspec" / "changes" / "demo").is_dir())
        self.assertEqual(list(outside.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
