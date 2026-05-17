## Context

本專案目前同時存在兩套 SDD 流程：

- **Spectra**：依賴 `spectra` CLI、artifact 存於 `openspec/changes/<change>/`、品質閘為「inline self-review + analyze-fix loop（max 2 iter）」，由主 agent 自查。
- **Agentflow-SDD**：自封閉 9 步流程、artifact 存於 `agentflow/changes/<change>/`、每步皆有「fresh sub-agent review/rating/fix loop（max 3 round、quality_score > 9/10 且 no critical gap）」，並把每輪結果存成 `agentflow/reviews/` 下的 md 檔。

使用者希望保留 Spectra 工作流的優勢（CLI 驗證、artifact 結構、analyze），同時引入 Agentflow 的 sub-agent 品質閘，並把上限放寬到 6 round 以補償 per-change 粒度（一次性 review，而非 per-artifact / per-task）。

目前 spectra-propose 的工作流末段包含「步驟 8 inline self-review」、「步驟 9 analyze-fix loop（max 2）」、「步驟 10 validate」、「步驟 11 park」。spectra-apply 流程跑完所有 task 後即結束。plus 變體需在這幾個固定位置注入新行為。

## Goals / Non-Goals

**Goals:**

- 提供 `spectra-propose-plus` 與 `spectra-apply-plus` 兩支 skill，行為與原版幾乎相同，但品質閘改為 sub-agent review/rating/fix loop。
- Plus skill 由 generator 從原 spectra skill + template + rules 產生，不手寫維護；spectra 上游改版時重跑 generator 即可重建 plus。
- Generator 在偵測到上游結構變化（注入點找不到、原段落不存在）時立即報錯，不嘗試自動修復。
- 每一 round 都有獨立 sub-agent 執行 review 與 rating，產出對應 md 檔案，整個過程可審計、可重現。
- `spectra-propose-plus` 流程結束後**不 park**，直接結束（與原版差異點）。

**Non-Goals:**

- 不取代原 spectra-propose、spectra-apply：兩者繼續存在。
- 不為其他 spectra-* skill（discuss、ingest、archive、ask、analyze、audit、commit、debug、drift、verify）產生 plus 版。
- Generator 不做自動 merge，不嘗試 line-by-line 對齊上游變更。
- 不支援手改已生成的 plus skill 並回流到 generator；plus 是單向 derived artifact。

## Decisions

### Generator-driven 而非 fork-and-sync

Plus skill 是 derived artifact，由 generator 從 spectra skill 產生。每次 spectra 改版只要重跑 generator，不維護 diff/patch。理由：

- 替代方案：fork & manual sync。每次 spectra 改版要人工 diff 出變更、合進 plus、解衝突——維護成本隨上游改版次數線性成長。
- generator-driven 把「plus 與 spectra 的差異」集中在 template + rules 兩個檔案，差異本身變成 first-class artifact，可審查、可版控、可重現。
- 失敗模式（注入點找不到）由 generator 顯式報錯，逼使人工檢視 rules，避免「靜默產出壞 plus」。

### Generator 拆檔：script / template / rules

主程式（generate script）只負責讀規則、套用轉換、寫檔，不嵌入任何業務文字。注入段落寫在 template 檔，每支 skill 的注入點與 metadata 變動寫在 rules.yaml。理由：

- 替代方案 A：規則內嵌在 script（硬寫 sed/regex）。Review/rating 段落上百行，混在 script 裡難維護；改評分標準、調 round 上限都要改 script。
- 替代方案 B：plus skill 用 m4 / handlebars 等 templating engine。需引入額外依賴、增加學習成本，不值得。
- 採 template + rules.yaml 拆檔：所有業務文字在 template、所有 skill 級差異在 rules.yaml，script 是純執行器、應該很穩定。

### 注入策略：marker-based section replacement

Generator 識別原 spectra skill 中要替換或追加的位置，採用「具名 marker section」而非「行號」或「fuzzy match」。Rules.yaml 為每個 plus skill 指定一組轉換項，每項聲明：

