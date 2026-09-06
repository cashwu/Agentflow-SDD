## Summary

新增唯讀 CLI command `cash lint-round`，只驗證能由磁碟與 Git 自行推導的 review loop 事實，並在 `.claude/settings.json` 掛上 Stop hook 使其成為阻擋型 gate。v1 的 gate 範圍是 round file 結構類判準與 grader-immutability。

## Motivation

Cash review loop 的全部判準目前都寫在 `scripts/cash-skills/blocks/review-gate.md` 的散文裡，由 main agent 自願執行。這造成一個結構性的不對稱：round file 由 main agent 撰寫，是否符合 schema 也由同一個 main agent 判斷，confidence filter、disposition 校正與 cumulative blocking set 的維護同樣落在被審查的那一方。裁判與被告是同一個 process。

`審查迴圈的 grader 不可變性` requirement 部分處理了這個問題——它禁止 main agent 修改受保護的裁判面檔案——但它自己也只是散文。受保護清單的第一項是 `.claude/skills/cash-apply/SKILL.md`，也就是宣告這條規則的檔案本身；違反它的唯一後果是下一輪 reviewer 可能注意到。

因此需要一個由 host 自動執行的工作區一致性檢查。設計上唯一有效的判準是事實來源：gate 只採納它能自行從磁碟與 Git 推導的事實，不接受 main agent 在任何介面上的自我申報。任何需要受審者提供輸入的 gate 都會退化成裝飾——它會在輸入缺席時靜默跳過，而受審者永遠有動機讓輸入缺席。

open signal `ungoverned-gate-input` 記錄了同一類失效的既有案例：新增的 gate input 若未在同一個 change 定義寫入治理，裁判面就對受審者可寫。本 change 限定 gate 自行讀取工作區與 Git，不接受額外傳入的判定結論；磁碟上的 artifacts 仍由 main agent 可寫，因此不宣稱來源不可偽造，限制見 design R8–R10。

## Proposed Solution

交付兩層。

第一層是 `cash lint-round <change> [--json]`，一個新的唯讀 command family。它讀取 `openspec/changes/<change>/reviews/` 下的 round files 與 Git 狀態，輸出逐項 check 結果與整體判定。它不產生任何由 command 自身控制的寫入（receipt-based target 上由 import system 產生的 bytecode cache 不在 command 控制範圍內，唯讀性的比較範圍因此排除該產物），不接受描述待驗事實的參數，也不讀取任何由 main agent 在該次 loop 中撰寫、且其內容即為待驗命題的輸入。

v1 納入兩組 gate：

**結構類**——round file 具備 `## Reviewer Findings`、`## Rating`、`## Fix Actions`、`## Decision` 四個 section；`## Decision` 的值恰為 `passed`、`next_round`、`aborted` 之一；round type 符合位置推導，即某次 run 的第一輪為 `full`，第一輪之後的每一輪當且僅當是該 run 第四輪時為 `full`、其餘為 `micro`。run 邊界由 round file 序列自行導出，不依賴 `loop-ledger.tsv`。

**grader-immutability**——把受保護裁判面路徑集合對上 Git 導出的變更集合，再對上 structured scope declarations。因為變更集合是 repository 全域而宣告是 per-change 的，涵蓋判定在 single-change 與 `--hook` 兩種 mode 都取未封存且未 parked 的被列舉 change 宣告聯集，single-change 的位置參數只決定回報對象；宣告有效期不因來源 change 的最高 round 為 `passed` 或 `aborted` 自動失效。這讓 A 合法修改受保護檔案、A 完成 passed 但未提交、B 仍 active 時，A 的宣告仍涵蓋該工作區改動；同時不把已封存或 parked change 的宣告帶入判定。來源完全不設限仍會讓任一無關 change 目錄解除全部判定。變更集合涵蓋工作區相對 `HEAD` 的改動（含已 staged 者）與 untracked 檔案，因此 `git add` 不能使改動逃離判定。受保護路徑被修改而未被 structured scope declaration 涵蓋時判定為失敗。

第二層是 Stop hook。它在 turn 結束時執行，自行判定檢查對象與迴圈活動狀態，判定依據只能是磁碟狀態。列舉對象為 `openspec/changes/` 下排除 `archive` 與 `.parked` 兩個保留目錄後的 change，再加上 `openspec/changes/.parked/` 下的 parked change，使 `cash park` 不構成逃逸口。活動狀態依 round file 的 `## Decision` 判定，且因 `propose-r<N>` 與 `apply-r<N>` 是各自從 1 起算的兩個獨立序列，判定 MUST 逐 skill 進行。parked change 納入列舉以接受結構類 gate 判定，但 MUST NOT 計入 active 判定——其最高編號 round file 常永久停在 `next_round`，計入會使 repository 長期 active 而讓僅在 active 時適用的 gate 對無關 session 持續生效。hook 不從 main agent 取得 change 名稱。無進行中 loop 時，結構 gate 仍檢查存在的 round files；僅 active-only 的 grader gate 回報 `skip`，hook 因此在沒有失敗時 exit 0。首次判定失敗時 hook 以 exit 2 阻擋；重入仍判定且有失敗時以 exit 1 放行並輸出當次失敗項。hook 在 command 進入點之後的基礎設施錯誤 fail open，以 exit 1 結束並輸出 `gate_unavailable`——依 host 行為，只有 exit 2 阻擋，其餘非零 exit 非阻擋且 stderr 可見，exit 0 的 stderr 則不顯示——不得使 session 卡死。

