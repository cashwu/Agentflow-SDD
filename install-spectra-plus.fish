#!/usr/bin/env fish

set script_name (basename (status --current-filename))
set script_dir (cd (dirname (status --current-filename)); and pwd)
set --global --unexport __spectra_plus_repair_snapshot ""
set --global --unexport __spectra_plus_rules_file ""

function usage
    echo "使用方式："
    echo "  ./$script_name --target <專案目錄> [--dry-run]"
    echo "  ./$script_name <專案目錄> [--dry-run]"
    echo "  ./$script_name --register-target <專案目錄> [--dry-run]"
    echo "  ./$script_name --unregister-target <專案目錄> [--dry-run]"
    echo "  ./$script_name --list-targets"
    echo "  ./$script_name --repair-all [--dry-run] [--force]"
    echo "  ./$script_name --install-launch-agent [--dry-run]"
    echo "  ./$script_name --uninstall-launch-agent [--dry-run]"
    echo ""
    echo "功能："
    echo "  將 scripts/spectra-plus 安裝到目標專案，並產生 spectra-propose-plus / spectra-apply-plus。"
    echo "  可註冊多個 project target，使用 --repair-all 批次修復 generated plus skills 與 spectra-commit guard。"
    echo ""
    echo "必要條件："
    echo "  目標專案已存在 .claude/skills/spectra-propose/SKILL.md"
    echo "  目標專案已存在 .claude/skills/spectra-apply/SKILL.md"
    echo "  目標專案已存在 .claude/skills/spectra-commit/SKILL.md"
    echo "  目標專案已存在 .agents/skills/spectra-propose/SKILL.md（Codex 變體）"
    echo "  目標專案已存在 .agents/skills/spectra-apply/SKILL.md（Codex 變體）"
    echo "  目標專案已存在 .agents/skills/spectra-commit/SKILL.md（Codex 變體）"
    echo "  本機可執行 fish 與 yq（macOS 可用 brew install yq 安裝）"
    echo ""
    echo "其他選項："
    echo "  --dry-run        只印出將要執行的動作，不實際變更檔案。"
    echo "  --register-target <專案目錄>      註冊要由 repair-all 維護的 project。"
    echo "  --unregister-target <專案目錄>    從 registry 移除 project；路徑可已不存在。"
    echo "  --list-targets                    列出 registry 內的 target。"
    echo "  --repair-all                      修復所有已註冊 target。"
    echo "  --install-launch-agent            安裝 macOS LaunchAgent 自動執行 repair-all。"
    echo "  --uninstall-launch-agent          移除 macOS LaunchAgent。"
    echo "  --force          repair-all 略過 throttle；不略過 lock。"
    echo "  -h, --help       顯示此說明。"
end

function fail
    echo "錯誤：$argv" >&2
    exit 1
end

function cleanup_repair_snapshot
    if test -z "$__spectra_plus_repair_snapshot"
        return 0
    end

    if test -e "$__spectra_plus_repair_snapshot"
        if not command rm -rf -- "$__spectra_plus_repair_snapshot"
            echo "錯誤：無法清理 repair-all pinned snapshot：$__spectra_plus_repair_snapshot" >&2
            return 1
        end
    end

    set --global --unexport __spectra_plus_repair_snapshot ""
    return 0
end

function cleanup_repair_snapshot_on_exit --on-event fish_exit
    cleanup_repair_snapshot >/dev/null
end

function run_cmd
    if test $dry_run -eq 1
        printf "+"
        for part in $argv
            printf " %s" (string escape -- $part)
        end
        printf "\n"
    else
        command $argv
    end
end

function require_file --argument-names path description
    if not test -f "$path"
        fail "找不到 $description：$path"
    end
end

function assert_contains --argument-names path text description
    if not rg -q --fixed-strings "$text" "$path"
        fail "$description 缺少必要內容：$text"
    end
end

function assert_not_contains --argument-names path text description
    if rg -q --fixed-strings "$text" "$path"
        fail "$description 含有已棄用內容：$text"
    end
end

function validate_commit_guard --argument-names path description
    set marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"

    assert_contains "$path" "$marker" "$description"
    assert_contains "$path" ".agents/skills/spectra-*-plus/" "$description"
    assert_contains "$path" ".claude/skills/spectra-*-plus/" "$description"
    assert_contains "$path" "openspec/changes/archive/<date>-<change>/" "$description"
    assert_contains "$path" "Do not treat the full post-archive dirty state as archive output." "$description"
    assert_contains "$path" "except protected generated plus skill deletions" "$description"
    assert_not_contains "$path" "openspec/archived/" "$description"
    assert_not_contains "$path" "docs/specs/" "$description"
end

