-- tools/check_sources.lua (part 1; extended in Task 7)
local reg = dofile("Bistooltip/SourceRegistry.lua")
local acq = dofile("Bistooltip/ItemAcquisition.lua")
assert(type(reg) == "table" and type(acq) == "table", "generated files must return tables")
local n = 0 for _ in pairs(acq) do n = n + 1 end
assert(n > 1000, "expected >1000 acquired items, got " .. n)
for id, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    if e.source then assert(reg[e.source], "dangling sourceID " .. tostring(e.source) .. " on item " .. id) end
    -- R5-A: DROP entries may carry an optional tier stamp (ex-Tier-zone origin)
    if e.kind == "DROP" and e.tier ~= nil then
      assert(type(e.tier) == "string" and e.tier ~= "", "DROP with bad tier on item " .. id)
    end
  end
end
print("smoke: OK (" .. n .. " items)")

-- canonical audit (Task 3): closed difficulty set, alias guards, TROPHY shape.
-- NOTE: brief draft asserted difficulty ~= "" for ALL sources; frozen spec S2
-- allows empty ONLY for world/vendor (and single-mode 5-man normals, which carry
-- no mode qualifier). The audit below enforces exactly that instead.
local DIFF_OK = { ["10N"] = true, ["25N"] = true, ["10HC"] = true, ["25HC"] = true, H = true, [""] = true }
local RAIDS = { -- canonical instance -> must carry a raid-mode difficulty
  ["Naxxramas"] = true, ["Obsidian Sanctum"] = true, ["Eye of Eternity"] = true,
  ["Onyxia's Lair"] = true, ["Ulduar"] = true, ["Trial of the Crusader"] = true,
  ["Icecrown Citadel"] = true, ["Ruby Sanctum"] = true,
}
local DUNGEONS = { -- 5-mans: normal ("") or heroic ("H") only
  ["Trial of the Champion"] = true, ["The Forge of Souls"] = true, ["Pit of Saron"] = true,
  ["Halls of Reflection"] = true, ["Utgarde Keep"] = true, ["The Nexus"] = true,
  ["Azjol-Nerub"] = true, ["Ahn'kahet: The Old Kingdom"] = true, ["Drak'Tharon Keep"] = true,
  ["The Violet Hold"] = true, ["Gundrak"] = true, ["Halls of Stone"] = true,
  ["Halls of Lightning"] = true, ["Utgarde Pinnacle"] = true, ["The Oculus"] = true,
  ["Caverns of Time Old Stratholme"] = true,
}
local function isRaidDiff(d)
  return d == "10N" or d == "25N" or d == "10HC" or d == "25HC"
end
for sid, s in pairs(reg) do
  assert(DIFF_OK[s.difficulty], "source with unknown difficulty: " .. sid)
  assert((s.instance and s.boss) or s.custom, "source without identity: " .. sid)
  assert(s.instance ~= "AhnKahet", "unmerged alias AhnKahet: " .. sid)
  assert(s.instance ~= "Azjol Nerub", "unmerged alias 'Azjol Nerub': " .. sid)
  assert(s.instance ~= "Utgarde keep", "unnormalized instance 'Utgarde keep': " .. sid)
  assert(s.boss ~= "Anubarak", "unmerged boss alias Anubarak: " .. sid)
  assert(s.boss ~= "Taldaram", "unmerged boss alias Taldaram: " .. sid)
  assert(s.boss ~= "Trash Mobs", "unmerged boss alias Trash Mobs: " .. sid)
  if RAIDS[s.instance] then
    assert(isRaidDiff(s.difficulty), "raid source without raid difficulty: " .. sid)
  elseif DUNGEONS[s.instance] then
    assert(s.difficulty == "" or s.difficulty == "H", "dungeon source with raid difficulty: " .. sid)
  end
  -- collapsed/merged fake zones must never resurface as registry identities
  -- (instance-less CUSTOM-kind rows carry no zone identity; skip the prefix probe)
  local inst = s.instance or ""
  assert(inst:sub(1, 10) ~= "Tier 9.25 ", "leaked Tier 9.25 identity: " .. sid)
  assert(inst:sub(1, 8) ~= "Tier 9.5", "leaked Tier 9.5 identity: " .. sid)
  assert(inst:sub(1, 8) ~= "Tier 10N", "leaked Tier 10N identity: " .. sid)
  assert(inst:sub(1, 9) ~= "Tier 10HC", "leaked Tier 10HC identity: " .. sid)
  assert(inst:sub(1, 13) ~= "Tier 7 Tokens", "leaked Tier 7 identity: " .. sid)
  assert(inst:sub(1, 13) ~= "Tier 8 Tokens", "leaked Tier 8 identity: " .. sid)
