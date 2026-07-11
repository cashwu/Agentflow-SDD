#!/usr/bin/env fish

set script_path (status --current-filename)
set test_dir (dirname "$script_path")
set root_dir (realpath "$test_dir/../../..")
set installer "$root_dir/install-spectra-plus.fish"
set guard_marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"
set guard_marker_end "<!-- SPECTRA-COMMIT-GUARD:END -->"
set guard_insert_after '   From the full `git status --porcelain` output, any dirty files NOT in the artifact set and NOT in the tracking file are "unrelated changes."'
set user_start "6. **User confirmation**"
set subflow_start "6a. **Archive sub-flow**"
set archive_start "    **6a-iii. Archive execution and file collection**"
set archive_end "    Then continue to step 7."

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
    $command >/tmp/spectra-plus-installer-test.out 2>/tmp/spectra-plus-installer-test.err
    set actual $status
    test "$actual" -eq "$expected"; or begin
        cat /tmp/spectra-plus-installer-test.out
        cat /tmp/spectra-plus-installer-test.err >&2
        fail "expected exit $expected, got $actual: $command"
    end
end

function file_mode --argument-names path
    set mode (stat -f %Lp "$path" 2>/dev/null)
    if test -z "$mode"
        set mode (stat -c %a "$path" 2>/dev/null)
    end
    echo "$mode"
end

function snapshot_target --argument-names target
    set snapshot (mktemp -d /tmp/spectra-plus-structure-before.XXXXXX)
    command cp -R "$target/." "$snapshot/"
    echo "$snapshot"
end

function assert_target_unchanged --argument-names label target snapshot commit_path expected_mode
    diff -qr "$snapshot" "$target"; or fail "$label modified target bytes"
    test (file_mode "$commit_path") = "$expected_mode"; or fail "$label modified target mode"
end

function assert_commit_unchanged --argument-names label commit_path snapshot expected_mode
    cmp -s "$snapshot" "$commit_path"; or fail "$label modified target bytes"
    test (file_mode "$commit_path") = "$expected_mode"; or fail "$label modified target mode"
end

function guard_candidates --argument-names commit_path
    find (dirname "$commit_path") -maxdepth 1 -type f -name '.spectra-commit-guard-candidate.*' -print
end

function assert_no_guard_candidate --argument-names label commit_path
    set candidates (guard_candidates "$commit_path")
    test (count $candidates) -eq 0; or fail "$label left guard candidate: $candidates"
end

function make_stale_atomic_target --argument-names target
    make_current_target "$target"
    set commit_path "$target/.agents/skills/spectra-commit/SKILL.md"
    remove_anchor "$commit_path" "Do not treat the full post-archive dirty state as archive output."
    command chmod 640 "$commit_path"
end

function rewrite_file --argument-names path
    set rewritten (mktemp /tmp/spectra-plus-structure-rewrite.XXXXXX)
    awk $argv[2..-1] "$path" > "$rewritten"; or fail "cannot rewrite $path"
    command mv -f "$rewritten" "$path"
end

function remove_anchor --argument-names path anchor
    rewrite_file "$path" -v "anchor=$anchor" 'index($0, anchor) == 0 { print }'
end

function duplicate_anchor --argument-names path anchor
    rewrite_file "$path" -v "anchor=$anchor" '{ print; if (index($0, anchor)) print }'
end

function swap_anchors --argument-names path first second
    rewrite_file "$path" -v "first=$first" -v "second=$second" '
        index($0, first) { print second; next }
        index($0, second) { print first; next }
        { print }
    '
end

function remove_guard_block_line --argument-names path text
    rewrite_file "$path" -v "marker=$guard_marker" -v "marker_end=$guard_marker_end" -v "text=$text" '
        index($0, marker) { in_guard = 1 }
        in_guard && index($0, text) { next }
        { print }
        index($0, marker_end) { in_guard = 0 }
    '
end

function relocate_guard_after_archive --argument-names path
    rewrite_file "$path" -v "marker=$guard_marker" -v "marker_end=$guard_marker_end" -v "archive_end=$archive_end" '
        index($0, marker) { in_guard = 1 }
        in_guard { guard = guard $0 "\n"; if (index($0, marker_end)) in_guard = 0; next }
        { print }
        index($0, archive_end) { printf "\n%s", guard }
    '
end

