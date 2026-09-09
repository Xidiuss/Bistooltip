-- ============================================================
-- EmblemData.lua - Emblem vendor item database
-- ============================================================
-- This file contains mappings of items that can be purchased with emblems.
-- Custom server content lives in server plugins (e.g. Bistooltip_Whitemane_Frostmourne), not in core.

-- Initialize the emblem items table
Bistooltip_emblem_items = Bistooltip_emblem_items or {}

-- ============================================================
-- Helper function to register items
-- ============================================================

local function RegisterEmblemItems(currency, items)
    for itemId, cost in pairs(items) do
        Bistooltip_emblem_items[itemId] = {
            currency = currency,
            cost = cost,
        }
        
        -- Also register in Constants if available
        if BistooltipConstants and BistooltipConstants.RegisterEmblemItem then
            BistooltipConstants.RegisterEmblemItem(itemId, currency, cost)
        end
    end
end

-- ============================================================
-- Emblem of Ascension Items (Custom Server)
-- Format: [itemId] = cost
-- 
-- To find item IDs:
-- 1. Use /script print(GetItemInfo("item:ITEMID"))
-- 2. Or check wowhead.com URL: wowhead.com/wotlk/item=ITEMID
-- 
-- Example: Sanctified T10 gear typically costs 60-95 emblems
-- ============================================================

