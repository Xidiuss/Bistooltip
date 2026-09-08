# W1 — Runtime cutover + difficulty vocabulary v2 (implementation plan)

> **STATUS: COMPLETE** — Tasks 1–5 executed (commits `601b422`…`500be75`),
> W5 (VENDOR mode) pulled forward per owner request (`ef511c6` + hotfix
> `1409d10`), **Task 6 in-game verification PASSED** (owner, 2026-09-08:
> "teraz jest ok"). Owner data note carried to W2: item 45614 (Starshine
> Circle) is an Algalon quest reward — model as `Algalon [Quest]` source.

> **For agentic workers:** implement task-by-task, TDD (failing check first).
> Lua 5.1 via WSL: `wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && lua5.1 …"`; syntax gate `luac5.1 -p`.

**Goal:** Finish the data-model cutover in the runtime: remove the dead `Loot_Sources.lua` load, make `GetEmblemCost` read the new model (one source of truth for vendor costs), switch the difficulty vocabulary to v2 (`HC` for 5-man heroics, `HM` for Ulduar hard modes), and regenerate `SourceRegistry`/`ItemAcquisition` from the **refreshed** Loot_Sources + current EmblemData.

**Spec:** `docs/superpowers/specs/2026-09-08-metaz-design.md` v2.4 — §0 (cutover W1), §2 (S2-3 vocabulary), §10 row W1.

## Global Constraints

- WoW 3.3.5a Lua 5.1 — no `goto`, no 5.2+ APIs; runtime files stay pure of offline-tool logic.
- `TROPHY` stays display-only; no new acquisition kinds; formatter still the only string builder.
- Vault of Archavon in the refreshed Loot_Sources has mangled boss keys (`"of Archavon Archavon1..7"`) — **deferred to W2** (oracle-driven canonical map). W1 MUST NOT ship garbage boss names: the migrator skips the whole `"Vault of Archavon"` zone with a printed warning.
- `EmblemData.lua` stays loaded until W6 (Whitemane extraction); only its READERS in DataProvider move to the new model now.
- ASCEND mode (until W5 rename) must keep working: `GetEmblemCost` must still resolve the custom "Emblem of Ascension/II" currencies (they exist as VENDOR entries in the regenerated ItemAcquisition).
- Every commit after Task 5 carries a `Tested-In-Game: pending` trailer until the owner runs the Task 6 checklist and confirms.

---

### Task 1: `.toc` cutover — stop loading Loot_Sources.lua

**Files:**
- Modify: `Bistooltip/Bistooltip.toc` (remove `Loot_Sources.lua` line; fix the stale "New source model … must load after Loot_Sources" comment)

- [ ] Step 1: Proof of zero runtime consumers (re-verify, must be empty):
  `grep -rn "lootTable" Bistooltip/*.lua Bistooltip/ui/*.lua Bistooltip/util/*.lua | grep -v "^Bistooltip/Loot_Sources.lua"` → 0 hits.
- [ ] Step 2: Edit `.toc`: drop the `Loot_Sources.lua` line; update the section comment (SourceRegistry/ItemAcquisition no longer depend on load order vs Loot_Sources; EmblemData still loads after bislists).
- [ ] Step 3: Syntax gate all runtime files: `for f in Bistooltip/*.lua; do luac5.1 -p "$f" || exit 1; done && echo OK`.
- [ ] Step 4: Commit: `chore: stop loading Loot_Sources.lua at runtime (offline input only)`.

### Task 2: `GetEmblemCost` → shim over ItemAcquisition (TDD)

**Files:**
- Modify: `Bistooltip/SourceFormatter.lua` — add pure `BisTooltip_GetVendorCost(itemID) -> cost, currency | nil`
- Modify: `Bistooltip/DataProvider.lua` — reimplement `GetEmblemCost` (lines ~399–414) as a wrapper; remove ALL direct `_G.Bistooltip_emblem_items` reads from DataProvider (audit every hit)
- Modify: `tools/test_formatter.lua` — new golden cases

