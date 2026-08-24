#!/usr/bin/env fish

set -g root_dir (path resolve (dirname (status filename))/../../..)
set -g cash_skills analyze apply archive ask audit commit debug discuss drift ingest propose verify

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
        '"$cash_cli" instructions --skill test-quality' \
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

function staging_failed --argument-names staging message
    command rm -rf -- "$staging"
    fail "$message"
end

function normalized_gate_hash --argument-names path
    awk '/^<!-- REVIEW-GATE:BEGIN -->$/ { copy = 1; next } /^<!-- REVIEW-GATE:END -->$/ { copy = 0 } copy { print }' "$path" \
        | perl -pe 's/(?<![A-Za-z0-9_.-])(?:\$|\/)cash-/\@cash-/g' \
        | shasum -a 256 | awk '{ print $1 }'
end

function assert_generated_fresh
    set -l staging (mktemp -d /tmp/cash-generated.XXXXXX)
    mkdir -p "$staging/scripts/cash-skills/blocks"; or staging_failed "$staging" "could not stage the generation input set"
    for relative in scripts/cash-skills/blocks/review-gate.md scripts/cash-skills/variant-rules.yaml
        cp "$root_dir/$relative" "$staging/$relative"; or staging_failed "$staging" "could not stage $relative"
    end
    for skill in $cash_skills
        set -l relative ".claude/skills/cash-$skill/SKILL.md"
        mkdir -p "$staging/.claude/skills/cash-$skill"; or staging_failed "$staging" "could not stage $relative"
        cp "$root_dir/$relative" "$staging/$relative"; or staging_failed "$staging" "could not stage $relative"
    end

    fish "$root_dir/scripts/cash-skills/generate.fish" "$staging" >/dev/null; or staging_failed "$staging" "generation pipeline failed"

    set -l generated .claude/skills/cash-propose/SKILL.md .claude/skills/cash-apply/SKILL.md
    for skill in $cash_skills
        set -a generated ".agents/skills/cash-$skill/SKILL.md"
    end
    for relative in $generated
        cmp -s "$staging/$relative" "$root_dir/$relative"; or begin
            diff -u "$root_dir/$relative" "$staging/$relative" >&2
            command rm -rf -- "$staging"
            fail "$relative is stale; rerun scripts/cash-skills/generate.fish"
        end
    end
    command rm -rf -- "$staging"

    set -l gate_hash
    for relative in \
        .claude/skills/cash-propose/SKILL.md \
        .claude/skills/cash-apply/SKILL.md \
        .agents/skills/cash-propose/SKILL.md \
        .agents/skills/cash-apply/SKILL.md
        set -l path "$root_dir/$relative"
        test (rg -Fxc '<!-- REVIEW-GATE:BEGIN -->' "$path" | string trim) = 1; or fail "$relative must have one review-gate begin anchor"
        test (rg -Fxc '<!-- REVIEW-GATE:END -->' "$path" | string trim) = 1; or fail "$relative must have one review-gate end anchor"
        set -l actual (normalized_gate_hash "$path")
        if test -z "$gate_hash"
            set gate_hash "$actual"
        else
            test "$actual" = "$gate_hash"; or fail "$relative gate region differs after invocation normalization"
        end
    end
end