local FROST_ITEMS = {
    -- ==================
    -- Tier 10 Sanctified (264 -> 277)
    -- These are example items - uncomment and adjust for your server
    -- ==================
    
    -- Death Knight
    [51312] = 95,  -- Sanctified Scourgelord Helmet
    [51314] = 60,  -- Sanctified Scourgelord Shoulderplates
    [51310] = 95,  -- Sanctified Scourgelord Battleplate
    [51313] = 60,  -- Sanctified Scourgelord Gauntlets
    [51311] = 95,  -- Sanctified Scourgelord Legplates
    
    -- Druid
    [51147] = 95,  -- Sanctified Lasherweave Helmet
    [51149] = 60,  -- Sanctified Lasherweave Pauldrons
    [51145] = 95,  -- Sanctified Lasherweave Robes
    [51148] = 60,  -- Sanctified Lasherweave Gloves
    [51146] = 95,  -- Sanctified Lasherweave Legplates
    
    -- Hunter
    [51286] = 95,  -- Sanctified Ahn'Kahar Blood Hunter's Headpiece
    [51288] = 60,  -- Sanctified Ahn'Kahar Blood Hunter's Spaulders
    [51289] = 95,  -- Sanctified Ahn'Kahar Blood Hunter's Tunic
    [51287] = 60,  -- Sanctified Ahn'Kahar Blood Hunter's Handguards
    [51285] = 95,  -- Sanctified Ahn'Kahar Blood Hunter's Legguards
    
    -- Mage
    [51281] = 95,  -- Sanctified Bloodmage Hood
    [51284] = 60,  -- Sanctified Bloodmage Shoulderpads
    [51282] = 95,  -- Sanctified Bloodmage Robe
    [51280] = 60,  -- Sanctified Bloodmage Gloves
    [51283] = 95,  -- Sanctified Bloodmage Leggings
    
    -- Paladin
    [51167] = 95,  -- Sanctified Lightsworn Faceguard (Tank)
    [51161] = 95,  -- Sanctified Lightsworn Headpiece (Holy)
    [51277] = 95,  -- Sanctified Lightsworn Helmet (Ret)
    [51169] = 60,  -- Sanctified Lightsworn Shoulderguards (Tank)
    [51163] = 60,  -- Sanctified Lightsworn Spaulders (Holy)
    [51279] = 60,  -- Sanctified Lightsworn Shoulderplates (Ret)
    
    -- Priest
    [51261] = 95,  -- Sanctified Crimson Acolyte Hood (Shadow)
    [51178] = 95,  -- Sanctified Crimson Acolyte Cowl (Heal)
    [51264] = 60,  -- Sanctified Crimson Acolyte Shoulderpads (Shadow)
    [51181] = 60,  -- Sanctified Crimson Acolyte Mantle (Heal)
    
    -- Rogue
    [51252] = 95,  -- Sanctified Shadowblade Helmet
    [51254] = 60,  -- Sanctified Shadowblade Pauldrons
    [51253] = 95,  -- Sanctified Shadowblade Breastplate
    [51251] = 60,  -- Sanctified Shadowblade Gauntlets
    [51250] = 95,  -- Sanctified Shadowblade Legplates
    
    -- Shaman
    [51242] = 95,  -- Sanctified Frost Witch's Headpiece (Ele)
    [51202] = 95,  -- Sanctified Frost Witch's Faceguard (Enh)
    [51192] = 95,  -- Sanctified Frost Witch's Helm (Resto)
    [51244] = 60,  -- Sanctified Frost Witch's Shoulderpads (Ele)
    [51204] = 60,  -- Sanctified Frost Witch's Shoulderguards (Enh)
    [51194] = 60,  -- Sanctified Frost Witch's Spaulders (Resto)
    
    -- Warlock
    [51232] = 95,  -- Sanctified Dark Coven Hood
    [51234] = 60,  -- Sanctified Dark Coven Shoulderpads
    [51231] = 95,  -- Sanctified Dark Coven Robe
    [51233] = 60,  -- Sanctified Dark Coven Gloves
    [51230] = 95,  -- Sanctified Dark Coven Leggings
    
    -- Warrior
    [51227] = 95,  -- Sanctified Ymirjar Lord's Helmet (DPS)
    [51217] = 95,  -- Sanctified Ymirjar Lord's Greathelm (Tank)
    [51229] = 60,  -- Sanctified Ymirjar Lord's Pauldrons (DPS)
    [51219] = 60,  -- Sanctified Ymirjar Lord's Shoulderplates (Tank)
    
 
    -- Tier 10 (ilvl 251)
    -- Death Knight
    [50096] = 95,  -- Scourgelord Helmet
    [50098] = 60,  -- Scourgelord Shoulderplates
    [50094] = 95,  -- Scourgelord Battleplate
    [50095] = 60,  -- Scourgelord Gauntlets
    [50097] = 95,  -- Scourgelord Legplates
    
    -- Druid
    [50107] = 95,  -- Lasherweave Helmet
    [50109] = 60,  -- Lasherweave Pauldrons
    [50106] = 95,  -- Lasherweave Robes
    [50108] = 60,  -- Lasherweave Gloves
    [50105] = 95,  -- Lasherweave Legplates
    
    -- Mage
    [50276] = 95,  -- Bloodmage Hood
    [50279] = 60,  -- Bloodmage Shoulderpads
    [50277] = 95,  -- Bloodmage Robe
    [50275] = 60,  -- Bloodmage Gloves
    [50278] = 95,  -- Bloodmage Leggings
    
    -- Priest (Shadow)
    [50392] = 95,  -- Crimson Acolyte Hood
    [50396] = 60,  -- Crimson Acolyte Shoulderpads
    [50394] = 95,  -- Crimson Acolyte Robe
    [50391] = 60,  -- Crimson Acolyte Gloves
    [50393] = 95,  -- Crimson Acolyte Pants
    
    -- Rogue
    [50088] = 95,  -- Shadowblade Helmet
    [50090] = 60,  -- Shadowblade Pauldrons
    [50089] = 95,  -- Shadowblade Breastplate
    [50087] = 60,  -- Shadowblade Gauntlets
    [50086] = 95,  -- Shadowblade Legplates
    
    -- Warlock
    [50241] = 95,  -- Dark Coven Hood
    [50244] = 60,  -- Dark Coven Shoulderpads
    [50242] = 95,  -- Dark Coven Robe
    [50240] = 60,  -- Dark Coven Gloves
    [50243] = 95,  -- Dark Coven Leggings
    
    -- Warrior
    [50080] = 95,  -- Ymirjar Lord's Helmet
    [50082] = 60,  -- Ymirjar Lord's Pauldrons
    [50078] = 95,  -- Ymirjar Lord's Battleplate
    [50079] = 60,  -- Ymirjar Lord's Gauntlets
    [50081] = 95,  -- Ymirjar Lord's Legplates


    -- Back
    [50468] = 50,        -- Drape of the Violet Tower
    [50467] = 50,        -- Might of the Ocean Serpent
    [50470] = 50,        -- Recovered Scarlet Onslaught Cape
    [50466] = 50,        -- Sentinel's Winter Cloak
    [50469] = 50,        -- Volde's Cloak of the Night Sky
    -- Hands
    [50980] = 60,        -- Blizzard Keeper's Mitts
    [50982] = 60,        -- Cat Burglar's Grips
    [50977] = 60,        -- Gatecrasher's Gauntlets
    [50976] = 60,        -- Gauntlets of Overexposure
    [50978] = 60,        -- Gauntlets of the Kraken
    [50984] = 60,        -- Gloves of Ambivalence
    [50983] = 60,        -- Gloves of False Gestures
    [50981] = 60,        -- Gloves of the Great Horned Owl
    [50979] = 60,        -- Logsplitters
    -- Waist
    [50989] = 60,        -- Lich Killer's Lanyard
    [50474] = 30,        -- Shrapnel Star
    [50458] = 30,        -- Bizuri's Totem of Shattered Ice
    [50454] = 30,        -- Idol of the Black Willow
    [50456] = 30,        -- Idol of the Crying Moon
    [50457] = 30,        -- Idol of the Lunar Eclipse
    [50460] = 30,        -- Libram of Blinding Light
    [50455] = 30,        -- Libram of Three Truths
    [50461] = 30,        -- Libram of the Eternal Tower
    [50462] = 30,        -- Sigil of the Bone Gryphon
    [50459] = 30,        -- Sigil of the Hanged Man
    [50463] = 30,        -- Totem of the Avalanche
    [50464] = 30,        -- Totem of the Surging Sea
    -- Trinket
    [50356] = 60,        -- Corroded Skeleton Key
    [50355] = 60,        -- Herkuml War Token
    [50357] = 60,        -- Maghia's Misguided Quill
    [50358] = 60,        -- Purified Lunar Dust
    -- Waist
    [50996] = 60,        -- Belt of Omission
    [50994] = 60,        -- Belt of Petrified Ivy
    [50997] = 60,        -- Circle of Ossus
    [50987] = 60,        -- Malevolent Girdle
    [50995] = 60,        -- Vengeful Noose
    [50991] = 60,        -- Verdigris Chain Belt
    [50992] = 60,        -- Waistband of Despair

}

