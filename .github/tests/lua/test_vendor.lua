local noop=function() end
BistooltipUtils={NormalizeItemID=function(id) return type(id)=='number' and id>0 and id or nil end}
BistooltipConstants={}
BistooltipState={}
BistooltipAddon={}
GetItemInfo=function() return nil end
GetTime=function() return 0 end
Bistooltip_char_equipment={}
BisTooltip_ItemAcquisition={
 [1]={{kind='VENDOR',cost={}}},
 [2]={{kind='VENDOR',cost={{item=90001,amount=2}}}},
 [3]={{kind='VENDOR',cost={{currency='Gold',amount=10000},{currency='Justice',amount=50}}}},
 [4]={{kind='VENDOR',cost={{currency='Valor',amount=20}}},{kind='VENDOR',cost={{currency='Justice',amount=40}}}},
 [5]={{kind='CUSTOM',label='Server shop'}},
 [6]={{kind='DROP',source='RAID'}},
 [7]={{kind='VENDOR',cost={{currency='Justice',amount=30}}}},
}
dofile('Bistooltip/SourceFormatter.lua')
dofile('Bistooltip/DataProvider.lua')
dofile('Bistooltip/ui/InstanceHeader.lua')
for _,id in ipairs({1,2,3,4,5,7}) do
 assert(BistooltipData.SlotHasVendorSource({slot_name='Head',id},true,false), 'vendor mode dropped item '..id)
 local groups=BistooltipInstanceHeader.GroupSlotsByInstance({{slot_name='Head',id}},false,true)
 assert(#groups==1 and groups[1].name~='Unknown vendor', 'vendor grouping lost item '..id)
 if id==3 or id==4 or id==5 then
  assert(groups[1].costNeedsDetails, 'partial/alternative cost presented as complete for '..id)
 end
end
assert(not BistooltipData.SlotHasVendorSource({6},true,false), 'raid item leaked into vendor mode')
local groups=BistooltipInstanceHeader.GroupSlotsByInstance({{slot_name='Head',7},{slot_name='Hands',7}},false,true)
assert(groups[1].totalEmblemCost==60 and not groups[1].costNeedsDetails, 'simple currency total changed')
local filtered=BistooltipData.FilterSlots({{slot_name='Finger',6,6,2}},'',false,true,false,true)
assert(filtered[1] and filtered[1][3]==2, 'deep vendor ring disappeared before per-item filtering')
print('vendor: OK (free, item, compound, alternatives, custom, scalar totals, deep ranks)')