function assert_tdd_discipline
    set -l test_quality_gate_literals \
        'name a realistic production defect' \
        'expected value' \
        'observable behavior instead' \
        'slow or external boundary' \
        'bounded mutation check'

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

        set -l quality_count (rg -Fo -- '"$cash_cli" instructions --skill test-quality' "$path" | wc -l | string trim)
        test "$quality_count" = 1; or fail "$relative must contain exactly one on-demand test-quality instruction consumer; found $quality_count"
        assert_contains "$path" 'when a task will add or modify any test' "on-demand test-quality trigger"
        assert_contains "$path" 'Regardless of the `tdd` value' "toggle-independent test-quality obligation"
        assert_contains "$path" 'do not add a test for form' "no-formal-test contract"
        for duplicated in $test_quality_gate_literals
            assert_absent "$path" (string escape --style=regex "$duplicated") "duplicated test-quality semantics"
        end

        for field in '`delivery`' '`verification`' '`regression`' '`success`' '`red`'
            assert_contains "$path" "$field" "task evidence field $field"
        end
        assert_contains "$path" 'Map the task' "task evidence mapping"
        assert_contains "$path" '`verification` names exactly one primary target' "single primary target mapping"
        assert_contains "$path" 'MUST NOT mix in regression, publication, or task completion results' "success marker boundary"
        assert_contains "$path" 'pure-refactor or remaining-task classification reason' "red field classification reason"
        assert_contains "$path" 'take the existing unclear-task branch before any production edit' "missing-field pause branch"
        assert_contains "$path" "run the targets named in the task's `regression` field" "regression target execution obligation"
    end

    for variant in .agents .claude
        set -l relative "$variant/skills/cash-debug/SKILL.md"
        set -l path "$root_dir/$relative"

        set -l debug_tdd_count (rg -Fo -- '"$cash_cli" instructions --skill tdd' "$path" | wc -l | string trim)
        test "$debug_tdd_count" = 1; or fail "$relative must contain exactly one conditional TDD instruction consumer; found $debug_tdd_count"
        set -l debug_quality_count (rg -Fo -- '"$cash_cli" instructions --skill test-quality' "$path" | wc -l | string trim)
        test "$debug_quality_count" = 1; or fail "$relative must contain exactly one on-demand test-quality instruction consumer; found $debug_quality_count"

        assert_contains "$path" 'If `tdd: true` is set' "conditional TDD instruction consumer"
        assert_contains "$path" 'follow the returned `instruction`' "canonical TDD instruction consumer"
        assert_contains "$path" 'If `tdd: false` is set' "disabled-TDD ordering contract"
        assert_contains "$path" 'do not force a fail-first ordering' "disabled-TDD ordering contract"

        assert_contains "$path" 'Record the verification evidence carrier' "Phase 3 evidence carrier"
        assert_contains "$path" 'exactly one primary verification target' "Phase 3 primary target"
        assert_contains "$path" 'the related regression targets, the success marker' "Phase 3 regression and success markers"
        assert_contains "$path" 'MUST NOT assume a `tasks.md` contract exists' "tasks.md-independent carrier"
        assert_contains "$path" 'a minimum root-cause fix, a named primary verification target' "shared verification gate"
        assert_contains "$path" 'The numbered order below is the `tdd: false` sequence' "toggle-scoped fix ordering"
        assert_contains "$path" 'observe its failure marker before any production edit' "red-before-production-edit ordering"

        set -l debug_rgr_count (rg -Fo -- 'Red-Green-Refactor' "$path" | wc -l | string trim)
        test "$debug_rgr_count" = 0; or fail "$relative must contain zero Red-Green-Refactor literals; found $debug_rgr_count"
        assert_absent "$path" (string escape --style=regex 'Write a failing test') "retired unconditional failing-test step"
        assert_absent "$path" (string escape --style=regex 'Phase 4 always starts with a failing test') "retired Phase-4-always-failing-test rule"
        for duplicated in $test_quality_gate_literals
            assert_absent "$path" (string escape --style=regex "$duplicated") "duplicated test-quality semantics"
        end
    end

    assert_command_matrix

    assert_tdd_variant_parity
end

function assert_tdd_variant_parity
    python3 -c '
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
prefix = re.compile(r"(?<![A-Za-z0-9_.-])(?:\$|/)cash-")

SECTIONS = (
    ("cash-apply", "tdd and test-quality consumers", "5. **Check project preferences**", "6. **Show current progress**"),
    ("cash-apply", "task evidence and verification gate", "   For each pending task:", "   **Pause if:**"),
    ("cash-debug", "root cause carrier and fix ordering", "## Phase 3: Root Cause", "## Guardrails"),
)


def section(path, begin, end):
    lines = path.read_text(encoding="utf-8").splitlines()
    try:
        start = lines.index(begin)
    except ValueError:
        raise SystemExit("parity: missing section start in " + str(path) + ": " + begin)
    for offset, line in enumerate(lines[start + 1:], start=start + 1):
        if line == end:
            body = lines[start:offset]
            break
    else:
        raise SystemExit("parity: missing section end in " + str(path) + ": " + end)
    if len(body) < 2:
        raise SystemExit("parity: empty section in " + str(path) + ": " + begin)
    return [prefix.sub("@cash-", line) for line in body]


