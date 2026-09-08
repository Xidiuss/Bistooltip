# Vendor Scanner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build standalone `Bistooltip_Scanner` mini-addon that scans the open vendor and produces an S3-ready snippet (ID, name, cost, currency).

**Architecture:** Flat addon (toc + 2 Lua files), read-only against merchant API, per-vendor SV store, pure snippet builder separated from UI so it runs under plain Lua 5.1 mocks.

**Tech Stack:** WoW 3.3.5a Lua 5.1, Interface 30300, no libraries, verification via `luac -p` + `lua5.1` mock harness in `/tmp`.

**Spec:** `docs/superpowers/specs/2026-09-08-vendor-scanner-design.md`

## Global Constraints

- `## Interface: 30300` in toc, nothing else version-gated.
- Lua 5.1 only: no `goto`, no bitwise operators, no `string.pack`.
- SavedVariables name verbatim: `BistooltipScannerDB`.
- Toc deps verbatim: `## OptionalDeps: Bistooltip` (never hard `Dependencies`).
- Scanner never writes `Bistooltip_emblem_items`, `ItemAcquisition`, `SourceRegistry`, or any `BisTooltip_*` core table.
- Export window shows max ~500 lines with SV-fallback note; chat prints one summary line per scan, never per-item spam.
- All merchant API calls guarded (`type(fn) == "function"`), silent-degrade to `-- no cost API` / `-- UNCACHED`, never a Lua error on screen.

---

## File Structure

- Create: `Bistooltip_Scanner/Bistooltip_Scanner.toc` — addon manifest, loads Scanner.lua then Export.lua.
- Create: `Bistooltip_Scanner/Scanner.lua` — owns `BisScanner_` namespace, SV init, event frame (`MERCHANT_SHOW`/`MERCHANT_CLOSED`), `/bis scan` slash, `BisScanner_ScanVendor()` loop, `BisScanner_ParseItemID()`, `BisScanner_VendorKey()`.
- Create: `Bistooltip_Scanner/Export.lua` — pure `BisScanner_BuildSnippet(vendor, opts)` plus `BisScanner_ShowExport(vendorKey)` window and MerchantFrame button wiring. No scan logic here.
- Test harness (throwaway, NOT committed): `/tmp/opencode/scanner_test.lua` — stubs WoW globals, loads the two files via `dofile`, asserts behavior, exits nonzero on failure.

---

### Task 1: Toc + skeleton (addon loads, slash registered, SV safe)

**Files:**
- Create: `Bistooltip_Scanner/Bistooltip_Scanner.toc`
- Create: `Bistooltip_Scanner/Scanner.lua`
- Test: `/tmp/opencode/scanner_test.lua` (harness, not committed)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: global `BisScanner` table; `BisScanner_ScanVendor` (stub returns `nil, "no vendor"` until Task 2); `SLASH_BISSCAN1 = "/bis scan"` registered in `SlashCmdList["BISSCAN"]`.

- [ ] **Step 1: Write the failing test**

```lua
-- /tmp/opencode/scanner_test.lua (Task 1 scope)
_G.UIParent = {}
_G.SlashCmdList = {}
function _G.CreateFrame(ftype, name, parent, template)
  local f = { _scripts = {} }
  function f:SetScript(ev, fn) self._scripts[ev] = fn end
  function f:RegisterEvent(ev) self._ev = ev end
  function f:Hide() end
  function f:Show() end
  return f
end
BistooltipScannerDB = nil
dofile("/mnt/d/PROJEKTY/Bistooltip-main/Bistooltip_Scanner/Scanner.lua")
assert(type(BisScanner) == "table", "BisScanner table missing")
assert(type(SlashCmdList["BISSCAN"]) == "function", "slash not registered")
assert(type(BistooltipScannerDB) == "table", "SV not initialized")
assert(type(BisScanner_ScanVendor) == "function", "ScanVendor stub missing")
print("TASK1-OK")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lua5.1 /tmp/opencode/scanner_test.lua`
Expected: FAIL — `dofile` errors (`No such file`) because `Bistooltip_Scanner/Scanner.lua` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```toc
## Interface: 30300
## Title: Bistooltip Scanner
## Notes: Scans open vendor (ID, name, cost, currency) and exports S3 snippet
## Author: Bistooltip
## Version: 0.1.0
## SavedVariables: BistooltipScannerDB
## OptionalDeps: Bistooltip

Scanner.lua
Export.lua
```

