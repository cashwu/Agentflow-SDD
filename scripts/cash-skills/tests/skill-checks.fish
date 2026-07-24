#!/usr/bin/env fish

set -g root_dir (path resolve (dirname (status filename))/../../..)
set -g cash_skills analyze apply archive ask audit commit debug discuss drift ingest propose verify
set -g divergent_skills analyze ask audit drift ingest propose verify

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function assert_contains --argument-names path literal contract
    set -l display (string replace -- "$root_dir/" "" "$path")
    rg -Fq -- "$literal" "$path"; or fail "$display violates $contract: missing '$literal'"
end

function assert_absent --argument-names path pattern contract
    set -l display (string replace -- "$root_dir/" "" "$path")
    if rg -Pq -- "$pattern" "$path"
        fail "$display violates $contract: matched '$pattern'"
    end
end

function assert_inventory
    set -l directories (find "$root_dir/.agents/skills" "$root_dir/.claude/skills" -mindepth 1 -maxdepth 1 -type d -name 'cash-*' -print | sort)
    test (count $directories) -eq 24; or fail "canonical Cash inventory must contain exactly 24 directories"
    for variant in .agents .claude
        for skill in $cash_skills
            set -l relative "$variant/skills/cash-$skill/SKILL.md"
            set -l path "$root_dir/$relative"
            test -f "$path"; or fail "missing $relative"
            set -l name (awk 'NR == 1 && $0 == "---" { front = 1; next } front && $0 == "---" { exit } front && /^name: / { sub(/^name: /, ""); print; exit }' "$path")
            test "$name" = "cash-$skill"; or fail "$relative has invalid name '$name'"
        end
        set -l retired (find "$root_dir/$variant/skills" -mindepth 1 -maxdepth 1 -type d -name 'spectra-*' -print)
        test (count $retired) -eq 0; or fail "$variant retains a retired canonical skill"
    end
    test (string trim <"$root_dir/cash-skills.version") = 2.1.0; or fail "cash-skills.version must be 2.1.0"
    test (stat -f '%Lp' "$root_dir/.cash-skills/bin/cash") = 755; or fail "Cash launcher must be 0755"
    test (stat -f '%Lp' "$root_dir/.cash-workspace.lock") = 644; or fail "workspace lock must be 0644"
    test (stat -f '%z' "$root_dir/.cash-workspace.lock") = 0; or fail "workspace lock must be empty"
    test ! -e "$root_dir/.spectra.yaml"; or fail "legacy project config remains live"
end

function assert_command_matrix
    for variant in .agents .claude
        for skill in $cash_skills
            set -l path "$root_dir/$variant/skills/cash-$skill/SKILL.md"
            assert_contains "$path" 'cash_root="$(git rev-parse --show-toplevel)" || exit 1' "Git-root launcher bootstrap"
            assert_contains "$path" 'cash_cli="$cash_root/.cash-skills/bin/cash"' "project-local launcher bootstrap"
            assert_contains "$path" 'test -x "$cash_cli" || exit 1' "launcher executable preflight"
            assert_absent "$path" '(?im)^[[:space:]]*(?:spectra|cash)[[:space:]]+(?:list|status|instructions|new|validate|analyze|drift|search|park|unpark|sync|archive|task|touched|in-progress)\b' "PATH-based artifact command"
            assert_absent "$path" '(?i)Requires spectra CLI|embedding-based vector search|vector_not_compiled|index_not_built|model_not_downloaded' "retired runtime compatibility"
        end
    end

    set -l codex_root "$root_dir/.agents/skills"
    for literal in \
        '"$cash_cli" list --json' \
        '"$cash_cli" list --parked --json' \
        '"$cash_cli" status --change "<name>" --json' \
        '"$cash_cli" instructions <artifact-id> --change "<name>" --json' \
        '"$cash_cli" instructions apply --change "<name>" --json' \
        '"$cash_cli" instructions --skill tdd' \
        '"$cash_cli" instructions --skill audit' \
        '"$cash_cli" new change "<name>" --agent codex' \
        '"$cash_cli" new artifact proposal --change "<name>" --stdin' \
        '"$cash_cli" new artifact spec <capability-name> --change "<name>" --stdin' \
        '"$cash_cli" in-progress add "<name>"' \
        '"$cash_cli" task done --change "<name>" <task-id>' \
        '"$cash_cli" touched ensure "<change-name>"' \
        '"$cash_cli" validate "<name>"' \
        '"$cash_cli" analyze <change-name> --json' \
        '"$cash_cli" drift <change-name>' \
        '"$cash_cli" search "<query>" --limit 10 --json' \
        '"$cash_cli" unpark "<name>"' \
        '"$cash_cli" archive <name> --skip-specs'
        rg -Fq -- "$literal" "$codex_root"/cash-*/SKILL.md; or fail "consumer matrix missing $literal"
    end

    for path in \
        "$root_dir/.agents/skills/cash-apply/SKILL.md" \
        "$root_dir/.agents/skills/cash-verify/SKILL.md" \
        "$root_dir/.claude/skills/cash-apply/SKILL.md" \
        "$root_dir/.claude/skills/cash-verify/SKILL.md"
        for literal in state missingArtifacts preflight contextFiles progress tasks '"blocked"' '"ready"' '"all_done"'
            assert_contains "$path" "$literal" "complete apply-instructions consumer"
        end
    end
    for path in "$root_dir/.agents/skills/cash-propose/SKILL.md" "$root_dir/.claude/skills/cash-propose/SKILL.md"
        for literal in '`context`' '`rules`' 'outputPath' dependencies
            assert_contains "$path" "$literal" "complete artifact-instructions consumer"
        end
    end