end
-- alias guard: known duplicate spellings must not both exist
assert(not (reg["AHN_KAHET_TALDARAM"] and reg["AHN_KAHET_THE_OLD_KINGDOM_TALDARAM"]),
  "duplicate Ahn'kahet identity")
-- spot-checks: known canonical identities resolve to expected difficulties
local function has(instance, boss, difficulty)
  for _, s in pairs(reg) do
    if s.instance == instance and s.boss == boss and s.difficulty == difficulty then return true end
  end
  return false
end
assert(has("Icecrown Citadel", "Lord Marrowgar", "25HC"), "missing ICC 25HC Marrowgar")
assert(has("Naxxramas", "Kel'Thuzad", "10N"), "missing Naxx 10N Kel'Thuzad")
assert(has("Trial of the Champion", "The Black Knight", "H"), "missing ToC5 heroic identity")
assert(has("Ahn'kahet: The Old Kingdom", "Prince Taldaram", "H"), "missing Ahn'kahet H Prince Taldaram")
assert(has("Azjol-Nerub", "Anub'arak", "H"), "missing Azjol-Nerub H Anub'arak")
assert(has("World Drops", "Level 80", ""), "missing World Drops identity")
-- TROPHY shape: display-only variant of VENDOR T9 with trophy+currency cost
local nTrophy = 0
for id, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    if e.displayVariant == "TROPHY" then
      nTrophy = nTrophy + 1
      assert(e.kind == "VENDOR", "TROPHY must stay kind=VENDOR on item " .. id)
      assert(e.tier == "T9", "TROPHY must carry tier=T9 on item " .. id)
      local hasTrophy, hasCurrency = false, false
      for _, c in ipairs(e.cost or {}) do
        if c.item == 47242 and c.amount == 1 then hasTrophy = true end
        if c.currency == "Emblem of Triumph" then hasCurrency = true end
      end
      assert(hasTrophy and hasCurrency, "TROPHY cost must be {item=47242}+{Emblem of Triumph} on item " .. id)
    end
  end
end
assert(nTrophy > 0, "expected T9-245 TROPHY entries, found none")
print("canonical: OK (" .. nTrophy .. " TROPHY entries)")

-- Task 7 final audit: orphan-registry report + rendered-line coverage.
-- (1) Orphan report: every source referenced at least once, or RESERVED below.
-- RESERVED = migrator artifacts from EMPTY raw boss lists (verified 2026-09-07:
-- each of these 29 zone/boss pairs holds zero items in Loot_Sources.lua, yet the
-- migrator emits one registry identity per pair). Empty normal-mode bosses whose
-- heroic twin carries the loot (Amanitar, Eck), empty Ulduar-HM identities,
-- empty reputation standings, one empty heroic trash identity. Any NEW orphan
-- fails; any RESERVED entry that gains a reference fails as a stale listing.
local RESERVED = {
  ["AHN_KAHET_THE_OLD_KINGDOM_AMANITAR"] = true,
  ["ALLIANCE_VANGUARD_FRIENDLY"] = true,
  ["ALLIANCE_VANGUARD_HONORED"] = true,
  ["ARGENT_CRUSADE_FRIENDLY"] = true,
  ["AZJOL_NERUB_H_TRASH_MOBS"] = true,
  ["GUNDRAK_ECK"] = true,
  ["KIRIN_TOR_FRIENDLY"] = true,
  ["KNIGHTS_OF_THE_EBON_BLADE_FRIENDLY"] = true,
  ["THE_HORDE_EXPEDITION_FRIENDLY"] = true,
  ["THE_HORDE_EXPEDITION_HONORED"] = true,
  ["THE_KALU_AK_FRIENDLY"] = true,
  ["THE_ORACLES_EXALTED"] = true,
  ["THE_ORACLES_FRIENDLY"] = true,
  ["THE_ORACLES_HONORED"] = true,
  ["THE_SONS_OF_HODIR_FRIENDLY"] = true,
  ["THE_WYRMREST_ACCORD_FRIENDLY"] = true,
  ["ULDUAR_10HC_ALGALON"] = true,
  ["ULDUAR_10HC_AURIAYA"] = true,
  ["ULDUAR_10HC_IGNIS"] = true,
  ["ULDUAR_10HC_KOLOGARN"] = true,
  ["ULDUAR_10HC_RAZORSCALE"] = true,
  ["ULDUAR_25HC_ALGALON"] = true,
  ["ULDUAR_25HC_AURIAYA"] = true,
  ["ULDUAR_25HC_IGNIS"] = true,
  ["ULDUAR_25HC_KOLOGARN"] = true,
  ["ULDUAR_25HC_RAZORSCALE"] = true,
  ["WINTERFINRETREAT_EXALTED"] = true,
  ["WINTERFINRETREAT_HONORED"] = true,
  ["WINTERFINRETREAT_REVERED"] = true,
}
local refCount = {}
for _, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    if e.source then refCount[e.source] = (refCount[e.source] or 0) + 1 end
  end
