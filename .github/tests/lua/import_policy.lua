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
  -- Owner scans dated 2026-10-05; chest/gloves prices confirmed for all classes.
  local reviewed={
    {"Valor",700,{39728,39757,40191,40207,40267,40268,40321,40322,40337,40342}},
    {"Valor",2200,{40635}},
    {"Valor",1650,{40638,40742,40743,40745,40746,40747,40748,40749,40750,40751}},
    {"Valor",1250,{40717,40718,40719,40720,40721,40722,40723,40724,
      40733,40734,40735,40736,40737,40738,40739,40740,40741}},
    {"Honor Points",1650,{43950,44710,44711,44713,49702}},
    {"Justice",2200,{40610,40611,40612}},
    {"Justice",1650,{40613,40614,40615}},
  }
  local pvp={
    {"Mark of Savagery",1,{42557,42511,42356,42221,42295,42212,42206,42294,42523,42382,44416,42344,42297,42535,42213,42446,42574,42575,42576,42219,42220,42611,42612,42445,42215,42517,42296,40778,44415,42444,42448,42595,42594,42593,42343,42224,42618,42217,42556,42216,42218,42447,42529,42568,42223,42222,40856,40836,40816,40797}},
    {"Honor Points",2200,{40783,40819,40840}},
    {"Honor Points",1650,{40801,40859,40877,40878,42122,42123}},
    {"Honor Points",1250,{40887,42020,42021,42022,42023,42024,42025,42026,42055,42056,42057,42058,42059,42060,42061,42110,42112}},
    {"Honor Points",2450,{42207,42241,42259,42274,42284,42345,42351,42558,42563,42569}},
    {"Honor Points",950,{42226,42231,42247,42254,42264,42269,42279,42289,42524,42530,42536}},
    {"Honor Points",3400,{42316,42321,42326,42331,42359,42383,42484,42489,42494,42501,42512,42518,44417,44418}},
    {"Honor Points",700,{42449,42577,42582,42587,42596,42601,42606,42613,42619,42851}},
    {"Arena Points",2200,{40786,40823,40844}},
    {"Arena Points",1650,{40804,40862,40880,42128,42129,42130,42131,42132}},
    {"Arena Points",1250,{40879,40888,42027,42028,42029,42030,42031,42032,42033,42062,42063,42064,42065,42066,42067,42068,42114,42115}},
    {"Arena Points",2450,{42208,42242,42260,42275,42285,42346,42352}},
    {"Arena Points",950,{42227,42232,42248,42255,42265,42270,42280,42290,42525,42531,42537,42559,42564,42570}},
    {"Arena Points",3400,{42317,42322,42327,42332,42362,42384,42485,42490,42495,44419,44420}},
    {"Arena Points",700,{42450,42502,42513,42519,42578,42583,42588,42597,42602,42607,42614,42620,42852}},
  }
  for _,group in ipairs(pvp) do reviewed[#reviewed+1]=group end
  for _,group in ipairs(reviewed) do
    for _,id in ipairs(group[3]) do
      assert(hasVendor(id,group[1],group[2]),"incorrect scanned vendor price for "..id)
      local amount,currency=BisTooltip_GetVendorCost(id)
      assert(amount==group[2] and currency==group[1],"incorrect displayed vendor cost for "..id)
      local vendors,seen=0,{}
      for _,entry in ipairs(BisTooltip_ItemAcquisition[id]) do
        if entry.kind=="VENDOR" then vendors=vendors+1 end
        seen[BisTooltip_FormatSource(entry)]=true
      end
      assert(vendors==1,"obsolete vendor price retained for "..id)
      for source in pairs(baseline[id] or {}) do
        assert(seen[source],"non-vendor source lost for "..id..": "..source)
      end
    end
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
  assert(priced==119,"expected 119 reviewed Justice/Valor offers, got "..priced)
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
say("Whitemane import policy: OK (37 ranks; phase 2 Emblem sources disabled; 119 Justice/Valor prices; 5 commendations; 195 PvP prices; four replays)")
