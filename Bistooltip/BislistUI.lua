-- ============================================================
-- BislistUI.lua - Main BiS List Window UI (Refactored)
-- Uses Object Pooling, Custom Layout, Clean Architecture
-- ============================================================

local ADDON_NAME = "Bis-Tooltip"
local AceGUI = LibStub("AceGUI-3.0")

-- Import modules
local Utils = BistooltipUtils
local Constants = BistooltipConstants
local Pools = BistooltipPools
local UI = BistooltipUI
local Data = BistooltipData
local State = BistooltipState

-- ============================================================
-- UNIFIED STYLING SYSTEM - Modern, consistent look
-- ============================================================

local STYLE = {
    -- Color palette
    COLORS = {
        -- Backgrounds
        BG_DARK = { 0.06, 0.06, 0.08, 0.95 },
        BG_MEDIUM = { 0.10, 0.10, 0.12, 0.95 },
        BG_LIGHT = { 0.14, 0.14, 0.16, 0.95 },
        BG_HOVER = { 0.18, 0.18, 0.22, 0.95 },

        -- Borders
        BORDER_SUBTLE = { 0.25, 0.25, 0.30, 0.6 },
        BORDER_NORMAL = { 0.35, 0.35, 0.40, 0.8 },
        BORDER_VISIBLE = { 0.45, 0.45, 0.50, 0.9 },  -- Brighter for inactive toggle buttons
        BORDER_ACCENT = { 0.40, 0.65, 0.90, 0.9 },

        -- Text
        TEXT_NORMAL = { 0.85, 0.85, 0.85, 1.0 },
        TEXT_DIM = { 0.55, 0.55, 0.55, 1.0 },
        TEXT_BRIGHT = { 1.0, 1.0, 1.0, 1.0 },
        TEXT_ACCENT = { 0.50, 0.75, 1.0, 1.0 },

        -- Accent colors
        ACCENT_BLUE = { 0.30, 0.60, 0.95, 1.0 },
        ACCENT_BLUE_DIM = { 0.20, 0.45, 0.75, 0.9 },
        ACCENT_TEAL = { 0.0, 0.75, 0.55, 1.0 },
        ACCENT_GOLD = { 0.90, 0.75, 0.30, 1.0 },

        -- Shadow
        SHADOW = { 0.0, 0.0, 0.0, 0.5 },
    },

    -- Dimensions
    BUTTON_HEIGHT = 26,
    BUTTON_BORDER = 1,
    TAB_HEIGHT = 28,
    HEADER_HEIGHT = 26,
}

-- Helper: Apply color from table
local function ApplyColor(texture, colorTable)
    if texture and colorTable then
        texture:SetVertexColor(colorTable[1], colorTable[2], colorTable[3], colorTable[4] or 1)
    end
end

-- Helper: Set text color from table
local function ApplyTextColor(fontString, colorTable)
    if fontString and colorTable then
        fontString:SetTextColor(colorTable[1], colorTable[2], colorTable[3], colorTable[4] or 1)
    end
end

-- ============================================================
-- STYLED BUTTON FACTORY - Unified button creation
-- ============================================================

local function CreateStyledButton(parent, text, width, height, onClick, tooltipText)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 70, height or STYLE.BUTTON_HEIGHT)

    -- Main background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(bg, STYLE.COLORS.BG_MEDIUM)
    btn._bg = bg

    -- Border (4 edges for crisp look)
    local borderTop = btn:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(borderTop, STYLE.COLORS.BORDER_SUBTLE)

    local borderBottom = btn:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(borderBottom, STYLE.COLORS.BORDER_SUBTLE)

    local borderLeft = btn:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(borderLeft, STYLE.COLORS.BORDER_SUBTLE)

    local borderRight = btn:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(borderRight, STYLE.COLORS.BORDER_SUBTLE)

    btn._borders = { borderTop, borderBottom, borderLeft, borderRight }

    -- Label
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text or "")
    ApplyTextColor(label, STYLE.COLORS.TEXT_NORMAL)
    btn._label = label

    -- State tracking
    btn._isActive = false
    btn._isToggle = false

    -- Set active state (for toggle buttons)
    btn.SetActive = function(self, active)
        self._isActive = active
        if active then
            ApplyColor(self._bg, STYLE.COLORS.ACCENT_BLUE_DIM)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.ACCENT_BLUE)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        else
            ApplyColor(self._bg, STYLE.COLORS.BG_MEDIUM)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.BORDER_SUBTLE)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        end
    end

    -- Mark as toggle button
    btn.SetToggleMode = function(self, isToggle)
        self._isToggle = isToggle
    end

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        if not self._isActive then
            ApplyColor(self._bg, STYLE.COLORS.BG_HOVER)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.BORDER_NORMAL)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        end
        if tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if self._isActive then
            ApplyColor(self._bg, STYLE.COLORS.ACCENT_BLUE_DIM)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.ACCENT_BLUE)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        else
            ApplyColor(self._bg, STYLE.COLORS.BG_MEDIUM)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.BORDER_SUBTLE)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        end
        GameTooltip:Hide()
    end)

    -- Click handler
    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

-- ============================================================
-- SHADOW HELPER - Add subtle depth to frames
-- ============================================================

local function AddFrameShadow(frame, offset, alpha)
    offset = offset or 3
    alpha = alpha or 0.4

    -- Shadow is created as a separate frame behind
    local shadow = CreateFrame("Frame", nil, frame)
    shadow:SetFrameLevel(math.max(1, frame:GetFrameLevel() - 1))
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)

    local shadowTex = shadow:CreateTexture(nil, "BACKGROUND")
    shadowTex:SetAllPoints()
    shadowTex:SetTexture("Interface\\Buttons\\WHITE8x8")
    shadowTex:SetVertexColor(0, 0, 0, alpha)

    frame._shadow = shadow
    return shadow
end

-- ============================================================
-- Lua 5.1 Compatibility: Delayed Call Helper (Optimized)
-- Uses mark-and-compact instead of table.remove() for O(n) instead of O(n²)
-- ============================================================

local delayedCallFrame = nil
local delayedCallQueue = {}
local delayedCallQueueSize = 0

local function DelayedCall(delay, func)
    if not delayedCallFrame then
        delayedCallFrame = CreateFrame("Frame")
        delayedCallFrame:SetScript("OnUpdate", function(self, elapsed)
            local needsCompact = false

            -- Process all entries, mark expired ones
            for i = 1, delayedCallQueueSize do
                local entry = delayedCallQueue[i]
                if entry then
                    entry.remaining = entry.remaining - elapsed
                    if entry.remaining <= 0 then
                        local success, err = pcall(entry.func)
                        delayedCallQueue[i] = nil  -- Mark for removal
                        needsCompact = true
                    end
                end
            end

            -- Compact array once per frame if needed
            if needsCompact then
                local writeIdx = 1
                for readIdx = 1, delayedCallQueueSize do
                    local entry = delayedCallQueue[readIdx]
                    if entry then
                        if writeIdx ~= readIdx then
                            delayedCallQueue[writeIdx] = entry
                            delayedCallQueue[readIdx] = nil
                        end
                        writeIdx = writeIdx + 1
                    end
                end
                delayedCallQueueSize = writeIdx - 1
            end

            if delayedCallQueueSize == 0 then
                self:Hide()
            end
        end)
    end

    delayedCallQueueSize = delayedCallQueueSize + 1
    delayedCallQueue[delayedCallQueueSize] = { remaining = delay, func = func }
    delayedCallFrame:Show()
end

-- ============================================================
-- Local State References
-- ============================================================

local mainFrame = nil
local specFrame = nil

-- Dropdown references (native dropdowns - for backward compatibility)
local classDropdown = nil
local specDropdown = nil
local phaseDropdown = nil

-- UI element references
local checklistSummaryLabel = nil
local emblemSummaryLabel = nil
local customizeToggleRef = nil
local resetBtnRef = nil

-- Class/spec option tables
local class_options = {}
local class_options_to_class = {}
local spec_options = {}
local spec_options_to_spec = {}

-- Preload system
local preloadFrame = nil
local preloadQueue = {}
local preloadSeen = {}
local preloadCooldown = 0
local PRELOAD_BATCH = Constants.TIMING and Constants.TIMING.PRELOAD_BATCH_SIZE or 5
local PRELOAD_INTERVAL = Constants.TIMING and Constants.TIMING.PRELOAD_INTERVAL or 0.1

-- Active pooled elements tracking (for proper cleanup)
local activePooledElements = {
    icons = {},
    rows = {},
    separators = {},
    headers = {},
    itemRows = {},
    textures = {},
    fontStrings = {},
}

-- ============================================================
-- Tab System (Phase 4 UI)
-- ============================================================

local TAB_MAIN = 1
local TAB_BIS = 2
local TAB_OPTIONS = 3

local currentTab = TAB_MAIN
local tabBarFrame = nil
local tabButtons = {}

-- ============================================================
-- NEW UI Layout Constants (Phase 4)
-- ============================================================

local LAYOUT = {
    TITLE_HEIGHT = 24,      -- AceGUI title bar
    TAB_BAR_HEIGHT = 32,    -- Tab bar below title
    FILTER_BAR_HEIGHT = 36, -- Filter bar (class/spec/phase + pills)
    PROGRESS_BAR_HEIGHT = 20, -- Progress bar
    HEADER_HEIGHT = 28,     -- Column headers with search
    BOTTOM_BAR_HEIGHT = 40, -- Bottom bar (buttons)
    ROW_HEIGHT = 52,        -- Content row height
    PADDING = 8,            -- General padding
}

-- New UI frame references
local uiFrames = {
    tabBar = nil,
    filterBar = nil,
    progressBar = nil,
    headerRow = nil,
    scrollArea = nil,
    contentFrame = nil,
    bottomBar = nil,
}

-- Forward declarations for tab switching
local drawSpecData

local function UpdateTabButtonAppearance(btn, isActive)
    if not btn then return end
    if isActive then
        -- Active tab: lighter background, bright accent line, white text
        ApplyColor(btn._bg, STYLE.COLORS.BG_LIGHT)
        btn._highlight:Show()
        btn._highlight:SetVertexColor(STYLE.COLORS.ACCENT_BLUE[1], STYLE.COLORS.ACCENT_BLUE[2], STYLE.COLORS.ACCENT_BLUE[3], 1)
        ApplyTextColor(btn._label, STYLE.COLORS.TEXT_BRIGHT)
        -- Show top border accent
        if btn._topBorder then
            ApplyColor(btn._topBorder, STYLE.COLORS.ACCENT_BLUE)
            btn._topBorder:Show()
        end
    else
        -- Inactive tab: dark background, no highlight, dim text
        ApplyColor(btn._bg, STYLE.COLORS.BG_DARK)
        btn._highlight:Hide()
        ApplyTextColor(btn._label, STYLE.COLORS.TEXT_DIM)
        if btn._topBorder then
            btn._topBorder:Hide()
        end
    end
end

local function SwitchToTab(tabId)
    if tabId == currentTab and tabId ~= TAB_OPTIONS then return end

    local oldTab = currentTab

    -- OPTIONS opens config and returns to previous tab
    if tabId == TAB_OPTIONS then
        if BistooltipAddon.openConfigDialog then
            BistooltipAddon:openConfigDialog()
        end
        return
    end

    currentTab = tabId

    -- Update tab appearances
    for id, btn in pairs(tabButtons) do
        UpdateTabButtonAppearance(btn, id == tabId)
    end

    -- Handle mode switching
    if tabId == TAB_MAIN then
        State.SetChecklistMode(false)
        -- Disable ASCEND mode when leaving BIS tab
        State.SetEmblemFilterMode(false)
        -- Reset ASCEND button visual using STYLE system
        if uiFrames.ascendBtn then
            if uiFrames.ascendBtn._bg then
                ApplyColor(uiFrames.ascendBtn._bg, STYLE.COLORS.BG_MEDIUM)
            end
            if uiFrames.ascendBtn._borders then
                for _, border in ipairs(uiFrames.ascendBtn._borders) do
                    ApplyColor(border, STYLE.COLORS.BORDER_SUBTLE)
                end
            end
            if uiFrames.ascendBtn._label then
                ApplyTextColor(uiFrames.ascendBtn._label, STYLE.COLORS.TEXT_NORMAL)
            end
            uiFrames.ascendBtn._isActive = false
        end
        if BistooltipAddon.db and BistooltipAddon.db.char then
            BistooltipAddon.db.char.bis_checklist = false
        end
    elseif tabId == TAB_BIS then
        State.SetChecklistMode(true)
        if BistooltipAddon.db and BistooltipAddon.db.char then
            BistooltipAddon.db.char.bis_checklist = true
        end
    end

    -- Redraw content
    if drawSpecData then
        drawSpecData()
    end
end

local function CreateTabBar(parent)
    if tabBarFrame then
        tabBarFrame:Show()
        return tabBarFrame
    end

    local TAB_HEIGHT = STYLE.TAB_HEIGHT or 28
    local TAB_WIDTH = Constants.UI.TAB_WIDTH or 100
    local TAB_SPACING = 1  -- Tighter spacing for modern look

    -- Tab bar container - positioned below title bar
    tabBarFrame = CreateFrame("Frame", "BistooltipTabBar", parent)
    tabBarFrame:SetHeight(TAB_HEIGHT + 4)
    tabBarFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -26)
    tabBarFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -26)

    -- Ensure tabs are visible above other elements
    tabBarFrame:SetFrameStrata("HIGH")
    tabBarFrame:SetFrameLevel(parent:GetFrameLevel() + 10)

    -- Tab definitions
    local tabs = {
        { id = TAB_MAIN, name = "MAIN" },
        { id = TAB_BIS, name = "BIS" },
        { id = TAB_OPTIONS, name = "OPTIONS" },
    }

    -- Tab bar background (subtle)
    local barBg = tabBarFrame:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(barBg, STYLE.COLORS.BG_DARK)

    -- Bottom separator line
    local barSep = tabBarFrame:CreateTexture(nil, "ARTWORK")
    barSep:SetPoint("BOTTOMLEFT", tabBarFrame, "BOTTOMLEFT", 0, 0)
    barSep:SetPoint("BOTTOMRIGHT", tabBarFrame, "BOTTOMRIGHT", 0, 0)
    barSep:SetHeight(1)
    barSep:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(barSep, STYLE.COLORS.BORDER_SUBTLE)

    -- Create tabs
    for i, tabDef in ipairs(tabs) do
        local btn = CreateFrame("Button", "BistooltipTab" .. tabDef.id, tabBarFrame)
        btn:SetSize(TAB_WIDTH, TAB_HEIGHT)
        btn:SetPoint("LEFT", tabBarFrame, "LEFT", (i - 1) * (TAB_WIDTH + TAB_SPACING), 1)
        btn:SetFrameStrata("HIGH")

        -- Background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 0)
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn._bg = bg

        -- Top accent border (shown when active)
        local topBorder = btn:CreateTexture(nil, "ARTWORK")
        topBorder:SetPoint("TOPLEFT", 1, 0)
        topBorder:SetPoint("TOPRIGHT", -1, 0)
        topBorder:SetHeight(2)
        topBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        topBorder:Hide()
        btn._topBorder = topBorder

        -- Bottom highlight (accent line when active)
        local highlight = btn:CreateTexture(nil, "OVERLAY")
        highlight:SetPoint("BOTTOMLEFT", 1, 0)
        highlight:SetPoint("BOTTOMRIGHT", -1, 0)
        highlight:SetHeight(2)
        highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
        highlight:Hide()
        btn._highlight = highlight

        -- Side borders (subtle separation)
        local leftBorder = btn:CreateTexture(nil, "BORDER")
        leftBorder:SetPoint("TOPLEFT", 0, 0)
        leftBorder:SetPoint("BOTTOMLEFT", 0, 0)
        leftBorder:SetWidth(1)
        leftBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(leftBorder, STYLE.COLORS.BORDER_SUBTLE)

        local rightBorder = btn:CreateTexture(nil, "BORDER")
        rightBorder:SetPoint("TOPRIGHT", 0, 0)
        rightBorder:SetPoint("BOTTOMRIGHT", 0, 0)
        rightBorder:SetWidth(1)
        rightBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(rightBorder, STYLE.COLORS.BORDER_SUBTLE)

        -- Label
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER", 0, 1)
        label:SetText(tabDef.name)
        btn._label = label

        -- Initial appearance
        UpdateTabButtonAppearance(btn, tabDef.id == currentTab)

        -- Hover
        btn:SetScript("OnEnter", function(self)
            if currentTab ~= tabDef.id then
                ApplyColor(self._bg, STYLE.COLORS.BG_HOVER)
                ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
            end
        end)

        btn:SetScript("OnLeave", function(self)
            UpdateTabButtonAppearance(self, currentTab == tabDef.id)
        end)

        -- Click
        btn:SetScript("OnClick", function()
            SwitchToTab(tabDef.id)
        end)

        tabButtons[tabDef.id] = btn
    end

    tabBarFrame:Show()
    return tabBarFrame
end

local function DestroyTabBar()
    if tabBarFrame then
        tabBarFrame:Hide()
        tabBarFrame:SetParent(nil)
    end
    tabBarFrame = nil
    wipe(tabButtons)
    currentTab = TAB_MAIN
end

-- ============================================================
-- Row Frame Management (TRUE POOLING to prevent memory exhaustion)
-- WoW frames cannot be garbage collected - must reuse them
-- ============================================================

local customRowPool = {}  -- Available row frames for reuse
local customRowPoolTotal = 0  -- Total rows ever created

-- Reset a row's visual state without destroying children
local function ResetRowVisuals(row)
    if not row then return end
    row:Hide()
    row:ClearAllPoints()
    row:SetScript("OnEnter", nil)
    row:SetScript("OnLeave", nil)
    row:SetScript("OnMouseDown", nil)
    -- Note: OnClick only exists on Button frames, not Frame - skip for safety

    -- Hide all stored children (textures, fontstrings, buttons)
    if row._bg then row._bg:Hide() end
    if row._border then row._border:Hide() end
    if row._slotIcon then row._slotIcon:Hide() end
    if row._slotLabel then row._slotLabel:Hide() end
    if row._planText then row._planText:Hide() end

    -- Hide plan frame and its children
    if row._planFrame then
        row._planFrame:Hide()
        if row._planFrame._bossText then row._planFrame._bossText:Hide() end
        if row._planFrame._itemText then row._planFrame._itemText:Hide() end
        if row._planFrame._enchFrame then row._planFrame._enchFrame:Hide() end
        if row._planFrame._enchLabel then row._planFrame._enchLabel:Hide() end
        if row._planFrame._gemFrames then
            for _, gf in ipairs(row._planFrame._gemFrames) do gf:Hide() end
        end
        if row._planFrame._gemLabels then
            for _, gl in ipairs(row._planFrame._gemLabels) do gl:Hide() end
        end
    end

    -- Hide lock frame and its children
    if row._lockFrame then
        row._lockFrame:Hide()
        if row._lockStatusLabel then row._lockStatusLabel:Hide() end
    end

    -- Hide BIS mode column labels
    if row._sourceLabel then row._sourceLabel:Hide() end
    if row._costLabel then row._costLabel:Hide() end
    if row._dropLabel then row._dropLabel:Hide() end
    if row._specsLabel then row._specsLabel:Hide() end
    if row._ilvlLabel then row._ilvlLabel:Hide() end

    -- Hide gems_bis elements
    if row._gemBisContainer then row._gemBisContainer:Hide() end
    if row._gemBisButtons then
        for _, btn in ipairs(row._gemBisButtons) do btn:Hide() end
    end
    if row._gemBisStats then
        for _, lbl in ipairs(row._gemBisStats) do lbl:Hide() end
    end

    -- Hide dynamic icon buttons
    if row._iconButtons then
        for _, btn in ipairs(row._iconButtons) do
            btn:Hide()
            btn:ClearAllPoints()
        end
    end

    -- Reset icon button index for reuse
    row._iconBtnIndex = 0

    -- Hide gem stat labels (for gem_detailed option - old implementation)
    if row._gemStatLabels then
        for _, lbl in ipairs(row._gemStatLabels) do
            lbl:Hide()
        end
    end

    -- Hide enchant name label (for enchant_detailed option - old implementation)
    if row._enchantNameLabel then
        row._enchantNameLabel:Hide()
    end

    -- Hide mode label
    if row._modeLabel then
        row._modeLabel:Hide()
    end

    -- Hide enchant detail row elements (new implementation)
    if row._enchDetailIcon then row._enchDetailIcon:Hide() end
    if row._enchDetailName then row._enchDetailName:Hide() end

    -- Hide gem detail row elements (new implementation)
    if row._gemDetailLabel then row._gemDetailLabel:Hide() end
    if row._gemDetailIcons then
        for _, icon in ipairs(row._gemDetailIcons) do icon:Hide() end
    end
    if row._gemDetailStats then
        for _, stat in ipairs(row._gemDetailStats) do stat:Hide() end
    end

    -- Clear data
    row._bt_data = {}
end

local function AcquireCustomRow(parent)
    local row = table.remove(customRowPool)
    if row then
        row:SetParent(parent or UIParent)
        row:Show()
        return row
    end

    -- Create new row with reusable children stored as properties
    row = CreateFrame("Frame", nil, parent or UIParent)
    row._bt_data = {}
    row._iconButtons = {}  -- Pool of icon buttons for this row
    customRowPoolTotal = customRowPoolTotal + 1
    row:Show()
    return row
end

local function ReleaseCustomRow(row)
    if not row then return end
    ResetRowVisuals(row)
    table.insert(customRowPool, row)
end

local function ReleaseAllCustomRows()
    -- No-op: tracking done via activeCustomRows
end

local function DestroyCustomRowPool()
    -- Can't actually destroy frames in WoW, but clear tracking
    wipe(customRowPool)
end

