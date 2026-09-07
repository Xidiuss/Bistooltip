# Meta-BisTooltip Data System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the O(N) `lootTable` scan and string-guessing difficulty logic with the frozen S1–S4 model: `SourceRegistry` + `ItemAcquisition`, one MASTER `FormatSource()`, and a 5-function plugin API.

**Architecture:** Offline Lua migrator (run with system `lua5.1`, never in `.toc`) inverts `lootTable[zone][boss]` once into O(1) tables; a pure formatter module owns all display strings; `GetItemSourceInfo` keeps its signature as a thin shim over the new model so tooltip/UI call sites don't change.

**Tech Stack:** WoW 3.3.5a Lua 5.1 (addon runtime); system `lua5.1`/`luac5.1` 5.1.5 for offline tooling and tests.

**Spec:** `docs/superpowers/specs/2026-09-07-metabistooltip-data-design.md`

## Global Constraints

- Runtime is WoW 3.3.5a Lua 5.1 — no `goto`, no bitwise ops, no Lua 5.2+ APIs.
- Server plugins use `## Dependencies: Bistooltip` (hard dep) — no pending-queue / drain lifecycle.
- No new cache/invalidation framework — two O(1) lookups + cheap formatter only.
- `TROPHY` is display-only (`displayVariant="TROPHY"` on `kind="VENDOR"`) — never a new acquisition kind.
- No `EnchantAcquisition` table — enhancements use the single `Enhancements` model.
- AtlasLoot oracle is offline validation only (GPLv2) — never committed, never in `.toc`.
- Scanner addon is future scope — this plan only guarantees the scanner can emit exactly the S3 API.

---

### Task 1: Census of the 3 BiS ranking bases (analysis gate)

**Files:**
- Create: `docs/superpowers/specs/2026-09-07-bis-census.md`
- Modify: none (code untouched)

**Interfaces:**
- Consumes: the three files `Bistooltip/Bistooltip_wowtbc_bislists.lua`, `Bistooltip/Bistooltip_wh_bislists.lua`, `Bistooltip/Bistooltip_WoWSimsBP_bislists.lua`
- Produces: authoritative-dataset decision (`STANDARD = <wowtbc|WoWSimsBP|merged>`) that later BiS work reads from the census note

- [ ] **Step 1: Write the census script (fails: file missing)**

```lua
-- tools/census_bis.lua (usage: lua5.1 tools/census_bis.lua)
-- Loads the 3 ranking files with WoW API stubbed, prints per class/spec/phase
-- item counts + overlap stats. FAILS until the note + decision exist.
local f = io.open("docs/superpowers/specs/2026-09-07-bis-census.md", "r")
assert(f, "census note missing: run the census and record STANDARD decision")
local body = f:read("*a"); f:close()
assert(body:find("STANDARD = "), "census note must contain a 'STANDARD = ...' line")
print("census gate: OK")
```

- [ ] **Step 2: Run it to verify it fails**

Run: `lua5.1 tools/census_bis.lua`
Expected: FAIL with "census note missing"

- [ ] **Step 3: Run the overlap analysis**

Run under `workdir: /mnt/d/PROJEKTY/Bistooltip-main`:

```bash
lua5.1 -e '
_G.FACTION_ALLIANCE="A"; _G.FACTION_HORDE="H"
dofile("Bistooltip/Bistooltip_wowtbc_bislists.lua")
dofile("Bistooltip/Bistooltip_wh_bislists.lua")
dofile("Bistooltip/Bistooltip_WoWSimsBP_bislists.lua")
local function stats(t, name)
  local n=0 for _ in pairs(t) do n=n+1 end print(name, "top-level keys:", n) end
stats(Bistooltip_wowtbc_bislists, "wowtbc"); stats(Bistooltip_wh_bislists, "wh")
' 2>&1 | head -20
```

Record in the note: per-dataset class/spec/phase coverage, whether `wh` is Whitemane-only, and the `STANDARD = ...` decision (direction: WoWSims-first with Wowhead/RaidMasterSuite cross-check; do NOT build a new ranking from scratch).

- [ ] **Step 4: Re-run gate to verify it passes**

