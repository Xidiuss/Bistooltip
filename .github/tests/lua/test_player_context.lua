-- Run from the repository root with Lua 5.1. WoW character APIs are stubbed.
local failures = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then print("PASS " .. name) else
        failures = failures + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end

local state = {}
local function reset()
    state.className = "Druid"
    state.classFile = "DRUID"
    state.group = 1
    state.points = {0, 51, 20}
    state.talents = {}
    state.professions = {}
    state.professionInfo = {}
    state.skillLines = {}
    state.spellbook = {}
    state.form = 0
    state.weaponLink = nil
    state.weaponStats = nil
    Bistooltip_bislists = { Druid = {}, Shaman = { Enhancement = {} } }
end

BistooltipConstants = {
    SPEC_BY_CLASSFILE_TAB = {
        DRUID = {[1] = "Balance", [2] = "Feral tank", [3] = "Restoration"},
        SHAMAN = {[1] = "Elemental", [2] = "Enhancement", [3] = "Restoration"},
    },
}
BistooltipUtils = {
    CLASSFILE_TO_DATASET = { DRUID = "Druid", SHAMAN = "Shaman" },
}

UnitClass = function() return state.className, state.classFile end
GetActiveTalentGroup = function() return state.group end
GetNumTalentTabs = function() return 3 end
GetTalentTabInfo = function(tab)
    return "Tab " .. tab, nil, state.points[tab] or 0
end
GetTalentInfo = function(tab, index)
    local talent = state.talents[index]
    if tab ~= 2 or not talent then return nil end
    return talent.name, "icon", talent.tier or 1, talent.column or 1,
        talent.rank or 0, talent.maxRank or 3
end
GetSpellInfo = function(id)
    if id == 57873 then return "Lokalny Obrońca Stada" end
    if id == 33867 then return "Lokalny Instynkt Drapieżcy" end
    if id == 7411 then return "Lokalne Zaklinanie" end
    if id == 45357 then return "Lokalna Inskrypcja" end
end
GetShapeshiftForm = function() return state.form end
GetProfessions = function() return unpack(state.professions) end
GetProfessionInfo = function(index)
    local info = state.professionInfo[index]
    if not info then return nil end
    return info.name, "icon", 450, 450, 1, 0, info.skillLine
end
GetNumSkillLines = function() return #state.skillLines end
GetSkillLineInfo = function(index)
    local info = state.skillLines[index]
    if not info then return nil end
    return info.name, info.header or false, true, info.rank or 0, 0, 0, info.maxRank or 450
end
GetNumSpellTabs = function() return #state.spellbook > 0 and 1 or 0 end
GetSpellTabInfo = function(index)
    if index == 1 and #state.spellbook > 0 then
        return "Professions", "icon", 0, #state.spellbook
    end
end
GetSpellName = function(index)
    return state.spellbook[index]
end
GetInventoryItemLink = function(_, slot)
    if slot == 16 then return state.weaponLink end
end
GetItemStats = function(link)
    if link == state.weaponLink then return state.weaponStats end
end

reset()
dofile("Bistooltip/PlayerContext.lua")

test("active dual spec chooses the dominant tab from the active group", function()
    reset()
    state.className, state.classFile = "Shaman", "SHAMAN"
    state.group = 2
    state.points = {8, 52, 11}
    local className, specName = BistooltipPlayerContext.GetPlayerClassSpecKeys()
    assert(className == "Shaman" and specName == "Enhancement",
        "active group did not select Enhancement")
end)

test("profession detection returns stable IDs and a fresh set", function()
    reset()
    state.professions = {11, 22}
    state.professionInfo[11] = {name = "Localized Enchanting", skillLine = 333}
    state.professionInfo[22] = {name = "Localized Inscription", skillLine = 773}
    local first = BistooltipPlayerContext.GetProfessionSkillLines()
    assert(first[333] and first[773], "profession skill-line IDs missing")
    first[333] = nil
    local second = BistooltipPlayerContext.GetProfessionSkillLines()
    assert(second[333] and second[773], "profession result was reused between calls")
end)

