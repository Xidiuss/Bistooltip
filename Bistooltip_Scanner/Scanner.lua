-- Bistooltip_Scanner/Scanner.lua — vendor scan -> SavedVariables.
-- Standalone (works without Bistooltip); never writes core tables.
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

-- Read-only walk over the merchant API; every call guarded so weird
-- private-server APIs degrade to "-- no cost API" instead of erroring.
function BisScanner_ScanVendor()
    if type(GetMerchantNumItems) ~= "function" then return nil, "no vendor" end
    local num = GetMerchantNumItems()
    if not num or num == 0 then return nil, "no vendor open" end
    local vendorName = (type(UnitName) == "function" and UnitName("target")) or "Unknown Vendor"
    local zone = (type(GetZoneText) == "function" and GetZoneText()) or "Unknown Zone"
    local key = BisScanner_VendorKey(vendorName, zone)
    local vendor = { vendor = vendorName, zone = zone, date = date("%Y-%m-%d"), items = {} }
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
        else
            vendor.uncachedCount = (vendor.uncachedCount or 0) + 1
        end
    end
    BistooltipScannerDB.vendors[key] = vendor
    return key, (function() local n = 0 for _ in pairs(vendor.items) do n = n + 1 end return n end)()
end

-- /bis item <ID>: one-item skeleton (W7 extension). Prints a snippet
-- with the cached name (or -- UNCACHED) for later completion.
function BisScanner_ItemSnippet(id)
    id = tonumber(id)
    if not id or id <= 0 then return nil, "usage: /bis item <itemID>" end
    local name = (type(GetItemInfo) == "function" and GetItemInfo(id)) or nil
    local nameComment = name or "UNCACHED"
    local lines = {
        "-- item " .. id .. " (" .. nameComment .. ") by Bistooltip_Scanner",
        "-- pick ONE acquisition shape, then delete the rest:",
        'BisTooltip:AddAcquisition(' .. id .. ', { { kind = "CUSTOM", label = "Vendor (Zone)" } })',
        'BisTooltip:AddAcquisition(' .. id .. ', { { kind = "DROP", source = "INSTANCE_DIFF_BOSS" } })',
        'BisTooltip:AddAcquisition(' .. id .. ', { { kind = "VENDOR", cost = { { currency = "Nazwa", amount = 1 } } } })',
    }
    if not name then
        table.insert(lines, 2, "-- item not in cache: hover it in game first, then rescan")
    end
    return table.concat(lines, "\n")
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
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r vendor open — /bis scan (button on MerchantFrame)")
        end
    end
end)

SLASH_BISSCAN1 = "/bis scan"
SlashCmdList["BISSCAN"] = function(msg)
    local key, res = BisScanner_ScanVendor()
    if key then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r scanned " .. tostring(res) .. " items: " .. key)
        end
        if type(BisScanner_ShowExport) == "function" then BisScanner_ShowExport(key) end
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000BisScanner:|r " .. tostring(res))
    end
end

SLASH_BISITEM1 = "/bis item"
SlashCmdList["BISITEM"] = function(msg)
    local snippet, err = BisScanner_ItemSnippet((msg or ""):match("(%d+)"))
    if DEFAULT_CHAT_FRAME then
        if snippet then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r snippet below / in export window")
            for line in snippet:gmatch("[^\n]+") do
                DEFAULT_CHAT_FRAME:AddMessage("|cFFaaaaaa" .. line .. "|r")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000BisScanner:|r " .. tostring(err))
        end
    end
    if snippet and type(BisScanner_ShowText) == "function" then BisScanner_ShowText(snippet) end
end
