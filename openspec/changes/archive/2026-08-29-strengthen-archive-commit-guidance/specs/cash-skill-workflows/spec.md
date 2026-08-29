## MODIFIED Requirements

### Requirement: cash-apply 封存指引須指引提交優先

當 `cash-apply` 的審查迴圈以 `decision: passed` 結束且最終回覆建議封存該 change 時，該回覆 SHALL 以「Archive guidance timing」段落內嵌的固定文案模板逐字輸出封存指引，唯二允許的代換是把 `<change>` 代入實際 change 名稱、以及變體 invocation 前綴（`/cash-` 與 `$cash-`）的差異。該模板 MUST 依序呈現：(1) 先執行 `cash-commit` 提交、再執行 `cash-archive` 封存；(2) 或執行 `cash-commit` 並在確認選項選 `Archive first, then commit together` 子流程，由 commit 流程代跑封存並把封存檔案搬移併入同一個 commit；(3) 警告——請勿先單獨執行封存，因為封存會刪除 `.cash-skills/state/touched/<change>.json`（`cash-commit` 用作來源允許清單的 touched state），使 `cash-commit` 退回封存 manifest 的時間點快照，封存後的變更不會入列。「較舊的封存沒有 `touched_files` 欄位」的歷史註腳 MUST 保留在段落規範句中而非模板內，因為對當下要封存的 change 該註腳永不適用。最終回覆 MUST NOT 以省略任一路徑或改寫模板的方式壓縮此指引。模板本體屬逐字保留內容，比照 CLI 指令與引用原文：既有「使用者明確要求其他語言時遵從最新指示」規則適用於回覆的其他部分，MUST NOT 用於改寫或翻譯模板本體。`decision: aborted` 時不建議封存的既有行為 MUST 不變。此 requirement 適用於 `cash-apply` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: 通過關卡後的封存指引逐字輸出固定模板

- **WHEN** 最終審查迴圈輪為 `decision: passed` 且最終回覆建議封存該 change
- **THEN** 該回覆逐字輸出「Archive guidance timing」段落內嵌的固定文案模板
- **AND** 僅代換 `<change>` 為實際 change 名稱與變體 invocation 前綴
- **AND** 模板同時呈現「先 commit 再 archive」與「`Archive first, then commit together` 子流程」兩條路徑
- **AND** 模板說明單獨先封存會刪除 `cash-commit` 用作來源允許清單的 touched state

#### Scenario: 指引不得被壓縮為單一路徑

- **WHEN** 最終回覆建議封存該 change
- **THEN** 該回覆 MUST NOT 只呈現「先 commit 再 archive」單一路徑
- **AND** MUST NOT 省略模板中的 touched state 後果警告

#### Scenario: 語言切換不改寫模板本體

- **GIVEN** 使用者已明確要求以其他語言回覆
- **WHEN** 最終回覆建議封存該 change
- **THEN** 回覆的其他部分遵從該語言要求
- **AND** 模板本體仍以繁體中文逐字輸出，比照 CLI 指令與引用原文的逐字保留

#### Scenario: abort 時的既有行為不變

- **WHEN** 最終審查迴圈輪為 `decision: aborted`
- **THEN** `cash-apply` 不建議封存該 change

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的封存指引段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

## ADDED Requirements

### Requirement: cash-archive 單獨封存前的未提交來源守門

`cash-archive` SHALL 在 delta spec 同步判定之後、執行 `"$cash_cli" archive` 之前，執行一個未提交來源守門步驟。該守門在 `.cash-skills/state/touched/<name>.json` 存在時讀取其 top-level `files` 欄位（CLI 驗證過的 canonical union）；該路徑不存在而 legacy 路徑 `.spectra/touched/<name>.json` 存在時，改讀 legacy 檔 `touched` 陣列各條目 `files` 的聯集——legacy schema 的 top-level keys 恰為 `change` 與 `touched` 兩鍵、沒有 top-level `files`，且封存執行步驟的 CLI 會 import legacy touched state 後同樣刪除它，守門必須涵蓋同一 hazard。取得的 `files` 集合與 `git status --porcelain=v1 -z --untracked-files=all` 在 project root 回報的 dirty 路徑取交集；守門步驟 MUST 逐字寫出這條完整 git 指令，並依 NUL-delimited 格式解析：條目涵蓋 staged、unstaged 與 untracked；每筆條目以兩字元狀態欄加一個空白開頭，比對前先剝除該前綴取出路徑；rename／copy 條目帶兩個 NUL 結尾路徑（先新路徑、後舊路徑），僅第一段帶狀態欄前綴，第二個 NUL field 是裸 old path，MUST NOT 對其剝除前綴，兩者皆計入 dirty 集合——copy 條目的來源檔通常未變更，仍計入是刻意的保守選擇，由此產生的誤報由「仍繼續單獨封存」出口吸收；`-z` 模式下路徑不做 C-quoting，特殊字元路徑得以與 touched 中的 raw 路徑直接比對。該 git 指令以 non-zero 結束、或其輸出無法依 NUL-delimited 格式完整解析時，守門 MUST NOT 把偵測失敗視同交集為空：MUST 停止 workflow、報告原始錯誤，且 MUST NOT 呼叫 `"$cash_cli" archive`——偵測失敗放行不安全，因為 `"$cash_cli" archive` 不檢查 dirty state，與 touched malformed 的放行分支（CLI 會對 touched fail closed）性質不同。交集非空時，守門 MUST 列出這些未提交的 source 檔案，並以恰好兩個互斥選項向使用者發問：停止本次封存並改走 `cash-commit` 的 `Archive first, then commit together` 子流程（建議選項），或知悉 touched state 將被刪除、後續 `cash-commit` 退回封存 manifest 快照的後果後仍繼續單獨封存。選擇停止時 MUST NOT 呼叫 `"$cash_cli" archive`；選擇繼續時走既有的封存執行步驟。兩個 touched 路徑都不存在、或交集為空時，守門 MUST 靜默通過，不發問也不顯示訊息。touched 檔存在但守門無法依 current／legacy schema 安全取得合法的 path set 時——例如無法解析為 JSON、current 檔缺 top-level `files` 或其值不是 string array、legacy 檔缺合法 `touched` 陣列——守門 MUST NOT 在 skill 層重製完整 CLI validator，MUST NOT 猜測也 MUST NOT 修改任何檔案，直接放行進入封存執行步驟，由 CLI fail closed 並保留其實際 diagnostic——可能為 `state_invalid`、`touched_invalid` 或 `legacy_touched_invalid`——守門 MUST NOT 預判或替 CLI 斷定錯誤碼。守門對 `.cash-skills/state/touched/<name>.json` 與 `.spectra/touched/<name>.json` MUST 只讀取，MUST NOT 修改或刪除。此 requirement 適用於 `cash-archive` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: touched state 缺失時靜默通過

