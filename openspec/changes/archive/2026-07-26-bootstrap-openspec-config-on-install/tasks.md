## 1. 測試先行（Red）

- [x] 1.1 在 `scripts/cash-skills/tests/test_installer_runtime.py` 新增只做 `git init`、不建立 `openspec/` 的 bare target helper，並新增 case：對該 target 執行 installer 後回報 `Result: update`、`openspec/config.yaml` 為 single-link regular file、mode 為 `0644`、bytes 逐 byte 等於 `cash_cli.installer.OPENSPEC_CONFIG_BASELINE`、可被 `cash_cli.config.parse_openspec_config` 解析、`openspec/` 的 entries 恰為 `{"config.yaml"}`，且 `.cash-skills/receipt.tsv` 不含 `openspec/config.yaml`。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 中該 case 失敗，失敗訊息含 `cannot open regular file openspec/config.yaml`。
- [x] 1.2 於同檔新增冪等與保留 case：對同一 bare target 第二次安裝回報 `Result: current`，且 `openspec/config.yaml` 的 bytes 與 `st_ino` 不變；另一 case 使既有 target 帶有 schema-valid 但與 `OPENSPEC_CONFIG_BASELINE` 不同的 `openspec/config.yaml`，安裝後該檔逐 byte 不變。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 中冪等 case 紅燈、保留 case 綠燈。
- [x] 1.3 於同檔新增 fail-closed 與 dry-run case：`openspec/config.yaml` 分別為 symlink、hard link 與 FIFO 時，installer 以 exit 1 失敗、不建立或替換該檔，加 `--force` 結果相同，且每個 case 的 `subprocess` 呼叫都帶 `timeout=`，使 FIFO 阻塞會以 `TimeoutExpired` 呈現為測試失敗而非掛住；既有 config 為 schema-invalid 時 exit 1、stderr 含 `invalid target openspec/config.yaml`，且加 `--force` 仍 exit 1；bare target 執行 `--dry-run` 時 exit 0、stdout 含 `Result: update`、不建立 `openspec/` 目錄。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 中 FIFO case 與 dry-run case 紅燈，其餘 case 綠燈。
- [x] 1.4 於同檔新增 `--self` 回歸護欄 case：以既有 source fixture 建立缺少 `openspec/config.yaml` 的 source repository，執行 `--self` 與 `--self --dry-run` 皆 exit 1 且不建立該檔、不寫入 receipt。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 中該 case 綠燈。
- [x] 1.5 於同檔新增 `--register` case：對缺 `openspec/config.yaml` 的 bare target 執行 `--register`，exit 0、該 target 被寫入 registry，且執行後 `openspec/config.yaml` 仍不存在；同一 target 的 `openspec/config.yaml` 為 symlink 時 `--register` 仍 exit 1 且 registry 不變；該檔為 schema-invalid 時 `--register` 亦 exit 1、stderr 含 `invalid target openspec/config.yaml` 且 registry 不變（此 case 專門擋住把 `return` 放得太早而讓 register 分支略過 schema 驗證的實作）。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 中登錄成功 case 紅燈，symlink 與 schema-invalid case 綠燈。
- [x] 1.6 於同檔新增 rollback case：對 bare target 以 `env={"TEST_CASH_INSTALL_TEST_HOOKS": "1", "TEST_CASH_INSTALL_FAIL_AFTER_PATH": ".gitignore"}` 注入 publication failure（沿用 `test_publication_failure_rolls_back_the_gitignore_operation` 的既有寫法），斷言 installer exit 1、stderr 含 `injected publication failure after .gitignore`（證明注入點確實被走到，而非在 preflight 就失敗）、`openspec/config.yaml` 不存在、`.cash-skills/receipt.tsv` 不存在，且 `openspec/` 目錄殘留不視為失敗。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 中該 case 紅燈，且紅燈原因為 stderr 斷言失敗（實作前的 stderr 為 `cannot open regular file openspec/config.yaml`）。

## 2. 實作（Green）

**順序要求與 `task done` 補標程序。** `.cash-skills/lib/cash_cli/installer.py` 是 receipt 的 runtime 記錄，launcher 在載入前逐檔比對其 digest。因此自 2.1 第一次寫入該檔起，**每一個 Cash 指令都會以 `receipt_invalid` 失敗**，訊息為 `runtime record drift: .cash-skills/lib/cash_cli/installer.py. Run ./install-cash-skills.fish --self from the project root`，直到 3.3 重建 receipt 為止。

受影響的是 **2.1、2.2、3.1、3.2** 四個 task——包含只改 `CASH-SKILLS.md` 的 3.2，因為失效的是 CLI 本身而非被改的檔案。第 1 節不受影響：`scripts/cash-skills/tests/test_installer_runtime.py` 不在 receipt 的受管集合內。

據此：

- 2.1 至 3.2 **不得平行**，且期間 MUST NOT 執行任何 Cash 指令——包含 `"$cash_cli" task done` 與 `"$cash_cli" touched record`。實作者 MUST NOT 在 receipt 失效期間嘗試呼叫 CLI 並把失敗誤判為實作缺陷。
- 這四個 task 的 `task done` MUST 延後到 3.3 完成之後一次補標，補標順序依 task 編號。
- 各 task 的驗證目標在此期間仍可執行，因為它們用的是 `python3` 與 `rg` 而非 Cash CLI；唯一例外是 3.3 自身的 `.cash-skills/bin/cash validate --all`，它本來就在重建之後。

