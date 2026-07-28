# Cash Apply Review — Round 5

本輪是 seeded re-run 的第二輪，依 run 內位置推導為 `micro`，由單一 Reviewer V 執行 delta 驗證。

## Reviewer Findings

### Critical

無。

### Warning

1. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `openspec/changes/target-receipt-bootstrap/proposal.md`（Proposed Solution 第 4 點、`## Impact` 的 Deployment surface）
   - **introduced_by**: round 4 Fix Actions 第 5 條「部署時序規則第三次適用」——該條明文宣稱「`design.md` D2、Contract 第 7 項、部署時序規則段與 `proposal.md` 的部署敘述皆同步為 2.11.0」，實際上 `proposal.md` 未被更新，該宣稱為假；同輪 post-fix mechanical self-check 的「版本三處一致為 2.11.0」只涵蓋版本檔／常數／source receipt，未 grep proposal
   - **summary**: round 4 把版本推進到 2.11.0 並重新 `--all`，但 `proposal.md` 兩處部署敘述仍寫「最終部署版本為 2.10.0」、且仍稱「重新部署過兩次」，與地面事實及 `design.md` D2／D6／Contract 第 7 項全部矛盾
   - **recommendation**: 兩處版本改為 2.11.0、「兩次」改為「三次」並補上第三次的內容，使 proposal 與 design D6 的三次適用敘述一致
   - **evidence**: reviewer 實測地面事實——`cash-skills.version` = `2.11.0`、`BUNDLE_VERSION = "2.11.0"`、source receipt 首行 `version 2.11.0` 且 `installer.py` record digest 與現地 `shasum -a 256` 相同、8 個 registry target 唯讀讀取皆為 `2.11.0` 且 digest 一致；`proposal.md` 全檔無任何 2.11.0 字串。reviewer 另指出這與 apply-r2 的 M1 屬同型復發（fix 只改 design／spec 而未同步 proposal／tasks）
   - **failure_scenario**: 後續維護者以 `## Impact` 的 Deployment surface 作為「targets 目前綁定哪個版本」的權威記錄（那正是該欄位的用途），認定 targets 持有 2.10.0，於是修改 `installer.py` 後 bump 到 2.11.0 再 `--all`——但 2.11.0 早已以不同 bytes 散佈出去，`--all` 會對每個 target 以 equal-version source integrity drift 失敗且 `--force` 不可繞過，正是 D6 這條規則本身要避免的死結

### Suggestion

2. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `text`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `openspec/changes/target-receipt-bootstrap/tasks.md`（第 7 節前言與 task 7.6）
   - **introduced_by**: round 4 Fix Actions 第 3 條「finding 2（步驟順序）已修復」——該條宣稱「全部 `步驟 6`／`D3-6` 交叉引用同步」，但同步範圍未涵蓋 `tasks.md` 與 `openspec/signals/`
   - **summary**: 步驟 6／7 對調後，`tasks.md` 仍寫「使 D3 步驟 7 的完整性檢核恆真」與「更新『它實際做了什麼』第 7 步」，指向對調後已是 mode 正規化的編號
   - **recommendation**: 改為不耦合編號的指稱，signal 檔同一處一併處理
   - **evidence**: reviewer 逐一核對 `design.md` 與 `CASH-INIT-RECEIPT.md` 的編號引用皆與對調後及程式碼實際順序相符，唯 `tasks.md` 兩處與 signal 一處仍指舊編號

3. **severity**: `Suggestion`｜**confidence**: `75`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `openspec/changes/target-receipt-bootstrap/tasks.md`（全檔止於 7.10）對照 `design.md` Implementation Contract 第 7 項
   - **introduced_by**: round 4 同時做了兩件事——Fix Actions 第 4 條把 Contract 第 7 項改寫為 task 序位判準，以及第 5 條在 task 清單之外執行 2.11.0 的 bump 與部署
   - **summary**: Contract 第 7 項以 task 序位表述 bump 先後，但 2.11.0 那次 bump 不在任何 task 內，該判準對最終 bump 沒有可指涉的 task；task 7.9／7.10 的部署證據仍斷言 2.10.0
   - **recommendation**: 新增一節 task 記錄該次 bump 與部署，或把判準限縮為「tasks 內的每次 bump」並明載最終 bump 的證據出處
   - **evidence**: `tasks.md` 全檔無 2.11.0 字串；reviewer 確認 Contract 第 7 項所舉的兩個配對本身成立（`replaceable_paths()` 的守衛集合涵蓋 `installer.py`），問題僅在最終 bump 無錨點；安全性質本身無虞（實測版本與 digest 全數一致）

