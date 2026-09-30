local failures = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then print("PASS " .. name) else
        failures = failures + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end
local function setup()
    BisTooltip, BisTooltip_SourceRegistry, BisTooltip_ItemAcquisition = {}, {}, {}
    Bistooltip_wowsims_final = {Druid = {Balance = {T7 = {
        {slot_name = "Head", enhs = {}, 1, 2},
    }}}}
    Bistooltip_wowtbc_bislists = {Druid = {Balance = {T10 = {
        {slot_name = "Head", enhs = {}, 3, 4},
    }}}}
    Bistooltip_wh_bislists = nil
    Bistooltip_bislists = Bistooltip_wowtbc_bislists
    BistooltipUtils, BistooltipConstants = {}, {}
    dofile("Bistooltip/PluginAPI.lua")
    dofile("Bistooltip/SourceFormatter.lua")
    dofile("Bistooltip/DataProvider.lua")
end

test("server rank for another database is queued without aborting plugin load", function()
    setup()
    BisTooltip:SetBiSSlotRank("Druid", "Balance", "T7", "Head", 1, 99, "test")
    BisTooltip:SetAcquisition(99, {{kind = "CUSTOM", label = "Server shop"}}, "test")
    assert(BisTooltip_ItemAcquisition[99], "remaining plugin registration was aborted")
    assert(Bistooltip_bislists.Druid.Balance.T10[1][1] == 3, "unrelated phase mutated")
    Bistooltip_bislists = Bistooltip_wowsims_final
    BisTooltip_ReplayOverlay()
    assert(Bistooltip_bislists.Druid.Balance.T7[1][1] == 99, "deferred rank was lost")
end)

test("repeated replay never mutates a recorded replacement with earlier appends", function()
    setup()
    BisTooltip:AddAcquisition(99, {kind="CUSTOM",label="Old shop"})
    BisTooltip:SetAcquisition(99, {{kind="CUSTOM",label="Replacement"}})
    for round=1,4 do
        BisTooltip_ReplayOverlay()
        local entries=BisTooltip_ItemAcquisition[99]
        assert(#entries==1 and entries[1].label=="Replacement",
            "earlier append contaminated replacement on replay "..round)
    end
end)

test("vendor price replacement preserves non-vendor routes across replay", function()
    setup()
    BisTooltip:SetAcquisition(99, {
        {kind="DROP",source="SHOP"},
        {kind="VENDOR",cost={{currency="Emblem of Heroism",amount=40}}},
    })
    BisTooltip:ReplaceVendorAcquisitions(99, {
        {kind="VENDOR",cost={{currency="Justice",amount=700}}},
    })
    for round=1,2 do
        if round == 2 then BisTooltip_ReplayOverlay() end
        local entries=BisTooltip_ItemAcquisition[99]
        assert(#entries==2 and entries[1].kind=="DROP"
            and entries[2].cost[1].currency=="Justice", "vendor replacement lost routes")
    end
end)

test("invalid server rank remains an actionable API error", function()
    setup()
    assert(not pcall(BisTooltip.SetBiSSlotRank, BisTooltip, "Druid", "Balance", "TYPO", "Head", 1, 99))
    assert(not pcall(BisTooltip.SetBiSSlotRank, BisTooltip, "Druid", "Balance", "T7", "Head", 9, 99))
end)

test("inserted server rank retains the slot capacity and survives replay", function()
    setup()
    Bistooltip_bislists = Bistooltip_wowsims_final
    BisTooltip:InsertBiSSlotRank("Druid", "Balance", "T7", "Head", 1, 99, "test")
    local slot = Bistooltip_bislists.Druid.Balance.T7[1]
    assert(#slot == 2 and slot[1] == 99 and slot[2] == 1,
        "inserting rank 1 did not replace the last baseline alternative")
    Bistooltip_bislists = {Druid = {Balance = {T7 = {
        {slot_name = "Head", enhs = {}, 5, 6},
    }}}}
    BisTooltip_ReplayOverlay()
    slot = Bistooltip_bislists.Druid.Balance.T7[1]
    assert(#slot == 2 and slot[1] == 99 and slot[2] == 5,
        "replay did not preserve the new database capacity")
end)

