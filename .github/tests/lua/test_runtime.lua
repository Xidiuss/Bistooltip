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
    return setmetatable({ scripts = {}, events = {}, lines = {}, doubleLines = {}, shown = true }, { __index = function(_, key)
        if methods[key] then return methods[key] end
        if key:match("^[A-Z]") then return noop end
    end })
end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:IsShown() return self.shown end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:HookScript(name, fn) self.scripts[name] = fn end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:UnregisterEvent(name) self.events[name] = nil end
function methods:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
function methods:AddDoubleLine(left, right)
    self.doubleLines[#self.doubleLines + 1] = tostring(left) .. " | " .. tostring(right)
end
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

test("bulk preload requests bounded batches and waits for slow items", function()
    BistooltipState.Set("class", "Warrior")
    BistooltipState.Set("spec", "Fury")
    BistooltipState.Set("phase", "T7")
    local slots = {}
    for i = 1, 32 do slots[i] = { i } end
    BistooltipData.GetSlotsForSpec = function() return slots end
    BistooltipData.GetDisplayItemID = function(id) return id end
    GetItemInfo = function() return nil end
    local requests = {}
    BistooltipAddon._bulkScanner = frame()
    BistooltipAddon._bulkScanner.SetHyperlink = function(_, link) requests[#requests + 1] = link end
    local bulk = upvalue(BistooltipAddon.showMainFrame, "BulkPreloadAllItems")
    bulk(false)
    local ticker = upvalue(bulk, "bulkPreloadFrame")
    local update = ticker:GetScript("OnUpdate")
    local pending = upvalue(upvalue(update, "RequestMissingBatch"), "itemsToLoad")
    assert(#requests > 0 and #requests <= 8, "initial request exceeded one bounded batch")
    update(ticker, 0.2)
    assert(#requests <= 16, "one update sent too many item requests")
    -- Leave the last entry in this runtime's iteration order uncached.
    local last
    for id in pairs(pending) do last = id end
    GetItemInfo = function(id) if id ~= last then return "cached" end end
    update(ticker, 2.1)
    assert(ticker:GetScript("OnUpdate"), "stopped polling after the old two-second timeout")
    GetItemInfo = function() return "cached" end
    update(ticker, 0.2)
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

test("stale preload callback cannot cancel a newer selection", function()
    local bulk = upvalue(BistooltipAddon.showMainFrame, "BulkPreloadAllItems")
    BistooltipState.Set("class", "Warrior")
    BistooltipState.Set("spec", "Fury")
    BistooltipState.Set("phase", "T7")
    BistooltipData.GetSlotsForSpec = function() return {{123456}} end
    GetItemInfo = function() return nil end
    bulk(false)
    local ticker = upvalue(bulk, "bulkPreloadFrame")
    local old = ticker:GetScript("OnUpdate")
    BistooltipState.Set("phase", "T8")
    bulk(false)
    local current = ticker:GetScript("OnUpdate")
    assert(old ~= current, "new selection did not replace preload callback")
    old(ticker, 0.2)
    assert(ticker:GetScript("OnUpdate") == current, "old callback canceled the current preload")
end)

test("switching to a fully cached selection cancels the old poller", function()
    local bulk = upvalue(BistooltipAddon.showMainFrame, "BulkPreloadAllItems")
    BistooltipState.Set("phase", "T7")
    BistooltipData.GetSlotsForSpec = function() return {{123456}} end
    GetItemInfo = function() return nil end
    bulk(false)
    local ticker = upvalue(bulk, "bulkPreloadFrame")
    assert(ticker:GetScript("OnUpdate"), "uncached item did not start polling")
    GetItemInfo = function() return "cached" end
    bulk(false)
    assert(not ticker:GetScript("OnUpdate"), "obsolete callback continued after all items were cached")
end)

test("on-demand preload retries a missing item and clears its pending state", function()
    local init = upvalue(BistooltipAddon.showMainFrame, "InitPreloadSystem")
    init()
    local ticker = upvalue(init, "preloadFrame")
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    local queue = upvalue(upvalue(draw, "CreateCustomSlotRow"), "QueuePreload")
    local requests = 0
    BistooltipAddon._preloadScanner = frame()
    BistooltipAddon._preloadScanner.SetHyperlink = function() requests = requests + 1 end
    GetItemInfo = function() return nil end
    queue(987654)
    local update = ticker:GetScript("OnUpdate")
    update(ticker, 0.2)
    update(ticker, 1.0)
    assert(requests >= 2, "on-demand miss was never retried")
    GetItemInfo = function() return "cached" end
    update(ticker, 0.2)
    assert(not upvalue(queue, "preloadSeen")[987654], "loaded ID remained blocked in preload cache")
end)

test("on-demand preload stops requesting after its retry budget", function()
    local init = upvalue(BistooltipAddon.showMainFrame, "InitPreloadSystem")
    local ticker = upvalue(init, "preloadFrame")
    local draw = upvalue(BistooltipAddon.showMainFrame, "drawSpecData")
    local queue = upvalue(upvalue(draw, "CreateCustomSlotRow"), "QueuePreload")
    local requests = 0
    BistooltipAddon._preloadScanner.SetHyperlink = function() requests = requests + 1 end
    GetItemInfo = function() return nil end
    queue(987655)
    for i = 1, 16 do ticker:GetScript("OnUpdate")(ticker, 1.0) end
    assert(requests == 4 and not ticker:IsShown(), "missing item kept being requested")
    queue(987655)
    assert(not ticker:IsShown(), "exhausted item was requeued before manual reload")
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

BistooltipUtils.ColorizeByClass = function(_, text) return tostring(text) end
BistooltipUtils.ColorizeClassName = function(text) return tostring(text) end
BistooltipUtils.NormalizeClassFileToken = function(value) return value end
BistooltipUtils.GetClassFileFromDatasetName = function(value) return value end
BistooltipUtils.TableContains = function() return false end
BistooltipUtils.CaseInsensitivePairs = function(value) return pairs(value or {}) end
BistooltipUtils.GetSpecIcon = function() return nil end
BistooltipPlayerContext = {
    GetPlayerClassSpecKeys = function() return "Shaman", "Spellhance" end,
}

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

test("Your specialization uses the shared player context result", function()
    Bistooltip_bislists = { Shaman = { Spellhance = { T7 = {
        {slot_name = "Head", enhs = {}, 123},
    } } } }
    Bistooltip_spec_icons = { Shaman = { Spellhance = "spellhance-icon" } }
    Bistooltip_classes_indexes = { Shaman = 1 }
    Bistooltip_wowtbc_phases = {"T7"}
    BistooltipAddon.db = { char = {
        tooltip_with_ctrl = false, filter_specs = {}, highlight_spec = {},
        filter_class_names = false, show_item_source = false,
    } }
    IsShiftKeyDown = function() return false end
    IsControlKeyDown = function() return false end
    IsEquippableItem = function() return true end
    strsplit = function() return "item", "123" end
    GetItemInfo = function()
        return "Test item", nil, 4, nil, nil, nil, nil, nil, "INVTYPE_HEAD"
    end
    GameTooltip.GetItem = function() return "Test item", "item:123:0:0:0" end
    GameTooltip.lines, GameTooltip.doubleLines = {}, {}
    local hook = GameTooltip.scripts.OnTooltipSetItem
    assert(type(hook) == "function", "tooltip hook was not installed")
    hook(GameTooltip)
    local output = table.concat(GameTooltip.doubleLines, "\n")
    assert(output:find("Spellhance", 1, true),
        "shared Spellhance context was not shown in Your specialization")
end)

test("tooltip source lines request native TOKEN item textures", function()
    dofile("Bistooltip/SourceFormatter.lua")
    local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    BisTooltip_SourceRegistry = {
        RAID = {instance = "Ulduar", boss = "Hodir", difficulty = "25N"},
    }
    BisTooltip_ItemAcquisition = { [123] = {{
        kind = "TOKEN", source = "RAID", tier = "T8",
        family = "Wayward Vanquisher", tokenItem = 45634,
    }} }
    BistooltipData.GetItemTexture = function(itemID)
        assert(itemID == 45634, "tooltip requested the wrong TOKEN item texture")
        return texture
    end
    BistooltipAddon.db.char.show_item_source = true
    IsEquippableItem = function() return false end
    GetItemInfo = function()
        return "Test item", nil, 2, nil, nil, nil, nil, nil, ""
    end
    GameTooltip.GetItem = function() return "Test item", "item:123:0:0:0" end
    GameTooltip.lines, GameTooltip.doubleLines = {}, {}
    GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
    local output = table.concat(GameTooltip.lines, "\n")
    assert(output:find("|T" .. texture .. ":14|t", 1, true),
        "tooltip source did not render the native TOKEN icon")
    assert(not output:find("TOKEN:", 1, true),
        "tooltip source retained the literal TOKEN label")
end)

test("character context events refresh visible tooltips and UI safely", function()
    local eventFrame = upvalue(BistooltipAddon.initBisTooltip, "eventFrame")
    local events = {
        "ACTIVE_TALENT_GROUP_CHANGED", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE",
        "PLAYER_EQUIPMENT_CHANGED", "SKILL_LINES_CHANGED",
    }
    local tooltipRefreshes, uiRefreshes = 0, 0
    GameTooltip.SetHyperlink = function() tooltipRefreshes = tooltipRefreshes + 1 end
    ItemRefTooltip.SetHyperlink = function() tooltipRefreshes = tooltipRefreshes + 1 end
    GameTooltip.GetItem = function() return "Item", "item:123:0:0:0" end
    ItemRefTooltip.GetItem = GameTooltip.GetItem
    GameTooltip:Show()
    ItemRefTooltip:Show()
    BistooltipAddon.RefreshUI = function() uiRefreshes = uiRefreshes + 1 end
    local onEvent = eventFrame:GetScript("OnEvent")
    for _, event in ipairs(events) do
        assert(eventFrame.events[event], "context event was not registered: " .. event)
        onEvent(eventFrame, event)
    end
    assert(tooltipRefreshes == #events * 2, "context events missed a visible tooltip")
    assert(uiRefreshes == #events, "context events missed the main UI refresh")

    BistooltipAddon.RefreshUI = nil
    local oldGame, oldRef = GameTooltip, ItemRefTooltip
    GameTooltip, ItemRefTooltip = nil, nil
    local ok, err = pcall(onEvent, eventFrame, "PLAYER_EQUIPMENT_CHANGED")
    GameTooltip, ItemRefTooltip = oldGame, oldRef
    assert(ok, "context event was unsafe before UI creation: " .. tostring(err))

    BistooltipAddon:cleanupBisTooltip()
    for _, event in ipairs(events) do
        assert(not eventFrame.events[event], "cleanup retained context event: " .. event)
    end
end)

test("bisemblem prints every canonical vendor option for IDs and links", function()
    local commands = {}
    LibStub = function() return { RegisterChatCommand = function(_, name, callback)
        commands[name] = callback
    end } end
    BistooltipAddon:initBislists()
    assert(commands.bisemblem, "canonical bisemblem command was not registered")
    dofile("Bistooltip/SourceFormatter.lua")
    local trophyTexture = "Interface\\Icons\\INV_Misc_Rune_10"
    BistooltipData.GetItemTexture = function(itemID)
        if itemID == 47242 then return trophyTexture end
    end
    BisTooltip_ItemAcquisition = { [123] = {
        { kind = "VENDOR", cost = {{ currency = "Emblem of Frost", amount = 5 }} },
        { kind = "VENDOR", cost = {{ currency = "Gold", amount = 10000 }} },
        { kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
          variantLabel = "Crusade", cost = {{ item = 47242, amount = 1 }} },
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
        assert(output:find("|T" .. trophyTexture .. ":14|t", 1, true),
            "TROPHY purchase option did not use its native icon")
        assert(not output:find("not a vendor", 1, true), "printed a non-vendor source")
    end
end)

function methods:SetText(text) self.text = text end
BistooltipUtils.NormalizeItemID = function(id) return type(id)=="number" and id>0 and id or nil end
dofile("Bistooltip/DataProvider.lua")

test("data source text resolves icons without changing plain dedup identity", function()
    local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    BisTooltip_SourceRegistry = {
        RAID = {instance = "Ulduar", boss = "Hodir", difficulty = "25N"},
    }
    BisTooltip_ItemAcquisition = { [123] = {{
        kind = "TOKEN", source = "RAID", tier = "T8",
        family = "Wayward Vanquisher", tokenItem = 45634,
    }} }
    GetItemInfo = function(itemID)
        assert(itemID == 45634, "data provider requested the wrong TOKEN item")
        return "Token", nil, nil, nil, nil, nil, nil, nil, nil, texture
    end
    BistooltipData.ClearAllCaches()
    local sources = BistooltipData.GetAllItemSources(123)
    assert(#sources == 1 and sources[1].text:find("|T" .. texture .. ":14|t", 1, true),
        "data provider source text did not resolve the native TOKEN icon")
    assert(BisTooltip_FormatSource(BisTooltip_ItemAcquisition[123][1]) ==
        "T8 - TOKEN: Wayward Vanquisher [Ulduar: Hodir <25N>]",
        "icon lookup changed deterministic plain formatting")
    GetItemInfo = function() return nil end
end)

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
