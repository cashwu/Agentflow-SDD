# Cash Propose Review — Round 5

本輪為 micro 輪，由單一 Reviewer V — Verification 對 round 4 的 cumulative blocking set 做 delta 驗證，並重點檢查 round 4 的改設計（格式判定委派給 `version_parts`）。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 4 的 3 個 blocking 成員全數 `resolved`；6 個非阻斷項中 5 個 resolved、G6 的文字已加入但機制錯誤（見 V1）。

| member | verdict | 依據摘要 |
| --- | --- | --- |
| G1 | resolved | task 1.1 的具名清單已無 `Help 不繞過 receipt gate`；1.1／1.2／IC4 三處對該 scenario 的檔案歸屬一致 |
| G2 | resolved | task 1.2 已寫入 characterization test 的定性與理由，驗收改為「實作前後皆通過」 |
| G3 | resolved | design Context 已列出實作面四處編碼並說明 `bin/cash` 是 stable path、其重述在一般升版中改不動；Reviewer V 逐一比對源碼確認記載屬實 |
| G4、G5、G7、G8、G9 | resolved | 逐一核對到位 |
| G6 | 文字已加入但機制錯誤 | 見 V1 |

### 改設計的專項查核（Reviewer V，四項全部實跑）

**委派給 `version_parts` 成立且迴路閉合。** (1) 可實作性：`sys.path.insert` 後 `from cash_cli.installer import version_parts` 成功、無 import 副作用，`skill-checks.fish` 側只需 read bytes 加 LF 判斷，確實不需任何格式常數。(2) 無覆蓋洞：IC4 要求的「含前導零」負面案例本身就是 `version_parts` 的回歸偵測器——若 `VERSION_RE` 被放寬，該案例會由「拒絕」翻為「接受」而使套件失敗；`test_bundle_version_history.py` 的 `version()` 以獨立實作在同一個 `assert_installer` 內再驗一次，形成第二層備援。(3) accept-set 與各處宣稱一致，任意長度分量亦接受。(4) 與 `PYTHONDONTWRITEBYTECODE` 相容且不經 launcher，因此不觸發 receipt gate、不受 task 2.4 的重建順序影響。

### Warning

**V1**（confidence 100，`layer`: design，`fix-introduced`）「以 `CASH_PROJECT_ROOT` 綁定暫存 workspace、不依賴呼叫者 cwd」在現行 runtime 不成立。`Workspace.discover` 以 `os.getcwd()` 經 `git rev-parse --show-toplevel` 決定 root，`CASH_PROJECT_ROOT` 只是一致性守衛：不等於該 git root 時丟 `workspace_root_mismatch`。主 agent 實測確認——設 `CASH_PROJECT_ROOT` 指向暫存 workspace 但 cwd 留在 repo root 得 `{"code":"workspace_root_mismatch"}`；改為 chdir 進去才得 `Unknown new mode: bogus`。且暫存 workspace 須含內容有效的 `.cash.yaml` 與 `openspec/config.yaml`，只建空檔會先失敗於 `config_invalid`。`introduced_by`：round 4 的「**修 G6** — tasks 1.1 與 IC4 明訂……以 `CASH_PROJECT_ROOT` 綁定」。

**V2**（confidence 90，`layer`: text，`unresolved-prior`）proposal `## Proposed Solution` A 段仍把形狀檢查放在 `assert_inventory`，與 design D1／IC1／tasks 2.3／spec 的「必須置於呼叫 `test_bundle_version_history.py` 的 `assert_installer`」直接衝突。實作者若以 proposal 為準，tasks 3.2 的驗收「確認形狀驗證與該呼叫落在同一個 function」必然失敗，且 scenario `形狀驗證與數值治理同組執行` 不成立。

### Suggestion（非阻斷）

- **V3**（85）proposal 仍複述完整格式規則 `0|[1-9][0-9]*`，是委派決策後本 change artifacts 中僅存的一份新增重述，與 D1 的立論牴觸。
- **V4**（90）design Goals 仍寫「不再被複述第四次」，該序數建立在 G3 已推翻的「三個擁有者」計數上，與同檔 Context 的「至少有四處」互斥。
- **V5**（85）design Context 的「上述三者以外」是 G3 修正前的殘留回指。
- **V6**（80）proposal 仍寫「另有兩個更早的擁有者」，與 design 修正後的四處不一致，且完全未提 `bin/cash`。
- **V7**（75）task 1.2 首句仍寫「新增……的失敗測試」，與同 bullet 後半的 characterization test 定性及修正後的驗收自相矛盾。
- **V8**（55）scenario GIVEN 的「replaceable inventory未漂移」在本 repo 術語中僅指路徑集合，未涵蓋 bytes 漂移，G9 的反例仍在 GIVEN 允許範圍內。
- **V9**（60）委派的取用方式未言明；`installer.py` 使用相對 import，不可單檔載入，且 `assert_installer` 目前不設 `PYTHONPATH`。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **2**（V1、V2）
- 非阻斷 triaged finding count: **7**（V3–V9）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 4 的 3 個成員全部以 verified resolution 離開集合，且其核心改設計（委派）經四項實跑驗證成立、迴路閉合、未引入設計缺陷——這是本輪最重要的結論。兩個 blocking 中，V1 是 round 4 修 G6 時寫入了一個與 runtime 實際機制相反的手段（我當時沒有實測 `CASH_PROJECT_ROOT` 的語意就寫下 binding 方式），V2 則是 proposal 從 round 4 改設計起就沒跟上 `assert_installer` 的定位。其餘七項全是措辭層殘留，且多數集中在 G3 修正後未同步的計數字樣——同一個事實更正需要在四份 artifact 的六處各自落地，我只做了兩處。

