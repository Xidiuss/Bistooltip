-- Runtime data contract; no private generator needed in CI.
dofile('Bistooltip/SourceRegistry.lua')
dofile('Bistooltip/ItemAcquisition.lua')
dofile('Bistooltip/UserVerifiedSources.lua')
dofile('Bistooltip/OwnerVerifiedAdditions.lua')
dofile('Bistooltip/SourceFormatter.lua')
local methods = {DROP=true, TOKEN=true, MARK=true, VENDOR=true, CUSTOM=true, ACTIVITY=true}
assert(BisTooltip_ItemAcquisition[24116][1].kind=='ACTIVITY', 'craft method absent')
assert(BisTooltip_ItemAcquisition[34180][1].kind=='DROP', 'Sunwell drop absent')
local choice=BisTooltip_ItemAcquisition[41678]
assert(#choice==2 and choice[1].kind=='VENDOR' and choice[2].kind=='VENDOR',
    'alternative Triumph/Honor offers were combined')
local exchange=BisTooltip_ItemAcquisition[34391][1]
assert(exchange.kind=='VENDOR' and #exchange.cost==2
    and exchange.cost[1].item==34209 and exchange.cost[2].item==34664,
    'Yrma exchange lost its two required items')
assert(not BisTooltip_ItemAcquisition[43792], 'unavailable ID got an invented source')
assert(BisTooltip_ItemAcquisition[37761][1].label:find('elite and ordinary mobs',1,true),
    'world-drop mob scope was lost')
assert(BisTooltip_ItemAcquisition[43573][1].label:find('Nascent Val',1,true),
    'known NPC source was omitted')
local exchanges={
    [34381]=34180,[34385]=34188,[34386]=34170,[34388]=34192,
    [34389]=34193,[34390]=34208,[34392]=34195,[34394]=34215,
    [34396]=34229,[34397]=34211,[34398]=34212,[34399]=34233,
    [34400]=34345,[34401]=34243,[34404]=34244,[34406]=34342,
    [34408]=34234,
}
for target,precursor in pairs(exchanges) do
    local entries=assert(BisTooltip_ItemAcquisition[target], 'missing Yrma target '..target)
    assert(#entries==1 and entries[1].kind=='VENDOR' and #entries[1].cost==2,
        'Yrma offer must have two joint ingredients: '..target)
    assert(entries[1].cost[1].item==precursor and entries[1].cost[1].amount==1
        and entries[1].cost[2].item==34664 and entries[1].cost[2].amount==1,
        'incorrect Yrma pair: '..target)
    local precursorEntries=assert(BisTooltip_ItemAcquisition[precursor],
        'missing precursor acquisition '..precursor)
    local hasDrop=false
    for _,entry in ipairs(precursorEntries) do
        if entry.kind=='DROP' then hasDrop=true end
    end
    assert(hasDrop, 'precursor has no DROP: '..precursor)
end
local twins=assert(BisTooltip_SourceRegistry['OWNER_VERIFIED_PRECURSOR_34192'])
assert(twins.npcIds[1]==25166 and twins.npcIds[2]==25165,
    'Eredar Twins NPC IDs lost')
for _,pair in ipairs({
    {47674,47675,75},{47677,47678,75},{47689,47688,75},
    {47690,47691,75},{47693,47692,75},{47694,47695,75},
    {47702,47701,45},{47704,47705,45},{47713,47714,45},
    {47715,47716,45},
}) do
    for _,id in ipairs({pair[1],pair[2]}) do
        local amount,currency=BisTooltip_GetVendorCost(id)
        assert(amount==pair[3] and currency=='Emblem of Triumph',
            'faction vendor price incorrect: '..id)
    end
end
local difficulties = {['']=true, HC=true, ['5HC']=true, ['10N']=true, ['25N']=true,
    ['10HC']=true, ['25HC']=true, ['10HM']=true, ['25HM']=true}
local count = 0
for id, entries in pairs(BisTooltip_ItemAcquisition) do
    assert(type(id)=='number' and id>0 and id%1==0, 'invalid item ID')
    for _, e in ipairs(entries) do
        assert(methods[e.kind], 'unknown acquisition kind')
        if e.source then
            local s = assert(BisTooltip_SourceRegistry[e.source], 'dangling source on '..id)
            assert(difficulties[s.difficulty or ''], 'invalid difficulty on '..id)
        end
        for _, cost in ipairs(e.cost or {}) do
            assert(type(cost.amount)=='number' and cost.amount>=0, 'invalid cost on '..id)
        end
        local plain = assert(BisTooltip_FormatSource(e), 'unrenderable source on '..id)
        local colored = assert(BisTooltip_FormatSourceColored(e))
        assert(colored:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')==plain,
            'plain/colored mismatch on '..id)
        count=count+1
    end
end
for _, id in ipairs({39192,39396}) do
    for _, e in ipairs(assert(BisTooltip_ItemAcquisition[id])) do
        assert(e.kind=='DROP', 'ordinary loot misclassified as tier gear: '..id)
    end
end
local hasToken = false
for _, e in ipairs(BisTooltip_ItemAcquisition[46111]) do
    if e.kind=='TOKEN' then
        local source=BisTooltip_SourceRegistry[e.source]
        assert(e.tier=='T8' and e.family=='Wayward Vanquisher')
        assert(source.boss=='Hodir' and source.difficulty=='25N')
        hasToken=true
    end
end
assert(hasToken, 'T8 DK chest must have its 25N token source')
local prices = {
    {50965,95,'Emblem of Frost'}, {50968,95,'Emblem of Frost'},
    {50969,95,'Emblem of Frost'}, {50975,95,'Emblem of Frost'},
    {50970,95,'Emblem of Frost'}, {50971,95,'Emblem of Frost'},
    {50974,95,'Emblem of Frost'}, {50972,95,'Emblem of Frost'},
    {50973,95,'Emblem of Frost'}, {50993,60,'Emblem of Frost'},
    {47667,25,'Emblem of Triumph'},
    {40342,25,'Emblem of Valor'}, {40337,25,'Emblem of Valor'},
    {40322,25,'Emblem of Valor'}, {40321,25,'Emblem of Valor'},
    {40268,25,'Emblem of Valor'}, {40267,25,'Emblem of Valor'},
    {40207,25,'Emblem of Valor'}, {40191,25,'Emblem of Valor'},
    {39757,25,'Emblem of Valor'}, {39728,25,'Emblem of Valor'},
    {40698,25,'Emblem of Heroism'}, {40699,25,'Emblem of Heroism'},
    {40700,35,'Emblem of Heroism'}, {40701,35,'Emblem of Heroism'},
}
for _, row in ipairs(prices) do
    local amount,currency=BisTooltip_GetVendorCost(row[1])
    assert(amount==row[2] and currency==row[3], 'incorrect standard vendor price: '..row[1])
end
print('data_integrity: OK ('..count..' acquisitions; 25 vendor price regressions)')
