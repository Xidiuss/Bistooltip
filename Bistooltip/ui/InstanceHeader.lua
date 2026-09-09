-- ============================================================
-- ui/InstanceHeader.lua - Instance Headers for BIS Mode
-- Collapsible headers grouping loot by raid instance
-- WoW 3.3.5a compatible (Lua 5.1)
-- ============================================================

local ADDON_NAME = "Bis-Tooltip"

-- Create namespace
BistooltipInstanceHeader = BistooltipInstanceHeader or {}

-- Dependencies
local State = BistooltipState
local Pools = BistooltipPools
local Constants = BistooltipConstants

-- ============================================================
-- Instance Header Configuration
-- ============================================================

local HEADER_HEIGHT = 28
local HEADER_PADDING = 4
local COLLAPSE_INDICATOR_WIDTH = 16

-- Collapse/expand indicators (ASCII compatible for WoW 3.3.5a)
-- Using simple minus/plus that all WoW fonts definitely support
local ARROW_EXPANDED = "-"
local ARROW_COLLAPSED = "+"

-- Instance colors (themed by raid/source type)
-- Raids: match instance theme (ice=blue, ruby=red, titans=cyan)
-- Economic/profession: warmer/neutral tones (emblems=amber, crafting=green, tokens=gold)

-- Cache for instance colors (avoid repeated string matching)
local instanceColorCache = {}

-- Helper function to get color by pattern matching (case insensitive)
-- Results are cached for performance
local function GetInstanceColor(instanceName)
    if not instanceName then return { r = 0.5, g = 0.5, b = 0.5 } end

    -- Check cache first
    local cached = instanceColorCache[instanceName]
    if cached then return cached end

    local lowerName = instanceName:lower()
    local color = nil

    -- ICC (Icy blue theme)
    if lowerName:find("icecrown") or lowerName:find("icc") then
        if lowerName:find("heroic") or lowerName:find("hm") or lowerName:find("hc") then
            color = { r = 0.3, g = 0.6, b = 0.95 }  -- Deeper ice blue
        else
            color = { r = 0.4, g = 0.7, b = 0.95 }  -- Ice blue
        end
    -- Ruby Sanctum (Ruby red theme)
    elseif lowerName:find("ruby") or lowerName:find("halion") or (lowerName:find("sanctum") and not lowerName:find("obsidian")) then
        color = { r = 0.85, g = 0.2, b = 0.3 }  -- Ruby red
    -- ToC - Trial of the Crusader RAID (Argent gold theme)
    elseif (lowerName:find("trial") and lowerName:find("crusader")) or lowerName:find("toc") then
        color = { r = 0.9, g = 0.75, b = 0.3 }  -- Argent gold
    -- Ulduar (Titan cyan theme)
    elseif lowerName:find("ulduar") or lowerName:find("algalon") or lowerName:find("yogg") or lowerName:find("mimiron") then
        if lowerName:find("hardmode") or lowerName:find("hm") then
            color = { r = 0.2, g = 0.9, b = 0.95 }  -- Bright titan cyan
        else
            color = { r = 0.3, g = 0.85, b = 0.9 }  -- Titan cyan
        end
    -- Naxxramas (Necrotic green theme)
    elseif lowerName:find("naxx") or lowerName:find("kel'thuzad") or lowerName:find("thaddius") or lowerName:find("loatheb") or lowerName:find("horsemen") then
        color = { r = 0.4, g = 0.8, b = 0.35 }  -- Necrotic green
    -- Eye of Eternity / Malygos (Arcane purple-blue)
    elseif lowerName:find("eye") or lowerName:find("eternity") or lowerName:find("malygos") or lowerName:find("eoe") then
        color = { r = 0.5, g = 0.4, b = 0.9 }  -- Arcane purple-blue
    -- Obsidian Sanctum / Sartharion (Volcanic orange)
    elseif lowerName:find("obsidian") or lowerName:find("sartharion") or lowerName:find("sarth") then
        color = { r = 0.9, g = 0.5, b = 0.15 }  -- Volcanic orange
    -- Vault of Archavon (Storm gray-blue)
    elseif lowerName:find("vault") or lowerName:find("archavon") or lowerName:find("voa") then
        color = { r = 0.6, g = 0.65, b = 0.75 }  -- Storm gray-blue
    -- Onyxia (Dragon purple)
    elseif lowerName:find("onyxia") then
        color = { r = 0.6, g = 0.4, b = 0.7 }  -- Dragon purple
    -- Tier tokens (Light gold)
    elseif lowerName:find("tier") and lowerName:find("token") then
        color = { r = 0.85, g = 0.8, b = 0.4 }  -- Light gold
    -- Ascension emblems by cost (warmer = more expensive)
    elseif lowerName:find("ascension") or (lowerName:find("ascend") and lowerName:find("x%d")) then
        if lowerName:find("x80") then color = { r = 1.0, g = 0.4, b = 0.1 }
        elseif lowerName:find("x60") then color = { r = 1.0, g = 0.55, b = 0.1 }
        elseif lowerName:find("x50") then color = { r = 0.95, g = 0.7, b = 0.1 }
        elseif lowerName:find("x45") then color = { r = 0.9, g = 0.8, b = 0.2 }
        elseif lowerName:find("x40") then color = { r = 0.7, g = 0.9, b = 0.3 }
        elseif lowerName:find("x38") then color = { r = 0.4, g = 0.9, b = 0.4 }
        elseif lowerName:find("x30") then color = { r = 0.3, g = 0.85, b = 0.6 }
        elseif lowerName:find("x25") then color = { r = 0.3, g = 0.75, b = 0.8 }
        elseif lowerName:find("x20") then color = { r = 0.4, g = 0.6, b = 0.9 }
        elseif lowerName:find("x15") or lowerName:find("x12") then color = { r = 0.5, g = 0.5, b = 0.85 }
        else color = { r = 0.3, g = 0.9, b = 0.5 }  -- Default ascension green
        end
    -- Emblems (Amber/gold warm tones)
    elseif lowerName:find("emblem") then
        if lowerName:find("frost") then color = { r = 0.4, g = 0.75, b = 0.95 }  -- Frost blue
        elseif lowerName:find("triumph") then color = { r = 0.9, g = 0.6, b = 0.15 }  -- Triumph amber
        elseif lowerName:find("conquest") then color = { r = 0.85, g = 0.55, b = 0.2 }
        elseif lowerName:find("valor") then color = { r = 0.8, g = 0.65, b = 0.25 }
        elseif lowerName:find("heroism") then color = { r = 0.75, g = 0.7, b = 0.3 }
        elseif lowerName:find("ascension") then color = { r = 0.3, g = 0.9, b = 0.5 }
        else color = { r = 0.9, g = 0.7, b = 0.2 }  -- Default emblem amber
        end
    -- Echo of the Titans (Titan cyan)
    elseif lowerName:find("echo") and lowerName:find("titan") then
        color = { r = 0.3, g = 0.9, b = 0.85 }  -- Titan cyan
    -- Crafted / Profession (Green)
    elseif lowerName:find("craft") or lowerName:find("profession") or lowerName:find("blacksmith") or lowerName:find("tailor") or lowerName:find("leatherwork") then
        color = { r = 0.3, g = 0.75, b = 0.4 }  -- Profession green
    -- WotLK Dungeons (Common dungeon blue-gray color)
    elseif lowerName:find("dungeon") or lowerName:find("heroic") or
       lowerName:find("stratholme") or lowerName:find("culling") or
       lowerName:find("azjol") or lowerName:find("nerub") or
       lowerName:find("ahn'kahet") or lowerName:find("ahnkahet") or lowerName:find("old kingdom") or
       lowerName:find("drak'tharon") or lowerName:find("draktharon") or
       lowerName:find("gundrak") or
       lowerName:find("halls of stone") or lowerName:find("halls of lightning") or
       lowerName:find("nexus") or lowerName:find("oculus") or
       lowerName:find("utgarde") or lowerName:find("violet hold") or
       lowerName:find("champion") or
       lowerName:find("forge of souls") or lowerName:find("pit of saron") or lowerName:find("halls of reflection") then
        color = { r = 0.45, g = 0.55, b = 0.75 }  -- Dungeon blue-gray
    -- PvP (Red-orange)
    elseif lowerName:find("pvp") or lowerName:find("arena") or lowerName:find("battleground") then
        color = { r = 0.9, g = 0.3, b = 0.2 }  -- PvP red
    end

    -- Default gray if no match
    if not color then
        color = { r = 0.5, g = 0.5, b = 0.5 }
    end

    -- Cache the result
    instanceColorCache[instanceName] = color
    return color
