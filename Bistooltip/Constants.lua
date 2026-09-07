-- ============================================================
-- Constants.lua - UI constants and configuration for BisTooltip
-- ============================================================

BistooltipConstants = BistooltipConstants or {}

-- ============================================================
-- UI Dimensions
-- ============================================================

BistooltipConstants.UI = {
    -- Main frame (compact width for better space usage)
    MAIN_FRAME_WIDTH = 600,
    MAIN_FRAME_HEIGHT = 700,
    MAIN_FRAME_MIN_WIDTH = 550,
    MAIN_FRAME_MIN_HEIGHT = 500,
    MAIN_FRAME_MAX_WIDTH = 1000,
    MAIN_FRAME_MAX_HEIGHT = 900,
    
    -- Spec frame (item list)
    SPEC_FRAME_HEIGHT = 420,

    -- Icons (original sizes)
    ICON_SIZE_TINY = 12,
    ICON_SIZE_SMALL = 14,
    ICON_SIZE_MEDIUM = 16,
    ICON_SIZE_LARGE = 28,
    ICON_SIZE_ITEM = 40,
    ICON_SIZE_GEM = 18,
    ICON_SIZE_ENCHANT = 16,
    
    -- Dropdown widths
    CLASS_DROPDOWN_WIDTH = 120,
    SPEC_DROPDOWN_WIDTH = 200,
    PHASE_DROPDOWN_WIDTH = 80,
    
    -- Buttons
    BUTTON_WIDTH_SMALL = 80,
    BUTTON_WIDTH_MEDIUM = 120,
    BUTTON_WIDTH_LARGE = 140,
    
    -- Search box
    SEARCH_BOX_WIDTH = 200,
    
    -- Checkbox
    CHECKBOX_WIDTH = 110,

    -- Tab system (Phase 4)
    TAB_HEIGHT = 28,
    TAB_WIDTH = 120,
    TAB_SPACING = 2,

    -- Pill buttons
    PILL_WIDTH = 70,
    PILL_HEIGHT = 24,

    -- Plan column (for checklist mode)
    PLAN_COLUMN_WIDTH = 180,
    ITEM_NAME_MAX_CHARS = 28,
    BOSS_NAME_MAX_CHARS = 22,
    ENCHANT_NAME_MAX_CHARS = 24,
}

-- ============================================================
-- Fonts
-- ============================================================

BistooltipConstants.FONTS = {
    DEFAULT = "Fonts\\FRIZQT__.TTF",
    SIZE_TINY = 9,
    SIZE_SMALL = 11,
    SIZE_MEDIUM = 12,
    SIZE_LARGE = 14,
}

-- ============================================================
-- Colors (as hex strings without alpha, for use with |cff)
-- ============================================================

BistooltipConstants.COLORS = {
    -- Rank colors
    BIS = "00ff00",         -- Bright green
    BIS2 = "009900",        -- Dark green
    ALT = "ffa500",         -- Orange
    NO_BIS = "ff3b3b",      -- Red
    FOUND = "ffff00",       -- Yellow

    -- UI colors
    HEADER = "ffd100",      -- Gold
    SUBHEADER = "ffffff",   -- White
    HINT = "aaaaaa",        -- Gray
    DISABLED = "666666",    -- Dark gray

    -- New UI Theme colors (Phase 4)
    TAB_ACTIVE = "3399ff",      -- Blue highlight for active tab
    TAB_INACTIVE = "666666",    -- Gray for inactive tabs
    TAB_HOVER = "4da6ff",       -- Lighter blue on hover
    PILL_ACTIVE = "3399ff",     -- Blue for active pill button
    PILL_INACTIVE = "444444",   -- Dark for inactive pill
    ROW_BORDER = "333333",      -- Subtle row separator
    GLASS_BG = "1a1a1a",        -- Dark glass background
    
    -- Item quality colors (fallbacks)
    QUALITY_POOR = "9d9d9d",
    QUALITY_COMMON = "ffffff",
    QUALITY_UNCOMMON = "1eff00",
    QUALITY_RARE = "0070dd",
    QUALITY_EPIC = "a335ee",
    QUALITY_LEGENDARY = "ff8000",
    
    -- Source colors
    SOURCE_ZONE = "cfcfcf",
    SOURCE_BOSS = "ffd000",
    SOURCE_EMBLEM = "00ffcc",  -- Cyan for Ascension emblems
    
    -- Status colors
    OWNED_EQUIPPED = "13f621",  -- Bright green
    OWNED_BAGS = "f6e013",      -- Yellow/gold
    BOE_MARKER = "ffd700",      -- Gold
    
    -- Emblem of Ascension - cyan/turquoise for visibility against purple items
    ASCENSION = "00ffcc",
    
    -- BIS Checklist Panel colors
    CHECKLIST_BOSS = "c41f3b",      -- Dark red (WoW Death Knight color)
    CHECKLIST_ZONE = "ff8000",      -- Orange (better visibility)
    CHECKLIST_ITEM = "ffd700",      -- Gold
    CHECKLIST_SLOT = "ffd700",      -- Gold (same as slot names in main container)
    CHECKLIST_SUBTOTAL = "ff7d0a",  -- Orange (WoW Druid color)
}

