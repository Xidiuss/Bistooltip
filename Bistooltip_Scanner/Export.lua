-- Bistooltip_Scanner/Export.lua
-- S3 snippet builder (frozen scanner spec S2) + copy-window data path.
-- VENDOR by default; CUSTOM lines only when the custom toggle is set
-- (donate-shop checkbox, off by default). One line builder serves both
-- full-vendor export and single-item (by-ID) export.
-- Lua 5.1, Interface 30300. Frame code is guarded for headless use.

-- Custom toggle backing the export-window checkbox. Default off (VENDOR).
Bistooltip_Scanner_UseCustom = Bistooltip_Scanner_UseCustom or false

-- Max lines shown in the copy window; full text always stays in SV.
Bistooltip_Scanner_MaxWindowLines = Bistooltip_Scanner_MaxWindowLines or 500

-- Quote a value for embedding in a double-quoted Lua string literal.
local function esc(s)
  s = tostring(s or "?")
  s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("[\r\n]+", " ")
  return s
end

-- Trailing comments are free text: only newlines must go.
local function safeComment(s)
  return tostring(s or "?"):gsub("[\r\n]+", " ")
end

local function sourceIDFor(vendor)
  local s = "CUSTOM_" .. tostring(vendor or "UNKNOWN"):upper()
  return (s:gsub("[^A-Z0-9_]", "_"))
end

local function labelFor(vendor, zone)
  if zone ~= nil and zone ~= "" then
    return tostring(vendor) .. " (" .. tostring(zone) .. ")"
  end
  return tostring(vendor)
end

