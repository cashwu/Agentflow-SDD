#!/usr/bin/env fish

set -g root_dir (path resolve (dirname (status filename))/../../..)
set -g shim "$root_dir/scripts/cash-shim/cash-shim.sh"
set -g shim_installer "$root_dir/install-cash-shim.fish"
set -g fish_bin (command -s fish)
set -g python_dir (command dirname (command -s python3))
set -g tool_path (string join : (command dirname "$fish_bin") "$python_dir" /usr/bin /bin)
set -g fixture_root (mktemp -d /tmp/cash-shim-checks.XXXXXX)

function cleanup --on-event fish_exit
    command rm -rf -- "$fixture_root"
end

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function assert_contains --argument-names path literal contract
    rg -Fq -- "$literal" "$path"; or fail "$contract: missing '$literal'"
end

function assert_empty_dir --argument-names path contract
    set -l entries (command find "$path" -mindepth 1 -maxdepth 1 -print)
    test (count $entries) -eq 0; or fail "$contract: directory was modified"
end

function make_repo --argument-names path
    command mkdir -p -- "$path"
    command git -C "$path" init -q; or fail "could not create git fixture at $path"
end

function make_stub_launcher --argument-names repo
    command mkdir -p -- "$repo/.cash-skills/bin"
    printf '%s\n' \
        '#!/bin/sh' \
        'printf "argc=%s\n" "$#" > "$STUB_LOG"' \
        'for arg do printf "arg=%s\n" "$arg" >> "$STUB_LOG"; done' \
        'printf "launcher-result\n"' \
        >"$repo/.cash-skills/bin/cash"
    command chmod 0755 "$repo/.cash-skills/bin/cash"
end

function make_stub_source --argument-names path
    command mkdir -p -- "$path"
    printf '%s\n' \
        '#!/bin/sh' \
        'printf "argc=%s\n" "$#" > "$STUB_LOG"' \
        'for arg do printf "arg=%s\n" "$arg" >> "$STUB_LOG"; done' \
        'printf "Result: update\n"' \
        >"$path/install-cash-skills.fish"
    printf '1\n' >"$path/cash-skills.version"
    command chmod 0755 "$path/install-cash-skills.fish"
end

function assert_real_home_unchanged --argument-names state fingerprint
    set -l real_cash "$HOME/.local/bin/cash"
    if test "$state" = absent
        not test -e "$real_cash"; and not test -L "$real_cash"; or fail "installer tests touched the real HOME cash path"
    else
        test -f "$real_cash"; or fail "installer tests changed the real HOME cash shape"
        set -l current (command stat -f '%i:%m:%Lp:%z' "$real_cash"):(command shasum -a 256 "$real_cash" | string split ' ' -f 1)
        test "$current" = "$fingerprint"; or fail "installer tests changed the real HOME cash file"
    end
end

test -x "$shim"; or fail "shim is not executable"
test -x "$shim_installer"; or fail "shim installer is not executable"
sh -n "$shim"; or fail "shim fails POSIX sh syntax validation"
fish -n "$shim_installer"; or fail "shim installer fails fish syntax validation"

set -l real_cash "$HOME/.local/bin/cash"
if test -e "$real_cash"; or test -L "$real_cash"
    test -f "$real_cash"; and not test -L "$real_cash"; or fail "real HOME cash path is not a regular file"
    set -g real_home_state present
    set -g real_home_fingerprint (command stat -f '%i:%m:%Lp:%z' "$real_cash"):(command shasum -a 256 "$real_cash" | string split ' ' -f 1)
else
    set -g real_home_state absent
    set -g real_home_fingerprint ""
end

# Dispatch preserves argument boundaries and supports zero arguments.
set -l dispatch_repo "$fixture_root/dispatch repo"
make_repo "$dispatch_repo"
make_stub_launcher "$dispatch_repo"
command mkdir -p -- "$dispatch_repo/nested"
set -l dispatch_log "$fixture_root/dispatch.log"
set -l dispatch_out "$fixture_root/dispatch.out"
pushd "$dispatch_repo/nested" >/dev/null
env STUB_LOG="$dispatch_log" "$shim" search "portable manifest" --limit 10 --json >"$dispatch_out"
set -l dispatch_status $status
popd >/dev/null
test $dispatch_status -eq 0; or fail "dispatch failed"
printf '%s\n' 'argc=5' 'arg=search' 'arg=portable manifest' 'arg=--limit' 'arg=10' 'arg=--json' >"$fixture_root/dispatch.expected"
command cmp -s "$dispatch_log" "$fixture_root/dispatch.expected"; or fail "dispatch changed argv"
assert_contains "$dispatch_out" "launcher-result" "dispatch output delegation"

