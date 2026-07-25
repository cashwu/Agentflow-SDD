# Cash Propose Review — Round 8

本輪為 re-run 的第二輪，依位置推導為 `micro`：由單一 Reviewer V — Verification 對 cumulative blocking set 做 delta 驗證，並重點檢查 round 7 兩處大改寫（恢復錨定、hold scenario 拆分）。

## Reviewer Findings

### Cumulative blocking set 逐項判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| H1（Critical） | **resolved** | requirement 本文已含「兩個hook同時啟用時其hold path MUST互異，相同時 MUST在preflight以execution error fail closed」，scenario 的 AND 已改寫，舊字串全 artifact 0 命中；design D3／IC3 與 tasks 1.3 同步。Reviewer V 另核對既有兩個 hold 測試各只啟用一個 hook，互異規則不觸發 |
| H2（Warning） | **resolved** | 已拆為 `Preflight 可判定的 hold 設定錯誤 fail closed` 與 `等待點才可判定的 hold 形狀在等待點中止`，後者不主張零 target write；requirement 本文明寫「因等待點在`acquire_lock`之後，這類 MUST NOT主張在首次target write之前失敗」。可滿足性經源碼確認：兩個等待點（`installer.py:1303`、`:1403`）皆在 `transaction.commit()`（`:1419`）之前，尚未提交任何 transaction operation |
| H3（Warning） | **resolved** | design IC2、spec scenario、proposal 三處皆已加上「且 recovery 之後不存在與該 journal 無關的 drift」限定；Reviewer V 確認全 artifact 已無其他無條件「SHALL NOT 為 `conflict`」斷言 |

三個成員全部以 verified resolution 離開 cumulative blocking set，該集合清空。

round 7 的七個非阻斷項 H4–H10 亦全部判定 resolved。

### Round 7 兩處大改寫的源碼驗證結果

**恢復錨定是良好定義的單一插入點。** Reviewer V 對 `installer.py` 確認：`:1200` 為 `return "newer"`，`:1202` 起才是 source config 讀取；三個提前返回分支分別在 `:1243`、`:1259`、`:1286`。插在 `:1201` 同時滿足「緊接在 `newer` 之後」與「早於全部三個分支」，且 `config_plan`、`render_guidance`、`legacy_candidates`、`installation_inputs`、`gitignore_plan` 全數落在其後。`parse_receipt`／`parse_legacy_receipt` 在版本比較之前執行不構成缺口——receipt 是最後一筆 operation 且以 `atomic_write` 發布，publishing 崩潰不可能留下半寫 receipt；receipt 缺失時完全不進入 parse 分支。重入一致性成立：recovery 回傳真即遞迴重入，`receipt_snapshot`、`receipt`、`legacy_receipt`、`present_skills` 全部重算；receipt-less fixture 經 rollback 後 `present_skills` 回到 0 而走 fresh 路徑，legacy fixture 經 rollback 後 24 個 skill digest 恢復相符。journal 確可存在於 legacy／receipt-less target，且必然帶 `lock+launcher` prefix——`commit()` 在任何 operation 之前寫出 journal，而該點已在 `acquire_lock` 與 `publish_launcher` 之後。

**hold scenario 拆分的兩集合互斥**（「release 檔在 preflight 已存在」與「preflight 之後才出現」由構造互斥），等待點組的 THEN 在兩個 hold 位置皆可滿足，互異規則不影響既有兩個 hold 測試。窮盡性有一處缺口（N5）。

### Suggestion（全部經 confidence filter 降級或原為 Suggestion，皆非阻斷）

- **N1**（75，`fix-introduced`，原 Warning）`兩個 hold hook 各自記帳` 新加的 AND「兩者指向同一路徑時 MUST 在 preflight fail closed」在該 scenario 自身的 WHEN 之下是空集合——同路徑時 preflight 會先 fail closed，hook 1 根本不可能「已等待過一次」。修 H1 把不可達的 THEN 換成了空 WHEN 的 AND。
- **N2**（70，`fix-introduced`，原 Warning）tasks 1.2 新增的 receipt-less 與 legacy 兩個 fixture 只規定「各配一份 publishing 階段 journal」，未規定必須同時具備既存的 `.cash-workspace.lock` 與 launcher；若照兩者 canonical 的「無 lock」形狀構造，會先命中「journal 存在而 stable lock 不存在則 fail closed」而使「先完成 recovery 再重新分類」的斷言不可達，實作者最可能的反應是放寬那條 fail-closed 規則。
- **N3**（88）IC5 自述與新增 scenario 一一對應，但 IC2 子條目缺 `Receipt-less 與 legacy 崩潰同樣先恢復`（正是 r7 認定「頭號賣點在最典型情境下不成立」的那個 scenario），IC3 子條目也未納入互異規則與拆分後的分組。
- **N4**（68）design D2 第 1 步與 proposal 仍把偵測點的輸出描述為「dry-run diagnostic」，未反映它已擴為 dry-run 與 real run 皆輸出、且已拆成通用句與 newer 專屬補充兩段。
- **N5**（55，`new`）拆分後的兩個 scenario 未涵蓋「ready 檔在 preflight 之後、等待點進入之前才出現」這一種同樣只在等待點可判定的形狀；另「到等待點才被換成 symlink」的措辭可能被讀成與 preflight 組重疊。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **0**
- 非阻斷 triaged finding count: **5**（N1–N5）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 7 的三個 blocking 成員（H1、H2、H3）全部由 Reviewer V 以 verified resolution 判定 resolved 並離開 cumulative blocking set，七個非阻斷項 H4–H10 亦全部關閉。本輪新提五項 finding，其中原評為 Warning 的 N1（75）與 N2（70）confidence 落在 [50, 80) 而依 confidence filter 降級為 Suggestion，其餘三項本即 Suggestion；Suggestion 不論 disposition 皆非阻斷。因此 post-filter cumulative blocking set 為空集合，pass 條件成立。

