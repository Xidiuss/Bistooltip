-- tools/test_formatter.lua
dofile("Bistooltip/SourceRegistry.lua") -- test-local fixture overrides globals below
BisTooltip_SourceRegistry = {
  VEZAX = { instance = "Ulduar", boss = "General Vezax", difficulty = "25N" },
  THORIM = { instance = "Ulduar", boss = "Thorim", difficulty = "25N" },
  FLAT = { instance = "Ulduar", boss = "General Vezax", difficulty = "" },
}
dofile("Bistooltip/SourceFormatter.lua")
local cases = {
  { { kind = "DROP", source = "VEZAX" }, "Ulduar [25N] - General Vezax" },
  { { kind = "TOKEN", tier = "T8", family = "Wayward Protector", source = "THORIM" },
    "T8 - TOKEN: Wayward Protector [Ulduar: Thorim <25N>]" },
  { { kind = "MARK", tier = "T10", family = "Vanquisher's Mark", source = "THORIM" },
    "T10 - MARK: Vanquisher's Mark [Ulduar: Thorim <25N>]" },
  { { kind = "VENDOR", tier = "T9", cost = { { currency = "Emblem of Triumph", amount = 50 } } },
    "T9 - VENDOR: 50 Emblem of Triumph" },
  { { kind = "VENDOR", tier = "T9", displayVariant = "TROPHY",
      cost = { { item = 47242, amount = 1 }, { currency = "Emblem of Triumph", amount = 75 } } },
    "T9 - TROPHY: Crusade + 75 Emblem of Triumph" },
  { { kind = "CUSTOM", label = "VIP Shop" }, "VIP Shop" },
  { { kind = "DROP", source = "FLAT" }, "Ulduar - General Vezax" }, -- empty difficulty: no brackets
  { { kind = "DROP", source = "NOPE" }, nil }, -- unknown sourceID: skip line, no error
}
for i, c in ipairs(cases) do
  local got = BisTooltip_FormatSource(c[1])
  assert(got == c[2], "case " .. i .. ": got " .. tostring(got) .. ", want " .. tostring(c[2]))
end
print("formatter: OK (" .. #cases .. " cases)")
