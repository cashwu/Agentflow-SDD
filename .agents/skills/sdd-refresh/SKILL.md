---
name: sdd-refresh
description: "Verify Agentflow-SDD skill integrity, config, and active change health. Use after modifying sdd-* skills or suspecting drift."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Refresh

Verify the Agentflow-SDD overlay is intact and consistent. No external CLI dependency.

## Invariants

- Required skills: `sdd-agentflow`, `sdd-discuss`, `sdd-explore`, `sdd-prototype`, `sdd-spec`, `sdd-usage`, `sdd-ticket`, `sdd-dev`, `sdd-review`, `sdd-wrap`, `sdd-refresh`.
- Each required skill must exist in both `.agents/skills/` and `.claude/skills/`.
- `agentflow/config.yaml` must exist and contain valid workflow config.
- `AGENTS.md` and `CLAUDE.md` must contain the `PROJECT-SDD` overlay block.
- `install-agentflow-sdd.fish` must exist and pass `fish -n` syntax check.
- Active changes must have their `agentflow/` step files and `agentflow/reviews/` round files.
- No `sdd-*` skill should reference `spectra` CLI commands or `$spectra-*` skills.

## Refresh Workflow

1. List skills:
   - Glob `.agents/skills/sdd-*/SKILL.md` and `.claude/skills/sdd-*/SKILL.md`.
   - Verify all 11 required skills exist in both directories.
   - Report any missing or extra skills.

2. Verify config:
   - Check `agentflow/config.yaml` exists and parses as valid YAML.
   - Verify it contains `workflow`, `directories`, `artifacts`, `rules` keys.

3. Verify documentation:
   - Check `AGENTS.md` and `CLAUDE.md` contain `PROJECT-SDD:START` / `PROJECT-SDD:END` blocks.
   - Check blocks do not reference `spectra-*` skills or `SPECTRA:START`.

4. Verify installer:
   - Check `install-agentflow-sdd.fish` exists.
   - Run `fish -n install-agentflow-sdd.fish` for syntax validation.
   - Verify it does not contain `--with-spectra`.

5. Verify active changes:
   - Scan `agentflow/changes/*/status.yaml` where `status` is not `archived`.
   - For each active change, verify step files and review round files exist as expected for `current_step`.
   - Report missing files but do not recreate them without context.

6. Spectra residue check:
   - `grep -r "spectra" .claude/skills/sdd-* .agents/skills/sdd-*`
   - Report any remaining references to Spectra.

## Output

Report:

- Whether all 11 required `sdd-*` skills are intact in both `.agents/skills/` and `.claude/skills/`
- Whether `agentflow/config.yaml` exists and is valid
- Whether `AGENTS.md` and `CLAUDE.md` have the correct overlay blocks
- Whether `install-agentflow-sdd.fish` exists and passes syntax check
- Active change health: step files and review round files present
- Any Spectra residue found in `sdd-*` skills
- Any required manual follow-up