- [ ] Step 1 (failing tests first): append cases to `tools/test_formatter.lua`: fixture `BisTooltip_ItemAcquisition` with (a) plain VENDOR `{{kind="VENDOR",cost={{currency="Emblem of Triumph",amount=50}}}}` → `50, "Emblem of Triumph"`; (b) TROPHY-shaped entry `cost={{item=47242,amount=1},{currency="Emblem of Triumph",amount=75}}` → `75, "Emblem of Triumph"` (currency part preferred over item part); (c) DROP-only item → `nil`; (d) no entry → `nil`. Run → FAIL (function missing).
- [ ] Step 2: Implement `BisTooltip_GetVendorCost` in SourceFormatter.lua (pure; scans `BisTooltip_ItemAcquisition[itemID]` for the first `kind="VENDOR"` entry, returns the first `currency`-typed cost part's amount+name).
- [ ] Step 3: DataProvider: `GetEmblemCost` delegates to the new function; remove `Bistooltip_emblem_items` reads; grep-proof: `grep -n "emblem_items" Bistooltip/DataProvider.lua` → 0 hits.
- [ ] Step 4: `lua5.1 tools/test_formatter.lua` → PASS; syntax gate.
- [ ] Step 5: Commit: `refactor: GetEmblemCost reads ItemAcquisition (single source of truth)`.

### Task 3: Difficulty vocabulary v2 in migrator + checker + goldens (TDD)

**Files:**
- Modify: `tools/migrate_sources.lua` (dictionaries: dungeon `H`→`HC`; Ulduar `10HC/25HC`→`10HM/25HM`; VOA defer-list)
- Modify: `tools/check_sources.lua` (closed set: `"" HC 10N 25N 10HC 25HC 10HM 25HM`; dungeons allow `""`/`HC`; NEW rule: Ulduar sources only `10N/25N/10HM/25HM`)
- Modify: `tools/test_formatter.lua` (goldens: DROP `HC` 5-man, TOKEN `<10HM>`)

- [ ] Step 1 (failing audit first): update `check_sources.lua` closed set + Ulduar rule; run against CURRENT committed data → FAIL (77 sources `H`, N Ulduar `HC` sources — count them, note in commit).
- [ ] Step 2: Update `migrate_sources.lua`: dungeon difficulty table emits `HC`; Ulduar hard-mode difficulty map emits `10HM/25HM`; add `"Vault of Archavon"` to a `DEFERRED_ZONES` list (skip + `print("[defer] Vault of Archavon → W2")`).
- [ ] Step 3: Goldens: add `{ {kind="DROP", source=FIXTURE_H_DUNGEON}, "Ahn'kahet: The Old Kingdom [HC] - Prince Taldaram" }` and a TOKEN case rendering `<25HM>`.
- [ ] Step 4: Regenerate data (Task 4 does the full regen; here only verify migrator changes compile): `luac5.1 -p tools/migrate_sources.lua`.
- [ ] Step 5: Commit: `feat(tools): difficulty vocabulary v2 (HC heroics, HM Ulduar, VOA deferred)`.

### Task 4: Regenerate SourceRegistry + ItemAcquisition from refreshed inputs

**Files:**
- Regenerate: `Bistooltip/SourceRegistry.lua`, `Bistooltip/ItemAcquisition.lua` (committed outputs)
- Modify: `tools/migrate_sources.lua` (only if the audit surfaces NEW unmapped zones/bosses from the refreshed Loot_Sources — reconcile via `CANON_ZONE`/boss-alias/`ZONE_DIFFICULTY` dictionaries, do NOT hand-edit generated files)

- [ ] Step 1: `lua5.1 tools/migrate_sources.lua` → emits fresh tables from refreshed Loot_Sources + EmblemData.
- [ ] Step 2: `lua5.1 tools/check_sources.lua` → expect FAILURES on new/unknown zones or empty difficulties from the refreshed input; reconcile each in the migrator dictionaries (boss aliases, zone difficulties); re-run until PASS (`smoke: OK`, `canonical: OK`).
- [ ] Step 3: Sanity counts vs old data: total items, DROP/VENDOR split, VOA absent (deferred), Ascension currencies still present as VENDOR (grep `Emblem of Ascension` in ItemAcquisition > 0 — ASCEND-mode parity until W5/W6).
- [ ] Step 4: `lua5.1 tools/test_formatter.lua && lua5.1 tools/test_pluginapi.lua && lua5.1 tools/check_sources.lua && lua5.1 tools/census_bis.lua` → all PASS.
- [ ] Step 5: Commit: `data: regenerate SourceRegistry+ItemAcquisition from refreshed upstream (vocab v2)`.

### Task 5: Full gate + CHANGELOG note

- [ ] Step 1: `for f in Bistooltip/*.lua tools/*.lua; do luac5.1 -p "$f" || exit 1; done` → OK.
- [ ] Step 2: Append W1 entry to `Bistooltip/CHANGELOG.md` (runtime: Loot_Sources unloaded; costs from ItemAcquisition; difficulty labels HC/HM visible in tooltips).
- [ ] Step 3: Commit: `docs: changelog for W1 cutover`.

### Task 6: Manual in-game verification (OWNER — client required)

Checklist (record result, then amend the last commit trailer to `Tested-In-Game: yes/no`):
- [ ] `/reload` — no Lua errors on login.
- [ ] Hover: normal drop (expect `Instance [HC] - Boss` for a 5-man heroic item; `Ulduar [25HM] - …` for a hard-mode drop), T9 vendor item (`T9 - VENDOR: 50 Emblem of Triumph`), TROPHY (`T9 - TROPHY: Crusade + 75 …`).
- [ ] `/bis` checklist: emblem groups still show costs (GetEmblemCost shim), ASCEND toggle still filters Ascension items.

## Self-review

- Spec coverage: toc cutover (§0 W1) → Task 1; single truth of costs → Task 2; S2-3 vocabulary → Tasks 3–4; audit/goldens → 3–5; in-game gate → Task 6.
- Risks named: VOA garbage keys deferred (W2), ASCEND parity pinned by grep-assertion, regenerated data must keep custom currencies until W6.
- No placeholders; every command runnable verbatim in the WSL lua5.1 environment.
