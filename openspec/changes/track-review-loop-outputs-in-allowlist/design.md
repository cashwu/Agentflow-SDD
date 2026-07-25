## Context

`.cash-skills/state/touched/<name>.json` 是 `cash-commit` 的來源檔允許清單唯一權威。它目前有兩個寫入者：`mark_task_done`（task loop 中由 `cash task done` 觸發，以 git 指紋對 snapshot 差分）與 `ensure_touched`（第一次 touched access 時建立狀態；在 legacy `.spectra/touched/<name>.json` 存在時，經 `_import_legacy` 寫入的是實質內容而非空殼）。

review loop 在所有 task 都 `[x]` 之後才跑，之後不會再有任何 `task done`。因此：

- signals write step 寫出的 `openspec/signals/*.md` 永遠不在 touched 內。它們也不在 `openspec/changes/<name>/` 之下，`cash-commit` step 3 的 artifact filter 同樣接不到，於是落進 step 4 的 Unrelated。
- review loop 的 fix actions 若改到之前沒有任何 task 碰過的檔案，該檔同樣不在 touched 內。

review round 檔（`reviews/*.md`、`loop-ledger.tsv`）不受影響，因為它們住在 change 目錄內。

限制可行解的既有事實：

- `cash-propose` 從不執行 `in-progress add`，因此 propose 迴圈**沒有 snapshot**。任何以 snapshot 差分為基礎的補記在 propose 迴圈不可用，而實測案例中 6 個 signal 檔有 5 個是 propose 迴圈寫的。
- `openspec/signals/` 是跨 change 的共享記憶層，同一個 signal 檔可被多個 change 各自追加 occurrence 條目。git 的 staging 粒度是檔案，**無法把單一檔案依 change 拆分**。
- 既有 master requirement `Change 與 artifact lifecycle` 規定「第一次Cash touched access MUST統一透過`touched ensure <name>`」，並把 legacy import 的 fail-closed 語意綁在 ensure 上。新 verb 必須維持這個不變量，否則會成為第二個 legacy import 進入點。
- master requirement `Cash workflow command surface` 以封閉列舉列出 CLI「提供且僅需支援」的 command families，其中 `touched` 只列了 `touched ensure`。新增 verb 必須以 MODIFIED 修訂該 requirement。
- `touched` 已列於 launcher 的 `MUTATING_FAMILIES` 與 `main.py` 的 `COMMANDS`，`emit_help` 只輸出 top-level command family 名稱，因此新增 `touched` 的第二個 verb 不需要改 `main.py`。
- `git_fingerprints` 以 `_IGNORED_PREFIXES` 排除 `openspec/changes/`、`.cash-skills/state/` 與 `.cash-skills/receipt.tsv`，因此 touched 的 `files` 至今是一個純來源檔集合。`cash-commit` 的 Change Artifacts／Source Files／Unrelated 三分法建立在這個不變量上。

## Goals / Non-Goals

**Goals**

- 讓 review loop 的產出經由既有的 touched 權威進入 `cash-commit` 的提交集合，不新增第二個允許清單來源。
- 在 `cash-propose`（無 snapshot）與 `cash-apply`（有 snapshot）兩種情境下都成立。
- 讓被多個**進行中** change 共同修改的 signal 檔在 commit plan 上可見並要求裁決，同時不對已封存 change 的歷史 link 誤判。
- 維持 touched 只含來源檔、且第一次 access 一律經由 `touched ensure` 的既有不變量。
- 兩個 skill 變體維持既有的對等關係。

**Non-Goals**

- 不嘗試把單一檔案依 change 拆分 staging。
- 不改變 `cash task done`、`ensure_touched`、`mark_task_done`、`load_or_import_touched`、`git_fingerprints` 的行為。
- 不讓 `cash-propose` 執行 `in-progress add` 或建立 snapshot。
- 不改變 signals write step 對 signal 內容的判定規則（target set、matching rubric、slug 規則、schema）。
- 不追溯補記既有已封存 change 的 review loop 產出。
- 不涵蓋「本次執行第一輪 reviewer 之前」那一次 inline pre-round self-check 的修復；該次修復發生在任何 round file 存在之前，沒有 `## Fix Actions` 可作為錨點（見 Risks）。