RegisterEmblemItems("Emblem of Frost", FROST_ITEMS)

-- ============================================================
-- Emblem of Triumph Items
-- ============================================================

local TRIUMPH_ITEMS = {

    -- Chest
    [50965] = 50,        -- Castle Breaker's Battleplate
    [50968] = 50,        -- Cataclysmic Chestguard
    [50969] = 50,        -- Chestplate of Unspoken Truths
    [50975] = 50,        -- Ermine Coronation Robes
    [50970] = 50,        -- Longstrider's Vest
    [50971] = 50,        -- Mail of the Geyser
    [50974] = 50,        -- Meteor Chaser's Raiment
    [50972] = 50,        -- Shadow Seeker's Tunic
    [50973] = 50,        -- Vestments of Spruce and Fir
    -- Finger
    [47732] = 35,        -- Band of the Invoker
    [47729] = 35,        -- Bloodshed Band
    [47731] = 35,        -- Clutch of Fortification
    [47730] = 35,        -- Dexterous Brightstone Ring
    [47733] = 35,        -- Heartmender Circle
    [50993] = 35,        -- Band of the Night Raven

    -- Head
    [47688] = 75,        -- Mask of Lethal Intent
    [47691] = 75,        -- Mask of Abundant Growth
    [47692] = 75,        -- Hood of Smoldering Aftermath
    [47695] = 75,        -- Hood of Clouded Sight
    [47682] = 75,        -- Helm of the Restless Watch
    [47678] = 75,        -- Headplate of the Honorbound
    [47687] = 75,        -- Headguard of Inner Warmth
    [47675] = 75,        -- Faceplate of Thunderous Rampage
    [47684] = 75,        -- Coif of the Brooding Dragon
    -- Thrown
    [47660] = 25,        -- Blades of the Sable Cross
    [47659] = 25,        -- Crimson Star
    -- Relic
    [47667] = 19,        -- Totem of Quaking Earth
    [47666] = 25,        -- Totem of Electrifying Wind
    [47665] = 25,        -- Totem of Calming Tides
    [47673] = 25,        -- Sigil of Virulence
    [47672] = 25,        -- Sigil of Insolence
    [47662] = 25,        -- Libram of Veracity
    [47661] = 25,        -- Libram of Valiance
    [47664] = 25,        -- Libram of Defiance
    [47668] = 25,        -- Idol of Mutilation
    [47670] = 25,        -- Idol of Lunar Fury
    [47671] = 25,        -- Idol of Flaring Growth
    -- Shoulder
    [47706] = 45,        -- Shoulders of the Groundbreaker
    [47701] = 45,        -- Shoulderplates of the Cavalier
    [47696] = 45,        -- Shoulderplates of Trembling Rage
    [47699] = 45,        -- Shoulderguards of Enduring Order
    [47705] = 45,        -- Pauldrons of the Devourer
    [47714] = 45,        -- Pauldrons of Catastrophic Emanation
    [47716] = 45,        -- Mantle of Revered Mortality
    [47710] = 45,        -- Epaulets of the Fateful Accord
    [47709] = 45,        -- Duskstalker Pauldrons
    -- Trinket
    [48724] = 50,        -- Talisman of Resurgence
    [48722] = 50,        -- Shard of the Crystal Heart
    [47734] = 50,        -- Mark of Supremacy
    [47735] = 50,        -- Glyph of Indomitability
    [47658] = 25,        -- Brimstone Igniter

}

