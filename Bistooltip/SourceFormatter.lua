-- Bistooltip/SourceFormatter.lua (pure; no WoW API; warn-once via local flag table)
local warned = {}
function BisTooltip_FormatSource(entry)
  if type(entry) ~= "table" or not entry.kind then return nil end
  if entry.kind == "CUSTOM" then
    if type(entry.label) == "string" and entry.label ~= "" then return entry.label end
    return nil
  end
  local reg = BisTooltip_SourceRegistry or {}
  local function costText(cost)
    local parts = {}
    for _, c in ipairs(cost or {}) do
      if c.currency then table.insert(parts, c.amount .. " " .. c.currency) end
    end
    return table.concat(parts, " + ")
  end
  if entry.kind == "VENDOR" then
    if entry.displayVariant == "TROPHY" then return (entry.tier or "T9") .. " - TROPHY: Crusade + " .. costText(entry.cost) end
    return (entry.tier or "") .. (entry.tier and " - " or "") .. "VENDOR: " .. costText(entry.cost)
  end
  local s = entry.source and reg[entry.source] or nil
  if not s then
    if entry.source and not warned[entry.source] then warned[entry.source] = true end
    return nil
  end
  if entry.kind == "DROP" then
    if s.difficulty and s.difficulty ~= "" then
      return s.instance .. " [" .. s.difficulty .. "] - " .. s.boss
    end
    return s.instance .. " - " .. s.boss
  end
  if entry.kind == "TOKEN" or entry.kind == "MARK" then
    -- S2: never Lua-error in tooltip; malformed entries render as nothing.
    if type(entry.tier) ~= "string" or entry.tier == ""
      or type(entry.family) ~= "string" or entry.family == ""
      or type(s.difficulty) ~= "string" then
      return nil
    end
    return entry.tier .. " - " .. entry.kind .. ": " .. entry.family
      .. " [" .. s.instance .. ": " .. s.boss .. " <" .. s.difficulty .. ">]"
  end
  return nil
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
