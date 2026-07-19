## 1. Master spec 遷移（contract C3）

- [x] 1.0 遷移前 verbatim 預掃：機械抽出三份 master spec 的所有 markdown 表格列與粗體錨點，對 SKILL.md 與 scripts/cash-skills/tests/skill-checks.fish 原文做 byte-substring 匹配，產出 quoted source text 清單（存於本 change 目錄備查）。驗證：清單存在且涵蓋 loop-ledger 表格範例等非 backtick 字面。

- [x] 1.1 [P] 遷移 openspec/specs/signals-shared-layer/spec.md：標題與內文中文化，結構關鍵字、規範動詞、識別字、引文、`<!-- @trace` 區塊 verbatim。驗證：requirement 數維持 3、各 requirement 的 `#### Scenario:` 數不變、code-span 多重集合比對為空 diff。
- [x] 1.2 [P] 遷移 openspec/specs/spectra-plus-skills/spec.md：Purpose 段落中文化。驗證：檔案結構（標題行與 `## Purpose` / `## Requirements` 骨架）不變。
- [x] 1.3 遷移 openspec/specs/cash-skill-workflows/spec.md 第一批（requirements 1–9，「Cash skill inventory and ownership」至「Spectra updates do not mutate cash skills」；遷移前參考行 9–668），含「Cash proposal quality gate」內「keep spec files in English」條款（行 222）的宣告式改寫為新政策等義中文條文（此為唯一允許的語意變更點）。驗證：該範圍 `### Requirement:` 數與各自 Scenario 數不變。
- [x] 1.4 遷移 cash-skill-workflows 第二批（requirements 10–25，「Stateless cross-project installer」至「Graded convergence and micro-verification round」；遷移前參考行 669–2099）。驗證：該範圍結構不變量（含 per-requirement code-span 與規範 token 計數）。
- [x] 1.5 遷移 cash-skill-workflows 第三批（requirements 26–42，「Review loop grader immutability」至檔尾；遷移前參考行 2100–3426）。驗證：該範圍結構不變量（含 per-requirement code-span 與規範 token 計數）。
- [x] 1.6 整檔驗證：三份 master spec 的 `### Requirement:` 總數 42/3/0、全檔 code-span 多重集合比對（僅 1.3 宣告的差異）、`<!-- @trace` 區塊位元組不變、`spectra validate --all` 通過、openspec/specs/ 下不再出現 keep spec files in English 字句、1.0 的 verbatim 清單項目位元組不變。

## 2. Skill 規則更新（contract C1、C2）

- [x] 2.1 改寫 6 份 SKILL.md（.claude 與 .agents 的 cash-propose、cash-apply、cash-ingest）的既有 spec 語言條目為新政策，逐檔錨點依 design C1：propose 的 step 7a locale 句與「Exception — spec files stay in English」段、apply 的 'always English, regardless of any other language rule' 句、ingest 的 locale 例外句、propose/apply 共用 Round file language 區塊的 'any other English-language artifact' 句（四檔逐字一致以維持 shared_gate_hash）。新政策含「MODIFIED/REMOVED/RENAMED FROM 標題必須從 master spec 逐字複製」規定。驗證：六檔均不含 'MUST always be written in English'、'spec files stay in English'、'always English, regardless of any other language rule'、'any other English-language artifact'。
- [x] 2.2 在 4 份 SKILL.md 共用 `<!-- MECHANICAL-SELF-CHECK -->` Checks 清單新增 **Spec delta title-identity check**（四檔逐字相同，維持 shared_gate_hash 相等）。驗證：兩變體中 propose 與 apply 的 shared gate 區塊 hash 各自相等（由 3.1 的測試套件覆蓋）。

## 3. 測試套件更新（contract C5）

- [x] 3.1 更新 scripts/cash-skills/tests/skill-checks.fish：assert_propose_contract 的 'spec files MUST be written in English' 字面替換為新政策 anchors；shared 契約字面清單加入 'Spec delta title-identity check'。驗證：fish scripts/cash-skills/tests/skill-checks.fish 以 PASS 結束、exit 0。

## 4. 治理收尾（contract C6）

- [x] 4.1 bump cash-skills.version 1.1.0 → 1.2.0；如 cash-propose 或 cash-ingest 的 variant parity hunks 行號位移，以測試同款正規化與 label 重生 scripts/cash-skills/variant-parity/cash-propose.diff 與 scripts/cash-skills/variant-parity/cash-ingest.diff。驗證：skill-checks.fish PASS（涵蓋 version governance 與 variant parity）。
- [x] 4.2 最終驗證：`spectra validate chinese-spec-content --strict` 通過、`spectra validate --all` 通過、skill-checks.fish PASS、`git status --porcelain` 僅含 proposal Impact 宣告的檔案、本 change 目錄，與 review loop 依 signals-shared-layer spec 寫入的 openspec/signals/ 檔案。
