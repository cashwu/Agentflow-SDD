# Cash Apply Review — Round 2

## Reviewer Findings

### Cumulative blocking set 逐一裁決（Reviewer V）

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| F1 — Example 表宣稱的 freshness 結果與實作相反 | resolved | 前兩列已換為生成模型下 freshness 確實偵測不到的缺陷類別；Reviewer V 於隔離副本重現新列 2（刪除 `frontmatter_remove_keys` 的 `- context` 後重新生成並提交 → `generated-fresh` 通過、`well-formedness` 於 `.agents/skills/cash-analyze/SKILL.md` 失敗）與新列 3；Scenario AND 子句已改為 `不論 freshness 比對回報通過或失敗都仍然失敗`，不再宣稱 freshness 通過。 |
| F2 — 內嵌 YAML 讀取器對 flow-style 靜默誤解析 | resolved | `UNSUPPORTED_SCALAR_LEADS` 與其守衛拒絕全部六種前導字元；Reviewer V 對 flow sequence、flow mapping 值、單引號 scalar、`&anchor`、`*alias`、`>` folded 六種形狀均取得 `generate: unsupported YAML scalar form` 與非零結束。`implementation-notes.md` 與 `design.md` D2 的敘述與實作列舉一致。 |
| F3 — cash-cli master spec 的「24-skill variant parity」措辭未列入 delta | resolved | `implementation-notes.md` 已追加日期化的解決條目（使用者選擇「維持現狀」、cash-cli delta 不擴充），原 `open-question` 條目逐字保留；`openspec/specs/cash-cli/spec.md` 與 cash-cli delta 均未變動，與所記錄的決定一致。 |
| F4 — `remove_section` 的終止線搜尋無上界 | resolved | 終止線搜尋以下一個 `^## ` 為上界（自 `start + 1` 起算，fork 標題本身不會成為上界），找不到時 `die()`；Reviewer V 重現 Round 1 情境後取得 `... without its --- terminator`、exit 1、且無內容被刪除。十二個 skill 的基準重新生成仍逐位元組相符，現行五個 fork 段落的 `---` 都在下一個 `## ` 之前，上界未排除任何合法終止線。 |

Reviewer V 另回報下列 fix propagation 檢查結果為乾淨：`blocks/review-gate.md` 的受保護路徑集合與 delta spec 及 `assert_grader_immutability` 的三個新字面值完全一致（11 個路徑／9 個字面值，無漂移）；`strip_frontmatter_keys` 的 `dropping` 迴圈重現十二個輸出逐位元組相同，且正確保留 `metadata:` 與其縮排子項（旗標在每個非縮排 key 重設）；`normalized_gate_hash` 斷言確實會失敗（以 per-skill patch 改寫 cash-apply gate 區段內文字後重新生成，freshness 通過但取得 `gate region differs after invocation normalization`）；`staging_failed` 確實清除暫存目錄；新斷言位於 `assert_generated_fresh` 內、在套件全量執行路徑上。

### Critical

（無）

### Warning

（無）

### Suggestion

**V1 — `remove_section` 上界在無後續 `## ` 標題時退回 `len(lines)`**

- severity: Suggestion
- confidence: 65
- layer: design
- location: `scripts/cash-skills/generate.fish:212-220`
- summary: fork 段落若位於檔案最後、其後沒有任何 `## ` 標題，上界退回 `len(lines)`，理論上仍可能刪除到檔案後方的 `---`。
- disposition: unresolved-prior
- 處置：**triage note，不修正。** 在沒有後續 `## ` 標題的情況下，fork 標題與該 `---` 之間的內容在結構上就屬於該 fork 段落，沒有可據以判定「無關」的邊界；而真正的失效情境——完全缺少終止線——已由 `stop is None` 的 `die()` 涵蓋（Reviewer V 亦確認該路徑非零結束且不刪除內容）。Reviewer V 自身註明此情境「以現行任何檔案皆不可達」（五個 fork 段落之後都還有 `## ` 標題）。收緊為「fork 段落不得位於檔案最後」屬於 spec 與 contract 均未要求的額外約束，依 Focused Implementation Discipline 不加。

**V2 — flow mapping 作為 block sequence item 時拋出 `KeyError` 而非明確錯誤**

- severity: Suggestion
- confidence: 60
- layer: design
- location: `scripts/cash-skills/generate.fish:58-64, 136-144`；`openspec/changes/cash-skill-maintainability/design.md:30`
- summary: F2 的拒絕守衛只放在值的位置（`read_scalar`），sequence item 位置的 flow mapping 會走進「inline first key」分支並以未處理的 `KeyError` traceback 結束，與 `design.md` D2 與 `implementation-notes.md` 新寫下的「flow mapping／sequence MUST 以明確錯誤結束」承諾不符。
- disposition: fix-introduced
- introduced_by: Round 1 Fix Action 2 與 10（`apply-r1.md` 的 F2 修正與 S6 回填）。
- 處置：**已修正。**