function ensure_commit_guard --argument-names target_path source_path description
    set marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"
    set marker_end "<!-- SPECTRA-COMMIT-GUARD:END -->"
    set guard_insert_after '   From the full `git status --porcelain` output, any dirty files NOT in the artifact set and NOT in the tracking file are "unrelated changes."'
    set user_start "6. **User confirmation**"
    set subflow_start "6a. **Archive sub-flow**"
    set archive_start "    **6a-iii. Archive execution and file collection**"
    set archive_end "    Then continue to step 7."

    require_file "$target_path" "$description"
    require_file "$source_path" "$description source"

    restore_source_guard_if_needed "$source_path" "$description source"
    set restore_rc $status
    if test $restore_rc -ne 2
        validate_commit_guard "$source_path" "$description source"
    end

    if rg -q --fixed-strings "$marker" "$target_path"
        if test $dry_run -eq 1
            validate_commit_guard "$target_path" "$description"
            echo "+ verify spectra-commit guard in $target_path"
            return
        end

        validate_commit_guard "$target_path" "$description"
        return
    end

    for anchor in "$guard_insert_after" "$user_start" "$subflow_start" "$archive_start" "$archive_end" "Archive first, then commit together"
        if not rg -q --fixed-strings "$anchor" "$target_path"
            fail "無法安全套用 spectra-commit guard 到 $target_path；找不到 section：$anchor"
        end
    end

    if test $dry_run -eq 1
        echo "+ update spectra-commit guard in $target_path"
        return
    end

    set guard_block (mktemp)
    awk -v marker="$marker" -v marker_end="$marker_end" '
        index($0, marker) { in_block = 1 }
        in_block { print }
        index($0, marker_end) { exit }
    ' "$source_path" > "$guard_block"
    test -s "$guard_block"; or fail "無法從 $source_path 讀取 spectra-commit guard block"

    set archive_block (mktemp)
    awk -v start="$archive_start" -v end="$archive_end" '
        index($0, start) { in_block = 1 }
        in_block { print }
        in_block && index($0, end) { exit }
    ' "$source_path" > "$archive_block"
    test -s "$archive_block"; or fail "無法從 $source_path 讀取 spectra-commit archive section"

    set user_block (mktemp)
    awk -v start="$user_start" -v end="$subflow_start" '
        index($0, start) { in_block = 1 }
        in_block && index($0, end) { exit }
        in_block { print }
    ' "$source_path" > "$user_block"
    test -s "$user_block"; or fail "無法從 $source_path 讀取 spectra-commit user confirmation section"

    set with_guard (mktemp)
    awk -v insert_after="$guard_insert_after" -v guard_path="$guard_block" '
        BEGIN {
            while ((getline line < guard_path) > 0) {
                guard = guard line "\n"
            }
            close(guard_path)
        }
        {
            print
            if ($0 == insert_after) {
                print ""
                printf "%s", guard
            }
        }
    ' "$target_path" > "$with_guard"

    set with_user (mktemp)
    awk -v start="$user_start" -v end="$subflow_start" -v user_path="$user_block" '
        BEGIN {
            while ((getline line < user_path) > 0) {
                user = user line "\n"
            }
            close(user_path)
        }
        index($0, start) {
            printf "%s", user
            skip = 1
            next
        }
        skip && index($0, end) {
            skip = 0
            print
            next
        }
        skip { next }
        { print }
    ' "$with_guard" > "$with_user"

    set patched (mktemp)
    awk -v start="$archive_start" -v end="$archive_end" -v archive_path="$archive_block" '
        BEGIN {
            while ((getline line < archive_path) > 0) {
                archive = archive line "\n"
            }
            close(archive_path)
        }
        index($0, start) {
            printf "%s", archive
            skip = 1
            next
        }
        skip && index($0, end) {
            skip = 0
            next
        }
        skip { next }
        { print }
    ' "$with_user" > "$patched"

    validate_commit_guard "$patched" "$description"
    command mv -f "$patched" "$target_path"
    validate_commit_guard "$target_path" "$description"
end

function require_command --argument-names name
    if not command -q "$name"
        if test "$name" = "yq"
            echo "錯誤：找不到必要指令：yq" >&2
            echo "" >&2
            echo "請先安裝 yq 後再重跑 installer。" >&2
            echo "macOS / Homebrew：" >&2
            echo "  brew install yq" >&2
            echo "" >&2
            echo "安裝後確認：" >&2
            echo "  yq --version" >&2
            exit 1
        end
        fail "找不到必要指令：$name"
    end
end

function registry_file
    echo "$HOME/.config/spectra-plus/projects.txt"
end

function cache_dir
    echo "$HOME/.cache/spectra-plus"
end

function lock_dir
    set tmp_root "$TMPDIR"
    if test -z "$tmp_root"
        set tmp_root /tmp
    end
    echo "$tmp_root/spectra-plus-repair.lock"
end

