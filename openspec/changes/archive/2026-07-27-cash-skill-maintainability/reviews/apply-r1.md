# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

**F1 — Example 表宣稱的 freshness 結果與實作相反**

- severity: Warning
- confidence: 95
- layer: design
- location: `openspec/changes/cash-skill-maintainability/specs/cash-skill-workflows/spec.md:86, 88-95`
- summary: `##### Example: 兩類缺陷與其偵測來源` 前兩列宣稱「源頭與輸出都帶 `context: fork` ／ `disallowedTools`」時 freshness 比對結果為 `通過`，但生成器對全部十二個 skill 無條件移除這三個 frontmatter key，該情境下 freshness 必定失敗；同一 Scenario 的 `即使該缺陷同樣存在於生成源頭因而 freshness 比對通過` 子句同樣不成立。
- recommendation: 把前兩列換成生成模型下 freshness 確實看不見的缺陷類別（源頭本身的缺陷被忠實複製到輸出），並改寫該 Scenario 的 AND 子句，使其不再宣稱 freshness 通過。requirement 本體與 rationale 段落維持不變，因為「源頭與輸出同樣錯誤時比對通過」對未被規則移除的缺陷仍然成立。
- reviewer source: Reviewer A（confidence 95）與 Reviewer B（confidence 85）獨立提出，依 `location + summary` 聚合為同一筆；兩者 `layer` 均為 `design`。
- introduced_by: 本 change 把 master spec 第 3531–3534 行的 `對等比較結果 通過` 逐列改寫為 delta 第 90–93 行的 `freshness 比對結果 通過`，只換了機制名稱未重算判定；相牴觸的行為在 `scripts/cash-skills/generate.fish` 的 `strip_frontmatter_keys` 呼叫。
- 驗證: 在暫存 root 對 `.claude` 與 `.agents` 兩側 `cash-debug` 同時注入 `context: fork` 後重跑生成管線，輸出與注入前的 `.agents` 檔案不同，即 freshness 失敗。

**F2 — 內嵌 YAML 讀取器對 flow-style 靜默誤解析**

- severity: Warning
- confidence: 85
- layer: design
- location: `scripts/cash-skills/generate.fish:55-60, 99-116`；`openspec/changes/cash-skill-maintainability/implementation-notes.md:7`
- summary: `implementation-notes.md` 的 deviation 條目宣稱受限讀取器「任何其他形狀一律 `die()` 而非猜測」，但 `'value'`、`{a: b}`、`[a, b]`、`&anchor value` 都被當成普通字串接受；維護者若把 `frontmatter_remove_keys` 寫成 flow sequence，會得到一個被逐字元迭代的字串。
- recommendation: 在 `read_scalar` 明確拒絕以 `'`、`{`、`[`、`&`、`*`、`>` 開頭的值，使不支援的 YAML 形狀成為明確錯誤；並修正 implementation notes 的敘述使其與實作一致。
- reviewer source: Reviewer A
- 驗證: 直接以該讀取器解析上述四種形狀，均回傳保留原字元的字串而非報錯。

**F3 — cash-cli master spec 的「24-skill variant parity」措辭未列入 delta**

- severity: Warning
- confidence: 100
- layer: design
- location: `openspec/changes/cash-skill-maintainability/implementation-notes.md:17-22`；`openspec/specs/cash-cli/spec.md:900`
- summary: `implementation-notes.md` 的 `open-question` 條目未解決——對等機制已改為重新生成 freshness 檢查，但 cash-cli master spec 仍以「24-skill variant parity」描述 `skill-checks.fish` 的治理範圍，而本 change 的 cash-cli delta 只 MODIFIED `Live namespace 與歷史邊界`。
- recommendation: 向使用者取得確認，二選一：維持現狀（該措辭描述被治理的性質而非機制），或經 `/cash-ingest` 擴充 cash-cli delta 改寫該句。
- reviewer source: Reviewer A
- introduced_by: 不適用（Reviewer A 依 Implementation Notes Protocol 將 `open-question` 條目提報為 Warning）。

**F4 — `remove_section` 的終止線搜尋無上界，會靜默刪除無關內容**

- severity: Warning
- confidence: 80
- layer: design
- location: `scripts/cash-skills/generate.fish:194-208`
- summary: `## Claude fork context` 段落若缺少自己的 `---` 終止線，`lines.index(terminator, start + 1)` 會一路找到檔案後方任何一條無關的 `---`，把中間全部內容刪除，且以 exit 0 結束、無任何診斷。
- recommendation: 把搜尋上界收在下一個 `^## ` 標題：在該標題之前找不到終止線時 `die()`，使未終止的 fork 段落成為明確錯誤而非靜默截斷。
- reviewer source: Reviewer B
- introduced_by: 新檔 `scripts/cash-skills/generate.fish:201` 的 `stop = lines.index(terminator, start + 1)`，由 `scripts/cash-skills/variant-rules.yaml:19-22` 的 `terminator: "---"` 規則驅動；此路徑取代了被刪除的 `scripts/cash-skills/variant-parity/*.diff`（原本以逐行範圍釘住被移除的內容）。
- 驗證: 在暫存 root 為 `cash-commit` 注入一段未終止的 fork 段落，後方隔著 `## KEEP ME A` 才出現 `---`；生成器 exit 0，輸出檔案中 `KEEP ME` 出現次數為 0。