set -l zero_log "$fixture_root/zero.log"
pushd "$dispatch_repo" >/dev/null
env STUB_LOG="$zero_log" "$shim" >"$fixture_root/zero.out"
set -l zero_status $status
popd >/dev/null
test $zero_status -eq 0; or fail "zero-argument dispatch failed"
test (string trim <"$zero_log") = "argc=0"; or fail "zero-argument dispatch added arguments"

# Hostile inherited variables do not leak shim internals or overwrite caller values.
set -l hostile_dispatch_repo "$fixture_root/hostile-dispatch"
make_repo "$hostile_dispatch_repo"
command mkdir -p -- "$hostile_dispatch_repo/.cash-skills/bin"
printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "root=$root" "target=$target" "launcher=$launcher" "install_mode=$install_mode" "dry_run=$dry_run" "force=$force" "source_root=$source_root" "installer=$installer" "version_file=$version_file" "inside_git_dir=$inside_git_dir" > "$STUB_LOG"' \
    'env | grep "^_cash_shim_" > "$STUB_ENV_LOG" || :' \
    >"$hostile_dispatch_repo/.cash-skills/bin/cash"
command chmod 0755 "$hostile_dispatch_repo/.cash-skills/bin/cash"
set -l hostile_dispatch_log "$fixture_root/hostile-dispatch.log"
set -l hostile_dispatch_env "$fixture_root/hostile-dispatch.env"
pushd "$hostile_dispatch_repo" >/dev/null
env \
    STUB_LOG="$hostile_dispatch_log" \
    STUB_ENV_LOG="$hostile_dispatch_env" \
    root=caller-root \
    target=caller-target \
    launcher=caller-launcher \
    install_mode=caller-install-mode \
    dry_run=caller-dry-run \
    force=caller-force \
    source_root=caller-source-root \
    installer=caller-installer \
    version_file=caller-version-file \
    inside_git_dir=caller-inside-git-dir \
    _cash_shim_install_mode=hostile-reserved-install-mode \
    _cash_shim_dry_run=hostile-reserved-dry-run \
    _cash_shim_force=hostile-reserved-force \
    _cash_shim_source_root=hostile-reserved-source-root \
    _cash_shim_installer=hostile-reserved-installer \
    _cash_shim_version_file=hostile-reserved-version-file \
    _cash_shim_target=hostile-reserved-target \
    _cash_shim_inside_git_dir=hostile-reserved-inside-git-dir \
    _cash_shim_root=hostile-reserved-root \
    _cash_shim_launcher=hostile-reserved-launcher \
    "$shim" status >"$fixture_root/hostile-dispatch.out"
set -l hostile_dispatch_status $status
popd >/dev/null
test $hostile_dispatch_status -eq 0; or fail "hostile dispatch failed"
not test -s "$hostile_dispatch_env"; or fail "hostile dispatch leaked reserved internal values"
printf '%s\n' \
    'root=caller-root' \
    'target=caller-target' \
    'launcher=caller-launcher' \
    'install_mode=caller-install-mode' \
    'dry_run=caller-dry-run' \
    'force=caller-force' \
    'source_root=caller-source-root' \
    'installer=caller-installer' \
    'version_file=caller-version-file' \
    'inside_git_dir=caller-inside-git-dir' \
    >"$fixture_root/hostile-dispatch.expected"
command cmp -s "$hostile_dispatch_log" "$fixture_root/hostile-dispatch.expected"; or fail "hostile dispatch changed caller generic variables"

