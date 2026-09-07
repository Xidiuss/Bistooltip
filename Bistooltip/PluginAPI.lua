-- Bistooltip/PluginAPI.lua (pure; no WoW API; plain Lua 5.1)
-- Frozen S3 5-function server plugin API over the canonical data model:
--   BisTooltip_SourceRegistry (sourceID -> facts)
--   BisTooltip_ItemAcquisition (itemID -> acquisition entries)
--   Bistooltip_bislists[class][spec][phase] (slot tables with slot_name/enhs + ranked IDs)
-- Semantics: DefineSource/SetAcquisition/SetBiSSlot/SetEnhancement = replace-wins,
-- AddAcquisition = append. Core overrides print a one-time dev warning
-- ("Plugin <name> replaced core ... <ID>", caller via trailing plugin arg or
-- "unknown plugin"). Malformed input raises a pcall-safe error (never silent).
-- Acquisition entries are shape-validated WITHOUT registry membership checks,
-- so plugins may SetAcquisition before DefineSource (any order).
-- SetEnhancement with phase=nil means COMMON: the slot's enhs is replaced in
-- EVERY phase of the spec that contains a slot with that slot_name.
BisTooltip = BisTooltip or {}

local warned = {}
local function plugName(p)
  if type(p) == "string" and p ~= "" then return p end
  return "unknown plugin"
end
local function noteOverride(key, msg)
  if not warned[key] then warned[key] = true print(msg) end
end

local KINDS = { DROP = true, TOKEN = true, MARK = true, VENDOR = true, CUSTOM = true }
local function checkEntry(e, what)
  if type(e) ~= "table" then error(what .. ": entry must be a table", 2) end
  if not KINDS[e.kind] then error(what .. ": unknown kind " .. tostring(e.kind), 2) end
  if e.kind == "CUSTOM" then
    if type(e.label) ~= "string" or e.label == "" then
      error(what .. ": CUSTOM needs non-empty label", 2)
    end
    return true
  end
  if e.kind == "VENDOR" then
    if type(e.cost) ~= "table" then error(what .. ": VENDOR needs cost table", 2) end
    for i, c in ipairs(e.cost) do
      if type(c) ~= "table" or type(c.amount) ~= "number"
        or (type(c.currency) ~= "string" and type(c.item) ~= "number") then
        error(what .. ": VENDOR cost part " .. i .. " malformed", 2)
      end
    end
    if e.tier ~= nil and (type(e.tier) ~= "string" or e.tier == "") then
      error(what .. ": VENDOR tier must be a non-empty string", 2)
    end
    if e.displayVariant ~= nil and (type(e.displayVariant) ~= "string" or e.displayVariant == "") then
      error(what .. ": VENDOR displayVariant must be a non-empty string", 2)
    end
    return true
  end
  if type(e.source) ~= "string" or e.source == "" then
    error(what .. ": " .. e.kind .. " needs sourceID", 2)
  end
  if e.kind == "DROP" then
    if e.tier ~= nil and (type(e.tier) ~= "string" or e.tier == "") then
      error(what .. ": DROP tier must be a non-empty string", 2)
    end
  else -- TOKEN / MARK
    if type(e.tier) ~= "string" or e.tier == "" then
      error(what .. ": " .. e.kind .. " needs tier", 2)
    end
    if type(e.family) ~= "string" or e.family == "" then
      error(what .. ": " .. e.kind .. " needs family", 2)
    end
  end
  return true
end

local function checkSourceDef(sourceID, def)
  local what = "BisTooltip.DefineSource"
  if type(sourceID) ~= "string" or sourceID == "" then
    error(what .. ": sourceID must be a non-empty string", 2)
  end
  if type(def) ~= "table" then error(what .. ": definition must be a table", 2) end
  if def.kind == "CUSTOM" then
    if type(def.label) ~= "string" or def.label == "" then
      error(what .. ': CUSTOM source "' .. sourceID .. '" needs non-empty label', 2)
    end
    return true
  end
  if def.kind ~= nil then error(what .. ": unknown source kind " .. tostring(def.kind), 2) end
  if type(def.instance) ~= "string" or def.instance == "" then
    error(what .. ': source "' .. sourceID .. '" needs instance', 2)
  end
  if type(def.boss) ~= "string" or def.boss == "" then
    error(what .. ': source "' .. sourceID .. '" needs boss', 2)
  end
  if def.difficulty ~= nil and type(def.difficulty) ~= "string" then
    error(what .. ': source "' .. sourceID .. '" difficulty must be a string', 2)
  end
  return true
end

local function checkEnhs(enhs, what)
  if type(enhs) ~= "table" or enhs[1] == nil then
    error(what .. ": enhs must be a non-empty list of {type=...,id=...}", 2)
  end
  for i, e in ipairs(enhs) do
    if type(e) ~= "table" then error(what .. ": enh #" .. i .. " must be a table", 2) end
    if type(e.type) ~= "string" or e.type == "" then
      error(what .. ": enh #" .. i .. " needs non-empty type", 2)
    end
    if type(e.id) ~= "number" then error(what .. ": enh #" .. i .. " needs numeric id", 2) end
  end
end
local function copyEnhs(enhs)
  local out = {}
  for i, e in ipairs(enhs) do out[i] = { type = e.type, id = e.id } end
  return out
end

local function specDataOf(className, specName, what)
  if type(className) ~= "string" or className == "" then
    error(what .. ": class must be a non-empty string", 2)
  end
  if type(specName) ~= "string" or specName == "" then
    error(what .. ": spec must be a non-empty string", 2)
  end
  if type(Bistooltip_bislists) ~= "table" then error(what .. ": Bistooltip_bislists missing", 2) end
  local classData = Bistooltip_bislists[className]
  if type(classData) ~= "table" then error(what .. ": unknown class " .. className, 2) end
  local specData = classData[specName]
  if type(specData) ~= "table" then error(what .. ": unknown spec " .. specName, 2) end
  return specData
