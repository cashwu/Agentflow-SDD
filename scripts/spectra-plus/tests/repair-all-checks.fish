#!/usr/bin/env fish

set script_path (status --current-filename)
set test_dir (dirname "$script_path")
set original_root_dir (realpath "$test_dir/../../..")
set root_dir "$original_root_dir"
set installer "$root_dir/install-spectra-plus.fish"
set entrypoint "$root_dir/scripts/spectra-plus/repair-all.fish"
set rules "$root_dir/scripts/spectra-plus/rules.yaml"
set guard_marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"
set agent_label "com.spectra.plus.repair"
set legacy_agent_label "com.agentflow.spectra-plus.repair"
set plus_version "1.5.0"
set plus_updated "2026-07-16"

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function fish_command_not_found
    fail "unknown test command: $argv[1]"
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

function frontmatter_value --argument-names path field
    awk -v field="$field" '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { exit }
        in_fm && $0 ~ "^  " field ": " {
            print substr($0, length(field) + 5)
            exit
        }
    ' "$path"
end

function assert_target_fingerprints_match_query --argument-names source target
    set query_rows ("$source/scripts/spectra-plus/generate.fish" --root "$target" --fingerprints)
    test $status -eq 0; or fail "fingerprint query failed for $target"
    test (count $query_rows) -eq 4; or fail "fingerprint query did not return four rows for $target"

    for row in $query_rows
        set fields (string split (printf '\t') -- "$row")
        test (count $fields) -eq 3; or fail "malformed fingerprint query row: $row"
        set skill $fields[1]
        set variant $fields[2]
        set expected $fields[3]
        switch "$variant"
            case claude
                set output "$target/.claude/skills/$skill/SKILL.md"
            case codex
                set output "$target/.agents/skills/$skill/SKILL.md"
            case '*'
                fail "unknown fingerprint variant: $variant"
        end
        set actual (frontmatter_value "$output" spectraPlusFingerprint)
        test "$actual" = "$expected"; or fail "$output fingerprint $actual did not match expected $expected"
    end
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
            stat -f 'mode %Lp' "$path" 2>/dev/null; or stat -c 'mode %a' "$path"
        else
            echo "missing $path"
        end
    end
    for path in "$target/.agents/skills/spectra-commit/SKILL.md" "$target/.claude/skills/spectra-commit/SKILL.md"
        if test -f "$path"
            cksum "$path"
            stat -f 'mode %Lp' "$path" 2>/dev/null; or stat -c 'mode %a' "$path"
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

function force_worktree_current_check_stale --argument-names path
    set rewritten (mktemp /tmp/spectra-plus-current-check.XXXXXX)
    awk '
        /^function target_is_current --argument-names target_path$/ {
            print
            print "    return 1"
            next
        }
        { print }
    ' "$path" > "$rewritten"
    command mv -f "$rewritten" "$path"
    chmod +x "$path"
end

function force_worktree_current_assertion_error --argument-names path
    set rewritten (mktemp /tmp/spectra-plus-current-error.XXXXXX)
    awk '
        /^function plus_outputs_are_current --argument-names target_path$/ {
            print
            print "    return 44"
            next
        }
        { print }
    ' "$path" > "$rewritten"
    command mv -f "$rewritten" "$path"
    chmod +x "$path"
end

function make_home
    mktemp -d /tmp/spectra-plus-home.XXXXXX
end

function make_run_dir
    mktemp -d /tmp/spectra-plus-run.XXXXXX
end

function assert_no_snapshots --argument-names run_dir context
    set snapshots (find "$run_dir" -maxdepth 1 -type d -name 'spectra-plus-snapshot.*' -print)
    test -z "$snapshots"; or fail "$context left snapshot: $snapshots"
end

function write_check_current_error_stub --argument-names path
    printf '%s\n' \
        '#!/usr/bin/env fish' \
        'if set -q __spectra_plus_repair_snapshot; and test -n "$__spectra_plus_repair_snapshot"' \
        '    echo "leaked snapshot ownership: $__spectra_plus_repair_snapshot" >&2' \
        '    exit 46' \
        'end' \
        'if test "$argv[1]" = --check-current' \
        '    echo "$argv[2]" >> "$SPECTRA_PLUS_TEST_CHECK_LOG"' \
        '    if test "$argv[2]" = "$SPECTRA_PLUS_TEST_ERROR_TARGET"' \
        '        echo "forced current-state failure" >&2' \
        '        exit 42' \
        '    end' \
        '    if test "$argv[2]" = "$SPECTRA_PLUS_TEST_STALE_TARGET"' \
        '        exit 10' \
        '    end' \
        '    exit 0' \
        'end' \
        'echo "$argv[2]" >> "$SPECTRA_PLUS_TEST_DELEGATION_LOG"' \
        'exit 0' > "$path"
    chmod +x "$path"
end

function make_snapshot_cleanup_failure_stub --argument-names dir
    mkdir -p "$dir"
    set real_rm (command -s rm)
    printf '%s\n' \
        '#!/usr/bin/env fish' \
        "set real_rm "(string escape -- "$real_rm") \
        'for arg in $argv' \
        '    if test -d "$arg"; and string match -q "spectra-plus-snapshot.*" -- (basename "$arg")' \
        '        echo "forced snapshot cleanup failure" >&2' \
        '        exit 45' \
        '    end' \
        'end' \
        'command "$real_rm" $argv' > "$dir/rm"
    chmod +x "$dir/rm"