## Decisions

**決策一：以明確路徑記錄，而非 snapshot 差分**

差分需要 baseline，而 propose 迴圈沒有 snapshot；就算補建 snapshot 也會把同一時間其他來源的 dirty 改動誤記進來。signals write step 與 fix actions 本來就明確知道自己寫了哪些檔，明確路徑的歸屬精確且與 snapshot 生命週期解耦。

**決策二：`touched record` 不得是第一次 touched access**

`touched record` MUST 在 `.cash-skills/state/touched/<name>.json` 不存在時以 `touched_invalid` 失敗且零寫入，並 MUST NOT 執行 legacy import。呼叫端 MUST 先執行 `touched ensure "<change-name>"`。

這個選擇同時解決兩件事：維持 master requirement `Change 與 artifact lifecycle` 的「第一次 access 一律經由 ensure」不變量（因此不需要 MODIFIED 該 requirement），並使 legacy import 的 fail-closed 語意繼續只有 ensure 一個進入點——record 面對的永遠是一份已驗證的既有狀態，不必定義「`legacy_import` 原值」在 import 情境下的意義。

**決策三：保留條目 `task_id` 為 `review-loop`，與 per-task 條目並存**

`_validate_touched` 對 `task_id` 只要求「非空、唯一的字串」，因此保留字不需 schema 變更。用獨立條目而非併入某個既有 task，是為了讓 `cash-commit` 能把 review loop 產出與 per-task 來源檔分開呈現——掛在最後一個 task 之下會產生假的 attribution。`task_desc` 固定為 `Review loop outputs`。

**決策四：路徑必須是既存的一般檔案，且維持 touched 的來源檔不變量**

`--path` 的值來自呼叫端的任意字串，這是第一個把未經 git 驗證的外部字串寫進 touched 的入口——`mark_task_done` 的路徑來自 `git_fingerprints`，結構上只可能是實際存在的 dirty 路徑。若不驗證，`./openspec/signals/foo.md`、`signals/foo.md`、目錄路徑或打錯的檔名都會「記錄成功」卻永遠匹配不到任何 dirty 檔，於是真正的檔案照樣漏 commit——與本變更要修的失效形態完全相同，而且 CLI 回報成功、沒人會察覺。

因此每個 `--path` MUST 依序通過：

1. `_safe_source_path` 的既有檢查（拒絕絕對路徑、含 `..`、以 `.git/` 或 `.cash-skills/state/` 開頭）。
2. 前綴拒絕：以 `openspec/changes/` 或 `.cash-skills/receipt.tsv` 開頭者 MUST 以 `touched_invalid` 失敗。這組前綴刻意與 `git_fingerprints` 的 `_IGNORED_PREFIXES` 對齊（該常數只含 `.cash-skills/state/`、`.cash-skills/receipt.tsv`、`openspec/changes/`），使 record 的前綴拒絕規則與 `mark_task_done` 的來源檔集合一致。兩者仍非完全等價：第 3 段的存在性檢查使 record 記不下已刪除的路徑與 rename 的來源路徑，而 `git_fingerprints` 會把兩者記入 touched（`_worktree_fingerprint` 對刪除檔回 `absent`、porcelain kind `2` 顯式加入 rename source）。record 的可記錄集合因此是 `mark_task_done` 的真子集；此缺口與其後果記於 Risks。`.cash-skills/state/` 已由第 1 段的 `_safe_source_path` 涵蓋。MUST NOT 拒絕整個 `.cash-skills/` 前綴：`.cash-skills/lib/` 與 `.cash-skills/bin/` 之下共 20 個 git-tracked 來源檔，且 `.cash-skills/lib/cash_cli/` 正是 apply 迴圈 fix actions 最典型的目標（本變更自身要改的 `tasks.py` 即在其中），全面拒絕會把它們永久排除在 record 之外，只留下決策十二的警告——等於把靜默漏檔換成有警告的漏檔。
3. `workspace.path_kind()` MUST 回傳 `file`；`missing`、`directory` 與 `other` MUST 以 `touched_invalid` 失敗。symlink MUST 以 `path_kind` 既有的 `unsafe_path` 失敗（該函式對 symlink 是 raise 而非回傳 kind），此為與其他型別不同的 error code，spec 需明寫以免合併後宣告與實作不符。

