-- tools/migrate_sources.lua
-- usage: lua5.1 tools/migrate_sources.lua
-- Offline migrator: lootTable + Bistooltip_emblem_items -> new source model.
-- Generates Bistooltip/SourceRegistry.lua + Bistooltip/ItemAcquisition.lua.
--
-- Canonical decisions (Task 3) live HERE so regeneration is stable. The chain is:
--   RAW aliases -> canonical dictionary (tables below) -> SourceRegistry -> FormatSource.
-- The tables are explicit encounter knowledge (offline tool); no string-guessing.
_G.FACTION_ALLIANCE = "Alliance"
_G.FACTION_HORDE = "Horde"
_G.SlashCmdList = {}
dofile("Bistooltip/Loot_Sources.lua") -- provides lootTable
dofile("Bistooltip/EmblemData.lua") -- provides Bistooltip_emblem_items
assert(type(lootTable) == "table", "lootTable missing after Loot_Sources.lua")
assert(type(Bistooltip_emblem_items) == "table", "Bistooltip_emblem_items missing after EmblemData.lua")

-- RAW zone -> canonical instance. Only zones needing rename/merge are listed;
-- default is identity. Covers heroic/normal key splits, spelling duplicates,
-- and token zones that alias a real raid encounter (same boss, same mode).
local CANON_ZONE = {
  -- 5-man heroic splits share one instance identity (mode via ZONE_DIFFICULTY)
  ["Trial of the Champion (Heroic)"] = "Trial of the Champion",
  ["The Forge of Souls (Heroic)"] = "The Forge of Souls",
  ["Pit of Saron (Heroic)"] = "Pit of Saron",
  ["Halls of Reflection (Heroic)"] = "Halls of Reflection",
  ["Utgarde keep (Heroic)"] = "Utgarde Keep",
  ["The Nexus (Heroic)"] = "The Nexus",
  ["Azjol Nerub (Heroic)"] = "Azjol-Nerub",
  ["Ahn'kahet: The Old Kingdom (Heroic)"] = "Ahn'kahet: The Old Kingdom",
  ["Drak'Tharon Keep (Heroic)"] = "Drak'Tharon Keep",
  ["The Violet Hold (Heroic)"] = "The Violet Hold",
  ["Gundrak (Heroic)"] = "Gundrak",
  ["Halls of Stone (Heroic)"] = "Halls of Stone",
  ["Halls of Lightning (Heroic)"] = "Halls of Lightning",
  ["Utgarde Pinnacle (Heroic)"] = "Utgarde Pinnacle",
  ["The Oculus (Heroic)"] = "The Oculus",
  ["Caverns of Time Old Stratholme (Heroic)"] = "Caverns of Time Old Stratholme",
  -- spelling / capitalization duplicates (proven: identical boss lists)
  ["Utgarde keep"] = "Utgarde Keep",
  -- defensive: spec's known alias; no raw key uses it today, but any future
  -- "AhnKahet" input collapses to the canonical identity instead of forking it
  ["AhnKahet"] = "Ahn'kahet: The Old Kingdom",
  ["AhnKahet (Heroic)"] = "Ahn'kahet: The Old Kingdom",
  -- token zones aliasing a real raid encounter (boss names match the raid lists)
  ["Tier 7 Tokens Naxx(10)"] = "Naxxramas",
  ["Tier 7 Tokens Naxx(25)"] = "Naxxramas",
  ["Tier 7 Tokens OS(10)"] = "Obsidian Sanctum",
  ["Tier 7 Tokens OS(25)"] = "Obsidian Sanctum",
  ["Tier 8 Tokens Ulduar(10)"] = "Ulduar",
  ["Tier 8 Tokens Ulduar(25)"] = "Ulduar",
  -- raid mode splits share one instance identity (mode via ZONE_DIFFICULTY)
  ["Naxxramas (10)"] = "Naxxramas",
  ["Naxxramas (25)"] = "Naxxramas",
  ["Obsidian Sanctum (10)"] = "Obsidian Sanctum",
  ["Obsidian Sanctum 1D(10)"] = "Obsidian Sanctum",
  ["Obsidian Sanctum 2D(10)"] = "Obsidian Sanctum",
  ["Obsidian Sanctum (25)"] = "Obsidian Sanctum",
  ["Obsidian Sanctum 1D(25)"] = "Obsidian Sanctum",
  ["Obsidian Sanctum 2D(25)"] = "Obsidian Sanctum",
  ["Eye of Eternity (10)"] = "Eye of Eternity",
  ["Eye of Eternity Q(10)"] = "Eye of Eternity",
  ["Eye of Eternity (25)"] = "Eye of Eternity",
  ["Eye of Eternity Q(25)"] = "Eye of Eternity",
  ["Onyxia's Lair (10)"] = "Onyxia's Lair",
  ["Onyxia's Lair (25)"] = "Onyxia's Lair",
  ["Ulduar (10)"] = "Ulduar",
  ["Ulduar (25)"] = "Ulduar",
  ["Ulduar HM(10)"] = "Ulduar",
  ["Ulduar HM(25)"] = "Ulduar",
  ["Trial of the Crusader (10)"] = "Trial of the Crusader",
  ["Trial of the Crusader (25)"] = "Trial of the Crusader",
  ["Trial of the Crusader (10) (Heroic)"] = "Trial of the Crusader",
  ["Trial of the Crusader (25) (Heroic)"] = "Trial of the Crusader",
  ["Icecrown Citadel (10)"] = "Icecrown Citadel",
  ["Icecrown Citadel (25)"] = "Icecrown Citadel",
  ["Icecrown Citadel (10) (Heroic)"] = "Icecrown Citadel",
  ["Icecrown Citadel (25) (Heroic)"] = "Icecrown Citadel",
  ["Ruby Sanctum (10)"] = "Ruby Sanctum",
  ["Ruby Sanctum (25)"] = "Ruby Sanctum",
  ["Ruby Sanctum (10) (Heroic)"] = "Ruby Sanctum",
  ["Ruby Sanctum (25) (Heroic)"] = "Ruby Sanctum",
}

