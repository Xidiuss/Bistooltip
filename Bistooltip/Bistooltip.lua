-- ============================================================
-- Bistooltip.lua - Tooltip enhancement for BIS item information
-- ============================================================

local eventFrame = CreateFrame("Frame", nil, UIParent)

-- Import utilities
local Utils = BistooltipUtils
local Constants = BistooltipConstants

-- ============================================================
-- Local Utility Functions (using Utils module)
-- ============================================================

local ColorizeByClass = Utils.ColorizeByClass
local ColorizeClassName = Utils.ColorizeClassName
local GetPhaseWeight = Constants.GetPhaseWeight
local NormalizeClassFileToken = Utils.NormalizeClassFileToken
local GetClassFileFromDatasetName = Utils.GetClassFileFromDatasetName
local TableContains = Utils.TableContains
local CaseInsensitivePairs = Utils.CaseInsensitivePairs

-- ============================================================
-- Spec Detection Configuration (from Constants)
-- ============================================================

local SPEC_BY_CLASSFILE_TAB = Constants.SPEC_BY_CLASSFILE_TAB

-- ============================================================
-- Local Helper Functions
-- ============================================================

local function ParseBestRankFromPhases(phasesText)
    if not phasesText or phasesText == "" then return nil end
    local s = tostring(phasesText)
    if s:find("BIS") then
        return { kind = "BIS" }
    end
    local bestAlt
    for n in s:gmatch("alt%s*(%d+)") do
        n = tonumber(n)
        if n and (not bestAlt or n < bestAlt) then bestAlt = n end
    end
    if bestAlt then
        return { kind = "ALT", n = bestAlt }
    end
    return { kind = "FOUND" }
end

-- Parse "T8 BIS / T9 alt 2" => phaseStats + bestPhase label for bestRank
local function ParsePhaseStatsFromString(phasesText)
    local bisCount, bestAlt = 0, nil
    local earliestBisW, earliestAnyW = 999, 999
    local bestRankKind, bestRankN = nil, nil
    local bestRankPhase, bestRankPhaseW = nil, 999

    if type(phasesText) ~= "string" or phasesText == "" then
        return 0, nil, 999, 999, nil
    end

    for token in phasesText:gmatch("([^/]+)") do
        local s = token:gsub("^%s+", ""):gsub("%s+$", "")
        local phase = s:match("^([^%s]+)") or s
        local w = GetPhaseWeight(phase)
        if w < earliestAnyW then earliestAnyW = w end

        local isBis = s:find("BIS") ~= nil
        local altN = s:match("alt%s*(%d+)")
        altN = altN and tonumber(altN) or nil

        if isBis then
            bisCount = bisCount + 1
            if w < earliestBisW then earliestBisW = w end
            if bestRankKind ~= "BIS" or w < bestRankPhaseW then
                bestRankKind, bestRankN = "BIS", nil
                bestRankPhase, bestRankPhaseW = phase, w
            end
        elseif altN then
            if not bestAlt or altN < bestAlt then bestAlt = altN end
            if bestRankKind ~= "BIS" then
                if (bestRankKind ~= "ALT") or (not bestRankN) or (altN < bestRankN) or (altN == bestRankN and w < bestRankPhaseW) then
                    bestRankKind, bestRankN = "ALT", altN
                    bestRankPhase, bestRankPhaseW = phase, w
                end
            end
        end
    end

    return bisCount, bestAlt, earliestBisW, earliestAnyW, bestRankPhase
end