任一 path 失敗時整個 command MUST 零寫入。

**決策五：驗證 change 存在**

`touched record` MUST 在寫入前確認 `openspec/changes/<name>/` 為目錄，否則以 `change_not_found` 失敗。record 接受呼叫端提供的任意路徑並寫入實質內容，名稱打錯時會產生一份內容錯誤的孤兒 state；ensure 的輸入則完全由既有 state 或 legacy 檔決定，兩者的風險不同。

**決策六：no-op 不寫入**

合併後的 touched 值與載入值完全相同時，`touched record` MUST NOT 寫入。重複執行同一組路徑不得改變 inode、mtime 或 bytes。這直接對應 open signal `noop-command-persists-state` 描述的反模式。

**決策七：不提供 `--json`**

兩個呼叫點都不消費輸出，spec 也不需要為它定義契約。不加無消費者的輸出表面。

**決策八：呼叫時點以「是否在 change 目錄之外」為條件，而非以 skill 為條件**

- signals write step 完成後（兩個 skill 皆適用）：以該步驟實際建立或更新的每個 signal 檔路徑呼叫。
- fix actions 完成後（兩個 skill 皆適用）：若該輪的 `## Fix Actions` 記錄了任何位於 `openspec/changes/<change>/` **之外**的已修改檔案，以那些路徑呼叫；只改動 change 目錄內 artifacts 的輪次不需呼叫。

原本考慮把 fix actions 的呼叫限定為 cash-apply，理由是「cash-propose 的 fix actions 只動 change 目錄內的 artifacts」。但那是對目前行為的觀察，不是任何機制保證的性質：review loop 的 grader-immutability 條款明文允許主 agent 在 structured scope declaration 涵蓋下，以 fix action 修改 `openspec/specs/`、`skill-checks.fish` 與四個 SKILL 檔等 change 目錄外的檔案，而該條款是兩個 skill 共用的。寫成 skill 條件式會在 propose 真的碰到外部檔案時把它推回同一個洞，而且用 MUST NOT 鎖死之後連補記都變成違反 spec。

**決策九：共用判定只看仍存在的 active change**

判準為：該 signal 檔 frontmatter `links` 中，形如 `openspec/changes/<other>/reviews/` 且 `<other>` 不等於本 change 名稱、**且 `openspec/changes/<other>/` 或 `openspec/changes/.parked/<other>/` 其中之一目前仍存在**者。parked change 未封存、其對共用 signal 的追加同樣可能尚未提交，只看 active 位置會漏判成非共用而靜默納入。

只比對名稱不比對存在性會造成大規模誤判：signal 的 `links` 在 change 封存時不會被改寫，永遠保留原路徑形狀。對本 workspace 現況實測，帶 links 的 signal 檔中有 35 個的 links 跨越多個 change，但跨越多個仍進行中（active 或 parked）之 change 的是 **0** 個。若不加存在性條件，signals write step 每併入一個既有 signal（README 明列這是常態路徑）幾乎必然觸發裁決提示，把例外裁決訓練成無條件按過，真正無法拆分的那一次反而失去把關效力。

**決策十：裁決結果必須有明確去向**

使用者選擇整檔納入時，該檔留在其所屬的來源檔區段——一般路徑為 `### Review Loop Outputs`，step 2a 路徑為該路徑的單一未分組清單（step 2a 不帶條目粒度，沒有該區段）。選擇整檔排除時，該檔 MUST 改列於 `### Unrelated Changes (not included)` 並註明使用者裁決排除，且最終輸出 MUST 提醒該檔仍為 dirty。

被排除的檔案仍在 tracking file 的 `files` 內，而 step 4 的 Unrelated 判定是「不在 artifact set 且不在 tracking file」，因此若不明寫去向，它會既不在 Review Loop Outputs 也不在 Unrelated——從 commit plan 完全消失。那正是本 proposal 引用為動機的 open signal `exclusion-without-matching-inclusion` 的形狀：只宣告離開哪個輸出、沒宣告加入哪個輸出。

