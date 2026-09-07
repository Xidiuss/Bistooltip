-- tools/census_bis.lua (usage: lua5.1 tools/census_bis.lua)
-- Loads the 3 ranking files with WoW API stubbed, prints per class/spec/phase
-- item counts + overlap stats. FAILS until the note + decision exist.
local f = io.open("docs/superpowers/specs/2026-09-07-bis-census.md", "r")
assert(f, "census note missing: run the census and record STANDARD decision")
local body = f:read("*a"); f:close()
assert(body:find("STANDARD = "), "census note must contain a 'STANDARD = ...' line")
print("census gate: OK")
