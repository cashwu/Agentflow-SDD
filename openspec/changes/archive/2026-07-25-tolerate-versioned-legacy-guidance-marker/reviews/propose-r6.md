# Cash Propose Review — Round 6

本輪為 micro 輪，也是本次執行的第六輪、即 6 輪上限的最後一輪。由單一 Reviewer V — Verification 對 round 5 的 cumulative blocking set 做 delta 驗證，並執行最終全面收斂檢查。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 5 的 2 個 blocking 成員全數 `resolved`：

| member | verdict | 依據摘要 |
| --- | --- | --- |
| V1 | resolved | Risks 第三段第二個案例已逐字帶入「恰有一側帶字尾」並寫入三種形狀的實測結果。Reviewer V 獨立複測三個數字全部重現：兩側皆不帶字尾 `(6,49)` 對 `(6,49)` 完全相同、兩側皆帶字尾現行回傳無 span 而於檔尾附加 canonical、恰有一側帶字尾現行 raise 而新定位 `(6,52)`。敘述與實測一致 |
| V2 | resolved | `前置步驟` 在三個 artifact 中只剩一處，且該處已改為「不是 3.2 的前置步驟，而是完成回報時必須告知使用者的交付說明」；另一處同步。與 tasks 3.2 現況方向一致，矛盾消除 |

### round 5 降級的缺口檢查與最終收斂檢查

Reviewer V 逐項確認全部通過：delta 降級後的段落與 `Missing、Spectra-only 與 mixed guidance 收斂` 相容，無懸空引用，移入 D6 的 rationale 與 D6 既有內容自洽；requirement 正文 7 段**全部有 scenario 或 IC 承接，無懸空段落**；計數三處一致且與 tasks 實際 case 數相符；字尾字集敘述四處逐字一致；9 個 scenario、2 個 Example、IC1–IC8、15 個 task 三向對應無孤兒無重複；delta 標題、首段與三個保留 scenario 與 master 逐 byte 相同；design 引用的實測數字**無一為假**（Tubify 的三組 offset、D4 的兩個空行、D1 的雙向吞噬、`CASH-SKILLS.md` 的 14 條字面與五個 `fail closed` 出現行、`scripts/` 無 legacy start marker 字面、實跑 `--all --dry-run` 得 `failed=2` 且兩行正是那兩個 target 的 marker 訊息）。Reviewer V 以實作者視角逐條讀完 15 個 task，除 F2 記載的分類模糊外，沒有任何一項需要回頭提問或與另一項衝突。

### Warning

**F1**（confidence 95，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 4 `## Fix Actions` 的「修 Q1」寫入該段三個案例；round 5 的「修 V1」複查時誤判案例一為成立而未更正）

- `location`：`design.md` `## Risks / Trade-offs` 第三段的第一個案例，連帶 `proposal.md` 的對應敘述
- `summary`：round 5 的「修 V1」只補了第二個案例的前提，但第一個案例有完全相同的缺陷且未被更正。原文「另有一段 fenced 範例逐行寫出完整的 legacy start／內容／end。現行實作以孤立判定 fail closed」，如字面所寫（範例的 start 不帶字尾）在現行實作下並不 fail closed。
- 主 agent 獨立實測確認：範例 start 不帶字尾時現行與新定位皆為 `(47, 96)`，逐 byte 相同——「範例內容被刪除，只剩一組空的 fence」是現行實作今天就會做的事，不是本次容忍引入的行為改變。只有範例 start 帶字尾時該案例才成立（現行 raise、新定位 `(47, 103)`）。
- round 5 的 `## Fix Actions` 逐字宣稱「案例一與案例三經本輪 reviewer 重新實測皆成立，不改動」，而實際上主 agent 只複測了案例三，案例一是直接採信 reviewer 的敘述。

### Suggestion（非阻斷）

- **F2**（100，`unresolved-prior`，自 round 4 建立兩例外清單起即存在，歷輪未被觸及）tasks 前言宣告 red-first 只有兩個例外，但 1.7 的兩個 case 在現行實作下必然是綠的，且任何 fixture 形狀都無法讓它變紅——現行 `marker_span` 對 source 帶字尾的三種形狀皆以非零結束。1.7 的真正對照組是「完成 2.1 但未完成 2.3 的中間實作」，性質與 1.6 前者相同而未被列入例外。緩解因素：1.6 後者對 1.7 全部 case 追加的診斷斷言在修復前確實是紅的，且 D3 已明載該輸入現行即 fail closed，實作者可自行判定，故非阻斷。
- **F3**（85，`new`）delta 的 `帶字尾的 marker 被辨識並收斂` 末條 AND 宣稱字尾含 `<` 或 `>` 者「由 `帶字尾 marker 違反判定仍 fail closed` 涵蓋」。單側如此時 referral 成立，但兩側都如此時兩側皆不匹配、計數 0 對 0，installer 走「沒有 managed block → 附加 canonical block」，不由該 scenario 涵蓋。無規格真空也無實作歧義（該輸入行為與現行實作相同且已被另一個 scenario 涵蓋），僅 referral 指向不精確。
- **F4**（100，`new`，Info 級）proposal 的「實測 `--all` 結果為 `updated=5 failed=2`」已隨時間變化——Reviewer V 實跑得 `current=5 ... failed=2`。載重部分（兩個具名 target 因 marker 理由 failed）完全成立，`updated=5` 只是當時的快照，IC8 已明記不綁定 registry 條目總數，無下游依賴。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**1**（F1）
- 非阻斷 triaged finding count：**3**（F2、F3、F4）
- `critical_gap`：**false**
- `round_type`：**micro**

