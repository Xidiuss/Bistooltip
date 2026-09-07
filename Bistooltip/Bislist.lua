-- ============================================================
-- Bislist.lua - Main BiS List Window UI
-- ============================================================

local AceGUI = LibStub("AceGUI-3.0")

-- Import utilities
local Utils = BistooltipUtils
local Constants = BistooltipConstants

-- ============================================================
-- Module State
-- ============================================================

local State = {
    class = nil,
    spec = nil,
    phase = nil,
    class_index = 1,
    spec_index = 1,
    phase_index = 1,
}

local class_options = {}
local class_options_to_class = {}

local spec_options = {}
local spec_options_to_spec = {}
local spec_frame = nil
local items = {}
local spells = {}
local main_frame = nil

local classDropdown = nil
local specDropdown = nil
local phaseDropDown = nil

local checkmarks = {}
local boemarks = {}

local isHorde = UnitFactionGroup("player") == "Horde"

-- Forward declarations
local QueuePreload
local TooltipSetItemByID
local clearCheckMarks, clearBoeMarks
local DestroyChecklistPanel
local mainFrameUISpecialName
local drawSpecData

-- ============================================================
-- UI State
-- ============================================================

local searchText = ""
local searchTextLower = ""
local showOnlyMissing = false
local bisChecklistMode = false
local emblemFilterMode = false  -- NEW: Filter to show only emblem sources
local checklistSummaryLabel = nil
local emblemSummaryLabel = nil  -- NEW: Shows emblem totals
local collapsedBosses = {}  -- Track collapsed boss sections {["BossName_Zone"] = true}
local blockedPhase = nil  -- NEW: Locked phase (when Block Phase is checked)
local blockedPhaseIndex = nil  -- Index of locked phase
local customizeMode = false  -- NEW: Enable slot priority customization
local unlockedSlots = {}  -- NEW: Track which slots are unlocked for customization {["Slot_Name"] = true}
local customPriorities = {}  -- NEW: Store custom item priorities {["Class_Spec_Phase_Slot"] = {item_ids...}}
local originalSlotOrders = {}  -- Store ORIGINAL slot orders for reset {["Class_Spec_Phase_Slot"] = {item_ids...}}
local currentFilteredData = {}  -- Store filtered slots for reference
local selectedSwapItem = nil  -- Track selected item for swap: {slotName = "...", index = N}
local selectionBorders = {}  -- Track all selection border textures for cleanup
local customizeToggleRef = nil  -- Reference to customize checkbox
local resetBtnRef = nil  -- Reference to reset button
local savedScrollValue = 0  -- Save scroll position

-- Emblem of Ascension item ID for icon
local EMBLEM_OF_ASCENSION_ID = 131008

-- ============================================================
-- 3.3.5 safe tooltip helper
-- ============================================================

TooltipSetItemByID = function(tt, item_id)
    if not tt or not item_id or item_id <= 0 then return end
    tt:SetHyperlink("item:" .. item_id .. ":0:0:0:0:0:0:0")
end

-- ============================================================
-- UISpecialFrames Management (from Utils)
-- ============================================================

local AddToUISpecialFrames = Utils.AddToUISpecialFrames
local RemoveFromUISpecialFrames = Utils.RemoveFromUISpecialFrames

-- ============================================================
-- Class Colorization (from Utils)
-- ============================================================

local function ColorizeClassOption(className)
    local file = Utils.CLASSNAME_TO_FILE[className]
    local c = file and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[file]
    if c and c.r then
        return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, className)
    end
    return className
end

-- ============================================================
-- Spec Table Layouts
-- ============================================================

local SPEC_TABLE_DEFAULT = Constants.SPEC_TABLE_DEFAULT
local SPEC_TABLE_CHECKLIST = Constants.SPEC_TABLE_CHECKLIST
local SPEC_TABLE_CUSTOMIZE = Constants.SPEC_TABLE_CUSTOMIZE

local function ApplySpecTable()
    if not spec_frame then return end
    local tableLayout
    if bisChecklistMode then
        -- BIS checklist mode - customize is disabled here
        tableLayout = SPEC_TABLE_CHECKLIST
    elseif customizeMode then
        -- Customize mode only works in standard mode
        tableLayout = SPEC_TABLE_CUSTOMIZE
    else
        tableLayout = SPEC_TABLE_DEFAULT
    end
    spec_frame:SetUserData("table", tableLayout)
end

-- ============================================================
-- Owned Info Helpers
-- ============================================================

local function GetOwnedRow(item_id)
    local t = _G.Bistooltip_char_equipment
    if not t then return nil end
    
    -- First try the direct ID
    if t[item_id] then return t[item_id] end
    
    -- If the item_id is an Alliance ID (from normalization), we need to find the Horde ID
    -- to check if a Horde player owns it
    if Bistooltip_horde_to_ali then
        -- Check if item_id is the Alliance version - find the Horde ID
        for hordeId, aliId in pairs(Bistooltip_horde_to_ali) do
            if aliId == item_id then
                -- item_id is Alliance, check Horde version
                if t[hordeId] then return t[hordeId] end
                break
            end
        end
        
        -- Also check if item_id is Horde and try Alliance version
        local aliId = Bistooltip_horde_to_ali[item_id]
        if aliId and t[aliId] then return t[aliId] end
    end
    
    return nil
end

local function OwnedCount(item_id)
    local row = GetOwnedRow(item_id)
    if not row then return 0 end
    return (row.bags or 0) + (row.equipped or 0)
end

local function NormalizeItemID(original_item_id)
    return Utils.NormalizeItemID(original_item_id)
end

-- ============================================================
-- Dual Slot Detection
-- ============================================================

local function IsDualSlot(slot, item_id)
    local equipLoc
    if item_id then
        local _, _, _, _, _, _, _, _, loc = GetItemInfo(item_id)
        equipLoc = loc
    end
    if equipLoc == "INVTYPE_TRINKET" or equipLoc == "INVTYPE_FINGER" then
        return true
    end
    local sn = slot and (slot.slot_name or slot.name)
    if sn then
        sn = tostring(sn):lower()
        if sn:find("trinket") or sn:find("ring") or sn:find("finger") then
            return true
        end
    end
    return false
end