local function GetCustomRowPoolStats()
    return { available = #customRowPool, total = customRowPoolTotal }
end

-- ============================================================
-- Forward Declarations
-- ============================================================

-- Note: drawSpecData is forward declared in Tab System section above
local ClearCustomRows  -- Forward declaration (defined later)
local isDrawing = false  -- Guard against concurrent draws
local buildClassDict
local buildSpecsDict
local loadData
local saveData

-- ============================================================
-- UISpecialFrames Management
-- ============================================================

local mainFrameUISpecialName = nil

-- ============================================================
-- Cleanup Functions
-- ============================================================

local function ReleaseActiveElements()
    -- Release all tracked pooled elements
    for _, icon in ipairs(activePooledElements.icons) do
        Pools.IconButtons:Release(icon)
    end
    activePooledElements.icons = {}
    
    for _, row in ipairs(activePooledElements.rows) do
        Pools.SlotRows:Release(row)
    end
    activePooledElements.rows = {}
    
    for _, sep in ipairs(activePooledElements.separators) do
        Pools.Separators:Release(sep)
    end
    activePooledElements.separators = {}
    
    for _, header in ipairs(activePooledElements.headers) do
        Pools.BossHeaders:Release(header)
    end
    activePooledElements.headers = {}
    
    for _, itemRow in ipairs(activePooledElements.itemRows) do
        Pools.ItemRows:Release(itemRow)
    end
    activePooledElements.itemRows = {}
    
    for _, tex in ipairs(activePooledElements.textures) do
        Pools.Textures:Release(tex)
    end
    activePooledElements.textures = {}
    
    for _, fs in ipairs(activePooledElements.fontStrings) do
        Pools.FontStrings:Release(fs)
    end
    activePooledElements.fontStrings = {}
end

local function CleanupMainFrame()
    ReleaseActiveElements()
    State.ClearSelectedSwapItem()
    State.SetMainFrame(nil)
    State.SetSpecFrame(nil)

    -- Cancel any pending debounced operations
    if BistooltipDebounce and BistooltipDebounce.CancelAll then
        BistooltipDebounce.CancelAll()
    end

    -- Clear active rows list (check if exists first)
    if activeCustomRows then
        wipe(activeCustomRows)
    end

    -- Destroy the entire row pool (rows have destroyed parent after close)
    DestroyCustomRowPool()

    -- Destroy old tab bar (legacy)
    DestroyTabBar()

    -- Destroy UI frame references properly (don't just nil them)
    if uiFrames then
        -- Destroy progress bar if it exists
        if uiFrames.progressBar then
            uiFrames.progressBar:Hide()
            uiFrames.progressBar:SetParent(nil)
            uiFrames.progressBar = nil
        end
        -- Clear other references (they get destroyed with mainFrame)
        uiFrames.tabBar = nil
        uiFrames.filterBar = nil
        uiFrames.headerRow = nil
        uiFrames.scrollArea = nil
        uiFrames.contentFrame = nil
        uiFrames.bottomBar = nil
    end

    -- Clear tab buttons array to prevent stale references
    if tabButtons then wipe(tabButtons) end
    -- Clear NEW tab bar buttons array (module-level)
    if tabBarButtons then wipe(tabBarButtons) end
    -- Clear new tab bar frame reference
    tabBarFrame = nil
    -- Clear filter bar frame reference (module-level)
    filterBarFrame = nil
    -- Clear native dropdown references
    nativeClassDropdown = nil
    nativeSpecDropdown = nil
    nativePhaseDropdown = nil
    -- Clear pill buttons references
    if pillButtons then wipe(pillButtons) end
    if filterBarButtons then wipe(filterBarButtons) end

    -- Clear custom frame references (they get destroyed with mainFrame)
    customContentFrame = nil
    customScrollFrame = nil
    customHeaderFrame = nil
    specFrame = nil
    specContainerFrame = nil

    -- Remove from UISpecialFrames
    if mainFrameUISpecialName then
        Utils.RemoveFromUISpecialFrames(mainFrameUISpecialName)
        mainFrameUISpecialName = nil
    end
end

-- ============================================================
-- Preload System
-- ============================================================

local function QueuePreload(itemId)
    if not itemId or itemId <= 0 then return end
    if preloadSeen[itemId] then return end
    
    preloadSeen[itemId] = true
    table.insert(preloadQueue, itemId)
    
    if preloadFrame then
        preloadFrame:Show()
    end
end

local function InitPreloadSystem()
    if preloadFrame then return end
    
    preloadFrame = CreateFrame("Frame")
    preloadFrame:Hide()
    
    preloadFrame:SetScript("OnUpdate", function(self, elapsed)
        preloadCooldown = (preloadCooldown or 0) - (elapsed or 0)
        if preloadCooldown > 0 then return end
        preloadCooldown = PRELOAD_INTERVAL
        
        if #preloadQueue == 0 then
            self:Hide()
            return
        end
        
        -- Create scanner tooltip if needed
        if not BistooltipAddon._preloadScanner then
            local tt = CreateFrame("GameTooltip", "BistooltipPreloadScanner", UIParent, "GameTooltipTemplate")
            tt:SetOwner(UIParent, "ANCHOR_NONE")
            tt:Hide()
            BistooltipAddon._preloadScanner = tt
        end
        local scanTT = BistooltipAddon._preloadScanner
        
        for i = 1, PRELOAD_BATCH do
            local itemId = table.remove(preloadQueue)
            if not itemId then break end
            if not GetItemInfo(itemId) then
                scanTT:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
                scanTT:Hide()
            end
        end
        
        -- Refresh if main frame is visible and not already drawing
        if mainFrame and specFrame and mainFrame.frame:IsShown() and not isDrawing then
            drawSpecData()
        end
    end)
end

-- ============================================================
-- Bulk Preload System - Load ALL items for current selection
-- ============================================================

local bulkPreloadFrame = nil
local bulkPreloadPending = false

local function BulkPreloadAllItems(forceRefresh)
    local className, specName, phase = State.GetCurrentSelection()
    if not className or not specName or not phase then return end

    -- Get all slots for current selection
    local slots = Data.GetSlotsForSpec(className, specName, phase)
    if not slots then return end

    -- Create scanner tooltip if needed
    if not BistooltipAddon._bulkScanner then
        local tt = CreateFrame("GameTooltip", "BistooltipBulkScanner", UIParent, "GameTooltipTemplate")
        tt:SetOwner(UIParent, "ANCHOR_NONE")
        tt:Hide()
        BistooltipAddon._bulkScanner = tt
    end
    local scanTT = BistooltipAddon._bulkScanner

    local isHorde = State.Get("isHorde")
    local itemsToLoad = {}
    local itemsRequested = 0

    -- Collect all item IDs
    for _, slot in ipairs(slots) do
        for i = 1, 8 do
            local itemId = slot[i]
            if itemId and type(itemId) == "number" and itemId > 0 then
                local displayId = Data.GetDisplayItemID(itemId, isHorde)
                if not GetItemInfo(displayId) then
                    itemsToLoad[displayId] = true
                end
            end
        end
        -- Also preload enhancement items (gems, enchants)
        if slot.enhs then
            for _, enh in ipairs(slot.enhs) do
                if enh and enh.id and enh.id > 0 then
                    if not GetItemInfo(enh.id) then
                        itemsToLoad[enh.id] = true
                    end
                end
            end
        end
    end

    -- Request all items at once
    for itemId in pairs(itemsToLoad) do
        scanTT:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
        scanTT:Hide()
        itemsRequested = itemsRequested + 1
    end

    -- Schedule refresh after items are loaded
    if itemsRequested > 0 or forceRefresh then
        if not bulkPreloadFrame then
            bulkPreloadFrame = CreateFrame("Frame")
        end

        bulkPreloadPending = true
        local waitTime = 0
        local maxWait = 2.0  -- Max 2 seconds wait

        bulkPreloadFrame:SetScript("OnUpdate", function(self, elapsed)
            waitTime = waitTime + elapsed

            -- Check if items are loaded or timeout reached
            local allLoaded = true
            local checkCount = 0
            for itemId in pairs(itemsToLoad) do
                if checkCount > 20 then break end  -- Only check first 20 for performance
                if not GetItemInfo(itemId) then
                    allLoaded = false
                    break
                end
                checkCount = checkCount + 1
            end

            if allLoaded or waitTime >= maxWait then
                self:SetScript("OnUpdate", nil)
                bulkPreloadPending = false

                -- Refresh UI
                if mainFrame and mainFrame.frame:IsShown() and not isDrawing then
                    drawSpecData()
                end
            end
        end)
    end
end

-- Force reload all items (for Reload Data button)
local function ForceReloadAllItems()
    -- Clear preload seen cache to allow re-queueing
    wipe(preloadSeen)

    -- Trigger bulk preload
    BulkPreloadAllItems(true)
end

-- ============================================================
-- Class Colorization
-- ============================================================

local function ColorizeClassOption(className)
    local file = Utils.CLASSNAME_TO_FILE[className]
    local c = file and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[file]
    if c and c.r then
        return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, className)
    end
    return className
end

-- ============================================================
-- Simple Group Creator (AceGUI compatibility)
-- ============================================================

local function NewSimpleGroup()
    local g = AceGUI:Create("SimpleGroup")
    g:SetAutoAdjustHeight(true)
    return g
end

-- ============================================================
-- Icon TexCoord Helper (125% zoom to remove Blizzard borders)
-- ============================================================

local function SetIconTexCoord(iconWidget)
    if iconWidget and iconWidget.image then
        iconWidget.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
end

-- ============================================================
-- Make AceGUI Icon Clickable (creates invisible button overlay)
-- Shift+Click to link to chat (WoW standard behavior)
-- ============================================================

local function MakeIconClickable(iconWidget, onClick)
    if not iconWidget or not iconWidget.frame then return end

    -- Create invisible button overlay
    local btn = CreateFrame("Button", nil, iconWidget.frame)
    btn:SetAllPoints(iconWidget.frame)
    btn:RegisterForClicks("AnyUp")
    btn:SetFrameLevel(iconWidget.frame:GetFrameLevel() + 10)

    -- Forward mouse events to parent for tooltip
    btn:SetScript("OnEnter", function(self)
        local parent = self:GetParent()
        if parent and parent:GetScript("OnEnter") then
            parent:GetScript("OnEnter")(parent)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        local parent = self:GetParent()
        if parent and parent:GetScript("OnLeave") then
            parent:GetScript("OnLeave")(parent)
        end
    end)

    -- Require Shift key for linking (WoW standard behavior)
    btn:SetScript("OnClick", function(self, button)
        if IsShiftKeyDown() then
            onClick(self, button)
        end
    end)
    iconWidget._clickOverlay = btn
    return btn
end

-- ============================================================
-- Create Item Icon (Using Object Pool)
-- ============================================================

local function CreatePooledItemIcon(itemId, size, parent, callbacks)
    if not itemId or itemId <= 0 then return nil end
    
    local icon = Pools.IconButtons:Acquire()
    icon:SetParent(parent)
    icon:SetSize(size, size)
    
    -- Track for cleanup
    table.insert(activePooledElements.icons, icon)
    
    -- Normalize item ID
    local displayId = Data.GetDisplayItemID(itemId, State.Get("isHorde"))
    
    -- Get item info
    local itemName, itemLink, quality, _, _, _, _, _, _, itemIcon, _, itemType, _, bindType = GetItemInfo(displayId)
    
    if itemIcon then
        icon._bt_texture:SetTexture(itemIcon)
    else
        icon._bt_texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        QueuePreload(displayId)
    end
    
    -- Store data
    icon._bt_data.itemId = displayId
    icon._bt_data.originalItemId = itemId
    icon._bt_data.itemLink = itemLink
    
    -- Set up owned status
    local ownedState, ownedCount = Data.GetOwnedState(displayId)
    UI.SetOwnedStatus(icon, ownedState, ownedCount)
    
    -- Set up BoE marker
    if bindType and bindType == 2 then -- LE_ITEM_BIND_ON_EQUIP
        UI.SetBoEMarker(icon, true)
    end

    -- Set up Tier gear marker (entries from ex-Tier zones carry a tier stamp)
    if Data and Data.GetAllItemSources then
        for _, src in ipairs(Data.GetAllItemSources(displayId)) do
            if src.tier then
                UI.SetTierMarker(icon, true)
                break
            end
        end
    end

    -- Tooltip
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if itemLink then
            GameTooltip:SetHyperlink(itemLink)
        else
            Utils.TooltipSetItemByID(GameTooltip, displayId)
        end
        GameTooltip:Show()
    end)
    
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Click handlers
    icon:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if IsControlKeyDown() and itemLink then
                DressUpItemLink(itemLink)
            elseif State.Get("customizeMode") and callbacks and callbacks.onLeftClick then
                callbacks.onLeftClick(self, displayId, itemId)
            elseif IsShiftKeyDown() and itemLink then
                ChatEdit_InsertLink(itemLink)
            end
        elseif button == "RightButton" and callbacks and callbacks.onRightClick then
            callbacks.onRightClick(self, displayId, itemId)
        end
    end)
    
    icon:Show()
    return icon
end

-- ============================================================
-- Enhancement Frame Creator
-- ============================================================

-- Strip "Enchant" prefix from names
-- "Enchant Gloves: Crusher" → "Gloves: Crusher"
-- "Enchant - Powerful Stats" → "Powerful Stats"
local function StripEnchantPrefix(name)
    if not name then return nil end
    -- First try: "Enchant Gloves: Crusher" → "Gloves: Crusher"
    local stripped = name:gsub("^Enchant ", "")
    -- Second try: "Enchant - Something" → "Something"
    stripped = stripped:gsub("^%- ", "")
    return stripped
end

-- Get enchant name from a single enhancement entry
local function GetEnchantNameFromEntry(enhancement)
    if not enhancement then return nil end
    
    if enhancement.type == "spell" and enhancement.id then
        local name = GetSpellInfo(enhancement.id)
        return StripEnchantPrefix(name)
    elseif enhancement.type == "item" and enhancement.id then
        local name, _, _, _, _, class = GetItemInfo(enhancement.id)
        -- Check if it's a gem (exclude from enchant display)
        local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"
        if class == ITEM_CLASS_GEM then
            return nil -- It's a gem, not an enchant
        end
        return StripEnchantPrefix(name)
    end
    
    return nil
end

-- Get enchant info (name, icon, id, type) from slot.enhs
local function GetSlotEnchantInfo(slot)
    if not slot or not slot.enhs then return nil, nil, nil, nil end
    
    for _, enh in ipairs(slot.enhs) do
        if enh and enh.type == "spell" and enh.id then
            local name, _, icon = GetSpellInfo(enh.id)
            if name then
                return StripEnchantPrefix(name), icon, enh.id, "spell"
            end
        elseif enh and enh.type == "item" and enh.id then
            local name, _, _, _, _, class, _, _, _, texture = GetItemInfo(enh.id)
            local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"
            if name and class ~= ITEM_CLASS_GEM then
                return StripEnchantPrefix(name), texture, enh.id, "item"
            end
        end
    end
    
    return nil, nil, nil, nil
end

-- Collect gem IDs from slot.enhs
local function CollectGemIdsFromSlot(slot)
    local out = {}
    if not slot or not slot.enhs then return out end
    
    local ITEM_CLASS_GEM = _G.ITEM_CLASS_GEM or "Gem"
    
    for _, e in ipairs(slot.enhs) do
        if e and e.type == "item" and e.id and e.id > 0 then
            local name, _, _, _, _, class = GetItemInfo(e.id)
            if not name then
                -- Item not cached, queue for preload and add anyway
                QueuePreload(e.id)
                table.insert(out, e.id)
            elseif class == ITEM_CLASS_GEM then
                table.insert(out, e.id)
            end
        end
    end
    
    return out
end

-- Create single enchant icon for normal mode (separate column)
local function CreateEnchantIcon(slot)
    local group = NewSimpleGroup()
    group:SetLayout("Flow")
    group:SetAutoAdjustHeight(false)
    group:SetWidth(22)
    group:SetHeight(44)
    
    if not slot or not slot.enhs then return group end
    
    local iconSize = 20
    
    -- Get enchant info from raw data
    local enchName, enchIcon, enchId, enchType = GetSlotEnchantInfo(slot)
    
    -- Enchant icon only
    if enchIcon then
        local enchIconWidget = AceGUI:Create("Icon")
        enchIconWidget:SetImageSize(iconSize, iconSize)
        enchIconWidget:SetWidth(iconSize + 2)
        enchIconWidget:SetHeight(iconSize + 2)
        enchIconWidget:SetImage(enchIcon)
        -- 125% zoom to eliminate Blizzard borders
        if enchIconWidget.image then
            enchIconWidget.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
        
        -- Tooltip - show proper enchant tooltip
        enchIconWidget:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            if enchType == "item" and enchId then
                -- Enchant scroll item
                Utils.TooltipSetItemByID(GameTooltip, enchId)
            elseif enchType == "spell" and enchId then
                -- Spell enchant - try enchant hyperlink first (3.3.5a compatible)
                local success = pcall(function()
                    GameTooltip:SetHyperlink("enchant:" .. enchId)
                end)
                if not success then
                    -- Fallback: show as spell
                    pcall(function()
                        GameTooltip:SetHyperlink("spell:" .. enchId)
                    end)
                end
                -- Add enchant name for clarity
                if enchName then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cff00ff00" .. enchName .. "|r", 1, 1, 1)
                end
            end
            GameTooltip:Show()
        end)
        enchIconWidget:SetCallback("OnLeave", function() GameTooltip:Hide() end)

        -- Shift+Click to link enchant to chat
        local capturedEnchId = enchId
        local capturedEnchType = enchType
        MakeIconClickable(enchIconWidget, function(self, button)
            if button == "LeftButton" and capturedEnchId then
                local link = nil
                if capturedEnchType == "item" then
                    -- Fetch fresh link at click time
                    link = select(2, GetItemInfo(capturedEnchId))
                elseif capturedEnchType == "spell" then
                    -- Fetch fresh spell name at click time
                    local spellName = GetSpellInfo(capturedEnchId)
                    if spellName then
                        link = "|cffffd000|Henchant:" .. capturedEnchId .. "|h[" .. spellName .. "]|h|r"
                    end
                end
                if link then
                    ChatEdit_InsertLink(link)
                end
            end
        end)

        group:AddChild(enchIconWidget)
    end

    return group
end

-- Helper: Get gem stat string from GemData
local function GetGemStatString(gemName)
    if not gemName or not Bistooltip_gem_stats then return nil end
    local lowerName = string.lower(gemName)
    return Bistooltip_gem_stats[lowerName]
end

-- Create gem icons for normal mode (separate column)
local function CreateGemIcons(slot)
    local showDetailed = BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.gem_detailed

    local group = NewSimpleGroup()
    group:SetLayout("Flow")
    group:SetAutoAdjustHeight(false)
    -- Wider if showing detailed stats
    group:SetWidth(showDetailed and 100 or 72)
    group:SetHeight(showDetailed and 52 or 44)

    if not slot or not slot.enhs then return group end

    local iconSize = 16

    -- Gem icons
    local gemIds = CollectGemIdsFromSlot(slot)
    if gemIds and #gemIds > 0 then
        for i, gemId in ipairs(gemIds) do
            local name, itemLink, _, _, _, _, _, _, _, texture = GetItemInfo(gemId)

            if showDetailed then
                -- Detailed mode: gem icon with stat text below
                local gemContainer = NewSimpleGroup()
                gemContainer:SetLayout("List")
                gemContainer:SetWidth(32)
                gemContainer:SetHeight(40)

                local gemIcon = AceGUI:Create("Icon")
                gemIcon:SetImageSize(iconSize, iconSize)
                gemIcon:SetWidth(iconSize + 2)
                gemIcon:SetHeight(iconSize + 2)

                if texture then
                    gemIcon:SetImage(texture)
                    if gemIcon.image then
                        gemIcon.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    end
                else
                    gemIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
                    QueuePreload(gemId)
                end

                local capturedGemId = gemId
                gemIcon:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
                    if itemLink then
                        GameTooltip:SetHyperlink(itemLink)
                    else
                        Utils.TooltipSetItemByID(GameTooltip, capturedGemId)
                    end
                    GameTooltip:Show()
                end)
                gemIcon:SetCallback("OnLeave", function() GameTooltip:Hide() end)

                -- Shift+Click to link gem to chat
                MakeIconClickable(gemIcon, function(self, button)
                    if button == "LeftButton" then
                        -- Fetch fresh link at click time
                        local _, freshLink = GetItemInfo(capturedGemId)
                        if freshLink then
                            ChatEdit_InsertLink(freshLink)
                        end
                    end
                end)

                gemContainer:AddChild(gemIcon)

                -- Stat text below gem
                local statStr = GetGemStatString(name)
                if statStr then
                    local statLabel = AceGUI:Create("Label")
                    statLabel:SetText("|cff88ff88" .. statStr .. "|r")
                    statLabel:SetFont(Constants.FONTS.DEFAULT, 8, "")
                    statLabel:SetWidth(32)
                    gemContainer:AddChild(statLabel)
                end

                group:AddChild(gemContainer)
            else
                -- Simple mode: just icon
                local gemIcon = AceGUI:Create("Icon")
                gemIcon:SetImageSize(iconSize, iconSize)
                gemIcon:SetWidth(iconSize + 2)
                gemIcon:SetHeight(iconSize + 2)

                if texture then
                    gemIcon:SetImage(texture)
                    if gemIcon.image then
                        gemIcon.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    end
                else
                    gemIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
                    QueuePreload(gemId)
                end

                local capturedGemId = gemId
                gemIcon:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
                    if itemLink then
                        GameTooltip:SetHyperlink(itemLink)
                    else
                        Utils.TooltipSetItemByID(GameTooltip, capturedGemId)
                    end
                    GameTooltip:Show()
                end)
                gemIcon:SetCallback("OnLeave", function() GameTooltip:Hide() end)

                -- Shift+Click to link gem to chat
                MakeIconClickable(gemIcon, function(self, button)
                    if button == "LeftButton" then
                        -- Fetch fresh link at click time
                        local _, freshLink = GetItemInfo(capturedGemId)
                        if freshLink then
                            ChatEdit_InsertLink(freshLink)
                        end
                    end
                end)

                group:AddChild(gemIcon)
            end
        end
    end

    return group
end

-- Legacy combined function (for BIS checklist mode compatibility)
local function CreateEnhancementsFrame(slot)
    local group = NewSimpleGroup()
    group:SetLayout("Flow")
    group:SetAutoAdjustHeight(false)
    group:SetWidth(Constants.UI.ENH_LABEL_WIDTH or 55)
    group:SetHeight(40)
    
    if not slot or not slot.enhs then return group end
    
    local iconSize = 18
    
    -- Get enchant info from raw data
    local enchName, enchIcon, enchId, enchType = GetSlotEnchantInfo(slot)
    
    -- Enchant icon only
    if enchIcon then
        local enchIconWidget = AceGUI:Create("Icon")
        enchIconWidget:SetImageSize(iconSize, iconSize)
        enchIconWidget:SetWidth(iconSize + 2)
        enchIconWidget:SetHeight(iconSize + 2)
        enchIconWidget:SetImage(enchIcon)
        if enchIconWidget.image then
            enchIconWidget.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
        
        enchIconWidget:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            if enchType == "item" and enchId then
                Utils.TooltipSetItemByID(GameTooltip, enchId)
            elseif enchType == "spell" and enchId then
                GameTooltip:SetSpellByID(enchId)
            end
            GameTooltip:Show()
        end)
        enchIconWidget:SetCallback("OnLeave", function() GameTooltip:Hide() end)

        -- Shift+Click to link enchant to chat
        local capturedEnchId = enchId
        local capturedEnchType = enchType
        MakeIconClickable(enchIconWidget, function(self, button)
            if button == "LeftButton" and capturedEnchId then
                local link = nil
                if capturedEnchType == "item" then
                    -- Fetch fresh link at click time
                    link = select(2, GetItemInfo(capturedEnchId))
                elseif capturedEnchType == "spell" then
                    -- Fetch fresh spell name at click time
                    local spellName = GetSpellInfo(capturedEnchId)
                    if spellName then
                        link = "|cffffd000|Henchant:" .. capturedEnchId .. "|h[" .. spellName .. "]|h|r"
                    end
                end
                if link then
                    ChatEdit_InsertLink(link)
                end
            end
        end)

        group:AddChild(enchIconWidget)
    end

    -- Gem icons
    local gemIds = CollectGemIdsFromSlot(slot)
    if gemIds and #gemIds > 0 then
        for i, gemId in ipairs(gemIds) do
            local name, itemLink, _, _, _, _, _, _, _, texture = GetItemInfo(gemId)
            
            local gemIcon = AceGUI:Create("Icon")
            gemIcon:SetImageSize(iconSize, iconSize)
            gemIcon:SetWidth(iconSize + 2)
            gemIcon:SetHeight(iconSize + 2)
            
            if texture then
                gemIcon:SetImage(texture)
                if gemIcon.image then
                    gemIcon.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                end
            else
                gemIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
                QueuePreload(gemId)
            end
            
            local capturedGemId = gemId
            gemIcon:SetCallback("OnEnter", function(widget)
                GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
                if itemLink then
                    GameTooltip:SetHyperlink(itemLink)
                else
                    Utils.TooltipSetItemByID(GameTooltip, capturedGemId)
                end
                GameTooltip:Show()
            end)
            gemIcon:SetCallback("OnLeave", function() GameTooltip:Hide() end)

            -- Shift+Click to link gem to chat
            MakeIconClickable(gemIcon, function(self, button)
                if button == "LeftButton" then
                    -- Fetch fresh link at click time
                    local _, freshLink = GetItemInfo(capturedGemId)
                    if freshLink then
                        ChatEdit_InsertLink(freshLink)
                    end
                end
            end)

            group:AddChild(gemIcon)
        end
    end

    return group
end

-- ============================================================
-- Boss/Item Info Frame (for checklist mode)
-- ============================================================

