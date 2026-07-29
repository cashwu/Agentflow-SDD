#!/usr/bin/env -S XDG_CONFIG_HOME=/dev/null XDG_DATA_HOME=/dev/null XDG_CACHE_HOME=/dev/null fish --no-config

set -l script_path (command realpath (status --current-filename) 2>/dev/null)
if test $status -ne 0; or test -z "$script_path"
    echo "Error: cannot resolve shim installer path." >&2
    exit 1
end

set -l source_root (command dirname "$script_path")
set -l source_shim "$source_root/scripts/cash-shim/cash-shim.sh"
set -l helper "$source_root/scripts/cash-shim/install_shim.py"
set -l python ""
for candidate in python3 python python3.14 python3.13 python3.12 python3.11
    set -l candidate_path (command -s "$candidate" 2>/dev/null)
    if test -n "$candidate_path"
        "$candidate_path" -I -B -P -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null
        if test $status -eq 0
            set python "$candidate_path"
            break
        end
    end
end

if test -z "$python"
    echo "Error: Python 3.11+ is required to install the Cash shim." >&2
    exit 1
end

exec "$python" -I -B -P "$helper" "$source_shim"
