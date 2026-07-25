# Cash Propose Review — Round 1

## Reviewer Findings

聚合自兩個平行 reviewer（Reviewer A — Adherence、Reviewer B — Quality），以 `location + summary` 去重後套用 confidence filter。

### Critical

**C1**
- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: design.md `### D1`、`### IC1`；specs/cash-cli/spec.md `#### Scenario: 空字串 mode 參數不得被重新解讀`；`.cash-skills/lib/cash_cli/installer.py:1602-1619`
- `summary`: D1 指定的機制（讓空字串落入 `install_target` / `canonical_target` 既有守衛）無法滿足 delta spec 自訂的「MUST NOT 讀取 registry」，因為 `records = read_registry()` 在三個 registry 分支之前無條件執行。
- `recommendation`: 在 `read_registry()` 之前對三個帶值 mode 參數各自加一道空值守衛；並補上以不合法 registry 觀察診斷優先序的測試，使「未讀取 registry」成為可驗收條件。
- reviewer source: Reviewer A（confidence 100）、Reviewer B（confidence 92），獨立提出同一問題。

**C2**
- `severity`: Critical
- `confidence`: 90
- `layer`: design
- `location`: design.md `### D1`、`### IC1`；specs/cash-cli/spec.md `### Requirement: Installer 與 legacy cleanup filesystem boundaries` 新增段落；tasks.md 1.1
- `summary`: delta spec 要求空字串以「caller-input error」失敗，master spec 的錯誤契約規定 caller input 為 exit 2，但 D1 沿用的既有守衛都走 `InstallerError` 預設 `exit_code=1`；tasks.md 1.1 只斷言「非零 exit code」，測試無法保護該契約。
- `recommendation`: IC1 明寫退出碼為 `2`，由新增守衛以 `exit_code=2` 拋出，且不改動兩個既有守衛的退出碼（它們同時服務既有的 boundary execution error 情境）；tasks.md 1.1 改為斷言確切 exit 2。
- reviewer source: Reviewer B（confidence 90）、Reviewer A（confidence 85）。主 agent 已核對 `openspec/specs/cash-cli/spec.md` 的錯誤契約段落與 `installer.py:55` 的預設值，確認成立。

### Warning

**W1**
- `severity`: Warning
- `confidence`: 88
- `layer`: design
- `location`: design.md `### D4` 第 2 點、`### IC4` 第二點；specs/cash-cli/spec.md `### Requirement: Installer 進入點 interpreter 解析與 process 邊界`
- `summary`: 把版本化名稱排在泛用名稱之前，會改變**所有既有可用環境**的 interpreter 選擇並繞過 toolchain shim，這項行為變更未列入 Risks，也超出「泛用名稱不合格時提供備援」的動機。
- `recommendation`: 候選順序改為泛用名稱在前、版本化名稱在後；spec 明寫該順序理由；補一個「泛用名稱合格時選擇結果不改變」的 scenario。
- reviewer source: Reviewer B。主 agent 於本機實測驗證：`python3` 解析到 `/Users/cash/.local/share/mise/installs/python/3.13.0/bin/python3`（3.13.0），`python3.14` 解析到 `/opt/homebrew/bin/python3.14`（3.14.6），確認選擇位移為真。

**W2**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: specs/cash-cli/spec.md `#### Scenario: Hold path 不安全形狀 fail closed` 的 THEN 子句；`.cash-skills/lib/cash_cli/installer.py:1301, 1303-1305, 1347, 1403-1405`
- `summary`: 該 scenario 要求「在首次 target write 前以 execution error 失敗」，但兩個 hold hook 的等待點都在首次 target write 之後——`acquire_lock` 對 fresh target 會先建立 workspace lock，publication hold 更在 launcher 發布之後——條文無法成立而測試仍會通過。
- `recommendation`: 把 hook 設定驗證提前到 `acquire_lock` 之前的 preflight，使該 THEN 成立；等待點維持原位。
- reviewer source: Reviewer A（confidence 85）、Reviewer B（confidence 85）。

**W3**
- `severity`: Warning
- `confidence`: 82
- `layer`: design
- `location`: design.md `### D2` 與 `### D3` 第 2 點的交互作用；`.cash-skills/lib/cash_cli/installer.py:1303-1305, 1321, 1338`
- `summary`: hold 的等待點位於 `install_target` 可重入區段內，把 ready 檔改為 exclusive 建立後，任何一次重新進入都會因自身上一輪留下的 ready 檔而變成 execution error；D2 又新增第三個重新進入來源，兩者疊加把原本良性的重新分類轉成失敗。
- `recommendation`: 明訂每個 hold hook 在單一 process 內至多等待一次，重新進入時不再等待；補對應 scenario 與測試。
- reviewer source: Reviewer A（confidence 80）、Reviewer B（confidence 82）。

