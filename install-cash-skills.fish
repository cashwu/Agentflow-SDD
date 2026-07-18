#!/usr/bin/env -S fish --no-config

set script_name (command basename (status --current-filename))
set script_path (command realpath (status --current-filename) 2>/dev/null)
set script_dir (command dirname "$script_path")

function usage
    echo "Usage:"
    echo "  ./$script_name --target <project> [--dry-run] [--force]"
    echo "  ./$script_name --register <project>"
    echo "  ./$script_name --unregister <project>"
    echo "  ./$script_name --list"
    echo "  ./$script_name --all [--dry-run] [--force]"
    echo ""
    echo "Options:"
    echo "  --target <project>  Existing project directory to receive cash skills."
    echo "  --register <project>    Add an existing project to the manual update list."
    echo "  --unregister <project>  Remove a project from the manual update list."
    echo "  --list                  Print the manual update list."
    echo "  --all                   Update every project in the manual update list."
    echo "  --dry-run           Report the complete plan without writing to the target."
    echo "  --force             Repair managed files when version and integrity checks allow it."
    echo "  -h, --help          Show this help."
end

function fail
    echo "Error: $argv" >&2
    exit 1
end

function emit_result --argument-names result
    echo ""
    echo "Result: $result"
end

function is_below --argument-names parent candidate
    set -l prefix "$parent/"
    set -l prefix_length (string length -- "$prefix")
    test (string sub -s 1 -l "$prefix_length" -- "$candidate") = "$prefix"
end

function valid_version --argument-names bundle_version
    string match -rq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -- "$bundle_version"
end

function compare_digit_strings --argument-names left right
    set -l left_length (string length -- "$left")
    set -l right_length (string length -- "$right")
    if test $left_length -lt $right_length
        echo -1
        return
    end
    if test $left_length -gt $right_length
        echo 1
        return
    end

    set -l index 1
    while test $index -le $left_length
        set -l left_digit (string sub -s $index -l 1 -- "$left")
        set -l right_digit (string sub -s $index -l 1 -- "$right")
        if test $left_digit -lt $right_digit
            echo -1
            return
        end
        if test $left_digit -gt $right_digit
            echo 1
            return
        end
        set index (math $index + 1)
    end
    echo 0
end

function compare_versions --argument-names left right
    set -l left_parts (string split . -- "$left")
    set -l right_parts (string split . -- "$right")
    for index in 1 2 3
        set -l comparison (compare_digit_strings "$left_parts[$index]" "$right_parts[$index]")
        if test $comparison -ne 0
            echo "$comparison"
            return
        end
    end
    echo 0
end

function hash_file --argument-names path
    set -l output (command shasum -a 256 "$path" 2>/dev/null)
    test $status -eq 0; or return 1
    set -l digest (string split ' ' -- "$output")[1]
    string match -rq '^[0-9a-f]{64}$' -- "$digest"; or return 1
    echo "$digest"
end

function file_has_forbidden_controls --argument-names path allow_tab
    set -l byte_lines (command od -An -t u1 "$path" 2>/dev/null)
    test $status -eq 0; or return 0
    set -l bytes (string split ' ' -- $byte_lines)
    for byte in $bytes
        test -n "$byte"; or continue
        if test $byte -eq 127
            return 0
        end
        if test $byte -lt 32; and test $byte -ne 10
            if test "$allow_tab" = 1; and test $byte -eq 9
                continue
            end
            return 0
        end
    end
    return 1
end

function has_control_character --argument-names value
    string match -rq '[\x00-\x1f\x7f]' -- "$value"
end

function valid_absolute_record --argument-names record
    test -n "$record"; or return 1
    has_control_character "$record"; and return 1
    string match -q '/*' -- "$record"; or return 1
    test "$record" != /; or return 1
    string match -q '*//*' -- "$record"; and return 1
    string match -q '*/' -- "$record"; and return 1
    string match -rq '(^|/)\.{1,2}(/|$)' -- "$record"; and return 1
    return 0
end

