## Summary

修補 `cash_cli.spec_merge` 的 `@trace` 路徑抽取：讓它認得 proposal `## Impact` 與 tasks 驗證子句中合法但目前不被辨識的書寫形式，大幅降低抽取落空的發生率——實測 29 份 proposal 中，`code` 為空由 14 份降為 0 份。本變更不動 `_with_trace` 的無條件抹除，也不新增任何訊號，因此「靜默」本身不在範圍內。

## Motivation

`sync` 在合併 delta spec 時會為每個被觸及的 requirement 重寫 `@trace` footer，`code` 取自 proposal `## Impact` 的 affected-code paths，`tests` 取自 tasks 的 verification target paths。兩個抽取器都對輸入形式有未成文的額外要求：

- `_paths_in_section` 只收集 backtick code span 內含斜線的值。Cash-owned 的 proposal 模板規定了 `## Impact`、`- Affected code:` 與 New／Modified／Removed 三個標籤列，但從未要求路徑加 backtick，因此以純文字列出路徑的 proposal 完全符合被治理的形狀，卻讓 `code` 落空。
- `_verification_path` 只取 code span 的第一個 whitespace token。驗證子句寫成前置直譯器或直譯器加參數的形式時，第一個 token 是直譯器名稱而非路徑，因此整條驗證目標落空。

兩者都不報錯，只是回傳空 list。`_with_trace` 會先無條件移除既有的 `@trace` 區塊再寫入新的，所以一次抽取落空不只是「這次沒填」，而是把先前已填好的 provenance 一併抹掉，且沒有任何訊號。已發生兩起可從 history 稽核的實例：`Cash workflow command surface` 的 `code` 在 commit `07254d7` 由 5 條變為 0 條，`Cash guidance deployment` 的 `code` 在 commit `6afc4ee` 由 37 條變為 0 條。兩次都沒有任何輸出指出 provenance 被抹除。

對現有 corpus 實測顯示這不是單一個案（基數為本 change 以外的 28 份 proposal）：其中 14 份的 `## Impact` 只用純文字路徑、4 份混用，合計 18 份會讓 `code` 完全或部分落空；73 個 master spec trace 中 `code` 為空的有 8 個。

`tests` 為空的 23 個 trace 則指向第三個同類缺陷：它們的 `source` 全部是同一個 change，其 `tasks.md` 有 13 行含 `cli-checks.fish`，但驗證子句寫成 `以` 後不接空白的形式，`_VERIFICATION_CLAUSE` 的 `(?:並)?以\s+` 在該檔定位到 0 個 clause。本變更不修 clause 定位，該缺陷的可見性同屬後續 change 的範圍；此處記錄它，是為了說明空 `tests` 與空 `code` 的成因不同。

## Proposed Solution

分三個部分，都限定在 trace 抽取本身：

1. **`- Affected code:` 子清單同時接受 backtick 與純文字路徑。** 除既有的 code span 之外，另接受該子清單內 ASCII 路徑形狀的裸 token。抽取範圍由整個 `## Impact` 收斂到 `- Affected code:`，使 `code` 名副其實。這同時是本點自身成本的必要對沖：現行規則下把 `- Affected specs:` 的 spec 路徑收進 `code` 的只有 29 份中的 3 份，放寬裸 token 後會升到 12 份，範圍收斂使其降回 7 份——後者是作者確實把 spec 檔列在 `- Affected code:` 之下，屬合法。限定 ASCII 的作用需標明範圍：以**收斂前**的整個 `## Impact` 為範圍時，唯一被消除的是中文以斜線當分隔的散文片語；但該片語出現在 `- Affected specs:` 行，因此在**收斂後**的 `- Affected code:` 範圍上，現行 corpus 的消除數為 0。ASCII 限定因此是防止未來作者在 affected-code 子清單寫入非 ASCII 散文的護欄，而非當前偵測器。殘留 1 個 ASCII 散文偽陽性 `runtime/install`（來自某份已封存 proposal 的一行散文，其中以斜線分隔的 runtime／install 被誤判為路徑），本變更接受它：以 token 形狀無法可靠區分 ASCII 散文與路徑，再加副檔名或存在性條件會分別排除合法的目錄項與已刪除檔案的歷史項；該值只影響一份已封存 proposal，代價明確小於 14/29 份 proposal 的 `code` 完全落空。

2. **驗證子句掃描 code span 的全部 token，而非只取第一個。** 這一項是放寬：對 28 份 tasks 實測（以檔案增量加總計，7 份各自多抓到合計 11 個條目；以全域相異值計為 9 條增為 13 條），沒有任何一條舊規則抓得到而新規則抓不到。

3. **測試路徑的判準由「副檔名」改為「測試形狀」。** 這一項是**收窄**，必須與第 2 點分開說明：目前只要 token 以 `.fish` 或 `.sh` 結尾就被當成測試路徑，而交付腳本與測試腳本共用該副檔名。單獨看第一個 token 時傷害有限，但第 2 點掃描全部 token 之後它會開始收進 source 腳本，正是 `trace-verification-path-source-confusion` 記錄過的缺陷。改為要求 `/tests/` 出現在路徑中或檔名以 `test_` 起首之後，實測相對現行規則損失 0 條、新增 2 條真實測試路徑（全域相異值基準：9 條增為 11 條），並排除 install-cash-skills.fish 與 spectra-plus 的 generate.fish 兩個交付腳本。代價是位於 tests 目錄外、檔名也無 `test_` 標記的檢查腳本不再被視為測試證據。


