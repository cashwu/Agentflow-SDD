# Cash Apply Review — Round 4

## Reviewer Findings

本輪為當前 run 的第二輪，`round_type: micro`，由單一 fresh sub-agent **Reviewer V — Verification** 執行 delta 驗證。apply-r3 以 `decision: next_round` 結束，cumulative blocking set 有三個 member。

### 每個 cumulative blocking set member 的判定

1. **apply-r3 Finding 1（negation-containment 斷言順序）— `resolved`**。Reviewer V 親自重現：現行順序為 `assertNotIn` → 結構規則 `assertTrue` → `assert_rejected` → `assert_accepted`，containment 斷言為每個 category 的第一項。把 `red-after-edit` 還原為 modal 起始形式 → `FAILED (failures=1)`，唯一失敗即具名的 containment 訊息，`assert_accepted` 未執行。**`tasks.md` 3.1 記錄的 red 證據已完全可重現**：同時還原四個 subject-dropped 的 pre-3.1 literal → `FAILED (failures=4)`，四筆皆為具名 containment 訊息，與 3.1 `red:` 欄位所記逐字相符。Reviewer V 另認定 apply-r3 記錄的「已知殘餘」敘述誠實：`assert_accepted` 確實嚴格蘊含 `assertNotIn`，這是數學必然而非缺陷；D2 的「不得以另一個較早失敗取代目標 guard」因被蘊含者現排在蘊含者之前而滿足。驗證者：Reviewer V。
2. **apply-r3 Finding 2（`LEGITIMATE_PROSE` 無錨定）— `resolved`**。Reviewer V 把嵌入式 checker 抽出對真實 repo root 執行：baseline exit 0；清空 `LEGITIMATE_PROSE` → exit 1 並輸出兩筆具名 record；只移除其中一個 token → exit 1 並輸出對應的單筆具名 record。錨定位置確實在 `leaked` 檢查之前。驗證者：Reviewer V。
3. **apply-r3 Finding 3（§Risks 覆蓋缺口敘述失準）— `resolved`**。Reviewer V 不採信改寫後的條目，自行對 HEAD 的 11 個 explicit literal 重跑 acceptance 檢查：10 句被接受、僅 `red 不適用時可以留空` 以 `forbidden tasks contradiction: blank-red` 被拒。改寫後的條目逐字枚舉的正是那 10 句、正確指出 `blank-red` 為唯一逐字倖存者，且「11 個 explicit forbidden literal」的計數與 HEAD 的 3+4+4 相符。判定為 factually exact。驗證者：Reviewer V。

三個 member 全部以 verified resolution 離開 cumulative blocking set，post-filter cumulative blocking set 為空。

### 非阻塞 finding 的 fix 複驗（apply-r3 Findings 4–7）

Reviewer V 逐一以 mutation 複驗，全部成立：`label` 綁定（塌縮 scope → `FAILED (failures=6)`；只改 `label` 字串 → `FAILED (failures=4)`）；`NEGATION_PARTICLES` exact-set 對縮減與擴增皆失敗；13 句 restatement 經程式化驗證**全部**是嚴格內插位置的純單一否定詞插入（插入位置 2–28，`不`×11／`並非`×2，無附加文字），故 D5 的「13 句一律採保留主詞的同序否定」敘述準確；三種掏空皆 `FAILED (failures=13)`；D5 的 13 句與 `EXPECTED_NEGATION_RESTATEMENTS`、D1 的 13 個 literal 與三個 detector dict 皆逐字相等；已被取代的免責條款確實已從 `design.md` D5 與 cash-cli spec 兩處移除；reshape 未削弱對 modal 起始或 subject-dropped 退化的攔截，且仍由 containment 斷言以具名訊息攔下。Findings 6、7 的 §Risks 條目經 Reviewer V 實測與敘述相符。

### Suggestion

1. `severity`: Suggestion｜`confidence`: 75（原始 `severity` 為 `Warning`）｜`layer`: design｜`disposition`: fix-introduced｜`introduced_by`: apply-r3 `## Fix Actions` 的「**Finding 5（非阻塞，已修復並升級判準）**」與「**免責條款同步更正**」｜`location`: `openspec/changes/refine-cash-tdd-test-guards/specs/cash-cli/spec.md`｜`summary`: 被取代的判準殘留在 spec——該句仍同時寫著「測試 MUST斷言每句非空且含`不`或`並非`」與結構規則兩個 MUST，但 fix actions 宣告前者已被後者**取代**，`design.md` D5 與 C1 都只保留結構規則，程式碼也沒有對應的獨立斷言。該殘留子句正是 Reviewer B 證明可被掏空的判準（13 句單字元 `不` 即滿足「非空且含否定詞」而 suite 全綠），留在 durable spec 等於重新授權它｜`recommendation`: 刪除該子句，只保留結構規則的 MUST，與 `design.md` D5／C1 一致｜reviewer source: V

2. `severity`: Suggestion｜`confidence`: 70（原始 `severity` 為 `Warning`）｜`layer`: design｜`disposition`: fix-introduced｜`introduced_by`: apply-r3 `## Fix Actions` 的「**Finding 2（阻塞）**」｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 prose token 錨定，對照 `design.md` C3／D5 與 `specs/cash-skill-workflows/spec.md`｜`summary`: 新增的 fish 側守衛沒有任何 artifact 依據——Findings 1、4 各自補了 C1 條目，兩項既有的 fish 側守衛（canonical anchor、值相等）也都寫進 C3 與 cash-skill-workflows spec，唯獨此項兩者皆無，且未記入 `implementation-notes.md`｜`recommendation`: 補 C3 條目與 spec 語句，或依 Implementation Notes Protocol 記為 `deviation`｜reviewer source: V