# Dispatch failures are single-line, fail closed, and do not write in the target.
set -l nongit "$fixture_root/non-git"
command mkdir -p -- "$nongit"
pushd "$nongit" >/dev/null
"$shim" list >"$fixture_root/non-git.out" 2>"$fixture_root/non-git.err"
set -l nongit_status $status
popd >/dev/null
test $nongit_status -eq 1; or fail "non-git dispatch did not exit 1"
test (count (string split \n (string trim <"$fixture_root/non-git.err"))) -eq 1; or fail "non-git dispatch error is not one line"
assert_contains "$fixture_root/non-git.err" "cash-shim:" "non-git error prefix"
assert_contains "$fixture_root/non-git.err" "cash init" "non-git recovery hint"
assert_empty_dir "$nongit" "non-git dispatch"

set -l missing_launcher_repo "$fixture_root/missing-launcher"
make_repo "$missing_launcher_repo"
pushd "$missing_launcher_repo" >/dev/null
"$shim" status >"$fixture_root/missing-launcher.out" 2>"$fixture_root/missing-launcher.err"
set -l missing_launcher_status $status
popd >/dev/null
test $missing_launcher_status -eq 1; or fail "missing launcher dispatch did not exit 1"
assert_contains "$fixture_root/missing-launcher.err" "cash-shim:" "missing launcher error prefix"
assert_contains "$fixture_root/missing-launcher.err" "cash init" "missing launcher recovery hint"

# Init validates flags and source before any git initialization.
set -l stub_source "$fixture_root/source"
make_stub_source "$stub_source"
set -l unknown_target "$fixture_root/unknown-flag"
command mkdir -p -- "$unknown_target"
pushd "$unknown_target" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fixture_root/unknown.log" "$shim" init --register >"$fixture_root/unknown.out" 2>"$fixture_root/unknown.err"
set -l unknown_status $status
popd >/dev/null
test $unknown_status -eq 1; or fail "unknown init flag did not exit 1"
not test -e "$unknown_target/.git"; or fail "unknown init flag created a git repo"
not test -e "$fixture_root/unknown.log"; or fail "unknown init flag invoked installer"

set -l invalid_source "$fixture_root/invalid-source"
command mkdir -p -- "$invalid_source"
printf '%s\n' '#!/bin/sh' 'exit 0' >"$invalid_source/install-cash-skills.fish"
command chmod 0755 "$invalid_source/install-cash-skills.fish"
set -l invalid_target "$fixture_root/invalid-source-target"
command mkdir -p -- "$invalid_target"
pushd "$invalid_target" >/dev/null
env CASH_SOURCE_ROOT="$invalid_source" STUB_LOG="$fixture_root/invalid-source.log" "$shim" init >"$fixture_root/invalid-source.out" 2>"$fixture_root/invalid-source.err"
set -l invalid_source_status $status
popd >/dev/null
test $invalid_source_status -eq 1; or fail "invalid source layout did not exit 1"
assert_contains "$fixture_root/invalid-source.err" "CASH_SOURCE_ROOT" "invalid source guidance"
not test -e "$invalid_target/.git"; or fail "invalid source layout created a git repo"
not test -e "$fixture_root/invalid-source.log"; or fail "invalid source layout invoked installer"

# Fresh init creates one repository and maps flags to the stub installer.
set -l fresh_target "$fixture_root/fresh target"
command mkdir -p -- "$fresh_target"
set -l fresh_log "$fixture_root/fresh.log"
pushd "$fresh_target" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fresh_log" "$shim" init >"$fixture_root/fresh.out" 2>"$fixture_root/fresh.err"
set -l fresh_status $status
popd >/dev/null
test $fresh_status -eq 0; or fail "fresh init failed"
test -d "$fresh_target/.git"; or fail "fresh init did not create a git repo"
set -l fresh_absolute (path resolve "$fresh_target")
printf '%s\n' 'argc=2' 'arg=--vendor' "arg=$fresh_absolute" >"$fixture_root/fresh.expected"
command cmp -s "$fresh_log" "$fixture_root/fresh.expected"; or fail "fresh init mapped installer arguments incorrectly"
assert_contains "$fixture_root/fresh.out" "$fresh_absolute" "fresh init target output"

