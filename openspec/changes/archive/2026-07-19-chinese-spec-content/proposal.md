## Summary

將 spec 檔案（delta spec 與 master spec）的內容語言從全英文改為「繁體中文內文 + 英文結構關鍵字」，一次性遷移三份既有 master spec，並補上 Requirement 標題身分鍵的機械防護。

## Motivation

目前 spec 檔案全文英文，對以中文為主的維護流程來說可讀性差，review 與修改 spec 時的理解成本高。實驗已證實 spectra CLI 完全接受中文內文（`spectra validate --strict` 通過、archive 合併正確），語言限制purely是 skill 規則層的政策，不是 CLI 限制。

同時實驗發現一個未被防護的陷阱：delta spec 的 MODIFIED/REMOVED 是以 Requirement 標題逐字比對 master spec 來合併，標題不吻合時 `spectra validate` 照樣通過、`spectra archive` 靜默輸出 `modified: 0`，修改內容被無聲丟棄。改為中文後「標題被重打或翻譯」的風險上升，需要一併補上機械防護。這也是 open signal `modified-requirement-undeclared-rewrite`（已發生 2 次）的根治方向。

## Proposed Solution

1. **語言政策**：spec 檔內文（Requirement 敘述、Scenario 步驟、Example 說明、Purpose）改用繁體中文；結構關鍵字逐字保留英文：`## ADDED Requirements`、`## MODIFIED Requirements`、`## REMOVED Requirements`、`## RENAMED Requirements`、`### Requirement:`、`#### Scenario:`、`##### Example:`、`**GIVEN/WHEN/THEN/AND**`；規範動詞 SHALL/MUST/SHOULD/MAY 以英文嵌入中文句子。程式識別字、檔案路徑、CLI 指令、引用原文一律 verbatim。
2. **標題也中文化**：Requirement 標題（合併身分鍵）一併使用中文，配套規定 MODIFIED/REMOVED/RENAMED（FROM）標題必須從現行 master spec 逐字複製，不得重打或翻譯。
3. **一次性遷移**：將三份既有 master spec（cash-skill-workflows、signals-shared-layer、spectra-plus-skills）的標題與內文遷移為中文，識別字與引文保持 verbatim。遷移採「宣告式直接編輯」而非 MODIFIED delta——因為本 change 會把 master 標題翻成中文，若同時用英文標題的 MODIFIED delta，archive 合併時將因標題不吻合而被靜默丟棄（排序陷阱）。既有的「keep spec files in English」條款（openspec/specs/cash-skill-workflows/spec.md 第 222 行附近）在遷移中一併宣告式改寫為新政策。
4. **機械防護**：在 cash-propose / cash-apply 共用的 pre-round mechanical self-check 加入「spec delta 標題身分鍵檢查」：delta 中每個 MODIFIED/REMOVED（及 RENAMED 的 FROM）標題必須逐字存在於對應 master spec，不吻合視為 self-check 失敗，必須在 spawn reviewers 前修復。
5. **skill 與測試同步**：改寫 6 份 SKILL.md（.claude 與 .agents 的 cash-propose、cash-apply、cash-ingest）的 spec 語言例外條目（各檔實際措辭見 design C1 逐檔列舉）；更新 scripts/cash-skills/tests/skill-checks.fish 的對應字面斷言；bump cash-skills.version；如 parity diff 行號位移則重生。

## Non-Goals

- 不翻譯 openspec/changes/archive/ 下的歷史 delta spec 與歷史 artifacts——它們是歷史紀錄。
- 不修改任何 signal 檔案的內容、status 或 check 欄位（`modified-requirement-undeclared-rewrite` 的 status 由人維護）。
- 不修改 spectra CLI 本身的驗證或合併行為；防護實作在 skill 規則層。
- 不修改上游 spectra-\* skill 檔（屬 Spectra CLI 再生成範圍）；spec 工作以 cash-\* skill 為入口，殘餘風險記載於 design Risks。
- 不在本 change 為 cash-archive 增加 archive 端檢查（留作 follow-up change；殘餘繞過路徑記載於 design Risks）。
- 不改變 round file、tasks、design 等非 spec artifacts 的既有語言規則（已是中文）。
- 不引入「標題仍保留英文」的混合方案（已評估並否決，見 design）。

## Alternatives Considered

- **標題保留英文、僅內文中文**：零遷移風險，但半英半中的標題違背可讀性初衷，且既有標題長句化後仍難讀。否決。
- **漸進式遷移（改到哪翻到哪）**：會產生長期中英混雜的 master spec，且 MODIFIED 標題在混雜期間更容易誤植。否決。
- **把標題比對防護做成帶 check 的 signal**：signals-shared-layer spec 規定 check 欄位必須由人撰寫（human-authored），由本 change 自動產生會違反該 spec；且防護屬於每次 review 都必跑的 gate 行為，放在 mechanical self-check 更符合定位。否決。

## Impact

- Affected specs: cash-skill-workflows（ADDED 語言政策與標題身分鍵防護兩條 requirements；遷移為中文為宣告式直接編輯）
- Affected code:
  - Modified: openspec/specs/cash-skill-workflows/spec.md
  - Modified: openspec/specs/signals-shared-layer/spec.md
  - Modified: openspec/specs/spectra-plus-skills/spec.md
  - Modified: .claude/skills/cash-propose/SKILL.md
  - Modified: .claude/skills/cash-apply/SKILL.md
  - Modified: .agents/skills/cash-propose/SKILL.md
  - Modified: .agents/skills/cash-apply/SKILL.md
  - Modified: .claude/skills/cash-ingest/SKILL.md
  - Modified: .agents/skills/cash-ingest/SKILL.md
  - Modified: scripts/cash-skills/tests/skill-checks.fish
  - Modified: scripts/cash-skills/variant-parity/cash-propose.diff（條件式：僅在 hunk 行號位移時重生）
  - Modified: scripts/cash-skills/variant-parity/cash-ingest.diff（條件式：僅在 hunk 行號位移時重生）
  - Modified: cash-skills.version