**決策十一：封存後路徑同樣套用共用裁決**

`cash-commit` 的 step 2a（封存後空允許清單復原）以 `archive-manifest.json` 的 `touched_files` 為來源允許清單，該欄位取自 touched 的頂層 `files` 聯集，因此 signal 路徑確實在內；但 step 2a 明文以單一未分組清單呈現，不帶條目粒度。若不處理，「先封存再提交」這條路徑會既沒有 `### Review Loop Outputs` 區段、也沒有共用裁決，共用檔會靜默納入。

因此 step 2a MUST 對其來源允許清單中位於 `openspec/signals/` 的路徑套用決策九的共用判定與決策十的裁決，不依賴條目粒度。這條路徑並非邊緣：`cash-apply` 的封存指引本身就在提醒使用者容易先封存再提交。

**決策十二：記錄失敗不中斷，但必須可見且可行動**

`touched ensure` 或 `touched record` 任一失敗時 MUST 印出警告並繼續，MUST NOT 使 workflow 失敗，MUST NOT 改變任何 round file 的 `decision`。ensure 在此情境 MUST NOT 沿用 `cash-commit` 既有的「ensure 失敗即 STOP」語意——那會使迴圈在末端硬停。但警告 MUST 逐字列出未能記錄的路徑與 CLI 回傳的 `error.code`，且 MUST 同時出現在 skill 的最終完成輸出。

理由：signals 寫入失敗只是少一筆記憶，`touched record` 失敗則等於該檔不進允許清單，也就是本變更要修的靜默漏檔換一個入口回來。而最可能的觸發條件在本 repo 極常見——只要 review loop 的 fix action 改到 `.cash-skills/lib/cash_cli/` 之下的檔案，launcher 的 receipt 驗證會使**其後每一個** `cash` 指令以 `receipt_invalid: runtime record drift` 失敗。因此 C4 的 receipt 常規 MUST 同時涵蓋 review loop 的 fix actions。

**決策十三：`cash-commit` 不新增允許清單來源，只新增呈現與裁決**

追蹤到的檔案經由既有的 touched 讀取自然進入提交集合，因此 `cash-commit` 不需要反查 signal `links` 之類的第二套發現機制——那會與既有契約 `Cash state is the only allowlist authority after this point` 衝突。

**決策十四：改動位置避開 grader 區塊**

`grader_hash` 只涵蓋 `<!-- GRADER-IMMUTABILITY -->` 到 `<!-- LOOP-LEDGER-STEP -->` 之間的區塊。signals write step 位於該區塊之後、fix actions 位於其之前，兩處改動都在區塊外。`cash-propose` 屬 `divergent_skills`，其變體差異由 `scripts/cash-skills/variant-parity/cash-propose.diff` 管制；本變更對兩個變體做逐字相同的改動，該 manifest 不需更新。

**決策十五：bundle 關卡**

`tasks.py` 與六個 `SKILL.md` 皆為 replaceable 檔案。`cash-skills.version` MUST 提升為嚴格大於 `git show HEAD:cash-skills.version` 的下一個 minor 版本（不得寫死常數）；`.cash-skills/receipt.tsv` MUST 在改動 `tasks.py` 的那個 task 收尾時、標記該 task 完成之前重建，最後一次重建 MUST 在版本提升之後、任何回歸執行之前。

## Implementation Contract

### C1 — `touched record` verb

