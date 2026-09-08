# W2 — Tier backfill (VOA + TOKEN/MARK per-boss + quest rule)

> **For agentic workers:** implement task-by-task; oracle file is TRANSIENT
> (never committed, never in .toc — GPLv2, spec S4-2).
> Lua via WSL: `wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && lua5.1 …"`.

**Goal:** Fill the tier-data gaps: canonical Vault of Archavon, per-boss
TOKEN (T7–T9) and MARK (T10) acquisitions replacing the aggregated fake
`boss="Mark"` source, and the owner's quest rule (boss-tied quest rewards
render as `<Boss> [Quest]`, e.g. 45614 Starshine Circle → Algalon).

**Spec:** `2026-09-08-metaz-design.md` §5 (S4-5), §2 (S2-3 vocab — already
live), Q10/Q11 decisions (uniform `T7`–`T10` labels, no 10/25 split in
tier labels; Ulduar 10N/25N/10HM/25HM only).

## Global Constraints

- Oracle (Pazzions AtlasLoot `wrathofthelichking.lua`) = offline validation
  + fact extraction only; downloaded to /tmp, NEVER committed. Relations
  imported into `tools/tier_matrix.lua` carry provenance + classification
  (frozen S4-2: "relation exists" ≠ "acquisition of the final item").
- Tier families: short names in data (`Lost/Wayward/Grand Protector`,
  T10 `Protector/Conqueror/Vanquisher`) — full→short map lives in the
  matrix file comments, never parsed at runtime (S2 rule 1).
- No fake bosses: the `ICECROWN_CITADEL_*_MARK` aggregate (`boss="Mark"`)
  is REMOVED and replaced by real per-boss MARK entries; checker gains a
  `boss ~= "Mark"` assertion.
- Quest rule (owner, 2026-09-08): quest reward tied to a boss = DROP kind,
  boss label `<Boss> [Quest]` (e.g. `Ulduar [10N] - Algalon [Quest]`),
  difficulty from the quest's lockout; distinct sourceID to avoid identity
  collision with the boss's regular drops.
- VOA keys in the upstream variant (`"of Archavon Archavon1..7"`) are
  garbage — decoding is oracle-verified before anything is committed; the
  fork input file gains properly-named zones instead.

---

### Task 1: Oracle acquisition + structure report (transient)

- [ ] Download to /tmp (curl, never into repo):
  `https://raw.githubusercontent.com/wonderkidsem-official/Pazzions-WotLK-BiS-List-AtlasLoot-Enhanced-v5.11.04/main/AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua`
- [ ] Inspect: table shape (BossKey → item rows), how difficulties are
  encoded, how quest rewards are marked; record findings in this plan's
  execution log (commit message / notes below).

### Task 2: VOA canonical supplement

**Files:** `Bistooltip/Loot_Sources.lua` (input), `tools/migrate_sources.lua`
(ZONE_DIFFICULTY), `tools/check_sources.lua` (drop the VOA ban, add matrix rule)

- [ ] Decode the 7 upstream keys (`of Archavon Archavon1..7`) via oracle
  cross-check into boss × difficulty: {Archavon, Emalon, Koralon, Toravon}
  × {10N, 25N} (verify actual coverage — some bosses may be missing).
- [ ] Append canonical zones to the fork input:
  `["Vault of Archavon (10)"] = { ["Archavon the Stone Watcher"] = {…}, … }`
  (and the 25 variant); map both in ZONE_DIFFICULTY → `10N`/`25N`.
- [ ] Checker: remove the `instance ~= "Vault of Archavon"` assert; add:
  VOA present with ≥1 boss per tier T7–T10 gloves/legs family (oracle-count
  based exact rule set while implementing); keep `boss ~= "Mark"` guard.
- [ ] Regenerate + audit green.

### Task 3: `tools/tier_matrix.lua` (committed derived facts)

- [ ] Extract from oracle + domain cross-check: for every tier token item
  (T7/T8/T9) → list of {instance, boss, difficulty}; for T10 marks →
  {boss, 25N|25HC}; TROPHY stays as-is (already VENDOR+displayVariant).
- [ ] Committed shape: `TOKENS[itemID] = { tier, family, sources = {{zone,boss,diff}} }`,
  `MARKS_GEAR[itemID] = { tier, family, sources = … }` + provenance header
  (oracle version/date + cross-check note). No oracle code/text beyond facts.

### Task 4: Migrator post-pass — TOKEN/MARK + quest + fake-Mark removal

**Files:** `tools/migrate_sources.lua` (post-pass after lootTable walk)

- [ ] TOKEN/MARK upgrade: for matrix items, replace migrator DROP entries
  with `{kind="TOKEN"/"MARK", tier, family, source=<canonical per-boss>}`
  — one entry per real boss×difficulty, no dedup (S2-2).
- [ ] Remove `ICECROWN_CITADEL_25N_MARK`/`_10N`/… aggregates: gear items
  get per-boss MARK entries instead.
- [ ] Quest rule: `QUEST_DROPS = { [45614] = {"Ulduar","Algalon [Quest]","10N"}, … }`
  → dedicated sourceIDs (`ULDUAR_10N_ALGALON_QUEST`), remove 45614 from the
  raw 25N Algalon list.
- [ ] Regenerate; audits: every matrix item renders ≥1 line; TOKEN/MARK
  golden strings verified in test_formatter (already covered by S2 goldens);
  `boss ~= "Mark"` assert green; render coverage 0 unrenderable.

### Task 5: Full gate + CHANGELOG + in-game checklist (owner)

- [ ] luac all, formatter/pluginapi/check_sources/census gates green.
- [ ] CHANGELOG entry (VOA sources, tier token/mark format, Algalon [Quest]).
- [ ] Owner in-game spot-check: VOA gloves/legs lines, T8 token line
      `T8 - TOKEN: Wayward Protector [Ulduar: <Boss> <25N>]`, T10 gear with
      multiple MARK lines, 45614 tooltip shows `Algalon [Quest]`.

## Execution log

- 2026-09-08, wave 1 COMPLETE (in-game check pending): oracle inspected
  (pages are per CLASS-GROUP, not per boss; upstream VOA keys inherited the
  same numbering — decoding done from page CONTENT). VOA decoded from all
  78 oracle pages (4 bosses × 2 difficulties + Koralon A/H variants merged)
  and spliced into Loot_Sources as canonical zones. `tools/tier_matrix.lua`
  committed (ICC mark bosses, marks 52025-30, class→family, quest drops).
  Migrator: Tier 10N/10HC zones now emit per-boss MARK entries (5 bosses ×
  25N/25HC); fake `Mark`/`Mark HC` aggregates gone; serializer supports
  TOKEN/MARK fields; dedupe key includes source+family. Quest: 45614 →
  `Ulduar [25N] - Algalon [Quest]` (removed from raw Algalon-25 list).
  Result: 719 sources / 8233 items / 950 MARK entries on 190 items /
  1 quest line; audits green (VOA matrix, MARK shape, fake-boss guard).
  Oracle anomalies handled: ICC 10HC mark rows EXCLUDED (single witness,
  contradicts lockouts); 25HC lists both mark tiers (kept — private-server
  reality).
- WAVE 2 REMAINING: T7/T8 TOKEN per-boss matrix (Naxx/Ulduar/Sartharion
  token rows already extracted to /tmp — needs gear↔token-slot matching
  via oracle slot descriptors) + T9 Regalia from Tribute chest pages.
