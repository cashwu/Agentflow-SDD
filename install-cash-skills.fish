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

function path_identity --argument-names path
    command stat -f '%d:%i' "$path" 2>/dev/null
end

function snapshot_canonical_cash_block --argument-names source output
    command perl -MDigest::SHA=sha256_hex -MFcntl=:DEFAULT,:mode -e '
        use strict;
        use warnings;
        my ($source, $output) = @ARGV;

        sub read_handle {
            my ($handle) = @_;
            my $data = "";
            while (1) {
                my $count = sysread($handle, my $chunk, 65536);
                die "cannot read source guidance snapshot: $!\n" unless defined $count;
                last if $count == 0;
                $data .= $chunk;
            }
            return $data;
        }

        sub run_test_hook {
            my ($stage) = @_;
            my $hook = $ENV{CASH_GUIDANCE_TEST_HOOK};
            return unless defined $hook && length $hook;
            system {$hook} $hook, $stage, $source;
            die "guidance snapshot test hook failed at $stage\n" unless $? == 0;
        }

        sysopen(my $input, $source, O_RDONLY | O_NOFOLLOW) or exit 1;
        my @before = stat($input);
        exit 1 unless @before && S_ISREG($before[2]);
        my $data = read_handle($input);
        my @after = stat($input);
        exit 1 unless @after && S_ISREG($after[2])
            && $after[0] == $before[0] && $after[1] == $before[1];
        close $input or exit 1;
        my $source_digest = sha256_hex($data);
        run_test_hook("after-source-snapshot");

        my $cash_start_raw = () = $data =~ /<!-- CASH:START -->/g;
        my $cash_end_raw = () = $data =~ /<!-- CASH:END -->/g;
        my @cash_starts = ($data =~ /(?m)^<!-- CASH:START -->$/g);
        my @cash_ends = ($data =~ /(?m)^<!-- CASH:END -->$/g);
        exit 2 unless $cash_start_raw == 1 && $cash_end_raw == 1;
        exit 2 unless @cash_starts == 1 && @cash_ends == 1;

        my $spectra_start_raw = () = $data =~ /<!-- SPECTRA:START/g;
        my $spectra_end_raw = () = $data =~ /<!-- SPECTRA:END -->/g;
        my @spectra_starts = ($data =~ /(?m)^<!-- SPECTRA:START(?: v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))? -->$/g);
        my @spectra_ends = ($data =~ /(?m)^<!-- SPECTRA:END -->$/g);
        exit 2 unless $spectra_start_raw == @spectra_starts && $spectra_end_raw == @spectra_ends;
        exit 2 unless @spectra_starts == @spectra_ends && @spectra_starts <= 1;

        $data =~ /(?ms)^<!-- CASH:START -->\n.*?^<!-- CASH:END -->(?:\n|\z)/ or exit 2;
        my ($cash_from, $cash_to, $block) = ($-[0], $+[0], $&);
        if (@spectra_starts == 1) {
            $data =~ /(?ms)^<!-- SPECTRA:START(?: v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))? -->\n.*?^<!-- SPECTRA:END -->(?:\n|\z)/ or exit 2;
            my ($spectra_from, $spectra_to) = ($-[0], $+[0]);
            exit 2 unless $cash_to <= $spectra_from || $spectra_to <= $cash_from;
        }

        open my $result, ">", $output or exit 1;
        binmode $result;
        print {$result} $block or exit 1;
        close $result or exit 1;
        run_test_hook("after-source-render");
        print join("\t", $source_digest, "$before[0]:$before[1]", sha256_hex($block)), "\n";
    ' "$source" "$output"
end