RegisterEmblemItems("Emblem of Triumph", TRIUMPH_ITEMS)


-- ============================================================
-- Emblem of Conquest Items
-- ============================================================
local CONQUEST_ITEMS = {

-- Head (Token T8)
    [45639] = 58,        -- Crown of the Wayward Protector
    [45633] = 58,        -- Breastplate of the Wayward Protector

    -- Relic
    [45144] = 19,        -- Sigil of Deflection
    [45254] = 19,        -- Sigil of the Vengeful Heart
    [45114] = 19,        -- Steamcaller's Totem
    [45255] = 19,        -- Thunderfall Totem
    [45169] = 19,        -- Totem of the Dancing Flame
    [45509] = 19,        -- Idol of the Corruptor
    [45270] = 19,        -- Idol of the Crying Wind
    [46138] = 19,        -- Idol of the Flourishing Life
    [45436] = 19,        -- Libram of the Resolute
    [45510] = 19,        -- Libram of Discord
    [45145] = 19,        -- Libram of the Sacred Shield

    -- Hands
    [45833] = 28,        -- Bladebreaker Gauntlets
    [45834] = 28,        -- Gauntlets of the Royal Watch
    [45835] = 28,        -- Gauntlets of Serene Blessing
    [45836] = 28,        -- Gloves of Unerring Aim
    [45837] = 28,        -- Gloves of Augury
    [45838] = 28,        -- Gloves of the Blind Stalker
    [45839] = 28,        -- Grips of the Secret Grove
    [45840] = 28,        -- Touch of the Occult
    -- Legs
    [45841] = 39,        -- Legplates of the Violet Champion
    [45842] = 39,        -- Wyrmguard Legplates
    [45843] = 39,        -- Legguards of the Peaceful Covenant
    [45844] = 39,        -- Leggings of the Tireless Sentry
    [45845] = 39,        -- Leggings of the Weary Mystic
    [45846] = 39,        -- Leggings of Wavering Shadow
    [45847] = 39,        -- Wildstrider Legguards
    [45848] = 39,        -- Legwraps of the Master Conjurer
    -- Neck
    [45819] = 25,        -- Spiked Battleguard Choker
    [45820] = 25,        -- Broach of the Wailing Night
    [45821] = 25,        -- Shard of the Crystal Forest
    [45822] = 25,        -- Evoker's Charm
    [45823] = 25,        -- Frozen Tear of Elune
    -- Waist
    [45824] = 28,        -- Belt of the Singing Blade
    [45825] = 28,        -- Shieldwarder Girdle
    [45826] = 28,        -- Girdle of Unyielding Trust
    [45827] = 28,        -- Belt of the Ardent Marksman
    [45828] = 28,        -- Windchill Binding
    [45829] = 28,        -- Belt of the Twilight Assassin
    [45830] = 28,        -- Belt of the Living Thicket
    [45831] = 28,        -- Sash of Potent Incantations
    }
