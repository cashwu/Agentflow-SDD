<!-- cash-apply implementation notes | change: rightsize-cash-apply-tdd-discipline | initialized: 2026-07-26 23:13 | no entries below means no deviations or open questions were recorded -->

## 2026-07-26 23:15 — 使用專案既有 Python import path 執行 resource contract test
- 類別：deviation
- 任務：1.1
- 內容：原任務指定直接執行 `python3 scripts/cash-cli/tests/test_graph_instructions.py`；實際以 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py` 執行相同 test module，並確認 14 個失敗皆源自現行 `DISCIPLINES["tdd"]` 缺少新 contract markers。
- 原因：未設定 `PYTHONPATH` 時 Python 在載入測試前即以 `ModuleNotFoundError: cash_cli` 結束；沿用 repository 既有 `cli-checks.fish` 的 import path 只替換啟動機制，不改變測試內容、失敗模式或驗收標準。

## 2026-07-26 23:19 — 以既有 Python import path 執行最終 resource contract
- 類別：deviation
- 任務：3.1
- 內容：原任務指定直接執行 `python3 scripts/cash-cli/tests/test_graph_instructions.py`；最終驗證改以 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py` 執行相同 test module，11 個 tests 全部通過。
- 原因：與 task 1.1 相同，repository-owned `cash_cli` 不在未設定 `PYTHONPATH` 的預設 import path；此調整只沿用既有 suite 的啟動機制，未改變受測程式、assertions 或驗收結果。