end

local INSTANCE_COLORS = {
    -- ICC (Icy blue theme - frozen citadel)
    ["Icecrown Citadel"] = { r = 0.4, g = 0.7, b = 0.95 },       -- Ice blue
    ["ICC 25 Heroic"] = { r = 0.3, g = 0.6, b = 0.95 },          -- Deeper ice blue
    ["ICC 25 Normal"] = { r = 0.5, g = 0.75, b = 0.9 },          -- Light ice blue
    ["ICC 10 Heroic"] = { r = 0.35, g = 0.65, b = 0.9 },         -- Medium ice blue
    ["ICC 10 Normal"] = { r = 0.55, g = 0.8, b = 0.95 },         -- Pale ice blue

    -- Ruby Sanctum (Ruby red theme - distinct from alert red)
    ["Ruby Sanctum"] = { r = 0.85, g = 0.2, b = 0.3 },           -- Ruby red (not orange-red alert)
    ["RS 25 Heroic"] = { r = 0.9, g = 0.15, b = 0.25 },          -- Deeper ruby
    ["RS 25 Normal"] = { r = 0.8, g = 0.25, b = 0.35 },          -- Lighter ruby
    ["RS 10 Heroic"] = { r = 0.85, g = 0.2, b = 0.3 },
    ["RS 10 Normal"] = { r = 0.75, g = 0.3, b = 0.4 },

    -- ToC (Argent Crusade gold/silver theme)
    ["Trial of the Crusader"] = { r = 0.9, g = 0.75, b = 0.3 },  -- Argent gold
    ["ToC 25 Heroic"] = { r = 0.95, g = 0.8, b = 0.25 },         -- Bright gold
    ["ToC 25 Normal"] = { r = 0.85, g = 0.7, b = 0.35 },         -- Muted gold
    ["ToC 10 Heroic"] = { r = 0.9, g = 0.75, b = 0.3 },
    ["ToC 10 Normal"] = { r = 0.8, g = 0.65, b = 0.4 },

    -- Ulduar (Titan cyan/arcane theme)
    ["Ulduar"] = { r = 0.3, g = 0.85, b = 0.9 },                 -- Titan cyan
    ["Ulduar 25 Hardmode"] = { r = 0.2, g = 0.9, b = 0.95 },     -- Bright titan cyan
    ["Ulduar 25 Normal"] = { r = 0.35, g = 0.8, b = 0.85 },
    ["Ulduar 10 Hardmode"] = { r = 0.25, g = 0.85, b = 0.9 },
    ["Ulduar 10 Normal"] = { r = 0.4, g = 0.75, b = 0.8 },

    -- Naxxramas (Undead green/necrotic theme)
    ["Naxxramas"] = { r = 0.4, g = 0.8, b = 0.35 },              -- Necrotic green
    ["Naxx 25"] = { r = 0.35, g = 0.85, b = 0.3 },
    ["Naxx 10"] = { r = 0.45, g = 0.75, b = 0.4 },

    -- Eye of Eternity (Arcane blue/purple theme)
    ["Eye of Eternity"] = { r = 0.5, g = 0.4, b = 0.9 },         -- Arcane purple-blue
    ["EoE 25"] = { r = 0.45, g = 0.35, b = 0.95 },
    ["EoE 10"] = { r = 0.55, g = 0.45, b = 0.85 },

    -- Obsidian Sanctum (Volcanic orange/black theme)
    ["Obsidian Sanctum"] = { r = 0.9, g = 0.5, b = 0.15 },       -- Volcanic orange
    ["OS 25"] = { r = 0.95, g = 0.55, b = 0.1 },
    ["OS 10"] = { r = 0.85, g = 0.45, b = 0.2 },

    -- Vault of Archavon (Storm gray/blue theme)
    ["Vault of Archavon"] = { r = 0.6, g = 0.65, b = 0.75 },     -- Storm gray-blue
    ["VoA 25"] = { r = 0.55, g = 0.6, b = 0.8 },
    ["VoA 10"] = { r = 0.65, g = 0.7, b = 0.7 },

    -- Onyxia's Lair (Dragon black/purple theme)
    ["Onyxia's Lair"] = { r = 0.6, g = 0.4, b = 0.7 },           -- Dragon purple
    ["Onyxia 25"] = { r = 0.55, g = 0.35, b = 0.75 },
    ["Onyxia 10"] = { r = 0.65, g = 0.45, b = 0.65 },

    -- Echo of the Titans (New emblem system - cyan/titan theme)
    ["Echo of the Titans"] = { r = 0.3, g = 0.9, b = 0.85 },     -- Titan cyan

    -- Emblems/Vendors (Amber/gold warm tones)
    ["Emblem Vendors"] = { r = 0.9, g = 0.7, b = 0.2 },          -- Amber
    ["Emblem of Frost"] = { r = 0.4, g = 0.75, b = 0.95 },       -- Frost blue
    ["Emblem of Triumph"] = { r = 0.9, g = 0.6, b = 0.15 },      -- Triumph amber
    ["Emblem of Conquest"] = { r = 0.85, g = 0.55, b = 0.2 },    -- Conquest amber
    ["Emblem of Valor"] = { r = 0.8, g = 0.65, b = 0.25 },       -- Valor gold
    ["Emblem of Heroism"] = { r = 0.75, g = 0.7, b = 0.3 },      -- Heroism gold
    ["Emblem of Ascension"] = { r = 0.3, g = 0.9, b = 0.5 },     -- Ascension green

    -- Ascension mode - distinct colors by cost tier (higher cost = more valuable = warmer colors)
    ["Ascension Emblems x80"] = { r = 1.0, g = 0.4, b = 0.1 },   -- Orange-red (most expensive)
    ["Ascension Emblems x60"] = { r = 1.0, g = 0.55, b = 0.1 },  -- Orange
    ["Ascension Emblems x50"] = { r = 0.95, g = 0.7, b = 0.1 },  -- Gold
    ["Ascension Emblems x45"] = { r = 0.9, g = 0.8, b = 0.2 },   -- Yellow-gold
    ["Ascension Emblems x40"] = { r = 0.7, g = 0.9, b = 0.3 },   -- Yellow-green
    ["Ascension Emblems x38"] = { r = 0.4, g = 0.9, b = 0.4 },   -- Green
    ["Ascension Emblems x30"] = { r = 0.3, g = 0.85, b = 0.6 },  -- Teal
    ["Ascension Emblems x25"] = { r = 0.3, g = 0.75, b = 0.8 },  -- Cyan
    ["Ascension Emblems x20"] = { r = 0.4, g = 0.6, b = 0.9 },   -- Blue
    ["Ascension Emblems x15"] = { r = 0.5, g = 0.5, b = 0.85 },  -- Light blue (cheapest)

    -- Crafted (Green profession theme)
    ["Crafted"] = { r = 0.3, g = 0.75, b = 0.4 },                -- Profession green
    ["Profession"] = { r = 0.3, g = 0.75, b = 0.4 },

    -- Tokens (Light gold theme)
    ["Tokens"] = { r = 0.85, g = 0.8, b = 0.4 },                 -- Light gold
    ["Tier Tokens"] = { r = 0.85, g = 0.8, b = 0.4 },

    -- Dungeons (Blue-gray theme)
    ["Dungeon"] = { r = 0.5, g = 0.6, b = 0.75 },
    ["Heroic Dungeon"] = { r = 0.55, g = 0.55, b = 0.8 },

    -- Default
    ["Unknown"] = { r = 0.5, g = 0.5, b = 0.5 },
}