function guard_block_contains --argument-names path text
    awk -v marker="$guard_marker" -v marker_end="$guard_marker_end" -v text="$text" '
        index($0, marker) { in_guard = 1 }
        in_guard && index($0, text) { found = 1 }
        index($0, marker_end) { exit }
        END { exit found ? 0 : 1 }
    ' "$path"
end

function make_current_target --argument-names target
    if set -q current_target_fixture
        command cp -R "$current_target_fixture/." "$target/"
    else
        make_target "$target"
        run_expect 0 "$installer" --target "$target"
    end
end

function run_marked_structure_case
    set label $argv[1]
    set mutation $argv[2]
    set mutation_args $argv[3..-1]
    set target (mktemp -d /tmp/spectra-plus-marked-structure.XXXXXX)
    make_current_target "$target"
    set commit_path "$target/.agents/skills/spectra-commit/SKILL.md"
    $mutation "$commit_path" $mutation_args
    set expected_mode (file_mode "$commit_path")
    set snapshot (snapshot_target "$target")

    echo "CASE: $label"
    run_expect 1 "$installer" --target "$target"
    assert_contains /tmp/spectra-plus-installer-test.err "spectra-commit structure error"
    assert_target_unchanged "$label" "$target" "$snapshot" "$commit_path" "$expected_mode"
end

function run_unguarded_structure_case
    set label $argv[1]
    set mutation $argv[2]
    set mutation_args $argv[3..-1]
    set target (mktemp -d /tmp/spectra-plus-unguarded-structure.XXXXXX)
    make_target "$target"
    set commit_path "$target/.agents/skills/spectra-commit/SKILL.md"
    $mutation "$commit_path" $mutation_args
    set expected_mode (file_mode "$commit_path")
    set snapshot (snapshot_target "$target")

    echo "CASE: $label"
    run_expect 1 "$installer" --target "$target"
    assert_contains /tmp/spectra-plus-installer-test.err "spectra-commit structure error"
    assert_target_unchanged "$label" "$target" "$snapshot" "$commit_path" "$expected_mode"
end

function make_isolated_source --argument-names source
    mkdir -p "$source/scripts" "$source/.agents/skills" "$source/.claude/skills"
    command cp "$installer" "$source/install-spectra-plus.fish"
    command cp -R "$root_dir/scripts/spectra-plus" "$source/scripts/"
    command cp -R "$root_dir/.agents/skills/spectra-commit" "$source/.agents/skills/"
    command cp -R "$root_dir/.claude/skills/spectra-commit" "$source/.claude/skills/"
end

function git_init_commit --argument-names source
    git -C "$source" init -q
    git -C "$source" add -A
    git -C "$source" -c user.email=t@example.com -c user.name=test commit -qm fixture
end

function make_target --argument-names target
    mkdir -p "$target/.agents/skills" "$target/.claude/skills"
    for skill in spectra-propose spectra-apply spectra-commit
        command cp -R "$root_dir/.agents/skills/$skill" "$target/.agents/skills/"
        command cp -R "$root_dir/.claude/skills/$skill" "$target/.claude/skills/"
    end

    # Simulate an installed project with older unguarded commit skills.
    for path in "$target/.agents/skills/spectra-commit/SKILL.md" "$target/.claude/skills/spectra-commit/SKILL.md"
        set stripped (mktemp /tmp/spectra-plus-commit-strip.XXXXXX)
        awk '
            /<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist \+ plus deletion protection -->/ { skip = 1; next }
            /<!-- SPECTRA-COMMIT-GUARD:END -->/ { skip = 0; next }
            !skip { print }
        ' "$path" > "$stripped"
        command mv -f "$stripped" "$path"

        set old_shape (mktemp /tmp/spectra-plus-commit-old-shape.XXXXXX)
        awk '
            /- \*\*Include all dirty files\*\*/ {
                print "   - **Include all dirty files**: Add all unrelated files to the commit as well"
                next
            }
            /Generated plus skill deletions under/ { next }
            {
                if ($0 == "       - Deletions under `openspec/changes/<name>/`") {
                    print "       - Deletions under `docs/specs/changes/<name>/`"
                    next
                }
                if ($0 == "       - Additions or modifications under `openspec/changes/archive/<date>-<change>/`") {
                    print "       - Additions in `docs/specs/archived/<name>/`"
                    next
                }
                if ($0 == "    - D  openspec/changes/<name>/proposal.md") {
                    print "    - D  docs/specs/changes/<name>/proposal.md"
                    next
                }
                if ($0 == "    - D  openspec/changes/<name>/tasks.md") {
                    print "    - D  docs/specs/changes/<name>/tasks.md"
                    next
                }
                if ($0 == "    - A  openspec/changes/archive/<date>-<change>/proposal.md") {
                    print "    - A  docs/specs/archived/<name>/proposal.md"
                    next
                }
                if ($0 == "    - A  openspec/changes/archive/<date>-<change>/tasks.md") {
                    print "    - A  docs/specs/archived/<name>/tasks.md"
                    next
                }
                if ($0 == "    - M  openspec/specs/<spec-name>/spec.md") {
                    print "    - M  docs/specs/specs/<spec-name>/spec.md"
                    next
                }
                print
            }
        ' "$path" > "$old_shape"
        command mv -f "$old_shape" "$path"
        printf '\n<!-- LOCAL-COMMIT-SKILL-SENTINEL -->\n' >> "$path"
    end