end

function make_tar_failure_stub --argument-names dir
    mkdir -p "$dir"
    printf '%s\n' \
        '#!/usr/bin/env fish' \
        'echo "forced tar failure" >&2' \
        'exit 44' > "$dir/tar"
    chmod +x "$dir/tar"
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
    git -C "$fixture" config commit.gpgsign false
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
        assert_frontmatter_contains "$path" "  spectraPlusVersion: $plus_version"
        assert_frontmatter_contains "$path" "  spectraPlusUpdated: $plus_updated"
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

function install_query_stub --argument-names source
    set generator "$source/scripts/spectra-plus/generate.fish"
    set real_generator (mktemp /tmp/spectra-plus-real-generator.XXXXXX)
    command mv "$generator" "$real_generator"
    printf '%s\n' \
        '#!/usr/bin/env -S fish --no-config' \
        'set target ""' \
        'set args $argv' \
        'for index in (seq 1 (count $args))' \
        '    if test "$args[$index]" = --root; and test $index -lt (count $args)' \
        '        set next_index (math $index + 1)' \
        '        set target (realpath "$args[$next_index]")' \
        '    end' \
        'end' \
        'if contains -- --fingerprints $args' \
        '    if set -q SPECTRA_PLUS_TEST_GENERATOR_LOG' \
        '        echo "query $target" >> "$SPECTRA_PLUS_TEST_GENERATOR_LOG"' \
        '    end' \
        '    if not set -q SPECTRA_PLUS_TEST_BAD_TARGET; or test "$target" = (realpath "$SPECTRA_PLUS_TEST_BAD_TARGET")' \
        '        switch "$SPECTRA_PLUS_TEST_QUERY_MODE"' \
        '            case wrong-field' \
        '                printf "spectra-apply-plus\\tclaude\\n"' \
        '                printf "spectra-apply-plus\\tcodex\\t2\\n"' \
        '                printf "spectra-propose-plus\\tclaude\\t3\\n"' \
        '                printf "spectra-propose-plus\\tcodex\\t4\\n"' \
        '                exit 0' \
        '            case unknown' \
        '                printf "spectra-unknown-plus\\tclaude\\t1\\n"' \
        '                printf "spectra-apply-plus\\tcodex\\t2\\n"' \
        '                printf "spectra-propose-plus\\tclaude\\t3\\n"' \
        '                printf "spectra-propose-plus\\tcodex\\t4\\n"' \
        '                exit 0' \
        '            case nondecimal' \
        '                printf "spectra-apply-plus\\tclaude\\t12x\\n"' \
        '                printf "spectra-apply-plus\\tcodex\\t2\\n"' \
        '                printf "spectra-propose-plus\\tclaude\\t3\\n"' \
        '                printf "spectra-propose-plus\\tcodex\\t4\\n"' \
        '                exit 0' \
        '            case duplicate' \
        '                printf "spectra-apply-plus\\tclaude\\t1\\n"' \
        '                printf "spectra-apply-plus\\tclaude\\t2\\n"' \
        '                printf "spectra-propose-plus\\tclaude\\t3\\n"' \
        '                printf "spectra-propose-plus\\tcodex\\t4\\n"' \
        '                exit 0' \
        '            case missing' \
        '                printf "spectra-apply-plus\\tclaude\\t1\\n"' \
        '                printf "spectra-apply-plus\\tcodex\\t2\\n"' \
        '                printf "spectra-propose-plus\\tclaude\\t3\\n"' \
        '                exit 0' \
        '            case out-of-order' \
        '                printf "spectra-apply-plus\\tcodex\\t2\\n"' \
        '                printf "spectra-apply-plus\\tclaude\\t1\\n"' \
        '                printf "spectra-propose-plus\\tclaude\\t3\\n"' \
        '                printf "spectra-propose-plus\\tcodex\\t4\\n"' \
        '                exit 0' \
        '            case nonzero' \
        '                echo "injected fingerprint query failure" >&2' \
        '                exit 9' \
        '        end' \
        '    end' \
        'else if set -q SPECTRA_PLUS_TEST_GENERATOR_LOG' \
        '    echo "generate $target" >> "$SPECTRA_PLUS_TEST_GENERATOR_LOG"' \
        'end' > "$generator"
    command cat "$real_generator" >> "$generator"
    command rm -f "$real_generator"
    chmod +x "$generator"
    git -C "$source" add scripts/spectra-plus/generate.fish
    git -C "$source" -c commit.gpgsign=false commit -qm "install fingerprint query test stub"
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
set pinned_home (make_home)
set pinned_run (make_run_dir)
set pinned_target (mktemp -d /tmp/spectra-plus-pinned-target.XXXXXX)
make_target "$pinned_target"
strip_guard "$pinned_target/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 env HOME="$pinned_home" TMPDIR="$pinned_run" "$installer" --register-target "$pinned_target"
printf '\n# uncommitted installer\n' >> "$installer"
printf '\nnot: [valid\n' >> "$rules"
replace_in_file "$root_dir/scripts/spectra-plus/template/review-loop-block.md" "10. **Sub-Agent Review/Rating/Fix Loop**" "10. **UNCOMMITTED_TEMPLATE**"
replace_in_file "$root_dir/.agents/skills/spectra-commit/SKILL.md" "$guard_marker" "<!-- UNCOMMITTED_GUARD_SOURCE -->"
printf '\n# uncommitted base skill\n' >> "$root_dir/.agents/skills/spectra-propose/SKILL.md"
set dirty_guard_before (cksum "$root_dir/.agents/skills/spectra-commit/SKILL.md")
run_expect 0 env HOME="$pinned_home" TMPDIR="$pinned_run" "$installer" --repair-all --force
assert_not_contains /tmp/spectra-plus-repair-test.out "dirty source checkout"
assert_plus_outputs "$pinned_target"
assert_not_contains "$pinned_target/.agents/skills/spectra-propose-plus/SKILL.md" "UNCOMMITTED_TEMPLATE"
assert_not_contains "$pinned_target/.agents/skills/spectra-commit/SKILL.md" "UNCOMMITTED_GUARD_SOURCE"
test "$dirty_guard_before" = (cksum "$root_dir/.agents/skills/spectra-commit/SKILL.md"); or fail "repair-all rewrote unregistered working-tree guard source"
assert_no_snapshots "$pinned_run" "dirty pinned-input repair"
reset_source_fixture