- **GIVEN** change `demo-change` 沒有 `.cash-skills/state/touched/demo-change.json`
- **AND** 也沒有 `.spectra/touched/demo-change.json`
- **WHEN** `cash-archive` 抵達未提交來源守門步驟
- **THEN** 守門靜默通過，不發問也不顯示訊息
- **AND** 流程繼續到封存執行步驟

#### Scenario: 僅 legacy touched state 存在時仍受守門

- **GIVEN** change `demo-change` 沒有 `.cash-skills/state/touched/demo-change.json`
- **AND** `.spectra/touched/demo-change.json` 存在
- **WHEN** `cash-archive` 抵達未提交來源守門步驟
- **THEN** 守門改讀 legacy 檔 `touched` 陣列各條目 `files` 的聯集，執行同一套交集判定
- **AND** 不因 legacy 檔沒有 top-level `files` 欄位而誤判為 malformed 放行

#### Scenario: 交集為空時靜默通過

- **GIVEN** change `demo-change` 的 touched state 存在
- **AND** 其依來源規則取得的 path set（current 檔 top-level `files`；legacy 檔 `touched` 條目 `files` 聯集）中沒有任何路徑出現在 `git status --porcelain=v1 -z --untracked-files=all` 解析出的 dirty 路徑中
- **WHEN** `cash-archive` 抵達未提交來源守門步驟
- **THEN** 守門靜默通過，不發問也不顯示訊息

#### Scenario: touched state malformed 時放行由 CLI 守門

- **GIVEN** change `demo-change` 的 touched state 檔存在，但守門無法依 current／legacy schema 安全取得合法的 path set（例如無法解析為 JSON、current 檔缺 top-level `files` 或其值不是 string array、legacy 檔缺合法 `touched` 陣列）
- **WHEN** `cash-archive` 抵達未提交來源守門步驟
- **THEN** 守門不在 skill 層重製 CLI validator、不猜測、不修改任何檔案，直接放行進入封存執行步驟
- **AND** 由 `"$cash_cli" archive` fail closed 並保留其實際 diagnostic（`state_invalid`、`touched_invalid` 或 `legacy_touched_invalid`），守門不替 CLI 斷定錯誤碼

#### Scenario: git 偵測失敗則停止且不封存

- **GIVEN** change `demo-change` 的 touched state 存在且已取得合法的 path set
- **WHEN** `git status --porcelain=v1 -z --untracked-files=all` 以 non-zero 結束，或其輸出無法依 NUL-delimited 格式完整解析
- **THEN** 守門 MUST NOT 把偵測失敗視同交集為空
- **AND** `cash-archive` 停止 workflow 並報告原始錯誤
- **AND** MUST NOT 呼叫 `"$cash_cli" archive`

#### Scenario: 交集非空時發問且選項互斥

- **GIVEN** change `demo-change` 的 touched state 存在
- **AND** 其依來源規則取得的 path set（current 檔 top-level `files`；legacy 檔 `touched` 條目 `files` 聯集）中至少一個路徑出現在 `git status --porcelain=v1 -z --untracked-files=all` 解析出的 dirty 路徑中
- **WHEN** `cash-archive` 抵達未提交來源守門步驟
- **THEN** 守門列出這些未提交的 source 檔案
- **AND** 以恰好兩個互斥選項發問：停止並改走 `cash-commit` 的 `Archive first, then commit together` 子流程（建議），或仍繼續單獨封存

#### Scenario: 選擇停止則不呼叫 archive

- **GIVEN** 守門已因交集非空發問
- **WHEN** 使用者選擇停止本次封存
- **THEN** `cash-archive` 停止
- **AND** MUST NOT 呼叫 `"$cash_cli" archive`
- **AND** 指引使用者改執行 `cash-commit` 並選 `Archive first, then commit together`

#### Scenario: 選擇繼續則走既有封存步驟

- **GIVEN** 守門已因交集非空發問
- **WHEN** 使用者選擇仍繼續單獨封存
- **THEN** 流程繼續到既有的封存執行步驟
- **AND** 守門不再重複發問

#### Scenario: 守門對 touched state 唯讀

- **WHEN** 未提交來源守門步驟執行
- **THEN** `.cash-skills/state/touched/<name>.json` 與 `.spectra/touched/<name>.json` 的內容與存在狀態不因守門而改變

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 的未提交來源守門步驟
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同