# Existing worktrees resolve to top-level and dry-run never initializes a repo.
set -l worktree_repo "$fixture_root/worktree"
make_repo "$worktree_repo"
command mkdir -p -- "$worktree_repo/a/b"
set -l worktree_log "$fixture_root/worktree.log"
pushd "$worktree_repo/a/b" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$worktree_log" "$shim" init --target >"$fixture_root/worktree.out" 2>"$fixture_root/worktree.err"
set -l worktree_status $status
popd >/dev/null
test $worktree_status -eq 0; or fail "worktree init failed"
set -l worktree_absolute (path resolve "$worktree_repo")
printf '%s\n' 'argc=2' 'arg=--target' "arg=$worktree_absolute" >"$fixture_root/worktree.expected"
command cmp -s "$worktree_log" "$fixture_root/worktree.expected"; or fail "worktree init mapped target incorrectly"
not test -e "$worktree_repo/a/b/.git"; or fail "worktree subdirectory was initialized"

pushd "$worktree_repo" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fixture_root/example-dry-run.log" "$shim" init --dry-run >"$fixture_root/example-dry-run.out"
set -l example_dry_run_status $status
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fixture_root/example-target-force.log" "$shim" init --target --force >"$fixture_root/example-target-force.out"
set -l example_target_force_status $status
popd >/dev/null
test $example_dry_run_status -eq 0; or fail "init --dry-run example failed"
test $example_target_force_status -eq 0; or fail "init --target --force example failed"
printf '%s\n' 'argc=3' 'arg=--vendor' "arg=$worktree_absolute" 'arg=--dry-run' >"$fixture_root/example-dry-run.expected"
printf '%s\n' 'argc=3' 'arg=--target' "arg=$worktree_absolute" 'arg=--force' >"$fixture_root/example-target-force.expected"
command cmp -s "$fixture_root/example-dry-run.log" "$fixture_root/example-dry-run.expected"; or fail "init --dry-run example mapped argv incorrectly"
command cmp -s "$fixture_root/example-target-force.log" "$fixture_root/example-target-force.expected"; or fail "init --target --force example mapped argv incorrectly"

# Init clears inherited reserved exports while preserving caller generic variables.
set -l hostile_init_source "$fixture_root/hostile-init-source"
command mkdir -p -- "$hostile_init_source"
printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "root=$root" "target=$target" "launcher=$launcher" "install_mode=$install_mode" "dry_run=$dry_run" "force=$force" "source_root=$source_root" "installer=$installer" "version_file=$version_file" "inside_git_dir=$inside_git_dir" > "$STUB_LOG"' \
    'env | grep "^_cash_shim_" > "$STUB_ENV_LOG" || :' \
    >"$hostile_init_source/install-cash-skills.fish"
printf '1\n' >"$hostile_init_source/cash-skills.version"
command chmod 0755 "$hostile_init_source/install-cash-skills.fish"
set -l hostile_init_repo "$fixture_root/hostile-init"
make_repo "$hostile_init_repo"
set -l hostile_init_log "$fixture_root/hostile-init.log"
set -l hostile_init_env "$fixture_root/hostile-init.env"
pushd "$hostile_init_repo" >/dev/null
env \
    CASH_SOURCE_ROOT="$hostile_init_source" \
    STUB_LOG="$hostile_init_log" \
    STUB_ENV_LOG="$hostile_init_env" \
    root=caller-root \
    target=caller-target \
    launcher=caller-launcher \
    install_mode=caller-install-mode \
    dry_run=caller-dry-run \
    force=caller-force \
    source_root=caller-source-root \
    installer=caller-installer \
    version_file=caller-version-file \
    inside_git_dir=caller-inside-git-dir \
    _cash_shim_install_mode=hostile-reserved-install-mode \
    _cash_shim_dry_run=hostile-reserved-dry-run \
    _cash_shim_force=hostile-reserved-force \
    _cash_shim_source_root=hostile-reserved-source-root \
    _cash_shim_installer=hostile-reserved-installer \
    _cash_shim_version_file=hostile-reserved-version-file \
    _cash_shim_target=hostile-reserved-target \
    _cash_shim_inside_git_dir=hostile-reserved-inside-git-dir \
    _cash_shim_root=hostile-reserved-root \
    _cash_shim_launcher=hostile-reserved-launcher \
    "$shim" init --target --dry-run --force >"$fixture_root/hostile-init.out"
