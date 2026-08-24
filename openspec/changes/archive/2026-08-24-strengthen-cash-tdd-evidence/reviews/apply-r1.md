# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

- `severity`: Warning｜`confidence`: 90｜`layer`: design｜`location`: `.claude/skills/cash-debug/SKILL.md:104-107`、`.agents/skills/cash-debug/SKILL.md:104-107`（Phase 4 編號步驟）｜`summary`: Phase 4 編號清單無條件以 `1. **Make the minimum change**` 起頭，等於在 `tdd: true` 且命中 canonical branch 1／2 時要求先做 production edit，與 C1「MUST在任何production edit前實際執行current workflow命名的primary verification target」互斥；design D4 移除舊絕對句的理由正是避免與 canonical resource 互斥的 ordering，此次卻換成方向相反的另一條絕對 ordering｜`recommendation`: 把編號清單明訂為 `tdd: false` 序列，並在其前說明 `tdd: true` 時由 fetched `instruction` 擁有 ordering、需先觀察 failure marker 再做 production edit；同步在 `assert_tdd_discipline` 加入守護該語意的 assert｜reviewer source: A（conf 90）與 B（conf 75，`introduced_by`: `.claude/skills/cash-debug/SKILL.md:104-107`，diff hunk `@@ -96,9 +98,14 @@`）合併，取 `layer: design`

- `severity`: Warning｜`confidence`: 90｜`layer`: design（Reviewer A 原報 `text`，主 agent 依 confidence filter 重新分類為 `design`，因其修復會變更一條 normative 列舉）｜`location`: `openspec/specs/cash-cli/spec.md:158-160`（`### Requirement: Cash workflow command surface`）vs `openspec/changes/strengthen-cash-tdd-evidence/specs/cash-cli/spec.md:19`｜`summary`: delta 只 MODIFY 了兩個 requirement 並把 skill 集合擴為 `<tdd|test-quality|audit>`，但 master spec 另一個 requirement 仍逐字寫 `instructions --skill <tdd|audit>` 且句首為「僅需支援」；archive 後同一份 spec 會同時存在兩個互相矛盾的 normative 列舉，且「僅需支援」措辭會把 `test-quality` 讀成非支援項｜`recommendation`: 在 delta 的 `## MODIFIED Requirements` 補上逐字同名的 `### Requirement: Cash workflow command surface`，僅把列舉改為 `<tdd|test-quality|audit>`，其餘內容逐字保留｜reviewer source: A（conf 90）與 B（conf 78，`introduced_by`: `.cash-skills/lib/cash_cli/resources.py:105-147` 新增的 `DISCIPLINES["test-quality"]` 使該列舉為假）合併

- `severity`: Warning｜`confidence`: 95｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py:461-510`（三個 validator 的 `forbidden` 區塊）與 `:205-226`、`:268-290`、`:341-378`（inversion mutations）｜`summary`: 三個 validator 的 `forbidden` guard 全是 dead code——沒有任何測試行使該路徑，且每個「inversion」mutation 都同時移除了必要 literal，因此一律由較早的 `missing …` 判定拒絕；保留全部必要 literal、只附加一句寬鬆例外句（`「但在時間緊迫時，也可以先做 production edit 再補跑該 target。」`）的加法式矛盾會被 `validate_tdd_red_green` 接受｜`recommendation`: 為每個 validator 增加一個保留全部必要 literal 的 additive-contradiction case，使 `forbidden` 路徑真正被行使；並讓 `assert_rejected` 斷言 rejection 理由，使 removal 無法冒充 inversion 偵測；同時把 `forbidden` 由「測試自造的合成字串」擴為可辨識的寬鬆措辭集合｜`introduced_by`: `scripts/cash-cli/tests/test_graph_instructions.py:461-510` 新增的三個 validator 與 `:205-226`、`:268-290`、`:341-378` 的 mutation 區塊｜reviewer source: B

### Suggestion

- `severity`: Suggestion｜`confidence`: 75（原 Warning，依 confidence filter 由 `[50, 80)` 降級）｜`layer`: design｜`location`: `openspec/changes/strengthen-cash-tdd-evidence/specs/cash-skill-workflows/spec.md:49-55` 對應 `.claude/skills/cash-apply/SKILL.md:210`、`:229`｜`summary`: scenario「其餘 task 使用命名 verification target」的第二個 `**AND**` 要求「task再執行`regression`欄位指定的相關targets」，但沒有任何實作文字承載這個執行義務：canonical branch 4 只寫「執行命名的 verification target」，新增的 evidence mapping bullet 只描述 `regression` 欄位語意，既有 `Verify before marking done` gate 仍是單數 target｜`recommendation`: 在 `Verify before marking done` 加入 primary 通過後執行 `regression` 欄位 targets 的義務，並加 assert 守護｜reviewer source: A

- `severity`: Suggestion｜`confidence`: 65（原 Warning，依 confidence filter 由 `[50, 80)` 降級）｜`layer`: design｜`location`: `.claude/skills/cash-apply/SKILL.md:211`、`.agents/skills/cash-apply/SKILL.md:211`｜`summary`: 五欄硬 gate 對 bundle ≤ 2.16.0 所撰寫的既有 `tasks.md` 沒有遷移路徑，下游 repo 在 change 進行中升級到 2.17.0 時，每個 pending task 都會變成阻塞式暫停｜`recommendation`: 或加入 fallback，或把它記為已知的 breaking change 並附升級說明｜`introduced_by`: `.claude/skills/cash-apply/SKILL.md:211` 與 `.cash-skills/lib/cash_cli/resources.py:85-96`｜reviewer source: B

- `severity`: Suggestion｜`confidence`: 90｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish:305`｜`summary`: 新增的 `rg -Fq -- '"$cash_cli" instructions --skill test-quality' .agents/skills/cash-*/SKILL.md` 永遠不可能失敗——它被 44 行之前的 `quality_count = 1` 檢查完全涵蓋，因此 `tdd-discipline` 群組對 command matrix 沒有獨立判別力｜`recommendation`: 讓 `tdd-discipline` 直接呼叫真正的 `assert_command_matrix`，或改成斷言 cash-apply／cash-debug 以外的消費點｜reviewer source: A（conf 70）與 B（conf 90）合併

