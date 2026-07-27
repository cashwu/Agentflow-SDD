#!/usr/bin/env fish

set -g root_dir (path resolve (dirname (status filename))/../../..)
set -g cash_skills analyze apply archive ask audit commit debug discuss drift ingest propose verify
set -g divergent_skills analyze ask audit discuss drift ingest propose verify

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

function write_bundle_version_fixture --argument-names path shape
    python3 -c '
import sys
from pathlib import Path

content = Path(sys.argv[1]).read_bytes()
fixtures = {
    "valid": content,
    "no-lf": content[:-1],
    "crlf": content[:-1] + b"\r\n",
    "multiple-lf": content + b"\n",
    "empty": b"",
    "leading-zero": b"0" + content,
}
Path(sys.argv[2]).write_bytes(fixtures[sys.argv[3]])
' "$root_dir/cash-skills.version" "$path" "$shape"; or fail "could not create bundle version fixture"
    chmod 0644 "$path"; or fail "could not set bundle version fixture mode"
end

function bundle_version_shape_is_valid --argument-names path
    python3 -c '
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[2])
from cash_cli.installer import InstallerError, version_parts

content = Path(sys.argv[1]).read_bytes()
if not content.endswith(b"\n") or content.count(b"\n") != 1:
    raise SystemExit(1)
try:
    version_parts(content[:-1].decode("utf-8"))
except (InstallerError, UnicodeDecodeError):
    raise SystemExit(1)
' "$path" "$root_dir/.cash-skills/lib"
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
        '"$cash_cli" touched record "<change-name>" --path <path>' \
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
    for path in \
        "$root_dir/.agents/skills/cash-propose/SKILL.md" \
        "$root_dir/.agents/skills/cash-apply/SKILL.md" \
        "$root_dir/.claude/skills/cash-propose/SKILL.md" \
        "$root_dir/.claude/skills/cash-apply/SKILL.md"
        for literal in \
            'record every signal file this step created or updated' \
            "record the files that round's Fix Actions modified outside the change directory" \
            'carry this warning into the final completion output' \
            '"$cash_cli" touched ensure "<change-name>"' \
            '"$cash_cli" touched record "<change-name>" --path <path>' \
            'rebuild the receipt before the next cash command'
            assert_contains "$path" "$literal" "review-loop output tracking"
        end
    end
    for path in "$root_dir/.agents/skills/cash-commit/SKILL.md" "$root_dir/.claude/skills/cash-commit/SKILL.md"
        for literal in \
            'Detect a post-archive empty allowlist' \
            'parsed files array is empty' \
            'openspec/changes/.parked/<change-name>/' \
            'openspec/changes/archive/<date>-<change-name>/' \
            'keep the existing behavior and continue to step 3' \
            'except when step 2a establishes a post-archive recovery source' \
            'point-in-time snapshot taken at archive time' \
            'stop without committing' \
            'master_digests' \
            'every `openspec/specs/` path stays in Unrelated Changes' \
            'NEVER fall through to classifying every dirty source file as Unrelated'
            assert_contains "$path" "$literal" "post-archive empty allowlist guard"
        end
    end
    for path in "$root_dir/.agents/skills/cash-commit/SKILL.md" "$root_dir/.claude/skills/cash-commit/SKILL.md"
        for literal in \
            '### Review Loop Outputs' \
            'a shared signal file cannot be split by change' \
            'only when that other change directory still exists'
            assert_contains "$path" "$literal" "review-loop output commit plan"
        end
    end
    for path in "$root_dir/.agents/skills/cash-apply/SKILL.md" "$root_dir/.claude/skills/cash-apply/SKILL.md"
        for literal in 'Archive first, then commit together' 'deletes the touched state that'
            assert_contains "$path" "$literal" "commit-before-archive guidance"
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

