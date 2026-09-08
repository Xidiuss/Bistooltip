-- Bistooltip_Scanner/Export.lua — snippet builder + export window.
-- Pure builder (no WoW API needed for BuildSnippet -> mock-testable).

local function SanitizeID(s)
    s = tostring(s or "VENDOR"):upper():gsub("[^A-Z0-9]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if s == "" then s = "VENDOR" end
    return s
end

local function EscapeComment(s)
    return tostring(s or "?"):gsub("[\r\n]", " ")
end

-- Canonical cost units (spec S2-5): Gold amounts are COPPER (as returned
-- by GetMerchantItemInfo); the Bistooltip formatter renders Gold as g/s/c.
function BisScanner_BuildSnippet(vendor, opts)
    opts = opts or {}
    if not vendor or not vendor.items then return "-- empty vendor" end
    local lines = {}
    local vname = EscapeComment(vendor.vendor)
    local zone = EscapeComment(vendor.zone)
    local count = 0
    for _ in pairs(vendor.items) do count = count + 1 end
    table.insert(lines, "-- " .. vname .. " @ " .. zone .. " | " .. tostring(vendor.date or "?")
        .. " | " .. count .. " items | by Bistooltip_Scanner")
    if opts.custom then
        local cid = opts.customID or ("CUSTOM_" .. SanitizeID(vendor.vendor))
        table.insert(lines, 'BisTooltip:DefineSource("' .. cid .. '", { kind = "CUSTOM", label = "'
            .. vname .. " (" .. zone .. ')" })')
    end
    local ids = {}
    for id in pairs(vendor.items) do table.insert(ids, id) end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local row = vendor.items[id]
        local iname = EscapeComment(row.name)
        local extra = ""
        if row.qty and row.qty > 1 then extra = extra .. " x" .. row.qty end
        if row.limited then extra = extra .. " limited:" .. row.limited end
        if row.uncached then extra = extra .. " UNCACHED" end
        if opts.custom then
            local cid = opts.customID or ("CUSTOM_" .. SanitizeID(vendor.vendor))
            table.insert(lines, "BisTooltip:SetAcquisition(" .. id .. ', { { kind = "CUSTOM", label = "'
                .. vname .. " (" .. zone .. ')" } }) -- ' .. iname .. extra)
        else
            local parts = {}
            if row.money and row.money > 0 then
                table.insert(parts, '{currency="Gold", amount=' .. row.money .. "}")
            end
            for _, c in ipairs(row.costs or {}) do
                local label = EscapeComment(c.currName or ("item:" .. tostring(c.currID or "?")))
                local seg = '{currency="' .. label:gsub('"', "'") .. '", amount=' .. (c.amount or 0) .. "}"
                if c.currID then seg = seg .. " -- item:" .. c.currID end
                table.insert(parts, seg)
            end
            if #parts == 0 then
                table.insert(parts, '{currency="Gold", amount=0} -- no cost API')
            end
            table.insert(lines, "BisTooltip:SetAcquisition(" .. id .. ', { { kind = "VENDOR", cost={ '
                .. table.concat(parts, ", ") .. " } } }) -- " .. iname .. extra)
        end
        if #lines > 600 then
            table.insert(lines, "-- truncated in chat preview, full text in BistooltipScannerDB")
            break
        end
    end
    return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------------
-- UI (in-game only; every CreateFrame call guarded for mock runs)
-- ---------------------------------------------------------------------------

BisScanner_CustomMode = BisScanner_CustomMode or false

function BisScanner_ToggleCustom()
    BisScanner_CustomMode = not BisScanner_CustomMode
    return BisScanner_CustomMode
end

local function EnsureExportFrame()
    if _G.BisScannerExportFrame then return _G.BisScannerExportFrame end
    if type(CreateFrame) ~= "function" or not UIParent then return nil end
    local frame = CreateFrame("Frame", "BisScannerExportFrame", UIParent)
    frame:SetSize(560, 460)
    frame:SetPoint("CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.85)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -8)
    title:SetText("Bistooltip Scanner — export (Ctrl+A, Ctrl+C)")
    local box = CreateFrame("EditBox", "BisScannerExportBox", frame)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetPoint("TOPLEFT", 12, -30)
    box:SetPoint("BOTTOMRIGHT", -12, 40)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local closeBtn = CreateFrame("Button", "BisScannerExportClose", frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(90, 22)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText("Zamknij")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    local customBtn = CreateFrame("Button", "BisScannerExportCustom", frame, "UIPanelButtonTemplate")
    customBtn:SetSize(150, 22)
    customBtn:SetPoint("BOTTOMLEFT", 12, 10)
    customBtn:SetText("Tryb: VENDOR")
    customBtn:SetScript("OnClick", function(self)
        local on = BisScanner_ToggleCustom()
        self:SetText(on and "Tryb: CUSTOM" or "Tryb: VENDOR")
        if BisScanner_LastKey then BisScanner_ShowExport(BisScanner_LastKey) end
    end)
    frame._box = box
    return frame
end

BisScanner_LastKey = nil

function BisScanner_ShowExport(vendorKey)
    local vendor = BistooltipScannerDB
        and BistooltipScannerDB.vendors
        and BistooltipScannerDB.vendors[vendorKey]
    local text = BisScanner_BuildSnippet(vendor, { custom = BisScanner_CustomMode })
    BisScanner_LastKey = vendorKey
    if type(CreateFrame) == "function" and UIParent then
        local frame = EnsureExportFrame()
        if frame and frame._box then
            frame._box:SetText(text)
            frame._box:HighlightText()
            frame:Show()
        end
    end
    return text
end

function BisScanner_ShowText(text)
    if type(CreateFrame) == "function" and UIParent then
        local frame = EnsureExportFrame()
        if frame and frame._box then
            frame._box:SetText(text)
            frame:Show()
        end
    end
    return text
end

function BisScanner_CreateMerchantButton()
    if _G.BisScannerMerchantButton then return _G.BisScannerMerchantButton end
    if type(CreateFrame) ~= "function" or type(MerchantFrame) ~= "table" then return nil end
    local btn = CreateFrame("Button", "BisScannerMerchantButton", MerchantFrame, "UIPanelButtonTemplate")
    btn:SetSize(95, 22)
    btn:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -40, -30)
    btn:SetText("Bis Scan")
    btn:SetScript("OnClick", function()
        local key, count = BisScanner_ScanVendor()
        if key then BisScanner_ShowExport(key) end
    end)
    return btn
end
-- Button creation is triggered from MERCHANT_SHOW (Scanner.lua), not via
-- hooksecurefunc — fewer load-order assumptions, mock-safe.
