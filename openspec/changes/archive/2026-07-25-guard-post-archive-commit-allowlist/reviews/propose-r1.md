# Cash Propose Review — Round 1

## Reviewer Findings

本輪為 full round，spawn 兩個獨立 reviewer（Reviewer A — Adherence、Reviewer B — Quality），各自收到相同 context 且互不傳遞輸出。findings 依 `location + summary` 聚合後套用信心過濾。合併紀錄：Reviewer A 第 5 筆與 Reviewer B 第 1 筆為同一缺陷（step 7 讀取已移走路徑），合併後取較嚴重的 `severity` 與較高的 `confidence`；Reviewer A 第 6 筆與 Reviewer B 第 7 筆為同一缺陷（機械斷言弱於 normative 陳述），Reviewer A 第 7 筆與 Reviewer B 第 9 筆為同一缺陷（測試 fixture 不滿足 `_validate_touched` 聯集檢查）。

### Critical

- `severity`: Critical / `confidence`: 100 / `layer`: design / `location`: `proposal.md` `## Impact` 與 `tasks.md` 全篇 / reviewer: A
  - `summary`: 本變更改動 `.cash-skills/lib/cash_cli/commands/archive.py` 與四個 `SKILL.md`（皆為 replaceable 檔案），但未宣告也未提升 `cash-skills.version`，`test_bundle_version_history.py` 的 `check_history` 在 `current == head` 時會逐檔比對引入 commit 的 bytes，必然失敗。
  - `recommendation`: `## Impact` 加入 `cash-skills.version`，並新增版本提升任務。
  - 主 agent 覆核：實測 `cash-skills.version` 與 `git show HEAD:cash-skills.version` 皆為 `2.3.1`，且 `skill-checks.fish` 的 `assert_installer` 確實呼叫該測試檔，宣稱成立。

- `severity`: Critical / `confidence`: 100 / `layer`: design / `location`: `tasks.md` 任務 2.1 與 5.1 / reviewer: A
  - `summary`: 改動 `archive.py` 之後未重建 `.cash-skills/receipt.tsv`，`.cash-skills/bin/cash` 會在任何 dispatch 之前以 `receipt_invalid: runtime record drift` 全面失敗，使後續 `validate` 與 cash-apply 自身的 `task done` 皆不可達。
  - `recommendation`: 新增可重複執行的 receipt 重建任務，首次緊接在 runtime 改動之後、最後一次在版本提升之後。
  - 主 agent 覆核：`.cash-skills/bin/cash` 於 dispatch 前呼叫 `validate_receipt`，其中 runtime 記錄逐檔比對 sha256；`.cash-skills/receipt.tsv` 確有 `runtime .cash-skills/lib/cash_cli/commands/archive.py` 記錄；`install-cash-skills.fish` 的 `--self` 旗標存在於 `installer.py` 的 `modes`，宣稱成立。

- `severity`: Critical / `confidence`: 88 / `layer`: design / `location`: `design.md` C2；`.claude/skills/cash-commit/SKILL.md` step 7 / reviewer: A（第 5 筆）＋B（第 1 筆，合併）
  - `summary`: 偵測成立代表 `openspec/changes/<name>/` 已被 archive 移走，但 step 7 仍寫死從該路徑讀 `proposal.md` 與 `tasks.md` 產生 commit message，復原路徑在使用者確認 commit plan 之後才撞上不存在的檔案；step 5 的「無可提交即 STOP」判定輸入同樣未同步。
  - `recommendation`: C2 增列 step 5 與 step 7 的來源改以封存目錄為準，spec 補對應 scenario。

### Warning

- `severity`: Warning / `confidence`: 85 / `layer`: design / `location`: `tasks.md` 任務 3.1 驗證目標 / reviewer: A
  - `summary`: 任務 3.1 只改 `.claude` 變體，驗證目標卻是整組 `codex-command-matrix`；該群組同時掃 `.agents`，在任務 3.2 完成前必然失敗，驗收準則在指定時點不可達。
  - `recommendation`: 3.1 的驗證目標改為只針對該單一檔案的字面句檢查，整組通過留給 3.2。

- `severity`: Warning / `confidence`: 85 / `layer`: design / `location`: `.claude/skills/cash-commit/SKILL.md` step 2 的 `Cash state is the only allowlist authority after this point.` / reviewer: B
  - `summary`: 該絕對句未被要求改寫，與新增的 `2a`「改以 archive manifest 的 `touched_files` 為來源」在同一份文件內形成直接矛盾指令，執行 agent 有充分理由依 step 2 拒絕 `2a` 的來源。
  - `recommendation`: 該句 MUST 加上 `2a` 例外，並把改寫後的字面句納入機械斷言集合。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings（`confidence ∈ [50, 80)`），皆已於本輪修復：