test("inserting an already ranked item moves it without duplicates", function()
    setup()
    Bistooltip_bislists = Bistooltip_wowsims_final
    BisTooltip:InsertBiSSlotRank("Druid", "Balance", "T7", "Head", 1, 2, "test")
    local slot = Bistooltip_bislists.Druid.Balance.T7[1]
    assert(#slot == 2 and slot[1] == 2 and slot[2] == 1,
        "existing item was duplicated or another item lost")
    BisTooltip_ReplayOverlay()
    assert(#slot == 2 and slot[1] == 2 and slot[2] == 1,
        "replay duplicated an existing ranked item")
end)

test("insert into unavailable database phase is deferred", function()
    setup()
    BisTooltip:InsertBiSSlotRank("Druid", "Balance", "T7", "Head", 1, 99, "test")
    Bistooltip_bislists = Bistooltip_wowsims_final
    BisTooltip_ReplayOverlay()
    local slot = Bistooltip_bislists.Druid.Balance.T7[1]
    assert(#slot == 2 and slot[1] == 99 and slot[2] == 1,
        "deferred insertion exceeded the baseline capacity")
end)

test("accepted custom registry source renders without a tooltip error", function()
    setup()
    BisTooltip:DefineSource("SHOP", {kind = "CUSTOM", label = "Server shop"})
    BisTooltip:SetAcquisition(99, {{kind = "DROP", source = "SHOP"}})
    assert(BisTooltip_FormatSource(BisTooltip_ItemAcquisition[99][1]) == "Server shop")
    local sources = BistooltipData.GetAllItemSources(99)
    assert(#sources == 1 and sources[1].type == "custom" and sources[1].label == "Server shop")
end)

test("TOKEN acquisitions require an exact token item and keep it in identity", function()
    setup()
    local function token(tokenItem)
        return {
            kind = "TOKEN", source = "RAID", tier = "T8",
            family = "Wayward Vanquisher", tokenItem = tokenItem,
        }
    end
    for _, invalid in ipairs({token(nil), token(0), token(1.5), token("45634")}) do
        assert(not pcall(BisTooltip.AddAcquisition, BisTooltip, 99, invalid, "test"),
            "malformed TOKEN tokenItem was accepted")
    end
    assert(BisTooltip:AddAcquisition(99, token(45634), "test"))
    assert(BisTooltip:AddAcquisition(99, token(45637), "test"))
    assert(#BisTooltip_ItemAcquisition[99] == 2,
        "distinct TOKEN item IDs were collapsed by acquisition identity")
end)

test("COMMON enhancement replay preserves arguments across its nil phase", function()
    setup()
    BisTooltip:SetEnhancement("Druid", "Balance", nil, "Head", {{type = "spell", id = 123}})
    Bistooltip_bislists = Bistooltip_wowsims_final
    -- Lua 5.1 permits #args == 2 for an array with args[3] absent.
    -- Emulate that legal boundary even on Lua runtimes choosing another one.
    local nativeUnpack = unpack
    unpack = function(values, first, last)
        return nativeUnpack(values, first or 1, last or 2)
    end
    local ok, err = pcall(BisTooltip_ReplayOverlay)
    unpack = nativeUnpack
    assert(ok, err)
    assert(Bistooltip_bislists.Druid.Balance.T7[1].enhs[1].id == 123)
end)

test("vendor rendering retains item-only and compound payment parts", function()
    setup()
    BisTooltip:SetAcquisition(99, {{kind = "VENDOR", cost = {{item = 30183, amount = 2}}}})
    assert(BisTooltip_FormatSource(BisTooltip_ItemAcquisition[99][1]) == "VENDOR: 2 Item #30183")
    local compound = {kind = "VENDOR", cost = {
        {currency = "Gold", amount = 10000}, {item = 30183, amount = 2},
        {currency = "Emblem of Triumph", amount = 75},
    }}
    assert(BisTooltip_FormatSource(compound) == "VENDOR: 1g + 2 Item #30183 + 75 Emblem of Triumph")
    assert(BisTooltip_FormatSourceColored(compound):find("2 Item #30183", 1, true))
end)

test("TROPHY display keeps its label and other item payment parts", function()
    setup()
    local entry = {kind = "VENDOR", tier = "T9", displayVariant = "TROPHY", variantLabel = "Crusade", cost = {
        {item = 47242, amount = 2}, {item = 30183, amount = 3},
        {currency = "Emblem of Triumph", amount = 75},
    }}
    assert(BisTooltip_FormatSource(entry) == "T9 - TROPHY: 2 Crusade + 3 Item #30183 + 75 Emblem of Triumph")
end)

test("TOKEN and TROPHY labels become exact item icons only when resolved", function()
    setup()
    BisTooltip_SourceRegistry.RAID = {
        instance = "Ulduar", boss = "Hodir", difficulty = "25N",
    }
    local token = {
        kind = "TOKEN", source = "RAID", tier = "T8",
        family = "Wayward Vanquisher", tokenItem = 45634,
    }
    local trophy = {
        kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
        variantLabel = "Crusade", cost = {
            {item = 47242, amount = 2},
            {currency = "Emblem of Triumph", amount = 75},
        },
    }
    local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    local function resolved(itemID)
        assert(itemID == 45634 or itemID == 47242, "wrong icon item requested")
        return texture
    end
    assert(BisTooltip_FormatSource(token) ==
        "T8 - TOKEN: Wayward Vanquisher [Ulduar: Hodir <25N>]")
    assert(BisTooltip_FormatSource(token, function() return nil end) ==
        "T8 - TOKEN: Wayward Vanquisher [Ulduar: Hodir <25N>]")
    assert(BisTooltip_FormatSource(token, resolved) ==
        "T8 - |T" .. texture .. ":14|t Wayward Vanquisher [Ulduar: Hodir <25N>]")
    assert(BisTooltip_FormatSource(trophy, resolved) ==
        "T9 - |T" .. texture .. ":14|t 2 Crusade + 75 Emblem of Triumph")
    local colored = assert(BisTooltip_FormatSourceColored(token, resolved))
    assert(colored:find("|T" .. texture .. ":14|t", 1, true),
        "colored TOKEN output lost the native icon")
    assert(not colored:find("TOKEN:", 1, true),
        "colored TOKEN output retained the literal label")
    assert(BisTooltip_FormatSource(trophy, function() error("cold cache") end) ==
        "T9 - TROPHY: 2 Crusade + 75 Emblem of Triumph")
end)

local function enhancementRule(overrides)
    local rule = {
        class = "Druid",
        spec = "Feral tank",
        slot = "Finger",
        enhancement = {type = "item", id = 900001},
    }
    for key, value in pairs(overrides or {}) do rule[key] = value end
    return rule
end

test("targeted enhancement registration rejects malformed rules", function()
    setup()
    local invalid = {
        enhancementRule({profession = false}),
        enhancementRule({profession = 0}),
        enhancementRule({profession = 333.5}),
        enhancementRule({class = false}),
        enhancementRule({spec = false}),
        enhancementRule({slot = false}),
        enhancementRule({phase = ""}),
        enhancementRule({enhancement = false}),
        enhancementRule({enhancement = {type = "gem", id = 1}}),
        enhancementRule({enhancement = {type = "item", id = 0}}),
        enhancementRule({enhancement = {type = "spell", id = 1.5}}),
        enhancementRule({enhancement = {type = "none", id = 1}}),
    }
    for index, rule in ipairs(invalid) do
        assert(not pcall(BisTooltip.DefineEnhancementOverride, BisTooltip, rule, "test"),
            "malformed targeted rule accepted at case " .. index)
    end
    assert(not pcall(BisTooltip.DefineEnhancementOverride, BisTooltip, enhancementRule(), nil),
        "missing plugin identifier was accepted")
    assert(BisTooltip:DefineEnhancementOverride(enhancementRule({
        enhancement = {type = "none", id = 0},
    }), "none"))
    assert(BisTooltip:DefineEnhancementOverride(enhancementRule({
        slot = "Head", enhancement = {type = "spell", id = 123},
    }), "spell"))
    assert(BisTooltip:DefineEnhancementOverride(enhancementRule({
        slot = "Neck", enhancement = {type = "item", id = 456},
    }), "item"))
end)

test("targeted resolver prefers exact phase then COMMON", function()
    setup()
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        enhancement = {type = "item", id = 10},
    }), "common")
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        phase = "T10", enhancement = {type = "item", id = 20},
    }), "phase")
    local t9 = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {}, true)
    local t10 = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T10", "Finger", {}, true)
    assert(t9 and t9.id == 10, "COMMON rule was not used")
    assert(t10 and t10.id == 20, "phase rule did not outrank COMMON")
    assert(BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral dps", "T10", "Finger", {}, true) == nil,
        "nonmatching spec returned a rule")
