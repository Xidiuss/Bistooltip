-- ============================================================
-- ObjectPool.lua - High-performance Object Pooling System
-- Zero GC churn, no frame drops
-- ============================================================

local ADDON_NAME = "Bis-Tooltip"

-- Create namespace
BistooltipPools = BistooltipPools or {}

-- ============================================================
-- Generic Pool Implementation
-- ============================================================

local function CreateGenericPool(createFunc, resetFunc, validateFunc)
    local pool = {
        _available = {},
        _inUse = {},
        _inUseCount = 0,  -- Track count instead of iterating
        _createFunc = createFunc,
        _resetFunc = resetFunc,
        _validateFunc = validateFunc or function() return true end,
        _totalCreated = 0,
        _peakUsage = 0,
    }

    -- Acquire an object from pool
    function pool:Acquire()
        local obj = table.remove(self._available)

        if not obj or not self._validateFunc(obj) then
            obj = self._createFunc()
            self._totalCreated = self._totalCreated + 1
        end

        self._inUse[obj] = true
        self._inUseCount = self._inUseCount + 1

        if self._inUseCount > self._peakUsage then
            self._peakUsage = self._inUseCount
        end

        return obj
    end

    -- Release an object back to pool
    function pool:Release(obj)
        if not obj then return end
        if not self._inUse[obj] then return end

        self._inUse[obj] = nil
        self._inUseCount = self._inUseCount - 1
        self._resetFunc(obj)
        table.insert(self._available, obj)
    end

    -- Release all objects back to pool
    function pool:ReleaseAll()
        for obj in pairs(self._inUse) do
            self._resetFunc(obj)
            table.insert(self._available, obj)
        end
        self._inUse = {}
        self._inUseCount = 0
    end

    -- Get pool statistics
    function pool:GetStats()
        return {
            available = #self._available,
            inUse = self._inUseCount,
            totalCreated = self._totalCreated,
            peakUsage = self._peakUsage,
        }
    end
    
    -- Pre-warm pool with N objects
    function pool:PreWarm(count)
        for i = 1, count do
            local obj = self._createFunc()
            self._totalCreated = self._totalCreated + 1
            self._resetFunc(obj)
            table.insert(self._available, obj)
        end
    end
    
    return pool
end

BistooltipPools.CreateGenericPool = CreateGenericPool

-- ============================================================
-- Frame Pool - Pooling for basic WoW Frames
-- ============================================================

local function CreateFrameResetFunc(defaultParent)
    return function(frame)
        -- Use centralized reset from util/reset.lua
        if BistooltipReset and BistooltipReset.ResetSimpleFrame then
            BistooltipReset.ResetSimpleFrame(frame)
            -- Re-parent to specified default if needed
            if defaultParent and frame then
                frame:SetParent(defaultParent)
            end
        else
            -- Fallback
            if not frame then return end
            frame:Hide()
            frame:ClearAllPoints()
            frame:SetParent(defaultParent or UIParent)
            frame:SetSize(1, 1)
            frame:SetAlpha(1)
            frame:SetFrameLevel(1)
            frame:SetScript("OnClick", nil)
            frame:SetScript("OnEnter", nil)
            frame:SetScript("OnLeave", nil)
            frame:SetScript("OnUpdate", nil)
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            if frame.SetBackdrop then
                frame:SetBackdrop(nil)
            end
            if frame._bt_data then
                wipe(frame._bt_data)
            end
        end
    end
end

BistooltipPools.Frames = CreateGenericPool(
    function()
        local f = CreateFrame("Frame", nil, UIParent)
        f._bt_data = {}
        return f
    end,
    CreateFrameResetFunc(UIParent),
    function(f) return f and f.IsShown ~= nil end
)

-- ============================================================
-- Button Pool - Pooling for clickable item icons
-- ============================================================

