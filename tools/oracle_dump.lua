-- tools/oracle_dump.lua — offline fact extraction from the AtlasLoot oracle.
-- The oracle file is GPLv2 and NEVER committed: download it transiently, run
-- this tool, keep only the extracted facts (IDs/names/pages) in your notes
-- or in tools/tier_matrix.lua (spec S4-2).
--
-- Usage (repo root, oracle at /tmp/oracle_wotlk.lua):
--   wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && lua5.1 tools/oracle_dump.lua"
-- Outputs (WSL /tmp):
--   /tmp/oracle_keys.txt   — all page keys (page = boss x size x difficulty)
--   /tmp/token_rows.txt    — rows whose name mentions a tier family word
--   /tmp/matrix_facts.txt  — ICC marks, Tribute chests, T7/T8 token rows, 45614
--   stdout                 — canonical VOA zones (for Loot_Sources input)

local function autoTable() return setmetatable({}, { __index = function() return "" end }) end
_G.LibStub = function() return { GetLocale = function() return autoTable() end } end
_G.AtlasLoot_GetLocaleLibBabble = function() return autoTable() end
_G.LOCALIZED_CLASS_NAMES_MALE = autoTable()
_G.AtlasLoot_Data = {}
dofile("/tmp/oracle_wotlk.lua")
local D = assert(AtlasLoot_Data, "oracle did not populate AtlasLoot_Data")

local keys = {}
for k in pairs(D) do keys[#keys + 1] = k end
table.sort(keys)

local kf = assert(io.open("/tmp/oracle_keys.txt", "w"))
for _, k in ipairs(keys) do kf:write(k .. "\n") end
kf:close()

local function rows(key)
  local t = D[key]
  if type(t) ~= "table" then return nil end
  local r = {}
  for i = 1, #t do
    local row = t[i]
    if type(row) == "table" and type(row[2]) == "number" and row[2] > 0 then
      r[#r + 1] = string.format("%d\t%s\t%s", row[2], tostring(row[4]), tostring(row[5]))
    end
  end
  return r
end

local tf = assert(io.open("/tmp/token_rows.txt", "w"))
for _, k in ipairs(keys) do
  local r = rows(k)
  if r then
    for _, line in ipairs(r) do
      if line:find("Protector") or line:find("Conqueror") or line:find("Vanquisher")
        or line:find("of the Lost") or line:find("Mark of Sanctification") then
        tf:write(k .. "\t" .. line .. "\n")
      end
    end
  end
end
tf:close()

local out = assert(io.open("/tmp/matrix_facts.txt", "w"))
out:write("== ICC mark pages ==\n")
for _, k in ipairs(keys) do
  local r = rows(k)
  if r and k:sub(1, 3) == "ICC" then
    for _, line in ipairs(r) do
      if line:find("Mark of Sanctification") then out:write(k .. "\t" .. line .. "\n") end
    end
  end
end
out:write("== Tribute pages (all rows) ==\n")
for _, k in ipairs(keys) do
  if k:find("Tribute") then
    local r = rows(k)
    if r then for _, line in ipairs(r) do out:write(k .. "\t" .. line .. "\n") end end
  end
end
out:write("== T7/T8 token rows (raid pages) ==\n")
for _, k in ipairs(keys) do
  local r = rows(k)
  if r then
    for _, line in ipairs(r) do
      if line:find("of the Lost ") or line:find("of the Wayward ") then
        out:write(k .. "\t" .. line .. "\n")
      end
    end
  end
end
out:close()

-- Canonical VOA zones (stdout) — for splicing into Bistooltip/Loot_Sources.lua
local FULL = {
  Archavon = "Archavon the Stone Watcher",
  Emalon = "Emalon the Storm Watcher",
  Koralon = "Koralon the Flame Watcher",
  Toravon = "Toravon the Ice Watcher",
}
local zones = { ["10"] = {}, ["25"] = {} }
for _, k in ipairs(keys) do
  if k:sub(1, 15) == "VaultofArchavon" then
    local boss = k:match("^VaultofArchavon(%a+)") or ""
    if FULL[boss] then
      local diff = k:find("25Man") and "25" or "10"
      local acc = zones[diff][FULL[boss]]
      if not acc then acc = {}; zones[diff][FULL[boss]] = acc end
      for _, line in ipairs(rows(k) or {}) do
        local id = tonumber(line:match("^(%d+)\t"))
        if id then acc[id] = true end
      end
    end
  end
end
local function emit(title, zone)
  print(string.format('    ["%s"] = {', title))
  local bosses = {}
  for b in pairs(zone) do bosses[#bosses + 1] = b end
  table.sort(bosses)
  for _, b in ipairs(bosses) do
    local ids = {}
    for id in pairs(zone[b]) do ids[#ids + 1] = id end
    table.sort(ids)
    io.write(string.format('        ["%s"] = {\n', b))
    for i, id in ipairs(ids) do
      io.write("            " .. id)
      if i % 12 == 0 then io.write(",\n") elseif i < #ids then io.write(", ") else io.write("\n") end
    end
    if #ids % 12 ~= 0 then io.write("        },\n") else io.write("        },\n") end
  end
  print("    },")
end
emit("Vault of Archavon (10)", zones["10"])
emit("Vault of Archavon (25)", zones["25"])
io.stderr:write("oracle_dump: keys/token_rows/matrix_facts written to /tmp; VOA zones on stdout\n")
