## Context

cash skill 系統目前有兩類重複維護面：

1. **Review gate 四份拷貝**：sub-agent review gate 規格逐字存在於 `.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`。跨檔一致性目前僅由 `scripts/cash-skills/tests/skill-checks.fish` 的 `grader_hash` 部分覆蓋（對 `<!-- GRADER-IMMUTABILITY -->` 至 `<!-- LOOP-LEDGER-STEP -->` 子區段做不經前綴正規化的 raw byte SHA-256 跨檔斷言），其餘 gate 文字沒有機械同步保障。實測已存在一處 propose 對 apply 的漂移：propose 兩檔的 false-positive 條目引用 `## Proposed Solution`，apply 兩檔同位置為 `## What Changes` or `## Proposed Solution`（同 skill 的兩變體各自逐字相同）。
2. **雙 canonical 變體**：十二個 skill 的 `.agents` 變體是獨立維護的完整檔案，與 `.claude` 變體的合法差異由 `scripts/cash-skills/variant-parity/` 下 8 個 unified-diff manifest 記錄（`cash-apply` 等 4 個 skill 無宣告差異），由 `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_variant_parity`（divergent 清單在該檔第 5 行，`normalized_variant_diff` 僅正規化 `/cash-*` 對 `$cash-*` 前綴）事後比對。

先前存在的 spectra-plus 生成管線（generate.fish + rules.yaml + template blocks）已於 cash cutover 時移除，本 change 需在 `scripts/cash-skills/` 下重建同型機制。master spec `openspec/specs/cash-skill-workflows/spec.md` 對四個 gate 檔案的內容有逐字錨定（sentinel 存在性、受保護 grader 路徑集合、可讀 manifest 條款），設計必須讓生成輸出繼續逐字滿足這些 requirement。

## Goals / Non-Goals

**Goals**

- Gate 規格與變體差異各自收斂到單一維護處（block 檔與轉換規則檔），拷貝一律由生成器產出。
- 生成輸出仍為版本控制檔案；防漂移機制從「事後 diff 比對」改為「重新生成後 byte-identical 的 freshness 檢查」。
- 補上 `CASH-GLOSSARY.md` 與 `scripts/cash-skills/SKILL-LINT.md` 兩份維護參考文件。
- 將 gate 的真實源頭（block、generator、rules）納入受保護 grader 路徑集合。

**Non-Goals**

- 不改變 gate 行為語意；不做 runtime progressive disclosure；不動 `.cash-skills/` runtime 與 installer；不在本 change 改寫其餘十個 skill 的內文引用詞彙表。

## Decisions

**D1 — 生成方向與兩段式管線**：`.claude/skills/` 是變體權威源頭；gate 段落的權威在 `scripts/cash-skills/blocks/review-gate.md`。`scripts/cash-skills/generate.fish` 依序執行兩段：

1. **Gate 注入**：把 `scripts/cash-skills/blocks/review-gate.md` 內容注入 `.claude/skills/cash-propose/SKILL.md` 與 `.claude/skills/cash-apply/SKILL.md` 中以成對錨點註解 `<!-- REVIEW-GATE:BEGIN -->` 與 `<!-- REVIEW-GATE:END -->` 界定的區段。錨點置於「Sub-Agent Review/Rating/Fix Loop」步驟標題行之後，標題行（含其清單編號，propose 為 9.、apply 為 11.）不屬於 block，也不參與逐字比對。gate 文字含 cash-propose 與 cash-apply 的條件分支，故單一 block 可注入兩個 skill；注入前先統一 Context 所述的既有漂移——以 propose 版本為準，將 apply 兩檔的 `## What Changes` or `## Proposed Solution` 改為僅 `## Proposed Solution`，依據是 master spec「cash-propose 的 proposal 結構取自 CLI 單一來源」requirement 對 `## What Changes` 的全檔禁令，且 CLI-owned proposal 結構不含 `## What Changes` 段落，對 apply 語意安全。
2. **變體生成**：由 `.claude/skills/` 十二個 SKILL.md 生成 `.agents/skills/` 對應檔：frontmatter 移除 `context`、`agent`、`disallowedTools` 三個 key；移除 Claude fork 情境區段；invocation 前綴 `/cash-` 置換為 `$cash-`，置換沿用 `normalized_variant_diff` 既有的 token 邊界語意（前綴前一字元不得屬於 `[A-Za-z0-9_.-]`），路徑字面值內的 `/cash-` 不受置換；再套用 `scripts/cash-skills/variant-rules.yaml` 宣告的 per-skill patch（如 `cash-audit` 的 Codex standalone 流程）。