**W4**
- `severity`: Warning
- `confidence`: 82
- `layer`: design
- `location`: design.md `### IC1` 第二點；`.cash-skills/lib/cash_cli/installer.py:1568-1575, 1582, 1587`
- `summary`: IC1 要求 `--dry-run` / `--force` 的相容性檢查「使用同一存在性判準」，但這兩個檢查的運算元含 `store_true` 的 `--all` 與 `--self`，未提供時為 `False` 而非 `None`，字面套用會使 `False is not None` 恆真、守衛整組失效——`--list --dry-run` 會由 exit 2 變成 exit 0 印出 registry。
- `recommendation`: 存在性判準只套用於帶值參數，布林 flag 維持真值判斷；tasks 驗收補上 `--list --dry-run` 與 `--register <project> --force` 仍為 exit 2。
- reviewer source: Reviewer B。

**W5**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: tasks.md 1.2；design.md `### D2`；`.cash-skills/lib/cash_cli/installer.py:965-994, 1058-1087`
- `summary`: tasks 1.2 要求的「停留在 publishing 階段的 journal」fixture 沒有任何既有機制可產生——失敗注入會走 `rollback` 與 `cleanup_journal`，崩潰型 hook 都在 `phase: committed` 寫入之後——design 與 tasks 皆未說明構造方式，TDD 的第一步沒有可執行路徑。
- `recommendation`: 在 design 與 tasks 明寫 fixture 以手工寫入 schema v2 journal（`phase` 為 `publishing`、`operations` 內 `before` 為 base64 內容）加半發布 bytes 的方式構造；不新增 mid-publication 崩潰 hook，避免與「零引用 hook 應移除」相互拉扯。
- reviewer source: Reviewer B（confidence 80）、Reviewer A（confidence 70）。

**W6**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: proposal.md `## Proposed Solution` 第 3 點 vs design.md `### D3` 第 2 點 vs specs/cash-cli/spec.md `### Requirement: Installer fault-injection hooks 治理`
- `summary`: proposal 寫「hold 路徑納入既有 containment 驗證」，而 design 與 spec 明寫「MUST NOT 被強制收斂到 target 之內」；`ensure_contained` 在本 codebase 的語意就是收斂到 target，照 proposal 字面實作會使既有兩個把 hold 檔放在獨立暫存目錄的測試全數 fail closed。
- `recommendation`: 改寫 proposal 第 3 點為 identity 約束（絕對路徑、parent 非 symlink、exclusive no-follow 建立），並明確排除 containment。
- reviewer source: Reviewer B。

### Suggestion（經 confidence filter 由 Warning 降級或原為 Suggestion）

- **S1**（confidence 78，原 Warning）IC2 的「不再次觸發同一原因的重新進入」是絕對式陳述，與 delta spec 的 per-journal 措辭及 Risks 的「整體遞迴無上限」三處不一致，且在時間窗內另一 installer 崩潰留下新 journal 時不成立。
- **S2**（confidence 75，原 Warning）修好 A2 後，同一份殘留 journal 會使 `--dry-run`（回報 conflict）與真實執行（回報 update）結論相反，design 宣稱「分類語意不變」並未承認此發散，且 dry-run 行為未被規範。
- **S3**（confidence 75，原 Warning）IC5 列舉的測試覆蓋是 tasks 與 scenarios 的嚴格子集：完全未列入 IC4 進入點的三個 scenario，hold 只列一種形狀。
- **S4**（confidence 72，原 Warning）hold 協定的治理只涵蓋 ready 檔，未涵蓋真正解除等待的 release 檔；`Path.exists()` 會跟隨 symlink、對 dangling symlink 回傳偽，殘留的 release 檔會讓 hold 靜默變成 no-op。
- **S5**（confidence 70，原 Warning）「任何零引用的 fault-injection hook MUST 自實作移除」是開放式無界規範，沒有可觀察的驗收條件。
- **S6**（confidence 70，原 Warning）tasks 2.3 未指定新開關在測試中的注入方式；直接寫 `os.environ` 會違反既有的 `TEST_` 前綴間接層慣例，使開關洩漏到同一 process 內其他 installer 呼叫。
- **S7**（confidence 65）design 宣稱「committed 階段由 `CASH_INSTALL_CRASH_AFTER_QUARANTINE` 涵蓋，刪除不減少覆蓋」只在交易含 legacy_delete 時成立；純 write 交易下 `removed` 恆為 0，該 hook 永不觸發。
- **S8**（confidence 60）`CASH_INSTALL_TEST_HOOKS` 本身也是同層級環境變數，並未建立授權邊界；proposal 把問題描述為「沒有規範界定誰可以啟用」會使後續 review 誤判 `ungoverned-gate-input` 已關閉。
- **S9**（confidence 60）IC2 無條件要求恢復後回報 `update`，與 Risks 承認的併發時間窗（可能分類為 `current` 或 `newer`）互相矛盾。
- **S10**（confidence 55）tasks 1.4 要求斷言 user site 已停用，但 installer 沒有任何輸出暴露該狀態，觀察手段未指定。