function snapshot_render_guidance --argument-names target canonical canonical_digest output
    command perl -MDigest::SHA=sha256_hex -MFcntl=:DEFAULT,:mode -MErrno=ENOENT -e '
        use strict;
        use warnings;
        my ($target, $canonical_path, $canonical_digest, $output) = @ARGV;

        sub read_handle {
            my ($handle) = @_;
            my $data = "";
            while (1) {
                my $count = sysread($handle, my $chunk, 65536);
                die "cannot read guidance snapshot: $!\n" unless defined $count;
                last if $count == 0;
                $data .= $chunk;
            }
            return $data;
        }

        sub run_test_hook {
            my ($stage) = @_;
            my $hook = $ENV{CASH_GUIDANCE_TEST_HOOK};
            return unless defined $hook && length $hook;
            system {$hook} $hook, $stage, $target;
            die "guidance snapshot test hook failed at $stage\n" unless $? == 0;
        }

        my $data = "";
        my ($existed, $digest, $identity, $mode) = (0, "missing", "missing", "0644");
        my @path_stat = lstat($target);
        if (@path_stat) {
            sysopen(my $input, $target, O_RDONLY | O_NOFOLLOW) or exit 1;
            my @before = stat($input);
            exit 1 unless @before && S_ISREG($before[2]);
            $data = read_handle($input);
            my @after = stat($input);
            exit 1 unless @after && S_ISREG($after[2])
                && $after[0] == $before[0] && $after[1] == $before[1];
            close $input or exit 1;
            ($existed, $digest, $identity, $mode) = (
                1,
                sha256_hex($data),
                "$before[0]:$before[1]",
                sprintf("%04o", S_IMODE($before[2])),
            );
        } else {
            exit 1 unless $! == ENOENT;
        }
        run_test_hook("after-target-snapshot");

        sysopen(my $canonical_input, $canonical_path, O_RDONLY | O_NOFOLLOW) or exit 1;
        my $canonical = read_handle($canonical_input);
        close $canonical_input or exit 1;
        exit 1 unless sha256_hex($canonical) eq $canonical_digest;

        my $cash_start_raw = () = $data =~ /<!-- CASH:START -->/g;
        my $cash_end_raw = () = $data =~ /<!-- CASH:END -->/g;
        my @cash_starts = ($data =~ /(?m)^<!-- CASH:START -->$/g);
        my @cash_ends = ($data =~ /(?m)^<!-- CASH:END -->$/g);
        exit 2 unless $cash_start_raw == @cash_starts && $cash_end_raw == @cash_ends;
        exit 2 unless @cash_starts == @cash_ends && @cash_starts <= 1;

        my $spectra_start_raw = () = $data =~ /<!-- SPECTRA:START/g;
        my $spectra_end_raw = () = $data =~ /<!-- SPECTRA:END -->/g;
        my @spectra_starts = ($data =~ /(?m)^<!-- SPECTRA:START(?: v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))? -->$/g);
        my @spectra_ends = ($data =~ /(?m)^<!-- SPECTRA:END -->$/g);
        exit 2 unless $spectra_start_raw == @spectra_starts && $spectra_end_raw == @spectra_ends;
        exit 2 unless @spectra_starts == @spectra_ends && @spectra_starts <= 1;

        my @spans;
        if (@cash_starts == 1) {
            $data =~ /(?ms)^<!-- CASH:START -->\n.*?^<!-- CASH:END -->(?:\n|\z)/ or exit 2;
            push @spans, [$-[0], $+[0], $canonical];
        }
        if (@spectra_starts == 1) {
            $data =~ /(?ms)^<!-- SPECTRA:START(?: v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))? -->\n.*?^<!-- SPECTRA:END -->(?:\n|\z)/ or exit 2;
            my $replacement = @cash_starts == 1 ? "" : $canonical;
            push @spans, [$-[0], $+[0], $replacement];
        }
        @spans = sort { $a->[0] <=> $b->[0] } @spans;
        if (@spans == 2) {
            exit 2 unless $spans[0]->[1] <= $spans[1]->[0];
        }

        my $rendered;
        if (!@spans) {
            my $separator = length($data) && $data !~ /\n\z/ ? "\n" : "";
            $rendered = $data . $separator . $canonical;
        } else {
            my $cursor = 0;
            $rendered = "";
            for my $span (@spans) {
                $rendered .= substr($data, $cursor, $span->[0] - $cursor);
                $rendered .= $span->[2];
                $cursor = $span->[1];
            }
            $rendered .= substr($data, $cursor);
        }

        open my $result, ">", $output or exit 1;
        binmode $result;
        print {$result} $rendered or exit 1;
        close $result or exit 1;
        run_test_hook("after-target-render");
        my $changed = $existed && $data eq $rendered ? 0 : 1;
        print join("\t", $existed, $digest, $identity, $mode, $changed, sha256_hex($rendered)), "\n";
    ' "$target" "$canonical" "$canonical_digest" "$output"
end

function guidance_snapshot_matches --argument-names path existed digest identity parent parent_identity
    test -d "$parent"; and not test -L "$parent"; or return 1
    test (path_identity "$parent") = "$parent_identity"; or return 1
    if test "$existed" = 1
        test -f "$path"; and not test -L "$path"; or return 1
        test (path_identity "$path") = "$identity"; or return 1
        set -l current_digest (hash_file "$path"); or return 1
        test "$current_digest" = "$digest"; or return 1
    else
        not test -e "$path"; and not test -L "$path"; or return 1
    end