local function CreateBossItemInfoFrame(slot)
    local group = NewSimpleGroup()
    group:SetLayout("List")
    group:SetAutoAdjustHeight(false)
    group:SetHeight(44)
    
    local firstItemId = Data.GetDisplayItemID(slot[1], State.Get("isHorde"))
    if not firstItemId or firstItemId <= 0 then return group end
    
    local sources = Data.GetAllItemSources(firstItemId)
    local itemName = GetItemInfo(firstItemId) or ""
    
    -- Get boss info from sources
    local bossName, zoneName, difficulty, emblemInfo
    for _, src in ipairs(sources) do
        if src.type == "raid" then
            bossName = src.boss
            zoneName = src.zone
            difficulty = src.difficulty
        elseif src.type == "emblem" then
            emblemInfo = src
        end
    end
    
    -- Boss line
    local bossLbl = AceGUI:Create("Label")
    bossLbl:SetFullWidth(true)
    bossLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "OUTLINE")
    bossLbl:SetJustifyH("LEFT")
    
    local bossText
    if bossName then
        bossText = "|cffc41f3b" .. Utils.TruncateText(bossName, 18) .. "|r"
        if difficulty then
            bossText = bossText .. " |cffaaaaaa(" .. difficulty .. ")|r"
        end
    elseif emblemInfo then
        local color = Constants.COLORS.ASCENSION or "00ffcc"
        bossText = "|cff" .. color .. (emblemInfo.currency or "Emblem") .. " x" .. (emblemInfo.cost or "?") .. "|r"
    else
        bossText = "|cff666666Unknown Source|r"
    end
    bossLbl:SetText(bossText)
    group:AddChild(bossLbl)
    
    -- Item name line
    local itemLbl = AceGUI:Create("Label")
    itemLbl:SetFullWidth(true)
    itemLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "OUTLINE")
    itemLbl:SetJustifyH("LEFT")
    itemLbl:SetText(itemName ~= "" and ("|cffff8040" .. itemName .. "|r") or " ")
    group:AddChild(itemLbl)
    
    -- Enchant line with icon (process raw enhs data)
    local enchName, enchIcon, enchId, enchType = GetSlotEnchantInfo(slot)
    if enchName then
        local enchGroup = NewSimpleGroup()
        enchGroup:SetFullWidth(true)
        enchGroup:SetLayout("Flow")
        enchGroup:SetAutoAdjustHeight(false)
        enchGroup:SetHeight(20)
        
        -- Enchant icon
        if enchIcon then
            local enchIconWidget = AceGUI:Create("Icon")
            enchIconWidget:SetImageSize(14, 14)
            enchIconWidget:SetWidth(16)
            enchIconWidget:SetHeight(16)
            enchIconWidget:SetImage(enchIcon)
            SetIconTexCoord(enchIconWidget)
            
            -- Tooltip
            if enchType == "spell" and enchId then
                enchIconWidget:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
                    GameTooltip:SetSpellByID(enchId)
                    GameTooltip:Show()
                end)
            elseif enchType == "item" and enchId then
                enchIconWidget:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
                    Utils.TooltipSetItemByID(GameTooltip, enchId)
                    GameTooltip:Show()
                end)
            end
            enchIconWidget:SetCallback("OnLeave", function() GameTooltip:Hide() end)

            -- Shift+Click to link enchant to chat
            local capturedEnchId = enchId
            local capturedEnchType = enchType
            MakeIconClickable(enchIconWidget, function(self, button)
                if button == "LeftButton" and capturedEnchId then
                    local link = nil
                    if capturedEnchType == "item" then
                        -- Fetch fresh link at click time
                        link = select(2, GetItemInfo(capturedEnchId))
                    elseif capturedEnchType == "spell" then
                        -- Fetch fresh spell name at click time
                        local spellName = GetSpellInfo(capturedEnchId)
                        if spellName then
                            link = "|cffffd000|Henchant:" .. capturedEnchId .. "|h[" .. spellName .. "]|h|r"
                        end
                    end
                    if link then
                        ChatEdit_InsertLink(link)
                    end
                end
            end)

            enchGroup:AddChild(enchIconWidget)
        end

        local enchLbl = AceGUI:Create("Label")
        enchLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_SMALL, "")
        enchLbl:SetText("|cff00ff00" .. enchName .. "|r")
        enchLbl:SetWidth(120)
        enchGroup:AddChild(enchLbl)
        
        group:AddChild(enchGroup)
    end
    
    return group
end

-- ============================================================
-- Gem Row Creator
-- ============================================================

local function DrawGemPlanRow(gemIds, parent)
    if not gemIds or #gemIds == 0 or not parent then return end
    
    -- Empty cells for alignment
    local e1 = AceGUI:Create("Label")
    e1:SetText(" ")
    local e2 = AceGUI:Create("Label")
    e2:SetText(" ")
    parent:AddChild(e1)
    parent:AddChild(e2)
    
    -- Gem container
    local box = NewSimpleGroup()
    box:SetLayout("Flow")
    box:SetAutoAdjustHeight(false)
    box:SetHeight(26)
    box:SetUserData("cell", { colspan = 6 })
    
    -- Remove backdrop
    if box.frame.SetBackdrop then
        box.frame:SetBackdrop(nil)
    end
    
    local iconSize = 16
    
    for i, id in ipairs(gemIds) do
        -- Spacer between gems
        if i > 1 then
            local spacer = AceGUI:Create("Label")
            spacer:SetWidth(6)
            spacer:SetText("")
            box:AddChild(spacer)
        end
        
        -- Gem icon
        local gemIcon = AceGUI:Create("Icon")
        gemIcon:SetImageSize(iconSize, iconSize)
        gemIcon:SetWidth(iconSize + 2)
        gemIcon:SetHeight(iconSize + 2)
        
        local name, itemLink, _, _, _, _, _, _, _, texture = GetItemInfo(id)
        if texture then
            gemIcon:SetImage(texture)
            SetIconTexCoord(gemIcon)
        else
            gemIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
            QueuePreload(id)
        end
        
        -- Gem tooltip
        local capturedGemId = id
        gemIcon:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            if itemLink then
                GameTooltip:SetHyperlink(itemLink)
            else
                Utils.TooltipSetItemByID(GameTooltip, capturedGemId)
            end
            GameTooltip:Show()
        end)
        gemIcon:SetCallback("OnLeave", function() GameTooltip:Hide() end)

        -- Shift+Click to link gem to chat
        MakeIconClickable(gemIcon, function(self, button)
            if button == "LeftButton" then
                -- Fetch fresh link at click time
                local _, freshLink = GetItemInfo(capturedGemId)
                if freshLink then
                    ChatEdit_InsertLink(freshLink)
                end
            end
        end)

        box:AddChild(gemIcon)
        
        -- Gem stat text (from GemData)
        local statToken = nil
        if _G.Bistooltip_GetGemStats and name then
            statToken = _G.Bistooltip_GetGemStats(name)
        end
        
        if statToken and statToken ~= "" then
            local statLbl = AceGUI:Create("Label")
            statLbl:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_SMALL, "OUTLINE")
            statLbl:SetText("|cff55aaff" .. statToken .. "|r")
            -- Wider for meta gems (contain "/" in stats)
            local labelWidth = string.find(statToken, "/") and 85 or 52
            statLbl:SetWidth(labelWidth)
            box:AddChild(statLbl)
        end
    end
    
    parent:AddChild(box)
end

-- ============================================================
-- Draw Item Slot
-- ============================================================

local function drawItemSlot(slot, parent)
    if not slot or not parent then return end
    
    local slotName = slot.slot_name
    local isHorde = State.Get("isHorde")
    local bisChecklistMode = State.Get("bisChecklistMode")
    local showOnlyMissing = State.Get("showOnlyMissing")
    local customizeMode = State.Get("customizeMode")
    local isUnlocked = State.IsSlotUnlocked(slotName)
    local selectedSwapItem = State.GetSelectedSwapItem()
    
    -- Slot name label
    local slotLabel = AceGUI:Create("Label")
    slotLabel:SetText("|cffffd700" .. slotName .. "|r")
    slotLabel:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_LARGE, "OUTLINE")
    parent:AddChild(slotLabel)
    
    -- Enhancements or Boss/Item info
    local gemIds = nil
    if bisChecklistMode then
        parent:AddChild(CreateBossItemInfoFrame(slot))
        gemIds = CollectGemIdsFromSlot(slot)
    else
        -- Normal mode: separate columns for enchant and gems
        parent:AddChild(CreateEnchantIcon(slot))
        parent:AddChild(CreateGemIcons(slot))
    end
    
    -- Item icons
    for i, originalItemId in ipairs(slot) do
        if type(originalItemId) == "number" and originalItemId > 0 then
            local itemId = Data.GetDisplayItemID(originalItemId, isHorde)
            local ownedState, ownedCount = Data.GetOwnedState(itemId)
            
            -- Skip owned items if "Only missing" is checked
            if showOnlyMissing and ownedState then
                local emptyLabel = AceGUI:Create("Label")
                emptyLabel:SetText("")
                parent:AddChild(emptyLabel)
            else
                -- Create icon using pool
                local callbacks = {
                    onLeftClick = function(self, displayId, origId)
                        if customizeMode and isUnlocked then
                            -- Swap logic
                            if selectedSwapItem and selectedSwapItem.slotName == slotName then
                                -- Swap items
                                local fromIndex = selectedSwapItem.index
                                local toIndex = i
                                if fromIndex ~= toIndex then
                                    -- Perform swap in slot data
                                    slot[fromIndex], slot[toIndex] = slot[toIndex], slot[fromIndex]
                                    Data.SaveCustomPriority(slot, State.Get("class"), State.Get("spec"), State.Get("phase"))
                                end
                                State.ClearSelectedSwapItem()
                                drawSpecData()
                            else
                                -- Select this item for swap
                                State.SetSelectedSwapItem(slotName, i)
                                drawSpecData()
                            end
                        else
                            -- Normal click - link to chat
                            local link = select(2, GetItemInfo(displayId))
                            if link then ChatEdit_InsertLink(link) end
                        end
                    end,
                }
                
                local icon = CreatePooledItemIcon(originalItemId, Constants.UI.ICON_SIZE_ITEM, parent.frame, callbacks)
                
                if icon then
                    -- Show selection border if this item is selected for swap
                    if customizeMode and selectedSwapItem and 
                       selectedSwapItem.slotName == slotName and selectedSwapItem.index == i then
                        UI.SetSelectionBorder(icon, true)
                    end
                    
                    -- Create wrapper with immediate parenting (no async OnShow)
                    local iconWrapper = AceGUI:Create("Label")
                    iconWrapper:SetWidth(Constants.UI.ICON_SIZE_ITEM + 4)
                    
                    -- Parent immediately and unconditionally
                    icon:SetParent(iconWrapper.frame)
                    icon:ClearAllPoints()
                    icon:SetPoint("CENTER")
                    icon:Show()
                    
                    -- Store reference for proper cleanup
                    iconWrapper._pooledIcon = icon
                    
                    parent:AddChild(iconWrapper)
                else
                    local emptyLabel = AceGUI:Create("Label")
                    emptyLabel:SetText("")
                    parent:AddChild(emptyLabel)
                end
            end
        end
    end
    
    -- Customize mode: Lock icon
    if customizeMode then
        local lockIcon = AceGUI:Create("Icon")
        lockIcon:SetImageSize(20, 20)
        lockIcon:SetWidth(24)
        lockIcon:SetImage(isUnlocked and "Interface\\Icons\\INV_Misc_Key_03" or "Interface\\Icons\\INV_Misc_Key_04")
        
        lockIcon:SetCallback("OnClick", function()
            State.ToggleSlotUnlock(slotName)
            if not State.IsSlotUnlocked(slotName) then
                -- Clear selection if locking
                local sel = State.GetSelectedSwapItem()
                if sel and sel.slotName == slotName then
                    State.ClearSelectedSwapItem()
                end
            end
            drawSpecData()
        end)
        
        lockIcon:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText(isUnlocked and "Click to lock (prevent reordering)" or "Click to unlock (allow reordering)")
            GameTooltip:Show()
        end)
        lockIcon:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        
        parent:AddChild(lockIcon)
    end
    
    -- Gem plan row (in checklist mode)
    if gemIds then
        DrawGemPlanRow(gemIds, parent)
    end

    -- Enchant detailed row (shows enchant name below slot row)
    local showEnchantDetailed = BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.enchant_detailed
    if showEnchantDetailed and not bisChecklistMode then
        local enchName, _, _, _ = GetSlotEnchantInfo(slot)
        if enchName then
            -- Create a label showing "SlotName: EnchantName"
            local enchLabel = AceGUI:Create("Label")
            enchLabel:SetText("|cff00ff00" .. slotName .. ": " .. enchName .. "|r")
            enchLabel:SetFont(Constants.FONTS.DEFAULT, 9, "")
            enchLabel:SetFullWidth(true)
            parent:AddChild(enchLabel)
        end
    end
end

-- ============================================================
-- Table Header
-- ============================================================

local function drawTableHeader(parent)
    local bisChecklistMode = State.Get("bisChecklistMode")
    local customizeMode = State.Get("customizeMode")
    
    local headers
    if bisChecklistMode then
        headers = {
            { text = "Slot" },
            { text = "Plan" },
            { text = "BIS" },
            { text = "BIS2" },
            { text = "Alt 3" },
            { text = "Alt 4" },
            { text = "Alt 5" },
            { text = "Alt 6" },
        }
    else
        -- Normal mode: separate Enc and Gems columns
        headers = {
            { text = "Slot" },
            { text = "Enc" },
            { text = "Gems" },
            { text = "BIS" },
            { text = "BIS2" },
            { text = "Alt 3" },
            { text = "Alt 4" },
            { text = "Alt 5" },
            { text = "Alt 6" },
        }
    end
    
    if customizeMode and not bisChecklistMode then
        table.insert(headers, { text = "Lock" })
    end
    
    for _, h in ipairs(headers) do
        local label = AceGUI:Create("Label")
        label:SetText("|cffaaaaaa" .. h.text .. "|r")
        label:SetFont(Constants.FONTS.DEFAULT, Constants.FONTS.SIZE_MEDIUM, "OUTLINE")
        label:SetJustifyH("CENTER")
        parent:AddChild(label)
    end
end

-- ============================================================
-- Apply Spec Table Layout
-- ============================================================

local function ApplySpecTable()
    if not specFrame then return end
    
    local bisChecklistMode = State.Get("bisChecklistMode")
    local customizeMode = State.Get("customizeMode")
    
    local tableLayout
    if bisChecklistMode then
        tableLayout = Constants.SPEC_TABLE_CHECKLIST
    elseif customizeMode then
        tableLayout = Constants.SPEC_TABLE_CUSTOMIZE
    else
        tableLayout = Constants.SPEC_TABLE_DEFAULT
    end
    
    specFrame:SetUserData("table", tableLayout)
end

-- ============================================================
-- Create Spec Frame - CUSTOM FRAMES (No AceGUI Table!)
-- ============================================================

-- Custom scroll frame references
local customScrollFrame = nil
local customContentFrame = nil
local customHeaderFrame = nil
local activeCustomRows = {}

local function DestroyCustomSpecFrame()
    -- Clear active rows
    for _, row in ipairs(activeCustomRows) do
        if row then
            row:Hide()
            row:SetParent(nil)
        end
    end
    wipe(activeCustomRows)

    -- Destroy header frame
    if customHeaderFrame then
        customHeaderFrame:Hide()
        customHeaderFrame:SetParent(nil)
        customHeaderFrame = nil
    end

    -- Destroy content frame
    if customContentFrame then
        customContentFrame:Hide()
        customContentFrame:SetParent(nil)
        customContentFrame = nil
    end

    -- Destroy scroll frame
    if customScrollFrame then
        customScrollFrame:Hide()
        customScrollFrame:SetParent(nil)
        customScrollFrame = nil
    end

    -- Destroy container frame
    if specContainerFrame then
        specContainerFrame:Hide()
        specContainerFrame:ClearAllPoints()
        specContainerFrame:SetParent(nil)
        specContainerFrame = nil
    end

    -- Release AceGUI container if present (legacy)
    if specFrame and specFrame.aceContainer then
        AceGUI:Release(specFrame.aceContainer)
    end

    -- Clear reference
    specFrame = nil
    State.SetSpecFrame(nil)
end

-- Helper to destroy progress bar (called separately as it's module-level)
local function DestroyProgressBar()
    if progressBarFrame then
        progressBarFrame:Hide()
        progressBarFrame:SetParent(nil)
        progressBarFrame = nil
    end
end

-- Counter for unique frame names
local specFrameCounter = 0

-- Store reference to the container frame for cleanup
local specContainerFrame = nil

local function CreateCustomSpecFrame()
    if customScrollFrame then return end

    -- CRITICAL: Verify mainFrame exists
    if not mainFrame or not mainFrame.frame then
        return
    end

    specFrameCounter = specFrameCounter + 1

    -- Create direct container frame (bypassing AceGUI layout issues)
    local containerName = "BistooltipSpecContainer" .. specFrameCounter
    local scrollName = "BistooltipSpecScroll" .. specFrameCounter
    local contentName = "BistooltipSpecContent" .. specFrameCounter

    -- Calculate offsets for new layout:
    -- From top: Tab spacer (28) + Dropdowns area (~70) = ~98px
    -- This positions content below the filter bar area
    local topOffset = -100
    -- From bottom: Bottom bar (40) + Status bar area (20) + padding = ~68px
    local bottomOffset = 68

    -- Create container with EXPLICIT SIZE - NEVER rely on parent width
    local containerWidth = Constants.UI.MAIN_FRAME_WIDTH or 600
    -- FIX: Use math.abs(topOffset) because topOffset is negative
    local containerHeight = (Constants.UI.MAIN_FRAME_HEIGHT or 700) - math.abs(topOffset) - bottomOffset

    -- ============================================================
    -- NATIVE MAIN FRAME SOLUTION:
    -- mainFrame is now our own CreateFrame (not AceGUI), so we can safely
    -- parent specContainerFrame directly to it without ElvUI interference
    -- ============================================================

    -- Verify mainFrame exists and is valid
    if not mainFrame or not mainFrame.frame then
        return
    end

    local parentFrame = mainFrame.frame

    specContainerFrame = CreateFrame("Frame", containerName, parentFrame)
    specContainerFrame:SetSize(containerWidth, containerHeight)
    specContainerFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, topOffset)

    -- Inherit strata from parent, set level slightly higher
    specContainerFrame:SetFrameStrata(parentFrame:GetFrameStrata())
    specContainerFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 1)

    -- Create scroll frame inside container, positioned BELOW progress bar AND sticky header
    -- Progress bar height (20) + spacing (4) + Header height (24) + spacing (2) = 50px from top
    local headerHeight = 24
    local scrollTopOffset = -((LAYOUT.PROGRESS_BAR_HEIGHT or 20) + 4 + headerHeight + 2)
    local scrollWidth = containerWidth - 24 - 8  -- Subtract scrollbar (16) and padding (8)
    local scrollHeight = containerHeight - math.abs(scrollTopOffset) - 4

    customScrollFrame = CreateFrame("ScrollFrame", scrollName, specContainerFrame, "UIPanelScrollFrameTemplate")
    customScrollFrame:SetPoint("TOPLEFT", 8, scrollTopOffset)  -- Match LAYOUT.PADDING
    customScrollFrame:SetSize(scrollWidth, scrollHeight)

    -- Position scrollbar with slight offset from right edge
    local scrollBar = _G[scrollName .. "ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", customScrollFrame, "TOPRIGHT", 2, -16)
        scrollBar:SetPoint("BOTTOMLEFT", customScrollFrame, "BOTTOMRIGHT", 2, 16)
    end

    -- Store reference to specContainerFrame for sticky header positioning
    customScrollFrame._containerFrame = specContainerFrame
    customScrollFrame._headerYOffset = -((LAYOUT.PROGRESS_BAR_HEIGHT or 20) + 4)  -- Below progress bar

    -- Calculate expected content width
    local expectedWidth = (Constants.UI.MAIN_FRAME_WIDTH or 720) - 4 - 24

    -- Create content frame
    customContentFrame = CreateFrame("Frame", contentName, customScrollFrame)
    customContentFrame:SetWidth(expectedWidth)
    customContentFrame:SetHeight(1)
    customScrollFrame:SetScrollChild(customContentFrame)

    -- NOTE: We use fixed width now, so OnSizeChanged is not needed
    -- This prevents ElvUI from affecting our content width
    -- customScrollFrame:SetScript("OnSizeChanged", nil)

    -- Store reference (for compatibility with existing code)
    specFrame = {
        frame = specContainerFrame,
        aceContainer = nil,  -- No AceGUI container
        customScrollFrame = customScrollFrame,
        customContentFrame = customContentFrame
    }
    State.SetSpecFrame(specFrame)
end

-- ============================================================
-- Custom Row Rendering
-- ============================================================

local CUSTOM_ROW_HEIGHT = 48
local CUSTOM_ROW_HEIGHT_BIS = 48  -- Same height for BIS mode (new simpler layout)
local CUSTOM_ROW_SPACING = 2
local CUSTOM_ICON_SIZE = 40
local CUSTOM_ICON_SPACING = 4

-- Column positions for different modes
-- STRUCTURE:
-- MAIN mode: Col1: SLOT | Col2: ENCHANT | Col3-5: GEMS | Col6-11: BIS + TOP1-TOP5
-- BIS mode:  Col1: SLOT | Col2: BIS | Col3: SOURCE | Col4: COST | Col5: ILVL | Col6: DROP%
-- (No gems in BIS mode as per user request)
local function GetColumnPositions()
    local bisChecklistMode = State.Get("bisChecklistMode")
    local customizeMode = State.Get("customizeMode")

    if bisChecklistMode then
        -- BIS mode: SLOT | ENCHANT | GEMS | BIS | SOURCE | MODE | COST | ILVL
        -- Same enchant/gems columns as MAIN mode
        return {
            { x = 4,   width = 70,  type = "label" },      -- Col1: SLOT name
            { x = 76,  width = 24,  type = "enchant" },    -- Col2: ENCHANT
            { x = 102, width = 70,  type = "gems" },       -- Col3: GEMS
            { x = 176, width = 38,  type = "item" },       -- Col4: BIS icon (only 1)
            { x = 218, width = 100, type = "source" },     -- Col5: SOURCE (Boss/Vendor)
            { x = 322, width = 40,  type = "mode" },       -- Col6: MODE (N/HM/HC)
            { x = 366, width = 55,  type = "cost" },       -- Col7: COST (emblem cost)
            { x = 425, width = 35,  type = "ilvl" },       -- Col8: ILVL
        }
    elseif customizeMode then
        -- Custom mode: no lock icon/status - just show items for swapping
        return {
            { x = 4,   width = 70,  type = "label" },      -- SLOT
            { x = 76,  width = 24,  type = "enchant" },
            { x = 102, width = 80,  type = "gems" },
            { x = 186, width = 44,  type = "item" },
            { x = 234, width = 44,  type = "item" },
            { x = 282, width = 40,  type = "item" },
            { x = 326, width = 40,  type = "item" },
            { x = 370, width = 40,  type = "item" },
            { x = 414, width = 40,  type = "item" },
        }
    else
        -- MAIN mode: SLOT | ENCHANT | GEMS | BIS | TOP1-TOP5
        return {
            { x = 4,   width = 70,  type = "label" },      -- Col1: SLOT
            { x = 76,  width = 24,  type = "enchant" },    -- Col2: ENCHANT
            { x = 102, width = 80,  type = "gems" },       -- Col3-5: GEMS
            { x = 186, width = 44,  type = "item" },       -- Col6: BIS
            { x = 234, width = 44,  type = "item" },       -- Col7: TOP1
            { x = 282, width = 40,  type = "item" },       -- Col8: TOP2
            { x = 326, width = 40,  type = "item" },       -- Col9: TOP3
            { x = 370, width = 40,  type = "item" },       -- Col10: TOP4
            { x = 414, width = 40,  type = "item" },       -- Col11: TOP5
        }
    end
end

-- Store search editbox reference
local headerSearchBox = nil

-- Progress bar reference (FIXED position, outside scroll)
local progressBarFrame = nil

-- Create progress bar as FIXED element ABOVE the scroll frame
-- Parented to specContainerFrame, not the scroll content
local function CreateProgressBar(containerFrame)
    if not containerFrame then return nil end

    local barHeight = LAYOUT.PROGRESS_BAR_HEIGHT or 20

    -- Check if existing progressBarFrame was orphaned (parent set to nil during cleanup)
    if progressBarFrame and not progressBarFrame:GetParent() then
        progressBarFrame = nil  -- Clear reference so we create a new one
    end

    if not progressBarFrame then
        -- Create frame and textures ONCE
        progressBarFrame = CreateFrame("Frame", "BistooltipProgressBar", containerFrame)

        -- Background with subtle border
        local bg = progressBarFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(bg, STYLE.COLORS.BG_DARK)
        progressBarFrame._bg = bg

        -- Border
        local borderTop = progressBarFrame:CreateTexture(nil, "BORDER")
        borderTop:SetPoint("TOPLEFT", 0, 0)
        borderTop:SetPoint("TOPRIGHT", 0, 0)
        borderTop:SetHeight(1)
        borderTop:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(borderTop, STYLE.COLORS.BORDER_SUBTLE)

        local borderBottom = progressBarFrame:CreateTexture(nil, "BORDER")
        borderBottom:SetPoint("BOTTOMLEFT", 0, 0)
        borderBottom:SetPoint("BOTTOMRIGHT", 0, 0)
        borderBottom:SetHeight(1)
        borderBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(borderBottom, STYLE.COLORS.BORDER_SUBTLE)

        -- Progress fill (create once)
        local fill = progressBarFrame:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMLEFT", 2, 2)
        fill:SetTexture("Interface\\Buttons\\WHITE8x8")
        fill:SetVertexColor(0.25, 0.75, 0.40, 1.0)  -- Slightly brighter green
        progressBarFrame._fill = fill

        -- Text with slight shadow effect
        local text = progressBarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        ApplyTextColor(text, STYLE.COLORS.TEXT_BRIGHT)
        progressBarFrame._text = text
    end

    -- Update parent and position (FIXED at top of container, OUTSIDE scroll)
    -- CRITICAL: Use FIXED width from Constants - NEVER use TOPRIGHT anchor
    -- Width accounts for padding (8px each side) and scrollbar area (20px)
    local fixedBarWidth = (Constants.UI.MAIN_FRAME_WIDTH or 600) - 16 - 20
    progressBarFrame:SetParent(containerFrame)
    progressBarFrame:ClearAllPoints()
    progressBarFrame:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 8, -2)  -- Match LAYOUT.PADDING
    progressBarFrame:SetSize(fixedBarWidth, barHeight)
    progressBarFrame:SetFrameLevel(containerFrame:GetFrameLevel() + 10)  -- High level to stay on top
    progressBarFrame:Show()

    -- Store reference in uiFrames for cleanup
    if uiFrames then
        uiFrames.progressBar = progressBarFrame
    end

    -- Store fixed width for Update calculations
    progressBarFrame._fixedWidth = fixedBarWidth

    return progressBarFrame
