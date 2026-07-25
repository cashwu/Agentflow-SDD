# Cash Propose Review — Round 1

## Reviewer Findings

本輪為 full round，spawn 兩個獨立 reviewer（Reviewer A — Adherence、Reviewer B — Quality），各自收到相同 context 且互不傳遞輸出。程序偏差記錄：兩者是先後而非同一則訊息平行 spawn，獨立性未受影響（B 未收到 A 的輸出），但未符合「in parallel in one message」的字面要求；後續回合改正。

findings 依 `location + summary` 聚合後套用信心過濾。合併紀錄：A 第 3 筆與 B 第 6 筆為同一缺陷（tasks 1.1 的紅燈判準與測試層級），A 第 5 筆與 B 第 8 筆為同一缺陷（cash-propose 的 fix actions 豁免前提不成立），A 第 7 筆與 B 第 2 筆為同一缺陷（裁決為排除後無去向）。合併後取較嚴重的 `severity` 與較高的 `confidence`。

### Critical

- `severity`: Critical / `confidence`: 92 / `layer`: design / `location`: `specs/cash-cli/spec.md` ADDED requirement ↔ `openspec/specs/cash-cli/spec.md:366` / reviewer: A
  - `summary`: master requirement `Change 與 artifact lifecycle` 規定「第一次Cash touched access MUST統一透過`touched ensure <name>`」，而新 verb 在 `cash-propose` 情境下必然是第一次 touched access，delta 卻只 MODIFIED 了 `Cash workflow command surface`、未修訂此條，merge 後 master spec 自相矛盾。
  - `recommendation`: 增列 MODIFIED，或改為要求 `touched record` 在 state 不存在時失敗並由 skill 先呼叫 `touched ensure`。
  - 主 agent 覆核：master 該句實測存在於 line 366；`cash-propose/SKILL.md` 全檔確無 `touched ensure`／`in-progress add`／`task done` 呼叫，宣稱成立。

### Warning

- `severity`: Warning / `confidence`: 95 / `layer`: design / `location`: `tasks.md` 任務 1.1 驗證目標；`design.md` C4 / reviewer: A（第 3 筆）＋B（第 6 筆，合併）
  - `summary`: 驗證目標宣稱「七個新測試因 `record` 尚不存在而失敗（`invalid_arguments`）」，但案例 (d) 斷言的正是 `invalid_arguments`，現行 `execute()` 的 fallback 已回該 code，(d) 在紅燈階段會通過——驗收在指定時點不可達。B 另指出測試層級問題：該檔既有 helper 只回傳 `Workspace.discover(root)`，全檔測試直接呼叫 library 函式，而 (d) 的 argument 解析行為只存在於 `execute()`，需要 chdir 進 temp root；`cli-checks.fish` 以單一 process 執行 `unittest discover`，chdir 是跨檔共享的全域狀態。
  - `recommendation`: 依實際層級分開描述紅燈預期，並明寫 chdir helper 與其 cleanup。

- `severity`: Warning / `confidence`: 90 / `layer`: design / `location`: `design.md` C1 的 `--json` 條目 / reviewer: A
  - `summary`: `--json` 無 spec 背書、無任務驗證、無消費者，卻受 master `統一 JSON 與錯誤契約` 約束。
  - `recommendation`: 補 spec 與測試，或直接刪除。

- `severity`: Warning / `confidence`: 88 / `layer`: design / `location`: `design.md` 決策六與 C3；`specs/cash-skill-workflows/spec.md` 共用判定 / reviewer: B
  - `summary`: 共用判準只比對 change 名稱、不比對存在性，而 signal 的 `links` 在 change 封存時不會被改寫。實測本 workspace 91 個帶 links 的 signal 檔中有 35 個 links 跨越多個 change，將使 signals write step 每併入一個既有 signal 幾乎必然觸發裁決提示，把例外裁決訓練成無條件按過。
  - `recommendation`: 判準收斂為「該 link 指向的 change 目錄目前仍存在」。
  - 主 agent 覆核：以現況實跑判準，跨多個 change 者 35 個、跨多個 **active** change 者 **0** 個；加上存在性條件可把誤判歸零。宣稱成立。

- `severity`: Warning / `confidence`: 82 / `layer`: design / `location`: `design.md` C1「以 `load_or_import_touched` 取得目前狀態」 / reviewer: A
  - `summary`: `load_or_import_touched` 在 Cash state 缺失而 legacy 檔存在時會執行 legacy import，使 `touched record` 成為第二個 legacy import 進入點；delta 的失敗模式未列 `legacy_touched_invalid`，且「`legacy_import` 原值 MUST 保留」在 import 情境下未定義。
  - `recommendation`: 明確定義 record 在該情境的行為並補對應 scenario 與測試。