end

function source_guidance_snapshot_matches --argument-names path digest identity parent_identity
    test -f "$path"; and test -r "$path"; and not test -L "$path"; or return 1
    test (path_identity "$path") = "$identity"; or return 1
    test (path_identity (command dirname "$path")) = "$parent_identity"; or return 1
    set -l current_digest (hash_file "$path"); or return 1
    test "$current_digest" = "$digest"
end

function guidance_publisher_capability_matches --argument-names parent basename parent_identity
    command perl -MFcntl=:DEFAULT,:mode -MErrno=ENOENT -e '
        use strict;
        use warnings;

        my ($parent, $basename, $parent_identity) = @ARGV;
        die "invalid guidance basename\n" unless $basename =~ /\A(?:AGENTS|CLAUDE)\.md\z/;
        die "invalid parent identity\n" unless $parent_identity =~ /\A([0-9]+):([0-9]+)\z/;
        my ($expected_device, $expected_inode) = ($1, $2);

        sysopen(my $directory_fh, $parent, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
            or die "cannot open guidance parent: $!\n";
        my @held_stat = stat($directory_fh);
        die "guidance parent identity mismatch\n"
            unless @held_stat && S_ISDIR($held_stat[2])
                && $held_stat[0] == $expected_device && $held_stat[1] == $expected_inode;
        chdir($directory_fh) or die "cannot bind guidance parent: $!\n";
        my @working_stat = stat(".");
        die "bound guidance parent identity mismatch\n"
            unless @working_stat && S_ISDIR($working_stat[2])
                && $working_stat[0] == $expected_device && $working_stat[1] == $expected_inode;

        my @child_stat = lstat($basename);
        die "cannot inspect guidance child: $!\n" unless @child_stat || $! == ENOENT;

        my $hook = $ENV{CASH_GUIDANCE_TEST_HOOK};
        if (defined $hook && length $hook) {
            system {$hook} $hook, "capability-preflight", $parent, $basename, "";
            die "guidance capability test hook failed\n" unless $? == 0;
        }
    ' "$parent" "$basename" "$parent_identity"
end

function publish_guidance_anchored --argument-names parent basename rendered rendered_digest existed digest identity parent_identity mode source source_digest source_identity source_parent_identity
    command perl -MDigest::SHA=sha256_hex -MFcntl=:DEFAULT,:mode -MErrno=ENOENT -e '
        use strict;
        use warnings;

        my ($parent, $basename, $rendered, $rendered_digest, $existed, $digest, $identity,
            $parent_identity, $mode_text, $source, $source_digest,
            $source_identity, $source_parent_identity) = @ARGV;
        die "invalid guidance basename\n" unless $basename =~ /\A(?:AGENTS|CLAUDE)\.md\z/;
        die "invalid guidance mode\n" unless $mode_text =~ /\A[0-7]{3,4}\z/;
        my $mode = oct($mode_text);
        my $source_parent = $source;
        $source_parent =~ s{/[^/]+\z}{} or die "invalid source guidance path\n";

        sub expected_identity {
            my ($value) = @_;
            die "invalid expected identity\n" unless $value =~ /\A([0-9]+):([0-9]+)\z/;
            return ($1, $2);
        }

        sub same_identity {
            my ($stat, $expected) = @_;
            my ($device, $inode) = expected_identity($expected);
            return @$stat && $stat->[0] == $device && $stat->[1] == $inode;
        }

        sub read_handle {
            my ($handle) = @_;
            my $data = "";
            while (1) {
                my $count = sysread($handle, my $chunk, 65536);
                die "cannot read snapshot: $!\n" unless defined $count;
                last if $count == 0;
                $data .= $chunk;
            }
            return $data;
        }

        sub verify_source {
            my @parent_stat = lstat($source_parent);
            die "source parent changed\n" unless same_identity(\@parent_stat, $source_parent_identity);
            sysopen(my $input, $source, O_RDONLY | O_NOFOLLOW) or die "cannot open source guidance: $!\n";
            my @source_stat = stat($input);
            die "source guidance changed\n" unless same_identity(\@source_stat, $source_identity) && S_ISREG($source_stat[2]);
            my $data = read_handle($input);
            close($input) or die "cannot close source guidance: $!\n";
            die "source guidance bytes changed\n" unless sha256_hex($data) eq $source_digest;
        }

        sub verify_parent_path {
            my @path_stat = lstat($parent);
            die "guidance parent changed\n" unless same_identity(\@path_stat, $parent_identity) && S_ISDIR($path_stat[2]);
        }

        sub verify_destination {
            if ($existed) {
                my @path_stat = lstat($basename);
                die "target guidance changed\n" unless same_identity(\@path_stat, $identity) && S_ISREG($path_stat[2]);
                sysopen(my $input, $basename, O_RDONLY | O_NOFOLLOW) or die "cannot open target guidance: $!\n";
                my @file_stat = stat($input);
                die "target guidance changed\n" unless same_identity(\@file_stat, $identity) && S_ISREG($file_stat[2]);
                my $data = read_handle($input);
                close($input) or die "cannot close target guidance: $!\n";
                die "target guidance bytes changed\n" unless sha256_hex($data) eq $digest;
                return;
            }

            my @path_stat = lstat($basename);
            die "target guidance appeared\n" if @path_stat;
            die "cannot inspect target guidance: $!\n" unless $! == ENOENT;
        }

        sub run_test_hook {
            my ($stage, $temporary) = @_;
            my $hook = $ENV{CASH_GUIDANCE_TEST_HOOK};
            return unless defined $hook && length $hook;
            $temporary = "" unless defined $temporary;
            system {$hook} $hook, $stage, $parent, $basename, $temporary;
            die "guidance test hook failed at $stage\n" unless $? == 0;
        }

        sysopen(my $rendered_input, $rendered, O_RDONLY | O_NOFOLLOW)
            or die "cannot open rendered guidance: $!\n";
        my $rendered_data = read_handle($rendered_input);
        close($rendered_input) or die "cannot close rendered guidance: $!\n";
        die "rendered guidance bytes changed\n" unless sha256_hex($rendered_data) eq $rendered_digest;

        sysopen(my $directory_fh, $parent, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
            or die "cannot open guidance parent: $!\n";
        my @held_stat = stat($directory_fh);
        die "guidance parent identity mismatch\n"
            unless same_identity(\@held_stat, $parent_identity) && S_ISDIR($held_stat[2]);
        chdir($directory_fh) or die "cannot bind guidance parent: $!\n";
        my @working_stat = stat(".");
        die "bound guidance parent identity mismatch\n"
            unless same_identity(\@working_stat, $parent_identity) && S_ISDIR($working_stat[2]);

        verify_source();
        run_test_hook("before-temp");
        verify_parent_path();
        verify_destination();

        open my $random_input, "<", "/dev/urandom" or die "cannot open random source: $!\n";
        binmode $random_input;
        my $random = "";
        read($random_input, $random, 16) == 16 or die "cannot read random source: $!\n";
        close($random_input) or die "cannot close random source: $!\n";
        my $temporary = ".cash-guidance." . unpack("H*", $random);
        die "invalid temporary basename\n" unless $temporary =~ /\A\.cash-guidance\.[0-9a-f]{32}\z/;
        my $cleanup;
        END {
            if (defined $cleanup && not unlink($cleanup)) {
                warn "cannot clean temporary guidance $cleanup: $!\n";
            }
        }

        run_test_hook("before-temp-create", $temporary);
        sysopen(my $temporary_fh, $temporary, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
            or die "cannot create temporary guidance: $!\n";
        $cleanup = $temporary;
        my $offset = 0;
        while ($offset < length($rendered_data)) {
            my $written = syswrite($temporary_fh, $rendered_data, length($rendered_data) - $offset, $offset);
            die "cannot write temporary guidance: $!\n" unless defined $written && $written > 0;
            $offset += $written;
        }
        chmod($mode, $temporary_fh) == 1 or die "cannot set guidance mode: $!\n";
        close($temporary_fh) or die "cannot close temporary guidance: $!\n";

        verify_source();
        run_test_hook("before-rename");
        verify_parent_path();
        verify_destination();
        run_test_hook("after-verify-before-rename");
        rename($temporary, $basename) or die "cannot publish guidance: $!\n";
        undef $cleanup;
    ' "$parent" "$basename" "$rendered" "$rendered_digest" "$existed" "$digest" "$identity" "$parent_identity" "$mode" "$source" "$source_digest" "$source_identity" "$source_parent_identity"
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

set guidance_relative_paths AGENTS.md CLAUDE.md
set guidance_source_paths
set guidance_source_hashes
set guidance_source_identities
set guidance_source_parent_identities
set guidance_canonical_paths
set guidance_canonical_hashes
set -g guidance_temporary_paths
function cleanup_guidance_temporary_paths --on-event fish_exit
    test (count $guidance_temporary_paths) -eq 0; or command rm -f -- $guidance_temporary_paths
end

for relative_path in $guidance_relative_paths
    set -l source_path "$script_dir/$relative_path"
    if test -L "$source_path"; or not test -f "$source_path"; or not test -r "$source_path"
        fail "invalid or missing source guidance: $source_path"
    end
    set -l source_parent_identity (path_identity "$script_dir")
    test $status -eq 0; and test -n "$source_parent_identity"; or fail "cannot identify source guidance parent: $script_dir"
    set -l canonical_path (command mktemp /tmp/.cash-guidance-source.XXXXXX 2>/dev/null)
    test $status -eq 0; and test -n "$canonical_path"; or fail "cannot create source guidance snapshot"
    set -a guidance_temporary_paths "$canonical_path"
    set -l source_metadata (snapshot_canonical_cash_block "$source_path" "$canonical_path")
    test $status -eq 0; or fail "invalid canonical Cash guidance markers: $source_path"
    set -l source_fields (string split \t -- "$source_metadata")
    test (count $source_fields) -eq 3; or fail "invalid source guidance snapshot metadata: $source_path"
    set -l source_digest "$source_fields[1]"
    set -l source_identity "$source_fields[2]"
    set -l canonical_digest "$source_fields[3]"
    string match -rq '^[0-9a-f]{64}$' -- "$source_digest"; or fail "invalid source guidance snapshot digest: $source_path"
    string match -rq '^[0-9]+:[0-9]+$' -- "$source_identity"; or fail "invalid source guidance snapshot identity: $source_path"
    string match -rq '^[0-9a-f]{64}$' -- "$canonical_digest"; or fail "invalid canonical guidance snapshot digest: $source_path"

    set -a guidance_source_paths "$source_path"
    set -a guidance_source_hashes "$source_digest"
    set -a guidance_source_identities "$source_identity"
    set -a guidance_source_parent_identities "$source_parent_identity"
    set -a guidance_canonical_paths "$canonical_path"
    set -a guidance_canonical_hashes "$canonical_digest"
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

for relative_path in $relative_paths $guidance_relative_paths .cash-skills/receipt.tsv
    is_below "$target_path" "$target_path/$relative_path"; or fail "managed path escapes target: $relative_path"
    validate_managed_boundary "$target_path" "$relative_path"; or exit 1
end

set guidance_exists
set guidance_hashes
set guidance_identities
set guidance_parent_identities
set guidance_modes
set guidance_rendered_paths
set guidance_rendered_hashes
set guidance_changed
for index in 1 2
    set -l relative_path "$guidance_relative_paths[$index]"
    set -l destination "$target_path/$relative_path"
    set -l parent (command dirname "$destination")
    if not test -d "$parent"; or test -L "$parent"; or not test -w "$parent"; or not test -x "$parent"
        fail "guidance parent is not a writable regular directory: $parent"
    end
    set -l parent_identity (path_identity "$parent")
    test $status -eq 0; and test -n "$parent_identity"; or fail "cannot identify guidance parent: $parent"

    if test -e "$destination"; or test -L "$destination"
        if test -L "$destination"; or not test -f "$destination"; or not test -r "$destination"; or not test -w "$destination"
            fail "invalid target guidance: $destination"
        end
    end

    set -l rendered_path (command mktemp /tmp/.cash-guidance-rendered.XXXXXX 2>/dev/null)
    test $status -eq 0; and test -n "$rendered_path"; or fail "cannot create rendered guidance snapshot"
    set -a guidance_temporary_paths "$rendered_path"
    set -l target_metadata (snapshot_render_guidance "$destination" "$guidance_canonical_paths[$index]" "$guidance_canonical_hashes[$index]" "$rendered_path")
    test $status -eq 0; or fail "invalid Cash or Spectra guidance markers: $destination"
    set -l target_fields (string split \t -- "$target_metadata")
    test (count $target_fields) -eq 6; or fail "invalid target guidance snapshot metadata: $destination"
    set -l existed "$target_fields[1]"
    set -l digest "$target_fields[2]"
    set -l identity "$target_fields[3]"
    set -l mode "$target_fields[4]"
    set -l changed "$target_fields[5]"
    set -l rendered_digest "$target_fields[6]"
    string match -rq '^[01]$' -- "$existed"; or fail "invalid target guidance snapshot existence: $destination"
    string match -rq '^[01]$' -- "$changed"; or fail "invalid target guidance snapshot change state: $destination"
    string match -rq '^[0-7]{3,4}$' -- "$mode"; or fail "invalid target guidance snapshot mode: $destination"
    string match -rq '^[0-9a-f]{64}$' -- "$rendered_digest"; or fail "invalid rendered guidance snapshot digest: $destination"
    if test "$existed" = 1
        string match -rq '^[0-9a-f]{64}$' -- "$digest"; or fail "invalid target guidance snapshot digest: $destination"
        string match -rq '^[0-9]+:[0-9]+$' -- "$identity"; or fail "invalid target guidance snapshot identity: $destination"
    else
        test "$digest" = missing; and test "$identity" = missing; or fail "invalid missing guidance snapshot metadata: $destination"
    end
    set -a guidance_exists "$existed"
    set -a guidance_hashes "$digest"
    set -a guidance_identities "$identity"
    set -a guidance_parent_identities "$parent_identity"
    set -a guidance_modes "$mode"
    set -a guidance_rendered_paths "$rendered_path"
    set -a guidance_rendered_hashes "$rendered_digest"
    set -a guidance_changed "$changed"
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

    if test (count $conflicts) -eq 0; and test $version_comparison -eq 0; and test (count $retired_plus_present) -eq 0; and not contains -- 1 $guidance_changed
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

for index in 1 2
    test "$guidance_changed[$index]" = 1; or continue
    guidance_publisher_capability_matches \
        "$target_path" \
        "$guidance_relative_paths[$index]" \
        "$guidance_parent_identities[$index]"
    or fail "guidance publisher capability validation failed: $target_path/$guidance_relative_paths[$index]"
end

for index in $inventory_indexes
    if test "$target_hashes[$index]" = "$source_hashes[$index]"
        echo "unchanged: $relative_paths[$index]"
    else if test "$target_exists[$index]" = 1
        echo "replace: $relative_paths[$index]"
    else
        echo "install: $relative_paths[$index]"
    end
end
for index in 1 2
    if test "$guidance_changed[$index]" = 0
        echo "guidance unchanged: $guidance_relative_paths[$index]"
    else if test "$guidance_exists[$index]" = 1
        echo "guidance replace: $guidance_relative_paths[$index]"
    else
        echo "guidance install: $guidance_relative_paths[$index]"
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

for index in 1 2
    test "$guidance_changed[$index]" = 1; or continue
    set -l destination "$target_path/$guidance_relative_paths[$index]"
    set -l parent (command dirname "$destination")
    source_guidance_snapshot_matches \
        "$guidance_source_paths[$index]" \
        "$guidance_source_hashes[$index]" \
        "$guidance_source_identities[$index]" \
        "$guidance_source_parent_identities[$index]"
    or fail "source guidance changed after preflight: $guidance_source_paths[$index]"
    guidance_snapshot_matches \
        "$destination" \
        "$guidance_exists[$index]" \
        "$guidance_hashes[$index]" \
        "$guidance_identities[$index]" \
        "$parent" \
        "$guidance_parent_identities[$index]"
    or fail "target guidance changed after preflight: $destination"

    publish_guidance_anchored \
        "$parent" \
        "$guidance_relative_paths[$index]" \
        "$guidance_rendered_paths[$index]" \
        "$guidance_rendered_hashes[$index]" \
        "$guidance_exists[$index]" \
        "$guidance_hashes[$index]" \
        "$guidance_identities[$index]" \
        "$guidance_parent_identities[$index]" \
        "$guidance_modes[$index]" \
        "$guidance_source_paths[$index]" \
        "$guidance_source_hashes[$index]" \
        "$guidance_source_identities[$index]" \
        "$guidance_source_parent_identities[$index]"
    or fail "cannot publish guidance file: $destination"
end

for index in $inventory_indexes
    set -l current_source_hash (hash_file "$source_paths[$index]")
    test $status -eq 0; and test "$current_source_hash" = "$source_hashes[$index]"; or fail "source changed during installation: $source_paths[$index]"
    set -l installed_hash (hash_file "$target_path/$relative_paths[$index]")
    test $status -eq 0; and test "$installed_hash" = "$source_hashes[$index]"; or fail "installed bytes do not match receipt content: $target_path/$relative_paths[$index]"
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

emit_result update
