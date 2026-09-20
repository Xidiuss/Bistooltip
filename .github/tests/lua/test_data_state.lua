-- Run from the core worktree with Lua 5.1. WoW/Ace UI calls are stubbed;
-- database binding, migration, plugin replay and personal order use real code.
local failures = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then print("PASS " .. name) else
        failures = failures + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end

local saved, options, defaults
local noop = function() end
LibStub = function(name)
    if name == "AceDB-3.0" then return { New = function(_, _, values) defaults = values; return saved end } end
    if name == "AceConfig-3.0" then return { RegisterOptionsTable = function(_, _, opts) options = opts end } end
    if name == "AceConfigDialog-3.0" then return { AddToBlizOptions = noop } end
    return {}
end
UnitFactionGroup = function() return "Alliance" end
GetItemInfo = function() return nil end
GetTime = function() return 0 end
DEFAULT_CHAT_FRAME = { AddMessage = noop }
BistooltipUtils = { NormalizeItemID = function(id) return id end }
BistooltipConstants = {}

local function database(a, b)
    return { Warrior = { Fury = { T7 = {
        {slot_name = "Head", enhs = {}, a, b},
        {slot_name = "Finger", enhs = {}, 10, 20, 30},
    } } } }
end
local function setup(legacy)
    BistooltipAddon = { AceAddonName = "Bis-Tooltip" }
    Bistooltip_wowsims_final = database(1, 2)
    Bistooltip_wowtbc_bislists = database(3, 4)
    Bistooltip_wh_bislists = database(5, 6)
    Bistooltip_wowsims_horde_overrides = nil
    local classes = {{name = "Warrior", specs = {"Fury"}}}
    Bistooltip_wowsims_final_classes, Bistooltip_wowtbc_classes, Bistooltip_wh_classes = classes, classes, classes
    Bistooltip_wowsims_final_phases, Bistooltip_wowtbc_phases, Bistooltip_wh_phases = {"T7"}, {"T7"}, {"T7"}
    saved = { global = { data_source = "wowsims", custom_priorities = {} }, char = {
        version = 6.3, class_index = 1, spec_index = 1, phase_index = 1,
        data_source = legacy, filter_specs = {}, highlight_spec = {},
    } }
    BisTooltip, BisTooltip_SourceRegistry, BisTooltip_ItemAcquisition = {}, {}, {}
    Bistooltip_char_equipment = {}
    dofile("Bistooltip/PluginAPI.lua")
    dofile("Bistooltip/SourceFormatter.lua")
    dofile("Bistooltip/DataProvider.lua")
    dofile("Bistooltip/Config.lua")
    BistooltipAddon:initConfig()
end
local function slots() return BistooltipData.GetSlotsForSpec("Warrior", "Fury", "T7") end
local function personalize(slot, first, second)
    BistooltipData.LoadCustomPriority(slot, "Warrior", "Fury", "T7")
    slot[1], slot[2] = first, second
    BistooltipData.SaveCustomPriority(slot, "Warrior", "Fury", "T7")
end

test("source column starts on, redraws, and stays independent of tooltip sources", function()
    setup()
    assert(defaults.char.show_item_source == true and defaults.char.show_source_column == true,
        "fresh characters should see both source displays")
    local refreshes = 0
    BistooltipAddon.RefreshUI = function() refreshes = refreshes + 1 end
    options.args.show_item_source.set(nil, false)
    assert(options.args.show_item_source.get() == false, "source toggle did not persist")
    options.args.show_source_column.set(nil, false)
    assert(options.args.show_source_column.get() == false and options.args.show_item_source.get() == false,
        "column toggle changed tooltip preference")
    options.args.show_source_column.set(nil, true)
    assert(options.args.show_source_column.get() == true and refreshes == 2,
        "source column toggle did not refresh UI")
end)

test("RESET removes the saved account order", function()
    setup()
    personalize(slots()[1], 2, 1)
    BistooltipData.ResetCustomPriorities("Warrior", "Fury", "T7")
    local slot = slots()[1]
    BistooltipData.LoadCustomPriority(slot, "Warrior", "Fury", "T7")
    assert(slot[1] == 1, "personal order returned after RESET")
    assert(next(saved.global.custom_priorities) == nil, "account order remains persisted")
end)

test("database round trip preserves default order for RESET", function()
    setup()
    personalize(slots()[1], 2, 1)
    BistooltipAddon:changeSpec("wowtbc")
    slots()
    BistooltipAddon:changeSpec("wowsims")
    local slot = slots()[1]
    BistooltipData.LoadCustomPriority(slot, "Warrior", "Fury", "T7")
    BistooltipData.RestoreOriginalOrder(slot, "Warrior", "Fury", "T7")
    assert(slot[1] == 1, "rebound database captured personalized order as default")
end)

test("migration never overrides a later account source choice", function()
    setup("wh")
    assert(saved.global.data_source == "wh", "legacy choice was not migrated")
    options.args.data_source.set(nil, "wowsims")
    BistooltipAddon:initConfig()
    assert(saved.global.data_source == "wowsims", "dormant char source overrode account selection")
    saved.char = { version = 6.3, data_source = "wowtbc", filter_specs = {}, highlight_spec = {} }
    BistooltipAddon:initConfig()
    assert(saved.global.data_source == "wowsims", "another character overrode account selection")
end)

test("migration never resurrects deleted legacy priorities", function()
    setup()
    -- A different character logs in after account migration completed.
    saved.char.custom_priorities = { Warrior_Fury_T7_Head = {2, 1} }
    BistooltipAddon:initConfig()
    assert(next(saved.global.custom_priorities) == nil, "legacy priorities migrated again")
end)

test("personal order is applied before BIS virtual slots and progress", function()
    setup()
    saved.global.custom_priorities.Warrior_Fury_T7_Finger = {30, 10, 20}
    Bistooltip_char_equipment[30] = {equipped = 1}
    local filtered, progress = BistooltipData.FilterSlots(slots(), "", false, false, false, true)
    assert(progress[2][1] == 30, "progress counted database rank instead of saved rank")
    assert(#filtered == 2, "owned personalized Ring 1 was not filtered out")
end)

test("plugin rank survives reset and database round trip", function()
    setup()
    BisTooltip:SetBiSSlotRank("Warrior", "Fury", "T7", "Head", 1, 99, "test")
    personalize(slots()[1], 2, 99)
    BistooltipAddon:changeSpec("wowtbc")
    BistooltipAddon:changeSpec("wowsims")
    slots()
    BistooltipData.ResetCustomPriorities("Warrior", "Fury", "T7")
    assert(slots()[1][1] == 99, "RESET lost server plugin rank")
    assert(slots()[1][2] == 2, "replay corrupted remaining ranks")
end)

test("Horde overrides remain pristine across a database round trip", function()
    setup()
    Bistooltip_wowsims_horde_overrides = { Warrior = { Fury = { T7 = {
        [1] = {slot_name = "Head", enhs = {}, 7, 8},
    } } } }
    UnitFactionGroup = function() return "Horde" end
    BistooltipAddon:changeSpec("wowsims")
    personalize(slots()[1], 8, 7)
    BistooltipAddon:changeSpec("wowtbc")
    BistooltipAddon:changeSpec("wowsims")
    slots()
    BistooltipData.ResetCustomPriorities("Warrior", "Fury", "T7")
    assert(slots()[1][1] == 7 and slots()[1][2] == 8, "Horde source slot was mutated")
    UnitFactionGroup = function() return "Alliance" end
end)

assert(failures == 0, tostring(failures) .. " data state regression(s)")
print("data_state: OK")
