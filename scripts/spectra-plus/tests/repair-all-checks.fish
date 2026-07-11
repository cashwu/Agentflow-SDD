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
set plus_version (yq -r '.skills."spectra-propose-plus".metadata.spectraPlusVersion' "$rules")
set plus_updated (yq -r '.skills."spectra-propose-plus".metadata.spectraPlusUpdated' "$rules")

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
        /^function file_has --argument-names path text$/ {
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
    set real_generator "$source/scripts/spectra-plus/generate.real.fish"
    command mv "$generator" "$real_generator"
    printf '%s\n' \
        '#!/usr/bin/env -S fish --no-config' \
        'set real_generator (dirname (status --current-filename))/generate.real.fish' \
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
        'end' \
        'exec "$real_generator" $args' > "$generator"
    chmod +x "$generator" "$real_generator"
    git -C "$source" add scripts/spectra-plus/generate.fish scripts/spectra-plus/generate.real.fish
    git -C "$source" commit -qm "install fingerprint query test stub"
end