4. **severity**: `Suggestion`｜**confidence**: `75`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `specs/cash-cli/spec.md`、`proposal.md`、`CASH-INIT-RECEIPT.md` 的 import-time 相依描述
   - **introduced_by**: round 4 Fix Actions 第 1 條為 finding 1 新增的 import-time 段落
   - **summary**: 三處都以「`cash_cli/__init__.py` 匯入鏈上的模組」界定 4 個成員，但 `cash_cli/__init__.py` 本身缺席時反而走到具名 error code（PEP 420 namespace package fallback），且 `config.py` 是 `installer.py` 自己的 import 而非 `__init__.py` 鏈上的；分類結論正確，界定方式卻無法讓讀者推導出正確分組
   - **recommendation**: 逐一標明四個成員各自的匯入來源，並明載 `cash_cli/__init__.py` 因 namespace package fallback 落在 15 的一側
   - **evidence**: reviewer 實測移走 `__init__.py` 得到 `init_inventory_invalid` 具名 error code；import 圖實查 `__init__.py` → `main.py` → `errors.py`，而 `installer.py` 自身 `from .config import`

### Cumulative blocking set 判定（Reviewer V）

| member | verdict | fix reference | 驗證要點 |
| --- | --- | --- | --- |
| M1 — import-time 相依未被期望集合涵蓋 | `resolved` | round 4 Fix Actions 第 1 條全部六個子項 | reviewer 於 `/tmp` fixture 獨立枚舉全部 19 個 `BUNDLE_RUNTIME_PATHS` 成員逐一 rename 實測：15 個回傳 `init_inventory_invalid` 具名 error code（stdout JSON、exit 1、零 receipt），4 個以 stderr `No module named` 失敗且 stdout 為空，正是 `config.py`／`errors.py`／`installer.py`／`main.py`，與 round 4 修正後的 15／4 分類逐一相符，無第五個亦無 `other` 分類。artifact 對齊逐處查證通過；`test_every_runtime_member_is_classified` 會在成員跨組移動時轉紅 |

M1 經 Reviewer V 明確判定 `resolved` 並移出 cumulative blocking set；finding 1 以 `fix-introduced` 進入集合。

## Rating

- post-filter cumulative blocking set Critical count：`0`
- post-filter cumulative blocking set Warning count：`1`
- 非阻塞 triaged finding count：`3`
- `critical_gap`：`false`
- `round_type`：`micro`

**rationale**：M1 經獨立枚舉全部 19 個成員實測後判定 `resolved` 並移出集合。Reviewer V 新增四筆 finding 皆為 `fix-introduced`：finding 1 為 `Warning`（`confidence: 100`），依 disposition 規則屬阻塞並進入集合；finding 2 為 `Suggestion`（`layer: text`，主 agent 複查其修正不影響任何行為或設計陳述，維持 `text`）；finding 3、4 的 `confidence` 為 `75`，落在 `[50, 80)` 依 confidence filter 降為 `Suggestion`。三筆 `Suggestion` 皆非阻塞。集合中僅餘 finding 1 一筆阻塞 `Warning`，已於本輪修復但尚未經 reviewer 驗證，故本輪為 `next_round`。

## Fix Actions

