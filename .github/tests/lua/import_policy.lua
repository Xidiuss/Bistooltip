-- From this worktree: lua5.1 .github/tests/lua/import_policy.lua <core-worktree>
local core=assert(arg[1],"core worktree path required")
local say=print
print=function() end
dofile(core.."/Bistooltip/SourceRegistry.lua")
dofile(core.."/Bistooltip/ItemAcquisition.lua")
dofile(core.."/Bistooltip/SourceFormatter.lua")
dofile(core.."/Bistooltip/PluginAPI.lua")
-- Rank behavior is covered by core's real-plugin matrix; inspect acquisitions here.
BisTooltip.InsertBiSSlotRank=function() end
local baseline={}
for id,entries in pairs(BisTooltip_ItemAcquisition) do
  local nonvendor={}
  for _,entry in ipairs(entries) do
    if entry.kind~="VENDOR" then nonvendor[BisTooltip_FormatSource(entry)]=true end
  end
  baseline[id]=nonvendor
end
dofile("Bistooltip_Whitemane_Frostmourne/main.lua")
local function check()
  local priced=0
  for id,entries in pairs(BisTooltip_ItemAcquisition) do
    local imported=false
    for _,entry in ipairs(entries) do
      if entry.kind=="VENDOR" then
        for _,cost in ipairs(entry.cost) do
          if cost.currency=="Justice" or cost.currency=="Valor" then imported=true end
        end
      end
    end
    if imported then
      priced=priced+1
      local seen,vendors={},0
      for _,entry in ipairs(entries) do
        seen[BisTooltip_FormatSource(entry)]=true
        if entry.kind=="VENDOR" then vendors=vendors+1 end
      end
      assert(vendors==1,"obsolete vendor price retained for "..id)
      for source in pairs(baseline[id] or {}) do
        assert(seen[source],"non-vendor source lost for "..id..": "..source)
      end
    end
  end
  assert(priced==112,"expected 112 reviewed Justice/Valor offers, got "..priced)
  for id,entries in pairs(BisTooltip_ItemAcquisition) do
    for _,entry in ipairs(entries) do
      assert(entry.kind~="VENDOR" or #entry.cost>0,"unverified empty vendor source for "..id)
    end
  end
  local stormcoil=BisTooltip_ItemAcquisition[150005]
  assert(#stormcoil==1 and stormcoil[1].cost[1].amount==80,"planned item overwrote Stormcoil price")
  local drops=0
  for _,entry in ipairs(BisTooltip_ItemAcquisition[46017]) do if entry.kind=="DROP" then drops=drops+1 end end
  assert(drops==14,"planned item overwrote Val'anyr drops")
end
check()
for round=1,4 do BisTooltip_ReplayOverlay(); check() end
say("Whitemane import policy: OK (112 prices; non-vendor routes and existing legendary prices retained; four replays)")
