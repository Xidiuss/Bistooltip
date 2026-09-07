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
  assert(s.instance:sub(1, 10) ~= "Tier 9.25 ", "leaked Tier 9.25 identity: " .. sid)
  assert(s.instance:sub(1, 8) ~= "Tier 9.5", "leaked Tier 9.5 identity: " .. sid)
  assert(s.instance:sub(1, 8) ~= "Tier 10N", "leaked Tier 10N identity: " .. sid)
  assert(s.instance:sub(1, 9) ~= "Tier 10HC", "leaked Tier 10HC identity: " .. sid)
  assert(s.instance:sub(1, 13) ~= "Tier 7 Tokens", "leaked Tier 7 identity: " .. sid)
  assert(s.instance:sub(1, 13) ~= "Tier 8 Tokens", "leaked Tier 8 identity: " .. sid)
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