set converge_home (make_home)
set converge_run (make_run_dir)
set converge_target (mktemp -d /tmp/spectra-plus-converge-target.XXXXXX)
make_target "$converge_target"
run_expect 0 env HOME="$converge_home" TMPDIR="$converge_run" "$installer" --register-target "$converge_target"
run_expect 0 env HOME="$converge_home" TMPDIR="$converge_run" "$installer" --repair-all --force
assert_plus_outputs "$converge_target"
set converge_before (target_plus_fingerprint "$converge_target" | string collect)
force_worktree_current_check_stale "$installer"
run_expect 0 env HOME="$converge_home" TMPDIR="$converge_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "already current"
assert_not_contains /tmp/spectra-plus-repair-test.out "[success]"
test "$converge_before" = (target_plus_fingerprint "$converge_target" | string collect); or fail "second repair-all rewrote current target"
assert_no_snapshots "$converge_run" "converged repair"
reset_source_fixture

set check_home (make_home)
set check_run (make_run_dir)
set check_current_target (mktemp -d /tmp/spectra-plus-check-current.XXXXXX)
set check_stale_target (mktemp -d /tmp/spectra-plus-check-stale.XXXXXX)
make_target "$check_current_target"
make_target "$check_stale_target"
run_expect 0 "$installer" --target "$check_current_target"
set check_current_before (target_plus_fingerprint "$check_current_target" | string collect)
set check_stale_before (target_plus_fingerprint "$check_stale_target" | string collect)
run_expect 0 env HOME="$check_home" TMPDIR="$check_run" "$installer" --check-current "$check_current_target"
run_expect 10 env HOME="$check_home" TMPDIR="$check_run" "$installer" --check-current "$check_stale_target"
run_expect 1 "$installer" --check-current .
run_expect 1 "$installer" --check-current "/tmp/spectra-plus-missing-check-$fish_pid"
run_expect 1 "$installer" --check-current "$check_current_target" "$check_stale_target"
run_expect 1 "$installer" --repair-all --check-current "$check_current_target"
test "$check_current_before" = (target_plus_fingerprint "$check_current_target" | string collect); or fail "current check modified current target"
test "$check_stale_before" = (target_plus_fingerprint "$check_stale_target" | string collect); or fail "current check modified stale target"
test ! -e "$check_home/.cache/spectra-plus"; or fail "current check wrote cache state"
test ! -e "$check_run/spectra-plus-repair.lock"; or fail "current check wrote repair lock"

set checker_error_home (make_home)
set checker_error_run (make_run_dir)
set checker_error_target (mktemp -d /tmp/spectra-plus-checker-error.XXXXXX)
make_target "$checker_error_target"
set checker_error_backup (mktemp /tmp/spectra-plus-checker-backup.XXXXXX)
command cp -f "$installer" "$checker_error_backup"
force_worktree_current_assertion_error "$installer"
commit_source_fixture "pin current assertion error"
command cp -f "$checker_error_backup" "$installer"
chmod +x "$installer"
run_expect 0 env HOME="$checker_error_home" TMPDIR="$checker_error_run" "$installer" --register-target "$checker_error_target"
run_expect 1 env HOME="$checker_error_home" TMPDIR="$checker_error_run" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "current state check failed (exit 44)"
test ! -e "$checker_error_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "checker execution error delegated installation"
test -f "$checker_error_home/.cache/spectra-plus/last-repair-attempt"; or fail "checker execution error changed throttle semantics"
test ! -e "$checker_error_run/spectra-plus-repair.lock"; or fail "checker execution error leaked repair lock"
assert_no_snapshots "$checker_error_run" "checker execution error"
commit_source_fixture "restore current assertion behavior"