end

-- Update progress bar
local function UpdateProgressBar(collected, total)
    if not progressBarFrame then return end

    local pct = total > 0 and (collected / total) or 0
    -- Use stored fixed width, NOT GetWidth() which may be wrong
    local barWidth = (progressBarFrame._fixedWidth or ((Constants.UI.MAIN_FRAME_WIDTH or 600) - 8)) - 2
    local width = barWidth * pct
    progressBarFrame._fill:SetWidth(math.max(width, 1))
    progressBarFrame._text:SetText(string.format("Progress: %d/%d (%.0f%%)", collected, total, pct * 100))
end

-- Create custom header row with search in SLOT column
-- STICKY HEADER: Parent is specContainerFrame, not customContentFrame
-- Reuses existing frame and elements to prevent memory leak
local function CreateCustomHeader(yOffset)
    -- yOffset parameter kept for compatibility but ignored for sticky positioning

    -- Get container frame for sticky positioning
    local containerFrame = customScrollFrame and customScrollFrame._containerFrame
    local headerYOffset = customScrollFrame and customScrollFrame._headerYOffset or -24

    -- Check if existing customHeaderFrame was orphaned (parent set to nil during cleanup)
    if customHeaderFrame and not customHeaderFrame:GetParent() then
        customHeaderFrame = nil  -- Clear reference so we create a new one
    end

    -- Reuse existing frame if possible
    if not customHeaderFrame then
        -- Create as child of container (NOT scroll content) for sticky behavior
        local parentForHeader = containerFrame or specContainerFrame or (customContentFrame and customContentFrame:GetParent())
        customHeaderFrame = CreateFrame("Frame", "BistooltipStickyHeader", parentForHeader)

        -- Header background with gradient-like effect
        local headerBg = customHeaderFrame:CreateTexture(nil, "BACKGROUND")
        headerBg:SetPoint("TOPLEFT", 0, 0)
        headerBg:SetPoint("BOTTOMRIGHT", 0, 0)
        headerBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(headerBg, STYLE.COLORS.BG_MEDIUM)
        customHeaderFrame._bg = headerBg

        -- Top border accent
        local topBorder = customHeaderFrame:CreateTexture(nil, "ARTWORK")
        topBorder:SetPoint("TOPLEFT", 0, 0)
        topBorder:SetPoint("TOPRIGHT", 0, 0)
        topBorder:SetHeight(1)
        topBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(topBorder, STYLE.COLORS.BORDER_SUBTLE)

        -- Bottom border (separator from content)
        local bottomBorder = customHeaderFrame:CreateTexture(nil, "ARTWORK")
        bottomBorder:SetPoint("BOTTOMLEFT", 0, 0)
        bottomBorder:SetPoint("BOTTOMRIGHT", 0, 0)
        bottomBorder:SetHeight(1)
        bottomBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(bottomBorder, STYLE.COLORS.BORDER_NORMAL)

        -- Pre-create header labels (will be reused)
        customHeaderFrame._labels = {}
        for labelIdx = 1, 12 do
            local label = customHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            customHeaderFrame._labels[labelIdx] = label
        end
    end

    -- Update parent to container frame (sticky - doesn't scroll)
    local parentForHeader = containerFrame or specContainerFrame or (customContentFrame and customContentFrame:GetParent())
    customHeaderFrame:SetParent(parentForHeader)
    customHeaderFrame:ClearAllPoints()
    -- CRITICAL: Use FIXED width from Constants - NEVER use GetWidth()
    -- Width accounts for padding (8px each side) and scrollbar area (20px)
    local fixedHeaderWidth = (Constants.UI.MAIN_FRAME_WIDTH or 600) - 16 - 20
    customHeaderFrame:SetSize(fixedHeaderWidth, 24)
    customHeaderFrame:SetPoint("TOPLEFT", 8, headerYOffset)  -- Match LAYOUT.PADDING
    -- Ensure header is above scroll content
    customHeaderFrame:SetFrameLevel((parentForHeader:GetFrameLevel() or 1) + 5)

    -- Hide all labels first
    for _, label in ipairs(customHeaderFrame._labels) do
        label:Hide()
    end

    -- Hide search box if exists
    if headerSearchBox then
        headerSearchBox:Hide()
    end

    local columns = GetColumnPositions()
    local bisChecklistMode = State.Get("bisChecklistMode")
    local customizeMode = State.Get("customizeMode")

    local headers
    if bisChecklistMode then
        -- BIS mode headers: SLOT | E | GEMS | BIS | SOURCE | MODE | COST | iLvl
        -- Same enchant/gems columns as MAIN mode
        headers = { "SEARCH", "E", "Gems", "BIS", "SOURCE", "MODE", "COST", "iLvl" }
    elseif customizeMode then
        headers = { "SEARCH", "E", "Gems", "BIS", "TOP1", "T2", "T3", "T4", "T5" }
    else
        -- MAIN mode headers: SLOT | E | GEMS | BIS | TOP1-TOP5
        headers = { "SEARCH", "E", "Gems", "BIS", "TOP1", "TOP2", "TOP3", "TOP4", "TOP5" }
    end

    -- Create or reuse search box with consistent styling
    if not customHeaderFrame._searchBox then
        local searchFrame = CreateFrame("EditBox", "BistooltipHeaderSearch", customHeaderFrame, "InputBoxTemplate")
        searchFrame:SetAutoFocus(false)
        searchFrame:SetMaxLetters(20)
        searchFrame:SetTextInsets(6, 6, 0, 0)
        searchFrame:SetFont(Constants.FONTS.DEFAULT, 10, "")
        -- Style the text color
        searchFrame:SetTextColor(STYLE.COLORS.TEXT_NORMAL[1], STYLE.COLORS.TEXT_NORMAL[2], STYLE.COLORS.TEXT_NORMAL[3])

        -- Placeholder text with consistent dim color
        local placeholder = searchFrame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        placeholder:SetPoint("LEFT", 6, 0)
        placeholder:SetText("Search...")
        ApplyTextColor(placeholder, STYLE.COLORS.TEXT_DIM)
        searchFrame._placeholder = placeholder

        -- Event handlers (set once)
        searchFrame:SetScript("OnTextChanged", function(self, userInput)
            local txt = self:GetText() or ""

            -- Always update placeholder visibility immediately
            if txt ~= "" then
                self._placeholder:Hide()
            else
                self._placeholder:Show()
            end

            -- Only process user input (ignore programmatic changes)
            if not userInput then
                return
            end

            -- Use debounced search - 250ms delay for better UX
            -- Empty search executes immediately to clear filter
            BistooltipDebounce.Search(txt, function(searchText)
                -- Update search state
                State.SetSearch(searchText)

                -- Force clear isDrawing to ensure redraw happens
                isDrawing = false

                -- Trigger redraw
                if mainFrame and mainFrame.frame and mainFrame.frame:IsShown() then
                    drawSpecData()
                end
            end, 250)
        end)

        searchFrame:SetScript("OnEscapePressed", function(self)
            -- Cancel any pending debounced search
            BistooltipDebounce.CancelAll()
            -- Clear search state immediately
            State.ClearSearch()
            -- Clear text box
            self:SetText("")
            self:ClearFocus()
            -- Force redraw to show all slots
            isDrawing = false
            if mainFrame and mainFrame.frame and mainFrame.frame:IsShown() then
                drawSpecData()
            end
        end)

        searchFrame:SetScript("OnEnterPressed", function(self)
            -- Cancel pending debounce and execute search immediately
            BistooltipDebounce.CancelAll()
            local txt = self:GetText() or ""
            State.SetSearch(txt)
            self:ClearFocus()
            -- Force redraw
            isDrawing = false
            if mainFrame and mainFrame.frame and mainFrame.frame:IsShown() then
                drawSpecData()
            end
        end)

        customHeaderFrame._searchBox = searchFrame
    end

    -- Position and show labels/search for current columns
    local labelIdx = 1
    for i, col in ipairs(columns) do
        local text = headers[i] or ""

        if i == 1 then
            -- Search box for first column
            local searchFrame = customHeaderFrame._searchBox
            searchFrame:ClearAllPoints()
            searchFrame:SetSize(col.width - 4, 18)
            searchFrame:SetPoint("LEFT", customHeaderFrame, "LEFT", col.x + 2, 0)

            -- Restore previous search text
            -- The OnTextChanged handler checks against State, so setting the same value won't trigger redraw
            local prevSearch = State.Get("searchText") or ""
            if prevSearch ~= "" then
                searchFrame:SetText(prevSearch)
                searchFrame._placeholder:Hide()
            else
                searchFrame:SetText("")
                searchFrame._placeholder:Show()
            end
            searchFrame:Show()
            headerSearchBox = searchFrame
        else
            -- Reuse pre-created label with consistent styling
            local label = customHeaderFrame._labels[labelIdx]
            if label then
                label:ClearAllPoints()
                label:SetPoint("LEFT", customHeaderFrame, "LEFT", col.x, 0)
                label:SetWidth(col.width)
                label:SetJustifyH("CENTER")
                -- Use STYLE colors for consistent look
                label:SetText(text)
                ApplyTextColor(label, STYLE.COLORS.TEXT_DIM)
                label:Show()
                labelIdx = labelIdx + 1
            end
        end
    end

    customHeaderFrame:Show()
    return STYLE.HEADER_HEIGHT or 26
end

-- NOTE: TooltipSetItemByID is defined earlier in file (line ~664)
-- Duplicate definition removed to prevent shadowing

-- Constants for detail row heights
local DETAIL_ROW_HEIGHT = 24  -- Height for enchant/gem detail rows

-- Create a single slot row using custom frames
local function CreateCustomSlotRow(slot, yOffset, rowIndex)
    local bisChecklistMode = State.Get("bisChecklistMode")
    local customizeMode = State.Get("customizeMode")

    -- Check if detail rows are needed (BIS mode only)
    local showEnchantDetail = false
    local showGemDetail = false
    local hasEnchant = false
    local hasGems = false
    local gemIds = {}

    if bisChecklistMode then
        showEnchantDetail = BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.enchant_detailed
        showGemDetail = BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.gem_detailed

        -- Check if slot has enchant
        local enchName, enchIcon = GetSlotEnchantInfo(slot)
        hasEnchant = enchName ~= nil

        -- Check if slot has gems
        gemIds = CollectGemIdsFromSlot(slot)
        hasGems = #gemIds > 0
    end

    -- Calculate total row height
    local baseHeight = bisChecklistMode and CUSTOM_ROW_HEIGHT_BIS or CUSTOM_ROW_HEIGHT
    local rowHeight = baseHeight
    if showEnchantDetail and hasEnchant then
        rowHeight = rowHeight + DETAIL_ROW_HEIGHT
    end
    if showGemDetail and hasGems then
        rowHeight = rowHeight + DETAIL_ROW_HEIGHT
    end

    -- Use pooled row frame (TRUE pooling - reuses frames)
    local row = AcquireCustomRow(customContentFrame)
    -- CRITICAL: Use FIXED width from Constants - NEVER use GetWidth()
    -- Width matches header: MAIN_FRAME_WIDTH - padding (16) - scrollbar (20)
    local fixedRowWidth = (Constants.UI.MAIN_FRAME_WIDTH or 600) - 16 - 20
    row:SetSize(fixedRowWidth, rowHeight)
    row:SetPoint("TOPLEFT", 0, yOffset)  -- No extra offset - scroll frame already has padding
    row:Show()

    -- Reuse or create background texture
    if not row._bg then
        row._bg = row:CreateTexture(nil, "BACKGROUND")
        row._bg:SetAllPoints()
        row._bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    end
    row._bg:Show()
    if customizeMode then
        if rowIndex % 2 == 0 then
            row._bg:SetVertexColor(0.18, 0.10, 0.18, 0.7)
        else
            row._bg:SetVertexColor(0.14, 0.08, 0.14, 0.7)
        end
    else
        if rowIndex % 2 == 0 then
            row._bg:SetVertexColor(0.12, 0.12, 0.12, 0.6)
        else
            row._bg:SetVertexColor(0.08, 0.08, 0.08, 0.6)
        end
    end

    -- Reuse or create border texture (only shown in custom mode)
    if not row._border then
        row._border = row:CreateTexture(nil, "BORDER")
        row._border:SetPoint("TOPLEFT", -1, 1)
        row._border:SetPoint("BOTTOMRIGHT", 1, -1)
        row._border:SetTexture("Interface\\Buttons\\WHITE8x8")
    end
    if customizeMode then
        row._border:SetVertexColor(0.6, 0.2, 0.8, 0.3)
        row._border:Show()
    else
        row._border:Hide()
    end

    -- Reset icon button index for this row (for reuse)
    row._iconBtnIndex = 0

    local columns = GetColumnPositions()
    local slotName = slot.slot_name or ""
    local showOnlyMissing = State.Get("showOnlyMissing")
    local isHorde = State.Get("isHorde")
    local selectedSwapItem = State.GetSelectedSwapItem()
    local isUnlocked = State.IsSlotUnlocked(slotName)
    
    local itemIndex = 1
    
    -- Helper to get or create a COMPLETE icon button with all possible overlays
    local function GetRowIconButton()
        row._iconBtnIndex = row._iconBtnIndex + 1
        local btn = row._iconButtons[row._iconBtnIndex]
        if not btn then
            btn = CreateFrame("Button", nil, row)
            btn:RegisterForClicks("AnyUp")

            -- Main texture
            btn._tex = btn:CreateTexture(nil, "ARTWORK")
            btn._tex:SetAllPoints()
            btn._tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Owned glow (outer)
            btn._glow = btn:CreateTexture(nil, "OVERLAY", nil, 1)
            btn._glow:SetPoint("TOPLEFT", -20, 20)
            btn._glow:SetPoint("BOTTOMRIGHT", 20, -20)
            btn._glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn._glow:SetBlendMode("ADD")

            -- Owned border (inner)
            btn._border = btn:CreateTexture(nil, "OVERLAY", nil, 2)
            btn._border:SetPoint("TOPLEFT", -10, 10)
            btn._border:SetPoint("BOTTOMRIGHT", 10, -10)
            btn._border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn._border:SetBlendMode("ADD")

            -- Checkmark
            btn._check = btn:CreateTexture(nil, "OVERLAY", nil, 3)
            btn._check:SetSize(22, 22)
            btn._check:SetPoint("TOPRIGHT", 8, 8)
            btn._check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")

            -- Selection glows (customize mode)
            btn._selGlow = btn:CreateTexture(nil, "OVERLAY", nil, 4)
            btn._selGlow:SetPoint("TOPLEFT", -14, 14)
            btn._selGlow:SetPoint("BOTTOMRIGHT", 14, -14)
            btn._selGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn._selGlow:SetBlendMode("ADD")

            btn._selMid = btn:CreateTexture(nil, "OVERLAY", nil, 5)
            btn._selMid:SetPoint("TOPLEFT", -10, 10)
            btn._selMid:SetPoint("BOTTOMRIGHT", 10, -10)
            btn._selMid:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn._selMid:SetBlendMode("ADD")

            btn._selInner = btn:CreateTexture(nil, "OVERLAY", nil, 6)
            btn._selInner:SetPoint("TOPLEFT", -6, 6)
            btn._selInner:SetPoint("BOTTOMRIGHT", 6, -6)
            btn._selInner:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn._selInner:SetBlendMode("ADD")

            -- BoE indicator
            btn._boe = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn._boe:SetPoint("BOTTOM", 0, -2)

            row._iconButtons[row._iconBtnIndex] = btn
        end

        -- Reset button state
        btn:ClearAllPoints()
        btn:SetScript("OnEnter", nil)
        btn:SetScript("OnLeave", nil)
        btn:SetScript("OnClick", nil)
        btn:Show()
        btn._tex:Show()
        btn._tex:SetTexture(nil)

        -- Hide all overlays by default
        btn._glow:Hide()
        btn._border:Hide()
        btn._check:Hide()
        btn._selGlow:Hide()
        btn._selMid:Hide()
        btn._selInner:Hide()
        btn._boe:Hide()

        return btn
    end

    -- Calculate Y offset for main row content (centered in the base height area)
    local mainRowYOffset = 0
    if rowHeight > baseHeight then
        -- If we have detail rows, main content should be at the top
        mainRowYOffset = (rowHeight - baseHeight) / 2
    end

    for _, col in ipairs(columns) do
        if col.type == "label" then
            -- Reuse or create slot label
            if not row._slotLabel then
                row._slotLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            end
            row._slotLabel:ClearAllPoints()
            row._slotLabel:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            row._slotLabel:SetWidth(col.width)
            row._slotLabel:SetJustifyH("LEFT")
            row._slotLabel:SetText("|cffffd700" .. slotName .. "|r")
            row._slotLabel:Show()

        elseif col.type == "enchant" then
            -- Enchant icon in main row (skip if enchant_detailed is enabled - will show in detail row)
            if not (showEnchantDetail and hasEnchant) then
                if slot.enhs then
                    for _, enh in ipairs(slot.enhs) do
                        if enh and enh.type ~= "none" and enh.id and enh.id > 0 then
                            if enh.type == "item" then
                                local name, _, _, _, _, class, _, _, _, texture = GetItemInfo(enh.id)
                                if class == "Gem" then
                                    -- Skip gems
                                elseif texture then
                                    local enchFrame = GetRowIconButton()
                                    enchFrame:SetSize(20, 20)
                                    enchFrame:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
                                    enchFrame._tex:SetTexture(texture)

                                    local capturedItemId = enh.id
                                    enchFrame:SetScript("OnEnter", function(self)
                                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                        GameTooltip:SetHyperlink("item:" .. capturedItemId .. ":0:0:0:0:0:0:0")
                                        GameTooltip:Show()
                                    end)
                                    enchFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                                    -- Shift+Click to link enchant item to chat
                                    enchFrame:SetScript("OnClick", function(self)
                                        if IsShiftKeyDown() then
                                            local _, freshLink = GetItemInfo(capturedItemId)
                                            if freshLink then
                                                ChatEdit_InsertLink(freshLink)
                                            end
                                        end
                                    end)
                                    break
                                end
                            elseif enh.type == "spell" then
                                local name, _, icon = GetSpellInfo(enh.id)
                                if icon then
                                    local enchFrame = GetRowIconButton()
                                    enchFrame:SetSize(20, 20)
                                    enchFrame:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
                                    enchFrame._tex:SetTexture(icon)

                                    local capturedSpellId = enh.id
                                    local capturedSpellName = name
                                    enchFrame:SetScript("OnEnter", function(self)
                                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                        local success = pcall(function()
                                            GameTooltip:SetHyperlink("enchant:" .. capturedSpellId)
                                        end)
                                        if not success then
                                            pcall(function()
                                                GameTooltip:SetHyperlink("spell:" .. capturedSpellId)
                                            end)
                                        end
                                        if capturedSpellName then
                                            GameTooltip:AddLine(" ")
                                            GameTooltip:AddLine("|cff00ff00" .. capturedSpellName .. "|r", 1, 1, 1)
                                        end
                                        GameTooltip:Show()
                                    end)
                                    enchFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                                    -- Shift+Click to link enchant spell to chat
                                    enchFrame:SetScript("OnClick", function(self)
                                        if IsShiftKeyDown() then
                                            -- Fetch fresh spell name at click time
                                            local spellName = GetSpellInfo(capturedSpellId)
                                            if spellName then
                                                local link = "|cffffd000|Henchant:" .. capturedSpellId .. "|h[" .. spellName .. "]|h|r"
                                                ChatEdit_InsertLink(link)
                                            end
                                        end
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
            end

        elseif col.type == "gems" then
            -- Gem icons in main row (skip if gem_detailed is enabled - will show in detail row)
            if not (showGemDetail and hasGems) then
                if slot.enhs then
                    local gemX = 0
                    local gemCount = 0
                    for _, enh in ipairs(slot.enhs) do
                        if enh and enh.type == "item" and enh.id and enh.id > 0 then
                            local name, link, _, _, _, class, subclass, _, _, texture = GetItemInfo(enh.id)
                            local isGem = (class == "Gem") or (subclass and subclass:find("Gem"))

                            if isGem and texture then
                                local gemFrame = GetRowIconButton()
                                gemFrame:SetSize(18, 18)
                                gemFrame:SetPoint("LEFT", row, "LEFT", col.x + gemX, mainRowYOffset)
                                gemFrame._tex:SetTexture(texture)

                                local gemId = enh.id
                                gemFrame:SetScript("OnEnter", function(self)
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    Utils.TooltipSetItemByID(GameTooltip, gemId)
                                    GameTooltip:Show()
                                end)
                                gemFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                                -- Shift+Click to link gem to chat
                                gemFrame:SetScript("OnClick", function(self)
                                    if IsShiftKeyDown() then
                                        local _, freshLink = GetItemInfo(gemId)
                                        if freshLink then
                                            ChatEdit_InsertLink(freshLink)
                                        end
                                    end
                                end)

                                gemX = gemX + 19
                                gemCount = gemCount + 1
                                if gemCount >= 4 then break end
                            end
                        end
                    end
                end
            end

        elseif col.type == "plan" then
            -- BIS Checklist mode: Boss / Item / Enchant(icon+text) / Gems below items
            -- Reuse planFrame to prevent child accumulation
            if not row._planFrame then
                row._planFrame = CreateFrame("Frame", nil, row)
            end
            local planFrame = row._planFrame
            planFrame:ClearAllPoints()
            planFrame:SetSize(col.width, rowHeight - 4)
            planFrame:SetPoint("LEFT", row, "LEFT", col.x, 0)
            planFrame:Show()
            
            local firstItemId = slot[1]
            local yPos = -2

            -- Reuse FontStrings to prevent accumulation
            if not planFrame._bossText then
                planFrame._bossText = planFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            local bossText = planFrame._bossText
            bossText:ClearAllPoints()
            bossText:SetPoint("TOPLEFT", 0, yPos)
            bossText:SetWidth(col.width)
            bossText:SetJustifyH("LEFT")
            bossText:Show()

            if firstItemId and firstItemId > 0 then
                local bossName = nil
                if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
                    local zone, boss = _G.BistooltipAddon:GetItemSourceInfo(firstItemId)
                    if boss then
                        bossName = boss
                    elseif zone then
                        bossName = zone
                    end
                end
                if bossName then
                    bossText:SetText("|cffaa4444" .. Utils.SmartTrunc(bossName, 22) .. "|r")
                else
                    bossText:SetText("|cff664444Unknown Source|r")
                end
            else
                bossText:SetText("")
            end
            yPos = yPos - 12

            -- LINE 2: Item name (reuse FontString)
            if not planFrame._itemText then
                planFrame._itemText = planFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            end
            local itemText = planFrame._itemText
            itemText:ClearAllPoints()
            itemText:SetPoint("TOPLEFT", 0, yPos)
            itemText:SetWidth(col.width)
            itemText:SetJustifyH("LEFT")
            itemText:Show()

            if firstItemId and firstItemId > 0 then
                local name = GetItemInfo(firstItemId)
                if name then
                    itemText:SetText("|cffff8040" .. Utils.SmartTrunc(name, 22) .. "|r")
                else
                    itemText:SetText("|cff888888Loading...|r")
                end
            else
                itemText:SetText("")
            end
            yPos = yPos - 14
            
            -- LINE 3: Enchant icon + text (reuse elements)
            -- Initialize enchant elements if needed
            if not planFrame._enchFrame then
                planFrame._enchFrame = CreateFrame("Button", nil, planFrame)
                planFrame._enchFrame._tex = planFrame._enchFrame:CreateTexture(nil, "ARTWORK")
                planFrame._enchFrame._tex:SetAllPoints()
                planFrame._enchFrame._tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            if not planFrame._enchLabel then
                planFrame._enchLabel = planFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end

            -- Hide enchant elements by default
            planFrame._enchFrame:Hide()
            planFrame._enchLabel:Hide()

            if slot.enhs then
                for _, enh in ipairs(slot.enhs) do
                    if enh and enh.type ~= "none" and enh.id and enh.id > 0 then
                        local isGem = false
                        local enchIcon, enchName, enchId, enchType

                        if enh.type == "item" then
                            local iName, _, _, _, _, iClass, _, _, _, iTex = GetItemInfo(enh.id)
                            isGem = (iClass == "Gem")
                            if not isGem and iTex then
                                enchIcon = iTex
                                enchName = iName
                                enchId = enh.id
                                enchType = "item"
                            end
                        elseif enh.type == "spell" then
                            local sName, _, sIcon = GetSpellInfo(enh.id)
                            if sIcon then
                                enchIcon = sIcon
                                enchName = sName
                                enchId = enh.id
                                enchType = "spell"
                            end
                        end

                        if enchIcon and not isGem then
                            local enchFrame = planFrame._enchFrame
                            enchFrame:ClearAllPoints()
                            enchFrame:SetSize(16, 16)
                            enchFrame:SetPoint("TOPLEFT", 0, yPos)
                            enchFrame._tex:SetTexture(enchIcon)
                            enchFrame:Show()

                            local capturedEnchId = enchId
                            local capturedEnchType = enchType
                            local capturedEnchName = enchName
                            enchFrame:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                if capturedEnchType == "item" then
                                    GameTooltip:SetHyperlink("item:" .. capturedEnchId .. ":0:0:0:0:0:0:0")
                                elseif capturedEnchType == "spell" then
                                    GameTooltip:SetSpellByID(capturedEnchId)
                                    GameTooltip:AddLine(" ")
                                    GameTooltip:AddLine("|cff00ff00Enchant: " .. (capturedEnchName or "") .. "|r")
                                end
                                GameTooltip:Show()
                            end)
                            enchFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                            -- Shift+Click to link enchant to chat
                            enchFrame:SetScript("OnClick", function(self)
                                if IsShiftKeyDown() then
                                    local link = nil
                                    if capturedEnchType == "item" then
                                        link = select(2, GetItemInfo(capturedEnchId))
                                    elseif capturedEnchType == "spell" then
                                        local spellName = GetSpellInfo(capturedEnchId)
                                        if spellName then
                                            link = "|cffffd000|Henchant:" .. capturedEnchId .. "|h[" .. spellName .. "]|h|r"
                                        end
                                    end
                                    if link then
                                        ChatEdit_InsertLink(link)
                                    end
                                end
                            end)

                            local enchLabel = planFrame._enchLabel
                            enchLabel:ClearAllPoints()
                            enchLabel:SetPoint("LEFT", enchFrame, "RIGHT", 3, 0)
                            enchLabel:SetWidth(col.width - 22)
                            enchLabel:SetJustifyH("LEFT")
                            enchLabel:SetText("|cff00ff00" .. Utils.SmartTrunc(enchName or "", 18) .. "|r")
                            enchLabel:Show()
                            break
                        end
                    end
                end
                yPos = yPos - 18
            end
            
            -- LINE 4: Gems with icons and stat text (reuse elements)
            -- Initialize gem elements pool on planFrame
            if not planFrame._gemFrames then
                planFrame._gemFrames = {}
                planFrame._gemLabels = {}
            end

            -- Hide all gem elements first
            for i = 1, 3 do
                if planFrame._gemFrames[i] then planFrame._gemFrames[i]:Hide() end
                if planFrame._gemLabels[i] then planFrame._gemLabels[i]:Hide() end
            end

            if slot.enhs then
                local gemX = 0
                local gemCount = 0
                for _, enh in ipairs(slot.enhs) do
                    if enh and enh.type == "item" and enh.id and enh.id > 0 then
                        local gName, _, _, _, _, gClass, _, _, _, gTex = GetItemInfo(enh.id)
                        if gClass == "Gem" and gTex then
                            gemCount = gemCount + 1

                            -- Get or create gem button
                            if not planFrame._gemFrames[gemCount] then
                                planFrame._gemFrames[gemCount] = CreateFrame("Button", nil, planFrame)
                                planFrame._gemFrames[gemCount]._tex = planFrame._gemFrames[gemCount]:CreateTexture(nil, "ARTWORK")
                                planFrame._gemFrames[gemCount]._tex:SetAllPoints()
                                planFrame._gemFrames[gemCount]._tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            end
                            local gemFrame = planFrame._gemFrames[gemCount]
                            gemFrame:ClearAllPoints()
                            gemFrame:SetSize(14, 14)
                            gemFrame:SetPoint("TOPLEFT", gemX, yPos)
                            gemFrame._tex:SetTexture(gTex)
                            gemFrame:Show()

                            local capturedGemId = enh.id
                            gemFrame:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                GameTooltip:SetHyperlink("item:" .. capturedGemId .. ":0:0:0:0:0:0:0")
                                GameTooltip:Show()
                            end)
                            gemFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                            -- Shift+Click to link gem to chat
                            gemFrame:SetScript("OnClick", function(self)
                                if IsShiftKeyDown() then
                                    local _, freshLink = GetItemInfo(capturedGemId)
                                    if freshLink then
                                        ChatEdit_InsertLink(freshLink)
                                    end
                                end
                            end)

                            -- Gem stat text
                            local statText = ""
                            if gName and _G.Bistooltip_GetGemStats then
                                statText = _G.Bistooltip_GetGemStats(gName) or ""
                            end

                            if statText ~= "" then
                                if not planFrame._gemLabels[gemCount] then
                                    planFrame._gemLabels[gemCount] = planFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                end
                                local statLabel = planFrame._gemLabels[gemCount]
                                statLabel:ClearAllPoints()
                                statLabel:SetPoint("LEFT", gemFrame, "RIGHT", 2, 0)
                                statLabel:SetText("|cff55aaff" .. statText .. "|r")
                                statLabel:Show()
                                gemX = gemX + 16 + statLabel:GetStringWidth() + 4
                            else
                                gemX = gemX + 17
                            end

                            if gemCount >= 3 or gemX > col.width - 20 then break end
                        end
                    end
                end
            end
            
        elseif col.type == "item" then
            local itemId = slot[itemIndex]
            if itemId and type(itemId) == "number" and itemId > 0 then
                local displayId = Data.GetDisplayItemID(itemId, isHorde)
                local ownedState, ownedCount = Data.GetOwnedState(displayId)

                -- Skip if "Only missing" and owned
                if not (showOnlyMissing and ownedState) then
                    -- Get pooled icon button (reuses frame and all overlays)
                    local iconFrame = GetRowIconButton()
                    -- Use mainRowYOffset to position in the main content area (top of row when detail rows present)
                    iconFrame:SetSize(CUSTOM_ICON_SIZE, CUSTOM_ICON_SIZE)
                    iconFrame:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)

                    -- Set icon texture
                    local _, itemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(displayId)
                    iconFrame._tex:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

                    -- Owned status overlays (use pre-created textures)
                    if ownedState then
                        local borderColor = ownedState == "equipped"
                            and {0.1, 0.96, 0.13, 1}
                            or {0.96, 0.88, 0.1, 1}

                        iconFrame._glow:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], 0.9)
                        iconFrame._glow:Show()

                        iconFrame._border:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], 1)
                        iconFrame._border:Show()

                        if ownedState == "equipped" then
                            iconFrame._check:Show()
                        end
                    end

                    -- Selection border (customize mode)
                    if customizeMode and selectedSwapItem and
                       selectedSwapItem.slotName == slotName and selectedSwapItem.index == itemIndex then
                        iconFrame._selGlow:SetVertexColor(1, 0, 0, 1)
                        iconFrame._selGlow:Show()
                        iconFrame._selMid:SetVertexColor(1, 0.3, 0.3, 1)
                        iconFrame._selMid:Show()
                        iconFrame._selInner:SetVertexColor(1, 0.5, 0.5, 1)
                        iconFrame._selInner:Show()
                    end

                    -- Tooltip
                    local capturedDisplayId = displayId
                    local capturedLink = itemLink
                    iconFrame:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        if capturedLink then
                            GameTooltip:SetHyperlink(capturedLink)
                        else
                            Utils.TooltipSetItemByID(GameTooltip, capturedDisplayId)
                        end
                        GameTooltip:Show()
                    end)
                    iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    -- Click handler
                    local capturedItemIndex = itemIndex
                    local capturedSlotName = slotName
                    local capturedSlot = slot
                    iconFrame:SetScript("OnClick", function(self, button)
                        if button == "LeftButton" then
                            local curCustomize = State.Get("customizeMode")
                            local curUnlocked = State.IsSlotUnlocked(capturedSlotName)

                            if curCustomize and curUnlocked then
                                local curSel = State.GetSelectedSwapItem()
                                if curSel and curSel.slotName == capturedSlotName then
                                    local fromIdx = curSel.index
                                    if fromIdx ~= capturedItemIndex then
                                        capturedSlot[fromIdx], capturedSlot[capturedItemIndex] = capturedSlot[capturedItemIndex], capturedSlot[fromIdx]
                                        Data.SaveCustomPriority(capturedSlot, State.Get("class"), State.Get("spec"), State.Get("phase"))
                                    end
                                    State.ClearSelectedSwapItem()
                                    drawSpecData()
                                else
                                    State.SetSelectedSwapItem(capturedSlotName, capturedItemIndex)
                                    drawSpecData()
                                end
                            elseif curCustomize and not curUnlocked then
                                print("|cffff8800Bistooltip:|r Unlock the slot first (click key icon)")
                            else
                                local _, link = GetItemInfo(capturedDisplayId)
                                if IsControlKeyDown() then
                                    if link then DressUpItemLink(link) end
                                elseif IsShiftKeyDown() then
                                    if link then ChatEdit_InsertLink(link) end
                                end
                            end
                        end
                    end)

                    -- NOTE: Gems under BIS icons REMOVED per user request
                    -- BIS mode uses simplified view without gem indicators
                end
            end
            itemIndex = itemIndex + 1
            
        elseif col.type == "lock" or col.type == "lockstatus" then
            -- Lock icon + status text (reuse elements)
            if not row._lockFrame then
                row._lockFrame = CreateFrame("Button", nil, row)
                row._lockFrame._tex = row._lockFrame:CreateTexture(nil, "ARTWORK")
                row._lockFrame._tex:SetAllPoints()
                row._lockFrame._tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            local lockFrame = row._lockFrame
            lockFrame:ClearAllPoints()
            lockFrame:SetSize(20, 20)
            lockFrame:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            lockFrame._tex:SetTexture(isUnlocked and "Interface\\Icons\\INV_Misc_Key_03" or "Interface\\Icons\\INV_Misc_Key_04")
            lockFrame:Show()

            -- Status text (LOCKED/UNLOCKED) - reuse
            if col.type == "lockstatus" then
                if not row._lockStatusLabel then
                    row._lockStatusLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                end
                local statusLabel = row._lockStatusLabel
                statusLabel:ClearAllPoints()
                statusLabel:SetPoint("LEFT", lockFrame, "RIGHT", 4, 0)
                if isUnlocked then
                    statusLabel:SetText("|cff00ff00UNLOCKED|r")
                else
                    statusLabel:SetText("|cffff4444LOCKED|r")
                end
                statusLabel:Show()
            end

            local capturedSlotName = slotName
            lockFrame:SetScript("OnClick", function()
                State.ToggleSlotUnlock(capturedSlotName)
                if not State.IsSlotUnlocked(capturedSlotName) then
                    local sel = State.GetSelectedSwapItem()
                    if sel and sel.slotName == capturedSlotName then
                        State.ClearSelectedSwapItem()
                    end
                end
                drawSpecData()
            end)

            lockFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(isUnlocked and "Click to lock" or "Click to unlock")
                GameTooltip:Show()
            end)
            lockFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- ============================================================
        -- BIS MODE NEW COLUMN TYPES
        -- ============================================================

        elseif col.type == "source" then
            -- SOURCE column: Boss/Vendor/Quest name (reuse FontString)
            if not row._sourceLabel then
                row._sourceLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            local sourceLabel = row._sourceLabel
            sourceLabel:ClearAllPoints()
            sourceLabel:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            sourceLabel:SetWidth(col.width)
            sourceLabel:SetJustifyH("LEFT")
            sourceLabel:Show()

            local firstItemId = slot[1]
            local sourceName = "Unknown"
            local sourceColor = "888888"

            if firstItemId and firstItemId > 0 then
                local foundInstanceSource = false

                -- Priority 1: Check boss/zone from instance drops FIRST
                if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
                    local zone, boss = _G.BistooltipAddon:GetItemSourceInfo(firstItemId)
                    if boss and boss ~= "" then
                        sourceName = boss
                        sourceColor = "ff6666"  -- Red for boss drops
                        foundInstanceSource = true
                    elseif zone and zone ~= "" then
                        sourceName = zone
                        sourceColor = "ffaa00"  -- Orange for zone
                        foundInstanceSource = true
                    end
                end

                -- Priority 2: If no instance source, check emblem vendors
                if not foundInstanceSource then
                    local cost, currency = nil, nil
                    if Data and Data.GetEmblemCost then
                        cost, currency = Data.GetEmblemCost(firstItemId)
                    end

                    if currency then
                        -- Vendor item - show emblem type with [E] prefix
                        local emblemShort = currency:gsub("Emblem of ", "")
                        sourceName = "[E] " .. emblemShort
                        -- Color based on emblem type
                        if currency == "Emblem of Frost" then
                            sourceColor = "00ccff"  -- Cyan/frost
                        elseif currency == "Emblem of Triumph" then
                            sourceColor = "cc66ff"  -- Purple
                        elseif currency == "Emblem of Conquest" then
                            sourceColor = "ffcc00"  -- Gold
                        elseif currency == "Emblem of Valor" then
                            sourceColor = "ff6600"  -- Orange
                        elseif currency == "Emblem of Heroism" then
                            sourceColor = "66ff66"  -- Green
                        elseif currency == "Emblem of Ascension" then
                            sourceColor = "00ffcc"  -- Teal (Ascension specific)
                        else
                            sourceColor = "ffaa00"  -- Default vendor color
                        end
                    end
                end
            end

            sourceLabel:SetText("|cff" .. sourceColor .. Utils.SmartTrunc(sourceName, 18) .. "|r")

        elseif col.type == "mode" then
            -- MODE column: Raid difficulty (N/HM/HC)
            if not row._modeLabel then
                row._modeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            local modeLabel = row._modeLabel
            modeLabel:ClearAllPoints()
            modeLabel:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            modeLabel:SetWidth(col.width)
            modeLabel:SetJustifyH("CENTER")
            modeLabel:Show()

            local firstItemId = slot[1]
            local modeText = "-"
            local modeColor = "cccccc"

            if firstItemId and firstItemId > 0 then
                -- Get source info
                if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
                    local zone = _G.BistooltipAddon:GetItemSourceInfo(firstItemId)
                    if zone then
                        local lowerZone = zone:lower()
                        -- Determine difficulty based on zone name
                        -- ICC/TOC use HC for heroic
                        if lowerZone:find("icecrown") or lowerZone:find("icc") or
                           lowerZone:find("trial") or lowerZone:find("toc") or lowerZone:find("crusader") then
                            if lowerZone:find("heroic") or lowerZone:find("hc") then
                                if lowerZone:find("25") then
                                    modeText = "25HC"
                                    modeColor = "ff6600"
                                elseif lowerZone:find("10") then
                                    modeText = "10HC"
                                    modeColor = "ff8833"
                                else
                                    modeText = "HC"
                                    modeColor = "ff6600"
                                end
                            else
                                if lowerZone:find("25") then
                                    modeText = "25N"
                                    modeColor = "88ff88"
                                elseif lowerZone:find("10") then
                                    modeText = "10N"
                                    modeColor = "aaffaa"
                                else
                                    modeText = "N"
                                    modeColor = "88ff88"
                                end
                            end
                        -- Ulduar uses HM for hard mode
                        elseif lowerZone:find("ulduar") then
                            if lowerZone:find("hard") or lowerZone:find("hm") then
                                if lowerZone:find("25") then
                                    modeText = "25HM"
                                    modeColor = "ffaa00"
                                elseif lowerZone:find("10") then
                                    modeText = "10HM"
                                    modeColor = "ffcc33"
                                else
                                    modeText = "HM"
                                    modeColor = "ffaa00"
                                end
                            else
                                if lowerZone:find("25") then
                                    modeText = "25N"
                                    modeColor = "88ff88"
                                elseif lowerZone:find("10") then
                                    modeText = "10N"
                                    modeColor = "aaffaa"
                                else
                                    modeText = "N"
                                    modeColor = "88ff88"
                                end
                            end
                        -- Naxx, EoE, OS, Ruby Sanctum - just N for normal
                        else
                            if lowerZone:find("25") then
                                modeText = "25N"
                                modeColor = "88ff88"
                            elseif lowerZone:find("10") then
                                modeText = "10N"
                                modeColor = "aaffaa"
                            else
                                modeText = "N"
                                modeColor = "88ff88"
                            end
                        end
                    end
                end

                -- Check if it's a profession/crafted item
                local cost, currency = nil, nil
                if Data and Data.GetEmblemCost then
                    cost, currency = Data.GetEmblemCost(firstItemId)
                end
                if not cost then
                    -- Check for profession source
                    if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
                        local zone, boss = _G.BistooltipAddon:GetItemSourceInfo(firstItemId)
                        if zone and (zone:lower():find("profession") or zone:lower():find("craft")) then
                            modeText = "-"
                            modeColor = "888888"
                        end
                    end
                end
            end

            modeLabel:SetText("|cff" .. modeColor .. modeText .. "|r")

        elseif col.type == "cost" then
            -- COST column: Emblem cost if applicable
            if not row._costLabel then
                row._costLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            local costLabel = row._costLabel
            costLabel:ClearAllPoints()
            costLabel:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            costLabel:SetWidth(col.width)
            costLabel:SetJustifyH("CENTER")
            costLabel:Show()

            local firstItemId = slot[1]
            local costText = "-"
            local costColor = "888888"

            if firstItemId and firstItemId > 0 then
                -- Check emblem cost
                local cost, currency = nil, nil
                if Data and Data.GetEmblemCost then
                    cost, currency = Data.GetEmblemCost(firstItemId)
                end

                if cost and currency then
                    -- Format: "x38" for emblems
                    costText = "x" .. tostring(cost)
                    if currency == "Emblem of Ascension" then
                        costColor = "00ffcc"  -- Teal for Ascension
                    elseif currency == "Emblem of Frost" then
                        costColor = "00ccff"  -- Cyan for Frost
                    elseif currency == "Emblem of Triumph" then
                        costColor = "cc66ff"  -- Purple for Triumph
                    else
                        costColor = "ffaa00"  -- Default orange
                    end
                end
            end

            costLabel:SetText("|cff" .. costColor .. costText .. "|r")

        elseif col.type == "dropchance" then
            -- DROP% column: Drop chance percentage
            if not row._dropLabel then
                row._dropLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            local dropLabel = row._dropLabel
            dropLabel:ClearAllPoints()
            dropLabel:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            dropLabel:SetWidth(col.width)
            dropLabel:SetJustifyH("CENTER")
            dropLabel:Show()

            local firstItemId = slot[1]
            local dropText = "-"

            if firstItemId and firstItemId > 0 then
                -- Check if it's a vendor item (no drop %)
                local isVendor = false
                if _G.Bistooltip_emblem_vendors then
                    for _, items in pairs(_G.Bistooltip_emblem_vendors) do
                        if items[firstItemId] then
                            isVendor = true
                            dropText = "|cff888888N/A|r"
                            break
                        end
                    end
                end

                -- If boss drop, show approximate drop % (placeholder)
                if not isVendor then
                    dropText = "|cff88ff88~15%|r"
                end
            end

            dropLabel:SetText(dropText)

        elseif col.type == "gems_bis" then
            -- GEMS with stats for BIS mode (compact layout with stats below icons)
            if not row._gemBisContainer then
                row._gemBisContainer = CreateFrame("Frame", nil, row)
            end
            local gemContainer = row._gemBisContainer
            gemContainer:ClearAllPoints()
            gemContainer:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            gemContainer:SetSize(col.width, baseHeight)
            gemContainer:Show()

            -- Initialize gem buttons if needed
            if not row._gemBisButtons then
                row._gemBisButtons = {}
                row._gemBisStats = {}
                for gemIdx = 1, 3 do
                    -- Gem icon button
                    local gemBtn = CreateFrame("Button", nil, gemContainer)
                    gemBtn:SetSize(18, 18)
                    gemBtn:RegisterForClicks("AnyUp")

                    local gemTex = gemBtn:CreateTexture(nil, "ARTWORK")
                    gemTex:SetAllPoints()
                    gemTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    gemBtn._tex = gemTex

                    row._gemBisButtons[gemIdx] = gemBtn

                    -- Stat label below gem
                    local statLabel = gemContainer:CreateFontString(nil, "OVERLAY")
                    statLabel:SetFont(Constants.FONTS.DEFAULT or "Fonts\\FRIZQT__.TTF", 8, "")
                    row._gemBisStats[gemIdx] = statLabel
                end
            end

            -- Get gem data for this slot
            local gemSlotData = slot.gems or {}

            -- Render up to 3 gems with stats
            for gemIdx = 1, 3 do
                local gemBtn = row._gemBisButtons[gemIdx]
                local statLabel = row._gemBisStats[gemIdx]

                gemBtn:Hide()
                statLabel:Hide()

                local gemId = gemSlotData[gemIdx]
                if gemId and gemId > 0 then
                    local gemName, _, _, _, _, _, _, _, _, gemTexture = GetItemInfo(gemId)

                    gemBtn:ClearAllPoints()
                    gemBtn:SetPoint("TOPLEFT", gemContainer, "TOPLEFT", (gemIdx - 1) * 24, -2)
                    gemBtn._tex:SetTexture(gemTexture or "Interface\\Icons\\INV_Misc_Gem_01")
                    gemBtn:Show()

                    -- Stat label (abbreviated)
                    statLabel:ClearAllPoints()
                    statLabel:SetPoint("TOP", gemBtn, "BOTTOM", 0, 0)

                    -- Get gem stats (simplified)
                    local statText = ""
                    if gemName then
                        -- Extract stat from name (e.g., "Bold Cardinal Ruby" -> "+20 STR")
                        if gemName:find("Strength") or gemName:find("Bold") then
                            statText = "+STR"
                        elseif gemName:find("Agility") or gemName:find("Delicate") then
                            statText = "+AGI"
                        elseif gemName:find("Intellect") or gemName:find("Brilliant") then
                            statText = "+INT"
                        elseif gemName:find("Haste") or gemName:find("Quick") then
                            statText = "+HST"
                        elseif gemName:find("Critical") or gemName:find("Smooth") then
                            statText = "+CRT"
                        elseif gemName:find("Hit") or gemName:find("Rigid") then
                            statText = "+HIT"
                        elseif gemName:find("Expertise") or gemName:find("Precise") then
                            statText = "+EXP"
                        elseif gemName:find("Spellpower") or gemName:find("Runed") then
                            statText = "+SP"
                        elseif gemName:find("Attack") then
                            statText = "+AP"
                        else
                            statText = ""
                        end
                    end
                    statLabel:SetText("|cff888888" .. statText .. "|r")
                    statLabel:Show()

                    -- Tooltip
                    gemBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        Utils.TooltipSetItemByID(GameTooltip, gemId)
                        GameTooltip:Show()
                    end)
                    gemBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    -- Click handler - Shift+click to link to chat
                    gemBtn:SetScript("OnClick", function(self)
                        if IsShiftKeyDown() then
                            local _, gemLink = GetItemInfo(gemId)
                            if gemLink then
                                ChatEdit_InsertLink(gemLink)
                            end
                        end
                    end)
                end
            end

        elseif col.type == "ilvl" then
            -- ILVL column: Item level (reuse FontString)
            if not row._ilvlLabel then
                row._ilvlLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            local ilvlLabel = row._ilvlLabel
            ilvlLabel:ClearAllPoints()
            ilvlLabel:SetPoint("LEFT", row, "LEFT", col.x, mainRowYOffset)
            ilvlLabel:SetWidth(col.width)
            ilvlLabel:SetJustifyH("CENTER")
            ilvlLabel:Show()

            local firstItemId = slot[1]
            local ilvlText = "-"
            local ilvlColor = "888888"

            if firstItemId and firstItemId > 0 then
                local _, _, _, itemLevel = GetItemInfo(firstItemId)
                if itemLevel and itemLevel > 0 then
                    ilvlText = tostring(itemLevel)
                    -- Color based on GearScore palette (WotLK 3.3.5)
                    if itemLevel >= 284 then ilvlColor = "D00000"      -- Deep red (284+)
                    elseif itemLevel >= 277 then ilvlColor = "F80000"  -- Red (277)
                    elseif itemLevel >= 264 then ilvlColor = "F83000"  -- Orange-red (264)
                    elseif itemLevel >= 258 then ilvlColor = "F04800"  -- Dark orange (258-259)
                    elseif itemLevel >= 239 then ilvlColor = "E06840"  -- Orange (239-245)
                    elseif itemLevel >= 226 then ilvlColor = "A84890"  -- Light pink/magenta (226)
                    elseif itemLevel >= 213 then ilvlColor = "A048F8"  -- Purple (213)
                    elseif itemLevel >= 200 then ilvlColor = "5060F8"  -- Deep blue (200)
                    elseif itemLevel >= 187 then ilvlColor = "08A0B8"  -- Light cyan (187)
                    end
                else
                    -- Item not cached yet - queue for preload
                    QueuePreload(firstItemId)
                end
            end

            ilvlLabel:SetText("|cff" .. ilvlColor .. ilvlText .. "|r")
        end
    end

    -- ============================================================
    -- BIS MODE: Enchant Detail Row (when enchant_detailed is enabled)
    -- Layout: [X mark] | [enchant icon] | Titanium Plating (name under BIS item area)
    -- ============================================================
    if showEnchantDetail and hasEnchant then
        local columns = GetColumnPositions()
        -- Position enchant row below main content area
        -- mainRowYOffset pushes main content UP, enchant row goes below it
        local enchantRowY = mainRowYOffset - (baseHeight / 2) - (DETAIL_ROW_HEIGHT / 2)

        -- Get enchant info
        local enchName, enchIcon, enchId, enchType = GetSlotEnchantInfo(slot)

        -- Enchant icon in the ENCHANT column (x=76)
        if enchIcon then
            if not row._enchDetailIcon then
                row._enchDetailIcon = CreateFrame("Button", nil, row)
                row._enchDetailIcon._tex = row._enchDetailIcon:CreateTexture(nil, "ARTWORK")
                row._enchDetailIcon._tex:SetAllPoints()
                row._enchDetailIcon._tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            row._enchDetailIcon:ClearAllPoints()
            row._enchDetailIcon:SetSize(18, 18)
            row._enchDetailIcon:SetPoint("LEFT", row, "LEFT", 76, enchantRowY)
            row._enchDetailIcon._tex:SetTexture(enchIcon)
            row._enchDetailIcon:Show()

            local capturedEnchId = enchId
            local capturedEnchType = enchType
            row._enchDetailIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if capturedEnchType == "spell" then
                    pcall(function() GameTooltip:SetHyperlink("enchant:" .. capturedEnchId) end)
                else
                    pcall(function() GameTooltip:SetHyperlink("item:" .. capturedEnchId .. ":0:0:0:0:0:0:0") end)
                end
                GameTooltip:Show()
            end)
            row._enchDetailIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
            -- Shift+Click to link enchant to chat
            row._enchDetailIcon:SetScript("OnClick", function(self)
                if IsShiftKeyDown() then
                    local link = nil
                    if capturedEnchType == "item" then
                        link = select(2, GetItemInfo(capturedEnchId))
                    elseif capturedEnchType == "spell" then
                        local spellName = GetSpellInfo(capturedEnchId)
                        if spellName then
                            link = "|cffffd000|Henchant:" .. capturedEnchId .. "|h[" .. spellName .. "]|h|r"
                        end
                    end
                    if link then
                        ChatEdit_InsertLink(link)
                    end
                end
            end)
        end

        -- Enchant name under the BIS item area (x=176)
        if enchName then
            if not row._enchDetailName then
                row._enchDetailName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end
            row._enchDetailName:ClearAllPoints()
            row._enchDetailName:SetPoint("LEFT", row, "LEFT", 176, enchantRowY)
            row._enchDetailName:SetText("|cff00ff00" .. enchName .. "|r")
            row._enchDetailName:Show()
        end
    else
        -- Hide enchant detail elements if not used
        if row._enchDetailIcon then row._enchDetailIcon:Hide() end
        if row._enchDetailName then row._enchDetailName:Hide() end
    end

    -- ============================================================
    -- BIS MODE: Gem Detail Row (when gem_detailed is enabled)
    -- Layout: [blank] | GEMS label | [gem icon] stats | [gem icon] stats | ...
    -- ============================================================
    if showGemDetail and hasGems then
        local enchantOffset = (showEnchantDetail and hasEnchant) and DETAIL_ROW_HEIGHT or 0
        -- Position gem row below enchant row (or below main content if no enchant)
        local gemRowY = mainRowYOffset - (baseHeight / 2) - enchantOffset - (DETAIL_ROW_HEIGHT / 2)

        -- "GEMS" label in the gems column area (x=102)
        if not row._gemDetailLabel then
            row._gemDetailLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        row._gemDetailLabel:ClearAllPoints()
        row._gemDetailLabel:SetPoint("LEFT", row, "LEFT", 102, gemRowY)
        row._gemDetailLabel:SetText("|cffffffffGEMS|r")
        row._gemDetailLabel:Show()

        -- Gem icons with stats under the BIS item area (x=176)
        if not row._gemDetailIcons then row._gemDetailIcons = {} end
        if not row._gemDetailStats then row._gemDetailStats = {} end

        local gemX = 176
        for i, gemId in ipairs(gemIds) do
            local gName, _, _, _, _, _, _, _, _, gTex = GetItemInfo(gemId)

            -- Create or reuse gem icon
            if not row._gemDetailIcons[i] then
                row._gemDetailIcons[i] = CreateFrame("Button", nil, row)
                row._gemDetailIcons[i]._tex = row._gemDetailIcons[i]:CreateTexture(nil, "ARTWORK")
                row._gemDetailIcons[i]._tex:SetAllPoints()
                row._gemDetailIcons[i]._tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            local gemIcon = row._gemDetailIcons[i]
            gemIcon:ClearAllPoints()
            gemIcon:SetSize(16, 16)
            gemIcon:SetPoint("LEFT", row, "LEFT", gemX, gemRowY)
            gemIcon._tex:SetTexture(gTex or "Interface\\Icons\\INV_Misc_QuestionMark")
            gemIcon:Show()

            local capturedGemId = gemId
            gemIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                Utils.TooltipSetItemByID(GameTooltip, capturedGemId)
                GameTooltip:Show()
            end)
            gemIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

            gemX = gemX + 18

            -- Gem stat text
            local statText = ""
            if gName and _G.Bistooltip_GetGemStats then
                statText = _G.Bistooltip_GetGemStats(gName) or ""
            end

            if statText ~= "" then
                if not row._gemDetailStats[i] then
                    row._gemDetailStats[i] = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                end
                local statLabel = row._gemDetailStats[i]
                statLabel:ClearAllPoints()
                statLabel:SetPoint("LEFT", row, "LEFT", gemX, gemRowY)
                statLabel:SetText("|cff55aaff" .. statText .. "|r")
                statLabel:Show()
                gemX = gemX + statLabel:GetStringWidth() + 8
            end

            if i >= 3 then break end  -- Max 3 gems
        end

        -- Hide unused gem elements
        for i = #gemIds + 1, 3 do
            if row._gemDetailIcons[i] then row._gemDetailIcons[i]:Hide() end
            if row._gemDetailStats[i] then row._gemDetailStats[i]:Hide() end
        end
    else
        -- Hide gem detail elements if not used
        if row._gemDetailLabel then row._gemDetailLabel:Hide() end
        if row._gemDetailIcons then
            for _, icon in ipairs(row._gemDetailIcons) do icon:Hide() end
        end
        if row._gemDetailStats then
            for _, stat in ipairs(row._gemDetailStats) do stat:Hide() end
        end
    end

    row:Show()
    table.insert(activeCustomRows, row)

    return row, rowHeight + CUSTOM_ROW_SPACING