local function GetRequiredBISItemsForSlot(slot)
    local req = {}
    local a = NormalizeItemID(slot and slot[1])
    if a then table.insert(req, a) end

    if a and IsDualSlot(slot, a) then
        local b = NormalizeItemID(slot and slot[2])
        if b and b ~= a then
            table.insert(req, b)
        else
            local found
            for i = 2, math.min(#slot, 6) do
                local cand = NormalizeItemID(slot[i])
                if cand and cand ~= a then
                    found = cand
                    break
                end
            end
            if found then
                table.insert(req, found)
            end
        end
    end
    return req
end

local function SlotBISCompleted(slot)
    local req = GetRequiredBISItemsForSlot(slot)
    if #req == 0 then return false end

    if #req == 1 then
        return OwnedCount(req[1]) >= 1
    end

    if req[1] == req[2] then
        return OwnedCount(req[1]) >= 1
    end
    return OwnedCount(req[1]) >= 1 and OwnedCount(req[2]) >= 1
end

-- ============================================================
-- Instance Difficulty Helper (NEW)
-- ============================================================

-- LEGACY-DEAD: Bislist.lua is not loaded by Bistooltip/Bistooltip.toc; difficulty now comes from canonical data.
local function GetInstanceDifficultyTag(instanceName)
    if not instanceName then return nil end
    
    -- Check Constants first
    local tag = Constants.GetInstanceDifficulty(instanceName)
    if tag then return tag end
    
    -- Parse common patterns
    local lower = string.lower(instanceName)
    
    if lower:find("heroic") or lower:find("hm") then
        if lower:find("25") then
            return "25HM"
        elseif lower:find("10") then
            return "10HM"
        end
        return "HM"
    end
    
    if lower:find("25") then
        return "25N"
    elseif lower:find("10") then
        return "10N"
    end
    
    return nil
end

-- ============================================================
-- Source Info with Multiple Sources Support (ENHANCED)
-- ============================================================

local function GetAllItemSources(item_id)
    local sources = {}
    
    if not item_id or item_id <= 0 then return sources end
    
    -- Get raid/dungeon source
    if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
        local zone, boss = _G.BistooltipAddon:GetItemSourceInfo(item_id)
        if zone and boss then
            local diffTag = GetInstanceDifficultyTag(zone)
            table.insert(sources, {
                type = "raid",
                zone = zone,
                boss = boss,
                difficulty = diffTag,
            })
        end
    end
    
    -- Check for emblem source - check both global and Constants
    local emblemSource = nil
    if _G.Bistooltip_emblem_items then
        emblemSource = _G.Bistooltip_emblem_items[item_id]
    end
    if not emblemSource and Constants and Constants.EMBLEM_ITEMS then
        emblemSource = Constants.EMBLEM_ITEMS[item_id]
    end
    
    if emblemSource then
        local emblemInfo = Constants and Constants.EMBLEM_VENDORS and 
                          Constants.EMBLEM_VENDORS[emblemSource.currency]
        table.insert(sources, {
            type = "emblem",
            currency = emblemSource.currency or "Emblems",
            cost = emblemSource.cost,
            color = emblemInfo and emblemInfo.color or (Constants.COLORS.ASCENSION or "00ffcc"),
            icon = emblemInfo and emblemInfo.icon,
        })
    end
    
    return sources
end

-- Check if item has emblem source
local function HasEmblemSource(item_id)
    if not item_id or item_id <= 0 then return false end
    
    if _G.Bistooltip_emblem_items and _G.Bistooltip_emblem_items[item_id] then
        return true
    end
    if Constants and Constants.EMBLEM_ITEMS and Constants.EMBLEM_ITEMS[item_id] then
        return true
    end
    
    return false
end

-- Get emblem cost for item
local function GetEmblemCost(item_id)
    if not item_id or item_id <= 0 then return nil, nil end
    
    local emblem = nil
    if _G.Bistooltip_emblem_items then
        emblem = _G.Bistooltip_emblem_items[item_id]
    end
    if not emblem and Constants and Constants.EMBLEM_ITEMS then
        emblem = Constants.EMBLEM_ITEMS[item_id]
    end
    
    if emblem then
        return emblem.cost, emblem.currency
    end
    return nil, nil
end

-- Calculate total emblems needed for missing BIS items
local function CalculateMissingEmblems()
    local totals = {}  -- currency -> { total = n, items = {} }
    
    if not (State.class and State.spec and State.phase) then
        return totals
    end
    
    local slots = Bistooltip_bislists
        and Bistooltip_bislists[State.class]
        and Bistooltip_bislists[State.class][State.spec]
        and Bistooltip_bislists[State.class][State.spec][State.phase]
    
    if type(slots) ~= "table" then
        return totals
    end
    
    for _, slot in ipairs(slots) do
        local req = GetRequiredBISItemsForSlot(slot)
        for _, id in ipairs(req) do
            if id and id > 0 and OwnedCount(id) < 1 then
                local cost, currency = GetEmblemCost(id)
                if cost and currency then
                    if not totals[currency] then
                        totals[currency] = { total = 0, items = {} }
                    end
                    totals[currency].total = totals[currency].total + cost
                    
                    local name = GetItemInfo(id) or ("Item " .. id)
                    table.insert(totals[currency].items, {
                        id = id,
                        name = name,
                        cost = cost,
                        slot = slot.slot_name or "",
                    })
                end
            end
        end
    end
    
    return totals
end

local function FormatSourcesText(sources, compact)
    if not sources or #sources == 0 then return "" end
    
    local parts = {}
    
    for _, src in ipairs(sources) do
        if src.type == "raid" then
            local text = ""
            if compact then
                -- Compact format: "Boss (10HM)"
                if src.difficulty then
                    text = "|cffffd000" .. Utils.TruncateText(src.boss, 15) .. "|r |cffaaaaaa(" .. src.difficulty .. ")|r"
                else
                    text = "|cffffd000" .. Utils.TruncateText(src.boss, 18) .. "|r"
                end
            else
                -- Full format: "[Instance (10HM)] - Boss"
                local zonePart = src.zone
                if src.difficulty then
                    zonePart = zonePart .. " " .. src.difficulty
                end
                text = "|cffcfcfcf" .. zonePart .. "|r\n|cffffd000" .. src.boss .. "|r"
            end
            table.insert(parts, text)
            
        elseif src.type == "emblem" then
            -- Use emblem color from Constants
            local emblemInfo = Constants and Constants.EMBLEM_VENDORS and Constants.EMBLEM_VENDORS[src.currency]
            local color = (emblemInfo and emblemInfo.color) or src.color or (Constants.COLORS.ASCENSION or "00ffcc")
            local text = "|cff" .. color .. (src.currency or "Emblem")
            if src.cost then
                text = text .. " x" .. src.cost
            end
            text = text .. "|r"
            table.insert(parts, text)
        end
    end
    
    if compact then
        return table.concat(parts, " | ")
    else
        return table.concat(parts, "\n")
    end
end

local function GetSourceShort(item_id)
    local sources = GetAllItemSources(item_id)
    return FormatSourcesText(sources, false)
end

-- ============================================================
-- Gem Stat Formatting (ENHANCED - show stats instead of names)
-- ============================================================

local STAT_MAP = Constants.STAT_ABBREVIATIONS
local STAT_ORDER = Constants.STAT_ORDER

local GEM_TOKEN_CACHE = {}

local function GetGemScanner()
    if _G.BistooltipAddon and _G.BistooltipAddon._btGemScanner then
        return _G.BistooltipAddon._btGemScanner
    end
    local tt = CreateFrame("GameTooltip", "BistooltipGemScanner", UIParent, "GameTooltipTemplate")
    tt:SetOwner(UIParent, "ANCHOR_NONE")
    tt:Hide()
    if _G.BistooltipAddon then
        _G.BistooltipAddon._btGemScanner = tt
    end
    return tt
end

local function CleanTooltipLine(line)
    return Utils.CleanLine(line)
end

local function ParseGemStatsFromTooltip(item_id)
    if not item_id or item_id <= 0 then return nil end
    local name = GetItemInfo(item_id)
    if not name then
        if QueuePreload then QueuePreload(item_id) end
        return nil
    end

    local tt = GetGemScanner()
    tt:ClearLines()
    tt:SetHyperlink("item:" .. tostring(item_id) .. ":0:0:0:0:0:0:0")

    local acc = {}
    local n = tt:NumLines() or 0

    local function addStat(stat, v)
        if not stat or not v then return false end
        stat = tostring(stat)
        stat = stat:gsub("[%(%)]", " ")
        stat = stat:gsub("[%,;%.]", " ")
        stat = stat:gsub("^%s+", ""):gsub("%s+$", "")
        stat = stat:gsub("^and%s+", ""):gsub("^i%s+", "")
        stat = stat:gsub("^your%s+", "")
        stat = stat:gsub("^increases%s+your%s+", "")
        stat = stat:gsub("^increases%s+", "")
        stat = stat:gsub("^improves%s+your%s+", "")
        stat = stat:gsub("^improves%s+", "")
        stat = stat:gsub("^equip:%s*", "")
        stat = stat:gsub("^use:%s*", "")
        stat = stat:gsub("%s+and$", ""):gsub("%s+i$", "")
        stat = stat:gsub("^%s+", ""):gsub("%s+$", "")

        local ab = STAT_MAP[stat]
        if not ab then
            local s2 = stat:gsub("%s+[Rr]ating$", "")
            if s2 ~= stat then ab = STAT_MAP[s2] end
        end
        if ab then
            acc[ab] = (acc[ab] or 0) + v
            return true
        end
        return false
    end

    for i = 2, n do
        local fs = _G["BistooltipGemScannerTextLeft" .. i]
        local line = fs and fs.GetText and fs:GetText()
        line = CleanTooltipLine(line)

        if line and line ~= "" then
            local foundInLine = false

            -- Pattern A: "+10 Strength and +10 Critical Strike Rating"
            for num, stat in line:gmatch("([%+%-]%d+)%s*([^%+%-]+)") do
                local v = tonumber(num)
                if v and addStat(stat, v) then
                    foundInLine = true
                end
            end

            -- Pattern B: "Increases your Critical Strike Rating by 10"
            if (not foundInLine) and line:find("by%s+%d+") then
                for stat, num in line:gmatch("([^%d]+)%s+by%s+(%d+)") do
                    local v = tonumber(num)
                    if v and addStat(stat, v) then
                        foundInLine = true
                    end
                end
            end
        end
    end

    local tmp = {}
    for ab, v in pairs(acc) do
        if v and v ~= 0 then
            table.insert(tmp, { abbr = ab, val = v })
        end
    end

    table.sort(tmp, function(a, b)
        return (STAT_ORDER[a.abbr] or 99) < (STAT_ORDER[b.abbr] or 99)
    end)

    return tmp
end

-- Build gem stat token (e.g., "20 STR" or "12 SP / 10 SPI")
-- Now uses hardcoded GemData.lua first for accurate display
local function BuildGemStatToken(item_id)
    if not item_id or item_id <= 0 then return nil end
    if GEM_TOKEN_CACHE[item_id] ~= nil then return GEM_TOKEN_CACHE[item_id] end

    local name, link, _, _, _, class, subclass = GetItemInfo(item_id)
    if not name then
        if QueuePreload then QueuePreload(item_id) end
        return nil
    end

    -- PRIMARY: Use hardcoded gem data (most accurate)
    if _G.Bistooltip_GetGemStats then
        local hardcoded = Bistooltip_GetGemStats(name)
        if hardcoded then
            GEM_TOKEN_CACHE[item_id] = hardcoded
            return hardcoded
        end
    end


    -- Also check global table directly
    if _G.Bistooltip_gem_stats then
        local key = string.lower(name)
        local hardcoded = Bistooltip_gem_stats[key]
        if hardcoded then
            GEM_TOKEN_CACHE[item_id] = hardcoded
            return hardcoded
        end
    end

    -- FALLBACK: Try to parse stats from API/tooltip
    local acc = {}
    local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"
    local ITEM_SUBCLASS_GEM_META = _G.ITEM_SUBCLASS_GEM_META or "Meta"

    -- Try GetItemStats (fast, locale-independent)
    if _G.GetItemStats then
        local stats = GetItemStats(link or ("item:" .. tostring(item_id) .. ":0:0:0:0:0:0:0"))
        if type(stats) == "table" then
            for k, v in pairs(stats) do
                if v and v ~= 0 then
                    local ab = STAT_MAP[k]
                    if not ab and type(k) == "string" then
                        local g = _G[k]
                        if type(g) == "string" then
                            ab = STAT_MAP[g]
                        end
                    end
                    if ab then
                        acc[ab] = (acc[ab] or 0) + v
                    end
                end
            end
        end
    end

    -- Fallback: parse tooltip
    if not next(acc) then
        local tmp = ParseGemStatsFromTooltip(item_id)
        if tmp then
            for _, x in ipairs(tmp) do
                acc[x.abbr] = (acc[x.abbr] or 0) + (x.val or 0)
            end
        end
    end

    -- Build ordered parts
    local parts = {}
    if next(acc) then
        local tmp = {}
        for ab, v in pairs(acc) do
            if v and v ~= 0 then
                table.insert(tmp, { abbr = ab, val = v })
            end
        end
        table.sort(tmp, function(a, b)
            return (STAT_ORDER[a.abbr] or 99) < (STAT_ORDER[b.abbr] or 99)
        end)
        for _, x in ipairs(tmp) do
            local vv = x.val
            if type(vv) == "number" and vv == math.floor(vv) then
                table.insert(parts, tostring(vv) .. " " .. x.abbr)
            else
                table.insert(parts, string.format("%s %s", tostring(vv), x.abbr))
            end
        end
    end

    local token = table.concat(parts, " / ")
    
    -- Add META prefix for meta gems
    if class == ITEM_CLASS_GEM and subclass == ITEM_SUBCLASS_GEM_META and token ~= "" then
        token = "META: " .. token
    end
    
    -- Fallback to abbreviated name if no stats found
    if token == "" then
        token = Utils.TruncateText(name, 16)
    end

    GEM_TOKEN_CACHE[item_id] = token
    return token
end


local function BuildGemStatTokenTwoLines(item_id)
    local token = BuildGemStatToken(item_id)
    if not token or token == "" then return "" end

    -- usuń prefix meta w UI
    token = token:gsub("^META:%s*", "")

    -- rozbij po "/"
    local parts = {}
    for part in token:gmatch("[^/]+") do
        part = part:gsub("^%s+", ""):gsub("%s+$", "")
        if part ~= "" then table.insert(parts, part) end
    end

    if #parts <= 1 then
        return token
    end

    -- max 2 linie: resztę dopnij do 2. linii
    local line1 = parts[1]
    local line2 = parts[2]
    for i = 3, #parts do
        line2 = line2 .. " " .. parts[i]
    end

    -- kosmetyka
    line1 = line1:gsub("%s+", " ")
    line2 = line2:gsub("%s+", " ")

    -- jeśli masz przypadki "STA" z fallbacka:
    line1 = line1:gsub("(%d+)%s+STA%f[%A]", "%1 STAM")
    line2 = line2:gsub("(%d+)%s+STA%f[%A]", "%1 STAM")

    return line1 .. "\n" .. line2
end


-- ============================================================
-- Enchant Name Helper (NEW)
-- ============================================================

-- Strip "Enchant" prefix from enchant names (e.g., "Enchant Gloves - Crusher" -> "Gloves - Crusher")
local function StripEnchantPrefix(name)
    if not name then return nil end
    -- Remove "Enchant " prefix
    local stripped = name:gsub("^Enchant%s+", "")
    return stripped
end

local function GetEnchantName(enhancement)
    if not enhancement then return nil end
    
    if enhancement.type == "spell" and enhancement.id then
        local name = GetSpellInfo(enhancement.id)
        return StripEnchantPrefix(name)
    elseif enhancement.type == "item" and enhancement.id then
        local name = GetItemInfo(enhancement.id)
        -- Check if it's a gem (exclude from enchant display)
        local _, _, _, _, _, class = GetItemInfo(enhancement.id)
        local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"
        if class == ITEM_CLASS_GEM then
            return nil -- It's a gem, not an enchant
        end
        return StripEnchantPrefix(name)
    end
    
    return nil
end

-- Get enchant info (name, icon, id, type) from slot
local function GetSlotEnchantInfo(slot)
    if not slot or not slot.enhs then return nil, nil, nil, nil end
    
    for _, enh in ipairs(slot.enhs) do
        if enh.type == "spell" and enh.id then
            local name, _, icon = GetSpellInfo(enh.id)
            if name then
                return StripEnchantPrefix(name), icon, enh.id, "spell"
            end
        elseif enh.type == "item" and enh.id then
            local name, _, _, _, _, class, _, _, _, texture = GetItemInfo(enh.id)
            local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"
            if name and class ~= ITEM_CLASS_GEM then
                return StripEnchantPrefix(name), texture, enh.id, "item"
            end
        end
    end
    
    return nil, nil, nil, nil
end

local function GetSlotEnchantName(slot)
    if not slot or not slot.enhs then return nil end
    
    for _, enh in ipairs(slot.enhs) do
        local name = GetEnchantName(enh)
        if name then
            return name
        end
    end
    
    return nil
end

-- ============================================================
-- Collect Gem IDs from Enhancements
-- ============================================================

local function CollectGemIdsFromEnhancements(enhs)
    local out = {}
    if type(enhs) ~= "table" then return out end

    local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"

    for _, e in ipairs(enhs) do
        if e and e.type == "item" and e.id and e.id > 0 then
            local name, _, _, _, _, class = GetItemInfo(e.id)
            if not name then
                if QueuePreload then QueuePreload(e.id) end
                table.insert(out, e.id)
            elseif class == ITEM_CLASS_GEM then
                table.insert(out, e.id)
            end
        end
    end

    -- Filter non-gems once cached
    local filtered = {}
    for _, id in ipairs(out) do
        local name, _, _, _, _, class = GetItemInfo(id)
        if not name then
            table.insert(filtered, id)
        elseif class == ITEM_CLASS_GEM then
            table.insert(filtered, id)
        end
    end

    while #filtered > 3 do table.remove(filtered) end
    return filtered
end

-- Build gem plan text with stat abbreviations and icons
local function BuildGemPlanText(gemIds)
    if not gemIds or #gemIds == 0 then return "" end

    local tokens = {}
    local iconSize = Constants.UI.ICON_SIZE_GEM or 22
    
    for _, id in ipairs(gemIds) do
        local t = BuildGemStatToken(id)
        if not t or t == "" then t = "..." end
        
        -- Get gem icon
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
        local iconStr = ""
        if texture then
            iconStr = string.format("|T%s:%d:%d:0:0|t", texture, iconSize, iconSize)
        end
        
        table.insert(tokens, iconStr .. "|cff55aaff" .. t .. "|r")
    end

    if #tokens == 0 then return "" end
    return table.concat(tokens, "  ")
end

-- ============================================================
-- Checklist Under Item Text (ENHANCED)
-- ============================================================

local function GetChecklistUnderItemText(item_id)
    if not item_id or item_id <= 0 then return "" end

    local name, _, quality = GetItemInfo(item_id)
    if not name then
        if QueuePreload then QueuePreload(item_id) end
        name = "Item " .. tostring(item_id)
        quality = 1
    end

    -- Get sources
    local sources = GetAllItemSources(item_id)
    
    -- Format name with quality color
    local hexColor = Utils.GetItemQualityHex(quality)
    local styledName = "|c" .. hexColor .. Utils.SmartTrunc(name, 18) .. "|r"

    -- Format source info
    local sourceText = ""
    if #sources > 0 then
        local src = sources[1]
        if src.type == "raid" then
            local bossText = Utils.SmartTrunc(src.boss, 12)
            if src.difficulty then
                sourceText = "\n|cffaaaaaa" .. bossText .. " (" .. src.difficulty .. ")|r"
            else
                sourceText = "\n|cffaaaaaa" .. bossText .. "|r"
            end
        elseif src.type == "emblem" then
            sourceText = "\n|cff55aaff" .. (src.currency or "Emblem") .. "|r"
        end
        
        -- Add second source if exists
        if #sources > 1 then
            local src2 = sources[2]
            if src2.type == "emblem" then
                sourceText = sourceText .. "\n|cff55aaff" .. (src2.currency or "Emblem") .. "|r"
            elseif src2.type == "raid" then
                sourceText = sourceText .. "\n|cffaaaaaa+" .. Utils.SmartTrunc(src2.boss, 10) .. "|r"
            end
        end
    end

    return styledName .. sourceText
end

-- ============================================================
-- Cleanup Functions
-- ============================================================

local function CleanupMainFrame()
    if clearCheckMarks then clearCheckMarks() end
    if clearBoeMarks then clearBoeMarks() end

    spec_frame = nil
    items = {}
    spells = {}

    DestroyChecklistPanel()

    if mainFrameUISpecialName then
        RemoveFromUISpecialFrames(mainFrameUISpecialName)
        mainFrameUISpecialName = nil
    end

    checklistSummaryLabel = nil
    emblemSummaryLabel = nil
    emblemFilterMode = false
end

-- ============================================================
-- BIS Checklist Side Panel
-- ============================================================

local checklistPanel = nil
local checklistContainer = nil
mainFrameUISpecialName = nil
local OpenChecklistExport = nil

local function EnsureChecklistPanel()
    if not main_frame or not main_frame.frame then return end
    if checklistPanel then return end

    checklistPanel = CreateFrame("Frame", "BistooltipChecklistPanel", main_frame.frame)
    checklistPanel:SetPoint("TOPLEFT", main_frame.frame, "TOPRIGHT", 5, 0)
    checklistPanel:SetPoint("BOTTOMLEFT", main_frame.frame, "BOTTOMRIGHT", 5, 0)
    checklistPanel:SetWidth(Constants.UI.CHECKLIST_PANEL_WIDTH)
    checklistPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    checklistPanel:Hide()

    -- Title
    local title = checklistPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cffffd100BIS CHECKLIST|r")

    -- Progress bar frame under title
    local progressFrame = CreateFrame("Frame", nil, checklistPanel)
    progressFrame:SetPoint("TOP", title, "BOTTOM", 0, -6)
    progressFrame:SetSize(280, 22)
    
    -- Progress bar background
    local progressBg = progressFrame:CreateTexture(nil, "BACKGROUND")
    progressBg:SetAllPoints()
    progressBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    progressBg:SetVertexColor(0.1, 0.1, 0.1, 0.9)
    
    -- Progress bar fill
    local progressFill = progressFrame:CreateTexture(nil, "ARTWORK")
    progressFill:SetPoint("LEFT", progressFrame, "LEFT", 2, 0)
    progressFill:SetHeight(18)
    progressFill:SetWidth(1)
    progressFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressFill:SetVertexColor(0.8, 0.2, 0.2, 1)  -- Red default
    checklistPanel._progressFill = progressFill
    
    -- Progress bar border
    local progressBorder = CreateFrame("Frame", nil, progressFrame)
    progressBorder:SetAllPoints()
    progressBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
    })
    progressBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Progress text
    local progressText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER", progressFrame, "CENTER", 0, 0)
    progressText:SetTextColor(1, 1, 1, 1)
    progressText:SetText("0 / 0")
    checklistPanel._progressText = progressText
    checklistPanel._progressFrame = progressFrame

    -- Make ESC close this panel
    AddToUISpecialFrames("BistooltipChecklistPanel", mainFrameUISpecialName)

    -- Export button
    local exportBtn = CreateFrame("Button", nil, checklistPanel, "UIPanelButtonTemplate")
    exportBtn:SetPoint("TOPRIGHT", -18, -12)
    exportBtn:SetSize(80, 22)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        if OpenChecklistExport then OpenChecklistExport() end
    end)

    checklistPanel:SetScript("OnHide", function()
        if checklistContainer then
            checklistContainer:ReleaseChildren()
        end
    end)

    -- ScrollFrame container (adjusted position for progress bar)
    checklistContainer = AceGUI:Create("ScrollFrame")
    checklistContainer:SetLayout("List")
    checklistContainer:SetWidth(310)
    checklistContainer:SetHeight(0)

    checklistContainer.frame:SetParent(checklistPanel)
    checklistContainer.frame:SetPoint("TOPLEFT", 15, -65)  -- Moved down for progress bar
    checklistContainer.frame:SetPoint("BOTTOMRIGHT", -15, 15)
    checklistContainer.frame:Show()

    checklistPanel._container = checklistContainer
