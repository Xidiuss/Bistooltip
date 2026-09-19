-- Run from the scanner worktree: lua5.1 .github/tests/lua/scanner_regression.lua
local failures = 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then print("PASS " .. name)
  else failures = failures + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end

dofile("Bistooltip_Scanner/Scanner.lua")
dofile("Bistooltip_Scanner/Export.lua")
Bistooltip_Scanner_ExportMode = "replace_all" -- existing fixtures exercise legacy output

test("export modes keep purchase route semantics explicit", function()
  BistooltipScannerDB = { test = {vendor="Vendor",zone="Zone",items={
    [123]={name="Sword",money=0,costs={{currName="Justice",amount=700}}}
  }} }
  Bistooltip_Scanner_ExportMode = "append"
  assert(Bistooltip_Scanner_BuildSnippet("test"):find("BisTooltip:AddAcquisition(123",1,true))
  Bistooltip_Scanner_ExportMode = "replace_vendor"
  assert(Bistooltip_Scanner_BuildSnippet("test"):find("BisTooltip:ReplaceVendorAcquisitions(123",1,true))
  Bistooltip_Scanner_ExportMode = "replace_all"
  assert(Bistooltip_Scanner_BuildSnippet("test"):find("BisTooltip:SetAcquisition(123",1,true))
end)

test("append mode exports both merchants selling the same item", function()
  BistooltipScannerDB = {_log={"A","B"},
    A={vendor="A",zone="Z",items={[123]={name="Sword",costs={{currName="Justice",amount=700}}}}},
    B={vendor="B",zone="Z",items={[123]={name="Sword",costs={{currName="Ascension",amount=20}}}}}}
  Bistooltip_Scanner_ExportMode = "append"
  local text = Bistooltip_Scanner_ExportText()
  local count = 0
  for _ in text:gmatch("BisTooltip:AddAcquisition%(123") do count = count + 1 end
  assert(count == 2, "append mode discarded a second merchant offer")
  Bistooltip_Scanner_ExportMode = "replace_all"
end)
Bistooltip_Scanner_ExportMode = "replace_all"

-- A merchant slot with a late link must become one item, not two records.
test("page rescan resolves positional placeholder", function()
  BistooltipScannerDB = {}
  UnitName = function() return "Vendor" end
  GetZoneText = function() return "Zone" end
  GetMerchantNumItems = function() return 1 end
  GetMerchantItemInfo = function() return "Sword", "texture", 100, 1, -1, true, false end
  GetMerchantItemLink = function() return nil end
  Bistooltip_Scanner_ScanPage()
  GetMerchantItemLink = function() return "item:123" end
  Bistooltip_Scanner_ScanPage()
  local rec = BistooltipScannerDB["Vendor @ Zone"]
  assert(rec.count == 1, "resolved slot counted twice")
  assert(rec.items[123] and not rec.items["pending:1"], "placeholder survived resolution")
  assert(not Bistooltip_Scanner_BuildSnippet("Vendor @ Zone"):find("TODO rescan", 1, true))
end)

test("CSV keeps money in sixth column without item costs", function()
  BistooltipScannerDB = { manual = { items = { [123] = { name = "Sword", money = 12345, costs = {} } } } }
  assert(Bistooltip_Scanner_BuildCSV("manual") ==
    "itemID;name;currency;amount;currID;money\n123;Sword;;;;12345", "money shifted into currID column")
end)

test("late cache fills export names without losing manually assigned cost", function()
  BistooltipScannerDB = {}
  GetItemInfo = function() return nil end
  Bistooltip_Scanner_ScanByID(123)
  Bistooltip_Scanner_SetCost(456, 7)
  GetItemInfo = function(id)
    if id == 123 then return 'Sword "quoted"', "item:123" end
    if id == 456 then return "Custom Mark", "item:456" end
  end
  local snippet = Bistooltip_Scanner_ExportItem("manual", 123)
  assert(snippet:find("Custom Mark", 1, true), "currency name remained uncached")
  assert(not snippet:find("UNCACHED", 1, true), "resolved cache still marked uncached")
  local captured
  BisTooltip = { SetAcquisition = function(_, id, entries) captured = entries[1] end }
  assert((loadstring or load)(snippet))()
  assert(captured.cost[1].amount == 7 and captured.cost[1].currency == "Custom Mark")
  assert(BistooltipScannerDB.manual.items[123].name == 'Sword "quoted"')
end)

test("CSV refreshes late currency cache independently", function()
  BistooltipScannerDB = { manual = { items = {
    [123] = { name = "?", uncached = true, money = 0, costs = { { currID = 456, amount = 7 } } }
  } } }
  GetItemInfo = function(id)
    if id == 123 then return "Sword", "item:123" end
    if id == 456 then return "Custom Mark", "item:456" end
  end
  assert(Bistooltip_Scanner_BuildCSV("manual"):find("123;Sword;Custom Mark;7;456;0", 1, true),
    "CSV kept stale names")
end)

-- Stock 3.3.5 FrameXML consumes honorPoints, arenaPoints, itemCount.
-- A token-only price therefore has ZERO in the first return position.
test("stock token-only price uses the third cost-info return", function()
  BistooltipScannerDB = {}
  UnitName = function() return "V" end
  GetZoneText = function() return "Z" end
  GetMerchantNumItems = function() return 1 end
  GetMerchantItemInfo = function() return "Sword", "tex", 0, 1, -1, true, true end
  GetMerchantItemLink = function() return "item:123" end
  GetMerchantItemCostInfo = function() return 0, 0, 1 end
  GetMerchantItemCostItem = function() return "tex", 7, "item:456" end
  GetItemInfo = function(id) return id == 456 and "Token" or "Sword" end
  Bistooltip_Scanner_ScanVendor()
  local it = BistooltipScannerDB["V @ Z"].items[123]
  assert(#it.costs == 1 and it.costs[1].currID == 456 and it.costs[1].amount == 7,
    "stock token price lost")
end)