## Non-Goals

- 不回填既有 master spec 中已經產生的空 trace 或錯誤 trace。這些 trace 無法由原 change 自行收斂：`workspace.change_path` 只解析 active change 目錄，封存後該名稱已不可 sync，目前 8 個空 `code` trace 全部屬於已封存的 change。它們只會在別的 change 觸及同一 requirement 時被改寫成該 change 的 provenance，原始歸屬永久遺失。回填需要人工修補或另立回填 change，不在本變更範圍。
- 不改變 sync manifest 的 no-op 判定：`sync` 一旦對某個 change 完成，其 `@trace` 即為 write-once。實測 `_merge` 只對 MODIFIED-only 的 delta 冪等（ADDED 撞 `requirement_collision`、REMOVED 與 RENAMED 撞 `requirement_identity_mismatch`），且 `already_synced` 另被 `validation.py` 用來推導 `identities_already_applied`。本變更因此把價值放在「第一次 sync 就抽對」，而非事後補救。
- 不新增任何診斷、gap 回報或輸出面，因此不動 archive command 模組（commands/archive.py）。抽取為空時的可見性由後續 change 處理：實測顯示本變更引為動機的兩起事故（`Cash workflow command surface` 的 code 由 5 條變 0 條、`Cash guidance deployment` 由 37 條變 0 條）單靠抽取修正即完全避免——兩份 proposal 在新規則下分別抽到 9 條與 2 條，因此診斷對動機案例的貢獻為零。後續 change SHOULD 把它放在 `validate` 而非 `sync`／`archive`（`validate` 不寫入、可反覆重跑，不受 sync manifest no-op 影響，且在 change 仍為 active 時觸發），判準 SHOULD 為「宣告了 affected code 卻抽不到任何路徑」而非「欄位為空」。
- 不動 drift command 模組（commands/drift.py）的 `_impact_paths`。它是同一書寫形狀的第二個消費者（同樣只認 backtick code span，且掃整份 `proposal.md` 而未限定 `## Impact`），用於產生 `Declared impact path does not exist.` 的 broken anchor 與 `dirty-impact` 維度。本變更修好 `spec_merge` 側之後，純文字 proposal 在 `cash drift` 下仍會得到 0 個 affected-code anchor，且兩個抽取器的語意分歧會擴大：只出現在 `- Affected specs:` 的路徑進 drift 不進 `code`，純文字路徑進 `code` 不進 drift。收斂兩者應共用同一個抽取 helper，屬另一個 change。
- 不讓位於 repo root、不含斜線的 affected-code 檔案進入 `code`。`_canonical_path` 對剝除後不含斜線的值回傳 `None`，因此 `cash-skills.version`、`install-cash-skills.fish`、`CASH-SKILLS.md` 等 root-level 宣告結構性地不會出現在 trace。後果是一個只宣告 root-level 檔案的合法 change 會得到空 `code`；本文件其他處引用的「新規則下 `code` 為空 0/29」其證據範圍不涵蓋此類 change。
- 不修 `_VERIFICATION_CLAUSE` 對 `以` 後不接空白之驗證子句的定位缺陷；該缺陷影響至少一個已封存 change 的 13 行驗證子句，屬另一個 change 的範圍。
- 不改變 `@trace` 的欄位集合、順序或渲染格式。
- 不改變 proposal 模板的段落集合，也不新增「路徑必須加 backtick」這類對作者的書寫要求。
- 不把任何 trace 抽取結果變成 execution error 或 validation finding。
- 不改變 sync manifest、transaction、rollback 或 archive 的既有語意。

## Alternatives Considered

- **只在文件與 skill 中要求作者一律用 backtick 寫路徑**：把機器的輸入限制轉嫁給人，而模板本身並未要求；28 份 proposal 中有 18 份不符合這個未成文要求，顯示它不是可靠的收斂手段。
- **在抽取器內對「宣告了 affected code 卻抽不到路徑」直接 fail closed**：本變更不新增任何輸出面或失敗模式（見 Non-Goals）；且該判準若要成立，需要先確定「宣告了」的計數方式，屬後續 change 的設計問題。
- **合併時保留舊 trace 的非空欄位**：舊路徑會被掛到新的 `source` 名下，等於用錯誤的歸屬換取欄位非空，比留空更難稽核。
- **改由 touched record 產生 trace**：touched record 記錄的是實際改動的檔案，語意與 proposal 宣告的影響範圍、tasks 宣告的驗證目標都不同，會使 trace 失去「宣告 vs 實作」的對照價值。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：sync 的 `@trace` 路徑抽取契約——`code` 的抽取範圍與可接受書寫形式、`tests` 的 token 掃描與判準、兩個欄位的 canonical 形式。

## Impact

- Affected specs:
  - `openspec/specs/cash-cli/spec.md`
- Affected code:
  - New:
    - （無）
  - Modified:
    - `.cash-skills/lib/cash_cli/spec_merge.py`
    - `scripts/cash-cli/tests/test_sync_archive_transaction.py`
    - `cash-skills.version`
  - Removed:
    - （無）