-- NOTE on the frozen spec's S2 example: it shows the currency item ID as
-- an inline `-- item:CurrID` comment *inside* the cost table, before the
-- closing braces. Taken literally that comments out the line's own
-- closers, so the line would not be luac-clean. The builder therefore
-- carries the same information in the trailing comment
-- (`-- <name> ... -- item:<currID>`), which keeps every spec-required
-- field (name, stack/limited, currency item IDs, UNCACHED, no-cost-API)
-- while staying luac-clean S3.
local function buildItemLine(itemID, item, custom, label)
  local head
  if custom then
    head = "BisTooltip:SetAcquisition(" .. itemID
      .. ', { { kind = "CUSTOM", label = "' .. esc(label) .. '" } })'
  else
    local cost = {}
    if (item.money or 0) > 0 then
      cost[#cost + 1] = '{ currency = "Gold", amount = ' .. item.money .. " }"
    end
    for _, c in ipairs(item.costs or {}) do
      -- ID zawsze widoczne: bez cache GetItemInfo nazwa jest nil,
      -- wtedy w pole currency wchodzi item:ID zamiast "?".
      local curLabel = c.currName
      if curLabel == nil and c.currID ~= nil then curLabel = "item:" .. tostring(c.currID) end
      cost[#cost + 1] = '{ currency = "' .. esc(curLabel)
        .. '", amount = ' .. tostring(c.amount or 0) .. " }"
    end
    head = "BisTooltip:SetAcquisition(" .. itemID
      .. ', { { kind = "VENDOR", cost = { ' .. table.concat(cost, ", ") .. " } } })"
  end
  local tail = " -- " .. safeComment(item.name)
  if (item.qty or 1) > 1 then tail = tail .. " x" .. item.qty end
  if item.limited ~= nil then tail = tail .. ", limited:" .. item.limited end
  if not custom then
    for _, c in ipairs(item.costs or {}) do
      if c.currID ~= nil then tail = tail .. " -- item:" .. c.currID end
    end
  end
  if item.uncached then tail = tail .. " -- UNCACHED" end
  if item.noCostAPI then tail = tail .. " -- no cost API" end
  if not custom and (item.money or 0) == 0 and #(item.costs or {}) == 0 then
    -- Pusty koszt: przyczyna wprost w linii, bez /script.
    -- Manual by-ID z zasady nie zna ceny (brak kontekstu vendora).
    tail = tail .. " -- EMPTY-COST ext=" .. tostring(item.ext) .. " nCost=" .. tostring(item.nCost)
    if type(item.tip) == "table" and #item.tip > 0 then
      local t = table.concat(item.tip, " | ")
      if #t > 220 then t = t:sub(1, 220) .. "..." end
      tail = tail .. " -- TIP: " .. safeComment(t)
    end
  end
  return head .. tail
end

-- Sorted item keys: merchant-index order (spec S2), index-less entries
-- (manual by-ID) last, ties broken by key for determinism.
local function sortedKeys(items)
  local keys = {}
  for k in pairs(items) do keys[#keys + 1] = k end
  local function order(k)
    local e = items[k]
    if type(e) == "table" and type(e.index) == "number" then return e.index end
    return 1e9
  end
  table.sort(keys, function(a, b)
    local oa, ob = order(a), order(b)
    if oa ~= ob then return oa < ob end
    return tostring(a) < tostring(b)
  end)
  return keys
end

-- DEDUPE (log/export): ten sam itemID u kilku vendorow eksportuje sie RAZ.
-- Zwyciezca = OSTATNI klucz na liscie (najswiezszy wpis w logu — zgodne
-- z semantyka wklejania, gdzie pozniejsze SetAcquisition nadpisuje).
-- Zwraca mape winner[itemID] = vendorKey (tylko ID numeryczne).
function Bistooltip_Scanner_DedupeWinners(keys)
  local winner = {}
  local db = BistooltipScannerDB
  if type(keys) ~= "table" then return winner end
  for _, key in ipairs(keys) do
    local rec = (type(db) == "table") and db[key] or nil
    if type(rec) == "table" and type(rec.items) == "table" then
      for id in pairs(rec.items) do
        if type(id) == "number" then winner[id] = key end
      end
    end
  end
  return winner
end

-- Zestaw ID do pominiecia w danym vendorze (te, ktore wygrywa inny klucz).
-- Zwraca set albo nil (nil = brak kolizji, sciezka bez zmian).
function Bistooltip_Scanner_SkipForKey(key, winner)
  if type(winner) ~= "table" then return nil end
  local db = BistooltipScannerDB
  local rec = (type(db) == "table") and db[key] or nil
  if type(rec) ~= "table" or type(rec.items) ~= "table" then return nil end
  local skip = nil
  for id, wkey in pairs(winner) do
    if wkey ~= key and rec.items[id] ~= nil then
      skip = skip or {}
      skip[id] = true
    end
  end
  return skip
end

local function buildSnippet(vendorKey, onlyItemID, skipIDs)
  local db = BistooltipScannerDB
  local rec = (type(db) == "table") and db[vendorKey] or nil
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    return "-- Bistooltip_Scanner: no data for " .. tostring(vendorKey)
  end
  local custom = (Bistooltip_Scanner_UseCustom == true)
  local label = labelFor(rec.vendor, rec.zone)
  local lines = {}
  local skipped = {}
  local count = 0
  for _ in pairs(rec.items) do count = count + 1 end
  if onlyItemID ~= nil then count = 1 end
  if onlyItemID ~= nil then
    local item = rec.items[onlyItemID]
    if type(item) ~= "table" then
      return "-- Bistooltip_Scanner: no data for item " .. tostring(onlyItemID)
    end
    if skipIDs and skipIDs[onlyItemID] then
      skipped[#skipped + 1] = onlyItemID
      return "-- Bistooltip_Scanner: item " .. tostring(onlyItemID)
        .. " skipped (DEDUPE, kept by another vendor)", skipped
    end
    lines[#lines + 1] = "-- " .. safeComment(rec.vendor) .. " / " .. safeComment(rec.zone)
      .. " / " .. safeComment(rec.date) .. " / " .. count
      .. " by Bistooltip_Scanner"
    if custom then
      lines[#lines + 1] = 'BisTooltip:DefineSource("' .. sourceIDFor(rec.vendor)
        .. '", { kind = "CUSTOM", label = "' .. esc(label) .. '" })'
    end
    lines[#lines + 1] = buildItemLine(onlyItemID, item, custom, label)
  else
    local emitted = 0
    local body = {}
    for _, k in ipairs(sortedKeys(rec.items)) do
      if type(k) == "number" then
        if skipIDs and skipIDs[k] then
          skipped[#skipped + 1] = k
        else
          body[#body + 1] = buildItemLine(k, rec.items[k], custom, label)
          emitted = emitted + 1
        end
      else
        -- Positional placeholder (uncached slot without a link yet):
        -- not emittable as S3, kept as a to-do comment.
        local item = rec.items[k]
        local nm = (type(item) == "table") and item.name or "?"
        body[#body + 1] = "-- TODO rescan (no link in cache): " .. safeComment(nm)
      end
    end
    if skipIDs then count = emitted end
    lines[#lines + 1] = "-- " .. safeComment(rec.vendor) .. " / " .. safeComment(rec.zone)
      .. " / " .. safeComment(rec.date) .. " / " .. count
      .. " by Bistooltip_Scanner"
    if custom then
      lines[#lines + 1] = 'BisTooltip:DefineSource("' .. sourceIDFor(rec.vendor)
        .. '", { kind = "CUSTOM", label = "' .. esc(label) .. '" })'
    end
    for _, l in ipairs(body) do lines[#lines + 1] = l end
  end
  return table.concat(lines, "\n"), skipped
end

-- Full-vendor snippet for a vendor key ("Vendor @ Zone").
-- skipIDs (opcjonalny set): ID wygrane przez innego vendora (DEDUPE).
function Bistooltip_Scanner_BuildSnippet(vendorKey, skipIDs)
  return buildSnippet(vendorKey, nil, skipIDs)
end

-- Single-item snippet for a by-ID scan. Same line builder, same toggle.
function Bistooltip_Scanner_ExportItem(vendorKey, itemID)
  return buildSnippet(vendorKey, tonumber(itemID))
end

-- CSV obok S3: itemID;name;currency;amount;currID;money (do arkusza/DB).
-- Puste koszty = wiersz z pustymi polami waluty. Lua 5.1, bez UI.
-- skipIDs (opcjonalny set): ID wygrane przez innego vendora (DEDUPE).
function Bistooltip_Scanner_BuildCSV(vendorKey, skipIDs)
  local db = BistooltipScannerDB
  local rec = (type(db) == "table") and db[vendorKey] or nil
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    return "-- Bistooltip_Scanner: no data for " .. tostring(vendorKey)
  end
  local function cell(s)
    return tostring(s or ""):gsub("[;\r\n]+", " ")
  end
  local lines = { "itemID;name;currency;amount;currID;money" }
  local ids = {}
  for k in pairs(rec.items) do
    if type(k) == "number" and not (skipIDs and skipIDs[k]) then ids[#ids + 1] = k end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local item = rec.items[id]
    if type(item) == "table" then
      if #(item.costs or {}) == 0 then
        lines[#lines + 1] = id .. ";" .. cell(item.name) .. ";;;"
          .. tostring(item.money or 0)
      else
        for _, c in ipairs(item.costs) do
          local label = c.currName
          if label == nil and c.currID ~= nil then label = "item:" .. c.currID end
          lines[#lines + 1] = id .. ";" .. cell(item.name) .. ";" .. cell(label)
            .. ";" .. tostring(c.amount or 0) .. ";" .. tostring(c.currID or "")
            .. ";" .. tostring(item.money or 0)
        end
      end
    end
  end
  return table.concat(lines, "\n")
end

-- Copy-window data path: Frame + ScrollFrame + EditBox (select-all,
-- Ctrl+C), Scan / Copy / Close buttons. Headless-safe: without
-- CreateFrame the text is only stored (caller keeps it in SV).
local exportFrame = nil

-- Dark "black frame" look (stylizacja z folderu "scanner wygląd").
-- Wylacznie warstwa wizualna: logika S3/CSV/snippet ponizej nietknieta.
local function bsApplyDarkPanel(frame, alpha)
  if type(frame) ~= "table" or type(frame.SetBackdrop) ~= "function" then return end
  pcall(frame.SetBackdrop, frame, {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  if type(frame.SetBackdropColor) == "function" then
    pcall(frame.SetBackdropColor, frame, 0, 0, 0, alpha or 0.88)
  end
  if type(frame.SetBackdropBorderColor) == "function" then
    pcall(frame.SetBackdropBorderColor, frame, 0, 0.80, 1.00, 0.55)
  end
end

local function bsStyleDarkButton(btn)
  if type(btn) ~= "table" or type(btn.SetBackdrop) ~= "function" then return end
  pcall(btn.SetBackdrop, btn, {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  if type(btn.SetBackdropColor) == "function" then
    pcall(btn.SetBackdropColor, btn, 0.08, 0.08, 0.08, 0.95)
  end
  if type(btn.SetBackdropBorderColor) == "function" then
    pcall(btn.SetBackdropBorderColor, btn, 0, 0.80, 1.00, 0.55)
  end
  if type(btn.SetNormalFontObject) == "function" then
    pcall(btn.SetNormalFontObject, btn, "GameFontHighlight")
  end
  if type(btn.SetHighlightFontObject) == "function" then
    pcall(btn.SetHighlightFontObject, btn, "GameFontNormal")
  end
  if type(btn.GetFontString) == "function" then
    local okF, fs = pcall(btn.GetFontString, btn)
    if okF and fs ~= nil and type(fs.SetTextColor) == "function" then
      pcall(fs.SetTextColor, fs, 0.70, 0.88, 1.00, 1)
    end
  end
  if type(btn.SetScript) == "function" then
    pcall(btn.SetScript, btn, "OnEnter", function(self)
      if type(self.SetBackdropColor) == "function" then
        pcall(self.SetBackdropColor, self, 0.14, 0.16, 0.18, 0.95)
      end
      if type(self.SetBackdropBorderColor) == "function" then
        pcall(self.SetBackdropBorderColor, self, 0, 0.95, 1.00, 0.85)
      end
    end)
    pcall(btn.SetScript, btn, "OnLeave", function(self)
      if type(self.SetBackdropColor) == "function" then
        pcall(self.SetBackdropColor, self, 0.08, 0.08, 0.08, 0.95)
      end
      if type(self.SetBackdropBorderColor) == "function" then
        pcall(self.SetBackdropBorderColor, self, 0, 0.80, 1.00, 0.55)
      end
    end)
  end
end

-- Reuse dla Menu.lua / Scanner.lua (ladowane po Export.lua wg .toc).
Bistooltip_Scanner_ApplyDarkPanel = bsApplyDarkPanel
Bistooltip_Scanner_StyleDarkButton = bsStyleDarkButton

-- Uchwyt zmiany rozmiaru w prawym dolnym rogu (3.3.5a: StartSizing).
-- Pole edycji rozciaga sie za oknem (OnSizeChanged). Wszystko guardowane.
-- Zwraca true gdy podpięto, nil gdy ramka nie wspiera resize.
function Bistooltip_Scanner_EnableResize(f, minW, minH)
  if type(f) ~= "table" then return nil end
  if type(f.SetResizable) ~= "function" then return nil end
  if type(CreateFrame) ~= "function" then return nil end
  local fname = "BistooltipScanner"
  if type(f.GetName) == "function" then
    local okN, nm = pcall(f.GetName, f)
    if okN and type(nm) == "string" and nm ~= "" then fname = nm end
  end
  local done = false
  pcall(function()
    f:SetResizable(true)
    if type(f.SetMinResize) == "function" then
      f:SetMinResize(minW or 400, minH or 300)
    end
    local grip = CreateFrame("Button", fname .. "Resize", f)
    if grip == nil then return end
    if type(grip.SetNormalTexture) == "function" then
      grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end
    if type(grip.SetHighlightTexture) == "function" then
      grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end
    if type(grip.SetSize) == "function" then grip:SetSize(16, 16)
    elseif type(grip.SetWidth) == "function" then grip:SetWidth(16) grip:SetHeight(16) end
    if type(grip.SetPoint) == "function" then
      grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    end
    if type(grip.SetScript) == "function" then
      grip:SetScript("OnMouseDown", function() pcall(f.StartSizing, f, "BOTTOMRIGHT") end)
      grip:SetScript("OnMouseUp", function() pcall(f.StopMovingOrSizing, f) end)
    end
    if type(f.SetScript) == "function" and type(f.GetEditBox) == "function" then
      f:SetScript("OnSizeChanged", function()
        local okB, box = pcall(f.GetEditBox, f)
        if okB and box ~= nil and type(box.SetWidth) == "function" then
          local w = 500
          if type(f.GetWidth) == "function" then
            local okW, fw = pcall(f.GetWidth, f)
            if okW and type(fw) == "number" and fw > 120 then w = fw - 60 end
          end
          pcall(box.SetWidth, box, w)
        end
      end)
    end
    done = true
  end)
  if done then return true end
  return nil
end
function Bistooltip_Scanner_ShowExport(text)
  text = tostring(text or "")
  if type(CreateFrame) ~= "function" then return text end
  local shown = text
  local nlines = 1
  for _ in text:gmatch("\n") do nlines = nlines + 1 end
  local limit = Bistooltip_Scanner_MaxWindowLines or 500
  if nlines > limit then
    local kept = {}
    local i = 0
    for line in (text .. "\n"):gmatch("(.-)\n") do
      i = i + 1
      if i > limit then break end
      kept[#kept + 1] = line
    end
    kept[#kept + 1] = "-- ... (" .. (nlines - limit)
      .. " more lines; full text in BistooltipScannerDB)"
    shown = table.concat(kept, "\n")
  end
  if exportFrame ~= nil then
    local okBox, box = pcall(exportFrame.GetEditBox, exportFrame)
    if okBox and box ~= nil and type(box.SetText) == "function" then
      pcall(box.SetText, box, shown)
    end
    if type(exportFrame.Show) == "function" then pcall(exportFrame.Show, exportFrame) end
    return text
  end
  local ok, f = pcall(CreateFrame, "Frame", "BistooltipScannerExport", UIParent)
  if not ok or f == nil then return text end
  local built, editBox = pcall(function()
    f:SetWidth(560)
    f:SetHeight(420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    bsApplyDarkPanel(f, 0.88)
    if f.TitleText and type(f.TitleText.SetText) == "function" then
      f.TitleText:SetText("Bistooltip Scanner - export")
    else
      local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      title:SetPoint("TOP", f, "TOP", 0, -10)
      title:SetText("|cff00ccffBistooltip Scanner|r — export  (Ctrl+A, Ctrl+C)")
      title:SetJustifyH("CENTER")
      local sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
      sub:SetText("BisScanner snippet — paste into your server plugin")
    end
    -- UIPanelScrollFrameTemplate wymaga NAZWANEJ ramki (OnLoad robi
    -- GetName().."ScrollBar"). nil tutaj = concatenate-nil w grze.
    local scroll = CreateFrame("ScrollFrame", "BistooltipScannerExportScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -60)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)
    local box = CreateFrame("EditBox", "BistooltipScannerExportBox", scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    local font = ChatFontNormal or GameFontHighlightSmall
    if font then box:SetFontObject(font) end
    box:SetWidth(500)
    box:SetTextInsets(8, 8, 8, 8)
    bsApplyDarkPanel(box, 0.55)
    if type(box.SetBackdropBorderColor) == "function" then
      pcall(box.SetBackdropBorderColor, box, 0, 0.80, 1.00, 0.25)
    end
    box:HighlightText()
    box:SetScript("OnEscapePressed", box.ClearFocus)
    scroll:SetScrollChild(box)
    f.GetEditBox = function() return box end
    local scan = CreateFrame("Button", "BistooltipScannerExportScan", f)
    scan:SetWidth(90); scan:SetHeight(22)
    scan:SetPoint("BOTTOMLEFT", 12, 12)
    scan:SetText("Scan")
    bsStyleDarkButton(scan)
    scan:SetScript("OnClick", function() Bistooltip_Scanner_ScanVendor() end)
    local copy = CreateFrame("Button", "BistooltipScannerExportCopy", f)
    copy:SetWidth(90); copy:SetHeight(22)
    copy:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    copy:SetText("Copy")
    bsStyleDarkButton(copy)
    copy:SetScript("OnClick", function() box:HighlightText() box:SetFocus() end)
    local close = CreateFrame("Button", "BistooltipScannerExportClose", f)
    close:SetWidth(90); close:SetHeight(22)
    close:SetPoint("BOTTOMRIGHT", -12, 12)
    close:SetText("Close")
    bsStyleDarkButton(close)
    close:SetScript("OnClick", function() f:Hide() end)
    return box
  end)
  if not built then return text end -- nie cachujemy polowy ramki
  exportFrame = f
  pcall(Bistooltip_Scanner_EnableResize, f, 480, 320)
  if built and editBox ~= nil and type(editBox.SetText) == "function" then
    pcall(editBox.SetText, editBox, shown)
  end
  if type(f.Show) == "function" then pcall(f.Show, f) end
  return text
end