end

DestroyChecklistPanel = function()
    if checklistPanel then
        checklistPanel:Hide()
        checklistPanel:SetParent(nil)
    end
    checklistPanel = nil
    checklistContainer = nil
end

-- ============================================================
-- Frame Decoration Helpers
-- ============================================================

local function ResetFrameDecor(fr)
    Utils.ResetFrameDecor(fr)
end

clearCheckMarks = function()
    for _, value in ipairs(checkmarks) do
        if value then
            if value.Hide then value:Hide() end
            if value.SetTexture then value:SetTexture(nil) end
            if value.SetVertexColor then value:SetVertexColor(1, 1, 1, 1) end  -- Reset color
        end
    end
    checkmarks = {}
end

clearBoeMarks = function()
    for _, value in ipairs(boemarks) do
        if value then
            if value.Hide then value:Hide() end
            if value.SetTexture then value:SetTexture(nil) end
        end
    end
    boemarks = {}
end

local function NewSimpleGroup()
    local g = AceGUI:Create("SimpleGroup")
    if g and g.frame then ResetFrameDecor(g.frame) end
    return g
end

-- ============================================================
-- Build Checklist Groups
-- ============================================================

local function BuildChecklistGroups()
    local groups = {}
    local totalMissing = 0
    local emblemGroups = {}  -- currency -> { items = {} }

    if not (State.class and State.spec and State.phase) then
        return groups, totalMissing, emblemGroups
    end

    local slots = Bistooltip_bislists
        and Bistooltip_bislists[State.class]
        and Bistooltip_bislists[State.class][State.spec]
        and Bistooltip_bislists[State.class][State.spec][State.phase]

    if type(slots) ~= "table" then
        return groups, totalMissing, emblemGroups
    end

    for _, slot in ipairs(slots) do
        local req = GetRequiredBISItemsForSlot(slot)
        for _, id in ipairs(req) do
            if id and id > 0 and OwnedCount(id) < 1 then
                totalMissing = totalMissing + 1

                local sources = GetAllItemSources(id)
                local zone = "Unknown instance"
                local boss = "Unknown boss"
                local difficulty = nil
                local hasEmblem = false
                local emblemCurrency = nil
                local emblemCost = nil
                
                for _, src in ipairs(sources) do
                    if src.type == "raid" then
                        zone = src.zone or zone
                        boss = src.boss or boss
                        difficulty = src.difficulty
                    elseif src.type == "emblem" then
                        hasEmblem = true
                        emblemCurrency = src.currency
                        emblemCost = src.cost
                    end
                end

                -- Skip non-emblem items if emblem filter is on
                if emblemFilterMode and not hasEmblem then
                    -- Skip this item
                else
                    -- Add to regular groups (by zone/boss)
                    if not emblemFilterMode then
                        groups[zone] = groups[zone] or {}
                        groups[zone][boss] = groups[zone][boss] or { items = {}, difficulty = difficulty }

                        local name = GetItemInfo(id)
                        if not name then
                            if QueuePreload then QueuePreload(id) end
                            name = "Item " .. tostring(id)
                        end

                        table.insert(groups[zone][boss].items, {
                            id = id,
                            name = name,
                            slot = slot.slot_name or "",
                            sources = sources,
                        })
                    end
                    
                    -- Add to emblem groups if has emblem source
                    if hasEmblem and emblemCurrency then
                        emblemGroups[emblemCurrency] = emblemGroups[emblemCurrency] or { items = {}, total = 0 }
                        
                        local name = GetItemInfo(id)
                        if not name then
                            if QueuePreload then QueuePreload(id) end
                            name = "Item " .. tostring(id)
                        end
                        
                        table.insert(emblemGroups[emblemCurrency].items, {
                            id = id,
                            name = name,
                            slot = slot.slot_name or "",
                            cost = emblemCost or 0,
                            sources = sources,
                        })
                        emblemGroups[emblemCurrency].total = emblemGroups[emblemCurrency].total + (emblemCost or 0)
                    end
                end
            end
        end
    end

    -- Sort items within each boss
    for _, bosses in pairs(groups) do
        for _, row in pairs(bosses) do
            if row and row.items then
                table.sort(row.items, function(a, b)
                    if a.slot ~= b.slot then return tostring(a.slot) < tostring(b.slot) end
                    return tostring(a.name) < tostring(b.name)
                end)
            end
        end
    end
    
    -- Sort emblem items by cost (descending)
    for _, data in pairs(emblemGroups) do
        if data.items then
            table.sort(data.items, function(a, b)
                if a.cost ~= b.cost then return (a.cost or 0) > (b.cost or 0) end
                return tostring(a.name) < tostring(b.name)
            end)
        end
    end

    return groups, totalMissing, emblemGroups
end

-- ============================================================
-- Export Functions
-- ============================================================

local exportWindow = nil

local function BuildChecklistExportText()
    local groups, totalMissing, emblemGroups = BuildChecklistGroups()
    local className = tostring(State.class or "?")
    local specName = tostring(State.spec or "?")
    local phaseName = tostring(State.phase or "?")

    local lines = {}
    table.insert(lines, "Bis-Tooltip • BIS Checklist export")
    table.insert(lines, string.format("Class/Spec/Phase: %s / %s / %s", className, specName, phaseName))
    table.insert(lines, string.format("Items missing: %d", tonumber(totalMissing) or 0))
    
    -- Add emblem totals
    local emblemParts = {}
    for currency, data in pairs(emblemGroups) do
        table.insert(emblemParts, string.format("%s: %d", currency, data.total))
    end
    if #emblemParts > 0 then
        table.insert(lines, "Emblems needed: " .. table.concat(emblemParts, ", "))
    end
    
    table.insert(lines, " ")

    -- Regular boss groups
    local zones = {}
    for zone in pairs(groups) do table.insert(zones, zone) end
    table.sort(zones)

    for _, zone in ipairs(zones) do
        table.insert(lines, tostring(zone))

        local bosses = {}
        for boss in pairs(groups[zone]) do table.insert(bosses, boss) end
        table.sort(bosses)

        for _, boss in ipairs(bosses) do
            local row = groups[zone][boss]
            local diffTag = row and row.difficulty and (" (" .. row.difficulty .. ")") or ""
            table.insert(lines, "  - " .. tostring(boss) .. diffTag)

            local its = (row and row.items) or {}

            for _, it in ipairs(its) do
                local iid = it.id
                local link = select(2, GetItemInfo(iid))
                local name = link or it.name or ("item:" .. tostring(iid))
                local slot = it.slot and it.slot ~= "" and ("[" .. tostring(it.slot) .. "] ") or ""
                
                -- Add alternative sources including emblems
                local altSources = ""
                if it.sources then
                    for _, src in ipairs(it.sources) do
                        if src.type == "emblem" then
                            local costText = src.cost and (" x" .. src.cost) or ""
                            altSources = altSources .. " | " .. (src.currency or "Emblem") .. costText
                        end
                    end
                end
                
                table.insert(lines, string.format("      %s%s (id:%s)%s", slot, name, tostring(iid), altSources))
            end
        end
        table.insert(lines, " ")
    end
    
    -- Emblem summary section
    if next(emblemGroups) then
        table.insert(lines, "=== EMBLEM SHOPPING LIST ===")
        table.insert(lines, " ")
        
        local currencies = {}
        for c in pairs(emblemGroups) do table.insert(currencies, c) end
        table.sort(currencies)
        
        for _, currency in ipairs(currencies) do
            local data = emblemGroups[currency]
            table.insert(lines, string.format("%s (Total: %d)", currency, data.total))
            
            for _, it in ipairs(data.items) do
                local name = GetItemInfo(it.id) or it.name
                table.insert(lines, string.format("  - [%s] %s (%d)", it.slot, name, it.cost))
            end
            table.insert(lines, " ")
        end
    end

    return table.concat(lines, "\n")
end

local function EnsureExportWindow()
    if exportWindow then
        exportWindow:Show()
        return
    end

    exportWindow = AceGUI:Create("Frame")
    exportWindow:SetTitle("BIS Checklist • Export")
    exportWindow:SetWidth(620)
    exportWindow:SetHeight(460)
    exportWindow:EnableResize(false)
    exportWindow:SetLayout("Fill")

    local exportName = exportWindow.frame and exportWindow.frame.GetName and exportWindow.frame:GetName() or nil
    AddToUISpecialFrames(exportName)

    exportWindow:SetCallback("OnClose", function(widget)
        RemoveFromUISpecialFrames(exportName)
        AceGUI:Release(widget)
        exportWindow = nil
    end)

    local edit = AceGUI:Create("MultiLineEditBox")
    edit:SetLabel("Ctrl+A then Ctrl+C to copy.")
    edit:SetFullWidth(true)
    edit:SetFullHeight(true)
    if edit.DisableButton then edit:DisableButton(true) end
    exportWindow:AddChild(edit)

    exportWindow._edit = edit
end

OpenChecklistExport = function()
    local txt = BuildChecklistExportText()
    EnsureExportWindow()
    if exportWindow and exportWindow._edit then
        exportWindow._edit:SetText(txt or "")
        local eb = exportWindow._edit.editBox
            or (exportWindow._edit.frame and exportWindow._edit.frame.editBox)
        if eb and eb.SetFocus then
            eb:SetFocus()
            if eb.HighlightText then eb:HighlightText() end
        end
    end
end

-- ============================================================
-- Checklist Panel Renderers (ENHANCED with collapsible sections)
-- ============================================================

-- Get difficulty icon based on difficulty string
local function GetDifficultyIcon(difficulty)
    if not difficulty then return "" end
    local diff = difficulty:upper()
    
    -- Use ASCII-safe indicators for 3.3.5 compatibility
    -- Heroic/HM modes
    if diff:find("HM") or diff:find("HEROIC") or diff:find("H$") then
        return "|cffff0000*H*|r"  -- Red H for Heroic
    end
    
    -- 25-man (nothing special, just show the number)
    if diff:find("25") then
        return ""  -- Already shown in difficulty text
    end
    
    -- 10-man
    if diff:find("10") then
        return ""  -- Already shown in difficulty text
    end
    
    return ""
end

-- Draw separator line between boss groups
local function DrawSeparatorLine(container)
    local sepGroup = NewSimpleGroup()
    sepGroup:SetFullWidth(true)
    sepGroup:SetHeight(12)
    
    local sepLbl = AceGUI:Create("Label")
    sepLbl:SetText("|cff555555- - - - - - - - - - - - - - - - - - - - - - - -|r")
    sepLbl:SetFullWidth(true)
    sepLbl:SetJustifyH("CENTER")
    sepGroup:AddChild(sepLbl)
    container:AddChild(sepGroup)
end

-- Forward declaration for UpdateChecklistPanel
local UpdateChecklistPanel

local function DrawBossHeaderGUI(container, bossName, instanceName, difficulty, itemCount)
    local bossKey = bossName .. "_" .. instanceName
    local isCollapsed = collapsedBosses[bossKey]
    
    local group = NewSimpleGroup()
    group:SetLayout("Flow")
    group:SetFullWidth(true)

    -- Create interactive label for clicking
    local headerLabel = AceGUI:Create("InteractiveLabel")
    headerLabel:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_LARGE + 2, "OUTLINE")
    
    -- Use new colors from Constants
    local bossColor = Constants.COLORS.CHECKLIST_BOSS or "c41f3b"
    local zoneColor = Constants.COLORS.CHECKLIST_ZONE or "ff8000"
    
    -- Collapse indicator (ASCII for 3.3.5 compatibility)
    local collapseIcon = isCollapsed and "|cffffffff[+]|r " or "|cffffffff[-]|r "
    
    -- Difficulty icon
    local diffIcon = GetDifficultyIcon(difficulty)
    local diffText = difficulty and (" |cffaaaaaa(" .. difficulty .. ")|r") or ""
    
    -- Item count badge
    local countBadge = itemCount and string.format(" |cff888888[%d]|r", itemCount) or ""
    
    -- Format: [▼/▶] Boss Name (10HM) [skull/star] [count]
    local text = string.format("\n%s|cff%s%s|r%s %s%s\n|cff%s%s|r", 
        collapseIcon,
        bossColor, bossName:upper(), diffText, diffIcon, countBadge,
        zoneColor, instanceName:gsub("[%(%)]", ""))
    
    headerLabel:SetText(text)
    headerLabel:SetFullWidth(true)
    headerLabel:SetJustifyH("CENTER")
    
    -- Click to toggle collapse
    headerLabel:SetCallback("OnClick", function()
        collapsedBosses[bossKey] = not collapsedBosses[bossKey]
        if UpdateChecklistPanel then
            UpdateChecklistPanel()
        end
    end)
    
    -- Hover effect
    headerLabel:SetCallback("OnEnter", function(widget)
        widget.label:SetTextColor(1, 1, 0.5)  -- Highlight on hover
    end)
    headerLabel:SetCallback("OnLeave", function(widget)
        widget.label:SetTextColor(1, 1, 1)  -- Reset color
    end)

    group:AddChild(headerLabel)
    container:AddChild(group)
    
    return isCollapsed
end

-- Crop icon texture to remove Blizzard borders (zoom ~108%)
-- Defined early so it can be used by DrawItemRowGUI
local function SetIconTexCoord(iconWidget)
    if iconWidget and iconWidget.image then
        iconWidget.image:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