## Fix Actions

2 個 blocking 成員與 7 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個。

**修 V1** — tasks 1.1 與 IC4 改寫為正確機制：以 `tempfile` 建立 `git init` 過、含內容有效 `.cash.yaml`／`openspec/config.yaml`（`schema: spec-driven`）／`.cash-workspace.lock` 的暫存 workspace，在測試內 `os.chdir` 進去並以 `addCleanup` 還原（本檔為 in-process 測試，chdir 會污染同 process 其他 case）；明寫 `CASH_PROJECT_ROOT` 不是 workspace 來源而是一致性守衛，只設它而不 chdir 會得到 `workspace_root_mismatch`，若設定其值必須等於該暫存 git root；並指出可沿用 `test_negative_atomicity.py` 的 `LauncherLockTests.setUp` 樣板。

**修 V2 與 V3** — proposal `## Proposed Solution` A 段改寫為：移除 `assert_inventory` 的字面值斷言、形狀驗證改置於呼叫 `test_bundle_version_history.py` 的 `assert_installer`、格式判定委派給 `version_parts`、本套件不內含任何格式常數。`0|[1-9][0-9]*` 字樣一併移除。

**修 V4、V5、V6** — design Goals 的「不再被複述第四次」改為不含序數的「不再新增任何一份重述」；Context 的「上述三者以外」改為「上述任一既有擁有者以外」；proposal 的「兩個更早的擁有者」改為與 design 一致的四處列舉，並補上 `bin/cash` 的 `is_source_layout` 及其為 stable path、一般升版改不動的說明。

**修 V7** — task 1.2 首句改為「新增 **Help 不繞過 receipt gate** 的 characterization test（回歸鎖，非 red-green；本節其餘 task 為測試先行，此項是明確例外）」。

**修 V8** — scenario GIVEN 改為「`cash-skills.version`為任一嚴格高於`HEAD`版本的合法值」，直接避開相等分支的內容綁定，比補述 inventory 漂移語意更不易再生歧義。

**修 V9** — tasks 2.3 補上委派的取用方式：在 `python3` 內把 `.cash-skills/lib` 加入 `sys.path` 後 `from cash_cli.installer import version_parts`（`installer.py` 使用相對 import，不可單檔載入），且不經 `.cash-skills/bin/cash`，因此不觸發 receipt gate、不受 task 2.4 的重建順序影響。

**修正後的機械自檢與驗證** — 因下一輪是 6 輪上限的最後一輪，本次自檢加嚴：4 份 artifact comment/annotation 平衡皆 0/0；殘留措辭逐項掃描（`第四次`、`上述三者`、`兩個更早的擁有者`、`assert_inventory 中的版本斷言`、`以 CASH_PROJECT_ROOT 綁定`、`的失敗測試：`、`不低於HEAD`）全部為 0；proposal 與 delta spec 的格式常數 `0|[1-9][0-9]*` 出現次數皆為 0；兩個 MODIFIED 標題與 master 逐 byte 相符；7 個新增 scenario 全數有 backing task；Impact 的 7 個含 `/` 路徑全部被 tasks 引用；ghost bold 為 0；無 lowercase `may`／`should`。重跑 `cash validate` 通過，`cash analyze` 非 Suggestion finding 為 0。

**Signal-derived checks** — 全部 open signal 無 `check` frontmatter，採 best-effort。本輪最相關者：`review-fix-propagation-incomplete`（V2、V4、V5、V6 —— 同一個事實更正只在部分位置落地）、`design-claim-unverified-against-code`（V1 —— 寫下 binding 手段前未實測其語意）、`cross-artifact-definition-drift`（V3）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 2 個 Warning（V1、V2），未滿足 pass 條件。round 4 的 3 個成員已全部以 verified resolution 離開集合。V1、V2 與 7 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第六輪，是 6 輪上限的最後一輪，依位置推導為 `micro` 輪，由單一 Reviewer V 對 V1、V2 逐一給出 resolved/unresolved 判定。若未 pass，依規則記錄 `decision: aborted` 並執行 Abort triage。