值得記錄的收斂軌跡：本次 re-run 兩輪的缺陷密度為 r7 的 1 Critical + 2 Warning 降至本輪的 0 + 0，且本輪五項全部是局部措辭與枚舉層級的問題，不再出現前一次執行那種「機制本身在最典型情境下不成立」的結構性缺陷。Reviewer V 對 r7 兩處大改寫的源碼逐點驗證（恢復插入點的唯一性、重入後各分支的重算、journal 與 `lock+launcher` prefix 的因果、兩個 hold 集合的互斥性與 THEN 可滿足性）全部通過，是本輪判定 pass 的主要依據。

## Fix Actions

pass 條件已成立，依規則本輪無必須執行的 fix。但五項非阻斷 finding 中 N1 與 N2 會實質誤導實作者（前者要求建構一個邏輯上不可能的測試前置狀態，後者會讓一個被要求撰寫的測試不可達並誘導實作者放寬一條 fail-closed 規則），因此一併修復而非僅留 triage note。以下修復均在 pass 輪執行，**未經任何 reviewer 驗證**，這一點在完成輸出中一併聲明。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 N1** — `#### Scenario: 兩個 hold hook 各自記帳` 的 GIVEN 補上「且設在互異的hold path」使前置條件顯式，並移除該空集合 AND；同路徑的 fail-closed 規則不會遺失，它已由 `#### Scenario: Preflight 可判定的 hold 設定錯誤 fail closed` 的 WHEN 涵蓋。tasks 1.3 對應斷言改為「兩個 hook 設在互異路徑時…仍正常等待（同路徑的 fail-closed 屬前述 preflight 六種形狀之一，不在此案例）」。

**修 N2** — tasks 1.2 的兩個新 fixture 各補上必要前置：必須同時具備既存的 `.cash-workspace.lock` 與已發布的 launcher（canonical `lock+launcher` prefix），並說明理由——journal 只可能在 `acquire_lock` 與 `publish_launcher` 之後才被寫出，因此真實崩潰狀態必然帶該 prefix；若照 canonical 的「無 lock」形狀構造會先命中 fail-closed 規則而使斷言不可達。

**修 N3** — design IC5 的 IC2 子條目補入 receipt-less 與 legacy 兩種 journal 起點、journal schema 不辨識與 `JOURNAL_PATH` 為 symlink 兩種 fail-closed；IC3 子條目改為與 spec 兩個 scenario 一致的六（preflight）＋三（等待點）分組並納入互異規則。

**修 N4** — design D2 第 1 步改為「通用 diagnostic 由此點發出，dry-run 與 real run 皆然…；`newer` 專屬補充句另於 `newer` early return 之前輸出」；proposal `## Proposed Solution` 第 2 點的括號同步。

**修 N5** — 等待點 scenario 的 WHEN 改為三種形狀：「ready 檔在 preflight 之後、該 hook 的等待點進入之前才出現」「release 檔在 preflight 當下不存在而於等待點進入之前才出現」「該後出現的 release 檔為 symlink」，後兩者的措辭同時消除了與 preflight 組的重疊；tasks 1.3 的等待點組由兩種擴為三種，preflight 組由五種改為六種（把互異規則併入計數）。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；新增 scenario 維持 20 個，全數在 tasks.md 有 backing task 且雙向無缺漏；ghost bold name 為 0；殘留措辭掃描（`dry-run diagnostic 由此`、`兩者指向同一路徑時亦如此`、`四條`、`三個 helper（`）全數為 0；proposal `## Impact` 中含 `/` 的三個 code span 皆在 tasks.md 出現；無 lowercase `may`／`should`。重跑 `cash validate` 通過，`cash analyze` 四個維度皆為 0 finding。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 仍無 `check` frontmatter 欄位，採 best-effort 判斷。本輪相關者：`review-fix-propagation-incomplete` 對應 N3、N4（r7 的 fix 未同步到 IC5 與 D2／proposal）；`acceptance-criterion-unreachable-at-specified-point` 對應 N1、N2（修好一個不可達條件後又產生兩個新的不可達前置狀態）；`enumerated-site-set-factually-wrong` 對應 N5（拆分後的形狀集合不窮盡）。

## Decision

passed

post-filter cumulative blocking set 為空集合：round 7 的三個 blocking 成員 H1、H2、H3 全部以 verified resolution 離開，本輪五項新 finding 經 confidence filter 後全為 Suggestion，依規則不阻斷。pass 條件成立。五項非阻斷 finding 已一併修復並記錄於 `## Fix Actions`，其中在 pass 輪執行的修復未經 reviewer 驗證，於完成輸出中聲明。