local function DrawItemRowGUI(container, item_id, slot_name, sources)
    local row = NewSimpleGroup()
    row:SetLayout("Flow")
    row:SetFullWidth(true)

    -- Icon (larger)
    local icon = AceGUI:Create("Icon")
    icon:SetImageSize(30, 30)
    icon:SetWidth(36)
    local _, link, quality, _, _, _, _, _, _, texture = GetItemInfo(item_id)

    if not texture then
        texture = "Interface\\Icons\\Inv_misc_questionmark"
        if QueuePreload then QueuePreload(item_id) end
    end

    icon:SetImage(texture)
    SetIconTexCoord(icon)  -- Crop Blizzard border

    icon:SetCallback("OnClick", function()
        if link then ChatEdit_InsertLink(link) end
    end)
    icon:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
        if link then
            GameTooltip:SetHyperlink(link)
        else
            TooltipSetItemByID(GameTooltip, item_id)
        end
        GameTooltip:Show()
    end)
    icon:SetCallback("OnLeave", function() GameTooltip:Hide() end)

    -- Text label with slot, name, and sources (larger font)
    local label = AceGUI:Create("InteractiveLabel")
    label:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "")

    local itemName = GetItemInfo(item_id) or ("loading " .. item_id)
    local slotColor = Constants.COLORS.CHECKLIST_SLOT or "ffd700"  -- Gold for slots
    
    -- Get item quality color for item name
    local _, _, quality = GetItemInfo(item_id)
    local itemColorHex = Utils.GetItemQualityHex(quality) or "ffffffff"

    -- Format sources - use cyan for Ascension emblems
    local sourceText = ""
    if sources and #sources > 0 then
        local parts = {}
        for _, src in ipairs(sources) do
            if src.type == "emblem" then
                -- Use ASCENSION color for all emblems
                local color = Constants.COLORS.ASCENSION or "00ffcc"
                local shortName = src.currency or "Emblem"
                local costText = src.cost and (" x" .. src.cost) or ""
                table.insert(parts, "|cff" .. color .. shortName .. costText .. "|r")
            end
        end
        if #parts > 0 then
            sourceText = "\n" .. table.concat(parts, " ")
        end
    end

    local text = string.format("|cff%s[%s]|r\n|c%s%s|r%s",
        slotColor, slot_name:upper(),
        itemColorHex, itemName,
        sourceText
    )

    label:SetText(text)
    label:SetWidth(260)

    label:SetCallback("OnClick", function() if link then ChatEdit_InsertLink(link) end end)
    label:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
        if link then
            GameTooltip:SetHyperlink(link)
        else
            TooltipSetItemByID(GameTooltip, item_id)
        end
        GameTooltip:Show()
    end)
    label:SetCallback("OnLeave", function() GameTooltip:Hide() end)

    row:AddChild(icon)
    row:AddChild(label)

    container:AddChild(row)
end

UpdateChecklistPanel = function()
    if not bisChecklistMode then
        if checklistPanel then checklistPanel:Hide() end
        return
    end
    if not main_frame or not main_frame.frame or not main_frame.frame:IsShown() then return end

    EnsureChecklistPanel()
    if not checklistPanel or not checklistPanel._container then return end
    checklistPanel:Show()

    checklistPanel._container:ReleaseChildren()

    local groups, totalMissing, emblemGroups = BuildChecklistGroups()

    if emblemFilterMode then
        -- ASCEND MODE: Show only Emblem of Ascension items grouped by cost
        local ascensionData = emblemGroups["Emblem of Ascension"]
        
        if not ascensionData or #ascensionData.items == 0 then
            -- No Emblem of Ascension items
            local headerGroup = NewSimpleGroup()
            headerGroup:SetFullWidth(true)
            local headerLbl = AceGUI:Create("Label")
            headerLbl:SetText("|cff888888No Emblem of Ascension items missing|r")
            headerLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM)
            headerLbl:SetJustifyH("CENTER")
            headerGroup:AddChild(headerLbl)
            checklistPanel._container:AddChild(headerGroup)
            return
        end
        
        -- Group items by cost
        local itemsByCost = {}
        for _, it in ipairs(ascensionData.items) do
            local cost = it.cost or 0
            if not itemsByCost[cost] then
                itemsByCost[cost] = { items = {}, subtotal = 0 }
            end
            table.insert(itemsByCost[cost].items, it)
            itemsByCost[cost].subtotal = itemsByCost[cost].subtotal + cost
        end
        
        -- Sort costs (ascending)
        local costs = {}
        for c in pairs(itemsByCost) do table.insert(costs, c) end
        table.sort(costs)
        
        local grandTotal = 0
        local emblemInfo = Constants and Constants.EMBLEM_VENDORS and Constants.EMBLEM_VENDORS["Emblem of Ascension"]
        local color = emblemInfo and emblemInfo.color or (Constants.COLORS.ASCENSION or "00ffcc")
        
        local isFirstGroup = true
        for _, cost in ipairs(costs) do
            local data = itemsByCost[cost]
            local itemCount = #data.items
            
            -- Add separator between cost groups (not before first)
            if not isFirstGroup then
                DrawSeparatorLine(checklistPanel._container)
            end
            isFirstGroup = false
            
            -- Cost group header
            local costHeader = NewSimpleGroup()
            costHeader:SetLayout("Flow")
            costHeader:SetFullWidth(true)
            
            local costLbl = AceGUI:Create("Label")
            costLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_LARGE + 2, "OUTLINE")
            costLbl:SetText(string.format("\n|cff%sEmblem of Ascension|r |cffffffff[x%d]|r\n", color, cost))
            costLbl:SetFullWidth(true)
            costLbl:SetJustifyH("CENTER")
            costHeader:AddChild(costLbl)
            checklistPanel._container:AddChild(costHeader)
            
            -- Items in this cost group
            for _, it in ipairs(data.items) do
                local row = NewSimpleGroup()
                row:SetLayout("Flow")
                row:SetFullWidth(true)
                
                -- Icon
                local icon = AceGUI:Create("Icon")
                icon:SetImageSize(26, 26)
                icon:SetWidth(32)
                local _, link, quality, _, _, _, _, _, _, texture = GetItemInfo(it.id)
                
                if not texture then
                    texture = "Interface\\Icons\\Inv_misc_questionmark"
                    if QueuePreload then QueuePreload(it.id) end
                end
                
                icon:SetImage(texture)
                SetIconTexCoord(icon)  -- Crop Blizzard border
                icon:SetCallback("OnClick", function()
                    if link then ChatEdit_InsertLink(link) end
                end)
                icon:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
                    if link then
                        GameTooltip:SetHyperlink(link)
                    else
                        TooltipSetItemByID(GameTooltip, it.id)
                    end
                    GameTooltip:Show()
                end)
                icon:SetCallback("OnLeave", function() GameTooltip:Hide() end)
                
                -- Item name and slot - GOLD for slots
                local label = AceGUI:Create("InteractiveLabel")
                label:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "")
                
                local itemName = GetItemInfo(it.id) or ("Item " .. it.id)
                local hexColor = Utils.GetItemQualityHex(quality)
                local slotColor = Constants.COLORS.CHECKLIST_SLOT or "ffd700"
                
                label:SetText(string.format("|cff%s[%s]|r |c%s%s|r", 
                    slotColor, (it.slot or ""):upper(), hexColor, Utils.SmartTrunc(itemName, 22)))
                label:SetWidth(240)
                
                label:SetCallback("OnClick", function() if link then ChatEdit_InsertLink(link) end end)
                label:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
                    if link then
                        GameTooltip:SetHyperlink(link)
                    else
                        TooltipSetItemByID(GameTooltip, it.id)
                    end
                    GameTooltip:Show()
                end)
                label:SetCallback("OnLeave", function() GameTooltip:Hide() end)
                
                row:AddChild(icon)
                row:AddChild(label)
                checklistPanel._container:AddChild(row)
            end
            
            -- Subtotal for this cost group - ORANGE color
            local subtotalGroup = NewSimpleGroup()
            subtotalGroup:SetFullWidth(true)
            local subtotalLbl = AceGUI:Create("Label")
            subtotalLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "")
            local subtotalColor = Constants.COLORS.CHECKLIST_SUBTOTAL or "ff7d0a"
            subtotalLbl:SetText(string.format("|cff%s%d items × %d = %d|r\n", subtotalColor, itemCount, cost, data.subtotal))
            subtotalLbl:SetFullWidth(true)
            subtotalLbl:SetJustifyH("CENTER")
            subtotalGroup:AddChild(subtotalLbl)
            checklistPanel._container:AddChild(subtotalGroup)
            
            grandTotal = grandTotal + data.subtotal
        end
        
        -- Grand total separator and summary
        local sepGroup = NewSimpleGroup()
        sepGroup:SetFullWidth(true)
        local sepLbl = AceGUI:Create("Label")
        sepLbl:SetText("\n|cffffffff--------------------|r")
        sepLbl:SetFullWidth(true)
        sepGroup:AddChild(sepLbl)
        checklistPanel._container:AddChild(sepGroup)
        
        local totalGroup = NewSimpleGroup()
        totalGroup:SetFullWidth(true)
        local totalLbl = AceGUI:Create("Label")
        totalLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_LARGE, "OUTLINE")
        totalLbl:SetText(string.format("|cff%sTOTAL COST: %d|r", color, grandTotal))
        totalLbl:SetFullWidth(true)
        totalLbl:SetJustifyH("CENTER")
        totalGroup:AddChild(totalLbl)
        checklistPanel._container:AddChild(totalGroup)
        
    else
        -- Regular boss-grouped view
        
        -- Update progress bar (instead of Items Missing label)
        if checklistPanel._progressFill and checklistPanel._progressText then
            local totalSlots = 0
            local collectedSlots = 0
            
            -- Use allSlotsForProgress which contains ALL slots (not just displayed ones)
            local allSlots = _G.Bistooltip_allSlotsForProgress or currentFilteredData
            if allSlots then
                for _, slot in ipairs(allSlots) do
                    if slot[1] and slot[1] > 0 then
                        totalSlots = totalSlots + 1
                        if SlotBISCompleted and SlotBISCompleted(slot) then
                            collectedSlots = collectedSlots + 1
                        end
                    end
                end
            end
            
            local barWidth = 276  -- Progress bar internal width
            local percentage = totalSlots > 0 and (collectedSlots / totalSlots) or 0
            
            checklistPanel._progressFill:SetWidth(math.max(1, barWidth * percentage))
            checklistPanel._progressText:SetText(string.format("%d / %d", collectedSlots, totalSlots))
            
            -- Color based on progress
            if percentage >= 1 then
                checklistPanel._progressFill:SetVertexColor(0.1, 0.9, 0.1, 1)  -- Green
            elseif percentage >= 0.6 then
                checklistPanel._progressFill:SetVertexColor(0.1, 0.8, 0.1, 1)  -- Light green
            elseif percentage >= 0.3 then
                checklistPanel._progressFill:SetVertexColor(1.0, 0.6, 0.0, 1)  -- Orange
            else
                checklistPanel._progressFill:SetVertexColor(0.9, 0.2, 0.2, 1)  -- Red
            end
        end
        
        local zones = {}
        for z in pairs(groups or {}) do table.insert(zones, z) end
        table.sort(zones)

        local isFirstBoss = true
        for _, z in ipairs(zones) do
            local bosses = {}
            for b in pairs(groups[z]) do table.insert(bosses, b) end
            table.sort(bosses)

            for _, b in ipairs(bosses) do
                local row = groups[z][b]
                local itemCount = row and row.items and #row.items or 0
                
                -- Add separator line between bosses (not before first)
                if not isFirstBoss then
                    DrawSeparatorLine(checklistPanel._container)
                end
                isFirstBoss = false
                
                -- Draw boss header (returns true if collapsed)
                local isCollapsed = DrawBossHeaderGUI(checklistPanel._container, b, z, row and row.difficulty, itemCount)

                -- Only draw items if not collapsed
                if not isCollapsed and row and row.items then
                    for _, it in ipairs(row.items) do
                        DrawItemRowGUI(checklistPanel._container, it.id, it.slot, it.sources)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Background Item Preloader
-- ============================================================

local preloadFrame = CreateFrame("Frame")
preloadFrame:Hide()
local preloadQueue = {}
local preloadSeen = {}
local preloadCooldown = 0
local PRELOAD_BATCH = Constants.TIMING.PRELOAD_BATCH_SIZE
local PRELOAD_INTERVAL = Constants.TIMING.PRELOAD_INTERVAL

QueuePreload = function(item_id)
    if not item_id or item_id <= 0 then return end
    if preloadSeen[item_id] then return end
    preloadSeen[item_id] = true
    table.insert(preloadQueue, item_id)
    preloadFrame:Show()
end

preloadFrame:SetScript("OnUpdate", function(self, elapsed)
    preloadCooldown = (preloadCooldown or 0) - (elapsed or 0)
    if preloadCooldown > 0 then return end
    preloadCooldown = PRELOAD_INTERVAL

    if #preloadQueue == 0 then
        self:Hide()
        return
    end

    if not BistooltipAddon._preloadScanner then
        local tt = CreateFrame("GameTooltip", "BistooltipPreloadScanner", UIParent, "GameTooltipTemplate")
        tt:SetOwner(UIParent, "ANCHOR_NONE")
        tt:Hide()
        BistooltipAddon._preloadScanner = tt
    end
    local scanTT = BistooltipAddon._preloadScanner

    for i = 1, PRELOAD_BATCH do
        local item_id = table.remove(preloadQueue)
        if not item_id then break end
        if not GetItemInfo(item_id) then
            scanTT:SetHyperlink("item:" .. item_id .. ":0:0:0:0:0:0:0")
            scanTT:Hide()
        end
    end

    if main_frame and spec_frame and main_frame.frame:IsShown() then
        drawSpecData()
    end
end)

-- ============================================================
-- Item Frame Helpers
-- ============================================================

local function ResetIconFrame(fr)
    if not fr then return end
    if fr._bt_owned_border then fr._bt_owned_border:Hide(); fr._bt_owned_border:SetTexture(nil); fr._bt_owned_border = nil end
    if fr._bt_owned_shadow then fr._bt_owned_shadow:Hide(); fr._bt_owned_shadow:SetTexture(nil); fr._bt_owned_shadow = nil end
    if fr._bt_owned_mark then fr._bt_owned_mark:Hide(); fr._bt_owned_mark:SetTexture(nil); fr._bt_owned_mark = nil end
    if fr._bt_boeMark then fr._bt_boeMark:Hide(); fr._bt_boeMark:SetTexture(nil); fr._bt_boeMark = nil end
    if fr._bt_countText then fr._bt_countText:SetText(""); fr._bt_countText:Hide(); fr._bt_countText = nil end
    if fr._bt_baseBorder then fr._bt_baseBorder:Hide(); fr._bt_baseBorder:SetTexture(nil); fr._bt_baseBorder = nil end
end