set -l hostile_init_status $status
popd >/dev/null
test $hostile_init_status -eq 0; or fail "hostile init failed"
not test -s "$hostile_init_env"; or fail "hostile init leaked reserved internal values"
command cmp -s "$hostile_init_log" "$fixture_root/hostile-dispatch.expected"; or fail "hostile init changed caller generic variables"

set -l dry_target "$fixture_root/dry-run-non-worktree"
command mkdir -p -- "$dry_target"
pushd "$dry_target" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fixture_root/dry.log" "$shim" init --dry-run >"$fixture_root/dry.out" 2>"$fixture_root/dry.err"
set -l dry_status $status
popd >/dev/null
test $dry_status -eq 1; or fail "non-worktree dry-run did not exit 1"
assert_contains "$fixture_root/dry.err" "existing git worktree" "non-worktree dry-run guidance"
assert_empty_dir "$dry_target" "non-worktree dry-run"
not test -e "$fixture_root/dry.log"; or fail "non-worktree dry-run invoked installer"

# Git internals and bare repositories are never initialized or installed into.
set -l internal_repo "$fixture_root/internal-repo"
make_repo "$internal_repo"
pushd "$internal_repo/.git" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fixture_root/internal.log" "$shim" init >"$fixture_root/internal.out" 2>"$fixture_root/internal.err"
set -l internal_status $status
popd >/dev/null
test $internal_status -eq 1; or fail "git internal directory init did not exit 1"
assert_contains "$fixture_root/internal.err" "inside a git directory" "git internal directory guidance"
not test -e "$fixture_root/internal.log"; or fail "git internal directory invoked installer"

set -l bare_repo "$fixture_root/bare.git"
command git init --bare -q "$bare_repo"; or fail "could not create bare repo fixture"
pushd "$bare_repo" >/dev/null
env CASH_SOURCE_ROOT="$stub_source" STUB_LOG="$fixture_root/bare.log" "$shim" init >"$fixture_root/bare.out" 2>"$fixture_root/bare.err"
set -l bare_status $status
popd >/dev/null
test $bare_status -eq 1; or fail "bare repo init did not exit 1"
assert_contains "$fixture_root/bare.err" "inside a git directory" "bare repo guidance"
not test -e "$fixture_root/bare.log"; or fail "bare repo invoked installer"

# A fresh git repository satisfies the real installer prerequisite boundary.
set -l validator_repo "$fixture_root/validator"
make_repo "$validator_repo"
env PYTHONPATH="$root_dir/.cash-skills/lib" python3 -s -P -c \
    'import sys; from pathlib import Path; from cash_cli.installer import validate_target_prerequisites; validate_target_prerequisites(Path(sys.argv[1]).resolve(), allow_missing_config=True)' \
    "$validator_repo"; or fail "fresh git repo failed validate_target_prerequisites"

# Removing an installed shim in an isolated HOME has no effect on direct launcher behavior.
set -l deletion_repo "$fixture_root/deletion"
make_repo "$deletion_repo"
make_stub_launcher "$deletion_repo"
set -l deletion_home "$fixture_root/deletion-home"
command mkdir -p -- "$deletion_home"
env HOME="$deletion_home" PATH="$tool_path" "$shim_installer" >"$fixture_root/deletion-install.out" 2>"$fixture_root/deletion-install.err"
test $status -eq 0; or fail "could not install isolated deletion-test shim"
set -l deletion_outside_local (command find "$deletion_home" -mindepth 1 ! -path "$deletion_home/.local" ! -path "$deletion_home/.local/*" -print)
test (count $deletion_outside_local) -eq 0; or fail "deletion-test installer wrote outside isolated HOME/.local"
set -l deletion_shim "$deletion_home/.local/bin/cash"
command mv -- "$deletion_shim" "$deletion_shim.away"; or fail "could not move isolated deletion-test shim"
set -l deletion_log "$fixture_root/deletion.log"
env STUB_LOG="$deletion_log" "$deletion_repo/.cash-skills/bin/cash" list --json >"$fixture_root/deletion.out"
test $status -eq 0; or fail "direct launcher failed after shim deletion"
printf '%s\n' 'argc=2' 'arg=list' 'arg=--json' >"$fixture_root/deletion.expected"
command cmp -s "$deletion_log" "$fixture_root/deletion.expected"; or fail "direct launcher changed after shim deletion"
command mv -- "$deletion_shim.away" "$deletion_shim"; or fail "could not restore isolated deletion-test shim"
test -x "$deletion_shim"; or fail "isolated deletion-test shim was not restored"

