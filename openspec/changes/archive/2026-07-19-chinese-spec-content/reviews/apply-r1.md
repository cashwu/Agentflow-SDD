# Cash Apply Review — Round 1

## Reviewer Findings

### Warning

- `severity`: Warning｜`confidence`: 90｜`layer`: design｜來源: Reviewer A + Reviewer B（合併）
  - `introduced_by`: 本次 diff 將 42 個 `### Requirement:` 標題翻譯為中文，同時依 C3 不變量保留內文英文標題 code spans（spec 內 38 處，行 1108、2102 等；另 SKILL.md 共用 grader-immutability 段 4 檔各 2 處引用 quality-gate 標題）
  - `location`: openspec/specs/cash-skill-workflows/spec.md 38 處；.claude/.agents 的 cash-propose/cash-apply SKILL.md 各 2 處
  - `summary`: 標題中文化後，以 backtick 引用 requirement 標題的規範性交叉參照全部斷鏈——design C3「code-span 位元組不變」不變量與標題翻譯在此類字面上互相矛盾，實作忠實遵守不變量反而凍結斷鏈；propose 三輪 triage 均未預見。
  - `recommendation`: 46 處引用改為對應中文標題；C3 增列第二個明示允許差異來源（逐一對應驗證）。
- `severity`: Warning｜`confidence`: 80｜`layer`: design（自 text 重分類：修正影響規範判定敘述）｜來源: Reviewer B
  - `introduced_by`: 本次 diff 對 openspec/specs/cash-skill-workflows/spec.md 行 2590（「Abort 後的 triage」bucket 1 定義句）的翻譯
  - `location`: openspec/specs/cash-skill-workflows/spec.md:2590
  - `summary`: 原文 "every cumulative-blocking-set member not accepted through consent" 譯為「未經同意被接受」，中文最自然讀法為「被接受了但未經同意」（依 ledger 規則是空集合），bucket 1 是重跑 seed 母集合，屬判定性邊界的否定範圍歧義。
  - `recommendation`: 改為「未經由同意路徑被接受」。

### Suggestion（非阻擋，已列入 triage）

- A2（confidence 65，降級）：4.2/C6 驗收字面未豁免 review loop 依 spec 合法寫入的 signals 產物，字面條件不可能成立。已順手修正 design C6 與 tasks 4.2 措辭。
- A3（confidence 60）：implementation-notes.md 零 entries——標題引用張力值得一則紀錄。已補一則 deviation entry。
- B-S1（confidence 60）：master spec 行 222 前向引用「Spec 檔案語言政策」在 archive 合併前懸空，合併後自癒（過渡期現象，無行動）。
- B-S2（confidence 65）：新測試錨點僅斷言 cash-propose，apply/ingest 的政策句無字面斷言——與 C5 宣告範圍一致、非 regression，屬 `policy-surface-enumeration-incomplete` issue class，建議 follow-up 補強。

## Rating

- post-filter cumulative blocking set：Critical 0、Warning 2（unseeded run 首輪，全部 surviving 均 blocking）
- 非阻擋 triaged findings：4
- `critical_gap`: false
- `round_type`: full
- 理由：兩位 reviewer 對六項 Implementation Contract 的機械主張全數獨立重跑無失實（含完整測試套件、validate、hash、不變量、verbatim 清單），翻譯抽查與高風險條款核對零語意反轉；兩個 blocking Warning 集中在「翻譯 × 字面不變量」交界（標題引用斷鏈、bucket 1 否定歧義），均已修復待驗證。

## Fix Actions

- design.md：C3 增列第二個允許 code-span 差異來源（內部標題引用隨標題翻譯，逐一對應驗證）；C6 驗收豁免 signals 產物（A2）。
- tasks.md：4.2 驗收措辭同步豁免 signals 產物（A2）。
- openspec/specs/cash-skill-workflows/spec.md：38 處內部標題引用改為對應中文標題；行 2590 bucket 1 改為「未經由同意路徑被接受」（B1）。
- .claude/.agents 的 cash-propose/cash-apply SKILL.md：grader-immutability 段各 2 處 quality-gate 標題引用改為中文標題（共 8 處，4 檔逐字一致）。
- implementation-notes.md：補一則 deviation entry 記錄 C3 例外（A3）。
- 修復後驗證：span diff 恰等於宣告替換集合（removed==expected、added==expected）；shared_gate_hash 兩變體各自相等；`spectra validate chinese-spec-content --strict` 通過；fish scripts/cash-skills/tests/skill-checks.fish PASS、exit 0。
- 修改檔案：design.md、tasks.md、openspec/specs/cash-skill-workflows/spec.md、.claude/skills/cash-propose/SKILL.md、.claude/skills/cash-apply/SKILL.md、.agents/skills/cash-propose/SKILL.md、.agents/skills/cash-apply/SKILL.md、implementation-notes.md。

## Decision

next_round
