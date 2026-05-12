# Agentflow-SDD 流程

本專案使用自包含的 9-step Agentflow-SDD 流程。Agentflow 自行管理 artifact 格式、目錄結構、workflow 引擎和生命週期，不依賴外部 CLI。

## 核心原則

- 非 trivial work 必須從 `$sdd-*` / `/sdd-*` Agentflow skills 進入。
- 每個 Agentflow step 都有自己的 Review -> Rating -> Fix quality loop。
- 通過條件是 `quality_score > 9/10`，也就是必須高於 9 分。
- 每一輪 review/rating/fix 都必須輸出獨立文件。
- 每一輪 review/rating 都必須委派給獨立的 sub-agent，不得在主 agent context 中進行。

## 9-Step Agentflow

| # | Agentflow step | Codex skill | Claude skill | 產出 |
| --- | --- | --- | --- | --- |
| 1 | Discuss | `$sdd-discuss` | `/sdd-discuss` | `01-discuss.md` |
| 2 | Explore | `$sdd-explore` | `/sdd-explore` | `02-explore.md` |
| 3 | Prototype | `$sdd-prototype` | `/sdd-prototype` | `03-prototype.md` |
| 4 | Spec | `$sdd-spec` | `/sdd-spec` | `proposal.md`, `design.md`, `spec.md`, `04-spec.md` |
| 5 | Usage | `$sdd-usage` | `/sdd-usage` | 更新 `design.md`, `spec.md`, `05-usage.md` |
| 6 | Tkt / Ticket | `$sdd-ticket` | `/sdd-ticket` | `tasks.md`, `06-ticket.md` |
| 7 | Dev | `$sdd-dev` | `/sdd-dev` | 實作 + 標記 tasks 完成, `07-dev.md` |
| 8 | Review | `$sdd-review` | `/sdd-review` | 一致性/安全/drift 檢查, `08-review.md` |
| 9 | Wrap | `$sdd-wrap` | `/sdd-wrap` | 歸檔 + master spec sync, `09-wrap.md` |

`$sdd-agentflow` / `/sdd-agentflow` 是完整端到端入口，會依序協調上面 9 個 step。若只要接續其中一步，就使用對應的 `$sdd-*` wrapper。

## Quality Loop

每個 step 都要跑：

```text
Review -> Rating -> Fix
```

最多 3 輪。每一輪都要輸出 review round 文件。若第 3 輪仍 `quality_score <= 9/10` 或存在 critical gap，就停止並回報 blocker，不得硬過。

### Sub-Agent 隔離規則

Review 和 Rating **必須**委派給獨立的 sub-agent 執行，不得在主 agent context 中進行。

- 每一輪 review/rating 都要開一個**全新的** sub-agent。不得透過 SendMessage 重用前一輪的 sub-agent。
- Sub-agent 不帶任何實作階段的 context，確保 reviewer 以獨立視角審查，避免確認偏誤。
- Sub-agent prompt 必須包含：step 名稱、change 名稱、要 review 的檔案/artifact 清單、rubric 標準、目標 review round 文件路徑。
- Sub-agent 負責：讀取 artifact、根據 rubric 評分、撰寫 review round 文件、回傳 `quality_score` 與 decision。
- 主 agent 只讀取 sub-agent 回傳的結果，若 decision 為 `fix-and-rerun`，主 agent 修正後再開**另一個新的** sub-agent 進行下一輪。

### Critical Gap

Critical gap 包含：

- 安全或隱私要求缺失
- 需求互相矛盾
- user-visible 行為沒有驗證方式
- task 必須靠猜才能實作
- artifact、step 文件、review round 文件互相不一致
- 缺少必要 review round 文件

## 目錄結構

```text
agentflow/
  config.yaml                          # Agentflow 設定
  changes/
    <change-name>/
      proposal.md                      # Step 4 建立
      design.md                        # Step 4 建立，Step 5 更新
      spec.md                          # Step 4 建立，Step 5 更新
      tasks.md                         # Step 6 建立，Step 7 更新
      status.yaml                      # 輕量狀態檔
      agentflow/
        01-discuss.md ~ 09-wrap.md
        reviews/
          01-discuss-r<round>.md ...
    archive/
      YYYY-MM-DD-<change-name>/        # sdd-wrap 歸檔目的地
openspec/
  specs/                               # 保留 — master capability specs
```