- `severity`: Warning / `confidence`: 82 / `layer`: design / `location`: `specs/cash-skill-workflows/spec.md` ADDED 第一條；`design.md` 決策七 / reviewer: A（第 5 筆）＋B（第 8 筆，合併）
  - `summary`: 「cash-propose 的 fix actions 只動 change 目錄內的 artifacts」是對目前行為的觀察而非機制保證——grader-immutability 條款明文允許主 agent 在 structured scope declaration 涵蓋下以 fix action 修改 change 目錄外的受保護檔案，且該條款為兩個 skill 共用。寫成 `MUST NOT 因此新增呼叫` 之後，未來要補記反而變成違反 spec。
  - `recommendation`: 改為條件式：以「是否修改了 change 目錄之外的檔案」為判準。

- `severity`: Warning / `confidence`: 80 / `layer`: design / `location`: `design.md` C3；`.claude/skills/cash-commit/SKILL.md` step 2a / reviewer: B
  - `summary`: C3 的兩個機制都以 touched 的 `review-loop` 條目為錨點，但封存會刪除 touched state，改由 `archive-manifest.json` 的 `touched_files`（頂層聯集、無條目粒度）承接。「先封存再提交」這條路徑因此既沒有 `### Review Loop Outputs` 也沒有共用裁決，共用檔會靜默納入——正是本變更宣稱要消除的行為，且 `cash-apply` 的封存指引本身就在提醒使用者容易走這條路。
  - `recommendation`: 讓 step 2a 對其來源允許清單中位於 `openspec/signals/` 的路徑套用同一組判定與裁決。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings（`confidence ∈ [50, 80)`），皆已於本輪修復：

- `confidence`: 78 / reviewer: B — `touched record` 不驗證路徑存在或正規形式，`./openspec/signals/foo.md`、`signals/foo.md`、目錄路徑或打錯的檔名都會「記錄成功」卻永遠匹配不到 dirty 檔，於是真正的檔案照樣漏 commit，且 CLI 回報成功。這是第一個把未經 git 驗證的外部字串寫進 touched 的入口。
- `confidence`: 78 / reviewer: B — 記錄失敗只印警告，而最可能的觸發條件（review loop 的 fix action 改到 `.cash-skills/lib/cash_cli/` 使 launcher 全面 `receipt_invalid`）在本 repo 極常見；C4 的 receipt 常規只約束實作 task，未涵蓋 fix actions。
- `confidence`: 75 / reviewer: A（第 7 筆）＋B（第 2 筆，合併）— 共用檔被裁決為「整檔排除」後沒有任何條文說明去向；它仍在 tracking file 內因此不會落進 Unrelated，又已離開 Review Loop Outputs，會從 commit plan 完全消失。
- `confidence`: 72 / reviewer: A — proposal 寫「已修改的**實作檔**」而 design 與 spec 寫「已修改的**檔案**」，枚舉在三份 artifact 間漂移。
- `confidence`: 65 / reviewer: B — `_safe_source_path` 不擋 `openspec/changes/` 與 `.cash-skills/`，會破壞 touched 至今只含來源檔的不變量，使同一檔同時出現在 Change Artifacts 與 Review Loop Outputs 並被 stage 兩次。
- `confidence`: 65 / reviewer: B — 七個測試案例未涵蓋 spec 明文要求的「MUST NOT 改動 `tasks.md`」。
- `confidence`: 88 / `layer`: text / reviewer: A — Context 稱 touched 「只有一個寫入者」，實際上 `ensure_touched` 也會寫入，且 legacy import 時寫的是實質內容；連帶使決策四的論據失去區分基礎。
- `confidence`: 85 / `layer`: text / reviewer: A — requirement 內文列四類不安全路徑，scenario、C4 與 tasks 的案例集合都只列三類，一致漏掉 `.git/`。
- `confidence`: 55 / reviewer: B — round 1 reviewer 之前那一次 inline pre-round self-check 的修復不落在任何 `## Fix Actions`，因此也不會被記錄。

## Rating

