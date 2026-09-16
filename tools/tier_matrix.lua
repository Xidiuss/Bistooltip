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
  "Saurfang",
  "Putricide",
  "BQ Lana'thel",
  "Sindragosa",
  "Lich King",
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

-- Owner short-form boss names (2026-09-15 cosmetics pass). Applied by the
-- migrator at registry-build time so every source line uses them.
M.BOSS_SHORT = {
  -- Naxxramas
  ["Grand Widow Faerlina"] = "Faerlina",
  ["Instructor Razuvious"] = "Razuvious",
  ["Gothik the Harvester"] = "Gothik",
  ["The Four Horsemen"] = "4Horsemen",
  ["Noth the Plaguebringer"] = "Noth",
  ["Heigan the Unclean"] = "Heigan",
  -- VoA
  ["Archavon the Stone Watcher"] = "Archavon",
  ["Emalon the Storm Watcher"] = "Emalon",
  ["Koralon the Flame Watcher"] = "Koralon",
  ["Toravon the Ice Watcher"] = "Toravon",
  -- Ulduar
  ["Flame Leviathan"] = "Leviathan",
  ["Ignis the Furnace Master"] = "Ignis",
  ["Lord Marrowgar"] = "Marrowgar",
  ["Lady Deathwhisper"] = "Lady",
  ["XT-002 Deconstructor"] = "XT",
  ["Assembly of Iron"] = "Assembly",
  ["General Vezax"] = "Vezax",
  ["Yogg-Saron"] = "Yogg",
  ["Algalon the Observer"] = "Algalon",
  -- TOC / TOGC
  ["Beasts of Northrend"] = "Beasts",
  ["Lord Jaraxxus"] = "Jaraxxus",
  ["Faction Champions"] = "Champions",
  ["Twin Val'kyr"] = "Twins",
  -- ICC
  ["Gunship Battle"] = "Gunship",
  ["Deathbringer Saurfang"] = "Saurfang",
  ["Professor Putricide"] = "Putricide",
  ["Blood Prince Council"] = "BP Council",
  ["Blood-Queen Lana'thel"] = "BQ Lana'thel",
  ["Valithria Dreamwalker"] = "Valithria",
  ["The Lich King"] = "Lich King",
}

