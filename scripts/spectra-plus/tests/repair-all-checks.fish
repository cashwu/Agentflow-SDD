#!/usr/bin/env fish

set script_path (status --current-filename)
set test_dir (dirname "$script_path")
set original_root_dir (realpath "$test_dir/../../..")
set root_dir "$original_root_dir"
set installer "$root_dir/install-spectra-plus.fish"
set entrypoint "$root_dir/scripts/spectra-plus/repair-all.fish"
set rules "$root_dir/scripts/spectra-plus/rules.yaml"
set guard_marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"
set agent_label "com.agentflow.spectra-plus.repair"
set plus_version "1.2.0"
set plus_updated "2026-07-07"

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function assert_contains
    set file $argv[1]
    set text $argv[2]
    rg -q --fixed-strings -- "$text" "$file"; or fail "$file missing $text"
end

function assert_not_contains
    set file $argv[1]
    set text $argv[2]
    if rg -q --fixed-strings -- "$text" "$file"
        fail "$file unexpectedly contains $text"
    end
end

function run_expect
    set expected $argv[1]
    set command $argv[2..-1]
    $command >/tmp/spectra-plus-repair-test.out 2>/tmp/spectra-plus-repair-test.err
    set actual $status
    test "$actual" -eq "$expected"; or begin
        cat /tmp/spectra-plus-repair-test.out
        cat /tmp/spectra-plus-repair-test.err >&2
        fail "expected exit $expected, got $actual: $command"
    end
end

function run_with_bad_rules_expect
    set expected $argv[1]
    set bad_rules $argv[2]
    set command $argv[3..-1]
    command cp -f "$rules" /tmp/spectra-plus-repair-rules.backup
    command cp -f "$bad_rules" "$rules"
    commit_source_fixture "test bad rules"
    $command >/tmp/spectra-plus-repair-test.out 2>/tmp/spectra-plus-repair-test.err
    set actual $status
    command cp -f /tmp/spectra-plus-repair-rules.backup "$rules"
    commit_source_fixture "restore rules"
    test "$actual" -eq "$expected"; or begin
        cat /tmp/spectra-plus-repair-test.out
        cat /tmp/spectra-plus-repair-test.err >&2
        fail "expected exit $expected, got $actual: $command"
    end
end

