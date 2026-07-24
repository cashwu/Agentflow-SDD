# demo Specification

## Purpose

demo capability.

## Requirements

### Requirement: Demo lifecycle

系統 SHALL 提供完整 lifecycle。

#### Scenario: Complete flow

- **WHEN** 執行 Cash lifecycle
- **THEN** change 被安全封存

<!-- @trace
source: demo
updated: @DATE@
code:
  - src/demo.py
tests:
  - scripts/cash-cli/tests/cli-checks.fish
-->
