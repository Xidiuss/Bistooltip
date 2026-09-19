-- Real menu callbacks, with synchronous EditBox SetText notifications as in WoW.
dofile("Bistooltip_Scanner/Scanner.lua")
dofile("Bistooltip_Scanner/Export.lua")
local noop=function() end
local methods={}
local function widget()
  return setmetatable({scripts={},text="",shown=true}, {__index=function(_,key)
    return methods[key] or (key:match("^[A-Z]") and noop or nil)
  end})
end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:SetText(text)
  self.text=tostring(text or "")
  if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end
end
function methods:GetText() return self.text end
function methods:GetWidth() return 460 end
function methods:SetHeight(height)
  self.height=height
  if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,460,height) end
end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:CreateTexture() return widget() end
function methods:CreateFontString() return widget() end
function methods:GetFontString() return widget() end
CreateFrame=function(_,name)
  local frame=widget()
  if name then _G[name]=frame end
  return frame
end
UIParent=widget()
GetItemInfo=function(id) return "Item "..id, "item:"..id end
BistooltipScannerDB={_markSets={{id=456,amount=7,note="Active"},{id=789,amount=4,note="Other"}},_markActive=1}
dofile("Bistooltip_Scanner/Menu.lua")
Bistooltip_Scanner_ShowMenu()
local failures=0
local function test(name,run)
  local ok,err=pcall(run)
  if ok then print("PASS "..name) else failures=failures+1;print("FAIL "..name..": "..tostring(err)) end
end
local function click(frame) assert(frame:GetScript("OnClick"))(frame) end
test("export mode button cycles purchase policies",function()
  local before=Bistooltip_Scanner_GetExportMode()
  click(BistooltipScannerMenuMode)
  assert(Bistooltip_Scanner_GetExportMode()~=before,"mode button did not switch policy")
end)
test("opening the menu preserves saved preset fields",function()
  assert(BistooltipScannerDB._markSets[1].amount==7,"layout overwrote stored amount")
  assert(BistooltipScannerDB._markSets[1].note=="Active","layout overwrote stored note")
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
assert(failures==0,tostring(failures).." menu regression(s)")
