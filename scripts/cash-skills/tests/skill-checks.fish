#!/usr/bin/env fish

if set -q CASH_SKILLS_TEST_ROOT
    set -g root_dir (path resolve "$CASH_SKILLS_TEST_ROOT")
else
    set -g root_dir (path resolve (dirname (status filename))/../../..)
end
set -g test_script (path resolve (status filename))
set -g cash_skills analyze apply archive ask audit commit debug discuss drift ingest propose verify

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function assert_contains --argument-names path literal contract
    set -l display_path (string replace -- "$root_dir/" '' "$path")
    rg -Fq -- "$literal" "$path"; or fail "$display_path violates $contract: missing '$literal'"
end

function assert_absent --argument-names path pattern contract
    set -l display_path (string replace -- "$root_dir/" '' "$path")
    if rg -Pq -- "$pattern" "$path"
        fail "$display_path violates $contract: matched forbidden pattern '$pattern'"
    end
end

function assert_variant_inventory --argument-names variant_root
    for skill in $cash_skills
        set -l relative_path "$variant_root/skills/cash-$skill/SKILL.md"
        set -l skill_path "$root_dir/$relative_path"
        test -f "$skill_path"; or fail "missing $relative_path"

        set -l declared_name (awk '
            NR == 1 && $0 == "---" { in_frontmatter = 1; next }
            in_frontmatter && $0 == "---" { exit }
            in_frontmatter && /^name: / { sub(/^name: /, ""); print; exit }
        ' "$skill_path")
        test "$declared_name" = "cash-$skill"; or fail "$relative_path has name '$declared_name'"

        if rg -q 'generatedBy: "Spectra"|spectraPlus(Version|Updated|Fingerprint)' "$skill_path"
            fail "$relative_path contains Spectra-generated ownership metadata"
        end
    end
end

function assert_cash_namespace --argument-names variant_root expected_prefix forbidden_pattern
    for skill in $cash_skills
        set -l relative_path "$variant_root/skills/cash-$skill/SKILL.md"
        set -l skill_path "$root_dir/$relative_path"

        if rg -Pn '(?<![[:alnum:]_.-])(?:\$|/)spectra-[a-z]' "$skill_path" >/dev/null
            fail "$relative_path contains an active spectra skill invocation"
        end
        if rg -Pn '(?<![[:alnum:]_.-])(?:\$|/)cash-[a-z-]+-plus' "$skill_path" >/dev/null
            fail "$relative_path contains a cash plus-tier invocation"
        end
        if rg -Pq "$forbidden_pattern" "$skill_path"
            fail "$relative_path uses the other variant's cash invocation syntax"
        end
    end

    rg -Fq "$expected_prefix""cash-propose" "$root_dir/$variant_root/skills/cash-discuss/SKILL.md"; or fail "$variant_root cash-discuss does not route to cash-propose"
    rg -Fq "$expected_prefix""cash-apply" "$root_dir/$variant_root/skills/cash-ingest/SKILL.md"; or fail "$variant_root cash-ingest does not route to cash-apply"
end

function assert_spectra_cli_contract
    for variant_root in .agents .claude
        set -l propose "$root_dir/$variant_root/skills/cash-propose/SKILL.md"
        set -l apply "$root_dir/$variant_root/skills/cash-apply/SKILL.md"
        set -l archive "$root_dir/$variant_root/skills/cash-archive/SKILL.md"
        rg -Fq 'spectra validate' "$propose"; or fail "$propose lost spectra validate"
        rg -Fq 'spectra instructions apply' "$apply"; or fail "$apply lost spectra instructions apply"
        rg -Fq 'spectra archive' "$archive"; or fail "$archive lost spectra archive"
    end
end

function assert_propose_contract --argument-names variant_root invocation
    set -l relative_path "$variant_root/skills/cash-propose/SKILL.md"
    set -l path "$root_dir/$relative_path"

    for marker in '<!-- SIGNALS-READ-STEP -->' '<!-- MECHANICAL-SELF-CHECK -->' '<!-- GRADER-IMMUTABILITY -->' '<!-- LOOP-LEDGER-STEP -->' '<!-- SIGNALS-WRITE-STEP -->'
        assert_contains "$path" "$marker" 'cash-propose retained quality gate'
    end
    for literal in 'proposal.md' 'design.md' 'tasks.md' 'spectra validate' 'Traditional Chinese' 'Traditional Chinese prose with English structural keywords' 'copied byte-for-byte from the current master spec' 'exceeds 15'
        assert_contains "$path" "$literal" 'cash-propose artifact and termination contract'
    end
    assert_contains "$path" "$invocation"'cash-ingest' 'cash-propose cash routing'
    assert_contains "$path" 'Do NOT invoke `spectra park`' 'cash-propose no-park termination'
    assert_absent "$path" '(?i)(?:spectra-propose-plus|propose-plus only|for propose-plus|plus proposal workflow|plus quality gate|generated plus|scripts/spectra-plus)' 'cash-propose ownership vocabulary'
    assert_absent "$path" '(?<![[:alnum:]_.-])(?:\$|/)cash-apply(?![[:alnum:]_.-])' 'cash-propose no-apply termination'
end

function assert_apply_contract --argument-names variant_root invocation
    set -l relative_path "$variant_root/skills/cash-apply/SKILL.md"
    set -l path "$root_dir/$relative_path"

    for marker in '<!-- BLOCKER-TRIAGE -->' '<!-- MECHANICAL-SELF-CHECK -->' '<!-- GRADER-IMMUTABILITY -->' '<!-- LOOP-LEDGER-STEP -->' '<!-- SIGNALS-WRITE-STEP -->'
        assert_contains "$path" "$marker" 'cash-apply retained quality gate'
    end
    for literal in 'implementation-notes.md' Surgical Simplicity 'tasks.md' '然後繼續該 task，不暫停' '暫停、報告 blocker' needs-design 'decision: aborted' 'decision: passed'
        assert_contains "$path" "$literal" 'cash-apply implementation contract'
    end
    assert_contains "$path" "$invocation"'cash-ingest' 'cash-apply design circuit breaker'
    assert_contains "$path" "$invocation"'cash-archive' 'cash-apply passed-only archive routing'
    assert_absent "$path" '(?i)(?:spectra-apply-plus|apply-plus task loop|during apply-plus|for apply-plus|plus quality gate|plus workflow|generated plus|scripts/spectra-plus)' 'cash-apply ownership vocabulary'
end

function assert_commit_contract --argument-names variant_root
    set -l relative_path "$variant_root/skills/cash-commit/SKILL.md"
    set -l path "$root_dir/$relative_path"

    for literal in '.spectra/touched/<change-name>.json' Customize 'Spec Sync Changes' openspec/specs/ 'openspec/changes/archive/<date>-<change>/' 'git status --porcelain'
        assert_contains "$path" "$literal" 'cash-commit archive-first allowlist'
    end
    assert_absent "$path" '(?i)(?:generated plus|spectra-[a-z-]+-plus|plus deletion|SPECTRA-COMMIT-GUARD)' 'cash-commit generated-plus exception removal'
    assert_absent "$path" openspec/archived/ 'cash-commit current archive path'
end

function assert_shared_gate_contract --argument-names variant_root skill
    set -l relative_path "$variant_root/skills/cash-$skill/SKILL.md"
    set -l path "$root_dir/$relative_path"

    for literal in \
        'Run max 6 rounds per loop run.' \
        'The first round of each loop run MUST be a full round.' \
        'the fourth round of the current run' \
        'Reviewer A — Adherence' \
        'Reviewer B — Quality' \
        'Reviewer V — Verification' \
        'exactly TWO fresh reviewer sub-agents in parallel' \
        'exactly ONE fresh sub-agent' \
        'cumulative blocking set' \
        unresolved-prior \
        fix-introduced \
        'accepted-risks.md' \
        'seeded re-run' \
        'explicit user consent in the current session' \
        'confidence < 50' \
        'confidence ∈ [50, 80)' \
        'confidence ≥ 80' \
        'retry once with a fresh sub-agent invocation' \
        'two consecutive times in a single round' \
        'Review round action obligation' \
        'Abort triage' \
        'openspec/changes/<change>/reviews/loop-ledger.tsv' \
        'scripts/cash-skills/tests/skill-checks.fish' \
        'single command-string argument to `sh -c`' \
        'Do NOT add, modify, or remove its `check` field' \
        'SAME capability or domain AND SAME underlying rule or anti-pattern' \
        'Run-first-round claim verification' \
        'Spec delta title-identity check' \
        'MUST NOT produce a signal'
        assert_contains "$path" "$literal" 'retained shared graded review branch'
    end

    set -l ledger_header (string join \t skill round round_type criticals warnings decision fixed_files)
    assert_contains "$path" "$ledger_header" 'seven-column loop ledger schema'

    assert_contains "$path" '# Cash Propose Review — Round <N>' 'cash review provenance'
    assert_contains "$path" '# Cash Apply Review — Round <N>' 'cash review provenance'
    assert_contains "$path" 'Reviewer roles are independent calls.' 'fresh reviewer isolation'
    assert_contains "$path" 'invoke a scoring sub-agent' 'mechanical review decision'
end

function shared_gate_hash --argument-names skill_path
    awk '
        /^   \*\*Entry conditions\*\*/ { copy = 1 }
        copy { print }
        /^   - \*\*Failure handling\*\*: If writing under `openspec\/signals\// { exit }
    ' "$skill_path" | shasum -a 256 | awk '{ print $1 }'
end

function assert_shared_gate_parity --argument-names variant_root
    set -l propose "$root_dir/$variant_root/skills/cash-propose/SKILL.md"
    set -l apply "$root_dir/$variant_root/skills/cash-apply/SKILL.md"
    set -l propose_hash (shared_gate_hash "$propose")
    set -l apply_hash (shared_gate_hash "$apply")
    test "$propose_hash" = "$apply_hash"; or fail "$variant_root/skills/cash-propose/SKILL.md and $variant_root/skills/cash-apply/SKILL.md shared review blocks differ"
end

function assert_signals_readme_contract
    set -l relative_path openspec/signals/README.md
    set -l path "$root_dir/$relative_path"

    assert_contains "$path" 'cash review loop' 'current signal writer ownership'
    assert_contains "$path" '— spectra-propose-plus round 1 —' 'historical signal occurrence preservation'
    assert_contains "$path" '`status`：`open` / `addressed` / `dismissed`' 'signal status schema'
    assert_contains "$path" '`check` 與 `status` 一樣由人維護' 'human-maintained signal fields'
    assert_contains "$path" 必須逐字節保留不動 'signal check preservation'

    if awk '!/— spectra-[a-z-]+-plus round [0-9]+ —/ { print }' "$path" | rg -Pqi '(?:spectra-(?:propose|apply)-plus|plus review loop)'
        fail "$relative_path contains active legacy plus writer prose outside a historical occurrence example"
    end
end

function assert_installer_interface
    set -l relative_path install-cash-skills.fish
    set -l path "$root_dir/$relative_path"
    test -f "$path"; or fail "missing $relative_path"
    fish -n "$path"; or fail "$relative_path is not valid Fish syntax"

    set -l help_output (fish "$path" --help | string collect)
    string match -q '*--target <project>*' "$help_output"; or fail "$relative_path help omits --target <project>"
    string match -q '*--register <project>*' "$help_output"; or fail "$relative_path help omits --register <project>"
    string match -q '*--unregister <project>*' "$help_output"; or fail "$relative_path help omits --unregister <project>"
    string match -q '*--list*' "$help_output"; or fail "$relative_path help omits --list"
    string match -q '*--all*' "$help_output"; or fail "$relative_path help omits --all"
    string match -q '*--dry-run*' "$help_output"; or fail "$relative_path help omits --dry-run"
    string match -q '*--force*' "$help_output"; or fail "$relative_path help omits --force"
    if string match -rq -- '--repair|launch-agent|fingerprint' "$help_output"
        fail "$relative_path exposes legacy repair automation"
    end
end

function assert_cleanup_interface
    set -l relative_path uninstall-spectra-plus-repair.fish
    set -l path "$root_dir/$relative_path"
    test -f "$path"; or fail "missing $relative_path"
    fish -n "$path"; or fail "$relative_path is not valid Fish syntax"

    set -l help_output (fish "$path" --help | string collect)
    string match -q '*--dry-run*' "$help_output"; or fail "$relative_path help omits --dry-run"
    for label in com.spectra.plus.repair com.agentflow.spectra-plus.repair
        assert_contains "$path" "$label" 'known legacy service cleanup'
    end
    assert_contains "$path" 'Library/Logs/spectra-plus-repair.log' 'diagnostic log preservation'
end

function assert_legacy_repair_runtime_absent
    for relative_path in install-spectra-plus.fish scripts/spectra-plus
        if test -e "$root_dir/$relative_path"
            fail "$relative_path keeps the legacy repair/generation runtime active"
        end
    end

    set -l installer "$root_dir/install-cash-skills.fish"
    if rg -Pqi -- '--register-target|--repair-all|--install-launch-agent|fingerprint|launchctl' "$installer"
        fail 'install-cash-skills.fish contains legacy repair, freshness, or scheduler behavior'
    end

    for variant_root in .agents .claude
        for skill in propose apply
            set -l relative_path "$variant_root/skills/spectra-$skill-plus/SKILL.md"
            if test -e "$root_dir/$relative_path"
                fail "$relative_path keeps a retired generated plus output"
            end
        end

        set -l commit_path "$root_dir/$variant_root/skills/spectra-commit/SKILL.md"
        if rg -Pqi 'SPECTRA-COMMIT-GUARD|generated plus|spectra-[a-z-]+-plus|plus deletion' "$commit_path"
            fail "$variant_root/skills/spectra-commit/SKILL.md retains the generated-plus deletion exception"
        end
    end
end

function assert_cash_guidance_contract
    for variant in 'AGENTS.md:$' 'CLAUDE.md:/'
        set -l fields (string split : -- "$variant")
        set -l relative_path "$fields[1]"
        set -l invocation_prefix "$fields[2]"
        set -l path "$root_dir/$relative_path"

        test (rg -Fx '<!-- CASH:START -->' "$path" | wc -l | string trim) = 1; or fail "$relative_path must contain exactly one Cash start marker"
        test (rg -Fx '<!-- CASH:END -->' "$path" | wc -l | string trim) = 1; or fail "$relative_path must contain exactly one Cash end marker"
        if rg -q '^<!-- SPECTRA:(?:START|END)' "$path"
            fail "$relative_path retains a Spectra managed marker"
        end

        for skill in discuss propose apply ingest archive commit
            assert_contains "$path" "$invocation_prefix""cash-$skill" 'Cash-only project guidance routing'
        end
        assert_contains "$path" 'Spectra CLI 與 `openspec/` artifact schema 仍具權威' 'Spectra artifact-engine authority'
        assert_contains "$path" '標準 `spectra-*` skills 是否存在不改變 Cash-only routing' 'routing and skill availability separation'
    end

    set -l agents_fallback (mktemp /tmp/cash-agents-fallback.XXXXXX)
    set -l claude_fallback (mktemp /tmp/cash-claude-fallback.XXXXXX)
    set -l expected_fallback (mktemp /tmp/cash-expected-fallback.XXXXXX)
    awk '/^## 向量模型未下載時的替代方式$/ { copy = 1 } copy { print } /^- 問程式碼或需求相關的問題/ { exit }' "$root_dir/AGENTS.md" >"$agents_fallback"
    awk '/^## 向量模型未下載時的替代方式$/ { copy = 1 } copy { print } /^- 問程式碼或需求相關的問題/ { exit }' "$root_dir/CLAUDE.md" >"$claude_fallback"
    printf '%s\n' \
        '## 向量模型未下載時的替代方式' \
        '' \
        'Spectra 的語意搜尋依賴本機向量模型。若模型尚未下載，不需要中斷或要求先下載，直接改用路徑與檔案讀取：' \
        '' \
        '- 使用者直接給 change 名稱 → 直接讀 `openspec/changes/<name>/` 底下的 artifacts（找不到時用 `spectra list --parked` 確認是否被 parked）' \
        '- 問程式碼或需求相關的問題 → 直接用 Grep／Read 搜尋 `openspec/specs/` 與程式碼來回答' >"$expected_fallback"
    command cmp -s "$agents_fallback" "$claude_fallback"; or fail 'AGENTS.md and CLAUDE.md fallback blocks differ'
    command cmp -s "$agents_fallback" "$expected_fallback"; or fail 'canonical Cash guidance does not preserve the required fallback block byte-for-byte'
    command rm -f -- "$agents_fallback" "$claude_fallback" "$expected_fallback"
end

function assert_cash_live_documentation
    if test -e "$root_dir/SPECTRA-PLUS.md"
        fail 'SPECTRA-PLUS.md remains as active legacy documentation'
    end
    set -l relative_path CASH-SKILLS.md
    set -l path "$root_dir/$relative_path"
    test -f "$path"; or fail "missing $relative_path"

    for literal in cash-analyze cash-apply cash-archive cash-ask cash-audit cash-commit cash-debug cash-discuss cash-drift cash-ingest cash-propose cash-verify '.agents/skills/' '.claude/skills/' './install-cash-skills.fish --target' 'cash-skills.version' '.cash-skills/receipt.tsv' '$HOME/.config/cash-skills/projects.txt' './install-cash-skills.fish --register' './install-cash-skills.fish --unregister' './install-cash-skills.fish --list' './install-cash-skills.fish --all' '--all --dry-run' '--all --force' 'updated' 'would-update' 'current' 'newer' 'conflict' 'failed' 'exit `2`' 'exit `1`' '沒有定期 repair' 'registry 本身不會觸發任何工作' './uninstall-spectra-plus-repair.fish --dry-run'
        assert_contains "$path" "$literal" 'cash live documentation'
    end
    assert_contains "$path" '先對 legacy registry 中每個專案安裝 cash skills' 'safe migration order'
    assert_contains "$path" '24 個 canonical `SKILL.md` 內容異動' 'bundle version bump ownership'
    assert_contains "$path" '舊 target 沒有 receipt' 'receipt-less migration'
    assert_contains "$path" '保留既有 24 個 skill bytes、收斂 `AGENTS.md` 與 `CLAUDE.md` guidance，並建立 receipt' 'receipt-less adoption behavior'
    assert_contains "$path" '不建立 target temporary files或持久狀態' 'dry-run target state boundary'
    assert_contains "$path" 'system temporary validation/render snapshots會在 exit 時清除' 'dry-run ephemeral snapshot boundary'
    assert_contains "$path" 'spectra-propose-plus' 'retired propose-plus cleanup documentation'
    assert_contains "$path" 'spectra-apply-plus' 'retired apply-plus cleanup documentation'
    assert_contains "$path" '只含一個 regular `SKILL.md`' 'retired plus safe-shape documentation'
    assert_contains "$path" '不使用 recursive deletion' 'retired plus non-recursive cleanup documentation'
    assert_contains "$path" '只清除 target 內的 retired plus skill' 'installer and scheduler cleanup responsibility split'
    for literal in \
        'AGENTS.md' \
        'CLAUDE.md' \
        '<!-- CASH:START -->' \
        '<!-- SPECTRA:START' \
        'managed spans 以外' \
        '標準 `spectra-*` skills' \
        'guidance 不會加入 `.cash-skills/receipt.tsv`' \
        '不需要調升 `cash-skills.version`' \
        '再次明確執行 installer' \
        '版本控制還原'
        assert_contains "$path" "$literal" 'Cash guidance ownership and migration documentation'
    end
    assert_absent "$path" '(?i)--repair-all|--register-target|--install-launch-agent|scripts/spectra-plus' 'retired repair instructions'
end

function normalized_variant_diff --argument-names skill output_path
    set -l agents_tmp (mktemp "/tmp/cash-$skill-agents.XXXXXX")
    set -l claude_tmp (mktemp "/tmp/cash-$skill-claude.XXXXXX")

    perl -pe 's/(?<![A-Za-z0-9_.-])\$cash-/\@cash-/g' "$root_dir/.agents/skills/cash-$skill/SKILL.md" >"$agents_tmp"
    perl -pe 's#(?<![A-Za-z0-9_.-])/cash-#\@cash-#g' "$root_dir/.claude/skills/cash-$skill/SKILL.md" >"$claude_tmp"
    command diff --label "codex/cash-$skill" --label "claude/cash-$skill" -U0 "$agents_tmp" "$claude_tmp" >"$output_path"
    set -l diff_status $status
    command rm -f -- "$agents_tmp" "$claude_tmp"
    test $diff_status -le 1; or fail "could not compare variant pair cash-$skill"
end

function assert_exhaustive_variant_parity
    set -l divergent_skills analyze ask audit drift ingest propose verify
    for skill in $cash_skills
        set -l actual_diff (mktemp "/tmp/cash-$skill-parity.XXXXXX")
        normalized_variant_diff "$skill" "$actual_diff"

        if contains "$skill" $divergent_skills
            set -l expected_path "$root_dir/scripts/cash-skills/variant-parity/cash-$skill.diff"
            test -f "$expected_path"; or fail "missing readable parity allowlist scripts/cash-skills/variant-parity/cash-$skill.diff"
            if not command cmp -s "$expected_path" "$actual_diff"
                command diff --label "expected/cash-$skill" --label "actual/cash-$skill" -u "$expected_path" "$actual_diff" >&2
                command rm -f -- "$actual_diff"
                fail ".agents/skills/cash-$skill/SKILL.md and .claude/skills/cash-$skill/SKILL.md differ outside scripts/cash-skills/variant-parity/cash-$skill.diff"
            end
        else if test -s "$actual_diff"
            command diff --label "expected/cash-$skill (identical)" --label "actual/cash-$skill" -u /dev/null "$actual_diff" >&2
            command rm -f -- "$actual_diff"
            fail ".agents/skills/cash-$skill/SKILL.md and .claude/skills/cash-$skill/SKILL.md must be identical after invocation normalization"
        end

        command rm -f -- "$actual_diff"
    end
end

function assert_contract_mutation_fixture
    set -l fixture (mktemp -d /tmp/cash-skill-suite.XXXXXX)
    string match -q '/tmp/cash-skill-suite.*' "$fixture"; or fail 'mktemp returned an unexpected fixture path'

    command mkdir -p "$fixture/.agents" "$fixture/.claude" "$fixture/scripts/cash-skills/tests" "$fixture/openspec/signals"; or fail 'could not create contract fixture directories'
    command cp -R "$root_dir/.agents/skills" "$fixture/.agents/"; or fail 'could not copy Codex cash fixture skills'
    command cp -R "$root_dir/.claude/skills" "$fixture/.claude/"; or fail 'could not copy Claude cash fixture skills'
    command cp "$root_dir/install-cash-skills.fish" "$root_dir/cash-skills.version" "$root_dir/uninstall-spectra-plus-repair.fish" "$root_dir/AGENTS.md" "$root_dir/CLAUDE.md" "$root_dir/CASH-SKILLS.md" "$fixture/"; or fail 'could not copy fixture root contracts'
    command cp "$test_script" "$fixture/scripts/cash-skills/tests/skill-checks.fish"; or fail 'could not copy fixture cash contract suite'
    command cp -R "$root_dir/scripts/cash-skills/variant-parity" "$fixture/scripts/cash-skills/"; or fail 'could not copy readable parity allowlists'
    command cp "$root_dir/openspec/signals/README.md" "$fixture/openspec/signals/README.md"; or fail 'could not copy signals fixture contract'

    set -l compliant_output "$fixture/compliant.out"
    env CASH_SKILLS_TEST_ROOT="$fixture" CASH_SKILLS_NESTED=1 fish "$test_script" >"$compliant_output" 2>&1
    or fail 'compliant isolated cash contract fixture did not return 0'

    set -l mutation_specs \
        (string join \t shared 'The first round of each loop run MUST be a full round.') \
        (string join \t shared 'the fourth round of the current run') \
        (string join \t shared 'exactly TWO fresh reviewer sub-agents in parallel') \
        (string join \t shared 'exactly ONE fresh sub-agent') \
        (string join \t shared 'cumulative blocking set') \
        (string join \t shared unresolved-prior) \
        (string join \t shared 'seeded re-run') \
        (string join \t shared 'accepted-risks.md') \
        (string join \t shared 'retry once with a fresh sub-agent invocation') \
        (string join \t shared 'two consecutive times in a single round') \
        (string join \t shared 'Review round action obligation') \
        (string join \t shared 'Abort triage') \
        (string join \t shared '<!-- LOOP-LEDGER-STEP -->') \
        (string join \t shared 'single command-string argument to `sh -c`') \
        (string join \t shared 'SAME capability or domain AND SAME underlying rule or anti-pattern') \
        (string join \t shared 'MUST NOT produce a signal') \
        (string join \t shared 'Do NOT add, modify, or remove its `check` field') \
        (string join \t shared 'Reviewer V — Verification') \
        (string join \t shared 'Run-first-round claim verification') \
        (string join \t propose 'spectra validate') \
        (string join \t propose 'Do NOT invoke `spectra park`') \
        (string join \t apply 'implementation-notes.md') \
        (string join \t apply '<!-- BLOCKER-TRIAGE -->') \
        (string join \t apply '然後繼續該 task，不暫停') \
        (string join \t apply '暫停、報告 blocker') \
        (string join \t apply needs-design) \
        (string join \t apply cash-archive) \
        (string join \t commit '.spectra/touched/<change-name>.json') \
        (string join \t commit 'git status --porcelain')

    set -l mutation_index 0
    for mutation_spec in $mutation_specs
        set mutation_index (math $mutation_index + 1)
        set -l fields (string split \t -- "$mutation_spec")
        set -l contract_group "$fields[1]"
        set -l literal "$fields[2]"
        set -l mutation_targets
        switch "$contract_group"
            case shared
                set mutation_targets \
                    .agents/skills/cash-propose/SKILL.md \
                    .agents/skills/cash-apply/SKILL.md \
                    .claude/skills/cash-propose/SKILL.md \
                    .claude/skills/cash-apply/SKILL.md
            case propose apply commit
                set mutation_targets \
                    ".agents/skills/cash-$contract_group/SKILL.md" \
                    ".claude/skills/cash-$contract_group/SKILL.md"
            case '*'
                fail "unknown mutation contract group: $contract_group"
        end

        for relative_path in $mutation_targets
            command cp "$root_dir/$relative_path" "$fixture/$relative_path"; or fail "could not reset mutation fixture $relative_path"
            env CASH_MUTATION_LITERAL="$literal" perl -0pi -e 'BEGIN { $needle = $ENV{"CASH_MUTATION_LITERAL"} } $count = s/\Q$needle\E/CASH_MUTATED_CONTRACT/g; die "literal not found\n" unless $count' "$fixture/$relative_path"
            or fail "could not seed governed mutation $mutation_index in $relative_path"
        end

        set -l mutation_output "$fixture/mutation-$mutation_index.out"
        if env CASH_SKILLS_TEST_ROOT="$fixture" CASH_SKILLS_NESTED=1 fish "$test_script" >"$mutation_output" 2>&1
            fail "governed mutation $mutation_index unexpectedly returned 0 for $mutation_targets[1]"
        end
        rg -Fq "$mutation_targets[1]" "$mutation_output"; or fail "governed mutation $mutation_index diagnostic omitted $mutation_targets[1]"
        for relative_path in $mutation_targets
            command cp "$root_dir/$relative_path" "$fixture/$relative_path"; or fail "could not restore mutation fixture $relative_path"
        end
    end

    command rm -rf -- "$fixture"
end

function tree_digest --argument-names directory
    set -l entries (command find "$directory" -mindepth 1 -print | command sort)
    set -l find_pipeline $pipestatus
    test $find_pipeline[1] -eq 0; and test $find_pipeline[2] -eq 0; or return 1

    set -l records
    for path in $entries
        set -l relative_path (string replace -- "$directory/" '' "$path")
        set -l mode (command stat -f '%Lp' "$path" 2>/dev/null); or return 1
        if test -L "$path"
            set -l link_target (command readlink "$path" 2>/dev/null); or return 1
            set -a records (string join \t link "$mode" "$relative_path" "$link_target")
        else if test -d "$path"
            set -a records (string join \t directory "$mode" "$relative_path")
        else if test -f "$path"
            set -l digest (command shasum -a 256 "$path" | command awk '{ print $1 }')
            set -l digest_pipeline $pipestatus
            test $digest_pipeline[1] -eq 0; and test $digest_pipeline[2] -eq 0; or return 1
            set -a records (string join \t file "$mode" "$relative_path" "$digest")
        else
            set -l file_type (command stat -f '%HT' "$path" 2>/dev/null); or return 1
            set -a records (string join \t special "$mode" "$relative_path" "$file_type")
        end
    end

    set -l digest (printf '%s\n' $records | command shasum -a 256 | command awk '{ print $1 }')
    set -l digest_pipeline $pipestatus
    test $digest_pipeline[1] -eq 0; and test $digest_pipeline[2] -eq 0; and test $digest_pipeline[3] -eq 0; or return 1
    echo "$digest"
end

function standard_spectra_inventory_digest --argument-names project_root
    set -l records
    for variant_root in .agents .claude
        set -l skills_root "$project_root/$variant_root/skills"
        test -d "$skills_root"; or continue
        set -l skill_dirs (command find "$skills_root" -mindepth 1 -maxdepth 1 -type d -name 'spectra-*' ! -name 'spectra-propose-plus' ! -name 'spectra-apply-plus' -print | command sort)
        set -l find_pipeline $pipestatus
        test $find_pipeline[1] -eq 0; and test $find_pipeline[2] -eq 0; or return 1
        for skill_dir in $skill_dirs
            set -l relative_path (string replace -- "$project_root/" '' "$skill_dir")
            set -l digest (tree_digest "$skill_dir"); or return 1
            set -a records (string join \t "$relative_path" "$digest")
        end
    end
    test (count $records) -gt 0; or return 1
    printf '%s\n' $records | command shasum -a 256 | command awk '{ print $1 }'
    set -l digest_pipeline $pipestatus
    test $digest_pipeline[1] -eq 0; and test $digest_pipeline[2] -eq 0; and test $digest_pipeline[3] -eq 0
end

function assert_tree_digest_mutation_oracle
    set -l fixture (mktemp -d /tmp/cash-tree-digest-suite.XXXXXX)
    string match -q '/tmp/cash-tree-digest-suite.*' "$fixture"; or fail 'mktemp returned an unexpected tree digest fixture path'

    set -l initial_digest (tree_digest "$fixture"); or fail 'tree digest could not hash an empty fixture'
    command mkdir "$fixture/empty-directory"; or fail 'could not seed empty-directory digest mutation'
    test (tree_digest "$fixture") != "$initial_digest"; or fail 'tree digest ignored an empty-directory mutation'

    set -l directory_digest (tree_digest "$fixture"); or fail 'tree digest could not hash the directory fixture'
    command ln -s empty-directory "$fixture/directory-link"; or fail 'could not seed symlink digest mutation'
    test (tree_digest "$fixture") != "$directory_digest"; or fail 'tree digest ignored a symlink mutation'

    command rm -rf -- "$fixture"
end

function copy_cash_source_fixture --argument-names destination
    command mkdir -p "$destination/.agents" "$destination/.claude"; or fail 'could not create versioned installer source fixture'
    command cp -R "$root_dir/.agents/skills" "$destination/.agents/"; or fail 'could not copy Codex cash source fixture'
    command cp -R "$root_dir/.claude/skills" "$destination/.claude/"; or fail 'could not copy Claude cash source fixture'
    command cp "$root_dir/install-cash-skills.fish" "$root_dir/AGENTS.md" "$root_dir/CLAUDE.md" "$destination/"; or fail 'could not copy installer source fixture'
    printf '1.0.0\n' >"$destination/cash-skills.version"; or fail 'could not write bundle version fixture'
end

function write_guidance_outside_snapshot --argument-names source output
    if not test -e "$source"
        printf '' >"$output"
        return
    end

    command perl -0e '
        use strict;
        use warnings;
        local $/;
        my $data = <>;
        $data =~ s/(?ms)^<!-- CASH:START -->\n.*?^<!-- CASH:END -->(?:\n|\z)//g;
        $data =~ s/(?ms)^<!-- SPECTRA:START(?: v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))? -->\n.*?^<!-- SPECTRA:END -->(?:\n|\z)//g;
        print $data;
    ' "$source" >"$output"; or fail "could not snapshot managed-span outside bytes: $source"
end

function assert_guidance_marker_state_matrix
    set -l fixture (mktemp -d /tmp/cash-guidance-suite.XXXXXX)
    string match -q '/tmp/cash-guidance-suite.*' "$fixture"; or fail 'mktemp returned an unexpected guidance fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l installer "$source/install-cash-skills.fish"

    for state in missing plain spectra cash both
        set -l target "$fixture/$state"
        command mkdir -p "$target"; or fail "could not create guidance $state target"
        switch "$state"
            case plain
                printf 'custom-before\ncustom-after' >"$target/AGENTS.md"
                printf 'claude-custom' >"$target/CLAUDE.md"
            case spectra
                printf '%s\n' 'custom-before' '<!-- SPECTRA:START v1.0.2 -->' 'legacy spectra' '<!-- SPECTRA:END -->' 'custom-after' >"$target/AGENTS.md"
                printf '%s\n' '<!-- SPECTRA:START -->' 'legacy spectra' '<!-- SPECTRA:END -->' >"$target/CLAUDE.md"
            case cash
                printf '%s\n' 'custom-before' '<!-- CASH:START -->' 'stale cash' '<!-- CASH:END -->' 'custom-after' >"$target/AGENTS.md"
                printf '%s\n' '<!-- CASH:START -->' 'stale cash' '<!-- CASH:END -->' >"$target/CLAUDE.md"
            case both
                printf '%s\n' 'custom-before' '<!-- SPECTRA:START -->' 'legacy spectra' '<!-- SPECTRA:END -->' 'between' '<!-- CASH:START -->' 'stale cash' '<!-- CASH:END -->' 'custom-after' >"$target/AGENTS.md"
                printf '%s\n' '<!-- CASH:START -->' 'stale cash' '<!-- CASH:END -->' '<!-- SPECTRA:START v2.3.4 -->' 'legacy spectra' '<!-- SPECTRA:END -->' >"$target/CLAUDE.md"
        end

        set -l agents_outside "$fixture/$state-agents-outside"
        set -l claude_outside "$fixture/$state-claude-outside"
        write_guidance_outside_snapshot "$target/AGENTS.md" "$agents_outside"
        write_guidance_outside_snapshot "$target/CLAUDE.md" "$claude_outside"
        if test "$state" = plain
            printf '\n' >>"$agents_outside"
            printf '\n' >>"$claude_outside"
        end

        fish "$installer" --target "$target" >"$fixture/$state.out" 2>"$fixture/$state.err"; or fail "installer rejected legal guidance state: $state"
        rg -Fq 'Result: update' "$fixture/$state.out"; or fail "guidance $state state did not report update"
        for guidance in AGENTS.md CLAUDE.md
            test (rg -Fx '<!-- CASH:START -->' "$target/$guidance" | wc -l | string trim) = 1; or fail "$state $guidance does not contain exactly one Cash block"
            if rg -q '^<!-- SPECTRA:(?:START|END)' "$target/$guidance"
                fail "$state $guidance retained a Spectra marker"
            end
        end
        assert_contains "$target/CLAUDE.md" '/cash-propose' 'installed Claude guidance invocation variant'
        assert_absent "$target/CLAUDE.md" '(?<![[:alnum:]_.-])\$cash-' 'installed Claude guidance invocation variant'
        write_guidance_outside_snapshot "$target/AGENTS.md" "$fixture/$state-agents-after"
        write_guidance_outside_snapshot "$target/CLAUDE.md" "$fixture/$state-claude-after"
        command cmp -s "$agents_outside" "$fixture/$state-agents-after"; or fail "$state AGENTS.md changed bytes outside managed spans"
        command cmp -s "$claude_outside" "$fixture/$state-claude-after"; or fail "$state CLAUDE.md changed bytes outside managed spans"
        if test "$state" != missing
            assert_contains "$target/AGENTS.md" custom 'guidance migration lost project-owned AGENTS.md bytes'
        end
    end

    set -l malformed "$fixture/malformed"
    command mkdir -p "$malformed"
    printf '%s\n' 'sentinel' '<!-- CASH:START -->' 'broken' >"$malformed/AGENTS.md"
    set -l malformed_before (tree_digest "$malformed")
    if fish "$installer" --target "$malformed" --force >"$fixture/malformed.out" 2>"$fixture/malformed.err"
        fail 'installer accepted malformed guidance markers with --force'
    end
    test (tree_digest "$malformed") = "$malformed_before"; or fail 'malformed guidance preflight changed target bytes'
    if rg -q '^Result:' "$fixture/malformed.out"
        fail 'malformed guidance failure emitted a domain result'
    end

    command cp "$source/AGENTS.md" "$fixture/source-agents-canonical"; or fail 'could not snapshot canonical source guidance'
    printf '%s\n' '<!-- CASH:START -->' 'orphan source marker' >>"$source/AGENTS.md"
    set -l source_malformed_target "$fixture/source-malformed-target"
    command mkdir -p "$source_malformed_target"
    set -l source_malformed_before (tree_digest "$source_malformed_target")
    fish "$installer" --target "$source_malformed_target" --force >"$fixture/source-malformed.out" 2>"$fixture/source-malformed.err"
    set -l source_malformed_status $status
    test $source_malformed_status -eq 1; or fail "malformed source guidance returned code $source_malformed_status instead of 1"
    test (tree_digest "$source_malformed_target") = "$source_malformed_before"; or fail 'malformed source guidance changed target bytes'
    if rg -q '^Result:' "$fixture/source-malformed.out"
        fail 'malformed source guidance failure emitted a domain result'
    end
    command cp "$fixture/source-agents-canonical" "$source/AGENTS.md"; or fail 'could not restore canonical source guidance'

    printf '%s\n' '<!-- SPECTRA:START v1.0.2 -->' 'external source guidance' '<!-- SPECTRA:END -->' >>"$source/AGENTS.md"
    set -l source_spectra_target "$fixture/source-spectra-target"
    command mkdir -p "$source_spectra_target"
    fish "$installer" --target "$source_spectra_target" >"$fixture/source-spectra.out" 2>"$fixture/source-spectra.err"; or fail 'legal source Spectra block prevented target installation'
    test (rg -Fx '<!-- CASH:START -->' "$source_spectra_target/AGENTS.md" | wc -l | string trim) = 1; or fail 'source Spectra fixture did not install canonical Cash guidance'
    if rg -q '^<!-- SPECTRA:(?:START|END)' "$source_spectra_target/AGENTS.md"
        fail 'source Spectra fixture leaked Spectra guidance into target'
    end

    command rm -rf -- "$fixture"
end

function assert_guidance_boundary_matrix
    set -l fixture (mktemp -d /tmp/cash-guidance-boundary-suite.XXXXXX)
    string match -q '/tmp/cash-guidance-boundary-suite.*' "$fixture"; or fail 'mktemp returned an unexpected guidance boundary fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l installer "$source/install-cash-skills.fish"

    set -l dry_target "$fixture/dry-target"
    command mkdir -p "$dry_target"
    set -l dry_before (tree_digest "$dry_target")
    set -l mktemp_bin (command -s mktemp)
    test -x "$mktemp_bin"; or fail 'could not locate the real mktemp executable'
    set -l mktemp_shim_dir "$fixture/mktemp-bin"
    set -l guidance_snapshot_record "$fixture/dry-guidance-snapshots"
    command mkdir -p "$mktemp_shim_dir"
    printf '%s\n' \
        '#!/bin/sh' \
        'path=$("$CASH_GUIDANCE_REAL_MKTEMP" "$@") || exit $?' \
        'case "$path" in' \
        '  /tmp/.cash-guidance-source.*|/tmp/.cash-guidance-rendered.*|/private/tmp/.cash-guidance-source.*|/private/tmp/.cash-guidance-rendered.*)' \
        '    printf "%s\n" "$path" >>"$CASH_GUIDANCE_MKTEMP_RECORD" || { rm -f -- "$path"; exit 1; }' \
        '    ;;' \
        'esac' \
        'printf "%s\n" "$path"' >"$mktemp_shim_dir/mktemp"
    command chmod +x "$mktemp_shim_dir/mktemp"
    env \
        PATH="$mktemp_shim_dir:$PATH" \
        CASH_GUIDANCE_REAL_MKTEMP="$mktemp_bin" \
        CASH_GUIDANCE_MKTEMP_RECORD="$guidance_snapshot_record" \
        fish --no-config "$installer" --target "$dry_target" --dry-run >"$fixture/dry.out" 2>"$fixture/dry.err"
    or fail 'guidance dry-run failed'
    test (tree_digest "$dry_target") = "$dry_before"; or fail 'guidance dry-run created target state'
    test -f "$guidance_snapshot_record"; or fail 'guidance dry-run did not record system temporary snapshots'
    set -l guidance_snapshot_paths (string split \n -- (string collect <"$guidance_snapshot_record"))
    test (count $guidance_snapshot_paths) -eq 4; or fail 'guidance dry-run did not create exactly four system temporary snapshots'
    for snapshot_path in $guidance_snapshot_paths
        string match -rq '^/(?:private/)?tmp/\.cash-guidance-(?:source|rendered)\.[A-Za-z0-9]+$' -- "$snapshot_path"; or fail "guidance dry-run created an unexpected snapshot path: $snapshot_path"
        test ! -e "$snapshot_path"; or fail "guidance dry-run left a system temporary snapshot after process exit: $snapshot_path"
    end
    rg -Fq 'guidance install: AGENTS.md' "$fixture/dry.out"; or fail 'guidance dry-run omitted AGENTS.md plan'

    set -l symlink_target "$fixture/symlink-target"
    command mkdir -p "$symlink_target"
    printf 'outside-guidance\n' >"$fixture/outside-guidance"
    command ln -s "$fixture/outside-guidance" "$symlink_target/AGENTS.md"
    set -l outside_before (shasum -a 256 "$fixture/outside-guidance" | awk '{ print $1 }')
    if fish "$installer" --target "$symlink_target" --force >"$fixture/symlink.out" 2>"$fixture/symlink.err"
        fail 'installer accepted a symlinked guidance target with --force'
    end
    test (shasum -a 256 "$fixture/outside-guidance" | awk '{ print $1 }') = "$outside_before"; or fail 'installer wrote through a guidance symlink'

    set -l source_link_target "$fixture/source-link-target"
    command mkdir -p "$source_link_target"
    command mv "$source/AGENTS.md" "$source/AGENTS.real"
    command ln -s AGENTS.real "$source/AGENTS.md"
    set -l source_link_before (tree_digest "$source_link_target")
    if fish "$installer" --target "$source_link_target" >"$fixture/source-link.out" 2>"$fixture/source-link.err"
        fail 'installer accepted a symlinked source guidance file'
    end
    test (tree_digest "$source_link_target") = "$source_link_before"; or fail 'source guidance failure changed target bytes'
    command rm "$source/AGENTS.md"
    command mv "$source/AGENTS.real" "$source/AGENTS.md"

    set -l malformed_cases duplicate cash-one-spectra-two nested inline reversed orphan-end unknown-version
    for malformed_case in $malformed_cases
        set -l target "$fixture/malformed-$malformed_case"
        command mkdir -p "$target"
        switch "$malformed_case"
            case duplicate
                printf '%s\n' '<!-- CASH:START -->' one '<!-- CASH:END -->' '<!-- CASH:START -->' two '<!-- CASH:END -->' >"$target/AGENTS.md"
            case cash-one-spectra-two
                printf '%s\n' '<!-- CASH:START -->' cash '<!-- CASH:END -->' '<!-- SPECTRA:START -->' spectra-one '<!-- SPECTRA:END -->' '<!-- SPECTRA:START v1.2.3 -->' spectra-two '<!-- SPECTRA:END -->' >"$target/AGENTS.md"
            case nested
                printf '%s\n' '<!-- CASH:START -->' '<!-- SPECTRA:START -->' nested '<!-- SPECTRA:END -->' '<!-- CASH:END -->' >"$target/AGENTS.md"
            case inline
                printf '%s\n' 'prefix <!-- CASH:START -->' body '<!-- CASH:END -->' >"$target/AGENTS.md"
            case reversed
                printf '%s\n' '<!-- CASH:END -->' body '<!-- CASH:START -->' >"$target/AGENTS.md"
            case orphan-end
                printf '%s\n' body '<!-- SPECTRA:END -->' >"$target/AGENTS.md"
            case unknown-version
                printf '%s\n' '<!-- SPECTRA:START v1.2 -->' body '<!-- SPECTRA:END -->' >"$target/AGENTS.md"
        end
        set -l before (tree_digest "$target")
        if fish "$installer" --target "$target" --force >"$fixture/$malformed_case.out" 2>"$fixture/$malformed_case.err"
            fail "installer accepted malformed guidance state: $malformed_case"
        end
        test (tree_digest "$target") = "$before"; or fail "malformed guidance state changed target: $malformed_case"
    end

    set -l mode_target "$fixture/mode-target"
    command mkdir -p "$mode_target"
    printf 'agents-custom\n' >"$mode_target/AGENTS.md"
    printf 'claude-custom\n' >"$mode_target/CLAUDE.md"
    command chmod 0600 "$mode_target/AGENTS.md"
    command chmod 0640 "$mode_target/CLAUDE.md"
    fish "$installer" --target "$mode_target" >"$fixture/mode.out" 2>"$fixture/mode.err"; or fail 'guidance mode-preservation install failed'
    test (stat -f '%Lp' "$mode_target/AGENTS.md") = 600; or fail 'AGENTS.md mode was not preserved'
    test (stat -f '%Lp' "$mode_target/CLAUDE.md") = 640; or fail 'CLAUDE.md mode was not preserved'

    set -l new_mode_target "$fixture/new-mode-target"
    command mkdir -p "$new_mode_target"
    fish "$installer" --target "$new_mode_target" >"$fixture/new-mode.out" 2>"$fixture/new-mode.err"; or fail 'new guidance mode install failed'
    test (stat -f '%Lp' "$new_mode_target/AGENTS.md") = 644; or fail 'new AGENTS.md mode was not 0644'
    test (stat -f '%Lp' "$new_mode_target/CLAUDE.md") = 644; or fail 'new CLAUDE.md mode was not 0644'

    set -l source_permission_target "$fixture/source-permission-target"
    command mkdir -p "$source_permission_target"
    command chmod 000 "$source/AGENTS.md"
    if fish "$installer" --target "$source_permission_target" >"$fixture/source-permission.out" 2>"$fixture/source-permission.err"
        fail 'installer accepted unreadable source guidance'
    end
    test (tree_digest "$source_permission_target") = (tree_digest "$fixture/dry-target"); or fail 'source permission failure wrote target state'
    command chmod 0644 "$source/AGENTS.md"

    set -l target_permission_target "$fixture/target-permission-target"
    command mkdir -p "$target_permission_target"
    printf 'permission-sentinel\n' >"$target_permission_target/AGENTS.md"
    command chmod 0400 "$target_permission_target/AGENTS.md"
    set -l target_permission_before (tree_digest "$target_permission_target")
    if fish "$installer" --target "$target_permission_target" >"$fixture/target-permission.out" 2>"$fixture/target-permission.err"
        fail 'installer accepted unwritable target guidance'
    end
    test (tree_digest "$target_permission_target") = "$target_permission_before"; or fail 'target permission failure wrote target state'
    command chmod 0644 "$target_permission_target/AGENTS.md"

    set -l hook "$fixture/guidance-race-hook"
    printf '%s\n' \
        '#!/bin/sh' \
        'stage=$1' \
        'parent=$2' \
        'basename=$3' \
        'temporary=$4' \
        '[ "$stage" = "$CASH_GUIDANCE_SWAP_STAGE" ] || exit 0' \
        '[ "$basename" = AGENTS.md ] || exit 0' \
        'case "$CASH_GUIDANCE_SWAP_KIND" in' \
        '  parent)' \
        '    mv "$parent" "$CASH_GUIDANCE_ORIGINAL_PARENT" || exit 81' \
        '    mkdir "$parent" || exit 82' \
        '    printf "%s\n" "replacement-parent-sentinel" >"$parent/AGENTS.md" || exit 83' \
        '    ;;' \
        '  inode)' \
        '    printf "%s\n" "destination-inode-sentinel" >"$parent/.replacement-guidance" || exit 84' \
        '    mv -f "$parent/.replacement-guidance" "$parent/$basename" || exit 85' \
        '    ;;' \
        '  symlink)' \
        '    rm -f "$parent/$basename" || exit 86' \
        '    ln -s "$CASH_GUIDANCE_OUTSIDE" "$parent/$basename" || exit 87' \
        '    ;;' \
        '  content)' \
        '    printf "%s\n" "post-preflight-edit" >"$parent/$basename" || exit 88' \
        '    ;;' \
        '  collision)' \
        '    printf "%s\n" "preexisting-temporary-sentinel" >"$parent/$temporary" || exit 89' \
        '    printf "%s\n" "$parent/$temporary" >"$CASH_GUIDANCE_TEMP_RECORD" || exit 90' \
        '    ;;' \
        '  capability-failure)' \
        '    exit 91' \
        '    ;;' \
        '  cleanup-failure)' \
        '    chmod 0500 "$parent" || exit 92' \
        '    exit 93' \
        '    ;;' \
        'esac' >"$hook"
    command chmod +x "$hook"

    for race_spec in before-temp:parent before-temp:inode before-rename:parent before-rename:symlink after-verify-before-rename:parent
        set -l race_fields (string split : -- "$race_spec")
        set -l race_stage "$race_fields[1]"
        set -l race_kind "$race_fields[2]"
        set -l race_target "$fixture/race-$race_stage-$race_kind"
        command mkdir -p "$race_target"
        fish "$installer" --target "$race_target" >/dev/null 2>&1; or fail "could not seed guidance race target: $race_spec"
        printf '%s\n' '<!-- SPECTRA:START -->' race-drift '<!-- SPECTRA:END -->' >>"$race_target/AGENTS.md"
        set -l race_receipt_before (shasum -a 256 "$race_target/.cash-skills/receipt.tsv" | awk '{ print $1 }')
        set -l race_claude_before (shasum -a 256 "$race_target/CLAUDE.md" | awk '{ print $1 }')
        set -l race_outside "$fixture/race-$race_stage-$race_kind-outside"
        printf 'outside-race-sentinel\n' >"$race_outside"
        set -l replacement_parent_expected "$fixture/replacement-parent-expected"
        printf 'replacement-parent-sentinel\n' >"$replacement_parent_expected"
        set -l replacement_inode_expected "$fixture/replacement-inode-expected"
        printf 'destination-inode-sentinel\n' >"$replacement_inode_expected"
        set -l race_original_parent "$race_target.original"
        if env \
            CASH_GUIDANCE_TEST_HOOK="$hook" \
            CASH_GUIDANCE_SWAP_STAGE="$race_stage" \
            CASH_GUIDANCE_SWAP_KIND="$race_kind" \
            CASH_GUIDANCE_ORIGINAL_PARENT="$race_original_parent" \
            CASH_GUIDANCE_OUTSIDE="$race_outside" \
            fish --no-config "$installer" --target "$race_target" >"$fixture/race-$race_stage-$race_kind.out" 2>"$fixture/race-$race_stage-$race_kind.err"
            fail "installer accepted guidance race injection: $race_spec"
        end
        if test "$race_kind" = parent
            command cmp -s "$replacement_parent_expected" "$race_target/AGENTS.md"; or fail "parent race modified replacement sentinel bytes: $race_spec"
            test (find "$race_original_parent" -maxdepth 1 -name '.cash-guidance.*' | wc -l | string trim) = 0; or fail "parent race left an anchored temporary file: $race_spec"
            test (shasum -a 256 "$race_original_parent/.cash-skills/receipt.tsv" | awk '{ print $1 }') = "$race_receipt_before"; or fail "parent race replaced the receipt: $race_spec"
            test (shasum -a 256 "$race_original_parent/CLAUDE.md" | awk '{ print $1 }') = "$race_claude_before"; or fail "parent race published later guidance: $race_spec"
        else
            test (shasum -a 256 "$race_target/.cash-skills/receipt.tsv" | awk '{ print $1 }') = "$race_receipt_before"; or fail "destination race replaced the receipt: $race_spec"
            test (shasum -a 256 "$race_target/CLAUDE.md" | awk '{ print $1 }') = "$race_claude_before"; or fail "destination race published later guidance: $race_spec"
            if test "$race_kind" = inode
                command cmp -s "$replacement_inode_expected" "$race_target/AGENTS.md"; or fail "destination inode race modified replacement bytes: $race_spec"
            else
                test -L "$race_target/AGENTS.md"; or fail "destination symlink race replaced the injected symlink: $race_spec"
                test (readlink "$race_target/AGENTS.md") = "$race_outside"; or fail "destination symlink race changed the injected link target: $race_spec"
            end
        end
        printf 'outside-race-sentinel\n' | command cmp -s - "$race_outside"; or fail "guidance race modified outside sentinel bytes: $race_spec"
        if rg -q '^Result:' "$fixture/race-$race_stage-$race_kind.out"
            fail "guidance race emitted a domain result: $race_spec"
        end
    end

    set -l capability_target "$fixture/capability-target"
    command mkdir -p "$capability_target"
    set -l capability_before (tree_digest "$capability_target")
    if env \
        CASH_GUIDANCE_TEST_HOOK="$hook" \
        CASH_GUIDANCE_SWAP_STAGE=capability-preflight \
        CASH_GUIDANCE_SWAP_KIND=capability-failure \
        fish --no-config "$installer" --target "$capability_target" >"$fixture/capability.out" 2>"$fixture/capability.err"
        fail 'installer mutated target before guidance publisher capability validation'
    end
    test (tree_digest "$capability_target") = "$capability_before"; or fail 'guidance capability failure wrote target state'
    if rg -q '^Result:' "$fixture/capability.out"
        fail 'guidance capability failure emitted a domain result'
    end

    set -l collision_target "$fixture/collision-target"
    command mkdir -p "$collision_target"
    fish "$installer" --target "$collision_target" >/dev/null 2>&1; or fail 'could not seed guidance temporary collision target'
    printf '%s\n' '<!-- SPECTRA:START -->' collision-drift '<!-- SPECTRA:END -->' >>"$collision_target/AGENTS.md"
    set -l collision_record "$fixture/collision-record"
    if env \
        CASH_GUIDANCE_TEST_HOOK="$hook" \
        CASH_GUIDANCE_SWAP_STAGE=before-temp-create \
        CASH_GUIDANCE_SWAP_KIND=collision \
        CASH_GUIDANCE_TEMP_RECORD="$collision_record" \
        fish --no-config "$installer" --target "$collision_target" >"$fixture/collision.out" 2>"$fixture/collision.err"
        fail 'installer accepted a guidance temporary create collision'
    end
    test -f "$collision_record"; or fail 'guidance temporary collision hook did not run'
    set -l collision_path (string trim <"$collision_record")
    printf 'preexisting-temporary-sentinel\n' | command cmp -s - "$collision_path"; or fail 'guidance create failure deleted or changed a preexisting same-name entry'

    set -l cleanup_target "$fixture/cleanup-failure-target"
    command mkdir -p "$cleanup_target"
    fish "$installer" --target "$cleanup_target" >/dev/null 2>&1; or fail 'could not seed guidance cleanup failure target'
    printf '%s\n' '<!-- SPECTRA:START -->' cleanup-drift '<!-- SPECTRA:END -->' >>"$cleanup_target/AGENTS.md"
    if env \
        CASH_GUIDANCE_TEST_HOOK="$hook" \
        CASH_GUIDANCE_SWAP_STAGE=before-rename \
        CASH_GUIDANCE_SWAP_KIND=cleanup-failure \
        fish --no-config "$installer" --target "$cleanup_target" >"$fixture/cleanup-failure.out" 2>"$fixture/cleanup-failure.err"
        fail 'installer accepted a guidance cleanup failure'
    end
    command chmod 0755 "$cleanup_target"
    rg -q 'cannot clean temporary guidance \.cash-guidance\.[0-9a-f]{32}:' "$fixture/cleanup-failure.err"; or fail 'guidance cleanup failure omitted the relative basename or cause'

    set -l hardlink_target "$fixture/hardlink-target"
    command mkdir -p "$hardlink_target"
    printf 'hardlink-sentinel\n' >"$fixture/hardlink-outside"
    command ln "$fixture/hardlink-outside" "$hardlink_target/AGENTS.md"
    set -l hardlink_before (shasum -a 256 "$fixture/hardlink-outside" | awk '{ print $1 }')
    fish "$installer" --target "$hardlink_target" >"$fixture/hardlink.out" 2>"$fixture/hardlink.err"; or fail 'guidance hard-link install failed'
    test (shasum -a 256 "$fixture/hardlink-outside" | awk '{ print $1 }') = "$hardlink_before"; or fail 'guidance atomic replace modified an external hard-link inode'
    assert_contains "$hardlink_target/AGENTS.md" '<!-- CASH:START -->' 'guidance hard-link target publication'

    set -l snapshot_target "$fixture/snapshot-target"
    command mkdir -p "$snapshot_target"
    fish "$installer" --target "$snapshot_target" >/dev/null 2>&1; or fail 'could not seed guidance snapshot target'
    printf '%s\n' '<!-- SPECTRA:START -->' external-update '<!-- SPECTRA:END -->' >>"$snapshot_target/AGENTS.md"
    set -l receipt_before (shasum -a 256 "$snapshot_target/.cash-skills/receipt.tsv" | awk '{ print $1 }')
    set -l claude_before (shasum -a 256 "$snapshot_target/CLAUDE.md" | awk '{ print $1 }')
    if env \
        CASH_GUIDANCE_TEST_HOOK="$hook" \
        CASH_GUIDANCE_SWAP_STAGE=before-temp \
        CASH_GUIDANCE_SWAP_KIND=content \
        fish --no-config "$installer" --target "$snapshot_target" >"$fixture/snapshot.out" 2>"$fixture/snapshot.err"
        fail 'installer overwrote a post-preflight guidance edit'
    end
    test (string trim <"$snapshot_target/AGENTS.md") = post-preflight-edit; or fail 'installer did not preserve the post-preflight guidance edit'
    test (shasum -a 256 "$snapshot_target/.cash-skills/receipt.tsv" | awk '{ print $1 }') = "$receipt_before"; or fail 'post-preflight guidance failure replaced the receipt'
    test (shasum -a 256 "$snapshot_target/CLAUDE.md" | awk '{ print $1 }') = "$claude_before"; or fail 'post-preflight guidance failure published a later guidance file'
    if rg -q '^Result:' "$fixture/snapshot.out"
        fail 'post-preflight guidance failure emitted a domain result'
    end

    command rm -rf -- "$fixture"
end

function assert_guidance_snapshot_binding
    set -l fixture (mktemp -d /tmp/cash-guidance-snapshot-suite.XXXXXX)
    string match -q '/tmp/cash-guidance-snapshot-suite.*' "$fixture"; or fail 'mktemp returned an unexpected guidance snapshot fixture path'
    set fixture (command realpath "$fixture"); or fail 'could not canonicalize guidance snapshot fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l target "$fixture/target"
    command mkdir -p "$target"
    printf 'project-owned-target\n' >"$target/AGENTS.md"
    command cp "$source/AGENTS.md" "$fixture/source-original"
    command cp "$target/AGENTS.md" "$fixture/target-original"

    set -l hook "$fixture/snapshot-hook"
    printf '%s\n' \
        '#!/bin/sh' \
        'stage=$1' \
        'path=$2' \
        'case "$stage" in' \
        '  after-source-snapshot)' \
        '    printf "%s|%s\n" "$stage" "$path" >>"$CASH_GUIDANCE_SNAPSHOT_RECORD" || exit 82' \
        '    [ "$path" = "$CASH_GUIDANCE_SNAPSHOT_SOURCE" ] || exit 0' \
        '    printf "%s\n" "<!-- CASH:START -->" transient-source "<!-- CASH:END -->" >"$path" || exit 81' \
        '    ;;' \
        '  after-source-render)' \
        '    printf "%s|%s\n" "$stage" "$path" >>"$CASH_GUIDANCE_SNAPSHOT_RECORD" || exit 84' \
        '    [ "$path" = "$CASH_GUIDANCE_SNAPSHOT_SOURCE" ] || exit 0' \
        '    cp "$CASH_GUIDANCE_SNAPSHOT_SOURCE_ORIGINAL" "$path" || exit 83' \
        '    ;;' \
        '  after-target-snapshot)' \
        '    printf "%s|%s\n" "$stage" "$path" >>"$CASH_GUIDANCE_SNAPSHOT_RECORD" || exit 86' \
        '    [ "$path" = "$CASH_GUIDANCE_SNAPSHOT_TARGET" ] || exit 0' \
        '    printf "%s\n" transient-target >"$path" || exit 85' \
        '    ;;' \
        '  after-target-render)' \
        '    printf "%s|%s\n" "$stage" "$path" >>"$CASH_GUIDANCE_SNAPSHOT_RECORD" || exit 88' \
        '    [ "$path" = "$CASH_GUIDANCE_SNAPSHOT_TARGET" ] || exit 0' \
        '    cp "$CASH_GUIDANCE_SNAPSHOT_TARGET_ORIGINAL" "$path" || exit 87' \
        '    ;;' \
        'esac' >"$hook"
    command chmod +x "$hook"

    set -l record "$fixture/snapshot-record"
    env \
        CASH_GUIDANCE_TEST_HOOK="$hook" \
        CASH_GUIDANCE_SNAPSHOT_SOURCE="$source/AGENTS.md" \
        CASH_GUIDANCE_SNAPSHOT_SOURCE_ORIGINAL="$fixture/source-original" \
        CASH_GUIDANCE_SNAPSHOT_TARGET="$target/AGENTS.md" \
        CASH_GUIDANCE_SNAPSHOT_TARGET_ORIGINAL="$fixture/target-original" \
        CASH_GUIDANCE_SNAPSHOT_RECORD="$record" \
        fish --no-config "$source/install-cash-skills.fish" --target "$target" >"$fixture/install.out" 2>"$fixture/install.err"
    or fail 'immutable guidance snapshot fixture failed'

    for stage in after-source-snapshot after-source-render after-target-snapshot after-target-render
        set -l stage_count 0
        if test -f "$record"
            if string match -q 'after-source-*' "$stage"
                set stage_count (rg -Fxc "$stage|$source/AGENTS.md" "$record")
            else
                set stage_count (rg -Fxc "$stage|$target/AGENTS.md" "$record")
            end
        end
        test "$stage_count" = 1; or fail "guidance snapshot hook stage did not run exactly once for AGENTS.md: $stage"
    end
    assert_absent "$target/AGENTS.md" 'transient-source|transient-target' 'guidance snapshot transient bytes'
    assert_contains "$target/AGENTS.md" 'project-owned-target' 'guidance snapshot target bytes'
    assert_contains "$target/AGENTS.md" '本專案只使用 Cash workflow invocations' 'guidance snapshot canonical source bytes'

    command rm -rf -- "$fixture"
end

function assert_numeric_version_guidance_examples
    set -l fixture (mktemp -d /tmp/cash-version-guidance-example-suite.XXXXXX)
    string match -q '/tmp/cash-version-guidance-example-suite.*' "$fixture"; or fail 'mktemp returned an unexpected numeric version example fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l installer "$source/install-cash-skills.fish"
    set -l rows \
        '1.10.0|1.9.9|canonical|update' \
        '2.0.0|2.0.0|canonical|current' \
        '2.0.0|2.0.0|spectra|update' \
        '2.9.0|3.0.0|spectra|newer'

    set -l row_index 0
    for row in $rows
        set row_index (math $row_index + 1)
        set -l fields (string split '|' -- "$row")
        set -l source_version "$fields[1]"
        set -l target_version "$fields[2]"
        set -l guidance "$fields[3]"
        set -l expected "$fields[4]"
        set -l target "$fixture/row-$row_index"
        command mkdir -p "$target"
        printf '%s\n' "$target_version" >"$source/cash-skills.version"
        fish "$installer" --target "$target" >/dev/null 2>&1; or fail "could not seed numeric version example row $row_index"
        if test "$guidance" = spectra
            printf '%s\n' '<!-- SPECTRA:START -->' example-drift '<!-- SPECTRA:END -->' >>"$target/AGENTS.md"
        end
        printf '%s\n' "$source_version" >"$source/cash-skills.version"
        fish "$installer" --target "$target" >"$fixture/row-$row_index.out" 2>"$fixture/row-$row_index.err"; or fail "numeric version example row $row_index failed"
        assert_single_result "$fixture/row-$row_index.out" "$expected" "numeric version example row $row_index"
    end

    command rm -rf -- "$fixture"
end

function assert_guidance_transaction_matrix
    set -l fixture (mktemp -d /tmp/cash-guidance-transaction-suite.XXXXXX)
    string match -q '/tmp/cash-guidance-transaction-suite.*' "$fixture"; or fail 'mktemp returned an unexpected guidance transaction fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l installer "$source/install-cash-skills.fish"

    set -l current_target "$fixture/current-target"
    command mkdir -p "$current_target"
    fish "$installer" --target "$current_target" >/dev/null 2>&1; or fail 'could not seed current guidance target'
    test (wc -l <"$current_target/.cash-skills/receipt.tsv" | string trim) = 25; or fail 'guidance migration changed the 25-record receipt schema'
    if rg -q 'AGENTS\.md|CLAUDE\.md' "$current_target/.cash-skills/receipt.tsv"
        fail 'guidance paths were added to the skill receipt'
    end
    test (string trim <"$source/cash-skills.version") = 1.0.0; or fail 'guidance migration changed the fixture bundle version'
    set -l current_before (tree_digest "$current_target")
    fish "$installer" --target "$current_target" >"$fixture/current.out" 2>"$fixture/current.err"; or fail 'canonical guidance current branch failed'
    rg -Fq 'Result: current' "$fixture/current.out"; or fail 'canonical guidance did not report current'
    test (tree_digest "$current_target") = "$current_before"; or fail 'canonical guidance current branch changed target bytes'

    for variant_root in .agents .claude
        for source_skill_dir in "$root_dir/$variant_root/skills"/spectra-*
            string match -rq '/spectra-(?:propose|apply)-plus$' -- "$source_skill_dir"; and continue
            command cp -R "$source_skill_dir" "$current_target/$variant_root/skills/"; or fail 'could not seed complete standard Spectra skill trees'
        end
    end
    set -l spectra_before (standard_spectra_inventory_digest "$current_target"); or fail 'could not hash complete standard Spectra skill trees before guidance migration'
    set -l guidance_with_sentinel (mktemp "$current_target/.guidance-sentinel.XXXXXX")
    printf 'project-owned-before\n' >"$guidance_with_sentinel"
    command cat "$current_target/AGENTS.md" >>"$guidance_with_sentinel"
    printf 'project-owned-after\n' >>"$guidance_with_sentinel"
    command mv "$guidance_with_sentinel" "$current_target/AGENTS.md"
    printf '%s\n' '<!-- SPECTRA:START -->' external-update '<!-- SPECTRA:END -->' >>"$current_target/AGENTS.md"
    assert_contains "$current_target/AGENTS.md" '$cash-propose' 'Cash block remains effective after an external Spectra update'
    fish "$installer" --target "$current_target" >"$fixture/update.out" 2>"$fixture/update.err"; or fail 'equal-version guidance migration failed'
    rg -Fq 'Result: update' "$fixture/update.out"; or fail 'equal-version guidance drift did not report update'
    test (rg -Fx 'project-owned-before' "$current_target/AGENTS.md" | wc -l | string trim) = 1; or fail 'guidance cleanup changed the leading project-owned sentinel'
    test (rg -Fx 'project-owned-after' "$current_target/AGENTS.md" | wc -l | string trim) = 1; or fail 'guidance cleanup changed the trailing project-owned sentinel'
    if rg -q '^<!-- SPECTRA:(?:START|END)' "$current_target/AGENTS.md"
        fail 'guidance cleanup retained the externally re-added Spectra block'
    end
    test (standard_spectra_inventory_digest "$current_target") = "$spectra_before"; or fail 'guidance migration modified complete standard Spectra skill trees'
    fish "$installer" --target "$current_target" >"$fixture/update-current.out" 2>"$fixture/update-current.err"; or fail 'post-migration current branch failed'
    rg -Fq 'Result: current' "$fixture/update-current.out"; or fail 'second equal-version guidance install did not report current'

    set -l newer_target "$fixture/newer-target"
    command cp -R "$current_target" "$newer_target"
    perl -0pi -e 's/^version\t[^\n]+/version\t9.0.0/' "$newer_target/.cash-skills/receipt.tsv"
    printf '%s\n' '<!-- SPECTRA:START -->' newer-drift '<!-- SPECTRA:END -->' >>"$newer_target/AGENTS.md"
    set -l newer_before (tree_digest "$newer_target")
    fish "$installer" --target "$newer_target" --force >"$fixture/newer.out" 2>"$fixture/newer.err"; or fail 'newer guidance branch failed'
    rg -Fq 'Result: newer' "$fixture/newer.out"; or fail 'newer guidance branch did not report newer'
    test (tree_digest "$newer_target") = "$newer_before"; or fail 'newer branch changed guidance bytes'

    set -l conflict_target "$fixture/conflict-target"
    command cp -R "$current_target" "$conflict_target"
    printf 'skill-drift\n' >"$conflict_target/.agents/skills/cash-ask/SKILL.md"
    printf '%s\n' '<!-- SPECTRA:START -->' conflict-drift '<!-- SPECTRA:END -->' >>"$conflict_target/AGENTS.md"
    set -l conflict_before (tree_digest "$conflict_target")
    fish "$installer" --target "$conflict_target" >"$fixture/conflict.out" 2>"$fixture/conflict.err"
    test $status -eq 2; or fail 'skill drift with guidance drift did not return conflict code 2'
    rg -Fq 'Result: conflict' "$fixture/conflict.out"; or fail 'skill drift with guidance drift did not report conflict'
    test (tree_digest "$conflict_target") = "$conflict_before"; or fail 'conflict branch changed guidance bytes'
    fish "$installer" --target "$conflict_target" --force >"$fixture/conflict-force.out" 2>"$fixture/conflict-force.err"; or fail 'force did not converge skill and guidance drift'

    set -l partial_target "$fixture/partial-target"
    command cp -R "$current_target" "$partial_target"
    printf '%s\n' '<!-- SPECTRA:START -->' agents-drift '<!-- SPECTRA:END -->' >>"$partial_target/AGENTS.md"
    printf '%s\n' '<!-- SPECTRA:START -->' claude-drift '<!-- SPECTRA:END -->' >>"$partial_target/CLAUDE.md"
    set -l partial_receipt_before (shasum -a 256 "$partial_target/.cash-skills/receipt.tsv" | awk '{ print $1 }')
    set -l partial_hook "$fixture/partial-guidance-hook"
    printf '%s\n' \
        '#!/bin/sh' \
        '[ "$1" = before-temp ] || exit 0' \
        '[ "$3" = CLAUDE.md ] || exit 0' \
        'exit 77' >"$partial_hook"
    command chmod +x "$partial_hook"
    if env CASH_GUIDANCE_TEST_HOOK="$partial_hook" fish --no-config "$installer" --target "$partial_target" >"$fixture/partial.out" 2>"$fixture/partial.err"
        fail 'installer masked a partial guidance publication failure'
    end
    test (shasum -a 256 "$partial_target/.cash-skills/receipt.tsv" | awk '{ print $1 }') = "$partial_receipt_before"; or fail 'partial guidance failure replaced an existing receipt'
    if rg -q '^Result:' "$fixture/partial.out"
        fail 'partial guidance failure emitted a domain result'
    end
    fish "$installer" --target "$partial_target" >"$fixture/partial-retry.out" 2>"$fixture/partial-retry.err"; or fail 'ordinary retry did not converge partial guidance publication'
    rg -Fq 'Result: update' "$fixture/partial-retry.out"; or fail 'partial guidance retry did not report update'

    set -l receipt_failure_target "$fixture/receipt-failure-target"
    command mkdir -p "$receipt_failure_target"
    set -l move_stub_dir "$fixture/receipt-move-bin"
    command mkdir -p "$move_stub_dir"
    printf '%s\n' \
        '#!/bin/sh' \
        'destination=' \
        'for argument in "$@"; do destination=$argument; done' \
        'case "$destination" in */.cash-skills/receipt.tsv) exit 78 ;; esac' \
        'exec /bin/mv "$@"' >"$move_stub_dir/mv"
    command chmod +x "$move_stub_dir/mv"
    if env PATH="$move_stub_dir:$PATH" fish --no-config "$installer" --target "$receipt_failure_target" >"$fixture/receipt-failure.out" 2>"$fixture/receipt-failure.err"
        fail 'installer masked receipt publication failure'
    end
    test ! -e "$receipt_failure_target/.cash-skills/receipt.tsv"; or fail 'receipt publication failure left a receipt'
    test (find "$receipt_failure_target/.agents/skills" "$receipt_failure_target/.claude/skills" -name SKILL.md | wc -l | string trim) = 24; or fail 'receipt publication failure did not leave the completed 24-file publication state'
    fish "$installer" --target "$receipt_failure_target" >"$fixture/receipt-retry.out" 2>"$fixture/receipt-retry.err"; or fail 'receipt-less adoption did not recover receipt publication failure'
    rg -Fq 'Result: update' "$fixture/receipt-retry.out"; or fail 'receipt-less adoption recovery did not report update'
    test -f "$receipt_failure_target/.cash-skills/receipt.tsv"; or fail 'receipt-less adoption recovery did not publish receipt'

    command rm -rf -- "$fixture"
end

function seed_retired_plus_skill --argument-names target variant skill declared_name
    set -l skill_dir "$target/$variant/skills/spectra-$skill-plus"
    command mkdir -p "$skill_dir"; or fail "could not create retired plus fixture: $skill_dir"
    printf '%s\n' '---' "name: $declared_name" '---' 'legacy plus fixture' >"$skill_dir/SKILL.md"
    or fail "could not write retired plus fixture: $skill_dir/SKILL.md"
end

function seed_all_retired_plus_skills --argument-names target
    for variant in .agents .claude
        for skill in propose apply
            seed_retired_plus_skill "$target" "$variant" "$skill" "spectra-$skill-plus"
        end
    end
end

function assert_retired_plus_skills_absent --argument-names target contract
    for variant in .agents .claude
        for skill in propose apply
            test ! -e "$target/$variant/skills/spectra-$skill-plus"; or fail "$contract retained $variant/skills/spectra-$skill-plus"
        end
    end
end

function assert_retired_plus_skills_present --argument-names target contract
    for variant in .agents .claude
        for skill in propose apply
            test -f "$target/$variant/skills/spectra-$skill-plus/SKILL.md"; or fail "$contract removed $variant/skills/spectra-$skill-plus"
        end
    end
end

function assert_complete_retired_plus_plan --argument-names output contract
    for variant in .agents .claude
        for skill in propose apply
            rg -Fq "remove: $variant/skills/spectra-$skill-plus" "$output"; or fail "$contract omitted $variant/skills/spectra-$skill-plus plan"
        end
    end
end

function write_retired_plus_swap_mv_stub --argument-names stub_dir
    command mkdir -p "$stub_dir"; or fail 'could not create retired plus mv stub directory'
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "$1" = "-h" ]; then source_path=$2; destination_path=$3; else source_path=$1; destination_path=$2; fi' \
        'case "$source_path:$destination_path" in' \
        '  */.agents/skills/spectra-propose-plus:*/.cash-retired-plus.*)' \
        '    case "$CASH_RETIRED_PLUS_SWAP_MODE" in' \
        '      symlink)' \
        '        /bin/rm -f "$source_path/SKILL.md" || exit 81' \
        '        /bin/rmdir "$source_path" || exit 82' \
        '        /bin/ln -s "$CASH_RETIRED_PLUS_SWAP_OUTSIDE" "$source_path" || exit 83' \
        '        ;;' \
        '      extra)' \
        '        printf "%s\n" unknown >"$source_path/UNKNOWN" || exit 84' \
        '        ;;' \
        '      quarantine-symlink)' \
        '        /bin/ln -s "$CASH_RETIRED_PLUS_SWAP_OUTSIDE" "$destination_path" || exit 85' \
        '        ;;' \
        '    esac' \
        '    ;;' \
        'esac' \
        'exec /bin/mv "$@"' >"$stub_dir/mv"
    or fail 'could not write retired plus mv swap stub'
    command chmod +x "$stub_dir/mv"; or fail 'could not make retired plus mv swap stub executable'
end

function assert_single_result --argument-names output expected contract
    set -l result_lines (rg '^Result: ' "$output" | string collect)
    test (count (string split \n -- (string trim -- "$result_lines"))) -eq 1; or fail "$contract did not emit exactly one Result line"
    rg -Fxq "Result: $expected" "$output"; or fail "$contract did not report Result: $expected"
end

function write_failing_cp_stub --argument-names stub_dir
    command mkdir -p "$stub_dir"; or fail 'could not create cp stub directory'
    printf '%s\n' \
        '#!/bin/sh' \
        'count=0' \
        'if [ -f "$CASH_CP_COUNT_FILE" ]; then count=$(cat "$CASH_CP_COUNT_FILE"); fi' \
        'count=$((count + 1))' \
        'printf "%s\n" "$count" >"$CASH_CP_COUNT_FILE"' \
        'if [ "$count" -eq "$CASH_CP_FAIL_AT" ]; then exit 73; fi' \
        'exec /bin/cp "$@"' >"$stub_dir/cp"
    or fail 'could not write cp failure stub'
    command chmod +x "$stub_dir/cp"; or fail 'could not make cp failure stub executable'
end

function compare_bundle_versions --argument-names left right
    set -l left_parts (string split . -- "$left")
    set -l right_parts (string split . -- "$right")
    for index in 1 2 3
        set -l left_length (string length -- "$left_parts[$index]")
        set -l right_length (string length -- "$right_parts[$index]")
        if test $left_length -lt $right_length
            echo -1
            return
        end
        if test $left_length -gt $right_length
            echo 1
            return
        end
        set -l digit_index 1
        while test $digit_index -le $left_length
            set -l left_digit (string sub -s $digit_index -l 1 -- "$left_parts[$index]")
            set -l right_digit (string sub -s $digit_index -l 1 -- "$right_parts[$index]")
            if test $left_digit -lt $right_digit
                echo -1
                return
            end
            if test $left_digit -gt $right_digit
                echo 1
                return
            end
            set digit_index (math $digit_index + 1)
        end
    end
    echo 0
end

function cash_inventory_digest_at --argument-names repository revision
    set -l records
    for variant_root in .agents .claude
        for skill in $cash_skills
            set -l relative_path "$variant_root/skills/cash-$skill/SKILL.md"
            set -l digest ""
            if test "$revision" = WORKTREE
                test -f "$repository/$relative_path"; or return 1
                set digest (command shasum -a 256 "$repository/$relative_path" | command awk '{ print $1 }')
                set -l digest_pipeline $pipestatus
                test $digest_pipeline[1] -eq 0; and test $digest_pipeline[2] -eq 0; or return 1
            else
                set digest (command git -C "$repository" show "$revision:$relative_path" 2>/dev/null | command shasum -a 256 | command awk '{ print $1 }')
                set -l digest_pipeline $pipestatus
                test $digest_pipeline[1] -eq 0; and test $digest_pipeline[2] -eq 0; and test $digest_pipeline[3] -eq 0; or return 1
            end
            set -a records "$digest  $relative_path"
        end
    end
    set -l digest (string join \n -- $records | command shasum -a 256 | command awk '{ print $1 }')
    set -l digest_pipeline $pipestatus
    test $digest_pipeline[1] -eq 0; and test $digest_pipeline[2] -eq 0; and test $digest_pipeline[3] -eq 0; or return 1
    echo "$digest"
end

function bundle_version_at --argument-names repository revision
    set -l lines (command git -C "$repository" show "$revision:cash-skills.version" 2>/dev/null)
    test $status -eq 0; and test (count $lines) -eq 1; or return 1
    string match -rq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -- "$lines[1]"; or return 1
    echo "$lines[1]"
end

function check_bundle_version_governance --argument-names repository
    set -l version_lines (command cat "$repository/cash-skills.version" 2>/dev/null)
    test $status -eq 0; and test (count $version_lines) -eq 1; or begin
        echo 'bundle version must contain exactly one readable line' >&2
        return 1
    end
    set -l current_version "$version_lines[1]"
    string match -rq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -- "$current_version"; or begin
        echo "invalid bundle version: $current_version" >&2
        return 1
    end

    command git -C "$repository" rev-parse --verify HEAD >/dev/null 2>&1; or return 0
    set -l head_version (bundle_version_at "$repository" HEAD)
    if test $status -ne 0
        # Bootstrap repositories without a committed version have no historical baseline.
        return 0
    end

    set -l current_digest (cash_inventory_digest_at "$repository" WORKTREE); or return 1
    if test "$current_version" != "$head_version"
        set -l comparison (compare_bundle_versions "$current_version" "$head_version")
        if test $comparison -lt 0
            echo "bundle version regressed from $head_version to $current_version" >&2
            return 1
        end
        set -l head_digest (cash_inventory_digest_at "$repository" HEAD); or return 1
        if test "$current_digest" != "$head_digest"; and test $comparison -le 0
            echo 'changed cash skill bytes require a strictly greater bundle version' >&2
            return 1
        end
        return 0
    end

    set -l introduction HEAD
    while true
        set -l parent (command git -C "$repository" rev-parse "$introduction^1" 2>/dev/null)
        test $status -eq 0; or break
        set -l parent_version (bundle_version_at "$repository" "$parent")
        test $status -eq 0; and test "$parent_version" = "$current_version"; or break
        set introduction "$parent"
    end

    set -l introduction_digest (cash_inventory_digest_at "$repository" "$introduction"); or return 1
    if test "$current_digest" != "$introduction_digest"
        echo "cash skill bytes changed without a bundle bump after $introduction" >&2
        return 1
    end
end

function assert_bundle_version_history_fixtures
    set -l fixture (mktemp -d /tmp/cash-version-governance-suite.XXXXXX)
    string match -q '/tmp/cash-version-governance-suite.*' "$fixture"; or fail 'mktemp returned an unexpected version governance fixture path'
    command git -C "$fixture" init -q; or fail 'could not initialize version governance history'
    command mkdir -p "$fixture/.agents" "$fixture/.claude"; or fail 'could not create version governance inventory roots'
    command cp -R "$root_dir/.agents/skills" "$fixture/.agents/"; or fail 'could not copy version governance Codex inventory'
    command cp -R "$root_dir/.claude/skills" "$fixture/.claude/"; or fail 'could not copy version governance Claude inventory'
    printf '1.0.0\n' >"$fixture/cash-skills.version"; or fail 'could not write version governance bundle version'
    command git -C "$fixture" add .; or fail 'could not stage version introduction fixture'
    command git -C "$fixture" -c user.name=Cash -c user.email=cash@example.invalid commit -q -m 'introduce cash bundle 1.0.0'; or fail 'could not commit version introduction fixture'

    set -l hash_stub_dir "$fixture/hash-bin"
    command mkdir -p "$hash_stub_dir"; or fail 'could not create digest failure stub directory'
    printf '%s\n' \
        '#!/bin/sh' \
        'count=0' \
        'if [ -f "$CASH_SHASUM_COUNT_FILE" ]; then count=$(cat "$CASH_SHASUM_COUNT_FILE"); fi' \
        'count=$((count + 1))' \
        'printf "%s\n" "$count" >"$CASH_SHASUM_COUNT_FILE"' \
        'if [ "$count" -eq "$CASH_SHASUM_FAIL_AT" ]; then exit 79; fi' \
        'exec "$CASH_REAL_SHASUM" "$@"' >"$hash_stub_dir/shasum"
    or fail 'could not write digest failure stub'
    command chmod +x "$hash_stub_dir/shasum"; or fail 'could not make digest failure stub executable'
    printf '0\n' >"$fixture/shasum-count"
    set -l system_shasum (command -s shasum)
    set -l original_path $PATH
    set -lx PATH "$hash_stub_dir:$PATH"
    set -lx CASH_SHASUM_COUNT_FILE "$fixture/shasum-count"
    set -lx CASH_SHASUM_FAIL_AT 25
    set -lx CASH_REAL_SHASUM "$system_shasum"
    if cash_inventory_digest_at "$fixture" WORKTREE >/dev/null
        fail 'cash inventory digest masked its final shasum pipeline failure'
    end
    set PATH $original_path
    set -e CASH_SHASUM_COUNT_FILE CASH_SHASUM_FAIL_AT CASH_REAL_SHASUM

    printf 'working mutation\n' >>"$fixture/.agents/skills/cash-ask/SKILL.md"
    if check_bundle_version_governance "$fixture" >/dev/null 2>&1
        fail 'same-version working cash mutation passed version governance'
    end
    printf '1.0.1\n' >"$fixture/cash-skills.version"
    check_bundle_version_governance "$fixture"; or fail 'strictly greater working version did not authorize changed cash bytes'
    printf '0.9.0\n' >"$fixture/cash-skills.version"
    if check_bundle_version_governance "$fixture" >/dev/null 2>&1
        fail 'regressed working version passed version governance'
    end

    command git -C "$fixture" show HEAD:.agents/skills/cash-ask/SKILL.md | command tee "$fixture/.agents/skills/cash-ask/SKILL.md" >/dev/null
    set -l restore_pipeline $pipestatus
    test $restore_pipeline[1] -eq 0; and test $restore_pipeline[2] -eq 0; or fail 'could not restore clean version comparator fixture'
    set -l seq_stub_dir "$fixture/seq-bin"
    command mkdir -p "$seq_stub_dir"; or fail 'could not create version comparator seq stub directory'
    printf '%s\n' '#!/bin/sh' 'exit 78' >"$seq_stub_dir/seq"
    command chmod +x "$seq_stub_dir/seq"; or fail 'could not make version comparator seq stub executable'
    set original_path $PATH
    set -lx PATH "$seq_stub_dir:$PATH"
    if check_bundle_version_governance "$fixture" >/dev/null 2>&1
        fail 'version governance masked a seq failure and accepted a regressed version'
    end
    set PATH $original_path

    printf '1.0.0\n' >"$fixture/cash-skills.version"
    printf 'working mutation\n' >>"$fixture/.agents/skills/cash-ask/SKILL.md"
    command git -C "$fixture" add .agents/skills/cash-ask/SKILL.md; or fail 'could not stage same-version history mutation'
    command git -C "$fixture" -c user.name=Cash -c user.email=cash@example.invalid commit -q -m 'same-version mutation'; or fail 'could not commit same-version history mutation'
    printf 'unrelated\n' >"$fixture/unrelated.txt"
    command git -C "$fixture" add unrelated.txt; or fail 'could not stage unrelated history fixture'
    command git -C "$fixture" -c user.name=Cash -c user.email=cash@example.invalid commit -q -m 'later unrelated commit'; or fail 'could not commit unrelated history fixture'
    if check_bundle_version_governance "$fixture" >/dev/null 2>&1
        fail 'same-version mutation passed after a later unrelated commit'
    end

    command rm -rf -- "$fixture"
end

function check_version_literal_occurrence_inventory --argument-names repository governed_literal
    set -e argv[1..2]
    set -l expected_records $argv
    set -l actual_records
    for path in (rg -l --hidden --glob '!.git/**' -F -- "$governed_literal" "$repository")
        set -l relative_path (string replace -- "$repository/" '' "$path")
        set relative_path (string replace -r '^openspec/changes/(archive/[0-9-]+-)?add-versioned-cash-skill-batch-update/' 'openspec/changes/<change>/' "$relative_path")
        set -l occurrence_count (rg -Fo -- "$governed_literal" "$path" | wc -l | string trim)
        set -a actual_records (string join \t "$relative_path" "$occurrence_count")
    end
    set -l actual_sorted (printf '%s\n' $actual_records | command sort)
    set -l actual_pipeline $pipestatus
    test $actual_pipeline[1] -eq 0; and test $actual_pipeline[2] -eq 0; or return 1
    set -l expected_sorted (printf '%s\n' $expected_records | command sort)
    set -l expected_pipeline $pipestatus
    test $expected_pipeline[1] -eq 0; and test $expected_pipeline[2] -eq 0; or return 1
    set -l actual_text (string join \n -- $actual_sorted | string collect)
    set -l expected_text (string join \n -- $expected_sorted | string collect)
    test "$actual_text" = "$expected_text"
end

function assert_version_literal_inventory_fixture
    set -l fixture (mktemp -d /tmp/cash-version-literal-inventory.XXXXXX)
    string match -q '/tmp/cash-version-literal-inventory.*' "$fixture"; or fail 'mktemp returned an unexpected version literal fixture path'
    set -l governed_literal (string join . 1 0 0)
    printf '%s\n' "$governed_literal" >"$fixture/assertions.txt"
    set -l expected (string join \t assertions.txt 1)
    check_version_literal_occurrence_inventory "$fixture" "$governed_literal" "$expected"; or fail 'complete version literal occurrence inventory did not pass'
    printf 'stale assertion %s\n' "$governed_literal" >>"$fixture/assertions.txt"
    if check_version_literal_occurrence_inventory "$fixture" "$governed_literal" "$expected"
        fail 'uninventoried prior-version assertion did not fail loudly'
    end
    printf '%s\n' "$governed_literal" >"$fixture/assertions.txt"
    set -l sort_stub_dir "$fixture/bin"
    command mkdir -p "$sort_stub_dir"; or fail 'could not create version inventory sort stub directory'
    printf '%s\n' '#!/bin/sh' 'exit 78' >"$sort_stub_dir/sort"
    command chmod +x "$sort_stub_dir/sort"; or fail 'could not make version inventory sort stub executable'
    set -lx PATH "$sort_stub_dir:$PATH"
    if check_version_literal_occurrence_inventory "$fixture" "$governed_literal" "$expected"
        fail 'version literal inventory masked sort execution failure'
    end
    command rm -rf -- "$fixture"
end

function assert_version_contract_inventory
    set -l affected_paths cash-skills.version install-cash-skills.fish scripts/cash-skills/tests/skill-checks.fish CASH-SKILLS.md
    for relative_path in $affected_paths
        test -f "$root_dir/$relative_path"; or fail "proposal affected-code path is missing: $relative_path"
    end
    test ! -e "$root_dir/update-cash-skills.fish"; or fail 'update-cash-skills.fish must not exist when install-cash-skills.fish is the single entry point'

    for relative_path in install-cash-skills.fish scripts/cash-skills/tests/skill-checks.fish CASH-SKILLS.md
        assert_contains "$root_dir/$relative_path" 'cash-skills.version' 'bundle version literal inventory'
        assert_contains "$root_dir/$relative_path" '.cash-skills/receipt.tsv' 'receipt literal inventory'
    end
    for relative_path in install-cash-skills.fish scripts/cash-skills/tests/skill-checks.fish CASH-SKILLS.md
        assert_contains "$root_dir/$relative_path" '.config/cash-skills/projects.txt' 'registry literal inventory'
    end
    assert_contains "$root_dir/install-cash-skills.fish" 'echo "Result: $result"' 'installer result protocol inventory'
    for result in update current newer conflict
        assert_contains "$root_dir/install-cash-skills.fish" "emit_result $result" 'installer result literal inventory'
    end
    for status_name in updated would-update current newer conflict failed
        assert_contains "$root_dir/install-cash-skills.fish" "$status_name" 'batch status literal inventory'
    end
    assert_absent "$root_dir/install-cash-skills.fish" '1\.0\.0' 'installer must read, not hardcode, bundle version'

    rg -n --hidden --glob '!.git/**' '1\.0\.0|cash-skills\.version|\.cash-skills/receipt\.tsv|\.config/cash-skills/projects\.txt|Result: (update|current|newer|conflict)|would-update|updated:' "$root_dir" >/dev/null
    or fail 'repository-wide cash version/result literal inventory scan failed'

    if test -d "$root_dir/.git"
        set -l governed_literal (string join . 1 0 0)
        set -l expected_records \
            (string join \t CASH-SKILLS.md 1) \
            (string join \t 'openspec/changes/<change>/design.md' 1) \
            (string join \t 'openspec/changes/<change>/tasks.md' 2) \
            (string join \t openspec/changes/archive/2026-07-04-guard-dirty-source-auto-repair/specs/spectra-plus-skills/spec.md 1) \
            (string join \t openspec/changes/archive/2026-07-04-version-spectra-plus-skills/specs/spectra-plus-skills/spec.md 1) \
            (string join \t scripts/cash-skills/tests/skill-checks.fish 17)
        check_version_literal_occurrence_inventory "$root_dir" "$governed_literal" $expected_records
        or fail 'repository prior-version literal occurrence inventory drifted'
        assert_version_literal_inventory_fixture
    end
end

function assert_versioned_installer_branch_matrix
    test -f "$root_dir/cash-skills.version"; or fail 'missing cash-skills.version for versioned installer contract'
    rg -Pq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' "$root_dir/cash-skills.version"; or fail 'cash-skills.version is not strict SemVer'

    set -l fixture (mktemp -d /tmp/cash-versioned-installer-suite.XXXXXX)
    string match -q '/tmp/cash-versioned-installer-suite.*' "$fixture"; or fail 'mktemp returned an unexpected versioned installer fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l installer "$source/install-cash-skills.fish"

    set -l invalid_target "$fixture/invalid-target"
    command mkdir -p "$invalid_target"; or fail 'could not create invalid-version target'
    printf '01.0.0\n' >"$source/cash-skills.version"
    if fish "$installer" --target "$invalid_target" >"$fixture/invalid.out" 2>"$fixture/invalid.err"
        fail 'installer accepted a leading-zero bundle version'
    end
    assert_absent "$fixture/invalid.out" '^Result: ' 'invalid source version result protocol'
    test (find "$invalid_target" -mindepth 1 | wc -l | string trim) = 0; or fail 'invalid source version changed target state'
    if fish "$installer" --target "$invalid_target" --dry-run >"$fixture/invalid-dry.out" 2>"$fixture/invalid-dry.err"
        fail 'installer dry-run accepted a leading-zero bundle version'
    end
    printf '1.0.0\n\n' >"$source/cash-skills.version"
    if fish "$installer" --target "$invalid_target" >"$fixture/extra-version-line.out" 2>"$fixture/extra-version-line.err"
        fail 'installer accepted an extra blank bundle version line'
    end
    assert_absent "$fixture/extra-version-line.out" '^Result: ' 'extra bundle version line result protocol'

    printf '1.9.9\n' >"$source/cash-skills.version"
    set -l ordered_target "$fixture/ordered-target"
    command mkdir -p "$ordered_target"; or fail 'could not create ordered-version target'
    set -l seq_stub_dir "$fixture/seq-bin"
    command mkdir -p "$seq_stub_dir"; or fail 'could not create seq failure stub directory'
    printf '%s\n' '#!/bin/sh' 'exit 77' >"$seq_stub_dir/seq"
    command chmod +x "$seq_stub_dir/seq"; or fail 'could not make seq failure stub executable'
    env PATH="$seq_stub_dir:$PATH" fish --no-config "$installer" --target "$ordered_target" >"$fixture/ordered-install.out" 2>"$fixture/ordered-install.err"; or fail 'installer depended on a fallible external seq command'
    assert_single_result "$fixture/ordered-install.out" update 'initial ordered-version install'
    printf '1.10.0\n' >"$source/cash-skills.version"
    fish "$installer" --target "$ordered_target" >"$fixture/ordered-minor.out" 2>"$fixture/ordered-minor.err"; or fail 'installer did not order 1.10.0 above 1.9.9'
    assert_single_result "$fixture/ordered-minor.out" update 'minor version upgrade'
    printf '1.10.1\n' >"$source/cash-skills.version"
    fish "$installer" --target "$ordered_target" >"$fixture/ordered-patch.out" 2>"$fixture/ordered-patch.err"; or fail 'installer did not order 1.10.1 above 1.10.0'
    assert_single_result "$fixture/ordered-patch.out" update 'patch version upgrade'
    printf '999999999999999999.0.0\n' >"$source/cash-skills.version"
    fish "$installer" --target "$ordered_target" >"$fixture/ordered-large-a.out" 2>"$fixture/ordered-large-a.err"; or fail 'installer could not install a large version component'
    printf '1000000000000000000.0.0\n' >"$source/cash-skills.version"
    fish "$installer" --target "$ordered_target" >"$fixture/ordered-large-b.out" 2>"$fixture/ordered-large-b.err"; or fail 'installer misordered arbitrary-length version components'
    assert_single_result "$fixture/ordered-large-b.out" update 'arbitrary-length version upgrade'

    printf '1.0.0\n' >"$source/cash-skills.version"
    set -l clean_target "$fixture/clean-target"
    command mkdir -p "$clean_target"; or fail 'could not create versioned clean target'
    fish "$installer" --target "$clean_target" >"$fixture/clean-versioned.out" 2>"$fixture/clean-versioned.err"; or fail 'versioned clean install failed'
    assert_single_result "$fixture/clean-versioned.out" update 'versioned clean install'
    set -l receipt "$clean_target/.cash-skills/receipt.tsv"
    test -f "$receipt"; or fail 'versioned clean install did not publish receipt'
    test (wc -l <"$receipt" | string trim) = 25; or fail 'receipt does not contain version plus 24 records'
    test (head -n 1 "$receipt") = (string join \t version 1.0.0); or fail 'receipt version record is invalid'
    for line in (tail -n +2 "$receipt")
        string match -rq '^sha256\t[0-9a-f]{64}\t\.(agents|claude)/skills/cash-[a-z-]+/SKILL\.md$' -- "$line"; or fail "invalid receipt record: $line"
    end

    set -l current_before (tree_digest "$clean_target")
    fish "$installer" --target "$clean_target" >"$fixture/current.out" 2>"$fixture/current.err"; or fail 'equal version current branch failed'
    assert_single_result "$fixture/current.out" current 'equal version current branch'
    test (tree_digest "$clean_target") = "$current_before"; or fail 'equal version current branch changed target state'

    set -l hardlink_target "$fixture/hardlink-target"
    command cp -R "$clean_target" "$hardlink_target"; or fail 'could not copy hard-link upgrade target'
    set -l external_file "$fixture/external-managed-file"
    command cp "$hardlink_target/.agents/skills/cash-ask/SKILL.md" "$external_file"; or fail 'could not seed external hard-link file'
    command rm -f "$hardlink_target/.agents/skills/cash-ask/SKILL.md"
    command ln "$external_file" "$hardlink_target/.agents/skills/cash-ask/SKILL.md"; or fail 'could not create managed hard-link fixture'
    set -l external_before (command shasum -a 256 "$external_file" | command awk '{ print $1 }')
    set -l external_pipeline $pipestatus
    test $external_pipeline[1] -eq 0; and test $external_pipeline[2] -eq 0; or fail 'could not hash external hard-link fixture'
    printf '1.0.1\n' >"$source/cash-skills.version"
    printf 'hard-link upgrade\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    fish "$installer" --target "$hardlink_target" >"$fixture/hardlink.out" 2>"$fixture/hardlink.err"; or fail 'hard-link clean upgrade failed'
    assert_single_result "$fixture/hardlink.out" update 'hard-link clean upgrade'
    set -l external_after (command shasum -a 256 "$external_file" | command awk '{ print $1 }')
    set external_pipeline $pipestatus
    test $external_pipeline[1] -eq 0; and test $external_pipeline[2] -eq 0; or fail 'could not rehash external hard-link fixture'
    test "$external_after" = "$external_before"; or fail 'installer modified an external inode through a managed hard link'
    command cmp -s "$source/.agents/skills/cash-ask/SKILL.md" "$hardlink_target/.agents/skills/cash-ask/SKILL.md"; or fail 'hard-link upgrade did not install source bytes'
    printf '1.0.0\n' >"$source/cash-skills.version"
    command cp "$root_dir/.agents/skills/cash-ask/SKILL.md" "$source/.agents/skills/cash-ask/SKILL.md"; or fail 'could not restore hard-link source fixture'

    set -l unwritable_parent_target "$fixture/unwritable-parent-target"
    command cp -R "$clean_target" "$unwritable_parent_target"; or fail 'could not copy unwritable managed parent target'
    printf '1.0.1\n' >"$source/cash-skills.version"
    printf 'managed parent preflight\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    command chmod 555 "$unwritable_parent_target/.agents/skills/cash-ask"; or fail 'could not make managed destination parent unwritable'
    set -l unwritable_parent_before (tree_digest "$unwritable_parent_target")
    for suffix in dry actual
        set -l arguments
        if test "$suffix" = dry
            set arguments --dry-run
        end
        if fish "$installer" --target "$unwritable_parent_target" $arguments >"$fixture/unwritable-parent-$suffix.out" 2>"$fixture/unwritable-parent-$suffix.err"
            fail "installer accepted an unwritable managed destination parent during $suffix"
        end
        assert_absent "$fixture/unwritable-parent-$suffix.out" '^Result: ' "unwritable managed parent $suffix result protocol"
        test (tree_digest "$unwritable_parent_target") = "$unwritable_parent_before"; or fail "unwritable managed parent $suffix failure changed target state"
    end
    command chmod 755 "$unwritable_parent_target/.agents/skills/cash-ask"; or fail 'could not restore managed destination parent permissions'
    printf '1.0.0\n' >"$source/cash-skills.version"
    command cp "$root_dir/.agents/skills/cash-ask/SKILL.md" "$source/.agents/skills/cash-ask/SKILL.md"; or fail 'could not restore managed parent source fixture'

    set -l unwritable_receipt_target "$fixture/unwritable-receipt-target"
    command cp -R "$clean_target" "$unwritable_receipt_target"; or fail 'could not copy unwritable receipt directory fixture'
    printf '1.0.1\n' >"$source/cash-skills.version"
    printf 'receipt parent preflight\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    command chmod 555 "$unwritable_receipt_target/.cash-skills"; or fail 'could not make receipt directory unwritable'
    set -l unwritable_receipt_before (tree_digest "$unwritable_receipt_target")
    if fish "$installer" --target "$unwritable_receipt_target" >"$fixture/unwritable-receipt.out" 2>"$fixture/unwritable-receipt.err"
        fail 'installer updated skills before rejecting an unwritable receipt directory'
    end
    assert_absent "$fixture/unwritable-receipt.out" '^Result: ' 'unwritable receipt directory result protocol'
    test (tree_digest "$unwritable_receipt_target") = "$unwritable_receipt_before"; or fail 'unwritable receipt directory failure changed target bytes'
    command chmod 755 "$unwritable_receipt_target/.cash-skills"; or fail 'could not restore receipt directory permissions'
    printf '1.0.0\n' >"$source/cash-skills.version"
    command cp "$root_dir/.agents/skills/cash-ask/SKILL.md" "$source/.agents/skills/cash-ask/SKILL.md"; or fail 'could not restore unwritable receipt source fixture'

    set -l missing_declared_target "$fixture/missing-declared-target"
    command cp -R "$clean_target" "$missing_declared_target"; or fail 'could not copy missing receipt-managed destination fixture'
    command rm -f "$missing_declared_target/.agents/skills/cash-ask/SKILL.md"
    set -l missing_declared_before (tree_digest "$missing_declared_target")
    fish "$installer" --target "$missing_declared_target" >"$fixture/missing-declared.out" 2>"$fixture/missing-declared.err"
    test $status -eq 1; or fail 'missing receipt-managed destination was not an execution failure'
    assert_absent "$fixture/missing-declared.out" '^Result: ' 'missing receipt-managed destination result protocol'
    test (tree_digest "$missing_declared_target") = "$missing_declared_before"; or fail 'missing receipt-managed destination failure changed target state'

    set -l hash_stub_dir "$fixture/hash-bin"
    command mkdir -p "$hash_stub_dir"; or fail 'could not create hash failure stub directory'
    printf '%s\n' '#!/bin/sh' 'exit 74' >"$hash_stub_dir/shasum"
    command chmod +x "$hash_stub_dir/shasum"; or fail 'could not make hash failure stub executable'
    set -l hash_failure_target "$fixture/hash-failure-target"
    command mkdir -p "$hash_failure_target"; or fail 'could not create hash failure target'
    if env PATH="$hash_stub_dir:$PATH" fish --no-config "$installer" --target "$hash_failure_target" >"$fixture/hash-failure.out" 2>"$fixture/hash-failure.err"
        fail 'installer masked a source hash command failure'
    end
    assert_absent "$fixture/hash-failure.out" '^Result: ' 'source hash failure result protocol'
    test (find "$hash_failure_target" -mindepth 1 | wc -l | string trim) = 0; or fail 'source hash failure changed target state'

    set -l malformed_before (tree_digest "$clean_target")
    printf 'sha256\tbad\tunknown\n' >>"$receipt"
    if fish "$installer" --target "$clean_target" >"$fixture/malformed.out" 2>"$fixture/malformed.err"
        fail 'installer accepted a malformed receipt'
    end
    assert_absent "$fixture/malformed.out" '^Result: ' 'malformed receipt result protocol'
    test (tree_digest "$clean_target") != "$malformed_before"; or fail 'malformed receipt fixture was not seeded'
    command sed -i '' -e '$d' "$receipt"; or fail 'could not restore receipt fixture'

    printf 'source mutation\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    set -l integrity_before (tree_digest "$clean_target")
    if fish "$installer" --target "$clean_target" --force >"$fixture/integrity.out" 2>"$fixture/integrity.err"
        fail 'installer force bypassed equal-version source integrity failure'
    end
    assert_absent "$fixture/integrity.out" '^Result: ' 'equal-version source integrity result protocol'
    test (tree_digest "$clean_target") = "$integrity_before"; or fail 'equal-version source integrity failure changed target state'
    command cp "$root_dir/.agents/skills/cash-ask/SKILL.md" "$source/.agents/skills/cash-ask/SKILL.md"; or fail 'could not restore equal-version source fixture'

    set -l adoption_target "$fixture/adoption-target"
    command mkdir -p "$adoption_target"; or fail 'could not create adoption target'
    for variant_root in .agents .claude
        for skill in $cash_skills
            command mkdir -p "$adoption_target/$variant_root/skills/cash-$skill"
            command cp "$source/$variant_root/skills/cash-$skill/SKILL.md" "$adoption_target/$variant_root/skills/cash-$skill/SKILL.md"
        end
    end
    set -l adoption_files_before (cash_inventory_digest "$adoption_target")
    fish "$installer" --target "$adoption_target" >"$fixture/adoption.out" 2>"$fixture/adoption.err"; or fail 'installer could not adopt an identical receipt-less target'
    assert_single_result "$fixture/adoption.out" update 'receipt-less adoption'
    test (cash_inventory_digest "$adoption_target") = "$adoption_files_before"; or fail 'receipt-less adoption rewrote skill bytes'
    test -f "$adoption_target/.cash-skills/receipt.tsv"; or fail 'receipt-less adoption did not publish receipt'

    set -l mixed_target "$fixture/mixed-target"
    command mkdir -p "$mixed_target/.agents/skills/cash-ask"; or fail 'could not create mixed legacy target'
    printf 'legacy\n' >"$mixed_target/.agents/skills/cash-ask/SKILL.md"
    set -l mixed_before (tree_digest "$mixed_target")
    fish "$installer" --target "$mixed_target" >"$fixture/mixed.out" 2>"$fixture/mixed.err"
    test $status -eq 2; or fail 'mixed receipt-less target did not exit 2'
    assert_single_result "$fixture/mixed.out" conflict 'mixed receipt-less conflict'
    test (tree_digest "$mixed_target") = "$mixed_before"; or fail 'mixed receipt-less conflict performed writes'
    fish "$installer" --target "$mixed_target" --force >"$fixture/mixed-force.out" 2>"$fixture/mixed-force.err"; or fail 'force did not repair mixed receipt-less target'
    assert_single_result "$fixture/mixed-force.out" update 'mixed receipt-less force'

    printf '2.0.0\n' >"$source/cash-skills.version"
    printf 'version two\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    fish "$installer" --target "$clean_target" >"$fixture/upgrade.out" 2>"$fixture/upgrade.err"; or fail 'clean older target did not upgrade'
    assert_single_result "$fixture/upgrade.out" update 'clean upgrade'
    printf 'target drift\n' >>"$clean_target/.agents/skills/cash-ask/SKILL.md"
    set -l drift_before (tree_digest "$clean_target")
    fish "$installer" --target "$clean_target" >"$fixture/drift.out" 2>"$fixture/drift.err"
    test $status -eq 2; or fail 'target drift did not exit 2'
    assert_single_result "$fixture/drift.out" conflict 'target drift conflict'
    test (tree_digest "$clean_target") = "$drift_before"; or fail 'target drift conflict changed target state'
    fish "$installer" --target "$clean_target" --force >"$fixture/drift-force.out" 2>"$fixture/drift-force.err"; or fail 'force did not repair target drift'

    printf '1.9.9\n' >"$source/cash-skills.version"
    set -l newer_before (tree_digest "$clean_target")
    fish "$installer" --target "$clean_target" --force >"$fixture/newer.out" 2>"$fixture/newer.err"; or fail 'newer target branch failed'
    assert_single_result "$fixture/newer.out" newer 'newer target preservation'
    test (tree_digest "$clean_target") = "$newer_before"; or fail 'force downgraded a newer target'

    set -l dry_target "$fixture/versioned-dry-target"
    command mkdir -p "$dry_target"; or fail 'could not create versioned dry-run target'
    set -l dry_before (tree_digest "$dry_target")
    fish "$installer" --target "$dry_target" --dry-run >"$fixture/versioned-dry.out" 2>"$fixture/versioned-dry.err"; or fail 'versioned dry-run failed'
    assert_single_result "$fixture/versioned-dry.out" update 'versioned dry-run'
    test (tree_digest "$dry_target") = "$dry_before"; or fail 'versioned dry-run changed target state'

    printf '3.0.0\n' >"$source/cash-skills.version"
    printf 'partial a\n' >>"$source/.agents/skills/cash-archive/SKILL.md"
    printf 'partial b\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    set -l stub_dir "$fixture/bin"
    write_failing_cp_stub "$stub_dir"
    set -l prior_receipt (command cp "$clean_target/.cash-skills/receipt.tsv" "$fixture/prior-receipt.tsv"; and echo "$fixture/prior-receipt.tsv")
    printf '0\n' >"$fixture/cp-count"
    if env PATH="$stub_dir:$PATH" CASH_CP_COUNT_FILE="$fixture/cp-count" CASH_CP_FAIL_AT=2 fish --no-config "$installer" --target "$clean_target" >"$fixture/partial-upgrade.out" 2>"$fixture/partial-upgrade.err"
        fail 'partial upgrade fixture unexpectedly succeeded'
    end
    command cmp -s "$fixture/prior-receipt.tsv" "$clean_target/.cash-skills/receipt.tsv"; or fail 'partial upgrade published a new receipt'
    fish "$installer" --target "$clean_target" >"$fixture/partial-retry.out" 2>"$fixture/partial-retry.err"
    test $status -eq 2; or fail 'partial upgrade retry did not detect drift against prior receipt'

    set -l partial_first_target "$fixture/partial-first-target"
    command mkdir -p "$partial_first_target"; or fail 'could not create first-install partial target'
    printf '0\n' >"$fixture/cp-count"
    if env PATH="$stub_dir:$PATH" CASH_CP_COUNT_FILE="$fixture/cp-count" CASH_CP_FAIL_AT=2 fish --no-config "$installer" --target "$partial_first_target" >"$fixture/partial-first.out" 2>"$fixture/partial-first.err"
        fail 'first-install partial fixture unexpectedly succeeded'
    end
    test ! -e "$partial_first_target/.cash-skills/receipt.tsv"; or fail 'first-install partial failure published a receipt'
    fish "$installer" --target "$partial_first_target" >"$fixture/partial-first-retry.out" 2>"$fixture/partial-first-retry.err"
    test $status -eq 2; or fail 'first-install partial retry did not report conflict'

    set -l zero_write_target "$fixture/zero-write-target"
    command mkdir -p "$zero_write_target"; or fail 'could not create zero-write target'
    printf '0\n' >"$fixture/cp-count"
    if env PATH="$stub_dir:$PATH" CASH_CP_COUNT_FILE="$fixture/cp-count" CASH_CP_FAIL_AT=1 fish --no-config "$installer" --target "$zero_write_target" >"$fixture/zero-write.out" 2>"$fixture/zero-write.err"
        fail 'zero-write failure fixture unexpectedly succeeded'
    end
    test (find "$zero_write_target" -type f | wc -l | string trim) = 0; or fail 'zero-write failure persisted a managed file'
    fish "$installer" --target "$zero_write_target" >"$fixture/zero-write-retry.out" 2>"$fixture/zero-write-retry.err"; or fail 'zero-write retry did not follow clean install path'

    command rm -rf -- "$fixture"
end

function assert_retired_plus_cleanup_matrix
    set -l fixture (mktemp -d /tmp/cash-retired-plus-suite.XXXXXX)
    string match -q '/tmp/cash-retired-plus-suite.*' "$fixture"; or fail 'mktemp returned an unexpected retired plus fixture path'
    set fixture (command realpath "$fixture"); or fail 'could not canonicalize retired plus fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l installer "$source/install-cash-skills.fish"

    set -l first_target "$fixture/first-target"
    command mkdir -p "$first_target/.agents/skills/spectra-ask"; or fail 'could not create first-install legacy target'
    seed_all_retired_plus_skills "$first_target"
    printf 'preserve non-plus\n' >"$first_target/.agents/skills/spectra-ask/SKILL.md"
    printf 'preserve outside\n' >"$first_target/outside-sentinel"
    set -l first_non_plus_before (command shasum -a 256 "$first_target/.agents/skills/spectra-ask/SKILL.md" | command awk '{ print $1 }')
    set -l first_non_plus_pipeline $pipestatus
    test $first_non_plus_pipeline[1] -eq 0; and test $first_non_plus_pipeline[2] -eq 0; or fail 'could not hash first-install non-plus sentinel'
    set -l first_outside_before (command shasum -a 256 "$first_target/outside-sentinel" | command awk '{ print $1 }')
    set -l first_outside_pipeline $pipestatus
    test $first_outside_pipeline[1] -eq 0; and test $first_outside_pipeline[2] -eq 0; or fail 'could not hash first-install outside sentinel'
    fish "$installer" --target "$first_target" >"$fixture/first.out" 2>"$fixture/first.err"; or fail 'first install with retired plus skills failed'
    assert_single_result "$fixture/first.out" update 'first install retired plus cleanup'
    assert_complete_retired_plus_plan "$fixture/first.out" 'first install retired plus cleanup'
    assert_retired_plus_skills_absent "$first_target" 'first install retired plus cleanup'
    test (command shasum -a 256 "$first_target/.agents/skills/spectra-ask/SKILL.md" | command awk '{ print $1 }') = "$first_non_plus_before"; or fail 'first install changed a non-plus Spectra skill'
    test (command shasum -a 256 "$first_target/outside-sentinel" | command awk '{ print $1 }') = "$first_outside_before"; or fail 'first install changed an outside sentinel'

    set -l current_target "$fixture/current-target"
    command mkdir -p "$current_target"; or fail 'could not create current retired plus target'
    fish "$installer" --target "$current_target" >/dev/null 2>&1; or fail 'could not seed current retired plus target'
    seed_all_retired_plus_skills "$current_target"
    fish "$installer" --target "$current_target" >"$fixture/current.out" 2>"$fixture/current.err"; or fail 'current target retired plus cleanup failed'
    assert_single_result "$fixture/current.out" update 'current target retired plus cleanup'
    assert_complete_retired_plus_plan "$fixture/current.out" 'current target retired plus cleanup'
    assert_retired_plus_skills_absent "$current_target" 'current target retired plus cleanup'

    set -l dry_target "$fixture/dry-target"
    command mkdir -p "$dry_target"; or fail 'could not create retired plus dry-run target'
    fish "$installer" --target "$dry_target" >/dev/null 2>&1; or fail 'could not seed retired plus dry-run target'
    seed_all_retired_plus_skills "$dry_target"
    set -l dry_before (tree_digest "$dry_target")
    fish "$installer" --target "$dry_target" --dry-run >"$fixture/dry.out" 2>"$fixture/dry.err"; or fail 'retired plus dry-run failed'
    assert_single_result "$fixture/dry.out" update 'retired plus dry-run'
    assert_complete_retired_plus_plan "$fixture/dry.out" 'retired plus dry-run'
    test (tree_digest "$dry_target") = "$dry_before"; or fail 'retired plus dry-run changed target state'

    set -l adoption_target "$fixture/adoption-target"
    command mkdir -p "$adoption_target"; or fail 'could not create retired plus adoption target'
    for variant_root in .agents .claude
        for skill in $cash_skills
            command mkdir -p "$adoption_target/$variant_root/skills/cash-$skill"
            command cp "$source/$variant_root/skills/cash-$skill/SKILL.md" "$adoption_target/$variant_root/skills/cash-$skill/SKILL.md"
        end
    end
    seed_all_retired_plus_skills "$adoption_target"
    fish "$installer" --target "$adoption_target" >"$fixture/adoption.out" 2>"$fixture/adoption.err"; or fail 'adoption retired plus cleanup failed'
    assert_single_result "$fixture/adoption.out" update 'adoption retired plus cleanup'
    assert_complete_retired_plus_plan "$fixture/adoption.out" 'adoption retired plus cleanup'
    assert_retired_plus_skills_absent "$adoption_target" 'adoption retired plus cleanup'

    set -l upgrade_target "$fixture/upgrade-target"
    command mkdir -p "$upgrade_target"; or fail 'could not create retired plus upgrade target'
    printf '0.9.0\n' >"$source/cash-skills.version"
    fish "$installer" --target "$upgrade_target" >/dev/null 2>&1; or fail 'could not seed retired plus upgrade target'
    printf '1.0.0\n' >"$source/cash-skills.version"
    seed_all_retired_plus_skills "$upgrade_target"
    fish "$installer" --target "$upgrade_target" >"$fixture/upgrade.out" 2>"$fixture/upgrade.err"; or fail 'upgrade retired plus cleanup failed'
    assert_single_result "$fixture/upgrade.out" update 'upgrade retired plus cleanup'
    assert_complete_retired_plus_plan "$fixture/upgrade.out" 'upgrade retired plus cleanup'
    assert_retired_plus_skills_absent "$upgrade_target" 'upgrade retired plus cleanup'

    set -l newer_target "$fixture/newer-target"
    command mkdir -p "$newer_target"; or fail 'could not create retired plus newer target'
    printf '2.0.0\n' >"$source/cash-skills.version"
    fish "$installer" --target "$newer_target" >/dev/null 2>&1; or fail 'could not seed retired plus newer target'
    printf '1.0.0\n' >"$source/cash-skills.version"
    seed_all_retired_plus_skills "$newer_target"
    set -l newer_before (tree_digest "$newer_target")
    fish "$installer" --target "$newer_target" >"$fixture/newer.out" 2>"$fixture/newer.err"; or fail 'newer target with retired plus skills failed'
    assert_single_result "$fixture/newer.out" newer 'newer retired plus preservation'
    assert_retired_plus_skills_present "$newer_target" 'newer retired plus preservation'
    test (tree_digest "$newer_target") = "$newer_before"; or fail 'newer branch changed retired plus target state'
    fish "$installer" --target "$newer_target" --force >"$fixture/newer-force.out" 2>"$fixture/newer-force.err"; or fail 'newer target with retired plus skills and force failed'
    assert_single_result "$fixture/newer-force.out" newer 'newer force retired plus preservation'
    assert_retired_plus_skills_present "$newer_target" 'newer force retired plus preservation'
    test (tree_digest "$newer_target") = "$newer_before"; or fail 'newer force branch changed retired plus target state'

    set -l conflict_target "$fixture/conflict-target"
    command mkdir -p "$conflict_target"; or fail 'could not create retired plus conflict target'
    fish "$installer" --target "$conflict_target" >/dev/null 2>&1; or fail 'could not seed retired plus conflict target'
    seed_all_retired_plus_skills "$conflict_target"
    printf 'target drift\n' >>"$conflict_target/.agents/skills/cash-ask/SKILL.md"
    set -l conflict_before (tree_digest "$conflict_target")
    fish "$installer" --target "$conflict_target" >"$fixture/conflict.out" 2>"$fixture/conflict.err"
    test $status -eq 2; or fail 'conflict target with retired plus skills did not exit 2'
    assert_single_result "$fixture/conflict.out" conflict 'conflict retired plus preservation'
    assert_retired_plus_skills_present "$conflict_target" 'conflict retired plus preservation'
    test (tree_digest "$conflict_target") = "$conflict_before"; or fail 'conflict branch changed retired plus target state'
    fish "$installer" --target "$conflict_target" --force >"$fixture/conflict-force.out" 2>"$fixture/conflict-force.err"; or fail 'force repair with retired plus skills failed'
    assert_single_result "$fixture/conflict-force.out" update 'force repair retired plus cleanup'
    assert_complete_retired_plus_plan "$fixture/conflict-force.out" 'force repair retired plus cleanup'
    assert_retired_plus_skills_absent "$conflict_target" 'force repair retired plus cleanup'

    for unsafe_case in extra name-mismatch non-directory symlink dangling-symlink skill-symlink missing-skill missing-closing duplicate-name conflicting-name read-only unreadable
        set -l unsafe_target "$fixture/unsafe-$unsafe_case"
        command cp -R "$first_target" "$unsafe_target"; or fail "could not copy retired plus unsafe target $unsafe_case"
        set -l candidate "$unsafe_target/.agents/skills/spectra-propose-plus"
        switch "$unsafe_case"
            case extra
                seed_retired_plus_skill "$unsafe_target" .agents propose spectra-propose-plus
                printf 'unknown\n' >"$candidate/UNKNOWN"
            case name-mismatch
                seed_retired_plus_skill "$unsafe_target" .agents propose spectra-apply-plus
            case non-directory
                command mkdir -p (command dirname "$candidate")
                printf 'not a skill directory\n' >"$candidate"
            case symlink
                set -l outside "$fixture/outside-plus"
                command mkdir -p "$outside"
                printf '%s\n' '---' 'name: spectra-propose-plus' '---' >"$outside/SKILL.md"
                command mkdir -p (command dirname "$candidate")
                command ln -s "$outside" "$candidate"; or fail 'could not create retired plus symlink candidate'
            case dangling-symlink
                command mkdir -p (command dirname "$candidate")
                command ln -s "$fixture/missing-plus-target" "$candidate"; or fail 'could not create dangling retired plus symlink candidate'
            case skill-symlink
                set -l outside_file "$fixture/outside-plus-skill"
                printf '%s\n' '---' 'name: spectra-propose-plus' '---' >"$outside_file"
                command mkdir -p "$candidate"
                command ln -s "$outside_file" "$candidate/SKILL.md"; or fail 'could not create retired plus SKILL.md symlink candidate'
            case missing-skill
                command mkdir -p "$candidate"; or fail 'could not create missing retired plus SKILL.md candidate'
            case missing-closing
                command mkdir -p "$candidate"
                printf '%s\n' '---' 'name: spectra-propose-plus' 'unknown user content' >"$candidate/SKILL.md"
            case duplicate-name
                command mkdir -p "$candidate"
                printf '%s\n' '---' 'name: spectra-propose-plus' 'name: spectra-propose-plus' '---' >"$candidate/SKILL.md"
            case conflicting-name
                command mkdir -p "$candidate"
                printf '%s\n' '---' 'name: spectra-propose-plus' 'name: spectra-apply-plus' '---' >"$candidate/SKILL.md"
            case read-only
                seed_retired_plus_skill "$unsafe_target" .agents propose spectra-propose-plus
                command chmod 400 "$candidate/SKILL.md"; or fail 'could not create read-only retired plus candidate'
            case unreadable
                seed_retired_plus_skill "$unsafe_target" .agents propose spectra-propose-plus
                command chmod 200 "$candidate/SKILL.md"; or fail 'could not create unreadable retired plus candidate'
        end
        set -l unsafe_before ""
        set -l unsafe_cash_before (cash_inventory_digest "$unsafe_target")
        set -l unsafe_receipt_before (command shasum -a 256 "$unsafe_target/.cash-skills/receipt.tsv" | command awk '{ print $1 }')
        if test "$unsafe_case" != unreadable
            set unsafe_before (tree_digest "$unsafe_target")
        end
        if fish "$installer" --target "$unsafe_target" >"$fixture/unsafe-$unsafe_case.out" 2>"$fixture/unsafe-$unsafe_case.err"
            fail "installer accepted unsafe retired plus candidate: $unsafe_case"
        end
        assert_absent "$fixture/unsafe-$unsafe_case.out" '^Result: ' "unsafe retired plus $unsafe_case result protocol"
        test (cash_inventory_digest "$unsafe_target") = "$unsafe_cash_before"; or fail "unsafe retired plus $unsafe_case failure changed cash skill state"
        test (command shasum -a 256 "$unsafe_target/.cash-skills/receipt.tsv" | command awk '{ print $1 }') = "$unsafe_receipt_before"; or fail "unsafe retired plus $unsafe_case failure changed receipt state"
        if not test -e "$candidate"; and not test -L "$candidate"
            fail "unsafe retired plus $unsafe_case failure removed its candidate"
        end
        if test "$unsafe_case" != unreadable
            test (tree_digest "$unsafe_target") = "$unsafe_before"; or fail "unsafe retired plus $unsafe_case failure changed target state"
        else
            command chmod 600 "$candidate/SKILL.md"; or fail 'could not restore unreadable retired plus candidate permissions'
        end
    end

    set -l swap_stub_dir "$fixture/swap-bin"
    write_retired_plus_swap_mv_stub "$swap_stub_dir"
    for swap_mode in symlink extra quarantine-symlink
        set -l swap_target "$fixture/swap-$swap_mode"
        command cp -R "$first_target" "$swap_target"; or fail "could not copy retired plus swap target $swap_mode"
        seed_retired_plus_skill "$swap_target" .agents propose spectra-propose-plus
        set -l swap_outside "$fixture/swap-outside-$swap_mode"
        command mkdir -p "$swap_outside"; or fail "could not create retired plus swap outside target $swap_mode"
        printf 'outside sentinel\n' >"$swap_outside/SKILL.md"
        set -l outside_before (command shasum -a 256 "$swap_outside/SKILL.md" | command awk '{ print $1 }')
        set -l swap_cash_before (cash_inventory_digest "$swap_target")
        set -l swap_receipt_before (command shasum -a 256 "$swap_target/.cash-skills/receipt.tsv" | command awk '{ print $1 }')
        env PATH="$swap_stub_dir:$PATH" CASH_RETIRED_PLUS_SWAP_MODE="$swap_mode" CASH_RETIRED_PLUS_SWAP_OUTSIDE="$swap_outside" fish --no-config "$installer" --target "$swap_target" >"$fixture/swap-$swap_mode.out" 2>"$fixture/swap-$swap_mode.err"
        set -l swap_status $status
        test $swap_status -ne 0; or fail "installer accepted retired plus post-preflight $swap_mode swap"
        assert_absent "$fixture/swap-$swap_mode.out" '^Result: ' "retired plus post-preflight $swap_mode result protocol"
        test (command shasum -a 256 "$swap_outside/SKILL.md" | command awk '{ print $1 }') = "$outside_before"; or fail "retired plus post-preflight $swap_mode changed outside content"
        test (cash_inventory_digest "$swap_target") = "$swap_cash_before"; or fail "retired plus post-preflight $swap_mode changed cash skills"
        test (command shasum -a 256 "$swap_target/.cash-skills/receipt.tsv" | command awk '{ print $1 }') = "$swap_receipt_before"; or fail "retired plus post-preflight $swap_mode changed receipt bytes"
        if test "$swap_mode" = extra
            test -f "$swap_target/.agents/skills/spectra-propose-plus/UNKNOWN"; or fail 'retired plus quarantine deleted post-preflight unknown content'
            test -f "$swap_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail 'retired plus quarantine deleted recognized file after unknown-content swap'
        else if test "$swap_mode" = symlink
            test -L "$swap_target/.agents/skills/spectra-propose-plus"; or fail 'retired plus quarantine did not preserve swapped symlink candidate'
        else
            test -f "$swap_target/.agents/skills/spectra-propose-plus/SKILL.md"; or fail 'retired plus no-follow quarantine destination swap lost candidate'
            test ! -e "$swap_outside/spectra-propose-plus"; or fail 'retired plus quarantine destination symlink moved candidate outside target'
        end
    end

    set -l batch_target "$fixture/batch-target"
    set -l batch_home "$fixture/batch-home"
    command mkdir -p "$batch_target" "$batch_home"; or fail 'could not create retired plus batch fixture'
    fish "$installer" --target "$batch_target" >/dev/null 2>&1; or fail 'could not seed retired plus batch target'
    seed_all_retired_plus_skills "$batch_target"
    env HOME="$batch_home" fish --no-config "$installer" --register "$batch_target" >/dev/null 2>&1; or fail 'could not register retired plus batch target'
    set -l batch_before (tree_digest "$batch_target")
    env HOME="$batch_home" fish --no-config "$installer" --all --dry-run >"$fixture/batch-dry.out" 2>"$fixture/batch-dry.err"; or fail 'retired plus batch dry-run failed'
    rg -Fq "would-update: $batch_target" "$fixture/batch-dry.out"; or fail 'retired plus batch dry-run omitted would-update status'
    rg -Fq 'Summary: updated=0 current=0 newer=0 conflict=0 failed=0 would-update=1' "$fixture/batch-dry.out"; or fail 'retired plus batch dry-run summary counts drifted'
    test (tree_digest "$batch_target") = "$batch_before"; or fail 'retired plus batch dry-run changed target state'
    env HOME="$batch_home" fish --no-config "$installer" --all >"$fixture/batch.out" 2>"$fixture/batch.err"; or fail 'retired plus batch update failed'
    rg -Fq "updated: $batch_target" "$fixture/batch.out"; or fail 'retired plus batch update omitted updated status'
    rg -Fq 'Summary: updated=1 current=0 newer=0 conflict=0 failed=0 would-update=0' "$fixture/batch.out"; or fail 'retired plus batch update summary counts drifted'
    assert_retired_plus_skills_absent "$batch_target" 'retired plus batch update'

    command rm -rf -- "$fixture"
end

function assert_cash_batch_branch_matrix
    set -l installer "$root_dir/install-cash-skills.fish"
    test -f "$installer"; or fail 'missing install-cash-skills.fish for manual batch update contract'
    test ! -e "$root_dir/update-cash-skills.fish"; or fail 'update-cash-skills.fish must not coexist with the single installer entry point'
    fish -n "$installer"; or fail 'install-cash-skills.fish is not valid Fish syntax'

    set -l fixture (mktemp -d /tmp/cash-batch-suite.XXXXXX)
    string match -q '/tmp/cash-batch-suite.*' "$fixture"; or fail 'mktemp returned an unexpected installer fixture path'
    set fixture (command realpath "$fixture"); or fail 'could not canonicalize installer fixture path'
    set -l source "$fixture/source"
    copy_cash_source_fixture "$source"
    set -l fixture_installer "$source/install-cash-skills.fish"
    set -l empty_home "$fixture/empty-home"
    set -l empty_target "$fixture/empty-target"
    command mkdir -p "$empty_home" "$empty_target"; or fail 'could not create installer empty-state fixtures'

    if fish --no-config "$fixture_installer" >"$fixture/no-mode.out" 2>"$fixture/no-mode.err"
        fail 'installer accepted an invocation without a primary mode'
    end
    if fish --no-config "$fixture_installer" --target "$empty_target" --list >"$fixture/target-list.out" 2>"$fixture/target-list.err"
        fail 'installer accepted --target with --list'
    end
    if fish --no-config "$fixture_installer" --register "$empty_target" --target "$empty_target" >"$fixture/register-target.out" 2>"$fixture/register-target.err"
        fail 'installer accepted --register with --target'
    end
    if fish --no-config "$fixture_installer" --list --all >"$fixture/list-all.out" 2>"$fixture/list-all.err"
        fail 'installer accepted --list with --all'
    end
    if fish --no-config "$fixture_installer" --register "$empty_target" --dry-run >"$fixture/register-dry.out" 2>"$fixture/register-dry.err"
        fail 'installer accepted --dry-run with --register'
    end
    if fish --no-config "$fixture_installer" --list --force >"$fixture/list-force.out" 2>"$fixture/list-force.err"
        fail 'installer accepted --force with --list'
    end

    env HOME="$empty_home" fish --no-config "$fixture_installer" --list >"$fixture/empty-list.out" 2>"$fixture/empty-list.err"; or fail 'installer list failed for absent registry'
    env HOME="$empty_home" fish --no-config "$fixture_installer" --unregister "$fixture/stale-target" >"$fixture/empty-unregister.out" 2>"$fixture/empty-unregister.err"; or fail 'installer unregister failed for absent registry'
    env HOME="$empty_home" fish --no-config "$fixture_installer" --all >"$fixture/empty-all.out" 2>"$fixture/empty-all.err"; or fail 'installer all failed for absent registry'
    rg -Fq 'updated=0 current=0 newer=0 conflict=0 failed=0' "$fixture/empty-all.out"; or fail 'absent registry all omitted zero summary'
    test ! -e "$empty_home/.config/cash-skills"; or fail 'read/removal mode created absent registry state'

    env HOME="$empty_home" fish --no-config "$fixture_installer" --register "$empty_target" >"$fixture/register.out" 2>"$fixture/register.err"; or fail 'installer first register failed'
    set -l registry "$empty_home/.config/cash-skills/projects.txt"
    test -f "$registry"; or fail 'installer first register did not create registry'
    set -l canonical_empty_target (command realpath "$empty_target")
    test (string trim <"$registry") = "$canonical_empty_target"; or fail 'installer did not store canonical target'
    env HOME="$empty_home" fish --no-config "$fixture_installer" --register "$empty_target/../empty-target" >"$fixture/register-repeat.out" 2>"$fixture/register-repeat.err"; or fail 'installer repeat register failed'
    test (rg -Fx "$canonical_empty_target" "$registry" | wc -l | string trim) = 1; or fail 'installer did not deduplicate registered target'
    env HOME="$empty_home" fish --no-config "$fixture_installer" --list >"$fixture/list.out" 2>"$fixture/list.err"; or fail 'installer list failed'
    test (string trim <"$fixture/list.out") = "$canonical_empty_target"; or fail 'installer list did not print canonical deduplicated target'
    env HOME="$empty_home" fish --no-config "$fixture_installer" --unregister "$empty_target" >"$fixture/unregister.out" 2>"$fixture/unregister.err"; or fail 'installer unregister existing target failed'
    test ! -s "$registry"; or fail 'installer unregister did not remove target'
    printf '%s\n' "$fixture/stale-target" >"$registry"
    env HOME="$empty_home" fish --no-config "$fixture_installer" --unregister "$fixture/stale-target" >"$fixture/unregister-stale.out" 2>"$fixture/unregister-stale.err"; or fail 'installer unregister stale target failed'
    test ! -s "$registry"; or fail 'installer unregister did not remove stale target'

    set -l injection_target (printf '%s\n%s' "$fixture/injection" target | string collect)
    command mkdir -p "$injection_target"; or fail 'could not create newline target fixture'
    set -l registry_before (tree_digest "$empty_home")
    if env HOME="$empty_home" fish --no-config "$fixture_installer" --register "$injection_target" >"$fixture/injection.out" 2>"$fixture/injection.err"
        fail 'installer accepted a newline-containing target'
    end
    test (tree_digest "$empty_home") = "$registry_before"; or fail 'newline target rejection changed registry state'

    printf '%s\tbad\n' "$canonical_empty_target" >"$registry"
    set -l malformed_before (tree_digest "$empty_home")
    for mode in list all
        if env HOME="$empty_home" fish --no-config "$fixture_installer" --$mode >"$fixture/malformed-$mode.out" 2>"$fixture/malformed-$mode.err"
            fail "installer $mode accepted retained registry control characters"
        end
        test (tree_digest "$empty_home") = "$malformed_before"; or fail "installer $mode rewrote malformed registry"
    end
    if env HOME="$empty_home" fish --no-config "$fixture_installer" --register "$empty_target" >"$fixture/malformed-register.out" 2>"$fixture/malformed-register.err"
        fail 'installer register rewrote malformed registry'
    end
    if env HOME="$empty_home" fish --no-config "$fixture_installer" --unregister "$empty_target" >"$fixture/malformed-unregister.out" 2>"$fixture/malformed-unregister.err"
        fail 'installer unregister rewrote malformed registry'
    end
    test (tree_digest "$empty_home") = "$malformed_before"; or fail 'mutation mode changed malformed registry'

    printf '%s\0bad\n' "$canonical_empty_target" >"$registry"
    set -l nul_registry_before (tree_digest "$empty_home")
    if env HOME="$empty_home" fish --no-config "$fixture_installer" --list >"$fixture/nul-registry.out" 2>"$fixture/nul-registry.err"
        fail 'installer accepted a NUL-containing registry record'
    end
    test (tree_digest "$empty_home") = "$nul_registry_before"; or fail 'NUL registry rejection changed HOME state'

    command rm -f "$registry"
    command mkdir "$registry"; or fail 'could not create unreadable registry fixture'
    set -l unreadable_before (tree_digest "$empty_home")
    for mode in list all
        if env HOME="$empty_home" fish --no-config "$fixture_installer" --$mode >"$fixture/unreadable-$mode.out" 2>"$fixture/unreadable-$mode.err"
            fail "installer $mode accepted a non-file registry"
        end
    end
    if env HOME="$empty_home" fish --no-config "$fixture_installer" --register "$empty_target" >"$fixture/unreadable-register.out" 2>"$fixture/unreadable-register.err"
        fail 'installer register accepted a non-file registry'
    end
    if env HOME="$empty_home" fish --no-config "$fixture_installer" --unregister "$empty_target" >"$fixture/unreadable-unregister.out" 2>"$fixture/unreadable-unregister.err"
        fail 'installer unregister accepted a non-file registry'
    end
    test (tree_digest "$empty_home") = "$unreadable_before"; or fail 'non-file registry rejection changed HOME state'

    set -l unsafe_home_wrapper 'set -gx HOME "$argv[1]"; source "$argv[2]" --list'
    for unsafe_home in '' relative / "$fixture/missing-home"
        if fish --no-config -c "$unsafe_home_wrapper" "$unsafe_home" "$fixture_installer" >"$fixture/unsafe-home.out" 2>"$fixture/unsafe-home.err"
            fail "installer accepted unsafe HOME '$unsafe_home'"
        end
    end
    set -l symlink_home "$fixture/symlink-home"
    command mkdir -p "$symlink_home" "$fixture/outside-config" "$fixture/fish-runtime-config"; or fail 'could not create installer symlink fixtures'
    command ln -s "$fixture/outside-config" "$symlink_home/.config"; or fail 'could not create installer config symlink'
    if env HOME="$symlink_home" XDG_CONFIG_HOME="$fixture/fish-runtime-config" fish --no-config "$fixture_installer" --register "$empty_target" >"$fixture/symlink-home.out" 2>"$fixture/symlink-home.err"
        fail 'installer accepted a symlinked config boundary'
    end
    test (find "$fixture/outside-config" -mindepth 1 | wc -l | string trim) = 0; or fail 'installer wrote through config symlink'

    set -l nested_symlink_home "$fixture/nested-symlink-home"
    command mkdir -p "$nested_symlink_home/.config" "$fixture/outside-cash-config"; or fail 'could not create nested installer symlink fixtures'
    command ln -s "$fixture/outside-cash-config" "$nested_symlink_home/.config/cash-skills"; or fail 'could not create cash-skills config symlink'
    if env HOME="$nested_symlink_home" XDG_CONFIG_HOME="$fixture/fish-runtime-config" fish --no-config "$fixture_installer" --list >"$fixture/nested-symlink.out" 2>"$fixture/nested-symlink.err"
        fail 'installer accepted a symlinked cash-skills config boundary'
    end
    test (find "$fixture/outside-cash-config" -mindepth 1 | wc -l | string trim) = 0; or fail 'installer wrote through cash-skills config symlink'

    set -l batch_home "$fixture/batch-home"
    command mkdir -p "$batch_home"; or fail 'could not create batch HOME'
    set -l older "$fixture/older"
    set -l current "$fixture/current"
    set -l newer "$fixture/newer"
    set -l conflict "$fixture/conflict"
    set -l guidance_drift "$fixture/guidance-drift"
    set -l guidance_failed "$fixture/guidance-failed"
    set -l later "$fixture/later"
    command mkdir -p "$older" "$current" "$newer" "$conflict" "$guidance_drift" "$guidance_failed" "$later"; or fail 'could not create batch targets'

    printf '0.9.0\n' >"$source/cash-skills.version"
    for target in "$older" "$conflict"
        fish "$fixture_installer" --target "$target" >/dev/null 2>&1; or fail 'could not seed older batch target'
    end
    printf '1.0.0\n' >"$source/cash-skills.version"
    for target in "$current" "$guidance_drift" "$guidance_failed" "$later"
        fish "$fixture_installer" --target "$target" >/dev/null 2>&1; or fail 'could not seed current batch target'
    end
    printf '2.0.0\n' >"$source/cash-skills.version"
    fish "$fixture_installer" --target "$newer" >/dev/null 2>&1; or fail 'could not seed newer batch target'
    printf '1.0.0\n' >"$source/cash-skills.version"
    printf 'local drift\n' >>"$conflict/.agents/skills/cash-ask/SKILL.md"
    printf '%s\n' '<!-- SPECTRA:START -->' batch-guidance-drift '<!-- SPECTRA:END -->' >>"$guidance_drift/AGENTS.md"
    printf '%s\n' '<!-- CASH:START -->' malformed-guidance >"$guidance_failed/AGENTS.md"
    printf '%s\n' '<!-- SPECTRA:START -->' newer-guidance-drift '<!-- SPECTRA:END -->' >>"$newer/AGENTS.md"
    set -l newer_before (tree_digest "$newer")

    for target in "$older" "$current" "$newer" "$conflict" "$guidance_drift" "$guidance_failed" "$fixture/missing-batch-target" "$later"
        env HOME="$batch_home" fish --no-config "$fixture_installer" --register "$target" >"$fixture/batch-register.out" 2>"$fixture/batch-register.err"
        set -l register_status $status
        if test -d "$target"
            test $register_status -eq 0; or fail "could not register batch target $target"
        else
            printf '%s\n' "$target" >>"$batch_home/.config/cash-skills/projects.txt"
        end
    end
    printf '%s\n' "$later" >>"$batch_home/.config/cash-skills/projects.txt"
    env HOME="$batch_home" fish --no-config "$fixture_installer" --all >"$fixture/batch.out" 2>"$fixture/batch.err"
    test $status -ne 0; or fail 'batch with conflict and failure returned 0'
    for status_path in "updated:$older" "current:$current" "newer:$newer" "conflict:$conflict" "updated:$guidance_drift" "failed:$guidance_failed" "failed:$fixture/missing-batch-target" "current:$later"
        set -l fields (string split : -- "$status_path")
        rg -Fq "$fields[1]: $fields[2]" "$fixture/batch.out"; or fail "batch omitted status $status_path"
    end
    test (rg -Fxc "current: $later" "$fixture/batch.out") = 1; or fail 'batch did not deduplicate duplicate target'
    rg -Fq 'Summary: updated=2 current=2 newer=1 conflict=1 failed=2 would-update=0' "$fixture/batch.out"; or fail 'batch summary counts drifted'
    test (tree_digest "$newer") = "$newer_before"; or fail 'batch changed guidance on a newer target'

    set -l conflict_before (tree_digest "$conflict")
    set -l dry_older "$fixture/dry-older"
    set -l dry_guidance "$fixture/dry-guidance"
    command mkdir -p "$dry_older" "$dry_guidance"; or fail 'could not create dry-run update target'
    printf '0.9.0\n' >"$source/cash-skills.version"
    fish "$fixture_installer" --target "$dry_older" >/dev/null 2>&1; or fail 'could not seed dry-run older target'
    printf '1.0.0\n' >"$source/cash-skills.version"
    fish "$fixture_installer" --target "$dry_guidance" >/dev/null 2>&1; or fail 'could not seed dry-run guidance target'
    printf '%s\n' '<!-- SPECTRA:START -->' dry-guidance-drift '<!-- SPECTRA:END -->' >>"$dry_guidance/CLAUDE.md"
    env HOME="$batch_home" fish --no-config "$fixture_installer" --register "$dry_older" >/dev/null 2>&1; or fail 'could not register dry-run older target'
    env HOME="$batch_home" fish --no-config "$fixture_installer" --register "$dry_guidance" >/dev/null 2>&1; or fail 'could not register dry-run guidance target'
    set -l dry_older_before (tree_digest "$dry_older")
    set -l dry_guidance_before (tree_digest "$dry_guidance")
    set -l batch_home_before (tree_digest "$batch_home")
    env HOME="$batch_home" fish --no-config "$fixture_installer" --all --dry-run >"$fixture/batch-dry.out" 2>"$fixture/batch-dry.err"
    test $status -ne 0; or fail 'batch dry-run masked conflict/failure aggregate status'
    rg -Fq "would-update: $dry_older" "$fixture/batch-dry.out"; or fail 'batch dry-run omitted would-update status'
    rg -Fq "would-update: $dry_guidance" "$fixture/batch-dry.out"; or fail 'batch dry-run omitted guidance would-update status'
    rg -Fq 'Summary: updated=0 current=4 newer=1 conflict=1 failed=2 would-update=2' "$fixture/batch-dry.out"; or fail 'batch dry-run summary counts drifted'
    test (tree_digest "$dry_older") = "$dry_older_before"; or fail 'batch dry-run changed would-update target state'
    test (tree_digest "$dry_guidance") = "$dry_guidance_before"; or fail 'batch dry-run changed guidance would-update target state'
    test (tree_digest "$conflict") = "$conflict_before"; or fail 'batch dry-run changed target state'
    test (tree_digest "$batch_home") = "$batch_home_before"; or fail 'batch dry-run changed registry state'

    set -l force_home "$fixture/force-home"
    command mkdir -p "$force_home"; or fail 'could not create force batch HOME'
    for target in "$conflict" "$newer"
        env HOME="$force_home" fish --no-config "$fixture_installer" --register "$target" >/dev/null 2>&1; or fail "could not register force target $target"
    end
    set -l force_newer_before (tree_digest "$newer")
    env HOME="$force_home" fish --no-config "$fixture_installer" --all --force >"$fixture/batch-force.out" 2>"$fixture/batch-force.err"; or fail 'batch force did not repair conflict target'
    rg -Fq "updated: $conflict" "$fixture/batch-force.out"; or fail 'batch force did not report updated target'
    rg -Fq "newer: $newer" "$fixture/batch-force.out"; or fail 'batch force did not preserve and report newer target'
    rg -Fq 'Summary: updated=1 current=0 newer=1 conflict=0 failed=0 would-update=0' "$fixture/batch-force.out"; or fail 'batch force summary counts drifted'
    test (tree_digest "$newer") = "$force_newer_before"; or fail 'batch force downgraded a newer target'

    set -l integrity_home "$fixture/integrity-home"
    command mkdir -p "$integrity_home"; or fail 'could not create integrity batch HOME'
    env HOME="$integrity_home" fish --no-config "$fixture_installer" --register "$current" >/dev/null 2>&1; or fail 'could not register integrity target'
    printf 'same version source mutation\n' >>"$source/.agents/skills/cash-ask/SKILL.md"
    env HOME="$integrity_home" fish --no-config "$fixture_installer" --all --force >"$fixture/batch-integrity.out" 2>"$fixture/batch-integrity.err"
    test $status -ne 0; or fail 'batch force masked equal-version source integrity failure'
    rg -Fq "failed: $current" "$fixture/batch-integrity.out"; or fail 'batch did not report equal-version source mismatch as failed'

    command cp "$root_dir/.agents/skills/cash-ask/SKILL.md" "$source/.agents/skills/cash-ask/SKILL.md"; or fail 'could not restore batch protocol source fixture'
    set -l protocol_target "$fixture/protocol-target"
    set -l protocol_home "$fixture/protocol-home"
    command mkdir -p "$protocol_target" "$protocol_home"; or fail 'could not create unexpected target-result fixtures'
    fish "$fixture_installer" --target "$protocol_target" >/dev/null 2>&1; or fail 'could not seed unexpected target-result fixture'
    env HOME="$protocol_home" fish --no-config "$fixture_installer" --register "$protocol_target" >/dev/null 2>&1; or fail 'could not register unexpected target-result fixture'
    command perl -0pi -e 's/emit_result current/emit_result unexpected/' "$fixture_installer"; or fail 'could not seed unexpected installer result'
    env HOME="$protocol_home" fish --no-config "$fixture_installer" --all >"$fixture/unexpected-child.out" 2>"$fixture/unexpected-child.err"
    test $status -ne 0; or fail 'batch accepted an unexpected target result'
    rg -Fq "failed: $protocol_target" "$fixture/unexpected-child.out"; or fail 'batch did not classify unexpected target result as failed'

    set -l startup_home "$fixture/startup-home"
    command mkdir -p "$startup_home/.config/fish"; or fail 'could not create installer startup HOME'
    printf '%s\n' 'function realpath; echo CONFIG_REALPATH_RAN >&2; return 1; end' 'function cat; echo CONFIG_CAT_RAN >&2; return 1; end' >"$startup_home/.config/fish/config.fish"
    "$fixture_installer" --help >"$fixture/installer-help.out" 2>"$fixture/installer-help.err"; or fail 'installer direct executable help failed'
    env HOME="$startup_home" "$fixture_installer" --list >"$fixture/installer-startup.out" 2>"$fixture/installer-startup.err"; or fail 'installer direct executable loaded hostile startup state'
    assert_absent "$fixture/installer-startup.err" 'CONFIG_(REALPATH|CAT)_RAN' 'installer no-config executable boundary'

    for forbidden in LaunchAgents cron crontab launchctl '.cache/cash-skills'
        if find "$fixture" -path "*$forbidden*" -print -quit | string length -q
            fail "installer fixture created forbidden background state: $forbidden"
        end
    end

    command rm -rf -- "$fixture"
end

function assert_installer_branch_matrix
    set -l fixture (mktemp -d /tmp/cash-installer-suite.XXXXXX)
    string match -q '/tmp/cash-installer-suite.*' "$fixture"; or fail 'mktemp returned an unexpected installer fixture path'
    set -l installer "$root_dir/install-cash-skills.fish"
    set -l target "$fixture/target"
    command mkdir -p "$target"; or fail 'could not create installer target fixture'

    fish "$installer" --target "$target" >"$fixture/clean.out" 2>"$fixture/clean.err"; or fail 'installer clean branch failed'
    set -l installed_count (find "$target/.agents/skills" "$target/.claude/skills" -path '*/cash-*/SKILL.md' -type f | wc -l | string trim)
    test "$installed_count" = 24; or fail "installer clean branch installed $installed_count files instead of 24"
    for variant_root in .agents .claude
        for skill in $cash_skills
            cmp -s "$root_dir/$variant_root/skills/cash-$skill/SKILL.md" "$target/$variant_root/skills/cash-$skill/SKILL.md"; or fail "installer output differs at $variant_root/skills/cash-$skill/SKILL.md"
        end
    end

    set -l identical_before (tree_digest "$target")
    fish "$installer" --target "$target" >"$fixture/identical.out" 2>"$fixture/identical.err"; or fail 'installer identical branch failed'
    test (tree_digest "$target") = "$identical_before"; or fail 'installer identical branch changed target bytes'

    printf 'conflict one\n' >"$target/.agents/skills/cash-ask/SKILL.md"
    printf 'conflict two\n' >"$target/.claude/skills/cash-debug/SKILL.md"
    printf 'preserve me\n' >"$target/unrelated.txt"
    set -l conflict_before (tree_digest "$target")
    if fish "$installer" --target "$target" >"$fixture/conflict.out" 2>"$fixture/conflict.err"
        fail 'installer conflict branch unexpectedly succeeded'
    end
    test (tree_digest "$target") = "$conflict_before"; or fail 'installer conflict preflight performed a partial write'
    rg -Fq '.agents/skills/cash-ask/SKILL.md' "$fixture/conflict.err"; or fail 'installer omitted the first conflict path'
    rg -Fq '.claude/skills/cash-debug/SKILL.md' "$fixture/conflict.err"; or fail 'installer omitted the second conflict path'

    fish "$installer" --target "$target" --force >"$fixture/force.out" 2>"$fixture/force.err"; or fail 'installer force branch failed'
    rg -Fq 'preserve me' "$target/unrelated.txt"; or fail 'installer force branch changed an unrelated file'
    test -f "$target/.agents/skills/cash-verify/SKILL.md"; or fail 'installer force branch did not install an absent managed file'

    printf 'single conflict\n' >"$target/.agents/skills/cash-ask/SKILL.md"
    set -l single_conflict_before (tree_digest "$target")
    if fish "$installer" --target "$target" >"$fixture/single-conflict.out" 2>"$fixture/single-conflict.err"
        fail 'installer single-conflict branch unexpectedly succeeded'
    end
    test (tree_digest "$target") = "$single_conflict_before"; or fail 'installer single-conflict preflight changed target bytes'
    fish "$installer" --target "$target" --force >"$fixture/single-force.out" 2>"$fixture/single-force.err"; or fail 'installer could not recover the single-conflict fixture with --force'

    set -l dry_target "$fixture/dry-target"
    command mkdir -p "$dry_target"; or fail 'could not create dry-run fixture'
    set -l dry_before (tree_digest "$dry_target")
    fish "$installer" --target "$dry_target" --dry-run >"$fixture/dry.out" 2>"$fixture/dry.err"; or fail 'installer dry-run branch failed'
    test (tree_digest "$dry_target") = "$dry_before"; or fail 'installer dry-run changed target state'
    test (find "$dry_target" -mindepth 1 | wc -l | string trim) = 0; or fail 'installer dry-run created target state'

    if fish "$installer" --target / >"$fixture/root.out" 2>"$fixture/root.err"
        fail 'installer accepted / as target'
    end
    if fish "$installer" --target "$root_dir" >"$fixture/source-target.out" 2>"$fixture/source-target.err"
        fail 'installer accepted its source repository as target'
    end
    if fish "$installer" --target "$fixture/missing" >"$fixture/missing-target.out" 2>"$fixture/missing-target.err"
        fail 'installer accepted an unresolved target'
    end

    set -l symlink_parent_target "$fixture/symlink-parent-target"
    command mkdir -p "$symlink_parent_target" "$fixture/outside-parent"; or fail 'could not create symlink-parent fixture'
    command ln -s "$fixture/outside-parent" "$symlink_parent_target/.agents"; or fail 'could not create managed-parent symlink fixture'
    if fish "$installer" --target "$symlink_parent_target" >"$fixture/symlink-parent.out" 2>"$fixture/symlink-parent.err"
        fail 'installer accepted a symlinked managed parent'
    end
    test (find "$fixture/outside-parent" -mindepth 1 | wc -l | string trim) = 0; or fail 'installer wrote through a managed-parent symlink escape'

    set -l symlink_destination_target "$fixture/symlink-destination-target"
    command mkdir -p "$symlink_destination_target/.agents/skills/cash-analyze"; or fail 'could not create destination symlink fixture'
    printf 'outside\n' >"$fixture/outside-skill"
    command ln -s "$fixture/outside-skill" "$symlink_destination_target/.agents/skills/cash-analyze/SKILL.md"; or fail 'could not create destination symlink'
    set -l outside_before (shasum -a 256 "$fixture/outside-skill" | awk '{ print $1 }')
    if fish "$installer" --target "$symlink_destination_target" >"$fixture/symlink-destination.out" 2>"$fixture/symlink-destination.err"
        fail 'installer accepted a symlinked managed destination'
    end
    test (shasum -a 256 "$fixture/outside-skill" | awk '{ print $1 }') = "$outside_before"; or fail 'installer wrote through a destination symlink escape'

    set -l symlink_receipt_target "$fixture/symlink-receipt-target"
    command mkdir -p "$symlink_receipt_target/.cash-skills"; or fail 'could not create receipt symlink fixture'
    printf 'outside receipt\n' >"$fixture/outside-receipt"
    command ln -s "$fixture/outside-receipt" "$symlink_receipt_target/.cash-skills/receipt.tsv"; or fail 'could not create receipt symlink'
    set -l outside_receipt_before (shasum -a 256 "$fixture/outside-receipt" | awk '{ print $1 }')
    if fish "$installer" --target "$symlink_receipt_target" >"$fixture/symlink-receipt.out" 2>"$fixture/symlink-receipt.err"
        fail 'installer accepted a symlinked receipt'
    end
    test (shasum -a 256 "$fixture/outside-receipt" | awk '{ print $1 }') = "$outside_receipt_before"; or fail 'installer wrote through a receipt symlink escape'

    set -l missing_source_root "$fixture/missing-source-root"
    command mkdir -p "$missing_source_root/.agents" "$missing_source_root/.claude"; or fail 'could not create missing-source fixture'
    command cp "$installer" "$missing_source_root/install-cash-skills.fish"; or fail 'could not copy fixture installer'
    command cp -R "$root_dir/.agents/skills" "$missing_source_root/.agents/"; or fail 'could not copy fixture Codex sources'
    command cp -R "$root_dir/.claude/skills" "$missing_source_root/.claude/"; or fail 'could not copy fixture Claude sources'
    command rm -f "$missing_source_root/.agents/skills/cash-ask/SKILL.md"
    set -l missing_source_target "$fixture/missing-source-target"
    command mkdir -p "$missing_source_target"
    if fish "$missing_source_root/install-cash-skills.fish" --target "$missing_source_target" >"$fixture/missing-source.out" 2>"$fixture/missing-source.err"
        fail 'installer accepted an incomplete source inventory'
    end
    test (find "$missing_source_target" -mindepth 1 | wc -l | string trim) = 0; or fail 'missing-source preflight performed a partial write'

    set -l startup_home "$fixture/startup-home"
    set -l startup_target "$fixture/startup-target"
    command mkdir -p "$startup_home/.config/fish" "$startup_target"; or fail 'could not create installer startup-config fixture'
    printf '%s\n' 'function realpath; echo CONFIG_REALPATH_RAN >&2; return 1; end' 'function cmp; echo CONFIG_CMP_RAN >&2; return 2; end' >"$startup_home/.config/fish/config.fish"
    env HOME="$startup_home" "$installer" --target "$startup_target" >"$fixture/startup-installer.out" 2>"$fixture/startup-installer.err"; or fail 'installer direct executable failed with hostile Fish startup config'
    assert_absent "$fixture/startup-installer.err" 'CONFIG_(REALPATH|CMP)_RAN' 'installer no-config executable boundary'
    set -l startup_installed_count (find "$startup_target/.agents/skills" "$startup_target/.claude/skills" -path '*/cash-*/SKILL.md' -type f | wc -l | string trim)
    test "$startup_installed_count" = 24; or fail "installer no-config executable installed $startup_installed_count files instead of 24"

    command rm -rf -- "$fixture"
end

function assert_cleanup_branch_matrix
    set -l fixture (mktemp -d /tmp/cash-cleanup-suite.XXXXXX)
    string match -q '/tmp/cash-cleanup-suite.*' "$fixture"; or fail 'mktemp returned an unexpected cleanup fixture path'
    set -l cleanup "$root_dir/uninstall-spectra-plus-repair.fish"
    set -l stub_dir "$fixture/bin"
    set -l state_dir "$fixture/state"
    set -l launchctl_log "$fixture/launchctl.log"
    command mkdir -p "$stub_dir" "$state_dir"; or fail 'could not create cleanup stub directories'
    printf '' >"$launchctl_log"

    set -l stub_script '#!/bin/sh
printf "%s\n" "$*" >>"$LAUNCHCTL_STUB_LOG"
operation=$1
service=$2
label=${service##*/}
if [ "$operation" = print ]; then
    if [ "$label" = "$LAUNCHCTL_FAIL_PRINT_LABEL" ]; then
        if [ -n "$LAUNCHCTL_FAIL_PRINT_MESSAGE" ]; then
            echo "$LAUNCHCTL_FAIL_PRINT_MESSAGE" >&2
        else
            echo "unexpected print failure" >&2
        fi
        exit 7
    fi
    if [ -f "$LAUNCHCTL_STATE_DIR/$label" ]; then
        echo "loaded: $service"
        exit 0
    fi
    echo "Could not find service: $service" >&2
    exit 3
fi
if [ "$operation" = bootout ]; then
    if [ "$label" = "$LAUNCHCTL_FAIL_BOOTOUT_LABEL" ]; then
        echo "unexpected bootout failure" >&2
        exit 7
    fi
    rm -f -- "$LAUNCHCTL_STATE_DIR/$label"
    exit 0
fi
echo "unsupported launchctl operation: $operation" >&2
exit 9'
    printf '%s\n' "$stub_script" >"$stub_dir/launchctl"
    command chmod +x "$stub_dir/launchctl"; or fail 'could not make launchctl stub executable'

    set -l common_env PATH="$stub_dir:$PATH" LAUNCHCTL_STUB_LOG="$launchctl_log" LAUNCHCTL_STATE_DIR="$state_dir"
    set -l cleanup_wrapper 'set isolated_home "$argv[1]"; set cleanup_script "$argv[2]"; set -e argv[1..2]; set -gx HOME "$isolated_home"; source "$cleanup_script" $argv'
    set -l first_label com.spectra.plus.repair
    set -l second_label com.agentflow.spectra-plus.repair

    set -l loaded_home "$fixture/loaded-home"
    command mkdir -p "$loaded_home/.config/spectra-plus" "$loaded_home/.cache/spectra-plus" "$loaded_home/Library/Logs"; or fail 'could not create loaded cleanup fixture'
    printf '/tmp/project-a\n/tmp/project-b\n' >"$loaded_home/.config/spectra-plus/projects.txt"
    printf 'cache\n' >"$loaded_home/.cache/spectra-plus/state"
    printf 'keep-log\n' >"$loaded_home/Library/Logs/spectra-plus-repair.log"
    printf 'loaded\n' >"$state_dir/$first_label"
    env $common_env fish --no-config -c "$cleanup_wrapper" "$loaded_home" "$cleanup" >"$fixture/loaded.out" 2>"$fixture/loaded.err"; or fail 'cleanup loaded-without-plist branch failed'
    if test -e "$state_dir/$first_label"
        fail 'cleanup did not boot out a loaded label without a plist'
    end
    if test -e "$loaded_home/.config/spectra-plus/projects.txt"
        fail 'cleanup did not remove the legacy registry'
    end
    if test -e "$loaded_home/.cache/spectra-plus"
        fail 'cleanup did not remove the legacy cache'
    end
    rg -Fq /tmp/project-a "$fixture/loaded.out"; or fail 'cleanup did not print the first registered target'
    rg -Fq /tmp/project-b "$fixture/loaded.out"; or fail 'cleanup did not print the second registered target'
    rg -Fq keep-log "$loaded_home/Library/Logs/spectra-plus-repair.log"; or fail 'cleanup changed the diagnostic log'
    rg -Fq "bootout gui/" "$launchctl_log"; or fail 'cleanup did not invoke launchctl bootout for a loaded label'

    env $common_env fish --no-config -c "$cleanup_wrapper" "$loaded_home" "$cleanup" >"$fixture/repeat.out" 2>"$fixture/repeat.err"; or fail 'cleanup repeated no-op branch failed'
    rg -Fq 'already absent (no-op)' "$fixture/repeat.out"; or fail 'cleanup repeated run did not report a no-op'

    set -l plist_home "$fixture/plist-home"
    command mkdir -p "$plist_home/Library/LaunchAgents" "$plist_home/.config/spectra-plus" "$plist_home/.cache/spectra-plus"; or fail 'could not create plist cleanup fixture'
    printf 'plist\n' >"$plist_home/Library/LaunchAgents/$second_label.plist"
    env $common_env fish --no-config -c "$cleanup_wrapper" "$plist_home" "$cleanup" >"$fixture/plist.out" 2>"$fixture/plist.err"; or fail 'cleanup not-loaded plist branch failed'
    if test -e "$plist_home/Library/LaunchAgents/$second_label.plist"
        fail 'cleanup did not remove a not-loaded known plist'
    end

    set -l dry_home "$fixture/dry-home"
    command mkdir -p "$dry_home/Library/LaunchAgents" "$dry_home/Library/Logs" "$dry_home/.config/spectra-plus" "$dry_home/.cache/spectra-plus"; or fail 'could not create cleanup dry-run fixture'
    printf '/tmp/dry-project\n' >"$dry_home/.config/spectra-plus/projects.txt"
    printf 'cache\n' >"$dry_home/.cache/spectra-plus/state"
    printf 'plist\n' >"$dry_home/Library/LaunchAgents/$first_label.plist"
    printf 'keep\n' >"$dry_home/Library/Logs/spectra-plus-repair.log"
    printf 'loaded\n' >"$state_dir/$first_label"
    printf '' >"$launchctl_log"
    set -l dry_before (tree_digest "$dry_home")
    env $common_env fish --no-config -c "$cleanup_wrapper" "$dry_home" "$cleanup" --dry-run >"$fixture/dry-cleanup.out" 2>"$fixture/dry-cleanup.err"; or fail 'cleanup dry-run branch failed'
    test (tree_digest "$dry_home") = "$dry_before"; or fail 'cleanup dry-run changed HOME state'
    test -s "$launchctl_log"; and fail 'cleanup dry-run invoked launchctl'
    rg -Fq /tmp/dry-project "$fixture/dry-cleanup.out"; or fail 'cleanup dry-run omitted registered targets'

    set -l print_error_home "$fixture/print-error-home"
    command mkdir -p "$print_error_home/Library/LaunchAgents" "$print_error_home/.config/spectra-plus" "$print_error_home/.cache/spectra-plus"; or fail 'could not create print-error fixture'
    printf 'plist\n' >"$print_error_home/Library/LaunchAgents/$first_label.plist"
    printf '/tmp/keep\n' >"$print_error_home/.config/spectra-plus/projects.txt"
    printf 'cache\n' >"$print_error_home/.cache/spectra-plus/state"
    set -l print_error_before (tree_digest "$print_error_home")
    if env $common_env LAUNCHCTL_FAIL_PRINT_LABEL="$first_label" fish --no-config -c "$cleanup_wrapper" "$print_error_home" "$cleanup" >"$fixture/print-error.out" 2>"$fixture/print-error.err"
        fail 'cleanup unexpected-print branch succeeded'
    end
    test (tree_digest "$print_error_home") = "$print_error_before"; or fail 'cleanup unexpected-print branch removed legacy state'
    rg -Fq "manual cleanup: launchctl bootout gui/" "$fixture/print-error.err"; or fail 'cleanup unexpected-print branch omitted the manual command'

    set -l misleading_error_home "$fixture/misleading-error-home"
    command mkdir -p "$misleading_error_home/Library/LaunchAgents" "$misleading_error_home/.config/spectra-plus" "$misleading_error_home/.cache/spectra-plus"; or fail 'could not create misleading-print fixture'
    printf 'plist\n' >"$misleading_error_home/Library/LaunchAgents/$first_label.plist"
    printf '/tmp/keep\n' >"$misleading_error_home/.config/spectra-plus/projects.txt"
    printf 'cache\n' >"$misleading_error_home/.cache/spectra-plus/state"
    set -l misleading_error_before (tree_digest "$misleading_error_home")
    if env $common_env LAUNCHCTL_FAIL_PRINT_LABEL="$first_label" LAUNCHCTL_FAIL_PRINT_MESSAGE='configuration not found while reading launch database' fish --no-config -c "$cleanup_wrapper" "$misleading_error_home" "$cleanup" >"$fixture/misleading-error.out" 2>"$fixture/misleading-error.err"
        fail 'cleanup treated an unrelated not-found launchctl error as service absence'
    end
    test (tree_digest "$misleading_error_home") = "$misleading_error_before"; or fail 'cleanup misleading-print branch removed legacy state'

    set -l unreadable_registry_home "$fixture/unreadable-registry-home"
    command mkdir -p "$unreadable_registry_home/.config/spectra-plus/projects.txt" "$unreadable_registry_home/.cache/spectra-plus"; or fail 'could not create unreadable-registry fixture'
    printf 'cache\n' >"$unreadable_registry_home/.cache/spectra-plus/state"
    set -l unreadable_registry_before (tree_digest "$unreadable_registry_home")
    printf '' >"$launchctl_log"
    if env $common_env fish --no-config -c "$cleanup_wrapper" "$unreadable_registry_home" "$cleanup" >"$fixture/unreadable-registry.out" 2>"$fixture/unreadable-registry.err"
        fail 'cleanup accepted a non-readable registry boundary'
    end
    test (tree_digest "$unreadable_registry_home") = "$unreadable_registry_before"; or fail 'cleanup unreadable-registry branch removed legacy state'
    test -s "$launchctl_log"; and fail 'cleanup invoked launchctl before rejecting the unreadable registry'

    set -l startup_home "$fixture/startup-home"
    command mkdir -p "$startup_home/.config/fish" "$startup_home/.config/spectra-plus" "$startup_home/.cache/spectra-plus"; or fail 'could not create cleanup startup-config fixture'
    printf '/tmp/startup-target\n' >"$startup_home/.config/spectra-plus/projects.txt"
    printf 'cache\n' >"$startup_home/.cache/spectra-plus/state"
    printf '%s\n' 'function launchctl; echo CONFIG_LAUNCHCTL_RAN >&2; return 0; end' 'function id; echo CONFIG_ID_RAN >&2; return 0; end' >"$startup_home/.config/fish/config.fish"
    printf '' >"$launchctl_log"
    env $common_env HOME="$startup_home" "$cleanup" >"$fixture/startup.out" 2>"$fixture/startup.err"; or fail 'cleanup direct executable failed with hostile Fish startup config'
    assert_absent "$fixture/startup.err" 'CONFIG_(LAUNCHCTL|ID)_RAN' 'cleanup no-config executable boundary'
    rg -Fq 'print gui/' "$launchctl_log"; or fail 'cleanup no-config executable did not use the launchctl executable'
    test ! -e "$startup_home/.config/spectra-plus/projects.txt"; or fail 'cleanup no-config executable did not remove registry state'
    test ! -e "$startup_home/.cache/spectra-plus"; or fail 'cleanup no-config executable did not remove cache state'

    set -l bootout_error_home "$fixture/bootout-error-home"
    command mkdir -p "$bootout_error_home/Library/LaunchAgents" "$bootout_error_home/.config/spectra-plus" "$bootout_error_home/.cache/spectra-plus"; or fail 'could not create bootout-error fixture'
    printf 'plist\n' >"$bootout_error_home/Library/LaunchAgents/$first_label.plist"
    printf '/tmp/keep\n' >"$bootout_error_home/.config/spectra-plus/projects.txt"
    printf 'cache\n' >"$bootout_error_home/.cache/spectra-plus/state"
    printf 'loaded\n' >"$state_dir/$first_label"
    set -l bootout_error_before (tree_digest "$bootout_error_home")
    if env $common_env LAUNCHCTL_FAIL_BOOTOUT_LABEL="$first_label" fish --no-config -c "$cleanup_wrapper" "$bootout_error_home" "$cleanup" >"$fixture/bootout-error.out" 2>"$fixture/bootout-error.err"
        fail 'cleanup unexpected-bootout branch succeeded'
    end
    test (tree_digest "$bootout_error_home") = "$bootout_error_before"; or fail 'cleanup unexpected-bootout branch removed legacy state'
    rg -Fq "manual cleanup: launchctl bootout gui/" "$fixture/bootout-error.err"; or fail 'cleanup unexpected-bootout branch omitted the manual command'

    for unsafe_home in '' relative /
        printf '' >"$launchctl_log"
        if env $common_env fish --no-config -c "$cleanup_wrapper" "$unsafe_home" "$cleanup" >"$fixture/unsafe.out" 2>"$fixture/unsafe.err"
            fail "cleanup accepted unsafe HOME '$unsafe_home'"
        end
        test -s "$launchctl_log"; and fail "cleanup invoked launchctl for unsafe HOME '$unsafe_home'"
    end

    set -l symlink_home "$fixture/symlink-home"
    command mkdir -p "$symlink_home" "$fixture/symlink-outside"; or fail 'could not create cleanup symlink fixture'
    command ln -s "$fixture/symlink-outside" "$symlink_home/.config"; or fail 'could not create cleanup boundary symlink'
    printf '' >"$launchctl_log"
    if env $common_env fish --no-config -c "$cleanup_wrapper" "$symlink_home" "$cleanup" >"$fixture/symlink-cleanup.out" 2>"$fixture/symlink-cleanup.err"
        fail 'cleanup accepted a symlinked cleanup parent'
    end
    test -s "$launchctl_log"; and fail 'cleanup invoked launchctl before rejecting a symlink boundary'
    test (find "$fixture/symlink-outside" -mindepth 1 | wc -l | string trim) = 0; or fail 'cleanup wrote through a symlink boundary'

    command rm -rf -- "$fixture"
end

function cash_inventory_digest --argument-names project_root
    begin
        for variant_root in .agents .claude
            for skill in $cash_skills
                set -l relative_path "$variant_root/skills/cash-$skill/SKILL.md"
                printf '%s  %s\n' (shasum -a 256 "$project_root/$relative_path" | awk '{ print $1 }') "$relative_path"
            end
        end
    end | shasum -a 256 | awk '{ print $1 }'
end

function assert_spectra_update_isolation
    set -l fixture (mktemp -d /tmp/cash-spectra-update-suite.XXXXXX)
    string match -q '/tmp/cash-spectra-update-suite.*' "$fixture"; or fail 'mktemp returned an unexpected Spectra update fixture path'
    command mkdir -p "$fixture/.agents" "$fixture/.claude" "$fixture/openspec"; or fail 'could not create Spectra update fixture directories'
    command cp -R "$root_dir/.agents/skills" "$fixture/.agents/"; or fail 'could not copy Codex update fixture skills'
    command cp -R "$root_dir/.claude/skills" "$fixture/.claude/"; or fail 'could not copy Claude update fixture skills'
    command cp "$root_dir/.spectra.yaml" "$root_dir/AGENTS.md" "$root_dir/CLAUDE.md" "$fixture/"; or fail 'could not copy Spectra update fixture guidance'
    command cp "$root_dir/openspec/config.yaml" "$fixture/openspec/"; or fail 'could not copy Spectra update fixture config'

    set -l before (cash_inventory_digest "$fixture")

    pushd "$fixture" >/dev/null; or fail 'could not enter Spectra update fixture'
    spectra update --force >"$fixture/update.out" 2>"$fixture/update.err"
    set -l update_status $status
    popd >/dev/null
    test $update_status -eq 0; or fail 'spectra update --force failed in the isolated fixture'

    test (cash_inventory_digest "$fixture") = "$before"; or fail 'spectra update --force mutated the cash skill inventory'
    rg -Fq '# Spectra Instructions' "$fixture/AGENTS.md"; or fail 'spectra update --force did not add managed Spectra guidance'
    test (rg -Fx '<!-- CASH:START -->' "$fixture/AGENTS.md" | wc -l | string trim) = 1; or fail 'spectra update --force removed the canonical Cash block'
    assert_contains "$fixture/AGENTS.md" '$cash-propose' 'Cash routing remains effective after Spectra update'
    assert_contains "$fixture/AGENTS.md" '本專案只使用 Cash workflow invocations' 'Cash-only routing remains explicit after Spectra update'

    command rm -rf -- "$fixture"
end

assert_variant_inventory .agents
assert_variant_inventory .claude
assert_cash_namespace .agents '$' '(?<![[:alnum:]_.-])/cash-'
assert_cash_namespace .claude / '(?<![[:alnum:]_.-])\$cash-'
assert_spectra_cli_contract
assert_propose_contract .agents '$'
assert_propose_contract .claude /
assert_apply_contract .agents '$'
assert_apply_contract .claude /
assert_commit_contract .agents
assert_commit_contract .claude
for variant_root in .agents .claude
    assert_shared_gate_contract "$variant_root" propose
    assert_shared_gate_contract "$variant_root" apply
    assert_shared_gate_parity "$variant_root"
end
assert_signals_readme_contract
assert_installer_interface
assert_cleanup_interface
assert_legacy_repair_runtime_absent
assert_cash_guidance_contract
assert_cash_live_documentation
assert_exhaustive_variant_parity
assert_tree_digest_mutation_oracle
check_bundle_version_governance "$root_dir"; or fail 'repository cash bundle version governance failed'
assert_version_contract_inventory
if not set -q CASH_SKILLS_NESTED
    assert_guidance_marker_state_matrix
    assert_guidance_snapshot_binding
    assert_guidance_boundary_matrix
    assert_guidance_transaction_matrix
    assert_numeric_version_guidance_examples
    assert_bundle_version_history_fixtures
    assert_cash_batch_branch_matrix
    assert_versioned_installer_branch_matrix
    assert_retired_plus_cleanup_matrix
    assert_installer_branch_matrix
    assert_cleanup_branch_matrix
    assert_spectra_update_isolation
    assert_contract_mutation_fixture
end

echo "PASS: cash skill inventory, ownership, namespace, and core workflow contracts"