-- Mark/tribute turn-in families name one raid mode and share one boss each
-- (verified uniform: 19x "Tribute Chest", 19x "Mark", 19x "Mark HC"), so each
-- family collapses to a single raid turn-in identity instead of 19 fake zones.
-- (Tier 9 / Tier 10 emblem zones name MULTIPLE sources, so they keep zone
-- identities with "" difficulty; reclassification is Task 5/6 territory.)
local function canonInstance(zone)
  local inst = CANON_ZONE[zone]
  if inst then return inst end
  if zone:sub(1, 8) == "Tier 9.5" then return "Trial of the Crusader" end
  if zone:sub(1, 8) == "Tier 10N" then return "Icecrown Citadel" end
  if zone:sub(1, 9) == "Tier 10HC" then return "Icecrown Citadel" end
  return zone
end

-- RAW boss -> canonical boss. Only proven duplicates (brief-mandated Taldaram
-- plus data-proven Anubarak 4-vs-2 and Trash Mobs 12-vs-21 majority spellings).
local BOSS_ALIASES = {
  ["Taldaram"] = "Prince Taldaram",
  ["Anubarak"] = "Anub'arak",
  ["Trash Mobs"] = "Trash mobs",
}

-- Explicit RAW zone -> difficulty. Closed fact set: 10N/25N/10HC/25HC for raids,
-- H for 5-man heroics; anything unlisted (world/vendor/events/rep/PvP/single-mode
-- 5-man normals, multi-source emblem zones) stays "" per frozen spec S2.
-- Ulduar HM = hard modes, the WotLK heroic-equivalent (flagged decision).
local ZONE_DIFFICULTY = {
  ["Naxxramas (10)"] = "10N",
  ["Naxxramas (25)"] = "25N",
  ["Obsidian Sanctum (10)"] = "10N",
  ["Obsidian Sanctum 1D(10)"] = "10N",
  ["Obsidian Sanctum 2D(10)"] = "10N",
  ["Obsidian Sanctum (25)"] = "25N",
  ["Obsidian Sanctum 1D(25)"] = "25N",
  ["Obsidian Sanctum 2D(25)"] = "25N",
  ["Eye of Eternity (10)"] = "10N",
  ["Eye of Eternity Q(10)"] = "10N",
  ["Eye of Eternity (25)"] = "25N",
  ["Eye of Eternity Q(25)"] = "25N",
  ["Onyxia's Lair (10)"] = "10N",
  ["Onyxia's Lair (25)"] = "25N",
  ["Ulduar (10)"] = "10N",
  ["Ulduar (25)"] = "25N",
  ["Ulduar HM(10)"] = "10HC",
  ["Ulduar HM(25)"] = "25HC",
  ["Trial of the Crusader (10)"] = "10N",
  ["Trial of the Crusader (25)"] = "25N",
  ["Trial of the Crusader (10) (Heroic)"] = "10HC",
  ["Trial of the Crusader (25) (Heroic)"] = "25HC",
  ["Icecrown Citadel (10)"] = "10N",
  ["Icecrown Citadel (25)"] = "25N",
  ["Icecrown Citadel (10) (Heroic)"] = "10HC",
  ["Icecrown Citadel (25) (Heroic)"] = "25HC",
  ["Ruby Sanctum (10)"] = "10N",
  ["Ruby Sanctum (25)"] = "25N",
  ["Ruby Sanctum (10) (Heroic)"] = "10HC",
  ["Ruby Sanctum (25) (Heroic)"] = "25HC",
  ["Trial of the Champion (Heroic)"] = "H",
  ["The Forge of Souls (Heroic)"] = "H",
  ["Pit of Saron (Heroic)"] = "H",
  ["Halls of Reflection (Heroic)"] = "H",
  ["Utgarde keep (Heroic)"] = "H",
  ["The Nexus (Heroic)"] = "H",
  ["Azjol Nerub (Heroic)"] = "H",
  ["Ahn'kahet: The Old Kingdom (Heroic)"] = "H",
  ["Drak'Tharon Keep (Heroic)"] = "H",
  ["The Violet Hold (Heroic)"] = "H",
  ["Gundrak (Heroic)"] = "H",
  ["Halls of Stone (Heroic)"] = "H",
  ["Halls of Lightning (Heroic)"] = "H",
  ["Utgarde Pinnacle (Heroic)"] = "H",
  ["The Oculus (Heroic)"] = "H",
  ["Caverns of Time Old Stratholme (Heroic)"] = "H",
  ["Tier 7 Tokens Naxx(10)"] = "10N",
  ["Tier 7 Tokens OS(10)"] = "10N",
  ["Tier 7 Tokens Naxx(25)"] = "25N",
  ["Tier 7 Tokens OS(25)"] = "25N",
  ["Tier 8 Tokens Ulduar(10)"] = "10N",
  ["Tier 8 Tokens Ulduar(25)"] = "25N",
}

