# BisTooltip Changelog

## v3.0.0 — row duplication FIXED (owner-verified in-game, 2026-09-15)

### Root cause & fix

1. **Assembler serializer collapsed sparse override maps** — `ser()` used
   implied sequential keys whenever `#v`-based checks passed; on a sparse map
   `{[1],[4],[6],…}` Lua's `#` returns an undefined border, so horde override
   indices silently shifted after every gap → duplicated Trinket/Weapon/Off
   hand rows, missing Chest/Hands/Legs (Paladin, Mage FFB, Warlock, Enh
   Shaman, Combat Rogue). Dense detection now counts keys explicitly
   (exactly 1..maxKey, no `#` anywhere); sparse maps keep explicit `[k]=` keys
2. **D8 collapse** — duplicate slot_name entries inherited from the raw
   upstream faction tables (their dual-slot convention: Weaponx2, Waistx2)
   are merged into single slots with concatenated/deduped/capped rank lists
   (the STANDARD model expresses duals via ranks)
3. Verified: applied-horde sweep 0 illegal duplicates across ALL phases;
   all reported phases render Head..Relic clean; owner in-game confirmation
   (Paladin + Mage + Warlock + Shaman + Rogue)

## META-Z hotfix round 1 (2026-09-10) — owner in-game feedback

### Fixed

1. **Sorting crash** (`invalid order function`): heroic/normal comparator could
   return `nil` when a vendor item had no raid zone — both comparators now
   return real booleans
2. **VENDOR mode rebuilt per-ITEM** (was per-slot): slots are replaced by
   virtual slots holding only purchasable ranks — raid items no longer leak
   into the mode (T8 shoulders, Naxx drops), "unknown vendor" disappeared,
   group cost totals are the true sum (5×20 = 100, not 320)
3. **Database switch now fully refreshes the UI** even when the options panel
   covers the window: class/spec/phase dropdowns rebuild for the new database
   (fixes Rogue tab showing DK "Blood tank" until a manual refresh)
4. **TOC/TOGC shorthand** (owner D17): Trial family renders `TOC [25N] - Boss`
   for N and `TOGC [25HC] - Tribute Chest` for HC; **VoA** unified (D18)
5. **T9-232 garbage sources removed** (D17c): the 19 mechanical
   "Tier 9 <spec> (HC5, Raids25)" zones no longer produce DROP identities —
   those items show their proper `T9 - VENDOR: N Emblem of Triumph` lines
6. **N difficulties are green** now (D20): `[10N]/[25N]/<25N>` render green
   instead of gray (HC red / HM orange unchanged)
7. **wh database renamed "Wowhead (wh)"** in the dropdown (owner D-B5: the
   plugin is Whitemane; the ranking base is Wowhead)

## META-Z W6 + W8 (2026-09-08) — Whitemane plugin, clean core, unified gate

### Changes

