# 07 — Dev Task T7 Review（r1）

- **Target**：auto-restore-commit-guard-source / 步驟 7（Dev）最終任務 T7 — 對照 spec/design/usage 與測試，對 installer 自動還原機制做獨立審查 + 安全稽核（audit=true）。
- **Reviewer**：獨立 sub-agent（未採信作者摘要，直接讀碼並實跑）。
- **Decision**：**pass**
- **quality_score**：**9.5 / 10**

## Inputs Reviewed

- 實作：`install-spectra-plus.fish`
  - `maybe_restore_source_guard`（L365–402，新函式）
  - `guard_is_current`（L353–363，HEAD/worktree blob 驗證）
  - 呼叫點 `ensure_commit_guard`（L100–104：`maybe_restore_source_guard` → `set restore_rc $status` → `if test $restore_rc -ne 2; validate_commit_guard`）
  - `file_has`/`file_lacks`（L345–351）、`validate_commit_guard`（L75–86）、`dry_run` 全域宣告（L723）、`repair_all`（L468–521）、dispatch（L771–792）
- 測試：`scripts/spectra-plus/tests/auto-restore-checks.fish`
- 契約：`spec.md`（5 scenarios）、`design.md`（Implementation Contract）、`agentflow/05-usage.md`（精確訊息字串）

## Scenario → Code → Test 對照

| Spec Scenario | Code 滿足點 | Test 覆蓋 | 結果 |
|---|---|---|---|
| 1. Self-heal stripped source from valid HEAD | L372 worktree fail → L375 in-git → L384 `show HEAD` → L388 HEAD guard 有效 → L399 `git restore --source=HEAD -- $relpath` + L400 log；回呼點 L103 重驗通過 | Case A2（L94–99）：斷言 `restored … from HEAD`（Claude+Codex）且還原後含 marker | PASS |
| 2. HEAD source 也壞 | L388 `guard_is_current "$head_blob"` 失敗 → L390 return 0（不還原）→ L103 `validate_commit_guard` fail-loud | Case B（L106–113）：HEAD 也無 guard，斷言 exit 1 + stderr「缺少必要內容」+ 無 restore 行 | PASS |
| 3. Source 不在 git 工作樹 | L375 `rev-parse --show-toplevel` 失敗 → L376 `test -n` 失敗 → return 0 → fail-loud | Case C（L118–125）：非 git repo，斷言 exit 1 + stderr「缺少必要內容」+ 無「from HEAD」 | PASS |
| 4. Dry-run 報告但不 mutate | L394 `if test $dry_run -eq 1` → L395 印 `+ would restore` → L396 return 2；回呼點 L102 `if … -ne 2` 跳過 source 硬驗；L399 git restore 被 dry-run 閘擋 | Case A1（L88–92）：斷言 `+ would restore …`，並以 `diff -u` 驗 source 位元組未變 | PASS |
| 5. 還原限定單一檔 | L399 pathspec 為精確 `$relpath`，無萬用字元、無 `git restore .` | Case A3（L100–101）：另置 tracked-dirty `unrelated.txt`，還原後仍為 `DIRTY` | PASS |

5 個 scenario 全部由程式碼滿足且由測試斷言（含精確訊息字串）。

## Security Audit Checklist（audit=true）

| 稽核項 | 判定 | 證據 |
|---|---|---|
| 是否可能覆蓋 working-tree **有效** guard 的檔案？ | **否（安全）** | L372 `guard_is_current "$source_path"; and return 0` 為第一道閘；guard 完好即立即返回，永不進入還原路徑。 |
| 還原是否嚴格單檔（無 unscoped `git restore .` / 無 wildcard）？ | **是（安全）** | L399 pathspec 為 `-- "$relpath"`，relpath 為 source 相對 toplevel 之精確路徑；Case A3 實證旁邊 dirty 檔未被動。 |
| `--dry-run` 是否有任何 mutation（git / file / lock / cache / throttle）？ | **否（安全）** | dry-run 僅 L375/L384 之 `rev-parse`/`show`（皆 read-only）；L399 `git restore` 被 L394 閘擋；`--target` 路徑不觸 lock/throttle/cache（皆僅存在於 `repair_all`，L470–496）。`repair_all --dry-run` 於 L472 提早返回，根本不進 install。Case A1 `diff` 實證 source 未變。 |
| 是否動 git index（spec：MUST NOT）？ | **否（安全）** | L399 為 `git restore --source=HEAD --`（worktree-only），無 `--staged`、無 `checkout`。Case A 先 commit 再弄髒 `unrelated.txt`，還原後 index 未受擾。 |
| relpath 推導之 path-traversal / symlink / 「source 不在 toplevel 下」風險 | **已防護** | L378–379 對 source 與 toplevel 皆 `realpath` 正規化（symlink 消歧義）；L380 `string replace` 取首次前綴匹配（已驗證重複目錄名不誤剝）；L381 `test "$relpath" != "$abs_source"` 確保前綴確實被剝（即 source 真的在 toplevel 下），否則 return 0 不還原。`git show HEAD:$relpath` 為 repo-relative，無法逃出 repo。`test` 守衛在此足夠。 |
| HEAD blob 驗證：是否可能自無效 HEAD 還原？ | **否（安全）** | L384 取 HEAD blob 寫暫存檔，L388 對該暫存檔跑完整 `guard_is_current`（與 `validate_commit_guard` 同 8 項檢查），不過則 L390 return 0 不還原。 |
| 暫存檔（`mktemp` head_blob）每條 return 路徑皆清理？ | **是** | L383 建立；return 路徑 L386（已 rm）、L390（已 rm）、L392 在 dry-run/真實還原前 rm；L396、L401 皆在 L392 之後，無洩漏。 |
| return-code-2 是否可能洩入真實執行而誤略驗證？ | **否（安全）** | return 2 僅在 L394 `if test $dry_run -eq 1` 內（L396）。真實執行 `dry_run==0` 必走至 L399→L401 return 0；故 L102 之 `-ne 2` 在真實執行恆為真，source 硬驗永不被略過。 |