Run: `lua5.1 tools/census_bis.lua`
Expected: PASS with "census gate: OK"

- [ ] **Step 5: Commit**

```bash
git add tools/census_bis.lua docs/superpowers/specs/2026-09-07-bis-census.md
git commit -m "docs: census 3 BiS bases, select authoritative STANDARD dataset"
```

---

### Task 2: Offline migrator `lootTable`/`EmblemData` → new model

**Files:**
- Create: `tools/migrate_sources.lua`
- Create (generated): `Bistooltip/SourceRegistry.lua`, `Bistooltip/ItemAcquisition.lua`
- Modify: none yet (generated files NOT wired into `.toc` until Task 5)

**Interfaces:**
- Consumes: global `lootTable` from `Bistooltip/Loot_Sources.lua`, global `Bistooltip_emblem_items` from `Bistooltip/EmblemData.lua`
- Produces: `BisTooltip_SourceRegistry` (`sourceID -> {instance,boss,difficulty}`), `BisTooltip_ItemAcquisition` (`itemID -> {{kind,source,tier,family,cost,...}}`)

- [ ] **Step 1: Write the failing smoke test**

```lua
-- tools/check_sources.lua (part 1; extended in Task 7)
local reg = dofile("Bistooltip/SourceRegistry.lua")
local acq = dofile("Bistooltip/ItemAcquisition.lua")
assert(type(reg) == "table" and type(acq) == "table", "generated files must return tables")
local n = 0 for _ in pairs(acq) do n = n + 1 end
assert(n > 1000, "expected >1000 acquired items, got " .. n)
for id, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    if e.source then assert(reg[e.source], "dangling sourceID " .. tostring(e.source) .. " on item " .. id) end
  end
end
print("smoke: OK (" .. n .. " items)")
```

- [ ] **Step 2: Run it to verify it fails**