end

-- Clear all custom rows (release to pool for reuse)
ClearCustomRows = function()
    -- Release all rows back to pool (for reuse)
    for _, row in ipairs(activeCustomRows) do
        ReleaseCustomRow(row)
    end
    wipe(activeCustomRows)

    -- Hide progress bar (but DON'T destroy - it's reused)
    if progressBarFrame then
        progressBarFrame:Hide()
    end

    -- Hide header and its children (but DON'T destroy - they're reused)
    if customHeaderFrame then
        customHeaderFrame:Hide()
        -- Hide all labels
        if customHeaderFrame._labels then
            for _, label in ipairs(customHeaderFrame._labels) do
                label:Hide()
            end
        end
        -- Hide search box
        if customHeaderFrame._searchBox then
            customHeaderFrame._searchBox:Hide()
        end
    end

    -- Clear search reference
    headerSearchBox = nil
end

-- Legacy wrapper for compatibility
local function destroySpecFrame()
    DestroyCustomSpecFrame()
end

local function createSpecFrame(forceRecreate)
    if forceRecreate then
        DestroyCustomSpecFrame()
    end
    CreateCustomSpecFrame()
end

-- ============================================================
-- Draw Spec Data (Main Refresh) - CUSTOM FRAMES VERSION
-- ============================================================

