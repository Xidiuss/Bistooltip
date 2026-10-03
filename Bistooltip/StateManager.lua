-- ============================================================
-- StateManager.lua - Centralized State Management
-- Single source of truth for all UI state
-- ============================================================

local ADDON_NAME = "Bis-Tooltip"

-- Create namespace
BistooltipState = BistooltipState or {}

-- ============================================================
-- State Definition
-- ============================================================

local State = {
    -- Selection state
    class = nil,
    spec = nil,
    phase = nil,
    class_index = 1,
    spec_index = 1,
    phase_index = 1,
    
    -- UI mode flags
    bisChecklistMode = false,
    vendorFilterMode = false,
    showOnlyMissing = false,
    customizeMode = false,
    
    -- Phase lock
    blockedPhase = nil,
    blockedPhaseIndex = nil,
    
    -- Search
    searchText = "",
    searchTextLower = "",
    
    -- Customize mode state
    unlockedSlots = {},
    selectedSwapItem = nil,
    
    -- Scroll state
    savedScrollValue = 0,
    
    -- Collapsed sections (for checklist)
    collapsedBosses = {},

    -- Collapsed instances (for BIS mode grouping)
    collapsedInstances = {},

    -- Drawing state (moved from BislistUI.lua for centralization)
    isDrawing = false,
    currentTab = "MAIN",

    -- Dirty flags for incremental updates
    dirtyFlags = {
        needsFullRebuild = true,     -- Complete UI rebuild needed
        needsProgressUpdate = false,  -- Only progress bar update needed
        needsSlotUpdate = {},         -- Specific slots need update (keyed by slotName)
        needsHeaderUpdate = false,    -- Instance headers need update
    },
    
    -- Faction
    isHorde = false,
    
    -- Frame references
    mainFrame = nil,
    specFrame = nil,
    
    -- Dropdown references (for AceGUI compatibility)
    classDropdown = nil,
    specDropdown = nil,
    phaseDropdown = nil,
    
    -- Listeners for state changes
    _listeners = {},
}

-- ============================================================
-- State Accessors
-- ============================================================

function BistooltipState.Get(key)
    return State[key]
end

function BistooltipState.Set(key, value)
    local oldValue = State[key]
    State[key] = value
    
    -- Notify listeners
    if oldValue ~= value then
        BistooltipState.NotifyListeners(key, value, oldValue)
    end
end

function BistooltipState.GetAll()
    return State
end

-- ============================================================
-- Batch State Updates
-- ============================================================

function BistooltipState.SetMultiple(updates)
    local changes = {}
    
    for key, value in pairs(updates) do
        local oldValue = State[key]
        if oldValue ~= value then
            State[key] = value
            changes[key] = { new = value, old = oldValue }
        end
    end
    
    -- Notify listeners for all changes
    for key, change in pairs(changes) do
        BistooltipState.NotifyListeners(key, change.new, change.old)
    end
end

-- ============================================================
-- Listener System (Observer Pattern)
-- ============================================================

function BistooltipState.AddListener(key, callback)
    if not State._listeners[key] then
        State._listeners[key] = {}
    end
    table.insert(State._listeners[key], callback)
    return #State._listeners[key]  -- Return listener ID
end

function BistooltipState.RemoveListener(key, listenerId)
    if State._listeners[key] and State._listeners[key][listenerId] then
        State._listeners[key][listenerId] = nil
    end
end

function BistooltipState.NotifyListeners(key, newValue, oldValue)
    if State._listeners[key] then
        for _, callback in pairs(State._listeners[key]) do
            if callback then
                pcall(callback, newValue, oldValue)
            end
        end
    end
    
    -- Global listener for any change
    if State._listeners["*"] then
        for _, callback in pairs(State._listeners["*"]) do
            if callback then
                pcall(callback, key, newValue, oldValue)
            end
        end
    end
end

-- ============================================================
-- State Initialization
-- ============================================================