## Rating

- post-filter cumulative blocking set Critical count: **2**
- post-filter cumulative blocking set Warning count: **6**
- 非阻斷 triaged finding count: **10**
- `critical_gap`: **true**
- `round_type`: **full**

rationale：本輪為未 seeded 執行的第一輪，因此所有通過 confidence filter 的 Critical 與 Warning 均為 blocking。兩個 Critical 都是同一類問題的兩面——D1 指定的達成手段無法滿足本變更自己寫下的 delta spec（registry 讀取順序與 caller-input 退出碼），若照字面實作會產出違反自身規格的程式碼。六個 Warning 中 W1、W2、W4 皆為主 agent 或 reviewer 以實際程式碼／實機執行證實的行為落差，W3、W5、W6 則是本變更內部 artifact 之間的矛盾或不可執行的驗收步驟。blocking set 非空，因此本輪為 `next_round`。

## Fix Actions

本輪所有 surviving finding 與 cumulative set 成員皆有對應 fix 行動，無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 C1（registry 讀取順序）** — design.md D1 新增「空值拒絕必須早於 `read_registry()`」段落並說明遮蔽風險；IC1 新增對應條款；specs/cash-cli/spec.md 的 `Installer 與 legacy cleanup filesystem boundaries` 段落加入「該空值拒絕 MUST 早於 registry 的讀取」及診斷優先序規定，並新增 `#### Scenario: 空字串 mode 參數的診斷優先於 registry 錯誤`；tasks.md 1.1 加入以不合法 registry 觀察診斷優先序的測試，2.1 指明守衛置於 `read_registry()` 之前。

**修 C2（退出碼）** — design.md D1 新增「退出碼必須是 2」段落，說明 `InstallerError` 預設為 1、兩個既有守衛同時服務 boundary execution error 因而無法一碼兩用；IC1 明寫 `exit_code=2` 且禁止改動既有守衛退出碼；tasks.md 1.1 由「非零 exit code」收緊為確切 exit 2，2.1 加入相同指示。

**修 W1（interpreter 順序）** — design.md D4 第 2 點改為泛用優先並附上本機實測證據；IC4 第二點候選順序改為 `python3`、`python`、`python3.14`…`python3.11`；Risks 的維護成本項同步改寫為「清單以泛用名稱開頭」；spec 的 requirement 段落加入順序理由，新增 `#### Scenario: 泛用名稱合格時選擇結果不改變`；tasks.md 3.1 同步順序與理由；proposal `## Proposed Solution` 第 4 點改為「在既有泛用名稱之後追加版本化名稱作為備援」。

**修 W2（hook 驗證時機）** — design.md D3 新增第 3 點「hook 設定的驗證時機與重入語意」，指明驗證提前到 `acquire_lock` 之前的 preflight；IC3 新增對應條款；spec requirement 段落加入該規定，scenario 更名為 `Hold 協定不安全形狀 fail closed` 並維持「首次 target write 前」的 THEN（此時已可成立）；tasks.md 1.3 加入「含 fresh target 未建立 workspace lock」的斷言，2.3 指明提前驗證。

**修 W3（hold 重入語意）** — design.md D3 第 3 點後半定義「每個 hold hook 在單一 process 內至多執行一次」；IC3 新增條款；spec 新增 `#### Scenario: 重新進入不因自身 ready 檔而失敗`；tasks.md 1.3、2.3 各自加入對應覆蓋與實作指示。