### Suggestion

- **S1**（Reviewer B，confidence 75，layer design，`scripts/cash-skills/generate.fish:178-191`）：`strip_frontmatter_keys` 只丟棄 key 自身那一行，block 形式的 `disallowedTools:` 值會留下孤兒的 `  - Edit` / `  - Write` 續行並黏到前一個 key 之下，產生無效 frontmatter，而 `assert_well_formedness` 的 `^(context|agent|disallowedTools):` 斷言看不見。introduced_by: 新檔 `generate.fish:186-190` 的 list comprehension。已實測重現。（原始 confidence 75，經 confidence filter 降為 Suggestion）
- **S2**（Reviewer B，confidence 70）：`rules.get("skills")`、`per_skill.get(skill)`、`entry.get("patches")` 三處的空值 fallback 使拼錯的鍵名靜默失效，是讀取器唯一還會「安靜產生錯誤輸出」的路徑。
- **S3**（Reviewer B，confidence 85，`scripts/cash-skills/tests/skill-checks.fish:178-187`）：`assert_generated_fresh` 在 staging 階段失敗時未清理 `mktemp -d` 目錄，與後兩個失敗路徑不一致。
- **S4**（Reviewer A，confidence 60）：新 SHALL「四份 gate 區段在正規化後 MUST 逐字相同」目前只靠建構方式成立，沒有常設斷言；`apply_patch` 在 gate 注入之後執行且不限制匹配位置。
- **S5**（Reviewer A，confidence 55）：`assert_grader_immutability` 的受保護路徑字面值清單未隨 Contract 第 7 項擴充三個新路徑。
- **S6**（Reviewer A，confidence 65）：YAML 受限讀取器的 deviation 未回填 `design.md` D2，其支援形狀的 contract 目前不存在於任何持久 artifact。（原始 confidence 65，經 confidence filter 降為 Suggestion）

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **4**（F1、F2、F3、F4）
- 非阻斷 triaged finding count: **0**
- critical_gap: **false**
- round_type: **full**

rationale：本輪為未 seed 執行的第一輪，因此通過 confidence filter 後存活的每一筆 Critical 與 Warning 都是阻斷性的。無 Critical，故 `critical_gap` 為 `false`；但 F1 到 F4 四筆 Warning 全部存活且全部阻斷，其中 F1、F4 已以暫存 root 的實際生成實測重現，F2 以直接解析驗證，F3 是 Implementation Notes Protocol 要求提報的未決 `open-question`。存在阻斷性 Warning 即不得判為 `passed`，故本輪為 `next_round`。

## Fix Actions

**Sub-agent 失敗處置**

- Reviewer B 的第一次呼叫因 session limit 於工具第 2 步中斷、輸出不完整，依 failure handling 規則以全新 sub-agent 重試該角色一次並取得完整輸出。同一輪內該角色未連續失敗兩次，不觸發 abort。
- 兩位 reviewer 以相同 context、彼此看不到對方輸出的方式各自獨立呼叫；因上述重試，實際為先後而非同一則訊息平行送出。獨立性未受影響。

**Disposition 與降級軌跡**

- Reviewer A 提出的「`CONTEXT-ENGINEERING.md` 為未宣告的新增檔案」（原 Warning，confidence 75）經查證為 false positive：該檔案是使用者自行建立的 Anthropic context engineering 指引摘錄，未被本 change 任何 task 或 Implementation Contract 項目產生，也不在本次 diff 內，屬「未被本 change 修改的既有內容」這一類 common false positive。confidence 調整為 0，不列入存活 findings。
- Reviewer A 提出的「`CASH-SKILLS.md` 仍稱 24 個 SKILL.md 為 canonical，與新詞彙表 `variant` 條目的 avoid 用語衝突」原標記 `layer: text`，但其修正會連帶更動 `scripts/cash-skills/tests/skill-checks.fish` 釘住的字面值 `24 個 canonical`，即會影響行為，依 confidence filter 規則改判為 `layer: design`；其 confidence 45 低於 50，依規則丟棄，降級軌跡記於此。

**本輪修正**

