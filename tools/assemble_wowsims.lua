-- tools/assemble_wowsims.lua — OFFLINE faction assembly for the wowsims DB.
-- 1:1 port of upstream (ExoJdi BiS-Tooltip_335a_fixed_backport, Config.lua
-- assembleActiveBislists) — moved offline per spec v2.3/v2.4. Computes BOTH
-- faction finals, emits the COMPACT representation:
--   Bistooltip_wowsims_final               (alliance base, full table)
--   Bistooltip_wowsims_horde_overrides     (whole slots where horde differs)
--   Bistooltip_wowsims_final_classes/_phases
-- Inputs (tracked, NOT loaded at runtime): Bistooltip_WoWSimsBP_bislists.lua
-- (3-table upstream file) + Bistooltip_faction.lua (item_faction map +
-- horde_to_ali). Usage: lua5.1 tools/assemble_wowsims.lua  (repo root)

dofile("Bistooltip/Bistooltip_WoWSimsBP_bislists.lua") -- primary + faction tables
dofile("Bistooltip/Bistooltip_faction.lua")            -- item_faction + horde_to_ali

local function isRealId(id) return id and id > 0 end

local function itemFaction(id)
  if type(Bistooltip_item_faction) == "table" then return Bistooltip_item_faction[id] end
  return nil
end

local function buildMirrorToMine(pf)
  local m = {}
  if type(Bistooltip_horde_to_ali) == "table" then
    for a, b in pairs(Bistooltip_horde_to_ali) do
      local fa = itemFaction(a)
      local fb = itemFaction(b)
      if fa == pf and fb and fb ~= pf then
        m[b] = a
      elseif fb == pf and fa and fa ~= pf then
        m[a] = b
      end
    end
  end
  return m
end

local function resolveId(id, mirror, pf)
  if mirror[id] then id = mirror[id] end
  if not isRealId(id) then return nil end
  local fr = itemFaction(id)
  if fr and pf and fr ~= pf then return nil end
  return id
end

