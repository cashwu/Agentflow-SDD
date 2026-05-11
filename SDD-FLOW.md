# Agentflow-SDD 流程

本專案在 Spectra 原生 SDD 流程上，加了一層專案自有的 Agentflow-SDD overlay。目標是保留 Spectra 的 artifact/state 管理，同時把演講中提到的 Discuss、Explore、Prototype、Usage/API Contract、Review/Rating/Fix gate 納入日常開發流程。

## 核心原則

- 不直接修改 generated `spectra-*` skills。
- 專案自有規則放在 `sdd-*` skills、`openspec/config.yaml`、以及 `AGENTS.md` / `CLAUDE.md` 的非 generated 區塊。
- Spectra 負責 artifacts、狀態、驗證與 archive。
- Agentflow-SDD overlay 負責需求釐清、風險探索、prototype 判斷、artifact 品質門檻與實作前審查。

## 日常入口

非 trivial 的功能、修正、重構，優先使用：

```text
$sdd-agentflow
```

Claude 版本對應：

```text
/sdd-agentflow
```

很小的 typo、純查詢、或只需要看既有 spec 的情況，可以直接用 `$spectra-ask` 或一般 Spectra skill。

## 兩層流程

### 第一層：Agentflow-SDD Overlay

```text
Discuss
→ Explore
→ Prototype Decision
→ Map To Spectra
→ Review / Rating / Fix Gate
→ Apply
→ Review And Wrap
```

### 第二層：Spectra 原生流程

```text
$spectra-discuss? → $spectra-propose → $spectra-apply ⇄ $spectra-ingest → $spectra-archive
```

Agentflow-SDD 會先把需求、風險與設計品質整理好，再交給 Spectra 產生或更新 artifacts。

## Step 文件輸出契約

每個 Agentflow-SDD step 都要輸出或更新對應文件。對於 active Spectra change `<change>`，文件放在：

```text
openspec/changes/<change>/agentflow/
```

固定檔名如下：

| Step | 文件 |
| --- | --- |
| Discuss | `01-discuss.md` |
| Explore | `02-explore.md` |
| Prototype Decision | `03-prototype.md` |
| Map To Spectra | `04-spectra-map.md` |
| Review / Rating / Fix Gate | `05-review-rating.md` |
| Apply | `06-apply-notes.md` |
| Review And Wrap | `07-wrap-review.md` |

這些是支援文件，不取代 Spectra 的 `proposal.md`、`design.md`、`spec.md`、`tasks.md`。它們用來保存每個 step 的判斷、證據、分數、修正紀錄與交接脈絡。

如果 change 還沒建立，先在回覆中保留 step output；一旦 `$spectra-propose` 建立 change，就把內容補進 `agentflow/` 目錄。

## Agentflow-SDD 步驟

### 1. Discuss

先釐清需求，不急著寫 code。

需要整理：

- Goal
- Non-goals
- Assumptions
- Open questions
- Observable success examples
- 可能受影響的 specs 或 code

如果資訊不足但不阻塞安全推進，先明確列出假設並繼續；只有在合理假設風險太高時才詢問使用者。

輸出：`01-discuss.md`

### 2. Explore

在寫正式 spec 或 tasks 前，先檢查既有 specs/code，並從多個角度找風險：

- Product / domain behavior
- Architecture and data flow
- Security, privacy, and secret handling
- UI/UX and accessibility
- Performance and reliability
- Testability and observability
- Platform, browser, OS, SDK, or dependency constraints

每個 finding 都要變成設計限制、spec requirement、task，或明確列為 non-goal。

輸出：`02-explore.md`

### 3. Prototype Decision

判斷是否需要 throwaway prototype / spike。

適合 prototype 的情況：

- 外部 API、瀏覽器行為、模型輸出、檔案格式或平台能力不確定。
- 資料結構或演算法可能在真實資料量下失敗。
- 一旦正式實作錯方向，回頭成本很高。

Prototype 只保留學到的結論，不直接視為 production implementation。若要保留 prototype code，必須明確轉成正式 task。

輸出：`03-prototype.md`

### 4. Map To Spectra

把前面結果轉入 Spectra artifacts：

- `proposal.md`：Discuss summary、動機、scope、non-goals、受影響 specs、主要風險。
- `design.md`：Explore Findings、Prototype Findings、Working Backwards Usage/API Contract、Implementation Contract、tradeoffs。
- `spec.md`：可測、具 normative language 的 requirements 與 scenario examples。
- `tasks.md`：小而明確的實作任務，每個 task 都有 observable outcome 與 verification target。