# The installer is isolated by HOME and exposes installed/current/fail-closed states.
set -l fixture_home "$fixture_root/home"
command mkdir -p -- "$fixture_home"
env HOME="$fixture_home" PATH="$tool_path" "$shim_installer" >"$fixture_root/install-first.out" 2>"$fixture_root/install-first.err"
test $status -eq 0; or fail "first shim installation failed"
set -l install_outside_local (command find "$fixture_home" -mindepth 1 ! -path "$fixture_home/.local" ! -path "$fixture_home/.local/*" -print)
test (count $install_outside_local) -eq 0; or fail "shim installer wrote outside isolated HOME/.local"
set -l installed_cash "$fixture_home/.local/bin/cash"
assert_contains "$fixture_root/install-first.out" "Result: installed" "first shim installation result"
assert_contains "$fixture_root/install-first.err" "not in PATH" "PATH warning"
command cmp -s "$shim" "$installed_cash"; or fail "installed shim content differs from source"
test (command stat -f '%Lp' "$installed_cash") = 755; or fail "installed shim mode is not 0755"
set -l installed_identity (command stat -f '%i:%m' "$installed_cash")
sleep 1
env HOME="$fixture_home" PATH="$tool_path" "$shim_installer" >"$fixture_root/install-second.out" 2>"$fixture_root/install-second.err"
test $status -eq 0; or fail "current shim installation failed"
assert_contains "$fixture_root/install-second.out" "Result: current" "current shim installation result"
test (command stat -f '%i:%m' "$installed_cash") = "$installed_identity"; or fail "current shim installation rewrote destination"

set -l shadow_dir "$fixture_root/shadow"
command mkdir -p -- "$shadow_dir"
printf '%s\n' '#!/bin/sh' 'exit 0' >"$shadow_dir/cash"
command chmod 0755 "$shadow_dir/cash"
env HOME="$fixture_home" PATH="$shadow_dir:$tool_path" "$shim_installer" >"$fixture_root/install-shadow.out" 2>"$fixture_root/install-shadow.err"
test $status -eq 0; or fail "shadow warning changed installer exit code"
assert_contains "$fixture_root/install-shadow.err" "resolves to" "command shadow warning"

set -l outside_target "$fixture_root/outside-cash"
printf 'sentinel\n' >"$outside_target"
command rm -- "$installed_cash"
command ln -s -- "$outside_target" "$installed_cash"
env HOME="$fixture_home" PATH="$tool_path" "$shim_installer" >"$fixture_root/install-fail.out" 2>"$fixture_root/install-fail.err"
test $status -ne 0; or fail "symlink destination did not fail closed"
test (string trim <"$outside_target") = sentinel; or fail "symlink destination target was modified"
test (count (command find "$fixture_home/.local/bin" -name '.cash-shim.*' -print)) -eq 0; or fail "installer left a temporary file"

command rm -- "$installed_cash"
command mkfifo "$installed_cash"
env HOME="$fixture_home" PATH="$tool_path" "$shim_installer" >"$fixture_root/install-fifo.out" 2>"$fixture_root/install-fifo.err"
test $status -ne 0; or fail "FIFO destination did not fail closed before open"
test -p "$installed_cash"; or fail "FIFO destination was modified"
test (count (command find "$fixture_home/.local/bin" -name '.cash-shim.*' -print)) -eq 0; or fail "FIFO failure left a temporary file"

