-- ============================================================
-- Core.lua - Main addon initialization and equipment cache
-- ============================================================

BistooltipAddon = LibStub("AceAddon-3.0"):NewAddon("Bis-Tooltip")

--[[
  Performance notes (3.3.5a):
  Previous versions were rebuilding huge BIS itemID lists and calling GetItemCount() for thousands of IDs
  on every BAG_UPDATE. That causes micro-stutters when moving/splitting/sorting items.

  This core now keeps a lightweight cache of *current character*:
    - bags (0..NUM_BAG_SLOTS)
    - equipped slots (1..19)

  Bank visibility:
    - We do NOT scan bank containers every time (expensive and often empty/unavailable).
    - If DataStore is enabled you can extend this later for alts/bank, but by default we keep it fast.
]]

-- ============================================================
-- Constants
-- ============================================================

local ADDON_NAME = "Bis-Tooltip"
local ADDON_VERSION = "2.2.2"
local ADDON_CREDITS = "backport by Silver [DisruptionAuras]"
local SCAN_DEBOUNCE = 0.25

-- ============================================================
-- Public cache: itemId -> { bags = n, equipped = n }
-- ============================================================

Bistooltip_char_equipment = Bistooltip_char_equipment or {}

-- ============================================================
-- Local state
-- ============================================================

local equipmentWatcherFrame = nil
local scanPending = false
local scanDelayLeft = 0

-- ============================================================
-- Helpers
-- ============================================================

local function GetItemIDFromLink(link)
    if not link then return nil end
    local id = link:match("item:(%d+):")
    if id then return tonumber(id) end
    return nil
end

-- ============================================================
-- Equipment / bags cache (debounced)
-- ============================================================

function BistooltipAddon:ScanEquipment(force)
    -- Build fresh table to avoid stale entries
    local collection = {}

    -- Bags only (0..NUM_BAG_SLOTS). This is tiny and safe.
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local id
            if GetContainerItemID then
                id = GetContainerItemID(bag, slot)
            else
                id = GetItemIDFromLink(GetContainerItemLink(bag, slot))
            end
            if id then
                local row = collection[id]
                if not row then
                    row = { bags = 0, equipped = 0 }
                    collection[id] = row
                end
                row.bags = (row.bags or 0) + 1
            end
        end
    end

    -- Equipped items (1..19)
    for i = 1, 19 do
        local id = GetInventoryItemID("player", i)
        if id then
            local row = collection[id]
            if not row then
                row = { bags = 0, equipped = 0 }
                collection[id] = row
            end
            row.equipped = (row.equipped or 0) + 1
        end
    end

    -- Update global cache
    Bistooltip_char_equipment = collection
    self.char_equipment = collection
    self.last_scan = GetTime()
end

-- ============================================================
-- Equipment Watcher (debounced scanning)
-- ============================================================

local function CreateEquipmentWatcher()
    if equipmentWatcherFrame then return end
    
    local frame = CreateFrame("Frame")
    frame:Hide()
    equipmentWatcherFrame = frame

    local function ScheduleScan()
        scanPending = true
        scanDelayLeft = SCAN_DEBOUNCE
        frame:Show()
    end

    frame:SetScript("OnEvent", function(self, event)
        -- BAG_UPDATE_DELAYED triggers once after a burst of changes (better than BAG_UPDATE spam)
        ScheduleScan()
    end)

    -- Use BAG_UPDATE_DELAYED if available; fallback to BAG_UPDATE
    if _G.BAG_UPDATE_DELAYED then
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
    else
        frame:RegisterEvent("BAG_UPDATE")
    end
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not scanPending then
            self:Hide()
            return
        end
        scanDelayLeft = scanDelayLeft - (elapsed or 0)
        if scanDelayLeft <= 0 then
            scanPending = false
            self:Hide()
            if BistooltipAddon and BistooltipAddon.ScanEquipment then
                BistooltipAddon:ScanEquipment(false)
            end
        end
    end)

    -- Initial scan as soon as possible
    ScheduleScan()
end

-- ============================================================
-- Source Cache for Item Lookups
-- ============================================================

-- Cache for item source info: itemId -> { zone, boss, emblemSource }
BistooltipAddon._sourceCache = BistooltipAddon._sourceCache or {}

-- Clear source cache (useful when data is reloaded)
function BistooltipAddon:ClearSourceCache()
    self._sourceCache = {}
end

-- ============================================================
-- Tooltip Cache for Performance
-- ============================================================

-- Cache for tooltip computation results
BistooltipAddon._tooltipCache = BistooltipAddon._tooltipCache or {}
local TOOLTIP_CACHE_DURATION = 1.0