`guard_is_current`（L353–363）與 `validate_commit_guard`（L75–86）逐項比對：8 項 marker/字串檢查完全一致（含 `assert_not_contains` 對 `openspec/archived/`、`docs/specs/`）。HEAD blob 驗證與最終 source 驗證標準等價，無「驗證鬆綁」缺口。

## Rubric

| 維度 | 評分 |
|---|---|
| 契約一致性（spec/design/usage） | 10 — 五 scenario、precondition 全成立；訊息字串與 usage 表一致（stdout `restored …`/`+ would restore …`、stderr 既有 fail-loud）。 |
| 安全（invariant R1/R2/R3/R4/R6/R12/R13/R14） | 10 — 全部稽核項通過，無 critical gap。 |
| 測試充分性 | 9.5 — 五情境全覆蓋且斷言精確字串與單檔/dry-run side-effect；扣分見 F1。 |
| 程式碼健壯性（fish quoting / status timing / edge） | 9 — quoting 正確、`set restore_rc $status` 緊接呼叫、relpath 已驗；扣分見 F2。 |

## Findings（severity / confidence）

- **F1 — git restore 退出碼未檢查（low / high）**：L399 `git restore` 之 exit code 未被檢查，即便還原失敗仍於 L400 印 `restored … from HEAD` 並 return 0。**安全影響為零**：L103 之 `validate_commit_guard "$source_path"` 為安全網，還原若實際失敗則 source 仍壞 → fail-loud（不會假成功）。唯一後果為「log 訊息與實況不符」之觀測性瑕疵。鑑於前置條件已保證 HEAD blob 可讀且有效，實務觸發機率極低。
- **F2 — `string replace` 非錨定（low / high）**：L380 以 `string replace`（首次匹配）剝前綴而非顯式起始錨定。已實證重複目錄名（`/tmp/reltest/reltest/f.md`）不誤剝，且 abs_source 必以 real_top 起頭，首次匹配即在位置 0。風險已關閉，僅記錄為設計觀察。
- **F3 — 觀察（info）**：`repair_all --dry-run`（L472）提早返回不進 install，故 dry-run 還原行為僅由 `--target --dry-run` 路徑（Case A1）覆蓋。與 spec/usage 一致（usage 表將 dry-run 對應至 `--target … --dry-run`），非缺口。

## Verification（reviewer 親跑）

- `fish scripts/spectra-plus/tests/auto-restore-checks.fish` → `PASS: auto-restore commit guard source checks`，**exit 0**。
- `fish -n install-spectra-plus.fish` → **exit 0**（語法乾淨）。
- 回歸：`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish` → `PASS`，**exit 0**（既有 commit-guard 測試無回歸）。
- relpath 推導以隔離 git fixture 手動模擬，含重複目錄名邊界，皆正確。

## Fixes Required

- 無（無 blocker、無 critical gap）。
- 選擇性硬化（非 pass 條件）：F1 可檢查 `git restore` 退出碼，失敗時改印錯誤而非 `restored`，使 log 與實況一致。

## Blockers / Critical Gaps

- 無。

## Decision

**pass**（quality_score 9.5 > 9，無 critical gap，5 scenario 全覆蓋並親測綠燈，安全稽核全數通過）。

## Next Action

進入步驟 8（`/sdd-review`）的整體 post-dev review gate；若採納 F1 之選擇性硬化，於該輪一併處理（非阻擋）。