local function ResetButton(btn)
    -- Use centralized reset from util/reset.lua
    if BistooltipReset and BistooltipReset.ResetIconFrame then
        BistooltipReset.ResetIconFrame(btn)
    else
        -- Fallback if reset module not loaded yet
        if not btn then return end
        btn:Hide()
        btn:ClearAllPoints()
        btn:SetParent(UIParent)
        btn:SetSize(40, 40)
        btn:SetAlpha(1)
        btn:EnableMouse(true)
        btn:SetScript("OnClick", nil)
        btn:SetScript("OnEnter", nil)
        btn:SetScript("OnLeave", nil)
        if btn._bt_texture then
            btn._bt_texture:SetTexture(nil)
            btn._bt_texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
        if btn._bt_border then btn._bt_border:Hide() end
        if btn._bt_glow then btn._bt_glow:Hide() end
        if btn._bt_checkmark then btn._bt_checkmark:Hide() end
        if btn._bt_boeMark then btn._bt_boeMark:Hide() end
        if btn._bt_countText then btn._bt_countText:SetText("") end
        if btn._bt_selectionBorder then btn._bt_selectionBorder:Hide() end
        if btn._bt_data then wipe(btn._bt_data) end
    end
end

local function CreateIconButton()
    local btn = CreateFrame("Button", nil, UIParent)
    btn:SetSize(40, 40)
    btn:RegisterForClicks("AnyUp")  -- Enable click handling
    btn._bt_data = {}
    
    -- Main texture (125% zoom to remove Blizzard borders)
    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    btn._bt_texture = tex
    
    -- Border overlay (for owned items) - larger for visibility
    local border = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetPoint("TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", 6, -6)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetAlpha(0.9)
    border:Hide()
    btn._bt_border = border
    
    -- Glow effect
    local glow = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    glow:SetPoint("TOPLEFT", -6, 6)
    glow:SetPoint("BOTTOMRIGHT", 6, -6)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:Hide()
    btn._bt_glow = glow
    
    -- Checkmark for owned items
    local check = btn:CreateTexture(nil, "OVERLAY", nil, 3)
    check:SetSize(20, 20)
    check:SetPoint("TOPRIGHT", 4, 4)
    check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    check:Hide()
    btn._bt_checkmark = check
    
    -- BoE marker
    local boe = btn:CreateTexture(nil, "OVERLAY", nil, 3)
    boe:SetSize(14, 14)
    boe:SetPoint("BOTTOMLEFT", -2, -2)
    boe:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    boe:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    boe:Hide()
    btn._bt_boeMark = boe

    -- Tier gear marker (shoulder icon for T7-10.5)
    local tier = btn:CreateTexture(nil, "OVERLAY", nil, 3)
    tier:SetSize(14, 14)
    tier:SetPoint("TOPLEFT", -2, 2)
    tier:SetTexture("Interface\\Icons\\INV_Shoulder_22")
    tier:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    tier:Hide()
    btn._bt_tierMark = tier

    -- Count text
    local count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    count:SetText("")
    btn._bt_countText = count
    
    -- Selection border (for customize mode)
    local sel = btn:CreateTexture(nil, "OVERLAY", nil, 4)
    sel:SetPoint("TOPLEFT", -3, 3)
    sel:SetPoint("BOTTOMRIGHT", 3, -3)
    sel:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    sel:SetVertexColor(1, 0, 0, 1)
    sel:SetBlendMode("ADD")
    sel:Hide()
    btn._bt_selectionBorder = sel
    
    return btn
end

BistooltipPools.IconButtons = CreateGenericPool(
    CreateIconButton,
    ResetButton,
    function(btn) return btn and btn._bt_texture ~= nil end
)

-- ============================================================
-- FontString Pool - Pooling for text labels
-- ============================================================

local function ResetFontString(fs)
    -- Use centralized reset from util/reset.lua
    if BistooltipReset and BistooltipReset.ResetFontString then
        BistooltipReset.ResetFontString(fs)
    else
        -- Fallback
        if not fs then return end
        fs:Hide()
        fs:ClearAllPoints()
        fs:SetParent(UIParent)
        fs:SetText("")
        fs:SetTextColor(1, 1, 1, 1)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("MIDDLE")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        fs:SetWidth(0)
        fs:SetHeight(0)
    end