function write_registry --argument-names registry_path
    set -e argv[1]
    set -l registry_dir (command dirname "$registry_path")
    command mkdir -p "$registry_dir"; or fail "cannot create registry directory: $registry_dir"
    set -l temporary (command mktemp "$registry_dir/.projects.txt.XXXXXX" 2>/dev/null)
    if test $status -ne 0; or test -z "$temporary"
        fail "cannot create temporary registry: $registry_dir"
    end
    if test -L "$temporary"; or not is_below "$registry_dir" "$temporary"
        command rm -f -- "$temporary"
        fail "unsafe temporary registry path: $temporary"
    end

    begin
        for record in $argv
            printf '%s\n' "$record"
        end
    end >"$temporary"
    if test $status -ne 0
        command rm -f -- "$temporary"
        fail "cannot write temporary registry: $temporary"
    end
    command mv -f "$temporary" "$registry_path"; or begin
        command rm -f -- "$temporary"
        fail "cannot publish registry: $registry_path"
    end
end

function validate_managed_boundary --argument-names target relative_path
    set -l boundary "$target"
    set -l components (string split / -- "$relative_path")
    for component in $components
        set boundary "$boundary/$component"
        if test -L "$boundary"
            echo "Error: symlink boundary for $relative_path: $boundary" >&2
            return 1
        end
        if test "$component" != "$components[-1]"; and test -e "$boundary"; and not test -d "$boundary"
            echo "Error: managed parent is not a directory for $relative_path: $boundary" >&2
            return 1
        end
    end

    set -l existing "$target/$relative_path"
    while not test -e "$existing"
        set existing (command dirname "$existing")
    end
    set -l resolved (command realpath "$existing" 2>/dev/null)
    if test $status -ne 0; or test -z "$resolved"
        echo "Error: cannot resolve managed boundary for $relative_path" >&2
        return 1
    end
    if test "$resolved" != "$target"; and not is_below "$target" "$resolved"
        echo "Error: managed boundary escapes target for $relative_path: $resolved" >&2
        return 1
    end
end

function valid_retired_plus_skill --argument-names skill_dir expected_name
    if test -L "$skill_dir"; or not test -d "$skill_dir"; or not test -r "$skill_dir"; or not test -w "$skill_dir"; or not test -x "$skill_dir"
        return 1
    end

    set -l skill_path "$skill_dir/SKILL.md"
    set -l entries (command find "$skill_dir" -mindepth 1 -prune -print | command sort)
    set -l entries_pipeline $pipestatus
    test $entries_pipeline[1] -eq 0; and test $entries_pipeline[2] -eq 0; or return 1
    test (count $entries) -eq 1; and test "$entries[1]" = "$skill_path"; or return 1
    if test -L "$skill_path"; or not test -f "$skill_path"; or not test -r "$skill_path"; or not test -w "$skill_path"
        return 1
    end

    command awk -v expected_name="$expected_name" '
        NR == 1 {
            if ($0 != "---") exit 1
            in_frontmatter = 1
            next
        }
        in_frontmatter && $0 == "---" {
            closed = 1
            in_frontmatter = 0
            next
        }
        in_frontmatter && $0 ~ /^name[[:space:]]*:/ {
            name_count++
            if ($0 != "name: " expected_name) invalid_name = 1
        }
        END {
            if (!closed || name_count != 1 || invalid_name) exit 1
        }
    ' "$skill_path" >/dev/null 2>&1
end

set mode ""
set project_input ""
set dry_run 0
set force 0

while test (count $argv) -gt 0
    switch "$argv[1]"
        case -h --help
            usage
            exit 0
        case --target --register --unregister
            test (count $argv) -ge 2; or fail "$argv[1] requires <project>."
            test -z "$mode"; or fail "specify exactly one primary mode."
            set mode (string replace -- -- '' "$argv[1]")
            set project_input "$argv[2]"
            set -e argv[1..2]
        case --list --all
            test -z "$mode"; or fail "specify exactly one primary mode."
            set mode (string replace -- -- '' "$argv[1]")
            set -e argv[1]
        case --dry-run
            test $dry_run -eq 0; or fail "--dry-run may be specified only once."
            set dry_run 1
            set -e argv[1]
        case --force
            test $force -eq 0; or fail "--force may be specified only once."
            set force 1
            set -e argv[1]
        case '*'
            fail "unknown argument: $argv[1]"
    end
end