end

cd "$root_dir"; or fail "cannot cd to root"

set target (mktemp -d /tmp/spectra-plus-installer-target.XXXXXX)
make_target "$target"

command cp -f "$target/.agents/skills/spectra-commit/SKILL.md" /tmp/spectra-plus-agents-commit.before
run_expect 0 "$installer" --target "$target" --dry-run
diff -u /tmp/spectra-plus-agents-commit.before "$target/.agents/skills/spectra-commit/SKILL.md"; or fail "dry-run modified agents commit skill"
assert_contains /tmp/spectra-plus-installer-test.out "spectra-commit guard"

run_expect 0 "$installer" --target "$target"
for path in "$target/.agents/skills/spectra-propose-plus/SKILL.md" "$target/.claude/skills/spectra-propose-plus/SKILL.md"
    assert_contains "$path" "has passed. If validation fixes are required, complete them before entering this loop."
    assert_contains "$path" 'if any fix action modifies proposal, design, tasks, or spec artifacts, run `spectra validate "<name>"` again'
    assert_not_contains "$path" "Codex Plan Mode"
end
for path in "$target/.agents/skills/spectra-apply-plus/SKILL.md" "$target/.claude/skills/spectra-apply-plus/SKILL.md"
    assert_contains "$path" "Reviewer A — Adherence in the Sub-Agent Review/Rating/Fix Loop MUST"
    assert_contains "$path" "archive guidance is deferred until the plus quality gate passes"
    assert_contains "$path" "All tasks complete. The plus quality gate runs next; archive guidance is shown only if it passes."
    assert_not_contains "$path" "All tasks complete! You can archive this change with"
end
for path in "$target/.agents/skills/spectra-commit/SKILL.md" "$target/.claude/skills/spectra-commit/SKILL.md"
    assert_contains "$path" "$guard_marker"
    assert_contains "$path" ".agents/skills/spectra-*-plus/"
    assert_contains "$path" ".claude/skills/spectra-*-plus/"
    assert_contains "$path" "openspec/changes/archive/<date>-<change>/"
    assert_contains "$path" "except protected generated plus skill deletions"
    assert_contains "$path" "<!-- LOCAL-COMMIT-SKILL-SENTINEL -->"
    assert_not_contains "$path" "openspec/archived/"
    assert_not_contains "$path" "docs/specs/"
    test (rg --fixed-strings "$guard_marker" "$path" | wc -l | string trim) = 1; or fail "$path has duplicate guard marker"
end

run_expect 0 "$installer" --target "$target"
for path in "$target/.agents/skills/spectra-commit/SKILL.md" "$target/.claude/skills/spectra-commit/SKILL.md"
    test (rg --fixed-strings "$guard_marker" "$path" | wc -l | string trim) = 1; or fail "$path has duplicate guard marker after second run"
end

set -g current_target_fixture (mktemp -d /tmp/spectra-plus-current-fixture.XXXXXX)
command cp -R "$target/." "$current_target_fixture/"