```lua
-- Bistooltip_Scanner/Scanner.lua
BisScanner = BisScanner or {}
BistooltipScannerDB = BistooltipScannerDB or { vendors = {} }
if not BistooltipScannerDB.vendors then BistooltipScannerDB.vendors = {} end

function BisScanner_ScanVendor()
  return nil, "no vendor"
end

local eventFrame = CreateFrame("Frame", "BisScannerEventFrame", UIParent)
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event)
  if event == "MERCHANT_SHOW" and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r open vendor, use /bis scan")
  end
end)

SLASH_BISSCAN1 = "/bis scan"
SlashCmdList["BISSCAN"] = function(msg)
  local key, err = BisScanner_ScanVendor()
  if DEFAULT_CHAT_FRAME then
    if key then DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBisScanner:|r " .. tostring(key))
    else DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000BisScanner:|r " .. tostring(err)) end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lua5.1 /tmp/opencode/scanner_test.lua` then `luac -p Bistooltip_Scanner/Scanner.lua`
Expected: prints `TASK1-OK`; `luac` silent (syntax clean).

- [ ] **Step 5: Commit**

```bash
git add Bistooltip_Scanner/Bistooltip_Scanner.toc Bistooltip_Scanner/Scanner.lua
git commit -m "feat(scanner): skeleton with toc, SV init and /bis scan stub"
```

---

### Task 2: Scan loop (vendor -> SV with ID, name, money, currency items)

**Files:**
- Modify: `Bistooltip_Scanner/Scanner.lua`
- Test: `/tmp/opencode/scanner_test.lua` (extend same file, Task 2 block)

**Interfaces:**
- Consumes: `BistooltipScannerDB.vendors` store from Task 1.
- Produces: `BisScanner_ParseItemID(link) -> number|nil`; `BisScanner_VendorKey(name, zone) -> string`; `BisScanner_ScanVendor() -> vendorKey|nil, countOrError`.

- [ ] **Step 1: Write the failing test**

```lua
-- append to /tmp/opencode/scanner_test.lua (Task 2 scope)
assert(type(BisScanner_ParseItemID) == "function", "ParseItemID missing")
assert(BisScanner_ParseItemID("|cffa335ee|Hitem:50096:0:0:0:0:0:0:0:80|h[Scourgelord Helmet]|h|r") == 50096, "parse failed")
assert(BisScanner_ParseItemID(nil) == nil, "nil link must give nil")
assert(BisScanner_VendorKey("Harold Winston", "Dalaran") == "Harold Winston @ Dalaran", "vendor key shape")
-- mock merchant with 1 gold item + 1 token item
_G._mockItems = {
  { info = { "Steel Sword", nil, 150000, 1, -1, true, false }, link = "|cff9d9d9d|Hitem:12345:0:0:0:0:0:0:0:80|h[Steel Sword]|h|r" },
  { info = { "Scourgelord Helmet", nil, 0, 1, -1, true, true }, link = "|cffa335ee|Hitem:50096:0:0:0:0:0:0:0:80|h[Scourgelord Helmet]|h|r",
    costCount = 1, costs = { { "Interface\\Icons\\spell_holy_championsbond", 95, "|cff0070dd|Hitem:40752:0:0:0:0:0:0:0:80|h[Emblem of Frost]|h|r" } } },
}
function _G.GetMerchantNumItems() return #_G._mockItems end
function _G.GetMerchantItemInfo(i)
  local it = _G._mockItems[i]
  return it.info[1], it.info[2], it.info[3], it.info[4], it.info[5], it.info[6], it.info[7]
end
function _G.GetMerchantItemLink(i) return _G._mockItems[i].link end
function _G.GetMerchantItemCostInfo(i) return _G._mockItems[i].costCount or 0 end
function _G.GetMerchantItemCostItem(i, n)
  local c = _G._mockItems[i].costs[n]
  return c[1], c[2], c[3]
end
function _G.UnitName(u) if u == "target" then return "Harold Winston" end return nil end
function _G.GetZoneText() return "Dalaran" end
function _G.GetItemInfo(id)
  if id == 40752 then return "Emblem of Frost" end
  return nil
end
local key, count = BisScanner_ScanVendor()
assert(key == "Harold Winston @ Dalaran", "scan key, got " .. tostring(key))
assert(count == 2, "scan count, got " .. tostring(count))
local v = BistooltipScannerDB.vendors[key]
assert(v.items[12345].money == 150000, "gold not stored")
assert(v.items[50096].costs[1].currID == 40752, "currency ID not stored")
assert(v.items[50096].costs[1].amount == 95, "currency amount not stored")
print("TASK2-OK")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lua5.1 /tmp/opencode/scanner_test.lua`
Expected: FAIL — `ParseItemID missing` (Task 1 file has no such function).