## Step 文件輸出契約

對於 active change `<change>`，step 文件放在：

```text
agentflow/changes/<change>/agentflow/
```

固定檔名：

| Step | 文件 |
| --- | --- |
| Discuss | `01-discuss.md` |
| Explore | `02-explore.md` |
| Prototype | `03-prototype.md` |
| Spec | `04-spec.md` |
| Usage | `05-usage.md` |
| Ticket | `06-ticket.md` |
| Dev | `07-dev.md` |
| Review | `08-review.md` |
| Wrap | `09-wrap.md` |

## Review Round 文件輸出契約

每一輪 review/rating/fix 都要輸出獨立文件。Step 文件只負責摘要與連結，不能取代 review round 文件。

Review round 文件放在：

```text
agentflow/changes/<change>/agentflow/reviews/
```

固定檔名：

| Review 範圍 | 文件 |
| --- | --- |
| Discuss | `01-discuss-r<round>.md` |
| Explore | `02-explore-r<round>.md` |
| Prototype | `03-prototype-r<round>.md` |
| Spec | `04-spec-r<round>.md` |
| Usage | `05-usage-r<round>.md` |
| Ticket | `06-ticket-r<round>.md` |
| Dev task | `07-dev-task-<task-id>-r<round>.md` |
| Review | `08-review-r<round>.md` |
| Wrap | `09-wrap-r<round>.md` |

每個 review round 文件至少記錄：

- target step、task、或 artifact set
- input files / artifacts reviewed
- rubric table 或 checklist
- `quality_score`，1 到 10 分
- findings
- fixes required
- fixes applied，或為什麼不需要修正
- remaining blockers 或 critical gaps
- decision：`pass`、`fix-and-rerun`、或 `blocked`
- next action

如果 change 還沒建立，先在回覆中保留 step output 與 review round output；一旦 `$sdd-spec` / `/sdd-spec` 建立 change，就補進 `agentflow/` 與 `agentflow/reviews/`。

## Artifact 格式

| Artifact | 建立者 | 更新者 | 語言 |
| --- | --- | --- | --- |
| `proposal.md` | Step 4 (Spec) | — | 繁體中文 |
| `design.md` | Step 4 (Spec) | Step 5 (Usage) | 繁體中文 |
| `spec.md` | Step 4 (Spec) | Step 5 (Usage) | 英文（SHALL/MUST） |
| `tasks.md` | Step 6 (Ticket) | Step 7 (Dev) | 繁體中文 |
| `status.yaml` | Step 4 (Spec) | 各 step 更新 | YAML |

## 安裝到其他專案

本資料夾提供 fish installer：

```fish
./install-agentflow-sdd.fish --target /path/to/project
```

常用選項：

- `--both`：同時安裝 `.agents/skills` 與 `.claude/skills`，預設值。
- `--codex-only`：只安裝 Codex skill。
- `--claude-only`：只安裝 Claude skill。
- `--docs`：額外複製 `SDD-FLOW.md`。
- `--dry-run`：只顯示會複製什麼，不改檔案。

Installer 不會自動覆蓋目標專案的 `AGENTS.md`、`CLAUDE.md`、`agentflow/config.yaml`。這些通常有專案自己的設定，應該由工程師檢查後手動合併。

## Agentflow 完整性檢查

使用 `$sdd-refresh` / `/sdd-refresh` 驗證：

- 11 個必要的 `sdd-*` skills 都存在（`.agents/skills/` 和 `.claude/skills/`）
- `agentflow/config.yaml` 存在且格式正確
- `AGENTS.md` / `CLAUDE.md` 有 `PROJECT-SDD` overlay block
- `install-agentflow-sdd.fish` 存在且通過 `fish -n` 語法檢查
- Active change 的 step 文件和 review round 文件存在
- `sdd-*` skills 中沒有殘留的 Spectra 引用

## 什麼不要做

- 不要繞過 `sdd-*` skills 直接操作 `agentflow/changes/` 目錄。
- 不要在 Agentflow step 未通過時直接實作。
- 不要讓 prototype code 默默變成正式 implementation。
- 不要把 review/rating/fix 只寫成 step 文件的一個摘要；每一輪都要有獨立 review round 文件。
- 不要在主 agent context 中做 review 或 rating；必須委派給獨立 sub-agent。
