-- ============================================================
-- DataProvider.lua - Data Layer for BisTooltip
-- Handles all data access, filtering, and transformation
-- ============================================================

local ADDON_NAME = "Bis-Tooltip"

-- Create namespace
BistooltipData = BistooltipData or {}

local Utils = BistooltipUtils
local Constants = BistooltipConstants

-- ============================================================
-- Cache Management
-- ============================================================

local DataCache = {
    filteredSlots = nil,
    filteredSlotsKey = nil,
    allSlotsForProgress = nil,
    emblemTotals = nil,
    emblemTotalsKey = nil,
    sourceCache = {},
    itemInfoCache = {},
}

function BistooltipData.ClearCache()
    DataCache.filteredSlots = nil
    DataCache.filteredSlotsKey = nil
    DataCache.allSlotsForProgress = nil
    DataCache.emblemTotals = nil
    DataCache.emblemTotalsKey = nil
    -- Don't clear sourceCache or itemInfoCache as they're expensive to rebuild
end

function BistooltipData.ClearAllCaches()
    DataCache.filteredSlots = nil
    DataCache.filteredSlotsKey = nil
    DataCache.allSlotsForProgress = nil
    DataCache.emblemTotals = nil
    DataCache.emblemTotalsKey = nil
    DataCache.sourceCache = {}
    DataCache.itemInfoCache = {}
end

-- ============================================================
-- Cached GetItemInfo - Reduces API calls during rendering
-- ============================================================

function BistooltipData.CachedGetItemInfo(itemId)
    if not itemId or itemId <= 0 then return nil end

    -- Check cache first
    local cached = DataCache.itemInfoCache[itemId]
    if cached then
        -- Cache hit - return cached values
        if cached.name then
            return cached.name, cached.link, cached.quality, cached.ilvl,
                   cached.minLevel, cached.itemType, cached.subType, cached.stackCount,
                   cached.equipLoc, cached.texture, cached.sellPrice
        else
            -- Item was queried but not available - return nil but don't re-query too often
            if cached.queryTime and (GetTime() - cached.queryTime) < 5 then
                return nil
            end
        end
    end

    -- Cache miss - call API
    local name, link, quality, ilvl, minLevel, itemType, subType, stackCount, equipLoc, texture, sellPrice = GetItemInfo(itemId)

    -- Store in cache
    if name then
        DataCache.itemInfoCache[itemId] = {
            name = name,
            link = link,
            quality = quality,
            ilvl = ilvl,
            minLevel = minLevel,
            itemType = itemType,
            subType = subType,
            stackCount = stackCount,
            equipLoc = equipLoc,
            texture = texture,
            sellPrice = sellPrice,
        }
    else
        -- Item not in cache yet - mark as queried to prevent spam
        DataCache.itemInfoCache[itemId] = {
            queryTime = GetTime(),
        }
    end

    return name, link, quality, ilvl, minLevel, itemType, subType, stackCount, equipLoc, texture, sellPrice
end

-- Quick texture lookup (commonly used during rendering)
function BistooltipData.GetItemTexture(itemId)
    if not itemId or itemId <= 0 then return nil end

    local cached = DataCache.itemInfoCache[itemId]
    if cached and cached.texture then
        return cached.texture
    end

    -- Try full lookup which will populate cache
    local _, _, _, _, _, _, _, _, _, texture = BistooltipData.CachedGetItemInfo(itemId)
    return texture
end

-- Quick name lookup
function BistooltipData.GetItemName(itemId)
    if not itemId or itemId <= 0 then return nil end

    local cached = DataCache.itemInfoCache[itemId]
    if cached and cached.name then
        return cached.name
    end

    local name = BistooltipData.CachedGetItemInfo(itemId)
    return name
end

-- Get item info as table (useful for multiple values)
function BistooltipData.GetCachedItemData(itemId)
    if not itemId or itemId <= 0 then return nil end

    -- Ensure cache is populated
    BistooltipData.CachedGetItemInfo(itemId)

    return DataCache.itemInfoCache[itemId]
end

-- Invalidate single item (e.g., after ITEM_DATA_LOAD_RESULT event)
function BistooltipData.InvalidateItemCache(itemId)
    if itemId then
        DataCache.itemInfoCache[itemId] = nil
    end
end

