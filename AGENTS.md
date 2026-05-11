<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `$spectra-*` skills when:

- A discussion needs structure before coding → `$spectra-discuss`
- User wants to plan, propose, or design a change → `$spectra-propose`
- Tasks are ready to implement → `$spectra-apply`
- There's an in-progress change to continue → `$spectra-ingest`
- User asks about specs or how something works → `$spectra-ask`
- Implementation is done → `$spectra-archive`
- Commit only files related to a specific change → `$spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `$spectra-apply` and `$spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

<!-- PROJECT-SDD:START -->

# Project SDD Overlay

Prefer `$sdd-agentflow` for non-trivial feature work before going directly to `$spectra-propose` or `$spectra-apply`. It layers Discuss, Explore, Prototype, Usage/API Contract, and Review/Rating/Fix gates over Spectra's generated workflow.

Use `$sdd-spectra-refresh` after `spectra update --force` or a Spectra upgrade to verify project-owned `sdd-*` skills and `openspec/config.yaml` rules still exist.

Do not put project-specific Agentflow-SDD rules inside generated `spectra-*` skills. Keep custom behavior in project-owned `sdd-*` skills and outside the `SPECTRA:START` / `SPECTRA:END` block.

<!-- PROJECT-SDD:END -->