-- Compact SHIFT entry: Class (colored) + spec icon + [T#]
local function FormatShiftEntry(e)
    local classColored = ColorizeByClass(e.class, e.class)
    local iconString = e.icon and string.format("|T%s:14|t", e.icon) or ""

    -- Build phase range like [PR-RS] or [T8-T9]
    local phases = {}
    if type(e.phases) == "string" and e.phases ~= "" then
        for token in e.phases:gmatch("([^/]+)") do
            local s = token:gsub("^%s+", ""):gsub("%s+$", "")
            local phase = s:match("^([^%s]+)")
            if phase then
                phases[phase] = true
            end
        end
    end
    local ordered = {}
    for phase in pairs(phases) do
        table.insert(ordered, phase)
    end
    table.sort(ordered, function(a, b)
        local wa, wb = GetPhaseWeight(a), GetPhaseWeight(b)
        if wa ~= wb then return wa < wb end
        return tostring(a) < tostring(b)
    end)

    local phaseTag = ""
    if #ordered == 1 then
        phaseTag = "|cffaaaaaa[" .. ordered[1] .. "]|r"
    elseif #ordered > 1 then
        phaseTag = "|cffaaaaaa[" .. ordered[1] .. "-" .. ordered[#ordered] .. "]|r"
    end

    return string.format("%s%s%s%s",
        classColored,
        iconString ~= "" and (" " .. iconString) or "",
        phaseTag ~= "" and " " or "",
        phaseTag
    )
end

-- For "Your specialization" header we want a clearer status
local function RankTagForSelf(rank)
    if not rank then
        return "|cffff3b3bNO BIS|r"
    end
    if rank.kind == "BIS" then
        return "|cff00ff00BIS|r"
    end
    if rank.kind == "BIS2" then
        return "|cff009900BIS²|r"
    end
    if rank.kind == "ALT" then
        return string.format("|cffffa500[ALT %d]|r", rank.n or 0)
    end
    return "|cffff3b3bNO BIS|r"
end

-- Robust points extraction across API variations
local function ExtractTalentPoints(...)
    local best
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "number" and v >= 0 and v <= 71 then
            if not best or v > best then best = v end
        end
    end
    return best
end

-- Promote ALT2 to BIS2 for dual-slot items (rings/trinkets) and Fury DW weapons
local function NormalizeDualSlotRank(itemId, className, specName, rank)
    if not rank or rank.kind ~= "ALT" or tonumber(rank.n) ~= 2 then
        return rank
    end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
    if equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_TRINKET" then
        return { kind = "BIS2" }
    end
    if tostring(className) == "Warrior" and tostring(specName) == "Fury" then
        if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND" then
            return { kind = "BIS2" }
        end
    end
    return rank
end

-- Display helper: in dual-slot contexts, treat ALT2 as BIS² in the phase string
-- Also applies tier combining for consecutive BIS phases
local function FormatPhasesString(itemId, className, specName, phasesStr)
    if not phasesStr then return phasesStr end
    
    -- First apply tier combining
    if Constants and Constants.CombineBISPhases then
        phasesStr = Constants.CombineBISPhases(phasesStr)
    end
    
    -- If already processed by CombineBISPhases, it will have color codes
    if phasesStr:find("|cff00ff00BIS") then
        return phasesStr
    end
    
    if phasesStr:find("BIS") then return phasesStr end
    
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
    local isDual = (equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_TRINKET")
    if not isDual and tostring(className) == "Warrior" and tostring(specName) == "Fury" then
        if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND" then
            isDual = true
        end
    end
    if not isDual then return phasesStr end

    local bis2Token = "|cff009900BIS²|r"
    local out = phasesStr:gsub("[Aa][Ll][Tt]%s*2%f[%D]", bis2Token)
    return out
end

local function RankTag(rank)
    if not rank then return "|cffff3b3bNO BIS|r" end
    if rank.kind == "BIS" then return "|cff00ff00BIS|r" end
    if rank.kind == "BIS2" then return "|cff009900BIS²|r" end
    if rank.kind == "ALT" then return string.format("|cffffa500ALT %d|r", rank.n or 0) end
    return "|cffffff00FOUND|r"
end

local function GetPlayerClassSpecKeys()
    local _, classFile = UnitClass("player")
    if not classFile then return nil end
    
    local classKey = Utils.CLASSFILE_TO_DATASET[classFile] or UnitClass("player")
    
    -- Active talent group (dual spec)
    local group = 1
    if type(_G.GetActiveTalentGroup) == "function" then
        local ok, g = pcall(_G.GetActiveTalentGroup, false, false)
        if not ok then ok, g = pcall(_G.GetActiveTalentGroup) end
        if ok and type(g) == "number" and g >= 1 then group = g end
    end
    
    local bestTab, bestPts = 1, -1
    local tabs = _G.GetNumTalentTabs and _G.GetNumTalentTabs(false, false) or 3
    
    for tab = 1, tabs do
        local points
        do
            local ok, r1, r2, r3, r4, r5, r6, r7, r8 = pcall(_G.GetTalentTabInfo, tab, false, false, group)
            if ok then
                points = ExtractTalentPoints(r1, r2, r3, r4, r5, r6, r7, r8)
            end
            if points == nil then
                local ok2, a1, a2, a3, a4, a5, a6, a7, a8 = pcall(_G.GetTalentTabInfo, tab, false, false)
                if ok2 then points = ExtractTalentPoints(a1, a2, a3, a4, a5, a6, a7, a8) end
            end
        end
        if points and points > bestPts then
            bestPts, bestTab = points, tab
        end
    end

    -- Druid edge: tab 2 can be cat or bear
    local specName = (SPEC_BY_CLASSFILE_TAB[classFile] and SPEC_BY_CLASSFILE_TAB[classFile][bestTab]) or nil
    if classFile == "DRUID" and bestTab == 2 then
        local form = GetShapeshiftForm and GetShapeshiftForm() or 0
        if form == 1 then specName = "Feral tank"
        elseif form == 3 then specName = "Feral dps"
        else specName = "Feral tank" end
    end
    if classFile == "DEATHKNIGHT" and bestTab == 1 then
        specName = "Blood tank"
    end
    
    return classKey, specName
end

local function specHighlighted(class_name, spec_name)
    if not BistooltipAddon or not BistooltipAddon.db or not BistooltipAddon.db.char then
        return false
    end
    local hs = BistooltipAddon.db.char.highlight_spec
    return hs and hs.spec_name == spec_name and hs.class_name == class_name
end

local function specFiltered(class_name, spec_name)
    if specHighlighted(class_name, spec_name) then
        return false
    end
    if BistooltipAddon and BistooltipAddon.db and BistooltipAddon.db.char then
        local fs = BistooltipAddon.db.char.filter_specs
        if fs and fs[class_name] then
            return not fs[class_name][spec_name]
        end
    end
    return false
end

local function classNamesFiltered()
    if BistooltipAddon and BistooltipAddon.db and BistooltipAddon.db.char then
        return BistooltipAddon.db.char.filter_class_names
    end
    return false
end

local function getFilteredItem(item)
    local filtered_item = {}
    for ki, spec in ipairs(item) do
        local class_name = spec.class_name
        local spec_name = spec.spec_name
        if not specFiltered(class_name, spec_name) then
            table.insert(filtered_item, spec)
        end
    end
    return filtered_item
end

local function printSpecLine(tooltip, slot, class_name, spec_name)
    local slot_name = slot.name
    local slot_ranks = slot.ranks
    local prefix = classNamesFiltered() and "" or "   "
    
    -- Safe icon lookup
    local icon = Utils.GetSpecIcon(class_name, spec_name)
    local left_text = prefix
    if icon then
        left_text = left_text .. "|T" .. icon .. ":14|t "
    end
    left_text = left_text .. ColorizeByClass(class_name, spec_name)
    
    if slot_name == "Off hand" or slot_name == "Weapon" or slot_name == "Weapon 1h" or slot_name == "Weapon 2h" then
        left_text = left_text .. " (" .. slot_name .. ")"
    end
    tooltip:AddDoubleLine(left_text, slot_ranks)
end

local function printClassName(tooltip, class_name)
    tooltip:AddLine(ColorizeByClass(class_name, class_name))
end

-- Search function for BIS lists
-- Now respects blocked phase - only shows items from phases up to and including blocked phase
function searchIDInBislistsClassSpec(structure, id, class, spec, filterByBlockedPhase)
    local paths = {}
    local seen = {}
    
    -- Get blocked phase from saved variables
    local blockedPhase = nil
    local blockedPhaseIndex = nil
    if filterByBlockedPhase and BistooltipAddon and BistooltipAddon.db and BistooltipAddon.db.char then
        blockedPhase = BistooltipAddon.db.char.blocked_phase
        blockedPhaseIndex = BistooltipAddon.db.char.blocked_phase_index
    end

    -- Sort phases according to Bistooltip_wowtbc_phases order
    local sortedPhases = {}
    if Bistooltip_wowtbc_phases then
        for phaseIdx, phase in ipairs(Bistooltip_wowtbc_phases) do
            -- If phase is blocked, only include phases up to and including blocked phase
            if blockedPhaseIndex then
                if phaseIdx > blockedPhaseIndex then
                    break  -- Skip phases after blocked phase
                end
            end
            if structure and structure[class] and structure[class][spec] and structure[class][spec][phase] then
                table.insert(sortedPhases, phase)
            end
        end
    end

    for _, phase in ipairs(sortedPhases) do
        local items = structure[class][spec][phase]

        for index, itemData in pairs(items) do
            if type(itemData) == "table" and itemData[1] then
                for i, itemId in ipairs(itemData) do
                    if i ~= "slot_name" and i ~= "enhs" and itemId == id then
                        local phaseLabel
                        if i == 1 then
                            phaseLabel = phase .. " BIS"
                        else
                            phaseLabel = phase .. " alt " .. i
                        end

                        if not seen[phaseLabel] then
                            table.insert(paths, phaseLabel)
                            seen[phaseLabel] = true
                        end
                    end
                end
            end
        end
    end

    if #paths > 0 then
        return table.concat(paths, " / ")
    else
        return nil
    end
end

-- ============================================================
-- New source model (O(1) ItemAcquisition -> SourceRegistry)
-- ============================================================

-- Public API used by Bislist: returns instance, boss
-- O(1) shim over the new model: first acquisition entry -> registry facts.
-- Signature unchanged; all existing call sites keep working untouched.
function BistooltipAddon:GetItemSourceInfo(itemId)
  if not itemId then return nil, nil end
  local entries = (BisTooltip_ItemAcquisition or {})[itemId]
  local e = entries and entries[1] or nil
  if not e then return nil, nil end
  if e.kind == "DROP" or e.kind == "TOKEN" or e.kind == "MARK" then
    local s = (BisTooltip_SourceRegistry or {})[e.source]
    if s then
      if s.difficulty and s.difficulty ~= "" then
        return s.instance .. " [" .. s.difficulty .. "]", s.boss
      end
      return s.instance, s.boss
    end
  end
  return nil, nil
end

local function GetItemSource(itemId)
    if not (BistooltipAddon and BistooltipAddon.GetItemSourceInfo) then
        return nil
    end
    local zone, boss = BistooltipAddon:GetItemSourceInfo(itemId)
    if zone and boss then
        return "|cFFFFFFFFSource:|r |cFF00FF00[" .. tostring(zone) .. "] - " .. tostring(boss) .. "|r"
    end
    return nil
end

-- Owned-item helper (cache from Core.lua)
local function GetOwnedInfo(itemId)
    if not itemId then return 0, 0 end
    local t = _G.Bistooltip_char_equipment
    if not t then return 0, 0 end
    local row = t[itemId]
    if not row then return 0, 0 end
    return row.bags or 0, row.equipped or 0
end

-- ============================================================
-- Tooltip source lines (new model: one line per acquisition entry)
-- ============================================================

local function GetAllItemSources(itemId)
    local lines = {}
    if not itemId or itemId <= 0 then return lines end
    local entries = (BisTooltip_ItemAcquisition or {})[itemId]
    if type(entries) ~= "table" then return lines end
    local fmt = BisTooltip_FormatSource
    if type(fmt) ~= "function" then return lines end

    -- Multi-source items keep every line; dedup ONLY byte-identical
    -- rendered lines (Saurfang vs Putricide stay separate).
    local seen = {}
    for _, e in ipairs(entries) do
        local line = fmt(e)
        if line and not seen[line] then
            seen[line] = true
            table.insert(lines, line)
        end
    end

    return lines
end

-- ============================================================
-- Tooltip Refresh with Cooldown
-- ============================================================

local lastRefreshTime = 0
local REFRESH_COOLDOWN = 0.1

local function RefreshAnyTooltip(tt)
    if not tt or not tt.GetItem then return end
    
    local now = GetTime()
    if now - lastRefreshTime < REFRESH_COOLDOWN then return end
    
    if BistooltipAddon._refreshing then return end
    
    local _, link = tt:GetItem()
    if not link then return end
    
    lastRefreshTime = now
    BistooltipAddon._refreshing = true
    tt:ClearLines()
    tt:SetHyperlink(link)
    BistooltipAddon._refreshing = false
end

-- ============================================================
-- Horde/Alliance Item ID Normalization for BIS Lookup
-- BIS lists store Horde IDs. On cross-faction or Alliance clients,
-- equipped items may have Alliance IDs that need reverse mapping.
-- ============================================================

local aliToHordeLookup = nil

local function GetBisCanonicalID(itemId)
    if not itemId or not _G.Bistooltip_horde_to_ali then return itemId end
    if not aliToHordeLookup then
        aliToHordeLookup = {}
        for hordeId, aliId in pairs(_G.Bistooltip_horde_to_ali) do
            aliToHordeLookup[aliId] = hordeId
        end
    end
    return aliToHordeLookup[itemId] or itemId
end

-- ============================================================
-- Main Tooltip Handler
-- ============================================================

local function OnGameTooltipSetItem(tooltip)
    local shiftMode = IsShiftKeyDown() and true or false
    local ctrlDown = IsControlKeyDown() and true or false

    local _, link = tooltip:GetItem()
    if not link then return end

    local _, itemIdStr = strsplit(":", link)
    local itemId = tonumber(itemIdStr)
    if not itemId then return end

    -- Normalize to canonical BIS list ID (Horde version)
    -- BIS lists store Horde IDs; cross-faction/Alliance items need reverse mapping
    local bisItemId = GetBisCanonicalID(itemId)

    -- Check if BIS data is loaded
    if not Bistooltip_bislists or not Bistooltip_spec_icons then
        return
    end
    
    -- Check tooltip_with_ctrl option - if enabled, only show BIS info when CTRL is held
    local tooltipWithCtrl = BistooltipAddon and BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.tooltip_with_ctrl
    if tooltipWithCtrl and not ctrlDown then
        return  -- Don't show BIS info unless CTRL is held
    end

    -- Your specialization section (only for rare+ equippable items)
    local showSpec = false
    do
        local _, _, quality, _, _, _, _, _, equipLoc = GetItemInfo(link)
        if quality and quality >= 3 then
            if type(_G.IsEquippableItem) == "function" then
                local ok, eq = pcall(_G.IsEquippableItem, link)
                if ok and eq then showSpec = true end
            else
                if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP" then
                    showSpec = true
                end
            end
        end
    end

    -- Store player class/spec for later filtering
    local playerClass, playerSpec = nil, nil
    
    if showSpec then
        local pClass, pSpec = GetPlayerClassSpecKeys()
        playerClass, playerSpec = pClass, pSpec  -- Save for later
        
        if pClass and pSpec then
            tooltip:AddLine(" ", 1, 1, 0)
            tooltip:AddLine("Your Class:", 1, 1, 1)

            local foundPhases = searchIDInBislistsClassSpec(Bistooltip_bislists, bisItemId, pClass, pSpec, true)
            local icon = Utils.GetSpecIcon(pClass, pSpec)
            
            -- Build spec text with optional highlighting
            local specText = ColorizeByClass(pClass, pClass) .. " - " .. ColorizeByClass(pClass, tostring(pSpec))
            
            -- Check if player's spec is highlighted
            local isPlayerSpecHighlighted = specHighlighted(pClass, pSpec)
            if isPlayerSpecHighlighted then
                specText = "|cff00ff00>>|r " .. specText .. " |cff00ff00<<|r"
            end
            
            local left = (icon and string.format("|T%s:16|t ", icon) or "") .. specText

            if foundPhases then
                local rank = NormalizeDualSlotRank(itemId, pClass, pSpec, ParseBestRankFromPhases(foundPhases))
                tooltip:AddDoubleLine(left, RankTagForSelf(rank), 1, 1, 1, 1, 1, 1)
                
                -- Check if we should hide Rank: line
                -- Hide if: BIS until last phase OR BIS with Lock enabled
                local hideRankLine = false
                local blockedPhase = BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.blocked_phase
                
                -- Check if it's BIS in the last phase (T10 or RS, or blocked phase if locked)
                local lastPhase = blockedPhase or "T10"  -- If locked, use blocked phase as "last"
                local isBisInLastPhase = foundPhases:find(lastPhase .. " BIS") ~= nil
                
                -- If it's purely BIS (no ALT phases), check if it spans to last phase
                local hasAltPhases = foundPhases:find("alt") ~= nil
                if not hasAltPhases and rank and rank.kind == "BIS" then
                    -- It's BIS - check if it goes until the last available phase
                    if blockedPhase then
                        -- Locked mode - hide if BIS
                        hideRankLine = true
                    elseif isBisInLastPhase then
                        -- BIS until last phase - hide
                        hideRankLine = true
                    end
                end
                
                if not hideRankLine then
                    tooltip:AddDoubleLine("Rank:", tostring(FormatPhasesString(itemId, pClass, pSpec, foundPhases)), 1, 1, 1, 1, 1, 0)
                end
            else
                tooltip:AddDoubleLine(left, "|cffff3b3bNO BIS|r", 1, 1, 1, 1, 1, 1)
            end
            tooltip:AddLine(" ", 1, 1, 0)
        end
    end

    -- Collect all matching entries (apply spec filtering here)
    local anyFound = false
    local entries = {}
    local classOrder = _G.Bistooltip_classes_indexes or {}

    for class, specs in CaseInsensitivePairs(Bistooltip_spec_icons) do
        for spec, icon in pairs(specs) do
            if spec ~= "classIcon" then
                -- Skip player's own spec (already shown in "Your specialization")
                local isPlayerSpec = (class == playerClass and spec == playerSpec)
                
                -- Apply spec filtering - skip filtered specs AND player's spec
                if not specFiltered(class, spec) and not isPlayerSpec then
                    local foundPhases = searchIDInBislistsClassSpec(Bistooltip_bislists, bisItemId, class, spec, true)
                    if foundPhases then
                        anyFound = true
                        local rank = ParseBestRankFromPhases(foundPhases)
                        local bisCount, bestAlt, earliestBisW, earliestAnyW, bestPhase = ParsePhaseStatsFromString(foundPhases)
                        
                        -- Check if this spec is highlighted
                        local isHighlighted = specHighlighted(class, spec)

                        table.insert(entries, {
                            class = class,
                            spec = spec,
                            icon = icon,
                            phases = foundPhases,
                            rank = rank,
                            bisCount = bisCount,
                            bestAlt = bestAlt,
                            earliestBisW = earliestBisW,
                            earliestAnyW = earliestAnyW,
                            bestPhase = bestPhase,
                            classIdx = tonumber(classOrder[class]) or 999,
                            isHighlighted = isHighlighted,
                        })
                    end
                end
            end
        end
    end

    -- Helper: rank allowlist for CTRL focus mode (only when tooltip_with_ctrl is OFF)
    local function isFocusRank(r)
        if not r then return false end
        if r.kind == "BIS" or r.kind == "BIS2" then return true end
        if r.kind == "ALT" then
            local n = tonumber(r.n) or 99
            return n <= 2
        end
        return false
    end

    -- Hint line removed per user request

    -- SHIFT summary (compact)
    if shiftMode and #entries > 0 then
        tooltip:AddLine(" ", 1, 1, 0)
        tooltip:AddLine("Summary (SHIFT):", 1, 1, 1)

        local groupedBis, groupedBis2, groupedNo = {}, {}, {}
        local altGroups = {}

        for i = 1, #entries do
            local e = entries[i]
            local r = NormalizeDualSlotRank(itemId, e.class, e.spec, e.rank)
            e._normRank = r

            if r and r.kind == "BIS" then
                table.insert(groupedBis, e)
            elseif r and r.kind == "BIS2" then
                table.insert(groupedBis2, e)
            elseif r and r.kind == "ALT" and r.n then
                local n = tonumber(r.n) or 99
                altGroups[n] = altGroups[n] or {}
                table.insert(altGroups[n], e)
            else
                table.insert(groupedNo, e)
            end
        end

        local function entrySort(a, b)
            if a.classIdx ~= b.classIdx then return a.classIdx < b.classIdx end
            if a.class ~= b.class then return tostring(a.class) < tostring(b.class) end
            return tostring(a.spec) < tostring(b.spec)
        end
        table.sort(groupedBis, entrySort)
        table.sort(groupedBis2, entrySort)
        table.sort(groupedNo, entrySort)
        for n, list in pairs(altGroups) do
            table.sort(list, entrySort)
        end

        local function addWrapped(label, list, sep)
            if #list == 0 then return end
            sep = sep or " / "
            local maxPerLine = 3
            local idx = 1
            local indent = string.rep(" ", 6)
            local first = true
            while idx <= #list do
                local chunk = {}
                for j = 1, maxPerLine do
                    local e = list[idx]
                    if not e then break end
                    chunk[#chunk + 1] = FormatShiftEntry(e)
                    idx = idx + 1
                end
                if #chunk > 0 then
                    if first then
                        tooltip:AddLine(label .. table.concat(chunk, sep))
                        first = false
                    else
                        tooltip:AddLine(indent .. table.concat(chunk, sep))
                    end
                end
            end
        end

        addWrapped("  |cff00ff00BIS:|r ", groupedBis, " / ")
        addWrapped("  |cff009900BIS²:|r ", groupedBis2, " / ")

        local alts = {}
        for n in pairs(altGroups) do table.insert(alts, n) end
        table.sort(alts)
        for _, n in ipairs(alts) do
            addWrapped(string.format("  |cffffa500ALT%d:|r ", n), altGroups[n], " > ")
        end

        addWrapped("  |cffff3b3bNO BIS:|r ", groupedNo, " / ")
        return true
    end

    -- Default view: full list (sorted) / CTRL focus view (filtered, only when tooltip_with_ctrl is OFF)
    local focusMode = (not shiftMode) and ctrlDown and not tooltipWithCtrl

    -- Rank ordering: BIS > BIS2 > ALT1 > ALT2 ... > NO BIS
    local function RankWeight(r)
        if not r then return 999 end
        if r.kind == "BIS" then return 0 end
        if r.kind == "BIS2" then return 1 end
        if r.kind == "ALT" then return 10 + (tonumber(r.n) or 99) end
        return 900
    end

    local buckets = {}
    local classes = {}

    for i = 1, #entries do
        local e = entries[i]
        e._normRank = NormalizeDualSlotRank(itemId, e.class, e.spec, e.rank)
        if (not focusMode) or isFocusRank(e._normRank) then
            local c = e.class
            local b = buckets[c]
            if not b then
                b = {
                    class = c,
                    classIdx = e.classIdx or 999,
                    bestW = 999,
                    bestPhaseW = 999,
                    entries = {},
                }
                buckets[c] = b
                table.insert(classes, b)
            end

            local w = RankWeight(e._normRank)
            local pW = GetPhaseWeight(e.bestPhase)
            if (w < b.bestW) or (w == b.bestW and pW < b.bestPhaseW) then
                b.bestW = w
                b.bestPhaseW = pW
            end

            table.insert(b.entries, e)
        end
    end

    -- Sort classes by best rank, then by earliest phase, then by natural class order
    -- Also prioritize classes with highlighted specs
    table.sort(classes, function(a, b)
        -- Check if any entry is highlighted
        local aHighlighted, bHighlighted = false, false
        for _, e in ipairs(a.entries) do if e.isHighlighted then aHighlighted = true break end end
        for _, e in ipairs(b.entries) do if e.isHighlighted then bHighlighted = true break end end
        if aHighlighted ~= bHighlighted then return aHighlighted end
        
        if a.bestW ~= b.bestW then return a.bestW < b.bestW end
        if a.bestPhaseW ~= b.bestPhaseW then return a.bestPhaseW < b.bestPhaseW end
        if a.classIdx ~= b.classIdx then return a.classIdx < b.classIdx end
        return tostring(a.class) < tostring(b.class)
    end)

    -- Sort specs inside each class by rank, then phase, then name
    -- Highlighted specs come first
    local function specSort(a, b)
        if a.isHighlighted ~= b.isHighlighted then return a.isHighlighted end
        local wa, wb = RankWeight(a._normRank), RankWeight(b._normRank)
        if wa ~= wb then return wa < wb end
        local pa, pb = GetPhaseWeight(a.bestPhase), GetPhaseWeight(b.bestPhase)
        if pa ~= pb then return pa < pb end
        return tostring(a.spec) < tostring(b.spec)
    end
    for i = 1, #classes do
        table.sort(classes[i].entries, specSort)
    end

    if focusMode and #classes > 0 then
        tooltip:AddLine("|cffaaaaaaFocus mode: BIS / BIS² / ALT1 / ALT2|r")
    end
    
    -- Check if class names should be hidden
    local hideClassNames = classNamesFiltered()

    for i = 1, #classes do
        local b = classes[i]
        -- Only show class name if not filtered
        if not hideClassNames then
            tooltip:AddLine(ColorizeByClass(b.class, b.class))
        end
        for j = 1, #b.entries do
            local e = b.entries[j]
            local iconString = e.icon and string.format("|T%s:14|t ", e.icon) or ""
            -- If class names hidden, no indent; otherwise indent
            local indent = hideClassNames and "" or "   "
            local specText = ColorizeByClass(b.class, e.spec)
            -- Highlight spec with special formatting if it's highlighted
            if e.isHighlighted then
                specText = "|cff00ff00>>|r " .. specText .. " |cff00ff00<<|r"
            end
            local leftText = indent .. iconString .. specText
            tooltip:AddDoubleLine(leftText, FormatPhasesString(itemId, e.class, e.spec, e.phases), 1, 1, 1, 1, 1, 0)
        end
    end

    -- Item source (controlled by show_item_source setting)
    if BistooltipAddon.db.char.show_item_source then
        local sourceLines = GetAllItemSources(itemId)

        if sourceLines and #sourceLines > 0 then
            tooltip:AddLine(" ", 1, 1, 0)
            tooltip:AddLine("|cFFFFFFFFSource:|r", 1, 1, 1)
            for _, line in ipairs(sourceLines) do
                tooltip:AddLine("  |cFF00FF00" .. line .. "|r", 1, 1, 1)
            end
            tooltip:AddLine(" ", 1, 1, 0)
        end
    end
end

-- ============================================================
-- Initialization
-- ============================================================

function BistooltipAddon:initBisTooltip()
    eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, _, e_key)
        if e_key ~= "RCTRL" and e_key ~= "LCTRL" and e_key ~= "RSHIFT" and e_key ~= "LSHIFT" then
            return
        end
        if GameTooltip and GameTooltip:IsShown() then
            RefreshAnyTooltip(GameTooltip)
        end
        if ItemRefTooltip and ItemRefTooltip:IsShown() then
            RefreshAnyTooltip(ItemRefTooltip)
        end
    end)

    GameTooltip:HookScript("OnTooltipSetItem", OnGameTooltipSetItem)
    ItemRefTooltip:HookScript("OnTooltipSetItem", OnGameTooltipSetItem)
end

-- Cleanup function for addon disable (prevents memory leaks)
function BistooltipAddon:cleanupBisTooltip()
    eventFrame:UnregisterEvent("MODIFIER_STATE_CHANGED")
    eventFrame:SetScript("OnEvent", nil)
end