test -n "$mode"; or fail "specify exactly one of --target, --register, --unregister, --list, or --all."
if not contains -- "$mode" target all; and begin; test $dry_run -eq 1; or test $force -eq 1; end
    fail "--dry-run and --force may be used only with --target or --all."
end
test -n "$script_path"; or fail "cannot resolve installer path."

if test "$mode" != target
    test -n "$HOME"; or fail "HOME must not be empty."
    string match -q '/*' -- "$HOME"; or fail "HOME must be absolute: $HOME"
    test "$HOME" != /; or fail "HOME must not be /."
    test -L "$HOME"; and fail "HOME must not be a symlink: $HOME"
    test -d "$HOME"; or fail "HOME must be an existing directory: $HOME"
    set home_path (command realpath "$HOME" 2>/dev/null)
    if test $status -ne 0; or test -z "$home_path"; or test "$home_path" = /
        fail "cannot resolve safe HOME: $HOME"
    end

    set registry_relative .config/cash-skills/projects.txt
    set registry_path "$home_path/$registry_relative"
    is_below "$home_path" "$registry_path"; or fail "registry escapes HOME: $registry_path"

    set boundary "$home_path"
    for component in .config cash-skills projects.txt
        set boundary "$boundary/$component"
        if test -L "$boundary"
            fail "registry boundary must not be a symlink: $boundary"
        end
        if test "$component" != projects.txt; and test -e "$boundary"; and not test -d "$boundary"
            fail "registry parent must be a directory: $boundary"
        end
    end

    set records
    if test -e "$registry_path"
        if not test -f "$registry_path"; or not test -r "$registry_path"
            fail "registry must be a readable regular file: $registry_path"
        end
        file_has_forbidden_controls "$registry_path" 0; and fail "registry contains a forbidden control character: $registry_path"
        set registry_lines (command cat "$registry_path" 2>/dev/null)
        test $status -eq 0; or fail "cannot read registry: $registry_path"
        for record in $registry_lines
            test -n "$record"; or continue
            valid_absolute_record "$record"; or fail "invalid registry record: $record"
            if test -e "$record"
                test -L "$record"; and fail "registry target must not be a symlink: $record"
                set -l canonical (command realpath "$record" 2>/dev/null)
                if test $status -ne 0; or test -z "$canonical"; or test "$canonical" != "$record"
                    fail "registry record is not canonical: $record"
                end
            end
            contains -- "$record" $records; or set -a records "$record"
        end
    end

    switch "$mode"
        case register
            has_control_character "$project_input"; and fail "project path contains an ASCII control character."
            test -L "$project_input"; and fail "project must not be a symlink: $project_input"
            test -d "$project_input"; or fail "project must be an existing directory: $project_input"
            set -l project_path (command realpath "$project_input" 2>/dev/null)
            if test $status -ne 0; or test -z "$project_path"; or test "$project_path" = /
                fail "cannot resolve safe project: $project_input"
            end
            contains -- "$project_path" $records; or set -a records "$project_path"
            write_registry "$registry_path" $records
            echo "registered: $project_path"

        case unregister
            has_control_character "$project_input"; and fail "project path contains an ASCII control character."
            set -l project_path "$project_input"
            if test -e "$project_input"
                test -L "$project_input"; and fail "project must not be a symlink: $project_input"
                test -d "$project_input"; or fail "project must be a directory: $project_input"
                set project_path (command realpath "$project_input" 2>/dev/null)
                test $status -eq 0; and test -n "$project_path"; or fail "cannot resolve project: $project_input"
            else
                valid_absolute_record "$project_input"; or fail "invalid stale project path: $project_input"
            end

            if not test -e "$registry_path"
                exit 0
            end
            set -l retained
            for record in $records
                test "$record" = "$project_path"; or set -a retained "$record"
            end
            write_registry "$registry_path" $retained
            echo "unregistered: $project_path"

        case list
            for record in $records
                echo "$record"
            end

        case all
            set -l updated_count 0
            set -l would_update_count 0
            set -l current_count 0
            set -l newer_count 0
            set -l conflict_count 0
            set -l failed_count 0

            for record in $records
                set -l child_arguments --target "$record"
                test $dry_run -eq 1; and set -a child_arguments --dry-run
                test $force -eq 1; and set -a child_arguments --force

                set -l child_output (command fish --no-config "$script_path" $child_arguments)
                set -l child_status $status
                set -l result_lines
                for line in $child_output
                    if string match -rq '^Result: (update|current|newer|conflict)$' -- "$line"
                        set -a result_lines "$line"
                    else if test -n "$line"
                        echo "$record: $line" >&2
                    end
                end

                set -l target_status failed
                if test (count $result_lines) -eq 1
                    switch "$result_lines[1]"
                        case 'Result: update'
                            if test $child_status -eq 0
                                if test $dry_run -eq 1
                                    set target_status would-update
                                else
                                    set target_status updated
                                end
                            end
                        case 'Result: current'
                            test $child_status -eq 0; and set target_status current
                        case 'Result: newer'
                            test $child_status -eq 0; and set target_status newer
                        case 'Result: conflict'
                            test $child_status -eq 2; and set target_status conflict
                    end
                end

                echo "$target_status: $record"
                switch "$target_status"
                    case updated
                        set updated_count (math $updated_count + 1)
                    case would-update
                        set would_update_count (math $would_update_count + 1)
                    case current
                        set current_count (math $current_count + 1)
                    case newer
                        set newer_count (math $newer_count + 1)
                    case conflict
                        set conflict_count (math $conflict_count + 1)
                    case failed
                        set failed_count (math $failed_count + 1)
                end
            end

            echo "Summary: updated=$updated_count current=$current_count newer=$newer_count conflict=$conflict_count failed=$failed_count would-update=$would_update_count"
            if test $conflict_count -gt 0; or test $failed_count -gt 0
                exit 1
            end
    end
    exit 0
