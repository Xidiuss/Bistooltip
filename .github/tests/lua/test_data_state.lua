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
local playerClass, professionSet
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
    return {
        Warrior = {
            Fury = {
                T7 = {
                    {slot_name = "Head", enhs = {}, a, b},
                    {slot_name = "Finger", enhs = {}, 10, 20, 30},
                },
                T8 = {{slot_name = "Head", enhs = {{type="item",id=80}}, a, b}},
            },
            Protection = { T7 = {
                {slot_name = "Head", enhs = {{type="item",id=70}}, a, b},
            } },
        },
        Druid = { Balance = { T7 = {
            {slot_name = "Head", enhs = {{type="item",id=700}}, a, b},
        } } },
    }
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
    playerClass, professionSet = "Warrior", {}
    BistooltipPlayerContext = {
        GetPlayerClassKey = function() return playerClass end,
        GetProfessionSkillLines = function()
            local copy = {}
            for id, owned in pairs(professionSet) do copy[id] = owned end
            return copy
        end,
    }
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

test("personal enchant assignment preserves gems and follows only its selected database", function()
    setup()
    local base = Bistooltip_bislists.Warrior.Fury.T7[1]
    base.enhs = {{type="spell",id=111}, {type="item",id=222}}
    local ok, err = BistooltipData.SaveCustomEnhancement("Warrior", "Fury", "T7", "Head", "item", 5000762)
    assert(ok, tostring(err))
    local shown = slots()[1]
    assert(shown.enhs[1].id == 5000762 and shown.enhs[2].id == 222, "assignment lost the existing gem")
    assert(base.enhs[1].id == 111, "personal assignment mutated the plugin/data slot")
    options.args.data_source.set(nil, "wowtbc")
    assert(slots()[1].enhs[1] == nil, "assignment leaked into another database")
    options.args.data_source.set(nil, "wowsims")
    assert(slots()[1].enhs[1].id == 5000762, "assignment was lost after database switch")
    assert(BistooltipData.ResetCustomEnhancement("Warrior", "Fury", "T7", "Head"))
    assert(slots()[1].enhs[1] == nil, "reset did not restore the current dataset")
end)

test("rank RESET still restores the base slot when it has a personal enchant", function()
    setup()
    personalize(slots()[1], 2, 1)
    assert(BistooltipData.SaveCustomEnhancement("Warrior", "Fury", "T7", "Head", "item", 5000762))
    BistooltipData.ResetCustomPriorities("Warrior", "Fury", "T7")
    local slot = slots()[1]
    assert(slot[1] == 1 and slot[2] == 2 and slot.enhs[1].id == 5000762,
        "rank RESET lost its base order or erased the personal enchant")
end)

test("enchant editor rejects unknown slots and invalid descriptor IDs", function()
    setup()
    assert(not BistooltipData.SaveCustomEnhancement("Warrior", "Fury", "T7", "Missing", "item", 1))
    assert(not BistooltipData.SaveCustomEnhancement("Warrior", "Fury", "T7", "Head", "item", 0))
    assert(not BistooltipData.SaveCustomEnhancement("Warrior", "Fury", "T7", "Head", "gem", 123))
    assert(not BistooltipData.SaveCustomEnhancement("Warrior", "Fury", "T7", "Head", "spell", 1.5))
end)