end

BistooltipPools.FontStrings = CreateGenericPool(
    function()
        local fs = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        return fs
    end,
    ResetFontString,
    function(fs) return fs and fs.SetText ~= nil end
)

-- ============================================================
-- Texture Pool - Pooling for decorative textures
-- ============================================================

local function ResetTexture(tex)
    -- Use centralized reset from util/reset.lua
    if BistooltipReset and BistooltipReset.ResetTexture then
        BistooltipReset.ResetTexture(tex)
    else
        -- Fallback
        if not tex then return end
        tex:Hide()
        tex:ClearAllPoints()
        tex:SetParent(UIParent)
        tex:SetTexture(nil)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetAlpha(1)
        tex:SetBlendMode("BLEND")
        tex:SetSize(1, 1)
    end
end

BistooltipPools.Textures = CreateGenericPool(
    function()
        local tex = UIParent:CreateTexture(nil, "ARTWORK")
        return tex
    end,
    ResetTexture,
    function(tex) return tex and tex.SetTexture ~= nil end
)

-- ============================================================
-- Slot Row Pool - Pre-configured rows for BIS list
-- ============================================================

local function CreateSlotRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetHeight(48)
    row._bt_data = {}
    
    -- Slot name label
    local slotLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slotLabel:SetPoint("LEFT", 4, 0)
    slotLabel:SetWidth(80)
    slotLabel:SetJustifyH("LEFT")
    row._bt_slotLabel = slotLabel
    
    -- Enhancement info (enchants/gems)
    local enhLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enhLabel:SetPoint("LEFT", slotLabel, "RIGHT", 4, 0)
    enhLabel:SetWidth(50)
    enhLabel:SetJustifyH("LEFT")
    row._bt_enhLabel = enhLabel
    
    -- Container for item icons
    local iconContainer = CreateFrame("Frame", nil, row)
    iconContainer:SetPoint("LEFT", enhLabel, "RIGHT", 4, 0)
    iconContainer:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    iconContainer:SetHeight(44)
    row._bt_iconContainer = iconContainer
    
    -- Pre-allocate icon slots (up to 8)
    row._bt_icons = {}
    for i = 1, 8 do
        local iconSlot = CreateFrame("Frame", nil, iconContainer)
        iconSlot:SetSize(44, 44)
        iconSlot:Hide()
        row._bt_icons[i] = iconSlot
    end
    
    -- Background highlight
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0, 0, 0, 0)
    row._bt_background = bg
    
    return row
end

local function ResetSlotRow(row)
    -- Use centralized reset from util/reset.lua
    if BistooltipReset and BistooltipReset.ResetRowFrame then
        BistooltipReset.ResetRowFrame(row)
    else
        -- Fallback
        if not row then return end
        row:Hide()
        row:ClearAllPoints()
        row:SetParent(UIParent)
        if row._bt_slotLabel then row._bt_slotLabel:SetText("") end
        if row._bt_enhLabel then row._bt_enhLabel:SetText("") end
        if row._bt_background then row._bt_background:SetVertexColor(0, 0, 0, 0) end
        if row._bt_icons then
            for _, iconSlot in ipairs(row._bt_icons) do iconSlot:Hide() end
        end
        if row._bt_data then wipe(row._bt_data) end
    end
end

BistooltipPools.SlotRows = CreateGenericPool(
    CreateSlotRow,
    ResetSlotRow,
    function(row) return row and row._bt_slotLabel ~= nil end
)

-- ============================================================
-- Separator Line Pool
-- ============================================================

local function CreateSeparator()
    local sep = CreateFrame("Frame", nil, UIParent)
    sep:SetHeight(1)
    
    local line = sep:CreateTexture(nil, "ARTWORK")
    line:SetAllPoints()
    line:SetTexture("Interface\\Buttons\\WHITE8x8")
    line:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    sep._bt_line = line
    
    return sep