end

set target_input "$project_input"

set version_path "$script_dir/cash-skills.version"
if test -L "$version_path"; or not test -f "$version_path"; or not test -r "$version_path"
    fail "invalid or missing bundle version: $version_path"
end
file_has_forbidden_controls "$version_path" 0; and fail "bundle version contains a forbidden control character: $version_path"
command awk 'END { exit (NR == 1 ? 0 : 1) }' "$version_path"; or fail "bundle version must contain exactly one line: $version_path"
set version_lines (command cat "$version_path" 2>/dev/null)
test $status -eq 0; or fail "cannot read bundle version: $version_path"
test (count $version_lines) -eq 1; or fail "bundle version must contain exactly one line: $version_path"
set source_version "$version_lines[1]"
valid_version "$source_version"; or fail "invalid bundle version: $source_version"

set skills analyze apply archive ask audit commit debug discuss drift ingest propose verify
set inventory_indexes 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
set source_paths
set relative_paths
set source_hashes

for variant in .agents .claude
    for skill in $skills
        set -l relative_path "$variant/skills/cash-$skill/SKILL.md"
        set -l source_path "$script_dir/$relative_path"
        if test -L "$source_path"; or not test -f "$source_path"; or not test -r "$source_path"
            fail "invalid or missing source: $source_path"
        end
        set -l digest (hash_file "$source_path")
        test $status -eq 0; or fail "cannot hash source: $source_path"
        set -a relative_paths "$relative_path"
        set -a source_paths "$source_path"
        set -a source_hashes "$digest"
    end
end

set retired_plus_paths \
    .agents/skills/spectra-propose-plus \
    .agents/skills/spectra-apply-plus \
    .claude/skills/spectra-propose-plus \
    .claude/skills/spectra-apply-plus
set retired_plus_names \
    spectra-propose-plus \
    spectra-apply-plus \
    spectra-propose-plus \
    spectra-apply-plus

if test -L "$target_input"
    fail "target must not be a symlink: $target_input"
end
test -d "$target_input"; or fail "target must be an existing directory: $target_input"
set target_path (command realpath "$target_input" 2>/dev/null)
if test $status -ne 0; or test -z "$target_path"
    fail "cannot resolve target: $target_input"
end
test "$target_path" != /; or fail "target must not resolve to /: $target_input"
test "$target_path" != "$script_dir"; or fail "target must not be the source repository: $target_path"

