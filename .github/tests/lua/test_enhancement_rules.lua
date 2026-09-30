-- Standalone contract test for WOTLK5 enhancement declarations.
-- Run from the WOTLK5 worktree with Lua 5.1.
local rules = {}
local acquisitionCalls = {}

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
    tank = {Trinket = 5000162, Head = 5000158, Neck = 5000766},
    ap = {Trinket = 5000161, Head = 5000156, Neck = 5000764},
    sp = {Trinket = 5000160, Head = 5000159, Neck = 5000764},
    healer = {Trinket = 5000160, Head = 5000157, Neck = 5000764},
}

local indexed = {}
for index, registered in ipairs(rules) do
    local rule = registered.rule
    assert(registered.plugin == "Bistooltip_WOTLK5_S2",
        "rule " .. index .. " has the wrong plugin identifier")
    assert(rule.phase == "T7", "rule " .. index .. " is not T7-only")
    assert(type(rule.enhancement) == "table" and rule.enhancement.type == "item",
        "rule " .. index .. " does not use an item descriptor")
    local scope = rule.profession and tostring(rule.profession) or "global"
    local key = table.concat({scope, rule.class, rule.spec, rule.phase, rule.slot}, "|")
    assert(indexed[key] == nil, "duplicate rule target: " .. key)
    indexed[key] = rule
end

local seenProfiles = {}
local roleCounts = {tank = 0, ap = 0, sp = 0, healer = 0}
local function expectRule(className, specName, slotName, profession, itemID)
    local scope = profession and tostring(profession) or "global"
    local key = table.concat({scope, className, specName, "T7", slotName}, "|")
    local rule = indexed[key]
    assert(rule, "missing rule: " .. key)
    assert(rule.enhancement.id == itemID,
        "wrong item for " .. key .. ": " .. tostring(rule.enhancement.id))
end

for role, profiles in pairs(roleProfiles) do
    for _, profile in ipairs(profiles) do
        local className, specName = profile[1], profile[2]
        local profileKey = className .. "|" .. specName
        assert(not seenProfiles[profileKey], "profile appears in multiple roles: " .. profileKey)
        seenProfiles[profileKey] = role
        roleCounts[role] = roleCounts[role] + 1

        expectRule(className, specName, "Trinket", 333, expectedIDs[role].Trinket)
        expectRule(className, specName, "Head", 773, expectedIDs[role].Head)
        local neckID = expectedIDs[role].Neck
        if className == "Warlock" and specName == "Affliction" then neckID = 5000765 end
        expectRule(className, specName, "Neck", nil, neckID)
    end
end

assert(roleCounts.tank == 4, "tank profile count changed")
assert(roleCounts.ap == 13, "AP profile count changed")
assert(roleCounts.sp == 10, "SP profile count changed")
assert(roleCounts.healer == 5, "healer profile count changed")
assert(#rules == 96, "expected 96 rules, got " .. #rules)

for itemID = 5000156, 5000162 do
    assert(acquisitionCalls[itemID] == nil,
        "invented acquisition data for enhancement " .. itemID)
end

local afflictionHaste = indexed[table.concat({
    "global", "Warlock", "Affliction", "T7", "Neck",
}, "|")]
assert(afflictionHaste and afflictionHaste.enhancement.id == 5000765,
    "Affliction must use only the critical neck enhancement")

print("wotlk5_enhancement_rules: OK (96 rules)")
