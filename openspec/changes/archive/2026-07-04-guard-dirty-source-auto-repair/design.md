## Context

`repair-all.fish` 是 LaunchAgent 的 entrypoint，會從 `Agentflow-SDD` checkout 呼叫 `install-spectra-plus.fish --repair-all`。目前這條路徑直接使用 working tree 的 generator、rules、template、以及 source skill files；因此 source checkout 若正在修改到一半，background repair 可能把未完成內容寫入所有 registry target。

這個風險和手動 `--target` 不同：手動操作通常是開發者明確觸發，可以接受用 WIP 測試單一 target；LaunchAgent 則是背景自動執行，應預設保守。

## Goals / Non-Goals

**Goals:**

- background `--repair-all` 在 source-sensitive paths dirty 時不得修改任何 registered target。
- `--repair-all --dry-run` 必須同樣揭露 dirty-source skip，而不是列出 target repair actions。
- 手動 `--target <project>` 仍可使用 dirty source checkout，保留開發測試流程。
- 測試必須證明 dirty source 時 registered target outputs 與 commit guard 不變。

**Non-Goals:**

- 不移除 registry 中的 `Agentflow-SDD` target。
- 不要求整個 repo 完全 clean；`openspec/changes/**`、`openspec/signals/**`、unrelated docs 等 source-sensitive path set 以外的 dirty files 不阻擋 auto repair。所有 `.agents/skills/spectra-*/**` / `.claude/skills/spectra-*/**` WIP 則刻意視為 source-sensitive。
- 不保證語法已壞到無法啟動的 `scripts/spectra-plus/repair-all.fish` 仍能自我保護；entrypoint 必須至少可被 `fish` parse 並執行到 installer handoff。
- 不加入新的背景服務或外部 dependency。
- 不修改已棄用的 `install-agentflow-sdd.fish`。

## Decisions

### Guard repair-all with source-sensitive dirty detection

`repair-all` 會在 dependency preflight、lock/throttle、讀 registry、驗證 local plus metadata、auto-restore source guard、或修復任何 target 之前檢查 source checkout。source checkout 定義為包含 `install-spectra-plus.fish` 的 git work tree；所有 source-sensitive path matching 都以該 repo root 為基準。檢查範圍刻意涵蓋整個 Spectra skill layer，而不只涵蓋 generator 目前直接讀取的 `spectra-propose` / `spectra-apply` / `spectra-commit`：`install-spectra-plus.fish`、`scripts/spectra-plus/**`、`.agents/skills/spectra-*/**`、`.claude/skills/spectra-*/**`。這是保守 trade-off，因為 background repair 是跨專案自動擴散機制；任何 Spectra skill WIP 都代表 source skill layer 正在變動，應先由使用者 commit/stash/revert 或手動 `--target` 驗證，而不是讓 LaunchAgent 推到所有 registered targets。Path matching 必須使用目錄邊界，不得用 substring match；例如 `scripts/spectra-plus-notes.md` 不符合 `scripts/spectra-plus/**`。任何 `git status --porcelain` entry 只要 match source-sensitive path 就算 dirty，包含 staged added/copied/typechange/unmerged、staged-only changes、unstaged changes、deleted files、renamed files、以及 untracked files。`repair-all` 輸出 skip 訊息並以成功狀態結束，避免 LaunchAgent 重複報錯。

dirty-source guard 在 `--repair-all` 中優先於 local plus metadata validation、registry target processing、lock/throttle state、以及 `spectra-commit` guard source auto-restore。這代表 dirty 且 invalid 的 `scripts/spectra-plus/rules.yaml` 或 stripped dirty source `spectra-commit/SKILL.md` 都會被視為 WIP source，background repair 會 skip exit 0；只有 source-sensitive paths clean 時，既有 invalid metadata fail-loud 與 auto-restore 行為才會執行。

如果 `--repair-all` 無法判定 source-sensitive paths 是否 clean（例如不在 git work tree、沒有 `HEAD`、或 `git status --porcelain` 執行失敗），必須 fail-closed：輸出 source clean state unavailable 的 skip 訊息、exit 0、且不處理 targets。這比 fail-open 擴散未知 source 狀態更安全。

`scripts/spectra-plus/repair-all.fish` 不應在 dirty guard 前要求 `yq`。entrypoint 可以要求 `fish` 自身存在，但會影響 dirty-source decision 的 dependency preflight 應交給 installer 在 dirty guard 之後處理，避免 dirty source + missing `yq` 時先 exit 1。

因為 `scripts/spectra-plus/repair-all.fish` 本身也屬於 source-sensitive path，entrypoint 的職責應保持極薄：在可被 `fish` parse 的前提下，不做 target processing、registry read、lock/throttle state、或非必要 dependency preflight，直接 hand off 給 `install-spectra-plus.fish --repair-all`。這讓 parseable WIP entrypoint 仍可被 installer 的 dirty guard 攔住；broken-syntax entrypoint 是 non-goal，因為程序無法啟動到任何 guard。

替代方案是要求整個 git worktree clean；這會被 active Spectra change artifacts 或 unrelated docs 擋住，對日常 SDD 流程太吵。另一個替代方案是自動從 `HEAD` export source 再 repair，但這會讓開發者難以理解實際套用的是哪個版本，也會增加 shell 腳本複雜度。

### Keep manual single-target repair explicit and permissive