function BistooltipState.Initialize()
    -- Detect faction
    State.isHorde = UnitFactionGroup("player") == "Horde"
    
    -- Load from saved variables if available
    if _G.BistooltipAddon and _G.BistooltipAddon.db and _G.BistooltipAddon.db.char then
        local db = _G.BistooltipAddon.db.char
        
        State.class_index = db.class_index or 1
        State.spec_index = db.spec_index or 1
        State.phase_index = db.phase_index or 1
        State.bisChecklistMode = db.bis_checklist or false
        State.blockedPhase = db.blocked_phase
        State.blockedPhaseIndex = db.blocked_phase_index
    end
end

function BistooltipState.Save()
    if not _G.BistooltipAddon or not _G.BistooltipAddon.db or not _G.BistooltipAddon.db.char then
        return
    end
    
    local db = _G.BistooltipAddon.db.char
    
    db.class_index = State.class_index
    db.spec_index = State.spec_index
    db.phase_index = State.phase_index
    db.bis_checklist = State.bisChecklistMode
    db.blocked_phase = State.blockedPhase
    db.blocked_phase_index = State.blockedPhaseIndex
end

-- ============================================================
-- Selection Helpers
-- ============================================================

function BistooltipState.SetClass(index, name)
    State.class_index = index
    State.class = name
    BistooltipState.NotifyListeners("class", name)
end

function BistooltipState.SetSpec(index, name)
    State.spec_index = index
    State.spec = name
    BistooltipState.NotifyListeners("spec", name)
end

function BistooltipState.SetPhase(index, name)
    -- Check if phase is locked
    if State.blockedPhase then
        return false
    end
    
    State.phase_index = index
    State.phase = name
    BistooltipState.NotifyListeners("phase", name)
    return true
end

function BistooltipState.GetCurrentSelection()
    return State.class, State.spec, State.phase
end

-- ============================================================
-- Mode Toggles
-- ============================================================

function BistooltipState.SetChecklistMode(enabled)
    State.bisChecklistMode = enabled
    
    -- Disable conflicting modes
    if enabled then
        State.showOnlyMissing = false
        State.customizeMode = false
        State.selectedSwapItem = nil
    end
    
    BistooltipState.NotifyListeners("bisChecklistMode", enabled)
end

function BistooltipState.SetVendorFilterMode(enabled)
    State.vendorFilterMode = enabled
    BistooltipState.NotifyListeners("vendorFilterMode", enabled)
end

function BistooltipState.SetShowOnlyMissing(enabled)
    State.showOnlyMissing = enabled
    BistooltipState.NotifyListeners("showOnlyMissing", enabled)
end

function BistooltipState.SetCustomizeMode(enabled)
    State.customizeMode = enabled
    
    if not enabled then
        State.selectedSwapItem = nil
        State.unlockedSlots = {}
    end
    
    BistooltipState.NotifyListeners("customizeMode", enabled)
end

-- ============================================================
-- Phase Lock
-- ============================================================

function BistooltipState.LockPhase()
    State.blockedPhase = State.phase
    State.blockedPhaseIndex = State.phase_index
    BistooltipState.Save()
    BistooltipState.NotifyListeners("blockedPhase", State.blockedPhase)
end

function BistooltipState.UnlockPhase()
    State.blockedPhase = nil
    State.blockedPhaseIndex = nil
    BistooltipState.Save()
    BistooltipState.NotifyListeners("blockedPhase", nil)
end

function BistooltipState.IsPhaseBlocked()
    return State.blockedPhase ~= nil
end

-- ============================================================
-- Search
-- ============================================================

function BistooltipState.SetSearch(text)
    State.searchText = text or ""
    State.searchTextLower = string.lower(State.searchText)
    BistooltipState.NotifyListeners("searchText", State.searchText)
end

function BistooltipState.ClearSearch()
    BistooltipState.SetSearch("")
end

-- ============================================================
-- Customize Mode State
-- ============================================================

function BistooltipState.ToggleSlotUnlock(slotName)
    if State.unlockedSlots[slotName] then
        State.unlockedSlots[slotName] = nil
    else
        State.unlockedSlots[slotName] = true
    end
    BistooltipState.NotifyListeners("unlockedSlots", State.unlockedSlots)
end

function BistooltipState.IsSlotUnlocked(slotName)
    return State.unlockedSlots[slotName] == true
