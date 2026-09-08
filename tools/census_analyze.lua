-- tools/census_analyze.lua — reproducible BiS census (W0a).
-- Usage (repo root): lua5.1 tools/census_analyze.lua
-- Pure Lua 5.1, no WoW API. Replaces the one-off /tmp script from the
-- original 2026-09-07 census; metrics kept compatible for comparison.

_G.FACTION_ALLIANCE = "Alliance"
_G.FACTION_HORDE = "Horde"
dofile("Bistooltip/Bistooltip_wowtbc_bislists.lua")
dofile("Bistooltip/Bistooltip_wh_bislists.lua")
dofile("Bistooltip/Bistooltip_WoWSimsBP_bislists.lua")

local DBS = {
  wowtbc  = { bis = Bistooltip_wowtbc_bislists, classes = Bistooltip_wowtbc_classes, phases = Bistooltip_wowtbc_phases },
  wh      = { bis = Bistooltip_wh_bislists,     classes = Bistooltip_wh_classes,     phases = Bistooltip_wh_phases },
  wowsims = { bis = Bistooltip_wowsims_bislists, classes = Bistooltip_wowsims_classes, phases = Bistooltip_wowsims_phases },
}

local MAX_REAL_ID = 54591 -- WotLK max real item ID (census 2026-09-07)

local function census(name, db)
  local specs, combos, slots, entries, fillers = 0, 0, 0, 0, 0
  local unique, customs = {}, {}
  for _, cls in ipairs(db.classes) do
    specs = specs + #cls.specs
    local c = db.bis[cls.name]
    if c then
      for _, spec in ipairs(cls.specs) do
        local s = c[spec]
        if s then
          for _, phase in ipairs(db.phases) do
            local list = s[phase]
            if list then
              combos = combos + 1
              for _, slot in ipairs(list) do
                slots = slots + 1
                for i = 1, 6 do
                  local id = slot[i]
                  if type(id) == "number" then
                    entries = entries + 1
                    if id <= 0 then fillers = fillers + 1
                    else
                      unique[id] = true
                      if id > MAX_REAL_ID then customs[id] = true end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  local u, cu = 0, 0
  for _ in pairs(unique) do u = u + 1 end
  for id in pairs(customs) do cu = cu + 1 end
  print(string.format("%-8s classes=%d specs=%d combos=%d slots=%d entries=%d -1=%d unique=%d phases=%s CUSTOM_IDS=%d",
    name, #db.classes, specs, combos, slots, entries, fillers, u, table.concat(db.phases, ","), cu))
  if cu > 0 then
    local ids = {}
    for id in pairs(customs) do ids[#ids + 1] = id end
    table.sort(ids)
    print("         custom: " .. table.concat(ids, ", "))
  end
  return { unique = unique }
end

print("== Per-database census (refreshed upstream data) ==")
local sets = {}
for name, db in pairs(DBS) do sets[name] = census(name, db) end

-- index a DB by class/spec/phase/slot_name -> rank1
local function indexRank1(db)
  local idx = {}
  for cname, specs in pairs(db.bis) do
    for sname, phases in pairs(specs) do
      for pname, list in pairs(phases) do
        for _, slot in ipairs(list) do
          if slot.slot_name then
            idx[cname .. "\t" .. sname .. "\t" .. pname .. "\t" .. slot.slot_name] = slot[1]
          end
        end
      end
    end
  end
  return idx
end

local IDX = {}
for name, db in pairs(DBS) do IDX[name] = indexRank1(db) end

local function rank1agreement(a, b, onlyPhase)
  local same, tot = 0, 0
  for key, ra in pairs(IDX[a]) do
    if ra and ra > 0 then
      local _, _, phase = key:match("([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)")
      if not onlyPhase or phase == onlyPhase then
        local rb = IDX[b][key]
        if rb and rb > 0 then
          tot = tot + 1
          if ra == rb then same = same + 1 end
        end
      end
    end
  end
  return same, tot
end

print("\n== Rank-1 agreement (shared class/spec/phase/slot) ==")
for _, pair in ipairs({ {"wowsims", "wowtbc"}, {"wowsims", "wh"}, {"wowtbc", "wh"} }) do
  local same, tot = rank1agreement(pair[1], pair[2])
  print(string.format("%s vs %s: %d/%d (%.1f%%)", pair[1], pair[2], same, tot, tot > 0 and same / tot * 100 or 0))
end
print("wh vs wowsims per phase:")
for _, phase in ipairs(DBS.wowsims.phases) do
  local same, tot = rank1agreement("wh", "wowsims", phase)
  if tot > 0 then print(string.format("  %-3s %d/%d (%.1f%%)", phase, same, tot, same / tot * 100)) end
end

local function overlap(a, b)
  local n = 0
  for id in pairs(sets[a].unique) do if sets[b].unique[id] then n = n + 1 end end
  print(string.format("unique overlap %s∩%s = %d", a, b, n))
end
print("\n== Unique-item overlap ==")
overlap("wowsims", "wowtbc"); overlap("wowsims", "wh"); overlap("wowtbc", "wh")

-- faction tables (WoWSimsBP file)
print("\n== WoWSimsBP faction tables ==")
local function factionSlots(t)
  local n = 0
  for _, specs in pairs(t or {}) do
    for _, phases in pairs(specs) do
      for _, list in pairs(phases) do n = n + #list end
    end
  end
  return n
end
local A, H = Bistooltip_bislists_alliance, Bistooltip_bislists_horde
print(string.format("alliance slots=%d horde slots=%d", factionSlots(A), factionSlots(H)))
local same, tot = 0, 0
for cname, specs in pairs(A or {}) do
  for sname, phases in pairs(specs) do
    for pname, list in pairs(phases) do
      for i, slot in ipairs(list) do
        local hs = H and H[cname] and H[cname][sname] and H[cname][sname][pname] and H[cname][sname][pname][i]
        if hs then
          tot = tot + 1
          if hs[1] == slot[1] then same = same + 1 end
        end
      end
    end
  end
end
print(string.format("alliance vs horde rank-1 agreement: %d/%d (%.1f%%)", same, tot, tot > 0 and same / tot * 100 or 0))
print("\ncensus analysis: DONE")
