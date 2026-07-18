# Cash Apply Review — Round 6

## Reviewer Findings

### Critical

1. `severity`: Critical；`confidence`: 100；`layer`: design；`location`: `install-cash-skills.fish:446-472,725-728`；`summary`: retired plus identity 只比對 `SKILL.md` 前兩列，未證明 frontmatter 有 closing delimiter 且 matching `name` 唯一，malformed 或使用者自有內容可能被誤判後永久刪除；`recommendation`: 驗證完整 frontmatter boundary、唯一且精確的 `name` field，拒絕 missing closing、duplicate/conflicting name，並加入零寫入 fixtures；`introduced_by`: current change diff 的 two-line identity heuristic 與其後 non-recursive deletion；reviewer source: Reviewer A — Adherence、Reviewer B — Quality。
2. `severity`: Critical；`confidence`: 100；`layer`: design；`location`: `install-cash-skills.fish:446-472,725-728`；`summary`: destructive preflight 與 `rm "$skill_dir/SKILL.md"` 相隔 cash/receipt mutation，candidate directory 若在其間被換成 target 外 symlink，`rm` 會沿 caller-controlled parent path 刪除外部檔案；`recommendation`: 先把 candidate atomic rename 到 target 內 same-filesystem quarantine，再對移入物重驗 non-symlink exact shape，只有通過才刪除，並加入 symlink／unknown-entry swap fault injection；`introduced_by`: current change diff 保存 candidate path 字串後於 destructive phase 未重新綁定便沿原 path 刪除；reviewer source: Reviewer B — Quality。

### Warning

1. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:1018-1175`；`summary`: cleanup matrix 未獨立覆蓋 missing `SKILL.md`、`SKILL.md` symlink 與 malformed frontmatter，且首次安裝、adoption、upgrade、current 正常分支未各自 assert 四列 `remove:` plan；`recommendation`: 補齊 unsafe matrix 與每個具名 normal branch 的完整 plan assertion；reviewer source: Reviewer A — Adherence。
2. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `install-cash-skills.fish:600-624,667-688`；`summary`: atomic replacement 需要 destination directory 可寫／可搜尋，但既有 destination preflight 只檢查檔案本身 `-w`，使 dry-run 可回報 update 而真實 `mktemp` 失敗，後段 failure 也可能留下 partial writes；`recommendation`: 對每個預計 replacement 的 existing destination parent 預驗 `-w`／`-x`，加入 dry-run/actual 同樣 exit `1`、no result、零寫入 fixture；`introduced_by`: current change diff 導入 same-directory `mktemp` + `mv`，但對應 preflight 未加入 parent permissions；reviewer source: Reviewer B — Quality。
3. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:1088-1098,1161-1173,1335-1370`；`summary`: regression matrix 未覆蓋 newer target 含 retired plus 且使用 `--force` 仍零移除，也未對 non-empty general/retired-plus batch 的完整 summary counts 做 assertion；`recommendation`: 加入 newer+force full-tree zero-write fixture及 normal/dry-run/force/retired-plus batch exact summary assertions；reviewer source: Reviewer B — Quality。

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 2
- post-filter cumulative blocking Warning: 3
- non-blocking triaged findings: 0
- `critical_gap`: true
- `round_type`: full
- rationale: 本 loop 第一輪的五個 confidence 100 findings 都直接影響不可逆刪除邊界、dry-run parity 或 tasks/spec 明定的 fail-loud evidence，因此全部進入 cumulative blocking set；frontmatter false identity 與 preflight-to-delete symlink swap 皆可造成未知或 target 外內容被刪除。

## Fix Actions

- 修改 `design.md` 與 delta spec：frontmatter identity 改為 closed opening block + exactly one matching `name`；destructive phase 改為 target 內 same-filesystem atomic quarantine rename、quarantine revalidation、unknown-content preservation/restore 與 no recursive deletion。
- 修改 `install-cash-skills.fish`：新增完整 frontmatter/shape validator供 preflight 與 quarantine 後重用；不再沿 original candidate path 刪除，candidate swap 只會移動 symlink/unknown directory 本身，重驗失敗時不刪內容並在安全時 restore。
- 修改 `install-cash-skills.fish`：對每個預計 atomic replacement 的 existing managed destination parent 預先驗證 directory write/execute permissions，使 dry-run 與 actual 使用相同 preflight。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：新增 missing SKILL、SKILL symlink、missing closing、duplicate/conflicting name、preflight 後 symlink/extra-entry swap、unwritable destination parent dry/actual、newer+force、每個 normal cleanup plan 與 exact batch summary fixtures。
- Fix propagation 與 post-fix mechanical self-check：retired plus identity/quarantine/plan/summary identifiers 已跨 design、spec、installer、tests、documentation 檢查；8 requirements、46 scenarios、14/14 tasks 一致，open signals 無 `check` field。
- Post-fix validation：Fish syntax、完整 `fish scripts/cash-skills/tests/skill-checks.fish`、`spectra analyze add-versioned-cash-skill-batch-update --json`、`spectra validate add-versioned-cash-skill-batch-update` 與 `git diff --check` 全部通過；analyze 僅保留 9 個非阻塞 Example Suggestions。

## Decision

next_round
