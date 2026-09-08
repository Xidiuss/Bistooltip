# W0a — Census rerun on refreshed data (implementation plan)

> **For agentic workers:** implement task-by-task; steps use checkbox syntax.
> Commands assume WSL Lua: `wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && lua5.1 …"`.

**Goal:** Re-run the BiS census on the refreshed (upstream 2026-06-09) data files, re-confirm `STANDARD = WoWSimsBP`, and make the analysis reproducible (committed script instead of the one-off `/tmp` original).

**Spec:** `docs/superpowers/specs/2026-09-08-metaz-design.md` (§10 W0a), addendum in `docs/superpowers/specs/2026-09-07-bis-census.md`.

## Global Constraints

- Analysis only — NO addon runtime file changes.
- Lua 5.1, no WoW API: stub `FACTION_ALLIANCE`/`FACTION_HORDE`, `dofile` the three bislist files.
- The old census numbers describe the STALE copies; the rerun section must state the fresh numbers separately (no overwriting of history).

---

### Task 1: Committed analysis tool `tools/census_analyze.lua`

**Files:**
- Create: `tools/census_analyze.lua`

- [ ] Step 1: Write the tool (pure lua5.1, run from repo root). Measures per DB (`wowtbc`, `wh`, `wowsims`): classes, specs, class/spec/phase combos, slots, ranked entries, `-1` fillers, unique items, declared phases. Pairwise: unique-item overlap; rank-1 agreement on shared slots (`wowsims`↔`wowtbc`, `wowsims`↔`wh`, `wowtbc`↔`wh`, plus `wh`↔`wowsims` per phase). Custom-ID scan (`id > 54591`, expect 0 everywhere after refresh). WoWSimsBP faction tables: slot counts + alliance↔horde rank-1 agreement.
- [ ] Step 2: Run: `lua5.1 tools/census_analyze.lua` — verify it prints all sections without errors.

### Task 2: Rerun + census doc update + STANDARD re-confirmation

**Files:**
- Modify: `docs/superpowers/specs/2026-09-07-bis-census.md` (append `## Rerun (2026-09-08, refreshed data)` section)
- Modify (only if decision changes): the `STANDARD = ` line area — decision change requires explicit justification, not silent edit.

- [ ] Step 1: Run the tool, capture the report.
- [ ] Step 2: Append the rerun section: fresh numbers table, drift vs old numbers (e.g. old rank-1 agreement wowsims/wowtbc 99.0% → new X%), custom-ID result (expected 0 — the 27 Whitemane entries now live only in the extraction artifact), and an explicit `STANDARD = WoWSimsBP — RECONFIRMED` (or a flagged change proposal if the data contradicts it).
- [ ] Step 3: Gate: `lua5.1 tools/census_bis.lua` → `census gate: OK`.

### Task 3: Commit

- [ ] `git add tools/census_analyze.lua docs/superpowers/specs/2026-09-07-bis-census.md && git commit -m "census: rerun on refreshed upstream data, reconfirm STANDARD"`

## Self-review

- Reproducible (committed tool), honest history (append, not overwrite), explicit re-confirmation gate. No runtime changes.
