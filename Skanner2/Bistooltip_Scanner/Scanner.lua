-- Bistooltip_Scanner/Scanner.lua
BisScanner = BisScanner or {}
BistooltipScannerDB = BistooltipScannerDB or { vendors = {} }
if not BistooltipScannerDB.vendors then BistooltipScannerDB.vendors = {} end

function BisScanner_ParseItemID(link)
  if type(link) ~= "string" then return nil end
  local id = link:match("item:(%d+)")
  if id then return tonumber(id) end
  return nil
end

function BisScanner_VendorKey(name, zone)
  name = name or "Unknown Vendor"
  zone = zone or "Unknown Zone"
  return tostring(name) .. " @ " .. tostring(zone)
end

function BisScanner_ScanVendor()
  if type(GetMerchantNumItems) ~= "function" then return nil, "no vendor" end
  local num = GetMerchantNumItems()
  if not num or num == 0 then return nil, "no vendor open" end
  local vendorName = (type(UnitName) == "function" and UnitName("target")) or "Unknown Vendor"
  local zone = (type(GetZoneText) == "function" and GetZoneText()) or "Unknown Zone"
  local key = BisScanner_VendorKey(vendorName, zone)
  local today = (type(date) == "function" and date("%Y-%m-%d")) or (type(os) == "table" and type(os.date) == "function" and os.date("%Y-%m-%d")) or "?"
  local vendor = { vendor = vendorName, zone = zone, date = today, items = {} }
  local scanned = 0
  if type(GetMerchantItemInfo) ~= "function" then return nil, "no merchant API" end
  for i = 1, num do
    local name, _, price, qty, avail, _, ext = GetMerchantItemInfo(i)
    local link = (type(GetMerchantItemLink) == "function" and GetMerchantItemLink(i)) or nil
    local id = BisScanner_ParseItemID(link)
    if id then
      local row = { name = name or ("item:" .. id), money = price or 0,
        qty = qty or 1, limited = (avail and avail >= 0) and avail or nil, costs = {} }
      if ext and type(GetMerchantItemCostInfo) == "function"
        and type(GetMerchantItemCostItem) == "function" then
        local n = GetMerchantItemCostInfo(i) or 0
        for c = 1, n do
          local _, amount, clink = GetMerchantItemCostItem(i, c)
          local cid = BisScanner_ParseItemID(clink)
          local cname = nil
          if cid and type(GetItemInfo) == "function" then cname = GetItemInfo(cid) end
          table.insert(row.costs, { currID = cid, currName = cname, amount = amount or 0 })
        end
      end
      if row.money == 0 and #row.costs == 0 and ext then row.uncached = true end
      vendor.items[id] = row
      scanned = scanned + 1
    else
      vendor.uncachedCount = (vendor.uncachedCount or 0) + 1
    end
  end
  BistooltipScannerDB.vendors[key] = vendor
  return key, scanned
end

local eventFrame = CreateFrame("Frame", "BisScannerEventFrame", UIParent)
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event)
  if event == "MERCHANT_SHOW" then
    if type(BisScanner_CreateMerchantButton) == "function" then
      BisScanner_CreateMerchantButton()
    end
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r open vendor, use /bis scan")
    end
  elseif event == "MERCHANT_CLOSED" then
    if _G.BisScannerExportFrame and type(_G.BisScannerExportFrame.Hide) == "function" then _G.BisScannerExportFrame:Hide() end
  end
end)

SLASH_BISSCAN1 = "/bis"
SLASH_BISSCAN2 = "/bisscan"
SlashCmdList["BISSCAN"] = function(msg)
  msg = tostring(msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" or msg == "scan" then
    local key, res = BisScanner_ScanVendor()
    if key then
      if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r scanned " .. tostring(res)
          .. " items: " .. tostring(key))
      end
      if type(BisScanner_ShowExport) == "function" then BisScanner_ShowExport(key) end
    elseif DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000BisScanner:|r " .. tostring(res))
    end
  else
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r usage: /bis scan") end
  end
end