- **finding 1（proposal 部署敘述未同步）已修復**：`proposal.md` Proposed Solution 第 4 點改為「重新部署過三次」並補上第三次（2.11.0 收斂 `__pycache__` 過濾範圍修正）；`## Impact` 的 Deployment surface 兩處「最終部署版本為 2.10.0」改為 2.11.0，並標註第三次部署的證據出處為 round 4 的 round file。修改檔案：`proposal.md`。
- **finding 2（步驟編號交叉引用）已修復**：`tasks.md` 第 7 節前言與 task 7.6 的步驟號指稱改為不耦合編號的描述（「D3 的 inventory 完整性檢核一步」、「『它實際做了什麼』的 inventory 完整性檢核一步」）；`openspec/signals/expected-set-derived-from-observed-state.md` 同一處一併處理。改為不耦合編號而非改號，是為了避免下一次步驟調整再度產生同型殘留。修改檔案：`tasks.md`、`openspec/signals/expected-set-derived-from-observed-state.md`。
- **finding 3（最終 bump 無 task 錨點）已修復**：採 reviewer 提供的第二個選項——Contract 第 7 項的判準限縮為「**tasks 內的**每次 bump」，並明載「發生在 review loop fix actions 內、不對應任何 task 的 bump（2.10.0 → 2.11.0）以該輪 round file 為證據出處，其序位由 `## Fix Actions` 記載，判準同為版本檔先寫入」。不新增 task 節，因為 fix actions 的工作由 round file 記錄才是正確的歸屬，捏造已完成的 task 會使 tasks.md 失去「經 task loop 驗證」的語意。修改檔案：`design.md`。
- **finding 4（import-time 界定不可推導）已修復**：`design.md` Contract 第 12 項逐一標明四個成員各自的匯入來源（`installer.py` 為 `-m` 目標模組本身、`config.py` 為 `installer.py` 自身的 `from .config import`、`main.py` 與 `errors.py` 為 `cash_cli/__init__.py` 的匯入鏈），並明載 `cash_cli/__init__.py` 因 PEP 420 namespace package fallback **不**屬此類而落在 15 的一側；`specs/cash-cli/spec.md`、`proposal.md`、`CASH-INIT-RECEIPT.md` 三處同步為同一界定。修改檔案：`design.md`、`specs/cash-cli/spec.md`、`proposal.md`、`CASH-INIT-RECEIPT.md`。
- **本輪改用全面 propagation sweep 而非點狀修補**：finding 1 與 2 都是 round 4 宣稱已同步而實際未涵蓋全部位置所致（reviewer 指出 finding 1 與 apply-r2 的 M1 屬同型復發）。本輪的 self-check 因此改為對「版本字串」「步驟編號交叉引用」「import-time 計數與界定」三個概念各做一次跨全部 artifact、文件、測試與 signals 的 grep，再比對地面事實，而非只 grep 被 finding 指名的檔案。
- **analyzer 誤判處理**：`cash analyze` 把 Deployment surface 散文中的 `reviews/apply-r4.md` 誤判為未被 task 覆蓋的 Impact path（該路徑不在 `## Impact` 清單內）。改以「該輪 round file」表述後 non-Suggestion findings 歸零，語意不變。此為本 change 第二次遇到同一類 analyzer 路徑誤判（前次為 `cash_cli/__init__.py`）。
- **未觸及程式碼**：本輪四筆 fix 全為 artifact 與文件，`.cash-skills/lib/cash_cli/` 下無任何修改，因此不觸發 D6 部署時序規則，不需 bump 亦不需重新部署。地面事實維持 2.11.0：版本檔、`BUNDLE_VERSION`、source receipt 與 8 個 registry target receipt 一致，`installer.py` digest 與 source 相同。
- **post-fix 驗證**：`"$cash_cli" validate` 通過；`cash analyze` non-Suggestion findings 為 `0`；`scripts/cash-skills/tests/test_init_receipt.py` 18 tests、`skill-checks.fish` 全套、`cli-checks.fish` 145 tests 全數通過。
- **post-fix mechanical self-check**：四處「最終」版本宣稱皆為 2.11.0 且與地面事實相符；import-time 計數在 `design.md`、`proposal.md`、`specs/cash-cli/spec.md`、`CASH-INIT-RECEIPT.md` 與測試的 `import_time` 集合五處一致為 4（15／4）；`tasks.md`、`implementation-notes.md` 與 signals 中耦合步驟編號的交叉引用為 `0`；spec delta 註解開閉數皆為 `0`。
- **變更目錄外的檔案記錄**：本輪修改的 change 目錄外檔案為 `CASH-INIT-RECEIPT.md` 與 `openspec/signals/expected-set-derived-from-observed-state.md`。未修改 `.cash-skills/` 下的 runtime 檔，故不需重建 receipt。已執行 `touched ensure` 與 `touched record`。

## Decision

next_round
