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

assert(failures == 0, tostring(failures) .. " plugin boundary regression(s)")
print("plugin_boundaries: OK")
