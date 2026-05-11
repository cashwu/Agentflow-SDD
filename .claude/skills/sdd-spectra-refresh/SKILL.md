---
name: sdd-spectra-refresh
description: "Refresh and verify this project's custom SDD overlay after Spectra updates or regenerated spectra-* skills. Use after running spectra update, upgrading Spectra, or suspecting generated skill drift."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.1"
  generatedBy: "project"
---

# SDD Spectra Refresh

Use this skill after Spectra is upgraded or instruction files are regenerated. Its job is to keep the project-owned Agentflow-SDD overlay intact while allowing generated `spectra-*` skills to update.

## Invariants

- Generated `spectra-*` skills may change after `spectra update --force`.
- Project-owned `sdd-*` skills must remain present in both `.agents/skills/` and `.claude/skills/`.
- `openspec/config.yaml` must preserve Agentflow-SDD context and artifact rules.
- `AGENTS.md` and `CLAUDE.md` should keep the project SDD overlay note outside the `SPECTRA:START` / `SPECTRA:END` generated block.
- Active Agentflow-SDD changes should keep supporting step documents under `openspec/changes/<change>/agentflow/`.

## Refresh Workflow

1. Inspect baseline:
   - `spectra --version`
   - `git status --short`
   - list `.agents/skills/*/SKILL.md` and `.claude/skills/*/SKILL.md`
2. If the user explicitly requested a Spectra refresh, run:
   - `spectra update --force`
3. Inspect the diff:
   - Generated areas: `AGENTS.md`, `CLAUDE.md`, `.agents/skills/spectra-*`, `.claude/skills/spectra-*`
   - Project-owned areas: `.agents/skills/sdd-*`, `.claude/skills/sdd-*`, `openspec/config.yaml`
4. Reapply project overlay if needed:
   - Restore missing `sdd-agentflow` and `sdd-spectra-refresh` skills.
   - Restore the project SDD overlay note outside generated blocks in `AGENTS.md` and `CLAUDE.md`.
   - Restore Agentflow-SDD context and artifact rules in `openspec/config.yaml`.
   - For active changes that follow Agentflow-SDD, report missing `agentflow/` step documents instead of silently recreating them without context.
5. Compatibility review:
   - Check whether `spectra-propose`, `spectra-ingest`, or `spectra-apply` changed in a way that affects the overlay.
   - If command names, artifact order, or validation behavior changed, update `sdd-agentflow` accordingly.
6. Verify:
   - `spectra --version`
   - `spectra list --json`
   - `spectra schema validate spec-driven`
   - `git diff --stat`

## Output

Report:

- Spectra version
- Whether generated skills changed
- Whether project `sdd-*` skills are intact
- Whether `openspec/config.yaml` still contains Agentflow-SDD rules
- Whether active Agentflow-SDD changes still have expected `agentflow/` step documents
- Any required manual follow-up