test("stock honor and arena prices survive alongside item costs", function()
  BistooltipScannerDB = {}
  GetMerchantItemCostInfo = function() return 1650, 375, 1 end
  GetMerchantItemCostItem = function() return "tex", 2, "item:456" end
  Bistooltip_Scanner_ScanVendor()
  local text = Bistooltip_Scanner_BuildSnippet("V @ Z")
  local costs
  BisTooltip = { SetAcquisition = function(_, _, entries) costs = entries[1].cost end }
  assert((loadstring or load)(text))()
  local prices = {}
  for _, cost in ipairs(costs) do prices[cost.currency] = cost.amount end
  assert(prices["Honor Points"] == 1650, "Honor Points treated as row count")
  assert(prices["Arena Points"] == 375, "Arena Points lost")
  assert(prices.Token == 2, "item payment lost from compound price")
  assert(not text:find("UNCACHED", 1, true), "point currencies require no item cache")
  local validation = Bistooltip_Scanner_ValidateKey("V @ Z")
  assert(validation.emptyN == 0 and validation.nonameN == 0 and validation.badN == 0)
end)

test("stock honor-only price never queries token rows", function()
  BistooltipScannerDB = {}
  GetMerchantItemCostInfo = function() return 1650, 0, 0 end
  local calls = 0
  GetMerchantItemCostItem = function() calls = calls + 1; return nil end
  Bistooltip_Scanner_ScanVendor()
  local it = BistooltipScannerDB["V @ Z"].items[123]
  assert(#it.costs == 1 and it.costs[1].currName == "Honor Points" and it.costs[1].amount == 1650,
    "Honor-only price lost")
  assert(calls == 0, "Honor used as token loop bound")
end)

-- A count-only server API can still return a malformed row count. This
-- fixture deliberately has ONE return, unlike the stock honor price above.
test("bogus cost count yields no junk cost rows", function()
  BistooltipScannerDB = {}
  UnitName = function() return "V" end
  GetZoneText = function() return "Z" end
  GetMerchantNumItems = function() return 1 end
  GetMerchantItemInfo = function() return "Badge", "tex", 0, 1, -1, true, false end
  GetMerchantItemLink = function() return "item:43950" end
  GetItemInfo = function() return nil end
  GetMerchantItemCostInfo = function() return 1650 end
  GetMerchantItemCostItem = function() return nil, nil, nil end
  Bistooltip_Scanner_ScanVendor()
  local it = BistooltipScannerDB["V @ Z"].items[43950]
  assert(it and #it.costs == 0, "junk cost rows saved")
  assert(it.nCost == 1650, "raw nCost diagnostic lost")
  local v = Bistooltip_Scanner_ValidateKey("V @ Z")
  assert(v.emptyN == 1 and v.nonameN == 0, "bogus-cost item not flagged empty")
  local text = Bistooltip_Scanner_BuildSnippet("V @ Z")
  assert(not text:find('currency = "?"', 1, true), "junk currency rendered")
  assert(text:find("nCost=1650", 1, true), "EMPTY-COST diagnostic missing")
end)

-- Wariant smieciowego licznika: kazdy wiersz zwraca ten sam link - petla
-- i tak musi sie zatrzymac na capie, zamiast zapisac 1650 duplikatow.
test("cost rows are capped when the count is garbage", function()
  BistooltipScannerDB = {}
  UnitName = function() return "V" end
  GetZoneText = function() return "Z" end
  GetMerchantNumItems = function() return 1 end
  GetMerchantItemInfo = function() return "Sword", "tex", 0, 1, -1, true, false end
  GetMerchantItemLink = function() return "item:40786" end
  GetItemInfo = function() return nil end
  GetMerchantItemCostInfo = function() return 1650 end
  GetMerchantItemCostItem = function() return "tex", 700, "item:1234" end
  Bistooltip_Scanner_ScanVendor()
  local it = BistooltipScannerDB["V @ Z"].items[40786]
  assert(it and #it.costs == 8, "cost rows not capped at 8")
  assert(it.nCost == 1650, "raw nCost diagnostic lost")
end)

-- Rekordy zapisane przed utwardzeniem (wiersze bez ID i nazwy) pozostaja
-- w SV: eksport Lua i CSV je filtruje zamiast renderowac currency = "?".
test("legacy junk cost rows are filtered from export", function()
  BistooltipScannerDB = { ["V @ Z"] = { vendor = "V", zone = "Z", date = "d",
    items = { [123] = { name = "Badge", money = 0, qty = 1,
      costs = { { currID = nil, currName = nil, amount = nil },
        { currID = nil, currName = nil, amount = nil } },
      nCost = 1650, ext = true } } } }
  GetItemInfo = function() return nil end
  local v = Bistooltip_Scanner_ValidateKey("V @ Z")
  assert(v.emptyN == 1 and v.nonameN == 0, "legacy junk not flagged empty")
  local text = Bistooltip_Scanner_BuildSnippet("V @ Z")
  assert(not text:find('currency = "?"', 1, true), "junk currency rendered")
  assert(text:find("cost = {  }", 1, true), "empty cost table not rendered")
  assert(text:find("nCost=1650", 1, true), "EMPTY-COST diagnostic missing")
  assert(not text:find("UNCACHED", 1, true), "junk rows force UNCACHED")
  assert(Bistooltip_Scanner_BuildCSV("V @ Z"):find("123;Badge;;;;0", 1, true),
    "CSV kept junk rows")
end)

if failures > 0 then error(failures .. " scanner regression(s) failed") end
print("scanner regressions passed")