實作全部落在 managed runtime。launcher 依 argv 將已知 mutating families 取 exclusive lock、其餘取 shared lock，因此唯讀的新 command 不需修改 `.cash-skills/bin/cash`，不觸發受控 launcher bootstrap migration。

## Non-Goals

- 不驗證 `## Fix Actions` 宣稱的修改是否確實落地。該項對應 open signal `fix-action-recorded-without-being-applied`，價值高但屬於後續 change。
- 不驗證已完成 round file 的不可變性。round files 位於 `openspec/changes/` 底下，在 change 進行中通常未 commit，沒有可比對的 Git baseline；`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_IGNORED_PREFIXES` 也把 `openspec/changes/` 排除於 touched 快照之外。唯一可行的替代是引入 host 寫入的 digest 帳，但寫入會使 `lint-round` 成為 mutating family 而須修改 launcher，觸發受控 launcher bootstrap migration，代價不成比例。
- 不驗證 `loop-ledger.tsv` 的列數與 round file 數是否一致。open signal `run-boundary-underivable-from-append-log` 已記錄 ledger 缺少 run 識別欄、`(skill, round)` 非唯一鍵、re-run 列同檔累積，因此跨 run 的列數比對在既有 schema 下不可導出，強行納入會讓 gate 本身在 re-run 情境誤判。
- 不驗證 findings 的 severity、confidence、disposition 是否判斷正確。這些是語意判斷，事實來源是 reviewer 的輸出而非磁碟，不屬於 host-derived 範圍。
- 不修改任何 canonical skill 或 `scripts/cash-skills/blocks/review-gate.md`。本 change 不往 skill 散文追加規則；gate 完全外部化。
- 不涵蓋 signal `check` 欄位保護。既有 `審查迴圈的 grader 不可變性` requirement 除路徑集合外另有一條無 declared-scope 例外的欄位級保護，禁止改動 `openspec/signals/` 下任何 signal 的 `check` frontmatter。該保護的判定粒度是欄位而非檔案，且不接受宣告例外，無法以路徑集合比對表達，v1 不納入。
- 不保護 gate 自身。`.claude/settings.json` 與 `.cash-skills/lib/cash_cli/commands/lint_round.py` 都不在既有受保護路徑集合內，把它們加入需要 MODIFIED 另一個 capability 的 master requirement，超出本 change 範圍。此洞在 design 的 Risks 逐字記錄。
- 不處理 reviewer sub-agent 的能力隔離。該項對應 open signal `review-isolation-unenforced-by-capability`，屬於不同範圍。

## Alternatives Considered

**改用 agentflow 那套。** agentflow 的 round-linter 已有 host-enforced Stop hook 與相應測試，但它的核心資料結構是 session 級的 devlog Ask/Round，沒有 master spec 累積，其 gate 全部是 devlog 形狀而非 change 形狀，無法直接套用。可轉移的只有「gate 事實必須由 host 自行推導」這個設計原則。此外它自身的 30 個 gate 中有 14 個因為 collect() 不產生對應欄位而在 Stop hook 路徑下永遠跳過，正是本 change 要避免的失效模式。

**讓 gate 接受 main agent 提供的 JSON context。** 這能大幅擴張可檢查的判準範圍，包含 disposition 與 blocking set。但受審者供應的事實不構成獨立驗證，且輸入缺席時 gate 只能跳過，等同讓受審者單方面決定是否受檢。已排除。

**只交付 CLI，不掛 hook。** 範圍較小，但這一版的執行力仍取決於 main agent 是否願意呼叫，只解決了「規則可機械判定」而未解決「規則被實際執行」，與本 change 的動機不符。

**hook 首版只警告不阻擋。** 可先累積誤判資料再改成阻擋。但阻擋型與警告型的差別只在 exit code，誤判風險主要由 gate 選材決定而非由 exit code 決定；既然 v1 只收 host-derived 事實，直接交付阻擋型。

## Capabilities

### New Capabilities

- `cash-round-gate`：定義 `cash lint-round` 的事實來源限制、v1 gate 集合與判定語意，以及 Stop hook 的啟用條件、阻擋語意與 fail-open 行為。

### Modified Capabilities

- `cash-cli`：`Cash workflow command surface` 以窮舉方式列出 CLI 支援的 command families，新增 `lint-round`（含 single-change 與 `lint-round --hook` 兩種 mode）必須擴充該集合，並確立它屬於 shared-read 而非 mutating family。Stop hook 的 command 即為以 `lint-round --hook` 執行，列舉與判定語意都由該 mode 承擔。

## Impact

- Affected specs: cash-round-gate, cash-cli
- Affected code:
  - New:
    - .cash-skills/lib/cash_cli/commands/lint_round.py
    - scripts/cash-cli/tests/test_lint_round.py
    - scripts/cash-cli/tests/fixtures/lint_round/
  - Modified:
    - .cash-skills/lib/cash_cli/main.py
    - .cash-skills/lib/cash_cli/commands/__init__.py
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
    - .claude/settings.json
    - cash-skills.version
    - scripts/cash-cli/tests/cli-checks.fish
  - Removed:
    - (none)
