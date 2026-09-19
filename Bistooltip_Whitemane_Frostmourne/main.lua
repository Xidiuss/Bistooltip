-- Bistooltip_Whitemane_Frostmourne/main.lua
-- Server diff for Whitemane: Frostmourne. Generated 2026-09-08 from:
--   * EmblemData.lua custom currencies (Emblem of Ascension / Ascension II /
--     Echo of the Titans) — moved OUT of core per spec W6 (core = clean WotLK)
--   * docs/superpowers/data/whitemane-custom-extract-2026-09-08.lua:
--     27 rank-1 legendary insertions (128858/130023/130031/131004/150005),
--     expressed as DB-independent InsertBiSSlotRank ("rank 1 = legendary"),
--     so they survive ranking updates and database switches
--   * typo fix (owner Q2): EmblemData [15000] emitted as 150005
-- Vendor location labels: pending owner scans (D6) — VENDOR lines carry
-- currency costs only, no location needed.
-- Pure Lua 5.1; loads after Bistooltip (hard ## Dependencies).

local P = "Bistooltip_Whitemane_Frostmourne"
-- Guard: without the core addon (missing/disabled) stay silent instead of
-- erroring on every line. ## Dependencies normally prevents this load order.
if not BisTooltip then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000" .. P .. ":|r Bistooltip core missing or disabled - plugin inactive")
    end
    return
end
BisTooltip:InsertBiSSlotRank("Druid", "Balance", "T7", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Druid", "Balance", "T8", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Druid", "Feral dps", "T8", "Weapon", 1, 128858, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Hunter", "Beast mastery", "T7", "Ranged", 1, 150005, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Hunter", "Marksmanship", "T7", "Ranged", 1, 150005, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Hunter", "Survival", "T7", "Ranged", 1, 150005, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Arcane", "T7", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Arcane", "T8", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Fire", "T7", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Fire", "T8", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Fire FFB", "T7", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Fire FFB", "T8", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Frost", "T7", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Mage", "Frost", "T8", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Paladin", "Retribution", "T7", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Paladin", "Retribution", "T8", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Paladin", "Retribution", "T9", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Priest", "Shadow", "T7", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Priest", "Shadow", "T8", "Weapon", 1, 130023, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Shaman", "Enhancement", "T8", "Weapon", 1, 131004, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Shaman", "Enhancement", "T9", "Weapon", 1, 131004, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Warrior", "Arms", "T7", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Warrior", "Arms", "T8", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Warrior", "Arms", "T9", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Warrior", "Fury", "T7", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Warrior", "Fury", "T8", "Weapon", 1, 130031, P) -- legendary rank-1
BisTooltip:InsertBiSSlotRank("Warrior", "Fury", "T9", "Weapon", 1, 130031, P) -- legendary rank-1

-- Custom-currency vendor costs (from EmblemData, W6 cutover)
BisTooltip:AddAcquisition(39701, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39702, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(39703, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39704, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39706, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39717, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39718, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39719, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39720, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39721, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39722, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(39723, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39724, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39725, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39726, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39727, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39728, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(39729, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(39731, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(39732, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39733, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39734, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39735, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39756, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39757, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(39759, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39760, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39761, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39762, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(39764, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(39765, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(39767, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(39768, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40061, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40062, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40063, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40064, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40065, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40069, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40071, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40074, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40075, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40080, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40107, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40108, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40184, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40185, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40186, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40187, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40188, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40191, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40193, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40194, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40196, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40197, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40198, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40200, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40201, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40203, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40204, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40205, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40206, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40207, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40209, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40210, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40234, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40235, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40236, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40237, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40238, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40239, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40240, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40241, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40242, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40243, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40244, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40246, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40247, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40249, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40250, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40251, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40252, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40253, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40254, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40255, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40256, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40257, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40258, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40259, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40260, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40261, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40262, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40263, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40267, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40268, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40269, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40270, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40271, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40272, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40274, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40275, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40277, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40278, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40279, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40282, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40283, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40286, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40287, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40288, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40289, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40294, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40296, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40297, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40298, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40299, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40301, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40302, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40303, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40304, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40305, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40306, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40315, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40316, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40317, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40318, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40319, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40320, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40321, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40322, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 12 } } }, P)
BisTooltip:AddAcquisition(40323, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40324, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40325, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40326, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40327, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40329, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40330, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40332, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40334, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40344, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40347, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40349, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40351, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40352, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40362, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40363, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40365, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40366, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40367, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40369, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40370, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40371, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40372, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40373, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40374, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40375, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40376, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40377, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40378, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40379, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40380, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40381, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40382, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40383, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40384, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40385, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40386, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40387, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40388, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40395, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40396, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40398, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40399, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40400, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40401, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40402, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40403, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40405, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40431, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40432, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40433, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 15 } } }, P)
BisTooltip:AddAcquisition(40437, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40438, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40439, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40446, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40451, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40453, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40531, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40532, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40539, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40541, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40543, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40549, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40555, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40558, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40560, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40561, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40562, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40564, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40566, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40588, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40589, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40590, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40591, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40592, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40594, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40602, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40626, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40629, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(40632, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(40635, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 25 } } }, P)
BisTooltip:AddAcquisition(40638, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(44003, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(44004, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 19 } } }, P)
BisTooltip:AddAcquisition(44005, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(44006, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(44007, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(44008, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(44011, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 38 } } }, P)
BisTooltip:AddAcquisition(45111, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45112, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45132, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45133, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45134, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45135, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45136, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45137, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45139, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45148, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45158, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45228, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45241, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45242, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45243, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45244, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45245, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45247, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45250, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45251, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45262, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45271, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45286, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45293, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45294, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45295, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45296, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45297, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45300, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45308, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45319, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45326, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45334, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45442, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45443, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45444, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45445, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45446, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45447, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45448, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45449, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45451, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45456, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45457, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 52 } } }, P)
BisTooltip:AddAcquisition(45459, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45460, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45461, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45462, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45466, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45469, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45470, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45471, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45472, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45473, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45474, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45481, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45484, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45485, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45486, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45487, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45488, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45490, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45494, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45495, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45496, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45497, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45502, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45516, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 52 } } }, P)
BisTooltip:AddAcquisition(45517, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45518, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45519, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45520, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45533, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 52 } } }, P)
BisTooltip:AddAcquisition(45534, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45535, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45536, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45537, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45540, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45542, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45570, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 52 } } }, P)
BisTooltip:AddAcquisition(45587, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45594, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45599, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45609, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45610, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45611, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45612, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45613, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 52 } } }, P)
BisTooltip:AddAcquisition(45615, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45616, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45617, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45619, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45620, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 44 } } }, P)
BisTooltip:AddAcquisition(45633, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45639, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45642, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 19 } } }, P)
BisTooltip:AddAcquisition(45654, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 25 } } }, P)
BisTooltip:AddAcquisition(45657, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 19 } } }, P)
BisTooltip:AddAcquisition(45663, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45665, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 32 } } }, P)
BisTooltip:AddAcquisition(45703, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45867, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45868, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45869, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45870, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45871, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45876, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45877, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45886, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45887, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45888, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45928, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45929, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45930, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45931, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45933, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45943, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45945, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45946, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45947, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45982, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45988, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45989, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45990, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(45993, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46017, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 150 } } }, P)
BisTooltip:AddAcquisition(46021, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46032, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46033, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46034, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46035, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46036, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46037, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46038, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46039, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46040, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46041, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46042, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46043, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46044, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46045, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46046, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46047, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46048, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46049, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46050, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46051, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46067, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46068, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46095, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46096, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(46097, { kind = "VENDOR", cost = { { currency = "Echo of the Titans", amount = 12 } } }, P)
BisTooltip:AddAcquisition(128858, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 150 } } }, P)
BisTooltip:AddAcquisition(130023, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 80 } } }, P)
BisTooltip:AddAcquisition(130031, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 80 } } }, P)
BisTooltip:AddAcquisition(131004, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 150 } } }, P)
BisTooltip:AddAcquisition(131008, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 1 } } }, P)
BisTooltip:AddAcquisition(131010, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension II", amount = 2 } } }, P)
BisTooltip:AddAcquisition(150005, { kind = "VENDOR", cost = { { currency = "Emblem of Ascension", amount = 80 } } }, P)


-- Bistooltip_Scanner EXPORT | vendors: 1 | 2026-09-19
-- Magistrix Lambriesse / Dalaran / 2026-09-19 / 37 by Bistooltip_Scanner
-- Owner policy: current Justice/Valor offers replace older vendor prices,
-- while DROP/TOKEN/MARK/CUSTOM methods remain. Keep the core API unchanged.
local function ReplaceVendorAcquisitions(itemID, offers)
    local entries = {}
    for _, entry in ipairs(BisTooltip_ItemAcquisition[itemID] or {}) do
        if entry.kind ~= "VENDOR" then entries[#entries + 1] = entry end
    end
    for _, offer in ipairs(offers) do entries[#entries + 1] = offer end
    BisTooltip:SetAcquisition(itemID, entries, P)
end
ReplaceVendorAcquisitions(39728, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Totem of Misery -- item:40752
ReplaceVendorAcquisitions(39757, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Idol of Worship -- item:40752
ReplaceVendorAcquisitions(40191, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Libram of Radiance -- item:40752
ReplaceVendorAcquisitions(40207, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Sigil of Awareness -- item:40752
ReplaceVendorAcquisitions(40267, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Totem of Hex -- item:40752
ReplaceVendorAcquisitions(40268, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Libram of Tolerance -- item:40752
ReplaceVendorAcquisitions(40321, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Idol of the Shooting Star -- item:40752
ReplaceVendorAcquisitions(40322, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Totem of Dueling -- item:40752
ReplaceVendorAcquisitions(40337, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Libram of Resurgence -- item:40752
ReplaceVendorAcquisitions(40342, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Idol of Awakening -- item:40752
ReplaceVendorAcquisitions(40636, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 2200 } } } }) -- Legplates of the Lost Vanquisher -- item:40752
ReplaceVendorAcquisitions(40639, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Mantle of the Lost Vanquisher -- item:40752
ReplaceVendorAcquisitions(40717, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Ring of Invincibility -- item:40752
ReplaceVendorAcquisitions(40718, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Signet of the Impregnable Fortress -- item:40752
ReplaceVendorAcquisitions(40719, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Band of Channeled Magic -- item:40752
ReplaceVendorAcquisitions(40720, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Renewal of Life -- item:40752
ReplaceVendorAcquisitions(40721, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Hammerhead Sharkskin Cloak -- item:40752
ReplaceVendorAcquisitions(40722, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Platinum Mesh Cloak -- item:40752
ReplaceVendorAcquisitions(40723, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Disguise of the Kumiho -- item:40752
ReplaceVendorAcquisitions(40724, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Cloak of Kea Feathers -- item:40752
ReplaceVendorAcquisitions(40733, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Wristbands of the Sentinel Huntress -- item:40752
ReplaceVendorAcquisitions(40734, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Bracers of Dalaran's Parapets -- item:40752
ReplaceVendorAcquisitions(40735, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Zartson's Jungle Vambraces -- item:40752
ReplaceVendorAcquisitions(40736, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Armguard of the Tower Archer -- item:40752
ReplaceVendorAcquisitions(40737, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Pigmented Clan Bindings -- item:40752
ReplaceVendorAcquisitions(40738, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Wristwraps of the Cutthroat -- item:40752
ReplaceVendorAcquisitions(40739, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Bands of the Great Tree -- item:40752
ReplaceVendorAcquisitions(40740, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Wraps of the Astral Traveler -- item:40752
ReplaceVendorAcquisitions(40741, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Cuffs of the Shadow Ascendant -- item:40752
ReplaceVendorAcquisitions(40743, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Kyzoc's Ground Stompers -- item:40752
ReplaceVendorAcquisitions(40745, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Sabatons of Rapid Recovery -- item:40752
ReplaceVendorAcquisitions(40746, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Pack-Ice Striders -- item:40752
ReplaceVendorAcquisitions(40747, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Treads of Coastal Wandering -- item:40752
ReplaceVendorAcquisitions(40748, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Boots of Captain Ellis -- item:40752
ReplaceVendorAcquisitions(40749, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Rainey's Chewed Boots -- item:40752
ReplaceVendorAcquisitions(40750, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Xintor's Expeditionary Boots -- item:40752
ReplaceVendorAcquisitions(40751, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Slippers of the Holy Light -- item:40752

-- Bistooltip_Scanner EXPORT | vendors: 1 | 2026-09-19
-- Magister Sarien / Dalaran / 2026-09-19 / 28 by Bistooltip_Scanner
ReplaceVendorAcquisitions(37111, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Soul Preserver -- item:40752
ReplaceVendorAcquisitions(40612, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 2200 } } } }) -- Chestguard of the Lost Vanquisher -- item:40752
ReplaceVendorAcquisitions(40615, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Gloves of the Lost Vanquisher -- item:40752
ReplaceVendorAcquisitions(40678, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Pendant of the Outcast Hero -- item:40752
ReplaceVendorAcquisitions(40679, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Chained Military Gorget -- item:40752
ReplaceVendorAcquisitions(40680, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Encircling Burnished Gold Chains -- item:40752
ReplaceVendorAcquisitions(40681, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1250 } } } }) -- Lattice Choker of Light -- item:40752
ReplaceVendorAcquisitions(40682, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Sundial of the Exiled -- item:40752
ReplaceVendorAcquisitions(40683, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Valor Medal of the First War -- item:40752
ReplaceVendorAcquisitions(40684, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Mirror of Truth -- item:40752
ReplaceVendorAcquisitions(40685, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- The Egg of Mortal Essence -- item:40752
ReplaceVendorAcquisitions(40688, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Verdungo's Barbarian Cord -- item:40752
ReplaceVendorAcquisitions(40689, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Waistguard of Living Iron -- item:40752
ReplaceVendorAcquisitions(40691, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Magroth's Meditative Cincture -- item:40752
ReplaceVendorAcquisitions(40692, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Vereesa's Silver Chain Belt -- item:40752
ReplaceVendorAcquisitions(40693, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Beadwork Belt of Shamanic Vision -- item:40752
ReplaceVendorAcquisitions(40694, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Jorach's Crocolisk Skin Belt -- item:40752
ReplaceVendorAcquisitions(40695, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Vine Belt of the Woodland Dryad -- item:40752
ReplaceVendorAcquisitions(40696, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Plush Sash of Guzbah -- item:40752
ReplaceVendorAcquisitions(40697, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 1650 } } } }) -- Elegant Temple Gardens' Girdle -- item:40752
ReplaceVendorAcquisitions(40698, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Ward of the Violet Citadel -- item:40752
ReplaceVendorAcquisitions(40699, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Handbook of Obscure Remedies -- item:40752
ReplaceVendorAcquisitions(40700, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Protective Barricade of the Light -- item:40752
ReplaceVendorAcquisitions(40701, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Crygil's Discarded Plate Panel -- item:40752
ReplaceVendorAcquisitions(40702, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Rolfsen's Ripper -- item:40752
ReplaceVendorAcquisitions(40703, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Grasscutter -- item:40752
ReplaceVendorAcquisitions(40704, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 950 } } } }) -- Pride -- item:40752
ReplaceVendorAcquisitions(40716, { { kind = "VENDOR", cost = { { currency = "Justice", amount = 700 } } } }) -- Lillehoff's Winged Blades -- item:40752

-- Bistooltip_Scanner EXPORT | vendors: 1 | 2026-09-19
-- Magister Brasael / Dalaran / 2026-09-19 / 47 by Bistooltip_Scanner
ReplaceVendorAcquisitions(41649, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Deadly Gladiator's Leather Tunic -- item:40753
ReplaceVendorAcquisitions(41654, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Deadly Gladiator's Leather Legguards -- item:40753
ReplaceVendorAcquisitions(41671, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Deadly Gladiator's Leather Helm -- item:40753
ReplaceVendorAcquisitions(41682, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Deadly Gladiator's Leather Spaulders -- item:40753
ReplaceVendorAcquisitions(41766, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Deadly Gladiator's Leather Gloves -- item:40753
ReplaceVendorAcquisitions(45114, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Steamcaller's Totem -- item:40753
ReplaceVendorAcquisitions(45144, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Sigil of Deflection -- item:40753
ReplaceVendorAcquisitions(45145, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Libram of the Sacred Shield -- item:40753
ReplaceVendorAcquisitions(45169, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Totem of the Dancing Flame -- item:40753
ReplaceVendorAcquisitions(45254, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Sigil of the Vengeful Heart -- item:40753
ReplaceVendorAcquisitions(45255, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Thunderfall Totem -- item:40753
ReplaceVendorAcquisitions(45270, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Idol of the Crying Wind -- item:40753
ReplaceVendorAcquisitions(45436, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Libram of the Resolute -- item:40753
ReplaceVendorAcquisitions(45509, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Idol of the Corruptor -- item:40753
ReplaceVendorAcquisitions(45510, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Libram of Discord -- item:40753
ReplaceVendorAcquisitions(45634, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Breastplate of the Wayward Vanquisher -- item:40753
ReplaceVendorAcquisitions(45640, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Crown of the Wayward Vanquisher -- item:40753
ReplaceVendorAcquisitions(45819, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1250 } } } }) -- Spiked Battleguard Choker -- item:40753
ReplaceVendorAcquisitions(45820, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1250 } } } }) -- Broach of the Wailing Night -- item:40753
ReplaceVendorAcquisitions(45821, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1250 } } } }) -- Shard of the Crystal Forest -- item:40753
ReplaceVendorAcquisitions(45822, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1250 } } } }) -- Evoker's Charm -- item:40753
ReplaceVendorAcquisitions(45823, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1250 } } } }) -- Frozen Tear of Elune -- item:40753
ReplaceVendorAcquisitions(45824, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Belt of the Singing Blade -- item:40753
ReplaceVendorAcquisitions(45825, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Shieldwarder Girdle -- item:40753
ReplaceVendorAcquisitions(45826, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Girdle of Unyielding Trust -- item:40753
ReplaceVendorAcquisitions(45827, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Belt of the Ardent Marksman -- item:40753
ReplaceVendorAcquisitions(45828, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Windchill Binding -- item:40753
ReplaceVendorAcquisitions(45829, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Belt of the Twilight Assassin -- item:40753
ReplaceVendorAcquisitions(45830, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Belt of the Living Thicket -- item:40753
ReplaceVendorAcquisitions(45831, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Sash of Potent Incantations -- item:40753
ReplaceVendorAcquisitions(45833, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Bladebreaker Gauntlets -- item:40753
ReplaceVendorAcquisitions(45834, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Gauntlets of the Royal Watch -- item:40753
ReplaceVendorAcquisitions(45835, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Gauntlets of Serene Blessing -- item:40753
ReplaceVendorAcquisitions(45836, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Gloves of Unerring Aim -- item:40753
ReplaceVendorAcquisitions(45837, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Gloves of Augury -- item:40753
ReplaceVendorAcquisitions(45838, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Gloves of the Blind Stalker -- item:40753
ReplaceVendorAcquisitions(45839, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Grips of the Secret Grove -- item:40753
ReplaceVendorAcquisitions(45840, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 1650 } } } }) -- Touch of the Occult -- item:40753
ReplaceVendorAcquisitions(45841, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Legplates of the Violet Champion -- item:40753
ReplaceVendorAcquisitions(45842, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Wyrmguard Legplates -- item:40753
ReplaceVendorAcquisitions(45843, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Legguards of the Peaceful Covenant -- item:40753
ReplaceVendorAcquisitions(45844, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Leggings of the Tireless Sentry -- item:40753
ReplaceVendorAcquisitions(45845, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Leggings of the Weary Mystic -- item:40753
ReplaceVendorAcquisitions(45846, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Leggings of Wavering Shadow -- item:40753
ReplaceVendorAcquisitions(45847, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Wildstrider Legguards -- item:40753
ReplaceVendorAcquisitions(45848, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 2200 } } } }) -- Legwraps of the Master Conjurer -- item:40753
ReplaceVendorAcquisitions(46138, { { kind = "VENDOR", cost = { { currency = "Valor", amount = 700 } } } }) -- Idol of the Flourishing Life -- item:40753




-- Bistooltip_Scanner EXPORT | LEGENDARY WEAPONS
-- Planned BiS update: 23 annotated item IDs, not acquisition evidence.
-- Preserve the notes below; enable only after sources/prices and rank targets
-- are confirmed. These observations must not erase existing runtime sources.
-- PLANNED (not a source): BisTooltip:SetAcquisition(128858, { { kind = "VENDOR", cost = {  } } }) -- Embersoul, Scythe of the Cat God -- EMPTY-COST ext=nil nCost=nil | ilvl 245 [BIS T8 feral]
-- PLANNED (not a source): BisTooltip:SetAcquisition(315010, { { kind = "VENDOR", cost = {  } } }) -- Embersoul, Scythe of the Cat God -- EMPTY-COST ext=nil nCost=nil | ilvl 258 [BIS T9 feral]

-- PLANNED (not a source): BisTooltip:SetAcquisition(130023, { { kind = "VENDOR", cost = {  } } }) -- Atiesh, Greatstaff of the Guardian -- EMPTY-COST ext=nil nCost=nil | mage   BIS T7-T8 ilvl 232
-- PLANNED (not a source): BisTooltip:SetAcquisition(315003, { { kind = "VENDOR", cost = {  } } }) -- Atiesh, Greatstaff of the Guardian -- EMPTY-COST ext=nil nCost=nil | mage T9 BIS ilvl 258
-- PLANNED (not a source): BisTooltip:SetAcquisition(130025, { { kind = "VENDOR", cost = {  } } }) -- Atiesh, Greatstaff of the Guardian -- EMPTY-COST ext=nil nCost=nil | priest BIS T7-T8 ilvl 232
-- PLANNED (not a source): BisTooltip:SetAcquisition(315015, { { kind = "VENDOR", cost = {  } } }) -- Atiesh, Greatstaff of the Guardian -- EMPTY-COST ext=nil nCost=nil  |priest BIS T9 ilvl 258
-- PLANNED (not a source): BisTooltip:SetAcquisition(130026, { { kind = "VENDOR", cost = {  } } }) -- Atiesh, Greatstaff of the Guardian -- EMPTY-COST ext=nil nCost=nil | druid  BIS T7-T8 ilvl 232
-- PLANNED (not a source): BisTooltip:SetAcquisition(315016, { { kind = "VENDOR", cost = {  } } }) -- Atiesh, Greatstaff of the Guardian -- EMPTY-COST ext=nil nCost=nil | druid BIS T9 ilvl 258



-- PLANNED (not a source): BisTooltip:SetAcquisition(131001, { { kind = "VENDOR", cost = {  } } }) -- Warglaive of Azzinoth -- EMPTY-COST ext=nil nCost=nil - rogue T8 BIS
-- PLANNED (not a source): BisTooltip:SetAcquisition(131002, { { kind = "VENDOR", cost = {  } } }) -- Warglaive of Azzinoth -- EMPTY-COST ext=nil nCost=nil - rogue T8 BIS

-- PLANNED (not a source): BisTooltip:SetAcquisition(130031, { { kind = "VENDOR", cost = {  } } }) -- Armata Strigoi -- EMPTY-COST ext=nil nCost=nil | BIS T7-T8 warrior / paladin
-- PLANNED (not a source): BisTooltip:SetAcquisition(315004, { { kind = "VENDOR", cost = {  } } }) -- Armata Strigoi -- EMPTY-COST ext=nil nCost=nil | BIS T9 warrior / paladin | BIS T10 offhand warrior fury

-- PLANNED (not a source): BisTooltip:SetAcquisition(131004, { { kind = "VENDOR", cost = {  } } }) -- Doomhammer -- EMPTY-COST ext=nil nCost=nil | BIS T8
-- PLANNED (not a source): BisTooltip:SetAcquisition(315008, { { kind = "VENDOR", cost = {  } } }) -- Doomhammer -- EMPTY-COST ext=nil nCost=nil  | BIS T9 upgraded

-- PLANNED (not a source): BisTooltip:SetAcquisition(132001, { { kind = "VENDOR", cost = {  } } }) -- Sulfuras, Hand of Ragnaros -- EMPTY-COST ext=nil nCost=nil | BIS T9 2h DK TANK

-- PLANNED (not a source): BisTooltip:SetAcquisition(132003, { { kind = "VENDOR", cost = {  } } }) -- Thunderfury, Blessed Blade of the Windseeker -- EMPTY-COST ext=nil nCost=nil | BIS PALADIN / PROT T9

-- PLANNED (not a source): BisTooltip:SetAcquisition(150005, { { kind = "VENDOR", cost = {  } } }) -- Stormcoil -- EMPTY-COST ext=nil nCost=nil | BIS T7 hunter
-- PLANNED (not a source): BisTooltip:SetAcquisition(150090, { { kind = "VENDOR", cost = {  } } }) -- Stormcoil -- EMPTY-COST ext=nil nCost=nil | BIS T8 hunter
-- PLANNED (not a source): BisTooltip:SetAcquisition(315005, { { kind = "VENDOR", cost = {  } } }) -- Stormcoil -- EMPTY-COST ext=nil nCost=nil | BIS T9 hunter

-- PLANNED (not a source): BisTooltip:SetAcquisition(315006, { { kind = "VENDOR", cost = {  } } }) -- Nightwing  | 258 ilvl staff - mage druid warlock priest  [W8 for dev info development Nightwing or  Atiesh, Greatstaff of the Guardian ilvl 258]

-- PLANNED (not a source): BisTooltip:SetAcquisition(46017, { { kind = "VENDOR", cost = {  } } }) -- Val'anyr, Hammer of Ancient Kings -- EMPTY-COST ext=nil nCost=nil | BIS T8
-- PLANNED (not a source): BisTooltip:SetAcquisition(315009, { { kind = "VENDOR", cost = {  } } }) -- Val'anyr, Hammer of Ancient Kings -- EMPTY-COST ext=nil nCost=nil | BIS T9-T10


-- PLANNED (not a source): BisTooltip:SetAcquisition(217741, { { kind = "VENDOR", cost = {  } } }) -- Fury of the Sunwell -- EMPTY-COST ext=nil nCost=nil | BIS T10 shield