- 檔案：`.cash-skills/lib/cash_cli/commands/tasks.py`。`main.py` MUST NOT 改動。
- 在 `execute()` 的 `command == "touched"` 分支內新增 `record` 子命令，既有 `ensure` 分支的行為 MUST 不變。
- 呼叫形式：`touched record <name> --path <path> [--path <path> ...]`。MUST NOT 提供 `--json`。
- 行為：
  - `openspec/changes/<name>/` 不是目錄 → `change_not_found`，零寫入（決策五）。
  - `.cash-skills/state/touched/<name>.json` 不存在 → `touched_invalid`，零寫入，且 MUST NOT 執行 legacy import（決策二）。存在時以 `_validate_touched` 驗證後使用。
  - 每個 `--path` 依決策四的三段檢查驗證，任一失敗即整個 command 零寫入。
  - 把通過驗證的路徑併入 `task_id` 為 `review-loop`、`task_desc` 為 `Review loop outputs` 的條目；該條目不存在時建立。條目內 `files` 與頂層 `files` 皆以 UTF-8 bytes 排序去重，頂層 `files` MUST 恰為各條目 `files` 的排序聯集，`legacy_import` 原值 MUST 保留。
  - MUST NOT 改動任何既有 per-task 條目、`tasks.md`、或 `.cash-skills/state/snapshots/<name>.json`。
  - 合併結果與載入值相同時 MUST NOT 寫入（決策六）。
- 失敗模式：`change_not_found`、`touched_invalid`（state 缺失、不安全路徑、被拒前綴、非既存一般檔案）、`invalid_arguments`（無 `--path`、`--path` 缺值、參數形狀不符）、`unsafe_path`（symlink，由 `path_kind` 既有行為產生）。
- 驗收：見 C4。

### C2 — review loop 呼叫 `touched record`

- 檔案：`.claude/skills/cash-propose/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`。四個檔的新增文字逐字相同。
- **兩個呼叫點共用的前置規則**：呼叫 `touched record` 之前 MUST 先執行 `"$cash_cli" touched ensure "<change-name>"`（決策二）。此規則對 signals write step 與 fix actions 兩處皆適用，且在 `cash-propose` 中尤其不可省——propose 的 `**Fix actions**` 區塊在文件中早於 `<!-- SIGNALS-WRITE-STEP -->`，且該 skill 全程沒有任何其他 touched access，因此 fix actions 呼叫點才是 propose 迴圈第一次接觸 touched state 的位置；漏掉 ensure 會使該次 record 以 `touched_invalid` 失敗並只留下一則警告，檔案照樣漏記。
- 在 `<!-- SIGNALS-WRITE-STEP -->` 區塊的 failure handling 之前新增一條規則，MUST 逐字包含 `record every signal file this step created or updated` 與 `"$cash_cli" touched record "<change-name>" --path <path>`。
- 在 `**Fix actions**` 區塊新增一條規則，MUST 逐字包含 `record the files that round's Fix Actions modified outside the change directory`，並指明只在該輪修改了 `openspec/changes/<change>/` 之外的檔案時才呼叫（決策八），且 MUST 同樣先執行 `"$cash_cli" touched ensure "<change-name>"`。
- fix actions 呼叫點 MUST 額外指明：若該輪 fix actions 改到 `.cash-skills/` 之下的 runtime 檔，MUST 先於 project root 執行 `./install-cash-skills.fish --self` 再呼叫 `touched ensure`／`touched record`，並 MUST 逐字包含 `rebuild the receipt before the next cash command`。理由見決策十二——launcher 在任何 dispatch 前逐檔比對 receipt 的 runtime digest，未重建時 ensure 與 record 都會以 `receipt_invalid` 失敗，使本變更的旗艦情境（apply 迴圈改到 CLI 實作）恰好是它必然失效的情境。C4 的 receipt 常規只約束實作本變更的人，不會隨變更出貨，因此這條 MUST 寫進 SKILL 文字本身。
- 呼叫協定（決策四的原子性與決策十二的 warn-and-continue 之交互）：此協定適用於**兩個呼叫點**。呼叫端 MUST 在呼叫前濾除位於 `openspec/changes/` 之下的路徑——注意觸發條件排除的是本 change 的目錄，而濾除規則涵蓋所有 change 的目錄，兩者範圍刻意不同；**濾除後若無任何路徑則不呼叫，且不產生警告**（否則會發出不帶 `--path` 的呼叫、換得一則 `invalid_arguments` 假警告）。整批呼叫失敗時 MUST 以逐路徑重試取得最大合法子集，警告只列出真正記不進去的路徑；單一壞路徑不得連坐掉同批的全部合法路徑。傳給 `--path` 的值 MUST 為 project-root-relative；`## Fix Actions` 若以其他形式記錄，呼叫前 MUST 先轉換。
- 兩處 MUST 指明失敗處理（決策十二）：`touched ensure` 或 `touched record` 任一失敗時，印出警告並繼續、不使 workflow 失敗、不改變任何 round file 的 `decision`；警告 MUST 列出未能記錄的路徑與 `error.code`，且 MUST 逐字包含 `carry this warning into the final completion output`。
- 兩處改動皆位於 grader 區塊之外；`grader_hash` 跨四個檔的一致性 MUST 不受影響；`scripts/cash-skills/variant-parity/cash-propose.diff` MUST 不需更新。

