-- tools/test_pluginapi.lua (Task 6: 5-function server plugin API, plain lua5.1)
-- Stubs core globals, then exercises BisTooltip:DefineSource/SetAcquisition/
-- AddAcquisition/SetBiSSlot/SetEnhancement (replace-wins + append + validation).
dofile("Bistooltip/SourceRegistry.lua"); dofile("Bistooltip/ItemAcquisition.lua")
dofile("Bistooltip/PluginAPI.lua")
assert(type(BisTooltip) == "table", "BisTooltip table must exist")
for _, fn in ipairs({ "DefineSource", "SetAcquisition", "AddAcquisition", "SetBiSSlot", "SetEnhancement" }) do
  assert(type(BisTooltip[fn]) == "function", "BisTooltip." .. fn .. " must exist")
end

-- Brief smoke lines (verbatim semantics).
BisTooltip:DefineSource("T_SRC", { instance = "I", boss = "B", difficulty = "25N" })
BisTooltip:SetAcquisition(1, { { kind = "DROP", source = "T_SRC" } })
assert(#BisTooltip_ItemAcquisition[1] == 1, "Set must replace")
BisTooltip:AddAcquisition(1, { kind = "CUSTOM", label = "Shop" })
assert(#BisTooltip_ItemAcquisition[1] == 2, "Add must append")
local ok = pcall(BisTooltip.DefineSource, BisTooltip, "BAD", { kind = "CUSTOM", label = "" })
assert(not ok, "empty CUSTOM label must be rejected")

-- Stub BiS core (shape mirrors Bistooltip_wowtbc_bislists slot tables).
Bistooltip_bislists = {
  Warrior = {
    Fury = {
      T9 = {
        { slot_name = "Chest", enhs = { { type = "spell", id = 1 } }, 111, 222 },
        { slot_name = "Weapon", enhs = { { type = "spell", id = 9 } }, 444 },
      },
      T10 = {
        { slot_name = "Chest", enhs = { { type = "spell", id = 2 } }, 333 },
        { slot_name = "Weapon", enhs = { { type = "spell", id = 59621 } }, 555 },
      },
    },
  },
}

-- SetAcquisition must replace, not merge.
BisTooltip:SetAcquisition(2, { { kind = "DROP", source = "T_SRC" } })
BisTooltip:SetAcquisition(2, { { kind = "CUSTOM", label = "Only" } })
assert(#BisTooltip_ItemAcquisition[2] == 1 and BisTooltip_ItemAcquisition[2][1].kind == "CUSTOM",
  "SetAcquisition must fully replace")

-- Shape validation (registry membership must NOT be required: DefineSource may come later).
BisTooltip:SetAcquisition(3, { { kind = "DROP", source = "LATER_SRC" } }) -- unknown sourceID: OK here
assert(BisTooltip_ItemAcquisition[3][1].source == "LATER_SRC", "forward source ref must be kept")
BisTooltip:DefineSource("LATER_SRC", { instance = "I2", boss = "B2", difficulty = "10N" })
assert(BisTooltip_SourceRegistry["LATER_SRC"].boss == "B2", "late DefineSource must register")
assert(not pcall(BisTooltip.SetAcquisition, BisTooltip, 4, { { kind = "BOGUS", source = "T_SRC" } }),
  "unknown kind must be rejected")
assert(not pcall(BisTooltip.SetAcquisition, BisTooltip, 4, { { kind = "DROP" } }),
  "missing sourceID must be rejected")
assert(not pcall(BisTooltip.SetAcquisition, BisTooltip, 4, { { kind = "TOKEN", tier = "T8", source = "T_SRC" } }),
  "TOKEN without family must be rejected")
assert(not pcall(BisTooltip.SetAcquisition, BisTooltip, 4, { { kind = "CUSTOM", label = "" } }),
  "empty CUSTOM label must be rejected in acquisition")
assert(not pcall(BisTooltip.AddAcquisition, BisTooltip, 4, { kind = "CUSTOM", label = "" }),
  "AddAcquisition must validate too")

-- Warn-once on core override with caller attribution.
local warned = {}
local realPrint = print
print = function(...) warned[#warned + 1] = table.concat({ ... }, " ") end
local coreID = next(BisTooltip_SourceRegistry) -- any real core source
BisTooltip:DefineSource(coreID, { instance = "Ov", boss = "Er", difficulty = "25N" }, "TestPlugin")
BisTooltip:DefineSource(coreID, { instance = "Ov", boss = "Er", difficulty = "25N" }, "TestPlugin")
print = realPrint
assert(#warned == 1 and warned[1] == "Plugin TestPlugin replaced core source " .. coreID,
  "expected exactly one override warning, got: " .. table.concat(warned, " | "))
local warned2 = {}
print = function(...) warned2[#warned2 + 1] = table.concat({ ... }, " ") end
local coreID2 = nil
for k in pairs(BisTooltip_SourceRegistry) do if k ~= coreID then coreID2 = k break end end
BisTooltip:DefineSource(coreID2, { instance = "Ov", boss = "Er" }) -- no plugin arg
print = realPrint
assert(#warned2 == 1 and warned2[1] == "Plugin unknown plugin replaced core source " .. coreID2,
  "missing caller must default to 'unknown plugin', got: " .. table.concat(warned2, " | "))

-- SetBiSSlot: replace ranked IDs only, keep slot_name/enhs.
BisTooltip:SetBiSSlot("Warrior", "Fury", "T10", "Chest", { 999001, 51289, 50024 }, "TestPlugin")
local slot = Bistooltip_bislists["Warrior"]["Fury"]["T10"][1]
assert(slot[1] == 999001 and slot[2] == 51289 and slot[3] == 50024 and slot[4] == nil,
  "SetBiSSlot must replace the ranked ID list")
assert(slot.slot_name == "Chest" and slot.enhs[1].id == 2, "SetBiSSlot must keep slot_name/enhs")
assert(not pcall(BisTooltip.SetBiSSlot, BisTooltip, "Warrior", "Fury", "T10", "Nope", { 1 }),
  "unknown slot must be rejected")
assert(not pcall(BisTooltip.SetBiSSlot, BisTooltip, "Warrior", "Fury", "T10", "Chest", {}),
  "empty ID list must be rejected")

-- SetEnhancement: replace enhs list with structural validation.
BisTooltip:SetEnhancement("Warrior", "Fury", "T10", "Weapon", { { type = "spell", id = 111 } }, "TestPlugin")
local w = Bistooltip_bislists["Warrior"]["Fury"]["T10"][2]
assert(#w.enhs == 1 and w.enhs[1].id == 111, "SetEnhancement must replace enhs")
assert(w[1] == 555, "SetEnhancement must keep ranked IDs")
assert(not pcall(BisTooltip.SetEnhancement, BisTooltip, "Warrior", "Fury", "T10", "Weapon",
  { { type = "", id = 1 } }), "empty enh type must be rejected")
assert(not pcall(BisTooltip.SetEnhancement, BisTooltip, "Warrior", "Fury", "T10", "Weapon",
  { { id = 1 } }), "enh without type must be rejected")

-- COMMON (phase=nil): apply to that slot in EVERY phase of the spec.
BisTooltip:SetEnhancement("Warrior", "Fury", nil, "Weapon", { { type = "item", id = 777 } }, "TestPlugin")
assert(Bistooltip_bislists["Warrior"]["Fury"]["T9"][2].enhs[1].id == 777, "COMMON must hit T9")
assert(Bistooltip_bislists["Warrior"]["Fury"]["T10"][2].enhs[1].id == 777, "COMMON must hit T10")

print("pluginapi: OK")