**D2 — variant-rules.yaml 承接可讀性義務**：每個有通用規則之外差異的 skill 在 `scripts/cash-skills/variant-rules.yaml` 有一個具名 entry，宣告其 patch 內容或轉換參數；規則檔為人可讀的宣告式格式。patch 以 marker／section 錨定（不以行號錨定，避免上游編輯使錨點失效）；generator 得以 python3 輔助解析規則檔與套用 patch（fish 無 YAML 解析能力）。python3 stdlib 不含 YAML 解析器，且回歸套件現況僅依賴 stdlib，因此 generator 內嵌一個 stdlib-only 的受限 YAML 子集讀取器，不引入第三方相依。該讀取器支援的形狀限於：巢狀 block mapping、scalar 或 mapping 的 block sequence、雙引號或裸 scalar，以及 `|` literal block scalar（body 內縮固定為 `parent_indent + 2`，不由首行推導，使本身帶前導空白的 patch 文字不被誤剝）。此範圍之外的形狀——flow mapping／sequence、單引號 scalar、anchor、alias、`>` folded block——MUST 以明確錯誤結束而非被當成字串接受；`skills:` 之下的每個鍵名 MUST 對應實際存在的 `.claude/skills/cash-*` 目錄，每個 entry 的鍵名 MUST 恰為 `description` 與 `patches`，否則同樣以明確錯誤結束。`scripts/cash-skills/variant-parity/` 的 8 個 diff manifest 移除。轉換規則的初始內容以現行 8 個 manifest 為依據轉寫；轉寫時 MUST 將 manifest 內被 `@cash-` placeholder 正規化的前綴還原為各側真實前綴。生成輸出必須重現現行 `.agents` 檔案內容；無法由通用規則加 per-skill patch 重現的差異，一律在實作時逐項人工裁決為「登記為 patch」或「視為既有漂移並修正」，並記入 implementation notes。

**D3 — freshness 檢查取代 parity 比對**：`skill-checks.fish` 移除 `assert_variant_parity`、`normalized_variant_diff` 與 divergent 清單，新增具名測試群組 `assert_generated_fresh`：把完整生成輸入集（十二個 `.claude/skills/` SKILL.md、`scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/variant-rules.yaml`）複製到暫存 root，對暫存 root 執行生成管線（`generate.fish` 接受 target-root 參數，預設 repo root），再與工作樹中 committed 的目標檔案逐檔 byte-compare，任何差異即失敗並指出檔案；測試本身不改寫工作樹。既有的良構斷言（空 code span、變體專屬 frontmatter）保留且不依賴生成機制。

**D4 — 治理延伸**：受保護 grader 路徑集合（定義於 gate 文字的 `<!-- GRADER-IMMUTABILITY -->` 區塊）加入 `scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`。此清單本身位於 gate 文字內，因此僅需修改 block 檔一處，由生成散播到四個 SKILL.md。

**D5 — 參考文件 schema**：`CASH-GLOSSARY.md` 每條詞彙為一個二級標題，內含定義、關係（指向相關詞彙）、avoid（不應使用的近義寫法）三部分；首批收錄 change、artifact、contract、deviation、blocker、touched state、parked、signal、round、cumulative blocking set、accepted risk、variant。`scripts/cash-skills/SKILL-LINT.md` 收錄六種失效模式（premature completion、duplication、sediment、sprawl、no-ops、negation），每條含定義、症狀、檢查問句。`CASH-SKILLS.md` 新增一節說明生成模型並連結兩份文件。

**D6 — 版本遞增與 receipt**：`cash-skills.version` 由 2.6.5 遞增至 2.7.0（結構性維護變更、無 workflow 行為變更，取 minor）。bump MUST 先於任何 SKILL.md 修改：`scripts/cash-skills/tests/test_bundle_version_history.py` 的 `check_history` 在工作樹版本未嚴格大於既有版本時，禁止任何 SKILL.md 相對其 introduction commit 變更；版本先領先，後續套件執行才可能通過。收尾以 `./install-cash-skills.fish --self` 重建 `.cash-skills/receipt.tsv`，使 receipt 的版本與 skill digests 反映 2.7.0（對應 signal `integrity-receipt-not-regenerated-after-runtime-change` 的既往結論）。

**D7 — 實作順序**：先 bump 版本，再統一既有 gate 漂移並驗證四份 gate 區段（標題行之後）在前綴正規化後逐字相同，然後抽 block、建 generator、切換測試（含 live namespace scan surface 同步）、移除 manifest，最後補文件並重建 receipt。

## Implementation Contract