end

function normalized_variant_diff --argument-names skill output
    set -l codex (mktemp "/tmp/cash-$skill-codex.XXXXXX")
    set -l claude (mktemp "/tmp/cash-$skill-claude.XXXXXX")
    perl -pe 's/(?<![A-Za-z0-9_.-])\$cash-/\@cash-/g' "$root_dir/.agents/skills/cash-$skill/SKILL.md" >"$codex"
    perl -pe 's#(?<![A-Za-z0-9_.-])/cash-#\@cash-#g' "$root_dir/.claude/skills/cash-$skill/SKILL.md" >"$claude"
    diff --label "codex/cash-$skill" --label "claude/cash-$skill" -U0 "$codex" "$claude" >"$output"
    set -l result $status
    command rm -f -- "$codex" "$claude"
    test $result -le 1; or fail "variant comparison failed for cash-$skill"
end

function assert_variant_parity
    for skill in $cash_skills
        set -l actual (mktemp "/tmp/cash-$skill-parity.XXXXXX")
        normalized_variant_diff "$skill" "$actual"
        if contains "$skill" $divergent_skills
            set -l expected "$root_dir/scripts/cash-skills/variant-parity/cash-$skill.diff"
            test -f "$expected"; or fail "missing parity manifest for cash-$skill"
            cmp -s "$expected" "$actual"; or begin
                diff -u "$expected" "$actual" >&2
                command rm -f -- "$actual"
                fail "variant drift outside manifest for cash-$skill"
            end
        else
            test ! -s "$actual"; or begin
                diff -u /dev/null "$actual" >&2
                command rm -f -- "$actual"
                fail "cash-$skill variants differ after invocation normalization"
            end
        end
        command rm -f -- "$actual"
    end
end

function grader_hash --argument-names path
    awk '/<!-- GRADER-IMMUTABILITY -->/ { copy = 1 } copy { print } copy && /<!-- LOOP-LEDGER-STEP -->/ { exit }' "$path" | shasum -a 256 | awk '{ print $1 }'
end

function assert_grader_immutability
    set -l expected
    for relative in \
        .agents/skills/cash-propose/SKILL.md \
        .agents/skills/cash-apply/SKILL.md \
        .claude/skills/cash-propose/SKILL.md \
        .claude/skills/cash-apply/SKILL.md
        set -l path "$root_dir/$relative"
        test (rg -Fc '<!-- GRADER-IMMUTABILITY -->' "$path" | string trim) = 1; or fail "$relative must have one grader sentinel"
        for literal in \
            '.cash.yaml' \
            'scripts/cash-skills/tests/skill-checks.fish' \
            'scripts/cash-cli/tests/cli-checks.fish' \
            'openspec/specs/' \
            'Structured scope declarations' \
            'MUST NOT add, modify, or remove the `check` frontmatter field'
            assert_contains "$path" "$literal" "grader protected set"
        end
        assert_absent "$path" '\\.spectra\\.yaml' "retired grader config"
        set -l actual (grader_hash "$path")
        if test -z "$expected"
            set expected "$actual"
        else
            test "$actual" = "$expected"; or fail "$relative grader block differs"
        end
    end
end