function materialize_repair_snapshot
    require_command git
    require_command tar

    set source_top (git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)
    test -n "$source_top"; or fail "無法解析 repair-all source checkout"

    set source_commit (git -C "$source_top" rev-parse --verify 'HEAD^{commit}' 2>/dev/null)
    test -n "$source_commit"; or fail "無法解析 repair-all pinned commit"

    set tmp_root "$TMPDIR"
    if test -z "$tmp_root"
        set tmp_root /tmp
    end

    set snapshot (mktemp -d "$tmp_root/spectra-plus-snapshot.XXXXXX" 2>/dev/null)
    test $status -eq 0; and test -n "$snapshot"; or fail "無法建立 repair-all pinned snapshot"
    set --global --unexport __spectra_plus_repair_snapshot "$snapshot"

    set archive_path "$snapshot/.source.tar"
    git -C "$source_top" archive --format=tar -o "$archive_path" "$source_commit" -- \
        install-spectra-plus.fish \
        scripts/spectra-plus/generate.fish \
        scripts/spectra-plus/rules.yaml \
        scripts/spectra-plus/template \
        .claude/skills/spectra-commit \
        .agents/skills/spectra-commit
    test $status -eq 0; or fail "無法封裝 repair-all pinned snapshot"

    tar -xf "$archive_path" -C "$snapshot"
    test $status -eq 0; or fail "無法解壓 repair-all pinned snapshot"
    command rm -f -- "$archive_path"
end

function normalize_existing_dir --argument-names path
    if not test -d "$path"
        return 1
    end
    cd "$path"; and pwd
end

function normalize_registry_path --argument-names path
    if test -d "$path"
        normalize_existing_dir "$path"
        return $status
    end

    if string match -q "/*" -- "$path"
        string replace -r '/+$' '' -- "$path"
    else
        set cwd (pwd)
        string replace -r '/+$' '' -- "$cwd/$path"
    end
end

function read_registry_targets
    set registry (registry_file)
    if not test -f "$registry"
        return 0
    end

    while read --line line
        set line (string trim -- "$line")
        if test -z "$line"; or string match -q "#*" -- "$line"
            continue
        end
        echo "$line"
    end < "$registry"
end

function register_target --argument-names path
    set normalized (normalize_existing_dir "$path")
    if test $status -ne 0
        echo "錯誤：invalid target project directory: $path" >&2
        return 1
    end

    set registry (registry_file)
    if test $dry_run -eq 1
        echo "+ register target $normalized in $registry"
        return 0
    end

    mkdir -p (dirname "$registry")
    if test -f "$registry"; and rg -q --fixed-strings --line-regexp "$normalized" "$registry"
        echo "target already registered: $normalized"
        return 0
    end

    printf '%s\n' "$normalized" >> "$registry"
    echo "registered target: $normalized"
end

function unregister_target --argument-names path
    set normalized (normalize_registry_path "$path")
    set registry (registry_file)

    if test $dry_run -eq 1
        echo "+ unregister target $normalized from $registry"
        return 0
    end

    if not test -f "$registry"
        echo "unregister no-op: $normalized"
        return 0
    end

    set tmp_registry (mktemp)
    set removed 0
    while read --line line
        if test "$line" = "$normalized"
            set removed 1
            continue
        end
        printf '%s\n' "$line" >> "$tmp_registry"
    end < "$registry"
    command mv -f "$tmp_registry" "$registry"

    if test $removed -eq 1
        echo "unregistered target: $normalized"
    else
        echo "unregister no-op: $normalized"
    end
end

function list_targets
    read_registry_targets
end

function file_has --argument-names path text
    test -f "$path"; and rg -q --fixed-strings "$text" "$path"
end

function file_lacks --argument-names path text
    test -f "$path"; or return 1
    rg -q --fixed-strings "$text" "$path"
    set match_status $status
    switch $match_status
        case 0
            return 1
        case 1
            return 0
        case '*'
            return $match_status
    end
end