-- T7 "Lost" set: which bosses drop which token slot (oracle: Naxx80 pages +
-- Sartharion; hands from Sartharion, legs chest Gluth/Noth/Heigan/Thaddius/
-- 4Horsemen, shoulders Loatheb, heads Kel'Thuzad).
-- T8 "Wayward" set: Ulduar bosses (oracle: Freya/Hodir/Mimiron/Thorim/Yogg
-- pages — chest Yogg+Hodir? per oracle rows below in TOKEN_DROPS).
-- Shape: [itemID] = { tier, family, slot, sources = { {instance, bossPage, diff}, ... } }
-- slot derived from the token name prefix at build time; we list pages only.
M.TOKEN_PAGES = {
  -- T7 hands (10: 40613-15 @ Sartharion10; 25: 40628-30 @ Sartharion25)
  [40613] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Obsidian Sanctum", "Sartharion", "10N" } } },
  [40614] = { tier = "T7", family = "Lost Protector",  pages = { { "Obsidian Sanctum", "Sartharion", "10N" } } },
  [40615] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Obsidian Sanctum", "Sartharion", "10N" } } },
  [40628] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Obsidian Sanctum", "Sartharion", "25N" } } },
  [40629] = { tier = "T7", family = "Lost Protector",  pages = { { "Obsidian Sanctum", "Sartharion", "25N" } } },
  [40630] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Obsidian Sanctum", "Sartharion", "25N" } } },
  -- T7 legs (10: Gluth/Noth/Heigan 40619-21; 25: Gluth/Thaddius/4H 40634-36)
  [40619] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Gluth", "10N" }, { "Naxxramas", "Noth", "10N" }, { "Naxxramas", "Heigan", "10N" } } },
  [40620] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Gluth", "10N" }, { "Naxxramas", "Noth", "10N" }, { "Naxxramas", "Heigan", "10N" } } },
  [40621] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Gluth", "10N" }, { "Naxxramas", "Noth", "10N" }, { "Naxxramas", "Heigan", "10N" } } },
  [40634] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Gluth", "25N" }, { "Naxxramas", "Thaddius", "25N" }, { "Naxxramas", "4Horsemen", "25N" } } },
  [40635] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Gluth", "25N" }, { "Naxxramas", "Thaddius", "25N" }, { "Naxxramas", "4Horsemen", "25N" } } },
  [40636] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Gluth", "25N" }, { "Naxxramas", "Thaddius", "25N" }, { "Naxxramas", "4Horsemen", "25N" } } },
  -- T7 shoulders (Loatheb 40622-24 / 40637-39)
  [40622] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Loatheb", "10N" } } },
  [40623] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Loatheb", "10N" } } },
  [40624] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Loatheb", "10N" } } },
  [40637] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Loatheb", "25N" } } },
  [40638] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Loatheb", "25N" } } },
  [40639] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Loatheb", "25N" } } },
  -- T7 chest (10: 4Horsemen 40610-12; 25: Gluth 40625-27)
  [40610] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "4Horsemen", "10N" } } },
  [40611] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "4Horsemen", "10N" } } },
  [40612] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "4Horsemen", "10N" } } },
  [40625] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Gluth", "25N" } } },
  [40626] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Gluth", "25N" } } },
  [40627] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Gluth", "25N" } } },
  -- T7 head (Kel'Thuzad 40616-18 / 40631-33)
  [40616] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Kel'Thuzad", "10N" } } },
  [40617] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Kel'Thuzad", "10N" } } },
  [40618] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Kel'Thuzad", "10N" } } },
  [40631] = { tier = "T7", family = "Lost Conqueror",  pages = { { "Naxxramas", "Kel'Thuzad", "25N" } } },
  [40632] = { tier = "T7", family = "Lost Protector",  pages = { { "Naxxramas", "Kel'Thuzad", "25N" } } },
  [40633] = { tier = "T7", family = "Lost Vanquisher", pages = { { "Naxxramas", "Kel'Thuzad", "25N" } } },
  -- T8 "Wayward" (oracle: exact per-boss pages, 10N bare / 25Man suffix)
  [45644] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Freya", "10N" } } },
  [45645] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Freya", "10N" } } },
  [45646] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Freya", "10N" } } },
  [45647] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Mimiron", "10N" } } },
  [45648] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Mimiron", "10N" } } },
  [45649] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Mimiron", "10N" } } },
  [45650] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Hodir", "10N" } } },
  [45651] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Hodir", "10N" } } },
  [45652] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Hodir", "10N" } } },
  [45635] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Yogg", "10N" } } },
  [45636] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Yogg", "10N" } } },
  [45637] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Yogg", "10N" } } },
  [45659] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Thorim", "10N" } } },
  [45660] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Thorim", "10N" } } },
  [45661] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Thorim", "10N" } } },
  [45641] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Mimiron", "25N" } } },
  [45642] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Mimiron", "25N" } } },
  [45643] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Mimiron", "25N" } } },
  [45638] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Thorim", "25N" } } },
  [45639] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Thorim", "25N" } } },
  [45640] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Thorim", "25N" } } },
  [45632] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Hodir", "25N" } } },
  [45633] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Hodir", "25N" } } },
  [45634] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Hodir", "25N" } } },
  [45653] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Freya", "25N" } } },
  [45654] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Freya", "25N" } } },
  [45655] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Freya", "25N" } } },
  [45656] = { tier = "T8", family = "Wayward Conqueror",  pages = { { "Ulduar", "Yogg", "25N" } } },
  [45657] = { tier = "T8", family = "Wayward Protector",  pages = { { "Ulduar", "Yogg", "25N" } } },
  [45658] = { tier = "T8", family = "Wayward Vanquisher", pages = { { "Ulduar", "Yogg", "25N" } } },
}

return M
