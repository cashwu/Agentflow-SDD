#!/usr/bin/env fish

set script_name (basename (status --current-filename))
set script_dir (cd (dirname (status --current-filename)); and pwd)

function usage
    echo "使用方式："
    echo "  ./$script_name --target <專案目錄> [--dry-run]"
    echo "  ./$script_name <專案目錄> [--dry-run]"
    echo ""
    echo "功能："
    echo "  將 scripts/spectra-plus 安裝到目標專案，並產生 spectra-propose-plus / spectra-apply-plus。"
    echo ""
    echo "必要條件："
    echo "  目標專案已存在 .claude/skills/spectra-propose/SKILL.md"
    echo "  目標專案已存在 .claude/skills/spectra-apply/SKILL.md"
    echo "  目標專案已存在 .agents/skills/spectra-propose/SKILL.md（Codex 變體）"
    echo "  目標專案已存在 .agents/skills/spectra-apply/SKILL.md（Codex 變體）"
    echo "  本機可執行 fish 與 yq（macOS 可用 brew install yq 安裝）"
    echo ""
    echo "其他選項："
    echo "  --dry-run        只印出將要執行的動作，不實際變更檔案。"
    echo "  -h, --help       顯示此說明。"
end

function fail
    echo "錯誤：$argv" >&2
    exit 1
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
    validate_commit_guard "$source_path" "$description source"

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

set target ""
set dry_run 0

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
            set target $args[1]
            set -e args[1]
        case --dry-run
            set dry_run 1
        case '*'
            if test -z "$target"
                set target $arg
            else
                fail "無法識別的參數：$arg"
            end
    end
end

if test -z "$target"
    usage
    exit 2
end

if not test -d "$target"
    fail "目標專案目錄不存在：$target"
end

set target (cd "$target"; and pwd)
set source_dir "$script_dir/scripts/spectra-plus"
set generator "$source_dir/generate.fish"

require_command fish
require_command yq
require_file "$generator" "spectra-plus generator"
require_file "$source_dir/rules.yaml" "spectra-plus rules.yaml"
require_file "$target/.claude/skills/spectra-propose/SKILL.md" "spectra-propose skill (Claude)"
require_file "$target/.claude/skills/spectra-apply/SKILL.md" "spectra-apply skill (Claude)"
require_file "$target/.claude/skills/spectra-commit/SKILL.md" "spectra-commit skill (Claude)"
require_file "$target/.agents/skills/spectra-propose/SKILL.md" "spectra-propose skill (Codex)"
require_file "$target/.agents/skills/spectra-apply/SKILL.md" "spectra-apply skill (Codex)"
require_file "$target/.agents/skills/spectra-commit/SKILL.md" "spectra-commit skill (Codex)"

echo ""
echo "正在產生 plus skills 到：$target"
if test $dry_run -eq 1
    echo "+ $generator --root $target"
else
    $generator --root "$target"
    set generate_status $status

    if test $generate_status -ne 0
        fail "plus skill 產生失敗；請檢查 $source_dir/rules.yaml 的 target_section 是否符合目標專案的 Spectra skill 章節"
    end
end

echo ""
echo "正在套用 spectra-commit guard..."
ensure_commit_guard "$target/.claude/skills/spectra-commit/SKILL.md" "$script_dir/.claude/skills/spectra-commit/SKILL.md" "spectra-commit guard (Claude)"
ensure_commit_guard "$target/.agents/skills/spectra-commit/SKILL.md" "$script_dir/.agents/skills/spectra-commit/SKILL.md" "spectra-commit guard (Codex)"

echo ""
echo "正在驗證輸出..."
if test $dry_run -eq 1
    echo "+ test -f $target/.claude/skills/spectra-propose-plus/SKILL.md"
    echo "+ test -f $target/.claude/skills/spectra-apply-plus/SKILL.md"
    echo "+ test -f $target/.agents/skills/spectra-propose-plus/SKILL.md"
    echo "+ test -f $target/.agents/skills/spectra-apply-plus/SKILL.md"
else
    require_file "$target/.claude/skills/spectra-propose-plus/SKILL.md" "spectra-propose-plus skill (Claude)"
    require_file "$target/.claude/skills/spectra-apply-plus/SKILL.md" "spectra-apply-plus skill (Claude)"
    require_file "$target/.agents/skills/spectra-propose-plus/SKILL.md" "spectra-propose-plus skill (Codex)"
    require_file "$target/.agents/skills/spectra-apply-plus/SKILL.md" "spectra-apply-plus skill (Codex)"

    rg -q --fixed-strings "ai 的回覆要用中文" "$target/.claude/skills/spectra-apply-plus/SKILL.md"
    or fail "spectra-apply-plus (Claude) 未包含中文回覆規則"
    rg -q --fixed-strings "ai 的回覆要用中文" "$target/.agents/skills/spectra-apply-plus/SKILL.md"
    or fail "spectra-apply-plus (Codex) 未包含中文回覆規則"
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
echo "  ./$script_name $target"
