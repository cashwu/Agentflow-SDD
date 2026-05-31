#!/usr/bin/env fish

# Tests for: auto-restore stripped commit-guard source from git HEAD.
# Builds an isolated git repo that mirrors the installer machinery, strips the
# working-tree commit-guard source, keeps a valid guard at HEAD, and asserts the
# installer self-heals (or fails loudly when it must not restore).

set script_path (status --current-filename)
set test_dir (dirname "$script_path")
set root_dir (realpath "$test_dir/../../..")
set installer_rel install-spectra-plus.fish
set guard_marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function assert_contains
    rg -q --fixed-strings "$argv[2]" "$argv[1]"; or fail "$argv[1] missing $argv[2]"
end

function assert_not_contains
    if rg -q --fixed-strings "$argv[2]" "$argv[1]"
        fail "$argv[1] unexpectedly contains $argv[2]"
    end
end

function run_expect
    set expected $argv[1]
    set command $argv[2..-1]
    $command >/tmp/spectra-plus-autorestore.out 2>/tmp/spectra-plus-autorestore.err
    set actual $status
    test "$actual" -eq "$expected"; or begin
        cat /tmp/spectra-plus-autorestore.out
        cat /tmp/spectra-plus-autorestore.err >&2
        fail "expected exit $expected, got $actual: $command"
    end
end

function strip_guard --argument-names path
    set stripped (mktemp /tmp/spectra-plus-autorestore-strip.XXXXXX)
    awk '
        /<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist \+ plus deletion protection -->/ { skip = 1; next }
        /<!-- SPECTRA-COMMIT-GUARD:END -->/ { skip = 0; next }
        !skip { print }
    ' "$path" > "$stripped"
    command mv -f "$stripped" "$path"
end

# Copy enough installer machinery into a self-contained directory so that
# running <dir>/install-spectra-plus.fish resolves its source skills from <dir>.
function build_source_tree --argument-names src
    mkdir -p "$src/.claude/skills" "$src/.agents/skills"
    command cp "$root_dir/$installer_rel" "$src/"
    command cp -R "$root_dir/scripts" "$src/"
    for skill in spectra-propose spectra-apply spectra-commit
        command cp -R "$root_dir/.claude/skills/$skill" "$src/.claude/skills/"
        command cp -R "$root_dir/.agents/skills/$skill" "$src/.agents/skills/"
    end
end

function git_init_commit --argument-names src
    git -C "$src" init -q
    git -C "$src" add -A
    git -C "$src" -c user.email=t@example.com -c user.name=test commit -qm fixture
end

set claude_rel .claude/skills/spectra-commit/SKILL.md
set agents_rel .agents/skills/spectra-commit/SKILL.md

# ---------------------------------------------------------------------------
# Case A: self-heal — working-tree source stripped, HEAD valid.
# Uses target == src (the real self-referential reproduction).
# ---------------------------------------------------------------------------
set src_a (mktemp -d /tmp/spectra-plus-autorestore-a.XXXXXX)
build_source_tree "$src_a"
git_init_commit "$src_a"
# Unrelated tracked-but-dirty file must survive a single-file restore.
echo ORIG > "$src_a/unrelated.txt"
git -C "$src_a" add unrelated.txt
git -C "$src_a" -c user.email=t@example.com -c user.name=test commit -qm unrelated
echo DIRTY > "$src_a/unrelated.txt"
strip_guard "$src_a/$claude_rel"
strip_guard "$src_a/$agents_rel"
assert_not_contains "$src_a/$claude_rel" "$guard_marker"

# A1: dry-run reports the restore and mutates nothing.
command cp -f "$src_a/$claude_rel" /tmp/spectra-plus-autorestore-claude.before
run_expect 0 fish "$src_a/$installer_rel" --target "$src_a" --dry-run
assert_contains /tmp/spectra-plus-autorestore.out "+ would restore .claude/skills/spectra-commit/SKILL.md from HEAD"
diff -u /tmp/spectra-plus-autorestore-claude.before "$src_a/$claude_rel"; or fail "dry-run modified source"

# A2: real run self-heals from HEAD and succeeds.
run_expect 0 fish "$src_a/$installer_rel" --target "$src_a"
assert_contains /tmp/spectra-plus-autorestore.out "restored .claude/skills/spectra-commit/SKILL.md from HEAD"
assert_contains /tmp/spectra-plus-autorestore.out "restored .agents/skills/spectra-commit/SKILL.md from HEAD"
assert_contains "$src_a/$claude_rel" "$guard_marker"
assert_contains "$src_a/$agents_rel" "$guard_marker"
# A3: single-file restore left the unrelated dirty file untouched.
test (cat "$src_a/unrelated.txt") = DIRTY; or fail "unrelated dirty file was clobbered by restore"

# ---------------------------------------------------------------------------
# Case B: HEAD source is also invalid — must fail loudly, no restore.
# ---------------------------------------------------------------------------
set src_b (mktemp -d /tmp/spectra-plus-autorestore-b.XXXXXX)
build_source_tree "$src_b"
strip_guard "$src_b/$claude_rel"
strip_guard "$src_b/$agents_rel"
git_init_commit "$src_b"   # HEAD now also lacks the guard
run_expect 1 fish "$src_b/$installer_rel" --target "$src_b"
assert_contains /tmp/spectra-plus-autorestore.err "缺少必要內容"
assert_not_contains /tmp/spectra-plus-autorestore.out "restored .claude/skills/spectra-commit/SKILL.md from HEAD"

# ---------------------------------------------------------------------------
# Case C: source not in a git work tree — must fail loudly, no restore.
# ---------------------------------------------------------------------------
set src_c (mktemp -d /tmp/spectra-plus-autorestore-c.XXXXXX)
build_source_tree "$src_c"
strip_guard "$src_c/$claude_rel"
strip_guard "$src_c/$agents_rel"
# Intentionally NOT a git repo.
run_expect 1 fish "$src_c/$installer_rel" --target "$src_c"
assert_contains /tmp/spectra-plus-autorestore.err "缺少必要內容"
assert_not_contains /tmp/spectra-plus-autorestore.out "from HEAD"

echo "PASS: auto-restore commit guard source checks"