-- Drake-count variants share instance/boss/difficulty with the base Sanctum kill
-- (closed set has no drake code), so they need an ID suffix to avoid collision.
local SOURCE_SUFFIX = {
  ["Obsidian Sanctum 1D(10)"] = "1D",
  ["Obsidian Sanctum 2D(10)"] = "2D",
  ["Obsidian Sanctum 1D(25)"] = "1D",
  ["Obsidian Sanctum 2D(25)"] = "2D",
}

local function difficultyOf(zone)
  local d = ZONE_DIFFICULTY[zone]
  if d then return d end
  -- Tier 9.5 / Tier 10N / Tier 10HC families are fully mechanical zone shapes
  -- ("Tier 9.5 <spec> ToC(25HC) ", "Tier 10N <spec> ICC(25)", ...); fixed mode each.
  if zone:sub(1, 8) == "Tier 9.5" then return "25HC" end
  if zone:sub(1, 9) == "Tier 10HC" then return "25HC" end
  if zone:sub(1, 8) == "Tier 10N" then return "25N" end
  return ""
end

-- Emblem currency -> tier, ONLY where provable from the repo: the
-- "Tier 9 ... (HC5, Raids25)" zones pair Emblem of Triumph with T9 and the
-- "Tier 10 ... (HC5 Dialy, ICC10/25)" zones pair Emblem of Frost with T10.
-- Conquest/Valor/Heroism/Ascension stay tier-less (unprovable; no guessing).
local VENDOR_TIER = {
  ["Emblem of Triumph"] = "T9",
  ["Emblem of Frost"] = "T10",
}

-- T9-245 (ilvl 245 tier, bought for trophy + triumph): exactly the items listed
-- under the "Tier 9.25 * ToC(25)" zones. Verified: those 190 IDs occur NOWHERE
-- else in Loot_Sources.lua and have no EmblemData entry, so no per-item triumph
-- price is provable from the repo. TROPHY stays display-only, never a new kind.
local TROPHY_ITEM = 47242 -- Trophy of the Crusade
-- FLAGGED GUESS: single fallback triumph amount for all TROPHY items
-- (repo-attested Triumph chest price, e.g. TRIUMPH_ITEMS chest=50).
-- Per-slot prices need oracle verification (Task 5/6); one constant to refine.
local TROPHY_TRIUMPH_FALLBACK = 50

local function isTrophyZone(zone)
  return zone:sub(1, 10) == "Tier 9.25 "
end

local registry, acquisition = {}, {}
local nTrophy, nDeduped = 0, 0
local function sourceID(inst, diff, boss)
  return ((inst .. "_" .. (diff or "") .. "_" .. boss):gsub("[^%w]+", "_"):gsub("_+", "_"):upper())
end
local function addEntry(itemID, entry)
  if type(itemID) ~= "number" or itemID <= 0 then return end
  acquisition[itemID] = acquisition[itemID] or {}
  table.insert(acquisition[itemID], entry)
end