test("WotLK 3.3.5 skill lines detect professions without Cataclysm APIs", function()
    reset()
    state.skillLines = {
        {name = "Lokalne Zaklinanie", rank = 450},
        {name = "Lokalna Inskrypcja", rank = 450},
    }
    local savedProfessions, savedProfessionInfo = GetProfessions, GetProfessionInfo
    GetProfessions, GetProfessionInfo = nil, nil
    local detected = BistooltipPlayerContext.GetProfessionSkillLines()
    GetProfessions, GetProfessionInfo = savedProfessions, savedProfessionInfo
    assert(detected[333] and detected[773],
        "3.3.5 skill lines did not produce Enchanting and Inscription IDs")
end)

test("WotLK 3.3.5 spellbook detects professions behind a collapsed skill header", function()
    reset()
    state.skillLines = {{name = "Profesje", header = true}}
    state.spellbook = {"Lokalne Zaklinanie", "Lokalna Inskrypcja"}
    local savedProfessions, savedProfessionInfo = GetProfessions, GetProfessionInfo
    GetProfessions, GetProfessionInfo = nil, nil
    local detected = BistooltipPlayerContext.GetProfessionSkillLines()
    GetProfessions, GetProfessionInfo = savedProfessions, savedProfessionInfo
    assert(detected[333] and detected[773],
        "collapsed 3.3.5 skill header hid spellbook professions")
end)

test("missing or truncated profession APIs produce an empty set", function()
    reset()
    state.professions = {11}
    state.professionInfo[11] = {name = "Incomplete"}
    assert(next(BistooltipPlayerContext.GetProfessionSkillLines()) == nil,
        "truncated profession tuple produced a key")
    local saved = GetProfessions
    GetProfessions = nil
    assert(next(BistooltipPlayerContext.GetProfessionSkillLines()) == nil,
        "missing profession API produced a key")
    GetProfessions = saved
end)

local function feralWith(protector, predatory, form)
    reset()
    state.form = form or 0
    if protector then
        state.talents[#state.talents + 1] = {name = GetSpellInfo(57873), rank = 3}
    end
    if predatory then
        state.talents[#state.talents + 1] = {name = GetSpellInfo(33867), rank = 3}
    end
    local _, specName = BistooltipPlayerContext.GetPlayerClassSpecKeys()
    return specName
end

test("Feral talent signals distinguish tank DPS and tank-favored hybrid", function()
    assert(feralWith(true, false) == "Feral tank", "Protector-only Feral was not tank")
    assert(feralWith(false, true) == "Feral dps", "Predatory-only Feral was not DPS")
    assert(feralWith(true, true) == "Feral tank", "hybrid Feral was not tank")
end)

test("Feral without either signal uses form then defaults to tank", function()
    assert(feralWith(false, false, 3) == "Feral dps", "Cat Form was not DPS fallback")
    assert(feralWith(false, false, 1) == "Feral tank", "Bear Form was not tank fallback")
    assert(feralWith(false, false, 0) == "Feral tank", "formless Feral did not default tank")
end)

local function shamanSpec(stats, withProfile)
    reset()
    state.className, state.classFile = "Shaman", "SHAMAN"
    state.points = {8, 52, 11}
    state.weaponLink = "item:900001"
    state.weaponStats = stats
    if withProfile then Bistooltip_bislists.Shaman.Spellhance = {} end
    local _, specName = BistooltipPlayerContext.GetPlayerClassSpecKeys()
    return specName
end

test("Enhancement main-hand spell stats select an available Spellhance profile", function()
    assert(shamanSpec({ITEM_MOD_SPELL_POWER_SHORT = 120}, true) == "Spellhance",
        "spell-power weapon did not select Spellhance")
    assert(shamanSpec({ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 80}, true) == "Spellhance",
        "spell-damage weapon did not select Spellhance")
end)

test("Enhancement falls back when weapon data or Spellhance profile is absent", function()
    assert(shamanSpec({ITEM_MOD_SPELL_POWER_SHORT = 120}, false) == "Enhancement",
        "missing profile still selected Spellhance")
    assert(shamanSpec(nil, true) == "Enhancement",
        "missing item stats did not fall back to Enhancement")
    assert(shamanSpec({ITEM_MOD_SPELL_POWER_SHORT = 0}, true) == "Enhancement",
        "zero spell power selected Spellhance")
end)

assert(failures == 0, tostring(failures) .. " player context regression(s)")
print("player_context: OK")
