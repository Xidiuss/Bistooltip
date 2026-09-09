-- Bistooltip_Scanner/Menu.lua
-- Male menu obslugi mikro-addonu: skan vendora, skan po ID, przelacznik
-- CUSTOM (donate), eksport, status. Wszystko klikalne, bez /script.
-- Lua 5.1, Interface 30300. Caly UI guardowany pod harness headless.

local menuFrame = nil
local statusLine = nil
local idBox = nil
local markBox = nil
local qtyBox = nil
local customBtn = nil
local customLabelFs = nil
local noteHeaderFs = nil

-- Dark styling (ten sam look co Export.lua z "scanner wygląd").
-- Uzyj wspoldzielonych helperow z Export.lua gdy zaladowane, inaczej lokalny fallback.
local applyDarkPanel = (type(Bistooltip_Scanner_ApplyDarkPanel) == "function")
  and Bistooltip_Scanner_ApplyDarkPanel or nil
local styleDarkButton = (type(Bistooltip_Scanner_StyleDarkButton) == "function")
  and Bistooltip_Scanner_StyleDarkButton or nil
if applyDarkPanel == nil then
  applyDarkPanel = function(frame, alpha)
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
end
if styleDarkButton == nil then
  styleDarkButton = function(btn)
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
end

-- NOTKA: celowo NIE uzywamy InputBoxTemplate — ta templatka rysuje wlasne
-- tekstury i ignoruje SetBackdrop*, wiec tintowanie jej to no-op (inputy
-- wygladaly "bez zmian"). Gole EditBoxy + ApplyDarkPanel nizej (mkDarkInput
-- w ensureMenu) daja ten sam dark look co okno eksportu.

local function refreshStatus()
  if statusLine and type(statusLine.SetText) == "function" then
    local ok, st = pcall(Bistooltip_Scanner_MenuStatus)
    if ok and type(st) == "string" then
      pcall(statusLine.SetText, statusLine, st)
    end
  end
  if customBtn ~= nil then
    Bistooltip_Scanner_SetCheckVisual(customBtn, Bistooltip_Scanner_UseCustom == true)
  end
end

-- Zielona fajka na ciemnym przycisku (standard wszystkich checkboxow menu).
-- Uzywa natywnej tekstury UI-CheckBox-Check (30300) z zielonym vertex color;
-- fallback ASCII "V" gdyby tekstura byla niedostepna. Stan pamieta _checkOn.
function Bistooltip_Scanner_SetCheckVisual(btn, on)
  if type(btn) ~= "table" then return end
  on = (on == true)
  local tex = btn._check
  if tex == nil and type(btn.CreateTexture) == "function" then
    local okT, t = pcall(btn.CreateTexture, btn, nil, "OVERLAY")
    if okT and t ~= nil then
      if type(t.SetTexture) == "function" then
        pcall(t.SetTexture, t, "Interface\\Buttons\\UI-CheckBox-Check")
      end
      if type(t.SetWidth) == "function" then pcall(t.SetWidth, t, 20) end
      if type(t.SetHeight) == "function" then pcall(t.SetHeight, t, 20) end
      if type(t.SetPoint) == "function" then
        if type(btn.GetName) == "function" then
          pcall(t.SetPoint, t, "CENTER", btn, "CENTER", 0, 0)
        else
          pcall(t.SetPoint, t, "CENTER")
        end
      end
      if type(t.SetVertexColor) == "function" then
        pcall(t.SetVertexColor, t, 0.25, 1.0, 0.25, 1)
      end
      btn._check = t
      tex = t
    end
  end
  btn._checkOn = on
  if tex ~= nil then
    if on then
      if type(tex.Show) == "function" then pcall(tex.Show, tex) end
    else
      if type(tex.Hide) == "function" then pcall(tex.Hide, tex) end
    end
  elseif type(btn.SetText) == "function" then
    pcall(btn.SetText, btn, on and "V" or "")
  end
end

function Bistooltip_Scanner_MenuStatus()
  local db = BistooltipScannerDB
  if type(db) ~= "table" then return "no data: open a vendor" end
  local nKeys, total = 0, 0
  for k, v in pairs(db) do
    if type(k) == "string" and k:sub(1, 1) ~= "_"
      and type(v) == "table" and type(v.items) == "table" then
      nKeys = nKeys + 1
      local c = tonumber(v.count) or 0
      if c == 0 then for _ in pairs(v.items) do c = c + 1 end end
      total = total + c
    end
  end
  if nKeys == 0 then return "no data: open a vendor and click Scan" end
  local s = "vendors: " .. nKeys .. "  items: " .. total
  if type(db._lastKey) == "string" then s = s .. "  |  last: " .. db._lastKey end
  if Bistooltip_Scanner_UseCustom then s = s .. "  [CUSTOM]" else s = s .. "  [VENDOR]" end
  if type(Bistooltip_Scanner_ActiveMarkLabel) == "function" then
    local okL, lab = pcall(Bistooltip_Scanner_ActiveMarkLabel)
    if okL and type(lab) == "string" then s = s .. "  |  set: " .. lab end
  end
  if type(Bistooltip_Scanner_StabStatus) == "function" then
    local okS, ss = pcall(Bistooltip_Scanner_StabStatus)
    if okS and type(ss) == "string" then s = s .. "  |  " .. ss end
  end
  return s
end

function Bistooltip_Scanner_ToggleCustom()
  Bistooltip_Scanner_UseCustom = not Bistooltip_Scanner_UseCustom
  refreshStatus()
  return Bistooltip_Scanner_UseCustom
end

-- Forward: maybeAutofillMark (nizej) wola syncPendingMark; bez deklaracji
-- Lua 5.1 wiazalby wywolanie z globalem nil (BugSack: line 154).
local syncPendingMark

