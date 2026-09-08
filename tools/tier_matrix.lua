-- tools/tier_matrix.lua — committed tier facts for the migrator post-pass.
-- Provenance: Pazzions AtlasLoot oracle v5.11.04 (wrathofthelichking.lua),
-- downloaded transiently on 2026-09-08 (GPLv2, never committed; spec S4-2).
-- Relations cross-checked against WotLK lockout rules where possible.
--
-- Oracle anomalies (deliberate handling):
--  * ICC 10HC pages list normal marks — EXCLUDED here: single witness,
--    contradicts 10/25 mark lockouts (10-man ICC drops no marks).
--  * ICC 25HC pages list BOTH normal and heroic marks — INCLUDED as-is
--    (matches common private-server behaviour; owner plays private servers).
--
-- Class groups are the standard T7-T10 token families (verify in-game once;
-- the turn-in vendor groups classes identically across tiers).

local M = {}

-- class (as spelled in "Tier 10N <Class> ..." input zones) -> token family
M.CLASS_FAMILY = {
  Warrior = "Protector", Hunter = "Protector", Shaman = "Protector",
  Paladin = "Conqueror", Priest = "Conqueror", Warlock = "Conqueror",
  Rogue = "Vanquisher", DK = "Vanquisher", Mage = "Vanquisher", Druid = "Vanquisher",
}

-- T10 mark-dropping bosses (oracle: Saurfang/Putricide/Lanathel/
-- Sindragosa/LichKing 25Man + 25ManHEROIC pages; no other ICC boss
-- carries Mark of Sanctification rows)
M.ICC_MARK_BOSSES = {
  "Deathbringer Saurfang",
  "Professor Putricide",
  "Blood Queen Lana'thel",
  "Sindragosa",
  "The Lich King",
}

-- Mark of Sanctification items: id -> {family, heroic}
M.MARKS = {
  [52025] = { family = "Vanquisher", heroic = false },
  [52026] = { family = "Protector",  heroic = false },
  [52027] = { family = "Conqueror",  heroic = false },
  [52028] = { family = "Vanquisher", heroic = true },
  [52029] = { family = "Protector",  heroic = true },
  [52030] = { family = "Conqueror",  heroic = true },
}

-- Boss-tied quest rewards (owner rule 2026-09-08): render "<Boss> [Quest]"
-- as a DROP from a dedicated source, difficulty per the quest's lockout.
-- 45614 Starshine Circle: oracle page UlduarAlgalon25Man (finger, 25-man).
M.QUEST_DROPS = {
  [45614] = { instance = "Ulduar", boss = "Algalon [Quest]", difficulty = "25N" },
}

return M
