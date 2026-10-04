-- From this worktree: lua5.1 .github/tests/lua/import_policy.lua <core-worktree>
local core=assert(arg[1],"core worktree path required")
local say=print
local printed,loaded={},{ }
print=function(message) printed[#printed+1]=tostring(message) end
DEFAULT_CHAT_FRAME={AddMessage=function(_,message) loaded[#loaded+1]=message end}
dofile(core.."/Bistooltip/SourceRegistry.lua")
dofile(core.."/Bistooltip/ItemAcquisition.lua")
dofile(core.."/Bistooltip/SourceFormatter.lua")
dofile(core.."/Bistooltip/PluginAPI.lua")
-- Rank application is covered by core's real-plugin matrix. Record the exact
-- declarations here so a wrong class/spec/phase/slot cannot hide behind it.
local insertions={}
BisTooltip.InsertBiSSlotRank=function(_,...) insertions[#insertions+1]={...} end
local baseline={}
for id,entries in pairs(BisTooltip_ItemAcquisition) do
  local nonvendor={}
  for _,entry in ipairs(entries) do
    if entry.kind~="VENDOR" then nonvendor[BisTooltip_FormatSource(entry)]=true end
  end
  baseline[id]=nonvendor
end
dofile("Bistooltip_Whitemane_Frostmourne/main.lua")
assert(#loaded==1 and loaded[1]=="Whitemane Frostmourne loaded",
  "plugin did not emit exactly one successful load message")
assert(#insertions==37,"expected 37 reviewed rank insertions, got "..#insertions)
local insertionKeys={}
for _,op in ipairs(insertions) do
  insertionKeys[table.concat({op[1],op[2],op[3],op[4],op[5],op[6]},"|")]=true
end
local function expectInsertion(className,spec,phase,slot,itemID)
  local key=table.concat({className,spec,phase,slot,1,itemID},"|")
  assert(insertionKeys[key],"missing rank insertion "..key)
end
expectInsertion("Druid","Feral dps","T9","Weapon",315010)
expectInsertion("Death knight","Blood tank","T9","Weapon",132001)
expectInsertion("Paladin","Protection","T9","Weapon",132003)
expectInsertion("Warrior","Protection","T9","Weapon",132003)
for _,spec in ipairs({"Beast mastery","Marksmanship","Survival"}) do
  expectInsertion("Hunter",spec,"T8","Ranged",150090)
  expectInsertion("Hunter",spec,"T9","Ranged",315005)
end
for _,message in ipairs(printed) do
  assert(not message:find("replaced core acquisition",1,true),
    "plugin emitted routine acquisition replacement spam")
end
local function check()
  local function hasVendor(itemID,currency,amount)
    for _,entry in ipairs(BisTooltip_ItemAcquisition[itemID] or {}) do
      if entry.kind=="VENDOR" then
        for _,cost in ipairs(entry.cost or {}) do
          if cost.currency==currency and cost.amount==amount then return true end
        end
      end
    end
    return false
  end
  local function hasRoute(itemID,kind,value)
    for _,entry in ipairs(BisTooltip_ItemAcquisition[itemID] or {}) do
      if entry.kind==kind and (entry.source==value or entry.label==value) then return true end
    end
    return false
  end
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
      if entry.kind=="VENDOR" then
        for _,cost in ipairs(entry.cost) do
          local isPhase2Emblem=cost.currency=="Emblem of Ascension"
            or cost.currency=="Emblem of Ascension II"
            or cost.currency=="Emblem of Ascension III"
          assert(not isPhase2Emblem,
            "phase 2 Emblem source is active for "..id..": "..tostring(cost.currency))
        end
      end
    end
  end
  assert(hasRoute(132001,"ACTIVITY","Whitemane quest (details pending)"),"Sulfuras quest route missing")
  assert(hasRoute(132003,"ACTIVITY","Whitemane quest (details pending)"),"Thunderfury quest route missing")
  assert(hasRoute(150005,"DROP","NAXXRAMAS_25N_KEL_THUZAD"),"Stormcoil 25N Kel'Thuzad drop missing")
  assert(hasVendor(45286,"Echo of the Titans",12),"active Echo of the Titans route missing")
  local drops=0
  for _,entry in ipairs(BisTooltip_ItemAcquisition[46017]) do if entry.kind=="DROP" then drops=drops+1 end end
  assert(drops==14,"planned item overwrote Val'anyr drops")
end
check()
for round=1,4 do BisTooltip_ReplayOverlay(); check() end
say("Whitemane import policy: OK (37 ranks; phase 2 Emblem sources disabled; 112 imported prices; four replays)")