for relative_path in $relative_paths .cash-skills/receipt.tsv
    is_below "$target_path" "$target_path/$relative_path"; or fail "managed path escapes target: $relative_path"
    validate_managed_boundary "$target_path" "$relative_path"; or exit 1
end

set retired_plus_present
for index in 1 2 3 4
    set -l relative_path "$retired_plus_paths[$index]"
    set -l expected_name "$retired_plus_names[$index]"
    set -l skill_dir "$target_path/$relative_path"
    is_below "$target_path" "$skill_dir"; or fail "retired plus path escapes target: $relative_path"
    validate_managed_boundary "$target_path" "$relative_path"; or exit 1
    if not test -e "$skill_dir"; and not test -L "$skill_dir"
        continue
    end
    valid_retired_plus_skill "$skill_dir" "$expected_name"; or fail "invalid retired plus skill: $skill_dir"

    set -l parent_dir (command dirname "$skill_dir")
    test -w "$parent_dir"; and test -x "$parent_dir"; or fail "retired plus parent is not writable: $parent_dir"
    set -a retired_plus_present "$relative_path"
end

set receipt_path "$target_path/.cash-skills/receipt.tsv"
set has_receipt 0
set receipt_version ""
set receipt_hashes
if test -e "$receipt_path"
    if test -L "$receipt_path"; or not test -f "$receipt_path"; or not test -r "$receipt_path"
        fail "invalid target receipt: $receipt_path"
    end
    file_has_forbidden_controls "$receipt_path" 1; and fail "target receipt contains a forbidden control character: $receipt_path"
    command awk 'END { exit (NR == 25 ? 0 : 1) }' "$receipt_path"; or fail "target receipt must contain exactly 25 records: $receipt_path"
    set receipt_lines (command cat "$receipt_path" 2>/dev/null)
    test $status -eq 0; or fail "cannot read target receipt: $receipt_path"
    test (count $receipt_lines) -eq 25; or fail "target receipt must contain exactly 25 records: $receipt_path"

    set version_fields (string split \t -- "$receipt_lines[1]")
    test (count $version_fields) -eq 2; and test "$version_fields[1]" = version; or fail "invalid receipt version record: $receipt_path"
    set receipt_version "$version_fields[2]"
    valid_version "$receipt_version"; or fail "invalid receipt version: $receipt_version"

    for index in $inventory_indexes
        set -l line_index (math $index + 1)
        set fields (string split \t -- "$receipt_lines[$line_index]")
        test (count $fields) -eq 3; or fail "invalid receipt record $index: $receipt_path"
        test "$fields[1]" = sha256; or fail "invalid receipt algorithm at record $index: $receipt_path"
        string match -rq '^[0-9a-f]{64}$' -- "$fields[2]"; or fail "invalid receipt digest at record $index: $receipt_path"
        test "$fields[3]" = "$relative_paths[$index]"; or fail "invalid receipt path at record $index: $receipt_path"
        set -a receipt_hashes "$fields[2]"
    end
    set has_receipt 1
end

set target_hashes
set target_exists
set preflight_failed 0
for index in $inventory_indexes
    set -l destination "$target_path/$relative_paths[$index]"
    if test -e "$destination"
        if test -L "$destination"; or not test -f "$destination"; or not test -r "$destination"
            echo "Error: invalid managed destination: $destination" >&2
            set preflight_failed 1
            set -a target_exists 1
            set -a target_hashes invalid
            continue
        end
        set -l digest (hash_file "$destination")
        if test $status -ne 0
            echo "Error: cannot hash managed destination: $destination" >&2
            set preflight_failed 1
            set digest invalid
        end
        set -a target_exists 1
        set -a target_hashes "$digest"
    else
        if test $has_receipt -eq 1
            echo "Error: receipt-managed destination is missing: $destination" >&2
            set preflight_failed 1
        end
        set -a target_exists 0
        set -a target_hashes missing
    end
end
test $preflight_failed -eq 0; or exit 1

