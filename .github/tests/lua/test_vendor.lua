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
dofile('Bistooltip/Bistooltip_horde_to_ali.lua')
assert(BistooltipData.GetDisplayItemID(47115,false)==47115, 'Alliance Verdict changed faction')
assert(BistooltipData.GetDisplayItemID(47115,true)==47303, 'Horde Choice not selected')
assert(BistooltipData.GetDisplayItemID(47303,false)==47115, 'Alliance reverse faction mapping failed')
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
local filtered=BistooltipData.FilterSlots({{slot_name='Head',6,7}},'',false,true,false,true)
assert(#filtered==0, 'non-BiS vendor rank leaked into VENDOR mode')
local choices=BistooltipData.GetVendorBISItems({slot_name='Trinket',6,7,2},false)
assert(#choices==1 and choices[1]==7, 'second required trinket disappeared from VENDOR mode')
print('vendor: OK (free, item, compound, alternatives, custom, scalar totals, BiS ranks)')