end)

test("targeted registry owns input and returned descriptor copies", function()
    setup()
    local rule = enhancementRule({enhancement = {type = "item", id = 40119}})
    BisTooltip:DefineEnhancementOverride(rule, "test")
    rule.enhancement.id = 999
    local first = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {}, true)
    assert(first.type == "item" and first.id == 40119,
        "registration retained the caller's descriptor")
    first.id = 888
    local second = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {}, true)
    assert(second.id == 40119, "resolver exposed its stored descriptor")
end)

test("duplicate targeted identity is last-write-wins with a diagnostic", function()
    setup()
    local lines = {}
    local originalPrint = print
    print = function(line) lines[#lines + 1] = tostring(line) end
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        enhancement = {type = "item", id = 10},
    }), "first")
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        enhancement = {type = "item", id = 20},
    }), "second")
    print = originalPrint
    local found = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {}, true)
    assert(found and found.id == 20, "duplicate target did not replace the rule")
    local output = table.concat(lines, "\n")
    assert(output:find("second", 1, true) and output:find("first", 1, true),
        "replacement diagnostic omitted the participating plugins")
end)

test("profession rule outranks a global rule when profession use is allowed", function()
    setup()
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        enhancement = {type = "item", id = 10},
    }), "global")
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        profession = 333, enhancement = {type = "item", id = 20},
    }), "enchanting")
    local profession = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {[333] = true}, true)
    local global = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {[333] = true}, false)
    assert(profession and profession.id == 20, "profession rule did not outrank global")
    assert(global and global.id == 10, "disallowed profession rules hid the global rule")