for zone, bosses in pairs(lootTable) do
  if isTrophyZone(zone) then
    -- fake zone (not a real place): no registry identity; vendor TROPHY instead
    for _, items in pairs(bosses) do
      for _, itemID in pairs(items) do
        local emb = Bistooltip_emblem_items[itemID]
        local triumph = TROPHY_TRIUMPH_FALLBACK
        if emb and emb.currency == "Emblem of Triumph" then triumph = emb.cost end
        addEntry(itemID, { kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
          cost = { { item = TROPHY_ITEM, amount = 1 },
                   { currency = "Emblem of Triumph", amount = triumph } } })
        nTrophy = nTrophy + 1
      end
    end
  else
    local inst = canonInstance(zone)
    local diff = difficultyOf(zone)
    local suffix = SOURCE_SUFFIX[zone] or ""
    for boss, items in pairs(bosses) do
      local cboss = BOSS_ALIASES[boss] or boss
      local id = sourceID(inst, diff, cboss)
      if suffix ~= "" then id = id .. "_" .. suffix end
      registry[id] = registry[id] or { instance = inst, boss = cboss, difficulty = diff }
      for _, itemID in pairs(items) do
        addEntry(itemID, { kind = "DROP", source = id })
      end
    end
  end
end
-- emblem items -> VENDOR entries (tier only where provable, see VENDOR_TIER)
for itemID, e in pairs(Bistooltip_emblem_items or {}) do
  local entry = { kind = "VENDOR", cost = { { currency = e.currency, amount = e.cost } } }
  if VENDOR_TIER[e.currency] then entry.tier = VENDOR_TIER[e.currency] end
  addEntry(itemID, entry)
end

-- dedup: collapse byte-identical entries per item; distinct bosses stay separate
local function entryKey(e)
  if e.kind == "DROP" then return "DROP\0" .. e.source end
  local parts = { e.kind or "", e.tier or "", e.displayVariant or "" }
  for _, c in ipairs(e.cost or {}) do
    parts[#parts + 1] = (c.currency or "") .. "#" .. (c.item or 0) .. "#" .. (c.amount or 0)
  end
  return table.concat(parts, "\0")
end
for itemID, list in pairs(acquisition) do
  local seen, kept = {}, {}
  for _, e in ipairs(list) do
    local k = entryKey(e)
    if seen[k] then
      nDeduped = nDeduped + 1
    else
      seen[k] = true
      kept[#kept + 1] = e
    end
  end
  acquisition[itemID] = kept
end

-- serializer: sorted keys, %q strings, numbers only, no external deps
local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

local HEADER = "-- Generated by tools/migrate_sources.lua - do not edit by hand.\n"

local function writeRegistry(path)
  local f = assert(io.open(path, "w"))
  f:write(HEADER)
  f:write("BisTooltip_SourceRegistry = {\n")
  for _, id in ipairs(sortedKeys(registry)) do
    local r = registry[id]
    f:write(string.format("  [%q] = { instance = %q, boss = %q, difficulty = %q },\n",
      id, r.instance, r.boss, r.difficulty))
  end
  f:write("}\nreturn BisTooltip_SourceRegistry\n")
  f:close()
end

local function writeCost(f, cost)
  f:write("{ ")
  for i, c in ipairs(cost) do
    if i > 1 then f:write(", ") end
    if c.item then
      f:write(string.format("{ item = %d, amount = %d }", c.item, c.amount))
    else
      f:write(string.format("{ currency = %q, amount = %d }", c.currency, c.amount))
    end
  end
  f:write(" }")
end

local function writeAcquisition(path)
  local f = assert(io.open(path, "w"))
  f:write(HEADER)
  f:write("BisTooltip_ItemAcquisition = {\n")
  for _, itemID in ipairs(sortedKeys(acquisition)) do
    f:write(string.format("  [%d] = {\n", itemID))
    for _, e in ipairs(acquisition[itemID]) do
      if e.kind == "DROP" then
        f:write(string.format("    { kind = %q, source = %q },\n", e.kind, e.source))
      else -- VENDOR (optional tier / displayVariant, N-leg cost)
        local extra = ""
        if e.tier then extra = extra .. string.format(", tier = %q", e.tier) end
        if e.displayVariant then extra = extra .. string.format(", displayVariant = %q", e.displayVariant) end
        f:write(string.format("    { kind = %q%s, cost = ", e.kind, extra))
        writeCost(f, e.cost)
        f:write(" },\n")
      end
    end
    f:write("  },\n")
  end
  f:write("}\nreturn BisTooltip_ItemAcquisition\n")
  f:close()
end

writeRegistry("Bistooltip/SourceRegistry.lua")
writeAcquisition("Bistooltip/ItemAcquisition.lua")

local nreg, nacq = 0, 0
for _ in pairs(registry) do nreg = nreg + 1 end
for _ in pairs(acquisition) do nacq = nacq + 1 end
print(string.format("migrated: %d sources, %d items (%d TROPHY entries, %d deduped)",
  nreg, nacq, nTrophy, nDeduped))