1. **F1** — 修改 `openspec/changes/cash-skill-maintainability/specs/cash-skill-workflows/spec.md`：Example 表前兩列改為生成模型下 freshness 確實偵測不到的缺陷類別，並改寫 `Codex 變體帶有 Claude 專屬 frontmatter 使套件失敗` Scenario 的 AND 子句。
2. **F2** — 修改 `scripts/cash-skills/generate.fish`：`read_scalar` 拒絕 flow-style、anchor、alias 與 folded 指示字元開頭的值；同步修改 `openspec/changes/cash-skill-maintainability/implementation-notes.md` 的 deviation 敘述使其與實作一致。
3. **F3** — 以 AskUserQuestion 取得使用者確認，使用者選擇「維持現狀」：「variant parity」描述的是被治理的性質（變體一致性），該性質未變，達成手段的變更已由 `cash-skill-workflows` 的 MODIFIED requirement `變體對等比較完整的受治理本文` 涵蓋，不擴充 cash-cli delta。依 Implementation Notes Protocol 於 `implementation-notes.md` 追加一筆解決條目，原 `open-question` 條目保留不刪改。
4. **F4** — 修改 `scripts/cash-skills/generate.fish`：`remove_section` 的終止線搜尋上界收在下一個 `^## ` 標題，找不到時 `die()`。
5. **S1** — 修改 `scripts/cash-skills/generate.fish`：`strip_frontmatter_keys` 移除 key 行後一併處理其縮排續行，block 形式的值不再留下孤兒行。
6. **S2** — 修改 `scripts/cash-skills/generate.fish`：驗證 `skills:` 之下每個鍵名對應實際存在的 `.claude/skills/cash-*` 目錄，且每個 entry 的鍵名限於 `description` 與 `patches`，否則 `die()`。
7. **S3** — 修改 `scripts/cash-skills/tests/skill-checks.fish`：`assert_generated_fresh` 的 staging 失敗路徑補上暫存目錄清理。
8. **S4** — 修改 `scripts/cash-skills/tests/skill-checks.fish`：`assert_generated_fresh` 加入四份 gate 區段正規化後逐字相同的斷言。
9. **S5** — 修改 `scripts/cash-skills/tests/skill-checks.fish`：`assert_grader_immutability` 的字面值清單補上三個新受保護路徑。
10. **S6** — 修改 `openspec/changes/cash-skill-maintainability/design.md` D2：回填受限 YAML 子集讀取器的決定與其支援形狀。

修正涉及的受保護 grader 檔案（`scripts/cash-skills/generate.fish`、`scripts/cash-skills/tests/skill-checks.fish`）由 proposal `## Impact` 的 affected-code 條目明確指名，屬結構化範圍宣告內，修改合法。`scripts/cash-skills/variant-rules.yaml` 本輪未被修改。本輪無 `未修復：裁判面保護` 紀錄。

**修正後驗證**

- F1 修正後的 Example 表四列全部以暫存 root 實測：列 1（源頭空 code span 忠實生成）freshness 通過／良構失敗；列 2（frontmatter 移除清單被縮減後重新生成並提交）freshness 通過／良構失敗；列 3（Codex-only 空 code span 寫入 per-skill patch）freshness 通過／良構失敗；列 4（Claude-only fork 段落由移除規則產生）freshness 通過／良構通過。四列與實作一致。
- F2 修正後，把 `frontmatter_remove_keys` 改寫為 flow sequence 使生成器以 `generate: unsupported YAML scalar form` 非零結束。
- F4 修正後，未終止的 `## Claude fork context` 段落使生成器以 `... without its --- terminator` 非零結束，不再靜默刪除後續內容。
- S1 修正後，block 形式的 `disallowedTools:` 值連同其縮排續行一併移除，生成的 `.agents` frontmatter 不再出現孤兒 sequence 項目。
- S2 修正後，未知 skill 名稱與非 `description`／`patches` 的 entry 鍵名分別以 `declares an unknown skill` 與 `must have exactly description and patches` 非零結束。
- 生成器修正未改變合法輸入的輸出：重新生成後 `.agents` 與 `.claude` 兩側檔案與修正前逐位元組相同，連續兩次執行無任何檔案變更。

**修正後機械自我檢查**

- spec delta 的 `<!--`／`-->` 計數平衡，無未閉合註解或殘留 `---` 分隔線。
- Example 表資料列數為 4，與 Scenario 敘述一致；文中已無「源頭與輸出都帶」的舊措辭。
- 識別字交叉比對通過：`assert_generated_fresh`、`normalized_gate_hash`、`staging_failed` 與三個新受保護路徑在各 artifact 與變更檔案中拼寫一致。
- `scripts/cash-skills/tests/skill-checks.fish` 全套與 `scripts/cash-cli/tests/cli-checks.fish` 全套皆以 exit 0 通過。
- 本輪自我檢查未發現需修正的項目。

**Outside-change-directory 檔案記錄**

- 本輪 Fix Actions 修改的 change 目錄以外檔案：`scripts/cash-skills/generate.fish`、`scripts/cash-skills/tests/skill-checks.fish`。兩者已以 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record --path` 記錄成功，無警告。未修改 `.cash-skills/` 之下的 runtime 檔，故不需重建 receipt。

## Decision

next_round