新 change 使用：

```text
$spectra-propose
```

更新既有 change 使用：

```text
$spectra-ingest
```

輸出：`04-spectra-map.md`

### 5. Review / Rating / Fix Gate

進入 `$spectra-apply` 前，先用 1 到 10 分檢查 artifacts。

評分面向：

- Requirement fidelity
- Risk coverage
- Prototype learning 是否有被捕捉，或是否有合理跳過理由
- Usage/API contract clarity
- Spec testability
- Task handoff quality
- Scope boundaries
- Verification strength

通過標準：

- 分數至少 9/10。
- 沒有 critical gap。
- 沒有 placeholder、模糊 task、互相矛盾的 artifact、或缺少 verification target。

Review/Fix 最多 3 輪：

1. 第 1 輪：review、rating，自動修正所有非 blocking 問題。
2. 第 2 輪：重新 review、rating，自動修正剩餘非 blocking 問題。
3. 第 3 輪：重新 review、rating；若仍低於 9 分或仍有 critical gap，就停止並列出 blockers。

Critical gap 不允許強行通過。Critical gap 包含安全/隱私要求缺失、需求互相矛盾、user-visible 行為沒有驗證方式、task 必須靠猜才能實作等。

未通過時，先修 artifacts，再重新 review。第 3 輪後仍未通過，就請使用者決策、縮小 scope，或補齊需求。不要直接進 apply。

輸出：`05-review-rating.md`，每一輪都要記錄 score、rubric、findings、已修正項目、剩餘 blockers、最終 pass/fail。

### 6. Apply

Artifacts 通過 gate 後才進入：

```text
$spectra-apply
```

實作時：

- 每個 task 前先重讀相關 spec 與 Implementation Contract。
- 若 `.spectra.yaml` 啟用 `tdd: true`，先寫或更新測試，再寫 production code。
- 完成 task 前必須跑過 task 指定的 verification target。
- 如果實作中發現 design/spec 問題，先回到 `$spectra-ingest` 更新 artifacts，不要默默偏離。

輸出：`06-apply-notes.md`

### 7. Review And Wrap

實作完成後：

- 比對 diff 是否符合 proposal、spec、design contracts、tasks。
- 跑相關測試。
- 跑 Spectra analyze / validate。
- 確認 artifact 與 implementation 一致後，再 archive。

```text
$spectra-archive
```

輸出：`07-wrap-review.md`

## Spectra 更新後的維護流程

如果升級 Spectra 或執行：

```text
spectra update --force
```

接著使用：

```text
$sdd-spectra-refresh
```

Claude 版本對應：

```text
/sdd-spectra-refresh
```

它要確認：

- `.agents/skills/sdd-*` 還存在。
- `.claude/skills/sdd-*` 還存在。
- `openspec/config.yaml` 仍保留 Agentflow-SDD context 與 artifact rules。
- `AGENTS.md` / `CLAUDE.md` 的 project overlay note 仍在 `SPECTRA:START` / `SPECTRA:END` generated block 外。
- 新版 `spectra-propose`、`spectra-ingest`、`spectra-apply` 行為沒有破壞 overlay 假設。

## 對應到演講流程

演講中的流程可映射成：

```text
Discuss
→ Explore
→ Prototype
→ Spec
→ Usage/API Docs
→ Ticket
→ Develop
→ Review
→ Wrap
```

本專案對應如下：

| 演講流程 | 本專案位置 |
| --- | --- |
| Discuss | `$sdd-agentflow` 的 Discuss，並寫入 `proposal.md` |
| Explore | `$sdd-agentflow` 的 Explore，並寫入 `proposal.md` / `design.md` |
| Prototype | Prototype Decision / Prototype Findings，寫入 `design.md` |
| Spec | Spectra `spec.md` |
| Usage/API Docs | `design.md` 的 Working Backwards Usage/API Contract |
| Ticket | Spectra `tasks.md` |
| Develop | `$spectra-apply` |
| Review | Review/Rating/Fix Gate、實作後 review、Spectra analyze/validate |
| Wrap | `$spectra-archive` |

## 什麼不要做

- 不要直接改 `.agents/skills/spectra-*` 或 `.claude/skills/spectra-*` 來塞專案規則。
- 不要在 artifact 品質不足時直接 `$spectra-apply`。
- 不要讓 prototype code 默默變成正式 implementation。
- 不要把「看起來合理」當作驗收；每個 task 都要有具體 verification target。