**修 W4（布林 flag 判準）** — design.md D1 末段說明 `False is not None` 恆真的失效模式與具體回歸（`--list --dry-run` 由 exit 2 變 exit 0）；IC1 明訂存在性判準只套用於帶值參數；spec 段落加入「對 `store_true` 的 boolean mode flag 則 MUST 維持既有判準」；新增 `#### Scenario: Boolean mode flag 的相容性守衛不受影響`；tasks.md 1.1、2.1 加入該驗收。

**修 W5（publishing fixture）** — design.md D2 新增「publishing 階段 journal 的 fixture 構造」段落，說明既有 hooks 皆無法產生該狀態並指定手工構造方式；tasks.md 1.2 展開為完整的 fixture 構造步驟。

**修 W6（proposal 與 design 矛盾）** — proposal.md `## Proposed Solution` 第 3 點改寫為 identity 約束並明確排除 target containment，與 design D3、spec requirement 一致。

**同時處理的非阻斷 triage 項（一併修正，不改變本輪決策）** — S1 與 S9：IC2 改為 per-journal 措辭並加上「無並發 installer 介入時」限定，Risks 補上另一 installer 崩潰的情形。S2：D2 新增 dry-run 分歧的規範段落，IC2 新增 dry-run 條款，spec 的 `Bundle 安裝與 runtime receipt` 段落加入 dry-run 規定並新增 `#### Scenario: Dry run 遇未完成 journal 不恢復但明示`，tasks.md 1.2、2.2 加入對應覆蓋，Risks 新增該取捨項。S3：IC5 改寫為與 IC1–IC4 及全部新增 scenario 一一對應的完整列舉。S4：D3 第 2 點與 IC3 加入 release 檔的 identity 規則，spec requirement 與 scenario 一併涵蓋，tasks.md 1.3 加入對應形狀。S5：spec 的開放式條款收斂為具名的 `CASH_INSTALL_CRASH_AFTER_COMMIT` 移除規定。S6：tasks.md 2.3 明訂沿用 `TEST_` 前綴間接層並擴充 helper 的變數剝除清單。S7：design.md D3 末段改寫為「`phase == "committed"` 分支唯一的實質工作是 quarantine 清理」，不再宣稱純 write 交易也有覆蓋。S8：D3 第 1 點加入「這個開關不是授權邊界」的定位說明。S10：tasks.md 1.4 指定以受控 `PYTHONUSERBASE` 植入 `usercustomize.py` 觀察副作用的驗證方式。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：comment/annotation 平衡 4 個 artifact 皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；delta 新增 scenario 由 10 個增至 15 個，全數具備 backing task；identifier cross-grep（`CASH_INSTALL_TEST_HOOKS`、`CASH_INSTALL_CRASH_AFTER_COMMIT`、`exit_code=2`、`read_registry`、`python3.14`、`usercustomize`）跨 artifact 拼寫與語義一致；無 lowercase `may`／`should`；無 stray `---` 分隔線。因 fix 行動修改了 proposal、design、tasks 與 spec artifacts，重跑 `cash validate "harden-installer-mode-and-recovery"` 通過，`cash analyze` 四個維度皆為 0 finding。

**本輪 pre-round self-check 另行捕捉並修正的項目（非 reviewer finding）** — 「commit 後崩潰用的 hook」未唯一指涉刪除目標（實作中有兩個 crash hook），已在 proposal、design、tasks 三處具名為 `CASH_INSTALL_CRASH_AFTER_COMMIT` 並註明 `CASH_INSTALL_CRASH_AFTER_QUARANTINE` 保留不動。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 均無 `check` frontmatter 欄位，因此採 best-effort 判斷：`positional-failure-injection-index-invalidated` 經核對本變更未新增 transaction operation，`CASH_INSTALL_FAIL_AFTER = "47"` 的硬編序號維持有效；`spec-requirement-no-backing-task` 經逐一比對 15 個新增 scenario 皆有 backing task。

## Decision

next_round

post-filter cumulative blocking set 含 2 個 Critical 與 6 個 Warning，未滿足 pass 條件。全部 8 個 blocking 成員皆已完成 fix 並記錄於 `## Fix Actions`，10 個非阻斷 triaged finding 亦一併修正。下一輪依位置推導為第二輪，故為 `micro` 輪，由單一 Reviewer V 對 cumulative blocking set 逐一給出 resolved/unresolved 判定，並檢查 fix 是否引入新缺陷。