-- ============================================================
-- Pool of Header Frames
-- ============================================================

local headerPool = {}
local activeHeaders = {}

local function AcquireHeader(parent)
    local header = table.remove(headerPool)

    if not header then
        header = CreateFrame("Button", nil, parent)
        header:SetHeight(HEADER_HEIGHT)
        header:RegisterForClicks("LeftButtonUp")

        -- Background
        local bg = header:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        header._bg = bg

        -- Collapse indicator
        local indicator = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        indicator:SetPoint("LEFT", HEADER_PADDING, 0)
        indicator:SetWidth(COLLAPSE_INDICATOR_WIDTH)
        indicator:SetJustifyH("CENTER")
        indicator:SetText("+")  -- Default to collapsed state (ASCII plus sign)
        header._indicator = indicator

        -- Instance icon
        local icon = header:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", indicator, "RIGHT", 4, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        header._icon = icon

        -- Instance name
        local nameLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        nameLabel:SetJustifyH("LEFT")
        header._nameLabel = nameLabel

        -- Item count
        local countLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countLabel:SetPoint("RIGHT", -HEADER_PADDING, 0)
        countLabel:SetJustifyH("RIGHT")
        header._countLabel = countLabel

        -- Progress text
        local progressLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        progressLabel:SetPoint("RIGHT", countLabel, "LEFT", -12, 0)
        progressLabel:SetJustifyH("RIGHT")
        header._progressLabel = progressLabel

        -- Hover highlight
        local highlight = header:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
        highlight:SetVertexColor(1, 1, 1, 0.1)
        header._highlight = highlight

        -- Store data table
        header._data = {}
    else
        -- When reusing from pool, explicitly show all child elements
        -- (they were hidden when the parent header was hidden)
        if header._bg then header._bg:Show() end
        if header._indicator then header._indicator:Show() end
        if header._icon then header._icon:Show() end
        if header._nameLabel then header._nameLabel:Show() end
        if header._countLabel then header._countLabel:Show() end
        if header._progressLabel then header._progressLabel:Show() end
        -- Note: _highlight is HIGHLIGHT layer, shown automatically on hover
    end

    header:SetParent(parent)
    header:Show()
    table.insert(activeHeaders, header)
    header._activeIndex = #activeHeaders  -- Store index for O(1) removal

    return header