### C3 — `cash-commit` 呈現與共用裁決

- 檔案：`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`，兩者在 invocation 前綴正規化後 MUST 逐字相同。
- step 2 解析 touched 後，把 `touched` 陣列拆為 per-task 條目與 `task_id` 為 `review-loop` 的保留條目。
- step 5 的 commit plan 新增獨立的 `### Review Loop Outputs` 區段列示保留條目的檔案，與既有 Source Files 區段分開，並指明其屬於提交集合；MUST 逐字包含 `### Review Loop Outputs`。
- 共用判定（決策九）：對保留條目中位於 `openspec/signals/` 的檔案讀其 frontmatter `links`，只有當某條 link 形如 `openspec/changes/<other>/reviews/`、`<other>` 不等於本 change 名稱、且 `openspec/changes/<other>/` 或 `openspec/changes/.parked/<other>/` 其中之一目前仍存在時，該檔才標示為共用。MUST 逐字包含 `only when that other change directory still exists`。
- 裁決（決策十）：共用檔 MUST 以 **AskUserQuestion tool** 讓使用者選擇整檔納入或整檔排除，MUST 逐字包含 `a shared signal file cannot be split by change`；選擇排除時該檔 MUST 改列於 `### Unrelated Changes (not included)` 並註明使用者裁決排除，最終輸出 MUST 提醒該檔仍為 dirty。MUST NOT 靜默納入，MUST NOT 靜默排除。
- step 2a（決策十一）：MUST 對其來源允許清單中位於 `openspec/signals/` 的路徑套用同一組共用判定與裁決。
- step 4 的 Unrelated 判定 MUST 新增一條例外：經使用者裁決排除的共用 signal 檔即使仍在 tracking file 內，也 MUST 列入 Unrelated Changes 並註記係使用者裁決排除。此為對既有「不在 artifact set 且不在 tracking file 才算 Unrelated」規則的明確例外，不得只寫「其餘規則不變」而讓實作者推導出相反結論。
- step 6a 的 Updated Commit Plan 區段清單 MUST 同樣保留 `### Review Loop Outputs`，內容沿用 archive 前已確認的集合。
- step 6 的 `Commit as shown` 選項說明 MUST 明示涵蓋 `### Review Loop Outputs`（比照既有 `### Spec Sync Changes` 的括號寫法）。此為對「step 6 其餘規則不變」的明確例外：不補則「as shown」的字面枚舉不含該區段，review-loop 檔案可能在使用者選該選項時未被 stage。
- step 6 的 `Include all dirty files` 與 `Customize` 的加回路徑若涵蓋一個已被裁決排除的共用 signal 檔，MUST 先明確告知該操作會推翻先前的裁決並取得確認，MUST NOT 靜默納入；`Customize` 移除一個已裁決納入的共用檔時，MUST 一併移入 Unrelated Changes 並沿用同一註記，不得從 plan 消失。
- 除上述例外外，既有的 step 2a 偵測條件與 step 3／4／5／6／7 的其餘規則 MUST 不變。

### C4 — 測試與關卡

