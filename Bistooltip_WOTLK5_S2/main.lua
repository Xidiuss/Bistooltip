-- Bistooltip_WOTLK5_S2/main.lua
-- Server diff for WOTLK5 (season 2): scanned vendor costs.
-- Generated from Wotlk5_skan.txt (Bistooltip_Scanner EXPORT 2026-09-08):
--   * Vexmor Gravebinder @ Dalaran (368 items, Emblem of Plague)
--   * Maldrith Soulleech @ Dalaran (255 items, Emblem of Resolve)
--   * hand-appended ENCHANTY section (custom enchants, Plagued Legendary Shard)
-- Conversion rule (same as Bistooltip_Whitemane_Frostmourne):
--   * scanned lines -> AddAcquisition (append; core DROP/VENDOR lines kept)
--   * ENCHANTY (core-absent custom IDs) -> SetAcquisition with plugin tag P
-- Trailing "-- item:ID" currency comments kept from the scan (luac-clean).
-- Pure Lua 5.1, no WoW API. Loads after Bistooltip (hard ## Dependencies).

local P = "Bistooltip_WOTLK5_S2"
-- Guard: without the core addon (missing/disabled) stay silent instead of
-- erroring on every line. ## Dependencies normally prevents this load order.
if not BisTooltip then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000" .. P .. ":|r Bistooltip core missing or disabled - plugin inactive")
    end
    return
end

-- Bistooltip_Scanner EXPORT | vendors: 1 | 2026-09-08
-- Vexmor Gravebinder / Dalaran / 2026-09-08 / 368 by Bistooltip_Scanner
-- Emblem of Plague
BisTooltip:AddAcquisition(39146, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Collar of Dissolution -- item:5000016
BisTooltip:AddAcquisition(39240, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Noth's Curse -- item:5000016
BisTooltip:AddAcquisition(39260, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Helm of the Corrupted Mind -- item:5000016
BisTooltip:AddAcquisition(39294, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Arc-Scorched Helmet -- item:5000016
BisTooltip:AddAcquisition(39295, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cowl of Sheet Lightning -- item:5000016
BisTooltip:AddAcquisition(39232, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Pendant of Lost Vocations -- item:5000016
BisTooltip:AddAcquisition(39395, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Thane's Tainted Greathelm -- item:5000016
BisTooltip:AddAcquisition(39399, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helm of the Vast Legions -- item:5000016
BisTooltip:AddAcquisition(39405, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helmet of the Inner Sanctum -- item:5000016
BisTooltip:AddAcquisition(39409, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cowl of Winged Fear -- item:5000016
BisTooltip:AddAcquisition(39230, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spaulders of the Monstrosity -- item:5000016
BisTooltip:AddAcquisition(39246, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Amulet of Autopsy -- item:5000016
BisTooltip:AddAcquisition(39274, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Retcher's Shoulderpads -- item:5000016
BisTooltip:AddAcquisition(39284, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Miasma Mantle -- item:5000016
BisTooltip:AddAcquisition(39403, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Helm of the Unsubmissive -- item:5000016
BisTooltip:AddAcquisition(39198, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Frostblight Pauldrons -- item:5000016
BisTooltip:AddAcquisition(39237, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spaulders of Resumed Battle -- item:5000016
BisTooltip:AddAcquisition(39282, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bone-Linked Amulet -- item:5000016
BisTooltip:AddAcquisition(39310, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Mantle of the Extensive Mind -- item:5000016
BisTooltip:AddAcquisition(39397, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Pauldrons of Havoc -- item:5000016
BisTooltip:AddAcquisition(39242, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Robes of Hoarse Breaths -- item:5000016
BisTooltip:AddAcquisition(39248, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Tunic of the Lost Pack -- item:5000016
BisTooltip:AddAcquisition(39249, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Shoulderplates of Bloodshed -- item:5000016
BisTooltip:AddAcquisition(39259, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fungi-Stained Coverings -- item:5000016
BisTooltip:AddAcquisition(39392, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Veiled Amulet of Life -- item:5000016
BisTooltip:AddAcquisition(39267, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Abomination Shoulderblades -- item:5000016
BisTooltip:AddAcquisition(39386, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Tunic of Dislocation -- item:5000016
BisTooltip:AddAcquisition(39391, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Heinous Mail Chestguard -- item:5000016
BisTooltip:AddAcquisition(39396, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gown of Blaumeux -- item:5000016
BisTooltip:AddAcquisition(39470, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Medallion of the Disgraced -- item:5000016
BisTooltip:AddAcquisition(39188, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Chivalric Chestguard -- item:5000016
BisTooltip:AddAcquisition(39252, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Preceptor's Bindings -- item:5000016
BisTooltip:AddAcquisition(39278, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bands of Anxiety -- item:5000016
BisTooltip:AddAcquisition(39472, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chain of Latent Energies -- item:5000016
BisTooltip:AddAcquisition(43990, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Blade-Scarred Tunic -- item:5000016
BisTooltip:AddAcquisition(39239, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Chestplate of the Risen Soldier -- item:5000016
BisTooltip:AddAcquisition(39247, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cuffs of Dark Shadows -- item:5000016
BisTooltip:AddAcquisition(39307, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Iron Rings of Endurance -- item:5000016
BisTooltip:AddAcquisition(39390, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Resurgent Phantom Bindings -- item:5000016
BisTooltip:AddAcquisition(40427, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Circle of Arcane Streams -- item:5000016
BisTooltip:AddAcquisition(39192, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of Dark Gestures -- item:5000016
BisTooltip:AddAcquisition(39194, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Rusted-Link Spiked Gauntlets -- item:5000016
BisTooltip:AddAcquisition(39283, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Putrescent Bands -- item:5000016
BisTooltip:AddAcquisition(39398, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Massive Skeletal Ribcage -- item:5000016
BisTooltip:AddAcquisition(43992, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Volitant Amulet -- item:5000016
BisTooltip:AddAcquisition(39141, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Deflection Band -- item:5000016
BisTooltip:AddAcquisition(39195, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Bracers of Lost Sentiments -- item:5000016
BisTooltip:AddAcquisition(39243, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Handgrips of the Foredoomed -- item:5000016
BisTooltip:AddAcquisition(39275, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Contagion Gloves -- item:5000016
BisTooltip:AddAcquisition(39285, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Handgrips of Turmoil -- item:5000016
BisTooltip:AddAcquisition(39190, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Agonal Sash -- item:5000016
BisTooltip:AddAcquisition(39193, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Band of Neglected Pleas -- item:5000016
BisTooltip:AddAcquisition(39235, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Bone-Framed Bracers -- item:5000016
BisTooltip:AddAcquisition(39251, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Necrogenic Belt -- item:5000016
BisTooltip:AddAcquisition(39299, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Rapid Attack Gloves -- item:5000016
BisTooltip:AddAcquisition(39216, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sash of Mortal Desire -- item:5000016
BisTooltip:AddAcquisition(39231, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Timeworn Silken Band -- item:5000016
BisTooltip:AddAcquisition(39279, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Blistered Belt of Decay -- item:5000016
BisTooltip:AddAcquisition(39379, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spectral Rider's Girdle -- item:5000016
BisTooltip:AddAcquisition(39467, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Minion Bracers -- item:5000016
BisTooltip:AddAcquisition(39197, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Gauntlets of the Master -- item:5000016
BisTooltip:AddAcquisition(39217, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Avenging Combat Leggings -- item:5000016
BisTooltip:AddAcquisition(39244, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ring of the Fated -- item:5000016
BisTooltip:AddAcquisition(39308, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Girdle of Lenience -- item:5000016
BisTooltip:AddAcquisition(39309, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of the Instructor -- item:5000016
BisTooltip:AddAcquisition(39189, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of Persistence -- item:5000016
BisTooltip:AddAcquisition(39191, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Splint-Bound Leggings -- item:5000016
BisTooltip:AddAcquisition(39228, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Web Cocoon Grips -- item:5000016
BisTooltip:AddAcquisition(39250, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ring of Holy Cleansing -- item:5000016
BisTooltip:AddAcquisition(39408, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Sapphiron -- item:5000016
BisTooltip:AddAcquisition(39224, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Discord -- item:5000016
BisTooltip:AddAcquisition(39236, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Trespasser's Boots -- item:5000016
BisTooltip:AddAcquisition(39254, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Saltarello Shoes -- item:5000016
BisTooltip:AddAcquisition(39262, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Gauntlets of Combined Strength -- item:5000016
BisTooltip:AddAcquisition(39277, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sealing Ring of Grobbulus -- item:5000016
BisTooltip:AddAcquisition(39273, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sullen Cloth Boots -- item:5000016
BisTooltip:AddAcquisition(39306, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Plated Gloves of Relief -- item:5000016
BisTooltip:AddAcquisition(39389, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Signet of the Malevolent -- item:5000016
BisTooltip:AddAcquisition(40235, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helm of Pilgrimage -- item:5000016
BisTooltip:AddAcquisition(43991, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Legguards of Composure -- item:5000016
BisTooltip:AddAcquisition(39196, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of the Worshiper -- item:5000016
BisTooltip:AddAcquisition(39261, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Tainted Girdle of Mending -- item:5000016
BisTooltip:AddAcquisition(39401, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Circle of Death -- item:5000016
BisTooltip:AddAcquisition(40340, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helm of Unleashed Energy -- item:5000016
BisTooltip:AddAcquisition(43995, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Enamored Cowl -- item:5000016
BisTooltip:AddAcquisition(39215, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of the Follower -- item:5000016
BisTooltip:AddAcquisition(39298, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Waistguard of the Tutor -- item:5000016
BisTooltip:AddAcquisition(39407, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Circle of Life -- item:5000016
BisTooltip:AddAcquisition(39732, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Faerlina's Madness -- item:5000016
BisTooltip:AddAcquisition(40344, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helm of the Grave -- item:5000016
BisTooltip:AddAcquisition(39345, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Girdle of the Ascended Phantom -- item:5000016
BisTooltip:AddAcquisition(39768, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cowl of the Perished -- item:5000016
BisTooltip:AddAcquisition(40247, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cowl of Innocent Delight -- item:5000016
BisTooltip:AddAcquisition(40426, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Signet of the Accord -- item:5000016
BisTooltip:AddAcquisition(40451, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Hyaline Helm of the Sniper -- item:5000016
BisTooltip:AddAcquisition(39229, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Embrace of the Spider -- item:5000016
BisTooltip:AddAcquisition(40287, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cowl of Vanity -- item:5000016
BisTooltip:AddAcquisition(40288, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spaulders of Incoherence -- item:5000016
BisTooltip:AddAcquisition(40296, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cover of Silence -- item:5000016
BisTooltip:AddAcquisition(43989, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Remembrance Girdle -- item:5000016
BisTooltip:AddAcquisition(39257, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Loatheb's Shadow -- item:5000016
BisTooltip:AddAcquisition(39258, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Legplates of Inescapable Death -- item:5000016
BisTooltip:AddAcquisition(40299, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Pauldrons of the Abandoned -- item:5000016
BisTooltip:AddAcquisition(40304, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Headpiece of Fungal Bloom -- item:5000016
BisTooltip:AddAcquisition(40339, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gothik's Cowl -- item:5000016
BisTooltip:AddAcquisition(39280, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Leggings of Innumerable Barbs -- item:5000016
BisTooltip:AddAcquisition(39292, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Repelling Charge -- item:5000016
BisTooltip:AddAcquisition(39719, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Mantle of the Locusts -- item:5000016
BisTooltip:AddAcquisition(40315, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shoulderpads of Secret Arts -- item:5000016
BisTooltip:AddAcquisition(40329, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Hood of the Exodus -- item:5000016
BisTooltip:AddAcquisition(39293, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Blackened Legplates of Feugen -- item:5000016
BisTooltip:AddAcquisition(39388, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spirit-World Glass -- item:5000016
BisTooltip:AddAcquisition(40063, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Mantle of Shattered Kinship -- item:5000016
BisTooltip:AddAcquisition(40286, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Mantle of the Corrupted -- item:5000016
BisTooltip:AddAcquisition(40438, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Council Chamber Epaulets -- item:5000016
BisTooltip:AddAcquisition(39139, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Ravaging Sabatons -- item:5000016
BisTooltip:AddAcquisition(40289, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sympathetic Amice -- item:5000016
BisTooltip:AddAcquisition(40305, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spaulders of Egotism -- item:5000016
BisTooltip:AddAcquisition(40430, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Majestic Dragon Figurine -- item:5000016
BisTooltip:AddAcquisition(44003, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Upstanding Spaulders -- item:5000016
BisTooltip:AddAcquisition(39234, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Plague-Impervious Boots -- item:5000016
BisTooltip:AddAcquisition(39473, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Contortion -- item:5000016
BisTooltip:AddAcquisition(39724, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cult's Chestguard -- item:5000016
BisTooltip:AddAcquisition(40351, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Mantle of the Fatigued Sage -- item:5000016
BisTooltip:AddAcquisition(40437, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Concealment Shoulderpads -- item:5000016
BisTooltip:AddAcquisition(39296, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Accursed Bow of the Elite -- item:5000016
BisTooltip:AddAcquisition(39369, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 10 } } }) -- Sabatons of Deathlike Gloom -- item:5000016
BisTooltip:AddAcquisition(40061, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Quivering Tunic -- item:5000016
BisTooltip:AddAcquisition(40439, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Mantle of the Eternal Sentinel -- item:5000016
BisTooltip:AddAcquisition(40526, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gown of the Spell-Weaver -- item:5000016
BisTooltip:AddAcquisition(39255, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Staff of the Plague Beast -- item:5000016
BisTooltip:AddAcquisition(39723, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fire-Scorched Greathelm -- item:5000016
BisTooltip:AddAcquisition(39756, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Tunic of Prejudice -- item:5000016
BisTooltip:AddAcquisition(40062, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Digested Silken Robes -- item:5000016
BisTooltip:AddAcquisition(40193, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Tunic of Masked Suffering -- item:5000016
BisTooltip:AddAcquisition(39256, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sulfur Stave -- item:5000016
BisTooltip:AddAcquisition(39760, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helm of Diminished Pride -- item:5000016
BisTooltip:AddAcquisition(40234, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Heigan's Putrid Vestments -- item:5000016
BisTooltip:AddAcquisition(40249, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Vest of Vitality -- item:5000016
BisTooltip:AddAcquisition(40283, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fallout Impervious Tunic -- item:5000016
BisTooltip:AddAcquisition(39394, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Charmed Cierge -- item:5000016
BisTooltip:AddAcquisition(40277, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Tunic of Indulgence -- item:5000016
BisTooltip:AddAcquisition(40298, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Faceguard of the Succumbed -- item:5000016
BisTooltip:AddAcquisition(40381, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sympathy -- item:5000016
BisTooltip:AddAcquisition(43998, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chestguard of Flagrant Prowess -- item:5000016
BisTooltip:AddAcquisition(39221, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Wraith Spear -- item:5000016
BisTooltip:AddAcquisition(39702, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Arachnoid Gold Band -- item:5000016
BisTooltip:AddAcquisition(40319, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chestpiece of Suspicion -- item:5000016
BisTooltip:AddAcquisition(40328, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Helm of Vital Protection -- item:5000016
BisTooltip:AddAcquisition(40602, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Robes of Mutation -- item:5000016
BisTooltip:AddAcquisition(39245, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Demise -- item:5000016
BisTooltip:AddAcquisition(39722, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Swarm Bindings -- item:5000016
BisTooltip:AddAcquisition(40209, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bindings of the Decrepit -- item:5000016
BisTooltip:AddAcquisition(40366, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Platehelm of the Great Wyrm -- item:5000016
BisTooltip:AddAcquisition(44002, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Sanctum's Flowing Vestments -- item:5000016
BisTooltip:AddAcquisition(39393, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Claymore of Ancient Power -- item:5000016
BisTooltip:AddAcquisition(39704, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Pauldrons of Unnatural Death -- item:5000016
BisTooltip:AddAcquisition(39731, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Punctilious Bindings -- item:5000016
BisTooltip:AddAcquisition(39765, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sinner's Bindings -- item:5000016
BisTooltip:AddAcquisition(40282, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Slime Stream Bands -- item:5000016
BisTooltip:AddAcquisition(39200, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Grieving Spellblade -- item:5000016
BisTooltip:AddAcquisition(39725, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Epaulets of the Grieving Servant -- item:5000016
BisTooltip:AddAcquisition(40186, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Thrusting Bands -- item:5000016
BisTooltip:AddAcquisition(40198, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bands of Impurity -- item:5000016
BisTooltip:AddAcquisition(40324, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bands of Mutual Respect -- item:5000016
BisTooltip:AddAcquisition(39270, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Hatestrike -- item:5000016
BisTooltip:AddAcquisition(39718, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Corpse Scarab Handguards -- item:5000016
BisTooltip:AddAcquisition(40185, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shoulderguards of Opportunity -- item:5000016
BisTooltip:AddAcquisition(40323, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Esteemed Bindings -- item:5000016
BisTooltip:AddAcquisition(40325, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bindings of the Expansive Mind -- item:5000016
BisTooltip:AddAcquisition(39291, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Torment of the Banished -- item:5000016
BisTooltip:AddAcquisition(39727, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Dislocating Handguards -- item:5000016
BisTooltip:AddAcquisition(40242, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Grotesque Handgrips -- item:5000016
BisTooltip:AddAcquisition(40334, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Burdened Shoulderplates -- item:5000016
BisTooltip:AddAcquisition(40338, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bindings of Yearning -- item:5000016
BisTooltip:AddAcquisition(39344, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Slayer of the Lifeless -- item:5000016
BisTooltip:AddAcquisition(39733, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of Token Respect -- item:5000016
BisTooltip:AddAcquisition(40238, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of the Dancing Bear -- item:5000016
BisTooltip:AddAcquisition(40262, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of Calculated Risk -- item:5000016
BisTooltip:AddAcquisition(40377, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Noble Birthright Pauldrons -- item:5000016
BisTooltip:AddAcquisition(39226, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Maexxna's Femur -- item:5000016
BisTooltip:AddAcquisition(40197, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of the Fallen Wizard -- item:5000016
BisTooltip:AddAcquisition(40302, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Benefactor's Gauntlets -- item:5000016
BisTooltip:AddAcquisition(40349, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of Peaceful Death -- item:5000016
BisTooltip:AddAcquisition(40414, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shoulderguards of the Undaunted -- item:5000016
BisTooltip:AddAcquisition(39281, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Infection Repulser -- item:5000016
BisTooltip:AddAcquisition(40303, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Wraps of the Persecuted -- item:5000016
BisTooltip:AddAcquisition(40362, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of Fast Reactions -- item:5000016
BisTooltip:AddAcquisition(40511, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Focusing Energy Epaulets -- item:5000016
BisTooltip:AddAcquisition(44004, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bountiful Gauntlets -- item:5000016
BisTooltip:AddAcquisition(39140, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Knife of Incision -- item:5000016
BisTooltip:AddAcquisition(39762, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Torn Web Wrapping -- item:5000016
BisTooltip:AddAcquisition(39767, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Undiminished Battleplate -- item:5000016
BisTooltip:AddAcquisition(40200, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Belt of Potent Chanting -- item:5000016
BisTooltip:AddAcquisition(40380, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gloves of Grandeur -- item:5000016
BisTooltip:AddAcquisition(39271, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Blade of Dormant Memories -- item:5000016
BisTooltip:AddAcquisition(39721, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sash of the Parlor -- item:5000016
BisTooltip:AddAcquisition(40203, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Breastplate of Tormented Rage -- item:5000016
BisTooltip:AddAcquisition(40205, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Stalk-Skin Belt -- item:5000016
BisTooltip:AddAcquisition(40272, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Girdle of the Gambit -- item:5000016
BisTooltip:AddAcquisition(39427, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Omen of Ruin -- item:5000016
BisTooltip:AddAcquisition(39735, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Belt of False Dignity -- item:5000016
BisTooltip:AddAcquisition(40210, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chestguard of Bitter Charms -- item:5000016
BisTooltip:AddAcquisition(40260, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Belt of the Tortured -- item:5000016
BisTooltip:AddAcquisition(40275, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Depraved Linked Belt -- item:5000016
BisTooltip:AddAcquisition(39468, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Stray -- item:5000016
BisTooltip:AddAcquisition(40271, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sash of Solitude -- item:5000016
BisTooltip:AddAcquisition(40279, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chestguard of the Exhausted -- item:5000016
BisTooltip:AddAcquisition(40327, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Girdle of Recuperation -- item:5000016
BisTooltip:AddAcquisition(40341, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shackled Cinch -- item:5000016
BisTooltip:AddAcquisition(39761, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Infectious Skitterer Leggings -- item:5000016
BisTooltip:AddAcquisition(40196, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Legguards of the Undisturbed -- item:5000016
BisTooltip:AddAcquisition(40301, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cincture of Polarity -- item:5000016
BisTooltip:AddAcquisition(40365, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Breastplate of Frozen Pain -- item:5000016
BisTooltip:AddAcquisition(40429, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Crimson Steel -- item:5000016
BisTooltip:AddAcquisition(39233, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Aegis of Damnation -- item:5000016
BisTooltip:AddAcquisition(39720, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Atrophy -- item:5000016
BisTooltip:AddAcquisition(40201, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Colossal Strides -- item:5000016
BisTooltip:AddAcquisition(40285, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Desecrated Past -- item:5000016
BisTooltip:AddAcquisition(40453, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chestplate of the Great Aspects -- item:5000016
BisTooltip:AddAcquisition(39276, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Skull of Ruin -- item:5000016
BisTooltip:AddAcquisition(40060, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Distorted Limbs -- item:5000016
BisTooltip:AddAcquisition(40331, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Failed Escape -- item:5000016
BisTooltip:AddAcquisition(40333, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Fleeting Moments -- item:5000016
BisTooltip:AddAcquisition(44000, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Dragonstorm Breastplate -- item:5000016
BisTooltip:AddAcquisition(39199, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Watchful Eye -- item:5000016
BisTooltip:AddAcquisition(39729, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bracers of the Tyrant -- item:5000016
BisTooltip:AddAcquisition(40352, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Leggings of Voracious Shadows -- item:5000016
BisTooltip:AddAcquisition(40376, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Legwraps of the Defeated Dragon -- item:5000016
BisTooltip:AddAcquisition(40379, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Legguards of the Boneyard -- item:5000016
BisTooltip:AddAcquisition(39311, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Scepter of Murmuring Spirits -- item:5000016
BisTooltip:AddAcquisition(39734, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Atonement Greaves -- item:5000016
BisTooltip:AddAcquisition(39764, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bindings of the Hapless Prey -- item:5000016
BisTooltip:AddAcquisition(40236, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Serene Echoes -- item:5000016
BisTooltip:AddAcquisition(40519, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Footsteps of Malygos -- item:5000016
BisTooltip:AddAcquisition(39421, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gem of Imprisoned Vassals -- item:5000016
BisTooltip:AddAcquisition(39701, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Dawnwalkers -- item:5000016
BisTooltip:AddAcquisition(40184, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Crippled Treads -- item:5000016
BisTooltip:AddAcquisition(40246, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of Impetuous Ideals -- item:5000016
BisTooltip:AddAcquisition(40274, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bracers of Liberation -- item:5000016
BisTooltip:AddAcquisition(40064, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Thunderstorm Amulet -- item:5000016
BisTooltip:AddAcquisition(40237, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Eruption-Scarred Boots -- item:5000016
BisTooltip:AddAcquisition(40243, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Footwraps of Vile Deceit -- item:5000016
BisTooltip:AddAcquisition(40269, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of Persuasion -- item:5000016
BisTooltip:AddAcquisition(40306, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bracers of the Unholy Knight -- item:5000016
BisTooltip:AddAcquisition(40065, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fool's Trial -- item:5000016
BisTooltip:AddAcquisition(40270, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of Septic Wounds -- item:5000016
BisTooltip:AddAcquisition(40326, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of Forlorn Wishes -- item:5000016
BisTooltip:AddAcquisition(40330, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bracers of Unrelenting Attack -- item:5000016
BisTooltip:AddAcquisition(40367, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of the Great Construct -- item:5000016
BisTooltip:AddAcquisition(39225, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cloak of Armed Strife -- item:5000016
BisTooltip:AddAcquisition(40069, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Heritage -- item:5000016
BisTooltip:AddAcquisition(40332, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Abetment Bracers -- item:5000016
BisTooltip:AddAcquisition(40409, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Boots of the Escaped Captive -- item:5000016
BisTooltip:AddAcquisition(43996, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sabatons of Firmament -- item:5000016
BisTooltip:AddAcquisition(39241, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Dark Shroud of the Scourge -- item:5000016
BisTooltip:AddAcquisition(39703, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Rescinding Grips -- item:5000016
BisTooltip:AddAcquisition(40071, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Chains of Adoration -- item:5000016
BisTooltip:AddAcquisition(39272, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Drape of Surgery -- item:5000016
BisTooltip:AddAcquisition(39726, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Callous-Hearted Gauntlets -- item:5000016
BisTooltip:AddAcquisition(40369, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Icy Blast Amulet -- item:5000016
BisTooltip:AddAcquisition(39297, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cloak of Darkening -- item:5000016
BisTooltip:AddAcquisition(40188, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gauntlets of the Disobedient -- item:5000016
BisTooltip:AddAcquisition(40374, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cosmic Lights -- item:5000016
BisTooltip:AddAcquisition(39404, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cloak of Mastery -- item:5000016
BisTooltip:AddAcquisition(40261, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Crude Discolored Battlegrips -- item:5000016
BisTooltip:AddAcquisition(40378, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ceaseless Pity -- item:5000016
BisTooltip:AddAcquisition(39415, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shroud of the Citadel -- item:5000016
BisTooltip:AddAcquisition(40316, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gauntlets of Guiding Touch -- item:5000016
BisTooltip:AddAcquisition(40412, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ousted Bead Necklace -- item:5000016
BisTooltip:AddAcquisition(40347, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Zeliek's Gauntlets -- item:5000016
BisTooltip:AddAcquisition(40486, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Necklace of the Glittering Chamber -- item:5000016
BisTooltip:AddAcquisition(43988, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gale-Proof Cloak -- item:5000016
BisTooltip:AddAcquisition(39425, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cloak of the Dying -- item:5000016
BisTooltip:AddAcquisition(39759, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ablative Chitin Girdle -- item:5000016
BisTooltip:AddAcquisition(40074, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Strong-Handed Ring -- item:5000016
BisTooltip:AddAcquisition(40075, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ruthlessness -- item:5000016
BisTooltip:AddAcquisition(40241, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Girdle of Unity -- item:5000016
BisTooltip:AddAcquisition(40250, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Aged Winter Cloak -- item:5000016
BisTooltip:AddAcquisition(40080, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Lost Jewel -- item:5000016
BisTooltip:AddAcquisition(40251, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shroud of Luminosity -- item:5000016
BisTooltip:AddAcquisition(40259, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Waistguard of Divine Grace -- item:5000016
BisTooltip:AddAcquisition(40107, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sand-Worn Band -- item:5000016
BisTooltip:AddAcquisition(40252, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cloak of the Shadowed Sun -- item:5000016
BisTooltip:AddAcquisition(40263, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fleshless Girdle -- item:5000016
BisTooltip:AddAcquisition(40108, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Seized Beauty -- item:5000016
BisTooltip:AddAcquisition(40253, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shawl of the Old Maid -- item:5000016
BisTooltip:AddAcquisition(40278, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Girdle of Chivalry -- item:5000016
BisTooltip:AddAcquisition(40254, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cloak of Averted Crisis -- item:5000016
BisTooltip:AddAcquisition(40317, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Girdle of Razuvious -- item:5000016
BisTooltip:AddAcquisition(40370, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gatekeeper -- item:5000016
BisTooltip:AddAcquisition(40204, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Legguards of the Apostle -- item:5000016
BisTooltip:AddAcquisition(40375, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ring of Decaying Beauty -- item:5000016
BisTooltip:AddAcquisition(40410, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shadow of the Ghoul -- item:5000016
BisTooltip:AddAcquisition(40240, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Greaves of Turbulence -- item:5000016
BisTooltip:AddAcquisition(40433, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Wyrmrest Band -- item:5000016
BisTooltip:AddAcquisition(40294, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Riveted Abomination Leggings -- item:5000016
BisTooltip:AddAcquisition(40474, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Surge Needle Ring -- item:5000016
BisTooltip:AddAcquisition(40318, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Legplates of Double Strikes -- item:5000016
BisTooltip:AddAcquisition(43993, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Greatring of Collision -- item:5000016
BisTooltip:AddAcquisition(40255, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Dying Curse -- item:5000016
BisTooltip:AddAcquisition(40363, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bone-Inlaid Legguards -- item:5000016
BisTooltip:AddAcquisition(40256, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Grim Toll -- item:5000016
BisTooltip:AddAcquisition(40446, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Dragon Brood Legguards -- item:5000016
BisTooltip:AddAcquisition(40257, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Defender's Code -- item:5000016
BisTooltip:AddAcquisition(43994, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Belabored Legplates -- item:5000016
BisTooltip:AddAcquisition(39706, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sabatons of Sudden Reprisal -- item:5000016
BisTooltip:AddAcquisition(40258, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Forethought Talisman -- item:5000016
BisTooltip:AddAcquisition(39717, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Inexorable Sabatons -- item:5000016
BisTooltip:AddAcquisition(40371, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Bandit's Insignia -- item:5000016
BisTooltip:AddAcquisition(40187, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Poignant Sabatons -- item:5000016
BisTooltip:AddAcquisition(40372, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Rune of Repulsion -- item:5000016
BisTooltip:AddAcquisition(40206, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Iron-Spring Jumpers -- item:5000016
BisTooltip:AddAcquisition(40373, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Extract of Necromantic Power -- item:5000016
BisTooltip:AddAcquisition(40297, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Sabatons of Endurance -- item:5000016
BisTooltip:AddAcquisition(40382, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Soul of the Dead -- item:5000016
BisTooltip:AddAcquisition(40320, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Faithful Steel Sabatons -- item:5000016
BisTooltip:AddAcquisition(40431, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fury of the Five Flights -- item:5000016
BisTooltip:AddAcquisition(40432, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Illustration of the Dragon Soul -- item:5000016
BisTooltip:AddAcquisition(39426, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Wand of the Archlich -- item:5000016
BisTooltip:AddAcquisition(39712, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Gemmed Wand of the Nerubians -- item:5000016
BisTooltip:AddAcquisition(40245, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Fading Glow -- item:5000016
BisTooltip:AddAcquisition(40284, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Plague Igniter -- item:5000016
BisTooltip:AddAcquisition(40335, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Touch of Horror -- item:5000016
BisTooltip:AddAcquisition(39419, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Nerubian Conquerer -- item:5000016
BisTooltip:AddAcquisition(40265, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Arrowsong -- item:5000016
BisTooltip:AddAcquisition(40346, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Final Voyage -- item:5000016
BisTooltip:AddAcquisition(39422, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Staff of the Plaguehound -- item:5000016
BisTooltip:AddAcquisition(40233, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Undeath Carrier -- item:5000016
BisTooltip:AddAcquisition(40280, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Origin of Nightmares -- item:5000016
BisTooltip:AddAcquisition(40300, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Spire of Sunset -- item:5000016
BisTooltip:AddAcquisition(40348, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Damnation -- item:5000016
BisTooltip:AddAcquisition(40455, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Staff of Restraint -- item:5000016
BisTooltip:AddAcquisition(40489, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Greatstaff of the Nexus -- item:5000016
BisTooltip:AddAcquisition(40208, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Cryptfiend's Bite -- item:5000016
BisTooltip:AddAcquisition(40497, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Black Ice -- item:5000016
BisTooltip:AddAcquisition(39417, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Death's Bite -- item:5000016
BisTooltip:AddAcquisition(39758, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Jawbone -- item:5000016
BisTooltip:AddAcquisition(40406, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Inevitable Defeat -- item:5000016
BisTooltip:AddAcquisition(40343, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Armageddon -- item:5000016
BisTooltip:AddAcquisition(39423, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Hammer of the Astral Plane -- item:5000016
BisTooltip:AddAcquisition(40189, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Angry Dread -- item:5000016
BisTooltip:AddAcquisition(40244, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Impossible Dream -- item:5000016
BisTooltip:AddAcquisition(40264, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Split Greathammer -- item:5000016
BisTooltip:AddAcquisition(40488, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Ice Spire Scepter -- item:5000016
BisTooltip:AddAcquisition(39730, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Widow's Fury -- item:5000016
BisTooltip:AddAcquisition(40336, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Life and Death -- item:5000016
BisTooltip:AddAcquisition(40345, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Broken Promise -- item:5000016
BisTooltip:AddAcquisition(40407, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Silent Crusader -- item:5000016
BisTooltip:AddAcquisition(40491, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Hailstorm -- item:5000016
BisTooltip:AddAcquisition(39420, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Anarchy -- item:5000016
BisTooltip:AddAcquisition(39424, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Soulblade -- item:5000016
BisTooltip:AddAcquisition(39714, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Webbed Death -- item:5000016
BisTooltip:AddAcquisition(40281, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Twilight Mist -- item:5000016
BisTooltip:AddAcquisition(40368, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Murder -- item:5000016
BisTooltip:AddAcquisition(40408, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Haunting Call -- item:5000016
BisTooltip:AddAcquisition(39416, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Kel'Thuzad's Reach -- item:5000016
BisTooltip:AddAcquisition(39763, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Wraith Strike -- item:5000016
BisTooltip:AddAcquisition(40239, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- The Hand of Nerub -- item:5000016
BisTooltip:AddAcquisition(39716, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Shield of Assimilation -- item:5000016
BisTooltip:AddAcquisition(40266, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Hero's Surrender -- item:5000016
BisTooltip:AddAcquisition(40475, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Barricade of Eternity -- item:5000016
BisTooltip:AddAcquisition(39766, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Matriarch's Spawn -- item:5000016
BisTooltip:AddAcquisition(40192, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Accursed Spine -- item:5000016
BisTooltip:AddAcquisition(40273, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Surplus Limb -- item:5000016
BisTooltip:AddAcquisition(40350, { kind = "VENDOR", cost = { { currency = "Emblem of Plague", amount = 20 } } }) -- Urn of Lost Memories -- item:5000016




-- Emblem of Resolve

-- Bistooltip_Scanner EXPORT | vendors: 1 | 2026-09-08
-- Maldrith Soulleech / Dalaran / 2026-09-08 / 255 by Bistooltip_Scanner
BisTooltip:AddAcquisition(37135, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Arcane-Shielded Helm -- item:90630
BisTooltip:AddAcquisition(37149, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Helm of Anomalus -- item:90630
BisTooltip:AddAcquisition(37188, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Plunderer's Helmet -- item:90630
BisTooltip:AddAcquisition(37294, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Crown of Unbridled Magic -- item:90630
BisTooltip:AddAcquisition(37615, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Titanium Compound Bow -- item:90630
BisTooltip:AddAcquisition(37180, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Battlemap Hide Helm -- item:90630
BisTooltip:AddAcquisition(37182, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Helmet of the Constructor -- item:90630
BisTooltip:AddAcquisition(37592, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Brood Plague Helmet -- item:90630
BisTooltip:AddAcquisition(37594, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Elder Headpiece -- item:90630
BisTooltip:AddAcquisition(37692, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Pierce's Pistol -- item:90630
BisTooltip:AddAcquisition(37237, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Chitin Shell Greathelm -- item:90630
BisTooltip:AddAcquisition(37293, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Mask of the Watcher -- item:90630
BisTooltip:AddAcquisition(37684, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Forgotten Shadow Hood -- item:90630
BisTooltip:AddAcquisition(43284, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Amanitar Skullbow -- item:90630
BisTooltip:AddAcquisition(43311, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Helmet of the Shrine -- item:90630
BisTooltip:AddAcquisition(37177, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Wand of the San'layn -- item:90630
BisTooltip:AddAcquisition(37633, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ground Tremor Helm -- item:90630
BisTooltip:AddAcquisition(37636, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Helm of Cheated Fate -- item:90630
BisTooltip:AddAcquisition(37715, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cowl of the Dire Troll -- item:90630
BisTooltip:AddAcquisition(37726, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- King Dred's Helm -- item:90630
BisTooltip:AddAcquisition(37373, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Massive Spaulders of the Jormungar -- item:90630
BisTooltip:AddAcquisition(37626, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Wand of Sseratus -- item:90630
BisTooltip:AddAcquisition(37655, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Mantle of the Tribunal -- item:90630
BisTooltip:AddAcquisition(37849, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Planetary Helm -- item:90630
BisTooltip:AddAcquisition(43403, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Shroud of Darkness -- item:90630
BisTooltip:AddAcquisition(37139, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Spaulders of the Careless Thief -- item:90630
BisTooltip:AddAcquisition(37181, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Dagger of Betrayal -- item:90630
BisTooltip:AddAcquisition(37398, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Mantle of Discarded Ways -- item:90630
BisTooltip:AddAcquisition(37691, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Mantle of Deceit -- item:90630
BisTooltip:AddAcquisition(43280, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Faceguard of the Hammer Clan -- item:90630
BisTooltip:AddAcquisition(37222, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Egg Sac Robes -- item:90630
BisTooltip:AddAcquisition(37368, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Silent Spectator Shoulderpads -- item:90630
BisTooltip:AddAcquisition(37377, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Netherbreath Spellblade -- item:90630
BisTooltip:AddAcquisition(37679, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Spaulders of the Abomination -- item:90630
BisTooltip:AddAcquisition(37814, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Iron Dwarf Smith Pauldrons -- item:90630
BisTooltip:AddAcquisition(37258, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Drakewing Raiments -- item:90630
BisTooltip:AddAcquisition(37376, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ferocious Pauldrons of the Rhino -- item:90630
BisTooltip:AddAcquisition(37593, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Sprinting Shoulderpads -- item:90630
BisTooltip:AddAcquisition(37631, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Fist of the Deity -- item:90630
BisTooltip:AddAcquisition(37875, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Spaulders of the Violet Hold -- item:90630
BisTooltip:AddAcquisition(37260, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Cloudstrider's Waraxe -- item:90630
BisTooltip:AddAcquisition(37627, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Snake Den Spaulders -- item:90630
BisTooltip:AddAcquisition(37641, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Arcane Flame Altar-Garb -- item:90630
BisTooltip:AddAcquisition(37652, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Spaulders of Krystallus -- item:90630
BisTooltip:AddAcquisition(43410, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Moragg's Chestguard -- item:90630
BisTooltip:AddAcquisition(37165, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Crystal-Infused Tunic -- item:90630
BisTooltip:AddAcquisition(37184, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Dalronn's Jerkin -- item:90630
BisTooltip:AddAcquisition(37635, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Pauldrons of the Colossus -- item:90630
BisTooltip:AddAcquisition(37851, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ornate Woolen Stola -- item:90630
BisTooltip:AddAcquisition(37871, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- The Key -- item:90630
BisTooltip:AddAcquisition(37219, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Custodian's Chestpiece -- item:90630
BisTooltip:AddAcquisition(37256, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Scaled Armor of Drakos -- item:90630
BisTooltip:AddAcquisition(37690, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Pauldrons of Destiny -- item:90630
BisTooltip:AddAcquisition(43401, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Water-Drenched Robe -- item:90630
BisTooltip:AddAcquisition(43407, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Stormstrike Mace -- item:90630
BisTooltip:AddAcquisition(37144, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Hauberk of the Arcane Wraith -- item:90630
BisTooltip:AddAcquisition(37236, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Insect Vestments -- item:90630
BisTooltip:AddAcquisition(37370, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cuffs of the Trussed Hall -- item:90630
BisTooltip:AddAcquisition(37612, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Bonegrinder Breastplate -- item:90630
BisTooltip:AddAcquisition(37681, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Gavel of the Fleshcrafter -- item:90630
BisTooltip:AddAcquisition(37138, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Bands of Channeled Energy -- item:90630
BisTooltip:AddAcquisition(37179, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Infantry Assault Blade -- item:90630
BisTooltip:AddAcquisition(37183, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Bindings of the Tunneler -- item:90630
BisTooltip:AddAcquisition(37613, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Flame Sphere Bindings -- item:90630
BisTooltip:AddAcquisition(37658, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Sun-Emblazoned Chestplate -- item:90630
BisTooltip:AddAcquisition(37235, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Crypt Lord's Deft Blade -- item:90630
BisTooltip:AddAcquisition(37395, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ornamented Plate Regalia -- item:90630
BisTooltip:AddAcquisition(37634, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Bracers of the Divine Elemental -- item:90630
BisTooltip:AddAcquisition(37725, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Savage Wound Wrap -- item:90630
BisTooltip:AddAcquisition(40490, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Necromantic Wristguards -- item:90630
BisTooltip:AddAcquisition(37153, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gloves of the Crystal Gardener -- item:90630
BisTooltip:AddAcquisition(37255, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- The Interrogator -- item:90630
BisTooltip:AddAcquisition(37656, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Raging Construct Bands -- item:90630
BisTooltip:AddAcquisition(37722, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Breastplate of Undeath -- item:90630
BisTooltip:AddAcquisition(37724, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Handler's Arm Strap -- item:90630
BisTooltip:AddAcquisition(37230, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Grotto Mist Gloves -- item:90630
BisTooltip:AddAcquisition(37614, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gauntlets of the Plundering Geist -- item:90630
BisTooltip:AddAcquisition(37721, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Cursed Lich Blade -- item:90630
BisTooltip:AddAcquisition(37735, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ziggurat Imprinted Chestguard -- item:90630
BisTooltip:AddAcquisition(37825, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Traditionally Dyed Handguards -- item:90630
BisTooltip:AddAcquisition(37190, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Enraged Feral Staff -- item:90630
BisTooltip:AddAcquisition(37261, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gloves of Radiant Light -- item:90630
BisTooltip:AddAcquisition(37639, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Grips of the Beast God -- item:90630
BisTooltip:AddAcquisition(37843, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Giant-Hair Woven Gloves -- item:90630
BisTooltip:AddAcquisition(43310, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Engraved Chestplate of Eck -- item:90630
BisTooltip:AddAcquisition(37288, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Catalytic Bands -- item:90630
BisTooltip:AddAcquisition(37384, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Staff of Wayward Principles -- item:90630
BisTooltip:AddAcquisition(37678, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Bile-Cured Gloves -- item:90630
BisTooltip:AddAcquisition(37686, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cracked Epoch Grasps -- item:90630
BisTooltip:AddAcquisition(37687, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gloves of Distorted Time -- item:90630
BisTooltip:AddAcquisition(37617, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Staff of Sinister Claws -- item:90630
BisTooltip:AddAcquisition(37682, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Bindings of Dark Will -- item:90630
BisTooltip:AddAcquisition(37846, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Charged-Bolt Grips -- item:90630
BisTooltip:AddAcquisition(38615, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Lightning-Charged Gloves -- item:90630
BisTooltip:AddAcquisition(43287, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Silken Bridge Handwraps -- item:90630
BisTooltip:AddAcquisition(37217, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Golden Limb Bands -- item:90630
BisTooltip:AddAcquisition(37680, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Belt of Unified Souls -- item:90630
BisTooltip:AddAcquisition(37714, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Batrider's Cord -- item:90630
BisTooltip:AddAcquisition(37848, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Lightning Giant Staff -- item:90630
BisTooltip:AddAcquisition(37868, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Girdle of the Ethereal -- item:90630
BisTooltip:AddAcquisition(37628, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Slad'ran's Coiled Cord -- item:90630
BisTooltip:AddAcquisition(37729, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Grips of Sculptured Icicles -- item:90630
BisTooltip:AddAcquisition(37850, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Flowing Sash of Order -- item:90630
BisTooltip:AddAcquisition(38616, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Maiden's Girdle -- item:90630
BisTooltip:AddAcquisition(43409, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Saliva Corroded Pike -- item:90630
BisTooltip:AddAcquisition(37289, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Sash of Phantasmal Images -- item:90630
BisTooltip:AddAcquisition(37842, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Belt of Vivacity -- item:90630
BisTooltip:AddAcquisition(37845, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cord of Swirling Winds -- item:90630
BisTooltip:AddAcquisition(37862, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gauntlets of the Water Revenant -- item:90630
BisTooltip:AddAcquisition(43281, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Edge of Oblivion -- item:90630
BisTooltip:AddAcquisition(37155, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Frozen Forest Kilt -- item:90630
BisTooltip:AddAcquisition(37389, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Crenelation Leggings -- item:90630
BisTooltip:AddAcquisition(37637, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Living Mojo Belt -- item:90630
BisTooltip:AddAcquisition(37874, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gauntlets of Capture -- item:90630
BisTooltip:AddAcquisition(38618, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Hammer of Grief -- item:90630
BisTooltip:AddAcquisition(37178, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Strategist's Belt -- item:90630
BisTooltip:AddAcquisition(37221, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Hollowed Mandible Legplates -- item:90630
BisTooltip:AddAcquisition(37616, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Kilt of the Forgotten One -- item:90630
BisTooltip:AddAcquisition(37731, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Opposed Stasis Leggings -- item:90630
BisTooltip:AddAcquisition(37733, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Mojo Masked Crusher -- item:90630
BisTooltip:AddAcquisition(37379, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Skadi's Iron Belt -- item:90630
BisTooltip:AddAcquisition(37653, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sword of Justice -- item:90630
BisTooltip:AddAcquisition(37818, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Patroller's War-Kilt -- item:90630
BisTooltip:AddAcquisition(37876, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cyanigosa's Leggings -- item:90630
BisTooltip:AddAcquisition(43286, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Legguards of Swarming Attacks -- item:90630
BisTooltip:AddAcquisition(37162, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Bulwark of the Noble Protector -- item:90630
BisTooltip:AddAcquisition(37262, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Azure Ringmail Leggings -- item:90630
BisTooltip:AddAcquisition(37374, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ravenous Leggings of the Furbolg -- item:90630
BisTooltip:AddAcquisition(37826, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- The General's Steel Girdle -- item:90630
BisTooltip:AddAcquisition(43313, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Leggings of the Ruins Dweller -- item:90630
BisTooltip:AddAcquisition(37152, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Girdle of Ice -- item:90630
BisTooltip:AddAcquisition(37167, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Dragon Slayer's Sabatons -- item:90630
BisTooltip:AddAcquisition(37189, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Breeches of the Caller -- item:90630
BisTooltip:AddAcquisition(37216, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Facade Shield of Glyphs -- item:90630
BisTooltip:AddAcquisition(37841, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Slag Footguards -- item:90630
BisTooltip:AddAcquisition(37292, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ley-Guardian's Legguards -- item:90630
BisTooltip:AddAcquisition(37369, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Sorrowgrave's Breeches -- item:90630
BisTooltip:AddAcquisition(37654, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Sabatons of the Ages -- item:90630
BisTooltip:AddAcquisition(37718, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Temple Crystal Fragment -- item:90630
BisTooltip:AddAcquisition(43312, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Gorloc Muddy Footwraps -- item:90630
BisTooltip:AddAcquisition(37134, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Telestra's Journal -- item:90630
BisTooltip:AddAcquisition(37640, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Boots of Transformation -- item:90630
BisTooltip:AddAcquisition(37650, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Shardling Legguards -- item:90630
BisTooltip:AddAcquisition(37730, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cleric's Linen Shoes -- item:90630
BisTooltip:AddAcquisition(37870, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Twin-Headed Boots -- item:90630
BisTooltip:AddAcquisition(37595, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Necklace of Taldaram -- item:90630
BisTooltip:AddAcquisition(37666, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Boots of the Whirling Mist -- item:90630
BisTooltip:AddAcquisition(37675, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Legplates of Steel Implants -- item:90630
BisTooltip:AddAcquisition(37788, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Limb Regeneration Bracers -- item:90630
BisTooltip:AddAcquisition(37867, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Footwraps of Teleportation -- item:90630
BisTooltip:AddAcquisition(37170, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Interwoven Scale Bracers -- item:90630
BisTooltip:AddAcquisition(37218, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Stone-Worn Footwraps -- item:90630
BisTooltip:AddAcquisition(37683, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Necromancer's Amulet -- item:90630
BisTooltip:AddAcquisition(37688, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Legplates of the Infinite Drakonid -- item:90630
BisTooltip:AddAcquisition(37696, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Plague-Infected Bracers -- item:90630
BisTooltip:AddAcquisition(37629, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Slithering Slippers -- item:90630
BisTooltip:AddAcquisition(37689, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Pendant of the Nathrezim -- item:90630
BisTooltip:AddAcquisition(37717, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Legs of Physical Regeneration -- item:90630
BisTooltip:AddAcquisition(37853, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Advanced Tooled-Leather Bands -- item:90630
BisTooltip:AddAcquisition(37886, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Handgrips of the Savage Emissary -- item:90630
BisTooltip:AddAcquisition(37263, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Legplates of the Oculus Guardian -- item:90630
BisTooltip:AddAcquisition(37409, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Gilt-Edged Leather Gauntlets -- item:90630
BisTooltip:AddAcquisition(37623, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Fiery Obelisk Handguards -- item:90630
BisTooltip:AddAcquisition(37630, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Shroud of Moorabi -- item:90630
BisTooltip:AddAcquisition(43282, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Shadowseeker's Pendant -- item:90630
BisTooltip:AddAcquisition(37367, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Echoing Stompers -- item:90630
BisTooltip:AddAcquisition(37643, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sash of Blood Removal -- item:90630
BisTooltip:AddAcquisition(37728, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cloak of the Enemy -- item:90630
BisTooltip:AddAcquisition(37855, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Mail Girdle of the Audient Earth -- item:90630
BisTooltip:AddAcquisition(37861, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Necklace of Arcane Spheres -- item:90630
BisTooltip:AddAcquisition(37194, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sharp-Barbed Leather Belt -- item:90630
BisTooltip:AddAcquisition(37407, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sovereign's Belt -- item:90630
BisTooltip:AddAcquisition(37618, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Greaves of Ancient Evil -- item:90630
BisTooltip:AddAcquisition(37840, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Shroud of Reverberation -- item:90630
BisTooltip:AddAcquisition(43404, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Zuramat's Necklace -- item:90630
BisTooltip:AddAcquisition(37141, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Amulet of Dazzling Light -- item:90630
BisTooltip:AddAcquisition(37632, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Mojo Frenzy Greaves -- item:90630
BisTooltip:AddAcquisition(37695, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Legguards of Nature's Power -- item:90630
BisTooltip:AddAcquisition(37791, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Leggings of the Winged Serpent -- item:90630
BisTooltip:AddAcquisition(43283, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Subterranean Waterfall Shroud -- item:90630
BisTooltip:AddAcquisition(37397, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Gold Amulet of Kings -- item:90630
BisTooltip:AddAcquisition(37644, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Gored Hide Legguards -- item:90630
BisTooltip:AddAcquisition(37669, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Leggings of the Stone Halls -- item:90630
BisTooltip:AddAcquisition(37712, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Terrace Defence Boots -- item:90630
BisTooltip:AddAcquisition(43406, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Cloak of the Gushing Wound -- item:90630
BisTooltip:AddAcquisition(37291, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Ancient Dragon Spirit Cape -- item:90630
BisTooltip:AddAcquisition(37847, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Skywall Striders -- item:90630
BisTooltip:AddAcquisition(43285, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Amulet of the Spell Flinger -- item:90630
BisTooltip:AddAcquisition(37361, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Cuffs of Winged Levitation -- item:90630
BisTooltip:AddAcquisition(37732, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Spectral Seal of the Prophet -- item:90630
BisTooltip:AddAcquisition(43402, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- The Obliterator Greaves -- item:90630
BisTooltip:AddAcquisition(37685, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Mobius Band -- item:90630
BisTooltip:AddAcquisition(37884, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Azure Cloth Bindings -- item:90630
BisTooltip:AddAcquisition(43405, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Sabatons of Erekem -- item:90630
BisTooltip:AddAcquisition(37150, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 10 } } }) -- Rift Striders -- item:90630
BisTooltip:AddAcquisition(37651, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- The Prospector's Prize -- item:90630
BisTooltip:AddAcquisition(37798, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Overlook Handguards -- item:90630
BisTooltip:AddAcquisition(37172, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Gloves of Glistening Runes -- item:90630
BisTooltip:AddAcquisition(37240, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Flamebeard's Bracers -- item:90630
BisTooltip:AddAcquisition(37371, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Ring of the Frenzied Wolvar -- item:90630
BisTooltip:AddAcquisition(37151, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Band of Frosted Thorns -- item:90630
BisTooltip:AddAcquisition(37242, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sash of the Servant -- item:90630
BisTooltip:AddAcquisition(37620, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Bracers of the Herald -- item:90630
BisTooltip:AddAcquisition(37186, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Unsmashable Heavy Band -- item:90630
BisTooltip:AddAcquisition(37408, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Girdle of Bane -- item:90630
BisTooltip:AddAcquisition(37668, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Bands of the Stoneforge -- item:90630
BisTooltip:AddAcquisition(37195, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Band of Enchanted Growth -- item:90630
BisTooltip:AddAcquisition(37645, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Horn-Tipped Gauntlets -- item:90630
BisTooltip:AddAcquisition(37854, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Woven Bracae Leggings -- item:90630
BisTooltip:AddAcquisition(37232, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Ring of the Traitor King -- item:90630
BisTooltip:AddAcquisition(37363, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Gauntlets of Dragon Wrath -- item:90630
BisTooltip:AddAcquisition(37622, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Skirt of the Old Kingdom -- item:90630
BisTooltip:AddAcquisition(37241, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Ancient Aligned Girdle -- item:90630
BisTooltip:AddAcquisition(37257, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Band of Torture -- item:90630
BisTooltip:AddAcquisition(37171, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Flame-Bathed Steel Girdle -- item:90630
BisTooltip:AddAcquisition(43408, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Solitaire of Reflecting Beams -- item:90630
BisTooltip:AddAcquisition(37591, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Nerubian Shield Ring -- item:90630
BisTooltip:AddAcquisition(37670, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sjonnir's Girdle -- item:90630
BisTooltip:AddAcquisition(37362, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Leggings of Protective Auras -- item:90630
BisTooltip:AddAcquisition(38617, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Woeful Band -- item:90630
BisTooltip:AddAcquisition(37869, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Globule Signet -- item:90630
BisTooltip:AddAcquisition(43500, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Bolstered Legplates -- item:90630
BisTooltip:AddAcquisition(37193, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Staggering Legplates -- item:90630
BisTooltip:AddAcquisition(37390, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Meteorite Whetstone -- item:90630
BisTooltip:AddAcquisition(37638, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Offering of Sacrifice -- item:90630
BisTooltip:AddAcquisition(37657, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Spark of Life -- item:90630
BisTooltip:AddAcquisition(37660, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Forge Ember -- item:90630
BisTooltip:AddAcquisition(37723, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Incisor Fragment -- item:90630
BisTooltip:AddAcquisition(37734, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Talisman of Troll Divinity -- item:90630
BisTooltip:AddAcquisition(37844, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Winged Talisman -- item:90630
BisTooltip:AddAcquisition(37872, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Lavanthor's Talisman -- item:90630
BisTooltip:AddAcquisition(37873, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Mark of the War Prisoner -- item:90630
BisTooltip:AddAcquisition(37166, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Sphere of Red Dragon's Blood -- item:90630
BisTooltip:AddAcquisition(37264, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Pendulum of Telluric Currents -- item:90630
BisTooltip:AddAcquisition(37220, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Essence of Gossamer -- item:90630
BisTooltip:AddAcquisition(37111, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Soul Preserver -- item:90630
BisTooltip:AddAcquisition(36993, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Seal of the Pantheon -- item:90630
BisTooltip:AddAcquisition(36972, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Tome of Arcane Phenomena -- item:90630
BisTooltip:AddAcquisition(37064, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Vestige of Haldor -- item:90630
BisTooltip:AddAcquisition(37238, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Rod of the Fallen Monarch -- item:90630
BisTooltip:AddAcquisition(37619, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Wand of Ahn'kahet -- item:90630
BisTooltip:AddAcquisition(37191, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Drake-Mounted Crossbow -- item:90630
BisTooltip:AddAcquisition(37169, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- War Mace of Unrequited Love -- item:90630
BisTooltip:AddAcquisition(37401, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Red Sword of Courage -- item:90630
BisTooltip:AddAcquisition(37667, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- The Fleshshaper -- item:90630
BisTooltip:AddAcquisition(37693, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Greed -- item:90630
BisTooltip:AddAcquisition(43085, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Royal Crest of Lordaeron -- item:90630
BisTooltip:AddAcquisition(37852, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Colossal Skull-Clad Cleaver -- item:90630
BisTooltip:AddAcquisition(37360, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Staff of Draconic Combat -- item:90630
BisTooltip:AddAcquisition(37883, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Staff of Trickery -- item:90630
BisTooltip:AddAcquisition(37694, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Band of Guile -- item:90630
BisTooltip:AddAcquisition(37784, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Keystone Great-Ring -- item:90630
BisTooltip:AddAcquisition(37642, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Hemorrhaging Circle -- item:90630
BisTooltip:AddAcquisition(37192, { kind = "VENDOR", cost = { { currency = "Emblem of Resolve", amount = 15 } } }) -- Annhylde's Ring -- item:90630


--ENCHANTY
BisTooltip:SetAcquisition(5000759, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Damage All -- item:5000971
BisTooltip:SetAcquisition(5000760, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Reduce All -- item:5000971
BisTooltip:SetAcquisition(5000761, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Heal All -- item:5000971
BisTooltip:SetAcquisition(5000763, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Huge Rocket -- item:5000971
BisTooltip:SetAcquisition(5000764, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Lightning Empowerement -- item:5000971
BisTooltip:SetAcquisition(5000765, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Critical Empowerement -- item:5000971
BisTooltip:SetAcquisition(5000766, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Evasive Empowerement -- item:5000971
BisTooltip:SetAcquisition(5000767, { { kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } } }, P) -- Scroll of Enchant Necklace - Restoration -- item:5000971