# A parent swap after owned temp creation cannot redirect publication or cleanup.
set -l swap_home "$fixture_root/swap-home"
set -l swap_outside "$fixture_root/swap-outside"
command mkdir -p -- "$swap_home" "$swap_outside"
printf 'sentinel\n' >"$swap_outside/sentinel"
printf '%s\n' \
    'import importlib.util' \
    'import os' \
    'from pathlib import Path' \
    'import sys' \
    '' \
    'root = Path(sys.argv[1])' \
    'source = Path(sys.argv[2])' \
    'home = Path(sys.argv[3])' \
    'outside = Path(sys.argv[4])' \
    'module_path = root / "scripts/cash-shim/install_shim.py"' \
    'spec = importlib.util.spec_from_file_location("install_shim", module_path)' \
    'module = importlib.util.module_from_spec(spec)' \
    'spec.loader.exec_module(module)' \
    '' \
    'def swap_parent():' \
    '    local = home / ".local"' \
    '    os.rename(local / "bin", local / "bin-held")' \
    '    os.symlink(outside, local / "bin")' \
    '' \
    'try:' \
    '    module.install(source, home, before_publish=swap_parent)' \
    'except module.InstallError as exc:' \
    '    if "identity" not in str(exc):' \
    '        raise AssertionError(f"unexpected parent-swap error: {exc}") from exc' \
    'else:' \
    '    raise AssertionError("parent swap did not fail closed")' \
    | env PYTHONDONTWRITEBYTECODE=1 python3 -s -P - "$root_dir" "$shim" "$swap_home" "$swap_outside"
test $status -eq 0; or fail "parent-swap fixture did not fail closed on identity mismatch"
test (string trim <"$swap_outside/sentinel") = sentinel; or fail "parent swap modified the outside sentinel"
not test -e "$swap_outside/cash"; and not test -L "$swap_outside/cash"; or fail "parent swap published outside verified directory"
test (count (command find "$swap_home/.local/bin-held" -name '.cash-shim.*' -print)) -eq 0; or fail "parent swap left an owned temporary file"
not test -e "$swap_home/.local/bin-held/cash"; and not test -L "$swap_home/.local/bin-held/cash"; or fail "parent swap published into the detached held directory"

# A HOME leaf swap between initial inspection and held-FD open must fail closed.
set -l root_swap_parent "$fixture_root/root-swap-parent"
set -l root_swap_home "$root_swap_parent/home"
set -l root_swap_outside "$fixture_root/root-swap-outside"
command mkdir -p -- "$root_swap_home" "$root_swap_outside"
printf 'sentinel\n' >"$root_swap_outside/sentinel"
printf '%s\n' \
    'import importlib.util' \
    'import os' \
    'from pathlib import Path' \
    'import sys' \
    '' \
    'root = Path(sys.argv[1])' \
    'source = Path(sys.argv[2])' \
    'home = Path(sys.argv[3])' \
    'outside = Path(sys.argv[4])' \
    'module_path = root / "scripts/cash-shim/install_shim.py"' \
    'spec = importlib.util.spec_from_file_location("install_shim", module_path)' \
    'module = importlib.util.module_from_spec(spec)' \
    'spec.loader.exec_module(module)' \
    'original_lstat = module.os.lstat' \
    'swapped = False' \
    '' \
    'def swap_after_home_lstat(path, *args, **kwargs):' \
    '    global swapped' \
    '    metadata = original_lstat(path, *args, **kwargs)' \
    '    if not swapped and Path(path) == home:' \
    '        swapped = True' \
    '        os.rename(home, home.with_name("home-held"))' \
    '        os.symlink(outside, home)' \
    '    return metadata' \
    '' \
    'module.os.lstat = swap_after_home_lstat' \
    'try:' \
    '    module.install(source, home)' \
    'except module.InstallError as exc:' \
    '    if "identity" not in str(exc):' \
    '        raise AssertionError(f"unexpected HOME-swap error: {exc}") from exc' \
    'else:' \
    '    raise AssertionError("HOME leaf swap did not fail closed")' \
    | env PYTHONDONTWRITEBYTECODE=1 python3 -s -P - "$root_dir" "$shim" "$root_swap_home" "$root_swap_outside"
test $status -eq 0; or fail "HOME leaf-swap fixture did not fail closed on identity mismatch"
test (string trim <"$root_swap_outside/sentinel") = sentinel; or fail "HOME leaf swap modified the outside sentinel"
not test -e "$root_swap_outside/.local/bin/cash"; and not test -L "$root_swap_outside/.local/bin/cash"; or fail "HOME leaf swap published outside supplied HOME identity"
not test -e "$root_swap_parent/home-held/.local"; and not test -L "$root_swap_parent/home-held/.local"; or fail "HOME leaf swap modified the detached supplied HOME"

assert_real_home_unchanged "$real_home_state" "$real_home_fingerprint"
echo "PASS: cash shim contract checks"