**V3 — Example 表新列 2 不屬於 requirement 本體列舉的兩類缺陷**

- severity: Suggestion
- confidence: 55
- layer: design
- location: `openspec/changes/cash-skill-maintainability/specs/cash-skill-workflows/spec.md:47, 57, 88-95`
- summary: 改寫後的列 2（frontmatter 移除清單被縮減、重新生成並提交）是**轉換規則**的缺陷，而 requirement 本體與 rationale 只列舉「源頭與生成輸出同時錯誤」與「被登記為 per-skill patch 因而被凍結」兩類，列 2 兩者皆不屬。
- disposition: fix-introduced
- introduced_by: Round 1 Fix Action 1 只改寫了 Example 表，未回頭檢視 `spec.md:47` 的兩類列舉與 `spec.md:57` 的 rationale。
- 處置：**已修正。**

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **0**
- 非阻斷 triaged finding count: **1**（V1）
- critical_gap: **false**
- round_type: **micro**

rationale：Reviewer V 對 cumulative blocking set 的四個成員全部給出 `resolved` 裁決，且每一項都附有在隔離暫存 root 實際重現的證據，四個成員因此全部以「已驗證解決」離開集合，集合清空。本輪新提出的三筆 findings 經 confidence filter 後全部維持 `Suggestion`（confidence 65／60／55，皆低於 80，本就不可能升為 `Critical` 或 `Warning`），依規則不進入 cumulative blocking set、也不構成 `next_round`。post-filter cumulative blocking set 既無阻斷性 `Critical` 也無阻斷性 `Warning`，pass 條件成立，故本輪為 `passed`。

## Fix Actions

決策依 post-filter cumulative blocking set 機械推導為 `passed`，因此本輪沒有必須執行的修正。以下為對非阻斷 Suggestion 的處置紀錄。

**Triage note**

- V1（`scripts/cash-skills/generate.fish` 的終止線上界在無後續 `## ` 標題時退回 `len(lines)`）：不修正，理由見上方該筆 finding 的處置說明——無結構邊界可據以判定「無關」，且真正缺少終止線的情境已明確報錯，Reviewer V 亦確認以現行任何檔案皆不可達。

**已套用的 Suggestion 修正**

1. **V2** — 修改 `scripts/cash-skills/generate.fish`：`read_sequence` 在進入「inline first key」分支之前先以 `UNSUPPORTED_SCALAR_LEADS` 拒絕 item body 的前導字元。驗證：把 `remove_sections` 的 item 改寫為 `- {id: ..., heading: ..., terminator: ...}` 後取得 `generate: unsupported YAML sequence item form: ...` 與 exit 1，不再是 `KeyError` traceback。
2. **V3** — 修改 `openspec/changes/cash-skill-maintainability/specs/cash-skill-workflows/spec.md`：把 requirement 本體的第一類缺陷由「源頭與生成輸出同時錯誤」放寬為「生成輸入（`.claude/skills/` 的源頭檔與 `scripts/cash-skills/variant-rules.yaml` 的轉換規則）與生成輸出同時錯誤」，rationale 的對應措辭同步改為「生成輸入與輸出同樣錯誤時比對通過」。「兩類缺陷」的列舉結構與 Example 表標題維持不變。

**修正後驗證**

- 合法規則檔的生成結果不變：重新生成後 `.agents` 與 `.claude` 的變更檔數維持為本 change 既有的 4 個檔案，連續兩次執行無任何檔案變更。
- Example 表列 2 重跑仍與實作一致：freshness 通過、良構斷言失敗。
- `scripts/cash-skills/tests/skill-checks.fish` 全套與 `scripts/cash-cli/tests/cli-checks.fish` 全套皆以 exit 0 通過。
- Implementation Contract 受影響項重驗：C3（四份 gate 區段正規化後逐字相同）與 C7（三個新受保護路徑在四檔皆存在）皆成立。

**Grader 保護**

- 本輪修改的受保護 grader 檔案 `scripts/cash-skills/generate.fish` 由 proposal `## Impact` 的 affected-code 條目明確指名，屬結構化範圍宣告內。本輪無 `未修復：裁判面保護` 紀錄；Round 1 亦無。

**Outside-change-directory 檔案記錄**

- 本輪 Fix Actions 修改的 change 目錄以外檔案：`scripts/cash-skills/generate.fish`，已以 `"$cash_cli" touched record --path` 記錄成功，無警告。未修改 `.cash-skills/` 之下的 runtime 檔，故不需重建 receipt。

## Decision

passed