set action update
set conflicts
set version_comparison -1
if test $has_receipt -eq 1
    set version_comparison (compare_versions "$source_version" "$receipt_version")
    if test $version_comparison -lt 0
        emit_result newer
        exit 0
    end

    if test $version_comparison -eq 0
        for index in $inventory_indexes
            if test "$source_hashes[$index]" != "$receipt_hashes[$index]"
                fail "source integrity differs from equal-version receipt: $relative_paths[$index]"
            end
        end
    end

    for index in $inventory_indexes
        if test "$target_hashes[$index]" != "$receipt_hashes[$index]"
            set -a conflicts "$relative_paths[$index]"
        end
    end

    if test (count $conflicts) -eq 0; and test $version_comparison -eq 0; and test (count $retired_plus_present) -eq 0
        emit_result current
        exit 0
    end
else
    set -l present_count 0
    set -l identical_count 0
    for index in $inventory_indexes
        if test "$target_exists[$index]" = 1
            set present_count (math $present_count + 1)
            if test "$target_hashes[$index]" = "$source_hashes[$index]"
                set identical_count (math $identical_count + 1)
            else
                set -a conflicts "$relative_paths[$index]"
            end
        end
    end
    if test $present_count -gt 0; and test $present_count -ne 24
        for index in $inventory_indexes
            if test "$target_exists[$index]" = 0
                set -a conflicts "$relative_paths[$index]"
            end
        end
    else if test $present_count -eq 24; and test $identical_count -ne 24
        # Differing paths were collected above.
    else if test $present_count -eq 24
        set action adopt
    end
end

if test (count $conflicts) -gt 0; and test $force -eq 0
    for relative_path in $conflicts
        echo "Error: conflicting destination: $target_path/$relative_path" >&2
    end
    emit_result conflict
    exit 2
end

# Validate every write condition only after the version/drift decision is known,
# while still completing this preflight before the first target mutation.
set preflight_failed 0
if test "$action" != adopt
    for index in $inventory_indexes
        if test "$target_hashes[$index]" = "$source_hashes[$index]"
            continue
        end
        set -l destination "$target_path/$relative_paths[$index]"
        if test -e "$destination"
            set -l destination_dir (command dirname "$destination")
            if not test -w "$destination"
                echo "Error: managed destination is not writable: $destination" >&2
                set preflight_failed 1
            end
            if not test -d "$destination_dir"; or not test -w "$destination_dir"; or not test -x "$destination_dir"
                echo "Error: managed destination parent is not writable: $destination_dir" >&2
                set preflight_failed 1
            end
        else
            set -l existing "$destination"
            while not test -e "$existing"
                set existing (command dirname "$existing")
            end
            if not test -w "$existing"; or not test -x "$existing"
                echo "Error: destination parent is not writable: $existing" >&2
                set preflight_failed 1
            end
        end
    end
end

set receipt_existing "$receipt_path"
while not test -e "$receipt_existing"
    set receipt_existing (command dirname "$receipt_existing")
end
if test -e "$receipt_path"
    if not test -w "$receipt_path"
        echo "Error: target receipt is not writable: $receipt_path" >&2
        set preflight_failed 1
    end
end
set receipt_dir (command dirname "$receipt_path")
if test -d "$receipt_dir"
    if not test -w "$receipt_dir"; or not test -x "$receipt_dir"
        echo "Error: receipt directory is not writable: $receipt_dir" >&2
        set preflight_failed 1
    end
else if not test -w "$receipt_existing"; or not test -x "$receipt_existing"
    echo "Error: receipt parent is not writable: $receipt_existing" >&2
    set preflight_failed 1
end
test $preflight_failed -eq 0; or exit 1

for index in $inventory_indexes
    if test "$target_hashes[$index]" = "$source_hashes[$index]"
        echo "unchanged: $relative_paths[$index]"
    else if test "$target_exists[$index]" = 1
        echo "replace: $relative_paths[$index]"
    else
        echo "install: $relative_paths[$index]"
    end
end
for relative_path in $retired_plus_present
    echo "remove: $relative_path"
end

if test $dry_run -eq 1
    emit_result update
    exit 0
end