test("enchant editor previews a vendor price and saves and resets the chosen slot", function()
    setup()
    BisTooltip_ItemAcquisition[5000762] = {{kind="VENDOR",cost={{currency="Plagued Legendary Shard",amount=1}}}}
    local editor = options.args.enchant_editor.args
    editor.class.set(nil, "Warrior")
    editor.spec.set(nil, "Fury")
    editor.phase.set(nil, "T7")
    editor.slot.set(nil, "Head")
    editor.kind.set(nil, "item")
    editor.id.set(nil, "invalid")
    assert(editor.save.disabled(), "bad ID left Save enabled")
    editor.id.set(nil, "5000762")
    assert(not editor.save.disabled(), "valid ID left Save disabled")
    assert(editor.preview.name():find("Plagued Legendary Shard", 1, true), "price missing from preview")
    editor.save.func()
    assert(slots()[1].enhs[1].id == 5000762, "UI save did not apply assignment")
    assert(not editor.reset.disabled(), "reset stayed disabled")
    editor.reset.func()
    assert(slots()[1].enhs[1] == nil, "UI reset did not restore dataset")
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

test("profession rules apply to same-class offspec while other classes use global rules", function()
    setup()
    professionSet[333] = true
    BisTooltip:DefineEnhancementOverride({
        profession = 333, class = "Warrior", spec = "Protection", slot = "Head",
        enhancement = {type="item",id=333001},
    }, "test")
    BisTooltip:DefineEnhancementOverride({
        profession = 333, class = "Druid", spec = "Balance", slot = "Head",
        enhancement = {type="item",id=333002},
    }, "test")
    BisTooltip:DefineEnhancementOverride({
        class = "Druid", spec = "Balance", slot = "Head",
        enhancement = {type="item",id=700001},
    }, "test")
    local offspec = BistooltipData.GetSlotsForSpec("Warrior", "Protection", "T7")[1]
    local otherClass = BistooltipData.GetSlotsForSpec("Druid", "Balance", "T7")[1]
    assert(offspec.enhs[1].id == 333001,
        "same-class offspec did not receive its profession override")
    assert(otherClass.enhs[1].id == 700001,
        "profession rule leaked to another class or global rule was skipped")
end)

test("Enchanting and Inscription resolve independently on disjoint slots", function()
    setup()
    professionSet[333], professionSet[773] = true, true
    BisTooltip:DefineEnhancementOverride({
        profession = 333, class = "Warrior", spec = "Fury", slot = "Finger",
        enhancement = {type="item",id=333001},
    }, "enchanting")
    BisTooltip:DefineEnhancementOverride({
        profession = 773, class = "Warrior", spec = "Fury", slot = "Head",
        enhancement = {type="item",id=773001},
    }, "inscription")
    local shown = slots()
    assert(shown[1].enhs[1].id == 773001, "Inscription head rule missing")
    assert(shown[2].enhs[1].id == 333001, "Enchanting finger rule missing")
end)

test("profession overrides global and replaces only index one", function()
    setup()
    professionSet[333] = true
    local base = Bistooltip_bislists.Warrior.Fury.T7[1]
    base.enhs = {
        {type="spell",id=111}, {type="item",id=222}, {type="item",id=333},
    }
    BisTooltip:DefineEnhancementOverride({
        class = "Warrior", spec = "Fury", slot = "Head",
        enhancement = {type="item",id=10},
    }, "global")
    BisTooltip:DefineEnhancementOverride({
        profession = 333, class = "Warrior", spec = "Fury", slot = "Head",
        enhancement = {type="item",id=20},
    }, "profession")
    local shown = slots()[1]
    assert(shown.enhs[1].id == 20, "profession rule did not outrank global")
    assert(shown.enhs[2].id == 222 and shown.enhs[3].id == 333,
        "targeted override replaced later gems")
    assert(base.enhs[1].id == 111 and base.enhs[2].id == 222,
        "targeted override mutated the bound database")
end)

test("an empty Trinket enhancement list gains only index one", function()
    setup()
    local base = {slot_name = "Trinket", enhs = {}, 101, 102}
    table.insert(Bistooltip_bislists.Warrior.Fury.T7, base)
    BisTooltip:DefineEnhancementOverride({
        class = "Warrior", spec = "Fury", phase = "T7", slot = "Trinket",
        enhancement = {type="item",id=5000161},
    }, "test")
    local shown = slots()[3]
    assert(shown.enhs[1].id == 5000161 and shown.enhs[2] == nil,
        "empty Trinket list was not populated cleanly")
    assert(next(base.enhs) == nil, "empty base Trinket list was mutated")
end)

test("slot views prefer exact phase and isolate registry and caller mutations", function()
    setup()
    professionSet[333] = true
    BisTooltip:DefineEnhancementOverride({
        profession = 333, class = "Warrior", spec = "Fury", slot = "Head",
        enhancement = {type="item",id=10},
    }, "common")
    local exactRule = {
        profession = 333, class = "Warrior", spec = "Fury", phase = "T7", slot = "Head",
        enhancement = {type="item",id=20},
    }
    BisTooltip:DefineEnhancementOverride(exactRule, "phase")
    exactRule.enhancement.id = 777
    local exact = BistooltipData.GetSlotsForSpec("Warrior", "Fury", "T7")[1]
    local common = BistooltipData.GetSlotsForSpec("Warrior", "Fury", "T8")[1]
    assert(exact.enhs[1].id == 20 and common.enhs[1].id == 10,
        "phase precedence or COMMON fallback was not preserved")
    exact.enhs[1].id = 999
    assert(BistooltipData.GetSlotsForSpec("Warrior", "Fury", "T7")[1].enhs[1].id == 20,
        "caller mutation reached the override registry")
    assert(Bistooltip_bislists.Warrior.Fury.T7[1].enhs[1] == nil,
        "automatic rule mutated the bound database")
end)

test("an exact-phase rule leaves other phases unchanged without COMMON", function()
    setup()
    BisTooltip:DefineEnhancementOverride({
        class = "Warrior", spec = "Fury", phase = "T7", slot = "Head",
        enhancement = {type="item",id=20},
    }, "phase")
    local t7 = BistooltipData.GetSlotsForSpec("Warrior", "Fury", "T7")[1]
    local t8 = BistooltipData.GetSlotsForSpec("Warrior", "Fury", "T8")[1]
    assert(t7.enhs[1].id == 20, "exact phase rule was skipped")
    assert(t8.enhs[1].id == 80, "exact phase rule leaked to another phase")
end)

test("personal enchant wins after automatic override and preserves base gems", function()
    setup()
    professionSet[773] = true
    local base = Bistooltip_bislists.Warrior.Fury.T7[1]
    base.enhs = {{type="spell",id=111}, {type="item",id=40119}}
    BisTooltip:DefineEnhancementOverride({
        profession = 773, class = "Warrior", spec = "Fury", slot = "Head",
        enhancement = {type="item",id=773001},
    }, "inscription")
    assert(BistooltipData.SaveCustomEnhancement(
        "Warrior", "Fury", "T7", "Head", "item", 999001))
    local shown = slots()[1]
    assert(shown.enhs[1].id == 999001 and shown.enhs[2].id == 40119,
        "personal override did not win last or preserve the base gem")
    assert(BistooltipData.ResetCustomEnhancement("Warrior", "Fury", "T7", "Head"))
    shown = slots()[1]
    assert(shown.enhs[1].id == 773001 and shown.enhs[2].id == 40119,
        "removing the personal override did not reveal the automatic layer")
end)

test("targeted rules survive database switches without stale mutation", function()
    setup()
    professionSet[333] = true
    BisTooltip:DefineEnhancementOverride({
        profession = 333, class = "Warrior", spec = "Fury", slot = "Finger",
        enhancement = {type="item",id=333001},
    }, "test")
    assert(slots()[2].enhs[1].id == 333001, "rule missing from initial database")
    options.args.data_source.set(nil, "wowtbc")
    assert(slots()[2].enhs[1].id == 333001, "rule was lost after database switch")
    assert(Bistooltip_bislists.Warrior.Fury.T7[2].enhs[1] == nil,
        "rule was replayed destructively into the new database")
end)

assert(failures == 0, tostring(failures) .. " data state regression(s)")
print("data_state: OK")
