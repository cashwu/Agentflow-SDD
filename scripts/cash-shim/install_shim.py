#!/usr/bin/env python3
"""Install the global Cash shim through verified directory file descriptors."""

from __future__ import annotations

import os
from pathlib import Path
import secrets
import shutil
import stat
import sys
from typing import Callable


DESTINATION_NAME = "cash"
TEMP_PREFIX = ".cash-shim."
DIRECTORY_FLAGS = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
FILE_READ_FLAGS = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC


class InstallError(Exception):
    """A fail-closed shim installation error."""


class HeldDirectory:
    def __init__(
        self,
        fd: int,
        identity: tuple[int, int],
        parent: "HeldDirectory | None",
        name: str | None,
    ) -> None:
        self.fd = fd
        self.identity = identity
        self.parent = parent
        self.name = name

    def close(self) -> None:
        os.close(self.fd)


def _identity(metadata: os.stat_result) -> tuple[int, int]:
    return metadata.st_dev, metadata.st_ino


def _open_home(home: Path) -> tuple[Path, HeldDirectory]:
    if not home.is_absolute():
        raise InstallError("HOME must be an absolute path")
    try:
        input_metadata = os.lstat(home)
    except OSError as exc:
        raise InstallError(f"cannot inspect HOME: {exc}") from exc
    if stat.S_ISLNK(input_metadata.st_mode):
        raise InstallError("HOME must not be a symlink")

    try:
        canonical_home = home.resolve(strict=True)
    except OSError as exc:
        raise InstallError(f"cannot resolve HOME: {exc}") from exc
    if canonical_home == Path("/"):
        raise InstallError("HOME must not be the filesystem root")

    try:
        fd = os.open(canonical_home, DIRECTORY_FLAGS)
    except OSError as exc:
        raise InstallError(f"cannot open HOME directory: {exc}") from exc
    metadata = os.fstat(fd)
    if not stat.S_ISDIR(metadata.st_mode):
        os.close(fd)
        raise InstallError("HOME is not a directory")
    if _identity(metadata) != _identity(input_metadata):
        os.close(fd)
        raise InstallError("HOME directory identity changed while opening")
    return canonical_home, HeldDirectory(fd, _identity(metadata), None, None)


def _revalidate(directory: HeldDirectory) -> None:
    if directory.parent is not None:
        assert directory.name is not None
        try:
            metadata = os.stat(
                directory.name,
                dir_fd=directory.parent.fd,
                follow_symlinks=False,
            )
        except OSError as exc:
            raise InstallError(
                f"directory identity mismatch for {directory.name}: {exc}"
            ) from exc
        if not stat.S_ISDIR(metadata.st_mode) or _identity(metadata) != directory.identity:
            raise InstallError(f"directory identity mismatch for {directory.name}")
        _revalidate(directory.parent)


def _open_child_directory(parent: HeldDirectory, name: str) -> HeldDirectory:
    _revalidate(parent)
    try:
        metadata = os.stat(name, dir_fd=parent.fd, follow_symlinks=False)
    except FileNotFoundError:
        _revalidate(parent)
        try:
            os.mkdir(name, mode=0o755, dir_fd=parent.fd)
        except OSError as exc:
            raise InstallError(f"cannot create directory {name}: {exc}") from exc
    except OSError as exc:
        raise InstallError(f"cannot inspect directory {name}: {exc}") from exc
    else:
        if not stat.S_ISDIR(metadata.st_mode):
            raise InstallError(f"install path is not a directory: {name}")

    try:
        fd = os.open(name, DIRECTORY_FLAGS, dir_fd=parent.fd)
    except OSError as exc:
        raise InstallError(f"cannot open directory {name}: {exc}") from exc
    metadata = os.fstat(fd)
    if not stat.S_ISDIR(metadata.st_mode):
        os.close(fd)
        raise InstallError(f"install path is not a directory: {name}")
    held = HeldDirectory(fd, _identity(metadata), parent, name)
    _revalidate(held)
    return held


def _read_regular_path(path: Path) -> bytes:
    try:
        metadata = os.lstat(path)
    except OSError as exc:
        raise InstallError(f"cannot inspect source shim: {exc}") from exc
    if not stat.S_ISREG(metadata.st_mode):
        raise InstallError(f"source shim is not a regular file: {path}")
    try:
        fd = os.open(path, FILE_READ_FLAGS)
    except OSError as exc:
        raise InstallError(f"cannot open source shim: {exc}") from exc
    try:
        opened = os.fstat(fd)
        if not stat.S_ISREG(opened.st_mode) or _identity(opened) != _identity(metadata):
            raise InstallError("source shim identity changed while opening")
        return _read_all(fd)
    finally:
        os.close(fd)


def _read_all(fd: int) -> bytes:
    chunks: list[bytes] = []
    while True:
        chunk = os.read(fd, 64 * 1024)
        if not chunk:
            return b"".join(chunks)
        chunks.append(chunk)


