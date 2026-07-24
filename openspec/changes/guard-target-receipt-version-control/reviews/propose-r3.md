# Cash Propose Review — Round 3

## Reviewer Findings

### Cumulative blocking set 裁決

- **[Warning, fix-introduced] snapshot revalidation 檢查點衝突 → resolved**（confidence 90）
  Reviewer V 逐點比對後確認：目前條文已區分 post-lock（重新分類）與 publication 前（execution error fail closed），且與 `installer.py:1202-1221`、`:1291-1301` 的實際行為及 master `Cash guidance deployment` 的 fail-closed 契約三方對齊。主 agent 先前已獨立查證該兩處實作行為。

累積 blocking 集合於本輪清空。

### Suggestion

- confidence 70 / layer: proposal / disposition: unresolved-prior
  location: `proposal.md` Proposed Solution
  summary: Round 2 的 revalidation 修正未傳播至 proposal，該行仍為單一檢查點敘述「使 plan 與 publication 之間的外部修改被重新分類而非靜默覆寫」，與 spec、design、tasks 及 master 契約相反。
  recommendation: 改為 post-lock 重新分類、publication 前 fail closed，兩者皆不覆寫。

- confidence 65 / layer: tasks / disposition: new
  location: `tasks.md` 1.2
  summary: publication 前 fail-closed 的測試無可用注入點；既有外部修改注入 hook 位於 post-lock revalidation 之前，沿用會使測試落在錯誤階段（與 Round 1 的 `CASH_INSTALL_FAIL_AFTER` 偽陽性同型）。

- confidence 55 / layer: spec / disposition: new
  location: `specs/cash-cli/spec.md` ADDED requirement
  summary: 未明說 `newer` 與 `conflict` target 不套用本保護；master 要求該兩類零寫入，實作若把判定放在早退之前即破壞既有契約。

- confidence 50 / layer: tasks / disposition: new
  location: `tasks.md` 1.4
  summary: 「diagnostic MUST NOT 依結果分類決定是否輸出」無對應測試；本 change 生效後該類 target 第二次起正是 `current`，為最常見路徑。

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 0
- non-blocking triaged: 4
- critical_gap: false
- round_type: micro
- rationale: Round 2 唯一的 blocking Warning 經 Reviewer V 以條文、實作行為與 master 契約三方對照裁決為 resolved，累積 blocking 集合清空。本輪四項新 findings 經信心過濾後全數為非阻斷；其中 proposal 殘留敘述與 spec 直接矛盾、`newer`/`conflict` 零寫入為既有契約風險，雖非阻斷仍於本輪一併修正以免帶入實作。

## Fix Actions

- 修改 `proposal.md`：revalidation 敘述改為 post-lock 重新分類、publication 前 fail closed，與 spec／design／tasks 一致。
- 修改 `specs/cash-cli/spec.md`：補明分類為 `newer` 或 `conflict` 的 target MUST 維持既有零寫入契約，本保護 MUST NOT 對其寫入。
- 修改 `tasks.md`：1.2 明示 publication 前案例需新增組裝後／publication 前的 hold hook、不得沿用既有 hook；1.4 補上分類為 `current` 的 target 仍輸出 diagnostic 的測試；3.1 驗收補上 `newer` 與 `conflict` 零寫入確認。
- 修正後 `validate` 通過；機械自我檢查確認 MODIFIED 區塊與 master 仍僅 4 行相異。
- fixed_files: 3

## Decision

passed
