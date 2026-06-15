# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

- **severity**: Critical / **confidence**: 100 / **location**: `scripts/spectra-plus/template/apply-notes-block.md`（line ~53，會被產生進兩個 apply-plus `SKILL.md`）/ **reviewer**: B
  - **summary**: 第二段來源 template 仍含 rater 引用（「The rater (Section 10) does not read this file directly...」），原計畫未列入，會使 apply-plus 產出殘留 `rater` 並使 acceptance 的 grep 失敗。
  - **recommendation**: 將 `apply-notes-block.md` 納入 proposal Impact、design Implementation Contract 與 tasks，並改寫該句。
- **severity**: Critical / **confidence**: 100 / **location**: master spec `Requirement: Confidence-scored findings and filter` / **reviewer**: A+B
  - **summary**: 該 requirement 仍寫「before passing findings to **the rater**」與 scenario「the rater does not see it」，delta 未修改，archive 後 master spec 自相矛盾。
  - **recommendation**: 在 delta 加入此 requirement 的 MODIFIED，改為「before deriving the round decision」與「it does not contribute to the round decision」。
- **severity**: Critical / **confidence**: 100 / **location**: master spec `Requirement: Sub-agent failure handling` / **reviewer**: A+B
  - **summary**: scenario「a reviewer or **the rater** sub-agent fails」殘留 rater，delta 未修改。
  - **recommendation**: 在 delta 加入此 requirement 的 MODIFIED，scenario 改為僅 reviewer。

### Warning

- **severity**: Warning / **confidence**: 90 / **location**: proposal `## What Changes` / `## Impact`、design Implementation Contract、tasks / **reviewer**: A
  - **summary**: 四個 artifact 一致地低估 scope（只提「描述 rater/quality_score 的 requirements」卻排除上述兩個 requirement 與第二來源 template），為三個 Critical 的共同根因。
  - **recommendation**: 擴充 Impact / Contract / tasks 至涵蓋兩個額外 requirement 與 `apply-notes-block.md`。
- **severity**: Warning / **confidence**: 85 / **location**: `scripts/spectra-plus/tests/generator-checks.fish` + tasks 1.1 / **reviewer**: B
  - **summary**: 測試應對全部四個產出檔同時斷言「不含 rater/quality_score」與「含機械規則文字」，否則 template 變更未傳播時會假綠燈。
  - **recommendation**: 以迴圈套用四檔斷言，比照既有 reviewer 斷言寫法。
- **severity**: Warning / **confidence**: 80 / **location**: design Decision 1 / Risks / **reviewer**: B
  - **summary**: 移除 rater 後，Suggestion-only 的一輪會立即 `passed`（舊規則 rater 仍可給低分擋下），屬未記錄的行為變更。
  - **recommendation**: 於 design Risks 明列此行為變更並確認為刻意取捨。

### Suggestion

- **severity**: Suggestion / **confidence**: 75 / **location**: template `Round file language` verbatim 清單 / **reviewer**: B
  - **summary**: 「keep verbatim」清單仍列 `quality_score (number 0–10)`，與 `## Rating` 移除 `quality_score` 需同步。（tasks 2.2 已涵蓋）
  - **recommendation**: 同一次編輯一併移除語言規則中的 `quality_score` 條目。
- **severity**: Suggestion / **confidence**: 70 / **location**: design Acceptance criteria / **reviewer**: A
  - **summary**: 擴充後「四個 requirement」計數過時，應為六個。
  - **recommendation**: 更新計數。

## Rating

- `quality_score`: 2
- `critical_gap`: true
- rationale: 三個 confidence-100 的 Critical 顯示變更不完整且自相矛盾——遺漏第二來源 template `apply-notes-block.md`，且兩個 master-spec requirement（`Confidence-scored findings and filter`、`Sub-agent failure handling`）仍保留 rater 引用而 delta 未修改，archive 後 master spec 將不一致。佐證的 Warning 指出 scope 低估、測試覆蓋過窄、以及一項未記錄的行為變更（Suggestion-only 輪次立即 pass）。存在 critical_gap，無法達到 pass 門檻。

## Fix Actions

- `proposal.md`：`## What Changes` 補上 `apply-notes-block.md` 與六個 master-spec requirement 的明列；`## Impact` 的 Modified 加入 `scripts/spectra-plus/template/apply-notes-block.md`。
- `specs/spectra-plus-skills/spec.md`：新增兩個 MODIFIED requirement——`Confidence-scored findings and filter`（rater→round decision）與 `Sub-agent failure handling`（scenario 移除 rater）。
- `design.md`：Implementation Contract 加入 `apply-notes-block.md` 與六個 requirement；Acceptance 由「四個」改「六個」並要求測試對四檔斷言；新增兩條 Risks（Suggestion-only 立即 pass、第二來源 template 遺漏風險）。
- `tasks.md`：1.1 改為對四個產出檔迴圈斷言（不含 rater/quality_score + 含機械規則）；新增 2.3 編輯 `apply-notes-block.md`（原 2.3 順延為 2.4）；4.1 grep 範圍擴及兩個 template。

## Decision

next_round