end
local nReserved, nUnlisted = 0, 0
for sid in pairs(reg) do
  if not refCount[sid] then
    if RESERVED[sid] then
      nReserved = nReserved + 1
    else
      nUnlisted = nUnlisted + 1
      print("UNLISTED ORPHAN: " .. sid)
    end
  end
end
for sid in pairs(RESERVED) do
  assert(reg[sid], "stale RESERVED listing (left the registry): " .. sid)
  assert(not refCount[sid], "stale RESERVED listing (now referenced, prune it): " .. sid)
end
assert(nUnlisted == 0, "found " .. nUnlisted .. " unlisted orphan sources")
print("orphans: OK (" .. nReserved .. " RESERVED empty-list artifacts, 0 unlisted)")

-- (2) Rendered-line coverage: EVERY acquisition entry must render to a
-- non-empty string via the MASTER formatter (all 8820 entries, incl.
-- tier-stamped DROPs and VENDOR/TROPHY shapes). VENDOR-without-tier renders
-- as "VENDOR: ..." (tier prefix omitted), never nil -- no exception needed.
BisTooltip_SourceRegistry = reg
dofile("Bistooltip/SourceFormatter.lua")
local nEntries, nTierDrop, nVendorPlain, nTrophyRender = 0, 0, 0, 0
local nNil = 0
for id, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    nEntries = nEntries + 1
    if e.kind == "DROP" and e.tier then nTierDrop = nTierDrop + 1 end
    if e.kind == "VENDOR" and e.displayVariant ~= "TROPHY" then nVendorPlain = nVendorPlain + 1 end
    if e.displayVariant == "TROPHY" then nTrophyRender = nTrophyRender + 1 end
    local s = BisTooltip_FormatSource(e)
    if type(s) ~= "string" or s == "" then
      nNil = nNil + 1
      if nNil <= 10 then
        print("UNRENDERABLE: item " .. id .. " kind=" .. tostring(e.kind)
          .. " source=" .. tostring(e.source) .. " tier=" .. tostring(e.tier))
      end
    end
  end
end
assert(nNil == 0, "found " .. nNil .. " unrenderable entries of " .. nEntries)
print("render: OK (" .. nEntries .. " entries: " .. nTierDrop .. " tier-stamped DROP, "
  .. nVendorPlain .. " plain VENDOR, " .. nTrophyRender .. " TROPHY, 0 unrenderable)")

-- (3) CUSTOM synthetic: zero real CUSTOM entries exist today, so cover the
-- shape synthetically exactly the way the formatter goldens do.
assert(BisTooltip_FormatSource({ kind = "CUSTOM", label = "VIP Shop" }) == "VIP Shop",
  "CUSTOM label must render verbatim")
assert(BisTooltip_FormatSource({ kind = "CUSTOM", label = "" }) == nil,
  "empty CUSTOM label must not render")
assert(BisTooltip_FormatSource({ kind = "BOGUS", source = "NOPE" }) == nil,
  "unknown kind must not render")
print("custom: OK (synthetic, 0 real CUSTOM entries in data)")

-- (4) R4 TROPHY price lock: oracle-verified per-item Triumph amounts only.
-- Flat-50 fallback is gone; every TROPHY cost must be 45 (shoulder/hands) or
-- 75 (head/chest/legs), and both prices must occur (guards a one-sided slip).
local n45, n75, nOther = 0, 0, 0
for id, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    if e.displayVariant == "TROPHY" then
      for _, c in ipairs(e.cost or {}) do
        if c.currency == "Emblem of Triumph" then
          if c.amount == 45 then n45 = n45 + 1
          elseif c.amount == 75 then n75 = n75 + 1
          else nOther = nOther + 1 end
        end
      end
    end
  end
end
assert(nOther == 0, "TROPHY with non-oracle Triumph amount: " .. nOther)
assert(n45 == 76 and n75 == 114, "TROPHY price split drifted (45x" .. n45 .. " 75x" .. n75 .. ", want 45x76 75x114)")
print("trophy-prices: OK (45x" .. n45 .. " 75x" .. n75 .. ", oracle-verified, no fallback)")