Run: `lua5.1 tools/check_sources.lua`
Expected: FAIL (generated files don't exist)

- [ ] **Step 3: Write the migrator (minimal)**

```lua
-- tools/migrate_sources.lua
-- usage: lua5.1 tools/migrate_sources.lua
_G.FACTION_ALLIANCE = "Alliance"; _G.FACTION_HORDE = "Horde"
dofile("Bistooltip/Loot_Sources.lua")   -- provides lootTable
dofile("Bistooltip/EmblemData.lua")     -- provides Bistooltip_emblem_items
local registry, acquisition = {}, {}
local function sourceID(inst, diff, boss)
  return ((inst .. "_" .. (diff or "") .. "_" .. boss):gsub("[^%w]+", "_"):gsub("_+", "_"):upper())
end
for zone, bosses in pairs(lootTable) do
  for boss, items in pairs(bosses) do
    local id = sourceID(zone, "", boss) -- difficulty filled during canonical pass (Task 3)
    registry[id] = registry[id] or { instance = zone, boss = boss, difficulty = "" }
    for _, itemID in pairs(items) do
      if type(itemID) == "number" and itemID > 0 then
        acquisition[itemID] = acquisition[itemID] or {}
        table.insert(acquisition[itemID], { kind = "DROP", source = id })
      end
    end
  end
end
-- emblem items -> VENDOR entries (T9-245 trophy variant flagged in Task 3)
for itemID, e in pairs(Bistooltip_emblem_items or {}) do
  acquisition[itemID] = acquisition[itemID] or {}
  table.insert(acquisition[itemID], { kind = "VENDOR", cost = { { currency = e.currency, amount = e.cost } } })
end
-- serialize both tables to Bistooltip/SourceRegistry.lua + Bistooltip/ItemAcquisition.lua
-- (plain `return {...}` files with sorted keys; serializer ~30 lines, no external deps)
```

Serializer detail is mechanical (sorted `pairs`, `%q` strings, numbers only) — implement inline, no new dependency.

- [ ] **Step 4: Run migrator + smoke test**

Run: `lua5.1 tools/migrate_sources.lua && lua5.1 tools/check_sources.lua`
Expected: PASS with "smoke: OK (N items)"

- [ ] **Step 5: Commit (tool only — generated data committed after canonical pass)**

```bash
git add tools/migrate_sources.lua tools/check_sources.lua
git commit -m "feat(tools): offline migrator lootTable+emblems to new source model"
```

---

### Task 3: Canonical pass (alias normalization, difficulties, TROPHY flag)

**Files:**
- Modify: `Bistooltip/SourceRegistry.lua`, `Bistooltip/ItemAcquisition.lua` (data only)
- Modify: `tools/migrate_sources.lua` (encode canonical decisions so regeneration is stable)

**Interfaces:**
- Consumes: raw generated files from Task 2
- Produces: canonical registry — one identity per real place; every entry has explicit `difficulty`; T9-245 VENDOR entries carry `displayVariant="TROPHY"` with cost `{item=47242}+{currency}`

- [ ] **Step 1: Write the canonical audit (fails on raw output)**

```lua
-- append to tools/check_sources.lua:
for sid, s in pairs(reg) do
  assert(s.difficulty and s.difficulty ~= "", "source without explicit difficulty: " .. sid)
  assert(s.instance and s.boss or s.custom, "source without identity: " .. sid)
end
-- alias guard: known duplicate spellings must not both exist
assert(not (reg["AHN_KAHET_TALDARAM"] and reg["AHN_KAHET_THE_OLD_KINGDOM_TALDARAM"]),
  "duplicate Ahn'kahet identity")
print("canonical: OK")
```

- [ ] **Step 2: Run to verify it fails**

Run: `lua5.1 tools/check_sources.lua`
Expected: FAIL on empty-difficulty sources

- [ ] **Step 3: Canonicalize (data edit, folded into this task)**

Encode in the migrator an `ALIASES` map (`"AhnKahet" -> "Ahn'kahet: The Old Kingdom"`, `"Prince Taldaram" -> "Prince Taldaram"`, boss/difficulty table for T7–T10 raids incl. `10N/25N/10HC/25HC` and `H` for 5-man heroics), re-run the migrator, and flag T9-245 cost entries (`item=47242` present) with `displayVariant="TROPHY"`, `tier="T9"`. Deduplicate identical `{kind,source,...}` entries per item; keep distinct bosses as separate entries (Saurfang vs Putricide both stay).

- [ ] **Step 4: Re-run full check**

Run: `lua5.1 tools/migrate_sources.lua && lua5.1 tools/check_sources.lua`
Expected: PASS with both "smoke: OK" and "canonical: OK"

- [ ] **Step 5: Commit data + tool**

```bash
git add tools/migrate_sources.lua tools/check_sources.lua Bistooltip/SourceRegistry.lua Bistooltip/ItemAcquisition.lua
git commit -m "feat(data): canonical SourceRegistry + ItemAcquisition (aliases, difficulties, T9 TROPHY variant)"
```

---

### Task 4: MASTER formatter module + golden tests

**Files:**
- Create: `Bistooltip/SourceFormatter.lua`
- Create: `tools/test_formatter.lua`

**Interfaces:**
- Consumes: `BisTooltip_SourceRegistry` (global from `SourceRegistry.lua`)
- Produces: `BisTooltip_FormatSource(entry)` returning the exact MASTER strings; `entry` shapes: `{kind="DROP",source}`, `{kind="TOKEN",tier,family,source}`, `{kind="MARK",tier,family,source}`, `{kind="VENDOR",tier,cost,displayVariant}`, `{kind="CUSTOM",label}`

- [ ] **Step 1: Write failing golden tests**

```lua
-- tools/test_formatter.lua
dofile("Bistooltip/SourceRegistry.lua") -- test-local fixture overrides globals below
BisTooltip_SourceRegistry = {
  VEZAX = { instance = "Ulduar", boss = "General Vezax", difficulty = "25N" },
  THORIM = { instance = "Ulduar", boss = "Thorim", difficulty = "25N" },
}
dofile("Bistooltip/SourceFormatter.lua")
local cases = {
  { { kind = "DROP", source = "VEZAX" }, "Ulduar [25N] - General Vezax" },
  { { kind = "TOKEN", tier = "T8", family = "Wayward Protector", source = "THORIM" },
    "T8 - TOKEN: Wayward Protector [Ulduar: Thorim <25N>]" },
  { { kind = "VENDOR", tier = "T9", cost = { { currency = "Emblem of Triumph", amount = 50 } } },
    "T9 - VENDOR: 50 Emblem of Triumph" },
  { { kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
      cost = { { item = 47242, amount = 1 }, { currency = "Emblem of Triumph", amount = 75 } } },
    "T9 - TROPHY: Crusade + 75 Emblem of Triumph" },
  { { kind = "CUSTOM", label = "VIP Shop" }, "VIP Shop" },
  { { kind = "DROP", source = "NOPE" }, nil }, -- unknown sourceID: skip line, no error
}
for i, c in ipairs(cases) do
  local got = BisTooltip_FormatSource(c[1])
  assert(got == c[2], "case " .. i .. ": got " .. tostring(got) .. ", want " .. tostring(c[2]))
end
print("formatter: OK (" .. #cases .. " cases)")
```

- [ ] **Step 2: Run to verify it fails**

Run: `lua5.1 tools/test_formatter.lua`
Expected: FAIL ("SourceFormatter.lua" missing)

- [ ] **Step 3: Implement the formatter (minimal, pure strings)**

```lua
-- Bistooltip/SourceFormatter.lua (pure; no WoW API; warn-once via local flag table)
local warned = {}
function BisTooltip_FormatSource(entry)
  if type(entry) ~= "table" or not entry.kind then return nil end
  if entry.kind == "CUSTOM" then
    if type(entry.label) == "string" and entry.label ~= "" then return entry.label end
    return nil
  end
  local reg = BisTooltip_SourceRegistry or {}
  local function costText(cost)
    local parts = {}
    for _, c in ipairs(cost or {}) do
      if c.currency then table.insert(parts, c.amount .. " " .. c.currency) end
    end
    return table.concat(parts, " + ")
  end
  if entry.kind == "VENDOR" then
    if entry.displayVariant == "TROPHY" then return (entry.tier or "T9") .. " - TROPHY: Crusade + " .. costText(entry.cost) end
    return (entry.tier or "") .. (entry.tier and " - " or "") .. "VENDOR: " .. costText(entry.cost)
  end
  local s = entry.source and reg[entry.source] or nil
  if not s then
    if entry.source and not warned[entry.source] then warned[entry.source] = true end
    return nil
  end
  if entry.kind == "DROP" then return s.instance .. " [" .. s.difficulty .. "] - " .. s.boss end
  if entry.kind == "TOKEN" or entry.kind == "MARK" then
    return entry.tier .. " - " .. entry.kind .. ": " .. entry.family
      .. " [" .. s.instance .. ": " .. s.boss .. " <" .. s.difficulty .. ">]"
  end
  return nil
end
```

(WoW-side warning print is wired in Task 5 where `DEFAULT_CHAT_FRAME` exists; the pure module only records.)

- [ ] **Step 4: Run tests**

Run: `lua5.1 tools/test_formatter.lua`
Expected: PASS with "formatter: OK (6 cases)"

- [ ] **Step 5: Commit**

```bash
git add Bistooltip/SourceFormatter.lua tools/test_formatter.lua
git commit -m "feat: MASTER source formatter with golden tests"
```

---

### Task 5: Wire into the addon, delete the old lookup

**Files:**
- Modify: `Bistooltip/Bistooltip.toc` (load `SourceRegistry.lua`, `ItemAcquisition.lua`, `SourceFormatter.lua`, `PluginAPI.lua` after `Loot_Sources.lua`/`EmblemData.lua`, before `DataProvider.lua`)
- Modify: `Bistooltip/Bistooltip.lua` (reimplement `GetItemSourceInfo` on the new model; delete `findSourceInLootTable`, `formatInstanceName` guessing, `GetInstanceDifficulty` heuristic)
- Modify: `Bistooltip/DataProvider.lua` (`GetAllItemSources` iterates `BisTooltip_ItemAcquisition[itemID]` + formatter; string-dedup identical rendered lines only)
- Modify: `Bistooltip/Core.lua` (one-time dev-warning drain for unknown sourceIDs; no cache framework)

**Interfaces:**
- Consumes: `BisTooltip_FormatSource`, `BisTooltip_SourceRegistry`, `BisTooltip_ItemAcquisition`
- Produces: unchanged public signatures — `BistooltipAddon:GetItemSourceInfo(itemId) -> zone, boss`, `BistooltipData.GetAllItemSources(itemId)` — now O(1); all existing call sites (`BislistUI.lua`, `ui/InstanceHeader.lua`, tooltip) keep working

- [ ] **Step 1: Syntax-gate all touched files (fails if Lua invalid)**

Run: `for f in Bistooltip/SourceRegistry.lua Bistooltip/ItemAcquisition.lua Bistooltip/SourceFormatter.lua Bistooltip/Bistooltip.lua Bistooltip/DataProvider.lua Bistooltip/Core.lua; do luac5.1 -p "$f" || exit 1; done && echo "syntax: OK"`
Expected: PASS (baseline before edits; re-run after every edit)

- [ ] **Step 2: Reimplement `GetItemSourceInfo` as shim (minimal)**

```lua
function BistooltipAddon:GetItemSourceInfo(itemId)
  local entries = (BisTooltip_ItemAcquisition or {})[itemId]
  local e = entries and entries[1] or nil
  if not e then return nil, nil end
  if e.kind == "DROP" or e.kind == "TOKEN" or e.kind == "MARK" then
    local s = (BisTooltip_SourceRegistry or {})[e.source]
    if s then return s.instance .. " [" .. s.difficulty .. "]", s.boss end
  end
  return nil, nil
end
```

Delete `findSourceInLootTable` (`Bistooltip.lua:426-450`), the `formatInstanceName` normalizer, and the difficulty-substring heuristic. Tooltip line rendering switches from `"[zone] - boss"` concatenation to `BisTooltip_FormatSource(entry)` per entry (multi-source = multiple lines, identical rendered lines deduped once).

- [ ] **Step 3: Re-run syntax gate + pure test suite**

Run: `for f in Bistooltip/*.lua; do luac5.1 -p "$f" || exit 1; done; lua5.1 tools/test_formatter.lua && lua5.1 tools/check_sources.lua`
Expected: PASS all three

- [ ] **Step 4: Manual in-game verification (client required)**

`/reload`, hover 3 items (normal drop, T8 token piece, T9 vendor piece), confirm MASTER strings from the spec; open `/bis`, confirm instance grouping unchanged. Record result in the commit message trailer (`Tested-In-Game: yes/no`).

- [ ] **Step 5: Commit**

```bash
git add Bistooltip/Bistooltip.toc Bistooltip/Bistooltip.lua Bistooltip/DataProvider.lua Bistooltip/Core.lua
git commit -m "feat: wire new source model into addon, remove O(N) scan and difficulty guessing"
```

---

### Task 6: 5-function plugin API

**Files:**
- Create: `Bistooltip/PluginAPI.lua`
- Create: `tools/test_pluginapi.lua`

**Interfaces:**
- Consumes: `BisTooltip_SourceRegistry`, `BisTooltip_ItemAcquisition`, `Bistooltip_bislists`, `Enhancements` table (name from census/codebase as found)
- Produces: `BisTooltip:DefineSource`, `BisTooltip:SetAcquisition`, `BisTooltip:AddAcquisition`, `BisTooltip:SetBiSSlot`, `BisTooltip:SetEnhancement` with replace-wins (all but Add), append (Add), structural validation, one-time override warnings

- [ ] **Step 1: Write failing API tests (stub core, plain lua5.1)**

```lua
-- tools/test_pluginapi.lua
dofile("Bistooltip/SourceRegistry.lua"); dofile("Bistooltip/ItemAcquisition.lua")
dofile("Bistooltip/PluginAPI.lua")
BisTooltip:DefineSource("T_SRC", { instance = "I", boss = "B", difficulty = "25N" })
BisTooltip:SetAcquisition(1, { { kind = "DROP", source = "T_SRC" } })
assert(#BisTooltip_ItemAcquisition[1] == 1, "Set must replace")
BisTooltip:AddAcquisition(1, { kind = "CUSTOM", label = "Shop" })
assert(#BisTooltip_ItemAcquisition[1] == 2, "Add must append")
local ok = pcall(BisTooltip.DefineSource, BisTooltip, "BAD", { kind = "CUSTOM", label = "" })
assert(not ok, "empty CUSTOM label must be rejected")
print("pluginapi: OK")
```

- [ ] **Step 2: Run to verify it fails**

Run: `lua5.1 tools/test_pluginapi.lua`
Expected: FAIL ("PluginAPI.lua" missing)

- [ ] **Step 3: Implement the 5 functions (minimal, validation-first)**

Replace-wins assignment for `DefineSource`/`SetAcquisition`/`SetBiSSlot`/`SetEnhancement`; `table.insert` for `AddAcquisition`; reject malformed entries (unknown kind, empty CUSTOM label, missing sourceID); warn-once string table for core overrides (`Plugin X replaced core source <ID>` — caller name via second arg or `"unknown plugin"`).

- [ ] **Step 4: Run tests**

Run: `lua5.1 tools/test_pluginapi.lua && lua5.1 tools/test_formatter.lua && lua5.1 tools/check_sources.lua`
Expected: PASS all three

- [ ] **Step 5: Commit (also wire into `.toc`)**

```bash
git add Bistooltip/PluginAPI.lua Bistooltip/Bistooltip.toc tools/test_pluginapi.lua
git commit -m "feat: 5-function server plugin API (replace-wins, validated)"
```

---

### Task 7: Full integrity audit + oracle spot-check (done gate)

**Files:**
- Modify: `tools/check_sources.lua` (final kommer: orphan-registry report, rendered-line audit)
- Modify: none in addon (audit only; fixes go through Tasks 3–6)

**Interfaces:**
- Consumes: everything from Tasks 2–6
- Produces: green audit; oracle diff report (transient, NOT committed — AtlasLoot stays out of the repo)

- [ ] **Step 1: Extend audit (orphans + render coverage)**

```lua
-- every registry entry referenced at least once, or explicitly listed as RESERVED
-- every acquisition entry renders to non-nil via BisTooltip_FormatSource, or is a known VENDOR-without-tier case
```

- [ ] **Step 2: Run the whole suite**

Run: `lua5.1 tools/test_formatter.lua && lua5.1 tools/test_pluginapi.lua && lua5.1 tools/check_sources.lua && for f in Bistooltip/*.lua tools/*.lua; do luac5.1 -p "$f" || exit 1; done`
Expected: all PASS

- [ ] **Step 3: Oracle spot-check (manual, transient)**

Download Pazzions `wrathofthelichking.lua` to `/tmp` (do NOT commit), sample 20 T7–T10 items, confirm boss agreement; record mismatches as follow-up data fixes, not as code changes. Any imported relation needs correct acquisition classification + second-source confirmation where AtlasLoot was the only witness.

- [ ] **Step 4: Commit audit**

```bash
git add tools/check_sources.lua
git commit -m "test: full source integrity audit green"
```

---

## Self-review

- **Spec coverage:** S1 model → Tasks 2,3,5; MASTER strings + TROPHY/CUSTOM/dedup/fallback rules → Task 4 (+Task 5 rendering); 5-function API + hard `Dependencies` + no queue + no cache → Task 6 (+Task 5 Core note); migration mechanics + alias normalization → Tasks 2,3; authoritative-dataset gate → Task 1; oracle-as-validation → Task 7 step 3; scanner → out of scope by design (API compatibility is the deliverable, Task 6).
- **Placeholder scan:** no TBD/TODO; every test command is an exact `lua5.1`/`luac5.1` invocation; in-game check is the only client-dependent step and is explicitly marked MANUAL with a commit-trailer convention.
- **Type consistency:** `BisTooltip_SourceRegistry`, `BisTooltip_ItemAcquisition`, `BisTooltip_FormatSource(entry)->string|nil`, `BisTooltip:{DefineSource,SetAcquisition,AddAcquisition,SetBiSSlot,SetEnhancement}` spelled identically across tasks; entry shapes `{kind,source,tier,family,cost,displayVariant,label}` stable from Task 2 through Task 6.
