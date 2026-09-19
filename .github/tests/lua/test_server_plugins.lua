-- Run with the real plugin main.lua path as arg[1]; no private inputs.
local plugin = assert(arg[1], 'usage: test_server_plugins.lua <plugin/main.lua>')
local say = print
print = function() end -- Expected override diagnostics are noisy in a matrix.
local noop = function() end
local saved
LibStub = function(name)
    if name == 'AceDB-3.0' then return {New=function() return saved end} end
    if name == 'AceConfig-3.0' then return {RegisterOptionsTable=noop} end
    if name == 'AceConfigDialog-3.0' then return {AddToBlizOptions=noop} end
    return {}
end
DEFAULT_CHAT_FRAME={AddMessage=noop}
GetTime=function() return 0 end
GetItemInfo=function() return nil end
BistooltipUtils={NormalizeItemID=function(id) return id end}
BistooltipConstants={}
dofile('Bistooltip/Bistooltip_WoWSimsBP_final.lua')
dofile('Bistooltip/Bistooltip_wowtbc_bislists.lua')
dofile('Bistooltip/Bistooltip_wh_bislists.lua')
local function count()
    local n=0
    for _,list in pairs(BisTooltip_ItemAcquisition) do n=n+#list end
    return n
end
local function verifyRanks(ops)
    for _,op in ipairs(ops) do
        local c=Bistooltip_bislists[op[1]]
        local s=c and c[op[2]]
        for _,slot in ipairs(s and s[op[3]] or {}) do
            if slot.slot_name==op[4] then
                assert(slot[op[5]]==op[6], 'server rank lost after database switch')
            end
        end
    end
end
local function verifyInsertions(ops, sourceKey, faction)
    local source = sourceKey == 'wowsims' and Bistooltip_wowsims_final
        or sourceKey == 'wowtbc' and Bistooltip_wowtbc_bislists or Bistooltip_wh_bislists
    for _,op in ipairs(ops) do
        local class, spec, phase, slotName, rank, itemID = unpack(op)
        local active = Bistooltip_bislists[class] and Bistooltip_bislists[class][spec]
        local original = source[class] and source[class][spec]
        local activeSlots = active and active[phase]
        local sourceSlots = original and original[phase]
        if activeSlots and sourceSlots then
            for index, slot in ipairs(activeSlots) do
                if slot.slot_name == slotName then
                    local baseline = sourceSlots[index]
                    local horde = faction == 'Horde' and sourceKey == 'wowsims'
                        and Bistooltip_wowsims_horde_overrides
                    local override = horde and horde[class] and horde[class][spec]
                        and horde[class][spec][phase]
                    if override and override[index] then baseline = override[index] end
                    assert(baseline and baseline.slot_name == slotName, 'baseline slot mismatch')
                    local expected = {itemID}
                    for _,id in ipairs(baseline) do
                        if id ~= itemID then expected[#expected + 1] = id end
                    end
                    while #expected > #baseline do table.remove(expected) end
                    assert(#slot == #expected, 'plugin insertion changed baseline rank count')
                    for i,id in ipairs(expected) do
                        assert(slot[i] == id, 'plugin insertion discarded or reordered a baseline item')
                    end
                end
            end
        end
    end
end
for _,faction in ipairs({'Alliance','Horde'}) do
    UnitFactionGroup=function() return faction end
    for _,initial in ipairs({'wowsims','wowtbc','wh'}) do
        BistooltipAddon={AceAddonName='Bis-Tooltip'}
        saved={global={data_source=initial,custom_priorities={},account_state_migrated=true},
            char={version=6.3,class_index=1,spec_index=1,phase_index=1,filter_specs={},highlight_spec={}}}
        BisTooltip={}
        dofile('Bistooltip/SourceRegistry.lua')
        dofile('Bistooltip/ItemAcquisition.lua')
        dofile('Bistooltip/UserVerifiedSources.lua')
        dofile('Bistooltip/SourceFormatter.lua')
        dofile('Bistooltip/PluginAPI.lua')
        dofile('Bistooltip/DataProvider.lua')
        dofile('Bistooltip/Config.lua')
        BistooltipAddon:initConfig()
        local before=count()
        local rankOps={}
        local insertOps={}
        local rank=BisTooltip.SetBiSSlotRank
        local insert=BisTooltip.InsertBiSSlotRank
        BisTooltip.SetBiSSlotRank=function(self,...)
            rankOps[#rankOps+1]={...}
            return rank(self,...)
        end
        BisTooltip.InsertBiSSlotRank=function(self,...)
            insertOps[#insertOps+1]={...}
            return insert(self,...)
        end
        dofile(plugin)
        BisTooltip.SetBiSSlotRank=rank
        BisTooltip.InsertBiSSlotRank=insert
        if plugin:find('Whitemane_Frostmourne', 1, true) then
            assert(#insertOps == 27, 'Whitemane legendary ranks must insert, not replace')
            local quest = BisTooltip_ItemAcquisition[130025]
            assert(quest and quest[1].kind == 'ACTIVITY', 'Whitemane quest route missing')
            local routes = BisTooltip_ItemAcquisition[130023]
            local hasQuest, hasVendor = false, false
            for _, entry in ipairs(routes or {}) do
                if entry.kind == 'ACTIVITY' then hasQuest = true end
                if entry.kind == 'VENDOR' then hasVendor = true end
            end
            assert(hasQuest and hasVendor, 'Whitemane quest/vendor alternatives lost')
            assert(not BisTooltip_ItemAcquisition[315003], 'deferred upgrade became a source')
        elseif plugin:find('WOTLK5_S2', 1, true) then
            local scroll = BisTooltip_ItemAcquisition[5000762]
            assert(scroll and #scroll == 1 and scroll[1].kind == 'VENDOR'
                and scroll[1].cost[1].amount == 1
                and scroll[1].cost[1].currency == 'Plagued Legendary Shard',
                'Great Wall necklace scroll source missing')
        end
        local after=count()
        assert(after>before, 'plugin registered no acquisitions')
        verifyRanks(rankOps)
        verifyInsertions(insertOps, initial, faction)
        for round=1,2 do
            for _,target in ipairs({'wh','wowtbc','wowsims'}) do
                BistooltipAddon:changeSpec(target)
                assert(count()==after, 'overlay replay duplicated acquisition entries')
                verifyRanks(rankOps)
                verifyInsertions(insertOps, target, faction)
            end
        end
        for id,entries in pairs(BisTooltip_ItemAcquisition) do
            for _,entry in ipairs(entries) do
                assert(BisTooltip_FormatSource(entry), 'unrenderable plugin acquisition '..id)
            end
        end
        say('server_plugin: OK '..faction..' initial='..initial..' '..plugin)
    end
end
print=say