for skill, label, begin, end in SECTIONS:
    claude = section(root / ".claude/skills" / skill / "SKILL.md", begin, end)
    codex = section(root / ".agents/skills" / skill / "SKILL.md", begin, end)
    if claude != codex:
        for index, (left, right) in enumerate(zip(claude, codex)):
            if left != right:
                raise SystemExit(
                    "parity: " + skill + " " + label + " differs at line " + str(index + 1)
                    + "\n  .claude: " + left + "\n  .agents: " + right
                )
        raise SystemExit("parity: " + skill + " " + label + " has a different line count")
' "$root_dir"; or fail "cash-apply/cash-debug TDD sections are not variant-identical"
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
            'scripts/cash-skills/blocks/review-gate.md' \
            'scripts/cash-skills/generate.fish' \
            'scripts/cash-skills/variant-rules.yaml' \
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
            '.cash-skills/bin/cash search "<query>" --limit 10 --json' \
            '.cash-skills/manifest.tsv' \
            'clone／pull 後直接使用' \
            'invalid manifest' \
            '不得執行 `--init-receipt`' \
            '或以 `receipt_invalid` 回報 stable record identity drift 時' \
            'stable record content drift 不得以重新簽發處理' \
            'MUST 先執行 `git rm --cached .cash-skills/receipt.tsv` 解除追蹤，再重新簽發' \
            'identity drift 這個入口只在診斷「僅」指名該 stable record 時適用' \
            '診斷同時指名 `runtime record drift:` 或 `skill record drift:` 時，MUST 改為把該筆 record 還原成 receipt 記錄的內容或從可信 source 重新安裝，MUST NOT 重新簽發'
            assert_contains "$path" "$literal" "canonical Cash guidance"
        end
    end
    awk '/^<!-- CASH:START -->$/ { copy = 1; next } /^<!-- CASH:END -->$/ { copy = 0 } copy { print }' "$root_dir/AGENTS.md" >"$agents"
    awk '/^<!-- CASH:START -->$/ { copy = 1; next } /^<!-- CASH:END -->$/ { copy = 0 } copy { print }' "$root_dir/CLAUDE.md" >"$claude"
    cmp -s "$agents" "$claude"; or fail "AGENTS.md and CLAUDE.md Cash blocks differ"
    test (shasum -a 256 "$agents" | awk '{ print $1 }') = 5f4b9f4b94bd39a7e262a1e12dea901bcd35c10fc2c32d925c39e00515b193bc; or fail "canonical Cash guidance baseline drifted"
    command rm -f -- "$agents" "$claude"

    set -l premise 'if .cash-skills/receipt.tsv is tracked by version control, untrack it first because it is machine-local identity'
    for relative in .cash-skills/bin/cash .cash-skills/lib/cash_cli/installer.py
        assert_contains "$root_dir/$relative" "$premise" "shared identity-drift version-control premise"
    end

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
        'git rm --cached .cash-skills/receipt.tsv' \
        '--vendor <project>' \
        '--vendor --dry-run' \
        '--vendor --force' \
        'portable manifest' \
        'Git logical mode' \
        'manifest-presence' \
        'receiptless' \
        'launcher rebind'
        assert_contains "$docs" "$literal" "current Cash documentation"
    end

    set -l init_docs "$root_dir/CASH-INIT-RECEIPT.md"
    for literal in \
        'init_python_version' \
        'init_outside_worktree' \
        'init_source_repo' \
        'init_vendored_bundle' \
        'init_config_invalid' \
        'init_inventory_invalid' \
        'init_write_failed' \
        'PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt' \
        './install-cash-skills.fish --self' \
        'portable manifest' \
        '--vendor'
        assert_contains "$init_docs" "$literal" "current Cash init-receipt documentation"
    end
    assert_absent "$init_docs" 'launcher 的主流程無條件執行 `validate_receipt`' "portable/receipt trust-mode split"
    assert_absent "$init_docs" '重建 source repo 自己的 receipt' "source self manifest ownership"
    assert_absent "$init_docs" '\\.cash-skills/bin/cash` 逐 byte不變|\\.cash-skills/bin/cash` 逐 byte 不變' "controlled launcher migration"

    python3 -c '
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from cash_cli.installer import PORTABLE_MANIFEST_PATH, source_inventory

