# 03 — Prototype 審查（r1）：auto-restore-commit-guard-source

- 審查角色：獨立審查者（Agentflow step 3 / Prototype gate）
- 審查對象（target）：`agentflow/changes/auto-restore-commit-guard-source/agentflow/03-prototype.md`
- 審查輸入（inputs reviewed）：
  - `agentflow/changes/auto-restore-commit-guard-source/agentflow/03-prototype.md`（跳過決策）
  - `agentflow/changes/auto-restore-commit-guard-source/agentflow/02-explore.md`（explore 輸出，R1–R15）
  - `install-spectra-plus.fish`（交叉驗證程式碼宣稱：`:88` `ensure_commit_guard`、`:99` `validate_commit_guard "$source_path"`、全域 `dry_run` 旗標）
- 審查問題：跳過 throwaway spike 的決策是否成立？

## 核心判斷

**跳過決策成立（justified）。** 本變更不存在「只有拋棄式實驗才能解開」的技術可行性未知。所有不確定性都落在「控制流次序、邊界判斷、dry-run 語意、測試 fixture」層面，這些是 spec + 測試可完全覆蓋的決策性問題，而非「先寫程式才知道行不行」的實驗性問題。

## 對抗性檢驗（adversarial pass）

逐一試圖找出「值得 spike 的隱藏技術未知」，結論為皆不成立：

1. **git 機制可行性**：`git show HEAD:<relpath>`、`git restore --source=HEAD -- <relpath>` 為成熟、確定性、文件化指令。其行為（含 detached HEAD、worktree-only 語意）已知，不需實驗。
2. **端到端 baseline 已存在**：本 session 已手動 `git restore` 兩個 source 檔，使 `--repair-all` 由 `failed` 轉為 `already current`，等同人工跑過一次「spike」並成功。自動化只是把此手動步驟條件化 + 安全化——這正是 spike 的目的，且已達成。
3. **最棘手的 git 邊界（R12 index vs working-tree、R13 toplevel-relative relpath、R7 detached HEAD）已在 explore 被點名且給出處置方向**，並非被跳過決策「忽略」的盲點；它們是 spec 待固化項，不是技術未知。
4. **程式碼宣稱經交叉驗證屬實**：`ensure_commit_guard`（:88）、hook 點 `validate_commit_guard "$source_path"`（:99）、`dry_run` 全域旗標皆與 explore/prototype 文件一致。決策建立在正確的程式碼事實上，非臆測。

未發現任何需要 spike 才能消解的真實技術風險。

## Rubric checklist

| 項目 | 結果 | 說明 |
|------|------|------|
| 是否存在「僅 spike 可解」的技術/可行性未知 | 通過（無） | 機制標準確定；唯一可疑點（index 語意、relpath 推導）為設計決策，非可行性未知 |
| prototype learning 已捕捉或刻意跳過且有清楚理由 | 通過 | 03-prototype.md 三點理由具體、可檢驗；非空泛「不需要」 |
| 隱藏風險未被跳過決策掩蓋 | 通過 | R12/R13/R7 等 git 邊界已顯式列出並導向 spec/測試 |
| 跳過 vs 做 spike 的風險權衡有記錄 | 通過 | 03 文件「風險與替代」段落明列風險等級（低）與替代路徑（直接進 spec） |
| 與 explore 銜接、前置設計帶入 spec | 通過 | hook 點、安全 invariant、觀測需求均轉交 spec |
| 決策可追溯到程式碼事實 | 通過 | :88 / :99 / dry_run 經本次審查實證 |

## Findings（含 severity）

- **[info] 跳過理由品質高**：三點論證（機制確定性、不確定性性質、實證 baseline）結構清楚且可驗證，超出一般「跳過」樣板。
- **[low] R12（index 未被 restore）僅在 explore 補充表出現，03-prototype.md 未複述**：03 文件的「安全 invariant」段落聚焦 source 驗證/單檔/dry-run，未顯式帶入「working-tree 語意足夠、index 修復為 non-goal」這一關鍵範圍邊界。此為文件完整性的輕微缺口，不影響跳過決策正確性，但 spec 階段必須承接 R12，否則可能出現「working tree 修好但已 staged 的破損版仍會被 commit」的盲區。建議在 03 結尾「從 explore 帶入 spec 的前置」補一行明列 R12/R14 範圍邊界，使 prototype→spec 交接零遺漏。
- **[low] R15 簡化建議（合併 R3/R4 為單一「HEAD blob 取得且有效」判斷）為 advisory，03 文件未提及**：不屬 prototype gate 必要項，spec/dev 處理即可，僅記錄以免遺失。

以上皆非 critical，且不改變「跳過成立」的結論。

## Fixes required（建議，非阻擋）

- （nit）於 `03-prototype.md` 的「從 explore 帶入 spec 的前置」段補列 R12（working-tree 語意足夠、index 修復為 non-goal）與 R14（僅還原 source、不改 target patch fail-loud）兩條範圍邊界，使交接完整。屬文件潤飾，spec 階段亦可直接從 explore 承接，不阻擋進度。

## Blockers / critical gaps

- 無。不存在 critical gap，無阻擋。

## 決策（decision）

**fix-and-rerun（建議性，非阻擋級）。**

理由：跳過決策本身完全成立、技術判斷正確、與程式碼一致，實質上達到 pass 水準。但 Agentflow pass gate 要求 `quality_score > 9 且無 critical gap`；目前存在兩個 low 級文件完整性 finding（R12/R14 未在 03 文件複述），使分數落在 9，未跨過 >9 門檻。這些是純文件潤飾，無 critical gap。

- quality_score：**9 / 10**
- 若採納上述 nit（補列 R12/R14 範圍邊界於 03 文件），可立即升至 9.5+ 並 pass。

## Next action

1. 於 `03-prototype.md` 補列 R12/R14 範圍邊界（一兩行即可）。
2. 以新的獨立 sub-agent 重跑 r2 確認 >9 後 pass。
3. 若 orchestrator 判定 low-級 nit 可由 spec 階段直接承接 explore 的 R12/R14（兩文件已完整記載），則可視為實質 pass、直接進 `/sdd-spec`，無需技術上的 spike。
