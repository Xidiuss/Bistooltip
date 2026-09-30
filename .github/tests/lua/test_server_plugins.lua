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
local contextClass, contextProfessions
BistooltipPlayerContext = {
    GetPlayerClassKey = function() return contextClass end,
    GetProfessionSkillLines = function()
        local copy = {}
        for profession,owned in pairs(contextProfessions or {}) do copy[profession] = owned end
        return copy
    end,
}
local function findSlot(slots, slotName)
    for _,slot in ipairs(slots or {}) do
        if slot.slot_name == slotName then return slot end
    end
end
local function copyEnhancements(enhs)
    local copy = {}
    for index,entry in ipairs(enhs or {}) do
        copy[index] = {type=entry.type,id=entry.id}
    end
    return copy
end
local function assertEnhancementsEqual(actual, expected, message)
    assert(#(actual or {}) == #(expected or {}), message .. ' (length)')
    for index,entry in ipairs(expected or {}) do
        local found = actual[index]
        assert(found and found.type == entry.type and found.id == entry.id,
            message .. ' (index ' .. index .. ')')
    end
end
local function verifyWotlkEnhancementViews()
    local representatives = {
        {'Warrior','Protection',5000162,59636,5000158,61119,5000766},
        {'Warrior','Fury',5000161,44645,5000156,61117,5000764},
        {'Mage','Arcane',5000160,44636,5000159,61120,5000764},
        {'Priest','Holy',5000160,44636,5000157,61118,5000764},
        {'Warlock','Affliction',5000160,44636,5000159,61120,5000765},
    }
    for _,profile in ipairs(representatives) do
        local className, specName = profile[1], profile[2]
        contextClass, contextProfessions = className, {[333]=true,[773]=true}
        local baseSlots = Bistooltip_bislists[className][specName].T7
        local views = BistooltipData.GetSlotsForSpec(className,specName,'T7')
        for _,target in ipairs({
            {'Trinket','item',profile[3]}, {'Finger','spell',profile[4]},
            {'Head','item',profile[5]}, {'Shoulder','spell',profile[6]},
            {'Neck','item',profile[7]},
        }) do
            local slotName, expectedType, expectedID = target[1], target[2], target[3]
            local base, view = findSlot(baseSlots,slotName), findSlot(views,slotName)
            assert(base and view, className .. '/' .. specName .. ' missing ' .. slotName)
            local before = copyEnhancements(base.enhs)
            assert(view.enhs[1] and view.enhs[1].type == expectedType
                and view.enhs[1].id == expectedID,
                className .. '/' .. specName .. '/' .. slotName .. ' override missing')
            for index=2,#before do
                assert(view.enhs[index] and view.enhs[index].type == before[index].type
                    and view.enhs[index].id == before[index].id,
                    className .. '/' .. specName .. '/' .. slotName .. ' lost later enhancement')
            end
            assertEnhancementsEqual(base.enhs,before,
                className .. '/' .. specName .. '/' .. slotName .. ' mutated base data')
        end
    end

    contextClass, contextProfessions = 'Warrior', {[333]=true,[773]=true}
    local mageBase = Bistooltip_bislists.Mage.Arcane.T7
    local mageView = BistooltipData.GetSlotsForSpec('Mage','Arcane','T7')
    assertEnhancementsEqual(findSlot(mageView,'Head').enhs,findSlot(mageBase,'Head').enhs,
        'profession Head override leaked to another class')
    assert(findSlot(mageView,'Neck').enhs[1].id == 5000764,
        'global Neck override did not apply on another-class tab')

    for _,phase in ipairs({'PR','T8','T9','T10','RS'}) do
        local phaseSlots = Bistooltip_bislists.Warrior.Fury[phase]
        if phaseSlots then
            local views = BistooltipData.GetSlotsForSpec('Warrior','Fury',phase)
            for _,target in ipairs({
                {'Trinket','item',5000161}, {'Finger','spell',44645},
                {'Head','item',5000156}, {'Shoulder','spell',61117},
            }) do
                local slotName, expectedType, expectedID = target[1], target[2], target[3]
                local base, view = findSlot(phaseSlots,slotName), findSlot(views,slotName)
                if base and view then
                    assert(view.enhs[1] and view.enhs[1].type == expectedType
                        and view.enhs[1].id == expectedID,
                        'COMMON override missing from Warrior/Fury/' .. phase .. '/' .. slotName)
                    for index=2,#(base.enhs or {}) do
                        assert(view.enhs[index] and view.enhs[index].type == base.enhs[index].type
                            and view.enhs[index].id == base.enhs[index].id,
                            'COMMON override lost later enhancement at Warrior/Fury/'
                                .. phase .. '/' .. slotName .. '/' .. index)
                    end
                end
            end
            local baseNeck, viewNeck = findSlot(phaseSlots,'Neck'), findSlot(views,'Neck')
            if baseNeck and viewNeck then
                assertEnhancementsEqual(viewNeck.enhs,baseNeck.enhs,
                    'phase-specific Neck leaked to Warrior/Fury/' .. phase)
            end
        end
    end
end

local function verifyWotlkLegacyProfessionContext()
    local savedContext = BistooltipPlayerContext
    local savedClassMap = BistooltipUtils.CLASSFILE_TO_DATASET
    local savedUnitClass = UnitClass
    local savedGetProfessions, savedGetProfessionInfo = GetProfessions, GetProfessionInfo
    local savedGetSpellInfo = GetSpellInfo
    local savedGetNumSkillLines, savedGetSkillLineInfo = GetNumSkillLines, GetSkillLineInfo

    BistooltipUtils.CLASSFILE_TO_DATASET = {WARRIOR='Warrior'}
    UnitClass = function() return 'Warrior','WARRIOR' end
    GetProfessions, GetProfessionInfo = nil, nil
    GetSpellInfo = function(id)
        if id == 7411 then return 'Localized Enchanting' end
        if id == 45357 then return 'Localized Inscription' end
    end
    GetNumSkillLines = function() return 2 end
    GetSkillLineInfo = function(index)
        if index == 1 then return 'Localized Enchanting',false,true,450 end
        if index == 2 then return 'Localized Inscription',false,true,450 end
    end
    BistooltipPlayerContext = {}
    dofile('Bistooltip/PlayerContext.lua')

    local baseSlots = Bistooltip_bislists.Warrior.Fury.T8
    local views = BistooltipData.GetSlotsForSpec('Warrior','Fury','T8')
    for _,target in ipairs({
        {'Trinket','item',5000161}, {'Finger','spell',44645},
        {'Head','item',5000156}, {'Shoulder','spell',61117},
    }) do
        local view = findSlot(views,target[1])
        assert(view and view.enhs[1] and view.enhs[1].type == target[2]
            and view.enhs[1].id == target[3],
            'real 3.3.5 profession context missed T8 ' .. target[1])
    end
    assertEnhancementsEqual(findSlot(views,'Neck').enhs,findSlot(baseSlots,'Neck').enhs,
        'real 3.3.5 profession context leaked T7 Neck into T8')

    BistooltipPlayerContext = savedContext
    BistooltipUtils.CLASSFILE_TO_DATASET = savedClassMap
    UnitClass = savedUnitClass
    GetProfessions, GetProfessionInfo = savedGetProfessions, savedGetProfessionInfo
    GetSpellInfo = savedGetSpellInfo
    GetNumSkillLines, GetSkillLineInfo = savedGetNumSkillLines, savedGetSkillLineInfo
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
        dofile('Bistooltip/OwnerVerifiedAdditions.lua')
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
            BistooltipAddon:changeSpec('wowsims')
            verifyWotlkEnhancementViews()
            verifyWotlkLegacyProfessionContext()
            BistooltipAddon:changeSpec(initial)
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
