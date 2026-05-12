#!/usr/bin/env fish

set script_name (basename (status --current-filename))
set script_dir (cd (dirname (status --current-filename)); and pwd)

function usage
    echo "使用方式："
    echo "  ./$script_name --target <專案目錄> [--sdd-only|--with-spectra] [--both|--codex-only|--claude-only] [--docs] [--dry-run]"
    echo ""
    echo "模式："
    echo "  --sdd-only       只安裝專案自有的 sdd-* skills。若目標專案已有 Spectra skills，這是預設模式。"
    echo "  --with-spectra   同時安裝 sdd-* skills 與產生的 spectra-* skills。適用於尚未安裝 Spectra skills 的專案。"
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
        echo "  - $label：找不到 $target_file，略過（請先讓 Spectra 產生此檔案後重跑安裝腳本）"
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

function ensure_openspec_config --argument-names source_file target_file
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
        echo "  - openspec/config.yaml：目標檔案不存在，已複製 Agentflow-SDD 設定"
        return
    end

    if grep -q "AGENTFLOW-SDD:START" "$target_file"
        echo "  - openspec/config.yaml：偵測到既有 AGENTFLOW-SDD 區段，將更新為最新內容"
        if test $dry_run -eq 1
            echo "+ 移除 $target_file 中舊的 AGENTFLOW-SDD 區段後重新合併"
            return
        end
        set tmp_strip (mktemp)
        awk '/AGENTFLOW-SDD:START/{skip=1; next} /AGENTFLOW-SDD:END/{skip=0; next} !skip{print}' "$target_file" >"$tmp_strip"
        command mv -f "$tmp_strip" "$target_file"
    end

    if test $dry_run -eq 1
        echo "+ 將 Agentflow-SDD 的 context/rules 合併進 $target_file"
        return
    end

    set tmp (mktemp)
    awk -v src="$source_file" '
        function inject_items_for(key,    items) {
            if (key == "") return
            items = sdd_sub_items[key]
            if (items == "") return
            if (injected[key]) return
            injected[key] = 1
            print "    # AGENTFLOW-SDD:START"
            printf "%s", items
            print "    # AGENTFLOW-SDD:END"
        }
        function inject_missing_subkeys(    i, k, has_any) {
            has_any = 0
            for (i = 1; i <= sub_count; i++) {
                k = sdd_sub_order[i]
                if (!injected[k] && sdd_sub_items[k] != "") { has_any = 1; break }
            }
            if (!has_any) return
            print "  # AGENTFLOW-SDD:START"
            for (i = 1; i <= sub_count; i++) {
                k = sdd_sub_order[i]
                if (!injected[k] && sdd_sub_items[k] != "") {
                    print "  " k ":"
                    printf "%s", sdd_sub_items[k]
                    injected[k] = 1
                }
            }
            print "  # AGENTFLOW-SDD:END"
        }
        BEGIN {
            state = 0
            current_sub = ""
            sub_count = 0
            while ((getline line < src) > 0) {
                if (line ~ /^context:/) { state = 1; current_sub = ""; continue }
                if (line ~ /^rules:/) { state = 2; current_sub = ""; continue }
                if (line ~ /^[A-Za-z_]/) { state = 0; current_sub = ""; continue }
                if (state == 1) sdd_ctx = sdd_ctx line "\n"
                if (state == 2) {
                    if (line ~ /^  [A-Za-z_]+:[[:space:]]*$/) {
                        tmpname = line
                        sub(/^[[:space:]]+/, "", tmpname)
                        sub(/:.*$/, "", tmpname)
                        current_sub = tmpname
                        sub_count += 1
                        sdd_sub_order[sub_count] = current_sub
                        sdd_sub_items[current_sub] = ""
                    } else if (current_sub != "" && line ~ /^    -/) {
                        sdd_sub_items[current_sub] = sdd_sub_items[current_sub] line "\n"
                    }
                }
            }
            close(src)
        }
        {
            if ($0 ~ /^context:/) {
                saw_context = 1
                in_ctx = 1
                print
                next
            }
            if (in_ctx && ($0 ~ /^[A-Za-z_]/ || $0 ~ /^#/)) {
                print "  # AGENTFLOW-SDD:START"
                printf "%s", sdd_ctx
                print "  # AGENTFLOW-SDD:END"
                in_ctx = 0
            }
            if ($0 ~ /^rules:/) {
                saw_rules = 1
                in_rules = 1
                cur_sub = ""
                print
                next
            }
            if (in_rules) {
                if ($0 ~ /^[A-Za-z_]/ || $0 ~ /^#/) {
                    inject_items_for(cur_sub)
                    inject_missing_subkeys()
                    in_rules = 0
                    cur_sub = ""
                    print
                    next
                }
                if ($0 ~ /^  [A-Za-z_]+:[[:space:]]*$/) {
                    inject_items_for(cur_sub)
                    tmpkey = $0
                    sub(/^[[:space:]]+/, "", tmpkey)
                    sub(/:.*$/, "", tmpkey)
                    cur_sub = tmpkey
                    print
                    next
                }
            }
            print
        }
        END {
            if (in_rules) {
                inject_items_for(cur_sub)
                inject_missing_subkeys()
            }
            if (in_ctx) {
                print "  # AGENTFLOW-SDD:START"
                printf "%s", sdd_ctx
                print "  # AGENTFLOW-SDD:END"
            }
            if (!saw_context) {
                print ""
                print "context: |"
                print "  # AGENTFLOW-SDD:START"
                printf "%s", sdd_ctx
                print "  # AGENTFLOW-SDD:END"
            }
            if (!saw_rules) {
                print ""
                print "# AGENTFLOW-SDD:START"
                print "rules:"
                for (i = 1; i <= sub_count; i++) {
                    k = sdd_sub_order[i]
                    print "  " k ":"
                    printf "%s", sdd_sub_items[k]
                }
                print "# AGENTFLOW-SDD:END"
            }
        }
    ' "$target_file" >"$tmp"

    if test -s "$tmp"
        command mv -f "$tmp" "$target_file"
        echo "  - openspec/config.yaml：已合併 Agentflow-SDD context/rules（以 AGENTFLOW-SDD:START/END 標記）"
    else
        rm -f "$tmp"
        fail "合併 openspec/config.yaml 時產生空檔，已中止"
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

    if test $include_spectra -eq 1
        for skill_dir in "$source_root"/spectra-*
            if test -d "$skill_dir"
                install_skill_dir "$skill_dir" "$dest_root"
            end
        end
    end
end

set target ""
set include_spectra 0
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
        case --sdd-only
            set include_spectra 0
        case --with-spectra
            set include_spectra 1
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
ensure_openspec_config "$script_dir/openspec/config.yaml" "$target/openspec/config.yaml"

echo ""
echo "完成。"
echo "目標專案的後續步驟："
echo "  1. 保持 Spectra 產生的區塊完整，不要修改。"
echo "  2. 使用 Spectra 相關 skills 時，請確認已安裝 spectra CLI；--with-spectra 參數僅安裝 skill 檔案。"