drawSpecData = function()
    if isDrawing then return end
    isDrawing = true

    -- CRITICAL: Verify and fix frame hierarchy before drawing
    -- This prevents ElvUI interference where content may render in wrong frame
    if mainFrame and mainFrame.frame then
        local currentParent = mainFrame.frame:GetParent()
        if currentParent ~= UIParent then
            -- Frame got reparented (likely by ElvUI) - fix it
            mainFrame.frame:SetParent(UIParent)
            mainFrame.frame:ClearAllPoints()
            mainFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            mainFrame.frame:SetFrameStrata("DIALOG")
            mainFrame.frame:SetFrameLevel(100)
        end
    end

    -- Ensure custom frame exists
    if not customContentFrame then
        CreateCustomSpecFrame()
    end

    if not customContentFrame then
        isDrawing = false
        return
    end

    -- Verify specContainerFrame parent is mainFrame.frame (our native frame)
    if specContainerFrame and mainFrame and mainFrame.frame then
        local containerParent = specContainerFrame:GetParent()
        if containerParent ~= mainFrame.frame then
            -- Parent is wrong - destroy and recreate ALL frames including progress bar
            DestroyProgressBar()
            DestroyCustomSpecFrame()
            customContentFrame = nil
            customScrollFrame = nil
            specContainerFrame = nil
            CreateCustomSpecFrame()
            if not customContentFrame then
                isDrawing = false
                return
            end
        end
    end

    -- Release pooled elements (but NOT selection state!)
    ReleaseActiveElements()
    -- DO NOT clear selected swap item here - it breaks customize mode!
    -- State.ClearSelectedSwapItem() -- REMOVED - this was the bug!

    -- Save state
    saveData()

    -- Clear previous rows
    ClearCustomRows()

    -- CRITICAL: Use FIXED width from Constants - NEVER trust GetWidth()
    -- This prevents ElvUI interference when parent has wrong size
    local fixedContentWidth = (Constants.UI.MAIN_FRAME_WIDTH or 600) - 4 - 24
    customContentFrame:SetWidth(fixedContentWidth)

    local yOffset = 0
    local totalHeight = 0

    -- Create progress bar as FIXED element (outside scroll, in specContainerFrame)
    -- This stays visible when scrolling
    CreateProgressBar(specContainerFrame)

    -- Create STICKY header (with search in SLOT column)
    -- Header is now OUTSIDE scroll content (in specContainerFrame), so doesn't affect yOffset
    CreateCustomHeader()
    -- Content starts at yOffset=0 in scroll area (header is above, fixed)

    local className, specName, phase = State.GetCurrentSelection()
    if not className or not specName or not phase then
        customContentFrame:SetHeight(math.max(totalHeight, 1))
        isDrawing = false
        return
    end

    -- Get slots
    local slots = Data.GetSlotsForSpec(className, specName, phase)
    if not slots then
        customContentFrame:SetHeight(math.max(totalHeight, 1))
        isDrawing = false
        return
    end

    -- Filter slots
    local searchText = State.Get("searchTextLower")
    local showOnlyMissing = State.Get("showOnlyMissing")
    local emblemFilterMode = State.Get("emblemFilterMode")
    local bisChecklistMode = State.Get("bisChecklistMode")
    local isHorde = State.Get("isHorde")

    local filteredSlots, allSlotsForProgress = Data.FilterSlots(
        slots, searchText, showOnlyMissing, emblemFilterMode, isHorde, bisChecklistMode
    )

    -- Store for progress calculation
    _G.Bistooltip_allSlotsForProgress = allSlotsForProgress

    -- Show message if ASCEND mode is enabled but no items match
    if emblemFilterMode and #filteredSlots == 0 then
        -- Create or show empty message label
        if not customContentFrame._emptyLabel then
            customContentFrame._emptyLabel = customContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            customContentFrame._emptyLabel:SetPoint("TOP", 0, -50)
            -- Use FIXED width from Constants
            customContentFrame._emptyLabel:SetWidth((Constants.UI.MAIN_FRAME_WIDTH or 600) - 4 - 24 - 40)
            customContentFrame._emptyLabel:SetJustifyH("CENTER")
        end
        customContentFrame._emptyLabel:SetText("|cffff8800ASCEND Mode Active|r\n\n|cffaaaaaaNo items in this spec/phase are purchasable with Emblem of Ascension.\n\nTry a different spec or phase.|r")
        customContentFrame._emptyLabel:Show()
        customContentFrame:SetHeight(150)
        isDrawing = false
        return
    else
        -- Hide empty message if it exists
        if customContentFrame._emptyLabel then
            customContentFrame._emptyLabel:Hide()
        end
    end

    -- Release previous instance headers
    if BistooltipInstanceHeader and BistooltipInstanceHeader.ReleaseAll then
        BistooltipInstanceHeader.ReleaseAll()
    end

    local rowIndex = 1

    -- In BIS mode, group slots by instance and render with collapsible headers
    if bisChecklistMode and BistooltipInstanceHeader and BistooltipInstanceHeader.GroupSlotsByInstance then
        local instanceGroups = BistooltipInstanceHeader.GroupSlotsByInstance(filteredSlots, isHorde, emblemFilterMode)

        for _, group in ipairs(instanceGroups) do
            -- Render instance header
            local _, headerHeight = BistooltipInstanceHeader.Create(customContentFrame, group, yOffset)
            yOffset = yOffset - headerHeight
            totalHeight = totalHeight + headerHeight

            -- Check if instance is collapsed
            local isCollapsed = State.IsInstanceCollapsed and State.IsInstanceCollapsed(group.key)

            -- If not collapsed, render slots belonging to this instance
            if not isCollapsed then
                for _, slot in ipairs(group.slots) do
                    -- Apply custom priorities
                    if slot.slot_name then
                        Data.LoadCustomPriority(slot, className, specName, phase)
                    end

                    local _, rowHeight = CreateCustomSlotRow(slot, yOffset, rowIndex)
                    yOffset = yOffset - rowHeight
                    totalHeight = totalHeight + rowHeight
                    rowIndex = rowIndex + 1
                end
            end
        end
    else
        -- MAIN mode: render slots directly (no grouping)
        for _, slot in ipairs(filteredSlots) do
            -- Apply custom priorities
            if slot.slot_name then
                Data.LoadCustomPriority(slot, className, specName, phase)
            end

            local _, rowHeight = CreateCustomSlotRow(slot, yOffset, rowIndex)
            yOffset = yOffset - rowHeight
            totalHeight = totalHeight + rowHeight
            rowIndex = rowIndex + 1
        end
    end
    
    -- Set content height
    customContentFrame:SetHeight(math.max(totalHeight, 1))

    -- Calculate and update progress bar
    local collectedCount = 0
    local totalCount = 0
    if allSlotsForProgress then
        for _, slot in ipairs(allSlotsForProgress) do
            totalCount = totalCount + 1
            if Data.IsSlotBISCompleted and Data.IsSlotBISCompleted(slot) then
                collectedCount = collectedCount + 1
            end
        end
    end
    UpdateProgressBar(collectedCount, totalCount)

    -- Update hints
    if checklistSummaryLabel then
        if not bisChecklistMode then
            checklistSummaryLabel:SetText("")
        elseif emblemFilterMode then
            checklistSummaryLabel:SetText("|cffff00ffASCEND MODE|r: Showing Emblem of Ascension items only")
        else
            checklistSummaryLabel:SetText("|cffffff00BIS Mode|r: Shows source boss, cost, and gem planning.")
        end
    end
    
    -- Update emblem summary
    if emblemSummaryLabel then
        if bisChecklistMode and emblemFilterMode then
            local totals = Data.CalculateMissingEmblems(className, specName, phase)
            local ascensionData = totals["Emblem of Ascension"]
            
            if ascensionData and ascensionData.total > 0 then
                local color = Constants.COLORS.ASCENSION or "00ffcc"
                emblemSummaryLabel:SetText(string.format("|cff%sEmblem of Ascension: %d|r", color, ascensionData.total))
            else
                emblemSummaryLabel:SetText("|cff00ff00All Ascension items collected!|r")
            end
        else
            emblemSummaryLabel:SetText("")
        end
    end

    isDrawing = false
end

-- ============================================================
-- Save/Load Data
-- ============================================================

saveData = function()
    State.Save()
end

loadData = function()
    State.Initialize()
    
    local classIndex = State.Get("class_index") or 1
    if not class_options[classIndex] then
        classIndex = 1
        State.Set("class_index", 1)
    end
    
    local classInfo = class_options_to_class[class_options[classIndex]]
    if classInfo then
        State.Set("class", classInfo.name)
    end
    
    buildSpecsDict(classIndex)
    
    local specIndex = State.Get("spec_index") or 1
    if not spec_options[specIndex] then
        specIndex = 1
        State.Set("spec_index", 1)
    end
    
    local specName = spec_options_to_spec[spec_options[specIndex]]
    State.Set("spec", specName)
    
    local phases = Data.GetPhaseList()
    local phaseIndex = State.Get("phase_index") or 1
    if not phases[phaseIndex] then
        phaseIndex = 1
        State.Set("phase_index", 1)
    end
    State.Set("phase", phases[phaseIndex])
end

-- ============================================================
-- Build Class Dictionary
-- ============================================================

buildClassDict = function()
    class_options = {}
    class_options_to_class = {}
    
    local classes = Data.GetClassList()
    
    for _, cls in ipairs(classes) do
        local coloredName = ColorizeClassOption(cls.name)
        table.insert(class_options, coloredName)
        class_options_to_class[coloredName] = { name = cls.name, i = cls.index }
    end
end

-- ============================================================
-- Build Specs Dictionary
-- ============================================================

buildSpecsDict = function(classIndex)
    spec_options = {}
    spec_options_to_spec = {}

    local classInfo = class_options_to_class[class_options[classIndex]]
    if not classInfo then return end

    local specs = Data.GetSpecsForClass(classInfo.name)

    for _, specName in ipairs(specs) do
        -- Include spec icons in dropdown for better visual identification
        local icon = Utils.GetSpecIcon(classInfo.name, specName)
        local displayName
        if icon then
            displayName = "|T" .. icon .. ":14:14:0:0|t " .. specName
        else
            displayName = specName
        end
        table.insert(spec_options, displayName)
        spec_options_to_spec[displayName] = specName
    end
end

-- ============================================================
-- Pill Button Helper (Toggle button with pill styling)
-- ============================================================

local pillButtons = {}  -- Store references for state updates

local function CreatePillButton(parent, text, width, isActive, onClick, tooltip)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 22)

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn._bg = bg

    -- Border
    local border = btn:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(0.3, 0.3, 0.35, 1)
    btn._border = border

    -- Label
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    btn._label = label

    -- State
    btn._isActive = isActive

    local function UpdateVisual()
        if btn._isActive then
            bg:SetVertexColor(0.2, 0.5, 0.8, 0.9)  -- Blue when active
            label:SetTextColor(1, 1, 1)
        else
            bg:SetVertexColor(0.15, 0.15, 0.18, 0.9)  -- Dark when inactive
            label:SetTextColor(0.7, 0.7, 0.7)
        end
    end

    btn.SetActive = function(self, active)
        self._isActive = active
        UpdateVisual()
    end

    UpdateVisual()

    btn:SetScript("OnClick", function(self)
        if onClick then
            onClick(self, not self._isActive)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        if not self._isActive then
            bg:SetVertexColor(0.2, 0.2, 0.25, 0.95)
        end
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        UpdateVisual()
        GameTooltip:Hide()
    end)

    return btn
end

-- ============================================================
-- NATIVE DROPDOWN SYSTEM (No AceGUI - full visual control)
-- ============================================================

-- Shared dropdown menu frame (reused for all dropdowns)
local dropdownMenuFrame = nil
local activeDropdown = nil

local function CreateDropdownMenu()
    if dropdownMenuFrame then return dropdownMenuFrame end

    local menu = CreateFrame("Frame", "BistooltipDropdownMenu", UIParent)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(100)
    menu:Hide()
    menu:EnableMouse(true)

    -- Background
    local bg = menu:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(bg, STYLE.COLORS.BG_DARK)
    menu._bg = bg

    -- Border
    local borders = {}
    for i, pos in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local border = menu:CreateTexture(nil, "BORDER")
        border:SetTexture("Interface\\Buttons\\WHITE8x8")
        ApplyColor(border, STYLE.COLORS.BORDER_VISIBLE)
        if pos == "TOP" then
            border:SetPoint("TOPLEFT", 0, 0)
            border:SetPoint("TOPRIGHT", 0, 0)
            border:SetHeight(1)
        elseif pos == "BOTTOM" then
            border:SetPoint("BOTTOMLEFT", 0, 0)
            border:SetPoint("BOTTOMRIGHT", 0, 0)
            border:SetHeight(1)
        elseif pos == "LEFT" then
            border:SetPoint("TOPLEFT", 0, 0)
            border:SetPoint("BOTTOMLEFT", 0, 0)
            border:SetWidth(1)
        else
            border:SetPoint("TOPRIGHT", 0, 0)
            border:SetPoint("BOTTOMRIGHT", 0, 0)
            border:SetWidth(1)
        end
        table.insert(borders, border)
    end
    menu._borders = borders

    -- Item buttons pool
    menu._items = {}

    -- Close on click outside
    menu:SetScript("OnShow", function(self)
        self:SetScript("OnUpdate", function(s)
            if not MouseIsOver(s) and not (activeDropdown and MouseIsOver(activeDropdown)) then
                if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
                    s:Hide()
                    activeDropdown = nil
                end
            end
        end)
    end)

    menu:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        activeDropdown = nil
    end)

    dropdownMenuFrame = menu
    return menu
end

local function ShowDropdownMenu(dropdown, items, selectedKey, onSelect)
    local menu = CreateDropdownMenu()

    -- Hide existing items
    for _, item in ipairs(menu._items) do
        item:Hide()
    end

    -- Position menu below dropdown
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(dropdown:GetWidth())

    -- Create/reuse item buttons
    local itemHeight = 20
    local padding = 4
    local yOffset = -padding

    for key, text in ipairs(items) do
        local itemBtn = menu._items[key]
        if not itemBtn then
            itemBtn = CreateFrame("Button", nil, menu)
            itemBtn:SetHeight(itemHeight)

            local itemBg = itemBtn:CreateTexture(nil, "BACKGROUND")
            itemBg:SetAllPoints()
            itemBg:SetTexture("Interface\\Buttons\\WHITE8x8")
            itemBtn._bg = itemBg

            local itemLabel = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            itemLabel:SetPoint("LEFT", 8, 0)
            itemLabel:SetPoint("RIGHT", -8, 0)
            itemLabel:SetJustifyH("LEFT")
            itemBtn._label = itemLabel

            menu._items[key] = itemBtn
        end

        itemBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", padding, yOffset)
        itemBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -padding, yOffset)

        itemBtn._label:SetText(text)
        itemBtn._key = key

        -- Highlight selected
        if key == selectedKey then
            ApplyColor(itemBtn._bg, STYLE.COLORS.ACCENT_BLUE_DIM)
            ApplyTextColor(itemBtn._label, STYLE.COLORS.TEXT_BRIGHT)
        else
            ApplyColor(itemBtn._bg, { 0, 0, 0, 0 })
            ApplyTextColor(itemBtn._label, STYLE.COLORS.TEXT_NORMAL)
        end

        itemBtn:SetScript("OnEnter", function(self)
            ApplyColor(self._bg, STYLE.COLORS.BG_HOVER)
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        end)

        itemBtn:SetScript("OnLeave", function(self)
            if self._key == selectedKey then
                ApplyColor(self._bg, STYLE.COLORS.ACCENT_BLUE_DIM)
            else
                ApplyColor(self._bg, { 0, 0, 0, 0 })
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        end)

        itemBtn:SetScript("OnClick", function(self)
            if onSelect then
                onSelect(self._key, items[self._key])
            end
            menu:Hide()
        end)

        itemBtn:Show()
        yOffset = yOffset - itemHeight
    end

    -- Set menu height
    menu:SetHeight(math.abs(yOffset) + padding)

    activeDropdown = dropdown
    menu:Show()
end

