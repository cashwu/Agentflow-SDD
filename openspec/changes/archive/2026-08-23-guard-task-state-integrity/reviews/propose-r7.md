# Cash Propose Review — Round 7

**本輪性質**：這不是標準 gate run 的一輪。本 change 的 cash-propose review loop 已於 round 6 以 `decision: passed` 結束（6 輪上限）。round 6 依規則把六筆非 blocking `Suggestion` 以 triage 處理而未修復；使用者其後要求修復該六筆，主 agent 在 gate 通過**之後**才套用這些編輯，因此它們從未被任何 reviewer 審查。本輪是使用者要求的補驗證，延續 round-file 編號寫為第 7 輪，進場時 cumulative blocking set 為空，無成員需給判定。

## Reviewer Findings

### Critical

（無）

### Warning

（無）

### Suggestion

1.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `design.md` D4 第二個 bullet
- `summary`: 該 bullet 以「`items = list(touched["touched"])` 是 shallow copy，就地改寫在兩側同步可見」作為「單靠 `updated != touched` 不足」的理由，但 IC4 第 2 點已 MUST 要求對齊在深層複本上運作、MUST NOT 就地改寫傳入物件，因此該理由描述的是設計明文禁止的機制。結論（寫入條件取**或**）不受影響。
- `recommendation`: 改寫理由句為「handler 取得的 `touched` 已是對齊後的物件，`updated` 由它衍生，合併為 no-op 時該比較恆為 False」。
- `disposition`: `new`
- reviewer source: Reviewer V — Verification
- 附註：根因是 round 5 finding 3 的深層複本修復未傳播到 D4 的理由句，round 6 未涵蓋；非本輪六筆編輯之一所引入。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `0`
- 非 blocking 的 triaged finding 數：`1`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：本輪為使用者要求的補驗證，進場時 cumulative blocking set 為空。Reviewer V 對六筆 gate 後編輯逐筆給出判定：F1、F2、F3、F5、F6 皆 `landed`，F4 為 `landed-with-defect`——其指名的 delta spec 與 `proposal.md` 兩處已修好，但驗證掃描另發現 `design.md` D4 有第三處相關殘留（即 finding 1）。Reviewer V 的驗證深度足以支撐這些判定：F1 逐條核對四條步驟 5 判準的檔案順序與其對應的 IC2 條目（並比對 `.claude/skills/cash-archive/SKILL.md` 確認 `validation_failed` 段落確以 `once the findings are judged acceptable.` 起頭）；F3 逐條 diff master spec 確認恰好兩條 MODIFIED scenario 各多一行 AND、其餘九條逐字相同；F5 核對 `.cash-skills/lib/cash_cli/workspace.py` 確認 `exists()` → `path_kind()` → `os.stat(follow_symlinks=False)` 對 symlink 在任何讀取之前即拋 `unsafe_path`，且 `read_bytes()` 對目錄回 `read_failed`、非 UTF-8 回 `invalid_encoding`，三者皆為 `CashError`，故三動作邊界可以單一 `except CashError` 實作、而把對齊迴圈置於 try 之外即不會吞掉 D3／D7 自拋的 `touched_invalid`；F6 確認新 scenario 與 `tasks.py` 的 `touched record` handler 相容且不與 MODIFIED 的 `重複記錄相同路徑不寫入` 衝突。本輪唯一 finding 經 confidence filter 後為 `Suggestion`，無 `Critical` 或 `Warning` 存活，故無新成員進入 cumulative blocking set，pass 條件成立。

## Fix Actions

**confidence filter 降級與丟棄紀錄**

- Reviewer V 另報一筆 `proposal.md` 第 4 點的動作句可能因 F4 編輯而失去 `MUST` 的 finding，`confidence: 30`。主 agent 以編輯前的原字串定案複核：該句原文為「描述找得到但 id 不符時（插入或刪除條目造成的整體位移）就地改寫 `task_id`；」，本就不含 `MUST`，F4 的編輯只刪去「就地」二字，未移除任何 `MUST`。該 finding 為**誤報**（Reviewer V 因 `proposal.md` 為 untracked、無 git 歷史可查而自行保守給分）。`confidence: 30 < 50`，依 confidence filter 丟棄，downgrade trace 記於此。
- finding 1 `confidence: 65` ∈ `[50, 80)`，原即為 `Suggestion`，維持。
- 無 `layer` 重分類：finding 1 為 `design`，被丟棄的誤報原標 `text`。

**非 blocking finding 的處置**

- finding 1：triage note——本輪一併修復。該理由句描述的機制正是 IC4 明文禁止者，留著會使實作者把 shallow copy ＋ 就地改寫當成 D4 的操作模型。修改 `design.md` D4 第二個 bullet 的理由句為「依 IC4 第 3、5 點，handler 取得的 `touched` 已是對齊後的物件，而 `updated` 由它衍生——當 `--path` 的合併是 no-op 時 `updated == touched`，該比較恆為 False，即使對齊相對於磁碟內容已有差異」，並以括號標明 `## Context` 記錄的 shallow-copy 性質是對齊前的既有程式碼、不能再作為本條理由。該 bullet 的 `MUST` 規範（寫入條件取**或**）未改動，本次修改無規範內容變更。

**六筆 gate 後編輯的驗證結論**

Reviewer V 明確陳述：六筆編輯本身是乾淨的，每一筆都落在 round 6 `recommendation` 指定的位置、內容與其規格相符，未發現任一編輯引入行為或 contract 層面的缺陷，也未發現應同步而未同步的第三方 artifact。F4 的 `landed-with-defect` 判定針對的是同一概念在 `design.md` 的第三處殘留，該處非 F4 編輯範圍所及，已於本輪修復。

**post-fix mechanical self-check 結果**

- 跨 artifact 傳播檢查：十個關鍵概念全部 `OK`，exit `0`。
- `就地改寫` 在 `design.md` 現存三處，逐一確認皆為正確用法：`## Context` 的問題描述、IC4 第 2 點的禁止句、以及本輪新寫的括號說明（明說它不再是合法手段）。本 change 的其他 artifact（`reviews/` 之外）已無該詞。
- comment/annotation lint：兩份 delta 的 `<!--`／`-->` 與 stray `---` 皆為 `0`。
- count-consistency：`cash-cli` delta ADDED `14` 條、MODIFIED `11` 條；`tasks.md` 的「依 IC4 六點施作」與 IC4 實際條目數相符；IC1–IC10、D1–D11 無空洞。
- spec delta title-identity：`### Requirement: touched record 記錄 review loop 產出` 與 master spec 逐位元相符。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。

**fix 後的重新驗證**

- `.cash-skills/bin/cash validate guard-task-state-integrity` 通過；`analyze` 無 `Critical`。
- `tasks.md` 中 24 條可直接執行的 `rg` 判準對現行（實作前）工作樹逐條執行，極性全部符合宣告，`0` 筆不符。
- 任務 0.1 的七條前置閘門判準在 `fish` 下**全部 exit 0**——`27ea397` 提交 `default-spec-sync-on-archive` 後，七個重疊路徑皆已乾淨，該閘門由本輪之前的全數擋下翻轉為全數通過，本 change 的實作前置條件因此滿足。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪唯一修改落在 `openspec/changes/guard-task-state-integrity/design.md`，濾除 `openspec/changes/` 前綴後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

passed