end)

test("two owned profession matches diagnose ambiguity and fall back globally", function()
    setup()
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        enhancement = {type = "item", id = 900000},
    }), "global")
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        profession = 333, enhancement = {type = "item", id = 900001},
    }), "enchanting")
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        profession = 773, enhancement = {type = "item", id = 900002},
    }), "inscription")
    local lines = {}
    local originalPrint = print
    print = function(line) lines[#lines + 1] = tostring(line) end
    local found = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {[773] = true, [333] = true}, true)
    print = originalPrint
    assert(found and found.id == 900000, "ambiguous professions did not use global fallback")
    local output = table.concat(lines, "\n")
    assert(output:find("ambiguous", 1, true) and output:find("Finger", 1, true),
        "ambiguous target did not produce an actionable diagnostic")
end)

test("ambiguous profession rules without a global rule resolve to nil", function()
    setup()
    BisTooltip:DefineEnhancementOverride(enhancementRule({profession = 333}), "enchanting")
    BisTooltip:DefineEnhancementOverride(enhancementRule({
        profession = 773, enhancement = {type = "item", id = 900002},
    }), "inscription")
    local originalPrint = print
    print = function() end
    local found = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {[333] = true, [773] = true}, true)
    print = originalPrint
    assert(found == nil, "ambiguous professions invented a fallback")
end)

test("overlay replay neither duplicates nor removes targeted rules", function()
    setup()
    BisTooltip:DefineEnhancementOverride(enhancementRule({profession = 333}), "test")
    BisTooltip_ReplayOverlay()
    BisTooltip_ReplayOverlay()
    local found = BisTooltip:ResolveEnhancementOverride(
        "Druid", "Feral tank", "T9", "Finger", {[333] = true}, true)
    assert(found and found.id == 900001,
        "overlay replay cleared or changed a targeted rule")
end)

test("unpublished whole-list profession API is absent", function()
    setup()
    assert(type(BisTooltip.DefineEnhancementOverride) == "function", "targeted registration API missing")
    assert(type(BisTooltip.ResolveEnhancementOverride) == "function", "targeted resolver API missing")
    assert(BisTooltip.DefineProfessionEnhancement == nil, "old registration API still published")
    assert(BisTooltip.ResolveProfessionEnhancement == nil, "old resolver API still published")
end)

assert(failures == 0, tostring(failures) .. " plugin boundary regression(s)")
print("plugin_boundaries: OK")
