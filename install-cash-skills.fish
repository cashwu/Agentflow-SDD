#!/usr/bin/env -S fish --no-config

set script_name (command basename (status --current-filename))
set script_path (command realpath (status --current-filename) 2>/dev/null)
set script_dir (command dirname "$script_path")

function usage
    echo "Usage:"
    echo "  ./$script_name --target <project> [--dry-run] [--force]"
    echo ""
    echo "Options:"
    echo "  --target <project>  Existing project directory to receive cash skills."
    echo "  --dry-run           Report the complete plan without writing to the target."
    echo "  --force             Replace differing managed cash skill files."
    echo "  -h, --help          Show this help."
end

function fail
    echo "Error: $argv" >&2
    exit 1
end

function is_below --argument-names parent candidate
    set -l prefix "$parent/"
    set -l prefix_length (string length -- "$prefix")
    test (string sub -s 1 -l "$prefix_length" -- "$candidate") = "$prefix"
end

set target_input ""
set dry_run 0
set force 0

while test (count $argv) -gt 0
    switch "$argv[1]"
        case -h --help
            usage
            exit 0
        case --target
            test (count $argv) -ge 2; or fail "--target requires <project>."
            test -z "$target_input"; or fail "--target may be specified only once."
            set target_input "$argv[2]"
            set -e argv[1..2]
        case --dry-run
            set dry_run 1
            set -e argv[1]
        case --force
            set force 1
            set -e argv[1]
        case '*'
            fail "unknown argument: $argv[1]"
    end
end

test -n "$target_input"; or fail "--target <project> is required."
test -n "$script_path"; or fail "cannot resolve installer path."

set skills \
    analyze \
    apply \
    archive \
    ask \
    audit \
    commit \
    debug \
    discuss \
    drift \
    ingest \
    propose \
    verify

set source_paths
set relative_paths
set preflight_failed 0

for variant in .claude .agents
    for skill in $skills
        set relative_path "$variant/skills/cash-$skill/SKILL.md"
        set source_path "$script_dir/$relative_path"
        set -a relative_paths "$relative_path"
        set -a source_paths "$source_path"

        if test -L "$source_path"; or not test -f "$source_path"; or not test -r "$source_path"
            echo "Error: invalid or missing source: $source_path" >&2
            set preflight_failed 1
        end
    end
end

if test $preflight_failed -ne 0
    exit 1
end

if test -L "$target_input"
    fail "target must not be a symlink: $target_input"
end
if not test -d "$target_input"
    fail "target must be an existing directory: $target_input"
end

set target_path (command realpath "$target_input" 2>/dev/null)
if test $status -ne 0; or test -z "$target_path"
    fail "cannot resolve target: $target_input"
end
if test "$target_path" = /
    fail "target must not resolve to /: $target_input"
end

set destination_paths
set actions
set install_count 0
set unchanged_count 0
set replace_count 0
set conflict_count 0

for index in (seq (count $relative_paths))
    set relative_path "$relative_paths[$index]"
    set destination_path "$target_path/$relative_path"
    set -a destination_paths "$destination_path"
    set destination_failed 0

    if not is_below "$target_path" "$destination_path"
        echo "Error: destination escapes target: $relative_path" >&2
        set -a actions invalid
        set preflight_failed 1
        continue
    end

    set boundary "$target_path"
    set components (string split / "$relative_path")
    for component_index in (seq (count $components))
        set boundary "$boundary/$components[$component_index]"

        if test -L "$boundary"
            echo "Error: symlink boundary for $relative_path: $boundary" >&2
            set preflight_failed 1
            set destination_failed 1
            break
        end

        if test $component_index -lt (count $components); and test -e "$boundary"; and not test -d "$boundary"
            echo "Error: managed parent is not a directory for $relative_path: $boundary" >&2
            set preflight_failed 1
            set destination_failed 1
            break
        end
    end

    if test $destination_failed -ne 0
        set -a actions invalid
        continue
    end

    set existing_path "$destination_path"
    while not test -e "$existing_path"
        set existing_path (command dirname "$existing_path")
    end
    set resolved_existing (command realpath "$existing_path" 2>/dev/null)
    set resolve_status $status
    set containment_failed 0
    if test $resolve_status -ne 0
        set containment_failed 1
    else if test "$resolved_existing" != "$target_path"; and not is_below "$target_path" "$resolved_existing"
        set containment_failed 1
    end
    if test $containment_failed -ne 0
        echo "Error: resolved destination escapes target for $relative_path: $resolved_existing" >&2
        set -a actions invalid
        set preflight_failed 1
        continue
    end

    if not test -e "$destination_path"
        if not test -w "$existing_path"; or not test -x "$existing_path"
            echo "Error: destination parent is not writable: $existing_path" >&2
            set -a actions invalid
            set preflight_failed 1
        else
            set -a actions install
            set install_count (math $install_count + 1)
        end
    else if not test -f "$destination_path"
        echo "Error: managed destination is not a regular file: $destination_path" >&2
        set -a actions invalid
        set preflight_failed 1
    else
        command cmp -s "$source_paths[$index]" "$destination_path"
        set compare_status $status

        if test $compare_status -eq 0
            set -a actions unchanged
            set unchanged_count (math $unchanged_count + 1)
        else if test $compare_status -gt 1
            echo "Error: cannot compare managed destination: $destination_path" >&2
            set -a actions invalid
            set preflight_failed 1
        else if test $force -eq 1
            if not test -w "$destination_path"
                echo "Error: managed destination is not writable: $destination_path" >&2
                set -a actions invalid
                set preflight_failed 1
            else
                set -a actions replace
                set replace_count (math $replace_count + 1)
            end
        else
            set -a actions conflict
            set conflict_count (math $conflict_count + 1)
        end
    end
end

for index in (seq (count $relative_paths))
    echo "$actions[$index]: $relative_paths[$index]"
    if test "$actions[$index]" = conflict
        echo "Error: conflicting destination: $destination_paths[$index]" >&2
    end
end

echo "Summary: install=$install_count unchanged=$unchanged_count replace=$replace_count conflict=$conflict_count"

if test $preflight_failed -ne 0; or test $conflict_count -ne 0
    exit 1
end

if test $dry_run -eq 1
    exit 0
end

for index in (seq (count $relative_paths))
    switch "$actions[$index]"
        case install replace
            set destination_dir (command dirname "$destination_paths[$index]")
            command mkdir -p "$destination_dir"; or fail "cannot create destination directory: $destination_dir"
            command cp "$source_paths[$index]" "$destination_paths[$index]"; or fail "cannot write destination: $destination_paths[$index]"
    end
end
