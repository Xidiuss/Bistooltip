-- Additional acquisition facts verified by the owner on 2026-09-20.
-- The exchange target is bought from Yrma with BOTH the precursor and Sunmote.
-- Bosses below drop precursors, never the exchange targets.
local precursors = {
  [34180] = { boss = "Brutallus", npcId = 24882 },
  [34188] = { boss = "Felmyst", npcId = 25038 },
  [34170] = { boss = "Sathrovarr the Corruptor", npcId = 24892 },
  [34192] = { boss = "Grand Warlock Alythess / Lady Sacrolash", npcIds = {25166, 25165} },
  [34193] = { boss = "Grand Warlock Alythess / Lady Sacrolash", npcIds = {25166, 25165} },
  [34208] = { boss = "Grand Warlock Alythess / Lady Sacrolash", npcIds = {25166, 25165} },
  [34195] = { boss = "Grand Warlock Alythess / Lady Sacrolash", npcIds = {25166, 25165} },
  [34215] = { boss = "Entropius", npcId = 25840 },
  [34229] = { boss = "Entropius", npcId = 25840 },
  [34211] = { boss = "Entropius", npcId = 25840 },
  [34212] = { boss = "Entropius", npcId = 25840 },
  [34233] = { boss = "Entropius", npcId = 25840 },
  [34345] = { boss = "Kil'jaeden", npcId = 25315 },
  [34243] = { boss = "Kil'jaeden", npcId = 25315 },
  [34244] = { boss = "Kil'jaeden", npcId = 25315 },
  [34342] = { boss = "Kil'jaeden", npcId = 25315 },
  [34234] = { boss = "Entropius", npcId = 25840 },
}

for precursorID, fact in pairs(precursors) do
  local key = "OWNER_VERIFIED_PRECURSOR_" .. precursorID
  if not BisTooltip_ItemAcquisition[precursorID] then
    BisTooltip_SourceRegistry[key] = {
      instance = "Sunwell Plateau", boss = fact.boss, difficulty = "25N",
      npcId = fact.npcId, npcIds = fact.npcIds,
    }
    BisTooltip_ItemAcquisition[precursorID] = { { kind = "DROP", source = key } }
  end
end
-- The original handoff named only Alythess; the owner confirmed both twins.
BisTooltip_SourceRegistry["USER_VERIFIED_34195"].boss = precursors[34195].boss
BisTooltip_SourceRegistry["USER_VERIFIED_34195"].npcIds = precursors[34195].npcIds

local exchanges = {
  [34381]=34180, [34385]=34188, [34386]=34170, [34388]=34192,
  [34389]=34193, [34390]=34208, [34392]=34195, [34394]=34215,
  [34396]=34229, [34397]=34211, [34398]=34212, [34399]=34233,
  [34400]=34345, [34401]=34243, [34404]=34244, [34406]=34342,
  [34408]=34234,
}
for targetID, precursorID in pairs(exchanges) do
  BisTooltip_ItemAcquisition[targetID] = { {
    kind = "VENDOR", tier = "Yrma exchange", cost = {
      { item = precursorID, amount = 1 }, { item = 34664, amount = 1 },
    },
  } }
end

-- 43792 is unobtainable and is deliberately not assigned an acquisition.
BisTooltip_ItemAcquisition[37761] = {
  { kind = "ACTIVITY", label = "World drop: elite and ordinary mobs" },
}
BisTooltip_ItemAcquisition[43573] = {
  { kind = "ACTIVITY", label = "Drop: Nascent Val'kyr (NPC 29570)" },
}

-- Horde counterpart IDs and the same prices already exist in the base table.
-- The historical faction mapping converts the Alliance IDs below to Horde.
local allianceTriumphPrices = {
  [47674]=75, [47677]=75, [47689]=75, [47690]=75,
  [47693]=75, [47694]=75, [47702]=45, [47704]=45,
  [47713]=45, [47715]=45,
}
for itemID, amount in pairs(allianceTriumphPrices) do
  BisTooltip_ItemAcquisition[itemID] = { {
    kind = "VENDOR", cost = {
      { currency = "Emblem of Triumph", item = 47241, amount = amount },
    },
  } }
end
