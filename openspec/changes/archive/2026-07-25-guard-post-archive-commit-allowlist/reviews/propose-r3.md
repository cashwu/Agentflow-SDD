# Cash Propose Review — Round 3

## Reviewer Findings

本輪為 micro round，spawn 一個 Reviewer V — Verification，context 含第 1、2 輪 round file 全文、當前累積 blocking 集合的唯一成員 M6、artifact 路徑與相關 `open` signals。`openspec/changes/guard-post-archive-commit-allowlist/reviews/accepted-risks.md` 不存在。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M6 任務 3.2 驗收在指定時點不可達（Warning，`fix-introduced`） | resolved | `tasks.md` 任務 3.2 驗證目標已改為單一檔案的十個字面句逐字 `rg -F` 檢查加 `skill-checks.fish variant-parity`，並明寫整組 `codex-command-matrix` 的通過由任務 4.2 承接；`design.md` C4 另把該修法升級為通則。Reviewer V 實測 `skill-checks.fish` 第 321–322 行 `case variant-parity` 只呼叫 `assert_variant_parity`、不觸及 `assert_command_matrix`，且 `commit` 與 `apply` 皆不在 `divergent_skills`，確認該驗收在任務 3.2 的時點可達。 |

累積 blocking 集合在本輪清空，verifying reviewer 為本輪的 Reviewer V。

### Suggestion

本輪五筆 findings 全部在信心過濾後為 `Suggestion`（`confidence ∈ [50, 80)`），皆為非 blocking，且皆已於本輪修復：

- `confidence`: 60 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策七，第 2 輪擴寫為「必須真的進入提交集合」後無條件語意被固化 — 決策七與 C2 把 digest 相等規則寫成無條件，但 spec scenario 以 `specs_synced` 為 true 為 GIVEN；`--skip-specs` 的封存其 `master_digests` 記錄的是未經 sync 的封存當下 digest，同一規則反而會把封存前就存在的第三方 dirty 編輯納入提交。
- `confidence`: 60 / `layer`: design（Reviewer V 原判 `text`，主 agent 依「修復可能影響行為或設計陳述即重分類為 design」上修）/ `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪對 M6 的修復（把個案修法升級為 C4 通則） — C4 通則寫成「在此之前的每個 task MUST 以單一檔案的 `rg -F` 為驗證目標」，未替以整組失敗為紅燈目標的任務 1.2 留例外，形成 design 與 tasks 的字面矛盾。
- `confidence`: 55 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪把首次 receipt 重建併入任務 2.1 的修復 — 任務 2.2 退化為不改動任何檔案的純常規宣告，其驗證目標在任務 2.1 收尾後已必然成立，無法驗證該常規本身。
- `confidence`: 52 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策七 — C2 只要求逐字含 `master_digests`，未載明「目前 digest」的計算方式，SKILL.md 的執行者無從得知演算法，該判定實質不可執行。
- `confidence`: 50 / `layer`: text / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪對「spec sync 判定無承接步驟」的修復（該輪只改 design／tasks／spec，未改 proposal） — 獨立 `### Spec Sync Changes` 區段與三者聯集的 Unrelated 判定兩個使用者可見概念未同步回 proposal 的 `## Proposed Solution`。

Reviewer V 另逐項確認並回報無 finding 的檢查：五組第 2 輪概念的傳播完整、全篇無殘留「八個字面句」與寫死版本常數、十個 cash-commit 與兩個 cash-apply 字面句與 C2／C3 的 MUST 一一對應、十個任務的驗收在各自時點皆可達、`[P]` 的任務 1.1 與 1.2 無共用檔案、三組 Non-Goal 與新增決策不衝突、`## Impact` 的 8 條 Modified 與 design／tasks 實際改動集合完全一致、spec 與 design／tasks 雙向背書完整無孤兒。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：0
- 非 blocking triaged finding 數：5
- `critical_gap`：false
- `round_type`：micro
- 理由：唯一的累積 blocking 集合成員 M6 經 Reviewer V 裁定 `resolved` 並附實測依據後離開集合，集合清空。本輪五筆新 findings 的 `confidence` 全部落在 `[50, 80)`，過濾後皆降級為 `Suggestion`，依規則為非 blocking，不造成 `next_round`。通過條件成立，決策為 `passed`。

## Fix Actions

本輪決策為 `passed`，通過條件已成立，五筆非 blocking 的 `Suggestion` 並非通過的前提；但它們皆為低風險的對齊性修正（不引入任何新機制、不改變已定案的判定結構），故一併修復以免把已知缺口留給實作階段。修改檔案：`openspec/changes/guard-post-archive-commit-allowlist/design.md`、`tasks.md`、`proposal.md`、`specs/cash-skill-workflows/spec.md`（共 4 個檔案）。

- spec sync 判定的無條件語意：決策七補上「此判定 MUST 以 manifest 的 `specs_synced` 為 true 為前提」與 `--skip-specs` 情形的具體失效說明，並明訂為 false 時所有 `openspec/specs/` 路徑一律留在 Unrelated；C2 的對應要素同步；spec 新增 scenario「specs_synced 為 false 時不納入任何 spec 路徑」；proposal 的 Proposed Solution 同步。
- C4 通則未替紅燈任務留例外：該句改為「在四個 SKILL 檔全部改完之前，任何**以通過為驗收**的 task MUST 以單一檔案的 `rg -F` 為驗證目標；以整組失敗為紅燈目標的 TDD 任務不受此限」。
- 任務 2.2 退化：移除任務 2.2，把 receipt 常規升格為 design C4 的全域約束，並把「最後一次重建」的時點約束直接寫進任務 5.2；`tasks.md` 全篇不再有指向任務 2.2 的參照。
- digest 計算方式未載明：決策七與 C2 補上「目前 digest 為該檔案內容的 sha256 hexdigest，與 `spec_merge.py` 的 `digest()` 一致」，並要求 `2a` 指明比對手段（例如 `shasum -a 256`）；tasks 任務 3.1 的內容清單同步。
- proposal 未同步：`## Proposed Solution` 第二節補上三者聯集的 Unrelated 判定與獨立 Spec Sync Changes 區段。

disposition 更正紀錄：本輪無 `new` 標籤需要更正；Reviewer V 對五筆 findings 皆已標為 `fix-introduced` 並附 `introduced_by`。主 agent 對第二筆做了 `layer` 上修（`text` → `design`），因其修復會改變 design 對任務驗收方式的陳述。

fix 傳播：`specs_synced` 前提、digest 演算法、C4 紅燈例外、receipt 常規升格、proposal 同步五個概念，都同時檢查了 design 決策段、C2／C4 清單、tasks 任務、spec scenario 與 proposal 五個位置。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--`／`-->` 皆為 0、無殘留 `---` 分隔線）通過；數量一致性（決策共 10 條、`## Impact` 的 Modified 為 8 條、cash-skill-workflows delta 共 11 個 scenario、cash-cli delta 共 3 個 scenario、任務編號為 1.1／1.2／2.1／3.1／3.2／4.1／4.2／5.1／5.2／5.3 且無斷鏈參照）通過；殘留字串掃描（`任務 2.2`、`八個字面句`）為 0 命中；delta 皆為 `## ADDED Requirements`，spec delta title-identity check 不適用；`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal。

修復後重跑 `.cash-skills/bin/cash validate guard-post-archive-commit-allowlist`：通過。

## Decision

passed