-- Puste pola marki wypelnij zapamietana marka vendora (B1).
local function maybeAutofillMark()
  if type(Bistooltip_Scanner_RecallMark) ~= "function" then return end
  local ok, mid, mamt = pcall(Bistooltip_Scanner_RecallMark)
  if not ok or mid == nil then return end
  if markBox and type(markBox.GetText) == "function" then
    local okT, txt = pcall(markBox.GetText, markBox)
    if okT and (txt == nil or txt == "") and type(markBox.SetText) == "function" then
      pcall(markBox.SetText, markBox, tostring(mid))
    end
  end
  if qtyBox and type(qtyBox.GetText) == "function" then
    local okT, txt = pcall(qtyBox.GetText, qtyBox)
    if okT and (txt == nil or txt == "") and type(qtyBox.SetText) == "function" then
      pcall(qtyBox.SetText, qtyBox, tostring(mamt))
    end
  end
  syncPendingMark()
end

local function doScanVendor()
  if type(Bistooltip_Scanner_ScanVendor) == "function" then
    pcall(Bistooltip_Scanner_ScanVendor)
  end
  maybeAutofillMark()
  refreshStatus()
end

local function doScanPage()
  if type(Bistooltip_Scanner_ScanPage) == "function" then
    pcall(Bistooltip_Scanner_ScanPage)
  end
  maybeAutofillMark()
  refreshStatus()
end

local function doStabilize()
  if type(Bistooltip_Scanner_Stabilize) == "function" then
    pcall(Bistooltip_Scanner_Stabilize)
  end
  maybeAutofillMark()
  refreshStatus()
end

local function doUndo()
  if type(Bistooltip_Scanner_Undo) == "function" then
    pcall(Bistooltip_Scanner_Undo)
  end
  refreshStatus()
end

-- Wyciaga ID z pola: najpierw link item:ID (wklejony link / Shift+klik),
-- potem zwykla liczba. Bez tego link dawalby losowy fragment koloru.
local function extractNum(txt)
  txt = tostring(txt or "")
  local id = txt:match("item:(%d+)") or txt:match("(%d+)")
  return tonumber(id)
end

-- Pola marki: zwraca markID, amount albo nil, nil.
local function readMarkFields()
  local mid, amt = nil, nil
  if markBox and type(markBox.GetText) == "function" then
    local ok, txt = pcall(markBox.GetText, markBox)
    if ok then mid = extractNum(txt) end
  end
  if qtyBox and type(qtyBox.GetText) == "function" then
    local ok, txt = pcall(qtyBox.GetText, qtyBox)
    if ok then amt = extractNum(txt) end
  end
  if mid and mid > 0 and amt and amt > 0 then return mid, amt end
  return nil, nil
end

-- Synchronizacja marki dla Alt+kliku (wywolywana przy zmianie pol).
syncPendingMark = function()
  local mid, amt = readMarkFields()
  if mid and amt then
    Bistooltip_Scanner_PendingMark = { id = mid, amount = amt }
  else
    Bistooltip_Scanner_PendingMark = nil
  end
end

local function doSetCost()
  local mid, amt = readMarkFields()
  if mid and amt and type(Bistooltip_Scanner_SetCost) == "function" then
    Bistooltip_Scanner_PendingMark = { id = mid, amount = amt }
    pcall(Bistooltip_Scanner_SetCost, mid, amt)
  end
  refreshStatus()
end

local function doScanID()
  local id = nil
  if idBox and type(idBox.GetText) == "function" then
    local ok, txt = pcall(idBox.GetText, idBox)
    if ok then id = extractNum(txt) end
  end
  if id and type(Bistooltip_Scanner_ScanByID) == "function" then
    pcall(Bistooltip_Scanner_ScanByID, id)
    -- Marka z pol: od razu dopnij koszt do tej pozycji.
    local mid, amt = readMarkFields()
    if mid and amt and type(Bistooltip_Scanner_SetCost) == "function" then
      Bistooltip_Scanner_PendingMark = { id = mid, amount = amt }
      pcall(Bistooltip_Scanner_SetCost, id, mid, amt)
    end
  end
  refreshStatus()
end

local function doLogAdd()
  if type(Bistooltip_Scanner_LogAdd) == "function" then
    pcall(Bistooltip_Scanner_LogAdd)
  end
  refreshStatus()
end

