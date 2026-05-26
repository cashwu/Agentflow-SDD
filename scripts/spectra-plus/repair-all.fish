#!/usr/bin/env fish

set script_path (status --current-filename)
set script_dir (cd (dirname "$script_path"); and pwd)
set root_dir (cd "$script_dir/../.."; and pwd)
set log_path "$HOME/Library/Logs/spectra-plus-repair.log"

function log_error --argument-names message
    mkdir -p (dirname "$log_path")
    echo "錯誤：$message" | tee -a "$log_path" >&2
end

for command_name in fish yq
    if not command -q "$command_name"
        log_error "找不到必要指令：$command_name"
        exit 1
    end
end

"$root_dir/install-spectra-plus.fish" --repair-all $argv