root = Path(sys.argv[2])
_, records, _ = source_inventory(root)
paths = {record.path for record in records}
if PORTABLE_MANIFEST_PATH in paths:
    raise SystemExit("portable manifest must not enter receipt inventory")
' "$root_dir/.cash-skills/lib" "$root_dir"; or fail "portable manifest receipt-inventory separation failed"
end

function assert_installer
    fish -n "$root_dir/install-cash-skills.fish"; or fail "installer wrapper syntax is invalid"
    set -l help (fish --no-config "$root_dir/install-cash-skills.fish" --help | string collect)
    for option in '--target <project>' '--vendor <project>' '--self' '--register <project>' '--unregister <project>' '--list' '--all' '--dry-run' '--force'
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

function assert_minimal_solution_discipline
    python3 -c '
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
apply_paths = [
    root / ".claude/skills/cash-apply/SKILL.md",
    root / ".agents/skills/cash-apply/SKILL.md",
]
canonical_paths = [
    root / ".claude/skills/cash-propose/SKILL.md",
    root / ".claude/skills/cash-apply/SKILL.md",
    root / ".agents/skills/cash-propose/SKILL.md",
    root / ".agents/skills/cash-apply/SKILL.md",
]
shared_path = root / "scripts/cash-skills/blocks/review-gate.md"

rungs = ["reuse", "stdlib", "native", "installed-dependency", "custom"]
safety_items = [
    "observable behavior",
    "interface／data shape",
    "failure modes",
    "acceptance criteria",
    "trust-boundary validation",
    "data-loss prevention",
    "security",
    "accessibility",
]
understanding = "Before writing code, re-read and understand the task, relevant spec, Implementation Contract, and actual call flow."
eligibility = "A candidate is eligible only when it preserves " + ", ".join(safety_items[:-1]) + ", and " + safety_items[-1] + "."
continue_clause = "If an earlier rung does not satisfy the contract, exclude it and continue"
yagni_clause = "MUST NOT use YAGNI to mark it complete or silently skip it"
tie_break = "Within the same rung among candidates of comparable cost, choose stronger edge-case correctness first, then the candidate that follows the existing codebase pattern."
traceability = "本次 diff 的每一行，都能直接追溯到 `tasks.md` 中的某條任務或 `design.md` 中的 Implementation Contract 項目"
circuit_breaker = "a synchronization primitive, identity/generation type, or state machine not defined in design.md"
paired_fields = "append both fields immediately after `原因`; never add only one and never fill either with `none`"
no_ceiling = "Preserve this four-field entry shape for every `open-question` and for a `deviation` with no nontrivial known ceiling."
trigger_clause = "A vague trigger such as「之後需要時」or「規模變大時」is insufficient."
routine_clause = "Routine implementation, an ordinary tradeoff, or an internal choice that does not deviate from an artifact creates no note."
invasive_clause = "the substitute is not contract-preserving: do not record it and continue; use the existing pause branch and direct the user to"
reviewer_notes = "Reviewer A and Reviewer V also evaluate every known-ceiling `deviation` for paired `限制`／`重訪條件` fields, an observable or measurable trigger, and a ceiling outside the current contract envelope."

def require(condition, message):
    if not condition:
        raise ValueError(message)

def validate_apply(text, ingest_command):
    ingest_clause = invasive_clause + " `" + ingest_command + "`."
    for literal in [understanding, eligibility, continue_clause, yagni_clause, tie_break, traceability, paired_fields, no_ceiling, trigger_clause, routine_clause, ingest_clause, reviewer_notes]:
        require(literal in text, "missing apply contract: " + literal)
    ladder_start = text.index("ordered minimal-solution ladder")
    ladder_end = text.index("Then check:", ladder_start)
    ladder = text[ladder_start:ladder_end]
    positions = []
    for rung in rungs:
        marker = "`" + rung + "`"
        require(ladder.count(marker) == 1, "rung must occur exactly once in ladder: " + rung)
        positions.append(ladder.index(marker))
    require(positions == sorted(positions), "rung order changed")
    require(text.count(circuit_breaker) == 2, "circuit-breaker literal must occur twice")
    require("- 限制：" in text and "- 重訪條件：" in text, "known-ceiling fields must be paired")
    forbidden = [r"(?im)^\s*\d+\.\s+`one line`", r"net:\s*-", r"LOC gate", r"complexity reviewer", r"third reviewer", r"限制：\s*none", r"重訪條件：\s*none"]
    for pattern in forbidden:
        require(not re.search(pattern, text), "forbidden contract found: " + pattern)