- `scripts/cash-cli/tests/test_creation_task_lifecycle.py` 新增 `touched record` 的十一個案例。全部經由 `tasks.execute()` 驅動，以與 `scripts/cash-cli/tests/test_runtime_and_errors.py` 的 `enter_workspace` 同形的 helper 進入 workspace：建立 temp git root、寫入 `.cash.yaml` 與 `openspec/config.yaml`、建立 0644 的 `.cash-workspace.lock`、`os.chdir` 進 root 並以 `self.addCleanup(os.chdir, previous)` 還原（`cli-checks.fish` 以單一 process 執行 `python3 -m unittest discover`，chdir 是跨檔共享的全域狀態，還原不可省）。
  - (a) 先 `touched ensure` 再 record 一個既存 signal 檔，建立含 `review-loop` 條目的合法 state；全程不需要 snapshot。
  - (b) 先 `task done` 產生 per-task 條目再 record，且 record 的路徑之一**與該 per-task 條目重疊**：既有條目逐字不變、兩條目並存、頂層 `files` 恰為兩者的排序聯集且無重複項（以 list 串接取代 set 聯集的實作會在此產生重複，且該狀態要到下一次載入才被 `_validate_touched` 攔下）。
  - (c) 重複 record 相同路徑時 state 檔的 bytes、`st_ino` 與 `st_mtime_ns` 皆不變。
  - (d) 未提供 `--path` 與 `--path` 缺值皆為 `invalid_arguments` 且零寫入。
  - (e) 絕對路徑、含 `..`、以 `.git/` 開頭、以 `.cash-skills/state/` 開頭四種路徑皆為 `touched_invalid` 且零寫入。
  - (f) `openspec/changes/` 與 `.cash-skills/receipt.tsv` 前綴皆為 `touched_invalid` 且零寫入；`.cash-skills/lib/cash_cli/commands/tasks.py` 這類 `.cash-skills/` 之下的既存一般檔案則 MUST 記錄成功（驗證依據是決策四第 3 段的存在性與型別檢查，不引入 git 追蹤狀態這個未被任何檢查背書的判準）。
  - (g) 不存在的路徑與目錄路徑皆為 `touched_invalid` 且零寫入。
  - (h) change 目錄不存在時為 `change_not_found`，且不建立 state 檔。
  - (i) 未先 `touched ensure`（state 檔不存在）時為 `touched_invalid`，且不建立 state 檔。
  - (j) record 前後 `.cash-skills/state/snapshots/<name>.json` 與 `openspec/changes/<name>/tasks.md` 的 bytes 皆不變。
  - (k) 單次呼叫混合多個合法路徑與一個非法路徑：以 `touched_invalid` 失敗，且 state 檔 bytes 逐字不變（單路徑案例無法區分「零寫入」與「不寫入」，此案例才真正覆蓋決策四末句的原子性 MUST）。
  - 紅燈預期：現行 `execute()` 對 `touched record ...` 一律以 `invalid_arguments` 失敗，因此案例 (d) 在紅燈階段**會通過**（它斷言的正是該 code），其餘十個案例失敗。驗證目標必須據此描述，不得宣稱十一個全部紅燈。
- `scripts/cash-skills/tests/skill-checks.fish`：
  - 在既有 codex consumer matrix 的字面句清單加入 `"$cash_cli" touched record "<change-name>" --path <path>`。
  - 對四個 review-loop SKILL 檔逐檔斷言 `record every signal file this step created or updated`、`record the files that round's Fix Actions modified outside the change directory`、`carry this warning into the final completion output`，以及 `"$cash_cli" touched ensure "<change-name>"`、`"$cash_cli" touched record "<change-name>" --path <path>`、`rebuild the receipt before the next cash command`（皆逐檔斷言而非依賴全域 consumer matrix，後者以 `rg -Fq -- "$literal" "$codex_root"/cash-*/SKILL.md` 一次 glob、任一命中即通過，且只掃 `.agents` 側）。
  - 對兩個 `cash-commit/SKILL.md` 斷言 `### Review Loop Outputs`、`a shared signal file cannot be split by change`、`only when that other change directory still exists`。