local function doExport()
  local db = BistooltipScannerDB
  -- W ten sam sposob co slash: caly eksport z naglowkiem WARN.
  if type(Bistooltip_Scanner_ExportText) == "function" then
    local okE, text = pcall(Bistooltip_Scanner_ExportText)
    if okE and type(text) == "string" then
      if type(db) == "table" then
        pcall(function()
          db._logText = text
          -- Pojedynczy vendor bez logu: odloz tez per-vendor (kompatybilnosc).
          if (type(db._log) ~= "table" or #db._log == 0)
            and type(db._lastKey) == "string"
            and type(db[db._lastKey]) == "table" then
            db[db._lastKey].lastExport = text
          end
        end)
      end
      if type(Bistooltip_Scanner_ShowExport) == "function" then
        pcall(Bistooltip_Scanner_ShowExport, text)
      end
      refreshStatus()
      return
    end
  end
  local key = (type(db) == "table") and db._lastKey or nil
  if type(key) ~= "string" and type(db) == "table" then
    for k, v in pairs(db) do
      if type(k) == "string" and k:sub(1, 1) ~= "_"
        and type(v) == "table" and type(v.items) == "table" then
        key = k break
      end
    end
  end
  if type(key) == "string" and type(Bistooltip_Scanner_BuildSnippet) == "function" then
    local ok, text = pcall(Bistooltip_Scanner_BuildSnippet, key)
    if ok and type(text) == "string" then
      if type(db) == "table" and type(db[key]) == "table" then
        pcall(function() db[key].lastExport = text end)
      end
      if type(Bistooltip_Scanner_ShowExport) == "function" then
        pcall(Bistooltip_Scanner_ShowExport, text)
      end
    end
  end
  refreshStatus()
end

-- Wpisz marke bez recznego przepisywania: Ctrl+Lewy na przedmiot
-- w plecaku/banku albo wklejony link. Kieruje do setow: aktywny set
-- dostaje ID; brak aktywnego = pierwszy pusty/nowy wiersz + aktywacja
-- (pola Marka sa ukrytym backingiem). Zwraca ID albo nil.
function Bistooltip_Scanner_SetMarkFromClick(linkOrID)
  local id = nil
  if tonumber(linkOrID) then
    id = tonumber(linkOrID)
  else
    id = extractNum(linkOrID)
  end
  if id == nil or id <= 0 then return nil end
  local mname = nil
  if type(GetItemInfo) == "function" then
    local okI, nm = pcall(GetItemInfo, id)
    if okI then mname = nm end
  end
  local routed = false
  if type(BistooltipScannerDB) == "table" then
    local active = BistooltipScannerDB._markActive
    local sets = nil
    if type(Bistooltip_Scanner_GetMarkSets) == "function" then
      local okG, t = pcall(Bistooltip_Scanner_GetMarkSets)
      if okG and type(t) == "table" then sets = t end
    end
    if type(sets) == "table" then
      local target = nil
      if type(active) == "number" and type(sets[active]) == "table" then
        target = active
      else
        for i, s in ipairs(sets) do
          if type(s) == "table" and s.id == nil then target = i break end
        end
        if target == nil and type(Bistooltip_Scanner_AddMarkSet) == "function" then
          local okA, ni = pcall(Bistooltip_Scanner_AddMarkSet)
          if okA and type(ni) == "number" then target = ni end
        end
      end
      if target ~= nil and type(sets[target]) == "table" then
        if type(Bistooltip_Scanner_UpdateMarkSet) == "function" then
          pcall(Bistooltip_Scanner_UpdateMarkSet, target, id, sets[target].amount, sets[target].note)
        end
        if type(Bistooltip_Scanner_SetActiveMarkSet) == "function" then
          pcall(Bistooltip_Scanner_SetActiveMarkSet, target)
        end
        if type(Bistooltip_Scanner_ApplySetToFields) == "function" then
          pcall(Bistooltip_Scanner_ApplySetToFields, target)
        end
        routed = true
      end
    end
  end
  if not routed then
    -- Fallback: prosto do ukrytego backingu (jak dotad).
    if markBox and type(markBox.SetText) == "function" then
      pcall(markBox.SetText, markBox, tostring(id))
    end
    -- sync na wypadek gdyby OnTextChanged nie odpalil (headless / focus)
    syncPendingMark()
  end
  if type(Bistooltip_Scanner_RefreshMarkSets) == "function" then
    pcall(Bistooltip_Scanner_RefreshMarkSets, true)
  else
    refreshStatus()
  end
  if type(DEFAULT_CHAT_FRAME) == "table"
    and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bistooltip_Scanner:|r Mark: "
      .. tostring(id) .. (mname and (" (" .. mname .. ")") or "") .. " — enter amount")
  end
  return id
end

-- Ctrl+Lewy na slocie plecaka: pobierz ID marki zamiast podnoszenia.
-- Zwraca true gdy obsluzone (oryginalny handler pomijany).
local function containerCtrlCapture(self)
  local bag, slot = nil, nil
  if type(self) == "table" and type(self.GetParent) == "function" then
    local okP, parent = pcall(self.GetParent, self)
    if okP and type(parent) == "table" and type(parent.GetID) == "function" then
      local okB, b = pcall(parent.GetID, parent)
      if okB then bag = tonumber(b) end
    end
  end
  if type(self) == "table" and type(self.GetID) == "function" then
    local okS, s = pcall(self.GetID, self)
    if okS then slot = tonumber(s) end
  end
  if bag == nil or slot == nil then return false end
  if type(GetContainerItemLink) ~= "function" then return false end
  local okL, link = pcall(GetContainerItemLink, bag, slot)
  if not okL or type(link) ~= "string" then return false end
  local id = extractNum(link)
  if id == nil or id <= 0 then return false end
  Bistooltip_Scanner_SetMarkFromClick(id)
  return true
end

-- Owrapowanie globalnego handlera plecaka. Idempotentne, headless-safe.
local function hookContainerClick()
  if type(ContainerFrameItemButton_OnClick) ~= "function" then return end
  if _G.BistooltipScannerContainerHooked then return end
  local orig = ContainerFrameItemButton_OnClick
  _G.BistooltipScannerContainerHooked = true
  _G.ContainerFrameItemButton_OnClick = function(self, button, ...)
    local okC, ctrl = pcall(IsControlKeyDown)
    if okC and ctrl and button == "LeftButton" then
      local okH, handled = pcall(containerCtrlCapture, self)
      if okH and handled then return end
    end
    return orig(self, button, ...)
  end
end

hookContainerClick()