set current_error_backup (mktemp /tmp/spectra-plus-installer-backup.XXXXXX)
command cp -f "$installer" "$current_error_backup"
write_check_current_error_stub "$installer"
commit_source_fixture "pin current-state error stub"
command cp -f "$current_error_backup" "$installer"
chmod +x "$installer"
set current_error_home (make_home)
set current_error_run (make_run_dir)
set current_error_target (mktemp -d /tmp/spectra-plus-current-error.XXXXXX)
set current_stale_target (mktemp -d /tmp/spectra-plus-current-stale.XXXXXX)
set current_ok_target (mktemp -d /tmp/spectra-plus-current-ok.XXXXXX)
set current_error_log /tmp/spectra-plus-current-error-delegation.log
set current_check_log /tmp/spectra-plus-current-error-check.log
command rm -f "$current_error_log" "$current_check_log"
make_target "$current_error_target"
make_target "$current_stale_target"
make_target "$current_ok_target"
mkdir -p (dirname (registry_path "$current_error_home"))
printf '%s\n' "$current_error_target" "$current_stale_target" "$current_ok_target" > (registry_path "$current_error_home")
run_expect 1 env HOME="$current_error_home" TMPDIR="$current_error_run" __spectra_plus_repair_snapshot="inherited-exported-value" SPECTRA_PLUS_TEST_ERROR_TARGET="$current_error_target" SPECTRA_PLUS_TEST_STALE_TARGET="$current_stale_target" SPECTRA_PLUS_TEST_CHECK_LOG="$current_check_log" SPECTRA_PLUS_TEST_DELEGATION_LOG="$current_error_log" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "[failed]"
assert_not_contains /tmp/spectra-plus-repair-test.err "leaked snapshot ownership"
assert_contains /tmp/spectra-plus-repair-test.out "$current_ok_target: already current"
assert_contains "$current_check_log" "$current_error_target"
assert_contains "$current_check_log" "$current_stale_target"
assert_contains "$current_check_log" "$current_ok_target"
assert_contains "$current_error_log" "$current_stale_target"
assert_not_contains "$current_error_log" "$current_error_target"
test ! -e "$current_error_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail "current-state error modified target"
test -f "$current_error_home/.cache/spectra-plus/last-repair-attempt"; or fail "current-state error changed throttle semantics"
test ! -e "$current_error_run/spectra-plus-repair.lock"; or fail "current-state error leaked repair lock"
assert_no_snapshots "$current_error_run" "current-state error"

set current_dry_home (make_home)
set current_dry_run (make_run_dir)
set current_dry_log /tmp/spectra-plus-current-dry-delegation.log
set current_dry_check_log /tmp/spectra-plus-current-dry-check.log
command rm -f "$current_dry_log" "$current_dry_check_log"
mkdir -p (dirname (registry_path "$current_dry_home"))
printf '%s\n' "$current_error_target" "$current_stale_target" "$current_ok_target" > (registry_path "$current_dry_home")
set current_dry_registry_before (cksum (registry_path "$current_dry_home"))
run_expect 1 env HOME="$current_dry_home" TMPDIR="$current_dry_run" SPECTRA_PLUS_TEST_ERROR_TARGET="$current_error_target" SPECTRA_PLUS_TEST_STALE_TARGET="$current_stale_target" SPECTRA_PLUS_TEST_CHECK_LOG="$current_dry_check_log" SPECTRA_PLUS_TEST_DELEGATION_LOG="$current_dry_log" "$installer" --repair-all --dry-run
assert_contains /tmp/spectra-plus-repair-test.out "[failed]"
assert_contains /tmp/spectra-plus-repair-test.out "[would repair]"
assert_contains /tmp/spectra-plus-repair-test.out "already current"
test ! -e "$current_dry_log"; or fail "dry-run current-state check delegated installation"
test "$current_dry_registry_before" = (cksum (registry_path "$current_dry_home")); or fail "dry-run current-state error modified registry"
test ! -e "$current_dry_home/.cache/spectra-plus"; or fail "dry-run current-state error wrote cache"
test ! -e "$current_dry_run/spectra-plus-repair.lock"; or fail "dry-run current-state error wrote lock"
assert_no_snapshots "$current_dry_run" "dry-run current-state error"
commit_source_fixture "restore installer after current-state error"

set manual_dirty_target (mktemp -d /tmp/spectra-plus-manual-dirty.XXXXXX)
make_target "$manual_dirty_target"
printf '\n# dirty source\n' >> "$root_dir/install-spectra-plus.fish"
run_expect 0 "$installer" --target "$manual_dirty_target"
assert_plus_outputs "$manual_dirty_target"
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

set create_fail_home (make_home)
set create_fail_tmp (mktemp /tmp/spectra-plus-blocked-tmp.XXXXXX)
set create_fail_target (mktemp -d /tmp/spectra-plus-create-fail-target.XXXXXX)
make_target "$create_fail_target"
set create_fail_before (target_plus_fingerprint "$create_fail_target" | string collect)
mkdir -p (dirname (registry_path "$create_fail_home"))
printf '%s\n' "$create_fail_target" > (registry_path "$create_fail_home")
run_expect 1 env HOME="$create_fail_home" TMPDIR="$create_fail_tmp" "$installer" --repair-all --force
test "$create_fail_before" = (target_plus_fingerprint "$create_fail_target" | string collect); or fail "snapshot creation failure modified target"
test ! -e "$create_fail_home/.cache/spectra-plus/last-repair-attempt"; or fail "snapshot creation failure wrote throttle state"