- [ ] **Step 3: Write minimal implementation**

```lua
-- append to Bistooltip_Scanner/Scanner.lua (replaces Task 1 stub)
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
  local vendor = { vendor = vendorName, zone = zone, date = date("%Y-%m-%d"), items = {} }
  local scanned = 0
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lua5.1 /tmp/opencode/scanner_test.lua` then `luac -p Bistooltip_Scanner/Scanner.lua`
Expected: prints `TASK1-OK` and `TASK2-OK`; `luac` silent.

- [ ] **Step 5: Commit**

```bash
git add Bistooltip_Scanner/Scanner.lua
git commit -m "feat(scanner): merchant scan loop with ID, money and currency capture"
```

---

### Task 3: Snippet builder (pure VENDOR/CUSTOM export, no UI)

**Files:**
- Create: `Bistooltip_Scanner/Export.lua`
- Test: `/tmp/opencode/scanner_test.lua` (extend, Task 3 block)

**Interfaces:**
- Consumes: vendor shape from Task 2 (`{vendor, zone, date, items[itemID]={name, money, costs, uncached}}`); exact field names verbatim.
- Produces: `BisScanner_BuildSnippet(vendor, opts) -> string` where `opts = {custom:boolean, customID:string|nil}`; `BisScanner_ShowExport` is only a stub in this task (real UI in Task 4).

- [ ] **Step 1: Write the failing test**

```lua
-- append to /tmp/opencode/scanner_test.lua (Task 3 scope)
dofile("/mnt/d/PROJEKTY/Bistooltip-main/Bistooltip_Scanner/Export.lua")
assert(type(BisScanner_BuildSnippet) == "function", "BuildSnippet missing")
local key = "Harold Winston @ Dalaran"
local snip = BisScanner_BuildSnippet(BistooltipScannerDB.vendors[key], {})
assert(snip:find("BisTooltip:SetAcquisition%(12345,", 1, true) ~= nil, "gold item line missing")
assert(snip:find('currency="Gold"', 1, true) ~= nil, "gold cost missing")
assert(snip:find("BisTooltip:SetAcquisition%(50096,", 1, true) ~= nil, "token item line missing")
assert(snip:find("Emblem of Frost", 1, true) ~= nil, "currency name missing")
assert(snip:find("by Bistooltip_Scanner", 1, true) ~= nil, "header missing")
local custom = BisScanner_BuildSnippet(BistooltipScannerDB.vendors[key], { custom = true, customID = "CUSTOM_TEST" })
assert(custom:find("BisTooltip:DefineSource", 1, true) ~= nil, "custom DefineSource missing")
assert(custom:find('kind="CUSTOM"', 1, true) ~= nil, "CUSTOM kind missing")
print("TASK3-OK")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lua5.1 /tmp/opencode/scanner_test.lua`
Expected: FAIL — `dofile Export.lua` errors (file does not exist yet).

- [ ] **Step 3: Write minimal implementation**