-- Native dropdown button factory (styled to match tab bar look)
local function CreateNativeDropdown(parent, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)

    -- Background (subtle, darker than container)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.08, 0.08, 0.10, 0.8)
    btn._bg = bg

    -- Right separator line (to visually separate from next element)
    local separator = btn:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPRIGHT", 0, -4)
    separator:SetPoint("BOTTOMRIGHT", 0, 4)
    separator:SetWidth(1)
    separator:SetTexture("Interface\\Buttons\\WHITE8x8")
    separator:SetVertexColor(0.35, 0.35, 0.40, 0.6)
    btn._separator = separator

    -- Label text
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 8, 0)
    label:SetPoint("RIGHT", -20, 0)
    label:SetJustifyH("LEFT")
    ApplyTextColor(label, STYLE.COLORS.TEXT_NORMAL)
    btn._label = label

    -- Arrow indicator (use "v" instead of Unicode - WoW 3.3.5a font compatibility)
    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")
    ApplyTextColor(arrow, STYLE.COLORS.TEXT_DIM)
    btn._arrow = arrow

    -- State
    btn._items = {}
    btn._selectedKey = nil
    btn._disabled = false
    btn._onValueChanged = nil

    -- API: SetList
    function btn:SetList(items)
        self._items = items or {}
    end

    -- API: SetValue
    function btn:SetValue(key)
        self._selectedKey = key
        if self._items[key] then
            self._label:SetText(self._items[key])
        end
    end

    -- API: GetValue
    function btn:GetValue()
        return self._selectedKey
    end

    -- API: SetDisabled
    function btn:SetDisabled(disabled)
        self._disabled = disabled
        if disabled then
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_DIM)
            ApplyTextColor(self._arrow, { 0.3, 0.3, 0.3, 1 })
            self._bg:SetVertexColor(0.06, 0.06, 0.08, 0.5)
        else
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
            ApplyTextColor(self._arrow, STYLE.COLORS.TEXT_DIM)
            self._bg:SetVertexColor(0.08, 0.08, 0.10, 0.8)
        end
    end

    -- API: SetCallback
    function btn:SetCallback(event, callback)
        if event == "OnValueChanged" then
            self._onValueChanged = callback
        end
    end

    -- API: Hide separator (for last element in row)
    function btn:HideSeparator()
        if self._separator then
            self._separator:Hide()
        end
    end

    -- Click handler
    btn:SetScript("OnClick", function(self)
        if self._disabled then return end
        if dropdownMenuFrame and dropdownMenuFrame:IsShown() and activeDropdown == self then
            dropdownMenuFrame:Hide()
            return
        end
        ShowDropdownMenu(self, self._items, self._selectedKey, function(key, text)
            self:SetValue(key)
            if self._onValueChanged then
                self._onValueChanged(self, nil, key)
            end
        end)
    end)

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        if self._disabled then return end
        self._bg:SetVertexColor(0.14, 0.14, 0.18, 0.9)
        ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        ApplyTextColor(self._arrow, STYLE.COLORS.TEXT_NORMAL)
    end)

    btn:SetScript("OnLeave", function(self)
        if self._disabled then return end
        self._bg:SetVertexColor(0.08, 0.08, 0.10, 0.8)
        ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        ApplyTextColor(self._arrow, STYLE.COLORS.TEXT_DIM)
    end)

    return btn
end

-- ============================================================
-- Native Filter Bar References
-- ============================================================
local nativeClassDropdown = nil
local nativeSpecDropdown = nil
local nativePhaseDropdown = nil

-- ============================================================
-- NEW UI: Tab Bar (Phase 4)
-- ============================================================

-- Module-level storage for tab buttons (tabBarFrame is already declared at line 104)
local tabBarButtons = {}

-- Forward declaration for filter bar buttons (needed by tab click handler)
local filterBarButtons = {}
local filterBarFrame = nil

local function CreateNewTabBar(parent)
    -- Hide any existing old-style tab bar elements (legacy cleanup)
    if _G["BistooltipTabBar"] then _G["BistooltipTabBar"]:Hide() end
    if _G["BistooltipTab1"] then _G["BistooltipTab1"]:Hide() end
    if _G["BistooltipTab2"] then _G["BistooltipTab2"]:Hide() end
    if _G["BistooltipTab3"] then _G["BistooltipTab3"]:Hide() end

    -- Destroy previous tab bar completely if it exists
    if tabBarFrame then
        tabBarFrame:Hide()
        tabBarFrame:SetParent(nil)
        -- Hide all children (buttons)
        for i = 1, 3 do
            if tabBarButtons[i] then
                tabBarButtons[i]:Hide()
                tabBarButtons[i]:SetParent(nil)
            end
        end
        wipe(tabBarButtons)
        tabBarFrame = nil
    end

    -- Create fresh frame WITHOUT global name (prevents persistence issues)
    local frame = CreateFrame("Frame", nil, parent)
    tabBarFrame = frame  -- Store reference

    frame:SetHeight(LAYOUT.TAB_BAR_HEIGHT)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", LAYOUT.PADDING, -34)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -LAYOUT.PADDING, -34)
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    frame:Show()

    -- Create background texture
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame._bg = bg
    frame._bg:SetVertexColor(0.08, 0.08, 0.10, 0.95)

    -- FULL WIDTH TABS: Calculate tab width to fill entire bar
    local totalPadding = 4  -- Left padding
    local tabSpacing = 2    -- Space between tabs
    local availableWidth = (Constants.UI.MAIN_FRAME_WIDTH or 600) - (LAYOUT.PADDING * 2) - totalPadding - (tabSpacing * 2)
    local tabWidth = math.floor(availableWidth / 3)
    local tabHeight = LAYOUT.TAB_BAR_HEIGHT - 4
    local tabs = { "MAIN", "BIS", "OPTIONS" }

    -- Determine which tab should be active based on saved state
    local savedBisChecklist = BistooltipAddon.db and BistooltipAddon.db.char and BistooltipAddon.db.char.bis_checklist
    local activeTabId = savedBisChecklist and 2 or 1  -- 1=MAIN, 2=BIS

    -- Create fresh buttons for each tab (no reuse - prevents stale state issues)
    for i, tabName in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, frame)
        btn:SetSize(tabWidth, tabHeight)
        btn:SetPoint("LEFT", frame, "LEFT", totalPadding + (i - 1) * (tabWidth + tabSpacing), 0)
        btn:RegisterForClicks("LeftButtonUp")

        -- Background texture
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn._bg = btnBg

        -- Highlight underline (blue line at bottom when active)
        local highlight = btn:CreateTexture(nil, "BORDER")
        highlight:SetPoint("BOTTOMLEFT", 0, 0)
        highlight:SetPoint("BOTTOMRIGHT", 0, 0)
        highlight:SetHeight(2)
        highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
        highlight:SetVertexColor(0.2, 0.6, 1, 1)
        highlight:Hide()  -- Start hidden
        btn._highlight = highlight

        -- Label text
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER")
        label:SetText(tabName)
        btn._label = label

        btn._tabId = i

        -- Store reference in module-level table for OnClick handler
        tabBarButtons[i] = btn

        -- Set initial visual state based on saved active tab
        local isActive = (i == activeTabId)
        if isActive then
            btn._bg:SetVertexColor(0.15, 0.15, 0.18, 0.95)
            btn._highlight:Show()
            btn._label:SetTextColor(1, 1, 1)
        else
            btn._bg:SetVertexColor(0.12, 0.12, 0.15, 0.9)
            btn._highlight:Hide()
            btn._label:SetTextColor(0.6, 0.6, 0.6)
        end

        btn:SetScript("OnClick", function(self)
            -- OPTIONS tab (3) opens config without changing active tab state
            if self._tabId == 3 then
                if BistooltipAddon.openConfigDialog then
                    BistooltipAddon:openConfigDialog()
                end
                return  -- Don't change tab highlight for OPTIONS
            end

            -- Update all tabs visual state (only MAIN and BIS)
            -- Reset ALL tabs first
            for j = 1, 2 do
                local otherBtn = tabBarButtons[j]
                if otherBtn and otherBtn._bg and otherBtn._highlight and otherBtn._label then
                    otherBtn._bg:SetVertexColor(0.12, 0.12, 0.15, 0.9)
                    otherBtn._highlight:Hide()
                    otherBtn._label:SetTextColor(0.6, 0.6, 0.6)
                end
            end

            -- Now highlight ONLY the clicked tab
            self._bg:SetVertexColor(0.15, 0.15, 0.18, 0.95)
            self._highlight:Show()
            self._label:SetTextColor(1, 1, 1)

            -- Handle tab switch
            if self._tabId == 1 then
                -- Switching to MAIN tab
                State.SetChecklistMode(false)

                -- CRITICAL: Disable ASCEND mode when leaving BIS tab
                State.SetEmblemFilterMode(false)

                -- Reset ASCEND button visual state using STYLE system
                if uiFrames.ascendBtn then
                    if uiFrames.ascendBtn._bg then
                        ApplyColor(uiFrames.ascendBtn._bg, STYLE.COLORS.BG_MEDIUM)
                    end
                    if uiFrames.ascendBtn._borders then
                        for _, border in ipairs(uiFrames.ascendBtn._borders) do
                            ApplyColor(border, STYLE.COLORS.BORDER_SUBTLE)
                        end
                    end
                    if uiFrames.ascendBtn._label then
                        ApplyTextColor(uiFrames.ascendBtn._label, STYLE.COLORS.TEXT_NORMAL)
                    end
                    uiFrames.ascendBtn._isActive = false
                end

                if BistooltipAddon.db and BistooltipAddon.db.char then
                    BistooltipAddon.db.char.bis_checklist = false
                end
                drawSpecData()
            elseif self._tabId == 2 then
                -- Switching to BIS tab
                State.SetChecklistMode(true)

                -- CRITICAL: Disable CUSTOM mode when entering BIS tab (only works in MAIN)
                State.SetCustomizeMode(false)
                State.LockAllSlots()

                -- Reset CUSTOM button visual state
                if filterBarButtons and filterBarButtons.custom then
                    filterBarButtons.custom:SetActive(false)
                end

                if BistooltipAddon.db and BistooltipAddon.db.char then
                    BistooltipAddon.db.char.bis_checklist = true
                end
                drawSpecData()
            end
        end)

        btn:SetScript("OnEnter", function(self)
            self._bg:SetVertexColor(0.18, 0.18, 0.22, 0.95)
        end)

        btn:SetScript("OnLeave", function(self)
            -- Check if highlight is shown for active state
            if self._highlight:IsShown() then
                self._bg:SetVertexColor(0.15, 0.15, 0.18, 0.95)
            else
                self._bg:SetVertexColor(0.12, 0.12, 0.15, 0.9)
            end
        end)
    end

    -- NOTE: LOCK and CUSTOM buttons are now in the filter bar below (CreateNewFilterBar)

    return frame
end

-- ============================================================
-- NEW UI: Filter Bar (Native dropdowns + LOCK + CUSTOM buttons)
-- All elements in one unified container - no AceGUI
-- ============================================================

-- Note: filterBarFrame and filterBarButtons are forward-declared above CreateNewTabBar

-- Helper to create filter bar toggle button (styled to match dropdowns)
local function CreateFilterBarButton(parent, text, width, height, initialActive, onClick, tooltipText)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)

    -- Background (matches dropdown style)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn._bg = bg

    -- Left separator line (to visually separate from previous element)
    local separator = btn:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", 0, -4)
    separator:SetPoint("BOTTOMLEFT", 0, 4)
    separator:SetWidth(1)
    separator:SetTexture("Interface\\Buttons\\WHITE8x8")
    separator:SetVertexColor(0.35, 0.35, 0.40, 0.6)
    btn._separator = separator

    -- Label text
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    btn._label = label
    btn._active = initialActive

    -- Set initial visual state
    if initialActive then
        bg:SetVertexColor(0.20, 0.50, 0.80, 0.7)
        ApplyTextColor(label, STYLE.COLORS.TEXT_BRIGHT)
    else
        bg:SetVertexColor(0.08, 0.08, 0.10, 0.8)
        ApplyTextColor(label, STYLE.COLORS.TEXT_NORMAL)
    end

    -- SetActive method
    btn.SetActive = function(self, active)
        self._active = active
        if active then
            self._bg:SetVertexColor(0.20, 0.50, 0.80, 0.7)
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        else
            self._bg:SetVertexColor(0.08, 0.08, 0.10, 0.8)
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        end
    end

    -- API: Hide separator (for first element)
    function btn:HideSeparator()
        if self._separator then
            self._separator:Hide()
        end
    end

    -- Click handler
    btn:SetScript("OnClick", function(self)
        local newState = not self._active
        if onClick then
            onClick(self, newState)
        end
    end)

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        if not self._active then
            self._bg:SetVertexColor(0.14, 0.14, 0.18, 0.9)
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        end
        if tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if self._active then
            self._bg:SetVertexColor(0.20, 0.50, 0.80, 0.7)
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        else
            self._bg:SetVertexColor(0.08, 0.08, 0.10, 0.8)
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        end
        GameTooltip:Hide()
    end)

    return btn
end

local function CreateNewFilterBar(parent, yOffset)
    -- Cleanup previous filter bar if exists
    if filterBarFrame then
        filterBarFrame:Hide()
        filterBarFrame:SetParent(nil)
        filterBarFrame = nil
        wipe(filterBarButtons)
    end

    local frame = CreateFrame("Frame", nil, parent)
    filterBarFrame = frame

    local filterHeight = 32  -- Height for filter bar
    frame:SetHeight(filterHeight)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", LAYOUT.PADDING, yOffset)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -LAYOUT.PADDING, yOffset)
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    frame:Show()

    -- ============================================================
    -- UNIFIED BACKGROUND for entire filter row
    -- ============================================================
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.10, 0.10, 0.12, 0.95)
    frame._bg = bg

    -- Border edges (4 sides) - subtle borders
    local borders = {}
    for i, pos in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local border = frame:CreateTexture(nil, "BORDER")
        border:SetTexture("Interface\\Buttons\\WHITE8x8")
        border:SetVertexColor(0.30, 0.30, 0.35, 0.7)
        if pos == "TOP" then
            border:SetPoint("TOPLEFT", 0, 0)
            border:SetPoint("TOPRIGHT", 0, 0)
            border:SetHeight(1)
        elseif pos == "BOTTOM" then
            border:SetPoint("BOTTOMLEFT", 0, 0)
            border:SetPoint("BOTTOMRIGHT", 0, 0)
            border:SetHeight(1)
        elseif pos == "LEFT" then
            border:SetPoint("TOPLEFT", 0, 0)
            border:SetPoint("BOTTOMLEFT", 0, 0)
            border:SetWidth(1)
        else
            border:SetPoint("TOPRIGHT", 0, 0)
            border:SetPoint("BOTTOMRIGHT", 0, 0)
            border:SetWidth(1)
        end
        table.insert(borders, border)
    end
    frame._borders = borders

    -- ============================================================
    -- LAYOUT DIMENSIONS - Fill entire bar width
    -- Total available: MAIN_FRAME_WIDTH (600) - LAYOUT.PADDING*2 (16) = 584px
    -- ============================================================
    local elementHeight = filterHeight - 4  -- 28px (full height minus small padding)
    local elementSpacing = 0  -- No gap - elements are adjacent, separated by lines
    local padding = 0  -- No edge padding - elements fill the bar

    -- Dropdown widths - expanded to fill entire bar
    -- Total: 125 + 175 + 80 + 90 + 110 = 580px (fills the bar)
    local classWidth = 125
    local specWidth = 175
    local phaseWidth = 80
    local lockWidth = 90
    local customWidth = 110

    -- ============================================================
    -- NATIVE DROPDOWNS (left side, adjacent to each other)
    -- ============================================================

    -- Class dropdown (first element - no left separator needed)
    nativeClassDropdown = CreateNativeDropdown(frame, classWidth, elementHeight)
    nativeClassDropdown:SetPoint("LEFT", frame, "LEFT", padding, 0)
    nativeClassDropdown:SetList(class_options)
    nativeClassDropdown:SetValue(State.Get("class_index") or 1)
    nativeClassDropdown:SetCallback("OnValueChanged", function(_, _, key)
        State.Set("class_index", key)
        State.Set("class", class_options_to_class[class_options[key]].name)

        nativeSpecDropdown:SetDisabled(false)
        buildSpecsDict(key)
        nativeSpecDropdown:SetList(spec_options)
        nativeSpecDropdown:SetValue(1)
        State.Set("spec_index", 1)
        State.Set("spec", spec_options_to_spec[spec_options[1]])
        drawSpecData()
        BulkPreloadAllItems(false)
    end)
    filterBarButtons.class = nativeClassDropdown

    -- Spec dropdown (adjacent to class)
    nativeSpecDropdown = CreateNativeDropdown(frame, specWidth, elementHeight)
    nativeSpecDropdown:SetPoint("LEFT", nativeClassDropdown, "RIGHT", elementSpacing, 0)
    nativeSpecDropdown:SetList(spec_options)
    nativeSpecDropdown:SetValue(State.Get("spec_index") or 1)
    nativeSpecDropdown:SetDisabled(not State.Get("class_index"))
    nativeSpecDropdown:SetCallback("OnValueChanged", function(_, _, key)
        State.Set("spec_index", key)
        State.Set("spec", spec_options_to_spec[spec_options[key]])
        drawSpecData()
        BulkPreloadAllItems(false)
    end)
    filterBarButtons.spec = nativeSpecDropdown

    -- Phase dropdown (adjacent to spec)
    nativePhaseDropdown = CreateNativeDropdown(frame, phaseWidth, elementHeight)
    nativePhaseDropdown:SetPoint("LEFT", nativeSpecDropdown, "RIGHT", elementSpacing, 0)
    nativePhaseDropdown:SetList(Data.GetPhaseList())
    nativePhaseDropdown:SetValue(State.Get("phase_index") or 1)
    nativePhaseDropdown:SetCallback("OnValueChanged", function(_, _, key)
        if State.IsPhaseBlocked() then
            local blockedIndex = State.Get("blockedPhaseIndex")
            nativePhaseDropdown:SetValue(blockedIndex)
            return
        end

        local phases = Data.GetPhaseList()
        State.Set("phase_index", key)
        State.Set("phase", phases[key])
        drawSpecData()
        BulkPreloadAllItems(false)
    end)
    filterBarButtons.phase = nativePhaseDropdown

    -- ============================================================
    -- LOCK & CUSTOM BUTTONS (right side, adjacent to each other)
    -- ============================================================

    -- CUSTOM button (far right - hide right separator)
    local customBtn = CreateFilterBarButton(
        frame,
        "CUSTOM",
        customWidth,
        elementHeight,
        State.Get("customizeMode"),
        function(btn, newState)
            if State.Get("bisChecklistMode") then return end

            State.SetCustomizeMode(newState)

            if newState then
                local className, specName, phase = State.GetCurrentSelection()
                if className and specName and phase then
                    local slots = Data.GetSlotsForSpec(className, specName, phase)
                    if slots then
                        local slotNames = {}
                        for _, slot in ipairs(slots) do
                            if slot.slot_name then
                                table.insert(slotNames, slot.slot_name)
                            end
                        end
                        State.UnlockAllSlots(slotNames)
                    end
                end
            else
                State.LockAllSlots()
            end

            btn:SetActive(newState)
            drawSpecData()
        end,
        "Enable item customization"
    )
    customBtn:SetPoint("RIGHT", frame, "RIGHT", -padding, 0)
    filterBarButtons.custom = customBtn
    pillButtons.custom = customBtn
    customizeToggleRef = { SetValue = function(_, val) customBtn:SetActive(val) end, SetDisabled = function() end }

    -- LOCK button (left of CUSTOM)
    local lockBtn = CreateFilterBarButton(
        frame,
        "LOCK",
        lockWidth,
        elementHeight,
        State.IsPhaseBlocked(),
        function(btn, newState)
            if newState then
                State.LockPhase()
            else
                State.UnlockPhase()
            end
            btn:SetActive(newState)
        end,
        "Lock current phase selection"
    )
    lockBtn:SetPoint("RIGHT", customBtn, "LEFT", elementSpacing, 0)
    filterBarButtons.lock = lockBtn
    pillButtons.lock = lockBtn

    -- Update references for compatibility with old AceGUI code
    classDropdown = nativeClassDropdown
    specDropdown = nativeSpecDropdown
    phaseDropdown = nativePhaseDropdown

    return frame
end

-- ============================================================
-- EXPORT Popup Frame and Generation
-- ============================================================

local exportPopupFrame = nil