local function createItemFrame(item_id, size, with_checkmark)
    if item_id < 0 then
        return AceGUI:Create("Label")
    end

    local item_frame = AceGUI:Create("Icon")
    item_frame:SetImageSize(size, size)
    ResetIconFrame(item_frame.frame)

    local aliItemID
    if Bistooltip_horde_to_ali then
        aliItemID = Bistooltip_horde_to_ali[item_id]
    end

    if aliItemID then
        item_id = aliItemID
    end

    local itemName, itemLink, _, _, _, _, _, _, _, itemIcon, _, itemType, _, bindType = GetItemInfo(item_id)

    if not itemName then
        item_frame:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
        SetIconTexCoord(item_frame)  -- Crop border
        QueuePreload(item_id)
        return item_frame
    end

    item_frame:SetImage(itemIcon)
    SetIconTexCoord(item_frame)  -- Crop Blizzard border

    if with_checkmark then
        local texCheck = "Interface\\RaidFrame\\ReadyCheck-Ready"
        local texBorder = "Interface\\Buttons\\UI-ActionButton-Border"
        local markSize = math.max(18, math.floor(size * 0.60))
        local borderSize = math.floor(size * 1.6)

        -- Determine colors first
        local r, g, b, a = 1.00, 0.85, 0.15, 1.00  -- Gold for bags
        if with_checkmark == "equipped" then
            r, g, b, a = 0.00, 1.00, 0.00, 1.00  -- Bright green for equipped
        end

        local border = item_frame.frame:CreateTexture(nil, "OVERLAY")
        border:SetTexture(texBorder)
        border:SetBlendMode("ADD")
        border:SetPoint("CENTER", item_frame.frame, "CENTER", 0, 0)
        border:SetWidth(borderSize)
        border:SetHeight(borderSize)
        border:SetTexCoord(0.13, 0.87, 0.13, 0.87)
        border:SetVertexColor(r, g, b, 0.85)

        local shadow = item_frame.frame:CreateTexture(nil, "OVERLAY")
        shadow:SetTexture(texCheck)
        shadow:SetWidth(markSize)
        shadow:SetHeight(markSize)
        shadow:SetPoint("BOTTOMRIGHT", -2, 2)
        shadow:SetVertexColor(0, 0, 0, 0.75)

        local mark = item_frame.frame:CreateTexture(nil, "OVERLAY")
        mark:SetTexture(texCheck)
        mark:SetWidth(markSize)
        mark:SetHeight(markSize)
        mark:SetPoint("BOTTOMRIGHT", -3, 3)
        mark:SetVertexColor(r, g, b, a)

        item_frame.frame._bt_owned_border = border
        item_frame.frame._bt_owned_shadow = shadow
        item_frame.frame._bt_owned_mark = mark

        table.insert(checkmarks, border)
        table.insert(checkmarks, shadow)
        table.insert(checkmarks, mark)
    end

    -- Stack count overlay for bags
    if with_checkmark == "bags" then
        local countText = item_frame.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        item_frame.frame._bt_countText = countText
        countText:SetPoint("BOTTOMRIGHT", -2, 2)
        countText:SetJustifyH("RIGHT")
        countText:SetTextColor(1, 1, 1, 1)
        countText:SetText("")
        countText._bt_item_id = item_id
        item_frame.frame._bt_countText = countText
    end

    -- BOE marker
    if bindType == 2 then
        local boeMark = item_frame.frame:CreateTexture(nil, "OVERLAY")
        item_frame.frame._bt_boeMark = boeMark
        boeMark:SetWidth(12)
        boeMark:SetHeight(12)
        boeMark:SetPoint("TOPLEFT", 2, -5)
        boeMark:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        table.insert(boemarks, boeMark)
    end

    -- Add OnRelease to clean up textures when widget is released
    local origOnRelease = item_frame.OnRelease
    item_frame.OnRelease = function(w)
        if w and w.frame then
            ResetIconFrame(w.frame)
        end
        if origOnRelease then origOnRelease(w) end
    end

    item_frame:SetCallback("OnClick", function(button)
        SetItemRef(itemLink, itemLink, "LeftButton")
    end)
    item_frame:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(item_frame.frame, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPRIGHT", item_frame.frame, "TOPRIGHT", 220, -13)
        GameTooltip:SetHyperlink(itemLink)
    end)
    item_frame:SetCallback("OnLeave", function(widget)
        GameTooltip:Hide()
    end)

    return item_frame
end

local function createSpellFrame(spell_id, size)
    if spell_id < 0 then
        return AceGUI:Create("Label")
    end

    local spell_frame = AceGUI:Create("Icon")
    spell_frame:SetImageSize(size, size)

    local name, rank, icon = GetSpellInfo(spell_id)
    if not name then
        return spell_frame
    end

    spell_frame:SetImage(icon)
    local link = GetSpellLink(spell_id)
    if not link then
        link = "\124cffffd000\124Hspell:" .. spell_id .. "\124h[" .. name .. "]\124h\124r"
    end

    spell_frame:SetCallback("OnClick", function(button)
        SetItemRef(link, link, "LeftButton")
    end)
    spell_frame:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(spell_frame.frame, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPRIGHT", spell_frame.frame, "TOPRIGHT", 220, -13)
        GameTooltip:SetHyperlink(link)
    end)
    spell_frame:SetCallback("OnLeave", function(widget)
        GameTooltip:Hide()
    end)

    return spell_frame
end

-- ============================================================
-- Gem Grid Frame
-- ============================================================

-- ============================================================
-- Gem Grid Frame (2x2)
-- ============================================================
local function createGemGridFrame(gemIds)
    local g = NewSimpleGroup()
    g:SetLayout("Table")
    g:SetWidth(30)
    g:SetHeight(30)
    g:SetAutoAdjustHeight(false)
    g:SetUserData("table", {
        columns = { { width = 14 }, { width = 14 } },
        spaceV = 0,
        spaceH = 0,
        align = "TOPLEFT",
    })

    local function Spacer(w)
        local s = AceGUI:Create("Label")
        s:SetText(" ")
        s:SetWidth(w or 14)
        if s.SetFullWidth then s:SetFullWidth(false) end
        return s
    end

    -- zawsze 4 komórki (2x2), żeby layout się nie “łamał”
    for i = 1, 4 do
        local id = gemIds and gemIds[i]
        if id and id > 0 then
            local ic = createItemFrame(id, 14)
            if ic and ic.SetWidth then ic:SetWidth(14) end
            g:AddChild(ic)
        else
            g:AddChild(Spacer(14))
        end
    end

    return g
end


-- ============================================================
-- Enhancement Frame (two columns: enchants | gems with counts)
-- ============================================================

-- ============================================================
-- Enhancement Frame (Enchant left + Gems 2x2 right)
-- ============================================================
local function createEnhancementsFrame(enhs)
    local frame = NewSimpleGroup()
    frame:SetLayout("Table")
    frame:SetAutoAdjustHeight(false)
    frame:SetHeight(40)
    frame:SetWidth(64)
    frame:SetUserData("table", {
        columns = { { width = 18 }, { width = 34 } },
        spaceH = 2,
        spaceV = 0,
        align = "TOPLEFT",
    })

    local enchantSpellId = nil
    local gemIds = {}

    if enhs then
        for _, enh in ipairs(enhs) do
            if enh and enh.type == "spell" and enh.id and enh.id > 0 and not enchantSpellId then
                enchantSpellId = enh.id
            elseif enh and enh.type == "item" and enh.id and enh.id > 0 then
                -- w Twoich danych: itemy = gemy
                table.insert(gemIds, enh.id)
            end
        end
    end

    local function Spacer(w)
        local s = AceGUI:Create("Label")
        s:SetText(" ")
        s:SetWidth(w or 18)
        if s.SetFullWidth then s:SetFullWidth(false) end
        return s
    end

    -- col 1: enchant (1 “linia”)
    if enchantSpellId then
        local ench = createSpellFrame(enchantSpellId, 18)
        if ench and ench.SetWidth then ench:SetWidth(18) end
        frame:AddChild(ench)
    else
        frame:AddChild(Spacer(18))
    end

    -- col 2: gemy (2 linie = 2x2)
    if gemIds and #gemIds > 0 then
        frame:AddChild(createGemGridFrame(gemIds))
    else
        local empty = NewSimpleGroup()
        empty:SetLayout("Fill")
        empty:SetAutoAdjustHeight(false)
        empty:SetWidth(30)
        empty:SetHeight(30)
        frame:AddChild(empty)
    end

    return frame
end


-- ============================================================
-- Boss/Item Info Frame for Checklist Mode (ENHANCED)
-- ============================================================

local function CreateBossItemInfoFrame(slot)
    local group = NewSimpleGroup()
    group:SetLayout("List")
    group:SetAutoAdjustHeight(false)
    group:SetHeight(56)
    group:SetWidth(Constants.UI.PLAN_COLUMN_WIDTH or 180)

    local item_id = slot and slot[1]
    local boss = ""
    local itemName = ""
    local difficulty = nil
    local enchantName = nil
    local enchantIcon = nil
    local enchantId = nil
    local enchantType = nil
    local emblemInfo = nil

    if item_id and item_id > 0 then
        local name = GetItemInfo(item_id)
        if not name then
            if QueuePreload then QueuePreload(item_id) end
            name = "Item " .. tostring(item_id)
        end
        itemName = Utils.TruncateText(name, Constants.UI.ITEM_NAME_MAX_CHARS or 28)

        -- Get source with difficulty
        local sources = GetAllItemSources(item_id)
        for _, src in ipairs(sources) do
            if src.type == "raid" then
                boss = Utils.TruncateText(src.boss, Constants.UI.BOSS_NAME_MAX_CHARS or 22)
                difficulty = src.difficulty
            elseif src.type == "emblem" then
                emblemInfo = src
            end
        end
        
        -- Get enchant name, icon, id, and type
        enchantName, enchantIcon, enchantId, enchantType = GetSlotEnchantInfo(slot)
        if enchantName then
            enchantName = Utils.TruncateText(enchantName, Constants.UI.ENCHANT_NAME_MAX_CHARS or 24)
        end
    end

    -- Boss line with difficulty tag
    local bossLbl = AceGUI:Create("Label")
    bossLbl:SetFullWidth(true)
    bossLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "OUTLINE")
    bossLbl:SetJustifyH("LEFT")
    
    local bossText = ""
    if boss ~= "" then
        bossText = "|cffffd200" .. boss .. "|r"
        if difficulty then
            bossText = bossText .. " |cffaaaaaa(" .. difficulty .. ")|r"
        end
    elseif emblemInfo then
        -- Show emblem source if no boss - use cyan color
        local color = Constants.COLORS and Constants.COLORS.ASCENSION or "00ffcc"
        bossText = "|cff" .. color .. (emblemInfo.currency or "Emblem") .. " x" .. (emblemInfo.cost or "?") .. "|r"
    else
        bossText = "|cff666666Unknown Source|r"
    end
    bossLbl:SetText(bossText)
    group:AddChild(bossLbl)

    -- Item name line
    local itemLbl = AceGUI:Create("Label")
    itemLbl:SetFullWidth(true)
    itemLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "OUTLINE")
    itemLbl:SetJustifyH("LEFT")
    itemLbl:SetText(itemName ~= "" and ("|cffff8040" .. itemName .. "|r") or " ")
    group:AddChild(itemLbl)

    -- Enchant line with clickable icon
    if enchantName and enchantId then
        local enchGroup = NewSimpleGroup()
        enchGroup:SetFullWidth(true)
        enchGroup:SetLayout("Flow")
        enchGroup:SetAutoAdjustHeight(false)
        enchGroup:SetHeight(20)
        
        -- Enchant icon with tooltip
        local iconSize = Constants.UI.ICON_SIZE_ENCHANT or 16
        local enchIcon = AceGUI:Create("Icon")
        enchIcon:SetImageSize(iconSize, iconSize)
        enchIcon:SetWidth(iconSize + 2)
        enchIcon:SetHeight(iconSize + 2)
        
        if enchantIcon then
            enchIcon:SetImage(enchantIcon)
        else
            enchIcon:SetImage("Interface\\Icons\\Trade_Engraving")
        end
        
        -- Add tooltip callbacks
        enchIcon:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            if enchantType == "spell" then
                local link = GetSpellLink(enchantId)
                if link then
                    GameTooltip:SetHyperlink(link)
                else
                    GameTooltip:SetSpellByID(enchantId)
                end
            else
                TooltipSetItemByID(GameTooltip, enchantId)
            end
            GameTooltip:Show()
        end)
        enchIcon:SetCallback("OnLeave", function(widget)
            GameTooltip:Hide()
        end)
        
        enchGroup:AddChild(enchIcon)
        
        -- Enchant name label
        local enchLbl = AceGUI:Create("Label")
        enchLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_SMALL, "")
        enchLbl:SetText("|cff00ff00" .. enchantName .. "|r")
        enchLbl:SetWidth(140)
        enchGroup:AddChild(enchLbl)
        
        group:AddChild(enchGroup)
    else
        -- Empty line if no enchant
        local emptyLbl = AceGUI:Create("Label")
        emptyLbl:SetText("")
        emptyLbl:SetFullWidth(true)
        group:AddChild(emptyLbl)
    end

    return group
end

-- ============================================================
-- Draw Gem Plan Row (with clickable icons and tooltips)
-- ============================================================

local function DrawGemPlanRow(gemIds)
    if not gemIds or #gemIds == 0 then return end

    local e1 = AceGUI:Create("Label"); e1:SetText(" ")
    local e2 = AceGUI:Create("Label"); e2:SetText(" ")
    spec_frame:AddChild(e1)
    spec_frame:AddChild(e2)

    local box = NewSimpleGroup()
    box:SetLayout("Flow")
    box:SetAutoAdjustHeight(false)
    box:SetHeight(30)
    box:SetUserData("cell", { colspan = 6 })

    -- Remove any default backdrop
    if box.frame.SetBackdrop then
        box.frame:SetBackdrop(nil)
    end

    -- Calculate centering padding based on gem count
    local gemCount = #gemIds
    local estimatedWidth = gemCount * 70 + (gemCount - 1) * 6  -- icon+text + spacers
    local boxWidth = 300  -- Approximate box width
    local leftPadding = math.max(4, math.floor((boxWidth - estimatedWidth) / 2))
    
    -- Left padding spacer for centering
    local leftPad = AceGUI:Create("Label")
    leftPad:SetWidth(leftPadding)
    leftPad:SetText("")
    box:AddChild(leftPad)

    local iconSize = 16  -- Smaller gems to fit better
    
    for i, id in ipairs(gemIds) do
        -- Add spacer between gem groups (icon+text)
        if i > 1 then
            local spacer = AceGUI:Create("Label")
            spacer:SetWidth(6)
            spacer:SetText("")
            box:AddChild(spacer)
        end
        
        -- Create gem icon with tooltip
        local gemIcon = AceGUI:Create("Icon")
        gemIcon:SetImageSize(iconSize, iconSize)
        gemIcon:SetWidth(iconSize + 2)
        gemIcon:SetHeight(iconSize + 2)
        
        local name, itemLink, _, _, _, _, _, _, _, texture = GetItemInfo(id)
        if texture then
            gemIcon:SetImage(texture)
            SetIconTexCoord(gemIcon)  -- Crop Blizzard border
        else
            gemIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
            if QueuePreload then QueuePreload(id) end
        end
        
        -- Add tooltip callbacks
        gemIcon:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            if itemLink then
                GameTooltip:SetHyperlink(itemLink)
            else
                TooltipSetItemByID(GameTooltip, id)
            end
            GameTooltip:Show()
        end)
        gemIcon:SetCallback("OnLeave", function(widget)
            GameTooltip:Hide()
        end)
        gemIcon:SetCallback("OnClick", function(widget)
            if itemLink then
                SetItemRef(itemLink, itemLink, "LeftButton")
            end
        end)
        
        box:AddChild(gemIcon)
        
        -- Add stat text