function assert_guidance_and_docs
    test -f "$root_dir/.cash.yaml"; or fail "missing .cash.yaml"
    for literal in 'locale: tw' 'tdd: true' 'audit: true' 'parallel_tasks: true'
        assert_contains "$root_dir/.cash.yaml" "$literal" "Cash config"
    end
    set -l agents (mktemp /tmp/cash-agents-block.XXXXXX)
    set -l claude (mktemp /tmp/cash-claude-block.XXXXXX)
    for relative in AGENTS.md CLAUDE.md
        set -l path "$root_dir/$relative"
        test (rg -Fxc '<!-- CASH:START -->' "$path" | string trim) = 1; or fail "$relative needs one Cash start marker"
        test (rg -Fxc '<!-- CASH:END -->' "$path" | string trim) = 1; or fail "$relative needs one Cash end marker"
        for literal in \
            '本專案所有面向使用者的回覆一律以繁體中文撰寫，除非使用者明確要求其他語言。' \
            '### Requirement: cash-apply 任務迴圈的阻塞分類' \
            '## Cash-owned artifact fallback' \
            '.cash-skills/bin/cash list --parked --json' \
            '.cash-skills/bin/cash search "<query>" --limit 10 --json'
            assert_contains "$path" "$literal" "canonical Cash guidance"
        end
    end
    awk '/^<!-- CASH:START -->$/ { copy = 1; next } /^<!-- CASH:END -->$/ { copy = 0 } copy { print }' "$root_dir/AGENTS.md" >"$agents"
    awk '/^<!-- CASH:START -->$/ { copy = 1; next } /^<!-- CASH:END -->$/ { copy = 0 } copy { print }' "$root_dir/CLAUDE.md" >"$claude"
    cmp -s "$agents" "$claude"; or fail "AGENTS.md and CLAUDE.md Cash blocks differ"
    test (shasum -a 256 "$agents" | awk '{ print $1 }') = 71cc139e2e69027e6e2d23edef83ad3fbb1e17154b932e8c2f923c0043b177b2; or fail "canonical Cash guidance baseline drifted"
    command rm -f -- "$agents" "$claude"

    set -l docs "$root_dir/CASH-SKILLS.md"
    for literal in \
        '.cash-skills/bin/cash' \
        '.cash-skills/receipt.tsv' \
        'runtime generation' \
        '24 個 canonical' \
        'legacy-spectra-digests.tsv' \
        'Live namespace' \
        'namespace-scan' \
        'fail closed' \
        '## Target 版控排除保護' \
        '.cash-skills/state/' \
        '__pycache__/' \
        '不視為已滿足' \
        '只附加、不重排' \
        'git rm --cached .cash-skills/receipt.tsv'
        assert_contains "$docs" "$literal" "current Cash documentation"
    end
end

function assert_installer
    fish -n "$root_dir/install-cash-skills.fish"; or fail "installer wrapper syntax is invalid"
    set -l help (fish --no-config "$root_dir/install-cash-skills.fish" --help | string collect)
    for option in '--target <project>' '--self' '--register <project>' '--unregister <project>' '--list' '--all' '--dry-run' '--force'
        string match -q "*$option*" "$help"; or fail "installer help missing $option"
    end
    if string match -rq -- '--repair|launch-agent|fingerprint' "$help"
        fail "installer exposes retired background repair"
    end
    set -lx PYTHONDONTWRITEBYTECODE 1
    python3 "$root_dir/scripts/cash-skills/tests/test_installer_runtime.py"; or fail "installer runtime contract tests failed"
    python3 "$root_dir/scripts/cash-skills/tests/test_bundle_version_history.py"; or fail "bundle version history contract tests failed"
end

function assert_namespace
    set -lx PYTHONDONTWRITEBYTECODE 1
    python3 "$root_dir/scripts/cash-skills/tests/test_live_namespace.py" "$root_dir"; or fail "live namespace scan failed"
end

set -l group all
if test (count $argv) -gt 0
    set group $argv[1]
end

switch "$group"
    case codex-command-matrix
        assert_inventory
        assert_command_matrix
    case variant-parity
        assert_variant_parity
    case grader-immutability
        assert_grader_immutability
    case guidance-cutover
        assert_guidance_and_docs
    case installer-runtime
        assert_installer
    case canonical-inventory
        assert_inventory
    case namespace-scan
        assert_namespace
    case all
        assert_inventory
        assert_command_matrix
        assert_variant_parity
        assert_grader_immutability
        assert_guidance_and_docs
        assert_installer
        assert_namespace
    case '*'
        fail "unknown test group: $group"
end

echo "PASS: $group"