- [x] 2.1 在 `.cash-skills/lib/cash_cli/installer.py` 新增模組常數 `OPENSPEC_CONFIG_PATH = "openspec/config.yaml"`（並以它取代該檔既有三處路徑字面值）與 `OPENSPEC_CONFIG_BASELINE`（LF 結尾 UTF-8、首行 `schema: spec-driven`、其餘只有 blank line 與 full-line `#` 註解）；新增 `ensure_regular_shape(root, relative)`，以 `ensure_contained` 解析後 `os.lstat`，`FileNotFoundError` 直接返回、非 `stat.S_ISREG` 以 `InstallerError(f"unsafe regular file identity: {relative}")` fail closed，並讓既有 `ensure_regular_gitignore` 委派給它；`validate_target_prerequisites` 改為接受 keyword-only `allow_missing_config: bool = False`、回傳型別維持 `None`，在 Git top-level 檢查之後先呼叫 `ensure_regular_shape(target, OPENSPEC_CONFIG_PATH)`，缺檔且允許時直接 `return`，其餘維持既有讀取、驗證與 `invalid target openspec/config.yaml: {error}` 訊息；新增 `openspec_config_plan(snapshot: Snapshot) -> bytes | None`，既有檔案回傳 `None`，缺檔時先以 `parse_openspec_config` 驗證 baseline 再回傳其 bytes，baseline 無效則以 `InstallerError` fail closed。驗證：`PYTHONPATH=.cash-skills/lib python3 -c 'from cash_cli.installer import OPENSPEC_CONFIG_BASELINE, OPENSPEC_CONFIG_PATH, Snapshot, openspec_config_plan; from cash_cli.config import parse_openspec_config; p = parse_openspec_config(OPENSPEC_CONFIG_BASELINE.decode("utf-8"), path=OPENSPEC_CONFIG_PATH); assert p["context"] == "" and p["rules"] == {}; assert OPENSPEC_CONFIG_BASELINE.endswith(b"\n"); assert openspec_config_plan(Snapshot(True)) is None; assert openspec_config_plan(Snapshot(False)) == OPENSPEC_CONFIG_BASELINE'` 成功。
- [x] 2.2 於同檔接線：`install_target` 的 preflight 與取得 stable lock 之後的兩處 `validate_target_prerequisites(target)`、以及 `run` 中 `--register` 分支的 `validate_target_prerequisites(Path(project))`，三處都改傳 `allow_missing_config=True`；於 `.cash.yaml` 的 `transaction.add` 之後、guidance 迴圈之前，以 `openspec_config_plan(dict(target_inputs)[OPENSPEC_CONFIG_PATH])` 取得 plan，非 `None` 時 `transaction.add(OPENSPEC_CONFIG_PATH, planned, 0o644)`，並保持 `.gitignore` 為 receipt 之前的最後一個 operation；`bootstrap_source` 的兩處呼叫不加參數。驗證：`python3 scripts/cash-skills/tests/test_installer_runtime.py` 全數綠燈。

## 3. 版本、文件與整體驗證

- [x] 3.1 提升 `cash-skills.version`：讀取工作區當下值與 `git show HEAD:cash-skills.version`，寫入嚴格大於兩者的下一個版本並維持單行 LF 結尾。不得沿用文件中的示例值 `2.6.0`，必須依執行當下的實際值決定。驗證：`python3 scripts/cash-skills/tests/test_bundle_version_history.py` 通過。
- [x] 3.2 [P] 在 `CASH-SKILLS.md` 的「Bundle 版本與單一 installer 入口」段落補一段說明：target 缺 `openspec/config.yaml` 時 installer 於同一 transaction 內建立預設檔（因此該 target 分類為 `update` 而非 `current`），既有檔案逐 byte 保留，unsafe shape 與 invalid schema 仍 fail closed 且 `--force` 不繞過，`--register` 接受缺檔但不建立該檔。驗證：`rg -F "openspec/config.yaml" CASH-SKILLS.md` 有命中。
- [x] 3.3 於 project root 執行 `./install-cash-skills.fish --self` 重建 receipt。**這是第 2 節前言所述 receipt 失效區間的終點**：本 task 完成後 Cash CLI 恢復可用，MUST 立即依編號順序補標 2.1、2.2、3.1、3.2 四個 task 的 `task done`，再繼續 3.4。驗證：該指令回報 `Result: bootstrap` 或 `Result: current`；`.cash-skills/bin/cash validate --all` 通過；補標後 `"$cash_cli" instructions apply --change bootstrap-openspec-config-on-install --json` 的 `progress` 顯示 2.1 至 3.3 皆為完成。
- [x] 3.4 端到端驗證：`fish scripts/cash-skills/tests/skill-checks.fish installer-runtime` 通過；並在一個新建、只做過 `git init` 的暫存目錄執行 `./install-cash-skills.fish --target <tmp>`，安裝後於該目錄執行 `.cash-skills/bin/cash list --json` 成功回傳 JSON。

## 4. Requirement 追溯

本節不含實作動作，用途是讓 spec requirement 有可稽核的落點。

| Spec requirement | 實作任務 |
| --- | --- |
| `Bundle 安裝與 runtime receipt` | 1.1–1.6（Red：bare target、冪等與保留、fail-closed 與 dry-run、`--self` 護欄、`--register`、rollback）、2.1–2.2（Green：常數、`ensure_regular_shape`、`openspec_config_plan` 與 transaction 接線）、3.1（版本遞增）、3.3（receipt 重建）、3.4（端到端） |