end

local function ReleaseHeader(header)
    if not header then return end

    header:Hide()
    header:ClearAllPoints()
    header:SetScript("OnClick", nil)
    header:SetScript("OnEnter", nil)
    header:SetScript("OnLeave", nil)

    -- Reset indicator to default (ASCII plus sign)
    if header._indicator then
        header._indicator:SetText("+")
    end

    if header._data then
        wipe(header._data)
    end

    -- Remove from active list using stored index (O(1) instead of O(n))
    local idx = header._activeIndex
    if idx and activeHeaders[idx] == header then
        local lastIdx = #activeHeaders
        if idx ~= lastIdx then
            -- Swap with last element
            local lastHeader = activeHeaders[lastIdx]
            activeHeaders[idx] = lastHeader
            lastHeader._activeIndex = idx
        end
        activeHeaders[lastIdx] = nil
    else
        -- Fallback: linear search (for safety)
        for i, h in ipairs(activeHeaders) do
            if h == header then
                local lastIdx = #activeHeaders
                if i ~= lastIdx then
                    local lastHeader = activeHeaders[lastIdx]
                    activeHeaders[i] = lastHeader
                    lastHeader._activeIndex = i
                end
                activeHeaders[lastIdx] = nil
                break
            end
        end
    end
    header._activeIndex = nil

    table.insert(headerPool, header)
end

function BistooltipInstanceHeader.ReleaseAll()
    for i = #activeHeaders, 1, -1 do
        ReleaseHeader(activeHeaders[i])
    end
    wipe(activeHeaders)
end

-- ============================================================
-- Create Instance Header
-- ============================================================

