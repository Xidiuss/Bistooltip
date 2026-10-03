-- Real menu callbacks, with synchronous EditBox SetText notifications as in WoW.
dofile("Bistooltip_Scanner/Scanner.lua")
dofile("Bistooltip_Scanner/Export.lua")
local noop=function() end
local methods={}
local fontStrings={}
local function widget(name)
  return setmetatable({name=name,scripts={},text="",shown=true,scale=1}, {__index=function(_,key)
    if key=="TitleText" then return nil end
    return methods[key] or (key:match("^[A-Z]") and noop or nil)
  end})
end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:GetName() return self.name end
function methods:SetText(text)
  self.text=tostring(text or "")
  if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end
end
function methods:GetText() return self.text end
function methods:GetWidth() return self.width or 460 end
function methods:SetWidth(width) self.width=width end
function methods:SetSize(width,height) self.width=width self.height=height end
function methods:SetMinResize(width,height) self.minWidth=width self.minHeight=height end
function methods:SetMaxLetters(value) self.maxLetters=value end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:SetHeight(height)
  self.height=height
  if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,460,height) end
end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:StartSizing(point) self.sizing=point end
function methods:StopMovingOrSizing() self.sizing=nil end
function methods:SetScale(value) self.scale=value end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.effectiveScale or 1 end
function methods:CreateTexture() return widget() end
function methods:CreateFontString()
  local fs=widget()
  fontStrings[#fontStrings+1]=fs
  return fs
end
function methods:GetFontString() return widget() end
CreateFrame=function(_,name)
  local frame=widget(name)
  if name then _G[name]=frame end
  return frame
end
UIParent=widget()
local cursorX,cursorY=100,100
GetCursorPosition=function() return cursorX,cursorY end
IsShiftKeyDown=function() return false end
local bagHookCalls=0
hooksecurefunc=function(name)
  if name=="ContainerFrameItemButton_OnClick" then bagHookCalls=bagHookCalls+1 end
end
ContainerFrameItemButton_OnClick=function() end
GetItemInfo=function(id) return "Item "..id, "item:"..id end
BistooltipScannerDB={_markSets={
  {id=456,amount=7,note="Active"},
  {id=789,amount=4,note="Other"},
  {id=111,amount=2,note="Third"},
  {id=222,amount=3,note="Fourth"},
},_markActive=1}
dofile("Bistooltip_Scanner/Menu.lua")
Bistooltip_Scanner_ShowMenu()
local failures=0
local function test(name,run)
  local ok,err=pcall(run)
  if ok then print("PASS "..name) else failures=failures+1;print("FAIL "..name..": "..tostring(err)) end
end
local function click(frame) assert(frame:GetScript("OnClick"))(frame) end
local function fontString(text)
  for _,fs in ipairs(fontStrings) do
    if fs.text==text then return fs end
  end
end
test("full preset menu keeps action buttons above bottom help",function()
  local toLog=BistooltipScannerMenuToLog.point
  local export=BistooltipScannerMenuExport.point
  assert(toLog and toLog[1]=="TOPLEFT" and toLog[3]==-446,
    "+ To log overlaps the bottom help at four presets")
  assert(export and export[1]=="TOPLEFT" and export[3]==-446,
    "Export overlaps the bottom help at four presets")
end)
test("bottom help uses the full responsive row width",function()
  local alt=fontString("Alt+click item = attach mark (never buys)")
  local ctrl=fontString("Ctrl+click item = grab first cost mark (never buys)")
  assert(alt and ctrl,"bottom help rows missing")
  assert(alt.width==436 and ctrl.width==436,"bottom help wraps at the base width")
  BistooltipScannerMenu.width=584
  local resize=BistooltipScannerMenu:GetScript("OnSizeChanged")
  assert(resize,"responsive resize handler missing")
  resize(BistooltipScannerMenu,584,BistooltipScannerMenu.height or 580)
  assert(alt.width==560 and ctrl.width==560,"bottom help did not expand with the window")
end)
test("mark table keeps full amount values and widens every column",function()
  local idHeader=fontString("MARK ID")
  local amountHeader=fontString("AMOUNT")
  local noteHeader=fontString("NOTE")
  local resize=BistooltipScannerMenu:GetScript("OnSizeChanged")
  assert(idHeader and amountHeader and noteHeader,"mark table headers missing")
  assert(resize,"responsive resize handler missing")
  assert(BistooltipScannerMenu.minWidth==460,"menu can shrink below the non-overlapping table width")

  BistooltipScannerMenu.width=460
  resize(BistooltipScannerMenu,460,BistooltipScannerMenu.height or 580)
  assert(BistooltipScannerMenuSet1ID.width==90,"MARK ID base width changed")
  assert(BistooltipScannerMenuSet1Amt.width==72,"AMOUNT does not fit five digits")
  assert(BistooltipScannerMenuSet1Amt.maxLetters==5,"AMOUNT lost its five-digit input limit")
  assert(BistooltipScannerMenuSet1Note.width==206,"NOTE base width does not preserve the table edge")
  assert(idHeader.width==90 and amountHeader.width==72 and noteHeader.width==206,
    "headers do not match their base columns")
  assert(BistooltipScannerMenuSet1ID.point[2]==46
    and BistooltipScannerMenuSet1Amt.point[2]==140
    and BistooltipScannerMenuSet1Note.point[2]==216,
    "base columns do not preserve four-pixel gaps")

  BistooltipScannerMenu.width=560
  resize(BistooltipScannerMenu,560,BistooltipScannerMenu.height or 580)
  assert(BistooltipScannerMenuSet1ID.width==115,"MARK ID did not receive 25% of resize growth")
  assert(BistooltipScannerMenuSet1Amt.width==92,"AMOUNT did not receive 20% of resize growth")
  assert(BistooltipScannerMenuSet1Note.width==261,"NOTE did not receive 55% of resize growth")
  assert(BistooltipScannerMenuSet1Amt.point[2]==165
    and BistooltipScannerMenuSet1Note.point[2]==261,
    "resized columns overlap or leave stale gaps")
  assert(idHeader.width==115 and amountHeader.width==92 and noteHeader.width==261,
    "headers did not widen with their columns")
  assert(amountHeader.point[2]==165 and noteHeader.point[2]==261,
    "headers did not move with their columns")

  BistooltipScannerMenu.width=860
  resize(BistooltipScannerMenu,860,BistooltipScannerMenu.height or 580)
  assert(BistooltipScannerMenuSet1ID.width==190
    and BistooltipScannerMenuSet1Amt.width==152
    and BistooltipScannerMenuSet1Note.width==426,
    "columns stopped widening past the old 300-pixel growth cap")
end)
test("menu never hooks container item clicks",function()
  assert(bagHookCalls==0,"bag click hook is still installed")
end)
test("external vendor scan refreshes the open menu status",function()
  local savedDB=BistooltipScannerDB
  local savedUnitName,savedZone=UnitName,GetZoneText
  local savedCount,savedInfo=GetMerchantNumItems,GetMerchantItemInfo
  local savedLink,savedCostItem=GetMerchantItemLink,GetMerchantItemCostItem
  BistooltipScannerDB={}
  UnitName=function() return "Refresh Vendor" end
  GetZoneText=function() return "Refresh Zone" end
  GetMerchantNumItems=function() return 2 end
  GetMerchantItemInfo=function(i) return "Item "..i,"tex",100,1,-1,true,false end
  GetMerchantItemLink=function(i) return "item:"..(7000+i) end
  GetMerchantItemCostItem=nil
  Bistooltip_Scanner_ScanVendor()
  local expected=Bistooltip_Scanner_MenuStatus()
  local fixtureOK=expected:find("vendors: 1  items: 2",1,true)
  local refreshed=fontString(expected)
  BistooltipScannerDB=savedDB
  UnitName,GetZoneText=savedUnitName,savedZone
  GetMerchantNumItems,GetMerchantItemInfo=savedCount,savedInfo
  GetMerchantItemLink,GetMerchantItemCostItem=savedLink,savedCostItem
  Bistooltip_Scanner_RefreshMenuStatus()
  assert(fixtureOK,"scan fixture did not create two items")
  assert(refreshed,"open menu status did not refresh after external vendor scan")
end)
test("export mode button cycles purchase policies",function()
  local before=Bistooltip_Scanner_GetExportMode()
  click(BistooltipScannerMenuMode)
  assert(Bistooltip_Scanner_GetExportMode()~=before,"mode button did not switch policy")
end)
test("export opened from menu hides and restores only its launcher",function()
  local originalExportText=Bistooltip_Scanner_ExportText
  Bistooltip_Scanner_ExportText=function() return "menu export" end
  click(BistooltipScannerMenuExport)
  Bistooltip_Scanner_ExportText=originalExportText
  assert(BistooltipScannerMenu:IsShown()==false,"menu stayed visible behind export")
  assert(BistooltipScannerExport and BistooltipScannerExport:IsShown(),"export did not open")
  click(BistooltipScannerExportClose)
  assert(BistooltipScannerExport:IsShown()==false,"export stayed visible after Close")
  assert(BistooltipScannerMenu:IsShown(),"Close did not restore the launching menu")

  BistooltipScannerMenu:Hide()
  Bistooltip_Scanner_ShowExport("direct export")
  assert(BistooltipScannerExport:IsShown(),"direct export did not open")
  click(BistooltipScannerExportClose)
  assert(BistooltipScannerMenu:IsShown()==false,"direct export opened the menu on Close")
  Bistooltip_Scanner_ShowMenu()
end)
test("opening the menu preserves saved preset fields",function()
  assert(BistooltipScannerDB._markSets[1].amount==7,"layout overwrote stored amount")
  assert(BistooltipScannerDB._markSets[1].note=="Active","layout overwrote stored note")
end)
test("captured vendor IDs preserve preset details and activate an empty fallback",function()
  Bistooltip_Scanner_SetMarkFromClick(654)
  assert(BistooltipScannerDB._markSets[1].id==654)
  assert(BistooltipScannerMenuSet1ID:GetText()=="654",
    "active mark ID field did not refresh after capture")
  assert(BistooltipScannerDB._markSets[1].amount==7 and BistooltipScannerDB._markSets[1].note=="Active",
    "active preset details changed with its vendor ID")

  Bistooltip_Scanner_SetActiveMarkSet(nil)
  Bistooltip_Scanner_UpdateMarkSet(3,nil,2,"Third")
  Bistooltip_Scanner_SetMarkFromClick(777)
  assert(BistooltipScannerDB._markActive==3,"first empty preset was not activated")
  assert(BistooltipScannerMenuSet3ID:GetText()=="777",
    "fallback mark ID field did not refresh after capture")
  assert(BistooltipScannerDB._markSets[3].id==777
    and BistooltipScannerDB._markSets[3].amount==2
    and BistooltipScannerDB._markSets[3].note=="Third",
    "empty preset details changed with its vendor ID")

  Bistooltip_Scanner_UpdateMarkSet(1,456,7,"Active")
  Bistooltip_Scanner_UpdateMarkSet(3,111,2,"Third")
  Bistooltip_Scanner_SetActiveMarkSet(1)
  Bistooltip_Scanner_RefreshMarkSets()
end)
-- Explicit user edits make later tests independent of initial layout failure.
BistooltipScannerMenuSet1ID:SetText("456")
BistooltipScannerMenuSet1Amt:SetText("7")
Bistooltip_Scanner_SetActiveMarkSet(nil)
click(BistooltipScannerMenuSet1Tgl)
test("active amount edit immediately updates scan price without reselecting",function()
  BistooltipScannerMenuSet1Amt:SetText("12")
  assert(BistooltipScannerDB._markSets[1].amount==12)
  assert(Bistooltip_Scanner_PendingMark and Bistooltip_Scanner_PendingMark.amount==12,"pending mark kept old amount")
  BistooltipScannerMenuID:SetText("123")
  click(BistooltipScannerMenuScanID)
  assert(BistooltipScannerDB.manual.items[123].costs[1].amount==12,"Scan ID used stale hidden quantity")
end)
test("inactive edits do not change the active price",function()
  BistooltipScannerMenuSet2Amt:SetText("99")
  assert(BistooltipScannerDB._markSets[2].amount==99)
  assert(Bistooltip_Scanner_PendingMark.amount==12)
end)
test("empty active amount disables stale pending price",function()
  BistooltipScannerMenuSet1Amt:SetText("")
  assert(Bistooltip_Scanner_PendingMark==nil,"empty amount left old pending price")
  assert(BistooltipScannerMenuQty:GetText()=="")
  BistooltipScannerMenuSet1Amt:SetText("15")
  assert(Bistooltip_Scanner_PendingMark.amount==15)
end)
test("refreshing preset layout does not feed partial UI values back into saved data",function()
  Bistooltip_Scanner_UpdateMarkSet(1,456,25,"Restored")
  Bistooltip_Scanner_RefreshMarkSets()
  assert(BistooltipScannerDB._markSets[1].amount==25)
  assert(BistooltipScannerMenuSet1Amt:GetText()=="25")
  assert(BistooltipScannerDB._markSets[1].note=="Restored")
  assert(Bistooltip_Scanner_PendingMark.amount==25)
end)
test("deselecting a preset clears the pending price",function()
  click(BistooltipScannerMenuSet1Tgl)
  assert(BistooltipScannerDB._markActive==nil)
  assert(Bistooltip_Scanner_PendingMark==nil)
end)
test("active currency edits and removal synchronize the pending price",function()
  click(BistooltipScannerMenuSet2Tgl)
  BistooltipScannerMenuSet2ID:SetText("900")
  assert(Bistooltip_Scanner_PendingMark.id==900 and Bistooltip_Scanner_PendingMark.amount==99)
  click(BistooltipScannerMenuSet2Del)
  assert(Bistooltip_Scanner_PendingMark==nil)
  assert(BistooltipScannerDB._markSets[1].amount==25)
end)
test("resize grip separates window sizing from saved shift scaling",function()
  local grip=BistooltipScannerMenuResize
  assert(grip,"menu resize grip missing")
  local mouseDown=grip:GetScript("OnMouseDown")
  local mouseUp=grip:GetScript("OnMouseUp")
  local update=grip:GetScript("OnUpdate")
  local clickGrip=grip:GetScript("OnClick")
  assert(mouseDown and mouseUp and update and clickGrip,"resize grip scripts incomplete")

  IsShiftKeyDown=function() return false end
  mouseDown(grip,"LeftButton")
  assert(BistooltipScannerMenu.sizing=="BOTTOMRIGHT","plain drag did not start window resize")
  mouseUp(grip,"LeftButton")
  assert(BistooltipScannerMenu.sizing==nil,"plain drag did not stop window resize")

  BistooltipScannerDB._windowScale=1
  cursorX,cursorY=100,100
  IsShiftKeyDown=function() return true end
  mouseDown(grip,"LeftButton")
  assert(BistooltipScannerMenu.sizing==nil,"Shift+drag also started window resize")
  cursorX,cursorY=140,100
  update(grip)
  assert(BistooltipScannerDB._windowScale==1.10,"Shift+drag did not save 110% scale")
  assert(BistooltipScannerMenu:GetScale()==1.10,"Shift+drag did not scale the menu")
  assert(BistooltipScannerExport:GetScale()==1.10,"Shift+drag did not share scale with Export")
  mouseUp(grip,"LeftButton")

  clickGrip(grip,"RightButton")
  assert(BistooltipScannerDB._windowScale==1,"right-click did not reset saved scale")
  assert(BistooltipScannerMenu:GetScale()==1 and BistooltipScannerExport:GetScale()==1,
    "right-click did not reset both Scanner windows")
  IsShiftKeyDown=function() return false end
end)
assert(failures==0,tostring(failures).." menu regression(s)")
