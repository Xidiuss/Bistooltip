-- Bistooltip/PlayerContext.lua
-- Current-character facts shared by tooltip and enhancement recommendation code.
BistooltipPlayerContext = BistooltipPlayerContext or {}

local Context = BistooltipPlayerContext
local Constants = BistooltipConstants or {}
local Utils = BistooltipUtils or {}
local SPEC_BY_CLASSFILE_TAB = Constants.SPEC_BY_CLASSFILE_TAB or {}

local function ExtractTalentPoints(...)
    local best
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "number" and value >= 0 and value <= 71 then
            if not best or value > best then best = value end
        end
    end
    return best
end

local function ActiveTalentGroup()
    if type(_G.GetActiveTalentGroup) ~= "function" then return 1 end
    local ok, group = pcall(_G.GetActiveTalentGroup, false, false)
    if not ok then ok, group = pcall(_G.GetActiveTalentGroup) end
    if ok and type(group) == "number" and group >= 1 then return group end
    return 1
end

local function TalentPoints(tab, group)
    if type(_G.GetTalentTabInfo) ~= "function" then return nil end
    local ok, r1, r2, r3, r4, r5, r6, r7, r8 =
        pcall(_G.GetTalentTabInfo, tab, false, false, group)
    local points = ok and ExtractTalentPoints(r1, r2, r3, r4, r5, r6, r7, r8) or nil
    if points ~= nil then return points end
    ok, r1, r2, r3, r4, r5, r6, r7, r8 = pcall(_G.GetTalentTabInfo, tab, false, false)
    if ok then return ExtractTalentPoints(r1, r2, r3, r4, r5, r6, r7, r8) end
end

local function ActiveTalentTab(group)
    local tabCount = 3
    if type(_G.GetNumTalentTabs) == "function" then
        local ok, count = pcall(_G.GetNumTalentTabs, false, false)
        if ok and type(count) == "number" and count > 0 then tabCount = count end
    end
    local bestTab, bestPoints = 1, -1
    for tab = 1, tabCount do
        local points = TalentPoints(tab, group)
        if points and points > bestPoints then
            bestTab, bestPoints = tab, points
        end
    end
    return bestTab
end

local function TalentCount(tab)
    if type(_G.GetNumTalents) ~= "function" then return 60 end
    local ok, count = pcall(_G.GetNumTalents, tab, false, false)
    if ok and type(count) == "number" and count >= 0 then return count end
    return 60
end

local function HasActiveTalent(tab, group, wantedName)
    if not wantedName or type(_G.GetTalentInfo) ~= "function" then return false end
    for index = 1, TalentCount(tab) do
        local ok, name, _, _, _, rank = pcall(_G.GetTalentInfo, tab, index, false, false, group)
        if not ok then
            ok, name, _, _, _, rank = pcall(_G.GetTalentInfo, tab, index, false, false)
        end
        if ok and name == wantedName and type(rank) == "number" and rank > 0 then
            return true
        end
    end
    return false
end

local function FeralSpec(group)
    local protectorName = type(_G.GetSpellInfo) == "function" and _G.GetSpellInfo(57873) or nil
    local predatoryName = type(_G.GetSpellInfo) == "function" and _G.GetSpellInfo(33867) or nil
    local protector = HasActiveTalent(2, group, protectorName)
    local predatory = HasActiveTalent(2, group, predatoryName)
    if protector then return "Feral tank" end
    if predatory then return "Feral dps" end
    local form = type(_G.GetShapeshiftForm) == "function" and _G.GetShapeshiftForm() or 0
    if form == 3 then return "Feral dps" end
    return "Feral tank"
end

local function StatValue(stats, token)
    local value = stats and stats[token]
    if value == nil and type(_G[token]) == "string" then value = stats and stats[_G[token]] end
    return tonumber(value) or 0
end

local function HasSpellhanceProfile()
    local shaman = type(_G.Bistooltip_bislists) == "table" and _G.Bistooltip_bislists.Shaman
    return type(shaman) == "table" and type(shaman.Spellhance) == "table"
end

local function EnhancementSpec()
    if not HasSpellhanceProfile() then return "Enhancement" end
    if type(_G.GetInventoryItemLink) ~= "function" or type(_G.GetItemStats) ~= "function" then
        return "Enhancement"
    end
    local ok, link = pcall(_G.GetInventoryItemLink, "player", 16)
    if not ok or not link then return "Enhancement" end
    local target = {}
    local statsOk, stats = pcall(_G.GetItemStats, link, target)
    if not statsOk then return "Enhancement" end
    if type(stats) ~= "table" then stats = target end
    if StatValue(stats, "ITEM_MOD_SPELL_POWER_SHORT") > 0
            or StatValue(stats, "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT") > 0 then
        return "Spellhance"
    end
    return "Enhancement"
end

function Context.GetPlayerClassKey()
    if type(_G.UnitClass) ~= "function" then return nil end
    local className, classFile = _G.UnitClass("player")
    if not classFile then return nil end
    return (Utils.CLASSFILE_TO_DATASET or {})[classFile] or className
end

function Context.GetProfessionSkillLines()
    local result = {}
    if type(_G.GetProfessions) ~= "function" or type(_G.GetProfessionInfo) ~= "function" then
        return result
    end
    local ok, p1, p2, p3, p4 = pcall(_G.GetProfessions)
    if not ok then return result end
    local professions = {p1, p2, p3, p4}
    for index = 1, 4 do
        local profession = professions[index]
        if profession then
            local infoOk, _, _, _, _, _, _, skillLine = pcall(_G.GetProfessionInfo, profession)
            if infoOk and type(skillLine) == "number" and skillLine > 0 then
                result[skillLine] = true
            end
        end
    end
    return result
end

function Context.GetPlayerClassSpecKeys()
    if type(_G.UnitClass) ~= "function" then return nil end
    local className, classFile = _G.UnitClass("player")
    if not classFile then return nil end
    local classKey = (Utils.CLASSFILE_TO_DATASET or {})[classFile] or className
    local group = ActiveTalentGroup()
    local bestTab = ActiveTalentTab(group)
    local specName = SPEC_BY_CLASSFILE_TAB[classFile] and SPEC_BY_CLASSFILE_TAB[classFile][bestTab]
    if classFile == "DRUID" and bestTab == 2 then
        specName = FeralSpec(group)
    elseif classFile == "SHAMAN" and bestTab == 2 then
        specName = EnhancementSpec()
    elseif classFile == "DEATHKNIGHT" and bestTab == 1 then
        specName = "Blood tank"
    end
    return classKey, specName
end

return Context
