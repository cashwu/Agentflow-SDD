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
    for literal in 'proposal.md' 'design.md' 'tasks.md' 'spectra validate' 'Traditional Chinese' 'spec files MUST be written in English' 'exceeds 15'
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

    for marker in '<!-- MECHANICAL-SELF-CHECK -->' '<!-- GRADER-IMMUTABILITY -->' '<!-- LOOP-LEDGER-STEP -->' '<!-- SIGNALS-WRITE-STEP -->'
        assert_contains "$path" "$marker" 'cash-apply retained quality gate'
    end
    for literal in 'implementation-notes.md' Surgical Simplicity 'tasks.md' needs-design 'decision: aborted' 'decision: passed'
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
    string match -q '*--dry-run*' "$help_output"; or fail "$relative_path help omits --dry-run"
    string match -q '*--force*' "$help_output"; or fail "$relative_path help omits --force"
    if string match -rq -- '--repair|--register|launch-agent|fingerprint' "$help_output"
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
    if rg -Pqi -- '--register-target|--repair-all|--install-launch-agent|fingerprint|projects\.txt|launchctl' "$installer"
        fail 'install-cash-skills.fish contains legacy registry, repair, freshness, or scheduler behavior'
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

function assert_cash_guidance_override
    set -l relative_path AGENTS.md
    set -l path "$root_dir/$relative_path"
    set -l override (awk '/<!-- SPECTRA:END -->/ { after = 1; next } after { print }' "$path" | string collect)

    string match -q '*cash workflow invocation takes precedence*' "$override"; or fail "$relative_path lacks cash precedence after the Spectra-managed block"
    string match -q '*Spectra CLI and artifact schema remain authoritative*' "$override"; or fail "$relative_path loses Spectra artifact-engine authority"
    for invocation in '$cash-discuss' '$cash-propose' '$cash-apply' '$cash-ingest' '$cash-archive' '$cash-commit'
        string match -q "*$invocation*" "$override"; or fail "$relative_path override omits $invocation"
    end
end

function assert_cash_live_documentation
    if test -e "$root_dir/SPECTRA-PLUS.md"
        fail 'SPECTRA-PLUS.md remains as active legacy documentation'
    end
    set -l relative_path CASH-SKILLS.md
    set -l path "$root_dir/$relative_path"
    test -f "$path"; or fail "missing $relative_path"

    for literal in cash-analyze cash-apply cash-archive cash-ask cash-audit cash-commit cash-debug cash-discuss cash-drift cash-ingest cash-propose cash-verify '.agents/skills/' '.claude/skills/' './install-cash-skills.fish --target' './uninstall-spectra-plus-repair.fish --dry-run' '沒有定期 repair'
        assert_contains "$path" "$literal" 'cash live documentation'
    end
    assert_contains "$path" '先對 registry 中每個專案安裝 cash skills，再移除舊排程' 'safe migration order'
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
    command cp "$root_dir/install-cash-skills.fish" "$root_dir/uninstall-spectra-plus-repair.fish" "$root_dir/AGENTS.md" "$root_dir/CASH-SKILLS.md" "$fixture/"; or fail 'could not copy fixture root contracts'
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
    begin
        for file in (find "$directory" -type f | sort)
            shasum -a 256 "$file"
        end
    end | shasum -a 256 | awk '{ print $1 }'
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
    command rm -f "$target/.agents/skills/cash-verify/SKILL.md"
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

    perl -0pi -e 's{(<!-- SPECTRA:START[^\n]*\n).*?(<!-- SPECTRA:END -->)}{$1\nBROKEN MANAGED BLOCK\n\n$2}s' "$fixture/AGENTS.md"
    rg -Fq 'BROKEN MANAGED BLOCK' "$fixture/AGENTS.md"; or fail 'could not seed stale managed guidance in the update fixture'
    set -l before (cash_inventory_digest "$fixture")

    pushd "$fixture" >/dev/null; or fail 'could not enter Spectra update fixture'
    spectra update --force >"$fixture/update.out" 2>"$fixture/update.err"
    set -l update_status $status
    popd >/dev/null
    test $update_status -eq 0; or fail 'spectra update --force failed in the isolated fixture'

    test (cash_inventory_digest "$fixture") = "$before"; or fail 'spectra update --force mutated the cash skill inventory'
    if rg -Fq 'BROKEN MANAGED BLOCK' "$fixture/AGENTS.md"
        fail 'spectra update --force did not refresh the managed AGENTS.md block'
    end
    rg -Fq '# Spectra Instructions' "$fixture/AGENTS.md"; or fail 'spectra update --force did not restore managed Spectra guidance'
    set -l override (awk '/<!-- SPECTRA:END -->/ { after = 1; next } after { print }' "$fixture/AGENTS.md" | string collect)
    string match -q '*cash workflow invocation takes precedence*' "$override"; or fail 'spectra update --force removed the project-owned cash precedence override'
    string match -q '*$cash-propose*' "$override"; or fail 'spectra update --force removed effective cash workflow routing'

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
assert_cash_guidance_override
assert_cash_live_documentation
assert_exhaustive_variant_parity
if not set -q CASH_SKILLS_NESTED
    assert_installer_branch_matrix
    assert_cleanup_branch_matrix
    assert_spectra_update_isolation
    assert_contract_mutation_fixture
end

echo "PASS: cash skill inventory, ownership, namespace, and core workflow contracts"
