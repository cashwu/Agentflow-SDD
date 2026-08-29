# Cash Apply Review — Round 1

## Reviewer Findings

### Warning

- severity: Warning
  confidence: 80
  layer: design
  location: `.agents/skills/cash-apply/SKILL.md` line 367（來源 `.claude/skills/cash-apply/SKILL.md` line 367 經 generate.fish 前綴置換）
  summary: `.agents` 變體的模板規範句被生成置換弄壞——前綴對枚舉「（`/cash-` 與 `$cash-`）」在 `.agents` 變體成為「（`$cash-` 與 `$cash-`）」，同一前綴枚舉兩次，該句在 `.agents` 讀者眼中自相矛盾。
  recommendation: 改寫 `.claude` 來源句避開可被置換的 `/cash-` 字面，再重跑 generate.fish 與 `./install-cash-skills.fish --self`。
  reviewer source: Reviewer A（Warning, confidence 80, layer design）與 Reviewer B（Warning, confidence 75, layer text）同報；依合併規則取 layer design、confidence 取已驗證之 80。主代理已直接 grep 驗證退化字串實存。

### Suggestion

- severity: Suggestion（原 Reviewer B Warning, confidence 55，依 confidence filter [50,80) 降級）
  confidence: 55
  layer: design
  location: `.claude/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 步驟 4b「取得 dirty 路徑」bullet
  summary: 解析規則未寫明每筆條目以兩字元狀態欄加一個空白開頭、比對前須剝除該前綴，naive NUL-split 交集可能得到靜默 false pass。
  recommendation: 在該 bullet 補一句剝除前綴的子句，鏡射至 delta spec，並在 skill-checks 以新內容獨有 literal pin 住。
  introduced_by: 本 change diff 新增之「取得 dirty 路徑」bullet。
  reviewer source: Reviewer B。

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 1
- non-blocking triaged finding count: 1
- critical_gap: false
- round_type: full
- rationale: 首輪（unseeded）全部 surviving Critical／Warning 皆為 blocking。合併後僅一個 Warning（`.agents` 前綴對枚舉退化）進入 cumulative blocking set，無 Critical，故 critical_gap 為 false；因 blocking set 非空，本輪不能 passed，進入 next_round 由 micro 輪驗證修復。

## Fix Actions

- 修復 blocking Warning（前綴對枚舉退化）：把 `.claude/skills/cash-apply/SKILL.md` line 367 的「（`/cash-` 與 `$cash-`）」改寫為不含可置換字面的「（斜線與錢字號兩種形式）」，重跑 `scripts/cash-skills/generate.fish` 再生 `.agents/skills/cash-apply/SKILL.md`，並以 `./install-cash-skills.fish --self` 重建 `.cash-skills/manifest.tsv`。已驗證退化字串於 `.agents` 變體歸零。修改檔案：`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`.cash-skills/manifest.tsv`。
- 修復 triaged Suggestion（NUL 解析剝除前綴子句）：於兩個 cash-archive 變體步驟 4b「取得 dirty 路徑」bullet 補「每筆條目以兩字元狀態欄加一個空白開頭，比對前先剝除該前綴取出路徑」，同句鏡射至 delta spec `specs/cash-skill-workflows/spec.md` 的 ADDED requirement，並在 `scripts/cash-skills/tests/skill-checks.fish` 的 uncommitted-source guard 區塊加入 literal `比對前先剝除該前綴取出路徑`。修改檔案：`.claude/skills/cash-archive/SKILL.md`、`.agents/skills/cash-archive/SKILL.md`、`openspec/changes/strengthen-archive-commit-guidance/specs/cash-skill-workflows/spec.md`、`scripts/cash-skills/tests/skill-checks.fish`（manifest 已於同批 `--self` 重建）。
- downgrade trace：Reviewer B finding「條目涵蓋枚舉未列 unmerged／typechange」severity Suggestion, confidence 35 < 50，依 confidence filter 丟棄；行為無誤（該類條目仍以單路徑條目入 dirty 集合），僅措辭非窮舉。
- layer 合併記錄：前綴退化 finding 由 Reviewer B 標 layer text、Reviewer A 標 layer design，依合併規則取 design。
- 前置自我檢查記錄（非 reviewer findings）：round 1 spawn 前依 open signals `implementation-deviation-not-backfilled`／`declared-scope-implementation-drift` 的 best-effort 檢查，把兩筆 deviation（`BUNDLE_VERSION` 同步、`test_live_namespace.py` `touched_allow` 擴充）回填至 proposal（Non-Goals 例外句、Impact Modified 清單）與 design（D5、D2），並於 implementation-notes.md 追加回填條目。
- fix 後已重跑 pre-round mechanical self-check（annotation lint、title identity、identifier cross-grep）無失敗，並重跑 `./scripts/cash-skills/tests/skill-checks.fish` 全綠（PASS: all）、`./install-cash-skills.fish --self` 回報 `Result: current`。

## Decision

next_round

blocking Warning 已有修復記錄，待 micro 輪 Reviewer V 對 cumulative blocking set 成員回傳 resolved／unresolved verdict。