end

local function ResetSeparator(sep)
    if not sep then return end
    sep:Hide()
    sep:ClearAllPoints()
    sep:SetParent(UIParent)
    sep:SetWidth(1)
    if sep._bt_line then
        sep._bt_line:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    end
end

BistooltipPools.Separators = CreateGenericPool(
    CreateSeparator,
    ResetSeparator,
    function(sep) return sep and sep._bt_line ~= nil end
)

-- ============================================================
-- Boss Header Pool (for checklist panel)
-- ============================================================

local function CreateBossHeader()
    local header = CreateFrame("Button", nil, UIParent)
    header:SetHeight(24)
    header._bt_data = {}
    
    -- Background
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
    header._bt_bg = bg
    
    -- Collapse indicator
    local indicator = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    indicator:SetPoint("LEFT", 4, 0)
    indicator:SetWidth(16)
    indicator:SetText("+")
    header._bt_indicator = indicator
    
    -- Boss name
    local bossLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bossLabel:SetPoint("LEFT", indicator, "RIGHT", 4, 0)
    bossLabel:SetJustifyH("LEFT")
    header._bt_bossLabel = bossLabel
    
    -- Zone name
    local zoneLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("LEFT", bossLabel, "RIGHT", 8, 0)
    zoneLabel:SetTextColor(0.7, 0.7, 0.7)
    header._bt_zoneLabel = zoneLabel
    
    -- Item count
    local countLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("RIGHT", -4, 0)
    countLabel:SetJustifyH("RIGHT")
    header._bt_countLabel = countLabel
    
    return header
end

local function ResetBossHeader(header)
    -- Use centralized reset from util/reset.lua
    if BistooltipReset and BistooltipReset.ResetBossHeader then
        BistooltipReset.ResetBossHeader(header)
    else
        -- Fallback
        if not header then return end
        header:Hide()
        header:ClearAllPoints()
        header:SetParent(UIParent)
        header:SetScript("OnClick", nil)
        header:SetScript("OnEnter", nil)
        header:SetScript("OnLeave", nil)
        if header._bt_indicator then header._bt_indicator:SetText("+") end
        if header._bt_bossLabel then header._bt_bossLabel:SetText("") end
        if header._bt_zoneLabel then header._bt_zoneLabel:SetText("") end
        if header._bt_countLabel then header._bt_countLabel:SetText("") end
        if header._bt_bg then header._bt_bg:SetVertexColor(0.15, 0.15, 0.15, 0.9) end
        if header._bt_data then wipe(header._bt_data) end
    end
end

BistooltipPools.BossHeaders = CreateGenericPool(
    CreateBossHeader,
    ResetBossHeader,
    function(h) return h and h._bt_bossLabel ~= nil end
)

-- ============================================================
-- Item Row Pool (for checklist panel)
-- ============================================================

local function CreateItemRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetHeight(36)
    row._bt_data = {}
    
    -- Icon
    local iconBtn = CreateFrame("Button", nil, row)
    iconBtn:SetSize(28, 28)
    iconBtn:SetPoint("LEFT", 20, 0)
    
    local iconTex = iconBtn:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints()
    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    iconBtn._bt_texture = iconTex
    row._bt_icon = iconBtn
    
    -- Slot label
    local slotLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slotLabel:SetPoint("LEFT", iconBtn, "RIGHT", 6, 8)
    slotLabel:SetWidth(60)
    slotLabel:SetJustifyH("LEFT")
    row._bt_slotLabel = slotLabel
    
    -- Item name label
    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", iconBtn, "RIGHT", 6, -6)
    nameLabel:SetWidth(180)
    nameLabel:SetJustifyH("LEFT")
    row._bt_nameLabel = nameLabel
    
    -- Source label
    local sourceLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("RIGHT", -4, 0)
    sourceLabel:SetWidth(100)
    sourceLabel:SetJustifyH("RIGHT")
    row._bt_sourceLabel = sourceLabel
    
    return row