local function ensureMenu()
  if _G.BistooltipScannerMenu then return _G.BistooltipScannerMenu end
  if type(CreateFrame) ~= "function" then return nil end
  -- Ciemny panel zamiast BasicFrameTemplateWithInset (look z "scanner wygląd").
  local ok, f = pcall(CreateFrame, "Frame", "BistooltipScannerMenu", UIParent)
  if not ok or f == nil then return nil end
  menuFrame = f
  pcall(function()
    if type(f.SetSize) == "function" then f:SetSize(460, 420)
    elseif type(f.SetWidth) == "function" then f:SetWidth(460) f:SetHeight(420) end
    if type(f.SetPoint) == "function" then f:SetPoint("CENTER") end
    if type(f.SetFrameStrata) == "function" then f:SetFrameStrata("DIALOG") end
    if type(f.SetMovable) == "function" then f:SetMovable(true) end
    if type(f.EnableMouse) == "function" then f:EnableMouse(true) end
    if type(f.RegisterForDrag) == "function" then f:RegisterForDrag("LeftButton") end
    if type(f.SetScript) == "function" then
      f:SetScript("OnDragStart", f.StartMoving)
      f:SetScript("OnDragStop", f.StopMovingOrSizing)
    end
    applyDarkPanel(f, 0.88)
    if f.TitleText and type(f.TitleText.SetText) == "function" then
      f.TitleText:SetText("Bistooltip Scanner")
    elseif type(f.CreateFontString) == "function" then
      local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      if title then
        if type(title.SetPoint) == "function" then title:SetPoint("TOP", f, "TOP", 0, -10) end
        if type(title.SetText) == "function" then
          title:SetText("|cff00ccffBistooltip Scanner|r")
        end
        if type(title.SetJustifyH) == "function" then title:SetJustifyH("CENTER") end
      end
    end
  end)
  local function mkLabel(text, x, y, width, just)
    local out = nil
    pcall(function()
      if type(f.CreateFontString) ~= "function" then return end
      local fs = f:CreateFontString(nil, "OVERLAY")
      if fs == nil then return end
      local font = GameFontHighlightSmall or GameFontNormal or ChatFontNormal
      if font and type(fs.SetFontObject) == "function" then fs:SetFontObject(font) end
      if type(fs.SetPoint) == "function" then
        fs:SetPoint("TOPLEFT", 12 + x, y)
      end
      if width and type(fs.SetWidth) == "function" then fs:SetWidth(width) end
      if type(fs.SetJustifyH) == "function" then fs:SetJustifyH(just or "LEFT") end
      if type(fs.SetText) == "function" then fs:SetText(text) end
      out = fs
    end)
    return out
  end
  -- status na gorze (z fontem! bez SetFontObject tekst jest niewidzialny)
  pcall(function()
    if type(f.CreateFontString) == "function" then
      statusLine = f:CreateFontString(nil, "OVERLAY")
      if statusLine then
        local font = GameFontHighlightSmall or GameFontNormal or ChatFontNormal
        if font and type(statusLine.SetFontObject) == "function" then
          statusLine:SetFontObject(font)
        end
        if type(statusLine.SetPoint) == "function" then
          statusLine:SetPoint("TOPLEFT", 12, -32)
        end
        if type(statusLine.SetWidth) == "function" then statusLine:SetWidth(436) end
        if type(statusLine.SetJustifyH) == "function" then statusLine:SetJustifyH("LEFT") end
        if type(statusLine.SetText) == "function" then
          statusLine:SetText(Bistooltip_Scanner_MenuStatus())
        end
      end
    end
  end)
  -- Responsywnosc: wpisy {b, x0, y, fx}; x = 12 + x0 + extra*fx
  -- (fx=0 stoi, fx=1 plynie z prawa krawedzia, fx=0.5 trzyma srodek).
  local rightCol = {}
  local function mkButton(name, text, x, y, fn, fx)
    local b = nil
    pcall(function()
      b = CreateFrame("Button", name, f)
      if b == nil then return end
      if type(b.SetSize) == "function" then b:SetSize(140, 24)
      else b:SetWidth(140) b:SetHeight(24) end
      b:SetPoint("TOPLEFT", 12 + x, -40 + y)
      b:SetText(text)
      styleDarkButton(b)
      b:SetScript("OnClick", fn)
    end)
    if b ~= nil then
      rightCol[#rightCol + 1] = { b = b, x0 = x, y = y, fx = fx or 0 }
    end
    return b
  end
  -- Pozycjonowanie responsywne (wspolne dla layoutu i OnSizeChanged).
  local function applyResponsive(extra)
    if extra < 0 then extra = 0 end
    if extra > 300 then extra = 300 end
    for _, e in ipairs(rightCol) do
      if type(e) == "table" and type(e.b) == "table"
        and type(e.b.ClearAllPoints) == "function"
        and type(e.b.SetPoint) == "function" then
        pcall(e.b.ClearAllPoints, e.b)
        pcall(e.b.SetPoint, e.b, "TOPLEFT", 12 + (e.x0 or 0) + extra * (e.fx or 0), -40 + (e.y or 0))
      end
    end
    if idBox ~= nil and type(idBox.SetWidth) == "function" then
      pcall(idBox.SetWidth, idBox, 288 + extra)
    end
    if statusLine ~= nil and type(statusLine.SetWidth) == "function" then
      pcall(statusLine.SetWidth, statusLine, 436 + extra)
    end
  end
  -- Goly ciemny input (bez InputBoxTemplate — patrz NOTKA na gorze pliku).
  local function mkDarkInput(name, w, x, y, opts)
    opts = opts or {}
    local box = nil
    pcall(function()
      box = CreateFrame("EditBox", name, f)
      if box == nil then return end
      if type(box.SetSize) == "function" then box:SetSize(w, 24)
      else box:SetWidth(w) box:SetHeight(24) end
      box:SetPoint("TOPLEFT", 12 + x, y)
      if type(box.SetAutoFocus) == "function" then box:SetAutoFocus(false) end
      local font = GameFontHighlightSmall or GameFontNormal or ChatFontNormal
      if font and type(box.SetFontObject) == "function" then box:SetFontObject(font) end
      if type(box.SetJustifyH) == "function" then box:SetJustifyH("LEFT") end
      if type(box.SetTextInsets) == "function" then box:SetTextInsets(6, 6, 0, 0) end
      applyDarkPanel(box, 0.55)
      if type(box.SetBackdropBorderColor) == "function" then
        pcall(box.SetBackdropBorderColor, box, 0, 0.80, 1.00, 0.25)
      end
      if type(box.SetTextColor) == "function" then
        pcall(box.SetTextColor, box, 0.85, 0.93, 1.00)
      end
      if type(box.SetText) == "function" then box:SetText("") end
      if opts.numeric and type(box.SetNumeric) == "function" then box:SetNumeric(true) end
      if opts.maxLetters and type(box.SetMaxLetters) == "function" then
        box:SetMaxLetters(opts.maxLetters)
      end
      if type(box.SetScript) == "function" then
        box:SetScript("OnEscapePressed", function(self)
          if type(self.ClearFocus) == "function" then pcall(self.ClearFocus, self) end
        end)
        box:SetScript("OnEnterPressed", function(self)
          if type(self.ClearFocus) == "function" then pcall(self.ClearFocus, self) end
        end)
        if opts.sync then
          box:SetScript("OnTextChanged", function() syncPendingMark() end)
        end
      end
    end)
    return box
  end
  local function mkBottomLabel(text, yOff, width)
    pcall(function()
      if type(f.CreateFontString) ~= "function" then return end
      local fs = f:CreateFontString(nil, "OVERLAY")
      if fs == nil then return end
      local font = GameFontHighlightSmall or GameFontNormal or ChatFontNormal
      if font and type(fs.SetFontObject) == "function" then fs:SetFontObject(font) end
      if type(fs.SetPoint) == "function" then
        fs:SetPoint("BOTTOMLEFT", 12, yOff)
      end
      if width and type(fs.SetWidth) == "function" then fs:SetWidth(width) end
      if type(fs.SetJustifyH) == "function" then fs:SetJustifyH("LEFT") end
      if type(fs.SetText) == "function" then fs:SetText(text) end
    end)
  end
  -- GRUPA SKAN: 3 kolumny (lewa stoi, srodek trzyma srodek, prawa plynie).
  mkButton("BistooltipScannerMenuScanPage", "Scan page", 0, -44, doScanPage, 0)
  mkButton("BistooltipScannerMenuStab", "Stabilize", 148, -44, doStabilize, 0.5)
  mkButton("BistooltipScannerMenuScan", "Scan vendor", 296, -44, doScanVendor, 1)
  -- GRUPA KOSZT: wycentrowana para (trzyma srodek przy resize).
  mkButton("BistooltipScannerMenuSetCost", "Set cost", 74, -80, doSetCost, 0.5)
  mkButton("BistooltipScannerMenuUndo", "Undo", 222, -80, doUndo, 0.5)
  -- Item ID: label + input (rozciaga sie) + Scan ID (plynie w prawo).
  mkLabel("Item ID:", 0, -156, 140)
  idBox = mkDarkInput("BistooltipScannerMenuID", 288, 0, -172, {})
  mkButton("BistooltipScannerMenuScanID", "Scan ID", 296, -132, doScanID, 1)
  -- Ukryty backing aktywnej marki (logika czyta/pisze, gracz widzi tabelke).
  markBox = mkDarkInput("BistooltipScannerMenuMark", 100, 0, -222, { sync = true })
  pcall(function()
    qtyBox = mkDarkInput("BistooltipScannerMenuQty", 50, 106, -222, { numeric = true, maxLetters = 5, sync = true })
  end)
  if markBox ~= nil and type(markBox.Hide) == "function" then pcall(markBox.Hide, markBox) end
  if qtyBox ~= nil and type(qtyBox.Hide) == "function" then pcall(qtyBox.Hide, qtyBox) end
  -- Sekcja setow marek: nazwane presety (ID + koszt + uwaga), wybor checkboxem.
  -- Aktywny jest JEDEN naraz (jak radio): wybor laduje pola Marka ID + ilosc,
  -- wiec Set cost / Alt+klik / Scan ID dzialaja bez zmian. Limit 6 (layout).
  local setRows = {}
  local function fwNow()
    local fw = 320
    if type(f.GetWidth) == "function" then
      local okW, w = pcall(f.GetWidth, f)
      if okW and type(w) == "number" and w > 200 then fw = w end
    end
    return fw
  end
  -- Forward: wiersz LOG/EKSPORT tworzony po layoucie, ale layout ustawia
  -- jego y (bez deklaracji Lua wiazaloby global nil — por. fix syncPendingMark).
  local logBtn1, logBtn2
  -- Wiersz i na pozycji; resizeOnly=true pomija SetText (nie gubi kursora).
  local function layoutMarkSets(resizeOnly)
    local sets = {}
    if type(Bistooltip_Scanner_GetMarkSets) == "function" then
      local okG, t = pcall(Bistooltip_Scanner_GetMarkSets)
      if okG and type(t) == "table" then sets = t end
    end
    local active = nil
    if type(BistooltipScannerDB) == "table" then active = BistooltipScannerDB._markActive end
    local n = #sets
    local fw = fwNow()
    for i, r in ipairs(setRows) do
      local s = sets[i]
      local show = (s ~= nil)
      local function showHide(w, vis)
        if w == nil then return end
        if vis then
          if type(w.Show) == "function" then pcall(w.Show, w) end
        else
          if type(w.Hide) == "function" then pcall(w.Hide, w) end
        end
      end
      showHide(r.tgl, show) showHide(r.id, show)
      showHide(r.amt, show) showHide(r.note, show) showHide(r.del, show)
      if show then
        local y = -232 - (i - 1) * 32
        if type(r.tgl.SetPoint) == "function" then
          if type(r.tgl.ClearAllPoints) == "function" then pcall(r.tgl.ClearAllPoints, r.tgl) end
          pcall(r.tgl.SetPoint, r.tgl, "TOPLEFT", 12, y)
        end
        if type(r.id.SetPoint) == "function" then
          if type(r.id.ClearAllPoints) == "function" then pcall(r.id.ClearAllPoints, r.id) end
          pcall(r.id.SetPoint, r.id, "TOPLEFT", 12 + 34, y)
        end
        if type(r.amt.SetPoint) == "function" then
          if type(r.amt.ClearAllPoints) == "function" then pcall(r.amt.ClearAllPoints, r.amt) end
          pcall(r.amt.SetPoint, r.amt, "TOPLEFT", 12 + 128, y)
        end
        if type(r.note.SetPoint) == "function" then
          if type(r.note.ClearAllPoints) == "function" then pcall(r.note.ClearAllPoints, r.note) end
          pcall(r.note.SetPoint, r.note, "TOPLEFT", 12 + 180, y)
          if type(r.note.SetWidth) == "function" then
            local nw = fw - 230
            if nw < 60 then nw = 60 end
            pcall(r.note.SetWidth, r.note, nw)
          end
        end
        if type(r.del.SetPoint) == "function" then
          if type(r.del.ClearAllPoints) == "function" then pcall(r.del.ClearAllPoints, r.del) end
          pcall(r.del.SetPoint, r.del, "TOPRIGHT", -12, y)
        end
        if not resizeOnly then
          Bistooltip_Scanner_SetCheckVisual(r.tgl, active == i)
          if type(r.id.SetText) == "function" then
            pcall(r.id.SetText, r.id, (s.id ~= nil) and tostring(s.id) or "")
          end
          if type(r.amt.SetText) == "function" then
            pcall(r.amt.SetText, r.amt, (s.amount ~= nil) and tostring(s.amount) or "")
          end
          if type(r.note.SetText) == "function" then
            pcall(r.note.SetText, r.note, tostring(s.note or ""))
          end
        end
      end
    end
    -- Wiersz CUSTOM zjezdza ponizej setow; wiersz LOG/EKSPORT za nim;
    -- ramka dopasowuje wysokosc. Naglowek NOTE trzyma szerokosc rubryki.
    local customBoxY = -242 - n * 32
    if noteHeaderFs ~= nil and type(noteHeaderFs.SetWidth) == "function" then
      local nw = fw - 230
      if nw < 60 then nw = 60 end
      pcall(noteHeaderFs.SetWidth, noteHeaderFs, nw)
    end
    if customBtn ~= nil and type(customBtn.SetPoint) == "function" then
      if type(customBtn.ClearAllPoints) == "function" then pcall(customBtn.ClearAllPoints, customBtn) end
      pcall(customBtn.SetPoint, customBtn, "TOPLEFT", 12, customBoxY)
    end
    if customLabelFs ~= nil and type(customLabelFs.SetPoint) == "function" then
      if type(customLabelFs.ClearAllPoints) == "function" then pcall(customLabelFs.ClearAllPoints, customLabelFs) end
      pcall(customLabelFs.SetPoint, customLabelFs, "TOPLEFT", 12 + 36, customBoxY - 6)
    end
    local logY = customBoxY - 46
    for _, e in ipairs(rightCol) do
      if type(e) == "table" and (e.b == logBtn1 or e.b == logBtn2) then
        e.y = logY
      end
    end
    applyResponsive(fwNow() - 460)
    if not resizeOnly then
      local need = -customBoxY + 176
      local H = 420
      if need > H then H = need end
      if type(f.SetHeight) == "function" then pcall(f.SetHeight, f, H) end
    end
  end
  local function syncSetRow(i)
    local r = setRows[i]
    if r == nil then return end
    if type(Bistooltip_Scanner_UpdateMarkSet) ~= "function" then return end
    local id, amt, note = nil, nil, nil
    if r.id ~= nil and type(r.id.GetText) == "function" then
      local okT, txt = pcall(r.id.GetText, r.id)
      if okT then id = extractNum(txt) end
    end
    if r.amt ~= nil and type(r.amt.GetText) == "function" then
      local okT, txt = pcall(r.amt.GetText, r.amt)
      if okT then amt = extractNum(txt) end
    end
    if r.note ~= nil and type(r.note.GetText) == "function" then
      local okT, txt = pcall(r.note.GetText, r.note)
      if okT and type(txt) == "string" then note = txt end
    end
    pcall(Bistooltip_Scanner_UpdateMarkSet, i, id, amt, note)
  end
  local function applySetToFields(i)
    local sets = {}
    if type(Bistooltip_Scanner_GetMarkSets) == "function" then
      local okG, t = pcall(Bistooltip_Scanner_GetMarkSets)
      if okG and type(t) == "table" then sets = t end
    end
    local s = sets[i]
    if type(s) ~= "table" then return end
    if markBox ~= nil and type(markBox.SetText) == "function" then
      pcall(markBox.SetText, markBox, (s.id ~= nil) and tostring(s.id) or "")
    end
    if qtyBox ~= nil and type(qtyBox.SetText) == "function" then
      pcall(qtyBox.SetText, qtyBox, (s.amount ~= nil) and tostring(s.amount) or "")
    end
    syncPendingMark()
  end
  -- Naglowek tabelki: "+" dodaje wiersz; kolumny jak w mockupie.
  -- NOTE wycentrowane wzgledem rubryki (szerokosc plynie z kolumna w layoucie).
  mkLabel("MARK ID", 34, -208, 92)
  mkLabel("AMOUNT", 128, -208, 60)
  noteHeaderFs = mkLabel("NOTE", 180, -208, 230, "CENTER")
  pcall(function()
    local plus = CreateFrame("Button", "BistooltipScannerMenuSetAdd", f)
    if plus == nil then return end
    if type(plus.SetSize) == "function" then plus:SetSize(30, 22)
    else plus:SetWidth(30) plus:SetHeight(22) end
    plus:SetPoint("TOPRIGHT", -12, -204)
    plus:SetText("+")
    styleDarkButton(plus)
    plus:SetScript("OnClick", function()
      if type(Bistooltip_Scanner_AddMarkSet) == "function" then
        pcall(Bistooltip_Scanner_AddMarkSet)
      end
      layoutMarkSets()
      refreshStatus()
    end)
  end)
  -- Pool wierszy (max 6): budowany raz, pokazywany wg modelu.
  do
    local cap = Bistooltip_Scanner_MaxMarkSets or 6
    for i = 1, cap do
      local r = {}
      pcall(function()
        -- Przelacznik aktywnego seta: zielona fajka = wybrany (jeden naraz).
        local tgl = CreateFrame("Button", "BistooltipScannerMenuSet" .. i .. "Tgl", f)
        if tgl ~= nil then
          if type(tgl.SetSize) == "function" then tgl:SetSize(30, 22)
          else tgl:SetWidth(30) tgl:SetHeight(22) end
          tgl:SetText("")
          styleDarkButton(tgl)
          Bistooltip_Scanner_SetCheckVisual(tgl, false)
          if type(tgl.SetScript) == "function" then
            tgl:SetScript("OnClick", function()
              local isActive = (type(BistooltipScannerDB) == "table"
                and BistooltipScannerDB._markActive == i)
              if isActive then
                if type(Bistooltip_Scanner_SetActiveMarkSet) == "function" then
                  pcall(Bistooltip_Scanner_SetActiveMarkSet, nil)
                end
              else
                if type(Bistooltip_Scanner_SetActiveMarkSet) == "function" then
                  pcall(Bistooltip_Scanner_SetActiveMarkSet, i)
                end
                applySetToFields(i)
              end
              layoutMarkSets()
              refreshStatus()
            end)
          end
          r.tgl = tgl
        end
        r.id = mkDarkInput("BistooltipScannerMenuSet" .. i .. "ID", 90, 34, -232, { numeric = true })
        r.amt = mkDarkInput("BistooltipScannerMenuSet" .. i .. "Amt", 48, 128, -232, { numeric = true, maxLetters = 5 })
        r.note = mkDarkInput("BistooltipScannerMenuSet" .. i .. "Note", 230, 180, -232, { maxLetters = 40 })
        local del = CreateFrame("Button", "BistooltipScannerMenuSet" .. i .. "Del", f)
        if del ~= nil then
          if type(del.SetSize) == "function" then del:SetSize(22, 22) end
          del:SetText("X")
          styleDarkButton(del)
          -- Czerwony X jak w mockupie (domyslny tekst jest blekitny).
          if type(del.GetFontString) == "function" then
            local okF, fs = pcall(del.GetFontString, del)
            if okF and fs ~= nil and type(fs.SetTextColor) == "function" then
              pcall(fs.SetTextColor, fs, 1.00, 0.30, 0.30, 1)
            end
          end
          if type(del.SetScript) == "function" then
            del:SetScript("OnClick", function()
              if type(Bistooltip_Scanner_RemoveMarkSet) == "function" then
                pcall(Bistooltip_Scanner_RemoveMarkSet, i)
              end
              layoutMarkSets()
              refreshStatus()
            end)
          end
          r.del = del
        end
        if type(r.id.SetScript) == "function" then
          r.id:SetScript("OnTextChanged", function() syncSetRow(i) end)
        end
        if type(r.amt.SetScript) == "function" then
          r.amt:SetScript("OnTextChanged", function() syncSetRow(i) end)
        end
        if type(r.note.SetScript) == "function" then
          -- mkDarkInput bez opts.sync nie podpina OnTextChanged — dopinamy recznie.
          r.note:SetScript("OnTextChanged", function() syncSetRow(i) end)
        end
      end)
      setRows[i] = r
    end
  end
  -- checkbox CUSTOM z podpisem (pozycja plynie za setami — ustawia layout).
  pcall(function()
    if type(f.CreateFontString) == "function" then
      customLabelFs = f:CreateFontString(nil, "OVERLAY")
      if customLabelFs ~= nil then
        local font = GameFontHighlightSmall or GameFontNormal or ChatFontNormal
        if font and type(customLabelFs.SetFontObject) == "function" then
          customLabelFs:SetFontObject(font)
        end
        if type(customLabelFs.SetWidth) == "function" then customLabelFs:SetWidth(260) end
        if type(customLabelFs.SetJustifyH) == "function" then customLabelFs:SetJustifyH("LEFT") end
        if type(customLabelFs.SetText) == "function" then
          customLabelFs:SetText("Custom (donate shop):")
        end
      end
    end
  end)
  pcall(function()
    -- Ciemny checkbox w standardzie menu (tekstura-fajka, nie templatka Blizzard).
    customBtn = CreateFrame("Button", "BistooltipScannerMenuCustom", f)
    if customBtn == nil then return end
    if type(customBtn.SetSize) == "function" then customBtn:SetSize(24, 24) end
    customBtn:SetText("")
    styleDarkButton(customBtn)
    Bistooltip_Scanner_SetCheckVisual(customBtn, Bistooltip_Scanner_UseCustom == true)
    if type(customBtn.SetScript) == "function" then
      customBtn:SetScript("OnClick", function() Bistooltip_Scanner_ToggleCustom() end)
    end
  end)
  -- Domyslnie jeden pusty wiersz (pierwsze zbudowanie menu, puste SV).
  if type(Bistooltip_Scanner_GetMarkSets) == "function"
    and type(Bistooltip_Scanner_AddMarkSet) == "function" then
    local okG, t = pcall(Bistooltip_Scanner_GetMarkSets)
    if okG and type(t) == "table" and #t == 0 then
      pcall(Bistooltip_Scanner_AddMarkSet)
    end
  end
  layoutMarkSets()
  -- GRUPA LOG/EKSPORT: wycentrowana para ponizej CUSTOM (pozycja plynie
  -- za setami — ustawia layoutMarkSets; tu tylko utworzenie + rejestracja).
  pcall(function()
    logBtn1 = CreateFrame("Button", "BistooltipScannerMenuToLog", f)
    if logBtn1 ~= nil then
      if type(logBtn1.SetSize) == "function" then logBtn1:SetSize(140, 24)
      else logBtn1:SetWidth(140) logBtn1:SetHeight(24) end
      logBtn1:SetText("+ To log")
      styleDarkButton(logBtn1)
      logBtn1:SetScript("OnClick", doLogAdd)
      rightCol[#rightCol + 1] = { b = logBtn1, x0 = 86, y = -320, fx = 0.5 }
    end
    logBtn2 = CreateFrame("Button", "BistooltipScannerMenuExport", f)
    if logBtn2 ~= nil then
      if type(logBtn2.SetSize) == "function" then logBtn2:SetSize(140, 24)
      else logBtn2:SetWidth(140) logBtn2:SetHeight(24) end
      logBtn2:SetText("Export")
      styleDarkButton(logBtn2)
      logBtn2:SetScript("OnClick", doExport)
      rightCol[#rightCol + 1] = { b = logBtn2, x0 = 234, y = -320, fx = 0.5 }
    end
  end)
  layoutMarkSets()
  -- Dol: hinty + Clear/Close przy prawej krawedzi.
  mkBottomLabel("Alt+click item = attach mark (never buys)", 70, 340)
  mkBottomLabel("Ctrl+click bag item = grab mark ID", 56, 340)
  pcall(function()
    local clearB = CreateFrame("Button", "BistooltipScannerMenuClear", f)
    if clearB ~= nil then
      if type(clearB.SetSize) == "function" then clearB:SetSize(140, 24)
      else clearB:SetWidth(140) clearB:SetHeight(24) end
      clearB:SetPoint("BOTTOMRIGHT", -164, 12)
      clearB:SetText("Clear")
      styleDarkButton(clearB)
      clearB:SetScript("OnClick", function()
        if type(Bistooltip_Scanner_RequestClearCache) == "function" then
          pcall(Bistooltip_Scanner_RequestClearCache)
        end
        refreshStatus()
      end)
    end
    local closeB = CreateFrame("Button", "BistooltipScannerMenuClose", f)
    if closeB ~= nil then
      if type(closeB.SetSize) == "function" then closeB:SetSize(140, 24)
      else closeB:SetWidth(140) closeB:SetHeight(24) end
      closeB:SetPoint("BOTTOMRIGHT", -12, 12)
      closeB:SetText("Close")
      styleDarkButton(closeB)
      closeB:SetScript("OnClick", function()
        if type(f.Hide) == "function" then f:Hide() end
      end)
    end
  end)
  -- Grip resize w prawym dolnym rogu (jak okno eksportu).
  if type(Bistooltip_Scanner_EnableResize) == "function" then
    pcall(Bistooltip_Scanner_EnableResize, f, 440, 400)
  end
  -- Resize wiazacy: applyResponsive + wiersze setow. Bez tego powiekszanie
  -- ramki nic nie dawalo.
  if type(f.SetScript) == "function" then
    pcall(f.SetScript, f, "OnSizeChanged", function(self)
      local fw = 460
      if type(self.GetWidth) == "function" then
        local okW, w = pcall(self.GetWidth, self)
        if okW and type(w) == "number" and w > 200 then fw = w end
      end
      applyResponsive(fw - 460)
      -- Wiersze setow: notatka rozciaga sie, reszta ma stale x (oprocz del na prawo).
      layoutMarkSets(true)
    end)
  end
  if type(f.Hide) == "function" then f:Hide() end
  -- Odswiezanie wierszy setow z zewnatrz (testy / przyszle wywolania).
  Bistooltip_Scanner_RefreshMarkSets = function(resizeOnly)
    layoutMarkSets(resizeOnly)
    refreshStatus()
  end
  -- Zastosowanie seta do ukrytych pol marki (dla Ctrl+klik / Recall spoza ensureMenu).
  Bistooltip_Scanner_ApplySetToFields = function(i)
    applySetToFields(i)
  end
  return f
end

function Bistooltip_Scanner_ShowMenu()
  local f = ensureMenu()
  if f == nil then
    -- headless: zwroc status tekstowo zamiast okna
    return Bistooltip_Scanner_MenuStatus()
  end
  maybeAutofillMark()
  -- RecallMatch: zapamietana marka vendora aktywuje pasujacy set
  -- (widoczny feedback zamiast cichego wypelnienia ukrytych pol).
  if type(Bistooltip_Scanner_RecallMark) == "function"
    and type(Bistooltip_Scanner_GetActiveMark) == "function" then
    local okR, mid, mamt = pcall(Bistooltip_Scanner_RecallMark)
    if okR and mid ~= nil then
      local okA, aid = pcall(Bistooltip_Scanner_GetActiveMark)
      if okA and aid == nil
        and type(Bistooltip_Scanner_GetMarkSets) == "function" then
        local okG, sets = pcall(Bistooltip_Scanner_GetMarkSets)
        if okG and type(sets) == "table" then
          for i, s in ipairs(sets) do
            if type(s) == "table" and tonumber(s.id) == mid and tonumber(s.amount) == mamt then
              if type(Bistooltip_Scanner_SetActiveMarkSet) == "function" then
                pcall(Bistooltip_Scanner_SetActiveMarkSet, i)
              end
              if type(Bistooltip_Scanner_ApplySetToFields) == "function" then
                pcall(Bistooltip_Scanner_ApplySetToFields, i)
              end
              break
            end
          end
          if type(Bistooltip_Scanner_RefreshMarkSets) == "function" then
            pcall(Bistooltip_Scanner_RefreshMarkSets, true)
          end
        end
      end
    end
  end
  refreshStatus()
  if type(f.Show) == "function" then f:Show() end
  return f
end

function Bistooltip_Scanner_ToggleMenu()
  local f = ensureMenu()
  if f == nil then return Bistooltip_Scanner_MenuStatus() end
  if type(f.IsShown) == "function" then
    local ok, shown = pcall(f.IsShown, f)
    if ok and shown then
      if type(f.Hide) == "function" then f:Hide() end
      return false
    end
  end
  refreshStatus()
  if type(f.Show) == "function" then f:Show() end
  return true
end

-- Przycisk Menu na MerchantFrame + odswiezenie statusu po MERCHANT_SHOW.
if type(CreateFrame) == "function" then
  local ok, f = pcall(CreateFrame, "Frame")
  if ok and f ~= nil and type(f.RegisterEvent) == "function" then
    pcall(function()
      f:RegisterEvent("MERCHANT_SHOW")
      f:SetScript("OnEvent", function()
        if type(MerchantFrame) == "table" and _G.BistooltipScannerMenuButton == nil then
          pcall(function()
            local b = CreateFrame("Button", "BistooltipScannerMenuButton", MerchantFrame)
            if b == nil then return end
            if type(b.SetSize) == "function" then b:SetSize(80, 22)
            else b:SetWidth(80) b:SetHeight(22) end
            b:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -145, -28)
            b:SetText("Bis Menu")
            styleDarkButton(b)
            b:SetScript("OnClick", function() Bistooltip_Scanner_ShowMenu() end)
          end)
        end
        refreshStatus()
      end)
    end)
  end
end