-- Helper to format color string
function BistooltipConstants.Color(colorKey, text)
    local hex = BistooltipConstants.COLORS[colorKey]
    if hex then
        return "|cff" .. hex .. tostring(text) .. "|r"
    end
    return tostring(text)
end

-- ============================================================
-- Phase Configuration
-- ============================================================

BistooltipConstants.PHASE_WEIGHT = {
    ["PR"] = 0, 
    ["PreRaid"] = 0, 
    ["Pre-Raid"] = 0,
    ["T7"] = 1, 
    ["T7.5"] = 2,
    ["T8"] = 3, 
    ["Ulduar"] = 3,
    ["T9"] = 4, 
    ["TOC"] = 4,
    ["T10"] = 5, 
    ["ICC"] = 5,
    ["RS"] = 6, 
    ["Ruby Sanctum"] = 6,
}

function BistooltipConstants.GetPhaseWeight(phase)
    if not phase then return 999 end
    phase = tostring(phase)
    return BistooltipConstants.PHASE_WEIGHT[phase] or tonumber(phase:match("T(%d+)")) or 999
end

-- ============================================================
-- Spec Detection Configuration
-- ============================================================

BistooltipConstants.SPEC_BY_CLASSFILE_TAB = {
    DEATHKNIGHT = { [1] = "Blood tank", [2] = "Frost", [3] = "Unholy" },
    DRUID       = { [1] = "Balance", [2] = "Feral tank", [3] = "Restoration" },
    HUNTER      = { [1] = "Beast mastery", [2] = "Marksmanship", [3] = "Survival" },
    MAGE        = { [1] = "Arcane", [2] = "Fire", [3] = "Frost" },
    PALADIN     = { [1] = "Holy", [2] = "Protection", [3] = "Retribution" },
    PRIEST      = { [1] = "Discipline", [2] = "Holy", [3] = "Shadow" },
    ROGUE       = { [1] = "Assassination", [2] = "Combat", [3] = "Subtlety" },
    SHAMAN      = { [1] = "Elemental", [2] = "Enhancement", [3] = "Restoration" },
    WARLOCK     = { [1] = "Affliction", [2] = "Demonology", [3] = "Destruction" },
    WARRIOR     = { [1] = "Arms", [2] = "Fury", [3] = "Protection" },
}

-- ============================================================
-- Table Layouts for Spec Frame
-- ============================================================

BistooltipConstants.SPEC_TABLE_DEFAULT = {
    columns = {
        { width = 60 },   -- Slot name
        { width = 24 },   -- Enchant icon
        { width = 75 },   -- Gem icons (up to 4)
        { width = 52 },   -- BIS
        { width = 52 },   -- Top 2
        { width = 46 },   -- Top 3
        { width = 46 },   -- Top 4
        { width = 46 },   -- Top 5
        { width = 46 },   -- Top 6
    },
    space = 4,
    align = "middle",
}

BistooltipConstants.SPEC_TABLE_CHECKLIST = {
    columns = {
        { width = 75 },   -- Slot
        { weight = 70 },  -- Plan (Boss/Item/Enchant/Gems)
        { width = 52 },   -- BIS
        { width = 52 },   -- BIS2
        { width = 46 },   -- Alt 3
        { width = 46 },   -- Alt 4
        { width = 46 },   -- Alt 5
        { width = 46 },   -- Alt 6
    },
    space = 4,
    align = "middle",
}