RegisterEmblemItems("Emblem of Conquest", CONQUEST_ITEMS)


-- ============================================================
-- Emblem of Valor Items
-- ============================================================

local VALOR_ITEMS = {

    -- Chest (Token T7)
    [40635] = 75,        -- Legplates of the Lost Protector
    [40638] = 60,        -- Mantle of the Lost Protector
    -- Back
    [40724] = 25,        -- Cloak of Kea Feathers
    [40723] = 25,        -- Disguise of the Kumiho
    [40722] = 25,        -- Platinum Mesh Cloak
    [40721] = 25,        -- Hammerhead Sharkskin Cloak
    [40751] = 40,        -- Slippers of the Holy Light
    [40750] = 40,        -- Xintor's Expeditionary Boots
    [40749] = 40,        -- Rainey's Chewed Boots
    [40748] = 40,        -- Boots of Captain Ellis
    [40747] = 40,        -- Treads of Coastal Wandering
    [40746] = 40,        -- Pack-Ice Striders
    [40745] = 40,        -- Sabatons of Rapid Recovery
    [40743] = 40,        -- Kyzoc's Ground Stompers
    [40742] = 40,        -- Bladed Steelboots
    -- Finger
    [40719] = 25,        -- Band of Channeled Magic
    [40718] = 25,        -- Signet of the Impregnable Fortress
    [40717] = 25,        -- Ring of Invincibility
    [40720] = 25,        -- Renewal of Life
    -- Relic
    [40342] = 15,        -- Idol of Awakening
    [40337] = 15,        -- Libram of Resurgence
    [40322] = 15,        -- Totem of Dueling
    [40321] = 15,        -- Idol of the Shooting Star
    [40268] = 15,        -- Libram of Tolerance
    [40267] = 15,        -- Totem of Hex
    [40207] = 15,        -- Sigil of Awareness
    [40191] = 15,        -- Libram of Radiance
    [39757] = 15,        -- Idol of Worship
    [39728] = 15,        -- Totem of Misery

    -- Wrist
    [40741] = 60,        -- Cuffs of the Shadow Ascendant
    [40740] = 60,        -- Wraps of the Astral Traveler
    [40739] = 60,        -- Bands of the Great Tree
    [40738] = 60,        -- Wristwraps of the Cutthroat
    [40737] = 60,        -- Pigmented Clan Bindings
    [40736] = 60,        -- Armguard of the Tower Archer
    [40735] = 60,        -- Zartson's Jungle Vambraces
    [40734] = 60,        -- Bracers of Dalaran's Parapets
    [40733] = 60,        -- Wristbands of the Sentinel Huntress


}

