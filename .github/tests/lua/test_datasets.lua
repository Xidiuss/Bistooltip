-- Structural census of the shipped final databases, not upstream raw inputs.
dofile('Bistooltip/Bistooltip_WoWSimsBP_final.lua')
dofile('Bistooltip/Bistooltip_wowtbc_bislists.lua')
dofile('Bistooltip/Bistooltip_wh_bislists.lua')
dofile('Bistooltip/SourceRegistry.lua')
dofile('Bistooltip/ItemAcquisition.lua')
dofile('Bistooltip/UserVerifiedSources.lua')
local function copy(t)
    if type(t)~='table' then return t end
    local out={} for k,v in pairs(t) do out[k]=copy(v) end return out
end
local horde=copy(Bistooltip_wowsims_final)
for class,specs in pairs(Bistooltip_wowsims_horde_overrides or {}) do
    for spec,phases in pairs(specs) do
        for phase,overrides in pairs(phases) do
            local list=assert(horde[class][spec][phase])
            for index,slot in pairs(overrides) do
                assert(type(index)=='number' and list[index], 'invalid faction slot index')
                list[index]=slot
            end
        end
    end
end
local forbidden={[128858]=true,[130023]=true,[130031]=true,[131004]=true,[150005]=true}
for name,db in pairs({wowsims_alliance=Bistooltip_wowsims_final,
    wowsims_horde=horde,wowtbc=Bistooltip_wowtbc_bislists,wh=Bistooltip_wh_bislists}) do
    local slots,entries=0,0
    local missing,missingTop={},{}
    local exchangedShoulders=0
    for _,specs in pairs(db) do
        for _,phases in pairs(specs) do
            for _,list in pairs(phases) do
                local seen={}
                for _,slot in ipairs(list) do
                    assert(type(slot.slot_name)=='string', 'missing slot name in '..name)
                    if name:find('wowsims',1,true) then
                        assert(not seen[slot.slot_name], 'duplicate final slot '..slot.slot_name)
                    end
                    seen[slot.slot_name]=true
                    slots=slots+1
                    for i,id in ipairs(slot) do
                        assert(type(id)=='number' and id%1==0 and (id>0 or id==-1), 'invalid rank item')
                        assert(id~=34209, 'precursor item ranked instead of Yrma reward in '..name)
                        if id==34391 then exchangedShoulders=exchangedShoulders+1 end
                        assert(not forbidden[id], 'server item leaked into standard dataset')
                        if id>0 then
                            entries=entries+1
                            local acq=BisTooltip_ItemAcquisition[id]
                            if not acq or #acq==0 then
                                missing[id]=true
                                if i==1 then missingTop[id]=true end
                            end
                        end
                    end
                end
            end
        end
    end
    local gaps=0 for _ in pairs(missing) do gaps=gaps+1 end
    if name=='wowsims_alliance' or name=='wowtbc' then
        assert(exchangedShoulders>0, 'Yrma reward missing from '..name)
    end
    local top={} for id in pairs(missingTop) do top[#top+1]=id end table.sort(top)
    local all={} for id in pairs(missing) do all[#all+1]=id end table.sort(all)
    print(string.format('dataset: %s slots=%d entries=%d items_without_sources=%d rank1_gaps=%d',name,slots,entries,gaps,#top))
    print('rank1 source gaps: '..table.concat(top,','))
    print('all source gaps: '..table.concat(all,','))
end
