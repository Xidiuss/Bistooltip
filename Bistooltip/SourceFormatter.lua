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
    return entry.tier .. " - " .. entry.kind .. ": " .. entry.family
      .. " [" .. s.instance .. ": " .. s.boss .. " <" .. s.difficulty .. ">]"
  end
  return nil
end
