## Context

The module has no spec-driven workflow and no `tests/` directory yet. Sibling modules already plan with OpenSpec and the shared engineering standards are published as OpenSpec stores.

## Decisions

- **Stores pinned through the profile.** `openspec/config.yaml` references `quality`, `repository` and `terraform` at released tags (copied from the `terraform-module` profile); `mise run spec-setup` registers them once per machine. Standards are fetched on demand, not copied into the repository.
- **Skills for Claude Code and OpenCode.** The `openspec-*` skills are installed in both `.claude/skills/` and `.opencode/skills/` and kept identical by `openspec update`; `AGENTS.md` is the single routing file (`CLAUDE.md` imports it).
- **CI job `validate:specs`.** `.gitlab/specs.yml` runs `openspec validate --all --strict` with the version pinned by `OPENSPEC_VERSION`, the same command as `mise run spec-validate`. It needs no store.
- **Capability split.** `module-contract` holds cross-cutting facts (versions, no provider/backend blocks, inputs, project resolution, outputs). The functional areas follow the three resources: `domain-registration`, `dns-zone`, `dns-records`. Each can be changed independently, as the module's features can be used independently.
- **Baseline describes released behaviour only.** Code that looks inconsistent (unused inputs, an unreachable precondition) is not specified; it is left for a dedicated change.
- **CHANGELOG stays generated.** `CHANGELOG.md` is produced by git-cliff from commit subjects (`mise run changelog`); OpenSpec does not curate it, so commit subjects read as CHANGELOG lines.

## Risks / Trade-offs

- Baseline specs can drift from the code until tests exist; the first behaviour change adds `tests/main.tftest.hcl` to pin them.