3. `severity`: Suggestion｜`confidence`: 55｜`layer`: design｜`disposition`: fix-introduced｜`introduced_by`: apply-r3 `## Fix Actions` 的「**Finding 2（阻塞）**」｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 `for token in ("expected value", "verification target"):`｜`summary`: 該 pattern 在 fish 側未如 Python 側般終止——錨定自身的比對來源是無 exact-set 斷言的行內 tuple。實測：同時清空該 tuple 與 `LEGITIMATE_PROSE` → exit 0、群組靜默全綠。Reviewer V 認定這比原缺陷弱（需兩處協同修改且其一就在檢查內部），明確表示不視為阻塞｜`recommendation`: 選擇性。若要封閉，比照 Python 側慣例改為具名常數加 exact-set 斷言，或於 §Risks 記載此 token 清單即為終點｜reviewer source: V

### Reviewer V 對「pattern 是否終止」的結論

Python 側**已終止**：本輪新增的每個 gate input 最終都落在斷言運算式內部直接書寫的 literal 集合（`{"不", "並非"}`、13 個 category 集合、各 inventory 的 category 集合），而 `label`／`canonical`／`validator` 三者透過具名 `assert_rejected` 訊息自我綁定。唯一剩下的無錨定輸入是 D1／D5 逐字清單與 `design.md` 之間沒有執行期綁定，該項已是具名的 §Risks 條目。fish 側則終止得弱一級，即上列 Suggestion 3。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非阻塞 triaged finding count：0
- `critical_gap`: false
- `round_type`: micro

rationale：apply-r3 的三個 cumulative blocking set member 全部由 Reviewer V 以親自重現的 mutation 判定為 `resolved`，依 verified resolution 規則離開 blocking set。本輪新增三筆 finding，其中兩筆原始 `severity` 為 `Warning`、`confidence` 分別為 75 與 70，一筆原始即為 `Suggestion`、`confidence` 55；三者皆落於 `[50, 80)` 或原本即為 `Suggestion`，經 confidence filter 後無任何 finding 維持 `Critical` 或 `Warning`，因此 `disposition: fix-introduced` 不使其成為阻塞（阻塞判定只適用於 post-filter 後仍為 `Critical` 或 `Warning` 的 finding）。post-filter cumulative blocking set 為空，符合 pass 條件。

## Fix Actions

本輪雖為 `passed`，仍就兩筆非阻塞 finding 做了修正，因為它們與本 change 反覆出現的「artifact 敘述與實際交付不符」屬同一類，且其中一筆會隨封存併入 master spec 而產生持續影響。

修改的檔案：`openspec/changes/refine-cash-tdd-test-guards/specs/cash-cli/spec.md`、`openspec/changes/refine-cash-tdd-test-guards/implementation-notes.md`。

- **Suggestion 1（已修復）**：刪除 cash-cli spec 中殘留的「測試 MUST斷言每句非空且含`不`或`並非`，」子句，只保留結構規則的 MUST，與 `design.md` D5／C1 及程式碼一致。修正後 grep 確認該子句出現次數為 0，且程式碼中對應的舊訊息 `carries no negating particle` 出現次數亦為 0。
- **Suggestion 2（已依 Reviewer V 提供的第二個選項處理）**：於 `implementation-notes.md` 追加一筆 `deviation` 條目，記錄 fish 側 legitimate-prose 錨定為超出 C3 明文的守衛、其反向驗證結果、未觸發 `/cash-ingest` 的理由，以及後續若要提升為 contract 的對稱做法。
- **Suggestion 3（triage note，不修復）**：Reviewer V 自身評估為「比原缺陷弱、明確不視為阻塞」且標示為選擇性。封閉它需在 fish 內再引入一層具名常數與 exact-set 斷言，而該常數本身又會成為下一個終點；本 change 選擇停在此處並將其列於完成輸出，交由使用者決定是否另開 change 處理。
- **Confidence filter 降級 trace（不計入 ledger `fixed_files`）**：Reviewer V finding 1 原始 `severity` 為 `Warning`、`confidence` 75；finding 2 原始 `severity` 為 `Warning`、`confidence` 70。兩者皆落於 `[50, 80)` 而降級為 `Suggestion`。兩者 `disposition` 皆為 `fix-introduced` 且附有可驗證的 `introduced_by`（指向 apply-r3 `## Fix Actions` 的具體條目），主 agent 已就 fix-touched location 複核並確認該 disposition 正確，無需修正。無 `confidence < 50` 的 finding 被丟棄。
- 無 `未修復：裁判面保護` 紀錄。無 accepted-risks 降級（該檔不存在）。無 disposition 修正。
- **修正後重跑驗證**：`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py` → 28 tests OK；`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline` → `PASS: tdd-discipline`；`"$cash_cli" analyze` → 0 Critical/Warning；`"$cash_cli" validate` → Validation passed。本輪修正只觸及 artifact 文字，未改動任何實作檔，故不重跑全量 regression（apply-r3 fix actions 後的全量 `fish scripts/cash-skills/tests/skill-checks.fish` 已為 `PASS: all`、exit 0）。

## Decision

passed
