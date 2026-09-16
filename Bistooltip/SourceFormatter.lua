-- Bistooltip/SourceFormatter.lua (pure; no WoW API; warn-once via local flag table)
local warned = {}

-- Default source palette (spec S2-4; Q9: colors on by default).
-- "RRGGBB" hex; the colored renderer wraps fragments as |cFF<hex>…|r.
-- Constants.lua aliases this table as COLORS.SOURCE for the UI layers;
-- future options wiring can swap fields without touching the builder.
BisTooltip_SourcePalette = {
  instance = "FFD100", -- gold    — instance names
  boss     = "FFFFFF", -- white   — boss names
  family   = "FFFFFF", -- white   — token families / custom labels
  method   = "00CCFF", -- blue    — tier + TOKEN/MARK/VENDOR/TROPHY
  currency = "00FFCC", -- teal    — costs/currencies (legacy emblem color)
  diffN    = "00FF00", -- green   — …N difficulties (owner D20, 2026-09-10)
  diffHC   = "FF4040", -- red     — …HC difficulties
  diffHM   = "FF9900", -- orange  — …HM difficulties
}

local function diffColor(d)
  if d and d ~= "" then
    if d:find("HM", 1, true) then return BisTooltip_SourcePalette.diffHM end
    if d:find("HC", 1, true) then return BisTooltip_SourcePalette.diffHC end
    return BisTooltip_SourcePalette.diffN
  end
  return nil
end

-- Shared MASTER builder (spec S2/S2-4): ONE place assembles every string;
-- plain mode returns fragments verbatim (golden-locked), colored mode wraps
-- them per palette. Identity/dedup always uses the PLAIN rendering.
local function render(entry, colored)
  if type(entry) ~= "table" or not entry.kind then return nil end
  local P = BisTooltip_SourcePalette
  local function seg(hex, text)
    if colored and hex then return "|cFF" .. hex .. text .. "|r" end
    return text
  end
  if entry.kind == "CUSTOM" then
    if type(entry.label) == "string" and entry.label ~= "" then
      return seg(P.family, entry.label)
    end
    return nil
  end
  local function goldText(cu)
    -- canonical unit: COPPER (as returned by the merchant API / scanner)
    local g = math.floor(cu / 10000)
    local s = math.floor((cu % 10000) / 100)
    local c = cu % 100
    local t = {}
    if g > 0 then t[#t + 1] = g .. "g" end
    if s > 0 then t[#t + 1] = s .. "s" end
    if c > 0 or #t == 0 then t[#t + 1] = c .. "c" end
    return table.concat(t, " ")
  end
  local function costText(cost)
    local parts = {}
    for _, c in ipairs(cost or {}) do
      if c.currency == "Gold" then
        parts[#parts + 1] = seg(P.currency, goldText(c.amount or 0))
      elseif c.currency then
        parts[#parts + 1] = seg(P.currency, c.amount .. " " .. c.currency)
      end
    end
    return table.concat(parts, " + ")
  end
  if entry.kind == "VENDOR" then
    if entry.displayVariant == "TROPHY" then
      return seg(P.method, (entry.tier or "T9") .. " - TROPHY: ")
        .. seg(P.currency, (entry.variantLabel or "Crusade") .. " + ") .. costText(entry.cost)
    end
    local prefix = (entry.tier or "") .. (entry.tier and " - " or "") .. "VENDOR: "
    return seg(P.method, prefix) .. costText(entry.cost)
  end
  local s = entry.source and (BisTooltip_SourceRegistry or {})[entry.source] or nil
  if not s then
    if entry.source and not warned[entry.source] then warned[entry.source] = true end
    return nil
  end
  if entry.kind == "DROP" then
    if s.difficulty and s.difficulty ~= "" then
      return seg(P.instance, s.instance) .. " "
        .. seg(diffColor(s.difficulty), "[" .. s.difficulty .. "]") .. " - "
        .. seg(P.boss, s.boss)
    end
    return seg(P.instance, s.instance) .. " - " .. seg(P.boss, s.boss)
  end
  if entry.kind == "TOKEN" or entry.kind == "MARK" then
    -- S2: never Lua-error in tooltip; malformed entries render as nothing.
    if type(entry.tier) ~= "string" or entry.tier == ""
      or type(entry.family) ~= "string" or entry.family == ""
      or type(s.difficulty) ~= "string" then
      return nil
    end
    -- Owner (2026-09-15): long families (Grand Vanquisher etc.) break the
    -- line in two — the bracket part starts on a new line.
    local familyText = seg(P.family, entry.family)
    local bracket = seg(P.instance, "[" .. s.instance .. ": ")
      .. seg(P.boss, s.boss .. " ")
      .. seg(diffColor(s.difficulty), "<" .. s.difficulty .. ">]")
    local sep = " "
    if entry.kind == "TOKEN" and #entry.tier + #entry.family > 14 then
      sep = "\n "
    end
    return seg(P.method, entry.tier .. " - " .. entry.kind .. ": ")
      .. familyText .. sep .. bracket
  end
  return nil
end

function BisTooltip_FormatSource(entry)
  return render(entry, false)
end

function BisTooltip_FormatSourceColored(entry)
  return render(entry, true)
end

-- Single source of truth for vendor costs (W1): returns the amount and
-- currency name of the first VENDOR acquisition of an item, preferring a
-- currency part over an item part (TROPHY entries price in emblems).
function BisTooltip_GetVendorCost(itemID)
  local entries = (BisTooltip_ItemAcquisition or {})[itemID]
  if not entries then return nil, nil end
  for _, e in ipairs(entries) do
    if type(e) == "table" and e.kind == "VENDOR" then
      for _, c in ipairs(e.cost or {}) do
        if type(c) == "table" and type(c.currency) == "string" and c.currency ~= "" then
          return c.amount, c.currency
        end
      end
    end
  end
  return nil, nil
end