function assert_tdd_discipline
    for variant in .agents .claude
        set -l relative "$variant/skills/cash-apply/SKILL.md"
        set -l path "$root_dir/$relative"
        set -l consumer_count (rg -Fo -- '"$cash_cli" instructions --skill tdd' "$path" | wc -l | string trim)
        test "$consumer_count" = 1; or fail "$relative must contain exactly one conditional TDD instruction consumer; found $consumer_count"

        assert_contains "$path" 'If `tdd: true` is set' "conditional TDD instruction consumer"
        assert_contains "$path" 'follow the returned `instruction`' "canonical TDD instruction consumer"
        assert_contains "$path" 'If `tdd: false` is set' "disabled-TDD ordering contract"
        assert_contains "$path" 'do not apply TDD ordering' "disabled-TDD ordering contract"

        set -l rgr_count (rg -Fo -- 'Red-Green-Refactor' "$path" | wc -l | string trim)
        test "$rgr_count" = 0; or fail "$relative must contain zero Red-Green-Refactor literals; found $rgr_count"
        assert_absent "$path" (string escape --style=regex 'For each task, write a failing test FIRST, then implement to make it pass') "retired per-task absolute fail-first rule"
        assert_absent "$path" (string escape --style=regex 'Write or update the relevant test before marking the task done, even when TDD is disabled or the task is a small refactor') "retired test-for-every-task rule"

        assert_contains "$path" 'verification evidence appropriate to the task' "shared verification-evidence gate"
        assert_contains "$path" 'test, CLI, analyzer, or manual assertion' "named verification targets"
        assert_contains "$path" 'Before calling `task done`' "task-done verification gate"

        assert_contains "$path" 'high-fidelity acceptance references' "example-as-reference contract"
        assert_contains "$path" "Cover every in-scope example's GIVEN/WHEN/THEN input and expected output, including every row of an example table, in the task's verification evidence." "example-table every-row contract"
        assert_contains "$path" 'concrete risk or boundary reason' "reasoned extra-case contract"
        assert_contains "$path" 'not a closed input set' "example input-set contract"
        assert_absent "$path" (string escape --style=regex 'Do NOT invent additional test values beyond what the spec examples provide without reason. The examples ARE the agreed specification.') "retired closed-example rule"
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
    set -l version_fixture (mktemp /tmp/cash-bundle-version.XXXXXX)
    write_bundle_version_fixture "$version_fixture" valid
    bundle_version_shape_is_valid "$version_fixture"; or begin
        command rm -f -- "$version_fixture"
        fail "valid bundle version fixture was rejected"
    end
    for invalid_shape in no-lf crlf multiple-lf empty leading-zero
        write_bundle_version_fixture "$version_fixture" "$invalid_shape"
        if bundle_version_shape_is_valid "$version_fixture"
            command rm -f -- "$version_fixture"
            fail "invalid bundle version fixture was accepted: $invalid_shape"
        end
    end
    command rm -f -- "$version_fixture"
    python3 "$root_dir/scripts/cash-skills/tests/test_bundle_version_history.py"; or fail "bundle version history contract tests failed"
end

function assert_namespace
    set -lx PYTHONDONTWRITEBYTECODE 1
    python3 "$root_dir/scripts/cash-skills/tests/test_live_namespace.py" "$root_dir"; or fail "live namespace scan failed"
end

function fallback_statement_count --argument-names path
    perl -ne '
BEGIN {
    $count = 0;
}
sub axis_a {
    my ($line) = @_;
    return $line =~ /(?:AskUserQuestion|interaction|(?:this|the)\s+(?:\*\*)?tool).*?(?:not\s+available|unavailable)/i
        || $line =~ /\bno\b.*?AskUserQuestion.*?available/i;
}
sub finish {
    my $same_prompt = $block =~ /\bask\b/i
        || $block =~ /\b(?:present|show|offer)\b.*?\b(?:questions?|options?)\b/i;
    if ($collect && $same_prompt && $block =~ /plain[- ](?:text|language)/i && $block =~ /\bwait\b/i) {
        $count++;
    }
    $collect = 0;
    $block = "";
}
if (/^\s*$/) {
    finish();
} elsif (axis_a($_)) {
    finish() if $collect;
    $collect = 1;
    $block = $_;
} elsif ($collect) {
    $block .= $_;
}
END {
    finish();
    print "$count\n";
}
' "$path"
end

function assert_fallback_parser_examples
    set -l fixture (mktemp /tmp/cash-fallback-parser.XXXXXX)

    printf '%s\n' \
        'If the AskUserQuestion tool is unavailable, ask the same question in plain text and wait.' \
        >"$fixture"
    test (fallback_statement_count "$fixture") = 1; or fail "fallback parser rejected single-line question form"

    printf '%s\n' \
        'If the AskUserQuestion tool is unavailable:' \
        'present the same options in plain text and wait.' \
        >"$fixture"
    test (fallback_statement_count "$fixture") = 1; or fail "fallback parser rejected multi-line option form"

    printf '%s\n' \
        'If interaction is unavailable, do not write the entry.' \
        '' \
        'Use plain-language option labels and wait for the user.' \
        >"$fixture"
    test (fallback_statement_count "$fixture") = 0; or fail "fallback parser counted a one-axis paragraph"

    printf '%s\n' \
        'If the AskUserQuestion tool is unavailable, ask the same question in plain text and wait.' \
        '' \
        'If the tool is unavailable, present the same options in plain text and wait.' \
        >"$fixture"
    test (fallback_statement_count "$fixture") = 2; or fail "fallback parser missed a duplicate statement"

    command rm -f -- "$fixture"
