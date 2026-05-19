#!/usr/bin/env fish

set script_path (status --current-filename)
set test_dir (dirname "$script_path")
set root_dir (realpath "$test_dir/../../..")
set installer "$root_dir/install-spectra-plus.fish"
set guard_marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function assert_contains
    set file $argv[1]
    set text $argv[2]
    rg -q --fixed-strings "$text" "$file"; or fail "$file missing $text"
end

function assert_not_contains
    set file $argv[1]
    set text $argv[2]
    if rg -q --fixed-strings "$text" "$file"
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

echo "PASS: installer commit guard checks"