1. **`Bistooltip_Whitemane_Frostmourne` plugin** (hard ## Dependencies)
   - 27 legendary rank-1 overrides as DB-independent `SetBiSSlotRank` calls
     (generated from the extraction artifact, all paths verified against the
     STANDARD database; typo `[15000]` fixed to 150005 per owner Q2)
   - 377 custom-currency vendor costs (Emblem of Ascension / Ascension II,
     Echo of the Titans) via `AddAcquisition` — append, core drop lines kept
2. **Core is now clean WotLK**: the custom-server currency tables left
   EmblemData for the plugin; core VENDOR entries 658 → 293 (standard emblems
   only); regenerated ItemAcquisition (8224 items) — audits green
3. **`tools/run_all.sh`** — single gate: syntax (luac) + formatter/pluginapi/
   check_sources/census suites + end-to-end validation of EVERY
   `Bistooltip_*/main.lua` plugin; `test_plugin.lua` now binds the STANDARD
   database like `EnableSpec` does
4. **CI** (`.github/workflows/tests.yml`): lua5.1 + full gate on every
   push/PR (owner-approved, Q15)

## META-Z W4 (2026-09-08) — database registry, faction assembly, account-wide state

### Changes

1. **Three selectable ranking databases** (options → Data source, default WoWSimsBP)
   - `Bistooltip_wowsims_final.lua` generated OFFLINE by `tools/assemble_wowsims.lua`
     (1:1 port of upstream's faction assembly): alliance base (2907 slots) +
     `horde_overrides` — only the 956 slots (32.9%) where horde differs — applied
     at runtime by reference swaps (706 KB loaded instead of the 1.98 MB 3-table file)
   - `wh` and cleaned `wowtbc` join as plain aliases; upstream input files stay
     in the repo but are no longer loaded
2. **SetBiSSlotRank** — 6th plugin API function: single-rank, DB-independent
   server diffs (rank validation + duplicate-rank warning)
3. **Overlay replay** — every plugin mutation is recorded (deep-copied) and
   replayed on database switch; AddAcquisition is now idempotent (byte-identical
   appends are no-ops), so replays never duplicate lines; failures warn-once
4. **Account-wide state (§12)** — `data_source` + personal BiS priorities moved
   to `db.global` (one-time migration from `db.char`; char copies dormant);
   personal order caches reset on database switch and re-reconciled by ID

## META-Z W7 + S2-5 (2026-09-08) — vendor scanner addon + cost units

### Changes

1. **New standalone addon `Bistooltip_Scanner`** (OptionalDeps: Bistooltip)
   - `/bis scan` or the "Bis Scan" button on MerchantFrame: reads the open
     vendor (ID, name, gold price in copper, extended-cost currencies) into
     `BistooltipScannerDB` per "Vendor @ Zone" key, then opens an export window
   - Export = ready-to-paste Bistooltip plugin snippet (VENDOR mode default,
     CUSTOM mode toggle for donate shops); rescan-safe (keyed by itemID)
   - `/bis item <ID>`: one-item acquisition skeleton (name from cache, UNCACHED
     marker otherwise) — for adding custom items without a vendor
   - All merchant API calls guarded; mock-tested offline (scan/SV/snippet/UI)
2. **Cost units canonical (S2-5)**: `amount` for `currency="Gold"` is always
   COPPER; the formatter renders it as g/s/c (`15g`, `15g 59c`)
3. **TROPHY label from data (S2-5)**: `variantLabel="Crusade"` lives in the
   generated data now, not hardcoded in the formatter

## META-Z W3 (2026-09-08) — colored source rendering

### Changes

1. **Colored source lines** (spec S2-4; colors on by default, Q9)
   - New pure `BisTooltip_FormatSourceColored(entry)` — identical MASTER
     structure with per-part colors; plain `FormatSource` stays canonical
     (tests, dedup, logs; identity never includes color)
   - Palette (single table `BisTooltip_SourcePalette`, aliased as
     `Constants.COLORS.SOURCE`): instance gold, boss/family white,
     tier+method blue, currency teal, N gray / HC red / HM orange
   - Tooltip source lines no longer uniformly green; checklist cards use
     the palette (boss white, difficulty per N/HC/HM, currency teal)
2. Golden tests extended: 7 colored cases on top of 10 plain + 5 cost cases

## META-Z W2 wave 1 (2026-09-08) — tier backfill: VOA + T10 MARK + quest rule

### Changes

1. **Vault of Archavon sources added** (was completely absent)
   - 4 canonical bosses × {10N, 25N}, items decoded from the AtlasLoot oracle
     (upstream's mangled `Archavon1..7` keys replaced by real boss names)
   - Toravon drops T10 gloves/legs directly; Emalon/Koralon carry T8/T9 tokens
2. **T10 sanctified gear: per-boss MARK format** (owner requirement)
   - `T10 - MARK: Protector [Icecrown Citadel: Deathbringer Saurfang <25N>]` —
     one line per real boss (Saurfang, Putricide, Lana'thel, Sindragosa, Lich King)
   - Replaces the aggregated fake source `boss="Mark"` (950 MARK entries / 190 items)
   - Mark of Sanctification items themselves list their boss drops
3. **Boss-tied quest rewards rule** (owner: "dałbym drop Algalon[quest]")
   - `Ulduar [25N] - Algalon [Quest]` for Starshine Circle (45614)
4. Audits extended: VOA matrix, MARK shape (T10/ICC/25N+25HC/families),
   fake-boss guard, `[Quest]` line presence; full gate green

## META-Z W1 (2026-09-08) — runtime cutover + difficulty vocabulary v2

### Changes

1. **Loot_Sources.lua no longer loads at runtime** (`Bistooltip.toc`)
   - Zero runtime consumers; the file remains the offline migrator input
2. **Single source of truth for vendor costs** (`SourceFormatter.lua`, `DataProvider.lua`)
   - New pure `BisTooltip_GetVendorCost(itemID)`; `GetEmblemCost`/`HasEmblemSource`
     read `ItemAcquisition` VENDOR entries instead of `EmblemData` tables
3. **Difficulty labels v2** (visible in tooltips)
   - 5-man heroics: `[H]` → `[HC]`; Ulduar hard modes: `<10HC>/<25HC>` → `<10HM>/<25HM>`
   - Ulduar now exclusively 10N/25N/10HM/25HM; Vault of Archavon deferred to the
     tier-backfill workstream (raw upstream keys are mangled)
4. **Data regenerated** from the canonical Loot_Sources with vocabulary v2
   (712 sources / 8820 acquisition entries; audits green, TROPHY prices locked)
5. **ASCEND mode renamed to VENDOR** with new semantics (pulled forward from W5)
   - Qualification by acquisition kind (VENDOR via `BisTooltip_GetVendorCost`), not
     by the "Ascension" currency substring — works on clean WotLK (Triumph/Frost)
     and with custom currencies alike
   - Fixed owner-reported leak: slots whose vendor item sat below rank 1 were grouped
     by their rank-1 raid instance (e.g. Trial of the Crusader groups inside the
     filter mode); VENDOR mode now groups strictly by the slot's vendor currency and
     never renders instance groups
   - Button label, tooltips, empty-state and summary strings updated

## Version 2.2.2-3.3.5a (2026-04-17)

### Bug Fixes

1. **Ctrl+Click Dressing Room** (`BislistUI.lua`)
   - Pressing Ctrl+Left Click on any item icon in the BIS list now opens the Dressing Room with that item equipped
   - Shift+Click still links the item to chat
   - Plain click no longer accidentally inserts links (modifier key required)
   - Applies to all item icons: main BIS list and checklist mode

2. **ASCEND Mode — Missing Emblem of Ascension II Items** (`DataProvider.lua`)
   - Fixed: items purchasable with Emblem of Ascension II were not shown in ASCEND filter mode
   - Root cause: filter only checked for exact `"Emblem of Ascension"` currency, skipping `"Emblem of Ascension II"`
   - Fix: changed to `string.find(currency, "Ascension")` — consistent with checklist group logic
   - Now correctly shows T8 token set pieces, Ulduar drops, Val'anyr, Domhammer, and all other Ascension II items

---

## Version 2.2.1-3.3.5a (2026-04-10)

### Features

1. **T8 Set Auto-Registration from BIS Lists** (`EmblemData.lua`)
   - Added `RegisterT8SetFromBislist()` — automatically scans the T8 phase of all BIS lists and registers class-specific set piece items with the correct Emblem of Ascension II cost
   - Slot costs: Head / Chest / Legs = 25 emblems, Shoulder / Hands = 19 emblems
   - Items appearing in multiple classes (non-set drops) are skipped automatically
   - Items already registered in any emblem table (e.g. Echo of the Titans drops) are preserved with their original cost
   - Eliminates the need to manually maintain a list of T8 set piece IDs per spec

2. **EmblemData Load Order Fix** (`.toc`)
   - `EmblemData.lua` now loads after `Bistooltip_wowtbc_bislists.lua` to allow T8 set auto-registration at startup

---

## Version 2.2.0-3.3.5a (2026-02-13)

### Bug Fixes

1. **Slash Commands Restored**
   - `/bis` and `/bistooltip` commands were not working due to missing registration in the active code path
   - Both commands now fully functional with subcommands: `config`, `reload`, `help`
   - Short aliases: `/bis c` (config), `/bis r` (reload)

2. **Cross-Faction T9 Tooltip Fix**
   - Fixed "Your Class NO BIS" showing for all T9 (and other faction-specific) items when hovering over equipped gear
   - Root cause: BIS lists store Horde item IDs, but Alliance players see Alliance IDs in tooltips - no reverse mapping was performed
   - Added `GetBisCanonicalID()` with lazy-built reverse cache for O(1) Alliance-to-Horde ID normalization
   - Fully supports cross-faction private servers where players may have mixed faction items

---

## Version 1.3.8-3.3.5a

### Bug Fixes

1. **Checkmark Color Stability Fixed**
   - `clearCheckMarks()` now properly hides textures with `Hide()`
   - Colors reset to white (1,1,1,1) before clearing
   - Prevents color bleeding when clicking UI elements

2. **Removed Blue Border from Gem Box**
   - Gem plan row has no backdrop (completely transparent)

3. **Discord Link Dialog Fixed**
   - Single "OK" button with copy hint

4. **Slot Separators in All Modes**
   - Solid line separator `_____` now visible in standard mode
   - Color: medium gray (#555555)
   - Works in: Standard, BIS Checklist, and Customize modes

5. **Gem Condensing in Standard Mode**
   - Duplicate gems now show as "2x" or "3x" instead of repeating
   - Example: 3 identical gems → single icon with "3x" label
   - Only applies to standard mode (BIS Checklist shows all gems)

6. **Spec Highlight for Your Specialization**
   - When Spec Highlight is enabled for player's own spec
   - "Your specialization" section now shows `>>` markers
   - Format: `>> Warrior - Protection <<`

---

## New Features Since Lock Phase (v1.3.0)

### 1. Lock Phase System (v1.3.0)
- **Checkbox "Lock"** next to phase dropdown
- When locked, phase dropdown is disabled
- **Tooltips filter**: Only show BIS info for locked phase and earlier

### 2. Customize Mode (v1.3.0)
- **Checkbox "Customize"** in dropdown row
- Only available in standard view
- Allows reordering item priorities per slot

### 3. Slot Locking Icons (v1.3.0)
- **[O]** = unlocked (green), **[X]** = locked (default)
- Click to toggle unlock state
- **[L]** header to toggle all slots

### 4. Click-to-Swap Item Reordering (v1.3.1)
- Click first item → red border appears
- Click second item → positions swap
- Right-click → cancel selection

### 5. Reset Button "R" (v1.3.1)
- Resets all custom priorities for current class/spec/phase
- Restores original item order

### 6. Custom Priority Integration (v1.3.5)
- Custom item order reflects in tooltips
- Item at position 1 shows as "BIS"
- Progress bar counts custom BIS items

### 7. Progress Bar Improvements (v1.3.4-1.3.7)
- Counts ALL slots
- Proper Horde↔Alliance ID lookup
- Color changes based on progress %

### 8. Phase Combining (v1.3.7)
- "PR BIS / T7 BIS" → "BIS PR-T7"
- All BIS text in green color

### 9. Tooltip Enhancements (v1.3.7)
- "Where:" changed to "Rank:"
- Rank: hidden when BIS until last phase
- Player's spec hidden from main list

### 10. UI Polish (v1.3.7-1.3.8)
- Bright green checkmarks (0, 1, 0)
- Gem stat width reduced for better fit
- Slot separators in all modes
- Gem condensing (2x, 3x notation)
- Spec Highlight works for player's spec

---

## Version History

| Version | Key Changes |
|---------|-------------|
| 2.2.2 | Ctrl+Click dressing room, ASCEND mode Ascension II fix |
| 2.2.1 | T8 set auto-registration from BIS lists |
| 2.2.0 | Slash commands fix, cross-faction T9 tooltip fix |
| 1.3.0 | Lock Phase, Customize Mode, Slot Locking |
| 1.3.1 | Click-to-Swap, Reset Button |
| 1.3.2 | Tooltip options, Lock Phase filtering |
| 1.3.4 | Progress bar counting |
| 1.3.5 | Custom priority system |
| 1.3.6 | Reset functionality, BIS green color |
| 1.3.7 | Phase combining, Rank: label, credits |
| 1.3.8 | Color fix, separators, gem condensing, spec highlight |