end

function assert_well_formedness
    assert_fallback_parser_examples

    for variant in .agents .claude
        for skill in $cash_skills
            set -l relative "$variant/skills/cash-$skill/SKILL.md"
            set -l path "$root_dir/$relative"
            set -l invalid (perl -ne '$count = 0; while (/(?<!`)``(?!`)/g) { $count++ } print "$.:$_" if $count % 2' "$path" | string collect)
            test -z "$invalid"; or fail "$relative contains an empty code span at $invalid"
        end
    end

    for skill in $cash_skills
        set -l relative ".agents/skills/cash-$skill/SKILL.md"
        set -l path "$root_dir/$relative"
        set -l frontmatter (mktemp "/tmp/cash-$skill-frontmatter.XXXXXX")
        awk 'NR == 1 && $0 == "---" { front = 1; next } front && $0 == "---" { exit } front { print }' "$path" >"$frontmatter"
        if rg -n '^(context|agent|disallowedTools):' "$frontmatter"
            command rm -f -- "$frontmatter"
            fail "$relative contains Claude-only frontmatter"
        end
        command rm -f -- "$frontmatter"
    end

    for variant in .agents .claude
        set -l propose "$root_dir/$variant/skills/cash-propose/SKILL.md"
        for heading in '## Why' '## What Changes' '## Problem' '## Root Cause' '## Success Criteria'
            assert_absent "$propose" (string escape --style=regex "$heading") "CLI-owned proposal template"
        end
        assert_absent "$root_dir/$variant/skills/cash-drift/SKILL.md" 'copy-pasteable' "variant-neutral drift recommendation"
    end

    set -l ingest "$root_dir/.agents/skills/cash-ingest/SKILL.md"
    assert_absent "$ingest" '~/.claude/plans/|(?<![A-Za-z0-9_*])(?:[A-Za-z0-9_.~-]+/)+(?:<name>|agile-discovering-rocket)(?:\\.md)?' "directory-free Codex plan references"

    for variant in .agents .claude
        set -l apply "$root_dir/$variant/skills/cash-apply/SKILL.md"
        assert_contains "$apply" '本次 diff 的每一行，都能直接追溯到 `tasks.md` 中的某條任務或 `design.md` 中的 Implementation Contract 項目' "focused implementation traceability"
        assert_contains "$apply" '若刻意 deviate，依 Implementation Notes Protocol 寫一筆 `deviation` 條目' "focused implementation deviation protocol"
        for forbidden in \
            '巢狀三元運算子（nested ternary）' \
            'dense one-liner' \
            '把多個關注點塞進同一個 function' \
            '移除有意義的中介變數' \
            '移除真正在傳遞意圖的命名常數' \
            '拿掉合理的抽象'
            assert_absent "$apply" (string escape --style=regex "$forbidden") "criterion-based implementation discipline"
        end
        for skill in apply propose
            set -l path "$root_dir/$variant/skills/cash-$skill/SKILL.md"
            assert_contains "$path" 'Focused Implementation Discipline' "focused implementation discipline reference"
            assert_absent "$path" 'Simplicity First|Surgical Changes' "retired implementation discipline reference"
        end
    end

    set -l ask_user_skills analyze apply archive commit drift ingest propose verify
    for variant in .agents .claude
        for skill in $cash_skills
            set -l path "$root_dir/$variant/skills/cash-$skill/SKILL.md"
            set -l expected 0
            contains "$skill" $ask_user_skills; and set expected 1
            set -l actual (fallback_statement_count "$path")
            test "$actual" = "$expected"; or fail "$variant/skills/cash-$skill/SKILL.md has $actual interaction fallback statements; expected $expected"
        end
    end
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
    case tdd-discipline
        assert_tdd_discipline
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
    case well-formedness
        assert_well_formedness
    case all
        assert_inventory
        assert_well_formedness
        assert_command_matrix
        assert_tdd_discipline
        assert_variant_parity
        assert_grader_immutability
        assert_guidance_and_docs
        assert_installer
        assert_namespace
    case '*'
        fail "unknown test group: $group"
end

echo "PASS: $group"