if test "$action" != adopt
    for index in $inventory_indexes
        if test "$target_hashes[$index]" != "$source_hashes[$index]"
            set -l destination "$target_path/$relative_paths[$index]"
            set -l destination_dir (command dirname "$destination")
            command mkdir -p "$destination_dir"; or fail "cannot create destination directory: $destination_dir"
            set -l destination_temp (command mktemp "$destination_dir/.cash-skill.XXXXXX" 2>/dev/null)
            if test $status -ne 0; or test -z "$destination_temp"
                fail "cannot create temporary managed file: $destination_dir"
            end
            if test -L "$destination_temp"; or not is_below "$destination_dir" "$destination_temp"
                command rm -f -- "$destination_temp"
                fail "unsafe temporary managed file path: $destination_temp"
            end
            command cp "$source_paths[$index]" "$destination_temp"; or begin
                command rm -f -- "$destination_temp"
                fail "cannot write temporary managed file: $destination"
            end
            command mv -f "$destination_temp" "$destination"; or begin
                command rm -f -- "$destination_temp"
                fail "cannot publish managed file: $destination"
            end
        end
    end
end

for index in $inventory_indexes
    set -l current_source_hash (hash_file "$source_paths[$index]")
    test $status -eq 0; and test "$current_source_hash" = "$source_hashes[$index]"; or fail "source changed during installation: $source_paths[$index]"
    set -l installed_hash (hash_file "$target_path/$relative_paths[$index]")
    test $status -eq 0; and test "$installed_hash" = "$source_hashes[$index]"; or fail "installed bytes do not match receipt content: $target_path/$relative_paths[$index]"
end

command mkdir -p "$receipt_dir"; or fail "cannot create receipt directory: $receipt_dir"
set receipt_temp (command mktemp "$receipt_dir/.receipt.tsv.XXXXXX" 2>/dev/null)
if test $status -ne 0; or test -z "$receipt_temp"
    fail "cannot create temporary receipt below target: $receipt_dir"
end
if test -L "$receipt_temp"; or not is_below "$receipt_dir" "$receipt_temp"
    command rm -f -- "$receipt_temp"
    fail "unsafe temporary receipt path: $receipt_temp"
end

begin
    printf 'version\t%s\n' "$source_version"
    for index in $inventory_indexes
        printf 'sha256\t%s\t%s\n' "$source_hashes[$index]" "$relative_paths[$index]"
    end
end >"$receipt_temp"
if test $status -ne 0
    command rm -f -- "$receipt_temp"
    fail "cannot write temporary receipt: $receipt_temp"
end
command mv -f "$receipt_temp" "$receipt_path"; or begin
    command rm -f -- "$receipt_temp"
    fail "cannot publish receipt: $receipt_path"
end

for relative_path in $retired_plus_present
    set -l skill_dir "$target_path/$relative_path"
    set -l retired_plus_index (contains -i -- "$relative_path" $retired_plus_paths)
    test $status -eq 0; or fail "unknown retired plus inventory path: $relative_path"
    set -l expected_name "$retired_plus_names[$retired_plus_index]"
    set -l parent_dir (command dirname "$skill_dir")
    set -l quarantine (command mktemp -d "$parent_dir/.cash-retired-plus.XXXXXX" 2>/dev/null)
    if test $status -ne 0; or test -z "$quarantine"
        fail "cannot create retired plus quarantine path: $parent_dir"
    end
    if test -L "$quarantine"; or not is_below "$parent_dir" "$quarantine"
        command rmdir "$quarantine" 2>/dev/null
        fail "unsafe retired plus quarantine path: $quarantine"
    end
    command rmdir "$quarantine"; or fail "cannot prepare retired plus quarantine path: $quarantine"
    command mv -h "$skill_dir" "$quarantine"; or fail "cannot quarantine retired plus skill: $skill_dir"

    if test -e "$skill_dir"; or test -L "$skill_dir"; or not valid_retired_plus_skill "$quarantine" "$expected_name"
        if not test -e "$skill_dir"; and not test -L "$skill_dir"
            command mv -h "$quarantine" "$skill_dir"; or fail "retired plus candidate changed after preflight; preserved at quarantine: $quarantine"
        end
        fail "retired plus candidate changed after preflight: $skill_dir"
    end

    command rm -f -- "$quarantine/SKILL.md"; or fail "cannot remove quarantined retired plus skill file: $quarantine/SKILL.md"
    command rmdir "$quarantine"; or fail "cannot remove retired plus quarantine directory: $quarantine"
end

emit_result update
