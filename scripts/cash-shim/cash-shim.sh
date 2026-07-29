#!/bin/sh

fail() {
    printf 'cash-shim: %s\n' "$1" >&2
    exit 1
}

unset _cash_shim_install_mode
unset _cash_shim_dry_run
unset _cash_shim_force
unset _cash_shim_source_root
unset _cash_shim_installer
unset _cash_shim_version_file
unset _cash_shim_target
unset _cash_shim_inside_git_dir
unset _cash_shim_root
unset _cash_shim_launcher

if [ "${1-}" = "init" ]; then
    shift

    _cash_shim_install_mode="--vendor"
    _cash_shim_dry_run=false
    _cash_shim_force=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                _cash_shim_install_mode="--target"
                ;;
            --dry-run)
                _cash_shim_dry_run=true
                ;;
            --force)
                _cash_shim_force=true
                ;;
            *)
                fail "unsupported cash init argument: $1"
                ;;
        esac
        shift
    done

    _cash_shim_source_root=${CASH_SOURCE_ROOT:-"${HOME-}/Github/Agentflow-SDD"}
    _cash_shim_installer="$_cash_shim_source_root/install-cash-skills.fish"
    _cash_shim_version_file="$_cash_shim_source_root/cash-skills.version"

    if [ ! -x "$_cash_shim_installer" ] || [ ! -f "$_cash_shim_version_file" ]; then
        fail "invalid source layout at $_cash_shim_source_root; set CASH_SOURCE_ROOT to the Agentflow-SDD checkout"
    fi

    _cash_shim_target=$(git rev-parse --show-toplevel 2>/dev/null) || _cash_shim_target=
    if [ -z "$_cash_shim_target" ]; then
        _cash_shim_inside_git_dir=$(git rev-parse --is-inside-git-dir 2>/dev/null) || _cash_shim_inside_git_dir=false
        if [ "$_cash_shim_inside_git_dir" = "true" ]; then
            fail "cash init cannot run from inside a git directory or bare repository"
        fi
        if [ "$_cash_shim_dry_run" = "true" ]; then
            fail "cash init --dry-run requires an existing git worktree; run cash init without --dry-run"
        fi
        if ! git init; then
            fail "git init failed"
        fi
        _cash_shim_target=$(pwd -P) || fail "cannot resolve the target directory"
    fi

    printf 'cash-shim: target: %s\n' "$_cash_shim_target"

    set -- "$_cash_shim_install_mode" "$_cash_shim_target"
    if [ "$_cash_shim_dry_run" = "true" ]; then
        set -- "$@" "--dry-run"
    fi
    if [ "$_cash_shim_force" = "true" ]; then
        set -- "$@" "--force"
    fi
    exec "$_cash_shim_installer" "$@"
fi

_cash_shim_root=$(git rev-parse --show-toplevel 2>/dev/null) ||
    fail "current directory is not a git worktree; run cash init"
_cash_shim_launcher="$_cash_shim_root/.cash-skills/bin/cash"
if [ ! -x "$_cash_shim_launcher" ]; then
    fail "project launcher is missing or not executable; run cash init"
fi
exec "$_cash_shim_launcher" "$@"
