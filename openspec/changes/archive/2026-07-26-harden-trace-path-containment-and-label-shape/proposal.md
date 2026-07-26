## Summary

收斂 `cash_cli.spec_merge` 的 `@trace` 路徑抽取在前一個 change `harden-spec-trace-path-extraction` 通過後仍留下的兩個缺口：`_canonical_path` 未拒絕含 `..`、`.`、空段的值，也未拒絕以 `~` 起首的 home-relative 值，使非 repo-relative 的路徑會逐字寫入 `code` 與 `tests`；`- Affected code:` 標籤列採整行相等比對，使該標籤帶行內內容、帶尾隨空白或被縮排時 `code` 完全落空。兩者在現行語料的出現數皆為 0，本變更因此是護欄而非缺陷修復——但第二項的護欄價值由 sibling 標籤的實測書寫慣例支撐：本 change 以外的 28 份 proposal 中，`- Affected specs:` 有 22 份帶行內內容。

## Motivation

前一個 change 把 `code` 的抽取範圍由整個 `## Impact` 收斂到 `- Affected code:` 子清單、並為兩個欄位加上共用的 `_canonical_path`。收斂與正規化都達成了原定目標（該 change 封存時的 28 份 proposal 語料上，空 `code` 由 14 降為 0），但留下兩個未被其 Implementation Contract 涵蓋的形狀缺口。

**缺口一：canonical 化不涵蓋 root containment。** `_canonical_path` 只在值以 `/` 起首或剝除後不含斜線時回傳 `None`。含 `..` 段的值三個條件全部滿足，因此原樣通過：`- Affected code:` 子清單寫 `../outside/x.py` 會使該值進入 `code`，驗證子句寫 `python3 ../tests/test_a.py` 會使 `../tests/test_a.py` 進入 `tests`（兩者皆已實測重現）。含 `.` 段的 `a/./b.py`、含內部連續斜線的 `a//b.py`、以及以 `~/` 起首的 home-relative 路徑同理原樣通過——`~` 屬字元集內的合法字元，其各段又都不是 `.` 或 `..`，因此是同一個缺口的第四種形態。master spec 對這兩個欄位的要求是「canonical repo-relative 形式」，而指向 repo 之外的值不是 repo-relative；既有條文只列舉了剝除 `./`、不以 `/` 起首、不以 `/` 結尾三個條件，未列舉 `..`，因此這是條文未涵蓋的缺口而非實作違反條文。這與 signal `filesystem-boundary-validation-missing`（13 次）是同一個問題類別：路徑進入持久化記錄前未做 root containment 檢查。寫入的對象是 master spec 的 `@trace` footer，屬長期保存的 provenance 記錄，與 signal `noncanonical-path-persisted-in-allowlist` 的教訓一致。

**缺口二：標籤列的整行相等比對是收斂新引入的落空面。** 現行 `_paths_in_section` 以 `line == list_label` 定位子清單起點。實測三種書寫都使 `code` 為空：標籤帶尾隨空白、標籤被縮排、標籤寫成粗體。收斂之前的舊規則掃整個 `## Impact`，這三種寫法下 backtick 路徑仍抽得到，所以這是範圍收斂新造出來的失敗路徑。後果不只是「這次沒填」——`_with_trace` 仍會無條件移除既有 `@trace` 區塊再寫入新的，因此一次落空會連同先前已填好的 provenance 一併抹除，且沒有任何訊號。

該缺口在現行語料的出現數為 0：本 change 以外的 28 份 proposal，其 `- Affected code:` 全部是精確形狀。但同一份模板的 sibling 標籤顯示了作者的實際書寫慣例——同一組 28 份中，`- Affected specs:` 有 22 份帶行內內容（如 `- Affected specs: cash-cli`）、僅 6 份為純標籤。行內形式因此是 `- Affected code:` 未來最可能出現的變體，而非粗體或縮排；目前若有作者比照 sibling 慣例寫成 `- Affected code: path/to/x.py`，該行的路徑不但不會被收集，整個子清單的抽取都會落空。

## Proposed Solution

分兩部分，都限定在既有的兩個抽取 helper 與其共用的 canonical 化：

