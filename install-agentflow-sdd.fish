#!/usr/bin/env fish

set script_name (basename (status --current-filename))
set script_dir (cd (dirname (status --current-filename)); and pwd)

function usage
    echo "Usage:"
    echo "  ./$script_name --target <project-dir> [--sdd-only|--with-spectra] [--both|--codex-only|--claude-only] [--docs] [--dry-run]"
    echo ""
    echo "Modes:"
    echo "  --sdd-only       Install only project-owned sdd-* skills. This is the default for projects that already have Spectra skills."
    echo "  --with-spectra   Install sdd-* skills and generated spectra-* skills. Use for projects that do not have Spectra skills yet."
    echo ""
    echo "Targets:"
    echo "  --both           Install Codex and Claude skills. Default."
    echo "  --codex-only     Install only .agents/skills."
    echo "  --claude-only    Install only .claude/skills."
    echo ""
    echo "Options:"
    echo "  --docs           Also copy SDD-FLOW.md to the target project."
    echo "  --dry-run        Print what would be copied without changing files."
    echo "  -h, --help       Show this help."
end

function fail
    echo "error: $argv" >&2
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
        fail "missing source skill directory: $skill_dir"
    end

    run_cmd mkdir -p "$dest_root"
    run_cmd cp -R "$skill_dir" "$dest_root/"
end

function install_skill_set --argument-names source_root dest_root label
    if not test -d "$source_root"
        fail "missing source skill root: $source_root"
    end

    echo "Installing $label skills into $dest_root"

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
                fail "$arg requires a project directory"
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
                fail "unexpected argument: $arg"
            end
    end
end

if test -z "$target"
    usage
    exit 2
end

if test $install_codex -eq 0; and test $install_claude -eq 0
    fail "nothing to install: choose --both, --codex-only, or --claude-only"
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
        fail "missing SDD-FLOW.md next to installer"
    end
    run_cmd cp "$script_dir/SDD-FLOW.md" "$target/SDD-FLOW.md"
end

echo ""
echo "Done."
echo "Next steps for the target project:"
echo "  1. Keep Spectra generated blocks intact."
echo "  2. Add the Project SDD Overlay note to AGENTS.md / CLAUDE.md if the target project uses those files."
echo "  3. Add Agentflow-SDD review round rules to openspec/config.yaml if the target project uses Spectra config."
echo "  4. Ensure the spectra CLI is installed when using Spectra-backed skills; --with-spectra installs skill files only."