set archive_backup (mktemp -d /tmp/spectra-plus-template-backup.XXXXXX)
command cp -R "$root_dir/scripts/spectra-plus/template" "$archive_backup/"
command rm -rf "$root_dir/scripts/spectra-plus/template"
commit_source_fixture "pin missing snapshot input"
command cp -R "$archive_backup/template" "$root_dir/scripts/spectra-plus/"
set archive_fail_home (make_home)
set archive_fail_run (make_run_dir)
set archive_fail_target (mktemp -d /tmp/spectra-plus-archive-fail-target.XXXXXX)
make_target "$archive_fail_target"
set archive_fail_before (target_plus_fingerprint "$archive_fail_target" | string collect)
mkdir -p (dirname (registry_path "$archive_fail_home"))
printf '%s\n' "$archive_fail_target" > (registry_path "$archive_fail_home")
run_expect 1 env HOME="$archive_fail_home" TMPDIR="$archive_fail_run" "$installer" --repair-all --force
test "$archive_fail_before" = (target_plus_fingerprint "$archive_fail_target" | string collect); or fail "snapshot archive failure modified target"
test ! -e "$archive_fail_home/.cache/spectra-plus/last-repair-attempt"; or fail "snapshot archive failure wrote throttle state"
test ! -e "$archive_fail_run/spectra-plus-repair.lock"; or fail "snapshot archive failure wrote repair lock"
assert_no_snapshots "$archive_fail_run" "snapshot archive failure"
commit_source_fixture "restore snapshot template input"

set extract_fail_home (make_home)
set extract_fail_run (make_run_dir)
set extract_fail_target (mktemp -d /tmp/spectra-plus-extract-fail-target.XXXXXX)
set tar_fail_bin (mktemp -d /tmp/spectra-plus-tar-fail.XXXXXX)
make_target "$extract_fail_target"
make_tar_failure_stub "$tar_fail_bin"
set extract_fail_before (target_plus_fingerprint "$extract_fail_target" | string collect)
mkdir -p (dirname (registry_path "$extract_fail_home"))
printf '%s\n' "$extract_fail_target" > (registry_path "$extract_fail_home")
run_expect 1 env HOME="$extract_fail_home" TMPDIR="$extract_fail_run" PATH="$tar_fail_bin:$PATH" "$installer" --repair-all --force
test "$extract_fail_before" = (target_plus_fingerprint "$extract_fail_target" | string collect); or fail "snapshot extraction failure modified target"
test ! -e "$extract_fail_home/.cache/spectra-plus/last-repair-attempt"; or fail "snapshot extraction failure wrote throttle state"
test ! -e "$extract_fail_run/spectra-plus-repair.lock"; or fail "snapshot extraction failure wrote repair lock"
assert_no_snapshots "$extract_fail_run" "snapshot extraction failure"

set combined_fail_home (make_home)
set combined_fail_run (make_run_dir)
set combined_fail_target (mktemp -d /tmp/spectra-plus-combined-fail-target.XXXXXX)
set combined_fail_bin (mktemp -d /tmp/spectra-plus-combined-fail-bin.XXXXXX)
make_target "$combined_fail_target"
make_tar_failure_stub "$combined_fail_bin"
make_snapshot_cleanup_failure_stub "$combined_fail_bin"
set combined_fail_before (target_plus_fingerprint "$combined_fail_target" | string collect)
mkdir -p (dirname (registry_path "$combined_fail_home"))
printf '%s\n' "$combined_fail_target" > (registry_path "$combined_fail_home")
run_expect 1 env HOME="$combined_fail_home" TMPDIR="$combined_fail_run" PATH="$combined_fail_bin:$PATH" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.err "forced tar failure"
assert_contains /tmp/spectra-plus-repair-test.err "無法清理 repair-all pinned snapshot"
test "$combined_fail_before" = (target_plus_fingerprint "$combined_fail_target" | string collect); or fail "combined snapshot failure modified target"
test ! -e "$combined_fail_home/.cache/spectra-plus/last-repair-attempt"; or fail "combined snapshot failure wrote throttle state"
test ! -e "$combined_fail_run/spectra-plus-repair.lock"; or fail "combined snapshot failure wrote repair lock"
set combined_leaks (find "$combined_fail_run" -maxdepth 1 -type d -name 'spectra-plus-snapshot.*' -print)
test (count $combined_leaks) -eq 1; or fail "combined snapshot cleanup failure did not preserve owned snapshot"
/bin/rm -rf -- $combined_leaks

set cleanup_fail_home (make_home)
set cleanup_fail_run (make_run_dir)
set cleanup_fail_target (mktemp -d /tmp/spectra-plus-cleanup-fail-target.XXXXXX)
set cleanup_fail_bin (mktemp -d /tmp/spectra-plus-rm-fail.XXXXXX)
make_target "$cleanup_fail_target"
run_expect 0 "$installer" --target "$cleanup_fail_target"
run_expect 0 env HOME="$cleanup_fail_home" TMPDIR="$cleanup_fail_run" "$installer" --register-target "$cleanup_fail_target"
make_snapshot_cleanup_failure_stub "$cleanup_fail_bin"
run_expect 1 env HOME="$cleanup_fail_home" TMPDIR="$cleanup_fail_run" PATH="$cleanup_fail_bin:$PATH" "$installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.err "無法清理 repair-all pinned snapshot"
test ! -e "$cleanup_fail_run/spectra-plus-repair.lock"; or fail "snapshot cleanup failure leaked repair lock"
set cleanup_leaks (find "$cleanup_fail_run" -maxdepth 1 -type d -name 'spectra-plus-snapshot.*' -print)
test (count $cleanup_leaks) -eq 1; or fail "snapshot cleanup failure did not preserve exactly one owned snapshot"
/bin/rm -rf -- $cleanup_leaks

