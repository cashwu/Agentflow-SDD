## Context

目前所有 spec 檔（openspec/specs/ 的 master spec 與 openspec/changes/<change>/specs/ 的 delta spec）依 skill 規則全文英文。實驗（隔離專案）已證實：

- spectra CLI 對「中文內文 + 英文結構關鍵字」的 delta spec 完整支援：spectra new artifact spec 內容驗證通過、spectra validate --strict 通過、spectra archive 正確合併（added: 1 / modified: 1）。
- delta 的 MODIFIED/REMOVED 合併是以 `### Requirement:` 標題對 master spec 逐字比對。標題不吻合時 validate 照樣通過、archive 靜默輸出 modified: 0，內容被無聲丟棄，CLI 無任何警告。

既有 master spec 共三份：openspec/specs/cash-skill-workflows/spec.md（3426 行、42 條 requirements）、openspec/specs/signals-shared-layer/spec.md（246 行、3 條）、openspec/specs/spectra-plus-skills/spec.md（僅 Purpose 的 tombstone）。「keep spec files in English」的既有規範字句只出現一處：cash-skill-workflows 的「Cash proposal quality gate」requirement 內文。

相關測試耦合（scripts/cash-skills/tests/skill-checks.fish）：
- assert_propose_contract 斷言字面 'spec files MUST be written in English'（本 change 要改寫的舊政策 anchor）。
- shared_gate_hash 要求 cash-propose 與 cash-apply 的共用 review-loop 區塊（從 `**Entry conditions**` 到 signals failure-handling 行）hash 相等。
- assert_exhaustive_variant_parity 要求 .agents 與 .claude 變體正規化後的 diff 逐字節等於 scripts/cash-skills/variant-parity/*.diff。
- check_bundle_version_governance 要求 canonical SKILL.md 位元組異動伴隨 cash-skills.version 嚴格遞增。

## Goals / Non-Goals

**Goals:**

- spec 檔內文（Requirement 敘述、Scenario 步驟、Example 說明、Purpose）改為繁體中文，結構關鍵字與規範動詞保持英文。
- Requirement 標題（合併身分鍵）一併中文化，並以機械檢查防護標題比對的靜默丟棄陷阱。
- 三份 master spec 一次遷移完成，避免中英混雜過渡期。
- skill 規則、測試斷言、bundle 版本治理同步更新。

**Non-Goals:**

- 不翻譯 openspec/changes/archive/ 的歷史內容。
- 不修改 spectra CLI 行為。
- 不修改任何 signal 檔（含 status 與 check 欄位）。
- 不改動 round file / tasks / design 等非 spec artifacts 的既有語言規則。

## Decisions

1. **遷移用宣告式直接編輯，不用 MODIFIED delta（排序陷阱）**：本 change 的 apply 會把 master 標題翻成中文；若同一 change 又帶英文標題的 MODIFIED delta，archive 在 apply 之後合併時標題必然不吻合，正好觸發已證實的靜默丟棄。因此三份 master spec 的遷移（含「keep spec files in English」條款的改寫）作為宣告在 proposal Impact 與 tasks 的直接編輯執行；本 change 的 delta spec 只帶 ADDED requirements（ADDED 是附加合併，無身分鍵比對）。
2. **標題身分鍵防護放在 pre-round mechanical self-check，不做成 signal check**：signals-shared-layer spec 規定 signal 的 check 欄位必須 human-authored；且此防護是每次 review 必跑的 gate 行為，放進 cash-propose / cash-apply 共用模板的 Checks 清單最符合定位。新增檢查文字在四份 SKILL.md 中逐字相同，維持 shared_gate_hash 相等。
3. **本 change 的 delta spec 以新格式撰寫（首個範例）**：中文標題與內文 + 英文結構關鍵字。它先於 skill 規則更新存在是刻意的：proposal 已宣告新政策，delta 本身就是政策的第一次應用。
4. **遷移的語意保存以結構不變量驗證**：翻譯逐 requirement 進行，並以機械可驗的不變量把關（見 Implementation Contract C3）——requirement 數、各 requirement 的 Scenario 數、backtick code-span 多重集合、`<!-- @trace` 區塊逐字保留。引用的英文原文（如 SKILL.md 內的字面錨點 `None; pass condition met.`、ledger 表頭）屬於 quoted source text，一律 verbatim。
5. **版本治理**：canonical SKILL.md 位元組會改變，cash-skills.version 由 1.1.0 提升為 1.2.0。repository 的 prior-version 字面值清點（check_version_literal_occurrence_inventory）不受影響——本 change 的所有檔案（含本 design 自身）MUST NOT 拼出該 governed 版本字串；測試自身以 string join 組字迴避自匹配，本條同樣以間接描述迴避。
6. **parity 影響評估**：cash-apply 為非 divergent（正規化後須逐字節一致），兩變體同步編輯即可。cash-propose 為 divergent，其 parity allowlist hunks 位於 step 1 與 step 4（在本 change 編輯的 step 7 語言段落之前，預期不受影響；若實際位移則重生 scripts/cash-skills/variant-parity/cash-propose.diff）。cash-ingest 亦為 divergent，其 6 個 parity hunks 中僅 @@ -256 位於本 change 編輯點（locale 例外句，約行 115）之後——改寫若增減行數即會位移，是三個 skill 中最可能實際觸發重生 scripts/cash-skills/variant-parity/cash-ingest.diff 的一個。

## Implementation Contract

**C1 — SKILL.md 語言政策改寫（6 檔：.claude 與 .agents 的 cash-propose、cash-apply、cash-ingest）**

新政策內容：spec 檔以繁體中文內文撰寫；下列結構關鍵字逐字保留英文：`## ADDED Requirements`、`## MODIFIED Requirements`、`## REMOVED Requirements`、`## RENAMED Requirements`、`### Requirement:`、`#### Scenario:`、`##### Example:`、GIVEN/WHEN/THEN/AND；規範動詞 SHALL/MUST/SHOULD/MAY 以英文嵌入；識別字、路徑、指令、引文 verbatim；MODIFIED/REMOVED 標題與 RENAMED 的 FROM 標題必須從現行 master spec 逐字複製，不得重打或翻譯。

既有舊政策條目的實際位置與措辭（逐檔列舉，全部改寫為新政策）：
- cash-propose（兩變體）：step 7a 的 locale 例外句（含 'MUST always be written in English' 字樣）；step 7 末「Exception — spec files stay in English」段落。
- cash-apply（兩變體）：「Artifact modifications during cash-apply」段落的 'always English, regardless of any other language rule' 句（cash-apply 沒有「Exception — spec files stay in English」標題段落，勿以 propose 措辭為模板推定）。
- cash-ingest（兩變體）：locale 例外句（含 'MUST always be written in English' 字樣）。cash-ingest 會更新既有 change 的 delta spec 且沒有 mechanical self-check，若漏改將依舊指令用英文改寫 delta 而重新製造靜默丟棄陷阱。
- 共用 Round file language 區塊（cash-propose 與 cash-apply，位於 shared_gate_hash 範圍內）：'Direct quotations from spec delta, master spec, or any other English-language artifact.' 改寫為不預設 spec 為英文的等義句（例：'Direct quotations from any source artifact, kept in the source's original language.'），四檔逐字一致以維持 hash 相等。

驗收（缺席斷言，六檔全部檢查）：不含 'MUST always be written in English'、不含 'spec files stay in English'、不含 'always English, regardless of any other language rule'、不含 'any other English-language artifact'；新政策段落於變體正規化後逐字一致。

**C2 — 共用 mechanical self-check 新增標題身分鍵檢查（4 檔：propose 與 apply 的兩變體，新增於 <!-- MECHANICAL-SELF-CHECK --> 的 Checks 清單；cash-ingest 無 mechanical self-check，不在此列）**
- 新增檢查（英文條文，四檔逐字相同）：**Spec delta title-identity check** — 對 delta spec 中 `## MODIFIED Requirements` 與 `## REMOVED Requirements` 區段下的每個 `### Requirement:` 標題、以及 `## RENAMED Requirements` 的 FROM 標題，逐字（byte-for-byte）確認存在於對應 master spec `openspec/specs/<capability>/spec.md` 的 `### Requirement:` 標題集合；master spec 尚不存在的 capability 跳過；不吻合為 self-check 失敗，必須在 spawn reviewers 前以「從 master spec 逐字複製標題」修復。
- 驗收：shared_gate_hash（propose vs apply）於兩個變體各自相等；skill-checks.fish 的 shared 契約字面清單納入新檢查的 anchor。

**C3 — 三份 master spec 遷移**
- 全部 `### Requirement:` 標題與內文為中文；結構關鍵字與規範動詞維持英文；識別字、路徑、指令、quoted source text、`<!-- @trace` 區塊逐字保留。
- 「keep spec files in English」字句改寫為新政策等義中文條文（此為宣告的內容變更，非翻譯）。
- 結構不變量（遷移前後相等）：各檔 `### Requirement:` 數（42 / 3 / 0）；各 requirement 的 `#### Scenario:` 數；backtick code-span 多重集合以 per-requirement 為單位比對（可把漂移定位到條）；各 requirement 的規範 token 計數（SHALL、MUST、MUST NOT、SHOULD、MAY、NEVER；MUST NOT 與 MUST 分開計數，防止否定翻反）；`<!-- @trace` 區塊位元組不變。
- verbatim 預掃清單：遷移前機械抽出三份 spec 的所有 markdown 表格列與粗體錨點，對 SKILL.md 與 scripts/cash-skills/tests/skill-checks.fish 原文做 byte-substring 匹配，命中者標記為 quoted source text 並列入清單；清單內項目遷移後位元組不變（涵蓋非 backtick 字面，如 loop-ledger 表格範例）。
- 順序敏感語句（exit code 對應、pass/fail 對應等）列入 apply 階段 Reviewer A 的指定抽查清單。
- 驗收：spectra validate --all 通過；不變量腳本比對為空 diff。允許的 code-span 差異來源有二：(1)「keep spec files in English」條款的宣告改寫；(2) 內部 requirement-title 引用（backtick 包住的標題字串，含 SKILL.md 共用 grader-immutability 段對 quality-gate 標題的引用）隨標題翻譯同步改為對應中文標題——替換必須逐一對應（移除的英文標題 span 多重集合 == 8+2 個標題引用×原出現次數——其中 `Confidence-scored findings` 為 HEAD 既有的縮短引用形式，替換為完整中文標題；新增的中文標題 span 一一對應），除此之外 code-span 多重集合不變。

**C4 — delta spec（capability: cash-skill-workflows）**
- 僅 `## ADDED Requirements`，兩條中文標題 requirements：spec 檔語言政策、Requirement 標題身分鍵防護；各至少 1 個 Scenario，政策條含 1 個 Example。
- 驗收：spectra validate chinese-spec-content --strict 通過；無 MODIFIED/REMOVED/RENAMED 區段。

**C5 — 測試套件更新（scripts/cash-skills/tests/skill-checks.fish）**
- assert_propose_contract 的 'spec files MUST be written in English' 字面替換為新政策 anchor（例：'Traditional Chinese prose' 與 'copy the requirement title verbatim'）；shared 契約清單加入 'Spec delta title-identity check'。
- 驗收：fish scripts/cash-skills/tests/skill-checks.fish 以 PASS 結束、exit 0。

**C6 — 治理收尾**
- cash-skills.version：1.1.0 → 1.2.0（單行、無 leading zero）。
- 如 cash-propose 或 cash-ingest 的 parity diff 行號位移，以與測試相同的正規化與 label 重生 scripts/cash-skills/variant-parity/cash-propose.diff 與 scripts/cash-skills/variant-parity/cash-ingest.diff（cash-ingest 依決策 6 評估為最可能觸發者）。
- 驗收：skill-checks.fish PASS（涵蓋 variant parity、gate hash、version governance）；git 工作區僅含 Impact 宣告的檔案、本 change 目錄的異動，以及 review loop 依 signals-shared-layer spec 合法寫入的 openspec/signals/ 檔案（signals 產物豁免於「僅 Impact 檔案」條件）。

## Risks / Trade-offs

- **翻譯語意漂移**：3426 行規範文本的翻譯可能改變語意。緩解：C3 結構不變量 + quoted text verbatim 規則 + review loop Reviewer A 對照抽查；發現歧義時以英文原文為準修正中文。
- **標題身分鍵斷代**：遷移後，任何仍引用英文標題的未來 delta 都會失配。現況無其他 active change（僅 archive），屬乾淨遷移窗口；新防護（C2）會在之後的每次 propose/apply 擋下失配。
- **防護繞過路徑（accepted residual risk）**：title-identity check 只掛在 cash-propose / cash-apply 的 pre-round self-check；下列路徑不受攔截——(a) 手寫或手改 delta 後直接跑 spectra archive；(b) apply 最後一輪之後 delta 再被編輯；(c) 兩個 change 並行時另一方先 archive 改動 master 標題使先前檢查過期。archive 前一刻的檢查（cash-archive 端）是攔截力最強的位置，留作後續 follow-up change，本 change 不擴充。
- **上游 spectra-\* 路徑不受防護（accepted residual risk）**：上游 spectra-propose / spectra-ingest skill 仍規定英文 spec 且無 self-check；spec 工作必須經由 cash-\* skill 進行。上游 skill 檔屬 Spectra CLI 再生成範圍，本 change 不修改（見 proposal Non-Goals）。
- **大檔遷移的中斷風險**：cash-skill-workflows 分批任務執行，任一批完成即為合法中間態（檔案整體仍可 validate），最終以不變量驗證整檔。

## Migration Plan

1. 先遷移兩份小 spec（可並行），建立翻譯詞彙慣例。
2. cash-skill-workflows 依 requirement 順序分三批遷移，含宣告的政策條款改寫。
3. 更新 6 份 SKILL.md（C1；其中 propose/apply 4 檔另含 C2），維持 gate hash 與 parity。
4. 更新測試斷言（C5），bump 版本（C6），跑全套驗證。

回滾：git revert 本 change 的 commit 即可；master spec 遷移前的內容可由 git 歷史完整還原。

## Open Questions

（無 — 排序陷阱、防護位置、標題語言三個原先的開放問題已在 Decisions 1–3 定案。）