end
local function findSlot(className, specName, phase, slotName, what)
  if type(phase) ~= "string" or phase == "" then
    error(what .. ": phase must be a non-empty string (nil means COMMON, SetEnhancement only)", 2)
  end
  if type(slotName) ~= "string" or slotName == "" then
    error(what .. ": slot must be a non-empty string", 2)
  end
  local specData = specDataOf(className, specName, what)
  local slots = specData[phase]
  if type(slots) ~= "table" then error(what .. ": unknown phase " .. phase, 2) end
  for _, slot in ipairs(slots) do
    if type(slot) == "table" and slot.slot_name == slotName then return slot end
  end
  error(what .. ": unknown slot " .. slotName, 2)
end

function BisTooltip:DefineSource(sourceID, def, plugin)
  checkSourceDef(sourceID, def)
  if type(BisTooltip_SourceRegistry) ~= "table" then
    error("BisTooltip.DefineSource: BisTooltip_SourceRegistry missing", 2)
  end
  if BisTooltip_SourceRegistry[sourceID] ~= nil then
    noteOverride("source:" .. sourceID,
      "Plugin " .. plugName(plugin) .. " replaced core source " .. sourceID)
  end
  BisTooltip_SourceRegistry[sourceID] = def
  return true
end

function BisTooltip:SetAcquisition(itemID, entries, plugin)
  local what = "BisTooltip.SetAcquisition"
  if type(itemID) ~= "number" or itemID <= 0 then
    error(what .. ": itemID must be a positive number", 2)
  end
  if type(entries) ~= "table" or entries[1] == nil then
    error(what .. ": entries must be a non-empty list", 2)
  end
  for _, e in ipairs(entries) do checkEntry(e, what) end
  if type(BisTooltip_ItemAcquisition) ~= "table" then
    error(what .. ": BisTooltip_ItemAcquisition missing", 2)
  end
  if BisTooltip_ItemAcquisition[itemID] ~= nil then
    noteOverride("acquisition:" .. tostring(itemID),
      "Plugin " .. plugName(plugin) .. " replaced core acquisition " .. tostring(itemID))
  end
  BisTooltip_ItemAcquisition[itemID] = entries
  return true
end

function BisTooltip:AddAcquisition(itemID, entry)
  local what = "BisTooltip.AddAcquisition"
  if type(itemID) ~= "number" or itemID <= 0 then
    error(what .. ": itemID must be a positive number", 2)
  end
  checkEntry(entry, what)
  if type(BisTooltip_ItemAcquisition) ~= "table" then
    error(what .. ": BisTooltip_ItemAcquisition missing", 2)
  end
  local list = BisTooltip_ItemAcquisition[itemID]
  if list == nil then
    list = {}
    BisTooltip_ItemAcquisition[itemID] = list
  elseif type(list) ~= "table" then
    error(what .. ": existing acquisition for item " .. tostring(itemID) .. " is corrupt", 2)
  end
  table.insert(list, entry)
  return true
end

function BisTooltip:SetBiSSlot(className, specName, phase, slotName, ids, plugin)
  local what = "BisTooltip.SetBiSSlot"
  if type(ids) ~= "table" or ids[1] == nil then
    error(what .. ": ids must be a non-empty list of itemIDs", 2)
  end
  for i, id in ipairs(ids) do
    if type(id) ~= "number" or id <= 0 then
      error(what .. ": itemID #" .. i .. " must be a positive number", 2)
    end
  end
  local slot = findSlot(className, specName, phase, slotName, what)
  for k in pairs(slot) do if type(k) == "number" then slot[k] = nil end end
  for i, id in ipairs(ids) do slot[i] = id end
  noteOverride("bis:" .. className .. "|" .. specName .. "|" .. phase .. "|" .. slotName,
    "Plugin " .. plugName(plugin) .. " replaced core BiS slot "
    .. className .. "/" .. specName .. "/" .. phase .. "/" .. slotName)
  return true
end

function BisTooltip:SetEnhancement(className, specName, phase, slotName, enhs, plugin)
  local what = "BisTooltip.SetEnhancement"
  checkEnhs(enhs, what)
  if type(slotName) ~= "string" or slotName == "" then
    error(what .. ": slot must be a non-empty string", 2)
  end
  if phase == nil then -- COMMON: every phase of the spec holding that slot
    local specData = specDataOf(className, specName, what)
    local n = 0
    for phaseName, slots in pairs(specData) do
      if type(slots) == "table" then
        for _, slot in ipairs(slots) do
          if type(slot) == "table" and slot.slot_name == slotName then
            slot.enhs = copyEnhs(enhs)
            noteOverride("enh:" .. className .. "|" .. specName .. "|" .. tostring(phaseName) .. "|" .. slotName,
              "Plugin " .. plugName(plugin) .. " replaced core enhancements "
              .. className .. "/" .. specName .. "/" .. tostring(phaseName) .. "/" .. slotName)
            n = n + 1
          end
        end
      end
    end
    if n == 0 then error(what .. ": unknown slot " .. slotName .. " (no phase of " .. specName .. " has it)", 2) end
    return true
  end
  local slot = findSlot(className, specName, phase, slotName, what)
  slot.enhs = copyEnhs(enhs)
  noteOverride("enh:" .. className .. "|" .. specName .. "|" .. phase .. "|" .. slotName,
    "Plugin " .. plugName(plugin) .. " replaced core enhancements "
    .. className .. "/" .. specName .. "/" .. phase .. "/" .. slotName)
  return true
end

return BisTooltip
