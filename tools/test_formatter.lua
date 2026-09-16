-- tools/test_formatter.lua
dofile("Bistooltip/SourceRegistry.lua") -- test-local fixture overrides globals below
BisTooltip_SourceRegistry = {
  VEZAX = { instance = "Ulduar", boss = "General Vezax", difficulty = "25N" },
  THORIM = { instance = "Ulduar", boss = "Thorim", difficulty = "25N" },
  FLAT = { instance = "Ulduar", boss = "General Vezax", difficulty = "" },
  AKN = { instance = "Ahn'kahet: The Old Kingdom", boss = "Prince Taldaram", difficulty = "HC" },
  HODIR_HM = { instance = "Ulduar", boss = "Hodir", difficulty = "25HM" },
}
dofile("Bistooltip/SourceFormatter.lua")
local cases = {
  { { kind = "DROP", source = "VEZAX" }, "Ulduar [25N] - General Vezax" },
  { { kind = "TOKEN", tier = "T8", family = "Wayward Protector", source = "THORIM" },
    "T8 - TOKEN: Wayward Protector\n [Ulduar: Thorim <25N>]" },
  { { kind = "MARK", tier = "T10", family = "Vanquisher's Mark", source = "THORIM" },
    "T10 - MARK: Vanquisher's Mark [Ulduar: Thorim <25N>]" },
  { { kind = "VENDOR", tier = "T9", cost = { { currency = "Emblem of Triumph", amount = 50 } } },
    "T9 - VENDOR: 50 Emblem of Triumph" },
  { { kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
      cost = { { item = 47242, amount = 1 }, { currency = "Emblem of Triumph", amount = 75 } } },
    "T9 - TROPHY: Crusade + 75 Emblem of Triumph" },
  { { kind = "CUSTOM", label = "VIP Shop" }, "VIP Shop" },
  { { kind = "VENDOR", tier = "T9", cost = { { currency = "Gold", amount = 150000 } } },
    "T9 - VENDOR: 15g" },
  { { kind = "VENDOR", tier = "T9", cost = { { currency = "Gold", amount = 150059 } } },
    "T9 - VENDOR: 15g 59c" },
  { { kind = "DROP", source = "FLAT" }, "Ulduar - General Vezax" }, -- empty difficulty: no brackets
  { { kind = "DROP", source = "NOPE" }, nil }, -- unknown sourceID: skip line, no error
  { { kind = "DROP", source = "AKN" }, "Ahn'kahet: The Old Kingdom [HC] - Prince Taldaram" }, -- 5-man heroic vocab v2
  { { kind = "TOKEN", tier = "T8", family = "Wayward Protector", source = "HODIR_HM" },
    "T8 - TOKEN: Wayward Protector\n [Ulduar: Hodir <25HM>]" }, -- 2-line: family 17+ chars
}
for i, c in ipairs(cases) do
  local got = BisTooltip_FormatSource(c[1])
  assert(got == c[2], "case " .. i .. ": got " .. tostring(got) .. ", want " .. tostring(c[2]))
end
print("formatter: OK (" .. #cases .. " cases)")

-- BisTooltip_GetVendorCost: single source of truth for vendor costs (W1 Task 2)
BisTooltip_ItemAcquisition = {
  [1] = { { kind = "VENDOR", cost = { { currency = "Emblem of Triumph", amount = 50 } } } },
  [2] = { { kind = "VENDOR", displayVariant = "TROPHY", tier = "T9",
            cost = { { item = 47242, amount = 1 }, { currency = "Emblem of Triumph", amount = 75 } } } },
  [3] = { { kind = "DROP", source = "VEZAX" } },
  [4] = { { kind = "DROP", source = "VEZAX" },
          { kind = "VENDOR", cost = { { item = 30183, amount = 1 }, { currency = "Emblem of Ascension II", amount = 150 } } } },
}
local vcases = {
  { 1, 50, "Emblem of Triumph" },   -- plain VENDOR
  { 2, 75, "Emblem of Triumph" },   -- TROPHY: currency part preferred over item part
  { 3, nil, nil },                  -- no VENDOR entry
  { 4, 150, "Emblem of Ascension II" }, -- VENDOR after a DROP entry
  { 999, nil, nil },                -- no acquisition at all
}
for i, c in ipairs(vcases) do
  local amount, currency = BisTooltip_GetVendorCost(c[1])
  assert(amount == c[2] and currency == c[3],
    "vcost case " .. i .. ": got " .. tostring(amount) .. "," .. tostring(currency)
    .. ", want " .. tostring(c[2]) .. "," .. tostring(c[3]))
end
print("vendorcost: OK (" .. #vcases .. " cases)")

-- W3: colored variant — identical MASTER structure, parts wrapped in |c…|r.
-- Palette defaults: instance FFD100, boss/family FFFFFF, method 00CCFF,
-- currency 00FFCC, diffN 9D9D9D, diffHC FF4040, diffHM FF9900.
local ccases = {
  { { kind = "DROP", source = "VEZAX" },
    "|cFFFFD100Ulduar|r |cFF00FF00[25N]|r - |cFFFFFFFFGeneral Vezax|r" },
  { { kind = "DROP", source = "AKN" },
    "|cFFFFD100Ahn'kahet: The Old Kingdom|r |cFFFF4040[HC]|r - |cFFFFFFFFPrince Taldaram|r" },
  { { kind = "TOKEN", tier = "T8", family = "Wayward Protector", source = "HODIR_HM" },
    "|cFF00CCFFT8 - TOKEN: |r|cFFFFFFFFWayward Protector|r\n |cFFFFD100[Ulduar: |r|cFFFFFFFFHodir |r|cFFFF9900<25HM>]|r" },
  { { kind = "VENDOR", tier = "T9", cost = { { currency = "Emblem of Triumph", amount = 50 } } },
    "|cFF00CCFFT9 - VENDOR: |r|cFF00FFCC50 Emblem of Triumph|r" },
  { { kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
      cost = { { item = 47242, amount = 1 }, { currency = "Emblem of Triumph", amount = 75 } } },
    "|cFF00CCFFT9 - TROPHY: |r|cFF00FFCCCrusade + |r|cFF00FFCC75 Emblem of Triumph|r" },
  { { kind = "CUSTOM", label = "VIP Shop" }, "|cFFFFFFFFVIP Shop|r" },
  { { kind = "DROP", source = "NOPE" }, nil },
}
for i, c in ipairs(ccases) do
  local got = BisTooltip_FormatSourceColored(c[1])
  assert(got == c[2], "colored case " .. i .. ":\n  got  " .. tostring(got) .. "\n  want " .. tostring(c[2]))
end
print("colored: OK (" .. #ccases .. " cases)")
