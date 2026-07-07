## 1. 模板規則收斂

- [x] 1.1 交付 Review loop grader immutability 的 Decision 1: Structured scope declarations control grader exceptions：scripts/spectra-plus/template/review-loop-block.md 中 protected grader path 的 exception 只接受 proposal ## Impact affected-code entries 與 tasks.md 交付標的路徑，且排除驗證命令、規則描述、範例與 finding context 的 incidental path；驗證：content review 對照 spectra-plus-skills delta 的 incidental protected path scenario，並在 scripts/spectra-plus/tests/generator-checks.fish 加入關鍵文字斷言。
- [x] 1.2 交付 Deterministic signal-derived self-checks 的 Decision 2: Exit 1 check handling uses mutually exclusive branches：Signal-derived checks 的 exit 1 分流明確限定 protected-path skip 只適用於未被 structured scope declarations 覆蓋的 grader path；驗證：content review 對照 protected path branch scenario，並在 scripts/spectra-plus/tests/generator-checks.fish 加入互斥分支文字斷言。
- [x] 1.3 交付 Deterministic signal-derived self-checks 的 Decision 3: Check scope classification is path-based and fail-closed：模板定義 check output path 與 change artifact/source file set 的交集判定，無可定位 path 時 fail closed；驗證：content review 對照 in-scope 與 unlocatable failure scenarios，並在 scripts/spectra-plus/tests/generator-checks.fish 加入 fail-closed 文字斷言。
- [x] 1.4 交付 Review loop grader immutability 的 Decision 4: Completion output anchors are named by skill and outcome：模板點名 propose-plus passed final summary、apply-plus passed gate-complete final response、aborted unresolved-findings warning 三種 workflow completion output 錨點；驗證：content review 對照 completion output anchors scenario，並在 scripts/spectra-plus/tests/generator-checks.fish 加入三個錨點文字斷言。

## 2. Signals README guidance

- [x] [P] 2.1 交付 Signals directory README contract 的 Decision 5: README guidance covers location output and shell error traps：openspec/signals/README.md 記載新寫 check 應輸出 project-root-relative paths，並記載 POSIX sh 無 pipefail、pipeline status、blind negation 與原生 exit 1 錯誤工具的 exit-code remapping 規則；驗證：content review 對照 signals-shared-layer delta scenario，並在 scripts/spectra-plus/tests/generator-checks.fish 或等效 README 檢查中斷言關鍵 guidance。
- [x] [P] 2.2 交付 Signals shared layer location and file schema 的 Decision 6: Canonical check example emits paths：openspec/specs/signals-shared-layer/spec.md 的 canonical `check` 範例從 quiet detection 改為輸出命中 project-root-relative paths 且保留 explicit exit-code remapping 的唯讀 pattern；驗證：content review 對照 signals-shared-layer delta 的 optional check example，確認範例不使用 `grep -rq` 且示範 path-emitting check。

## 3. 重生成與驗證

- [x] 3.1 執行 scripts/spectra-plus/generate.fish 全量重生成，交付 generated plus skills 與模板規則一致的契約：.claude/skills/spectra-propose-plus/SKILL.md、.claude/skills/spectra-apply-plus/SKILL.md、.agents/skills/spectra-propose-plus/SKILL.md、.agents/skills/spectra-apply-plus/SKILL.md 均包含 structured scope declarations、mutually exclusive exit 1 分流、fail-closed scope 判定與 completion output anchors；驗證：scripts/spectra-plus/tests/generator-checks.fish 全數通過，且連續兩次重生成後 git diff 顯示產物 byte-identical。
- [x] 3.2 執行 spectra validate "tighten-review-loop-edge-cases"，交付 proposal、design、specs、tasks 的 artifact consistency 契約：所有 modified capabilities 都有對應 delta spec，所有 requirement 與 design decision 都有 backing task；驗證：命令 exit 0 且無 validation error。