- `target_section`：原 skill 中要操作的小節標題（例如 `## Steps` 下的 `8. **Inline Self-Review**`）。
- `operation`：`replace`、`append`、`remove` 三種之一。
- `template`：要套用的 template 檔名（僅 `replace`、`append` 需要）。
- `metadata`：要覆寫的 frontmatter 欄位（name、description、version 等）。

若 `target_section` 在原 skill 找不到，generator 直接退出並印出錯誤，不嘗試模糊匹配。

### Review/rating/fix loop 粒度：per-change、max 6 round

兩支 plus skill 均採「**先完成所有 artifact / task → 一次性 review/rating/fix**」的粒度。理由：

- 替代方案：per-artifact（propose 對 proposal、design、spec、tasks 分別 review）或 per-task（apply 每完成一個 task 跑一次 review）。
- per-change 效率高、整體耗用 token 少；以 6 round 補償降低的 granularity（原本 Agentflow 是 max 3）。
- 風險：第 6 round 才發現 proposal 寫錯會牽動下游全部重做。緩解：在 review 階段優先檢查 proposal-level scope，發現 scope 錯誤可中止並回到 discuss。

### Round md 檔輸出契約

每一 round 產出 `openspec/changes/<change>/reviews/<skill>-r<round>.md`，固定欄位包括：

- `round`：整數。
- `reviewer_findings`：列出 Critical / Warning / Suggestion，每項含位置（artifact、section）、描述、影響。
- `rating`：`quality_score`（0-10）、`critical_gap`（boolean）、`rationale`（一段文字）。
- `fix_actions`：本 round 做了哪些修正、改了哪些檔案、為何這樣改。
- `decision`：`passed` / `next_round` / `aborted`。

第一個 round 一定有 reviewer_findings + rating + fix_actions（除非 round 1 就 passed）。最終 round 的 fix_actions 可空，但 decision 必須是 `passed`（quality_score > 9 且 no critical gap）或 `aborted`（6 round 仍未過）。

### Sub-agent 分工：reviewer 與 rater 分離

每 round spawn 兩隻 sub-agent：

- **Reviewer**：讀所有 artifact / diff / test 結果，產出 findings（Critical/Warning/Suggestion），不評分。
- **Rater**：讀 findings + artifact，產出 quality_score 與 critical_gap，提供 rationale。

理由：分離是為了避免「同一 agent 既挑錯又給分」的偏差。Rater 只看 reviewer 給的 findings 並獨立評估嚴重程度。每 round 兩隻都重新 spawn，不重用前一 round 的 sub-agent。

### `spectra-propose-plus` 不 park

原 spectra-propose 步驟 11 會無條件 park。Plus 變體刻意 **不 park**，直接結束流程。理由：

- 使用者明確指示。
- Plus 流程已含 6 round 嚴格品質閘，artifact 完成度比原版更高，不需要 park 等使用者最終確認。
- 若使用者仍想 park，可在 plus 結束後手動執行 `spectra park <change>`。

### Generator 實作語言

採用 fish shell（與既有的 `install-agentflow-sdd.fish` 一致），輔以 `yq` 或 `awk` 解析 YAML 與處理 markdown section。理由：

- 替代方案 Python / Node：增加額外執行環境依賴，與專案現有工具鏈不一致。
- fish + yq 已是專案既有工具鏈，零新增依賴。
- Generator 邏輯只是「讀 YAML、找 section、替換、寫檔」，shell 足夠。

## Implementation Contract

### Generator script

- **可觀測行為**：
  - 執行 `scripts/spectra-plus/generate.fish` 不帶參數時，重新產生 `spectra-propose-plus` 與 `spectra-apply-plus` 兩支 skill。
  - 執行 `scripts/spectra-plus/generate.fish <skill-name>` 只重新產生指定的 plus skill。
  - 成功時印出每支被覆寫的 SKILL.md 路徑與校驗結果。
  - 失敗時印出失敗的 skill、未匹配到的 target_section、原 spectra skill 對應路徑。
- **介面/資料形狀**：
  - 輸入：`.claude/skills/spectra-{propose,apply}/SKILL.md`、`scripts/spectra-plus/rules.yaml`、`scripts/spectra-plus/template/*.md`。
  - 輸出：`.claude/skills/spectra-{propose,apply}-plus/SKILL.md`，每檔首行加註 `<!-- Generated by scripts/spectra-plus/generate.fish — DO NOT EDIT MANUALLY -->`。
  - 結束碼：成功 0，section 找不到 1，rules.yaml 解析失敗 2，template 缺檔 3。