1. `scripts/cash-skills/generate.fish` 存在且冪等：對乾淨工作樹連續執行兩次，第二次結束後 git 狀態無任何檔案變更。
2. 生成涵蓋十二個 skill；`.agents/skills/` 全部 SKILL.md 的 frontmatter 不含 `context`、`agent`、`disallowedTools`。
3. 四個 SKILL.md 的 gate 區段皆由 `scripts/cash-skills/blocks/review-gate.md` 生成，`<!-- REVIEW-GATE:BEGIN -->` 與 `<!-- REVIEW-GATE:END -->` 錨點在四檔中各成對出現恰一次且位於步驟標題行之後；四份 gate 區段（不含標題行）在 `/cash-*` 對 `$cash-*` 正規化後逐字相同。
4. 變更前後四份 gate 文字的 normalized diff 僅含三類差異：受保護 grader 路徑集合新增三個路徑、成對錨點註解、apply 兩檔的 `## What Changes` or `## Proposed Solution` 統一為 `## Proposed Solution`。
5. `scripts/cash-skills/tests/skill-checks.fish` 不再引用 `scripts/cash-skills/variant-parity/`；具名群組 `assert_generated_fresh` 存在並納入套件全量執行路徑；既有良構斷言群組保留。
6. `scripts/cash-skills/variant-parity/` 目錄自工作樹移除，且功能性引用面（兩處測試套件、`scripts/cash-skills/tests/test_live_namespace.py` 的 scan 枚舉、`CASH-SKILLS.md` 敘述）不再有對該目錄的引用；master spec 枚舉由 archive 置換、`@trace` provenance 屬歷史紀錄，均不在本條驗證範圍。
7. 生成後四個 SKILL.md 的 `<!-- GRADER-IMMUTABILITY -->` 區塊列出的受保護集合包含 `scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`。
8. `CASH-GLOSSARY.md` 收錄 D5 列舉的十二個詞彙，每條含定義、關係、avoid；`scripts/cash-skills/SKILL-LINT.md` 收錄六種失效模式，每條含定義、症狀、檢查問句；`CASH-SKILLS.md` 含指向兩者的連結（並註明 SKILL-LINT 為人工檢核維度、非阻斷性檢查）、更新後的所有權敘述（`.claude` 為權威源頭、`.agents` 為生成輸出）與更新後的 live scan 敘述。
9. `cash-skills.version` 內容為 2.7.0，且 bump commit 序位先於任何 SKILL.md 修改；`.cash-skills/receipt.tsv` 經 `./install-cash-skills.fish --self` 重建。
10. `scripts/cash-skills/tests/skill-checks.fish` 全套，與 `scripts/cash-skills/tests/`、`scripts/cash-cli/tests/` 兩處 python 測試套件執行通過。

## Risks / Trade-offs

- **首次生成不可重現現行 `.agents` 內容**：歷史手工維護可能存在 manifest 未涵蓋的細部差異。緩解：D2 規定逐項人工裁決並記入 implementation notes，不允許生成器靜默吞掉差異。
- **錨點註解破壞 spec 對 gate 文字的逐字錨定**：master spec 斷言的是 sentinel 與內容存在性，不是「無其他註解」；Contract 第 4 條以受控的三類差異鎖住語意不變。風險殘留在 skill-checks 對特定字串的行號級斷言，實作時以全套測試驗證。
- **`grader_hash` byte-identity 約束**：`skill-checks.fish` 對四檔 `<!-- GRADER-IMMUTABILITY -->` 至 `<!-- LOOP-LEDGER-STEP -->` 子區段做不經前綴正規化的 raw byte SHA-256 跨檔斷言，因此 block 該子區段內不得引入任何 invocation 前綴差異或每檔不同的內容（現行該子區段僅含路徑字面值、無前綴，注入後仍四檔 byte 相等）。
- **freshness 檢查在 fish/coreutils 環境差異下誤報**：生成器輸出一律以 LF 與 UTF-8 寫出，byte-compare 不做任何正規化，冪等性由 Contract 第 1 條直接測試。
- **`skill-checks.fish` 與四個 SKILL.md 均為受保護 grader 檔案**：本 change 已在 proposal `## Impact` 以結構化範圍宣告指名，review loop 的修正動作合法；但 gate 行為語意仍以 Contract 第 4 條凍結，避免以「維護重構」之名夾帶 gate 規則變更。
- **取捨**：build-time 生成保留了 SKILL.md 呼叫時完整載入的 context 成本（放棄 runtime 拆檔的節省），換取 master spec 內容錨定 requirement 的最小 churn 與執行期行為零變更。
