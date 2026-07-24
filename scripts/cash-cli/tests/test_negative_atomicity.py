from __future__ import annotations

import fcntl
import json
import os
import stat
import subprocess
import sys
import tempfile
import time
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from cash_cli.errors import CashError
from cash_cli import workspace as workspace_module
from cash_cli.workspace import Workspace


ROOT = Path(__file__).resolve().parents[3]
FIXTURES = ROOT / "scripts" / "cash-cli" / "fixtures" / "negative-atomicity"


class NegativeAtomicityTests(unittest.TestCase):
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

    def test_post_preflight_content_edit_is_rejected(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        target = root / "openspec" / "state.txt"
        target.write_text("before", encoding="utf-8")
        transaction = workspace.transaction()
        transaction.write("openspec/state.txt", b"after")
        target.write_text("intruder", encoding="utf-8")

        with self.assertRaises(CashError) as raised:
            transaction.commit()

        self.assertEqual(raised.exception.code, "snapshot_drift")
        self.assertEqual(target.read_text(encoding="utf-8"), "intruder")
        self.assertFalse(workspace.transactions.exists())

    def test_parent_swap_is_rejected_without_touching_outside_sentinel(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        managed = root / "openspec" / "managed"
        managed.mkdir()
        target = managed / "state.txt"
        target.write_text("before", encoding="utf-8")
        transaction = workspace.transaction()
        transaction.write("openspec/managed/state.txt", b"after")
        original = root / "openspec" / "managed-original"
        managed.rename(original)
        managed.mkdir()
        sentinel = managed / "state.txt"
        sentinel.write_text("outside", encoding="utf-8")

        with self.assertRaises(CashError) as raised:
            transaction.commit()

        self.assertEqual(raised.exception.code, "snapshot_drift")
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "outside")
        self.assertEqual((original / "state.txt").read_text(encoding="utf-8"), "before")

    def test_destination_parent_swap_blocks_move_and_preserves_source(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        source = root / "openspec" / "changes" / "demo"
        source.mkdir()
        transaction = workspace.transaction()
        transaction.move(
            "openspec/changes/demo",
            "openspec/changes/.parked/demo",
        )
        parked = root / "openspec" / "changes" / ".parked"
        parked.rename(root / "openspec" / "changes" / ".parked-original")
        parked.mkdir()

        with self.assertRaises(CashError) as raised:
            transaction.commit()

        self.assertEqual(raised.exception.code, "snapshot_drift")
        self.assertTrue(source.is_dir())
        self.assertFalse((parked / "demo").exists())

    def test_second_replace_failure_rolls_back_and_removes_temporary_files(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        first = root / "openspec" / "first.txt"
        second = root / "openspec" / "second.txt"
        first.write_text("first-before", encoding="utf-8")
        second.write_text("second-before", encoding="utf-8")
        transaction = workspace.transaction()
        transaction.write("openspec/first.txt", b"first-after")
        transaction.write("openspec/second.txt", b"second-after")
        real_replace = os.replace
        publishes = 0

        def fail_second_publish(
            source: os.PathLike[str],
            destination: os.PathLike[str],
            **kwargs,
        ) -> None:
            nonlocal publishes
            if Path(source).name.startswith(".cash-tmp-"):
                publishes += 1
                if publishes == 2:
                    raise OSError("injected second replace failure")
            real_replace(source, destination, **kwargs)

        with mock.patch("cash_cli.workspace.os.replace", side_effect=fail_second_publish):
            with self.assertRaises(OSError):
                transaction.commit()

        self.assertEqual(first.read_text(encoding="utf-8"), "first-before")
        self.assertEqual(second.read_text(encoding="utf-8"), "second-before")
        self.assertEqual(list((root / "openspec").glob(".cash-*")), [])
        self.assertFalse(workspace.transactions.exists())

    def test_rollback_failure_preserves_recovery_journal(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        first = root / "openspec" / "first.txt"
        second = root / "openspec" / "second.txt"
        first.write_text("first-before", encoding="utf-8")
        second.write_text("second-before", encoding="utf-8")
        transaction = workspace.transaction()
        transaction.write("openspec/first.txt", b"first-after")
        transaction.write("openspec/second.txt", b"second-after")
        real_replace = os.replace
        publishes = 0

        def fail_publish_and_rollback(
            source: os.PathLike[str],
            destination: os.PathLike[str],
            **kwargs,
        ) -> None:
            nonlocal publishes
            source_name = Path(source).name
            if source_name.startswith(".cash-tmp-"):
                publishes += 1
                if publishes == 2:
                    raise OSError("injected publish failure")
            if source_name.startswith(".cash-rollback-"):
                raise OSError("injected rollback failure")
            real_replace(source, destination, **kwargs)

        with (
            mock.patch(
                "cash_cli.workspace.os.replace",
                side_effect=fail_publish_and_rollback,
            ),
            mock.patch(
                "cash_cli.workspace._restore_at",
                side_effect=OSError("injected rollback failure"),
            ),
        ):
            with self.assertRaises(CashError) as raised:
                transaction.commit()

        self.assertEqual(raised.exception.code, "rollback_failed")
        journals = list(workspace.transactions.glob("*/journal.json"))
        self.assertEqual(len(journals), 1)
        document = json.loads(journals[0].read_text(encoding="utf-8"))
        self.assertEqual(document["published"], 2)

    def test_published_file_has_requested_mode_owner_and_no_temp_residue(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        transaction = workspace.transaction()
        transaction.write("openspec/owned.txt", b"owned\n", mode=0o640)

        transaction.commit()

        target = root / "openspec" / "owned.txt"
        metadata = os.lstat(target)
        self.assertEqual(stat.S_IMODE(metadata.st_mode), 0o640)
        self.assertEqual((metadata.st_uid, metadata.st_gid), (os.getuid(), os.getgid()))
        self.assertEqual(list((root / "openspec").glob(".cash-*")), [])

    def test_crash_after_publication_is_recovered_from_write_ahead_ledger(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        target = root / "openspec" / "crash.txt"
        target.write_text("before\n", encoding="utf-8")
        library = Path(__file__).resolve().parents[3] / ".cash-skills" / "lib"
        script = (
            "from cash_cli.workspace import Workspace\n"
            "import sys\n"
            "workspace = Workspace.discover(sys.argv[1])\n"
            "transaction = workspace.transaction()\n"
            "transaction.write('openspec/crash.txt', b'after\\n')\n"
            "transaction.commit()\n"
        )
        environment = dict(os.environ)
        environment["PYTHONPATH"] = str(library)
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        environment["CASH_WORKSPACE_CRASH_AFTER_PUBLISH"] = "1"

        crashed = subprocess.run(
            [sys.executable, "-c", script, str(root)],
            env=environment,
            capture_output=True,
            text=True,
        )

        self.assertEqual(crashed.returncode, 97)
        self.assertEqual(target.read_text(encoding="utf-8"), "after\n")
        workspace.recover()
        self.assertEqual(target.read_text(encoding="utf-8"), "before\n")
        self.assertFalse(workspace.transactions.exists())

    def test_recovery_rejects_same_bytes_on_replaced_published_inode(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        target = root / "openspec" / "crash.txt"
        target.write_text("before\n", encoding="utf-8")
        library = ROOT / ".cash-skills" / "lib"
        script = (
            "from cash_cli.workspace import Workspace\n"
            "import sys\n"
            "workspace = Workspace.discover(sys.argv[1])\n"
            "transaction = workspace.transaction()\n"
            "transaction.write('openspec/crash.txt', b'after\\n')\n"
            "transaction.commit()\n"
        )
        environment = dict(os.environ)
        environment.update(
            {
                "PYTHONPATH": str(library),
                "PYTHONDONTWRITEBYTECODE": "1",
                "CASH_WORKSPACE_CRASH_AFTER_PUBLISH": "1",
            }
        )
        crashed = subprocess.run(
            [sys.executable, "-c", script, str(root)],
            env=environment,
            capture_output=True,
            text=True,
        )
        self.assertEqual(crashed.returncode, 97)
        published_inode = target.stat().st_ino
        replacement = target.with_name("replacement.txt")
        replacement.write_text("after\n", encoding="utf-8")
        os.replace(replacement, target)
        self.assertNotEqual(target.stat().st_ino, published_inode)

        with self.assertRaises(CashError) as raised:
            workspace.recover()

        self.assertEqual(raised.exception.code, "recovery_failed")
        self.assertEqual(target.read_text(encoding="utf-8"), "after\n")
        self.assertTrue(workspace.transactions.exists())

    def test_rollback_holds_verified_parent_through_restore(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        managed = root / "openspec" / "managed"
        managed.mkdir()
        target = managed / "state.txt"
        target.write_text("before\n", encoding="utf-8")
        transaction = workspace.transaction()
        transaction.write("openspec/managed/state.txt", b"after\n")
        transaction.commit()
        original_snapshot = workspace_module._snapshot_at
        swapped = False

        def swap_after_snapshot(parent: int, name: str, relative: str):
            nonlocal swapped
            snapshot = original_snapshot(parent, name, relative)
            if not swapped:
                swapped = True
                original = managed.with_name("managed-original")
                managed.rename(original)
                managed.mkdir()
                (managed / "state.txt").write_text("sentinel\n", encoding="utf-8")
            return snapshot

        with mock.patch(
            "cash_cli.workspace._snapshot_at",
            side_effect=swap_after_snapshot,
        ):
            workspace_module._rollback(workspace, transaction.operations)

        self.assertEqual(
            (root / "openspec" / "managed-original" / "state.txt").read_text(
                encoding="utf-8"
            ),
            "before\n",
        )
        self.assertEqual(target.read_text(encoding="utf-8"), "sentinel\n")

    def test_temporary_cleanup_holds_verified_parent_through_unlink(self) -> None:
        temporary, root, workspace = self.make_workspace()
        self.addCleanup(temporary.cleanup)
        managed = root / "openspec" / "managed"
        managed.mkdir()
        transaction = workspace.transaction()
        transaction.write("openspec/managed/state.txt", b"after\n")
        operation = transaction.operations[0]
        operation["published_identity"] = workspace_module._stage_write(
            workspace,
            operation,
        )
        original_open_parent = Workspace._open_parent
        swapped = False

        @contextmanager
        def swap_after_open(instance: Workspace, relative: str):
            nonlocal swapped
            with original_open_parent(instance, relative) as opened:
                if not swapped:
                    swapped = True
                    original = managed.with_name("managed-original")
                    managed.rename(original)
                    managed.mkdir()
                    (managed / "sentinel.txt").write_text(
                        "sentinel\n",
                        encoding="utf-8",
                    )
                yield opened

        with mock.patch.object(Workspace, "_open_parent", swap_after_open):
            workspace_module._cleanup_temporaries(
                workspace,
                transaction.operations,
            )

        original = root / "openspec" / "managed-original"
        self.assertEqual(list(original.glob(".cash-tmp-*")), [])
        self.assertEqual(
            (managed / "sentinel.txt").read_text(encoding="utf-8"),
            "sentinel\n",
        )


class LauncherLockTests(unittest.TestCase):
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
        result = subprocess.run(
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
        self.assertEqual(result.returncode, 0, result.stderr)
        self.launcher = self.root / ".cash-skills" / "bin" / "cash"
        self.lock = self.root / ".cash-workspace.lock"

    def lock_holder(self, delay: float, *, crash: bool = False) -> subprocess.Popen[str]:
        code = (
            "import fcntl,os,sys,time;"
            "fd=os.open(sys.argv[1],os.O_RDONLY);"
            "fcntl.flock(fd,fcntl.LOCK_EX);"
            "print('ready',flush=True);"
            + ("os._exit(23)" if crash else f"time.sleep({delay})")
        )
        process = subprocess.Popen(
            ["python3", "-c", code, str(self.lock)],
            stdout=subprocess.PIPE,
            text=True,
        )
        self.assertEqual(process.stdout.readline(), "ready\n")
        process.stdout.close()
        return process

    def test_reader_waits_for_exclusive_publication_lock(self) -> None:
        holder = self.lock_holder(0.35)
        started = time.monotonic()

        result = subprocess.run(
            [str(self.launcher), "list", "--json"],
            cwd=self.root,
            capture_output=True,
            text=True,
        )

        elapsed = time.monotonic() - started
        self.assertEqual(holder.wait(), 0)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertGreaterEqual(elapsed, 0.25)

    def test_process_crash_releases_workspace_lock(self) -> None:
        holder = self.lock_holder(0, crash=True)
        self.assertEqual(holder.wait(), 23)

        result = subprocess.run(
            [str(self.launcher), "list", "--json"],
            cwd=self.root,
            capture_output=True,
            text=True,
            timeout=2,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '{"changes":[]}\n')

    def test_error_fixture_documents_stable_exit_classes(self) -> None:
        contracts = json.loads(
            (FIXTURES / "error-contracts.json").read_text(encoding="utf-8")
        )
        unknown = subprocess.run(
            [str(self.launcher), "nope", "--json"],
            cwd=self.root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(unknown.returncode, 2)
        self.assertEqual(json.loads(unknown.stdout), contracts["unknown_command"])


if __name__ == "__main__":
    unittest.main()