-- Get cache stats (for debugging)
function BistooltipData.GetItemCacheStats()
    local count = 0
    local withData = 0
    for id, data in pairs(DataCache.itemInfoCache) do
        count = count + 1
        if data.name then
            withData = withData + 1
        end
    end
    return count, withData
end

-- ============================================================
-- Equipment Cache Access
-- ============================================================

-- Reverse of the historically named table: Horde ID -> Alliance ID.
local hordeToAliCache = nil

local function GetHordeToAliMapping()
    if hordeToAliCache then return hordeToAliCache end

    hordeToAliCache = {}
    if _G.Bistooltip_horde_to_ali then
        for allianceId, hordeId in pairs(_G.Bistooltip_horde_to_ali) do
            hordeToAliCache[hordeId] = allianceId
        end
    end
    return hordeToAliCache
end

function BistooltipData.GetOwnedRow(itemId)
    local t = _G.Bistooltip_char_equipment
    if not t or not itemId then return nil end

    -- Direct lookup
    if t[itemId] then return t[itemId] end

    -- Handle Horde<->Alliance translation using cached reverse mapping
    if _G.Bistooltip_horde_to_ali then
        -- Check whether a Horde item has its Alliance equivalent in inventory.
        local allianceId = GetHordeToAliMapping()[itemId]
        if allianceId and t[allianceId] then return t[allianceId] end

        -- Check whether an Alliance item has its Horde equivalent in inventory.
        local hordeId = _G.Bistooltip_horde_to_ali[itemId]
        if hordeId and t[hordeId] then return t[hordeId] end
    end

    return nil
end

function BistooltipData.GetOwnedCount(itemId)
    local row = BistooltipData.GetOwnedRow(itemId)
    if not row then return 0 end
    return (row.bags or 0) + (row.equipped or 0)
end

function BistooltipData.GetOwnedState(itemId)
    local row = BistooltipData.GetOwnedRow(itemId)
    if not row then return nil, 0 end
    
    local bags = row.bags or 0
    local equipped = row.equipped or 0
    
    if equipped > 0 then
        return "equipped", equipped
    elseif bags > 0 then
        return "bags", bags
    end
    return nil, 0
end

-- ============================================================
-- Item ID Normalization (Horde->Alliance)
-- ============================================================

-- Local alias for Utils function (avoid breaking existing code)
local NormalizeItemID = Utils.NormalizeItemID

function BistooltipData.GetDisplayItemID(originalItemId, isHorde)
    if not originalItemId or originalItemId <= 0 then return nil end

    -- Despite its historical name, this table maps Alliance IDs to Horde
    -- IDs. Most baseline slots contain Alliance IDs; WoWSims Horde overrides
    -- already contain Horde IDs. Accept either form without flipping sides.
    if _G.Bistooltip_horde_to_ali then
        if isHorde then
            return _G.Bistooltip_horde_to_ali[originalItemId] or originalItemId
        end
        return GetHordeToAliMapping()[originalItemId] or originalItemId
    end

    return originalItemId
end

-- ============================================================
-- Dual Slot Detection (Rings/Trinkets)
-- ============================================================

function BistooltipData.IsDualSlot(slot, itemId)
    -- Virtual slots (Ring 1, Ring 2, Trinket 1, Trinket 2) are NOT dual slots
    -- They represent a single item each
    if slot and slot._isVirtual then
        return false
    end

    -- Check by item equip location
    if itemId then
        local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
        if equipLoc == "INVTYPE_TRINKET" or equipLoc == "INVTYPE_FINGER" then
            return true
        end
    end

    -- Check by slot name - only original Finger/Trinket slots are dual
    local slotName = slot and (slot.slot_name or slot.name)
    if slotName then
        local lower = tostring(slotName):lower()
        -- Only exact match for "trinket" or "finger", not "ring 1", "trinket 2", etc.
        if lower == "trinket" or lower == "finger" then
            return true
        end
    end

    return false
end

-- ============================================================
-- BIS Slot Completion Detection
-- ============================================================