function BistooltipAddon:GetCachedTooltipData(itemId)
    local cached = self._tooltipCache[itemId]
    if cached and (GetTime() - cached.time) < TOOLTIP_CACHE_DURATION then
        return cached.data
    end
    return nil
end

function BistooltipAddon:SetCachedTooltipData(itemId, data)
    self._tooltipCache[itemId] = {
        time = GetTime(),
        data = data
    }
end

function BistooltipAddon:ClearTooltipCache()
    self._tooltipCache = {}
end

-- ============================================================
-- DataStore Integration
-- ============================================================

local function GetDataStoreInventory()
    if _G.DataStore_Inventory then
        return _G.DataStore_Inventory
    end
    -- Try AceAddon lookup if DataStore is an AceAddon (safe = true)
    local ok, AceAddon = pcall(LibStub, "AceAddon-3.0")
    if ok and AceAddon and AceAddon.GetAddon then
        local ds = AceAddon:GetAddon("DataStore_Inventory", true)
        if ds then return ds end
    end
    return nil
end

-- ============================================================
-- Unknown sourceID dev-warning drain (new source model)
-- ============================================================

-- Session-local seen table: each unknown sourceID warns at most once per
-- session. Deliberately no cache/invalidation framework (frozen constraint:
-- lookups are already O(1)).
local _warnedUnknownSources = {}

local function DrainUnknownSourceWarnings()
    local acq = _G.BisTooltip_ItemAcquisition
    local reg = _G.BisTooltip_SourceRegistry
    if type(acq) ~= "table" or type(reg) ~= "table" then return end
    for itemId, entries in pairs(acq) do
        if type(entries) == "table" then
            for _, e in ipairs(entries) do
                local sid = type(e) == "table" and e.source or nil
                if sid and not reg[sid] and not _warnedUnknownSources[sid] then
                    _warnedUnknownSources[sid] = true
                    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip:|r unknown sourceID "
                            .. tostring(sid) .. " on item " .. tostring(itemId))
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Addon Initialization
-- ============================================================

function BistooltipAddon:OnInitialize()
    -- Pre-warm object pools FIRST (before any UI creation)
    -- This prevents CreateFrame calls during rendering and reduces FPS drops
    if BistooltipPools and BistooltipPools.Initialize then
        BistooltipPools.Initialize()
    end

    -- Create equipment watcher
    CreateEquipmentWatcher()

    -- DataStore is optional. We only *use* it in tooltip source lookups; bank/alt inventory is optional.
    self.hasDataStore = not not (_G.DataStore_Inventory or GetDataStoreInventory())
    if not self.hasDataStore then
        -- One-time info message
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd000Bis-Tooltip:|r running without DataStore. Bank/alt inventory features may be unavailable.")
    end

    -- Set addon info
    self.AceAddonName = ADDON_NAME
    self.AddonNameAndVersion = ADDON_NAME .. " " .. ADDON_VERSION .. " enchanted by Divian"
    self.AddonCredits = ADDON_CREDITS
    self.Version = ADDON_VERSION

    -- Initialize configuration
    if self.initConfig then 
        self:initConfig() 
    end
    
    -- Add minimap icon
    if self.addMapIcon then 
        self:addMapIcon() 
    end
    
    -- Initialize BIS lists
    if self.initBislists then 
        self:initBislists() 
    end
    
    -- Initialize tooltip hooks
    if self.initBisTooltip then 
        self:initBisTooltip() 
    end

    -- Ensure we have an initial cache for "You have this item" lines
    self:ScanEquipment(true)

    -- One-time dev warnings for acquisition entries pointing at
    -- sourceIDs missing from the registry (e.g. plugin typos).
    DrainUnknownSourceWarnings()
end

-- ============================================================
-- Addon Disable (cleanup)
-- ============================================================

function BistooltipAddon:OnDisable()
    -- Cleanup tooltip event handlers
    if self.cleanupBisTooltip then
        self:cleanupBisTooltip()
    end
end

-- ============================================================
-- Public API
-- ============================================================

-- Get owned count for an item (bags + equipped)
function BistooltipAddon:GetOwnedCount(itemId)
    if not itemId then return 0, 0 end
    local t = Bistooltip_char_equipment
    if not t then return 0, 0 end
    local row = t[itemId]
    if not row then return 0, 0 end
    return row.bags or 0, row.equipped or 0
end

-- Check if player owns an item
function BistooltipAddon:PlayerOwnsItem(itemId)
    local bags, equipped = self:GetOwnedCount(itemId)
    return (bags + equipped) > 0
end
