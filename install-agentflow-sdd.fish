#!/usr/bin/env fish

set script_name (basename (status --current-filename))
set script_dir (cd (dirname (status --current-filename)); and pwd)

function usage
    echo "使用方式："
    echo "  ./$script_name --target <專案目錄> [--both|--codex-only|--claude-only] [--docs] [--dry-run]"
    echo ""
    echo "安裝目標："
    echo "  --both           同時安裝 Codex 與 Claude 的 skills（預設）。"
    echo "  --codex-only     只安裝 .agents/skills。"
    echo "  --claude-only    只安裝 .claude/skills。"
    echo ""
    echo "其他選項："
    echo "  --docs           一併複製 SDD-FLOW.md 到目標專案。"
    echo "  --dry-run        只印出將要複製的內容，不實際變更檔案。"
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

function install_skill_dir --argument-names skill_dir dest_root
    if not test -d "$skill_dir"
        fail "找不到來源 skill 目錄：$skill_dir"
    end

    run_cmd mkdir -p "$dest_root"
    run_cmd cp -R "$skill_dir" "$dest_root/"
end

function ensure_project_sdd_block --argument-names source_file target_file label
    if not test -f "$source_file"
        fail "找不到來源檔案：$source_file"
    end

    if not grep -q "PROJECT-SDD:START" "$source_file"
        fail "$source_file 中找不到 PROJECT-SDD 區塊"
    end

    if not test -f "$target_file"
        echo "  - $label：找不到 $target_file，將建立新檔案"
        if test $dry_run -eq 1
            echo "+ 將 PROJECT-SDD 區塊寫入 $target_file"
            return
        end
        awk '/<!-- PROJECT-SDD:START -->/{flag=1} flag{print} /<!-- PROJECT-SDD:END -->/{flag=0}' "$source_file" >"$target_file"
        echo "  - $label：已建立 $target_file 並寫入 Project SDD Overlay"
        return
    end

    if grep -q "PROJECT-SDD:START" "$target_file"
        echo "  - $label：偵測到既有 Project SDD Overlay，將更新為最新內容"
        if test $dry_run -eq 1
            echo "+ 移除 $target_file 中舊的 PROJECT-SDD 區塊後重新附加"
            return
        end
        set tmp_strip (mktemp)
        awk '/<!-- PROJECT-SDD:START -->/{skip=1; next} /<!-- PROJECT-SDD:END -->/{skip=0; next} !skip{print}' "$target_file" >"$tmp_strip"
        command mv -f "$tmp_strip" "$target_file"
    end

    if test $dry_run -eq 1
        echo "+ 將 PROJECT-SDD 區塊附加到 $target_file"
        return
    end

    printf '\n' >>"$target_file"
    awk '/<!-- PROJECT-SDD:START -->/{flag=1} flag{print} /<!-- PROJECT-SDD:END -->/{flag=0}' "$source_file" >>"$target_file"
    echo "  - $label：已將 Project SDD Overlay 附加到 $target_file"
end

function ensure_agentflow_config --argument-names source_file target_file
    if not test -f "$source_file"
        fail "找不到來源檔案：$source_file"
    end

    if not test -f "$target_file"
        if test $dry_run -eq 1
            echo "+ mkdir -p "(dirname "$target_file")
            echo "+ cp $source_file $target_file"
            return
        end
        run_cmd mkdir -p (dirname "$target_file")
        run_cmd cp "$source_file" "$target_file"
        echo "  - agentflow/config.yaml：目標檔案不存在，已複製 Agentflow-SDD 設定"
        return
    end

    echo "  - agentflow/config.yaml：目標檔案已存在，將更新為最新內容"
    if test $dry_run -eq 1
        echo "+ cp $source_file $target_file"
        return
    end
    run_cmd cp "$source_file" "$target_file"
    echo "  - agentflow/config.yaml：已更新為最新設定"
end