RegisterEmblemItems("Emblem of Valor", VALOR_ITEMS)


-- ============================================================
-- Emblem of Heroism Items
-- ============================================================

local Heroism_ITEMS = {

 
-- Chest (Token T7)
[40611] = 80,        -- Chestguard of the Lost Protector
[40614] = 60,        -- Gloves of the Lost Protector
-- Neck
[40678] = 25,        -- Pendant of the Outcast Hero
[40679] = 25,        -- Chained Military Gorget
[40680] = 25,        -- Encircling Burnished Gold Chains
[40681] = 25,        -- Lattice Choker of Light
[40698] = 40,        -- Ward of the Violet Citadel
[40699] = 40,        -- Handbook of Obscure Remedies
-- One-Hand
[40702] = 50,        -- Rolfsen's Ripper
[40703] = 50,        -- Grasscutter
[40704] = 50,        -- Pride
-- Shield
[40700] = 40,        -- Protective Barricade of the Light
[40701] = 40,        -- Crygil's Discarded Plate Panel
-- Trinket
[40682] = 40,        -- Sundial of the Exiled
[40683] = 40,        -- Valor Medal of the First War
[40684] = 40,        -- Mirror of Truth
[40685] = 40,        -- The Egg of Mortal Essence
[37111] = 60,        -- Soul Preserver
-- Waist
[40688] = 40,        -- Verdungo's Barbarian Cord
[40689] = 40,        -- Waistguard of Living Iron
[40691] = 40,        -- Magroth's Meditative Cincture
[40692] = 40,        -- Vereesa's Silver Chain Belt
[40693] = 40,        -- Beadwork Belt of Shamanic Vision
[40694] = 40,        -- Jorach's Crocolisk Skin Belt
[40695] = 40,        -- Vine Belt of the Woodland Dryad
[40696] = 40,        -- Plush Sash of Guzbah
[40697] = 40,        -- Elegant Temple Gardens' Girdle

--libram
[40705] = 15,        -- Libram of Resurgence
[40706] = 15,        -- Libram of Tolerance
[40707] = 15,        -- Libram of Radiance
[40715] = 15,        -- Sigil of Haunted Dreams
[40714] = 15,        -- Sigil of the Unfaltering Knight
[40713] = 15,        -- Idol of the Ravenous Beast
[40712] = 15,        -- Idol of Steadfast Renewal
[40711] = 15,        -- Idol of Lush Moss
[40710] = 15,        -- Totem of Splintering
[40709] = 15,        -- Totem of Forest Growth
[40708] = 15,        -- Totem of the Elemental Plane

--thrown
[40716] = 15,        -- Lillehoff's Winged Blades

}

RegisterEmblemItems("Emblem of Heroism", Heroism_ITEMS)

-- ============================================================
-- Emblem of Ascension Items
-- ============================================================

-- Custom server currencies (Emblem of Ascension / Ascension II, Echo of the
-- Titans) moved to Bistooltip_Whitemane_Frostmourne (spec W6): core stays
-- clean WotLK. Add your own server via a plugin, not here.

-- ============================================================
-- T8 Set Auto-Registration (from BIS lists)
-- ============================================================
-- Scans the T8 phase of all BIS lists and registers class-specific
-- set piece items with the appropriate Emblem of Ascension II cost.
--
-- Logic:
--   - Only registers items that appear in exactly ONE class (class-specific = set piece)
--   - Items shared across multiple classes (non-set drops) are skipped
--   - Items already registered in any emblem table are preserved as-is
--
-- Slot costs (mirror the T8 token costs):
--   Head / Chest / Legs  = 25 emblems
--   Shoulder / Hands     = 19 emblems
-- ============================================================

