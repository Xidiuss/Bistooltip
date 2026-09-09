-- Bistooltip_Scanner/Scanner.lua
-- Minimal vendor + by-ID scanner (frozen scanner spec S1).
-- Standalone plugin: reads the merchant API and GetItemInfo, writes only
-- its own SavedVariables (BistooltipScannerDB). Never touches core tables.
-- Lua 5.1, Interface 30300. Every WoW global is guarded so this file also
-- loads in a headless harness (missing API = skipped feature, never an
-- error in the player's face).

BistooltipScannerDB = BistooltipScannerDB or {}

local PREFIX = "|cffffd000Bistooltip_Scanner:|r "

local function msg(text)
  if type(DEFAULT_CHAT_FRAME) == "table" and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(text), 1, 0.82, 0)
  elseif type(print) == "function" then
    print("Bistooltip_Scanner: " .. tostring(text))
  end
end

local function itemIDFromLink(link)
  if type(link) ~= "string" then return nil end
  local id = link:match("item:(%d+)")
  return id and tonumber(id) or nil
end

local function vendorKey(vendor, zone)
  return tostring(vendor or "?") .. " @ " .. tostring(zone or "")
end

local function today()
  if type(date) == "function" then return date("%Y-%m-%d") end
  return "????-??-??"
end