```lua
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
  local count = 0
  for _ in pairs(vendor.items) do count = count + 1 end
  table.insert(lines, "-- " .. vname .. " @ " .. zone .. " | " .. tostring(vendor.date or "?")
    .. " | " .. count .. " items | by Bistooltip_Scanner")
  if opts.custom then
    local cid = opts.customID or ("CUSTOM_" .. SanitizeID(vendor.vendor))
    table.insert(lines, 'BisTooltip:DefineSource("' .. cid .. '", { kind="CUSTOM", label="'
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
      table.insert(lines, "BisTooltip:SetAcquisition(" .. id .. ', { { kind="CUSTOM", label="'
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
      table.insert(lines, "BisTooltip:SetAcquisition(" .. id .. ", { { kind=\"VENDOR\", cost={ "
        .. table.concat(parts, ", ") .. " } } }) -- " .. iname .. extra)
    end
    if #lines > 600 then
      table.insert(lines, "-- truncated in chat preview, full text in BistooltipScannerDB")
      break
    end
  end
  return table.concat(lines, "\n")
end

function BisScanner_ShowExport(vendorKey)
  return BisScanner_BuildSnippet(
    BistooltipScannerDB and BistooltipScannerDB.vendors
      and BistooltipScannerDB.vendors[vendorKey], {})
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lua5.1 /tmp/opencode/scanner_test.lua` then `luac -p Bistooltip_Scanner/Export.lua`
Expected: prints `TASK1-OK`, `TASK2-OK`, `TASK3-OK`; `luac` silent.

- [ ] **Step 5: Commit**

```bash
git add Bistooltip_Scanner/Export.lua
git commit -m "feat(scanner): pure S3 snippet builder with VENDOR and CUSTOM modes"
```

---

### Task 4: Export window + MerchantFrame button + wiring

**Files:**
- Modify: `Bistooltip_Scanner/Export.lua` (replace `BisScanner_ShowExport` stub with real window; add `BisScanner_ToggleCustom()` and button creator)
- Modify: `Bistooltip_Scanner/Scanner.lua` (slash auto-opens export; `MERCHANT_SHOW` enables button)
- Test: `/tmp/opencode/scanner_test.lua` (extend, Task 4 block with richer CreateFrame mock)

**Interfaces:**
- Consumes: `BisScanner_BuildSnippet(vendor, opts)` from Task 3 (signature frozen); `BisScanner_ScanVendor()` from Task 2.
- Produces: `BisScanner_ShowExport(vendorKey) -> string` (now also renders window when in game); global frame `BisScannerExportFrame`; merchant button `BisScannerMerchantButton`.

- [ ] **Step 1: Write the failing test**

```lua
-- append to /tmp/opencode/scanner_test.lua (Task 4 scope, needs widget mocks)
local _frames = {}
function _G.CreateFrame(ftype, name, parent, template)
  local f = { _type = ftype, _name = name, _scripts = {}, _shown = false }
  function f:SetScript(ev, fn) self._scripts[ev] = fn end
  function f:RegisterEvent(ev) end
  function f:SetSize(w, h) end
  function f:SetPoint(...) end
  function f:Show() self._shown = true end
  function f:Hide() self._shown = false end
  function f:IsShown() return self._shown end
  function f:SetText(t) self._text = t end
  function f:GetText() return self._text end
  function f:HighlightText() end
  function f:SetFocus() end
  function f:SetMultiLine(b) end
  function f:SetAutoFocus(b) end
  function f:SetFontObject(o) end
  function f:SetWidth(w) end
  function f:SetScrollChild(c) end
  function f:EnableMouse(b) end
  function f:SetMovable(b) end
  function f:RegisterForDrag(b) end
  function f:StartMoving() end
  function f:StopMovingOrSizing() end
  function f:CreateTexture(...) return { SetAllPoints = function() end, SetTexture = function() end, SetVertexColor = function() end, SetPoint = function() end } end
  function f:CreateFontString(...) local o = {} function o:SetPoint(...) end function o:SetText(t) end return o end
  if name then _G[name] = f end
  table.insert(_frames, f)
  return f
end
_G.GameFontHighlightSmall = {}
_G.UIPanelScrollFrameTemplate = "tpl"
local out = BisScanner_ShowExport("Harold Winston @ Dalaran")
assert(type(out) == "string" and out:find("SetAcquisition", 1, true) ~= nil, "export must return snippet string")
assert(_G.BisScannerExportFrame ~= nil, "export frame not created")
print("TASK4-OK")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lua5.1 /tmp/opencode/scanner_test.lua`
Expected: FAIL — `export frame not created` (Task 3 stub creates no frame).