set nongit_source (make_clean_source_fixture "$root_dir")
command rm -rf "$nongit_source/.git"
set nongit_installer "$nongit_source/install-spectra-plus.fish"
set nongit_home (make_home)
set nongit_run (make_run_dir)
set nongit_target (mktemp -d /tmp/spectra-plus-nongit-target.XXXXXX)
make_target "$nongit_target"
set nongit_before (target_plus_fingerprint "$nongit_target" | string collect)
mkdir -p (dirname (registry_path "$nongit_home"))
printf '%s\n' "$nongit_target" > (registry_path "$nongit_home")
run_expect 1 env HOME="$nongit_home" TMPDIR="$nongit_run" "$nongit_installer" --repair-all --force
test "$nongit_before" = (target_plus_fingerprint "$nongit_target" | string collect); or fail "non-git source modified target"
test ! -e "$nongit_home/.cache/spectra-plus/last-repair-attempt"; or fail "non-git source wrote throttle state"
test ! -e "$nongit_run/spectra-plus-repair.lock"; or fail "non-git source wrote repair lock"
assert_no_snapshots "$nongit_run" "non-git source"
reset_source_fixture

set repair_home (make_home)
set repair_run (make_run_dir)
set repair_a (mktemp -d /tmp/spectra-plus-repair-a.XXXXXX)
set repair_b (mktemp -d /tmp/spectra-plus-repair-b.XXXXXX)
set repair_stale_plus (mktemp -d /tmp/spectra-plus-repair-stale-plus.XXXXXX)
set repair_stale_version (mktemp -d /tmp/spectra-plus-repair-stale-version.XXXXXX)
set repair_stale_updated (mktemp -d /tmp/spectra-plus-repair-stale-updated.XXXXXX)
set repair_missing_metadata (mktemp -d /tmp/spectra-plus-repair-missing-metadata.XXXXXX)
set repair_missing_fingerprint (mktemp -d /tmp/spectra-plus-repair-missing-fingerprint.XXXXXX)
set repair_changed_base (mktemp -d /tmp/spectra-plus-repair-changed-base.XXXXXX)
set repair_single_stale (mktemp -d /tmp/spectra-plus-repair-single-stale.XXXXXX)
make_target "$repair_a"
make_target "$repair_b"
make_target "$repair_stale_plus"
make_target "$repair_stale_version"
make_target "$repair_stale_updated"
make_target "$repair_missing_metadata"
make_target "$repair_missing_fingerprint"
make_target "$repair_changed_base"
make_target "$repair_single_stale"
run_expect 0 "$installer" --target "$repair_stale_plus"
run_expect 0 "$installer" --target "$repair_stale_version"
run_expect 0 "$installer" --target "$repair_stale_updated"
run_expect 0 "$installer" --target "$repair_missing_metadata"
run_expect 0 "$installer" --target "$repair_missing_fingerprint"
run_expect 0 "$installer" --target "$repair_changed_base"
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
    awk -v version_line="  spectraPlusVersion: $plus_version" -v updated_line="  spectraPlusUpdated: $plus_updated" '$0 != version_line && $0 != updated_line { print }' "$path" > "$stripped"
    command mv -f "$stripped" "$path"
end
set no_fingerprint (mktemp /tmp/spectra-plus-fingerprint-strip.XXXXXX)
awk '$0 !~ /^  spectraPlusFingerprint: / { print }' "$repair_missing_fingerprint/.agents/skills/spectra-propose-plus/SKILL.md" > "$no_fingerprint"
command mv -f "$no_fingerprint" "$repair_missing_fingerprint/.agents/skills/spectra-propose-plus/SKILL.md"
printf '\n# target-local base input changed without metadata bump\n' >> "$repair_changed_base/.agents/skills/spectra-propose/SKILL.md"
replace_in_file "$repair_single_stale/.agents/skills/spectra-propose-plus/SKILL.md" "spectraPlusVersion: $plus_version" "spectraPlusVersion: 1.0.0"
strip_guard "$repair_b/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_a"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_b"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_stale_plus"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_stale_version"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_stale_updated"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_missing_metadata"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_missing_fingerprint"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_changed_base"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_single_stale"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --repair-all --force
assert_plus_outputs "$repair_a"
assert_plus_outputs "$repair_b"
assert_plus_outputs "$repair_stale_plus"
assert_plus_outputs "$repair_stale_version"
assert_plus_outputs "$repair_stale_updated"
assert_plus_outputs "$repair_missing_metadata"
assert_plus_outputs "$repair_missing_fingerprint"
assert_plus_outputs "$repair_changed_base"
assert_plus_outputs "$repair_single_stale"
for repaired_target in "$repair_a" "$repair_b" "$repair_stale_plus" "$repair_stale_version" "$repair_stale_updated" "$repair_missing_metadata" "$repair_missing_fingerprint" "$repair_changed_base" "$repair_single_stale"
    assert_target_fingerprints_match_query "$root_dir" "$repaired_target"
