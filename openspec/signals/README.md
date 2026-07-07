# Signals 共享層

本文件說明 `openspec/signals/` 這個跨 change 的共享記憶層：它收錄什麼、每個 signal 檔的 schema、slug 規則、新增/更新流程，以及 status 維護與並發風險。

## 用途與收錄規則

`openspec/signals/` 是一個跨 change 的共享記憶層，用來收錄 plus review loop 在反覆、跨 change 過程中觀察到的高信號 issue：product friction、idea、gap、recurring review finding。它的目的是把「一再出現、值得人關注」的問題累積起來，避免每個 change 各自重新發現同樣的問題。

收錄門檻嚴格，只收真正高信號的觀察：

- 只收 plus review loop 中、經 post-filter 後屬於 `Critical` 或 `Warning`（`confidence >= 80`）的 finding。
- 不收 `Suggestion` 等級的 finding。
- 不收 linter / typechecker 本來就會抓到的問題。
- 不收一次性、低信號的雜訊。

## 檔案與 schema

每個 signal 是一個獨立檔案：`openspec/signals/<slug>.md`。檔案開頭是固定的 frontmatter，欄位如下：

- `id`：等於該檔的 slug。
- `type`：`friction` / `idea` / `gap` / `recurring-finding` 其中之一。
- `status`：`open` / `addressed` / `dismissed` 其中之一。
- `occurrences`：非負整數，表示這個 issue-class 被觀察到的次數。
- `first_seen`：首次觀察日期，格式為 `YYYY-MM-DD`。
- `last_seen`：最近一次觀察日期，格式為 `YYYY-MM-DD`。
- `links`：project-root 相對路徑陣列，指向每次觀察的來源。

frontmatter 可額外包含一個選填欄位：

- `check`：人工撰寫的單行 shell 檢查命令。self-check 從 project root 以 `sh -c` 執行，且把欄位值作為 `sh -c` 的單一命令字串參數。exit code 慣例為：`0` = anti-pattern 不存在；`1` = anti-pattern 存在；其他任何 exit code = 執行錯誤，不是偵測結果。

`check` 命令必須是唯讀、快速、離線、非互動。它不得修改任何檔案，不得依賴網路或使用者輸入。偵測結果只能用 exit `0` 或 `1` 回報；可預見的執行錯誤（例如路徑不存在、工具缺失、語法錯誤）必須以其他 exit code 浮現，不得用 `!` 或類似盲目反轉把錯誤折疊成 `0` 或 `1`。撰寫 YAML 時，`check` 是單行字串；值若包含引號、冒號或 `#`，必須正確加引號，避免 `#` 後方被 YAML 當成註解截斷。

frontmatter 之後依序是：一個標題、一段說明，以及一個 `## Occurrences` 區段。`## Occurrences` 區段每次觀察記一筆，每筆包含：日期、change 名、來源 skill 與 round、以及一行 context。

最小範例 signal 檔內容如下：

```markdown
---
id: spec-requirement-no-backing-task
type: gap
status: open
occurrences: 1
first_seen: 2026-06-21
last_seen: 2026-06-21
links:
  - openspec/changes/add-signals-shared-layer/reviews/propose-r1.md
---

# Spec requirement with no backing task

Spec 列出一條 requirement，但 tasks.md 沒有對應的 task 去實作或驗證它。

## Occurrences

- 2026-06-21 — add-signals-shared-layer — spectra-propose-plus round 1 — REQ-4 在 tasks.md 找不到對應 task。
```

## slug 規則

`<slug>` 是 writer 指派的、簡短而具語意的 issue-class 識別碼。它必須是 ASCII kebab-case，符合 `^[a-z0-9]+(-[a-z0-9]+)*$`，例如 `spec-requirement-no-backing-task`、`unhandled-empty-input`。

slug **不是** 由 finding 的 `location + summary` 機械式字串轉換而來。那種做法有兩個問題：不同 change 的同一類問題會因為 location 不同而算成不同 slug；而中文 summary 經正規化後常會變成空字串。slug 要表達的是「問題的類別」，由 writer 依語意命名。

coin 一個新 slug 前，writer MUST 先列舉既有的 `openspec/signals/*.md`，挑一個尚未存在的 slug。若自然 slug 已被佔用，就加後綴（例如 `-2`）。建檔 MUST NOT 覆寫任何既有的 signal 檔。

## 新增與更新流程

writer 處理一筆符合收錄門檻的 finding 時：

1. 先讀既有 signals。
2. 以 rubric 判斷是否屬於既有 issue-class：同 capability / domain，且同 rule / anti-pattern，視為同一 issue-class。
3. 若命中某個既有的 `open` 同 class signal，就沿用它的 slug 就地更新：
   - 遞增 `occurrences`。
   - 更新 `last_seen`。
   - 在 `## Occurrences` append 一筆新觀察。
   - 把來源路徑 append 到 `links`。
   - 不更動 `status`。
4. 否則 coin 一個尚未佔用的新 slug，建立新 signal，初始 `status: open`、`occurrences: 1`。

當不確定一筆 finding 是否與既有 signal 屬同一 class 時，偏向建新 signal，而非勉強併入。

## status 由人維護

自動 writer 的權限刻意受限：它只會建立新的 `open` signal，或更新既有 `open` signal 的 `occurrences` / `last_seen` / `links` / `## Occurrences`。

自動 writer **永不** 把 `status` 改成 `addressed` 或 `dismissed`，也 **永不** 把已解決的 signal 改回 `open`。`addressed` / `dismissed` 的轉換完全是人工動作，由人在問題真正被處理或判定不予處理時手動維護。

`check` 與 `status` 一樣由人維護。自動 writer（包含 plus review loop 的 signals write step 與 fix action）不得新增、修改或刪除任何 signal 的 `check` 欄位；更新既有 signal 時，若已有人工撰寫的 `check`，必須逐字節保留不動。建立新 signal 時，自動 writer 不得自動鑄造 `check`。

## 並發 lost-entry 風險與拆分指引

本層不對檔案加鎖。當兩個 run 同時寫同一個 `<slug>.md`（包含兩個 run 各自為同一個新 issue-class coin 出相同的自然 slug）時，落敗的 writer 的 `## Occurrences` 與 `links` append、甚至整個新建的 signal 都可能遺失。不加鎖是刻意的取捨：signal 寫入頻率本來就低，且人可以事後校正。

此外，由於 issue-class 的判斷有模糊地帶，可能出現誤併。若某個 signal 的 `## Occurrences` 中有條目明顯描述的是不相關的問題，reviewer / analyst 應手動把它拆分成不同的 signal。