local function CreateExportPopup()
    if exportPopupFrame then return exportPopupFrame end

    local frame = CreateFrame("Frame", "BistooltipExportPopup", UIParent)
    frame:SetSize(520, 480)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- ESC to close
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.08, 0.08, 0.10, 0.98)

    -- Border
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(0.3, 0.5, 0.8, 0.8)

    -- Inner bg
    local innerBg = frame:CreateTexture(nil, "ARTWORK")
    innerBg:SetPoint("TOPLEFT", 1, -1)
    innerBg:SetPoint("BOTTOMRIGHT", -1, 1)
    innerBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    innerBg:SetVertexColor(0.08, 0.08, 0.10, 1)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cFF00CCFFBis-Tooltip Export|r")

    -- Scroll frame for export text
    local scrollFrame = CreateFrame("ScrollFrame", "BistooltipExportScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 70)

    -- EditBox for export text
    local editBox = CreateFrame("EditBox", "BistooltipExportEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    scrollFrame:SetScrollChild(editBox)

    frame._editBox = editBox

    -- Bottom button bar
    local buttonBar = CreateFrame("Frame", nil, frame)
    buttonBar:SetHeight(40)
    buttonBar:SetPoint("BOTTOMLEFT", 10, 10)
    buttonBar:SetPoint("BOTTOMRIGHT", -10, 10)

    -- Helper to create styled button (matching addon theme)
    local function CreateStyledButton(parent, text, width)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(width, 26)

        -- Background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        bg:SetVertexColor(0.15, 0.15, 0.18, 0.95)
        btn._bg = bg

        -- Border
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetTexture("Interface\\Buttons\\WHITE8x8")
        border:SetVertexColor(0.3, 0.5, 0.8, 0.6)
        btn._border = border

        -- Label
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER")
        label:SetText(text)
        label:SetTextColor(0.9, 0.9, 0.9)
        btn._label = label

        -- Hover effects
        btn:SetScript("OnEnter", function(self)
            self._bg:SetVertexColor(0.2, 0.4, 0.6, 0.95)
            self._label:SetTextColor(1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self._bg:SetVertexColor(0.15, 0.15, 0.18, 0.95)
            self._label:SetTextColor(0.9, 0.9, 0.9)
        end)

        return btn
    end

    -- Copy button
    local copyBtn = CreateStyledButton(buttonBar, "Select All", 100)
    copyBtn:SetPoint("LEFT", 10, 0)
    copyBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        -- Select all text for easy Ctrl+C
        local textLen = editBox:GetText() and string.len(editBox:GetText()) or 0
        editBox:HighlightText(0, textLen)
    end)

    -- Close button
    local closeBtn = CreateStyledButton(buttonBar, "Close", 100)
    closeBtn:SetPoint("RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Copy instruction
    local copyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    copyLabel:SetPoint("BOTTOM", buttonBar, "TOP", 0, 2)
    copyLabel:SetText("|cff888888Press Ctrl+C to copy (text is auto-selected)|r")

    exportPopupFrame = frame
    return frame
end

local function GenerateExportText()
    local lines = {}
    local className, specName, phase = State.GetCurrentSelection()
    if not className or not specName or not phase then
        return "No class/spec/phase selected."
    end

    -- Header
    table.insert(lines, "Bis-Tooltip - BIS Checklist export")
    table.insert(lines, string.format("Class/Spec/Phase: %s / %s / %s", className, specName, phase))

    -- Get slots data
    local slots = Data.GetSlotsForSpec(className, specName, phase)
    if not slots then
        table.insert(lines, "No data available.")
        return table.concat(lines, "\n")
    end

    local isHorde = State.Get("isHorde")

    -- Group slots by instance
    local instanceGroups = {}
    local instanceOrder = {}
    local missingCount = 0
    local ownedItems = {}
    local emblemTotals = {}

    for _, slot in ipairs(slots) do
        local slotName = slot.slot_name or "Unknown"
        local firstItemId = slot[1]

        if firstItemId and firstItemId > 0 then
            local displayId = Data.GetDisplayItemID(firstItemId, isHorde)
            local ownedState = Data.GetOwnedState(displayId)
            local itemName = GetItemInfo(displayId) or ("Item:" .. displayId)
            local cost, currency = Data.GetEmblemCost(displayId)

            -- Get source
            local zone, boss = nil, nil
            if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
                zone, boss = _G.BistooltipAddon:GetItemSourceInfo(firstItemId)
            end
            zone = zone or "Unknown"
            boss = boss or "Unknown"

            local itemData = {
                slotName = slotName,
                itemId = displayId,
                itemName = itemName,
                zone = zone,
                boss = boss,
                cost = cost,
                currency = currency,
                owned = ownedState ~= nil
            }

            if ownedState then
                table.insert(ownedItems, itemData)
            else
                missingCount = missingCount + 1

                -- Track emblem costs
                if cost and currency then
                    emblemTotals[currency] = (emblemTotals[currency] or 0) + cost
                end

                -- Group by zone
                if not instanceGroups[zone] then
                    instanceGroups[zone] = { bosses = {} }
                    table.insert(instanceOrder, zone)
                end

                if not instanceGroups[zone].bosses[boss] then
                    instanceGroups[zone].bosses[boss] = {}
                end

                table.insert(instanceGroups[zone].bosses[boss], itemData)
            end
        end
    end

    -- Count and emblem totals
    table.insert(lines, string.format("Items missing: %d", missingCount))

    local emblemLine = "Emblems needed: "
    local first = true
    for currency, total in pairs(emblemTotals) do
        if not first then emblemLine = emblemLine .. ", " end
        emblemLine = emblemLine .. currency .. ": " .. total
        first = false
    end
    if not first then
        table.insert(lines, emblemLine)
    end

    table.insert(lines, "")

    -- Missing Items section
    table.insert(lines, "|cffff8800=== MISSING ITEMS ===|r")
    table.insert(lines, "")

    for _, zone in ipairs(instanceOrder) do
        local zoneData = instanceGroups[zone]
        table.insert(lines, "|cff00ff00" .. zone .. "|r")

        for boss, items in pairs(zoneData.bosses) do
            table.insert(lines, "  - |cffaaaaaa" .. boss .. "|r")

            for _, item in ipairs(items) do
                local costStr = ""
                if item.cost and item.currency then
                    costStr = " | |cff00ffcc" .. item.currency .. " x" .. item.cost .. "|r"
                end
                -- Slot in gold, item in purple, ID in blue
                table.insert(lines, string.format("      |cffffff00[%s]|r |cffa335ee[%s]|r |cff3399ff(id:%d)|r%s",
                    item.slotName, item.itemName, item.itemId, costStr))
            end
        end
        table.insert(lines, "")
    end

    -- Emblem Shopping List
    if next(emblemTotals) then
        table.insert(lines, "|cff00ffcc=== EMBLEM SHOPPING LIST ===|r")
        table.insert(lines, "")

        for currency, total in pairs(emblemTotals) do
            table.insert(lines, string.format("|cff00ffcc%s|r (Total: |cffffffff%d|r)", currency, total))

            -- List items for this currency
            for _, zone in ipairs(instanceOrder) do
                local zoneData = instanceGroups[zone]
                for _, items in pairs(zoneData.bosses) do
                    for _, item in ipairs(items) do
                        if item.currency == currency then
                            -- Slot in gold, item in purple
                            table.insert(lines, string.format("  - |cffffff00[%s]|r |cffa335ee%s|r |cff888888(%d)|r",
                                item.slotName, item.itemName, item.cost))
                        end
                    end
                end
            end
            table.insert(lines, "")
        end
    end

    -- Owned Items section
    if #ownedItems > 0 then
        table.insert(lines, "|cff00ff00=== OWNED ITEMS ===|r")
        table.insert(lines, "")
        for _, item in ipairs(ownedItems) do
            -- Slot in gold, item in purple, ID in blue
            table.insert(lines, string.format("  - |cffffff00[%s]|r |cffa335ee%s|r |cff3399ff(id:%d)|r",
                item.slotName, item.itemName, item.itemId))
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

local function ShowExportPopup()
    local popup = CreateExportPopup()
    local exportText = GenerateExportText()

    popup._editBox:SetText(exportText)
    popup._editBox:SetWidth(popup:GetWidth() - 50)
    popup._editBox:SetCursorPosition(0)

    -- Position next to main window (to the right)
    popup:ClearAllPoints()
    if mainFrame and mainFrame.frame then
        local mainX = mainFrame.frame:GetRight()
        local mainY = mainFrame.frame:GetTop()
        if mainX and mainY then
            popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", mainX + 10, mainY)
        else
            popup:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
        end
    else
        popup:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
    end

    popup:Show()

    -- Auto-select all text after a short delay
    if BistooltipDebounce and BistooltipDebounce.SetTimeout then
        BistooltipDebounce.SetTimeout(function()
            popup._editBox:SetFocus()
            popup._editBox:HighlightText()
        end, 0.1)
    end
end

-- ============================================================
-- NEW UI: Bottom Bar (Reload, Discord, Reset, ASCEND, EXPORT)
-- Uses unified STYLE system for consistent look
-- ============================================================

local function CreateNewBottomBar(parent)
    local frame = CreateFrame("Frame", "BistooltipNewBottomBar", parent)
    frame:SetHeight(LAYOUT.BOTTOM_BAR_HEIGHT)
    frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", LAYOUT.PADDING, 36)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -LAYOUT.PADDING, 36)
    frame:SetFrameLevel(parent:GetFrameLevel() + 5)

    -- Background with subtle top border
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(bg, STYLE.COLORS.BG_DARK)

    -- Top separator line
    local topLine = frame:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topLine:SetHeight(1)
    topLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(topLine, STYLE.COLORS.BORDER_SUBTLE)

    -- Reload Data button - use unified styled button
    local reloadBtn = CreateStyledButton(frame, "RELOAD", 70, STYLE.BUTTON_HEIGHT, function()
        BistooltipAddon:reloadData()
    end, "Reload item data")
    reloadBtn:SetPoint("LEFT", frame, "LEFT", 8, 0)

    -- Reset button (for custom mode)
    local resetBtn = CreateStyledButton(frame, "RESET", 60, STYLE.BUTTON_HEIGHT, function()
        Data.ResetCustomPriorities(State.Get("class"), State.Get("spec"), State.Get("phase"))
        State.LockAllSlots()
        State.ClearSelectedSwapItem()
        drawSpecData()
    end, "Reset item priorities to default")
    resetBtn:SetPoint("LEFT", reloadBtn, "RIGHT", 6, 0)
    uiFrames.resetBtn = resetBtn

    -- Discord button
    local discordBtn = CreateStyledButton(frame, "DISCORD", 70, STYLE.BUTTON_HEIGHT, function()
        BistooltipAddon:OpenDiscordLink()
    end, "Join our Discord server")
    discordBtn:SetPoint("LEFT", resetBtn, "RIGHT", 6, 0)

    -- Separator
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetSize(1, 20)
    sep:SetPoint("LEFT", discordBtn, "RIGHT", 12, 0)
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(sep, STYLE.COLORS.BORDER_NORMAL)

    -- ASCEND button (emblem filter) - toggle button style
    local ascendBtn = CreateStyledButton(frame, "ASCEND", 75, STYLE.BUTTON_HEIGHT, function(self)
        local bisChecklistMode = State.Get("bisChecklistMode")
        if not bisChecklistMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Bistooltip:|r ASCEND mode is only available in the BIS tab.")
            return
        end

        local newState = not State.Get("emblemFilterMode")
        State.SetEmblemFilterMode(newState)

        -- Update button visual state
        if newState then
            -- Active: teal accent
            ApplyColor(self._bg, STYLE.COLORS.ACCENT_TEAL)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.ACCENT_TEAL)
            end
            self._label:SetTextColor(0.1, 0.1, 0.1, 1)
            self._isActive = true
        else
            self:SetActive(false)
        end
        drawSpecData()
    end, "Filter Emblem of Ascension items (BIS tab only)")
    ascendBtn:SetToggleMode(true)
    ascendBtn:SetPoint("LEFT", sep, "RIGHT", 12, 0)
    uiFrames.ascendBtn = ascendBtn

    -- Custom OnEnter/OnLeave for ASCEND to handle teal active state
    ascendBtn:SetScript("OnEnter", function(self)
        local isActive = State.Get("emblemFilterMode")
        if not isActive then
            ApplyColor(self._bg, STYLE.COLORS.BG_HOVER)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.BORDER_NORMAL)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_BRIGHT)
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Filter Emblem of Ascension items (BIS tab only)", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    ascendBtn:SetScript("OnLeave", function(self)
        local isActive = State.Get("emblemFilterMode")
        if isActive then
            ApplyColor(self._bg, STYLE.COLORS.ACCENT_TEAL)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.ACCENT_TEAL)
            end
            self._label:SetTextColor(0.1, 0.1, 0.1, 1)
        else
            ApplyColor(self._bg, STYLE.COLORS.BG_MEDIUM)
            for _, border in ipairs(self._borders) do
                ApplyColor(border, STYLE.COLORS.BORDER_SUBTLE)
            end
            ApplyTextColor(self._label, STYLE.COLORS.TEXT_NORMAL)
        end
        GameTooltip:Hide()
    end)

    -- EXPORT button - use unified styled button
    local exportBtn = CreateStyledButton(frame, "EXPORT", 75, STYLE.BUTTON_HEIGHT, function()
        ShowExportPopup()
    end, "Export BIS list to clipboard")
    exportBtn:SetPoint("LEFT", ascendBtn, "RIGHT", 6, 0)

    return frame
end

-- ============================================================
-- Native Main Frame (WITHOUT AceGUI - fixes ElvUI interference)
-- ============================================================

local nativeMainFrame = nil  -- Our custom frame (not AceGUI)

local function CreateNativeMainFrame()
    local frameWidth = Constants.UI.MAIN_FRAME_WIDTH or 600
    local frameHeight = Constants.UI.MAIN_FRAME_HEIGHT or 700

    -- Create shadow frame FIRST (behind main frame)
    local shadowFrame = CreateFrame("Frame", "BistooltipMainShadow", UIParent)
    shadowFrame:SetFrameStrata("DIALOG")
    shadowFrame:SetFrameLevel(98)  -- Below main frame

    -- Create main frame directly - NO AceGUI
    local frame = CreateFrame("Frame", "BistooltipMainFrame", UIParent)
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(false)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)

    -- Position shadow relative to main frame
    shadowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 6)
    shadowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -6)

    -- Multi-layer shadow for depth effect
    local shadow1 = shadowFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow1:SetAllPoints()
    shadow1:SetTexture("Interface\\Buttons\\WHITE8x8")
    shadow1:SetVertexColor(0, 0, 0, 0.3)

    local shadow2 = shadowFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    shadow2:SetPoint("TOPLEFT", 2, -2)
    shadow2:SetPoint("BOTTOMRIGHT", -2, 2)
    shadow2:SetTexture("Interface\\Buttons\\WHITE8x8")
    shadow2:SetVertexColor(0, 0, 0, 0.4)

    local shadow3 = shadowFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
    shadow3:SetPoint("TOPLEFT", 4, -4)
    shadow3:SetPoint("BOTTOMRIGHT", -4, 4)
    shadow3:SetTexture("Interface\\Buttons\\WHITE8x8")
    shadow3:SetVertexColor(0, 0, 0, 0.5)

    frame._shadowFrame = shadowFrame

    -- Backdrop with refined border
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.40, 0.9)

    -- Title bar background
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(28)
    titleBar:SetPoint("TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", -4, -4)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    ApplyColor(titleBg, STYLE.COLORS.BG_LIGHT)

    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", 8, 0)
    titleText:SetTextColor(1, 0.82, 0, 1)
    frame._titleText = titleText

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        if frame._shadowFrame then frame._shadowFrame:Hide() end
        if frame._onClose then frame._onClose() end
    end)

    -- Show/hide shadow with main frame
    frame:SetScript("OnShow", function(self)
        if self._shadowFrame then self._shadowFrame:Show() end
    end)
    frame:SetScript("OnHide", function(self)
        if self._shadowFrame then self._shadowFrame:Hide() end
    end)

    -- Status bar at bottom
    local statusBar = CreateFrame("Frame", nil, frame)
    statusBar:SetHeight(20)
    statusBar:SetPoint("BOTTOMLEFT", 4, 4)
    statusBar:SetPoint("BOTTOMRIGHT", -4, 4)

    local statusBg = statusBar:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    statusBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    statusBg:SetVertexColor(0.06, 0.06, 0.08, 1)

    local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", 8, 0)
    statusText:SetTextColor(0.7, 0.7, 0.7, 1)
    frame._statusText = statusText

    -- Content area (legacy - kept for compatibility, no longer used for dropdowns)
    -- Native dropdowns are now created directly in CreateNewFilterBar
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 8, -100)  -- Below filter bar
    content:SetPoint("BOTTOMRIGHT", -8, 24)
    content:SetFrameLevel(frame:GetFrameLevel() + 5)
    frame.content = content

    -- Store reference to the actual frame (for compatibility)
    frame.frame = frame

    -- API methods to match AceGUI interface
    function frame:SetTitle(text)
        self._titleText:SetText(text)
    end

    function frame:SetStatusText(text)
        self._statusText:SetText(text)
    end

    function frame:SetWidth(w)
        self:SetSize(w, self:GetHeight())
    end

    function frame:SetHeight(h)
        self:SetSize(self:GetWidth(), h)
    end

    function frame:SetCallback(event, callback)
        if event == "OnClose" then
            self._onClose = callback
        end
    end

    function frame:SetLayout(layout)
        -- Not needed for our custom frame
    end

    -- Track children for layout
    frame._children = {}
    frame._childYOffset = 0

    function frame:AddChild(widget)
        -- For AceGUI widgets - parent them to our content area and position them
        if widget and widget.frame then
            widget.frame:SetParent(self.content)
            widget.frame:ClearAllPoints()

            -- Position below previous children
            widget.frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self._childYOffset)
            widget.frame:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -self._childYOffset)

            -- Ensure proper strata and level for visibility
            widget.frame:SetFrameStrata("DIALOG")
            widget.frame:SetFrameLevel(self.content:GetFrameLevel() + 10)

            -- Set full width and trigger layout
            if widget.SetFullWidth then
                widget:SetFullWidth(true)
            end

            -- Force widget to do its layout
            if widget.DoLayout then
                widget:DoLayout()
            end

            -- Show the widget
            widget.frame:Show()

            -- Track height for next child
            local widgetHeight = widget.frame:GetHeight() or 30
            self._childYOffset = self._childYOffset + widgetHeight + 4

            table.insert(self._children, widget)
        end
    end

    function frame:ReleaseChildren()
        for _, widget in ipairs(self._children) do
            if AceGUI and AceGUI.Release then
                AceGUI:Release(widget)
            end
        end
        wipe(self._children)
        self._childYOffset = 0
    end

    -- ESC to close
    tinsert(UISpecialFrames, "BistooltipMainFrame")

    return frame
end

-- ============================================================
-- Main Frame Creation (NEW LAYOUT)
-- ============================================================

function BistooltipAddon:showMainFrame()
    -- If mainFrame exists but was closed with X, UI elements were destroyed
    -- Check if we need to rebuild UI (tabBarFrame being nil is the indicator)
    if mainFrame and not tabBarFrame then
        -- UI elements were cleaned up - need to rebuild them
        mainFrame:Show()

        -- Re-register in UISpecialFrames for ESC to work
        -- First remove any existing entry to avoid duplicates
        Utils.RemoveFromUISpecialFrames("BistooltipMainFrame")
        tinsert(UISpecialFrames, "BistooltipMainFrame")
        mainFrameUISpecialName = "BistooltipMainFrame"

        local parentFrame = mainFrame.frame

        -- Rebuild all UI elements
        uiFrames.tabBar = CreateNewTabBar(parentFrame)
        uiFrames.filterBar = CreateNewFilterBar(parentFrame, -66)
        uiFrames.bottomBar = CreateNewBottomBar(parentFrame)

        -- Re-initialize dropdown values
        if nativeClassDropdown and nativeSpecDropdown then
            local classIndex = State.Get("class_index") or 1
            buildSpecsDict(classIndex)
            nativeSpecDropdown:SetList(spec_options)
            nativeSpecDropdown:SetValue(State.Get("spec_index") or 1)
            nativeSpecDropdown:SetDisabled(false)
        end

        -- Set initial tab state
        local initialTab = State.Get("bisChecklistMode") and 2 or 1
        local tabBtn = tabBarButtons[initialTab]
        if tabBtn and tabBtn:GetScript("OnClick") then
            tabBtn:GetScript("OnClick")(tabBtn)
        end

        -- Recreate content frame and draw
        createSpecFrame()
        drawSpecData()

        return
    end

    -- If mainFrame exists and UI is intact, just show it
    if mainFrame then
        mainFrame:Show()
        if specContainerFrame then
            specContainerFrame:Show()
        end
        return
    end

    -- Initialize systems
    InitPreloadSystem()
    Pools.Initialize()

    -- Build class dictionary
    buildClassDict()
    loadData()

    -- Load saved checklist mode
    if self.db and self.db.char and self.db.char.bis_checklist then
        State.Set("bisChecklistMode", true)
    end

    -- ============================================================
    -- CREATE NATIVE MAIN FRAME (NO AceGUI - fixes ElvUI interference)
    -- ============================================================
    mainFrame = CreateNativeMainFrame()

    mainFrame:SetCallback("OnClose", function()
        CleanupMainFrame()
        mainFrame:Hide()
        -- Keep mainFrame reference - it will be reused, but tabs will be recreated in showMainFrame
    end)

    -- Track the UISpecialFrames name for proper cleanup
    mainFrameUISpecialName = "BistooltipMainFrame"

    mainFrame:SetTitle(self.AddonNameAndVersion)

    local statusText = (self.AddonCredits or "") .. "  |  " .. (_G.Bistooltip_source_to_url and _G.Bistooltip_source_to_url[self.db.char.data_source] or "wowtbc.gg/wotlk")
    mainFrame:SetStatusText(statusText)

    State.SetMainFrame(mainFrame)

    -- ========================================
    -- BUILD NEW UI LAYOUT (Native frames - no AceGUI)
    -- ========================================

    -- 1. Tab Bar (full width MAIN/BIS/OPTIONS)
    local parentFrame = mainFrame.frame
    uiFrames.tabBar = CreateNewTabBar(parentFrame)

    -- 2. Filter Bar with NATIVE dropdowns + LOCK + CUSTOM
    -- All elements in one unified container - no AceGUI
    -- Position: below tab bar at -66px (title 34px + tab bar 32px)
    uiFrames.filterBar = CreateNewFilterBar(parentFrame, -66)

    -- 3. Bottom Bar (as direct frame at bottom)
    uiFrames.bottomBar = CreateNewBottomBar(parentFrame)

    -- 4. Initialize dropdown values (native dropdowns are already set in CreateNewFilterBar)
    -- Just ensure spec dropdown has correct list after class is set
    if nativeClassDropdown and nativeSpecDropdown then
        local classIndex = State.Get("class_index") or 1
        buildSpecsDict(classIndex)
        nativeSpecDropdown:SetList(spec_options)
        nativeSpecDropdown:SetValue(State.Get("spec_index") or 1)
        nativeSpecDropdown:SetDisabled(false)
    end

    -- 7. Set initial tab based on saved state
    -- Note: tabBarButtons is module-level array populated by CreateNewTabBar
    -- We use it directly instead of _G[] since buttons are created without global names
    local initialTab = State.Get("bisChecklistMode") and 2 or 1
    local tabBtn = tabBarButtons[initialTab]
    if tabBtn and tabBtn:GetScript("OnClick") then
        tabBtn:GetScript("OnClick")(tabBtn)
    end

    -- 8. Update ASCEND button visual state
    local ascendBtn = uiFrames.ascendBtn
    if ascendBtn then
        local emblemFilterMode = State.Get("emblemFilterMode")
        local btnBg = ascendBtn._bg
        local btnLabel = ascendBtn._label
        if btnBg and btnBg.SetVertexColor then
            if emblemFilterMode then
                btnBg:SetVertexColor(0.0, 0.8, 0.6, 0.95)
            else
                btnBg:SetVertexColor(0.12, 0.12, 0.15, 0.9)
            end
        end
        if btnLabel and btnLabel.SetTextColor then
            if emblemFilterMode then
                btnLabel:SetTextColor(0.1, 0.1, 0.1, 1)
            else
                btnLabel:SetTextColor(0.8, 0.8, 0.8, 1)
            end
        end
    end

    -- CRITICAL: Delay content creation to next frame to ensure parent hierarchy is fully established
    -- This fixes ElvUI interference where frames were created before parent change propagated
    local delayFrame = CreateFrame("Frame")
    local frameCount = 0
    delayFrame:SetScript("OnUpdate", function(self)
        frameCount = frameCount + 1
        -- Wait 2 frames to ensure UI hierarchy is fully settled
        if frameCount >= 2 then
            self:SetScript("OnUpdate", nil)

            -- Verify parent is still correct before creating child frames
            if mainFrame and mainFrame.frame and mainFrame.frame:GetParent() == UIParent then
                -- 4. NOW create content frame (after parent is settled)
                createSpecFrame()

                -- 9. Initial draw
                drawSpecData()

                -- 10. Bulk preload items
                BulkPreloadAllItems(false)
            end
        end
    end)
end

-- ============================================================
-- Close Main Frame
-- ============================================================

function BistooltipAddon:closeMainFrame()
    if mainFrame then
        CleanupMainFrame()
        mainFrame:Hide()
        -- Native dropdowns are cleaned up with the filter bar frame
        -- No AceGUI:Release needed - they are native Button frames now
    end
end

-- ============================================================
-- Aliases and Additional Methods
-- ============================================================

-- Alias for backward compatibility
function BistooltipAddon:createMainFrame()
    self:showMainFrame()
end

-- Reload data and refresh UI
function BistooltipAddon:reloadData()
    -- Force clear drawing flag to prevent stuck state
    isDrawing = false

    -- Rescan equipment and bags (refresh owned items cache)
    if self.ScanEquipment then
        self:ScanEquipment(true)
    end

    -- Clear all caches including filtered slots
    if Data.ClearAllCaches then
        Data.ClearAllCaches()
    else
        Data.ClearCache()
    end

    -- Also clear the global progress cache
    _G.Bistooltip_allSlotsForProgress = nil

    -- Rebuild dictionaries
    buildClassDict()
    loadData()

    -- Refresh if frame is open
    if mainFrame and mainFrame.frame:IsShown() then
        if specDropdown then
            buildSpecsDict(State.Get("class_index") or 1)
            specDropdown:SetList(spec_options)
            specDropdown:SetValue(State.Get("spec_index") or 1)
        end
        -- Force immediate redraw
        drawSpecData()
        -- Also preload items in background
        ForceReloadAllItems()
        -- Provide user feedback
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Bistooltip:|r Data reloaded successfully.")
    end
end

-- Initialize bislists (called from Core.lua)
function BistooltipAddon:initBislists()
    -- Data is already loaded via Config.lua EnableSpec()
    -- This is a hook for any additional initialization
    if Data and Data.ClearAllCaches then
        Data.ClearAllCaches()
    end

    -- Register slash commands
    LibStub("AceConsole-3.0"):RegisterChatCommand("bistooltip", function(msg)
        msg = msg and msg:lower():trim() or ""
        if msg == "config" or msg == "options" or msg == "settings" then
            BistooltipAddon:openConfigDialog()
        elseif msg == "reload" or msg == "refresh" then
            BistooltipAddon:reloadData()
        elseif msg == "help" then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip Commands:|r")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bistooltip|r - Toggle BIS window")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bistooltip config|r - Open settings")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bistooltip reload|r - Reload data")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/bis|r - Short alias")
        else
            BistooltipAddon:createMainFrame()
        end
    end)

    LibStub("AceConsole-3.0"):RegisterChatCommand("bis", function(msg)
        msg = msg and msg:lower():trim() or ""
        if msg == "config" or msg == "c" then
            BistooltipAddon:openConfigDialog()
        elseif msg == "reload" or msg == "r" then
            BistooltipAddon:reloadData()
        else
            BistooltipAddon:createMainFrame()
        end
    end)
end

-- Open Discord link
function BistooltipAddon:OpenDiscordLink()
    -- Create a simple editbox dialog for copying
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Join our Discord")
    frame:SetWidth(400)
    frame:SetHeight(120)
    frame:SetLayout("List")
    
    local label = AceGUI:Create("Label")
    label:SetText("Copy this link to join our Discord server:")
    label:SetFullWidth(true)
    frame:AddChild(label)
    
    local editbox = AceGUI:Create("EditBox")
    editbox:SetText("https://discord.gg/3gPCPCxbmP")
    editbox:SetFullWidth(true)
    editbox:DisableButton(true)
    editbox:SetCallback("OnEnterPressed", function() end)
    frame:AddChild(editbox)
    
    -- Select all text
    DelayedCall(0.1, function()
        if editbox.editbox then
            editbox.editbox:SetFocus()
            editbox.editbox:HighlightText()
        end
    end)
end

-- ============================================================
-- Global RefreshUI function for external modules (e.g., InstanceHeader)
-- ============================================================

_G.Bistooltip_RefreshUI = function()
    if drawSpecData and not isDrawing then
        drawSpecData()
    end
end

-- Also add to BistooltipAddon for dot notation access
function BistooltipAddon:RefreshUI()
    _G.Bistooltip_RefreshUI()
end
