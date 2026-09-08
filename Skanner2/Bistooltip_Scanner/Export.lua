-- Bistooltip_Scanner/Export.lua
local function SanitizeID(s)
  s = tostring(s or "VENDOR"):upper():gsub("[^A-Z0-9]+", "_"):gsub("^_+", ""):gsub("_+$", "")
  if s == "" then s = "VENDOR" end
  return s
end

local function EscapeComment(s)
  return tostring(s or "?"):gsub("[\r\n]", " ")
end

function BisScanner_BuildSnippet(vendor, opts)
  opts = opts or {}
  if not vendor or not vendor.items then return "-- empty vendor" end
  local lines = {}
  local vname = EscapeComment(vendor.vendor)
  local zone = EscapeComment(vendor.zone)
  local vnameQ = vname:gsub('"', "'")
  local zoneQ = zone:gsub('"', "'")
  local count = 0
  for _ in pairs(vendor.items) do count = count + 1 end
  table.insert(lines, "-- " .. vname .. " @ " .. zone .. " | " .. tostring(vendor.date or "?")
    .. " | " .. count .. " items | by Bistooltip_Scanner")
  if opts.custom then
    local cid = opts.customID or ("CUSTOM_" .. SanitizeID(vendor.vendor))
    table.insert(lines, 'BisTooltip:DefineSource("' .. cid .. '", { kind="CUSTOM", label="'
      .. vnameQ .. " (" .. zoneQ .. ')" })')
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
      table.insert(lines, "BisTooltip:SetAcquisition(" .. id .. ', { { kind="CUSTOM", label="'
        .. vnameQ .. " (" .. zoneQ .. ')" } }) -- ' .. iname .. extra)
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
      table.insert(lines, "BisTooltip:SetAcquisition(" .. id .. ", { { kind=\"VENDOR\", cost={ "
        .. table.concat(parts, ", ") .. " } } }) -- " .. iname .. extra)
    end
    if #lines > 500 then
      table.insert(lines, "-- truncated at 500 lines, full text in BistooltipScannerDB (WTF file)")
      break
    end
  end
  return table.concat(lines, "\n")
end

BisScanner_CustomMode = BisScanner_CustomMode or false

function BisScanner_ToggleCustom()
  BisScanner_CustomMode = not BisScanner_CustomMode
  return BisScanner_CustomMode
end

-- ---------------------------------------------------------------------------
-- UI styling: dark "black frame" look (matching Bistooltip export style).
-- Visual layer only — scan/snippet logic above stays untouched.
-- ---------------------------------------------------------------------------
local function ApplyDarkPanel(frame, alpha)
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame:SetBackdropColor(0, 0, 0, alpha or 0.85)
  frame:SetBackdropBorderColor(0, 0.80, 1.00, 0.55) -- teal accent border
end

local function StyleDarkButton(btn)
  btn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  btn:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
  btn:SetBackdropBorderColor(0, 0.80, 1.00, 0.55)
  btn:SetNormalFontObject("GameFontHighlight")
  btn:SetHighlightFontObject("GameFontNormal")
  local fs = btn:GetFontString()
  if fs then fs:SetTextColor(0.70, 0.88, 1.00, 1) end
  btn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.14, 0.16, 0.18, 0.95)
    self:SetBackdropBorderColor(0, 0.95, 1.00, 0.85)
  end)
  btn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    self:SetBackdropBorderColor(0, 0.80, 1.00, 0.55)
  end)
end

local function EnsureExportFrame()
  if _G.BisScannerExportFrame then return _G.BisScannerExportFrame end
  local frame = CreateFrame("Frame", "BisScannerExportFrame", UIParent)
  frame:SetSize(560, 460)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  ApplyDarkPanel(frame, 0.88)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", frame, "TOP", 0, -10)
  title:SetText("|cff00ccffBistooltip Scanner|r — export  (Ctrl+A, Ctrl+C)")
  title:SetJustifyH("CENTER")

  local sub = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
  sub:SetText("BisScanner_LastKey snippet — paste into your server plugin")

  local box = CreateFrame("EditBox", "BisScannerExportBox", frame)
  box:SetMultiLine(true)
  box:SetAutoFocus(false)
  box:SetFontObject(GameFontHighlightSmall)
  box:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -52)
  box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 46)
  box:SetTextInsets(8, 8, 8, 8)
  ApplyDarkPanel(box, 0.55)
  box:SetBackdropBorderColor(0, 0.80, 1.00, 0.25)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  frame._box = box

  local closeBtn = CreateFrame("Button", "BisScannerExportClose", frame)
  closeBtn:SetSize(96, 24)
  closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)
  closeBtn:SetText("Zamknij")
  StyleDarkButton(closeBtn)
  closeBtn:SetScript("OnClick", function() frame:Hide() end)

  -- exposes the existing BisScanner_CustomMode toggle (logic untouched)
  local customBtn = CreateFrame("Button", "BisScannerExportCustom", frame)
  customBtn:SetSize(150, 24)
  customBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 12)
  customBtn:SetText(BisScanner_CustomMode and "Tryb: CUSTOM" or "Tryb: VENDOR")
  StyleDarkButton(customBtn)
  customBtn:SetScript("OnClick", function(self)
    local on = BisScanner_ToggleCustom()
    self:SetText(on and "Tryb: CUSTOM" or "Tryb: VENDOR")
    if BisScanner_LastKey and type(BisScanner_ShowExport) == "function" then
      BisScanner_ShowExport(BisScanner_LastKey)
    end
  end)

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

function BisScanner_CreateMerchantButton()
  if _G.BisScannerMerchantButton then return _G.BisScannerMerchantButton end
  if type(MerchantFrame) ~= "table" then return nil end
  local btn = CreateFrame("Button", "BisScannerMerchantButton", MerchantFrame)
  btn:SetSize(95, 22)
  btn:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -40, -30)
  btn:SetText("Bis Scan")
  StyleDarkButton(btn)
  btn:SetScript("OnClick", function()
    local key, count = BisScanner_ScanVendor()
    if key then
      if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r scanned " .. tostring(count)
          .. " items: " .. tostring(key))
      end
      if type(BisScanner_ShowExport) == "function" then BisScanner_ShowExport(key) end
    end
  end)
  return btn
end