- 落地前 MUST 對現有 `openspec/signals/*.md` 實跑決策九的判準，確認**誤判數**為零——即不存在僅因指向已封存 change 的歷史 link 而被判為共用的 signal 檔。真陽性計數（真的被多個仍進行中之 change 共同修改者）是本變更存在的理由，會隨迴圈寫入而變動，MUST NOT 作為 pass 條件，只記入 `implementation-notes.md` 作為觀測值。signal 總數同理 MUST NOT 釘進驗收條件。
- 在四個 review-loop SKILL 檔與兩個 cash-commit SKILL 檔全部改完之前，任何**以通過為驗收**的 task MUST 以針對單一檔案的 `rg -F` 作為驗證目標；以整組失敗為紅燈目標的 TDD 任務不受此限。
- `cash-skills.version` 由 `git show HEAD:cash-skills.version` 推導為嚴格大於該值的下一個 minor 版本。
- receipt 常規（全域約束，不另立 task）：每一次改動 `.cash-skills/lib/cash_cli/` 之下的任何檔案之後、下一次執行任何 `.cash-skills/bin/cash` 指令之前，MUST 於 project root 執行 `./install-cash-skills.fish --self`。此常規同時適用於實作 task 與 review loop 的 fix actions（決策十二）。
- 驗證指令：`scripts/cash-cli/tests/cli-checks.fish all`、`scripts/cash-skills/tests/skill-checks.fish all`、`.cash-skills/bin/cash validate --all`。

### 範圍邊界

- MUST NOT 改動 `mark_task_done`、`start_in_progress`、`ensure_touched`、`load_or_import_touched`、`git_fingerprints`、`_safe_source_path`。
- MUST NOT 改動 `.cash-skills/lib/cash_cli/main.py`。
- MUST NOT 改動 `cash-archive` skill 或 `archive.py`。
- MUST NOT 改動 `scripts/cash-cli/tests/cli-checks.fish`。
- MUST NOT 改動 `scripts/cash-skills/variant-parity/cash-propose.diff`。

## Risks / Trade-offs

- **保留字 `review-loop` 與真實 task id 衝突**：`_task_entries` 以 `str(len(entries) + 1)` 產生十進位數字字串 task id，不可能碰撞。若未來規則改變，`_validate_touched` 只檢查唯一性不會攔下，後果是靜默併入同一條目而非失敗；屆時需重新檢視。
- **本次執行第一輪之前的 self-check 修復未被涵蓋**：review loop 在 round 1 的 reviewer 之前有一次 inline pre-round self-check，其修復發生在任何 round file 存在之前，沒有 `## Fix Actions` 可作為錨點，因此不會被記錄。這是刻意留下的殘留缺口（見 Non-Goals）；對 cash-apply 而言該次修復可能改到沒有任何 task 碰過的實作檔。
- **共用 signal 檔仍需人工裁決**：檔案粒度 staging 的固有限制，本變更不宣稱解決，只保證不靜默通過。代價是共用情形多一次互動。
- **`links` 判定依賴 frontmatter 格式**：`links` 缺失或格式異常時判定會落空而該檔被當成非共用。緩解方式是保留條目的檔案本來就完整顯示在 commit plan 上供過目，不是靜默納入。
- **路徑驗證要求檔案當下存在**：若某個 signal 檔在 record 與 commit 之間被刪除，record 當下仍會成功而該路徑之後匹配不到 dirty 檔。這與 `mark_task_done` 的既有行為一致，不另行處理。
- **已刪除與 rename source 路徑無法記錄**：第 3 段的存在性檢查使 record 的可記錄集合成為 `mark_task_done` 的真子集。若 review loop 的 fix action 刪除或搬移一個 change 目錄外的檔案，該路徑進不了允許清單，commit 會少掉刪除側、rename 會被提交成只有 add 的半套。刻意保留嚴格檢查，因為放寬到接受 `missing` 會讓打錯的檔名重新變成「記錄成功但永遠匹配不到」的靜默失效——那正是決策四要擋的形態。此缺口以 Unrelated 區段的可見性與決策十二的警告緩解。
- **字面句斷言只保證文字存在、不保證行為**：這是 skill 層可機械驗證的上限。C4 的九個字面句涵蓋兩個呼叫時點、失敗可見性、receipt 重建、`### Review Loop Outputs` 區段、共用裁決與 active-change 條件；`links` 解析細節、裁決後的去向、step 2a 與 step 6／6a 的套用、以及呼叫協定（濾除、空集合終止、逐路徑重試）仍只靠 spec 與 review 把關。