1. **`_canonical_path` 拒絕非 repo-relative 與非 canonical 的路徑形狀。** 在既有的「以 `/` 起首」與「剝除後不含斜線」兩個回傳 `None` 條件之外，增加「任一路徑段為空、`.` 或 `..`」與「第一段以 `~` 起首」兩條。後者不可省略：`~` 在裸路徑與驗證子句共用的字元集之內，而 home-relative 路徑的每一段都不是空段、`.` 或 `..`，因此只加前者時 `~/outside/x.py` 仍會原樣寫入 `code`（已實測）；只判定第一段則使 `a/~b/c.py` 這類合法檔名維持被接受。採拒絕而非解析（不把 `a/../b` 正規化為 `b`）：解析會讓寫入 trace 的值與作者實際書寫的字串不同，使 provenance 難以稽核，且 `a/../b` 這類寫法本身不是宣告路徑的正當形式。此規則對 `code` 與 `tests` 兩側同時生效，因為兩者共用該 helper。實測現行語料受影響條目為 0。

2. **標籤列比對由整行相等改為正規化後前綴相等，並把標籤列 colon 之後的殘餘內容納入抽取範圍。** 容忍範圍明確定為兩項：前後空白（含縮排與尾隨空白），以及 colon 之後的行內內容。同層終止條件 `- Affected ` 同步以相同正規化比對，使起點與終點對稱——否則一個縮排的 `- Affected specs:` 會無法終止 `- Affected code:` 的掃描範圍，反而讓 spec 路徑重新進入 `code`。粗體與其他 markdown 強調標記、全形冒號不在容忍範圍：兩者的語料證據皆為 0，且剝除強調標記會開啟不封閉的文字正規化面，與「MUST NOT 額外要求該形狀未規定的書寫慣例」的收斂方向相反——正確的作法是模板已規定的形狀加上前後空白與行內內容這兩個低風險維度。

`## Impact` 標題列的定位同屬 `line == heading` 的整行相等比對，同一個失敗類別，一併以尾隨空白正規化收斂；標題不會被縮排（markdown ATX 標題須在行首），因此只正規化尾端。

## Non-Goals

- 不新增任何診斷、gap 回報或輸出面。抽取落空時的可見性仍屬後續 change 的範圍，其判準與落點的建議（放在 `validate`、判準為「宣告了 affected code 卻抽不到任何路徑」）由前一個 change 的 Non-Goals 記錄，本變更不改變該建議。
- 不回填既有 master spec 中已經產生的空 trace 或錯誤 trace。理由與前一個 change 相同：封存後的 change 已不可 sync，原始歸屬無法由原 change 自行收斂。
- 不修 `_VERIFICATION_CLAUSE` 對 `以` 後不接空白之驗證子句的定位缺陷。該缺陷影響至少一個已封存 change 的 13 行驗證子句，屬另一個 change 的範圍。
- 不動 drift command 模組的 `_impact_paths`。它是同一書寫形狀的第二個消費者，收斂兩個抽取器共用同一個 helper 屬另一個 change；本變更放寬標籤形狀後，兩者的語意分歧不會擴大，因為 `_impact_paths` 本來就不看任何標題或標籤。
- 不改變 `@trace` 的欄位集合、順序或渲染格式。
- 不改變 sync manifest、transaction、rollback 或 archive 的既有語意，也不改變其 no-op 判定。
- 不把任何 trace 抽取結果變成 execution error 或 validation finding。
- 不容忍粗體或其他 markdown 強調標記形式的標籤列，也不容忍全形冒號。
- 不改變 proposal 模板的段落集合，也不新增對作者的書寫要求。
- 不對含 `..` 段的值做路徑解析或正規化，只拒絕。

## Alternatives Considered

- **把 `..` 的值正規化為解析後的路徑**：`a/../b` 會被寫成 `b`，使 trace 的值與 proposal 實際書寫的字串不一致，稽核時無法逐字對回原始宣告；且指向 repo 之外的 `../x` 解析後仍在 repo 之外，仍需另一個拒絕條件，等於兩套規則並存。
- **以檔案系統存在性判定 root containment**：會排除已刪除檔案的歷史宣告與尚未建立的 New 條目，與前一個 change 已經記錄過的理由相同。
- **標籤列改用寬鬆 regex（如允許任意前綴與 markdown 標記）**：容忍面不封閉，會讓散文中提及 `- Affected code:` 的行（本專案的 proposal 確實存在這種行）被誤判為子清單起點，把散文段落納入抽取範圍。前綴相等加上明確列舉的兩個容忍維度是可界定的最小集合。
- **維持整行相等比對，改以文件或 skill 要求作者逐字書寫標籤**：把機器的輸入限制轉嫁給人，且 sibling 標籤 22/28 的行內書寫率顯示這種未成文要求不是可靠的收斂手段——這正是前一個 change 已經拒絕過的同一種論證。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：sync 的 `@trace` 路徑抽取契約——canonical 形式的 root containment 條件，以及 `- Affected code:` 子清單定位所接受的標籤列形狀。

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