- 過濾後累積 blocking 集合 Critical 數：1
- 過濾後累積 blocking 集合 Warning 數：6
- 非 blocking triaged finding 數：9
- `critical_gap`：true
- `round_type`：full
- 理由：本輪為本次執行的第一輪且未 seed，因此所有通過信心過濾的 `Critical` 與 `Warning` 皆為 blocking。累積 blocking 集合含 1 個 Critical 與 6 個 Warning，其中 master lifecycle requirement 未修訂、共用判準誤判兩項已由主 agent 實測覆核成立。未達通過條件，決策為 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/track-review-loop-outputs-in-allowlist/proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`（共 5 個檔案）。

blocking findings 的修復：

- master lifecycle requirement 未修訂（Critical）：改採 reviewer 建議的第二條路徑而非增列 MODIFIED——新增決策二，規定 `touched record` MUST 在 state 檔不存在時以 `touched_invalid` 失敗且零寫入、MUST NOT 執行 legacy import，呼叫端 MUST 先執行 `touched ensure`。這使 record 永遠不是第一次 access，master 不變量得以保留，因此不需要 MODIFIED 該 requirement。此修法同時消解了 legacy import 那筆 Warning。spec 新增 scenario「未先 ensure 時失敗」，C2 與 tasks 3.1 明寫先 ensure 再 record。
- legacy import 進入點（Warning）：由決策二一併解決——record 面對的永遠是已驗證的既有狀態，`legacy_import` 原值的語意不再有歧義；失敗模式列表據此重寫。
- 紅燈判準與測試層級（Warning）：C4 改為全部十個案例經由 `tasks.execute()` 驅動，並明寫 chdir helper 與 `addCleanup(os.chdir, previous)` 還原及其理由；紅燈預期改為「案例 (d) 會通過，其餘九個失敗」。tasks 1.1 同步。
- `--json` 無背書（Warning）：新增決策七，直接移除 `--json`；C1 與 spec 皆明寫 MUST NOT 提供。
- 共用判準誤判（Warning）：新增決策九，判準加上「該 link 指向的 change 目錄目前仍存在」；C3 加字面句 `only when that other change directory still exists`；spec 新增兩個 scenario（指向 active change 觸發、指向已封存 change 不觸發）；新增任務 5.1 要求落地前對現有 signals 實跑判準並把實測數字記入 `implementation-notes.md`。
- cash-propose 豁免前提（Warning）：新增決策八，呼叫時點改以「該輪是否修改了 `openspec/changes/<change>/` 之外的檔案」為條件，兩個 skill 一致；spec 的 MUST NOT 改寫為條件式並新增兩個 scenario。
- step 2a 繞過（Warning）：新增決策十一，step 2a MUST 對其來源允許清單中位於 `openspec/signals/` 的路徑套用同一組判定與裁決；C3 與 spec 各補一條，spec 新增 scenario「封存後路徑同樣套用共用裁決」。

非 blocking findings 的處置：九筆全部修復，未留 triage 待辦。

- 路徑驗證：新增決策四，`--path` MUST 依序通過 `_safe_source_path`、前綴拒絕（`openspec/changes/`、`.cash-skills/`）、`workspace.path_kind()` 為 `file` 三段檢查，任一失敗即整個 command 零寫入。此項同時涵蓋「破壞來源檔不變量」那一筆。spec 新增兩個 scenario，C4 新增案例 (f)(g)。
- 失敗可見性：新增決策十二，警告 MUST 列出未能記錄的路徑與 `error.code`、MUST 出現在最終完成輸出（字面句 `carry this warning into the final completion output`）；C4 的 receipt 常規擴大為涵蓋 review loop 的 fix actions 與 `.cash-skills/lib/cash_cli/` 之下的任何檔案。
- 排除後無去向：新增決策十，排除的共用檔 MUST 改列於 Unrelated Changes 並註明係使用者裁決排除、最終輸出 MUST 提醒該檔仍為 dirty；spec 新增 scenario。
- 枚舉漂移：proposal、design、spec 三處統一為「位於 `openspec/changes/<change>/` 之外的已修改檔案」。
- `tasks.md` 未被測試涵蓋：C4 新增案例 (j) 斷言 record 前後 snapshot 與 `tasks.md` 的 bytes 皆不變。
- Context 寫入者數目錯誤：改為「兩個寫入者：`mark_task_done` 與 `ensure_touched`」，並說明 ensure 在 legacy import 時寫入的是實質內容；決策五的理由改以「record 接受呼叫端提供的任意路徑」為區分基礎。
- `.git/` 漏列：spec scenario、C4 案例 (e) 與 tasks 1.1 三處各補上 `.git/` 前綴。
- round 1 前 self-check 殘留：寫入 Non-Goals 與 Risks，明列為刻意留下的殘留缺口與理由。

fix 傳播：決策二的 ensure-before-record、決策四的三段路徑驗證、決策八的條件式呼叫、決策九的 active-change 條件、決策十的排除去向、決策十一的 step 2a 套用、決策十二的失敗可見性七個概念，都同時同步到 design 決策段、C1／C2／C3／C4、tasks 各任務與兩份 delta spec。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--`／`-->` 皆為 0）通過；數量一致性（決策 15 條、C1–C4 連號、C4 的案例 (a)–(j) 為 10 個且與 tasks 1.1 一致、`## Impact` 的 Modified 為 10 條）通過；十個識別字與字面句跨 artifact 交叉比對一致；spec delta title-identity check：`### Requirement: Cash workflow command surface` 逐字存在於 master spec，通過；`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，改採既有 best-effort 判斷，並據此對現有 signals 實跑了決策九的判準。

修復後重跑 `.cash-skills/bin/cash validate track-review-loop-outputs-in-allowlist`：通過。

## Decision

next_round