`install-spectra-plus.fish --target <project>` 不套用 dirty-source guard。這保留開發者手動驗證 WIP generator/rules/template 的能力；風險由明確操作承擔，不由 LaunchAgent 背景擴散。

替代方案是在所有 install path 都阻擋 dirty source；這會讓開發和 fixture 測試更不方便，且不是本次要解決的 background repair 問題。

### Make dry-run report the same guard decision

`--repair-all --dry-run` 也要先執行 dirty-source guard。若 source-sensitive paths dirty，dry-run 只輸出 skip 訊息，不列出 `+ repair target ...`，避免給出實際 repair 可以安全執行的錯誤訊號。

## Implementation Contract

- `install-spectra-plus.fish --repair-all` 在 source-sensitive paths dirty 時 MUST NOT read target current state as success, MUST NOT invoke `--target`, and MUST NOT modify any registered target file.
- `install-spectra-plus.fish --repair-all --dry-run` 在 source-sensitive paths dirty 時 MUST print a dirty-source skip message and MUST NOT print per-target repair commands.
- Dirty-source skip messages SHOULD include at least one offending source-sensitive path when that path is available.
- dirty-source skip MUST run before dependency preflight that is not needed to detect dirty source, before lock acquisition, before throttle state reads/writes, before registry target processing, before local plus metadata validation, and before `spectra-commit` guard source auto-restore in `--repair-all`.
- dirty-source skip MUST exit with status 0 for LaunchAgent compatibility, including when the dirty source-sensitive file is an invalid WIP `scripts/spectra-plus/rules.yaml`; missing dependencies or invalid local metadata still use the existing fail-loud behavior when source-sensitive paths are clean.
- `install-spectra-plus.fish --repair-all` MUST fail-closed with a skip message and exit 0 when it cannot confirm source-sensitive paths are clean.
- `scripts/spectra-plus/repair-all.fish` MUST NOT fail for missing `yq` before the installer has a chance to apply the dirty-source skip decision.
- `scripts/spectra-plus/repair-all.fish` MUST remain a thin handoff wrapper before invoking the installer: it MUST NOT read registry targets, acquire repair locks, read or write throttle state, inspect target current state, or perform nonessential dependency preflight before calling `install-spectra-plus.fish --repair-all`.
- `install-spectra-plus.fish --target <project>` MUST NOT be blocked by the dirty-source guard.
- The source-sensitive path set MUST include `install-spectra-plus.fish`, `scripts/spectra-plus/**`, all files under matching `.agents/skills/spectra-*/` directories, and all files under matching `.claude/skills/spectra-*/` directories.
- Source-sensitive path matching MUST be evaluated relative to the git work tree that contains `install-spectra-plus.fish`, and MUST respect path segment boundaries rather than substring matches.
- The source-sensitive path set intentionally treats every `spectra-*` skill directory as protected, including skills not directly read by the current plus generator, so background repair never propagates while the local Spectra skill layer is mid-edit.
- Dirty detection MUST treat any `git status --porcelain` entry matching a source-sensitive path as dirty, including staged added/copied/typechange/unmerged files and staged-only changes.
- Dirty files outside the source-sensitive path set MUST NOT block `--repair-all`.
- Tests MUST isolate source checkout state with a clean temporary source fixture for normal repair-all cases; dirty-source cases MUST create intentional dirty state inside that fixture instead of relying on the developer's current working tree.
- Tests MUST cover dirty source skip for normal `--repair-all`, dirty source skip for `--repair-all --dry-run`, dirty invalid `rules.yaml` precedence, dirty source guard precedence over auto-restore, source clean state unavailable skip, parseable dirty `repair-all.fish` handoff behavior, missing `yq` entrypoint ordering, lock/throttle precedence, staged-only and staged-added source-sensitive changes, deleted/renamed/copied/typechange/unmerged porcelain entries, manual `--target` allowed with dirty source, and unrelated dirty file not blocking `--repair-all`.

## Risks / Trade-offs

- [Risk] A legitimate urgent auto repair is skipped while source-sensitive files are dirty. → Mitigation: the skip message points at the dirty-source condition; the operator can commit/stash/revert WIP or run an explicit manual `--target` for a chosen project.
- [Risk] The broad `spectra-*` skill path set can skip auto repair for WIP that does not directly affect current plus output. → Mitigation: this is intentional; avoiding background propagation of any mid-edit Spectra skill layer is more important than immediate auto repair. Manual `--target` remains available for explicit WIP testing.
- [Risk] A non-git source checkout such as a tarball/export cannot prove source cleanliness and will permanently skip automatic repair. → Mitigation: the skip message identifies source clean state unavailable; operators should install from a git checkout or run an explicit manual `--target` when they accept the source state.
- [Risk] Path filtering misses a file that affects generated output. → Mitigation: tests should include a small matrix covering `install-spectra-plus.fish`, `scripts/spectra-plus/rules.yaml` or template files, `.agents/skills/spectra-commit/SKILL.md`, `.claude/skills/spectra-commit/SKILL.md`, at least one non-output Spectra skill such as `spectra-ask` or `spectra-audit`, and at least one nested untracked file; future output-affecting paths must be added to the source-sensitive set with tests.
- [Risk] LaunchAgent logs repeat skip messages while development is ongoing. → Mitigation: exit 0 keeps it non-fatal, and one skip per LaunchAgent interval is accepted for this change. Any separate dirty-skip log throttling would be a future behavior that must not reuse target repair lock/throttle state.