complexity_literals = [
    "new dependency",
    "single-implementation abstraction",
    "pass-through wrapper",
    "speculative configuration",
    "duplicate existing capability",
    "`stdlib`／`native` replacement opportunity",
]
propose_scope = "For cash-propose: scan proposal, design, and tasks for complexity introduced or permitted by those artifacts without evidence that the contract requires it"
apply_scope = "For cash-apply: scan only complexity introduced by the changed diff"
contract_exemption = "mechanisms explicitly required by the contract"
rationale_exemption = "intentional complexity already justified in `design.md`, `implementation-notes.md`, proposal Non-Goals, or `## Alternatives Considered`"
exclusions = "Do not report this lens against pre-existing code, unrelated refactors, " + contract_exemption + ", or " + rationale_exemption + "."
metric_boundary = "LOC, estimated token use, cost, and time are not inputs to a finding, severity, confidence, or gate decision."

def validate_review(text):
    for literal in complexity_literals + [propose_scope, apply_scope, exclusions, contract_exemption, rationale_exemption, metric_boundary, "Reviewer A — Adherence", "Reviewer B — Quality", "Reviewer V — Verification"]:
        require(literal in text, "missing reviewer contract: " + literal)
    require("complexity reviewer" not in text.lower(), "new complexity reviewer role")
    require("third reviewer" not in text.lower(), "third reviewer role")
    require("net: -" not in text, "net-line metric gate")
    full_start = text.index("Full rounds occur only")
    micro_start = text.index("Each micro round", full_start)
    pre_spawn = text.index("A pre-spawn short-circuit round", micro_start)
    role_pattern = re.compile(r"(?m)^\s+- \*\*([^*]+)\*\*:")
    require(role_pattern.findall(text[full_start:micro_start]) == ["Reviewer A — Adherence", "Reviewer B — Quality"], "full-round reviewer topology changed")
    require(role_pattern.findall(text[micro_start:pre_spawn]) == ["Reviewer V — Verification"], "micro-round reviewer topology changed")

def expect_rejected(label, validator, text):
    try:
        validator(text)
    except (ValueError, AssertionError):
        return
    raise AssertionError("mutation was accepted: " + label)

for path in apply_paths:
    text = path.read_text(encoding="utf-8")
    ingest_command = "$cash-ingest" if ".agents" in path.parts else "/cash-ingest"
    validator = lambda value, command=ingest_command: validate_apply(value, command)
    validator(text)
    for rung in rungs:
        expect_rejected("remove rung " + rung, validator, text.replace("`" + rung + "`", "`removed-rung`", 1))
    expect_rejected("swap rung order", validator, text.replace("1. `reuse`", "1. `stdlib`", 1).replace("2. `stdlib`", "2. `reuse`", 1))
    expect_rejected("remove earlier-rung continuation", validator, text.replace(continue_clause, "Stop when an earlier rung fails", 1))
    expect_rejected("reverse YAGNI", validator, text.replace(yagni_clause, "use YAGNI to mark it complete or silently skip it", 1))
    expect_rejected("swap tie-break order", validator, text.replace("edge-case correctness first, then the candidate that follows the existing codebase pattern", "existing codebase pattern first, then edge-case correctness", 1))
    for item in safety_items:
        expect_rejected("remove safety item " + item, validator, text.replace(eligibility, eligibility.replace(item, "removed-safety-item"), 1))
    expect_rejected("missing ceiling limitation", validator, text.replace("- 限制：", "- removed-field：", 1))
    expect_rejected("missing revisit trigger", validator, text.replace("- 重訪條件：", "- removed-field：", 1))
    expect_rejected("vague trigger accepted", validator, text.replace(trigger_clause, "A vague trigger such as「之後需要時」is sufficient.", 1))
    expect_rejected("contract-invasive continuation", validator, text.replace(invasive_clause, "the substitute may be recorded and continued; direct the user to", 1))
    exact_ingest_clause = invasive_clause + " `" + ingest_command + "`."
    expect_rejected("wrong ingest destination", validator, text.replace(exact_ingest_clause, invasive_clause + " `wrong-destination`.", 1))
    expect_rejected("routine stdlib note", validator, text.replace(routine_clause, "Routine `stdlib` implementation creates a deviation note.", 1))
    expect_rejected("one-line rung", validator, text.replace("5. `custom`", "5. `one line`\n     6. `custom`", 1))
    expect_rejected("forced none fields", validator, text.replace("never fill either with `none`", "fill missing values with `none`", 1))