local t = BuildGemStatTokenTwoLines(id)
if t and t ~= "" then
    local statLbl = AceGUI:Create("Label")
    statLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_SMALL, "OUTLINE")
    statLbl:SetText("|cff55aaff" .. t .. "|r")
    statLbl:SetWidth(60)      -- było 52
    statLbl:SetHeight(26)     -- żeby 2 linie nie były cięte
    if statLbl.label then
        statLbl.label:SetJustifyH("LEFT")
        statLbl.label:SetWordWrap(true)
    end
    box:AddChild(statLbl)
end

    end

    do
        local orig = box.OnRelease
        box.OnRelease = function(w)
            if w and w.frame then ResetFrameDecor(w.frame) end
            if orig then orig(w) end
        end
    end

    spec_frame:AddChild(box)
end

-- ============================================================
-- Custom Priority Management
-- ============================================================

local function GetCustomPriorityKey(slotName)
    return string.format("%s_%s_%s_%s", 
        State.class or "Unknown",
        State.spec or "Unknown", 
        State.phase or "Unknown",
        slotName or "Unknown")
end

-- Save custom priority to saved variables (from working 1.3.2)
local function SaveCustomPriority(slotName, slot)
    local key = GetCustomPriorityKey(slotName)
    local itemIds = {}
    for i, id in ipairs(slot) do
        itemIds[i] = id
    end
    customPriorities[key] = itemIds
    
    -- Persist to saved variables
    if BistooltipAddon.db and BistooltipAddon.db.char then
        BistooltipAddon.db.char.custom_priorities = BistooltipAddon.db.char.custom_priorities or {}
        BistooltipAddon.db.char.custom_priorities[key] = itemIds
    end
end

-- Load and APPLY custom priority to slot data
-- This modifies the actual slot table so tooltips and BIS checklist see the changes
local function LoadCustomPriority(slotName, slot)
    local key = GetCustomPriorityKey(slotName)
    
    -- Store original order BEFORE any modifications (only once per key)
    if not originalSlotOrders[key] then
        local origOrder = {}
        for i, id in ipairs(slot) do
            if type(id) == "number" then
                origOrder[i] = id
            end
        end
        originalSlotOrders[key] = origOrder
    end
    
    local savedOrder = customPriorities[key]
    
    if not savedOrder then
        -- Try loading from saved variables
        if BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.custom_priorities then
            savedOrder = BistooltipAddon.db.char.custom_priorities[key]
            if savedOrder then
                customPriorities[key] = savedOrder
            end
        end
    end
    
    if savedOrder and #savedOrder > 0 then
        -- Reorder slot items based on saved priority
        local newOrder = {}
        local usedIndices = {}
        
        -- First, add items in saved order
        for _, savedId in ipairs(savedOrder) do
            for i, slotId in ipairs(slot) do
                if slotId == savedId and not usedIndices[i] then
                    table.insert(newOrder, slotId)
                    usedIndices[i] = true
                    break
                end
            end
        end
        
        -- Then add any remaining items not in saved order
        for i, slotId in ipairs(slot) do
            if not usedIndices[i] then
                table.insert(newOrder, slotId)
            end
        end
        
        -- Apply new order - THIS MODIFIES THE ACTUAL SLOT DATA
        for i, id in ipairs(newOrder) do
            slot[i] = id
        end
    end
end

-- Restore original slot order (used by reset)
local function RestoreOriginalOrder(slotName, slot)
    local key = GetCustomPriorityKey(slotName)
    local origOrder = originalSlotOrders[key]
    
    if origOrder and #origOrder > 0 then
        -- Restore original order to slot
        for i, id in ipairs(origOrder) do
            slot[i] = id
        end
    end
end

-- Clear custom priorities and restore original order for current spec/phase
local function ResetCustomPriorities()
    local prefix = string.format("%s_%s_%s_", 
        State.class or "Unknown",
        State.spec or "Unknown", 
        State.phase or "Unknown")
    
    -- First, restore original orders to the actual slot data
    if Bistooltip_bislists and State.class and State.spec and State.phase then
        local slots = Bistooltip_bislists[State.class] and 
                      Bistooltip_bislists[State.class][State.spec] and
                      Bistooltip_bislists[State.class][State.spec][State.phase]
        if slots then
            for _, slot in ipairs(slots) do
                if slot.slot_name then
                    RestoreOriginalOrder(slot.slot_name, slot)
                end
            end
        end
    end
    
    -- Clear saved custom priorities
    for key, _ in pairs(customPriorities) do
        if key:find(prefix, 1, true) == 1 then
            customPriorities[key] = nil
        end
    end
    
    -- Clear original orders so they can be re-captured
    for key, _ in pairs(originalSlotOrders) do
        if key:find(prefix, 1, true) == 1 then
            originalSlotOrders[key] = nil
        end
    end
    
    -- Clear from saved variables
    if BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.custom_priorities then
        for key, _ in pairs(BistooltipAddon.db.char.custom_priorities) do
            if key:find(prefix, 1, true) == 1 then
                BistooltipAddon.db.char.custom_priorities[key] = nil
            end
        end
    end
end

-- Clean up all selection borders (called before redraw)
local function ClearAllSelectionBorders()
    for _, border in ipairs(selectionBorders) do
        if border and border.Hide then
            border:Hide()
        end
    end
    selectionBorders = {}
end

-- ============================================================
-- Draw Item Slot
-- ============================================================

local function drawItemSlot(slot, zebraOn)
    -- Slot name label (bold)
    local f = AceGUI:Create("Label")
    f:SetText("|cffffd700" .. slot.slot_name .. "|r")
    f:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_LARGE, "OUTLINE")
    spec_frame:AddChild(f)

    local gemIds = nil

    if bisChecklistMode then
        spec_frame:AddChild(CreateBossItemInfoFrame(slot))
        gemIds = CollectGemIdsFromEnhancements(slot.enhs)
    else
        spec_frame:AddChild(createEnhancementsFrame(slot.enhs))
    end

    local slotName = slot.slot_name
    local isUnlocked = unlockedSlots[slotName]
    
    -- Iterate directly over slot (LoadCustomPriority already modified it)
    for i, original_item_id in ipairs(slot) do
        local item_id = original_item_id

        if isHorde and Bistooltip_horde_to_ali then
            local translated_item_id = Bistooltip_horde_to_ali[original_item_id]
            if translated_item_id then
                item_id = translated_item_id
            end
        end

        local owned = GetOwnedRow(item_id)
        local ownedState = nil
        local ownedCount = 0
        if owned then
            local bags = owned.bags or 0
            local eq = owned.equipped or 0
            if eq > 0 then
                ownedState = "equipped"
            elseif bags > 0 then
                ownedState = "bags"
                ownedCount = bags
            end
        end

        if showOnlyMissing and ownedState then
            spec_frame:AddChild(AceGUI:Create("Label"))
        else
            local w = createItemFrame(item_id, Constants.UI.ICON_SIZE_ITEM, ownedState)
            if w and w.frame and w.frame._bt_countText then
                if ownedState == "bags" and ownedCount and ownedCount > 1 then
                    w.frame._bt_countText:SetText(ownedCount)
                else
                    w.frame._bt_countText:SetText("")
                end
            end
            
            -- Check if this item is selected for swap (show red border)
            local isSelected = selectedSwapItem and 
                              selectedSwapItem.slotName == slotName and 
                              selectedSwapItem.index == i
            
            if isSelected and w.frame then
                -- Add thick red border to show selection - use same pattern as checkmark
                local size = Constants.UI.ICON_SIZE_ITEM or 45
                local borderSize = math.floor(size * 1.6)
                
                local border = w.frame:CreateTexture(nil, "OVERLAY")
                border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                border:SetBlendMode("ADD")
                border:SetVertexColor(1, 0, 0, 1)  -- Red
                border:SetPoint("CENTER", w.frame, "CENTER", 0, 0)
                border:SetWidth(borderSize)
                border:SetHeight(borderSize)
                border:SetTexCoord(0.13, 0.87, 0.13, 0.87)
                w.frame._selectBorder = border
                -- Track this border for cleanup
                table.insert(selectionBorders, border)
            end
            
            -- In customize mode with unlocked slot, add click to select/swap
            if customizeMode and isUnlocked and w.SetCallback then
                local itemIndex = i
                w:SetCallback("OnClick", function(widget, event, button)
                    if button == "LeftButton" then
                        -- Save scroll position BEFORE any changes
                        if spec_frame and spec_frame.localstatus then
                            savedScrollValue = spec_frame.localstatus.scrollvalue or 0
                        end
                        
                        if selectedSwapItem and selectedSwapItem.slotName == slotName then
                            if selectedSwapItem.index == itemIndex then
                                -- Clicking same item - deselect
                                selectedSwapItem = nil
                            else
                                -- Second click on different item - perform swap directly on slot
                                local temp = slot[selectedSwapItem.index]
                                slot[selectedSwapItem.index] = slot[itemIndex]
                                slot[itemIndex] = temp
                                -- Save custom priority
                                SaveCustomPriority(slotName, slot)
                                -- Clear selection after swap
                                selectedSwapItem = nil
                            end
                        else
                            -- First click - select this item
                            selectedSwapItem = {slotName = slotName, index = itemIndex, itemId = item_id}
                        end
                        drawSpecData()
                    elseif button == "RightButton" then
                        -- Save scroll position
                        if spec_frame and spec_frame.localstatus then
                            savedScrollValue = spec_frame.localstatus.scrollvalue or 0
                        end
                        -- Right click - clear selection or link to chat
                        if selectedSwapItem then
                            selectedSwapItem = nil
                            drawSpecData()
                        else
                            local _, link = GetItemInfo(item_id)
                            if link then ChatEdit_InsertLink(link) end
                        end
                    end
                end)
            elseif not customizeMode or not isUnlocked then
                -- Normal click behavior - link to chat
                if w.SetCallback then
                    w:SetCallback("OnClick", function(widget, event, button)
                        if button == "LeftButton" then
                            local _, link = GetItemInfo(item_id)
                            if link then ChatEdit_InsertLink(link) end
                        end
                    end)
                end
            end
            
            spec_frame:AddChild(w)
        end
    end
    
    -- Lock icon column (only in customize mode, NOT in BIS checklist)
    if customizeMode and not bisChecklistMode then
        local lockBtn = AceGUI:Create("InteractiveLabel")
        local lockIcon = isUnlocked and "|cff00ff00[O]|r" or "|cffaaaaaa[X]|r"
        lockBtn:SetText(lockIcon)
        lockBtn:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "")
        lockBtn:SetWidth(30)
        lockBtn:SetCallback("OnClick", function()
            -- Save scroll position
            if spec_frame and spec_frame.localstatus then
                savedScrollValue = spec_frame.localstatus.scrollvalue or 0
            end
            
            local wasUnlocked = unlockedSlots[slotName]
            unlockedSlots[slotName] = not unlockedSlots[slotName]
            
            -- Clear selection if locking this slot
            if not unlockedSlots[slotName] and selectedSwapItem and selectedSwapItem.slotName == slotName then
                selectedSwapItem = nil
            end
            
            if BistooltipAddon.db and BistooltipAddon.db.char then
                BistooltipAddon.db.char.unlocked_slots = unlockedSlots
            end
            drawSpecData()
        end)
        lockBtn:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            if isUnlocked then
                GameTooltip:SetText("|cff00ff00UNLOCKED|r\nClick item to select (red border)\nClick another item to SWAP\nRight-click to cancel\nClick here to lock")
            else
                GameTooltip:SetText("|cffaaaaaaLOCKED|r\nClick to unlock slot for customization")
            end
            GameTooltip:Show()
        end)
        lockBtn:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        spec_frame:AddChild(lockBtn)
    end

    -- Gem plan row (only in checklist mode)
    if bisChecklistMode then
        DrawGemPlanRow(gemIds)
    end
    
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    spacer:SetHeight(4) -- reguluj: 4-10
    spacer:SetUserData("cell", { colspan = (customizeMode and not bisChecklistMode) and 9 or 8 })
    spec_frame:AddChild(spacer)

end

-- ============================================================
-- Draw Table Header
-- ============================================================

local function drawTableHeader(frame)
    local color = 0.6

    -- Get current table layout widths
    local itemColWidth = 60  -- Default item column width
    local smallColWidth = 48
    
    if bisChecklistMode then
        itemColWidth = 54
        smallColWidth = 48
    elseif customizeMode then
        itemColWidth = 55
        smallColWidth = 45
    end

    local f = AceGUI:Create("Label")
    f:SetText("Slot")
    f:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_LARGE, "")
    f:SetColor(color, color, color)
    frame:AddChild(f)

    local h2 = AceGUI:Create("Label")
    if bisChecklistMode then
        h2:SetText("Plan")
        h2:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "")
        h2:SetColor(color, color, color)
    else
        h2:SetText(" ")
    end
    frame:AddChild(h2)

    -- Headers: BIS, TOP1, TOP2, TOP3, TOP4, TOP5
    for i = 1, 6 do
        f = AceGUI:Create("Label")
        if i == 1 then
            f:SetText("|cff00ff00BIS|r")
        else
            f:SetText("TOP" .. (i - 1))
        end
        f:SetColor(color, color, color)
        frame:AddChild(f)
    end
    
    -- Lock column header (only in customize mode AND not in BIS checklist)
    if customizeMode and not bisChecklistMode then
        local lockHeader = AceGUI:Create("InteractiveLabel")
        lockHeader:SetText("|cffffd700[L]|r")
        lockHeader:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "")
        lockHeader:SetWidth(30)
        -- Click to unlock all slots
        lockHeader:SetCallback("OnClick", function()
            -- Toggle all slots
            local allUnlocked = true
            for slotName, _ in pairs(unlockedSlots) do
                if not unlockedSlots[slotName] then
                    allUnlocked = false
                    break
                end
            end
            -- If all unlocked, lock all. Otherwise unlock all.
            if allUnlocked and next(unlockedSlots) then
                unlockedSlots = {}
                selectedSwapItem = nil
            else
                -- Unlock all current slots
                if currentFilteredData then
                    for _, slot in ipairs(currentFilteredData) do
                        if slot.slot_name then
                            unlockedSlots[slot.slot_name] = true
                        end
                    end
                end
            end
            -- Save scroll position
            if spec_frame and spec_frame.localstatus then
                savedScrollValue = spec_frame.localstatus.scrollvalue or 0
            end
            drawSpecData()
        end)
        lockHeader:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText("Click to toggle all locks")
            GameTooltip:Show()
        end)
        lockHeader:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        frame:AddChild(lockHeader)
    end