end

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
test ! -e "$bad_rules_home/.cache/spectra-plus/last-repair-attempt"; or fail "bad pinned rules wrote throttle state"
test ! -e "$bad_rules_run/spectra-plus-repair.lock"; or fail "bad pinned rules wrote repair lock"
assert_no_snapshots "$bad_rules_run" "bad pinned rules"
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

set query_source (make_clean_source_fixture "$root_dir")
install_query_stub "$query_source"
set query_installer "$query_source/install-spectra-plus.fish"
set query_home (make_home)
set query_run (make_run_dir)
set query_bad_target (mktemp -d /tmp/spectra-plus-query-bad.XXXXXX)
set query_good_target (mktemp -d /tmp/spectra-plus-query-good.XXXXXX)
set saved_root_dir "$root_dir"
set root_dir "$query_source"
make_target "$query_bad_target"
make_target "$query_good_target"
run_expect 0 "$query_installer" --target "$query_bad_target"
set root_dir "$saved_root_dir"
set query_bad_before (target_plus_fingerprint "$query_bad_target" | string collect)
for query_mode in wrong-field unknown nondecimal duplicate missing out-of-order nonzero
    run_expect 2 env SPECTRA_PLUS_TEST_BAD_TARGET="$query_bad_target" SPECTRA_PLUS_TEST_QUERY_MODE="$query_mode" "$query_installer" --check-current "$query_bad_target"
    test "$query_bad_before" = (target_plus_fingerprint "$query_bad_target" | string collect); or fail "fingerprint protocol $query_mode modified target"
end
mkdir -p (dirname (registry_path "$query_home"))
printf '%s\n' "$query_bad_target" "$query_good_target" > (registry_path "$query_home")
set query_log /tmp/spectra-plus-query.log
command rm -f "$query_log"
run_expect 1 env HOME="$query_home" TMPDIR="$query_run" SPECTRA_PLUS_TEST_BAD_TARGET="$query_bad_target" SPECTRA_PLUS_TEST_QUERY_MODE=nonzero SPECTRA_PLUS_TEST_GENERATOR_LOG="$query_log" "$query_installer" --repair-all --force
assert_contains /tmp/spectra-plus-repair-test.out "$query_bad_target: expected fingerprint unavailable"
assert_contains /tmp/spectra-plus-repair-test.out "$query_good_target: repaired"
test "$query_bad_before" = (target_plus_fingerprint "$query_bad_target" | string collect); or fail "unavailable fingerprint target was modified"
set root_dir "$query_source"
assert_plus_outputs "$query_good_target"
assert_target_fingerprints_match_query "$query_source" "$query_good_target"
set root_dir "$saved_root_dir"
assert_contains "$query_log" "query "(realpath "$query_bad_target")
assert_contains "$query_log" "query "(realpath "$query_good_target")
assert_contains "$query_log" "generate "(realpath "$query_good_target")
assert_not_contains "$query_log" "generate "(realpath "$query_bad_target")
assert_no_snapshots "$query_run" "fingerprint unavailable batch"

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
printf '%s\n' '#!/bin/sh' 'echo "錯誤：找不到必要指令：yq" >&2' 'exit 127' > "$fish_only_bin/yq"
chmod +x "$fish_only_bin/yq"
set missing_yq_home (make_home)
set missing_yq_run (make_run_dir)
set missing_yq_target (mktemp -d /tmp/spectra-plus-missing-yq.XXXXXX)
make_target "$missing_yq_target"
mkdir -p (dirname (registry_path "$missing_yq_home"))
printf '%s\n' "$missing_yq_target" > (registry_path "$missing_yq_home")
set missing_yq_before (target_plus_fingerprint "$missing_yq_target" | string collect)
reset_source_fixture
printf '\n# dirty source\n' >> "$root_dir/scripts/spectra-plus/generate.fish"
run_expect 1 env HOME="$missing_yq_home" TMPDIR="$missing_yq_run" fish_user_paths="" PATH="$fish_only_bin:/usr/bin:/bin" "$fish_bin" --no-config "$entrypoint" --force
assert_contains /tmp/spectra-plus-repair-test.err "找不到必要指令：yq"
test "$missing_yq_before" = (target_plus_fingerprint "$missing_yq_target" | string collect); or fail "missing yq modified registered target"
test ! -e "$missing_yq_home/.cache/spectra-plus/last-repair-attempt"; or fail "missing yq wrote throttle state"
test ! -e "$missing_yq_run/spectra-plus-repair.lock"; or fail "missing yq wrote repair lock"
assert_no_snapshots "$missing_yq_run" "missing yq"
reset_source_fixture

set dirty_entry_home (make_home)
set dirty_entry_run (make_run_dir)
set dirty_entry_target (mktemp -d /tmp/spectra-plus-dirty-entry.XXXXXX)
make_target "$dirty_entry_target"
mkdir -p (dirname (registry_path "$dirty_entry_home"))
printf '%s\n' "$dirty_entry_target" > (registry_path "$dirty_entry_home")
printf '\n# parseable dirty entrypoint\n' >> "$entrypoint"
run_expect 0 env HOME="$dirty_entry_home" TMPDIR="$dirty_entry_run" "$entrypoint" --force
assert_plus_outputs "$dirty_entry_target"
assert_contains /tmp/spectra-plus-repair-test.out "[success]"
assert_no_snapshots "$dirty_entry_run" "parseable dirty entrypoint"
reset_source_fixture

