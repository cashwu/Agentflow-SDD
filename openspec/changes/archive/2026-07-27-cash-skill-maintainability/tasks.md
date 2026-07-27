## 1. 版本前置與 gate 單一源頭建立

- [x] 1.1 將 `cash-skills.version` 由 2.6.5 遞增為 2.7.0；此 task MUST 先於任何 SKILL.md 修改完成，否則 `scripts/cash-skills/tests/test_bundle_version_history.py` 的 `check_history` 會以「SKILL.md changed without a strictly greater cash-skills.version」失敗
- [x] 1.2 統一既有 gate 漂移並機械驗證：將 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` gate 區段中的 `` `## What Changes` or `## Proposed Solution` `` 改為僅 `` `## Proposed Solution` ``（以 propose 版本為準，依據 master spec「cash-propose 的 proposal 結構取自 CLI 單一來源」對 `## What Changes` 的全檔禁令）；然後驗證四份 gate 區段（「Sub-Agent Review/Rating/Fix Loop」步驟標題行之後的規格文字，前綴正規化採 `(?<![A-Za-z0-9_.-])` 邊界）逐字相同；若發現其他漂移，同樣以 propose 版本為準統一並記入 implementation notes
- [x] 1.3 建立 `scripts/cash-skills/blocks/review-gate.md`：內容自統一後的 `.claude/skills/cash-propose/SKILL.md` gate 區段抽出，並在 `<!-- GRADER-IMMUTABILITY -->` 區塊的受保護路徑集合中加入 `scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml` 三個路徑
- [x] 1.4 在 `.claude/skills/cash-propose/SKILL.md` 與 `.claude/skills/cash-apply/SKILL.md` 置入成對錨點 `<!-- REVIEW-GATE:BEGIN -->` 與 `<!-- REVIEW-GATE:END -->`：各檔恰一對，位於該 skill gate 步驟標題行之後、gate 規格文字結束處，標題行（含清單編號）不納入錨點區段

## 2. 生成器與轉換規則

- [x] 2.1 建立 `scripts/cash-skills/variant-rules.yaml`：宣告通用轉換規則（invocation 前綴置換含 `(?<![A-Za-z0-9_.-])` 邊界、`context`／`agent`／`disallowedTools` frontmatter 移除、fork 區塊移除），並將 `scripts/cash-skills/variant-parity/` 現有 8 個 diff manifest 轉寫為 marker／section 錨定（非行號錨定）的 per-skill 具名 entries；轉寫時將 manifest 內的 `@cash-` placeholder 還原為各側真實前綴
- [x] 2.2 實作 `scripts/cash-skills/generate.fish`：接受 target-root 參數（預設 repo root）；第一段把 `scripts/cash-skills/blocks/review-gate.md` 注入 `.claude` 兩檔的錨點區段，第二段由 `.claude/skills/` 十二個 SKILL.md 依通用規則與 per-skill entries 生成 `.agents/skills/` 對應檔；得以 python3 輔助解析規則與套用 patch；輸出一律 UTF-8 與 LF
- [x] 2.3 執行完整生成並逐檔比對輸出與現行 `.agents/skills/` committed 內容；每個無法由規則重現的差異逐項裁決為「登記 per-skill entry」或「既有漂移修正」，裁決結果記入 implementation notes
- [x] 2.4 冪等驗證：乾淨工作樹連續執行兩次 `scripts/cash-skills/generate.fish`，第二次結束後 git 狀態無任何檔案變更

## 3. 測試切換

- [x] 3.1 在 `scripts/cash-skills/tests/skill-checks.fish` 新增具名測試群組 `assert_generated_fresh`：把完整生成輸入集（十二個 `.claude/skills/` SKILL.md、`scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/variant-rules.yaml`）複製到暫存 root，對暫存 root 執行生成管線，與工作樹目標檔案逐檔 byte-compare，並納入套件全量執行路徑；先以「手改 `.agents` 輸出一行」驗證該群組確實以非零失敗，再還原
- [x] 3.2 自 `scripts/cash-skills/tests/skill-checks.fish` 移除 `assert_variant_parity`、`normalized_variant_diff` 與第 5 行 divergent 清單；保留既有良構斷言群組（空 code span、變體專屬 frontmatter）與 `grader_hash` 斷言
- [x] 3.3 刪除 `scripts/cash-skills/variant-parity/` 目錄（8 個 diff manifest）
- [x] 3.4 更新 `scripts/cash-skills/tests/test_live_namespace.py` 的 scan surface：自枚舉移除 `scripts/cash-skills/variant-parity/`，加入 `scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md`
- [x] 3.5 執行 `scripts/cash-skills/tests/skill-checks.fish` 全套，與 `scripts/cash-skills/tests/`、`scripts/cash-cli/tests/` 兩處 python 測試套件通過，且功能性引用面（兩處測試套件、`scripts/cash-skills/tests/test_live_namespace.py` 的 scan 枚舉、`CASH-SKILLS.md` 敘述）不再有任何對 `scripts/cash-skills/variant-parity/` 的引用；master spec 枚舉由 archive 時的 delta 置換，`@trace` provenance 區塊屬歷史紀錄不在此列

## 4. 維護參考文件

- [x] 4.1 [P] 建立 `CASH-GLOSSARY.md`：十二個首批詞條（change、artifact、contract、deviation、blocker、touched state、parked、signal、round、cumulative blocking set、accepted risk、variant），每條為二級標題，含定義、關係、avoid 三部分
- [x] 4.2 [P] 建立 `scripts/cash-skills/SKILL-LINT.md`：六種失效模式（premature completion、duplication、sediment、sprawl、no-ops、negation），每條含定義、症狀、檢查問句
- [x] 4.3 更新 `CASH-SKILLS.md`：新增生成模型說明一節（`.claude` 為權威源頭、`.agents` 為生成輸出、gate 以 block 為源頭）；修訂開頭的所有權敘述（原「source-controlled canonical files」直接維護的說法改為反映生成模型）；更新 live scan 涵蓋範圍敘述（「variant parity manifests」置換為與 cash-cli delta 枚舉一致的清單：`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md`）；加入指向 `CASH-GLOSSARY.md` 與 `scripts/cash-skills/SKILL-LINT.md` 的連結，並於後者旁註明其為人工檢核維度、非阻斷性檢查

## 5. 收尾驗證

- [x] 5.1 逐條驗證 design.md Implementation Contract 第 1 至 10 項全部成立（冪等、frontmatter 淨空、錨點成對唯一且不含標題行、gate 差異僅限三類、freshness 群組存在、variant-parity 移除且無殘引、受保護集合含三新路徑、兩份文件 schema 與 CASH-SKILLS.md 敘述更新、版本序位與 receipt、兩套測試通過）
- [x] 5.2 執行變更後四份 gate 區段的 normalized diff 比對，確認差異僅限三類：受保護 grader 路徑集合三個新路徑、成對錨點註解、apply 兩檔 `## What Changes` 引用統一為 `## Proposed Solution`
- [x] 5.3 執行 `./install-cash-skills.fish --self` 重建 `.cash-skills/receipt.tsv`，確認 receipt 的版本與 skill digests 反映 2.7.0
