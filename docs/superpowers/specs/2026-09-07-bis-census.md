# Census of the 3 BiS ranking bases → STANDARD decision

Date: 2026-09-07. Task 1 of the meta-BisTooltip data-system plan. Analysis only — no addon code changed.
Gate: `lua5.1 tools/census_bis.lua` requires the line `STANDARD = ...` below.

STANDARD = wowsims (file `Bistooltip_WoWSimsBP_bislists.lua`, global `Bistooltip_wowsims_bislists`)

## 1. Sources inventoried

All paths relative to repo root `/mnt/d/PROJEKTY/Bistooltip-main` (files are UNTRACKED working-dir
copies there, except where noted; the worktree `feat/meta-bistooltip-data` tracks only the wowtbc file):

| file | size | lines | global | git status |
|---|---|---|---|---|
| `Bistooltip/Bistooltip_wowtbc_bislists.lua` | 829 KB | 3114 | `Bistooltip_wowtbc_bislists` | tracked (HEAD) |
| `Bistooltip/Bistooltip_wh_bislists.lua` | 686 KB | 2536 | `Bistooltip_wh_bislists` | untracked reference |
| `Bistooltip/Bistooltip_WoWSimsBP_bislists.lua` | 1,9 MB | 9688 | `Bistooltip_wowsims_bislists` (+ `Bistooltip_bislists_alliance` / `_horde`) | untracked reference |
| `Bistooltip_wowtbc_bislists _some custom items.lua` (repo root) | 829 KB | — | same `Bistooltip_wowtbc_bislists` global (overwrite variant) | untracked, NOT analyzed (later triage) |

All three load offline under `lua5.1` with only `FACTION_ALLIANCE`/`FACTION_HORDE` stubbed.
Shape (all three): `BIS[class][spec][phase][slot] = { [1..6] = itemID, slot_name=..., enhs={...} }`
— 6 ranked IDs per slot, `-1` = empty filler, gems/enchants embedded per slot (`enhs`).

## 2. Coverage (measured, `lua5.1 /tmp/opencode/census_analyze.lua`)

| dataset | classes | specs | combos (class/spec/phase) | slots | entries | `-1` | unique items | phases declared |
|---|---|---|---|---|---|---|---|---|
| wowtbc | 10 | 32 | 190 | 2822 | 16932 | 292 | 2838 | PR,T7,T8,T9,T10,RS |
| wh | 10 | 31 | 153 | 2284 | 13704 | 90 | 2513 | PR,T7,T8,T9,T10 (no RS) |
| wowsims (primary) | 10 | 32 | 190 | 2822 | 16932 | 292 | 2836 | PR,T7,T8,T9,T10,RS |

- Spec difference: Mage `Fire FFB` exists only in wowtbc+wowsims; wh Mage = Arcane/Fire/Frost.
- Sparse phases: DK `Blood dps` lacks T7/T8 in wowtbc AND wowsims (wh: only PR,T9,T10 for that spec).
- wowsims file additionally holds faction tables `Bistooltip_bislists_alliance`/`_horde`
  (10 classes each, all 6 phases, 2652 alliance slots, single-rank `[1]` + `-1` fillers,
  970 unique alliance rank-1; alliance-vs-horde rank-1 agreement 93.0%).

## 3. Overlap (measured)

- Unique-item overlap: wowtbc∩wowsims = 2833 (only-wowtbc 5, only-wowsims 3);
  wowtbc∩wh = 2143 (only-wowtbc 695, only-wh 370).
- Rank-1 agreement: wowtbc vs wowsims **99.0%** (2794 shared slots);
  wh vs wowsims 63.2%, wowtbc vs wh 62.3% (2159 shared slots).
- wh vs wowsims rank-1 per phase: PR **0.9%**, T7 77.6%, T8 83.9%, T9 82.3%, T10 70.9%.
  wh is a genuinely different ranking, most divergent pre-raid.

## 4. Custom-item finding (decisive)

- wowtbc is the ONLY base with out-of-range IDs: 27 entries, **all rank-1**, all in
  `Weapon` (24) / `Ranged` (3) slots; 5 unique IDs: 128858, 130023, 130031, 131004, 150005
  (max real-WotLK ID in the other bases: 54591; wh/wowsims have zero custom entries).
- In the exact same slots wowsims ranks real items (e.g. Fury T7 Weapon: wowtbc=130031 vs
  wowsims=40384; the 3 wowsims-only IDs 40343, 42317, 45458 are the displaced real items).
- Shape match: a private-server diff baked into the base file, NOT part of any Standard.

## 5. Is `wh` Whitemane-only? No (evidence)

- Zero occurrences of "Whitemane" (any case) in all addon Lua; only `WHITE8x8` textures.
- Zero custom IDs; full 10-class / 31-spec / 5-phase coverage with its own T7–T10 rankings —
  a server diff would touch single slots, not ship a parallel full ranking with 0.9% PR agreement.
- Verdict: `wh` is an independent reference ranking (cross-check), not a server diff.

## 6. Runtime wiring today

- `.toc` loads ONLY `Bistooltip_wowtbc_bislists.lua`; `Config.lua` (`EnableSpec`) and
  `EmblemData.lua` (T8 auto-registration) consume `Bistooltip_wowtbc_bislists`.
- `wh` / `WoWSimsBP` files are loaded by nothing (not in `.toc`, not in git).

## 7. Decision and consequences

STANDARD = wowsims (file `Bistooltip_WoWSimsBP_bislists.lua`, global `Bistooltip_wowsims_bislists`,
faction slots resolved via `Bistooltip_bislists_alliance`/`_horde`).

Rationale: spec direction is WoWSims-first with Wowhead/RaidMasterSuite cross-check and NO new
ranking from scratch. wowsims primary is rank-99%-identical to the current runtime base (wowtbc)
minus its 27 custom rank-1 overrides, has full RS coverage + Fire FFB, zero custom IDs, and the
only faction-split tables. It is the cleanest superset, not a new build.

- wowtbc → migration/runtime reference; its 5 custom IDs (27 rank-1 Weapon/Ranged entries) are
  the candidate private-server diff for later triage (with the root `_some custom items` file).
- wh → cross-check reference only (especially T7–T10, ~71–84% rank-1 agreement); PR ignored as
  a divergent snapshot.
- No `merged` ranking, no new ranking from scratch.

Risk/flag for later tasks: the STANDARD source files (`wh`, `WoWSimsBP`) are currently UNTRACKED
in git and absent from the worktree — a later task must decide where the authoritative STANDARD
data lives (vendor into repo vs. reference-only) before migration code depends on it.

## 8. Repro

From `/mnt/d/PROJEKTY/Bistooltip-main` (read-only; files live only there):
`lua5.1 -e '_G.FACTION_ALLIANCE="A"; _G.FACTION_HORDE="H";
dofile("Bistooltip/Bistooltip_wowtbc_bislists.lua");
dofile("Bistooltip/Bistooltip_wh_bislists.lua");
dofile("Bistooltip/Bistooltip_WoWSimsBP_bislists.lua");
print(Bistooltip_wowtbc_bislists and "wowtbc OK", Bistooltip_wh_bislists and "wh OK",
Bistooltip_wowsims_bislists and "wowsims OK")'`
Full per-slot stats: `lua5.1 /tmp/opencode/census_analyze.lua` (one-off, uncommitted).
Gate (worktree): `lua5.1 tools/census_bis.lua` → `census gate: OK`.