end

-- ============================================================
-- Save/Load Data
-- ============================================================

local function saveData()
    BistooltipAddon.db.char.class_index = State.class_index
    BistooltipAddon.db.char.spec_index = State.spec_index
    BistooltipAddon.db.char.phase_index = State.phase_index
end

-- ============================================================
-- Draw Spec Data (Main Refresh Function)
-- ============================================================

drawSpecData = function()
    -- Clear all selection borders first (before releasing children)
    ClearAllSelectionBorders()
    
    clearCheckMarks()
    clearBoeMarks()
    saveData()
    items = {}
    spells = {}
    spec_frame:ReleaseChildren()
    ApplySpecTable()
    drawTableHeader(spec_frame)
    
    if not State.spec or not State.phase then
        return
    end
    
    if not Bistooltip_bislists or not Bistooltip_bislists[State.class] then
        return
    end
    
    if not Bistooltip_bislists[State.class][State.spec] then
        return
    end
    
    local slots = Bistooltip_bislists[State.class][State.spec][State.phase]
    if not slots then return end

    local function rowMatches(slot)
        if not searchTextLower or searchTextLower == "" then return true end
        if slot.slot_name and string.find(string.lower(slot.slot_name), searchTextLower, 1, true) then
            return true
        end
        for _, iid in ipairs(slot) do
            local id = iid
            if isHorde and Bistooltip_horde_to_ali and Bistooltip_horde_to_ali[iid] then
                id = Bistooltip_horde_to_ali[iid]
            end
            if tostring(id) == searchTextLower then
                return true
            end
            local name = GetItemInfo(id)
            if name and string.find(string.lower(name), searchTextLower, 1, true) then
                return true
            elseif not name then
                QueuePreload(id)
            end
        end
        return false
    end

    -- Check if slot has Emblem of Ascension source (for ASCEND filter)
    local function slotHasAscensionSource(slot)
        if not emblemFilterMode then return true end
        
        for _, iid in ipairs(slot) do
            local id = iid
            if isHorde and Bistooltip_horde_to_ali and Bistooltip_horde_to_ali[iid] then
                id = Bistooltip_horde_to_ali[iid]
            end
            
            -- Check specifically for Emblem of Ascension
            local cost, currency = GetEmblemCost(id)
            if currency == "Emblem of Ascension" then
                return true
            end
        end
        return false
    end

    -- Store filtered data for other functions (like progress bar)
    currentFilteredData = {}
    
    -- Store ALL slots for progress bar calculation (regardless of completion status)
    local allSlotsForProgress = {}
    
    for i, slot in ipairs(slots) do
        if rowMatches(slot) and slotHasAscensionSource(slot) then
            -- Apply custom priorities - this MODIFIES slot data so tooltips see the change
            if slot.slot_name then
                LoadCustomPriority(slot.slot_name, slot)
            end
            
            -- Always add to allSlotsForProgress for correct progress counting
            table.insert(allSlotsForProgress, slot)
            
            if bisChecklistMode and SlotBISCompleted(slot) then
                -- Skip completed slots in checklist mode (for display only)
            else
                table.insert(currentFilteredData, slot)
                drawItemSlot(slot)
            end
        end
    end
    
    -- Store the full slot list for progress bar updates
    _G.Bistooltip_allSlotsForProgress = allSlotsForProgress

    -- Update hint label
    if checklistSummaryLabel then
        if not bisChecklistMode then
            checklistSummaryLabel:SetText("")
        elseif emblemFilterMode then
            checklistSummaryLabel:SetText("|cffff00ffASCEND MODE|r: Showing Emblem of Ascension items only")
        else
            checklistSummaryLabel:SetText("|cffffff00BIS checklist|r: Boss/Item + gem plan shown. Full list in right panel.")
        end
    end

    -- Update emblem summary with icon - ONLY show in ASCEND mode
    if emblemSummaryLabel then
        if bisChecklistMode and emblemFilterMode then
            local totals = CalculateMissingEmblems()
            local ascensionData = totals["Emblem of Ascension"]
            
            if ascensionData and ascensionData.total > 0 then
                -- Use cyan color from Constants
                local color = Constants.COLORS and Constants.COLORS.ASCENSION or "00ffcc"
                
                -- Get emblem icon
                local iconSize = 20
                local _, _, _, _, _, _, _, _, _, emblemTexture = GetItemInfo(EMBLEM_OF_ASCENSION_ID)
                local iconStr = ""
                if emblemTexture then
                    iconStr = string.format("|T%s:%d:%d:0:0|t ", emblemTexture, iconSize, iconSize)
                end
                
                emblemSummaryLabel:SetText(string.format("%s|cff%sEmblem of Ascension:\n%d|r", iconStr, color, ascensionData.total))
            else
                emblemSummaryLabel:SetText("|cff00ff00✓ All Ascension items collected!|r")
            end
        else
            -- Hide emblem summary when not in ASCEND mode
            emblemSummaryLabel:SetText("")
        end
    end

    -- Update side panel
    UpdateChecklistPanel()
    
    -- Restore scroll position after redraw (use longer delay to ensure frame is ready)
    if savedScrollValue and savedScrollValue > 0 and spec_frame then
        -- Use a slightly longer delay to ensure the scroll frame content is fully rendered
        C_Timer.After(0.05, function()
            if spec_frame and spec_frame.SetScroll then
                spec_frame:SetScroll(savedScrollValue)
                -- Reset the saved value after restoring
                savedScrollValue = 0
            end
        end)
    end
end

-- ============================================================
-- Build Class/Spec Dictionaries
-- ============================================================

local function buildClassDict()
    class_options = {}
    class_options_to_class = {}

    if Bistooltip_classes and type(Bistooltip_classes) == "table" and #Bistooltip_classes > 0 then
        for ci, class in ipairs(Bistooltip_classes) do
            local option_name = ColorizeClassOption(class.name)
            table.insert(class_options, option_name)
            class_options_to_class[option_name] = { name = class.name, i = ci }
        end
        return
    end

    -- Fallback: build from spec icons
    local ordered = {}
    if Bistooltip_classes_indexes then
        for cname, idx in pairs(Bistooltip_classes_indexes) do 
            ordered[idx] = cname 
        end
    end
    if #ordered == 0 and Bistooltip_spec_icons then
        for cname, _ in pairs(Bistooltip_spec_icons) do 
            table.insert(ordered, cname) 
        end
        table.sort(ordered)
    end

    local ci = 1
    for _, cname in ipairs(ordered) do
        local option_name = ColorizeClassOption(cname)
        table.insert(class_options, option_name)
        class_options_to_class[option_name] = { name = cname, i = ci }
        ci = ci + 1
    end
end

local function buildSpecsDict(class_i)
    spec_options = {}
    spec_options_to_spec = {}

    if Bistooltip_classes and type(Bistooltip_classes) == "table" and #Bistooltip_classes > 0 then
        local cls = Bistooltip_classes[class_i]
        if not cls or not cls.specs then return end

        for _, specName in ipairs(cls.specs) do
            local icon = nil
            if Bistooltip_spec_icons and Bistooltip_spec_icons[cls.name] then
                icon = Bistooltip_spec_icons[cls.name][specName]
            end

            local option_name = icon and ("|T" .. icon .. ":14|t " .. specName) or specName
            table.insert(spec_options, option_name)
            spec_options_to_spec[option_name] = specName
        end
        return
    end

    -- Fallback
    local clsName = class_options_to_class[class_options[class_i]] and class_options_to_class[class_options[class_i]].name
    if not clsName or not Bistooltip_wowtbc_bislists or not Bistooltip_wowtbc_bislists[clsName] then return end

    local specs = {}
    for sname, _ in pairs(Bistooltip_wowtbc_bislists[clsName]) do
        table.insert(specs, sname)
    end
    table.sort(specs)

    for _, sname in ipairs(specs) do
        table.insert(spec_options, sname)
        spec_options_to_spec[sname] = sname
    end
end

local function loadData()
    State.class_index = BistooltipAddon.db.char.class_index
    State.spec_index = BistooltipAddon.db.char.spec_index
    State.phase_index = BistooltipAddon.db.char.phase_index

    if not State.class_index or not class_options[State.class_index] then 
        State.class_index = 1 
    end
    State.class = class_options_to_class[class_options[State.class_index]].name
    buildSpecsDict(State.class_index)

    if not State.spec_index or not spec_options[State.spec_index] then 
        State.spec_index = 1 
    end
    State.spec = spec_options_to_spec[spec_options[State.spec_index]]

    if not State.phase_index or not Bistooltip_phases[State.phase_index] then 
        State.phase_index = 1 
    end
    State.phase = Bistooltip_phases[State.phase_index]
end

-- ============================================================
-- Draw Dropdowns
-- ============================================================

local function drawDropdowns()
    local dropDownGroup = NewSimpleGroup()

    dropDownGroup:SetLayout("Table")
    dropDownGroup:SetUserData("table", {
        columns = {
            Constants.UI.CLASS_DROPDOWN_WIDTH, 
            Constants.UI.SPEC_DROPDOWN_WIDTH, 
            Constants.UI.PHASE_DROPDOWN_WIDTH,
            80,  -- Lock Phase checkbox
            90,  -- Customize checkbox
            35,  -- Reset button (smaller)
        },
        space = 1,
        align = "BOTTOMRIGHT"
    })
    main_frame:AddChild(dropDownGroup)

    classDropdown = AceGUI:Create("Dropdown")
    specDropdown = AceGUI:Create("Dropdown")
    phaseDropDown = AceGUI:Create("Dropdown")
    specDropdown:SetDisabled(true)

    phaseDropDown:SetCallback("OnValueChanged", function(_, _, key)
        -- If phase is locked, prevent changing
        if blockedPhase then
            -- Find the index of blocked phase and revert
            for i, p in ipairs(Bistooltip_phases) do
                if p == blockedPhase then
                    phaseDropDown:SetValue(i)
                    State.phase_index = i
                    State.phase = blockedPhase
                    return
                end
            end
        end
        State.phase_index = key
        State.phase = Bistooltip_phases[key]
        drawSpecData()
    end)

    specDropdown:SetCallback("OnValueChanged", function(_, _, key)
        State.spec_index = key
        State.spec = spec_options_to_spec[spec_options[key]]
        drawSpecData()
    end)

    classDropdown:SetCallback("OnValueChanged", function(_, _, key)
        State.class_index = key
        State.class = class_options_to_class[class_options[key]].name

        specDropdown:SetDisabled(false)
        buildSpecsDict(key)
        specDropdown:SetList(spec_options)
        specDropdown:SetValue(1)
        State.spec_index = 1
        State.spec = spec_options_to_spec[spec_options[1]]
        drawSpecData()
    end)

    classDropdown:SetList(class_options)
    phaseDropDown:SetList(Bistooltip_phases)

    dropDownGroup:AddChild(classDropdown)
    dropDownGroup:AddChild(specDropdown)
    dropDownGroup:AddChild(phaseDropDown)
    
    -- Lock Phase checkbox - locks tooltips to show only items up to this phase
    local lockPhaseCheck = AceGUI:Create("CheckBox")
    lockPhaseCheck:SetLabel("Lock")
    lockPhaseCheck:SetWidth(70)
    lockPhaseCheck:SetValue(blockedPhase ~= nil)
    lockPhaseCheck:SetCallback("OnValueChanged", function(_, _, val)
        if val then
            blockedPhase = State.phase
            blockedPhaseIndex = State.phase_index
            if BistooltipAddon.db and BistooltipAddon.db.char then
                BistooltipAddon.db.char.blocked_phase = blockedPhase
                BistooltipAddon.db.char.blocked_phase_index = blockedPhaseIndex
            end
        else
            blockedPhase = nil
            blockedPhaseIndex = nil
            if BistooltipAddon.db and BistooltipAddon.db.char then
                BistooltipAddon.db.char.blocked_phase = nil
                BistooltipAddon.db.char.blocked_phase_index = nil
            end
        end
        -- Refresh tooltips will use new blockedPhase value
    end)
    lockPhaseCheck:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
        if blockedPhase then
            GameTooltip:SetText("|cff00ff00Phase Locked: " .. blockedPhase .. "|r\nTooltips will only show items from this phase and earlier.\nUncheck to show all phases.")
        else
            GameTooltip:SetText("Lock current phase for tooltips.\nWhen locked, tooltips will only show BIS info\nfor this phase and earlier phases.")
        end
        GameTooltip:Show()
    end)
    lockPhaseCheck:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    dropDownGroup:AddChild(lockPhaseCheck)
    
    -- Customize checkbox (only works in standard mode, not BIS checklist)
    local customizeCheck = AceGUI:Create("CheckBox")
    customizeCheck:SetLabel("Customize")
    customizeCheck:SetWidth(85)
    customizeCheck:SetValue(customizeMode and true or false)
    customizeCheck:SetDisabled(bisChecklistMode)  -- Disabled in BIS checklist mode
    customizeCheck:SetCallback("OnValueChanged", function(_, _, val)
        customizeMode = val and true or false
        
        -- Clear selection when toggling
        selectedSwapItem = nil
        
        if BistooltipAddon.db and BistooltipAddon.db.char then
            BistooltipAddon.db.char.customize_mode = customizeMode
        end
        -- Update reset button visibility
        if resetBtnRef then
            if customizeMode then
                resetBtnRef.frame:Show()
            else
                resetBtnRef.frame:Hide()
            end
        end
        ApplySpecTable()
        drawSpecData()
    end)
    dropDownGroup:AddChild(customizeCheck)
    customizeToggleRef = customizeCheck  -- Store reference for later
    
    -- Reset button for customization - only visible in customize mode
    local resetBtn = AceGUI:Create("Button")
    resetBtn:SetText("R")
    resetBtn:SetWidth(30)
    resetBtn:SetCallback("OnClick", function()
        if not customizeMode then return end
        -- Save scroll position
        if spec_frame and spec_frame.localstatus then
            savedScrollValue = spec_frame.localstatus.scrollvalue or 0
        end
        -- Use the new reset function
        ResetCustomPriorities()
        -- Clear unlocked slots and selection
        unlockedSlots = {}
        selectedSwapItem = nil
        drawSpecData()
    end)
    resetBtn:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
        GameTooltip:SetText("|cffff6666[R]eset|r\nRestores original item order\nfor current class/spec/phase")
        GameTooltip:Show()
    end)
    resetBtn:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    -- Hide if not in customize mode
    if not customizeMode then
        resetBtn.frame:Hide()
    end
    dropDownGroup:AddChild(resetBtn)
    resetBtnRef = resetBtn  -- Store reference

    local fillerFrame = AceGUI:Create("Label")
    fillerFrame:SetText(" ")
    main_frame:AddChild(fillerFrame)

    classDropdown:SetValue(State.class_index)
    if State.class_index then
        buildSpecsDict(State.class_index)
        specDropdown:SetList(spec_options)
        specDropdown:SetDisabled(false)
    end
    specDropdown:SetValue(State.spec_index)
    phaseDropDown:SetValue(State.phase_index)
