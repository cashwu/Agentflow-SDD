# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

1. **Installer 與 runtime 的 master requirements 未完整遷移**
   - confidence: 96
   - layer: specification
   - location: `specs/cash-skill-workflows/spec.md`
   - summary: 原草案只改寫部分需求，仍保留會要求 Spectra runtime、非交易式發佈與舊 namespace 的權威 requirements。
   - recommendation: 對所有衝突 requirements 建立精確的 `MODIFIED` 或 `REMOVED` delta，並把替代契約移入 `cash-cli` capability。
   - reviewer: adherence, quality

2. **相對 launcher path 在 nested cwd 下無法運作**
   - confidence: 99
   - layer: design
   - location: `design.md`
   - summary: `.cash-skills/bin/cash` 若以相對路徑呼叫，從子目錄執行 skill 時會解析到錯誤位置。
   - recommendation: 先以 Git root discovery 取得 workspace root，再使用絕對 launcher path。
   - reviewer: quality

3. **`instructions apply` 與 analyze/drift consumer fields 不完整**
   - confidence: 98
   - layer: interface
   - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
   - summary: 原草案沒有列出 Cash skills 實際消費的完整 JSON 欄位，也沒有規範 drift 的非 JSON 行為。
   - recommendation: 明列完整欄位、型別、空值與 non-JSON 契約，並加入 consumer contract tests。
   - reviewer: adherence, quality

4. **缺少 Cash-owned touched-state 與 legacy state migration**
   - confidence: 98
   - layer: runtime state
   - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
   - summary: `cash-commit` 等流程仍依賴 `.spectra/touched` 與 snapshots，但替代 CLI 未定義等價狀態。
   - recommendation: 定義 `.cash-skills/state/` 中的 snapshots、touched allowlist、pre-existing dirty 排除與受驗證的 legacy import。
   - reviewer: adherence, quality

5. **sync 與 archive 可能重複合併 specs**
   - confidence: 95
   - layer: lifecycle
   - location: `design.md`, `specs/cash-cli/spec.md`
   - summary: 原草案未定義 sync 後 archive 的 idempotency，也未描述拒絕 sync 時的 archive 分支。
   - recommendation: 建立 digest manifest、idempotent merge 與 `archive --skip-specs` 契約。
   - reviewer: quality

6. **legacy removal 只靠名稱辨識，可能刪除使用者修改**
   - confidence: 99
   - layer: installer safety
   - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
   - summary: 只以 Spectra skill 名稱判斷舊檔不足以證明檔案為 installer-owned baseline。
   - recommendation: 使用 versioned full-body digest manifest，並在 body、mode、hardlink 或 symlink 不符時 fail closed。
   - reviewer: quality

7. **launcher executable mode 未受契約管理**
   - confidence: 97
   - layer: installer
   - location: `design.md`, `specs/cash-cli/spec.md`
   - summary: 若 installer 沒有保存與驗證 executable mode，安裝完成的 CLI 仍可能無法執行。
   - recommendation: launcher 固定為 `0755`、其他新檔為 `0644`，receipt 記錄並驗證 mode。
   - reviewer: quality

8. **多檔 publication 並非真正 all-or-nothing**
   - confidence: 99
   - layer: filesystem transaction
   - location: `design.md`, `specs/cash-cli/spec.md`
   - summary: 單檔 atomic replace 無法避免多檔操作中途失敗留下部分狀態，也未覆蓋 preflight 後替換或 rollback failure。
   - recommendation: 使用 workspace lock、snapshot revalidation、transaction journal、rollback 與可重入 recovery。
   - reviewer: quality

9. **修改了 code fence 內的偽 heading，而非權威 outer requirement**
   - confidence: 99
   - layer: specification identity
   - location: `specs/cash-skill-workflows/spec.md`
   - summary: `cash-apply 任務迴圈的阻塞分類` 是 guidance code fence 內容，不是 master requirement identity。
   - recommendation: 移除錯誤 delta，改為完整 `MODIFIED`「Cash 指引提供無向量模型替代流程」requirement。
   - reviewer: adherence

### Warning

10. **archive provenance 與 `@trace` 契約遺失**
    - confidence: 93
    - layer: provenance
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: 替代流程未保留由 change、proposal 與 tasks 推導 archive trace 的既有行為。
    - recommendation: 規範 deterministic trace 來源、日期、code 與 tests 欄位。
    - reviewer: adherence

11. **接受 `spec_dir` 設定但實作固定 `openspec/`，契約互相矛盾**
    - confidence: 96
    - layer: configuration
    - location: `design.md`, `specs/cash-cli/spec.md`
    - summary: 原設計一方面聲稱支援 `.spectra.yaml` 的 `spec_dir`，另一方面所有路徑都固定為 `openspec/`。
    - recommendation: 新設定不支援 `spec_dir`；legacy 非預設值需 fail closed 並要求人工遷移。
    - reviewer: quality

12. **lexical search 讀取路徑缺少 symlink containment**
    - confidence: 96
    - layer: filesystem boundary
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: 僅限制搜尋起點不足以防止樹內 symlink 把讀取導向 workspace 外。
    - recommendation: 所有 artifact reads 採 no-follow traversal，並驗證 resolved target 仍位於 workspace。
    - reviewer: quality

## Rating

- Critical: 9
- Warning: 3
- non-blocking triaged: 0
- critical_gap: true
- round_type: full
- rationale: 第一輪發現 runtime 相容性、規格 identity、狀態遷移、installer safety 與多檔交易等阻塞問題，因此不可直接通過。

## Fix Actions

- 在 `proposal.md` 補齊 runtime、設定、digest manifest、測試與 24 個標準 Spectra skill directories 的影響面。
- 在 `design.md` 加入 Git root bootstrap、完整 command consumer fields、Cash-owned touched-state、sync manifest、trace、固定 artifact root、read containment、workspace lock、journal、rollback 與 recovery。
- 在 `specs/cash-cli/spec.md` 補齊 CLI、設定、state、lifecycle、search、installer、guidance、filesystem boundary 與 live/history namespace 的可驗收 requirements。
- 在 `specs/cash-skill-workflows/spec.md` 精確遷移或移除衝突的 master requirements，並改寫真正的 outer guidance requirement。
- 在 `tasks.md` 為上述契約加入明確實作與正負向驗證工作。
- Post-fix mechanical self-check：scenario comments 成對、所有 `MODIFIED`／`REMOVED` title 均能對應 master identity。
- Post-fix validation：`spectra validate replace-spectra-cli-with-cash-cli` 通過；`spectra analyze replace-spectra-cli-with-cash-cli` 的 Coverage、Consistency、Gaps 無阻塞結果，僅剩非阻塞寫作品質建議。
- fixed_files: 5

## Decision

next_round