function BistooltipInstanceHeader.Create(parent, instanceData, yOffset)
    local header = AcquireHeader(parent)

    local instanceKey = instanceData.key or instanceData.name or "Unknown"
    local instanceName = instanceData.name or "Unknown Instance"
    local itemCount = instanceData.itemCount or 0
    local collectedCount = instanceData.collectedCount or 0
    local iconTexture = instanceData.icon

    -- Store data
    header._data.instanceKey = instanceKey
    header._data.instanceName = instanceName
    header._data.itemCount = itemCount

    -- Position - use FIXED width from Constants to prevent ElvUI interference
    -- CRITICAL: NEVER use parent:GetWidth() as parent may be inside wrong frame
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

    -- Use FIXED width matching table content (same as SlotRow)
    -- MAIN_FRAME_WIDTH (600) - padding (8) - scrollbar area (24) - extra margin (8) = 560
    -- This ensures header doesn't go under the scrollbar
    local fixedWidth = (Constants and Constants.UI and Constants.UI.MAIN_FRAME_WIDTH or 600) - 8 - 24 - 8
    header:SetWidth(fixedWidth)

    -- Get color for this instance (use pattern matching helper for flexibility)
    local color = GetInstanceColor(instanceName)

    -- Background color - brighter for vendor-mode groups
    local isVendorGroup = instanceData.isVendorGroup
    local colorMultiplier = isVendorGroup and 0.5 or 0.3  -- vendor groups are brighter
    header._bg:SetVertexColor(color.r * colorMultiplier, color.g * colorMultiplier, color.b * colorMultiplier, 0.95)

    -- Collapse state - use arrow icons for modern look
    local isCollapsed = State and State.IsInstanceCollapsed and State.IsInstanceCollapsed(instanceKey)
    header._indicator:SetText(isCollapsed and ARROW_COLLAPSED or ARROW_EXPANDED)
    header._indicator:SetTextColor(color.r, color.g, color.b, 1)

    -- Icon - use proper raid icons for each instance
    if iconTexture then
        header._icon:SetTexture(iconTexture)
        header._icon:Show()
    else
        local lowerName = instanceName:lower()
        local iconPath = nil

        -- Match instance names to icons (check more specific patterns first)
        -- Raids
        if lowerName:find("naxxramas") or lowerName:find("naxx") then
            iconPath = "Interface\\Icons\\Achievement_Dungeon_Naxxramas_Normal"
        elseif lowerName:find("obsidian") or lowerName:find("sartharion") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_ulduarraid_misc_03"
        elseif lowerName:find("eye") and lowerName:find("eternity") then
            iconPath = "Interface\\Icons\\Achievement_Dungeon_NexusRaid"
        elseif lowerName:find("malygos") then
            iconPath = "Interface\\Icons\\Achievement_Dungeon_NexusRaid"
        elseif lowerName:find("ulduar") then
            iconPath = "Interface\\Icons\\Achievement_Boss_Algalon_01"
        elseif lowerName:find("trial") or lowerName:find("crusader") then
            iconPath = "Interface\\Icons\\Achievement_reputation_argentchampion"
        elseif lowerName:find("icecrown") or lowerName:find("citadel") then
            iconPath = "Interface\\Icons\\Achievement_zone_icecrown_01"
        elseif lowerName:find("ruby") or lowerName:find("halion") or lowerName:find("sanctum") and lowerName:find("25") then
            iconPath = "Interface\\Icons\\inv_misc_head_dragon_red"
        -- WotLK Dungeons (use heroic dungeon icon as default)
        elseif lowerName:find("azjol") or lowerName:find("nerub") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_azjoluppercity_heroic"
        elseif lowerName:find("ahn'kahet") or lowerName:find("ahnkahet") or lowerName:find("old kingdom") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_azjollowercity_heroic"
        elseif lowerName:find("drak'tharon") or lowerName:find("draktharon") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_dloraktorkeep_heroic"
        elseif lowerName:find("gundrak") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_gundrak_heroic"
        elseif lowerName:find("halls of stone") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_ulduar80_heroic"
        elseif lowerName:find("halls of lightning") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_hallsoflightning_heroic"
        elseif lowerName:find("nexus") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_nexus80_heroic"
        elseif lowerName:find("oculus") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_nexus70_heroic"
        elseif lowerName:find("utgarde keep") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_utgardekeep_heroic"
        elseif lowerName:find("utgarde pinnacle") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_utgardepinnacle_heroic"
        elseif lowerName:find("violet hold") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_violethold_heroic"
        elseif lowerName:find("culling") or lowerName:find("stratholme") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_cotstratholme_heroic"
        elseif lowerName:find("trial of the champion") or lowerName:find("champion") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_theargentcoliseum_heroic"
        elseif lowerName:find("forge of souls") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_icecrown_forgeofsouls"
        elseif lowerName:find("pit of saron") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_icecrown_pitofsaron"
        elseif lowerName:find("halls of reflection") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_icecrown_hallsofreflection"
        elseif lowerName:find("dungeon") or lowerName:find("heroic") then
            iconPath = "Interface\\Icons\\Achievement_dungeon_heroic_gloryoftheraider"
        -- Emblems and currencies
        elseif lowerName:find("ascension") then
            iconPath = "Interface\\Icons\\Inv_misc_bone_skull_01"
        elseif lowerName:find("echo") and lowerName:find("titan") then
            iconPath = "Interface\\Icons\\Spell_Holy_SurgeOfLight"
        elseif lowerName:find("emblem") or lowerName:find("frost") or lowerName:find("triumph") or lowerName:find("valor") or lowerName:find("conquest") then
            iconPath = "Interface\\Icons\\INV_Misc_Token_ArgentDawn3"
        elseif lowerName:find("craft") or lowerName:find("profession") then
            iconPath = "Interface\\Icons\\Trade_BlackSmithing"
        elseif lowerName:find("token") then
            iconPath = "Interface\\Icons\\INV_Shoulder_22"
        end

        -- If no match, use dungeon icon as default (better than question mark)
        if not iconPath then
            if instanceData.emblemType then
                iconPath = "Interface\\Icons\\INV_Misc_Token_ArgentDawn3"
            else
                -- Default to dungeon icon for unrecognized instances
                iconPath = "Interface\\Icons\\Achievement_dungeon_heroic_gloryoftheraider"
            end
        end

        header._icon:SetTexture(iconPath)
        header._icon:Show()
    end

    -- Instance name with color
    header._nameLabel:SetText(string.format("|cff%02x%02x%02x%s|r",
        color.r * 255, color.g * 255, color.b * 255, instanceName))

    -- Item count / Emblem cost (for vendor groups)
    if instanceData.isVendorGroup and instanceData.totalEmblemCost and instanceData.totalEmblemCost > 0 then
        -- Show total emblem cost for vendor groups
        header._countLabel:SetText(string.format("|cff00ffcc%d Emblems|r", instanceData.totalEmblemCost))
    else
        header._countLabel:SetText(string.format("|cffaaaaaa%d items|r", itemCount))
    end

    -- Progress
    if itemCount > 0 then
        local pct = (collectedCount / itemCount) * 100
        local progressColor
        if pct >= 100 then
            progressColor = "00ff00"
        elseif pct >= 50 then
            progressColor = "ffff00"
        else
            progressColor = "ff8800"
        end
        header._progressLabel:SetText(string.format("|cff%s%d/%d (%.0f%%)|r",
            progressColor, collectedCount, itemCount, pct))
    else
        header._progressLabel:SetText("")
    end

    -- Click handler for collapse/expand
    header:SetScript("OnClick", function(self)
        if State and State.ToggleInstanceCollapse then
            State.ToggleInstanceCollapse(instanceKey)

            -- Trigger redraw
            if _G.BistooltipAddon and _G.BistooltipAddon.RefreshUI then
                _G.BistooltipAddon:RefreshUI()
            elseif _G.Bistooltip_RefreshUI then
                _G.Bistooltip_RefreshUI()
            end
        end
    end)

    -- Hover tooltip
    header:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(instanceName, color.r, color.g, color.b)
        GameTooltip:AddLine(string.format("Items: %d/%d collected", collectedCount, itemCount), 1, 1, 1)
        if isCollapsed then
            GameTooltip:AddLine("Click to expand", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Click to collapse", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    header:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return header, HEADER_HEIGHT + 2  -- Return height for layout calculation
end

-- ============================================================
-- Group Slots by Instance or Emblem Cost (for Ascension mode)
-- ============================================================

-- Caches for normalized instance names (avoid repeated string operations)
local normalizeFullCache = {}
local normalizeKeepSizeCache = {}
-- Note: instanceColorCache is declared at line 30

-- Helper: Normalize instance name for VENDOR mode (removes ALL size/difficulty)
local function NormalizeInstanceNameFull(instanceName)
    if not instanceName then return "Unknown" end

    -- Check cache first
    local cached = normalizeFullCache[instanceName]
    if cached then return cached end

    local name = instanceName
    -- Remove ALL difficulty and size suffixes for unified grouping
    name = name:gsub("%s*%(%d+%)%s*", "")      -- Remove (10), (25)
    name = name:gsub("%s*%d+%s*$", "")         -- Remove trailing numbers like "25"
    name = name:gsub("%s*HM%s*$", "")          -- Remove HM suffix
    name = name:gsub("%s*HC%s*$", "")          -- Remove HC suffix
    name = name:gsub("%s*NM%s*$", "")          -- Remove NM suffix
    name = name:gsub("%s*Normal%s*$", "")      -- Remove Normal suffix
    name = name:gsub("%s*Heroic%s*$", "")      -- Remove Heroic suffix
    name = name:gsub("%s*Hardmode%s*$", "")    -- Remove Hardmode suffix
    name = name:gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace

    -- Cache the result
    normalizeFullCache[instanceName] = name
    return name
end

-- Helper: Normalize instance name for BIS mode (removes difficulty but KEEPS raid size)
-- Result: "Icecrown Citadel (10)" or "Icecrown Citadel (25)"
-- Handles various formats:
--   "Icecrown Citadel (10)" -> "Icecrown Citadel (10)"
--   "Icecrown Citadel (10) (Heroic)" -> "Icecrown Citadel (10)"
--   "Ulduar (10)" -> "Ulduar (10)"
--   "Ulduar HM(10)" -> "Ulduar (10)"
--   "Trial of the Crusader (25) (Heroic)" -> "Trial of the Crusader (25)"
local function NormalizeInstanceNameKeepSize(instanceName)
    if not instanceName then return "Unknown" end

    -- Check cache first
    local cached = normalizeKeepSizeCache[instanceName]
    if cached then return cached end

    local name = instanceName

    -- Extract raid size from various patterns
    local raidSize = nil

    -- Pattern 1: "(10)" or "(25)" or "HM(10)" or "HM(25)"
    local size = name:match("HM%s*%((%d+)%)")    -- "Ulduar HM(10)" -> "10"
        or name:match("%s*%((%d+)%)")             -- "(10)" or "(25)"
        or name:match("(%d+)$")                   -- Trailing number

    if size == "10" or size == "25" then
        raidSize = size
    end

    -- Remove difficulty/heroic indicators (order matters!)
    name = name:gsub("%s*%(Heroic%)%s*", "")           -- Remove (Heroic)
    name = name:gsub("%s*%(Normal%)%s*", "")           -- Remove (Normal)
    name = name:gsub("%s*HM%s*%(%d+%)", "")            -- Remove "HM(10)" or "HM(25)"
    name = name:gsub("%s*HC%s*%(%d+%)", "")            -- Remove "HC(10)" or "HC(25)"
    name = name:gsub("%s*%(%d+%)%s*", "")              -- Remove remaining (10), (25)
    name = name:gsub("%s*%d+%s*$", "")                 -- Remove trailing numbers
    name = name:gsub("%s*HM%s*$", "")                  -- Remove trailing HM
    name = name:gsub("%s*HC%s*$", "")                  -- Remove trailing HC
    name = name:gsub("%s*NM%s*$", "")                  -- Remove trailing NM
    name = name:gsub("%s*Normal%s*$", "")              -- Remove trailing Normal
    name = name:gsub("%s*Heroic%s*$", "")              -- Remove trailing Heroic
    name = name:gsub("%s*Hardmode%s*$", "")            -- Remove trailing Hardmode
    name = name:gsub("^%s+", ""):gsub("%s+$", "")      -- Trim whitespace

    -- Re-add raid size if it was present
    if raidSize then
        name = name .. " (" .. raidSize .. ")"
    end

    -- Cache the result
    normalizeKeepSizeCache[instanceName] = name
    return name
end

-- Helper: Check if a currency/source is an emblem type (auto-detect)
local function IsEmblemSource(currency)
    if not currency then return false end
    local lower = currency:lower()
    return lower:find("emblem") or lower:find("badge") or lower:find("echo") or lower:find("titan")
end

function BistooltipInstanceHeader.GroupSlotsByInstance(slots, isHorde, vendorFilterMode)
    if not slots then return {} end

    local groups = {}
    local groupOrder = {}
    local totalEmblems = 0

    for _, slot in ipairs(slots) do
        local firstItemId = slot[1]
        if firstItemId and firstItemId > 0 then
            local groupKey = "Unknown"
            local groupName = "Unknown"
            local emblemCost = 0
            local emblemType = nil
            local isEmblemTypeGroup = false

            -- Check if it's from emblem vendor first
            if _G.BistooltipData and _G.BistooltipData.GetEmblemCost then
                local cost, currency = _G.BistooltipData.GetEmblemCost(firstItemId)
                if cost and currency then
                    emblemCost = cost
                    emblemType = currency
                end
            end

            -- VENDOR mode grouping: find the slot's FIRST vendor-purchasable
            -- item (any rank, not just rank 1) and group by its currency.
            -- A slot enters this mode only when it contains a vendor item
            -- (SlotHasVendorSource), but that item may sit below a raid
            -- rank-1 — grouping by slot[1]'s instance would leak raid items
            -- into VENDOR mode (owner-reported Trial of the Crusader bug).
            -- There is deliberately NO instance branch in VENDOR mode.
            if vendorFilterMode then
                local vendorCost, vendorCurrency
                if _G.BistooltipData and _G.BistooltipData.GetDisplayItemID and _G.BistooltipData.GetEmblemCost then
                    for _, iid in ipairs(slot) do
                        local id = _G.BistooltipData.GetDisplayItemID(iid, isHorde)
                        local cost, currency = _G.BistooltipData.GetEmblemCost(id)
                        if cost and currency then
                            vendorCost, vendorCurrency = cost, currency
                            break
                        end
                    end
                end
                if vendorCurrency then
                    groupKey = "emblem_" .. vendorCurrency
                    groupName = vendorCurrency
                    isEmblemTypeGroup = true
                    emblemType = vendorCurrency
                    -- Store the cost on the slot for later sorting and use it
                    -- for the group totals (rank-1 may not be the vendor item)
                    slot._emblemCost = vendorCost
                    emblemCost = vendorCost
                else
                    -- Defensive: no vendor item found (filter should prevent
                    -- this). Keep the slot visible under Unknown instead of
                    -- silently hiding it.
                    groupKey = "emblem_Unknown"
                    groupName = "Unknown vendor"
                end
            else
                -- Normal BIS mode: group by raid size (10/25) but not difficulty (Normal/Heroic)
                if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
                    local zone, boss = _G.BistooltipAddon:GetItemSourceInfo(firstItemId)
                    if zone and zone ~= "" then
                        local normalizedZone = NormalizeInstanceNameKeepSize(zone)
                        groupKey = normalizedZone
                        groupName = normalizedZone
                    end
                end

                -- If no instance found but has emblem, use emblem type
                if groupKey == "Unknown" and emblemType then
                    groupKey = emblemType
                    groupName = emblemType
                end
            end

            -- Create group if not exists
            if not groups[groupKey] then
                groups[groupKey] = {
                    name = groupName,
                    key = groupKey,
                    slots = {},
                    itemCount = 0,
                    collectedCount = 0,
                    totalEmblemCost = 0,
                    emblemType = emblemType,
                    isVendorGroup = isEmblemTypeGroup,
                    isEmblemTypeGroup = isEmblemTypeGroup,
                }
                table.insert(groupOrder, groupKey)
            end

            -- Add slot to group
            table.insert(groups[groupKey].slots, slot)
            groups[groupKey].itemCount = groups[groupKey].itemCount + 1

            -- Track emblem cost for vendor groups
            if emblemCost > 0 then
                groups[groupKey].totalEmblemCost = (groups[groupKey].totalEmblemCost or 0) + emblemCost
                totalEmblems = totalEmblems + emblemCost
            end

            -- Check if collected
            if _G.BistooltipData and _G.BistooltipData.IsSlotBISCompleted then
                if _G.BistooltipData.IsSlotBISCompleted(slot) then
                    groups[groupKey].collectedCount = groups[groupKey].collectedCount + 1
                end
            end
        end
    end

    -- Sort groups by priority (dynamic for VENDOR mode)
    local function GetGroupPriority(key)
        -- Emblem/vendor groups first (priority 100)
        if key:find("^emblem_") then
            return 100
        end

        -- Instance groups second (sorted alphabetically)
        if key:find("^instance_") then
            return 300
        end

        -- For normal BIS mode, use static priority
        local tierPriority = {
            -- Raid instances first (highest tier to lowest)
            ["Icecrown Citadel"] = 1,
            ["ICC 25 Heroic"] = 2, ["ICC 25 Normal"] = 3, ["ICC 10 Heroic"] = 4, ["ICC 10 Normal"] = 5,
            ["Ruby Sanctum"] = 6,
            ["Trial of the Crusader"] = 7, ["ToC 25 Heroic"] = 8, ["ToC 25 Normal"] = 9,
            ["Ulduar"] = 10,
            ["Naxxramas"] = 11,
            ["Eye of Eternity"] = 12,
            ["Obsidian Sanctum"] = 13,
            -- Emblems after raids
            ["Emblem of Frost"] = 20, ["Emblem of Triumph"] = 21, ["Emblem of Conquest"] = 22,
            ["Emblem of Valor"] = 23, ["Emblem of Heroism"] = 24, ["Emblem of Ascension"] = 25,
            ["Echo of the Titans"] = 26,
            ["Crafted"] = 50,
            ["Dungeon"] = 51,
        }
        return tierPriority[key] or 500
    end

    table.sort(groupOrder, function(a, b)
        local prioA = GetGroupPriority(a)
        local prioB = GetGroupPriority(b)
        if prioA ~= prioB then
            return prioA < prioB
        end
        -- Secondary sort: alphabetically by display name
        local nameA = groups[a] and groups[a].name or a
        local nameB = groups[b] and groups[b].name or b
        return nameA < nameB
    end)

    -- Store total emblems needed for display
    _G.Bistooltip_totalEmblemsNeeded = totalEmblems

    -- Helper: Check if an item comes from a heroic source
    -- (MUST return a real boolean — sort comparators choke on nil,
    -- which crashed grouping when vendor items had no raid zone.)
    local function IsHeroicSource(slot)
        if not slot or not slot[1] then return false end
        local itemId = slot[1]
        if _G.BistooltipAddon and _G.BistooltipAddon.GetItemSourceInfo then
            local zone, boss = _G.BistooltipAddon:GetItemSourceInfo(itemId)
            if zone then
                local lowerZone = zone:lower()
                return (lowerZone:find("heroic") or lowerZone:find("hm") or lowerZone:find("hc")) ~= nil
            end
        end
        return false
    end

    -- Sort slots within each group
    for key, group in pairs(groups) do
        if group.slots and #group.slots > 1 then
            -- For Emblem of Ascension group: sort by emblem cost (highest first)
            if key == "emblem_Emblem of Ascension" then
                table.sort(group.slots, function(a, b)
                    local costA = a._emblemCost or 0
                    local costB = b._emblemCost or 0
                    if costA ~= costB then
                        return costA > costB  -- Higher cost first
                    end
                    return (a.slot_name or "") < (b.slot_name or "")
                end)
            else
                -- For other groups: Heroic items first, then Normal
                table.sort(group.slots, function(a, b)
                    local aHeroic = IsHeroicSource(a) == true
                    local bHeroic = IsHeroicSource(b) == true
                    if aHeroic ~= bHeroic then
                        return aHeroic  -- Heroic items come first
                    end
                    return (a.slot_name or "") < (b.slot_name or "")
                end)
            end
        end
    end

    -- Build ordered result
    local result = {}
    for _, key in ipairs(groupOrder) do
        table.insert(result, groups[key])
    end

    return result
end

-- ============================================================
-- Get Header Height (for layout calculations)
-- ============================================================

function BistooltipInstanceHeader.GetHeight()
    return HEADER_HEIGHT + 2
end

-- Module loaded
-- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Bistooltip:|r InstanceHeader module loaded")