set sentinel_outside (mktemp -d /tmp/spectra-plus-sentinel-outside.XXXXXX)
make_current_target "$sentinel_outside"
set sentinel_outside_commit "$sentinel_outside/.agents/skills/spectra-commit/SKILL.md"
remove_guard_block_line "$sentinel_outside_commit" '.agents/skills/spectra-*-plus/'
remove_guard_block_line "$sentinel_outside_commit" '.claude/skills/spectra-*-plus/'
guard_block_contains "$sentinel_outside_commit" '.agents/skills/spectra-*-plus/'; and fail "sentinel-outside fixture retained agents sentinel inside guard"
assert_contains "$sentinel_outside_commit" '.agents/skills/spectra-*-plus/'
echo "CASE: required-sentinels-outside-guard-do-not-count-as-current"
run_expect 0 "$installer" --target "$sentinel_outside"
guard_block_contains "$sentinel_outside_commit" '.agents/skills/spectra-*-plus/'; or fail "installer did not restore agents sentinel inside guard"
guard_block_contains "$sentinel_outside_commit" '.claude/skills/spectra-*-plus/'; or fail "installer did not restore claude sentinel inside guard"

run_marked_structure_case "guard-block-relocated-after-controlled-sections" relocate_guard_after_archive

run_marked_structure_case "marker-start-missing-one-side" remove_anchor "$guard_marker"
run_marked_structure_case "marker-end-missing-one-side" remove_anchor "$guard_marker_end"
run_marked_structure_case "marker-start-duplicate" duplicate_anchor "$guard_marker"
run_marked_structure_case "marker-end-duplicate" duplicate_anchor "$guard_marker_end"
run_marked_structure_case "marker-boundary-reversed" swap_anchors "$guard_marker" "$guard_marker_end"

for anchor_case in \
        "user-start::$user_start" \
        "archive-subflow-start::$subflow_start" \
        "archive-execution-start::$archive_start" \
        "archive-execution-end::$archive_end"
    set parts (string split -m 1 -- "::" "$anchor_case")
    run_marked_structure_case "controlled-anchor-$parts[1]-missing" remove_anchor "$parts[2]"
    run_marked_structure_case "controlled-anchor-$parts[1]-duplicate" duplicate_anchor "$parts[2]"
end

run_marked_structure_case "controlled-anchor-user-before-subflow-order" swap_anchors "$user_start" "$subflow_start"
run_marked_structure_case "controlled-anchor-subflow-before-archive-order" swap_anchors "$subflow_start" "$archive_start"
run_marked_structure_case "controlled-anchor-archive-boundary-order" swap_anchors "$archive_start" "$archive_end"

run_unguarded_structure_case "unguarded-insertion-anchor-missing" remove_anchor "$guard_insert_after"
run_unguarded_structure_case "unguarded-insertion-anchor-duplicate" duplicate_anchor "$guard_insert_after"

set malformed_source (mktemp -d /tmp/spectra-plus-malformed-source.XXXXXX)
make_isolated_source "$malformed_source"
duplicate_anchor "$malformed_source/.agents/skills/spectra-commit/SKILL.md" "$guard_marker"
set malformed_source_target (mktemp -d /tmp/spectra-plus-malformed-source-target.XXXXXX)
make_target "$malformed_source_target"
set malformed_source_commit "$malformed_source_target/.agents/skills/spectra-commit/SKILL.md"
set malformed_source_mode (file_mode "$malformed_source_commit")
set malformed_source_snapshot (snapshot_target "$malformed_source_target")
echo "CASE: authoritative-source-marker-duplicate"
run_expect 1 "$malformed_source/install-spectra-plus.fish" --target "$malformed_source_target"
assert_contains /tmp/spectra-plus-installer-test.err "spectra-commit structure error"
assert_target_unchanged "authoritative-source-marker-duplicate" "$malformed_source_target" "$malformed_source_snapshot" "$malformed_source_commit" "$malformed_source_mode"

set malformed_head_source (mktemp -d /tmp/spectra-plus-malformed-head-source.XXXXXX)
make_isolated_source "$malformed_head_source"
duplicate_anchor "$malformed_head_source/.claude/skills/spectra-commit/SKILL.md" "$guard_marker"
git_init_commit "$malformed_head_source"
remove_anchor "$malformed_head_source/.claude/skills/spectra-commit/SKILL.md" "$guard_marker"
set malformed_head_target (mktemp -d /tmp/spectra-plus-malformed-head-target.XXXXXX)
make_current_target "$malformed_head_target"
set malformed_head_commit "$malformed_head_target/.agents/skills/spectra-commit/SKILL.md"
set malformed_head_mode (file_mode "$malformed_head_commit")
set malformed_head_snapshot (snapshot_target "$malformed_head_target")
echo "CASE: authoritative-head-restore-candidate-marker-duplicate-dry-run"
run_expect 1 "$malformed_head_source/install-spectra-plus.fish" --target "$malformed_head_target" --dry-run
assert_contains /tmp/spectra-plus-installer-test.err "spectra-commit structure error"
assert_target_unchanged "authoritative-head-restore-candidate-marker-duplicate-dry-run" "$malformed_head_target" "$malformed_head_snapshot" "$malformed_head_commit" "$malformed_head_mode"