- **失敗模式**：
  - rules.yaml 中 `target_section` 在原 spectra skill 找不到 → 退出碼 1，列出找不到的 section 名稱。
  - template 檔名在 rules.yaml 有列、但 `scripts/spectra-plus/template/` 下不存在 → 退出碼 3。
  - frontmatter 覆寫欄位導致 SKILL.md 變不合法（缺 name / description）→ 退出碼非 0、列出問題欄位。
- **驗收標準**：
  - 重跑 generator 兩次，產出的 SKILL.md 必須位元組相同（idempotent）。
  - 故意刪掉原 spectra-propose 中某個 `target_section` 並重跑，必須在 stderr 報錯且 exit code != 0。
- **驗證目標**：
  - `scripts/spectra-plus/generate.fish` 執行成功並產生兩支 plus skill。
  - 對產生出的 SKILL.md 做 frontmatter 解析測試（name = `spectra-propose-plus` / `spectra-apply-plus`）。
  - 故障注入測試：刪除一個 target_section、重跑、確認 exit code 非 0。
- **不在範圍**：自動修補 rules.yaml、自動偵測 spectra 上游新增章節並提示。

### spectra-propose-plus 行為

- **可觀測行為**：
  - 流程前段（步驟 1-7：建 change、寫 proposal、建 design/specs/tasks）與原 spectra-propose 行為一致。
  - 流程後段：將原 spectra-propose 的「步驟 8 inline self-review」與「步驟 9 analyze-fix loop」**整段替換**為 sub-agent review/rating/fix loop（max 6 round）。
  - 流程末端：執行 `spectra validate <change>`，然後**不執行 `spectra park`**，直接顯示完成 summary 後結束。
- **介面/資料形狀**：
  - Skill 名稱：`spectra-propose-plus`。
  - 觸發方式：`/spectra-propose-plus <requirement description>`。
  - 每 round 產出檔案：`openspec/changes/<change>/reviews/propose-r<N>.md`（N 從 1 起算）。
  - Round md 檔欄位：`round`、`reviewer_findings`、`rating`、`fix_actions`、`decision`（如「Round md 檔輸出契約」決策段）。
- **失敗模式**：
  - 6 round 內未達 quality_score > 9 且 no critical gap → 最後一份 round 檔 `decision: aborted`，skill 顯示警告但仍結束流程（artifact 已寫入、change 已存在，由使用者決定如何處理）。
  - Reviewer 或 rater sub-agent 失敗（無回應、回傳格式錯）→ 整個 round 視為失敗，重新 spawn 一次；連續兩次失敗則整個 plus skill 退出並標記為 abort。
- **驗收標準**：
  - 全程不執行 `spectra park`。
  - 每跑滿一 round 必有對應 `propose-r<N>.md` 寫入，欄位齊全。
  - Reviewer 與 rater 是兩次獨立的 sub-agent 呼叫。
- **驗證目標**：
  - 用一個小型測試 change 跑完 `spectra-propose-plus`：確認 `openspec/changes/<change>/reviews/` 有至少一份 round 檔，且該 change 仍處於 active（未 park）。
  - 確認 sub-agent 呼叫紀錄中 reviewer 與 rater 是兩次獨立呼叫。
- **不在範圍**：per-artifact review（propose 內細到 proposal/design/spec/tasks 各跑一輪）。

### spectra-apply-plus 行為

- **可觀測行為**：
  - 流程前段：跑完原 spectra-apply 的所有 task 實作行為。
  - 流程後段：所有 task 完成後追加 sub-agent review/rating/fix loop（max 6 round）。
  - 流程末端：原 spectra-apply 不 park、不 archive，plus 行為一致，僅追加 review。
- **介面/資料形狀**：
  - Skill 名稱：`spectra-apply-plus`。
  - 觸發方式：`/spectra-apply-plus <change-name>`。
  - 每 round 產出檔案：`openspec/changes/<change>/reviews/apply-r<N>.md`，欄位同 propose-plus。