shared = shared_path.read_text(encoding="utf-8")
validate_review(shared)
for path in canonical_paths:
    validate_review(path.read_text(encoding="utf-8"))
expect_rejected("remove changed-diff restriction", validate_review, shared.replace(apply_scope, "For cash-apply: scan repository complexity", 1))
expect_rejected("remove contract exemption", validate_review, shared.replace(contract_exemption, "contract mechanisms", 1))
expect_rejected("remove rationale exemption", validate_review, shared.replace(rationale_exemption, "documented complexity", 1))
expect_rejected("metrics become gate input", validate_review, shared.replace(metric_boundary, "LOC, estimated token use, cost, and time are inputs to the gate decision.", 1))
reviewer_c = "     - **Reviewer C — Simplicity**: score the implementation.\n"
rater = "     - **Rater — Simplicity**: score the implementation.\n"
auditor_c = "     - **Auditor C — Simplicity**: score the implementation.\n"
expect_rejected("extra Reviewer C", validate_review, shared.replace("   - Each micro round", reviewer_c + "   - Each micro round", 1))
expect_rejected("extra rater", validate_review, shared.replace("   - Each micro round", rater + "   - Each micro round", 1))
expect_rejected("extra Auditor C", validate_review, shared.replace("   - Each micro round", auditor_c + "   - Each micro round", 1))
expect_rejected("net-line metric", validate_review, shared + "\nnet: -10 lines\n")

def validate_note_entry(entry, known_ceiling=False):
    for field in ["類別", "任務", "內容", "原因"]:
        require("- " + field + "：" in entry, "missing base note field: " + field)
    has_limit = "- 限制：" in entry
    has_trigger = "- 重訪條件：" in entry
    require(has_limit == has_trigger, "ceiling fields are not paired")
    require((has_limit and has_trigger) if known_ceiling else (not has_limit and not has_trigger), "wrong ceiling shape")
    if known_ceiling:
        trigger = next(line.removeprefix("- 重訪條件：").strip() for line in entry.splitlines() if line.startswith("- 重訪條件："))
        require(trigger and trigger not in {"之後需要時", "規模變大時"}, "revisit trigger must be observable or measurable")

validate_note_entry("## date — title\n- 類別：deviation\n- 任務：x\n- 內容：x\n- 原因：x\n")
for missing in ["- 限制：100 ops/s\n", "- 重訪條件：observed 100 ops/s\n"]:
    fixture = "## date — title\n- 類別：deviation\n- 任務：x\n- 內容：x\n- 原因：x\n- 限制：100 ops/s\n- 重訪條件：observed 100 ops/s\n".replace(missing, "")
    expect_rejected("known-ceiling field pair", lambda value: validate_note_entry(value, known_ceiling=True), fixture)
for vague in ["之後需要時", "規模變大時"]:
    fixture = "## date — title\n- 類別：deviation\n- 任務：x\n- 內容：x\n- 原因：x\n- 限制：100 ops/s\n- 重訪條件：" + vague + "\n"
    expect_rejected("vague known-ceiling trigger " + vague, lambda value: validate_note_entry(value, known_ceiling=True), fixture)

print("minimal-solution-discipline contract and mutations: ok")
' "$root_dir"; or fail "minimal-solution discipline contract failed"
end

set -l group all
if test (count $argv) -gt 0
    set group $argv[1]
end

switch "$group"
    case codex-command-matrix
        assert_inventory
        assert_command_matrix
    case generated-fresh
        assert_generated_fresh
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
    case minimal-solution-discipline
        assert_minimal_solution_discipline
    case all
        assert_inventory
        assert_well_formedness
        assert_command_matrix
        assert_tdd_discipline
        assert_generated_fresh
        assert_grader_immutability
        assert_guidance_and_docs
        assert_installer
        assert_namespace
        assert_minimal_solution_discipline
    case '*'
        fail "unknown test group: $group"
end

echo "PASS: $group"