local function RegisterT8SetFromBislist()
    if not Bistooltip_wowtbc_bislists then return end

    local slotCosts = {
        ["Head"]     = 25,
        ["Shoulder"] = 19,
        ["Chest"]    = 25,
        ["Hands"]    = 19,
        ["Legs"]     = 25,
    }

    -- Pass 1: for every item in T8 set slots, record which classes use it
    local itemClasses = {}
    for className, classData in pairs(Bistooltip_wowtbc_bislists) do
        for _, specData in pairs(classData) do
            local t8Data = specData["T8"]
            if t8Data then
                for _, slotData in ipairs(t8Data) do
                    if slotCosts[slotData["slot_name"]] then
                        local i = 1
                        while slotData[i] do
                            local itemId = slotData[i]
                            if not itemClasses[itemId] then
                                itemClasses[itemId] = {}
                            end
                            itemClasses[itemId][className] = true
                            i = i + 1
                        end
                    end
                end
            end
        end
    end

    -- Pass 2: register class-specific items not already in any emblem table
    for className, classData in pairs(Bistooltip_wowtbc_bislists) do
        for _, specData in pairs(classData) do
            local t8Data = specData["T8"]
            if t8Data then
                for _, slotData in ipairs(t8Data) do
                    local slotName = slotData["slot_name"]
                    local cost = slotCosts[slotName]
                    if cost then
                        local i = 1
                        while slotData[i] do
                            local itemId = slotData[i]
                            local numClasses = 0
                            for _ in pairs(itemClasses[itemId]) do
                                numClasses = numClasses + 1
                            end
                            if numClasses == 1 and not Bistooltip_emblem_items[itemId] then
                                Bistooltip_emblem_items[itemId] = {
                                    currency = "Emblem of Ascension II",
                                    cost = cost,
                                }
                            end
                            i = i + 1
                        end
                    end
                end
            end
        end
    end
end

RegisterT8SetFromBislist()

-- ============================================================
-- Utility Functions
-- ============================================================

-- Check if an item is available from emblems
function Bistooltip_GetEmblemSource(itemId)
    if not itemId then return nil end
    return Bistooltip_emblem_items[itemId]
end

-- Calculate total emblems needed for a list of item IDs
function Bistooltip_CalculateEmblemsNeeded(itemIds)
    local totals = {}  -- currency -> { total = n, items = {} }
    
    for _, itemId in ipairs(itemIds) do
        local emblem = Bistooltip_emblem_items[itemId]
        if emblem then
            local currency = emblem.currency
            if not totals[currency] then
                totals[currency] = { total = 0, items = {} }
            end
            totals[currency].total = totals[currency].total + (emblem.cost or 0)
            table.insert(totals[currency].items, {
                id = itemId,
                cost = emblem.cost or 0,
            })
        end
    end
    
    return totals
end

-- Print emblem info for an item (useful for debugging)
function Bistooltip_PrintEmblemInfo(itemIdOrLink)
    local itemId = itemIdOrLink
    if type(itemIdOrLink) == "string" then
        itemId = tonumber(itemIdOrLink:match("item:(%d+)"))
    end
    
    if not itemId then
        print("|cffff0000Invalid item ID or link|r")
        return
    end
    
    local name = GetItemInfo(itemId)
    local emblem = Bistooltip_emblem_items[itemId]
    
    if emblem then
        print(string.format("|cffffd000%s|r (ID: %d): |cff00ff00%s x%d|r", 
            name or "Unknown", itemId, emblem.currency, emblem.cost or 0))
    else
        print(string.format("|cffffd000%s|r (ID: %d): |cffff0000Not available from emblems|r",
            name or "Unknown", itemId))
    end
end

-- Slash command to check emblem info
SLASH_BISEMBLEM1 = "/bisemblem"
SlashCmdList["BISEMBLEM"] = function(msg)
    if msg == "" then
        print("|cffffd000Bis-Tooltip Emblem Info:|r")
        print("Usage: /bisemblem [itemId or item link]")
        print("Example: /bisemblem 50356")
        return
    end
    
    Bistooltip_PrintEmblemInfo(msg)
end
