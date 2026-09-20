-- Run from the repository root with Lua 5.1 (WoW APIs are stubbed).
local failures = 0
local function test(name, run)
    local ok, err = pcall(run)
    if ok then print("PASS " .. name) else
        failures = failures + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end
local function upvalue(fn, wanted, replacement, replace)
    for i = 1, 100 do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then
            if replace then debug.setupvalue(fn, i, replacement) end
            return value
        end
    end
    error("Missing upvalue: " .. wanted)
end
local noop = function() end
local methods = {}
local function frame()
    return setmetatable({ scripts = {}, shown = true }, { __index = function(_, key)
        if methods[key] then return methods[key] end
        if key:match("^[A-Z]") then return noop end
    end })
end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:IsShown() return self.shown end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:CreateTexture() return frame() end
function methods:CreateFontString() return frame() end
CreateFrame = function() return frame() end
UIParent = frame()
wipe = function(t) for k in pairs(t) do t[k] = nil end end
GetTime = function() return 10 end
NUM_BAG_SLOTS = 0
GetContainerNumSlots = function() return 0 end
GetInventoryItemID = function() return nil end
DEFAULT_CHAT_FRAME = { AddMessage = noop }
LibStub = function() return { NewAddon = function() return {} end } end

test("initialization preserves shared Lua table functions", function()
    local insert, remove = table.insert, table.remove
    dofile("Bistooltip/Core.lua")
    BistooltipAddon:OnInitialize()
    local unchanged = table.insert == insert and table.remove == remove
    table.insert, table.remove = insert, remove
    assert(unchanged, "addon replaced the process-wide table functions")
end)

test("repeated pool initialization does not allocate another pool", function()
    dofile("Bistooltip/ObjectPool.lua")
    BistooltipPools.Initialize()
    local first = BistooltipPools.IconButtons:GetStats().totalCreated
    BistooltipPools.Initialize()
    assert(BistooltipPools.IconButtons:GetStats().totalCreated == first,
        "second initialization allocated another set of icons")
end)

dofile("Bistooltip/Constants.lua")
dofile("Bistooltip/StateManager.lua")
BistooltipUtils = { RemoveFromUISpecialFrames = noop }
BistooltipData = {}
BistooltipUI = {}
dofile("Bistooltip/BislistUI.lua")