end

local function ResetItemRow(row)
    -- Use centralized reset from util/reset.lua
    if BistooltipReset and BistooltipReset.ResetItemRow then
        BistooltipReset.ResetItemRow(row)
    else
        -- Fallback
        if not row then return end
        row:Hide()
        row:ClearAllPoints()
        row:SetParent(UIParent)
        if row._bt_icon then
            row._bt_icon:SetScript("OnClick", nil)
            row._bt_icon:SetScript("OnEnter", nil)
            row._bt_icon:SetScript("OnLeave", nil)
            if row._bt_icon._bt_texture then
                row._bt_icon._bt_texture:SetTexture(nil)
            end
        end
        if row._bt_slotLabel then row._bt_slotLabel:SetText("") end
        if row._bt_nameLabel then row._bt_nameLabel:SetText("") end
        if row._bt_sourceLabel then row._bt_sourceLabel:SetText("") end
        if row._bt_data then wipe(row._bt_data) end
    end
end

BistooltipPools.ItemRows = CreateGenericPool(
    CreateItemRow,
    ResetItemRow,
    function(row) return row and row._bt_icon ~= nil end
)

-- ============================================================
-- Global Pool Release (cleanup all pools)
-- ============================================================

function BistooltipPools.ReleaseAll()
    BistooltipPools.Frames:ReleaseAll()
    BistooltipPools.IconButtons:ReleaseAll()
    BistooltipPools.FontStrings:ReleaseAll()
    BistooltipPools.Textures:ReleaseAll()
    BistooltipPools.SlotRows:ReleaseAll()
    BistooltipPools.Separators:ReleaseAll()
    BistooltipPools.BossHeaders:ReleaseAll()
    BistooltipPools.ItemRows:ReleaseAll()
end

-- ============================================================
-- Debug/Stats Function
-- ============================================================

function BistooltipPools.PrintStats()
    local pools = {
        { name = "Frames", pool = BistooltipPools.Frames },
        { name = "IconButtons", pool = BistooltipPools.IconButtons },
        { name = "FontStrings", pool = BistooltipPools.FontStrings },
        { name = "Textures", pool = BistooltipPools.Textures },
        { name = "SlotRows", pool = BistooltipPools.SlotRows },
        { name = "Separators", pool = BistooltipPools.Separators },
        { name = "BossHeaders", pool = BistooltipPools.BossHeaders },
        { name = "ItemRows", pool = BistooltipPools.ItemRows },
    }
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip Pool Stats:|r")
    for _, p in ipairs(pools) do
        local stats = p.pool:GetStats()
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %d available, %d in use, %d total (peak: %d)",
            p.name, stats.available, stats.inUse, stats.totalCreated, stats.peakUsage))
    end
end

-- ============================================================
-- Pre-warm pools on load
-- ============================================================

local poolsInitialized = false

function BistooltipPools.Initialize()
    if poolsInitialized then return end
    -- Pre-warm commonly used pools
    -- 17 slots × 8 items = 136 icons max, plus gems/enchants = ~200 total
    -- Pre-warming prevents CreateFrame calls during rendering
    BistooltipPools.IconButtons:PreWarm(150)   -- was 50, need ~136 for full render
    BistooltipPools.FontStrings:PreWarm(100)   -- was 30, labels + headers
    BistooltipPools.SlotRows:PreWarm(25)       -- was 20, 17 slots + buffer
    BistooltipPools.Separators:PreWarm(20)     -- was 10
    BistooltipPools.BossHeaders:PreWarm(25)    -- was 15, for BIS mode grouping
    BistooltipPools.ItemRows:PreWarm(50)       -- was 30, for checklist
    BistooltipPools.Textures:PreWarm(100)      -- NEW: for overlays/decorations
    BistooltipPools.Frames:PreWarm(30)         -- NEW: generic containers
    poolsInitialized = true
end