function frontmatter_has --argument-names path text
    test -f "$path"; or return 1
    awk -v text="$text" '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { exit }
        in_fm && $0 == text { found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$path"
end

function assert_frontmatter_contains --argument-names path text description
    if not frontmatter_has "$path" "$text"
        fail "$description frontmatter 缺少必要內容：$text"
    end
end

function plus_skill_names
    # These generated plus skills intentionally share one freshness marker.
    echo spectra-propose-plus
    echo spectra-apply-plus
end

function valid_iso_date --argument-names value
    string match -qr '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' -- "$value"; or return 1

    set parsed (date -j -f "%Y-%m-%d" "$value" "+%Y-%m-%d" 2>/dev/null)
    if test $status -eq 0; and test "$parsed" = "$value"
        return 0
    end

    set parsed (date -d "$value" "+%Y-%m-%d" 2>/dev/null)
    if test $status -eq 0; and test "$parsed" = "$value"
        return 0
    end

    return 1
end

function plus_metadata_value --argument-names field
    switch "$field"
        case spectraPlusVersion
            if set -q __spectra_plus_metadata_version
                echo $__spectra_plus_metadata_version
                return 0
            end
        case spectraPlusUpdated
            if set -q __spectra_plus_metadata_updated
                echo $__spectra_plus_metadata_updated
                return 0
            end
        case '*'
            fail "rules.yaml parse error: unknown plus metadata field $field"
    end

    set rules_file "$__spectra_plus_rules_file"
    if test -z "$rules_file"
        set rules_file "$script_dir/scripts/spectra-plus/rules.yaml"
    end
    require_command yq
    require_file "$rules_file" "spectra-plus rules.yaml"

    set plus_skills (plus_skill_names)
    for skill in $plus_skills
        if not yq -e ".skills.\"$skill\".metadata | has(\"$field\")" "$rules_file" >/dev/null
            fail "rules.yaml parse error: $skill metadata missing field $field"
        end
        if not yq -e ".skills.\"$skill\".metadata.\"$field\" | type == \"!!str\"" "$rules_file" >/dev/null
            fail "rules.yaml parse error: $skill metadata field $field must be a non-empty string"
        end
        set value (yq -r ".skills.\"$skill\".metadata.\"$field\"" "$rules_file")
        if test -z (string trim -- "$value")
            fail "rules.yaml parse error: $skill metadata field $field must be a non-empty string"
        end
    end

    set reference_skill $plus_skills[1]
    set reference_value (yq -r ".skills.\"$reference_skill\".metadata.\"$field\"" "$rules_file")
    for skill in $plus_skills[2..-1]
        set skill_value (yq -r ".skills.\"$skill\".metadata.\"$field\"" "$rules_file")
        if test "$reference_value" != "$skill_value"
            fail "rules.yaml parse error: mismatched plus metadata field $field"
        end
    end

    if test "$field" = "spectraPlusUpdated"; and not valid_iso_date "$reference_value"
        fail "rules.yaml parse error: metadata field spectraPlusUpdated must be a valid YYYY-MM-DD date"
    end

    switch "$field"
        case spectraPlusVersion
            set -g __spectra_plus_metadata_version "$reference_value"
        case spectraPlusUpdated
            set -g __spectra_plus_metadata_updated "$reference_value"
    end

    echo "$reference_value"
end

function validate_plus_metadata_source
    plus_metadata_value spectraPlusVersion >/dev/null
    plus_metadata_value spectraPlusUpdated >/dev/null
end

function use_plus_rules_file --argument-names rules_file
    set --global --unexport __spectra_plus_rules_file "$rules_file"
    set -e __spectra_plus_metadata_version
    set -e __spectra_plus_metadata_updated
end

function guard_is_current --argument-names path
    set marker "<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->"
    file_has "$path" "$marker"; or return $status
    file_has "$path" ".agents/skills/spectra-*-plus/"; or return $status
    file_has "$path" ".claude/skills/spectra-*-plus/"; or return $status
    file_has "$path" "openspec/changes/archive/<date>-<change>/"; or return $status
    file_has "$path" "Do not treat the full post-archive dirty state as archive output."; or return $status
    file_has "$path" "except protected generated plus skill deletions"; or return $status
    file_lacks "$path" "openspec/archived/"; or return $status
    file_lacks "$path" "docs/specs/"; or return $status
end

function restore_source_guard_if_needed --argument-names source_path description
    # Self-heal a stripped commit-guard source from git HEAD.
    # Return codes:
    #   0 — source is valid on disk now (already valid, or really restored),
    #       OR cannot be restored (caller then fails loudly via validate_commit_guard).
    #   2 — dry-run only: a restore would happen and HEAD is valid, so the caller
    #       MUST skip the hard source validation (the file is intentionally not mutated).
    guard_is_current "$source_path"; and return 0

    set source_dir (dirname "$source_path")
    set toplevel (git -C "$source_dir" rev-parse --show-toplevel 2>/dev/null)
    test -n "$toplevel"; or return 0

    set abs_source (realpath "$source_path" 2>/dev/null); or set abs_source "$source_path"
    set real_top (realpath "$toplevel" 2>/dev/null); or set real_top "$toplevel"
    set relpath (string replace -- "$real_top/" "" "$abs_source")
    test "$relpath" != "$abs_source"; or return 0

    set head_blob (mktemp)
    if not git -C "$toplevel" show "HEAD:$relpath" >"$head_blob" 2>/dev/null
        command rm -f "$head_blob"
        return 0
    end
    if not guard_is_current "$head_blob"
        command rm -f "$head_blob"
        return 0
    end
    command rm -f "$head_blob"

    if test $dry_run -eq 1
        echo "+ would restore $relpath from HEAD"
        return 2
    end

    if git -C "$toplevel" restore --source=HEAD -- "$relpath"
        echo "restored $relpath from HEAD"
    end
    # If restore failed, fall through: the source stays invalid and the caller's
    # validate_commit_guard fails loudly rather than logging a false success.
    return 0
end

function plus_outputs_are_current --argument-names target_path
    set propose_outputs \
        "$target_path/.claude/skills/spectra-propose-plus/SKILL.md" \
        "$target_path/.agents/skills/spectra-propose-plus/SKILL.md"
    set apply_outputs \
        "$target_path/.claude/skills/spectra-apply-plus/SKILL.md" \
        "$target_path/.agents/skills/spectra-apply-plus/SKILL.md"
    set plus_version (plus_metadata_value spectraPlusVersion)
    set plus_updated (plus_metadata_value spectraPlusUpdated)

    for skill_path in $apply_outputs
        file_has "$skill_path" "ai 的回覆要用中文"; or return $status
        file_has "$skill_path" "Implementation Notes Protocol"; or return $status
        file_has "$skill_path" "Surgical & Simplicity Discipline"; or return $status
        file_has "$skill_path" "Simplicity First"; or return $status
        file_has "$skill_path" "Surgical Changes"; or return $status
        file_has "$skill_path" "Maintain Balance"; or return $status
        file_has "$skill_path" "8. **Implementation Notes Protocol**"; or return $status
        file_has "$skill_path" "9. **Final check**"; or return $status
        file_has "$skill_path" "10. **On completion or pause, show status**"; or return $status
        file_has "$skill_path" "11. **Apply-plus response language**"; or return $status
        file_has "$skill_path" "12. **Sub-Agent Review/Rating/Fix Loop**"; or return $status
        file_has "$skill_path" "Reviewer A — Adherence in the Sub-Agent Review/Rating/Fix Loop MUST"; or return $status
        file_has "$skill_path" "archive guidance is deferred until the plus quality gate passes"; or return $status
        file_has "$skill_path" "All tasks complete. The plus quality gate runs next; archive guidance is shown only if it passes."; or return $status
        file_has "$skill_path" 'Do not suggest archive before the Sub-Agent Review/Rating/Fix Loop has ended with `decision: passed`.'; or return $status
        file_lacks "$skill_path" "All tasks complete! You can archive this change with"; or return $status
        file_lacks "$skill_path" "The review-loop reviewer"; or return $status
        file_lacks "$skill_path" "Section 10"; or return $status
        file_lacks "$skill_path" "step 11"; or return $status
    end

    for skill_path in $propose_outputs $apply_outputs
        frontmatter_has "$skill_path" "spectraPlusVersion: $plus_version"; or return $status
        frontmatter_has "$skill_path" "spectraPlusUpdated: $plus_updated"; or return $status
        file_has "$skill_path" "Reviewer A — Adherence"; or return $status
        file_has "$skill_path" "Reviewer B — Quality"; or return $status
        file_has "$skill_path" "Confidence scoring rubric"; or return $status
        file_has "$skill_path" "Confidence filter"; or return $status
        file_has "$skill_path" "Common false positives"; or return $status
        file_has "$skill_path" "Direct artifact-requirement violations MUST score"; or return $status
        file_lacks "$skill_path" "Codex Plan Mode"; or return $status
        file_lacks "$skill_path" "ExitPlanMode"; or return $status
        file_lacks "$skill_path" "EnterPlanMode"; or return $status
        file_lacks "$skill_path" "docs/specs/"; or return $status
    end

    for skill_path in $propose_outputs
        file_has "$skill_path" "8. **Validation**"; or return $status
        file_has "$skill_path" "9. **Sub-Agent Review/Rating/Fix Loop**"; or return $status
        file_has "$skill_path" "10. **Finish the plus proposal workflow**"; or return $status
        file_has "$skill_path" 'has passed. If validation fixes are required, complete them before entering this loop.'; or return $status
        file_has "$skill_path" 'if any fix action modifies proposal, design, tasks, or spec artifacts, run `spectra validate "<name>"` again'; or return $status
        file_lacks "$skill_path" "Surgical & Simplicity Discipline"; or return $status
        file_lacks "$skill_path" "Maintain Balance"; or return $status
    end
end

function validate_plus_outputs_current --argument-names target_path
    set propose_outputs \
        "$target_path/.claude/skills/spectra-propose-plus/SKILL.md" \
        "$target_path/.agents/skills/spectra-propose-plus/SKILL.md"
    set apply_outputs \
        "$target_path/.claude/skills/spectra-apply-plus/SKILL.md" \
        "$target_path/.agents/skills/spectra-apply-plus/SKILL.md"
    set plus_version (plus_metadata_value spectraPlusVersion)
    set plus_updated (plus_metadata_value spectraPlusUpdated)

    for skill_path in $apply_outputs
        assert_contains "$skill_path" "ai 的回覆要用中文" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "Implementation Notes Protocol" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "Surgical & Simplicity Discipline" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "Simplicity First" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "Surgical Changes" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "Maintain Balance" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "8. **Implementation Notes Protocol**" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "9. **Final check**" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "10. **On completion or pause, show status**" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "11. **Apply-plus response language**" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "12. **Sub-Agent Review/Rating/Fix Loop**" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "Reviewer A — Adherence in the Sub-Agent Review/Rating/Fix Loop MUST" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "archive guidance is deferred until the plus quality gate passes" "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" "All tasks complete. The plus quality gate runs next; archive guidance is shown only if it passes." "spectra-apply-plus ($skill_path)"
        assert_contains "$skill_path" 'Do not suggest archive before the Sub-Agent Review/Rating/Fix Loop has ended with `decision: passed`.' "spectra-apply-plus ($skill_path)"
        assert_not_contains "$skill_path" "All tasks complete! You can archive this change with" "spectra-apply-plus ($skill_path)"
        assert_not_contains "$skill_path" "The review-loop reviewer" "spectra-apply-plus ($skill_path)"
        assert_not_contains "$skill_path" "Section 10" "spectra-apply-plus ($skill_path)"
        assert_not_contains "$skill_path" "step 11" "spectra-apply-plus ($skill_path)"
    end

    for skill_path in $propose_outputs $apply_outputs
        assert_frontmatter_contains "$skill_path" "spectraPlusVersion: $plus_version" "spectra plus skill ($skill_path)"
        assert_frontmatter_contains "$skill_path" "spectraPlusUpdated: $plus_updated" "spectra plus skill ($skill_path)"
        assert_contains "$skill_path" "Reviewer A — Adherence" "spectra plus skill ($skill_path)"
        assert_contains "$skill_path" "Reviewer B — Quality" "spectra plus skill ($skill_path)"
        assert_contains "$skill_path" "Confidence scoring rubric" "spectra plus skill ($skill_path)"
        assert_contains "$skill_path" "Confidence filter" "spectra plus skill ($skill_path)"
        assert_contains "$skill_path" "Common false positives" "spectra plus skill ($skill_path)"
        assert_contains "$skill_path" "Direct artifact-requirement violations MUST score" "spectra plus skill ($skill_path)"
        assert_not_contains "$skill_path" "Codex Plan Mode" "spectra plus skill ($skill_path)"
        assert_not_contains "$skill_path" "ExitPlanMode" "spectra plus skill ($skill_path)"
        assert_not_contains "$skill_path" "EnterPlanMode" "spectra plus skill ($skill_path)"
        assert_not_contains "$skill_path" "docs/specs/" "spectra plus skill ($skill_path)"
    end

    for skill_path in $propose_outputs
        assert_contains "$skill_path" "8. **Validation**" "spectra-propose-plus ($skill_path)"
        assert_contains "$skill_path" "9. **Sub-Agent Review/Rating/Fix Loop**" "spectra-propose-plus ($skill_path)"
        assert_contains "$skill_path" "10. **Finish the plus proposal workflow**" "spectra-propose-plus ($skill_path)"
        assert_contains "$skill_path" 'has passed. If validation fixes are required, complete them before entering this loop.' "spectra-propose-plus ($skill_path)"
        assert_contains "$skill_path" 'if any fix action modifies proposal, design, tasks, or spec artifacts, run `spectra validate "<name>"` again' "spectra-propose-plus ($skill_path)"
        assert_not_contains "$skill_path" "Surgical & Simplicity Discipline" "spectra-propose-plus ($skill_path)"
        assert_not_contains "$skill_path" "Maintain Balance" "spectra-propose-plus ($skill_path)"
    end
end

function target_is_current --argument-names target_path
    plus_outputs_are_current "$target_path"; or return $status
    guard_is_current "$target_path/.claude/skills/spectra-commit/SKILL.md"; or return $status
    guard_is_current "$target_path/.agents/skills/spectra-commit/SKILL.md"; or return $status
    return 0
end

function lock_mtime --argument-names path
    stat -f %m "$path" 2>/dev/null
end

function acquire_repair_lock
    set path (lock_dir)
    if mkdir "$path" 2>/dev/null
        echo "$path"
        return 0
    end

    set now (date +%s)
    set mtime (lock_mtime "$path")
    if test -n "$mtime"; and test (math "$now - $mtime") -gt 300
        rm -rf "$path"
        if mkdir "$path" 2>/dev/null
            echo "$path"
            return 0
        end
    end

    echo "[skipped] locked: repair-all is already running ($path)"
    return 1
end

function repair_all
    set throttle_window 60
    set throttle_file (cache_dir)/last-repair-attempt

    materialize_repair_snapshot
    set snapshot_installer "$__spectra_plus_repair_snapshot/install-spectra-plus.fish"
    use_plus_rules_file "$__spectra_plus_repair_snapshot/scripts/spectra-plus/rules.yaml"
    validate_plus_metadata_source

    if test $dry_run -eq 1
        set failed 0
        for registry_target in (read_registry_targets)
            if not test -d "$registry_target"
                echo "[failed] $registry_target: invalid target project directory"
                set failed 1
                continue
            end

            "$snapshot_installer" --check-current "$registry_target"
            set current_status $status
            switch $current_status
                case 0
                    echo "[skipped] $registry_target: already current"
                case 10
                    echo "[would repair] $registry_target"
                case '*'
                    echo "[failed] $registry_target: current state check failed (exit $current_status)"
                    set failed 1
            end
        end
        cleanup_repair_snapshot; or return 1
        return $failed
    end

    set lock_path (acquire_repair_lock)
    if test $status -ne 0
        echo "$lock_path"
        cleanup_repair_snapshot; or return 1
        return 0
    end

    set now (date +%s)
    if test $force -eq 0; and test -f "$throttle_file"
        set last_attempt (cat "$throttle_file")
        if string match -qr '^[0-9]+$' -- "$last_attempt"; and test (math "$now - $last_attempt") -lt $throttle_window
            echo "[skipped] throttled: last repair attempt was within $throttle_window seconds"
            rm -rf "$lock_path"
            cleanup_repair_snapshot; or return 1
            return 0
        end
    end

    mkdir -p (dirname "$throttle_file")
    echo "$now" > "$throttle_file"

    set failed 0
    for registry_target in (read_registry_targets)
        if not test -d "$registry_target"
            echo "[failed] $registry_target: invalid target project directory"
            set failed 1
            continue
        end

        "$snapshot_installer" --check-current "$registry_target"
        set current_status $status
        switch $current_status
            case 0
                echo "[skipped] $registry_target: already current"
                continue
            case 10
            case '*'
                echo "[failed] $registry_target: current state check failed (exit $current_status)"
                set failed 1
                continue
        end

        if "$snapshot_installer" --target "$registry_target"
            echo "[success] $registry_target: repaired"
        else
            echo "[failed] $registry_target: repair failed"
            set failed 1
        end
    end

    rm -rf "$lock_path"
    cleanup_repair_snapshot; or set failed 1
    return $failed
end

function launch_agent_label
    echo "com.agentflow.spectra-plus.repair"
end

function launch_agent_plist
    echo "$HOME/Library/LaunchAgents/"(launch_agent_label)".plist"
end

function launch_agent_log
    echo "$HOME/Library/Logs/spectra-plus-repair.log"
end

function plist_escape --argument-names value
    string replace -a '&' '&amp;' -- "$value" \
        | string replace -a '<' '&lt;' \
        | string replace -a '>' '&gt;' \
        | string replace -a '"' '&quot;' \
        | string replace -a "'" '&apos;'
end

function write_launch_agent_plist --argument-names plist_path
    set fish_path (command -s fish)
    if test -z "$fish_path"
        fail "找不到必要指令：fish"
    end

    set entrypoint_path "$script_dir/scripts/spectra-plus/repair-all.fish"
    set log_path (launch_agent_log)

    mkdir -p (dirname "$plist_path") (dirname "$log_path")
    printf '%s\n' \
        '<?xml version="1.0" encoding="UTF-8"?>' \
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
        '<plist version="1.0">' \
        '<dict>' \
        '  <key>Label</key>' \
        "  <string>"(plist_escape (launch_agent_label))"</string>" \
        '  <key>ProgramArguments</key>' \
        '  <array>' \
        "    <string>"(plist_escape "$fish_path")"</string>" \
        "    <string>"(plist_escape "$entrypoint_path")"</string>" \
        '  </array>' \
        '  <key>EnvironmentVariables</key>' \
        '  <dict>' \
        '    <key>PATH</key>' \
        '    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>' \
        '  </dict>' \
        '  <key>StartInterval</key>' \
        '  <integer>60</integer>' \
        '  <key>StandardOutPath</key>' \
        "  <string>"(plist_escape "$log_path")"</string>" \
        '  <key>StandardErrorPath</key>' \
        "  <string>"(plist_escape "$log_path")"</string>" \
        '</dict>' \
        '</plist>' > "$plist_path"
end

function install_launch_agent
    set plist_path (launch_agent_plist)
    if test $dry_run -eq 1
        echo "+ write LaunchAgent plist $plist_path"
        echo "+ launchctl bootstrap gui/"(id -u)" $plist_path"
        return 0
    end

    write_launch_agent_plist "$plist_path"
    launchctl bootout "gui/"(id -u) "$plist_path" >/dev/null 2>/dev/null
    if not launchctl bootstrap "gui/"(id -u) "$plist_path"
        echo "錯誤：無法啟用 LaunchAgent；manual activation: launchctl bootstrap gui/"(id -u)" $plist_path" >&2
        return 1
    end
    echo "installed LaunchAgent: $plist_path"
end

function uninstall_launch_agent
    set plist_path (launch_agent_plist)
    if test $dry_run -eq 1
        echo "+ remove LaunchAgent plist $plist_path"
        echo "+ launchctl bootout gui/"(id -u)" $plist_path"
        return 0
    end

    if test -f "$plist_path"
        set bootout_err (mktemp)
        launchctl bootout "gui/"(id -u) "$plist_path" >/dev/null 2>"$bootout_err"
        set bootout_status $status
        if test $bootout_status -ne 0
            set bootout_message (cat "$bootout_err")
            if not string match -qi "*not*found*" -- "$bootout_message"; and not string match -qi "*no such*" -- "$bootout_message"; and not string match -qi "*not loaded*" -- "$bootout_message"
                echo "錯誤：無法卸載 LaunchAgent；manual cleanup: launchctl bootout gui/"(id -u)" $plist_path" >&2
                return 1
            end
        end
        command rm -f "$plist_path"
        echo "uninstalled LaunchAgent: $plist_path"
    else
        echo "uninstall no-op: LaunchAgent is not installed"
    end
end

function install_target --argument-names target_path
    if not test -d "$target_path"
        fail "目標專案目錄不存在：$target_path"
    end

    set target_path (cd "$target_path"; and pwd)
    set source_dir "$script_dir/scripts/spectra-plus"
    set generator "$source_dir/generate.fish"

    require_command fish
    require_command yq
    require_file "$generator" "spectra-plus generator"
    require_file "$source_dir/rules.yaml" "spectra-plus rules.yaml"
    validate_plus_metadata_source
    require_file "$target_path/.claude/skills/spectra-propose/SKILL.md" "spectra-propose skill (Claude)"
    require_file "$target_path/.claude/skills/spectra-apply/SKILL.md" "spectra-apply skill (Claude)"
    require_file "$target_path/.claude/skills/spectra-commit/SKILL.md" "spectra-commit skill (Claude)"
    require_file "$target_path/.agents/skills/spectra-propose/SKILL.md" "spectra-propose skill (Codex)"
    require_file "$target_path/.agents/skills/spectra-apply/SKILL.md" "spectra-apply skill (Codex)"
    require_file "$target_path/.agents/skills/spectra-commit/SKILL.md" "spectra-commit skill (Codex)"

    echo ""
    echo "正在產生 plus skills 到：$target_path"
    if test $dry_run -eq 1
        echo "+ $generator --root $target_path"
    else
        $generator --root "$target_path"
        set generate_status $status

        if test $generate_status -ne 0
            fail "plus skill 產生失敗；請檢查 $source_dir/rules.yaml 的 target_section 是否符合目標專案的 Spectra skill 章節"
        end
    end

    echo ""
    echo "正在套用 spectra-commit guard..."
    ensure_commit_guard "$target_path/.claude/skills/spectra-commit/SKILL.md" "$script_dir/.claude/skills/spectra-commit/SKILL.md" "spectra-commit guard (Claude)"
    ensure_commit_guard "$target_path/.agents/skills/spectra-commit/SKILL.md" "$script_dir/.agents/skills/spectra-commit/SKILL.md" "spectra-commit guard (Codex)"

    echo ""
    echo "正在驗證輸出..."
    if test $dry_run -eq 1
        echo "+ test -f $target_path/.claude/skills/spectra-propose-plus/SKILL.md"
        echo "+ test -f $target_path/.claude/skills/spectra-apply-plus/SKILL.md"
        echo "+ test -f $target_path/.agents/skills/spectra-propose-plus/SKILL.md"
        echo "+ test -f $target_path/.agents/skills/spectra-apply-plus/SKILL.md"
    else
        require_file "$target_path/.claude/skills/spectra-propose-plus/SKILL.md" "spectra-propose-plus skill (Claude)"
        require_file "$target_path/.claude/skills/spectra-apply-plus/SKILL.md" "spectra-apply-plus skill (Claude)"
        require_file "$target_path/.agents/skills/spectra-propose-plus/SKILL.md" "spectra-propose-plus skill (Codex)"
        require_file "$target_path/.agents/skills/spectra-apply-plus/SKILL.md" "spectra-apply-plus skill (Codex)"

        validate_plus_outputs_current "$target_path"
    end

    echo ""
    echo "完成。"
    echo "已產生："
    echo "  - .claude/skills/spectra-propose-plus/SKILL.md"
    echo "  - .claude/skills/spectra-apply-plus/SKILL.md"
    echo "  - .agents/skills/spectra-propose-plus/SKILL.md"
    echo "  - .agents/skills/spectra-apply-plus/SKILL.md"
    echo ""
    echo "後續若原始 spectra skill 更新，請重跑："
    echo "  ./$script_name $target_path"
end

if contains -- --check-current $argv
    if test (count $argv) -ne 2; or test "$argv[1]" != "--check-current"
        fail "--check-current 只能單獨搭配一個 absolute target path"
    end
    if not string match -q '/*' -- "$argv[2]"; or not test -d "$argv[2]"
        fail "--check-current 需要 existing absolute target directory：$argv[2]"
    end

    validate_plus_metadata_source
    target_is_current "$argv[2]"
    set current_status $status
    switch $current_status
        case 0
            exit 0
        case 1
            exit 10
        case '*'
            exit $current_status
    end
end

set target ""
set mode install
set mode_arg ""
set dry_run 0
set force 0

set args $argv
while test (count $args) -gt 0
    set arg $args[1]
    set -e args[1]

    switch $arg
        case -h --help
            usage
            exit 0
        case -t --target
            if test (count $args) -eq 0
                fail "$arg 需要指定專案目錄"
            end
            set mode install
            set target $args[1]
            set -e args[1]
        case --register-target --unregister-target
            if test (count $args) -eq 0
                fail "$arg 需要指定專案目錄"
            end
            set mode (string replace -- '--' '' "$arg")
            set mode_arg $args[1]
            set -e args[1]
        case --list-targets
            set mode list-targets
        case --repair-all
            set mode repair-all
        case --install-launch-agent
            set mode install-launch-agent
        case --uninstall-launch-agent
            set mode uninstall-launch-agent
        case --dry-run
            set dry_run 1
        case --force
            set force 1
        case '*'
            if test -z "$target"
                set mode install
                set target $arg
            else
                fail "無法識別的參數：$arg"
            end
    end
end

switch $mode
    case install
        if test -z "$target"
            usage
            exit 2
        end
        install_target "$target"
    case register-target
        register_target "$mode_arg"
    case unregister-target
        unregister_target "$mode_arg"
    case list-targets
        list_targets
    case repair-all
        repair_all
    case install-launch-agent
        install_launch_agent
    case uninstall-launch-agent
        uninstall_launch_agent
    case '*'
        fail "無法識別的操作：$mode"
end