end

-- ============================================================
-- Create Spec Frame
-- ============================================================

local function createSpecFrame()
    local frame = AceGUI:Create("ScrollFrame")
    frame:SetLayout("Table")
    -- Use same logic as ApplySpecTable
    local tableLayout
    if bisChecklistMode then
        -- BIS checklist mode - customize is disabled here
        tableLayout = SPEC_TABLE_CHECKLIST
    elseif customizeMode then
        -- Customize mode only works in standard mode
        tableLayout = SPEC_TABLE_CUSTOMIZE
    else
        tableLayout = SPEC_TABLE_DEFAULT
    end
    frame:SetUserData("table", tableLayout)
    frame:SetFullWidth(true)
    frame:SetHeight(Constants.UI.SPEC_FRAME_HEIGHT)
    frame:SetAutoAdjustHeight(false)
    main_frame:AddChild(frame)
    spec_frame = frame
end

-- ============================================================
-- Reload Data (Public API)
-- ============================================================

function BistooltipAddon:reloadData()
    buildClassDict()
    State.class_index = self.db.char.class_index
    State.spec_index = self.db.char.spec_index
    State.phase_index = self.db.char.phase_index

    if not State.class_index or not class_options[State.class_index] then 
        State.class_index = 1 
    end
    State.class = class_options_to_class[class_options[State.class_index]].name
    buildSpecsDict(State.class_index)
    
    if not State.spec_index or not spec_options[State.spec_index] then 
        State.spec_index = 1 
    end
    State.spec = spec_options_to_spec[spec_options[State.spec_index]]
    
    if not State.phase_index or not Bistooltip_phases[State.phase_index] then 
        State.phase_index = 1 
    end
    State.phase = Bistooltip_phases[State.phase_index]

    if main_frame then
        phaseDropDown:SetList(Bistooltip_phases)
        classDropdown:SetList(class_options)
        specDropdown:SetList(spec_options)

        classDropdown:SetValue(State.class_index)
        specDropdown:SetValue(State.spec_index)
        phaseDropDown:SetValue(State.phase_index)

        drawSpecData()
        main_frame:SetStatusText(Bistooltip_source_to_url[self.db.char.data_source])
    end

    -- Refresh owned-item cache
    if self.ScanEquipment then
        self:ScanEquipment(true)
    end
end

-- ============================================================
-- Discord Link Dialog
-- ============================================================

StaticPopupDialogs["BISTOOLTIP_DISCORD_LINK"] = {
    text = "Join our Discord\n|cffaaaaaa(Select and Ctrl+C to copy)|r",
    button1 = "OK",
    OnShow = function(self)
        local link = "https://discord.gg/3gPCPCxbmP"
        self.editBox:SetText(link)
        self.editBox.data = link
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 4,
    hasEditBox = true,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnTextChanged = function(self, userInput)
        if userInput and self.data then
            self:SetText(self.data)
            self:HighlightText()
        end
    end,
}

function BistooltipAddon:OpenDiscordLink()
    self:closeMainFrame()
    StaticPopup_Show("BISTOOLTIP_DISCORD_LINK")
end

-- ============================================================
-- Initialize BIS Lists
-- ============================================================

function BistooltipAddon:initBislists()
    buildClassDict()
    loadData()
    
    -- Register slash commands
    LibStub("AceConsole-3.0"):RegisterChatCommand("bistooltip", function(msg)
        msg = msg and msg:lower():trim() or ""
        
        if msg == "config" or msg == "options" or msg == "settings" then
            self:openConfigDialog()
        elseif msg == "reload" or msg == "refresh" then
            self:reloadData()
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip:|r Data reloaded.")
        elseif msg == "help" then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip Commands:|r")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bistooltip|r - Toggle BIS window")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bistooltip config|r - Open settings")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bistooltip reload|r - Reload data")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bis|r - Short alias for /bistooltip")
        else
            self:createMainFrame()
        end
    end)
    
    -- Short alias
    LibStub("AceConsole-3.0"):RegisterChatCommand("bis", function(msg)
        msg = msg and msg:lower():trim() or ""
        
        if msg == "config" or msg == "c" then
            self:openConfigDialog()
        elseif msg == "reload" or msg == "r" then
            self:reloadData()
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip:|r Data reloaded.")
        else
            self:createMainFrame()
        end
    end)
end

-- ============================================================
-- Create Main Frame
-- ============================================================

function BistooltipAddon:createMainFrame()
    -- Toggle behavior
    if main_frame then
        if main_frame.frame and not main_frame.frame:IsShown() then
            main_frame.frame:Show()
            if self.db and self.db.char and self.db.char.bis_checklist then
                UpdateChecklistPanel()
            end
            return
        end
        self:closeMainFrame()
        return
    end

    -- Restore UI modes from saved variables
    if self.db and self.db.char then
        if self.db.char.bis_checklist ~= nil then
            bisChecklistMode = self.db.char.bis_checklist and true or false
        end
        -- Load new settings
        if self.db.char.blocked_phase then
            blockedPhase = self.db.char.blocked_phase
        end
        if self.db.char.blocked_phase_index then
            blockedPhaseIndex = self.db.char.blocked_phase_index
        end
        if self.db.char.customize_mode ~= nil then
            -- Customize mode only works in standard mode, not BIS checklist
            if not bisChecklistMode then
                customizeMode = self.db.char.customize_mode and true or false
            else
                customizeMode = false
            end
        end
        if self.db.char.unlocked_slots then
            unlockedSlots = self.db.char.unlocked_slots
        end
        if self.db.char.custom_priorities then
            customPriorities = self.db.char.custom_priorities
        end
    end

    main_frame = AceGUI:Create("Frame")
    main_frame:SetWidth(Constants.UI.MAIN_FRAME_WIDTH)
    main_frame:SetHeight(Constants.UI.MAIN_FRAME_HEIGHT)

    main_frame.frame:SetMinResize(Constants.UI.MAIN_FRAME_MIN_WIDTH, Constants.UI.MAIN_FRAME_MIN_HEIGHT)
    main_frame.frame:SetMaxResize(Constants.UI.MAIN_FRAME_MAX_WIDTH, Constants.UI.MAIN_FRAME_MAX_HEIGHT)

    -- ESC to close
    mainFrameUISpecialName = main_frame.frame and main_frame.frame.GetName and main_frame.frame:GetName() or nil
    AddToUISpecialFrames(mainFrameUISpecialName)

    local statusFrame = nil

    main_frame:SetCallback("OnClose", function(widget)
        if statusFrame then
            statusFrame:SetScript("OnUpdate", nil)
            statusFrame = nil
        end
        
        -- Clear selection
        selectedSwapItem = nil
        -- Clear selection borders
        ClearAllSelectionBorders()

        CleanupMainFrame()
        AceGUI:Release(widget)
        main_frame = nil
    end)

    main_frame:SetLayout("List")
    main_frame:SetTitle(self.AddonNameAndVersion)
    local statusText = (self.AddonCredits or "") .. "  |  " .. (Bistooltip_source_to_url[self.db.char.data_source] or "wowtbc.gg/wotlk")
    main_frame:SetStatusText(statusText)

    drawDropdowns()
    createSpecFrame()

    -- Search + filters
    local searchGroup = NewSimpleGroup()
    searchGroup:SetFullWidth(true)
    searchGroup:SetLayout("Flow")

    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetLabel("Search")
    searchBox:SetWidth(Constants.UI.SEARCH_BOX_WIDTH)
    searchBox:SetCallback("OnTextChanged", function(_, _, txt)
        searchText = txt or ""
        searchTextLower = string.lower(searchText)
        drawSpecData()
    end)
    searchGroup:AddChild(searchBox)

    local missingToggle = AceGUI:Create("CheckBox")
    missingToggle:SetLabel("Only missing")
    missingToggle:SetWidth(Constants.UI.CHECKBOX_WIDTH)
    missingToggle:SetValue(showOnlyMissing and true or false)
    missingToggle:SetCallback("OnValueChanged", function(_, _, val)
        showOnlyMissing = val and true or false
        drawSpecData()
    end)
    searchGroup:AddChild(missingToggle)

    -- Forward declare emblemToggle so checklistToggle callback can reference it
    local emblemToggle

    local checklistToggle = AceGUI:Create("CheckBox")
    checklistToggle:SetLabel("BIS checklist")
    checklistToggle:SetWidth(Constants.UI.CHECKBOX_WIDTH)
    checklistToggle:SetValue(bisChecklistMode and true or false)
    checklistToggle:SetCallback("OnValueChanged", function(_, _, val)
        bisChecklistMode = val and true or false

        -- Persist
        if self.db and self.db.char then
            self.db.char.bis_checklist = bisChecklistMode
        end

        -- Enable/disable emblem toggle
        if emblemToggle then
            emblemToggle:SetDisabled(not bisChecklistMode)
            if not bisChecklistMode then
                emblemFilterMode = false
                emblemToggle:SetValue(false)
            end
        end
        
        -- Disable customize in BIS checklist mode
        if customizeToggleRef then
            customizeToggleRef:SetDisabled(bisChecklistMode)
            if bisChecklistMode and customizeMode then
                customizeMode = false
                customizeToggleRef:SetValue(false)
                selectedSwapItem = nil
            end
        end
        if resetBtnRef then
            if bisChecklistMode or not customizeMode then
                resetBtnRef.frame:Hide()
            else
                resetBtnRef.frame:Show()
            end
        end

        -- Mutual exclusion with "Only missing"
        if bisChecklistMode then
            showOnlyMissing = false
            missingToggle:SetValue(false)
            missingToggle:SetDisabled(true)
        else
            missingToggle:SetDisabled(false)
            DestroyChecklistPanel()
            emblemFilterMode = false
        end

        ApplySpecTable()
        drawSpecData()
    end)
    searchGroup:AddChild(checklistToggle)

    -- Emblem filter toggle (only enabled when checklist mode is on)
    emblemToggle = AceGUI:Create("CheckBox")
    emblemToggle:SetLabel("ASCEND")
    emblemToggle:SetWidth(80)
    emblemToggle:SetValue(emblemFilterMode and true or false)
    emblemToggle:SetDisabled(not bisChecklistMode)
    emblemToggle:SetCallback("OnValueChanged", function(_, _, val)
        emblemFilterMode = val and true or false
        drawSpecData()
    end)
    searchGroup:AddChild(emblemToggle)

    if bisChecklistMode then
        missingToggle:SetDisabled(true)
        missingToggle:SetValue(false)
        showOnlyMissing = false
        emblemToggle:SetDisabled(false)
    else
        emblemToggle:SetDisabled(true)
    end

    main_frame:AddChild(searchGroup)

    -- Checklist hint label row
    local checklistGroup = NewSimpleGroup()
    checklistGroup:SetFullWidth(true)
    checklistGroup:SetLayout("Flow")

    checklistSummaryLabel = AceGUI:Create("Label")
    checklistSummaryLabel:SetWidth(300)
    checklistSummaryLabel:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_SMALL, "")
    checklistSummaryLabel:SetText("")
    checklistGroup:AddChild(checklistSummaryLabel)

    -- Emblem summary label with icon (only visible in ASCEND mode)
    emblemSummaryLabel = AceGUI:Create("Label")
    emblemSummaryLabel:SetWidth(300)
    emblemSummaryLabel:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "OUTLINE")
    emblemSummaryLabel:SetText("")
    emblemSummaryLabel:SetJustifyH("CENTER")
    checklistGroup:AddChild(emblemSummaryLabel)

    main_frame:AddChild(checklistGroup)

    -- Buttons container
    local buttonContainer = NewSimpleGroup()
    buttonContainer:SetFullWidth(true)
    buttonContainer:SetLayout("Flow")

    local reloadButton = AceGUI:Create("Button")
    reloadButton:SetText("Reload Data")
    reloadButton:SetWidth(Constants.UI.BUTTON_WIDTH_MEDIUM)
    reloadButton:SetCallback("OnClick", function()
        self:reloadData()
    end)
    buttonContainer:AddChild(reloadButton)

    local discordButton = AceGUI:Create("Button")
    discordButton:SetText("Join our Discord")
    discordButton:SetWidth(Constants.UI.BUTTON_WIDTH_LARGE)
    discordButton:SetCallback("OnClick", function()
        self:OpenDiscordLink()
    end)
    buttonContainer:AddChild(discordButton)

    local noteLabel = AceGUI:Create("Label")
    noteLabel:SetText("")
    noteLabel:SetWidth(250)
    noteLabel:SetFont(GameFontNormal:GetFont(), Constants.FONTS.SIZE_TINY)

    local spacerLabel = AceGUI:Create("Label")
    spacerLabel:SetWidth(20)
    buttonContainer:AddChild(spacerLabel)
    buttonContainer:AddChild(noteLabel)

    noteLabel:SetHeight(reloadButton.frame:GetHeight())
    noteLabel:SetFullWidth(false)
    if noteLabel.label and noteLabel.label.SetPoint then
        noteLabel.label:SetPoint("BOTTOM")
    end

    local function UpdateStatusText()
        local ds = (_G.DataStore_Inventory and "ON") or "OFF"
        local q = #preloadQueue
        local s = "DataStore: " .. ds
        if q > 0 then
            s = s .. "  •  Loading: " .. q
        end
        if searchTextLower and searchTextLower ~= "" then
            s = s .. "  •  Filter: " .. searchText
        end
        noteLabel:SetText(s)
    end

    statusFrame = CreateFrame("Frame", nil, main_frame.frame)
    statusFrame:SetScript("OnUpdate", function()
        UpdateStatusText()
    end)

    local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
    spacer:SetText(" ")
    main_frame:AddChild(spacer)
    main_frame:AddChild(buttonContainer)

    -- Initial draw
    drawSpecData()
end

-- ============================================================
-- Close Main Frame
-- ============================================================

function BistooltipAddon:closeMainFrame()
    if main_frame then
        CleanupMainFrame()
        AceGUI:Release(main_frame)
        main_frame = nil
        classDropdown = nil
        specDropdown = nil
        phaseDropDown = nil
    end
end