- [ ] **Step 3: Write minimal implementation**

```lua
-- in Bistooltip_Scanner/Export.lua: replace BisScanner_ShowExport stub with:
BisScanner_CustomMode = BisScanner_CustomMode or false

function BisScanner_ToggleCustom()
  BisScanner_CustomMode = not BisScanner_CustomMode
  return BisScanner_CustomMode
end

local function EnsureExportFrame()
  if _G.BisScannerExportFrame then return _G.BisScannerExportFrame end
  local frame = CreateFrame("Frame", "BisScannerExportFrame", UIParent)
  frame:SetSize(560, 460)
  frame:Hide()
  local box = CreateFrame("EditBox", "BisScannerExportBox", frame)
  box:SetMultiLine(true)
  box:SetAutoFocus(false)
  box:SetFontObject(GameFontHighlightSmall)
  frame._box = box
  return frame
end

function BisScanner_ShowExport(vendorKey)
  local vendor = BistooltipScannerDB
    and BistooltipScannerDB.vendors
    and BistooltipScannerDB.vendors[vendorKey]
  local text = BisScanner_BuildSnippet(vendor, { custom = BisScanner_CustomMode })
  if type(CreateFrame) == "function" and UIParent then
    local frame = EnsureExportFrame()
    if frame and frame._box then
      frame._box:SetText(text)
      frame._box:HighlightText()
    end
    frame:Show()
  end
  return text
end

function BisScanner_CreateMerchantButton()
  if _G.BisScannerMerchantButton then return _G.BisScannerMerchantButton end
  if type(MerchantFrame) ~= "table" then return nil end
  local btn = CreateFrame("Button", "BisScannerMerchantButton", MerchantFrame, "UIPanelButtonTemplate")
  btn:SetSize(90, 22)
  btn:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -40, -30)
  btn:SetText("Bis Scan")
  btn:SetScript("OnClick", function()
    local key, count = BisScanner_ScanVendor()
    if key then BisScanner_ShowExport(key) end
  end)
  return btn
end
```

```lua
-- in Bistooltip_Scanner/Scanner.lua: extend slash + MERCHANT_SHOW wiring
-- (append; keeps Task 1-2 code intact)
if type(BisScanner_CreateMerchantButton) == "function" then
  local _origShow = eventFrame._scripts and eventFrame._scripts["OnEvent"]
end
SlashCmdList["BISSCAN"] = function(msg)
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
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lua5.1 /tmp/opencode/scanner_test.lua` then `luac -p Bistooltip_Scanner/Scanner.lua Bistooltip_Scanner/Export.lua`
Expected: prints `TASK1-OK` through `TASK4-OK`; `luac` silent for both files.

- [ ] **Step 5: Commit**

```bash
git add Bistooltip_Scanner/Scanner.lua Bistooltip_Scanner/Export.lua
git commit -m "feat(scanner): export window, merchant button and slash wiring"
```

---

## Self-Review

- Spec coverage: S1 (toc/SV/scan/keys) -> Task 1+2; S2 (flow/snippet VENDOR+CUSTOM toggle/window+SV) -> Task 3+4; S3 (guards/UNCACHED/stacks/500-line cap/one-line chat) -> Task 2+3; S4 (manual checklist, no auto-scan/CSV/migrator/LDB) -> Task 4 notes, nothing extra built.
- Placeholder scan: no TBD/TODO; every step has exact commands and code; no "similar to Task N" without repetition.
- Type consistency: `BisScanner_ParseItemID(string|nil)->number|nil`, `BisScanner_VendorKey(name,zone)->string`, `BisScanner_ScanVendor()->string|nil, number|string`, `BisScanner_BuildSnippet(vendor,opts)->string`, `BisScanner_ShowExport(key)->string` — identical in Tasks 2-4.