- `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish:265-266`（cash-apply）與 `:281-303`（cash-debug 迴圈）｜`summary`: 「單一來源禁重複」的 `assert_absent` 只對 cash-apply 檢查五個 gate 中的兩個，cash-debug 迴圈則完全沒有 test-quality 去重 assert｜`recommendation`: 把五個 gate 的代表性 literal 整理成共用集合，於 cash-apply 與 cash-debug 兩個迴圈共同套用｜reviewer source: A

- `severity`: Suggestion｜`confidence`: 88｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish:312`、`:318`、`:355-357`｜`summary`: `assert_tdd_variant_parity` 內兩個機制是惰性的——invocation-prefix 正規化 regex 在三個比對區段中沒有任何 match，sha256 digest 算完只被印進 `>/dev/null`｜`recommendation`: 移除惰性 digest 與 stdout 丟棄；Reviewer B 已確認 section 抽取本身 fail closed（anchor 改名會以 exit 1 與具名訊息失敗）｜reviewer source: B

- `severity`: Suggestion｜`confidence`: 95｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py:346-348`｜`summary`: `lambda description, template: validate_tasks_resource(description, template)` 是 pass-through wrapper，與直接傳 `validate_tasks_resource` 語意相同｜`recommendation`: 直接傳函式本身｜reviewer source: B（complexity lens: `pass-through wrapper`）

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 3
- 非阻塞 triaged finding count: 6
- `critical_gap`: false
- `round_type`: full

rationale：本輪為未 seeded run 的第一輪，所有存活的 Critical 與 Warning 皆為阻塞。三筆阻塞 Warning 都經主 agent 獨立複核為真：cash-debug Phase 4 的絕對 ordering 與 C1 的 executed-RED gate 互斥；master spec `Cash workflow command surface` 的 skill 列舉未被 delta 涵蓋，archive 後會產生自相矛盾的 normative 列舉；三個新 validator 的 `forbidden` guard 未被任何測試行使，且加法式矛盾可被接受，使宣稱的 inversion 偵測未經驗證。三筆皆可在不觸及裁判面保護的情況下修復，因此本輪為 `next_round` 而非 `aborted`。六筆非阻塞 finding 全部在本輪一併處理，未留下待辦。

## Fix Actions