def _destination_state(bin_directory: HeldDirectory) -> tuple[bytes, int] | None:
    _revalidate(bin_directory)
    try:
        metadata = os.stat(
            DESTINATION_NAME,
            dir_fd=bin_directory.fd,
            follow_symlinks=False,
        )
    except FileNotFoundError:
        return None
    except OSError as exc:
        raise InstallError(f"cannot inspect destination: {exc}") from exc
    if not stat.S_ISREG(metadata.st_mode):
        raise InstallError("destination is not a regular file")

    try:
        fd = os.open(DESTINATION_NAME, FILE_READ_FLAGS, dir_fd=bin_directory.fd)
    except OSError as exc:
        raise InstallError(f"cannot open destination: {exc}") from exc
    try:
        opened = os.fstat(fd)
        if not stat.S_ISREG(opened.st_mode):
            raise InstallError("destination is not a regular file")
        if _identity(opened) != _identity(metadata):
            raise InstallError("destination identity changed while opening")
        return _read_all(fd), stat.S_IMODE(opened.st_mode)
    finally:
        os.close(fd)


def _write_all(fd: int, content: bytes) -> None:
    offset = 0
    while offset < len(content):
        written = os.write(fd, content[offset:])
        if written == 0:
            raise InstallError("cannot write temporary shim file")
        offset += written


def _owned_temp_name(bin_directory: HeldDirectory) -> tuple[str, int, tuple[int, int]]:
    for _ in range(32):
        name = f"{TEMP_PREFIX}{secrets.token_hex(8)}"
        _revalidate(bin_directory)
        try:
            fd = os.open(
                name,
                os.O_WRONLY
                | os.O_CREAT
                | os.O_EXCL
                | os.O_NOFOLLOW
                | os.O_CLOEXEC,
                0o600,
                dir_fd=bin_directory.fd,
            )
        except FileExistsError:
            continue
        except OSError as exc:
            raise InstallError(f"cannot create temporary shim file: {exc}") from exc
        return name, fd, _identity(os.fstat(fd))
    raise InstallError("cannot allocate an exclusive temporary shim file")


def _cleanup_owned_temp(
    bin_directory: HeldDirectory,
    name: str,
    identity: tuple[int, int],
) -> None:
    try:
        metadata = os.stat(name, dir_fd=bin_directory.fd, follow_symlinks=False)
    except FileNotFoundError:
        return
    except OSError:
        return
    if stat.S_ISREG(metadata.st_mode) and _identity(metadata) == identity:
        try:
            os.unlink(name, dir_fd=bin_directory.fd)
        except OSError:
            pass


def install(
    source_shim: Path,
    home: Path,
    *,
    before_publish: Callable[[], None] | None = None,
) -> str:
    """Install source_shim and return ``installed`` or ``current``."""

    source_content = _read_regular_path(source_shim)
    _, home_directory = _open_home(home)
    local_directory: HeldDirectory | None = None
    bin_directory: HeldDirectory | None = None
    try:
        local_directory = _open_child_directory(home_directory, ".local")
        bin_directory = _open_child_directory(local_directory, "bin")
        destination = _destination_state(bin_directory)
        if destination == (source_content, 0o755):
            return "current"

        temp_name, temp_fd, temp_identity = _owned_temp_name(bin_directory)
        try:
            try:
                _revalidate(bin_directory)
                _write_all(temp_fd, source_content)
                _revalidate(bin_directory)
                os.fchmod(temp_fd, 0o755)
            finally:
                os.close(temp_fd)
            if before_publish is not None:
                before_publish()
            _revalidate(bin_directory)
            _destination_state(bin_directory)
            _revalidate(bin_directory)
            os.replace(
                temp_name,
                DESTINATION_NAME,
                src_dir_fd=bin_directory.fd,
                dst_dir_fd=bin_directory.fd,
            )
        finally:
            _cleanup_owned_temp(bin_directory, temp_name, temp_identity)
        return "installed"
    finally:
        if bin_directory is not None:
            bin_directory.close()
        if local_directory is not None:
            local_directory.close()
        home_directory.close()


def _warn_if_not_selected(canonical_home: Path) -> None:
    install_dir = canonical_home / ".local" / "bin"
    destination = install_dir / DESTINATION_NAME
    path_entries = os.environ.get("PATH", "").split(os.pathsep)
    if str(install_dir) not in path_entries:
        print(f"Warning: {install_dir} is not in PATH.", file=sys.stderr)
    selected = shutil.which(DESTINATION_NAME)
    if selected is not None and Path(selected).resolve() != destination.resolve():
        print(
            f"Warning: cash resolves to {selected} instead of {destination}.",
            file=sys.stderr,
        )


def main() -> int:
    if sys.version_info < (3, 11):
        print("Error: Python 3.11+ is required.", file=sys.stderr)
        return 1
    if len(sys.argv) != 2:
        print("Error: expected source shim path.", file=sys.stderr)
        return 1
    home_value = os.environ.get("HOME")
    if not home_value:
        print("Error: HOME must identify an existing directory.", file=sys.stderr)
        return 1
    try:
        canonical_home = Path(home_value).resolve(strict=True)
        result = install(Path(sys.argv[1]), Path(home_value))
    except (InstallError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    print(f"Result: {result}")
    _warn_if_not_selected(canonical_home)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
