#!/usr/bin/env -S fish --no-config

set -l script_path (command realpath (status --current-filename) 2>/dev/null)
if test $status -ne 0; or test -z "$script_path"
    echo "Error: cannot resolve installer path." >&2
    exit 1
end
set -l source_root (command dirname "$script_path")
set -l python_path "$source_root/.cash-skills/lib"

set -l python_command ""
for candidate in python3 python python3.14 python3.13 python3.12 python3.11
    if command -q "$candidate"
        if command "$candidate" -s -P -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>/dev/null
            set python_command "$candidate"
            break
        end
    end
end

if test -z "$python_command"
    echo "Error: Cash installer requires Python 3.11+." >&2
    exit 1
end

set -lx PYTHONPATH "$python_path"
exec "$python_command" -s -P -m cash_cli.installer $argv
