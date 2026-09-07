-- tools/check_sources.lua (part 1; extended in Task 7)
local reg = dofile("Bistooltip/SourceRegistry.lua")
local acq = dofile("Bistooltip/ItemAcquisition.lua")
assert(type(reg) == "table" and type(acq) == "table", "generated files must return tables")
local n = 0 for _ in pairs(acq) do n = n + 1 end
assert(n > 1000, "expected >1000 acquired items, got " .. n)
for id, entries in pairs(acq) do
  for _, e in ipairs(entries) do
    if e.source then assert(reg[e.source], "dangling sourceID " .. tostring(e.source) .. " on item " .. id) end
  end
end
print("smoke: OK (" .. n .. " items)")