- **失敗模式**：
  - 6 round 未達標 → 最後一份 round 檔 `decision: aborted`，skill 顯示警告並結束。實作 code 已寫入、tasks.md 已標 `[x]`。
  - Sub-agent 連續兩次失敗 → 整個 plus skill 退出並標記 abort。
- **驗收標準**：
  - 所有 task 必須先全部完成（tasks.md 全 `[x]`）才進入 review loop。
  - 每跑滿一 round 必有 `apply-r<N>.md`。
- **驗證目標**：
  - 用一個小型測試 change 執行 `spectra-apply-plus`，確認 task 全 `[x]` 且 reviews/ 下有 apply round 檔。
- **不在範圍**：per-task review（每個 task 完成就 review 一次）。

### Round md 檔格式（兩支共用）

- **可觀測行為**：固定欄位、固定排序，可被後續工具自動解析。
- **介面/資料形狀**（以 propose-plus 為例）：
  - 路徑：`openspec/changes/<change>/reviews/propose-r<N>.md`。
  - Markdown 結構：
    - `# Propose Plus Review — Round <N>`
    - `## Reviewer Findings`（Critical/Warning/Suggestion 三個子標題）
    - `## Rating`（含 quality_score、critical_gap、rationale）
    - `## Fix Actions`（列每個修正與修改檔案）
    - `## Decision`（passed / next_round / aborted）
- **失敗模式**：欄位缺漏 → 視為 round 寫入失敗，重新請 sub-agent 補完。
- **驗收標準**：每份 round md 檔均含五個固定 section、可被 grep 找到固定標題。
- **驗證目標**：對任一 round 檔執行 `grep -c "^## "` 應回傳 5。
- **不在範圍**：HTML / JSON 等其他格式輸出。

### rules.yaml schema

- **可觀測行為**：可被 generator 解析；新增一支 plus skill 只要在 rules.yaml 加一筆條目（雖然第一版不開放此功能）。
- **介面/資料形狀**：
  ```yaml
  skills:
    spectra-propose-plus:
      source: .claude/skills/spectra-propose/SKILL.md
      output: .claude/skills/spectra-propose-plus/SKILL.md
      metadata:
        name: spectra-propose-plus
        description: <new description>
      transformations:
        - target_section: "8. **Inline Self-Review**"
          operation: replace
          template: review-loop-block.md
        - target_section: "9. **Analyze-Fix Loop**"
          operation: remove
        - target_section: "11. **Park the change and end the workflow**"
          operation: replace
          template: no-park-end-block.md
  ```
- **失敗模式**：欄位缺漏（無 source / output / transformations）→ generator 退出碼 2。
- **驗收標準**：rules.yaml 為 generator 唯一變更入口；新增 plus skill 不需改 generator script。
- **驗證目標**：對 rules.yaml 跑 `yq` parse，確認結構合法。
- **不在範圍**：rules.yaml 的 schema 驗證工具（單純 yq parse 通過即可）。

## Risks / Trade-offs

- [上游 spectra-propose 結構大改（章節編號變、合併、新增中間步驟）] → Generator 失敗報錯，需要人工檢視並更新 rules.yaml 的 `target_section`。緩解：rules.yaml 內每個 transformation 都有清楚 comment，方便對照 spectra 原檔；錯誤訊息明確指出哪個 section 找不到。
- [Per-change 粒度錯過 proposal-level 的早期錯誤] → Review sub-agent 在第一輪優先檢查 scope/proposal，若發現 scope 錯誤，可在 fix_actions 階段直接中止並標記 `decision: aborted` 給使用者，避免空轉到第 6 round。
- [Sub-agent 6 round 累積 token 成本高] → 接受此成本作為品質代價；若實務發現平均常跑滿 6 round，再考慮降回 3-4 round 或回退到 per-artifact。
- [Reviewer 與 rater 分離但仍是同模型 → 偏差未完全消除] → 接受此限制；分離雖無法消除模型一致性偏差，但能避免「自評」捷徑思考（rater 必須讀 findings、寫 rationale）。

## Open Questions

- Sub-agent 的具體 prompt 文字（reviewer prompt、rater prompt）由 spec 階段定稿，不在 design 階段固定。