set stale_marked (mktemp -d /tmp/spectra-plus-stale-marked.XXXXXX)
make_current_target "$stale_marked"
set stale_marked_commit "$stale_marked/.agents/skills/spectra-commit/SKILL.md"
remove_anchor "$stale_marked_commit" "Do not treat the full post-archive dirty state as archive output."
remove_anchor "$stale_marked_commit" "- **Commit as shown**: Proceed with the displayed artifact + source files"
command chmod 640 "$stale_marked_commit"
echo "CASE: stale-marked-unique-boundary-upgrade"
run_expect 0 "$installer" --target "$stale_marked"
assert_contains "$stale_marked_commit" "Do not treat the full post-archive dirty state as archive output."
assert_contains "$stale_marked_commit" "- **Commit as shown**: Proceed with the displayed artifact + source files"
assert_contains "$stale_marked_commit" "<!-- LOCAL-COMMIT-SKILL-SENTINEL -->"
test (rg -o --fixed-strings "$guard_marker" "$stale_marked_commit" | count) = 1; or fail "stale marked upgrade duplicated guard start"
test (rg -o --fixed-strings "$guard_marker_end" "$stale_marked_commit" | count) = 1; or fail "stale marked upgrade duplicated guard end"
test (file_mode "$stale_marked_commit") = 640; or fail "stale marked upgrade did not preserve target mode"
command cp -p "$stale_marked_commit" /tmp/spectra-plus-stale-marked.after
echo "CASE: stale-marked-second-run-byte-stable"
run_expect 0 "$installer" --target "$stale_marked"
cmp -s /tmp/spectra-plus-stale-marked.after "$stale_marked_commit"; or fail "second stale marked run changed target bytes"
test (file_mode "$stale_marked_commit") = 640; or fail "second stale marked run changed target mode"
assert_no_guard_candidate "stale-marked-success" "$stale_marked_commit"

set stale_dry_run (mktemp -d /tmp/spectra-plus-stale-dry-run.XXXXXX)
make_stale_atomic_target "$stale_dry_run"
set stale_dry_run_commit "$stale_dry_run/.agents/skills/spectra-commit/SKILL.md"
set stale_dry_run_mode (file_mode "$stale_dry_run_commit")
command cp -p "$stale_dry_run_commit" /tmp/spectra-plus-stale-dry-run.before
echo "CASE: stale-marked-dry-run-no-target-candidate"
run_expect 0 "$installer" --target "$stale_dry_run" --dry-run
assert_contains /tmp/spectra-plus-installer-test.out "+ upgrade spectra-commit guard"
assert_commit_unchanged "stale-marked-dry-run" "$stale_dry_run_commit" /tmp/spectra-plus-stale-dry-run.before "$stale_dry_run_mode"
assert_no_guard_candidate "stale-marked-dry-run" "$stale_dry_run_commit"

set validation_failure (mktemp -d /tmp/spectra-plus-validation-failure.XXXXXX)
make_stale_atomic_target "$validation_failure"
set validation_failure_commit "$validation_failure/.agents/skills/spectra-commit/SKILL.md"
set validation_failure_mode (file_mode "$validation_failure_commit")
command cp -p "$validation_failure_commit" /tmp/spectra-plus-validation-failure.before
echo "CASE: temporary-validation-failure-cleans-candidate"
run_expect 1 env SPECTRA_PLUS_TEST_GUARD_VALIDATION_FAILURE=1 "$installer" --target "$validation_failure"
assert_contains /tmp/spectra-plus-installer-test.err "candidate validation failure"
assert_commit_unchanged "temporary-validation-failure" "$validation_failure_commit" /tmp/spectra-plus-validation-failure.before "$validation_failure_mode"
assert_no_guard_candidate "temporary-validation-failure" "$validation_failure_commit"