- `confidence`: 78 / `layer`: design / reviewer: B — `2a` 成立時 step 6 仍提供 `Archive first, then commit together`，使用者選它會得到 `change_not_found`，流程在確認之後死路。
- `confidence`: 75 / `layer`: design / reviewer: A — C2 未要求同步修改 step 4 的 `NOT in the tracking file` 判定句，也未規定 manifest 來源清單在 step 5 的呈現方式（現行格式強制以 task 分組，而 `touched_files` 不含 task 粒度）。
- `confidence`: 72 / `layer`: design / reviewer: B — `specs_synced` 為 true 時無條件納入 `master_digests` 所列全部 `openspec/specs/` 路徑，會把並行 change 對同一 master spec 的 dirty 編輯靜默掃進提交。
- `confidence`: 70 / `layer`: design / reviewer: A（第 6 筆）＋B（第 7 筆，合併） — 機械斷言弱於 normative 陳述：最載重的「三條偵測條件」與「任一條件 false 即維持既有行為」完全沒有斷言，且 `touched_files` 這種泛詞在文中任何位置出現即通過；`cash-cli` spec 的「其他 manifest 欄位不受影響」scenario 沒有任何對應驗證步驟。
- `confidence`: 70 / `layer`: design / reviewer: B — requirement 同時要求「必須取得使用者確認才繼續」與「MUST NOT 全部歸 Unrelated」，但未定義選項集合與合法終止狀態，形成未治理出口。
- `confidence`: 62 / `layer`: design / reviewer: A（第 7 筆）＋B（第 9 筆，合併） — 任務 1.1 的 fixture 描述不滿足 `_validate_touched` 的「頂層 `files` 必須恰為各 `touched` 條目 `files` 之聯集」檢查，紅燈會以 `touched_invalid` 失敗而掩蓋應觀察的 `touched_files` 缺席。
- `confidence`: 60 / `layer`: design / reviewer: B — `touched_files` 只是封存當下快照，審查迴圈 fix 階段之後的改動不會進 touched state，非空即被當成權威等於替不完整清單加上權威標籤。
- `confidence`: 58 / `layer`: design / reviewer: B — 偵測條件 2 只排除 active 位置，未排除 `openspec/changes/.parked/<change-name>/`，同名 parked change 會被舊封存的 `touched_files` 誤導。
- `confidence`: 50 / `layer`: design / reviewer: B — 不同日期的同名封存是合法狀態，「比對到多於一個目錄」直接升級為使用者確認，會在可自動消歧的情形上打斷流程。

## Rating

- 過濾後累積 blocking 集合 Critical 數：3
- 過濾後累積 blocking 集合 Warning 數：2
- 非 blocking triaged finding 數：9
- `critical_gap`：true
- `round_type`：full
- 理由：本輪為本次執行的第一輪且未 seed，因此所有通過信心過濾的 `Critical` 與 `Warning` 皆為 blocking。累積 blocking 集合含 3 個 Critical 與 2 個 Warning，其中兩個 Critical 已由主 agent 直接對照程式碼與腳本覆核成立（bundle version history 關卡、receipt runtime digest 關卡），第三個 Critical 由兩個 reviewer 獨立提出。未達通過條件，決策為 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/guard-post-archive-commit-allowlist/proposal.md`、`design.md`、`tasks.md`、`specs/cash-skill-workflows/spec.md`（共 4 個檔案）。`specs/cash-cli/spec.md` 未修改。

blocking findings 的修復：

- bundle version（Critical）：`## Impact` 的 Modified 加入 `cash-skills.version`；design 新增決策十說明兩道 bundle 關卡；tasks 新增任務 5.1（提升為 `2.4.0`，驗證目標為 `python3 scripts/cash-skills/tests/test_bundle_version_history.py`）。
- receipt 重建（Critical）：design 決策十與 C4 記載重建規則；tasks 新增任務 2.2（可重複執行，首次緊接任務 2.1）與任務 5.2（版本提升後的最後一次重建），驗證目標為 `.cash-skills/bin/cash validate --all` exit 0。
- step 7 讀取已移走路徑（Critical）：design 新增決策六，把 artifact 集合、step 5 的 STOP 判定輸入、step 6 的選項可用性、step 7 的 proposal 與 tasks 讀取路徑一併改以封存目錄為準；C2 增列對應的 step 3／4／5／6／7 改寫要求；spec 的 scenario 由「封存後的 artifact 集合取自封存目錄」擴寫為「封存後的 artifact 與 commit message 來源取自封存目錄」並加上四個 THEN／AND 步驟。
- 任務 3.1 驗收不可達（Warning）：驗證目標改為對 `.claude/skills/cash-commit/SKILL.md` 單一檔案逐一執行 `rg -F`，整組 `codex-command-matrix` 通過改由任務 3.2 承接。
- step 2 絕對句矛盾（Warning）：C2 增列該句 MUST 改寫為帶例外的形式並逐字包含 `except when step 2a establishes a post-archive recovery source`，該字面句同時進入任務 1.2 的斷言集合。

非 blocking findings 的處置：本輪 9 個降級為 `Suggestion` 的 finding 全部一併修復，未留 triage 待辦——step 6 選項可用性（決策六）、step 4 判定句與 step 5 呈現（C2）、spec sync 以 digest 判定歸屬（決策七）、斷言集合由 5 個擴充為 10 個字面句並改綁最載重判定句（C4 與任務 1.2）、確認選項集合與合法終止狀態（決策五）、fixture 聯集要求（C1 與任務 1.1）、時點快照標示（決策八）、parked 位置（決策二）、封存目錄兩層消歧（決策四）。

fix 傳播：`.parked` 條件、消歧規則、時點快照、終止狀態、`master_digests` 判定五個概念都同時同步到 design 決策段、C2 要素清單、C4 斷言清單、tasks 任務 1.2／3.1 與 spec scenario，未只改被指出的單一位置。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--`／`-->` 皆為 0、無殘留 `---` 分隔線）通過；數量一致性（決策一至十連號無缺、C1 至 C4 連號、cash-commit 八個字面句與 cash-apply 兩個字面句在 design 與 tasks 一致、C1 三個測試與任務 1.1 三個測試一致、`## Impact` 的 Modified 為 8 條）通過；十三個識別字與字面句跨 artifact 交叉比對一致；delta 皆為 `## ADDED Requirements`，spec delta title-identity check 不適用；`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，改採既有 best-effort 判斷，未觸發額外檢查。

修復後重跑 `.cash-skills/bin/cash validate guard-post-archive-commit-allowlist`：通過。

## Decision

next_round