end

function BistooltipState.UnlockAllSlots(slotNames)
    for _, name in ipairs(slotNames) do
        State.unlockedSlots[name] = true
    end
    BistooltipState.NotifyListeners("unlockedSlots", State.unlockedSlots)
end

function BistooltipState.LockAllSlots()
    State.unlockedSlots = {}
    State.selectedSwapItem = nil
    BistooltipState.NotifyListeners("unlockedSlots", State.unlockedSlots)
end

function BistooltipState.SetSelectedSwapItem(slotName, index)
    if slotName and index then
        State.selectedSwapItem = { slotName = slotName, index = index }
    else
        State.selectedSwapItem = nil
    end
    BistooltipState.NotifyListeners("selectedSwapItem", State.selectedSwapItem)
end

function BistooltipState.GetSelectedSwapItem()
    return State.selectedSwapItem
end

function BistooltipState.ClearSelectedSwapItem()
    State.selectedSwapItem = nil
    BistooltipState.NotifyListeners("selectedSwapItem", nil)
end

-- ============================================================
-- Boss Collapse State (Checklist Panel)
-- ============================================================

function BistooltipState.ToggleBossCollapse(bossKey)
    if State.collapsedBosses[bossKey] then
        State.collapsedBosses[bossKey] = nil
    else
        State.collapsedBosses[bossKey] = true
    end
    BistooltipState.NotifyListeners("collapsedBosses", State.collapsedBosses)
end

function BistooltipState.IsBossCollapsed(bossKey)
    return State.collapsedBosses[bossKey] == true
end

function BistooltipState.ExpandAllBosses()
    State.collapsedBosses = {}
    BistooltipState.NotifyListeners("collapsedBosses", State.collapsedBosses)
end

-- ============================================================
-- Instance Collapse State (BIS Mode Grouping)
-- ============================================================

function BistooltipState.ToggleInstanceCollapse(instanceKey)
    if State.collapsedInstances[instanceKey] then
        State.collapsedInstances[instanceKey] = nil
    else
        State.collapsedInstances[instanceKey] = true
    end
    BistooltipState.NotifyListeners("collapsedInstances", State.collapsedInstances)
end

function BistooltipState.IsInstanceCollapsed(instanceKey)
    return State.collapsedInstances[instanceKey] == true
end

function BistooltipState.ExpandAllInstances()
    State.collapsedInstances = {}
    BistooltipState.NotifyListeners("collapsedInstances", State.collapsedInstances)
end

function BistooltipState.CollapseAllInstances()
    -- Mark all known instances as collapsed
    -- This will be populated by the UI when instances are rendered
    BistooltipState.NotifyListeners("collapsedInstances", State.collapsedInstances)
end

-- ============================================================
-- Drawing State (centralized)
-- ============================================================

function BistooltipState.SetDrawing(isDrawing)
    State.isDrawing = isDrawing
end

function BistooltipState.IsDrawing()
    return State.isDrawing
end

function BistooltipState.SetCurrentTab(tabName)
    State.currentTab = tabName
    BistooltipState.NotifyListeners("currentTab", tabName)
end

function BistooltipState.GetCurrentTab()
    return State.currentTab or "MAIN"
end

-- ============================================================
-- Dirty Flags System (Incremental Updates)
-- ============================================================

function BistooltipState.SetDirty(flag, value)
    if flag == "full" then
        State.dirtyFlags.needsFullRebuild = value ~= false
    elseif flag == "progress" then
        State.dirtyFlags.needsProgressUpdate = value ~= false
    elseif flag == "headers" then
        State.dirtyFlags.needsHeaderUpdate = value ~= false
    end
end

function BistooltipState.SetSlotDirty(slotName, value)
    if slotName then
        State.dirtyFlags.needsSlotUpdate[slotName] = value ~= false
    end
end