-- Customize mode with extra column for lock icons
BistooltipConstants.SPEC_TABLE_CUSTOMIZE = {
    columns = {
        { width = 60 },   -- Slot
        { width = 24 },   -- Enchant
        { width = 75 },   -- Gems
        { width = 50 },   -- BIS
        { width = 50 },   -- BIS2
        { width = 44 },   -- Alt 3
        { width = 44 },   -- Alt 4
        { width = 44 },   -- Alt 5
        { width = 44 },   -- Alt 6
        { width = 32 },   -- Lock icon
    },
    space = 4,
    align = "middle",
}

-- ============================================================
-- Stat Abbreviations for Gems
-- ============================================================

BistooltipConstants.STAT_ABBREVIATIONS = {
    -- WoW API stat keys (GetItemStats returns these)
    ["ITEM_MOD_SPELL_POWER_SHORT"] = "SP",
    ["ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"] = "SP",
    ["ITEM_MOD_ATTACK_POWER_SHORT"] = "AP",
    ["ITEM_MOD_CRIT_RATING_SHORT"] = "CRIT",
    ["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] = "CRIT",
    ["ITEM_MOD_CRIT_MELEE_RATING_SHORT"] = "CRIT",
    ["ITEM_MOD_HASTE_RATING_SHORT"] = "HASTE",
    ["ITEM_MOD_HASTE_SPELL_RATING_SHORT"] = "HASTE",
    ["ITEM_MOD_HASTE_MELEE_RATING_SHORT"] = "HASTE",
    ["ITEM_MOD_HIT_RATING_SHORT"] = "HIT",
    ["ITEM_MOD_HIT_SPELL_RATING_SHORT"] = "HIT",
    ["ITEM_MOD_HIT_MELEE_RATING_SHORT"] = "HIT",
    ["ITEM_MOD_EXPERTISE_RATING_SHORT"] = "EXP",
    ["ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT"] = "ARP",
    ["ITEM_MOD_STRENGTH_SHORT"] = "STR",
    ["ITEM_MOD_AGILITY_SHORT"] = "AGI",
    ["ITEM_MOD_INTELLECT_SHORT"] = "INT",
    ["ITEM_MOD_SPIRIT_SHORT"] = "SPI",
    ["ITEM_MOD_STAMINA_SHORT"] = "STA",
    ["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] = "DEF",
    ["ITEM_MOD_DODGE_RATING_SHORT"] = "DODGE",
    ["ITEM_MOD_PARRY_RATING_SHORT"] = "PARRY",
    ["ITEM_MOD_BLOCK_RATING_SHORT"] = "BLOCK",
    ["ITEM_MOD_BLOCK_VALUE_SHORT"] = "BV",
    ["ITEM_MOD_RESILIENCE_RATING_SHORT"] = "RES",
    ["ITEM_MOD_MANA_REGENERATION_SHORT"] = "MP5",
    ["ITEM_MOD_HEALTH_REGEN_SHORT"] = "HP5",
    ["ITEM_MOD_POWER_REGEN0_SHORT"] = "MP5",
    
    -- English stat names (from tooltip text)
    ["Stamina"] = "STA",
    ["Intellect"] = "INT",
    ["Strength"] = "STR",
    ["Agility"] = "AGI",
    ["Spirit"] = "SPI",
    ["Spell Power"] = "SP",
    ["Attack Power"] = "AP",
    ["Critical Strike Rating"] = "CRIT",
    ["Critical Strike"] = "CRIT",
    ["Crit Rating"] = "CRIT",
    ["Crit"] = "CRIT",
    ["Haste Rating"] = "HASTE",
    ["Haste"] = "HASTE",
    ["Armor Penetration Rating"] = "ARP",
    ["Armor Penetration"] = "ARP",
    ["Hit Rating"] = "HIT",
    ["Hit"] = "HIT",
    ["Expertise Rating"] = "EXP",
    ["Expertise"] = "EXP",
    ["Defense Rating"] = "DEF",
    ["Defense"] = "DEF",
    ["Dodge Rating"] = "DODGE",
    ["Dodge"] = "DODGE",
    ["Parry Rating"] = "PARRY",
    ["Parry"] = "PARRY",
    ["Block Rating"] = "BLOCK",
    ["Block Value"] = "BV",
    ["Resilience Rating"] = "RES",
    ["Resilience"] = "RES",
    ["mana per 5 sec"] = "MP5",
    ["mana per 5 seconds"] = "MP5",
    ["Mana every 5 seconds"] = "MP5",
    ["MP5"] = "MP5",
    
    -- Short forms (from gem names like "Bold Cardinal Ruby")
    ["Str"] = "STR",
    ["Agi"] = "AGI",
    ["Int"] = "INT",
    ["Sta"] = "STA",
    ["Spi"] = "SPI",
    ["Sp"] = "SP",
    ["Ap"] = "AP",
}

-- Stat display order
BistooltipConstants.STAT_ORDER = {
    META = 1,
    STR = 2, AGI = 3, INT = 4, SPI = 5, STA = 6,
    SP = 7, AP = 8,
    HIT = 9, CRIT = 10, HASTE = 11, EXP = 12, ARP = 13,
    DEF = 14, DODGE = 15, PARRY = 16, BLOCK = 17,
    MP5 = 18, RES = 19,
}

-- ============================================================
-- Timing Constants
-- ============================================================

BistooltipConstants.TIMING = {
    -- Equipment scan debounce
    SCAN_DEBOUNCE = 0.25,
    
    -- Tooltip refresh cooldown
    TOOLTIP_REFRESH_COOLDOWN = 0.1,
    
    -- Tooltip cache duration
    TOOLTIP_CACHE_DURATION = 1.0,
    
    -- Preloader settings
    PRELOAD_BATCH_SIZE = 12,
    PRELOAD_INTERVAL = 0.12,
}

-- ============================================================
-- Instance Difficulty Mappings
-- ============================================================

BistooltipConstants.INSTANCE_DIFFICULTY = {
    -- Naxxramas
    ["Naxxramas"] = "10N",
    ["Naxxramas (10)"] = "10N",
    ["Naxxramas (25)"] = "25N",
    ["Naxxramas (heroic)"] = "25N",
    
    -- Obsidian Sanctum
    ["The Obsidian Sanctum"] = "10N",
    ["The Obsidian Sanctum (10)"] = "10N",
    ["The Obsidian Sanctum(25)"] = "25N",
    ["The Obsidian Sanctum (25)"] = "25N",
    ["The Obsidian Sanctum (heroic)"] = "25N",
    
    -- Eye of Eternity
    ["The Eye of Eternity"] = "10N",
    ["The Eye of Eternity (10)"] = "10N",
    ["The Eye Of Eternity (25)"] = "25N",
    ["The Eye of Eternity (25)"] = "25N",
    ["The Eye of Eternity (heroic)"] = "25N",
    
    -- Ulduar
    ["Ulduar"] = "10N",
    ["Ulduar (10)"] = "10N",
    ["Ulduar (25)"] = "25N",
    ["Ulduar (heroic)"] = "25N",
    
    -- Trial of the Crusader
    ["Trial of the Crusader"] = "10N",
    ["Trial of the Crusader (10)"] = "10N",
    ["Trial of the Crusader (10 Heroic)"] = "10HM",
    ["Trial of the Crusader (25)"] = "25N",
    ["Trial of the Crusader (25 Heroic)"] = "25HM",
    ["Trial of the Grand Crusader"] = "10HM",
    ["Trial of the Grand Crusader (10)"] = "10HM",
    ["Trial of the Grand Crusader (25)"] = "25HM",
    
    -- Icecrown Citadel
    ["Icecrown Citadel"] = "10N",
    ["Icecrown Citadel (10)"] = "10N",
    ["Icecrown Citadel (10 Heroic)"] = "10HM",
    ["Icecrown Citadel (25)"] = "25N",
    ["Icecrown Citadel (25 Heroic)"] = "25HM",
    ["ICC"] = "10N",
    ["ICC (10)"] = "10N",
    ["ICC (10 Heroic)"] = "10HM",
    ["ICC (25)"] = "25N",
    ["ICC (25 Heroic)"] = "25HM",
    
    -- Ruby Sanctum
    ["Ruby Sanctum"] = "10N",
    ["Ruby Sanctum (10)"] = "10N",
    ["Ruby Sanctum (10 Heroic)"] = "10HM",
    ["Ruby Sanctum (25)"] = "25N",
    ["Ruby Sanctum (25 Heroic)"] = "25HM",
    
    -- Vault of Archavon
    ["Vault of Archavon"] = "10N",
    ["Vault of Archavon (10)"] = "10N",
    ["Vault of Archavon (25)"] = "25N",
    
    -- Onyxia's Lair
    ["Onyxia's Lair"] = "10N",
    ["Onyxia's Lair (10)"] = "10N",
    ["Onyxia's Lair (25)"] = "25N",
}

-- LEGACY-DEAD: no .toc-loaded caller (sole caller was unloaded Bislist.lua); difficulty now comes from canonical data.
-- Get difficulty tag for an instance name
function BistooltipConstants.GetInstanceDifficulty(instanceName)
    if not instanceName then return nil end
    return BistooltipConstants.INSTANCE_DIFFICULTY[instanceName]
end

-- ============================================================
-- Emblem/Badge Sources
-- ============================================================

BistooltipConstants.EMBLEM_VENDORS = {
    -- Custom server emblem
    ["Emblem of Ascension"] = {
        color = "00ffcc",  -- Cyan/turquoise for visibility
        shortName = "Ascension",
        icon = "Interface\\Icons\\Spell_Holy_SummonChampion",
    },
    -- Emblems of Frost
    ["Emblem of Frost"] = {
        color = "00ccff",
        shortName = "Frost",
        icon = "Interface\\Icons\\Spell_Frost_FrozenOrb",
    },
    -- Emblems of Triumph
    ["Emblem of Triumph"] = {
        color = "ffd700",
        shortName = "Triumph",
        icon = "Interface\\Icons\\Spell_Holy_ChampionsGrace",
    },
    -- Emblems of Conquest
    ["Emblem of Conquest"] = {
        color = "ff8000",
        shortName = "Conquest",
        icon = "Interface\\Icons\\Spell_Holy_ChampionsBond",
    },
    -- Emblems of Valor
    ["Emblem of Valor"] = {
        color = "a335ee",
        shortName = "Valor",
        icon = "Interface\\Icons\\Spell_Holy_ProclaimChampion_02",
    },
    -- Emblems of Heroism
    ["Emblem of Heroism"] = {
        color = "0070dd",
        shortName = "Heroism",
        icon = "Interface\\Icons\\Spell_Holy_ProclaimChampion",
    },
}

-- ============================================================
-- Emblem Vendor Items Database
-- Maps itemId -> { currency = "Emblem of Ascension", cost = 60 }
-- This should be populated with actual server data
-- ============================================================

BistooltipConstants.EMBLEM_ITEMS = BistooltipConstants.EMBLEM_ITEMS or {}

-- Helper to register emblem items
function BistooltipConstants.RegisterEmblemItem(itemId, currency, cost)
    BistooltipConstants.EMBLEM_ITEMS[itemId] = {
        currency = currency,
        cost = cost,
    }
end

-- Get emblem source for item
function BistooltipConstants.GetEmblemSource(itemId)
    return BistooltipConstants.EMBLEM_ITEMS[itemId]
end

-- ============================================================
-- Tier/Phase Combining Logic
-- ============================================================

-- Ordered list of phases for combining
BistooltipConstants.PHASE_ORDER = {
    "PR", "PreRaid", "Pre-Raid",
    "T7", "T7.5", 
    "T8", "Ulduar",
    "T9", "TOC",
    "T10", "ICC",
    "RS", "Ruby Sanctum",
}

-- Normalize phase name to canonical form
function BistooltipConstants.NormalizePhase(phase)
    if not phase then return nil end
    local p = tostring(phase)
    
    -- Normalize pre-raid
    if p == "PR" or p == "PreRaid" or p == "Pre-Raid" then
        return "PR"
    end
    
    -- Normalize T7.5
    if p == "T7.5" then return "T7.5" end
    
    -- Normalize Ulduar
    if p == "Ulduar" then return "T8" end
    
    -- Normalize TOC
    if p == "TOC" then return "T9" end
    
    -- Normalize ICC
    if p == "ICC" then return "T10" end
    
    -- Normalize Ruby Sanctum
    if p == "RS" or p == "Ruby Sanctum" then return "RS" end
    
    return p
end

-- Get numeric tier from phase for comparison
function BistooltipConstants.GetTierNumber(phase)
    if not phase then return 0 end
    local p = BistooltipConstants.NormalizePhase(phase)
    
    if p == "PR" then return 0 end
    if p == "T7" then return 7 end
    if p == "T7.5" then return 7.5 end
    if p == "T8" then return 8 end
    if p == "T9" then return 9 end
    if p == "T10" then return 10 end
    if p == "RS" then return 11 end
    
    -- Try to extract number
    local num = p:match("T(%d+)")
    if num then return tonumber(num) end
    
    return 999
end

-- Get phase index from Bistooltip_wowtbc_phases (for consecutive detection)
function BistooltipConstants.GetPhaseIndex(phase)
    if not phase then return 999 end
    local p = BistooltipConstants.NormalizePhase(phase)
    
    -- Use actual phase order: PR, T7, T8, T9, T10, RS
    local phaseOrder = { PR = 1, T7 = 2, T8 = 3, T9 = 4, T10 = 5, RS = 6 }
    return phaseOrder[p] or 999
end

-- Combine consecutive BIS phases: "PR BIS / T7 BIS / T8 BIS" -> "BIS PR-T8"
function BistooltipConstants.CombineBISPhases(phasesText)
    if not phasesText or phasesText == "" then return phasesText end
    
    -- Parse all tokens
    local tokens = {}
    local bisPhases = {}
    local altPhases = {}  -- altN -> { phases }
    
    for token in phasesText:gmatch("([^/]+)") do
        local s = token:gsub("^%s+", ""):gsub("%s+$", "")
        local phase = s:match("^([^%s]+)")
        
        if s:find("BIS") then
            table.insert(bisPhases, phase)
        else
            local altN = s:match("alt%s*(%d+)")
            if altN then
                altN = tonumber(altN)
                altPhases[altN] = altPhases[altN] or {}
                table.insert(altPhases[altN], phase)
            end
        end
    end
    
    -- Sort phases by phase index (actual order: PR, T7, T8, T9, T10, RS)
    local function sortByPhaseIndex(a, b)
        return BistooltipConstants.GetPhaseIndex(a) < BistooltipConstants.GetPhaseIndex(b)
    end
    
    table.sort(bisPhases, sortByPhaseIndex)
    
    -- Build combined string
    local parts = {}
    
    -- Combine BIS phases
    if #bisPhases > 0 then
        if #bisPhases == 1 then
            -- Single BIS phase - add green color
            table.insert(parts, "|cff00ff00" .. bisPhases[1] .. " BIS|r")
        elseif #bisPhases >= 2 then
            -- Check if consecutive using phase index (PR=1, T7=2, T8=3, etc)
            local first = bisPhases[1]
            local last = bisPhases[#bisPhases]
            local isConsecutive = true
            
            for i = 2, #bisPhases do
                local prevIdx = BistooltipConstants.GetPhaseIndex(bisPhases[i-1])
                local currIdx = BistooltipConstants.GetPhaseIndex(bisPhases[i])
                -- Consecutive means index difference of exactly 1
                if currIdx - prevIdx ~= 1 then
                    isConsecutive = false
                    break
                end
            end
            
            if isConsecutive and #bisPhases >= 2 then
                table.insert(parts, "|cff00ff00BIS " .. first .. "-" .. last .. "|r")
            else
                -- Not consecutive, list individually with green color
                for _, p in ipairs(bisPhases) do
                    table.insert(parts, "|cff00ff00" .. p .. " BIS|r")
                end
            end
        end
    end
    
    -- Add alt phases (sorted by alt number)
    local altNums = {}
    for n in pairs(altPhases) do table.insert(altNums, n) end
    table.sort(altNums)
    
    for _, n in ipairs(altNums) do
        local phases = altPhases[n]
        table.sort(phases, sortByPhaseIndex)
        
        if #phases == 1 then
            table.insert(parts, phases[1] .. " alt " .. n)
        elseif #phases >= 2 then
            local first = phases[1]
            local last = phases[#phases]
            table.insert(parts, "|cffffa500ALT" .. n .. " " .. first .. "-" .. last .. "|r")
        end
    end
    
    if #parts == 0 then return phasesText end
    
    return table.concat(parts, " / ")
end
