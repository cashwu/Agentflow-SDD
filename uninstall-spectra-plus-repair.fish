#!/usr/bin/env -S fish --no-config

function usage
    echo 'Usage: uninstall-spectra-plus-repair.fish [--dry-run]'
    echo
    echo 'Remove the legacy Spectra Plus repair schedule and local repair state.'
    echo '  --dry-run  List registered targets and planned actions without invoking launchctl or removing state.'
    echo '  -h, --help Show this help.'
end

function fail --argument-names message
    echo "Error: $message" >&2
    return 1
end

function is_not_loaded --argument-names message service operation
    set -l label (path basename "$service")
    set -l service_parts (string split / -- "$service")
    set -l uid "$service_parts[2]"
    set -l launchctl_print_message (string join \n \
        'Bad request.' \
        "Could not find service \"$label\" in domain for user gui: $uid")

    if test "$operation" = print
        test "$message" = "Could not find service: $service"; or test "$message" = "$launchctl_print_message"
        return
    end

    test "$operation" = bootout; and test "$message" = 'Boot-out failed: 3: No such process'
end

function query_service --argument-names service
    set -l query_output (command launchctl print "$service" 2>&1)
    set -l query_status $status
    set -g launchctl_message (string join \n -- $query_output)

    if test $query_status -eq 0
        return 0
    end
    if is_not_loaded "$launchctl_message" "$service" print
        return 1
    end
    return 2
end

function manual_cleanup_failure --argument-names operation service details
    echo "Error: unexpected launchctl $operation failure for $service: $details" >&2
    echo "manual cleanup: launchctl bootout $service" >&2
    return 1
end

function reject_symlink_boundary --argument-names home_dir relative_path
    set -l current "$home_dir"
    if test -L "$current"
        fail "unsafe symlink boundary: $current"
        return 1
    end

    for component in (string split / -- "$relative_path")
        set current "$current/$component"
        if test -L "$current"
            fail "unsafe symlink boundary: $current"
            return 1
        end
        if not test -e "$current"
            break
        end
    end
end

set -l dry_run false
for argument in $argv
    switch "$argument"
        case --dry-run
            set dry_run true
        case -h --help
            usage
            exit 0
        case '*'
            usage >&2
            fail "unknown argument: $argument"
            exit 2
    end
end

if not set -q HOME; or test -z "$HOME"
    fail 'HOME must be a non-empty absolute path other than /'
    exit 1
end
if not string match -q '/*' -- "$HOME"; or test "$HOME" = /
    fail 'HOME must be a non-empty absolute path other than /'
    exit 1
end
if test -L "$HOME"; or not test -d "$HOME"
    fail "HOME is not a safe existing directory: $HOME"
    exit 1
end

set -l home_dir (path resolve -- "$HOME" 2>/dev/null)
if test $status -ne 0; or test -z "$home_dir"; or test "$home_dir" = /
    fail "HOME could not be safely resolved: $HOME"
    exit 1
end

set -l labels com.spectra.plus.repair com.agentflow.spectra-plus.repair
set -l plist_paths \
    "$home_dir/Library/LaunchAgents/com.spectra.plus.repair.plist" \
    "$home_dir/Library/LaunchAgents/com.agentflow.spectra-plus.repair.plist"
set -l registry_path "$home_dir/.config/spectra-plus/projects.txt"
set -l cache_path "$home_dir/.cache/spectra-plus"
set -l log_path "$home_dir/Library/Logs/spectra-plus-repair.log"

for relative_path in \
    Library/LaunchAgents/com.spectra.plus.repair.plist \
    Library/LaunchAgents/com.agentflow.spectra-plus.repair.plist \
    .config/spectra-plus/projects.txt \
    .cache/spectra-plus
    reject_symlink_boundary "$home_dir" "$relative_path"; or exit 1
end

set -l registered_targets
if test -e "$registry_path"
    if not test -f "$registry_path"; or not test -r "$registry_path"
        fail "registry is not a readable regular file: $registry_path"
        exit 1
    end

    set -l registry_lines (command cat -- "$registry_path")
    if test $status -ne 0
        fail "could not read registry: $registry_path"
        exit 1
    end

    for registered_target in $registry_lines
        set -l trimmed_target (string trim -- "$registered_target")
        if test -n "$trimmed_target"; and not string match -q '#*' -- "$trimmed_target"
            set -a registered_targets "$trimmed_target"
        end
    end
end

if test (count $registered_targets) -gt 0
    echo 'Registered targets (install cash skills in each before cleanup):'
    printf '%s\n' $registered_targets
end

set -l uid (command id -u)
set -l services
for label in $labels
    set -a services "gui/$uid/$label"
end

if test "$dry_run" = true
    for service in $services
        echo "Would query: launchctl print $service"
        echo "Would unload if loaded: launchctl bootout $service"
    end
    for plist_path in $plist_paths
        echo "Would remove: $plist_path"
    end
    echo "Would remove: $registry_path"
    echo "Would remove: $cache_path"
    echo "Would preserve: $log_path"
    echo 'Dry run complete; no state changed.'
    exit 0
end

set -l loaded_services
for service in $services
    query_service "$service"
    set -l query_status $status
    switch $query_status
        case 0
            set -a loaded_services "$service"
        case 1
            # An absent service is already in the required final state.
        case '*'
            manual_cleanup_failure print "$service" "$launchctl_message"
            exit 1
    end
end

for service in $loaded_services
    set -l bootout_output (command launchctl bootout "$service" 2>&1)
    set -l bootout_status $status
    set -l bootout_message (string join \n -- $bootout_output)
    if test $bootout_status -ne 0; and not is_not_loaded "$bootout_message" "$service" bootout
        manual_cleanup_failure bootout "$service" "$bootout_message"
        exit 1
    end
    echo "Unloaded: $service"
end

for service in $services
    query_service "$service"
    set -l query_status $status
    switch $query_status
        case 1
            # Confirmed absent after any required bootout.
        case 0
            manual_cleanup_failure verification "$service" 'service is still loaded'
            exit 1
        case '*'
            manual_cleanup_failure verification "$service" "$launchctl_message"
            exit 1
    end
end

set -l removed_count 0
for plist_path in $plist_paths
    if test -e "$plist_path"
        command rm -f -- "$plist_path"
        or begin
            fail "could not remove: $plist_path"
            exit 1
        end
        echo "Removed: $plist_path"
        set removed_count (math $removed_count + 1)
    end
end

if test -e "$registry_path"
    command rm -f -- "$registry_path"
    or begin
        fail "could not remove: $registry_path"
        exit 1
    end
    echo "Removed: $registry_path"
    set removed_count (math $removed_count + 1)
end

if test -e "$cache_path"
    command rm -rf -- "$cache_path"
    or begin
        fail "could not remove: $cache_path"
        exit 1
    end
    echo "Removed: $cache_path"
    set removed_count (math $removed_count + 1)
end

echo "Preserved: $log_path"
if test $removed_count -eq 0; and test (count $loaded_services) -eq 0
    echo 'Cleanup complete: legacy repair state was already absent (no-op).'
else
    echo "Cleanup complete: unloaded "(count $loaded_services)" service(s) and removed $removed_count item(s)."
end