function BistooltipState.IsDirty(flag)
    if flag == "full" then
        return State.dirtyFlags.needsFullRebuild
    elseif flag == "progress" then
        return State.dirtyFlags.needsProgressUpdate
    elseif flag == "headers" then
        return State.dirtyFlags.needsHeaderUpdate
    elseif flag == "any" then
        if State.dirtyFlags.needsFullRebuild then return true end
        if State.dirtyFlags.needsProgressUpdate then return true end
        if State.dirtyFlags.needsHeaderUpdate then return true end
        for _, v in pairs(State.dirtyFlags.needsSlotUpdate) do
            if v then return true end
        end
        return false
    end
    return false
end

function BistooltipState.IsSlotDirty(slotName)
    return slotName and State.dirtyFlags.needsSlotUpdate[slotName] == true
end

function BistooltipState.ClearDirty(flag)
    if flag == "full" then
        State.dirtyFlags.needsFullRebuild = false
    elseif flag == "progress" then
        State.dirtyFlags.needsProgressUpdate = false
    elseif flag == "headers" then
        State.dirtyFlags.needsHeaderUpdate = false
    elseif flag == "slots" then
        wipe(State.dirtyFlags.needsSlotUpdate)
    elseif flag == "all" then
        State.dirtyFlags.needsFullRebuild = false
        State.dirtyFlags.needsProgressUpdate = false
        State.dirtyFlags.needsHeaderUpdate = false
        wipe(State.dirtyFlags.needsSlotUpdate)
    end
end

function BistooltipState.ClearSlotDirty(slotName)
    if slotName then
        State.dirtyFlags.needsSlotUpdate[slotName] = nil
    end
end

-- Mark everything dirty (e.g., after selection change)
function BistooltipState.MarkAllDirty()
    State.dirtyFlags.needsFullRebuild = true
    State.dirtyFlags.needsProgressUpdate = true
    State.dirtyFlags.needsHeaderUpdate = true
end

-- Get list of dirty slots
function BistooltipState.GetDirtySlots()
    local slots = {}
    for slotName, isDirty in pairs(State.dirtyFlags.needsSlotUpdate) do
        if isDirty then
            table.insert(slots, slotName)
        end
    end
    return slots
end

-- ============================================================
-- Scroll State
-- ============================================================

function BistooltipState.SaveScrollPosition(value)
    State.savedScrollValue = value or 0
end

function BistooltipState.GetSavedScrollPosition()
    local value = State.savedScrollValue
    State.savedScrollValue = 0  -- Clear after reading
    return value
end

-- ============================================================
-- Frame References
-- ============================================================

function BistooltipState.SetMainFrame(frame)
    State.mainFrame = frame
end

function BistooltipState.GetMainFrame()
    return State.mainFrame
end

function BistooltipState.SetSpecFrame(frame)
    State.specFrame = frame
end

function BistooltipState.GetSpecFrame()
    return State.specFrame
end

-- ============================================================
-- Reset State
-- ============================================================

function BistooltipState.Reset()
    State.searchText = ""
    State.searchTextLower = ""
    State.showOnlyMissing = false
    State.customizeMode = false
    State.vendorFilterMode = false
    State.unlockedSlots = {}
    State.selectedSwapItem = nil
    State.savedScrollValue = 0
    State.collapsedBosses = {}
    
    BistooltipState.NotifyListeners("reset", true)
end

function BistooltipState.FullReset()
    BistooltipState.Reset()
    
    State.class = nil
    State.spec = nil
    State.phase = nil
    State.class_index = 1
    State.spec_index = 1
    State.phase_index = 1
    State.bisChecklistMode = false
    State.blockedPhase = nil
    State.blockedPhaseIndex = nil
    
    BistooltipState.NotifyListeners("fullReset", true)
end

-- ============================================================
-- Debug Output
-- ============================================================

function BistooltipState.PrintState()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip State:|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Class: %s (index: %d)", tostring(State.class), State.class_index))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Spec: %s (index: %d)", tostring(State.spec), State.spec_index))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Phase: %s (index: %d)", tostring(State.phase), State.phase_index))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Checklist Mode: %s", tostring(State.bisChecklistMode)))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Vendor Filter: %s", tostring(State.vendorFilterMode)))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Customize Mode: %s", tostring(State.customizeMode)))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Phase Locked: %s", tostring(State.blockedPhase)))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Search: '%s'", State.searchText))
end