set replace_failure (mktemp -d /tmp/spectra-plus-replace-failure.XXXXXX)
make_stale_atomic_target "$replace_failure"
set replace_failure_commit "$replace_failure/.agents/skills/spectra-commit/SKILL.md"
set replace_failure_mode (file_mode "$replace_failure_commit")
command cp -p "$replace_failure_commit" /tmp/spectra-plus-replace-failure.before
echo "CASE: final-replace-failure-cleans-candidate"
run_expect 1 env SPECTRA_PLUS_TEST_GUARD_REPLACE_FAILURE=1 "$installer" --target "$replace_failure"
assert_contains /tmp/spectra-plus-installer-test.err "final replace failure"
assert_commit_unchanged "final-replace-failure" "$replace_failure_commit" /tmp/spectra-plus-replace-failure.before "$replace_failure_mode"
assert_no_guard_candidate "final-replace-failure" "$replace_failure_commit"

set cleanup_failure (mktemp -d /tmp/spectra-plus-cleanup-failure.XXXXXX)
make_stale_atomic_target "$cleanup_failure"
set cleanup_failure_commit "$cleanup_failure/.agents/skills/spectra-commit/SKILL.md"
set cleanup_failure_mode (file_mode "$cleanup_failure_commit")
command cp -p "$cleanup_failure_commit" /tmp/spectra-plus-cleanup-failure.before
echo "CASE: candidate-cleanup-failure-secondary-diagnostic"
run_expect 1 env SPECTRA_PLUS_TEST_GUARD_REPLACE_FAILURE=1 SPECTRA_PLUS_TEST_GUARD_CLEANUP_FAILURE=1 "$installer" --target "$cleanup_failure"
assert_contains /tmp/spectra-plus-installer-test.err "final replace failure"
assert_contains /tmp/spectra-plus-installer-test.err "candidate cleanup failure"
assert_commit_unchanged "candidate-cleanup-failure" "$cleanup_failure_commit" /tmp/spectra-plus-cleanup-failure.before "$cleanup_failure_mode"
set cleanup_candidates (guard_candidates "$cleanup_failure_commit")
test (count $cleanup_candidates) -eq 1; or fail "candidate cleanup failure did not leave exactly one diagnosable candidate"
string match -q -- (dirname "$cleanup_failure_commit")'/.spectra-commit-guard-candidate.*' "$cleanup_candidates[1]"; or fail "final candidate was not created in target directory"
assert_contains /tmp/spectra-plus-installer-test.err "$cleanup_candidates[1]"
command rm -f "$cleanup_candidates[1]"

set missing_agents (mktemp -d /tmp/spectra-plus-installer-missing-agents.XXXXXX)
make_target "$missing_agents"
command rm -rf "$missing_agents/.agents/skills/spectra-commit"
run_expect 1 "$installer" --target "$missing_agents"
assert_contains /tmp/spectra-plus-installer-test.err ".agents/skills/spectra-commit/SKILL.md"

set missing_claude (mktemp -d /tmp/spectra-plus-installer-missing-claude.XXXXXX)
make_target "$missing_claude"
command rm -rf "$missing_claude/.claude/skills/spectra-commit"
run_expect 1 "$installer" --target "$missing_claude"
assert_contains /tmp/spectra-plus-installer-test.err ".claude/skills/spectra-commit/SKILL.md"

set unsupported (mktemp -d /tmp/spectra-plus-installer-unsupported.XXXXXX)
make_target "$unsupported"
printf '%s\n' '---' 'name: spectra-commit' '---' 'unsupported shape' > "$unsupported/.agents/skills/spectra-commit/SKILL.md"
run_expect 1 "$installer" --target "$unsupported"
assert_contains /tmp/spectra-plus-installer-test.err "spectra-commit guard"

set stale_base (mktemp -d /tmp/spectra-plus-installer-stale-base.XXXXXX)
make_target "$stale_base"
printf '\nDetect dormancy from `docs/specs/changes/<name>/`\n' >> "$stale_base/.agents/skills/spectra-apply/SKILL.md"
printf '\nAll file paths example: `docs/specs/specs/auth/spec.md`\n' >> "$stale_base/.agents/skills/spectra-propose/SKILL.md"
run_expect 0 "$installer" --target "$stale_base"
assert_contains "$stale_base/.agents/skills/spectra-apply-plus/SKILL.md" "openspec/changes/<name>/"
assert_contains "$stale_base/.agents/skills/spectra-propose-plus/SKILL.md" "openspec/specs/auth/spec.md"
assert_not_contains "$stale_base/.agents/skills/spectra-apply-plus/SKILL.md" "docs/specs/"
assert_not_contains "$stale_base/.agents/skills/spectra-propose-plus/SKILL.md" "docs/specs/"

echo "PASS: installer commit guard checks"