rationale：round 5 的 2 個成員全部以 verified resolution 離開集合。Reviewer V 的最終收斂檢查全面通過——requirement 每一段都有承接、三向對應無孤兒、delta 與 master 逐 byte 相容、design 引用的實測數字無一為假、端對端驗收基準經實跑確認可達成、15 個 task 以實作者視角讀完無需回頭提問。缺陷密度自 round 1 的 1C+7W 單調下降至 0C+1W。

唯一的 blocking 是 F1，而它值得如實記錄：這是我在 round 5 修 V1 時犯的第二次同型錯誤。V1 的內容正是「我採信了 reviewer 對某個案例的敘述而未親自量測」，我在修它的同一輪，對同一段落的另一個案例又做了完全相同的事——並且在 `## Fix Actions` 裡寫下「經本輪 reviewer 重新實測皆成立」，把 reviewer 的複測當成我自己的驗證。這與本 session 稍早未經核對就宣稱 analyze 乾淨是同一個根因。F1 的修法極小，但依 V1 在上一輪被判為 blocking 的同一判準，Reviewer V 拒絕把它降為非阻斷是正確的。

## Fix Actions

1 個 blocking 成員與 3 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 F1** — Risks 第三段的第一個案例補上「該範例的 start marker 帶字尾」這個前提，並比照第二個案例寫入實測對照：兩側皆不帶字尾時新舊定位完全相同（皆為 `(47, 96)`），該範例內容在現行實作下即已被刪除，不屬本次引入的行為改變。proposal 的對應敘述同步加上該限定。

**修 F2** — tasks 第 1 節前言的 red-first 例外由兩個改為三個，加入 1.7，並逐一寫明三者各自的對照組：1.3 是「未導入字尾容忍的實作」、1.6 前者是「只排除 `>` 而未排除 `<` 的假想錯誤實作」、1.7 是「完成 2.1 但未完成 2.3 的中間實作」。另說明 1.7 為何任何 fixture 形狀都無法在現行實作下變紅，以及真正在修復前為紅的是 1.6 後者追加的診斷斷言。

**修 F3** — 該 AND 改為分兩種情形指向：僅一側含 `<` 或 `>` 時由 `帶字尾 marker 違反判定仍 fail closed` 涵蓋，兩側皆如此時該形式不被辨識為 managed marker，由 `Missing、Spectra-only 與 mixed guidance 收斂` 的「沒有 managed block」分支涵蓋。

**修 F4** — proposal 的量測敘述改為只保留穩定的部分：兩個具名 target 每次都以 marker 理由 `failed`（`failed=2`），並明記其餘 target 的分類會隨安裝狀態變動、不是穩定的量測值。

**修正後的機械自檢** — 重跑全部檢查，未捕捉到本輪 fix 引入的新缺陷。delta 註解計數 2 比 2 平衡；tasks 全部 10 個粗體項皆為 scenario 或 requirement 名，無 emphasis 粗體與結構性小標題；proposal 的 `updated=5` 殘留為 0。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（F1——第二次採信未驗證的敘述並寫進論證，且在 `## Fix Actions` 中宣稱已複測）、`acceptance-criterion-unreachable-at-specified-point`（F2——red-first 規則對一個結構上不可能變紅的 task 生效）、`enumerated-site-set-factually-wrong`（F3 的 referral 指向不完整）。

## Decision

aborted

本輪為本次執行的第六輪，達 6 輪上限而 post-filter cumulative blocking set 仍含 1 個 Warning（F1），依規則記為 `aborted`。0 個 Critical。

### Abort triage

**bucket 1 — 仍屬本 change 的義務（seeds a later re-run）**

- **F1**（Warning，confidence 95）`design.md` Risks 第三段第一個案例的前提缺漏。**已於本輪完成 fix**（補上「該範例的 start marker 帶字尾」前提與實測對照，proposal 同步），但因達輪次上限而未經 reviewer 驗證。這是本 bucket 唯一成員，也是唯一阻擋 `passed` 的項目。

**bucket 2 — 新發現但從未阻斷**

- **F2**（Suggestion）red-first 例外清單遺漏 1.7。已於本輪修復。
- **F3**（Suggestion）delta 的 referral 指向不完整。已於本輪修復。
- **F4**（Info）proposal 的一次性量測快照過期。已於本輪修復。

三項皆已修復且皆非 Critical，不需要另開 follow-up change proposal，將透過 signals 步驟記錄其 issue class。

**bucket 3 — 接受的取捨**

無。本次未取得任何 accepted-risks 同意，因此沒有條目寫入 `accepted-risks.md`。

### 再次執行的具體前置條件

不建議原封不動重跑。再次執行的前置條件只有一項：**驗證 F1 的 fix**——確認 `design.md` Risks 第三段的三個案例前提在現行實作下逐一成立。該驗證是純量測，可由 re-run 的第一輪 reviewer 直接完成，不需要使用者決策、不需要擴大 scope、也不需要 `/cash-ingest`。

re-run 將以 F1 為 seeded cumulative blocking set 的唯一成員，round 編號自 7 起，其第一輪為 full 輪並須對 F1 給出明確的 resolved/unresolved 判定。