function migrate_from_spectra --argument-names target_dir
    set has_migration 0

    # 1. Move active changes from openspec/changes/ to agentflow/changes/
    if test -d "$target_dir/openspec/changes"
        for change_dir in "$target_dir"/openspec/changes/*/
            set change_name (basename "$change_dir")
            if test "$change_name" = "archive"
                continue
            end
            if test -d "$change_dir"
                set has_migration 1
                echo "  - 遷移 change：$change_name → agentflow/changes/$change_name"
                if test $dry_run -eq 0
                    run_cmd mkdir -p "$target_dir/agentflow/changes"
                    run_cmd mv "$change_dir" "$target_dir/agentflow/changes/$change_name"
                end
            end
        end

        # Move archived changes
        if test -d "$target_dir/openspec/changes/archive"
            for archive_dir in "$target_dir"/openspec/changes/archive/*/
                if test -d "$archive_dir"
                    set archive_name (basename "$archive_dir")
                    set has_migration 1
                    echo "  - 遷移 archive：$archive_name → agentflow/changes/archive/$archive_name"
                    if test $dry_run -eq 0
                        run_cmd mkdir -p "$target_dir/agentflow/changes/archive"
                        run_cmd mv "$archive_dir" "$target_dir/agentflow/changes/archive/$archive_name"
                    end
                end
            end
        end
    end

    # 2. Remove old openspec/config.yaml (replaced by agentflow/config.yaml)
    if test -f "$target_dir/openspec/config.yaml"
        set has_migration 1
        echo "  - 移除舊的 openspec/config.yaml（由 agentflow/config.yaml 取代）"
        if test $dry_run -eq 0
            run_cmd rm "$target_dir/openspec/config.yaml"
        end
    end

    # 3. Remove old spectra-* skill directories
    for skill_root in "$target_dir/.claude/skills" "$target_dir/.agents/skills"
        if test -d "$skill_root"
            for spectra_dir in "$skill_root"/spectra-*/
                if test -d "$spectra_dir"
                    set has_migration 1
                    echo "  - 移除舊的 skill："(basename "$spectra_dir")
                    if test $dry_run -eq 0
                        run_cmd rm -rf "$spectra_dir"
                    end
                end
            end
        end
    end

    # 4. Remove old sdd-spectra-refresh skill directories
    for skill_root in "$target_dir/.claude/skills" "$target_dir/.agents/skills"
        if test -d "$skill_root/sdd-spectra-refresh"
            set has_migration 1
            echo "  - 移除舊的 sdd-spectra-refresh（由 sdd-refresh 取代）"
            if test $dry_run -eq 0
                run_cmd rm -rf "$skill_root/sdd-spectra-refresh"
            end
        end
    end

    # 5. Strip SPECTRA:START/END blocks from CLAUDE.md and AGENTS.md
    for md_file in "$target_dir/CLAUDE.md" "$target_dir/AGENTS.md"
        if test -f "$md_file"; and grep -q "SPECTRA:START" "$md_file"
            set has_migration 1
            echo "  - 移除 "(basename "$md_file")" 中的 SPECTRA:START/END 區塊"
            if test $dry_run -eq 0
                set tmp_strip (mktemp)
                awk '/<!-- SPECTRA:START/{skip=1; next} /<!-- SPECTRA:END/{skip=0; next} !skip{print}' "$md_file" >"$tmp_strip"
                command mv -f "$tmp_strip" "$md_file"
            end
        end
    end

    if test $has_migration -eq 0
        echo "  - 未偵測到需要遷移的舊版內容"
    end
end

function install_skill_set --argument-names source_root dest_root label
    if not test -d "$source_root"
        fail "找不到來源 skill 根目錄：$source_root"
    end

    echo "正在安裝 $label skills 到 $dest_root"

    for skill_dir in "$source_root"/sdd-*
        if test -d "$skill_dir"
            install_skill_dir "$skill_dir" "$dest_root"
        end
    end
end

set target ""
set install_codex 1
set install_claude 1
set install_docs 0
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
        case --both
            set install_codex 1
            set install_claude 1
        case --codex-only
            set install_codex 1
            set install_claude 0
        case --claude-only
            set install_codex 0
            set install_claude 1
        case --docs
            set install_docs 1
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

if test $install_codex -eq 0; and test $install_claude -eq 0
    fail "沒有可安裝的內容：請選擇 --both、--codex-only 或 --claude-only"
end

if not test -d "$target"
    run_cmd mkdir -p "$target"
end

echo ""
echo "正在檢查是否有舊版 Spectra 內容需要遷移..."
migrate_from_spectra "$target"

if test $install_codex -eq 1
    install_skill_set "$script_dir/.agents/skills" "$target/.agents/skills" "Codex"
end

if test $install_claude -eq 1
    install_skill_set "$script_dir/.claude/skills" "$target/.claude/skills" "Claude"
end

if test $install_docs -eq 1
    if not test -f "$script_dir/SDD-FLOW.md"
        fail "安裝腳本旁找不到 SDD-FLOW.md"
    end
    run_cmd cp "$script_dir/SDD-FLOW.md" "$target/SDD-FLOW.md"
end

echo ""
echo "正在套用 Project SDD Overlay 到目標專案的設定檔..."
ensure_project_sdd_block "$script_dir/AGENTS.md" "$target/AGENTS.md" "AGENTS.md"
ensure_project_sdd_block "$script_dir/CLAUDE.md" "$target/CLAUDE.md" "CLAUDE.md"
ensure_agentflow_config "$script_dir/agentflow/config.yaml" "$target/agentflow/config.yaml"

echo ""
echo "正在建立 agentflow 目錄結構..."
run_cmd mkdir -p "$target/agentflow/changes/archive"

echo ""
echo "完成。"
echo "目標專案的後續步驟："
echo "  1. 檢查 AGENTS.md / CLAUDE.md 的 Project SDD Overlay 是否需要調整。"
echo "  2. 檢查 agentflow/config.yaml 是否需要針對專案調整 preferences 或 rules。"