function BistooltipData.GetRequiredBISItems(slot)
    local required = {}
    local firstItem = NormalizeItemID(slot and slot[1])
    
    if not firstItem then return required end
    table.insert(required, firstItem)
    
    -- For dual slots, need second BIS item
    if BistooltipData.IsDualSlot(slot, firstItem) then
        local secondItem = NormalizeItemID(slot and slot[2])
        
        if secondItem and secondItem ~= firstItem then
            table.insert(required, secondItem)
        else
            -- Find first different item
            for i = 2, math.min(#slot, 6) do
                local candidate = NormalizeItemID(slot[i])
                if candidate and candidate ~= firstItem then
                    table.insert(required, candidate)
                    break
                end
            end
        end
    end
    
    return required
end

function BistooltipData.IsSlotBISCompleted(slot)
    local required = BistooltipData.GetRequiredBISItems(slot)
    if #required == 0 then return false end
    
    if #required == 1 then
        return BistooltipData.GetOwnedCount(required[1]) >= 1
    end
    
    -- For two required items
    if required[1] == required[2] then
        return BistooltipData.GetOwnedCount(required[1]) >= 1
    end
    
    return BistooltipData.GetOwnedCount(required[1]) >= 1 and
           BistooltipData.GetOwnedCount(required[2]) >= 1
end

-- ============================================================
-- Source Information
-- ============================================================

-- Item sources from the new model (O(1) acquisition -> registry facts).
-- Each acquisition entry renders via BisTooltip_FormatSource; multi-source
-- items keep every line, deduped ONLY on byte-identical rendered lines
-- (Saurfang vs Putricide stay separate). Returned structs preserve the
-- legacy {type,zone,boss,difficulty,currency,cost} shape so existing UI
-- call sites (BislistUI, UIFramework, BuildChecklistGroups) keep working
-- untouched; the rendered MASTER line rides along as .text.
function BistooltipData.GetAllItemSources(itemId)
    if not itemId or itemId <= 0 then return {} end

    local entries = (BisTooltip_ItemAcquisition or {})[itemId]
    if type(entries) ~= "table" then return {} end
    local reg = BisTooltip_SourceRegistry or {}
    local fmt = BisTooltip_FormatSource
    if type(fmt) ~= "function" then return {} end

    local sources = {}
    local seen = {}

    for _, e in ipairs(entries) do
        if type(e) == "table" then
            local line = fmt(e)
            if line and not seen[line] then
                seen[line] = true
                local displayLine = fmt(e, BistooltipData.GetItemTexture) or line
                local src = nil
                if e.kind == "DROP" or e.kind == "TOKEN" or e.kind == "MARK" then
                    local s = e.source and reg[e.source] or nil
                    if s and s.kind == "CUSTOM" then
                        src = { type = "custom", label = s.label, text = displayLine }
                    elseif s then
                        local zone = s.instance
                        if s.difficulty and s.difficulty ~= "" then
                            zone = zone .. " [" .. s.difficulty .. "]"
                        end
                        src = {
                            type = "raid",
                            zone = zone,
                            boss = s.boss,
                            difficulty = s.difficulty,
                            tier = e.tier, -- optional ex-Tier-zone stamp (R5-A), nil otherwise
                            text = displayLine,
                        }
                    end
                elseif e.kind == "VENDOR" then
                    local currency, amount = nil, nil
                    for _, c in ipairs(e.cost or {}) do
                        if c.currency and not currency then
                            currency, amount = c.currency, c.amount
                        end
                    end
                    src = {
                        type = "emblem",
                        currency = currency or "Emblems",
                        cost = amount,
                        text = displayLine,
                    }
                elseif e.kind == "CUSTOM" then
                    src = {
                        type = "custom",
                        label = e.label,
                        text = displayLine,
                    }
                elseif e.kind == "ACTIVITY" then
                    src = {
                        type = "activity",
                        label = e.label,
                        text = displayLine,
                    }
                end
                -- Entries with unknown sourceIDs render to nil and are
                -- skipped here (dev warning is drained once in Core.lua).
                if src then
                    table.insert(sources, src)
                end
            end
        end
    end

    return sources
end

-- W1 cutover: both emblem helpers read the new source model
-- (ItemAcquisition VENDOR entries) via the pure lookup in
-- SourceFormatter.lua. Bistooltip_emblem_items / Constants.EMBLEM_ITEMS
-- are no longer consulted at runtime (single source of truth).
function BistooltipData.HasEmblemSource(itemId)
    if not itemId or itemId <= 0 then return false end
    local _, currency = BisTooltip_GetVendorCost(itemId)
    return currency ~= nil
end

function BistooltipData.GetEmblemCost(itemId)
    if not itemId or itemId <= 0 then return nil, nil end
    return BisTooltip_GetVendorCost(itemId)
end

-- Vendor eligibility is a property of the method, not of its first currency.
-- Only a single one-part price is safe to add to a group budget. Alternatives
-- and compound prices remain visible in full through the source formatter.
function BistooltipData.GetVendorSummary(itemId)
    local purchases = {}
    for _, entry in ipairs((BisTooltip_ItemAcquisition or {})[itemId] or {}) do
        if entry.kind == "VENDOR" or entry.kind == "CUSTOM" then
            purchases[#purchases + 1] = entry
        end
    end
    if #purchases == 0 then return nil end
    if #purchases > 1 then return "Vendor options", nil, true end
    local entry = purchases[1]
    if entry.kind == "CUSTOM" then return entry.label or "Custom", nil, true end
    local costs = entry.cost or {}
    if #costs == 0 then return "Free / unspecified price", nil, true end
    if #costs > 1 then return "Multiple costs", nil, true end
    local cost = costs[1]
    return cost.currency or ("Item #" .. tostring(cost.item)), cost.amount, false
end

-- NOTE: difficulty is a closed fact set on SourceRegistry entries (spec S2);
-- the old difficulty-substring guessing heuristic was removed with the O(N)
-- lookup (Task 5). Difficulty now travels on GetAllItemSources structs.

-- ============================================================
-- Slot Data Access
-- ============================================================

local function CopyEnhancements(enhancements)
    local copy = {}
    for index, entry in ipairs(enhancements or {}) do
        copy[index] = {type = entry.type, id = entry.id}
    end
    return copy
end

function BistooltipData.GetSlotsForSpec(className, specName, phase)
    if not _G.Bistooltip_bislists then return nil end
    if not className or not specName or not phase then return nil end

    local classData = _G.Bistooltip_bislists[className]
    if not classData then return nil end

    local specData = classData[specName]
    if not specData then return nil end

    local list = specData[phase]
    if type(list) ~= "table" then return nil end

    -- Defensive copy per read (row-duplication hunt, owner report): some
    -- in-session code path overwrites EXISTING array entries (invisible to
    -- __newindex traps), duplicating Weapon/Off hand rows within ~2s of a
    -- fresh bind. Returning a fresh array per call starves that mutator —
    -- every draw reads the bound source untouched. Slot tables stay shared
    -- (personal rank order and plugin rank overrides persist).
    local professionSet
    local allowProfessionRules = false
    if type(_G.BistooltipPlayerContext) == "table"
            and type(_G.BistooltipPlayerContext.GetPlayerClassKey) == "function"
            and _G.BistooltipPlayerContext.GetPlayerClassKey() == className then
        allowProfessionRules = true
        if type(_G.BistooltipPlayerContext.GetProfessionSkillLines) == "function" then
            professionSet = _G.BistooltipPlayerContext.GetProfessionSkillLines()
        end
    end

    local copy = {}
    for i, slot in ipairs(list) do
        -- Consumers filter, split rings/trinkets and calculate progress before
        -- rendering, so the personal order must already be applied here.
        BistooltipData.LoadCustomPriority(slot, className, specName, phase)
        local automatic
        if type(_G.BisTooltip) == "table"
                and type(_G.BisTooltip.ResolveEnhancementOverride) == "function" then
            automatic = _G.BisTooltip:ResolveEnhancementOverride(
                className, specName, phase, slot.slot_name,
                professionSet, allowProfessionRules)
        end
        if automatic then
            local view = {}
            for key, value in pairs(slot) do view[key] = value end
            local enhs = CopyEnhancements(slot.enhs)
            enhs[1] = {type = automatic.type, id = automatic.id}
            view.enhs = enhs
            copy[i] = view
        else
            copy[i] = slot
        end
    end
    return copy
end

-- ============================================================
-- Filtering Functions
-- ============================================================

-- Helper to create a virtual slot with specific items (for splitting Finger/Trinket in BIS mode)
local function CreateVirtualSlot(originalSlot, newSlotName, itemIndex)
    local virtualSlot = {
        slot_name = newSlotName,
        enhs = originalSlot.enhs,  -- Share enhancements
        _isVirtual = true,
        _originalSlotName = originalSlot.slot_name,
        _itemIndex = itemIndex,
    }
    -- Copy the item at specified index as the primary item
    local itemId = originalSlot[itemIndex]
    if itemId and itemId > 0 then
        virtualSlot[1] = itemId
    else
        -- Fallback to first valid item if specified index is empty
        for i = 1, 6 do
            if originalSlot[i] and originalSlot[i] > 0 then
                virtualSlot[1] = originalSlot[i]
                break
            end
        end
    end
    return virtualSlot
end

function BistooltipData.FilterSlots(slots, searchText, showOnlyMissing, vendorFilterMode, isHorde, bisMode)
    if not slots then return {}, {} end

    -- Ensure searchText is a string (handle nil/empty properly)
    local searchLower = ""
    if searchText and type(searchText) == "string" and searchText ~= "" then
        searchLower = string.lower(searchText)
    end

    local filtered = {}
    local allForProgress = {}

    for _, slot in ipairs(slots) do
        -- ALWAYS split Finger and Trinket into separate rows for progress counting
        -- Progress bar should count ALL items regardless of filters and mode
        -- This ensures Ring 1, Ring 2, Trinket 1, Trinket 2 are all counted
        if slot.slot_name == "Finger" then
            local ring1 = CreateVirtualSlot(slot, "Ring 1", 1)
            local ring2 = CreateVirtualSlot(slot, "Ring 2", 2)
            table.insert(allForProgress, ring1)
            table.insert(allForProgress, ring2)
        elseif slot.slot_name == "Trinket" then
            local trinket1 = CreateVirtualSlot(slot, "Trinket 1", 1)
            local trinket2 = CreateVirtualSlot(slot, "Trinket 2", 2)
            table.insert(allForProgress, trinket1)
            table.insert(allForProgress, trinket2)
        else
            table.insert(allForProgress, slot)
        end

        -- Check if slot matches search filter
        local matches = BistooltipData.SlotMatchesFilter(slot, searchLower, isHorde)

        -- Check if slot passes the vendor filter (VENDOR mode; true when off)
        local hasVendor = BistooltipData.SlotHasVendorSource(slot, vendorFilterMode, isHorde)

        if matches and hasVendor then
            -- In BIS mode, split Finger and Trinket into separate rows
            if vendorFilterMode then
                -- Keep all ranks for the per-item vendor filter, including
                -- purchasable rings/trinkets below the two BIS positions.
                table.insert(filtered, slot)
            elseif bisMode and slot.slot_name == "Finger" then
                -- Create Ring 1 (item [1]) and Ring 2 (item [2])
                local ring1 = CreateVirtualSlot(slot, "Ring 1", 1)
                local ring2 = CreateVirtualSlot(slot, "Ring 2", 2)

                -- In BIS mode, always filter to show only missing items
                if not BistooltipData.IsSlotBISCompleted(ring1) then
                    table.insert(filtered, ring1)
                end
                if not BistooltipData.IsSlotBISCompleted(ring2) then
                    table.insert(filtered, ring2)
                end
            elseif bisMode and slot.slot_name == "Trinket" then
                -- Create Trinket 1 (item [1]) and Trinket 2 (item [2])
                local trinket1 = CreateVirtualSlot(slot, "Trinket 1", 1)
                local trinket2 = CreateVirtualSlot(slot, "Trinket 2", 2)

                -- In BIS mode, always filter to show only missing items
                if not BistooltipData.IsSlotBISCompleted(trinket1) then
                    table.insert(filtered, trinket1)
                end
                if not BistooltipData.IsSlotBISCompleted(trinket2) then
                    table.insert(filtered, trinket2)
                end
            else
                -- Normal slot handling
                local isCompleted = BistooltipData.IsSlotBISCompleted(slot)

                -- In BIS mode, always show only missing items
                -- In MAIN mode, use showOnlyMissing setting
                if bisMode then
                    if not isCompleted then
                        table.insert(filtered, slot)
                    end
                else
                    if not (showOnlyMissing and isCompleted) then
                        table.insert(filtered, slot)
                    end
                end
            end
        end
    end

    return filtered, allForProgress
end

function BistooltipData.SlotMatchesFilter(slot, searchLower, isHorde)
    if not searchLower or searchLower == "" then return true end

    -- Match slot name (pre-lowercase slot names for performance)
    if slot.slot_name then
        local slotNameLower = slot._slot_name_lower
        if not slotNameLower then
            slotNameLower = string.lower(slot.slot_name)
            slot._slot_name_lower = slotNameLower  -- Cache on slot
        end
        if string.find(slotNameLower, searchLower, 1, true) then
            return true
        end
    end

    -- Match item IDs or names (use cached item info)
    for _, iid in ipairs(slot) do
        local id = BistooltipData.GetDisplayItemID(iid, isHorde)

        -- Check numeric ID match
        local idStr = tostring(id)
        if idStr == searchLower then
            return true
        end

        -- Use cached GetItemInfo for name lookup
        local name = BistooltipData.GetItemName(id)
        if name then
            -- Cache lowercase name in item cache
            local cached = DataCache.itemInfoCache[id]
            if cached then
                if not cached.nameLower then
                    cached.nameLower = string.lower(name)
                end
                if string.find(cached.nameLower, searchLower, 1, true) then
                    return true
                end
            end
        end
    end

    return false
end

-- VENDOR is the purchasable subset of the required BiS choices, not every
-- lower-ranked alternative in the slot. Dual slots may require two items.
function BistooltipData.GetVendorBISItems(slot, isHorde)
    local items = {}
    for _, id in ipairs(BistooltipData.GetRequiredBISItems(slot)) do
        local displayID = BistooltipData.GetDisplayItemID(id, isHorde)
        if displayID and BistooltipData.GetVendorSummary(displayID) then
            items[#items + 1] = id
        end
    end
    return items
end

function BistooltipData.SlotHasVendorSource(slot, vendorFilterMode, isHorde)
    if not vendorFilterMode then return true end
    return #BistooltipData.GetVendorBISItems(slot, isHorde) > 0
end

-- ============================================================
-- Calculate Missing Emblems
-- ============================================================

function BistooltipData.CalculateMissingEmblems(className, specName, phase)
    -- Create cache key
    local cacheKey = string.format("%s_%s_%s", className or "", specName or "", phase or "")
    
    -- Check cache
    if DataCache.emblemTotalsKey == cacheKey and DataCache.emblemTotals then
        return DataCache.emblemTotals
    end
    
    local totals = {}
    local slots = BistooltipData.GetSlotsForSpec(className, specName, phase)
    
    if not slots then
        DataCache.emblemTotals = totals
        DataCache.emblemTotalsKey = cacheKey
        return totals
    end
    
    for _, slot in ipairs(slots) do
        local required = BistooltipData.GetRequiredBISItems(slot)
        
        for _, id in ipairs(required) do
            if id and id > 0 and BistooltipData.GetOwnedCount(id) < 1 then
                local cost, currency = BistooltipData.GetEmblemCost(id)
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
    
    -- Cache result
    DataCache.emblemTotals = totals
    DataCache.emblemTotalsKey = cacheKey
    
    return totals
end

-- ============================================================
-- Build Checklist Groups (by Boss/Zone)
-- ============================================================

function BistooltipData.BuildChecklistGroups(className, specName, phase, vendorFilterMode)
    local groups = {}         -- groups[zone][boss] = { items = {}, difficulty = "10HM" }
    local totalMissing = 0
    local emblemGroups = {}   -- emblemGroups[costKey] = { items = {}, total = 0, cost = X }
    
    local slots = BistooltipData.GetSlotsForSpec(className, specName, phase)
    if not slots then return groups, totalMissing, emblemGroups end
    
    for _, slot in ipairs(slots) do
        local required = BistooltipData.GetRequiredBISItems(slot)
        
        for _, id in ipairs(required) do
            if id and id > 0 and BistooltipData.GetOwnedCount(id) < 1 then
                totalMissing = totalMissing + 1

                local sources = BistooltipData.GetAllItemSources(id)

                for _, src in ipairs(sources) do
                    if src.type == "raid" then
                        -- Only add raid items if NOT in VENDOR mode
                        if not vendorFilterMode then
                            local zone = src.zone or "Unknown"
                            local boss = src.boss or "Unknown"

                            groups[zone] = groups[zone] or {}
                            groups[zone][boss] = groups[zone][boss] or { items = {}, difficulty = src.difficulty }

                            table.insert(groups[zone][boss].items, {
                                id = id,
                                slot = slot.slot_name or "",
                                sources = sources,
                            })
                        end
                    elseif src.type == "emblem" then
                        -- VENDOR mode: vendor items are the WHOLE point; normal
                        -- mode keeps them as emblem groups next to raid drops.
                        -- Grouped by currency (spec W5; replaces the old
                        -- Ascension-only substring grouping and its cost buckets).
                        local currency = src.currency or "Emblems"
                        local cost = src.cost or 0
                        local groupKey = currency

                        emblemGroups[groupKey] = emblemGroups[groupKey] or { items = {}, total = 0, cost = 0 }
                        emblemGroups[groupKey].total = emblemGroups[groupKey].total + cost

                        table.insert(emblemGroups[groupKey].items, {
                            id = id,
                            slot = slot.slot_name or "",
                            cost = cost,
                            sources = sources,
                        })
                    elseif src.type == "custom" and vendorFilterMode then
                        -- Plugin donate/custom shops: VENDOR mode only.
                        local groupKey = src.label or "Custom"
                        emblemGroups[groupKey] = emblemGroups[groupKey] or { items = {}, total = 0, cost = 0 }
                        table.insert(emblemGroups[groupKey].items, {
                            id = id,
                            slot = slot.slot_name or "",
                            cost = 0,
                            sources = sources,
                        })
                    elseif src.type == "activity" and not vendorFilterMode then
                        local label = src.label or "Other source"
                        groups[label] = groups[label] or {}
                        groups[label][label] = groups[label][label] or { items = {} }
                        table.insert(groups[label][label].items, {
                            id = id, slot = slot.slot_name or "", sources = sources,
                        })
                    end
                end
            end
        end
    end
    
    return groups, totalMissing, emblemGroups
end

-- ============================================================
-- Class/Spec Data Access
-- ============================================================

function BistooltipData.GetClassList()
    local classes = {}
    
    if _G.Bistooltip_classes and type(_G.Bistooltip_classes) == "table" then
        for i, class in ipairs(_G.Bistooltip_classes) do
            table.insert(classes, {
                index = i,
                name = class.name,
                specs = class.specs,
            })
        end
    elseif _G.Bistooltip_bislists then
        -- Fallback: build from bislists
        local ordered = {}
        for className in pairs(_G.Bistooltip_bislists) do
            table.insert(ordered, className)
        end
        table.sort(ordered)
        
        for i, name in ipairs(ordered) do
            table.insert(classes, {
                index = i,
                name = name,
                specs = BistooltipData.GetSpecsForClass(name),
            })
        end
    end
    
    return classes
end

function BistooltipData.GetSpecsForClass(className)
    local specs = {}
    
    if _G.Bistooltip_classes and type(_G.Bistooltip_classes) == "table" then
        for _, class in ipairs(_G.Bistooltip_classes) do
            if class.name == className and class.specs then
                for _, specName in ipairs(class.specs) do
                    table.insert(specs, specName)
                end
                return specs
            end
        end
    end
    
    -- Fallback: build from bislists
    if _G.Bistooltip_bislists and _G.Bistooltip_bislists[className] then
        for specName in pairs(_G.Bistooltip_bislists[className]) do
            table.insert(specs, specName)
        end
        table.sort(specs)
    end
    
    return specs
end

function BistooltipData.GetPhaseList()
    if _G.Bistooltip_phases then
        return _G.Bistooltip_phases
    end
    return { "PR", "T7", "T8", "T9", "T10", "RS" }
end

-- Note: GetSpecIcon moved to Utils.lua - use Utils.GetSpecIcon()

-- ============================================================
-- Custom Priority Management
-- ============================================================

local CustomPriorities = {}
local OriginalOrders = {}

function BistooltipData.GetCustomPriorityKey(className, specName, phase, slotName)
    return string.format("%s_%s_%s_%s", className or "Unknown", specName or "Unknown", phase or "Unknown", slotName or "Unknown")
end

function BistooltipData.LoadCustomPriority(slot, className, specName, phase)
    if not slot or not slot.slot_name then return end
    
    local key = BistooltipData.GetCustomPriorityKey(className, specName, phase, slot.slot_name)
    
    -- Store original order (only once)
    if not OriginalOrders[key] then
        local origOrder = {}
        for i, id in ipairs(slot) do
            if type(id) == "number" then
                origOrder[i] = id
            end
        end
        OriginalOrders[key] = origOrder
    end
    
    -- Load from memory
    local savedOrder = CustomPriorities[key]

    -- Try saved variables (account-wide since W4/§12)
    if not savedOrder and _G.BistooltipAddon and _G.BistooltipAddon.db
       and _G.BistooltipAddon.db.global
       and _G.BistooltipAddon.db.global.custom_priorities then
        savedOrder = _G.BistooltipAddon.db.global.custom_priorities[key]
        if savedOrder then
            CustomPriorities[key] = savedOrder
        end
    end
    
    -- Apply saved order
    if savedOrder and #savedOrder > 0 then
        local newOrder = {}
        local usedIndices = {}
        
        -- Add items in saved order
        for _, savedId in ipairs(savedOrder) do
            for i, slotId in ipairs(slot) do
                if slotId == savedId and not usedIndices[i] then
                    table.insert(newOrder, slotId)
                    usedIndices[i] = true
                    break
                end
            end
        end
        
        -- Add remaining items
        for i, slotId in ipairs(slot) do
            if not usedIndices[i] then
                table.insert(newOrder, slotId)
            end
        end
        
        -- Apply new order
        for i, id in ipairs(newOrder) do
            slot[i] = id
        end
    end
end

function BistooltipData.SaveCustomPriority(slot, className, specName, phase)
    if not slot or not slot.slot_name then return end
    
    local key = BistooltipData.GetCustomPriorityKey(className, specName, phase, slot.slot_name)
    
    local itemIds = {}
    for i, id in ipairs(slot) do
        itemIds[i] = id
    end
    
    CustomPriorities[key] = itemIds

    -- Persist to saved variables (account-wide since W4/§12)
    if _G.BistooltipAddon and _G.BistooltipAddon.db and _G.BistooltipAddon.db.global then
        local g = _G.BistooltipAddon.db.global
        g.custom_priorities = g.custom_priorities or {}
        g.custom_priorities[key] = itemIds
    end
end

-- W4: called on database switch — the cached orders belong to the
-- previously bound DB. Reads re-reconcile from db.global per slot via
-- LoadCustomPriority (ID-based, so personal order survives the switch).
function BistooltipData.ResetCustomPriorityCaches()
    CustomPriorities = {}
    OriginalOrders = {}
end

function BistooltipData.RestoreOriginalOrder(slot, className, specName, phase)    if not slot or not slot.slot_name then return end
    
    local key = BistooltipData.GetCustomPriorityKey(className, specName, phase, slot.slot_name)
    local origOrder = OriginalOrders[key]
    
    if origOrder and #origOrder > 0 then
        for i, id in ipairs(origOrder) do
            slot[i] = id
        end
    end
end

function BistooltipData.ResetCustomPriorities(className, specName, phase)
    local prefix = BistooltipData.GetCustomPriorityKey(className, specName, phase, "")
    
    -- Restore original orders
    -- Restore the bound base slots, not a derived enhancement view.
    local classData = _G.Bistooltip_bislists and _G.Bistooltip_bislists[className]
    local specData = classData and classData[specName]
    local slots = specData and specData[phase]
    if slots then
        for _, slot in ipairs(slots) do
            if slot.slot_name then
                BistooltipData.RestoreOriginalOrder(slot, className, specName, phase)
            end
        end
    end
    
    -- Clear custom priorities
    for key in pairs(CustomPriorities) do
        if key:find(prefix, 1, true) == 1 then
            CustomPriorities[key] = nil
        end
    end
    
    -- Clear original orders
    for key in pairs(OriginalOrders) do
        if key:find(prefix, 1, true) == 1 then
            OriginalOrders[key] = nil
        end
    end
    
    -- Clear from saved variables
    if _G.BistooltipAddon and _G.BistooltipAddon.db and _G.BistooltipAddon.db.global and
       _G.BistooltipAddon.db.global.custom_priorities then
        for key in pairs(_G.BistooltipAddon.db.global.custom_priorities) do
            if key:find(prefix, 1, true) == 1 then
                _G.BistooltipAddon.db.global.custom_priorities[key] = nil
            end
        end
    end
end

-- ============================================================
-- Progress Calculation
-- ============================================================

function BistooltipData.CalculateProgress(slots)
    if not slots then return 0, 0 end
    
    local total = 0
    local collected = 0
    
    for _, slot in ipairs(slots) do
        if slot[1] and slot[1] > 0 then
            total = total + 1
            if BistooltipData.IsSlotBISCompleted(slot) then
                collected = collected + 1
            end
        end
    end
    
    return collected, total
end