- **W1（cash-debug Phase 4 ordering）**：修改 `.claude/skills/cash-debug/SKILL.md`，在 Phase 4 編號清單前加入「The numbered order below is the `tdd: false` sequence…」段落，明訂 `tdd: true` 時由 fetched `instruction` 擁有 ordering，並須先執行 Phase 3 primary verification target、觀察其 failure marker 後才可做 production edit。`.agents/skills/cash-debug/SKILL.md` 由 `scripts/cash-skills/generate.fish` 重新生成。
- **W2（master spec 列舉矛盾）**：修改 `openspec/changes/strengthen-cash-tdd-evidence/specs/cash-cli/spec.md`，於 `## MODIFIED Requirements` 補入逐字同名的 `### Requirement: Cash workflow command surface`，內容自 master spec 逐字複製、僅將 `instructions --skill <tdd|audit>` 改為 `instructions --skill <tdd|test-quality|audit>`；已確認複製內容不含 trace annotation 區塊，且 title 與 master spec byte-for-byte 相同。
- **W3（validator forbidden guard 為 dead code）**：修改 `scripts/cash-cli/tests/test_graph_instructions.py`。`assert_rejected` 新增必填的 `because` 參數並斷言 rejection 訊息前綴，使 removal 無法冒充 inversion 偵測；新增共用的 `PERMISSIVE_CONTRADICTIONS` 與 `_reject_permissive`，三個 validator 各自套用；三個 mutation 測試各新增一個保留全部必要 literal 的 additive-contradiction case。驗證：移除三行 `_reject_permissive` 呼叫後三個 mutation 測試以 exit 1 失敗，還原後 22 tests OK。
- **非阻塞 triage 與處理（六筆全部一併修復，未留待辦）**：
  - regression 執行義務（Reviewer A）：修改 `.claude/skills/cash-apply/SKILL.md` 的 `Verify before marking done`，加入 primary 通過後執行 `regression` 欄位 targets、欄位為 `N/A` 時確認理由仍成立的義務。
  - 五欄 gate 缺遷移路徑（Reviewer B）：triage note。該暫停行為由 spec `cash-skill-workflows` 明文要求（「任一欄位缺失…MUST在任何production edit前走既有unclear-task branch」），在本 change 範圍內修改會與 spec 互斥；記錄為已知的升級影響，交由後續 change 決定是否提供 fallback。
  - command matrix assert 不可失敗（A／B）：`scripts/cash-skills/tests/skill-checks.fish` 以呼叫真正的 `assert_command_matrix` 取代該行。
  - 去重 assert 覆蓋不足（Reviewer A）：`scripts/cash-skills/tests/skill-checks.fish` 新增 `test_quality_gate_literals` 共用集合，於 cash-apply 與 cash-debug 兩個迴圈共同套用。
  - parity helper 惰性機制（Reviewer B）：`scripts/cash-skills/tests/skill-checks.fish` 移除 `hashlib` import、digest 計算、print 與 `>/dev/null`。
  - pass-through lambda（Reviewer B）：`scripts/cash-cli/tests/test_graph_instructions.py` 改為直接傳 `validate_tasks_resource`。
- **修復守護補強**：mutation check 發現 W1 與 A2 的修復原本沒有任何 assertion 守護（移除修復後 `tdd-discipline` 仍 PASS）。已於 `scripts/cash-skills/tests/skill-checks.fish` 新增 `regression target execution obligation`、`toggle-scoped fix ordering`、`red-before-production-edit ordering` 三條 assert；重跑 mutation check 後兩者皆以具名 failure 失敗，還原後 PASS。
- **Fix propagation**：`test-quality`、`<tdd|test-quality|audit>`、五欄名稱與 `regression` 欄位義務等概念已 grep 過全部 artifacts 與變更檔並同步；change 目錄內已無殘留的 `<tdd|audit>` 列舉。
- **修改的檔案**：`openspec/changes/strengthen-cash-tdd-evidence/specs/cash-cli/spec.md`、`.claude/skills/cash-debug/SKILL.md`、`.agents/skills/cash-debug/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`scripts/cash-cli/tests/test_graph_instructions.py`、`scripts/cash-skills/tests/skill-checks.fish`、`.cash-skills/manifest.tsv`（共 8 個）。
- **Managed bytes 重新發布**：所有 managed skill edits 完成後執行 `./install-cash-skills.fish --self` 重建 manifest；`bundle_version` 維持 2.17.0（本 change 已在 task 1.1 完成遞增，尚未提交）。
- **Post-fix 驗證**：`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`、`generated-fresh`、全量 `skill-checks.fish`、`fish scripts/cash-cli/tests/cli-checks.fish`（170 tests）、`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`（22 tests）、`test_discovery_contracts.py`（9 tests）、`python3 scripts/cash-skills/tests/test_bundle_version_history.py` 全部 exit 0。
- **Post-fix mechanical self-check**：spec delta annotation 平衡（0/0）、count consistency（3 disciplines／4 branches／5 gates／5 fields）、identifier cross-grep、delta title identity（四個 MODIFIED title 全部與 master spec byte-for-byte 相符）皆通過，未發現需修正項目。
- **Touched 記錄**：`"$cash_cli" touched ensure` 後逐一 `touched record` 七個 change 目錄外的檔案，全部成功，無警告。
- 無 `未修復：裁判面保護` 記錄。本輪修改的 `.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-apply/SKILL.md` 與 `scripts/cash-skills/tests/skill-checks.fish` 雖屬保護路徑，但均逐字列於 proposal `## Impact` 的 affected-code 與 `tasks.md` 的 delivery，屬 structured scope declarations 內。

## Decision

next_round

本輪 post-filter cumulative blocking set 含 3 筆阻塞 Warning、0 筆 Critical，未達 pass 條件。三筆阻塞 finding 與六筆非阻塞 finding 均已在本輪 `## Fix Actions` 取得對應行動（阻塞者皆為具名檔案的實際修復），且修復後全部 verification 與 regression targets 皆 exit 0，因此進入下一輪由 Reviewer V 做 delta verification。
