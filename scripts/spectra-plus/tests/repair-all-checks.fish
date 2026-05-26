#!/usr/bin/env fish

set script_path (status --current-filename)
set test_dir (dirname "$script_path")
set root_dir (realpath "$test_dir/../../..")
set installer "$root_dir/install-spectra-plus.fish"
set entrypoint "$root_dir/scripts/spectra-plus/repair-all.fish"
set guard_marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"
set agent_label "com.agentflow.spectra-plus.repair"

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

function make_home
    mktemp -d /tmp/spectra-plus-home.XXXXXX
end

function make_run_dir
    mktemp -d /tmp/spectra-plus-run.XXXXXX
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

cd "$root_dir"; or fail "cannot cd to root"

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

set repair_home (make_home)
set repair_run (make_run_dir)
set repair_a (mktemp -d /tmp/spectra-plus-repair-a.XXXXXX)
set repair_b (mktemp -d /tmp/spectra-plus-repair-b.XXXXXX)
make_target "$repair_a"
make_target "$repair_b"
strip_guard "$repair_b/.agents/skills/spectra-commit/SKILL.md"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_a"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --register-target "$repair_b"
run_expect 0 env HOME="$repair_home" TMPDIR="$repair_run" "$installer" --repair-all --force
assert_plus_outputs "$repair_a"
assert_plus_outputs "$repair_b"

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
set missing_fish_home (make_home)
run_expect 1 env HOME="$missing_fish_home" TMPDIR="$entry_run" PATH="/usr/bin:/bin" "$fish_bin" "$entrypoint" --dry-run
assert_contains "$missing_fish_home/Library/Logs/spectra-plus-repair.log" "找不到必要指令：fish"
set fish_only_bin (mktemp -d /tmp/spectra-plus-fish-only.XXXXXX)
ln -s "$fish_bin" "$fish_only_bin/fish"
set missing_yq_home (make_home)
run_expect 1 env HOME="$missing_yq_home" TMPDIR="$entry_run" PATH="$fish_only_bin:/usr/bin:/bin" "$fish_bin" "$entrypoint" --dry-run
assert_contains "$missing_yq_home/Library/Logs/spectra-plus-repair.log" "找不到必要指令：yq"

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

echo "PASS: repair-all checks"