-- Odczyt awaryjny: tooltip pozycji vendora. Na serwerach gdzie
-- GetMerchantItemCostInfo zwraca 0 mimo widocznej ceny, tooltip
-- (SetMerchantItem) czasem niesie wiersze kosztu. Zwraca liste
-- wierszy albo nil. Wylacznie do diagnostyki / fallbacku.
local scanTip = nil
local function tipLinesFor(index)
  if type(CreateFrame) ~= "function" or UIParent == nil then return nil end
  local lines = nil
  local ok = pcall(function()
    if scanTip == nil then
      scanTip = CreateFrame("GameTooltip", "BistooltipScannerTip", UIParent, "GameTooltipTemplate")
    end
    if scanTip == nil or type(scanTip.SetOwner) ~= "function" then return end
    if type(scanTip.SetMerchantItem) ~= "function" then return end
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetMerchantItem(index)
    lines = {}
    for n = 1, 12 do
      local fs = _G["BistooltipScannerTipTextLeft" .. n]
      if fs == nil or type(fs.GetText) ~= "function" then break end
      local okT, txt = pcall(fs.GetText, fs)
      if okT and type(txt) == "string" and txt ~= "" then
        txt = txt:gsub("[\r\n]+", " ")
        if #txt > 120 then txt = txt:sub(1, 120) end
        lines[#lines + 1] = txt
        if #lines >= 8 then break end
      end
    end
    if type(scanTip.Hide) == "function" then scanTip:Hide() end
  end)
  if ok and type(lines) == "table" and #lines > 0 then return lines end
  return nil
end

local function currentVendor()
  local name, zone = nil, nil
  if type(UnitName) == "function" then
    local ok, v = pcall(UnitName, "npc")
    if ok then name = v end
  end
  if type(GetZoneText) == "function" then
    local ok, v = pcall(GetZoneText)
    if ok then zone = v end
  end
  return name or "?", zone or ""
end

local function finishRecord(key, rec)
  BistooltipScannerDB[key] = rec
  BistooltipScannerDB._lastKey = key
  local n = 0
  for _ in pairs(rec.items) do n = n + 1 end
  rec.count = n
  local nEmpty = 0
  for _, it in pairs(rec.items) do
    if type(it) == "table" and (it.money or 0) == 0 and #(it.costs or {}) == 0
      and type(_) == "number" then
      nEmpty = nEmpty + 1
    end
  end
  msg("Scanned " .. n .. " items: " .. key)
  if nEmpty > 0 then
    msg("no cost detected: " .. nEmpty .. " (hover items, wait, rescan; culprit line has EMPTY-COST)")
  end
  -- Cicho: snippet + okno dopiero na Export (po setcost).
  rec.lastExport = nil
  return n
end

-- Jeden slot vendora -> rec.items. Wspolne dla ScanVendor / ScanPage / Alt-klik.
-- st.uncached liczy braki cache. Zwraca klucz wpisu (itemID lub "pending:N") albo nil.
local function scanOne(rec, i, noCostAPI, st)
    local name, price, qty, numAvailable, extendedCost
    if type(GetMerchantItemInfo) == "function" then
      local ok, n, _t, p, q, na, _u, ec = pcall(GetMerchantItemInfo, i)
      if ok then
        name, price, qty, numAvailable, extendedCost = n, p, q, na, ec
      end
    end
    local link = nil
    if type(GetMerchantItemLink) == "function" then
      local ok, l = pcall(GetMerchantItemLink, i)
      if ok then link = l end
    end
    local itemID = itemIDFromLink(link)
    local limited = nil
    if type(numAvailable) == "number" and numAvailable >= 0 then
      limited = numAvailable
    end
    if itemID == nil then
      -- No link in cache: keep a positional placeholder so the slot is
      -- not lost. Rescan overwrites the whole record, so this can never
      -- duplicate a later keyed entry.
      st.uncached = st.uncached + 1
      rec.items["pending:" .. i] = { name = (name or "?"), money = (price or 0),
        costs = {}, qty = (qty or 1), limited = limited,
        uncached = true, index = i }
      return "pending:" .. i
    else
      local costs = {}
      local entryUncached = (name == nil)
      local nCostDbg = nil
      local canCost = (not noCostAPI and type(GetMerchantItemCostInfo) == "function"
        and type(GetMerchantItemCostItem) == "function")
      if canCost then
        -- Probujemy zawsze, nie tylko gdy extendedCost: czesc serwerow
        -- zle raportuje flage, a GetMerchantItemCostInfo mowi prawde.
        local okN, nCost = pcall(GetMerchantItemCostInfo, i)
        if okN and type(nCost) == "number" then
          nCostDbg = nCost
          if nCost > 0 then
            for c = 1, nCost do
              -- Stock 3.3.5a zwraca 3 wartosci (texture, value, link),
              -- bez nazwy: nazwe dobieramy sami przez GetItemInfo.
              local okC, _tex, amount, currLink = pcall(GetMerchantItemCostItem, i, c)
              if okC then
                local currID = itemIDFromLink(currLink)
                local currName = nil
                if currID and type(GetItemInfo) == "function" then
                  local okI, iname = pcall(GetItemInfo, currID)
                  if okI then currName = iname end
                end
                if currName == nil then entryUncached = true end
                table.insert(costs, { currID = currID, currName = currName, amount = amount })
              end
            end
          end
        end
      end
      if entryUncached then st.uncached = st.uncached + 1 end
      local tip = nil
      if #costs == 0 and (price or 0) == 0 then
        tip = tipLinesFor(i) -- tylko dla pustych: najwyzej nil w headless
      end
      rec.items[itemID] = { name = (name or "?"), money = (price or 0),
        costs = costs, qty = (qty or 1), limited = limited,
        uncached = entryUncached,
        noCostAPI = (noCostAPI and extendedCost) and true or nil,
        ext = extendedCost and true or nil, nCost = nCostDbg,
        tip = tip,
        index = i }
      return itemID
    end
end

-- Full vendor scan (spec S1). Call with the vendor window open.
-- Overwrites this vendor's record (no cross-vendor merge).
-- Returns the stored item count (0 = nothing saved).
function Bistooltip_Scanner_ScanVendor()
  if type(GetMerchantNumItems) ~= "function" then
    msg("No vendor open - nothing saved.")
    return 0
  end
  local okCount, count = pcall(GetMerchantNumItems)
  if not okCount or type(count) ~= "number" or count <= 0 then
    msg("Vendor empty or closed - nothing saved.")
    return 0
  end
  local noCostAPI = (type(GetMerchantItemCostItem) ~= "function")
  local vendor, zone = currentVendor()
  local key = vendorKey(vendor, zone)
  local rec = { vendor = vendor, zone = zone, date = today(), items = {} }
  local st = { uncached = 0 }
  for i = 1, count do scanOne(rec, i, noCostAPI, st) end
  local uncached = st.uncached
  if uncached > 0 then
    msg("not in cache (" .. uncached .. "), rescan.")
  end
  if noCostAPI then
    msg("no cost API - saved gold only (-- no cost API).")
  end
  return finishRecord(key, rec)
end

-- Skan biezacej strony vendora z MERGE do rekordu (duzi vendorzy:
-- przeklikaj strony, na kazdej Scan page, licznik rosnie do pelnego stanu).
-- Zwraca liczbe pozycji zeskanowanych na tej stronie.
function Bistooltip_Scanner_ScanPage()
  if type(GetMerchantNumItems) ~= "function" then
    msg("No vendor open - nothing saved.")
    return 0
  end
  if type(MerchantFrame) == "table" and tonumber(MerchantFrame.selectedTab) == 2 then
    msg("Buyback tab: go back to the sell tab and scan the page.")
    return 0
  end
  local okCount, count = pcall(GetMerchantNumItems)
  if not okCount or type(count) ~= "number" or count <= 0 then
    msg("Vendor empty or closed - nothing saved.")
    return 0
  end
  local perPage = tonumber(MERCHANT_ITEMS_PER_PAGE) or 10
  if perPage < 1 then perPage = 10 end
  local page = 1
  if type(MerchantFrame) == "table" then page = tonumber(MerchantFrame.page) or 1 end
  if page < 1 then page = 1 end
  local from = (page - 1) * perPage + 1
  if from > count then
    msg("Page " .. page .. " empty.")
    return 0
  end
  local to = math.min(from + perPage - 1, count)
  local noCostAPI = (type(GetMerchantItemCostItem) ~= "function")
  local vendor, zone = currentVendor()
  local key = vendorKey(vendor, zone)
  local rec = BistooltipScannerDB[key]
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    rec = { vendor = vendor, zone = zone, date = today(), items = {} }
  end
  local st = { uncached = 0 }
  local nNew = 0
  for i = from, to do scanOne(rec, i, noCostAPI, st) nNew = nNew + 1 end
  BistooltipScannerDB[key] = rec
  BistooltipScannerDB._lastKey = key
  local n = 0
  for _ in pairs(rec.items) do n = n + 1 end
  rec.count = n
  msg("Page " .. page .. ": " .. nNew .. " (total " .. n .. "): " .. key)
  if st.uncached > 0 then
    msg("not in cache (" .. st.uncached .. "), rescan the page.")
  end
  -- Cicho: snippet + okno dopiero na Export.
  rec.lastExport = nil
  return nNew
end

-- Marka przepisana z menu (pola Marka ID + ilosc), dopinana przez Alt+klik.
-- Menu synchronizuje ja przy kazdej zmianie pol; nil = brak marki.
Bistooltip_Scanner_PendingMark = Bistooltip_Scanner_PendingMark

-- Alt+klik na przycisk towaru: dopisz pozycje (z marka z menu) do rekordu.
-- Zwraca true gdy klik obsluzony (nigdy nie kupuje), false = pusc dalej.
local function altCapture(btn)
  if type(IsAltKeyDown) ~= "function" then return false end
  local okA, down = pcall(IsAltKeyDown)
  if not okA or not down then return false end
  if type(MerchantFrame) == "table" and tonumber(MerchantFrame.selectedTab) == 2 then
    return false
  end
  local bname = ""
  if type(btn) == "table" and type(btn.GetName) == "function" then
    local okN, nm = pcall(btn.GetName, btn)
    if okN then bname = tostring(nm or "") end
  end
  local slot = tonumber(bname:match("MerchantItem(%d+)"))
  if slot == nil or slot < 1 then return false end
  local perPage = tonumber(MERCHANT_ITEMS_PER_PAGE) or 10
  if perPage < 1 then perPage = 10 end
  local page = 1
  if type(MerchantFrame) == "table" then page = tonumber(MerchantFrame.page) or 1 end
  if page < 1 then page = 1 end
  local idx = (page - 1) * perPage + slot
  local okC, count = pcall(GetMerchantNumItems)
  if not okC or type(count) ~= "number" or idx < 1 or idx > count then
    return true -- zjedz klik: zly slot, ale i tak nie kupuj z Altem
  end
  local vendor, zone = currentVendor()
  local key = vendorKey(vendor, zone)
  local rec = BistooltipScannerDB[key]
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    rec = { vendor = vendor, zone = zone, date = today(), items = {} }
    BistooltipScannerDB[key] = rec
  end
  local noCostAPI = (type(GetMerchantItemCostItem) ~= "function")
  local st = { uncached = 0 }
  local storedKey = scanOne(rec, idx, noCostAPI, st)
  local applied = ""
  local pm = Bistooltip_Scanner_PendingMark
  if type(storedKey) == "number" and type(pm) == "table"
    and tonumber(pm.id) and tonumber(pm.id) > 0
    and tonumber(pm.amount) and tonumber(pm.amount) > 0 then
    local markID, amount = tonumber(pm.id), tonumber(pm.amount)
    local markName = nil
    if type(GetItemInfo) == "function" then
      local okI, nm = pcall(GetItemInfo, markID)
      if okI then markName = nm end
    end
    local it = rec.items[storedKey]
    if type(it) == "table" then
      it.costs = { { currID = markID, currName = markName, amount = amount } }
      if markName then it.uncached = (it.name == "?") end
      applied = " + " .. (markName or ("item:" .. markID)) .. " x" .. amount
    end
  end
  BistooltipScannerDB._lastKey = key
  local n = 0
  for _ in pairs(rec.items) do n = n + 1 end
  rec.count = n
  local shown = storedKey or ("slot " .. idx)
  msg("Alt: saved " .. tostring(shown) .. applied .. " (total " .. n .. ")")
  -- Cicho: snippet + okno dopiero na Export.
  rec.lastExport = nil
  return true
end

-- Owrapowanie OnClick przyciskow MerchantItemN: Alt+klik dopisuje pozycje
-- (i nigdy nie kupuje), zwykly klik leci oryginalna sciezka. Idempotentne.
function Bistooltip_Scanner_HookMerchantButtons()
  if type(CreateFrame) ~= "function" then return end
  for n = 1, 12 do
    for _, fname in ipairs({ "MerchantItem" .. n, "MerchantItem" .. n .. "ItemButton" }) do
      local b = _G[fname]
      if type(b) == "table" and not b._bisAltHooked
        and type(b.GetScript) == "function" and type(b.SetScript) == "function" then
        local okG, orig = pcall(b.GetScript, b, "OnClick")
        if okG and type(orig) == "function" then
          b._bisAltHooked = true
          pcall(b.SetScript, b, "OnClick", function(self, ...)
            local okH, handled = pcall(altCapture, self)
            if okH and handled then return end
            return orig(self, ...)
          end)
          break -- ten rzad obsluzony, nie hakuj dziecka
        end
      end
    end
  end
end

-- Manual by-ID scan (Task 6 delta). Works with NO vendor open:
-- GetItemInfo from cache; name="?" + UNCACHED flag when link is nil.
-- Keyed by itemID: rescan never duplicates. Export reuses the same S3
-- snippet path (VENDOR default, CUSTOM iff the custom toggle is set).
-- Returns the itemID, or nil on bad input.
function Bistooltip_Scanner_ScanByID(itemID)
  itemID = tonumber(itemID)
  if itemID == nil or itemID <= 0 then
    msg("Usage: /bisscan <itemID>")
    return nil
  end
  local name, link = nil, nil
  if type(GetItemInfo) == "function" then
    local ok, n, l = pcall(GetItemInfo, itemID)
    if ok then name, link = n, l end
  end
  BistooltipScannerDB["manual"] = BistooltipScannerDB["manual"]
    or { vendor = "Manual", zone = "", date = today(), items = {} }
  BistooltipScannerDB["manual"].items[itemID] = {
    name = (name or "?"), money = 0, costs = {}, qty = 1,
    limited = nil, uncached = (link == nil),
  }
  BistooltipScannerDB._lastKey = "manual"
  BistooltipScannerDB["manual"].lastExport = nil -- snippet dopiero na Export
  msg("Saved " .. itemID)
  return itemID
end

-- Reczne dopychanie kosztu dla serwerow gdzie klient nie dostaje cen
-- (dowod: ext=true/nCost=0 + tooltip bez linii ceny). Formy:
--   Bistooltip_Scanner_SetCost(markID, amount) -> wszystkie puste
--     pozycje ostatniego vendora (_lastKey)
--   Bistooltip_Scanner_SetCost(itemID, markID, amount) -> jedna pozycja
-- Zwraca liczbe dopelnionych pozycji.
function Bistooltip_Scanner_SetCost(a, b, c)
  local db = BistooltipScannerDB
  if type(db) ~= "table" then
    msg("No data: scan a vendor first.")
    return 0
  end
  local itemID, markID, amount
  if c ~= nil then
    itemID, markID, amount = tonumber(a), tonumber(b), tonumber(c)
  else
    markID, amount = tonumber(a), tonumber(b)
  end
  if markID == nil or markID <= 0 or amount == nil or amount <= 0
    or (c ~= nil and (itemID == nil or itemID <= 0)) then
    msg("Usage: /bisscan setcost <markID> <amount> | /bisscan setcost <itemID> <markID> <amount>")
    return 0
  end
  local key = db._lastKey
  local rec = (type(key) == "string") and db[key] or nil
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    msg("No data: scan a vendor first.")
    return 0
  end
  local markName = nil
  if type(GetItemInfo) == "function" then
    local okI, nm = pcall(GetItemInfo, markID)
    if okI then markName = nm end
  end
  -- Pamiec marki per vendor: menu podpowie ja przy kolejnym otwarciu.
  db._marks = (type(db._marks) == "table") and db._marks or {}
  db._marks[key] = { id = markID, amount = amount }
  -- Snapshot do Cofnij (listy kosztow podmieniamy w calosci, wiec
  -- referencje do starych list sa bezpieczne).
  local snap = { key = key, prev = {} }
  if itemID then
    local it0 = rec.items[itemID]
    if type(it0) == "table" then
      snap.prev[itemID] = { costs = it0.costs, uncached = it0.uncached }
    end
  else
    for id, it0 in pairs(rec.items) do
      if type(id) == "number" and type(it0) == "table"
        and (it0.money or 0) == 0 and #(it0.costs or {}) == 0 then
        snap.prev[id] = { costs = it0.costs, uncached = it0.uncached }
      end
    end
  end
  local n = 0
  if itemID then
    local it = rec.items[itemID]
    if type(it) ~= "table" then
      msg("No entry " .. itemID .. " in " .. key)
      return 0
    end
    it.costs = { { currID = markID, currName = markName, amount = amount } }
    if markName then it.uncached = (it.name == "?") end
    n = 1
  else
    for id, it in pairs(rec.items) do
      if type(id) == "number" and type(it) == "table"
        and (it.money or 0) == 0 and #(it.costs or {}) == 0 then
        it.costs = { { currID = markID, currName = markName, amount = amount } }
        if markName then it.uncached = (it.name == "?") end
        n = n + 1
      end
    end
  end
  msg("Cost applied " .. (markName or ("item:" .. markID)) .. " x" .. amount
    .. ": " .. n .. " entries (" .. key .. ")")
  -- Cicho: snippet + okno dopiero na Export.
  rec.lastExport = nil
  if n > 0 then db._undo = snap end
  return n
end

-- Cofnij ostatni setcost (jeden poziom). Zwraca liczbe przywroconych pozycji.
function Bistooltip_Scanner_Undo()
  local db = BistooltipScannerDB
  local u = (type(db) == "table") and db._undo or nil
  if type(u) ~= "table" or type(u.prev) ~= "table" then
    msg("Nothing to undo.")
    return 0
  end
  local rec = (type(u.key) == "string") and db[u.key] or nil
  local n = 0
  if type(rec) == "table" and type(rec.items) == "table" then
    for id, prev in pairs(u.prev) do
      local it = rec.items[id]
      if type(it) == "table" and type(prev) == "table" then
        it.costs = prev.costs or {}
        it.uncached = prev.uncached
        n = n + 1
      end
    end
    rec.lastExport = nil
  end
  db._undo = nil
  if n > 0 then msg("Cost undone: " .. n .. " entries (" .. tostring(u.key) .. ")") end
  return n
end

-- Domyslna marka vendora (markID, amount) albo nil. Menu wypelnia
-- nia puste pola przy skanie / otwarciu menu.
function Bistooltip_Scanner_RecallMark(key)
  local db = BistooltipScannerDB
  if type(db) ~= "table" or type(db._marks) ~= "table" then return nil end
  local m = db._marks[key or db._lastKey]
  if type(m) == "table" and tonumber(m.id) and tonumber(m.amount) then
    return tonumber(m.id), tonumber(m.amount)
  end
  return nil
end

-- Sety marek: nazwane presety {id, amount, note}, trwale w SV.
-- Aktywny jest JEDEN naraz (wybor checkboxem w menu). Wybor seta laduje
-- jego wartosci do pol Marka ID + ilosc, wiec cala istniejaca sciezka
-- (Set cost / Alt+klik / Scan ID) dziala bez zmian. Brak aktywnego =
-- reczne pola jak dotad. Limit chroni layout menu.
Bistooltip_Scanner_MaxMarkSets = 6

local function markSets()
  local db = BistooltipScannerDB
  if type(db) ~= "table" then return nil end
  if type(db._markSets) ~= "table" then db._markSets = {} end
  return db._markSets
end

function Bistooltip_Scanner_GetMarkSets()
  local t = markSets()
  if type(t) ~= "table" then return {} end
  return t
end

-- Dopisz pusty set. Zwraca indeks albo nil przy limicie.
function Bistooltip_Scanner_AddMarkSet()
  local t = markSets()
  if type(t) ~= "table" then return nil end
  if #t >= (Bistooltip_Scanner_MaxMarkSets or 6) then return nil end
  t[#t + 1] = { id = nil, amount = nil, note = "" }
  return #t
end

function Bistooltip_Scanner_RemoveMarkSet(i)
  local t = markSets()
  i = tonumber(i)
  if type(t) ~= "table" or i == nil or i < 1 or i > #t then return false end
  table.remove(t, i)
  local db = BistooltipScannerDB
  if type(db) == "table" then
    if db._markActive == i then
      db._markActive = nil
    elseif type(db._markActive) == "number" and db._markActive > i then
      db._markActive = db._markActive - 1
    end
  end
  return true
end

-- id/amount: liczby (Menu parsuje linki przez extractNum przed wywolaniem);
-- note: wolny tekst do 40 znakow, jedna linia.
function Bistooltip_Scanner_UpdateMarkSet(i, id, amount, note)
  local t = markSets()
  i = tonumber(i)
  if type(t) ~= "table" or i == nil or type(t[i]) ~= "table" then return false end
  id = tonumber(id)
  amount = tonumber(amount)
  if id ~= nil and id > 0 then t[i].id = math.floor(id) else t[i].id = nil end
  if amount ~= nil and amount > 0 then t[i].amount = math.floor(amount) else t[i].amount = nil end
  if type(note) == "string" then
    t[i].note = note:gsub("[\r\n]+", " "):sub(1, 40)
  end
  return true
end

-- i = indeks albo nil (odznacz wszystko). Zwraca true przy zmianie.
function Bistooltip_Scanner_SetActiveMarkSet(i)
  local db = BistooltipScannerDB
  if type(db) ~= "table" then return false end
  if i == nil then db._markActive = nil return true end
  i = tonumber(i)
  local t = markSets()
  if i == nil or type(t) ~= "table" or type(t[i]) ~= "table" then return false end
  db._markActive = i
  return true
end

-- Zwraca id, amount, note aktywnego seta albo nil.
function Bistooltip_Scanner_GetActiveMark()
  local db = BistooltipScannerDB
  local t = (type(db) == "table") and db._markSets or nil
  local i = (type(db) == "table") and db._markActive or nil
  if type(t) ~= "table" or type(i) ~= "number" or type(t[i]) ~= "table" then return nil end
  local s = t[i]
  if tonumber(s.id) and tonumber(s.amount) then
    return tonumber(s.id), tonumber(s.amount), tostring(s.note or "")
  end
  return nil
end

-- Krotka etykieta do statusu menu, np. 'Tarcze (90630x10)' albo '90630x10'.
function Bistooltip_Scanner_ActiveMarkLabel()
  local id, amt, note = Bistooltip_Scanner_GetActiveMark()
  if id == nil then return nil end
  if note ~= nil and note ~= "" then return note .. " (" .. id .. "x" .. amt .. ")" end
  return id .. "x" .. amt
end

-- Wspolny log do wklejenia calosci do wtyczki serwera.
-- "Dodaj do logu" dopina snippet vendora (ten sam klucz = aktualizacja,
-- nie duplikat). Export pokazuje caly log zamiast pojedynczego vendora.
function Bistooltip_Scanner_LogAdd(key)
  local db = BistooltipScannerDB
  if type(db) ~= "table" then
    msg("No data: scan a vendor first.")
    return 0
  end
  key = key or db._lastKey
  local rec = (type(key) == "string") and db[key] or nil
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    msg("No data: scan a vendor first.")
    return #(type(db._log) == "table" and db._log or {})
  end
  if type(Bistooltip_Scanner_BuildSnippet) ~= "function" then return 0 end
  local ok, text = pcall(Bistooltip_Scanner_BuildSnippet, key)
  if not ok or type(text) ~= "string" then
    msg("Snippet build failed for " .. key)
    return 0
  end
  db._log = (type(db._log) == "table") and db._log or {}
  local found = false
  for i, e in ipairs(db._log) do
    if type(e) == "table" and e.key == key then
      db._log[i] = { key = key, text = text }
      found = true
      break
    end
  end
  if not found then db._log[#db._log + 1] = { key = key, text = text } end
  msg("Log: " .. key .. " (" .. #db._log .. " vendors in log)")
  -- Historia cen: diff wzgledem poprzedniego zapisu tego vendora.
  local function priceSig(it)
    if type(it) ~= "table" then return "?" end
    local parts = { tostring(it.money or 0) }
    for _, c in ipairs(it.costs or {}) do
      parts[#parts + 1] = tostring(c.currID) .. ":" .. tostring(c.amount)
    end
    return table.concat(parts, "+")
  end
  db._history = (type(db._history) == "table") and db._history or {}
  local cur = {}
  for id, it in pairs(rec.items) do
    if type(id) == "number" then cur[id] = priceSig(it) end
  end
  local prev = db._history[key]
  if type(prev) == "table" and type(prev.sig) == "table" then
    local newN, goneN, chg = 0, 0, {}
    for id in pairs(cur) do
      if prev.sig[id] == nil then newN = newN + 1
      elseif prev.sig[id] ~= cur[id] then chg[#chg + 1] = id end
    end
    for id in pairs(prev.sig) do
      if cur[id] == nil then goneN = goneN + 1 end
    end
    local bits = {}
    if newN > 0 then bits[#bits + 1] = "+" .. newN .. " new" end
    if goneN > 0 then bits[#bits + 1] = "-" .. goneN end
    if #chg > 0 then
      table.sort(chg)
      local show = {}
      for i = 1, math.min(#chg, 5) do show[#show + 1] = chg[i] end
      bits[#bits + 1] = "price: " .. table.concat(show, ",") .. (#chg > 5 and "..." or "")
    end
    if #bits > 0 then msg("History " .. key .. ": " .. table.concat(bits, ", ")) end
  end
  db._history[key] = { date = today(), sig = cur }
  return #db._log
end

-- Caly log jako jeden tekst do wklejenia, albo nil gdy pusty.
function Bistooltip_Scanner_LogText()
  local db = BistooltipScannerDB
  if type(db) ~= "table" or type(db._log) ~= "table" or #db._log == 0 then
    return nil
  end
  local parts = { "-- Bistooltip_Scanner LOG | vendors: " .. #db._log .. " | " .. today() }
  for _, e in ipairs(db._log) do
    if type(e) == "table" and type(e.text) == "string" then
      parts[#parts + 1] = e.text
    end
  end
  return table.concat(parts, "\n")
end

function Bistooltip_Scanner_LogClear()
  if type(BistooltipScannerDB) == "table" then
    BistooltipScannerDB._log = nil
    BistooltipScannerDB._logText = nil
  end
  msg("Log cleared.")
  return true
end

-- Clear cache: usuwa WSZYSTKIE zeskanowane przedmioty (rekordy vendorow +
-- manual + log + historia + pamiec marek). Sety marek i przelacznik CUSTOM
-- to konfiguracja gracza — ZOSTAJA. Zwraca liczbe vendorow i pozycji.
function Bistooltip_Scanner_ClearCache()
  local db = BistooltipScannerDB
  if type(db) ~= "table" then return 0, 0 end
  local nV, nI = 0, 0
  for k, v in pairs(db) do
    if type(k) == "string" and k:sub(1, 1) ~= "_"
      and type(v) == "table" and type(v.items) == "table" then
      local c = 0
      for _ in pairs(v.items) do c = c + 1 end
      nI = nI + c
      nV = nV + 1
      db[k] = nil
    end
  end
  db._log = nil
  db._logText = nil
  db._csvText = nil
  db._lastKey = nil
  db._history = nil
  db._undo = nil
  db._marks = nil
  if type(Bistooltip_Scanner_Stab) == "table" then
    Bistooltip_Scanner_Stab.done = true
  end
  msg("Cache cleared: " .. nV .. " vendors, " .. nI .. " entries (mark sets kept).")
  return nV, nI
end

-- Wariant pod przycisk: destrukcyjne, wiec z popupem Tak/Nie gdy dostepny.
-- Headless (brak StaticPopup) = bezposrednie czyszczenie.
if type(StaticPopupDialogs) == "table" and StaticPopupDialogs["BISSCANNER_CLEAR"] == nil then
  StaticPopupDialogs["BISSCANNER_CLEAR"] = {
    text = "Delete all scanned items? Mark sets will stay.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
      Bistooltip_Scanner_ClearCache()
      if type(Bistooltip_Scanner_RefreshMarkSets) == "function" then
        pcall(Bistooltip_Scanner_RefreshMarkSets)
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
  }
end

function Bistooltip_Scanner_RequestClearCache()
  if type(StaticPopup_Show) == "function"
    and type(StaticPopupDialogs) == "table"
    and StaticPopupDialogs["BISSCANNER_CLEAR"] ~= nil then
    StaticPopup_Show("BISSCANNER_CLEAR")
    return true
  end
  Bistooltip_Scanner_ClearCache()
  if type(Bistooltip_Scanner_RefreshMarkSets) == "function" then
    pcall(Bistooltip_Scanner_RefreshMarkSets)
  end
  return true
end

-- Walidacja rekordu: {emptyN, emptySample, nonameN, nonameSample, badN, badSample}.
-- empty = brak kosztu i brak golda; noname = koszt bez ID waluty;
-- bad = ilosc nil/<=0. Proby do 5 ID dla zwiezlosci.
function Bistooltip_Scanner_ValidateKey(key)
  local r = { emptyN = 0, emptySample = {}, nonameN = 0, nonameSample = {}, badN = 0, badSample = {} }
  local db = BistooltipScannerDB
  local rec = (type(db) == "table" and type(key) == "string") and db[key] or nil
  if type(rec) ~= "table" or type(rec.items) ~= "table" then return r end
  local ids = {}
  for id in pairs(rec.items) do
    if type(id) == "number" then ids[#ids + 1] = id end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local it = rec.items[id]
    if type(it) == "table" then
      if (it.money or 0) == 0 and #(it.costs or {}) == 0 then
        r.emptyN = r.emptyN + 1
        if #r.emptySample < 5 then r.emptySample[#r.emptySample + 1] = id end
      else
        for _, c in ipairs(it.costs or {}) do
          if c.currID == nil then
            r.nonameN = r.nonameN + 1
            if #r.nonameSample < 5 then r.nonameSample[#r.nonameSample + 1] = id end
            break
          elseif c.amount == nil or tonumber(c.amount) == nil or tonumber(c.amount) <= 0 then
            r.badN = r.badN + 1
            if #r.badSample < 5 then r.badSample[#r.badSample + 1] = id end
            break
          end
        end
      end
    end
  end
  return r
end

local function logKeys()
  local db = BistooltipScannerDB
  local keys = {}
  if type(db) == "table" and type(db._log) == "table" and #db._log > 0 then
    for _, e in ipairs(db._log) do
      local k = nil
      if type(e) == "table" then k = e.key elseif type(e) == "string" then k = e end
      if type(k) == "string" then keys[#keys + 1] = k end
    end
  elseif type(db) == "table" and type(db._lastKey) == "string" then
    keys = { db._lastKey }
  end
  return keys
end

-- Walidacja calego eksportu: per-vendor + duplikaty ID miedzy vendorami.
-- Zwraca {perKey={key=validate}, dupes={id={keys}}, dupeN, emptyN}.
function Bistooltip_Scanner_ValidateLog()
  local r = { perKey = {}, dupes = {}, dupeN = 0, emptyN = 0 }
  local seen = {}
  local db = BistooltipScannerDB
  for _, key in ipairs(logKeys()) do
    local v = Bistooltip_Scanner_ValidateKey(key)
    r.perKey[key] = v
    r.emptyN = r.emptyN + v.emptyN
    if type(db) == "table" and type(db[key]) == "table" and type(db[key].items) == "table" then
      for id in pairs(db[key].items) do
        if type(id) == "number" then
          seen[id] = seen[id] or {}
          seen[id][#seen[id] + 1] = key
        end
      end
    end
  end
  for id, keys in pairs(seen) do
    if #keys > 1 then
      r.dupes[id] = keys
      r.dupeN = r.dupeN + 1
    end
  end
  return r
end

-- Gotowy tekst eksportu: swiezo budowany (nie zalezny od starych wpisow),
-- caly log albo biezacy vendor, z naglowkiem WARN gdy sa problemy.
-- Zwraca string albo nil.
function Bistooltip_Scanner_ExportText()
  if type(Bistooltip_Scanner_BuildSnippet) ~= "function" then return nil end
  local keys = logKeys()
  if #keys == 0 then return nil end
  local V = Bistooltip_Scanner_ValidateLog()
  local head = { "-- Bistooltip_Scanner EXPORT | vendors: " .. #keys .. " | " .. today() }
  for _, key in ipairs(keys) do
    local v = V.perKey[key]
    if v and v.emptyN > 0 then
      head[#head + 1] = "-- WARN: no cost: " .. key .. " (n=" .. v.emptyN
        .. ": " .. table.concat(v.emptySample, ", ") .. ")"
    end
    if v and v.nonameN > 0 then
      head[#head + 1] = "-- WARN: cost without currency ID: " .. key .. " (n=" .. v.nonameN
        .. ": " .. table.concat(v.nonameSample, ", ") .. ")"
    end
    if v and v.badN > 0 then
      head[#head + 1] = "-- WARN: suspicious amount: " .. key .. " (n=" .. v.badN
        .. ": " .. table.concat(v.badSample, ", ") .. ")"
    end
  end
  do
    local dids = {}
    for id in pairs(V.dupes) do dids[#dids + 1] = id end
    table.sort(dids)
    for _, id in ipairs(dids) do
      head[#head + 1] = "-- WARN: duplicate ID " .. id .. " in: " .. table.concat(V.dupes[id], " + ")
    end
  end
  -- DEDUPE: kazdy itemID eksportowany RAZ (ostatni vendor wygrywa, zgodnie
  -- z semantyka wklejania). Pomijane wystapienia trafiaja do notek ponizej.
  local winner = {}
  if type(Bistooltip_Scanner_DedupeWinners) == "function" then
    local okW, w = pcall(Bistooltip_Scanner_DedupeWinners, keys)
    if okW and type(w) == "table" then winner = w end
  end
  local dropped = {} -- id -> { from = key, to = winnerKey }
  local parts = { table.concat(head, "\n") }
  for _, key in ipairs(keys) do
    local skip = nil
    if type(Bistooltip_Scanner_SkipForKey) == "function" then
      local okS, s = pcall(Bistooltip_Scanner_SkipForKey, key, winner)
      if okS and type(s) == "table" then skip = s end
    end
    local ok, text, skipped = pcall(Bistooltip_Scanner_BuildSnippet, key, skip)
    if ok and type(text) == "string" then
      parts[#parts + 1] = text
      if type(skipped) == "table" then
        for _, id in ipairs(skipped) do
          dropped[id] = { from = key, to = winner[id] }
        end
      end
    end
  end
  do
    local dids = {}
    for id in pairs(dropped) do dids[#dids + 1] = id end
    table.sort(dids)
    local shown = 0
    for _, id in ipairs(dids) do
      shown = shown + 1
      if shown <= 20 then
        parts[#parts + 1] = "-- DEDUPE: " .. id .. " skipped in [" .. tostring(dropped[id].from)
          .. "], kept in [" .. tostring(dropped[id].to) .. "]"
      end
    end
    if #dids > 20 then
      parts[#parts + 1] = "-- DEDUPE: ... and " .. (#dids - 20) .. " more"
    end
  end
  if #parts < 2 then return nil end
  return table.concat(parts, "\n")
end

-- CSV calego eksportu (log albo biezacy vendor), sekcje poprzedzone "# klucz".
-- Dedupe jak w eksporcie S3 (ostatni vendor wygrywa per ID).
function Bistooltip_Scanner_CSVText()
  if type(Bistooltip_Scanner_BuildCSV) ~= "function" then return nil end
  local keys = logKeys()
  if #keys == 0 then return nil end
  local winner = {}
  if type(Bistooltip_Scanner_DedupeWinners) == "function" then
    local okW, w = pcall(Bistooltip_Scanner_DedupeWinners, keys)
    if okW and type(w) == "table" then winner = w end
  end
  local parts = {}
  for _, key in ipairs(keys) do
    local skip = nil
    if type(Bistooltip_Scanner_SkipForKey) == "function" then
      local okS, s = pcall(Bistooltip_Scanner_SkipForKey, key, winner)
      if okS and type(s) == "table" then skip = s end
    end
    local ok, text = pcall(Bistooltip_Scanner_BuildCSV, key, skip)
    if ok and type(text) == "string" then
      parts[#parts + 1] = "# " .. key
      parts[#parts + 1] = text
    end
  end
  if #parts == 0 then return nil end
  return table.concat(parts, "\n")
end

local function onSlash(raw)
  local s = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if s == "menu" then
    if type(Bistooltip_Scanner_ShowMenu) == "function" then
      Bistooltip_Scanner_ShowMenu()
    else
      msg("Menu unavailable (Menu.lua missing).")
    end
    return
  end
  if s == "custom" then
    if type(Bistooltip_Scanner_ToggleCustom) == "function" then
      local v = Bistooltip_Scanner_ToggleCustom()
      msg("CUSTOM: " .. (v and "ON (donate)" or "OFF (VENDOR)"))
    else
      msg("No CUSTOM toggle.")
    end
    return
  end
  if s == "export" or s == "log" then
    if type(Bistooltip_Scanner_ExportText) == "function" then
      local okE, text = pcall(Bistooltip_Scanner_ExportText)
      if okE and type(text) == "string" then
        local db = BistooltipScannerDB
        if type(db) == "table" then
          db._logText = text
          -- Pojedynczy vendor bez logu: odloz tez per-vendor (kompatybilnosc).
          if (type(db._log) ~= "table" or #db._log == 0)
            and type(db._lastKey) == "string"
            and type(db[db._lastKey]) == "table" then
            db[db._lastKey].lastExport = text
          end
        end
        if type(Bistooltip_Scanner_ShowExport) == "function" then
          pcall(Bistooltip_Scanner_ShowExport, text)
        end
        return
      end
    end
    msg("No data to export.")
    return
  end
  if s == "clearlog" then
    if type(Bistooltip_Scanner_LogClear) == "function" then
      Bistooltip_Scanner_LogClear()
    end
    return
  end
  if s == "clearcache" or s == "wyczysc" then
    if type(Bistooltip_Scanner_RequestClearCache) == "function" then
      Bistooltip_Scanner_RequestClearCache()
    end
    return
  end
  if s == "cofnij" or s == "undo" then
    if type(Bistooltip_Scanner_Undo) == "function" then
      Bistooltip_Scanner_Undo()
    end
    return
  end
  if s == "csv" then
    if type(Bistooltip_Scanner_CSVText) == "function" then
      local okC, text = pcall(Bistooltip_Scanner_CSVText)
      if okC and type(text) == "string" then
        if type(BistooltipScannerDB) == "table" then
          BistooltipScannerDB._csvText = text
        end
        if type(Bistooltip_Scanner_ShowExport) == "function" then
          pcall(Bistooltip_Scanner_ShowExport, text)
        end
        return
      end
    end
    msg("No data for CSV.")
    return
  end
  if s == "setcost" or s:match("^setcost%s") then
    local nums = {}
    for d in s:gmatch("%d+") do nums[#nums + 1] = tonumber(d) end
    if #nums == 3 then
      Bistooltip_Scanner_SetCost(nums[1], nums[2], nums[3])
    elseif #nums == 2 then
      Bistooltip_Scanner_SetCost(nums[1], nums[2])
    else
      msg("Usage: /bisscan setcost <markID> <amount> | /bisscan setcost <itemID> <markID> <amount>")
    end
    return
  end
  -- Nowy kanon: /bisscan | /bisscan <ID>. Stare /bis scan | /bis scan <ID>
  -- zostaje jako alias (gdy core nie nadpisze slasha).
  local id = s:match("^scan%s+(%d+)$") or s:match("^(%d+)$")
  if id then
    Bistooltip_Scanner_ScanByID(tonumber(id))
    return
  end
  if s == "" or s == "scan" then
    Bistooltip_Scanner_ScanVendor()
    return
  end
  if s == "page" then
    Bistooltip_Scanner_ScanPage()
    return
  end
  if s == "stab" then
    if type(Bistooltip_Scanner_Stabilize) == "function" then
      Bistooltip_Scanner_Stabilize()
    end
    return
  end
  msg("Usage: /bisscan | /bisscan page | /bisscan stab | /bisscan <itemID> | /bisscan menu | /bisscan export | /bisscan csv | /bisscan log | /bisscan clearlog | /bisscan clearcache | /bisscan custom | /bisscan setcost <markID> <amount> | /bisscan undo")
end

if type(SlashCmdList) == "table" then
  -- Wlasny slash: nie kolizja z core /bis (core rejestruje /bis pozniej
  -- i nadpisywal BISSCAN, przez co /bis scan [ID] odpalal glowny addon).
  SLASH_BISSCAN1 = "/bisscan"
  SLASH_BISSCAN2 = "/bisscanner"
  SlashCmdList["BISSCAN"] = onSlash
end
-- Exposed for the headless harness (and debugging).
Bistooltip_Scanner_OnSlash = onSlash

-- Auto-stabilizacja: vendor strumieniuje dane (126/64/51), wiec Stabilize
-- robi serie skanow z MERGE co ~1s az licznik stanie (2x to samo + zero
-- brakow cache) albo do limitu. Przerywa zamkniecie vendora.
Bistooltip_Scanner_Stab = nil

local STAB_MAX = 8

local function stabVendorOpen()
  if type(GetMerchantNumItems) ~= "function" then return nil end
  local okC, count = pcall(GetMerchantNumItems)
  if not okC or type(count) ~= "number" or count <= 0 then return nil end
  return count
end

local stabTimer = nil
local stabAccum = 0
local function ensureStabTimer()
  if stabTimer ~= nil then return end
  if type(CreateFrame) ~= "function" then return end
  local ok, f = pcall(CreateFrame, "Frame")
  if not ok or f == nil or type(f.SetScript) ~= "function" then return end
  stabTimer = f
  pcall(f.SetScript, f, "OnUpdate", function()
    local S = Bistooltip_Scanner_Stab
    if S == nil or S.done then return end
    stabAccum = stabAccum + 1
    if stabAccum >= 60 then -- ~1s przy 60fps; headless: tyka na wywolanie
      stabAccum = 0
      pcall(Bistooltip_Scanner_StabStep)
    end
  end)
end

function Bistooltip_Scanner_Stabilize()
  if stabVendorOpen() == nil then
    msg("No vendor open - nothing saved.")
    return nil
  end
  local vendor, zone = currentVendor()
  Bistooltip_Scanner_Stab = { key = vendorKey(vendor, zone),
    vendor = vendor, zone = zone, pass = 0, lastCount = -1, stable = 0, done = false }
  stabAccum = 0
  msg("Stabilizing: scanning until stable (max " .. STAB_MAX .. ")...")
  ensureStabTimer()
  return true
end

-- Jeden przebieg (timer; osobna funkcja dla testow i /bisscan stab x1).
-- Zwraca liczbe pozycji po przebiegu albo nil gdy koniec.
function Bistooltip_Scanner_StabStep()
  local S = Bistooltip_Scanner_Stab
  if S == nil or S.done then return nil end
  local count = stabVendorOpen()
  if count == nil then
    S.done = true
    msg("Stabilizing aborted (vendor closed).")
    return nil
  end
  local noCostAPI = (type(GetMerchantItemCostItem) ~= "function")
  local rec = BistooltipScannerDB[S.key]
  if type(rec) ~= "table" or type(rec.items) ~= "table" then
    rec = { vendor = S.vendor, zone = S.zone, date = today(), items = {} }
    BistooltipScannerDB[S.key] = rec
  end
  local st = { uncached = 0 }
  for i = 1, count do scanOne(rec, i, noCostAPI, st) end
  S.pass = S.pass + 1
  local n = 0
  for _ in pairs(rec.items) do n = n + 1 end
  rec.count = n
  BistooltipScannerDB._lastKey = S.key
  rec.lastExport = nil -- snippet dopiero na Export
  if n == S.lastCount and st.uncached == 0 then
    S.stable = S.stable + 1
  else
    S.stable = 0
  end
  S.lastCount = n
  if S.stable >= 2 or S.pass >= STAB_MAX then
    S.done = true
    if S.stable >= 2 then
      msg("Stable: " .. n .. " items (" .. S.key .. ")")
    else
      msg("Timeout: " .. n .. " items, still unstable (" .. S.key .. ")")
    end
  end
  return n
end

function Bistooltip_Scanner_StabStatus()
  local S = Bistooltip_Scanner_Stab
  if S == nil or S.done then return nil end
  return "stabilizing " .. S.pass .. "/" .. STAB_MAX .. " (last " .. S.lastCount .. ")"
end

-- Merchant-frame button + MERCHANT_SHOW hint (spec S1 trigger).
-- Fully guarded: absent without the vendor UI (headless harness).
local scanButton = nil
local function ensureButton()
  if scanButton ~= nil then return end
  if type(CreateFrame) ~= "function" or MerchantFrame == nil then return end
  local ok, b = pcall(CreateFrame, "Button", "BistooltipScannerButton", MerchantFrame)
  if not ok or b == nil then return end
  scanButton = b
  pcall(function()
    b:SetWidth(80)
    b:SetHeight(22)
    b:SetText("Scan BIS")
    b:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -60, -28)
    if type(Bistooltip_Scanner_StyleDarkButton) == "function" then
      pcall(Bistooltip_Scanner_StyleDarkButton, b)
    end
    b:SetScript("OnClick", function() Bistooltip_Scanner_ScanVendor() end)
  end)
end

if type(CreateFrame) == "function" then
  local ok, f = pcall(CreateFrame, "Frame")
  if ok and f ~= nil and type(f.RegisterEvent) == "function" then
    pcall(function()
      f:RegisterEvent("MERCHANT_SHOW")
      f:RegisterEvent("MERCHANT_CLOSED")
      f:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_CLOSED" then
          if type(Bistooltip_Scanner_Stab) == "table" then
            Bistooltip_Scanner_Stab.done = true
          end
          return
        end
        ensureButton()
        if type(Bistooltip_Scanner_HookMerchantButtons) == "function" then
          pcall(Bistooltip_Scanner_HookMerchantButtons)
        end
        msg("Click Scan BIS / Bis Menu or type /bisscan.")
      end)
    end)
  end
end