test("independent source option removes the BIS column without hiding costs", function()
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    local header = upvalue(draw, "CreateCustomHeader")
    local columnsFor = upvalue(header, "GetColumnPositions")
    BistooltipState.Set("bisChecklistMode", true)
    BistooltipAddon.db = { char = { show_item_source = false, show_source_column = true } }
    local shown = columnsFor()
    assert(shown[5].type == "source" and shown[7].type == "cost", "default BIS columns changed")
    BistooltipAddon.db.char.show_source_column = false
    local hidden = columnsFor()
    assert(#hidden == 7 and hidden[5].type == "mode" and hidden[6].type == "cost", "source column remains or costs disappeared")
    BistooltipAddon.db.char.show_source_column = true
    BistooltipState.Set("bisChecklistMode", false)
end)

test("closing retains the native UI for reuse", function()
    local main = frame()
    main.frame = main
    local spec = { frame = frame() }
    local tabs = frame()
    upvalue(BistooltipAddon.closeMainFrame, "mainFrame", main, true)
    upvalue(BistooltipAddon.showMainFrame, "tabBarFrame", tabs, true)
    local cleanup = upvalue(BistooltipAddon.closeMainFrame, "CleanupMainFrame")
    -- The public state must still refer to the retained window after close.
    BistooltipState.SetMainFrame(main)
    BistooltipState.SetSpecFrame(spec)
    BistooltipAddon:closeMainFrame()
    assert(not main:IsShown(), "window was not hidden")
    assert(BistooltipState.GetMainFrame() == main, "closed window lost its live reference")
    assert(BistooltipState.GetSpecFrame() == spec, "closed window lost its content reference")
    assert(upvalue(BistooltipAddon.showMainFrame, "tabBarFrame") == tabs,
        "reopening would allocate a new tab tree")
end)

test("bulk preload waits for uncached items beyond the first batch", function()
    BistooltipState.Set("class", "Warrior")
    BistooltipState.Set("spec", "Fury")
    BistooltipState.Set("phase", "T7")
    local slots = {}
    for i = 1, 32 do slots[i] = { i } end
    BistooltipData.GetSlotsForSpec = function() return slots end
    BistooltipData.GetDisplayItemID = function(id) return id end
    GetItemInfo = function() return nil end
    local bulk = upvalue(BistooltipAddon.showMainFrame, "BulkPreloadAllItems")
    bulk(false)
    local ticker = upvalue(bulk, "bulkPreloadFrame")
    local update = ticker:GetScript("OnUpdate")
    local pending = upvalue(update, "itemsToLoad")
    -- Leave the last entry in this runtime's iteration order uncached.
    local last
    for id in pairs(pending) do last = id end
    GetItemInfo = function(id) if id ~= last then return "cached" end end
    update(ticker, 0.1)
    assert(ticker:GetScript("OnUpdate"), "stopped polling while a requested item was uncached")
    GetItemInfo = function() return "cached" end
    update(ticker, 0.1)
    assert(not ticker:GetScript("OnUpdate"), "did not finish once every item was cached")
end)

test("bulk preload requests item enhancements but never spell IDs", function()
    BistooltipData.GetSlotsForSpec = function()
        return {{ enhs = {{ type = "item", id = 123 }, { type = "spell", id = 456 }} }}
    end
    GetItemInfo = function() return nil end
    local requested = {}
    BistooltipAddon._bulkScanner = frame()
    BistooltipAddon._bulkScanner.SetHyperlink = function(_, link) requested[link] = true end
    upvalue(BistooltipAddon.showMainFrame, "BulkPreloadAllItems")(false)
    assert(requested["item:123:0:0:0:0:0:0:0"], "item enhancement was not requested")
    assert(not requested["item:456:0:0:0:0:0:0:0"], "spell enhancement was requested as an item")
end)

test("recreate cleanup hides the actual spec container", function()
    local container = frame()
    upvalue(BistooltipAddon.showMainFrame, "specContainerFrame", container, true)
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    upvalue(draw, "DestroyCustomSpecFrame")()
    assert(not container:IsShown(), "cleanup targeted a global instead of the live container")
end)

test("recreate cleanup hides the actual progress bar", function()
    local bar = frame()
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    local create = upvalue(draw, "CreateProgressBar")
    upvalue(create, "progressBarFrame", bar, true)
    upvalue(draw, "DestroyProgressBar")()
    assert(not bar:IsShown(), "cleanup targeted a global instead of the live progress bar")
end)

test("modifier events refresh both tooltips including rapid release", function()
    GameTooltip, ItemRefTooltip = frame(), frame()
    local counts = { 0, 0 }
    for i, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        tooltip.GetItem = function() return "Item", "item:123:0:0:0" end
        tooltip.SetHyperlink = function() counts[i] = counts[i] + 1 end
    end
    dofile("Bistooltip/Bistooltip.lua")
    BistooltipAddon:initBisTooltip()
    local events = upvalue(BistooltipAddon.initBisTooltip, "eventFrame")
    events:GetScript("OnEvent")(events, "MODIFIER_STATE_CHANGED", "LSHIFT", 1)
    events:GetScript("OnEvent")(events, "MODIFIER_STATE_CHANGED", "LSHIFT", 0)
    assert(counts[1] == 2 and counts[2] == 2,
        "modifier refresh lost tooltip or release: " .. counts[1] .. "/" .. counts[2])
end)

test("bisemblem prints every canonical vendor option for IDs and links", function()
    local commands = {}
    LibStub = function() return { RegisterChatCommand = function(_, name, callback)
        commands[name] = callback
    end } end
    BistooltipAddon:initBislists()
    assert(commands.bisemblem, "canonical bisemblem command was not registered")
    dofile("Bistooltip/SourceFormatter.lua")
    BisTooltip_ItemAcquisition = { [123] = {
        { kind = "VENDOR", cost = {{ currency = "Emblem of Frost", amount = 5 }} },
        { kind = "VENDOR", cost = {{ currency = "Gold", amount = 10000 }} },
        { kind = "CUSTOM", label = "not a vendor" },
    } }
    for _, argument in ipairs({ "123", "|Hitem:123:0:0|h[Item Name]|h" }) do
        local lines = {}
        local originalPrint = print
        print = function(line) lines[#lines + 1] = line end
        local ok, err = pcall(commands.bisemblem, argument)
        print = originalPrint
        assert(ok, err)
        local output = table.concat(lines, "\n")
        assert(output:find("5 Emblem of Frost", 1, true), "missing emblem purchase option")
        assert(output:find("1g", 1, true), "missing gold purchase option")
        assert(not output:find("not a vendor", 1, true), "printed a non-vendor source")
    end
end)

function methods:SetText(text) self.text = text end
BistooltipUtils.NormalizeItemID = function(id) return type(id)=="number" and id>0 and id or nil end
dofile("Bistooltip/DataProvider.lua")

test("cost cells distinguish complete, compound and alternative prices", function()
    BisTooltip_ItemAcquisition = {
        [1]={{kind="VENDOR",cost={{currency="Gold",amount=10000}}}},
        [2]={{kind="VENDOR",cost={{item=90001,amount=2}}}},
        [3]={{kind="VENDOR",cost={{currency="Gold",amount=10000},{currency="Justice",amount=50}}}},
        [4]={{kind="VENDOR",cost={{currency="Valor",amount=20}}},{kind="VENDOR",cost={{currency="Justice",amount=40}}}},
    }
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    local create = upvalue(draw, "CreateCustomSlotRow")
    upvalue(create, "AcquireCustomRow", frame, true)
    upvalue(create, "GetColumnPositions", function() return {{type="cost",x=0,width=100}} end, true)
    BistooltipState.Set("bisChecklistMode", false)
    for id, expected in ipairs({"1g", "x2", "Details", "Details"}) do
        local row = create({slot_name="Head",id}, 0, 1)
        assert(row._costLabel.text:find(expected,1,true), "incomplete/misleading COST for "..id..": "..row._costLabel.text)
    end
end)

test("vendor draw renders only required BiS choices and clears empty headers", function()
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    for _, name in ipairs({"ReleaseActiveElements", "saveData", "ClearCustomRows", "CreateProgressBar", "CreateCustomHeader", "UpdateProgressBar"}) do
        upvalue(draw, name, noop, true)
    end
    upvalue(draw, "specContainerFrame", nil, true)
    upvalue(draw, "customContentFrame", frame(), true)
    local rendered, released = {}, 0
    upvalue(draw, "CreateCustomSlotRow", function(slot)
        assert(#slot==1, "several vendor alternatives packed into one visible item column")
        rendered[#rendered+1]=slot[1]
        return frame(), 20
    end, true)
    BistooltipInstanceHeader={ReleaseAll=function() released=released+1 end}
    BistooltipData.GetSlotsForSpec=function() return {{slot_name="Finger",3,1,2}} end
    BistooltipData.FilterSlots=function(slots) return slots, slots end
    BistooltipData.GetDisplayItemID=function(id) return id end
    BistooltipData.GetOwnedCount=function() return 0 end
    BistooltipData.LoadCustomPriority=function() error("priority reapplied after filtering") end
    BistooltipState.Set("vendorFilterMode", true)
    BistooltipState.Set("bisChecklistMode", true)
    draw()
    assert(#rendered==2 and rendered[1]==3 and rendered[2]==1,
        "vendor draw included a lower-ranked alternative")
    local previous=released
    BistooltipData.GetSlotsForSpec=function() return {} end
    draw()
    assert(released==previous+1, "old instance headers survived empty vendor view")
end)

assert(failures == 0, tostring(failures) .. " runtime regression(s)")