function assert_frontmatter_contains
    set file $argv[1]
    set text $argv[2]
    awk -v text="$text" '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { exit }
        in_fm && $0 == text { found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$file"; or fail "$file frontmatter missing $text"
end

function target_plus_outputs
    set target $argv[1]
    printf '%s\n' \
        "$target/.agents/skills/spectra-propose-plus/SKILL.md" \
        "$target/.agents/skills/spectra-apply-plus/SKILL.md" \
        "$target/.claude/skills/spectra-propose-plus/SKILL.md" \
        "$target/.claude/skills/spectra-apply-plus/SKILL.md"
end

function target_plus_fingerprint
    set target $argv[1]
    for path in (target_plus_outputs "$target")
        if test -f "$path"
            cksum "$path"
        else
            echo "missing $path"
        end
    end
    for path in "$target/.agents/skills/spectra-commit/SKILL.md" "$target/.claude/skills/spectra-commit/SKILL.md"
        if test -f "$path"
            cksum "$path"
        else
            echo "missing $path"
        end
    end
end

function replace_in_file --argument-names path from to
    set rewritten (mktemp /tmp/spectra-plus-rewrite.XXXXXX)
    awk -v from="$from" -v to="$to" '
        {
            line = $0
            out = ""
            flen = length(from)
            while ((idx = index(line, from)) > 0) {
                out = out substr(line, 1, idx - 1) to
                line = substr(line, idx + flen)
            }
            out = out line
            print out
        }
    ' "$path" > "$rewritten"
    command mv -f "$rewritten" "$path"
end

function make_home
    mktemp -d /tmp/spectra-plus-home.XXXXXX
end

function make_run_dir
    mktemp -d /tmp/spectra-plus-run.XXXXXX
end

function make_clean_source_fixture --argument-names source
    set fixture (mktemp -d /tmp/spectra-plus-source.XXXXXX)
    mkdir -p "$fixture/scripts" "$fixture/.agents" "$fixture/.claude"
    command cp "$source/install-spectra-plus.fish" "$fixture/"
    command cp -R "$source/scripts/spectra-plus" "$fixture/scripts/"
    command cp -R "$source/.agents/skills" "$fixture/.agents/"
    command cp -R "$source/.claude/skills" "$fixture/.claude/"
    git -C "$fixture" init -q
    git -C "$fixture" config user.email "spectra-plus-test@example.invalid"
    git -C "$fixture" config user.name "Spectra Plus Test"
    git -C "$fixture" add install-spectra-plus.fish scripts/spectra-plus .agents/skills .claude/skills
    git -C "$fixture" commit -qm "initial fixture"
    echo "$fixture"
end

function commit_source_fixture --argument-names message
    git -C "$root_dir" add install-spectra-plus.fish scripts/spectra-plus .agents/skills .claude/skills
    git -C "$root_dir" commit -qm "$message"
end

function reset_source_fixture
    git -C "$root_dir" reset --hard -q HEAD
    git -C "$root_dir" clean -fd -q
end

function registry_path --argument-names home
    echo "$home/.config/spectra-plus/projects.txt"
end

function make_target --argument-names target
    mkdir -p "$target/.agents/skills" "$target/.claude/skills"
    for skill in spectra-propose spectra-apply spectra-commit
        command cp -R "$root_dir/.agents/skills/$skill" "$target/.agents/skills/"
        command cp -R "$root_dir/.claude/skills/$skill" "$target/.claude/skills/"
    end
end

function strip_guard --argument-names path
    set stripped (mktemp /tmp/spectra-plus-guard-strip.XXXXXX)
    awk '
        /<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist \+ plus deletion protection -->/ { skip = 1; next }
        /<!-- SPECTRA-COMMIT-GUARD:END -->/ { skip = 0; next }
        !skip { print }
    ' "$path" > "$stripped"
    command mv -f "$stripped" "$path"
end

function assert_registered_once --argument-names registry target
    test -f "$registry"; or fail "missing registry $registry"
    set count (rg --fixed-strings "$target" "$registry" | wc -l | string trim)
    test "$count" = 1; or fail "$registry should contain one $target entry, found $count"
end

function assert_plus_outputs --argument-names target
    test -f "$target/.claude/skills/spectra-propose-plus/SKILL.md"; or fail "missing claude propose-plus in $target"
    test -f "$target/.claude/skills/spectra-apply-plus/SKILL.md"; or fail "missing claude apply-plus in $target"
    test -f "$target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "missing codex propose-plus in $target"
    test -f "$target/.agents/skills/spectra-apply-plus/SKILL.md"; or fail "missing codex apply-plus in $target"
    assert_contains "$target/.agents/skills/spectra-commit/SKILL.md" "$guard_marker"
    assert_contains "$target/.claude/skills/spectra-commit/SKILL.md" "$guard_marker"
    for path in (target_plus_outputs "$target")
        assert_frontmatter_contains "$path" "spectraPlusVersion: $plus_version"
        assert_frontmatter_contains "$path" "spectraPlusUpdated: $plus_updated"
    end
    for path in "$target/.agents/skills/spectra-propose-plus/SKILL.md" "$target/.claude/skills/spectra-propose-plus/SKILL.md"
        assert_contains "$path" "8. **Validation**"
        assert_contains "$path" "9. **Sub-Agent Review/Rating/Fix Loop**"
        assert_contains "$path" "10. **Finish the plus proposal workflow**"
        assert_contains "$path" "has passed. If validation fixes are required, complete them before entering this loop."
        assert_contains "$path" 'if any fix action modifies proposal, design, tasks, or spec artifacts, run `spectra validate "<name>"` again'
        assert_not_contains "$path" "Codex Plan Mode"
        assert_not_contains "$path" "docs/specs/"
    end
    for path in "$target/.agents/skills/spectra-apply-plus/SKILL.md" "$target/.claude/skills/spectra-apply-plus/SKILL.md"
        assert_contains "$path" "8. **Implementation Notes Protocol**"
        assert_contains "$path" "12. **Sub-Agent Review/Rating/Fix Loop**"
        assert_contains "$path" "Reviewer A — Adherence in the Sub-Agent Review/Rating/Fix Loop MUST"
        assert_contains "$path" "archive guidance is deferred until the plus quality gate passes"
        assert_contains "$path" "All tasks complete. The plus quality gate runs next; archive guidance is shown only if it passes."
        assert_not_contains "$path" "All tasks complete! You can archive this change with"
        assert_not_contains "$path" "docs/specs/"
    end
end

function make_launchctl_stub --argument-names dir mode
    mkdir -p "$dir"
    set stub "$dir/launchctl"
    printf '%s\n' \
        '#!/usr/bin/env fish' \
        'echo "$argv" >> "$LAUNCHCTL_LOG"' \
        'if test "$LAUNCHCTL_MODE" = fail_bootout; and contains -- bootout $argv' \
        '    exit 8' \
        'end' \
        'if test "$LAUNCHCTL_MODE" = fail; and contains -- bootstrap $argv' \
        '    exit 7' \
        'end' \
        'exit 0' > "$stub"
    chmod +x "$stub"
end

function make_git_status_stub --argument-names dir status_line
    mkdir -p "$dir"
    set stub "$dir/git"
    set real_git (command -s git)
    printf '%s\n' \
        '#!/usr/bin/env fish' \
        "set real_git "(string escape -- "$real_git") \
        "set status_line "(string escape -- "$status_line") \
        'if contains -- status $argv; and contains -- --porcelain $argv' \
        '    echo "$status_line"' \
        '    exit 0' \
        'end' \
        'command "$real_git" $argv' > "$stub"
    chmod +x "$stub"
end

function prepare_guard_case
    set -g guard_home (make_home)
    set -g guard_run (make_run_dir)
    set -g guard_target (mktemp -d /tmp/spectra-plus-dirty-target.XXXXXX)
    make_target "$guard_target"
    run_expect 0 "$installer" --target "$guard_target"
    set -g guard_before (target_plus_fingerprint "$guard_target" | string collect)
    mkdir -p (dirname (registry_path "$guard_home"))
    printf '%s\n' "$guard_target" > (registry_path "$guard_home")
end

function assert_guard_case_unchanged --argument-names context
    set guard_after (target_plus_fingerprint "$guard_target" | string collect)
    test "$guard_before" = "$guard_after"; or fail "$context modified registered target"
    test ! -e "$guard_run/spectra-plus-repair.lock"; or fail "$context wrote repair lock"
    test ! -e "$guard_home/.cache/spectra-plus/last-repair-attempt"; or fail "$context wrote throttle state"
end

function assert_dirty_source_skip_output --argument-names path_hint
    assert_contains /tmp/spectra-plus-repair-test.out "dirty source checkout"
    assert_contains /tmp/spectra-plus-repair-test.out "$path_hint"
    assert_not_contains /tmp/spectra-plus-repair-test.out "already current"
    assert_not_contains /tmp/spectra-plus-repair-test.out "[success]"
    assert_not_contains /tmp/spectra-plus-repair-test.out "[failed]"
    assert_not_contains /tmp/spectra-plus-repair-test.out "throttled"
    assert_not_contains /tmp/spectra-plus-repair-test.out "+ repair target"
end

cd "$root_dir"; or fail "cannot cd to root"

set source_fixture (make_clean_source_fixture "$original_root_dir")
set root_dir "$source_fixture"
set installer "$root_dir/install-spectra-plus.fish"
set entrypoint "$root_dir/scripts/spectra-plus/repair-all.fish"
set rules "$root_dir/scripts/spectra-plus/rules.yaml"
cd "$root_dir"; or fail "cannot cd to source fixture"

set home (make_home)
set run_dir (make_run_dir)
set target (mktemp -d /tmp/spectra-plus-reg-target.XXXXXX)
make_target "$target"
set registry (registry_path "$home")

run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --register-target "$target"
run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --register-target "$target"
assert_registered_once "$registry" "$target"
set before_checksum (cksum "$registry")
run_expect 1 env HOME="$home" TMPDIR="$run_dir" "$installer" --register-target "$target/missing"
assert_contains /tmp/spectra-plus-repair-test.err "invalid target"
test "$before_checksum" = (cksum "$registry"); or fail "invalid nonexistent target modified registry"
set not_dir "$target/not-dir"
echo "not a directory" > "$not_dir"
run_expect 1 env HOME="$home" TMPDIR="$run_dir" "$installer" --register-target "$not_dir"
assert_contains /tmp/spectra-plus-repair-test.err "invalid target"
test "$before_checksum" = (cksum "$registry"); or fail "invalid non-directory target modified registry"

set second_target (mktemp -d /tmp/spectra-plus-reg-second.XXXXXX)
make_target "$second_target"
run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --register-target "$second_target"
run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --unregister-target "$target"
assert_not_contains "$registry" "$target"
assert_contains "$registry" "$second_target"
set before_noop (cksum "$registry")
run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --unregister-target "$target"
assert_contains /tmp/spectra-plus-repair-test.out "no-op"
test "$before_noop" = (cksum "$registry"); or fail "unregister no-op modified other entries"
set stale_target (mktemp -d /tmp/spectra-plus-stale-target.XXXXXX)
make_target "$stale_target"
run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --register-target "$stale_target"
command rm -rf "$stale_target"
run_expect 0 env HOME="$home" TMPDIR="$run_dir" "$installer" --unregister-target "$stale_target"
assert_not_contains "$registry" "$stale_target"

set list_home (make_home)
set list_registry (registry_path "$list_home")
mkdir -p (dirname "$list_registry")
printf '%s\n' "" "# comment" "$target" "   " "$second_target" > "$list_registry"
run_expect 0 env HOME="$list_home" TMPDIR="$run_dir" "$installer" --list-targets
assert_contains /tmp/spectra-plus-repair-test.out "$target"
assert_contains /tmp/spectra-plus-repair-test.out "$second_target"
assert_not_contains /tmp/spectra-plus-repair-test.out "# comment"

set dry_home (make_home)
set dry_registry (registry_path "$dry_home")
run_expect 0 env HOME="$dry_home" TMPDIR="$run_dir" "$installer" --register-target "$target" --dry-run
test ! -e "$dry_registry"; or fail "register dry-run created registry"
mkdir -p (dirname "$dry_registry")
printf '%s\n' "$target" > "$dry_registry"
set dry_before (cksum "$dry_registry")
run_expect 0 env HOME="$dry_home" TMPDIR="$run_dir" "$installer" --unregister-target "$target" --dry-run
test "$dry_before" = (cksum "$dry_registry"); or fail "unregister dry-run modified registry"

reset_source_fixture
prepare_guard_case
printf '\n# dirty source\n' >> "$root_dir/install-spectra-plus.fish"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output "install-spectra-plus.fish"
assert_guard_case_unchanged "dirty installer repair-all"
reset_source_fixture

prepare_guard_case
printf '\nnot: [valid\n' >> "$rules"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output "scripts/spectra-plus/rules.yaml"
assert_not_contains /tmp/spectra-plus-repair-test.err "rules.yaml parse error"
assert_guard_case_unchanged "dirty invalid rules repair-all"
reset_source_fixture

prepare_guard_case
printf '%s\n' "/tmp/spectra-plus-invalid-dirty-$fish_pid" "$guard_target" > (registry_path "$guard_home")
printf '\n# dirty source\n' >> "$root_dir/.agents/skills/spectra-propose/SKILL.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output ".agents/skills/spectra-propose/SKILL.md"
assert_not_contains /tmp/spectra-plus-repair-test.out "invalid target"
assert_guard_case_unchanged "dirty source invalid registry precedence"
reset_source_fixture

prepare_guard_case
mkdir -p "$guard_home/.cache/spectra-plus"
date +%s > "$guard_home/.cache/spectra-plus/last-repair-attempt"
set throttle_before (cksum "$guard_home/.cache/spectra-plus/last-repair-attempt")
printf '\n# dirty source\n' >> "$root_dir/.claude/skills/spectra-apply/SKILL.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all
assert_dirty_source_skip_output ".claude/skills/spectra-apply/SKILL.md"
test "$throttle_before" = (cksum "$guard_home/.cache/spectra-plus/last-repair-attempt"); or fail "dirty source rewrote throttle state"
test ! -e "$guard_run/spectra-plus-repair.lock"; or fail "dirty source wrote repair lock"
set throttle_target_after (target_plus_fingerprint "$guard_target" | string collect)
test "$guard_before" = "$throttle_target_after"; or fail "dirty source throttle precedence modified registered target"
reset_source_fixture

prepare_guard_case
printf '\n# dirty source\n' >> "$root_dir/.agents/skills/spectra-ask/SKILL.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --dry-run
assert_dirty_source_skip_output ".agents/skills/spectra-ask/SKILL.md"
assert_guard_case_unchanged "dirty source dry-run"
reset_source_fixture

prepare_guard_case
printf '\n# staged source\n' >> "$root_dir/scripts/spectra-plus/generate.fish"
git -C "$root_dir" add scripts/spectra-plus/generate.fish
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output "scripts/spectra-plus/generate.fish"
assert_guard_case_unchanged "staged source-sensitive modification"
reset_source_fixture

prepare_guard_case
printf '%s\n' "staged add" > "$root_dir/.claude/skills/spectra-audit/STAGED.txt"
git -C "$root_dir" add .claude/skills/spectra-audit/STAGED.txt
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output ".claude/skills/spectra-audit/STAGED.txt"
assert_guard_case_unchanged "staged added source-sensitive file"
reset_source_fixture

prepare_guard_case
mkdir -p "$root_dir/scripts/spectra-plus/tmp/nested"
printf '%s\n' "nested dirty" > "$root_dir/scripts/spectra-plus/tmp/nested/untracked.txt"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output "scripts/spectra-plus/tmp/nested/untracked.txt"
assert_guard_case_unchanged "nested untracked source-sensitive file"
reset_source_fixture

prepare_guard_case
command rm -f "$root_dir/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output ".agents/skills/spectra-commit/SKILL.md"
assert_guard_case_unchanged "deleted source-sensitive file"
reset_source_fixture

prepare_guard_case
git -C "$root_dir" mv .claude/skills/spectra-commit/SKILL.md .claude/skills/spectra-commit/SKILL.moved
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output ".claude/skills/spectra-commit/SKILL.md"
assert_guard_case_unchanged "renamed source-sensitive file"
reset_source_fixture

prepare_guard_case
command rm -f "$root_dir/.agents/skills/spectra-ask/SKILL.md"
ln -s /tmp/spectra-plus-typechange "$root_dir/.agents/skills/spectra-ask/SKILL.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output ".agents/skills/spectra-ask/SKILL.md"
assert_guard_case_unchanged "typechange source-sensitive file"
reset_source_fixture

prepare_guard_case
set copied_git_stub (mktemp -d /tmp/spectra-plus-git-copy.XXXXXX)
make_git_status_stub "$copied_git_stub" "C  .agents/skills/spectra-apply/SKILL.md -> .agents/skills/spectra-apply/SKILL.copy"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" PATH="$copied_git_stub:$PATH" "$installer" --repair-all --force
assert_dirty_source_skip_output ".agents/skills/spectra-apply/SKILL.md"
assert_guard_case_unchanged "copied source-sensitive porcelain entry"
reset_source_fixture

prepare_guard_case
set copied_unrelated_git_stub (mktemp -d /tmp/spectra-plus-git-copy-unrelated.XXXXXX)
make_git_status_stub "$copied_unrelated_git_stub" "C  scripts/spectra-plus-notes.md -> scripts/spectra-plus-notes.copy"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" PATH="$copied_unrelated_git_stub:$PATH" "$installer" --repair-all --force
assert_not_contains /tmp/spectra-plus-repair-test.out "dirty source checkout"
assert_contains /tmp/spectra-plus-repair-test.out "already current"
reset_source_fixture

prepare_guard_case
set fixture_branch (git -C "$root_dir" branch --show-current)
git -C "$root_dir" checkout -qb spectra-plus-conflict
printf '\n# conflict left\n' >> "$rules"
git -C "$root_dir" add scripts/spectra-plus/rules.yaml
git -C "$root_dir" commit -qm "left conflict"
git -C "$root_dir" checkout -q "$fixture_branch"
printf '\n# conflict right\n' >> "$rules"
git -C "$root_dir" add scripts/spectra-plus/rules.yaml
git -C "$root_dir" commit -qm "right conflict"
git -C "$root_dir" merge spectra-plus-conflict >/dev/null 2>/dev/null
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output "scripts/spectra-plus/rules.yaml"
assert_guard_case_unchanged "unmerged source-sensitive file"
reset_source_fixture

prepare_guard_case
printf '%s\n' "outside source-sensitive set" > "$root_dir/scripts/spectra-plus-notes.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_not_contains /tmp/spectra-plus-repair-test.out "dirty source checkout"
assert_contains /tmp/spectra-plus-repair-test.out "already current"
set unrelated_target_after (target_plus_fingerprint "$guard_target" | string collect)
test "$guard_before" = "$unrelated_target_after"; or fail "unrelated dirty source modified current target"
reset_source_fixture

set manual_dirty_target (mktemp -d /tmp/spectra-plus-manual-dirty.XXXXXX)
make_target "$manual_dirty_target"
printf '\n# dirty source\n' >> "$root_dir/install-spectra-plus.fish"
run_expect 0 "$installer" --target "$manual_dirty_target"
assert_plus_outputs "$manual_dirty_target"
reset_source_fixture

prepare_guard_case
strip_guard "$root_dir/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$installer" --repair-all --force
assert_dirty_source_skip_output ".agents/skills/spectra-commit/SKILL.md"
assert_not_contains "$root_dir/.agents/skills/spectra-commit/SKILL.md" "$guard_marker"
assert_guard_case_unchanged "dirty stripped source guard repair-all"
reset_source_fixture

set restore_target (mktemp -d /tmp/spectra-plus-restore-target.XXXXXX)
make_target "$restore_target"
strip_guard "$root_dir/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 "$installer" --target "$restore_target"
assert_contains /tmp/spectra-plus-repair-test.out "restored .agents/skills/spectra-commit/SKILL.md from HEAD"
assert_contains "$root_dir/.agents/skills/spectra-commit/SKILL.md" "$guard_marker"
reset_source_fixture

set restore_dry_target (mktemp -d /tmp/spectra-plus-restore-dry-target.XXXXXX)
make_target "$restore_dry_target"
strip_guard "$root_dir/.claude/skills/spectra-commit/SKILL.md"
run_expect 0 "$installer" --target "$restore_dry_target" --dry-run
assert_contains /tmp/spectra-plus-repair-test.out "+ would restore .claude/skills/spectra-commit/SKILL.md from HEAD"
assert_not_contains "$root_dir/.claude/skills/spectra-commit/SKILL.md" "$guard_marker"
reset_source_fixture

set nongit_source (make_clean_source_fixture "$root_dir")
command rm -rf "$nongit_source/.git"
set nongit_installer "$nongit_source/install-spectra-plus.fish"
prepare_guard_case
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$nongit_installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "source clean state unavailable"
assert_not_contains /tmp/spectra-plus-repair-test.out "already current"
assert_guard_case_unchanged "non-git source repair-all"
reset_source_fixture

set repair_home (make_home)
set repair_run (make_run_dir)
set repair_a (mktemp -d /tmp/spectra-plus-repair-a.XXXXXX)
set repair_b (mktemp -d /tmp/spectra-plus-repair-b.XXXXXX)
set repair_stale_plus (mktemp -d /tmp/spectra-plus-repair-stale-plus.XXXXXX)
set repair_stale_version (mktemp -d /tmp/spectra-plus-repair-stale-version.XXXXXX)
set repair_stale_updated (mktemp -d /tmp/spectra-plus-repair-stale-updated.XXXXXX)
set repair_missing_metadata (mktemp -d /tmp/spectra-plus-repair-missing-metadata.XXXXXX)
set repair_single_stale (mktemp -d /tmp/spectra-plus-repair-single-stale.XXXXXX)
make_target "$repair_a"
make_target "$repair_b"
make_target "$repair_stale_plus"
make_target "$repair_stale_version"
make_target "$repair_stale_updated"
make_target "$repair_missing_metadata"
make_target "$repair_single_stale"
run_expect 0 "$installer" --target "$repair_stale_plus"
run_expect 0 "$installer" --target "$repair_stale_version"
run_expect 0 "$installer" --target "$repair_stale_updated"
run_expect 0 "$installer" --target "$repair_missing_metadata"
run_expect 0 "$installer" --target "$repair_single_stale"
for path in "$repair_stale_plus/.agents/skills/spectra-apply-plus/SKILL.md" "$repair_stale_plus/.claude/skills/spectra-apply-plus/SKILL.md"
    set stale_output (mktemp /tmp/spectra-plus-stale-output.XXXXXX)
    awk '{ gsub(/archive guidance is deferred until the plus quality gate passes/, "suggest archive"); print }' "$path" > "$stale_output"
    command mv -f "$stale_output" "$path"
end
for path in (target_plus_outputs "$repair_stale_version")
    replace_in_file "$path" "spectraPlusVersion: $plus_version" "spectraPlusVersion: 1.0.0"
end
for path in (target_plus_outputs "$repair_stale_updated")
    replace_in_file "$path" "spectraPlusUpdated: $plus_updated" "spectraPlusUpdated: 2026-01-01"
end
for path in (target_plus_outputs "$repair_missing_metadata")
    set stripped (mktemp /tmp/spectra-plus-metadata-strip.XXXXXX)
    awk -v version_line="spectraPlusVersion: $plus_version" -v updated_line="spectraPlusUpdated: $plus_updated" '$0 != version_line && $0 != updated_line { print }' "$path" > "$stripped"
    command mv -f "$stripped" "$path"
end
replace_in_file "$repair_single_stale/.agents/skills/spectra-propose-plus/SKILL.md" "spectraPlusVersion: $plus_version" "spectraPlusVersion: 1.0.0"
strip_guard "$repair_b/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_a"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_b"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_stale_plus"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_stale_version"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_stale_updated"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_missing_metadata"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_single_stale"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --repair-all --force
assert_plus_outputs "$repair_a"
assert_plus_outputs "$repair_b"
assert_plus_outputs "$repair_stale_plus"
assert_plus_outputs "$repair_stale_version"
assert_plus_outputs "$repair_stale_updated"
assert_plus_outputs "$repair_missing_metadata"
assert_plus_outputs "$repair_single_stale"

set bad_rules_home (make_home)
set bad_rules_run (make_run_dir)
set bad_rules_target (mktemp -d /tmp/spectra-plus-bad-rules-target.XXXXXX)
make_target "$bad_rules_target"
run_expect 0 "$installer" --target "$bad_rules_target"
set bad_rules_before (target_plus_fingerprint "$bad_rules_target" | string collect)
mkdir -p (dirname (registry_path "$bad_rules_home"))
printf '%s\n' "$bad_rules_target" > (registry_path "$bad_rules_home")
yq 'del(.skills."spectra-propose-plus".metadata.spectraPlusVersion)' "$rules" > /tmp/spectra-plus-repair-rules.bad
run_with_bad_rules_expect 1 /tmp/spectra-plus-repair-rules.bad env HOME="$bad_rules_home" TMPDIR="$bad_rules_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.err "spectraPlusVersion"
assert_not_contains /tmp/spectra-plus-repair-test.out "already current"
set bad_rules_after (target_plus_fingerprint "$bad_rules_target" | string collect)
test "$bad_rules_before" = "$bad_rules_after"; or fail "bad local rules modified target plus outputs"
yq '.skills."spectra-propose-plus".metadata.spectraPlusVersion = null' "$rules" > /tmp/spectra-plus-repair-rules.bad
run_with_bad_rules_expect 1 /tmp/spectra-plus-repair-rules.bad env HOME="$bad_rules_home" TMPDIR="$bad_rules_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.err "spectraPlusVersion"
assert_not_contains /tmp/spectra-plus-repair-test.out "already current"
set bad_rules_after (target_plus_fingerprint "$bad_rules_target" | string collect)
test "$bad_rules_before" = "$bad_rules_after"; or fail "bad local rules null version modified target plus outputs"
yq '.skills."spectra-propose-plus".metadata.spectraPlusUpdated = "2026-13-45" | .skills."spectra-apply-plus".metadata.spectraPlusUpdated = "2026-13-45"' "$rules" > /tmp/spectra-plus-repair-rules.bad
run_with_bad_rules_expect 1 /tmp/spectra-plus-repair-rules.bad env HOME="$bad_rules_home" TMPDIR="$bad_rules_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.err "spectraPlusUpdated"
assert_not_contains /tmp/spectra-plus-repair-test.out "already current"
set bad_rules_after (target_plus_fingerprint "$bad_rules_target" | string collect)
test "$bad_rules_before" = "$bad_rules_after"; or fail "bad local rules invalid updated modified target plus outputs"
yq 'del(.skills."spectra-propose-plus".metadata.spectraPlusVersion)' "$rules" > /tmp/spectra-plus-repair-rules.bad
run_with_bad_rules_expect 1 /tmp/spectra-plus-repair-rules.bad env HOME="$bad_rules_home" TMPDIR="$bad_rules_run" "$installer" --repair-all --dry-run
assert_contains /tmp/spectra-plus-repair-test.err "spectraPlusVersion"
assert_not_contains /tmp/spectra-plus-repair-test.out "+ repair target"
set bad_rules_after (target_plus_fingerprint "$bad_rules_target" | string collect)
test "$bad_rules_before" = "$bad_rules_after"; or fail "bad local rules dry-run modified target plus outputs"
yq 'del(.skills."spectra-propose-plus".metadata.spectraPlusVersion)' "$rules" > /tmp/spectra-plus-repair-rules.bad
run_with_bad_rules_expect 1 /tmp/spectra-plus-repair-rules.bad env HOME="$bad_rules_home" TMPDIR="$bad_rules_run" "$installer" --target "$bad_rules_target" --dry-run
assert_contains /tmp/spectra-plus-repair-test.err "spectraPlusVersion"
assert_not_contains /tmp/spectra-plus-repair-test.out "+ "
set bad_rules_after (target_plus_fingerprint "$bad_rules_target" | string collect)
test "$bad_rules_before" = "$bad_rules_after"; or fail "bad local rules target dry-run modified target plus outputs"

set boundary_home (make_home)
set boundary_run (make_run_dir)
set registered (mktemp -d /tmp/spectra-plus-registered.XXXXXX)
set unregistered (mktemp -d /tmp/spectra-plus-unregistered.XXXXXX)
make_target "$registered"
make_target "$unregistered"
set unregistered_agents_commit_before (cksum "$unregistered/.agents/skills/spectra-commit/SKILL.md")
set unregistered_claude_commit_before (cksum "$unregistered/.claude/skills/spectra-commit/SKILL.md")
run_expect 0 env HOME="$boundary_home" TMPDIR="$boundary_run" "$installer" --register-target "$registered"
run_expect 0 env HOME="$boundary_home" TMPDIR="$boundary_run" "$installer" --repair-all --force
assert_plus_outputs "$registered"
test "$unregistered_agents_commit_before" = (cksum "$unregistered/.agents/skills/spectra-commit/SKILL.md"); or fail "repair-all modified unregistered agents commit guard"
test "$unregistered_claude_commit_before" = (cksum "$unregistered/.claude/skills/spectra-commit/SKILL.md"); or fail "repair-all modified unregistered claude commit guard"
test ! -e "$unregistered/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "repair-all modified unregistered target"
test ! -e "$unregistered/.agents/skills/spectra-apply-plus/SKILL.md"; or fail "repair-all modified unregistered target"
test ! -e "$unregistered/.claude/skills/spectra-propose-plus/SKILL.md"; or fail "repair-all modified unregistered target"
test ! -e "$unregistered/.claude/skills/spectra-apply-plus/SKILL.md"; or fail "repair-all modified unregistered target"

set invalid_home (make_home)
set invalid_run (make_run_dir)
set invalid_valid (mktemp -d /tmp/spectra-plus-invalid-valid.XXXXXX)
set invalid_missing "/tmp/spectra-plus-invalid-missing-$fish_pid"
make_target "$invalid_valid"
mkdir -p (dirname (registry_path "$invalid_home"))
printf '%s\n' "$invalid_missing" "$invalid_valid" > (registry_path "$invalid_home")
run_expect 1 env HOME="$invalid_home" TMPDIR="$invalid_run" "$installer" --repair-all --force
assert_plus_outputs "$invalid_valid"
assert_contains /tmp/spectra-plus-repair-test.out "[failed]"
assert_contains /tmp/spectra-plus-repair-test.out "$invalid_missing"

set dry_repair_home (make_home)
set dry_repair_run (make_run_dir)
set dry_repair_target (mktemp -d /tmp/spectra-plus-dry-repair.XXXXXX)
make_target "$dry_repair_target"
run_expect 0 env HOME="$dry_repair_home" TMPDIR="$dry_repair_run" "$installer" --register-target "$dry_repair_target"
set dry_commit_before (cksum "$dry_repair_target/.agents/skills/spectra-commit/SKILL.md")
run_expect 0 env HOME="$dry_repair_home" TMPDIR="$dry_repair_run" "$installer" --repair-all --dry-run
test "$dry_commit_before" = (cksum "$dry_repair_target/.agents/skills/spectra-commit/SKILL.md"); or fail "repair-all dry-run modified target"
test ! -e "$dry_repair_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "repair-all dry-run generated plus skill"
test ! -e "$dry_repair_home/.cache/spectra-plus/last-repair-attempt"; or fail "repair-all dry-run wrote throttle state"
test ! -e "$dry_repair_run/spectra-plus-repair.lock"; or fail "repair-all dry-run wrote lock"

set summary_home (make_home)
set summary_run (make_run_dir)
set current_target (mktemp -d /tmp/spectra-plus-current.XXXXXX)
set reset_target (mktemp -d /tmp/spectra-plus-reset.XXXXXX)
set failed_target "/tmp/spectra-plus-summary-missing-$fish_pid"
make_target "$current_target"
make_target "$reset_target"
run_expect 0 "$installer" --target "$current_target"
mkdir -p (dirname (registry_path "$summary_home"))
printf '%s\n' "$current_target" "$reset_target" "$failed_target" > (registry_path "$summary_home")
run_expect 1 env HOME="$summary_home" TMPDIR="$summary_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "[skipped]"
assert_contains /tmp/spectra-plus-repair-test.out "[success]"
assert_contains /tmp/spectra-plus-repair-test.out "[failed]"

set entry_home (make_home)
set entry_run (make_run_dir)
set entry_target (mktemp -d /tmp/spectra-plus-entry-target.XXXXXX)
make_target "$entry_target"
run_expect 0 env HOME="$entry_home" TMPDIR="$entry_run" "$installer" --register-target "$entry_target"
run_expect 0 env HOME="$entry_home" TMPDIR="$entry_run" "$entrypoint" --force
assert_plus_outputs "$entry_target"
set fish_bin (command -s fish)
set fish_only_bin (mktemp -d /tmp/spectra-plus-fish-only.XXXXXX)
ln -s "$fish_bin" "$fish_only_bin/fish"
set missing_yq_home (make_home)
reset_source_fixture
prepare_guard_case
printf '\n# dirty source\n' >> "$root_dir/scripts/spectra-plus/generate.fish"
run_expect 0 env HOME="$missing_yq_home" TMPDIR="$guard_run" PATH="$fish_only_bin:/usr/bin:/bin" "$fish_bin" "$entrypoint" --force
assert_dirty_source_skip_output "scripts/spectra-plus/generate.fish"
assert_guard_case_unchanged "entrypoint missing yq dirty source"
test ! -e "$missing_yq_home/Library/Logs/spectra-plus-repair.log"; or assert_not_contains "$missing_yq_home/Library/Logs/spectra-plus-repair.log" "找不到必要指令：yq"
reset_source_fixture

prepare_guard_case
printf '\n# parseable dirty entrypoint\n' >> "$entrypoint"
run_expect 0 env HOME="$guard_home" TMPDIR="$guard_run" "$entrypoint" --force
assert_dirty_source_skip_output "scripts/spectra-plus/repair-all.fish"
assert_guard_case_unchanged "parseable dirty entrypoint"
reset_source_fixture

set agent_home (mktemp -d "/tmp/spectra-plus-agent-&-home.XXXXXX")
set agent_run (make_run_dir)
set launch_stub (mktemp -d /tmp/spectra-plus-launchctl.XXXXXX)
set launch_log "$agent_home/launchctl.log"
make_launchctl_stub "$launch_stub" ok
run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --install-launch-agent
set plist "$agent_home/Library/LaunchAgents/$agent_label.plist"
assert_contains "$plist" "$agent_label"
assert_contains "$plist" "$entrypoint"
assert_contains "$plist" "StartInterval"
assert_contains "$plist" "StandardOutPath"
assert_not_contains "$plist" "/Applications/Spectra.app"
assert_contains "$plist" "spectra-plus-agent-&amp;-home"
set start_interval (awk '/<key>StartInterval<\/key>/ { getline; gsub(/[^0-9]/, ""); print; exit }' "$plist")
test "$start_interval" -ge 60; or fail "throttle window exceeds LaunchAgent StartInterval"
assert_contains "$launch_log" "bootstrap"
run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --install-launch-agent
test (rg --fixed-strings "$agent_label" "$plist" | wc -l | string trim) = 1; or fail "LaunchAgent plist duplicated label"

set fail_agent_home (make_home)
set fail_launch_log "$fail_agent_home/launchctl.log"
run_expect 1 env HOME="$fail_agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$fail_launch_log" LAUNCHCTL_MODE=fail "$installer" --install-launch-agent
assert_contains /tmp/spectra-plus-repair-test.err "manual activation"

run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --uninstall-launch-agent
test ! -e "$plist"; or fail "uninstall left LaunchAgent plist"
run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --uninstall-launch-agent

set bootout_fail_home (make_home)
set bootout_fail_log "$bootout_fail_home/launchctl.log"
run_expect 0 env HOME="$bootout_fail_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$bootout_fail_log" "$installer" --install-launch-agent
set bootout_fail_plist "$bootout_fail_home/Library/LaunchAgents/$agent_label.plist"
run_expect 1 env HOME="$bootout_fail_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$bootout_fail_log" LAUNCHCTL_MODE=fail_bootout "$installer" --uninstall-launch-agent
test -f "$bootout_fail_plist"; or fail "failed LaunchAgent uninstall removed plist"
assert_contains /tmp/spectra-plus-repair-test.err "manual cleanup"

set bounded_home (make_home)
set bounded_run (make_run_dir)
set bounded_target (mktemp -d /tmp/spectra-plus-bounded.XXXXXX)
make_target "$bounded_target"
run_expect 0 env HOME="$bounded_home" TMPDIR="$bounded_run" "$installer" --register-target "$bounded_target"
mkdir "$bounded_run/spectra-plus-repair.lock"
run_expect 0 env HOME="$bounded_home" TMPDIR="$bounded_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "locked"
test ! -e "$bounded_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "locked repair modified target"
touch -t 202001010000 "$bounded_run/spectra-plus-repair.lock"
run_expect 0 env HOME="$bounded_home" TMPDIR="$bounded_run" "$installer" --repair-all --force
assert_plus_outputs "$bounded_target"

set throttle_home (make_home)
set throttle_run (make_run_dir)
set throttle_target (mktemp -d /tmp/spectra-plus-throttle.XXXXXX)
make_target "$throttle_target"
run_expect 0 env HOME="$throttle_home" TMPDIR="$throttle_run" "$installer" --register-target "$throttle_target"
mkdir -p "$throttle_home/.cache/spectra-plus"
date +%s > "$throttle_home/.cache/spectra-plus/last-repair-attempt"
run_expect 0 env HOME="$throttle_home" TMPDIR="$throttle_run" "$installer" --repair-all
assert_contains /tmp/spectra-plus-repair-test.out "throttled"
test ! -e "$throttle_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "throttled repair modified target"
run_expect 0 env HOME="$throttle_home" TMPDIR="$throttle_run" "$installer" --repair-all --force
assert_plus_outputs "$throttle_target"

set fail_throttle_home (make_home)
set fail_throttle_run (make_run_dir)
mkdir -p (dirname (registry_path "$fail_throttle_home"))
printf '%s\n' "/tmp/spectra-plus-fail-throttle-missing-$fish_pid" > (registry_path "$fail_throttle_home")
run_expect 1 env HOME="$fail_throttle_home" TMPDIR="$fail_throttle_run" "$installer" --repair-all --force
test -f "$fail_throttle_home/.cache/spectra-plus/last-repair-attempt"; or fail "failed repair did not update throttle attempt"
run_expect 0 env HOME="$fail_throttle_home" TMPDIR="$fail_throttle_run" "$installer" --repair-all
assert_contains /tmp/spectra-plus-repair-test.out "throttled"

set dry_agent_home (make_home)
set dry_agent_run (make_run_dir)
set dry_launch_stub (mktemp -d /tmp/spectra-plus-launchctl-dry.XXXXXX)
set dry_launch_log "$dry_agent_home/launchctl.log"
make_launchctl_stub "$dry_launch_stub" ok
mkdir -p "$dry_agent_home/Library/LaunchAgents"
set dry_plist "$dry_agent_home/Library/LaunchAgents/$agent_label.plist"
printf '%s\n' "sentinel" > "$dry_plist"
set dry_plist_before (cksum "$dry_plist")
run_expect 0 env HOME="$dry_agent_home" TMPDIR="$dry_agent_run" PATH="$dry_launch_stub:$PATH" LAUNCHCTL_LOG="$dry_launch_log" "$installer" --install-launch-agent --dry-run
test "$dry_plist_before" = (cksum "$dry_plist"); or fail "install LaunchAgent dry-run modified plist"
test ! -e "$dry_launch_log"; or fail "install LaunchAgent dry-run called launchctl"
run_expect 0 env HOME="$dry_agent_home" TMPDIR="$dry_agent_run" PATH="$dry_launch_stub:$PATH" LAUNCHCTL_LOG="$dry_launch_log" "$installer" --uninstall-launch-agent --dry-run
test "$dry_plist_before" = (cksum "$dry_plist"); or fail "uninstall LaunchAgent dry-run modified plist"
test ! -e "$dry_launch_log"; or fail "uninstall LaunchAgent dry-run called launchctl"

run_expect 0 "$installer" --help
assert_contains /tmp/spectra-plus-repair-test.out "--register-target"
assert_contains /tmp/spectra-plus-repair-test.out "--repair-all"
assert_contains /tmp/spectra-plus-repair-test.out "--install-launch-agent"
assert_contains /tmp/spectra-plus-repair-test.out "--force"
assert_contains /tmp/spectra-plus-repair-test.out ".claude/skills/spectra-commit/SKILL.md"
assert_contains /tmp/spectra-plus-repair-test.out ".agents/skills/spectra-commit/SKILL.md"

echo "PASS: repair-all checks"