local function groupWowsimsByName(wsSlots)
  local g = {}
  for _, s in ipairs(wsSlots) do
    local n = s.slot_name
    g[n] = g[n] or {}
    g[n][#g[n] + 1] = s
  end
  return g
end

local function packSlot(slot_name, enhs, result)
  local merged = { slot_name = slot_name, enhs = enhs }
  for col = 1, 6 do merged[col] = result[col] or -1 end
  return merged
end

local function mergeSlot(oldSlot, wsList, mirror, pf)
  local result, seen = {}, {}
  local function add(id)
    id = resolveId(id, mirror, pf)
    if id and not seen[id] and #result < 6 then
      seen[id] = true
      result[#result + 1] = id
    end
  end
  if wsList then
    for j = 1, #wsList do add(wsList[j][1]) end
  end
  for col = 1, 6 do add(oldSlot[col]) end
  return packSlot(oldSlot.slot_name, oldSlot.enhs, result)
end

local function translateSlots(slots, mirror, pf)
  if type(slots) ~= "table" then return slots end
  local out = {}
  for i, slot in ipairs(slots) do
    local result, seen = {}, {}
    for col = 1, 6 do
      local id = resolveId(slot[col], mirror, pf)
      if id and not seen[id] then seen[id] = true result[#result + 1] = id end
    end
    out[i] = packSlot(slot.slot_name, slot.enhs, result)
  end
  return out
end

local function mergeSpecPhase(wsSlots, oldSlots, mirror, pf)
  if type(oldSlots) ~= "table" then return translateSlots(wsSlots, mirror, pf) end
  local g = (type(wsSlots) == "table") and groupWowsimsByName(wsSlots) or nil
  local out = {}
  for i, oldSlot in ipairs(oldSlots) do
    local wsList = nil
    if g then
      local name = oldSlot.slot_name
      wsList = g[name]
      if not wsList and (name == "Ranged" or name == "Relic") then wsList = g["Relic"] end
    end
    out[i] = mergeSlot(oldSlot, wsList, mirror, pf)
  end
  return out
end

local function assemble(pf, primary)
  local fallback = Bistooltip_wowsims_bislists
  local mirror = buildMirrorToMine(pf)
  local active = {}
  if type(fallback) == "table" then
    for className, specs in pairs(fallback) do
      active[className] = active[className] or {}
      local wsClass = primary and primary[className]
      for specName, phases in pairs(specs) do
        active[className][specName] = active[className][specName] or {}
        local wsSpec = wsClass and wsClass[specName]
        for phaseName, oldSlots in pairs(phases) do
          local wsSlots = wsSpec and wsSpec[phaseName]
          active[className][specName][phaseName] = mergeSpecPhase(wsSlots, oldSlots, mirror, pf)
        end
      end
    end
  end
  if type(primary) == "table" then
    for className, specs in pairs(primary) do
      active[className] = active[className] or {}
      for specName, phases in pairs(specs) do
        active[className][specName] = active[className][specName] or {}
        for phaseName, wsSlots in pairs(phases) do
          if active[className][specName][phaseName] == nil then
            active[className][specName][phaseName] = translateSlots(wsSlots, mirror, pf)
          end
        end
      end
    end
  end
  return active
end

local function sameSlot(a, b)
  if a.slot_name ~= b.slot_name then return false end
  for i = 1, 6 do if a[i] ~= b[i] then return false end end
  local ae, be = a.enhs or {}, b.enhs or {}
  if #ae ~= #be then return false end
  for i = 1, #ae do
    if ae[i].type ~= be[i].type or ae[i].id ~= be[i].id then return false end
  end
  return true
end

-- run both factions
local A = assemble(1, Bistooltip_bislists_alliance)
local H = assemble(2, Bistooltip_bislists_horde)

-- D8 collapse: the RAW faction tables sometimes carry the same slot_name
-- twice (their own dual-slot convention: Weaponx2, Waistx2...) and phases
-- missing from the primary flow through translateSlots verbatim, leaking
-- that structure into the final view. The STANDARD model expresses duals
-- via RANKS in a single slot (like Finger/Trinket), so duplicate slot
-- entries are merged: rank lists concatenated, IDs deduped, capped at 6.
local function collapseDuplicates(list)
  local byName, order = {}, {}
  for _, slot in ipairs(list) do
    local name = slot.slot_name
    local tgt = byName[name]
    if not tgt then
      tgt = { slot_name = name, enhs = slot.enhs }
      for k = 1, 6 do tgt[k] = slot[k] or -1 end
      byName[name] = tgt
      order[#order + 1] = tgt
    else
      local seen = {}
      for k = 1, 6 do
        if type(tgt[k]) == "number" and tgt[k] > 0 then seen[tgt[k]] = true end
      end
      for k = 1, 6 do
        local id = slot[k]
        if type(id) == "number" and id > 0 and not seen[id] then
          for r = 1, 6 do
            if type(tgt[r]) ~= "number" or tgt[r] <= 0 then
              tgt[r] = id
              seen[id] = true
              break
            end
          end
        end
      end
      if (not tgt.enhs or #tgt.enhs == 0) and slot.enhs and #slot.enhs > 0 then
        tgt.enhs = slot.enhs
      end
    end
  end
  for i = 1, #list do list[i] = nil end
  for i, slot in ipairs(order) do list[i] = slot end
  return list
end
for _, faction in ipairs({ A, H }) do
  for _, specs in pairs(faction) do
    for _, phases in pairs(specs) do
      for _, list in pairs(phases) do
        collapseDuplicates(list)
      end
    end
  end
end

-- self-audit: no opposite-faction tagged ids inside either final
local function auditFaction(t, pf, label)
  local bad, slots = 0, 0
  for _, specs in pairs(t) do
    for _, phases in pairs(specs) do
      for _, list in pairs(phases) do
        for _, slot in ipairs(list) do
          slots = slots + 1
          for i = 1, 6 do
            local fr = itemFaction(slot[i])
            if fr and fr ~= pf then bad = bad + 1 end
          end
        end
      end
    end
  end
  assert(bad == 0, label .. ": " .. bad .. " opposite-faction ids leaked")
  return slots
end
local slotsA = auditFaction(A, 1, "alliance")
local slotsH = auditFaction(H, 2, "horde")

-- overrides: whole slots where horde differs from alliance base
local overrides, totalSlots = {}, 0
local nClasses, nSpecs = 0, 0
for className, specs in pairs(H) do
  nClasses = nClasses + 1
  for specName, phases in pairs(specs) do
    for phaseName, list in pairs(phases) do
      local abase = A[className] and A[className][specName] and A[className][specName][phaseName]
      for i, hslot in ipairs(list) do
        totalSlots = totalSlots + 1
        local aslot = abase and abase[i]
        if not aslot or not sameSlot(aslot, hslot) then
          overrides[className] = overrides[className] or {}
          overrides[className][specName] = overrides[className][specName] or {}
          overrides[className][specName][phaseName] = overrides[className][specName][phaseName] or {}
          overrides[className][specName][phaseName][i] = hslot
        end
      end
    end
  end
end
for _, specs in pairs(A) do
  for _ in pairs(specs) do nSpecs = nSpecs + 1 end
end
local nOverrideSlots = 0
for _, specs in pairs(overrides) do
  for _, phases in pairs(specs) do
    for _, m in pairs(phases) do
      for _ in pairs(m) do nOverrideSlots = nOverrideSlots + 1 end
    end
  end
end
assert(nClasses == 10, "expected 10 classes, got " .. nClasses)

-- ---------------------------------------------------------------------------
-- serializer (deterministic: numeric keys first, then sorted string keys)
-- ---------------------------------------------------------------------------
local function ser(v)
  local t = type(v)
  if t == "number" then return string.format("%.0f", v) end
  if t == "string" then return string.format("%q", v) end
  if t == "boolean" then return tostring(v) end
  if t ~= "table" then error("cannot serialize " .. t) end
  -- Dense detection WITHOUT #: #v on a sparse map is an UNDEFINED border
  -- (e.g. keys {1,4,6..14} may yield #v==1), which made the previous
  -- numInRange==n check pass and collapse sparse override maps again.
  -- Dense iff every key is a positive integer and they are exactly 1..N.
  local keys = {}
  local numKeys, maxKey, hasOther = 0, 0, false
  for k in pairs(v) do
    keys[#keys + 1] = k
    if type(k) == "number" and k >= 1 and k % 1 == 0 then
      numKeys = numKeys + 1
      if k > maxKey then maxKey = k end
    else
      hasOther = true
    end
  end
  local dense = (not hasOther) and (numKeys == maxKey) and (numKeys > 0 or next(v) == nil)
  table.sort(keys, function(a, b)
    if type(a) ~= type(b) then return type(a) == "number" end
    return a < b
  end)
  local parts = {}
  for _, k in ipairs(keys) do
    local idx = dense and k or nil
    if idx then
      parts[#parts + 1] = ser(v[idx])
    else
      parts[#parts + 1] = "[" .. ser(k) .. "] = " .. ser(v[k])
    end
  end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

local function writeVar(path, name, value, comment)
  local f = assert(io.open(path, "a"))
  if comment then f:write("-- " .. comment .. "\n") end
  f:write(name .. " = " .. ser(value) .. "\n")
  f:close()
end

local OUT = "Bistooltip/Bistooltip_wowsims_final.lua"
os.remove(OUT)
local f = assert(io.open(OUT, "w"))
f:write("-- Generated by tools/assemble_wowsims.lua - do not edit by hand.\n")
f:write("-- Offline faction assembly (upstream algorithm port, spec v2.3/v2.4):\n")
f:write("-- alliance = merged final base; horde = base + horde_overrides per slot.\n")
f:close()
writeVar(OUT, "Bistooltip_wowsims_final", A, "alliance base (merged: faction rank-1s + primary fallback)")
writeVar(OUT, "Bistooltip_wowsims_horde_overrides", overrides, "whole slots where the horde final differs from the alliance base")
writeVar(OUT, "Bistooltip_wowsims_final_classes", Bistooltip_wowsims_classes)
writeVar(OUT, "Bistooltip_wowsims_final_phases", Bistooltip_wowsims_phases)

print(string.format(
  "assembled: %d classes / %d specs | alliance %d slots, horde %d slots | horde overrides: %d/%d slots (%.1f%%)",
  nClasses, nSpecs, slotsA, slotsH, nOverrideSlots, totalSlots, nOverrideSlots / totalSlots * 100))
