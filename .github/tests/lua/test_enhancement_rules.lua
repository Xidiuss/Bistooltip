-- Standalone contract test for WOTLK5 enhancement declarations.
-- Run from the WOTLK5 worktree with Lua 5.1.
local rules = {}
local acquisitionCalls = {}
local loaded = {}
DEFAULT_CHAT_FRAME = {AddMessage = function(_, message) loaded[#loaded + 1] = message end}

BisTooltip = {
    AddAcquisition = function(_, itemID)
        acquisitionCalls[itemID] = (acquisitionCalls[itemID] or 0) + 1
        return true
    end,
    SetAcquisition = function(_, itemID)
        acquisitionCalls[itemID] = (acquisitionCalls[itemID] or 0) + 1
        return true
    end,
    DefineEnhancementOverride = function(_, rule, plugin)
        rules[#rules + 1] = {rule = rule, plugin = plugin}
        return true
    end,
}

dofile("Bistooltip_WOTLK5_S2/main.lua")
assert(#loaded == 1 and loaded[1] == "WOTLK5_S2 loaded",
    "plugin did not emit exactly one successful load message")

local roleProfiles = {
    tank = {
        {"Death knight", "Blood tank"},
        {"Druid", "Feral tank"},
        {"Paladin", "Protection"},
        {"Warrior", "Protection"},
    },
    ap = {
        {"Death knight", "Frost"},
        {"Death knight", "Unholy"},
        {"Death knight", "Blood dps"},
        {"Druid", "Feral dps"},
        {"Hunter", "Beast mastery"},
        {"Hunter", "Marksmanship"},
        {"Hunter", "Survival"},
        {"Paladin", "Retribution"},
        {"Rogue", "Assassination"},
        {"Rogue", "Combat"},
        {"Shaman", "Enhancement"},
        {"Warrior", "Arms"},
        {"Warrior", "Fury"},
    },
    sp = {
        {"Druid", "Balance"},
        {"Mage", "Arcane"},
        {"Mage", "Fire"},
        {"Mage", "Fire FFB"},
        {"Mage", "Frost"},
        {"Priest", "Shadow"},
        {"Shaman", "Elemental"},
        {"Warlock", "Affliction"},
        {"Warlock", "Demonology"},
        {"Warlock", "Destruction"},
    },
    healer = {
        {"Druid", "Restoration"},
        {"Paladin", "Holy"},
        {"Priest", "Discipline"},
        {"Priest", "Holy"},
        {"Shaman", "Restoration"},
    },
}

local expectedIDs = {
    tank = {Trinket = 5000162, Finger = 59636, Head = 5000158, Shoulder = 61119, Neck = 5000766},
    ap = {Trinket = 5000161, Finger = 44645, Head = 5000156, Shoulder = 61117, Neck = 5000764},
    sp = {Trinket = 5000160, Finger = 44636, Head = 5000159, Shoulder = 61120, Neck = 5000764},
    healer = {Trinket = 5000160, Finger = 44636, Head = 5000157, Shoulder = 61118, Neck = 5000764},
}

local indexed = {}
for index, registered in ipairs(rules) do
    local rule = registered.rule
    assert(registered.plugin == "Bistooltip_WOTLK5_S2",
        "rule " .. index .. " has the wrong plugin identifier")
    local expectedPhase = rule.slot == "Neck" and "T7" or nil
    assert(rule.phase == expectedPhase,
        "rule " .. index .. " has the wrong phase scope for " .. tostring(rule.slot))
    local expectedType = rule.slot == "Neck" and "item" or "spell"
    assert(type(rule.enhancement) == "table" and rule.enhancement.type == expectedType,
        "rule " .. index .. " has the wrong descriptor type")
    local scope = rule.profession and tostring(rule.profession) or "global"
    local key = table.concat({scope, rule.class, rule.spec, rule.phase or "COMMON", rule.slot}, "|")
    assert(indexed[key] == nil, "duplicate rule target: " .. key)
    indexed[key] = rule
end

local seenProfiles = {}
local roleCounts = {tank = 0, ap = 0, sp = 0, healer = 0}
local function expectRule(className, specName, phase, slotName, profession, enhancementType, enhancementID)
    local scope = profession and tostring(profession) or "global"
    local key = table.concat({scope, className, specName, phase or "COMMON", slotName}, "|")
    local rule = indexed[key]
    assert(rule, "missing rule: " .. key)
    assert(rule.enhancement.type == enhancementType and rule.enhancement.id == enhancementID,
        "wrong enhancement for " .. key .. ": "
            .. tostring(rule.enhancement.type) .. "/" .. tostring(rule.enhancement.id))
end

for role, profiles in pairs(roleProfiles) do
    for _, profile in ipairs(profiles) do
        local className, specName = profile[1], profile[2]
        local profileKey = className .. "|" .. specName
        assert(not seenProfiles[profileKey], "profile appears in multiple roles: " .. profileKey)
        seenProfiles[profileKey] = role
        roleCounts[role] = roleCounts[role] + 1

        expectRule(className, specName, nil, "Trinket", 333, "spell", expectedIDs[role].Trinket)
        expectRule(className, specName, nil, "Finger", 333, "spell", expectedIDs[role].Finger)
        expectRule(className, specName, nil, "Head", 773, "spell", expectedIDs[role].Head)
        expectRule(className, specName, nil, "Shoulder", 773, "spell", expectedIDs[role].Shoulder)
        local neckID = expectedIDs[role].Neck
        if className == "Warlock" and specName == "Affliction" then neckID = 5000765 end
        expectRule(className, specName, "T7", "Neck", nil, "item", neckID)
    end
end

assert(roleCounts.tank == 4, "tank profile count changed")
assert(roleCounts.ap == 13, "AP profile count changed")
assert(roleCounts.sp == 10, "SP profile count changed")
assert(roleCounts.healer == 5, "healer profile count changed")
assert(#rules == 160, "expected 160 rules, got " .. #rules)

for itemID = 5000156, 5000162 do
    assert(acquisitionCalls[itemID] == nil,
        "invented acquisition data for enhancement " .. itemID)
end

local afflictionHaste = indexed[table.concat({
    "global", "Warlock", "Affliction", "T7", "Neck",
}, "|")]
assert(afflictionHaste and afflictionHaste.enhancement.id == 5000765,
    "Affliction must use only the critical neck enhancement")

print("wotlk5_enhancement_rules: OK (160 rules)")
