-- Runtime data contract; no private oracle or generator needed in CI.
dofile('Bistooltip/SourceRegistry.lua')
dofile('Bistooltip/ItemAcquisition.lua')
dofile('Bistooltip/SourceFormatter.lua')
local methods = {DROP=true, TOKEN=true, MARK=true, VENDOR=true, CUSTOM=true}
local difficulties = {['']=true, HC=true, ['10N']=true, ['25N']=true,
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
