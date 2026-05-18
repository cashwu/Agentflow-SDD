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
set target_dir "$target/scripts/spectra-plus"

require_command fish
require_command yq
require_file "$source_dir/generate.fish" "spectra-plus generator"
require_file "$source_dir/rules.yaml" "spectra-plus rules.yaml"
require_file "$target/.claude/skills/spectra-propose/SKILL.md" "spectra-propose skill (Claude)"
require_file "$target/.claude/skills/spectra-apply/SKILL.md" "spectra-apply skill (Claude)"
require_file "$target/.agents/skills/spectra-propose/SKILL.md" "spectra-propose skill (Codex)"
require_file "$target/.agents/skills/spectra-apply/SKILL.md" "spectra-apply skill (Codex)"

echo ""
echo "正在安裝 Spectra Plus generator 到：$target_dir"
run_cmd mkdir -p "$target/scripts"
run_cmd cp -R "$source_dir" "$target/scripts/"

echo ""
echo "正在產生 plus skills..."
if test $dry_run -eq 1
    echo "+ cd $target"
    echo "+ scripts/spectra-plus/generate.fish"
else
    pushd "$target" >/dev/null
    scripts/spectra-plus/generate.fish
    set generate_status $status
    popd >/dev/null

    if test $generate_status -ne 0
        fail "plus skill 產生失敗；請檢查 $target_dir/rules.yaml 的 target_section 是否符合目標專案的 Spectra skill 章節"
    end
end

echo ""
echo "正在驗證輸出..."
if test $dry_run -eq 1
    echo "+ test -f $target/.claude/skills/spectra-propose-plus/SKILL.md"
    echo "+ test -f $target/.claude/skills/spectra-apply-plus/SKILL.md"
    echo "+ test -f $target/.agents/skills/spectra-propose-plus/SKILL.md"
    echo "+ test -f $target/.agents/skills/spectra-apply-plus/SKILL.md"
    echo "+ yq '.' $target_dir/rules.yaml"
else
    require_file "$target/.claude/skills/spectra-propose-plus/SKILL.md" "spectra-propose-plus skill (Claude)"
    require_file "$target/.claude/skills/spectra-apply-plus/SKILL.md" "spectra-apply-plus skill (Claude)"
    require_file "$target/.agents/skills/spectra-propose-plus/SKILL.md" "spectra-propose-plus skill (Codex)"
    require_file "$target/.agents/skills/spectra-apply-plus/SKILL.md" "spectra-apply-plus skill (Codex)"
    yq '.' "$target_dir/rules.yaml" >/dev/null
    or fail "rules.yaml 無法解析：$target_dir/rules.yaml"

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
echo "後續若原始 spectra skill 更新，請在目標專案重跑："
echo "  scripts/spectra-plus/generate.fish"
