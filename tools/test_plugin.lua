-- tools/test_plugin.lua — offline validation of a pure server plugin.
-- Loads the core source model + PluginAPI, runs the plugin's main.lua,
-- then asserts the plugin actually mutated the model and renders through
-- the MASTER formatter. Usage (repo root):
--   lua5.1 tools/test_plugin.lua Bistooltip_WOTLK5_S2/main.lua
local path = arg[1] or "Bistooltip_WOTLK5_S2/main.lua"

dofile("Bistooltip/SourceRegistry.lua")
dofile("Bistooltip/ItemAcquisition.lua")
dofile("Bistooltip/SourceFormatter.lua")
dofile("Bistooltip/PluginAPI.lua")

-- Plugins may touch ranking slots (SetBiSSlot/SetBiSSlotRank) — bind the
-- STANDARD database the same way Config.EnableSpec does at runtime.
if type(Bistooltip_bislists) ~= "table" then
  pcall(dofile, "Bistooltip/Bistooltip_wowsims_final.lua")
  if type(Bistooltip_wowsims_final) == "table" then
    Bistooltip_bislists = Bistooltip_wowsims_final
  end
end

local function itemCount(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end
local function entryCount(t)
  local n = 0
  for _, es in pairs(t) do n = n + #es end
  return n
end
local before = itemCount(BisTooltip_ItemAcquisition)
local beforeEntries = entryCount(BisTooltip_ItemAcquisition)

local ok, err = pcall(dofile, path)
assert(ok, "plugin raised: " .. tostring(err))

local after = itemCount(BisTooltip_ItemAcquisition)
local added = after - before
assert(added > 0 or entryCount(BisTooltip_ItemAcquisition) > beforeEntries,
  "plugin changed nothing")

-- collect vendor currencies introduced/touched by the plugin + renders
local currencies, rendered, unrenderable = {}, 0, 0
local sampleLines = {}
for id, entries in pairs(BisTooltip_ItemAcquisition) do
  for _, e in ipairs(entries) do
    if e.kind == "VENDOR" then
      for _, c in ipairs(e.cost or {}) do
        if c.currency then currencies[c.currency] = (currencies[c.currency] or 0) + 1 end
      end
    end
    local line = BisTooltip_FormatSource(e)
    if line then
      rendered = rendered + 1
      if #sampleLines < 4 and line:find("VENDOR") then sampleLines[#sampleLines + 1] = line end
    elseif e.kind ~= "DROP" or e.source then
      -- DROP entries with an unknown sourceID render nil by design (warn-once);
      -- anything else that fails to render is a plugin shape bug.
      if e.kind ~= "DROP" then unrenderable = unrenderable + 1 end
    end
  end
end
assert(unrenderable == 0, unrenderable .. " non-DROP entries failed to render")

print(string.format("plugin: OK (%s) | +%d new items, +%d appended entries (%d items total) | %d rendered lines",
  path, added, entryCount(BisTooltip_ItemAcquisition) - beforeEntries, after, rendered))
local cur = {}
for name, n in pairs(currencies) do cur[#cur + 1] = string.format("%s x%d", name, n) end
table.sort(cur)
print("currencies: " .. table.concat(cur, ", "))
for _, l in ipairs(sampleLines) do print("  e.g. " .. l) end