set agent_home (mktemp -d "/tmp/spectra-plus-agent-&-home.XXXXXX")
set agent_run (make_run_dir)
set launch_stub (mktemp -d /tmp/spectra-plus-launchctl.XXXXXX)
set launch_log "$agent_home/launchctl.log"
make_launchctl_stub "$launch_stub" ok
mkdir -p "$agent_home/Library/LaunchAgents"
set legacy_plist "$agent_home/Library/LaunchAgents/$legacy_agent_label.plist"
printf '%s\n' "legacy" > "$legacy_plist"
run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --install-launch-agent
set plist "$agent_home/Library/LaunchAgents/$agent_label.plist"
test ! -e "$legacy_plist"; or fail "install left deprecated LaunchAgent plist"
assert_contains "$plist" "$agent_label"
assert_contains "$plist" "$entrypoint"
assert_contains "$plist" "StartInterval"
assert_contains "$plist" "StandardOutPath"
test (rg --fixed-strings "<key>StandardOutPath</key>" "$plist" | wc -l | string trim) = 1; or fail "LaunchAgent plist duplicated StandardOutPath"
assert_not_contains "$plist" "/Applications/Spectra.app"
assert_contains "$plist" "spectra-plus-agent-&amp;-home"
set start_interval (awk '/<key>StartInterval<\/key>/ { getline; gsub(/[^0-9]/, ""); print; exit }' "$plist")
test "$start_interval" -ge 60; or fail "throttle window exceeds LaunchAgent StartInterval"
assert_contains "$launch_log" "bootstrap"
assert_contains "$launch_log" "$legacy_plist"
run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --install-launch-agent
test (rg --fixed-strings "$agent_label" "$plist" | wc -l | string trim) = 1; or fail "LaunchAgent plist duplicated label"

set fail_agent_home (make_home)
set fail_launch_log "$fail_agent_home/launchctl.log"
run_expect 1 env HOME="$fail_agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$fail_launch_log" LAUNCHCTL_MODE=fail "$installer" --install-launch-agent
assert_contains /tmp/spectra-plus-repair-test.err "manual activation"

printf '%s\n' "legacy" > "$legacy_plist"
run_expect 0 env HOME="$agent_home" TMPDIR="$agent_run" PATH="$launch_stub:$PATH" LAUNCHCTL_LOG="$launch_log" "$installer" --uninstall-launch-agent
test ! -e "$plist"; or fail "uninstall left LaunchAgent plist"
test ! -e "$legacy_plist"; or fail "uninstall left deprecated LaunchAgent plist"
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
set dry_legacy_plist "$dry_agent_home/Library/LaunchAgents/$legacy_agent_label.plist"
printf '%s\n' "sentinel" > "$dry_plist"
printf '%s\n' "legacy sentinel" > "$dry_legacy_plist"
set dry_plist_before (cksum "$dry_plist")
set dry_legacy_before (cksum "$dry_legacy_plist")
run_expect 0 env HOME="$dry_agent_home" TMPDIR="$dry_agent_run" PATH="$dry_launch_stub:$PATH" LAUNCHCTL_LOG="$dry_launch_log" "$installer" --install-launch-agent --dry-run
test "$dry_plist_before" = (cksum "$dry_plist"); or fail "install LaunchAgent dry-run modified plist"
test "$dry_legacy_before" = (cksum "$dry_legacy_plist"); or fail "install LaunchAgent dry-run modified legacy plist"
assert_contains /tmp/spectra-plus-repair-test.out "$dry_legacy_plist"
test ! -e "$dry_launch_log"; or fail "install LaunchAgent dry-run called launchctl"
run_expect 0 env HOME="$dry_agent_home" TMPDIR="$dry_agent_run" PATH="$dry_launch_stub:$PATH" LAUNCHCTL_LOG="$dry_launch_log" "$installer" --uninstall-launch-agent --dry-run
test "$dry_plist_before" = (cksum "$dry_plist"); or fail "uninstall LaunchAgent dry-run modified plist"
test "$dry_legacy_before" = (cksum "$dry_legacy_plist"); or fail "uninstall LaunchAgent dry-run modified legacy plist"
assert_contains /tmp/spectra-plus-repair-test.out "$dry_legacy_plist"
test ! -e "$dry_launch_log"; or fail "uninstall LaunchAgent dry-run called launchctl"

run_expect 0 "$installer" --help
assert_contains /tmp/spectra-plus-repair-test.out "--register-target"
assert_contains /tmp/spectra-plus-repair-test.out "--repair-all"
assert_contains /tmp/spectra-plus-repair-test.out "--install-launch-agent"
assert_contains /tmp/spectra-plus-repair-test.out "--force"
assert_contains /tmp/spectra-plus-repair-test.out ".claude/skills/spectra-commit/SKILL.md"
assert_contains /tmp/spectra-plus-repair-test.out ".agents/skills/spectra-commit/SKILL.md"

echo "PASS: repair-all checks"
