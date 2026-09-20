-- ============================================================
-- Config.lua - Settings and configuration for BisTooltip
-- ============================================================

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)

-- ============================================================
-- Local State
-- ============================================================

local icon_loaded = false
local icon_name = "BisTooltipIcon"

-- ============================================================
-- Data Sources
-- ============================================================

local sources = {
    wowsims = "wowsims",
    wowtbc = "wowtbc",
    wh = "wh",
}

Bistooltip_source_to_url = {
    ["wowsims"] = "WoWSimsBP (STANDARD)",
    ["wowtbc"] = "wowtbc.gg",
    ["wh"] = "Wowhead (wh)" -- wh = Wowhead WotLK ranking (census: no data-level Whitemane link),
}

-- ============================================================
-- Database Defaults
-- ============================================================

local db_defaults = {
    -- Account-wide (W4 §12): database choice and personal BiS priorities
    -- are shared across characters; UI-only preferences stay per-char.
    global = {
        data_source = "wowsims",
        custom_priorities = {},
        custom_enhancements = {},
    },
    char = {
        -- Selection state
        class_index = 1,
        spec_index = 1,
        phase_index = 1,

        -- Filtering
        filter_specs = {},
        highlight_spec = {},
        filter_class_names = true,
        show_item_source = true,
        show_source_column = true,

        -- UI preferences
        minimap_icon = true,
        tooltip_with_ctrl = false,
        bis_checklist = false,
        gem_detailed = false,
        enchant_detailed = false,
        
        -- Version for migrations
        version = nil,
        
        -- Debug mode
        debug_mode = false,
    }
}

-- Editor state is intentionally transient; saved assignments live in
-- db.global.custom_enhancements and are scoped to the selected database.
local enchantEditor = { kind = "item", id = "" }

local function EditorChoices(level)
    local choices = {}
    local lists = _G.Bistooltip_bislists or {}
    if level == "class" then
        for name in pairs(lists) do choices[name] = name end
        return choices
    end
    local className = enchantEditor.class
    if not className or not lists[className] then className = next(lists) end
    enchantEditor.class = className
    local specs = className and lists[className] or {}
    if level == "spec" then
        for name in pairs(specs) do choices[name] = name end
        return choices
    end
    local specName = enchantEditor.spec
    if not specName or not specs[specName] then specName = next(specs) end
    enchantEditor.spec = specName
    local phases = specName and specs[specName] or {}
    if level == "phase" then
        for name in pairs(phases) do choices[name] = name end
        return choices
    end
    local phase = enchantEditor.phase
    if not phase or not phases[phase] then phase = next(phases) end
    enchantEditor.phase = phase
    local slots = phase and phases[phase] or {}
    for _, slot in ipairs(slots) do
        if slot.slot_name then choices[slot.slot_name] = slot.slot_name end
    end
    return choices
end

local function EditorTarget()
    local choices = EditorChoices("slot")
    if not enchantEditor.slot or not choices[enchantEditor.slot] then
        enchantEditor.slot = next(choices)
    end
    return enchantEditor.class, enchantEditor.spec, enchantEditor.phase, enchantEditor.slot
end

local function EditorBaseSlot()
    local className, specName, phase, slotName = EditorTarget()
    local slots = _G.Bistooltip_bislists and _G.Bistooltip_bislists[className]
    slots = slots and slots[specName]
    slots = slots and slots[phase]
    for _, slot in ipairs(slots or {}) do
        if slot.slot_name == slotName then return slot end
    end
    return nil
end

local function EditorPreview()
    local className, specName, phase, slotName = EditorTarget()
    if not slotName then return "No slot is available in this database." end
    local base = EditorBaseSlot()
    local old = base and base.enhs and base.enhs[1]
    local current = BistooltipData.GetCustomEnhancement(className, specName, phase, slotName)
    local id = tonumber(enchantEditor.id)
    local lines = {
        "Current first entry: " .. (old and (old.type .. ":" .. old.id) or "none"),
        "Personal assignment: " .. (current and (current.type .. ":" .. current.id) or "none"),
    }
    if not id or id <= 0 or id % 1 ~= 0 then
        lines[#lines + 1] = "Enter a positive whole-number item or spell ID to preview."
    else
        local name
        if enchantEditor.kind == "item" and type(GetItemInfo) == "function" then
            name = GetItemInfo(id)
        elseif enchantEditor.kind == "spell" and type(GetSpellInfo) == "function" then
            name = GetSpellInfo(id)
        end
        lines[#lines + 1] = "New first entry: " .. enchantEditor.kind .. ":" .. id
            .. " (" .. (name or "name not cached/available") .. ")"
        if enchantEditor.kind == "item" and BistooltipData.GetAllItemSources then
            local sources = BistooltipData.GetAllItemSources(id)
            if #sources == 0 then
                lines[#lines + 1] = "No recorded acquisition or price for this item."
            else
                for i = 1, math.min(#sources, 3) do
                    lines[#lines + 1] = sources[i].text
                end
                if #sources > 3 then lines[#lines + 1] = "+ " .. (#sources - 3) .. " more sources" end
            end
        end
        local entries = {}
        entries[1] = string.format('{type=%q,id=%d}', enchantEditor.kind, id)
        for i = 2, #(base and base.enhs or {}) do
            local entry = base.enhs[i]
            entries[#entries + 1] = string.format('{type=%q,id=%d}', entry.type, entry.id)
        end
        lines[#lines + 1] = "Plugin preview: BisTooltip:SetEnhancement(" .. string.format("%q,%q,%q,%q", className, specName, phase, slotName)
            .. ", {" .. table.concat(entries, ", ") .. "})"
    end
    lines[#lines + 1] = "The game item API cannot confirm enchant-to-slot compatibility; verify the scroll in game."
    if enchantEditor.message then lines[#lines + 1] = enchantEditor.message end
    return table.concat(lines, "\n")
end

-- ============================================================
-- Configuration Table
-- ============================================================

local configTable = {
    type = "group",
    name = "Bis-Tooltip",
    args = {
        header_general = {
            name = "General Settings",
            order = 0,
            type = "header",
        },
        minimap_icon = {
            name = "Show minimap icon",
            order = 1,
            desc = "Shows/hides minimap icon",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.minimap_icon = val
                if val == true then
                    if icon_loaded == true then
                        LDBIcon:Show(icon_name)
                    else
                        BistooltipAddon:addMapIcon()
                    end
                else
                    if LDBIcon then
                        LDBIcon:Hide(icon_name)
                    end
                end
            end,
            get = function(info)
                return BistooltipAddon.db.char.minimap_icon
            end
        },
        filter_class_names = {
            name = "Hide class names in tooltips",
            order = 2,
            desc = "Removes class name separators from item tooltips",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.filter_class_names = val
            end,
            get = function(info)
                return BistooltipAddon.db.char.filter_class_names
            end
        },
        show_item_source = {
            name = "Show item source in tooltips",
            order = 2.5,
            desc = "Shows where items drop from (boss, zone, emblems, etc.)",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.show_item_source = val
            end,
            get = function(info)
                return BistooltipAddon.db.char.show_item_source
            end
        },
        show_source_column = {
            name = "Show SOURCE column in BIS window",
            order = 2.6,
            desc = "Show the dedicated source column in BIS mode, independently of tooltip sources",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.show_source_column = val
                if BistooltipAddon.RefreshUI then
                    BistooltipAddon:RefreshUI()
                end
            end,
            get = function(info)
                return BistooltipAddon.db.char.show_source_column
            end
        },
        tooltip_with_ctrl = {
            name = "Show BIS info only with Ctrl",
            order = 3,
            desc = "Show BIS information in item tooltips only when holding Ctrl key",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.tooltip_with_ctrl = val
            end,
            get = function(info)
                return BistooltipAddon.db.char.tooltip_with_ctrl
            end
        },
        gem_detailed = {
            name = "Show gem stats in BIS list",
            order = 4,
            desc = "Display shortened stat bonuses below gem icons (e.g., +20 STR, +16 Crit)",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.gem_detailed = val
                if BistooltipAddon.reloadData then
                    BistooltipAddon:reloadData()
                end
            end,
            get = function(info)
                return BistooltipAddon.db.char.gem_detailed
            end
        },
        enchant_detailed = {
            name = "Show enchant names in BIS list",
            order = 5,
            desc = "Display enchant name below item icon (e.g., Gloves: Crusher)",
            type = "toggle",
            width = "full",
            set = function(info, val)
                BistooltipAddon.db.char.enchant_detailed = val
                if BistooltipAddon.reloadData then
                    BistooltipAddon:reloadData()
                end
            end,
            get = function(info)
                return BistooltipAddon.db.char.enchant_detailed
            end
        },
        header_data = {
            name = "Data Source",
            order = 10,
            type = "header",
        },
        data_source = {
            name = "Data source",
            order = 11,
            desc = "Changes BIS data source",
            type = "select",
            style = "dropdown",
            width = "double",
            values = Bistooltip_source_to_url,
            -- FIXED: select type uses (info, value) not (info, key, val)
            set = function(info, value)
                BistooltipAddon.db.global.data_source = value
                BistooltipAddon:changeSpec(value)
                enchantEditor.class, enchantEditor.spec, enchantEditor.phase, enchantEditor.slot = nil, nil, nil, nil
                enchantEditor.id = ""
                enchantEditor.message = nil
            end,
            -- FIXED: select type uses (info) not (info, key)
            get = function(info)
                return BistooltipAddon.db.global.data_source
            end
        },
        enchant_editor = {
            type = "group",
            name = "Enchant editor",
            order = 15,
            args = {
                intro = { type = "description", order = 1, name = "Assign an item scroll or spell to one exact database/class/spec/phase/slot. The first enhancement entry is replaced; later entries, including gems, are preserved. Assignments are account-wide and can be reset here.", width = "full" },
                class = { type = "select", name = "Class", order = 2, values = function() return EditorChoices("class") end,
                    get = function() EditorTarget(); return enchantEditor.class end,
                    set = function(_, value) enchantEditor.class = value; enchantEditor.spec, enchantEditor.phase, enchantEditor.slot = nil, nil, nil; enchantEditor.id = ""; enchantEditor.message = nil end },
                spec = { type = "select", name = "Spec", order = 3, values = function() return EditorChoices("spec") end,
                    get = function() EditorTarget(); return enchantEditor.spec end,
                    set = function(_, value) enchantEditor.spec = value; enchantEditor.phase, enchantEditor.slot = nil, nil; enchantEditor.id = ""; enchantEditor.message = nil end },
                phase = { type = "select", name = "Phase", order = 4, values = function() return EditorChoices("phase") end,
                    get = function() EditorTarget(); return enchantEditor.phase end,
                    set = function(_, value) enchantEditor.phase = value; enchantEditor.slot = nil; enchantEditor.id = ""; enchantEditor.message = nil end },
                slot = { type = "select", name = "Slot", order = 5, values = function() return EditorChoices("slot") end,
                    get = function() EditorTarget(); return enchantEditor.slot end,
                    set = function(_, value) enchantEditor.slot = value; enchantEditor.id = ""; enchantEditor.message = nil end },
                kind = { type = "select", name = "Type", order = 6, values = { item = "Item / scroll", spell = "Spell" },
                    get = function() return enchantEditor.kind end,
                    set = function(_, value) enchantEditor.kind = value; enchantEditor.message = nil end },
                id = { type = "input", name = "Item or spell ID", order = 7,
                    get = function() return enchantEditor.id end,
                    set = function(_, value) enchantEditor.id = value; enchantEditor.message = nil end },
                preview = { type = "description", name = EditorPreview, order = 8, width = "full" },
                save = { type = "execute", name = "Save assignment", order = 9,
                    disabled = function()
                        local id = tonumber(enchantEditor.id)
                        local _, _, _, slotName = EditorTarget()
                        return not slotName or not id or id <= 0 or id % 1 ~= 0
                    end,
                    confirm = function()
                        local base = EditorBaseSlot()
                        local className, specName, phase, slotName = EditorTarget()
                        if (base and base.enhs and base.enhs[1])
                                or BistooltipData.GetCustomEnhancement(className, specName, phase, slotName) then
                            return "Replace the first enhancement entry for this exact slot? Later entries are preserved."
                        end
                        return false
                    end,
                    func = function()
                        local className, specName, phase, slotName = EditorTarget()
                        local ok, err = BistooltipData.SaveCustomEnhancement(className, specName, phase, slotName,
                            enchantEditor.kind, tonumber(enchantEditor.id))
                        enchantEditor.message = ok and "Assignment saved." or err
                        if ok and BistooltipAddon.RefreshUI then BistooltipAddon:RefreshUI() end
                    end },
                reset = { type = "execute", name = "Reset this slot", order = 10,
                    disabled = function()
                        local className, specName, phase, slotName = EditorTarget()
                        return not BistooltipData.GetCustomEnhancement(className, specName, phase, slotName)
                    end,
                    func = function()
                        local className, specName, phase, slotName = EditorTarget()
                        BistooltipData.ResetCustomEnhancement(className, specName, phase, slotName)
                        enchantEditor.message = "Dataset/plugin enhancement restored."
                        if BistooltipAddon.RefreshUI then BistooltipAddon:RefreshUI() end
                    end },
            },
        },
        header_filter = {
            name = "Spec Filtering",
            order = 20,
            type = "header",
        },
        filter_specs = {
            name = "Show specs in tooltips",
            order = 21,
            desc = "Select which specs to show in item tooltips (unchecked = hidden)",
            type = "multiselect",
            values = {}, -- Populated dynamically
            set = function(info, key, val)
                local ci, si = strsplit(":", key)
                ci = tonumber(ci)
                si = tonumber(si)
                
                if not Bistooltip_classes or not Bistooltip_classes[ci] then return end
                
                local class_name = Bistooltip_classes[ci].name
                local spec_name = Bistooltip_classes[ci].specs[si]
                
                if not class_name or not spec_name then return end
                
                if not BistooltipAddon.db.char.filter_specs[class_name] then
                    BistooltipAddon.db.char.filter_specs[class_name] = {}
                end
                BistooltipAddon.db.char.filter_specs[class_name][spec_name] = val
            end,
            get = function(info, key)
                local ci, si = strsplit(":", key)
                ci = tonumber(ci)
                si = tonumber(si)
                
                if not Bistooltip_classes or not Bistooltip_classes[ci] then return true end
                
                local class_name = Bistooltip_classes[ci].name
                local spec_name = Bistooltip_classes[ci].specs and Bistooltip_classes[ci].specs[si]
                
                if not class_name or not spec_name then return true end
                
                if not BistooltipAddon.db.char.filter_specs[class_name] then
                    BistooltipAddon.db.char.filter_specs[class_name] = {}
                end
                if BistooltipAddon.db.char.filter_specs[class_name][spec_name] == nil then
                    BistooltipAddon.db.char.filter_specs[class_name][spec_name] = true
                end
                return BistooltipAddon.db.char.filter_specs[class_name][spec_name]
            end
        },
        header_highlight = {
            name = "Spec Highlighting",
            order = 30,
            type = "header",
        },
        highlight_spec = {
            name = "Highlight spec",
            order = 31,
            desc = "Highlights selected spec in item tooltips (select only one)",
            type = "multiselect",
            values = {}, -- Populated dynamically
            set = function(info, key, val)
                if val then
                    local ci, si = strsplit(":", key)
                    ci = tonumber(ci)
                    si = tonumber(si)
                    
                    if not Bistooltip_classes or not Bistooltip_classes[ci] then return end
                    
                    local class_name = Bistooltip_classes[ci].name
                    local spec_name = Bistooltip_classes[ci].specs and Bistooltip_classes[ci].specs[si]
                    
                    if class_name and spec_name then
                        BistooltipAddon.db.char.highlight_spec = {
                            key = key,
                            class_name = class_name,
                            spec_name = spec_name
                        }
                    end
                else
                    BistooltipAddon.db.char.highlight_spec = {}
                end
            end,
            get = function(info, key)
                return BistooltipAddon.db.char.highlight_spec.key == key
            end
        }
    }
}

-- ============================================================
-- Build Filter/Highlight Options
-- ============================================================

local function BuildFilterSpecOptions()
    local filter_specs_options = {}
    
    if not Bistooltip_classes or type(Bistooltip_classes) ~= "table" then
        return
    end
    
    for ci, class in ipairs(Bistooltip_classes) do
        if class and class.name and class.specs then
            for si, spec in ipairs(class.specs) do
                -- Get spec icon if available
                local icon = nil
                if Bistooltip_spec_icons and Bistooltip_spec_icons[class.name] then
                    icon = Bistooltip_spec_icons[class.name][spec]
                end
                
                local option_val
                if icon then
                    option_val = "|T" .. icon .. ":16|t " .. class.name .. " " .. spec
                else
                    option_val = class.name .. " " .. spec
                end
                
                local option_key = ci .. ":" .. si
                filter_specs_options[option_key] = option_val
            end
        end
    end
    
    configTable.args.filter_specs.values = filter_specs_options
    configTable.args.highlight_spec.values = filter_specs_options
end

-- ============================================================
-- Source Selection Dialog (first-time setup)
-- ============================================================

local function OpenSourceSelectDialog()
    local frame = AceGUI:Create("Window")
    frame:SetWidth(300)
    frame:SetHeight(150)
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
    frame:SetLayout("List")
    frame:SetTitle(BistooltipAddon.AddonNameAndVersion)

    local labelEmpty = AceGUI:Create("Label")
    labelEmpty:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    labelEmpty:SetText(" ")
    frame:AddChild(labelEmpty)

    local label = AceGUI:Create("Label")
    label:SetText("Please select a BIS data source to be used for this addon:")
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetRelativeWidth(1)
    frame:AddChild(label)

    local labelEmpty2 = AceGUI:Create("Label")
    labelEmpty2:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    labelEmpty2:SetText(" ")
    frame:AddChild(labelEmpty2)

    local sourceDropdown = AceGUI:Create("Dropdown")
    sourceDropdown:SetCallback("OnValueChanged", function(_, _, key)
        BistooltipAddon.db.global.data_source = key
        BistooltipAddon:changeSpec(key)
    end)
    sourceDropdown:SetRelativeWidth(1)
    sourceDropdown:SetList(Bistooltip_source_to_url)
    sourceDropdown:SetValue(BistooltipAddon.db.global.data_source)
    frame:AddChild(sourceDropdown)
end

-- ============================================================
-- Database Migration
-- ============================================================

local function MigrateAddonDB()
    local db = BistooltipAddon.db.char

    -- W4 (§12): account-wide migration — one-time copy of the old
    -- per-character values into db.global; char copies stay dormant.
    local gdb = BistooltipAddon.db.global
    if not gdb.account_state_migrated then
        if db.data_source ~= nil and gdb.data_source == "wowsims"
            and db.data_source ~= "wowsims" then
            gdb.data_source = db.data_source
        end
        if type(db.custom_priorities) == "table" then
            gdb.custom_priorities = gdb.custom_priorities or {}
            for k, v in pairs(db.custom_priorities) do
                if gdb.custom_priorities[k] == nil then gdb.custom_priorities[k] = v end
            end
        end
        gdb.account_state_migrated = true
    end

    -- Initial migration
    if not db.version then
        db.version = 6.1
        db.highlight_spec = {}
        db.filter_specs = {}
        db.class_index = 1
        db.spec_index = 1
        db.phase_index = 1
    end

    -- Set default data source if not set
    if db.data_source == nil then
        db.data_source = "wowsims"
    end

    -- Version 6.1 -> 6.2 migration
    if db.version == 6.1 then
        db.version = 6.2
        if db.filter_specs["Death knight"] and
           db.filter_specs["Death knight"]["Blood dps"] == nil then
            db.filter_specs["Death knight"]["Blood dps"] = true
        end
    end
    
    -- Version 6.2 -> 6.3 migration (new features)
    if db.version == 6.2 then
        db.version = 6.3
        if db.bis_checklist == nil then
            db.bis_checklist = false
        end
    end
end

-- ============================================================
-- Enable Data Source
-- ============================================================

-- Each bind starts from pristine database slots. Plugin replay and saved
-- personal priorities supply the two mutable layers on top of that baseline.
local function CopySlot(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = CopySlot(v) end
    return copy
end

local function FreshBind(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for className, specs in pairs(src) do
        out[className] = {}
        for specName, phases in pairs(specs) do
            out[className][specName] = {}
            for phaseName, list in pairs(phases) do
                local arr = {}
                for i, slot in ipairs(list) do arr[i] = CopySlot(slot) end
                -- Mutation trap (row-duplication hunt): after bind these
                -- arrays should only be index-READ; any NEW key written
                -- (e.g. an appended duplicate Weapon/Off hand) logs the
                -- exact source line that did it via debugstack.
                local label = className .. "/" .. specName .. "/" .. phaseName
                local seenSites = {}
                setmetatable(arr, {
                    __newindex = function(t, k, v)
                        local site = "?"
                        if type(debugstack) == "function" then
                            site = tostring(debugstack(2, 2, 1) or "?"):gsub("\n", " ")
                        end
                        if not seenSites[site] then
                            seenSites[site] = true
                            if DEFAULT_CHAT_FRAME then
                                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Bis-MUTATE]|r " .. label
                                    .. " [" .. tostring(k) .. "] = " .. tostring(v and v.slot_name or type(v))
                                    .. " @ " .. site)
                            end
                        end
                        rawset(t, k, v)
                    end,
                })
                out[className][specName][phaseName] = arr
            end
        end
    end
    return out
end

local function EnableSpec(spec_name)
    -- W4 DB registry (spec §4): wowsims = assembled STANDARD (alliance base
    -- + horde slot overrides via reference swaps); wowtbc / wh = plain alias.
    -- Unknown keys fall back to the STANDARD.
    local key = sources[spec_name] and spec_name or "wowsims"
    if key == "wowsims" then
        Bistooltip_bislists = FreshBind(Bistooltip_wowsims_final)
        Bistooltip_classes = Bistooltip_wowsims_final_classes
        Bistooltip_phases = Bistooltip_wowsims_final_phases
        if type(Bistooltip_wowsims_horde_overrides) == "table"
            and type(UnitFactionGroup) == "function"
            and UnitFactionGroup("player") == "Horde" then
            for className, specs in pairs(Bistooltip_wowsims_horde_overrides) do
                local classData = Bistooltip_bislists[className]
                if type(classData) == "table" then
                    for specName, phases in pairs(specs) do
                        local specData = classData[specName]
                        if type(specData) == "table" then
                            for phaseName, idxMap in pairs(phases) do
                                local phaseList = specData[phaseName]
                                if type(phaseList) == "table" then
                                    for idx, slot in pairs(idxMap) do
                                        phaseList[idx] = CopySlot(slot)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif key == "wh" then
        Bistooltip_bislists = FreshBind(Bistooltip_wh_bislists)
        Bistooltip_classes = Bistooltip_wh_classes
        Bistooltip_phases = Bistooltip_wh_phases
    else -- wowtbc
        Bistooltip_bislists = FreshBind(Bistooltip_wowtbc_bislists)
        Bistooltip_classes = Bistooltip_wowtbc_classes
        Bistooltip_phases = Bistooltip_wowtbc_phases
    end

    -- Check if Bistooltip_phases is nil or not a table
    if type(Bistooltip_phases) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Bis-Tooltip:|r Phase data not loaded. Check addon files.")
        return
    end

    -- W4 overlay replay: server plugins describe the SERVER, not a ranking
    -- DB — their mutations follow the user across database switches
    -- (warn-once skips for slots missing in the new DB).
    if type(BisTooltip_ReplayOverlay) == "function" then
        BisTooltip_ReplayOverlay()
    end

    BuildFilterSpecOptions()
end

-- ============================================================
-- Config Dialog
-- ============================================================

function BistooltipAddon:openConfigDialog()
    -- Hide main addon frame while options are open
    local mainFrame = _G["BistooltipMainFrame"]
    local shadowFrame = _G["BistooltipMainShadow"]
    if mainFrame then mainFrame:Hide() end
    if shadowFrame then shadowFrame:Hide() end

    -- Always open to addon category (fixes race condition when window closed via ESC)
    InterfaceOptionsFrame_OpenToCategory(self.AceAddonName)
    -- Call twice to ensure proper category selection (WoW bug workaround)
    InterfaceOptionsFrame_OpenToCategory(self.AceAddonName)

    -- Hook to show main frame when options are closed
    if InterfaceOptionsFrame and not InterfaceOptionsFrame._bistooltipHooked then
        InterfaceOptionsFrame:HookScript("OnHide", function()
            local mf = _G["BistooltipMainFrame"]
            local sf = _G["BistooltipMainShadow"]
            if mf then mf:Show() end
            if sf then sf:Show() end
        end)
        InterfaceOptionsFrame._bistooltipHooked = true
    end
end

-- ============================================================
-- Minimap Icon
-- ============================================================

function BistooltipAddon:addMapIcon()
    if not self.db.char.minimap_icon then return end
    if icon_loaded then return end
    
    icon_loaded = true
    
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
    
    if not LDB then return end
    
    local PC_MinimapBtn = LDB:NewDataObject(icon_name, {
        type = "launcher",
        text = icon_name,
        icon = "interface/icons/inv_weapon_glave_01.blp",
        OnClick = function(_, button)
            if button == "LeftButton" then
                BistooltipAddon:createMainFrame()
            elseif button == "RightButton" then
                BistooltipAddon:openConfigDialog()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(BistooltipAddon.AddonNameAndVersion)
            tt:AddLine("|cffffff00Left click|r to open the BiS lists window")
            tt:AddLine("|cffffff00Right click|r to open addon configuration window")
        end
    })
    
    if LDBIcon then
        LDBIcon:Register(icon_name, PC_MinimapBtn, self.db.char)
    end
end

-- ============================================================
-- Change Data Source
-- ============================================================

function BistooltipAddon:changeSpec(spec_name)
    -- W4 (owner feedback 2026-09-10): keep the LAST VIEWED profile across a
    -- database switch, resolved BY NAME against the new database (indices
    -- are database-relative; specs/phases differ between bases).
    local D = _G.BistooltipData
    local className, specName, phaseName
    if D and D.GetClassList then
        local ci = D.GetClassList()[self.db.char.class_index]
        className = ci and ci.name or nil
        if className and D.GetSpecsForClass then
            local specs = D.GetSpecsForClass(className)
            specName = specs and specs[self.db.char.spec_index] or nil
        end
    end
    if type(_G.Bistooltip_phases) == "table" then
        phaseName = _G.Bistooltip_phases[self.db.char.phase_index] or nil
    end

    -- Personal-BiS order caches are keyed to the previously bound database
    -- (ID reconciliation re-applies the saved order on read)
    if BistooltipData and BistooltipData.ResetCustomPriorityCaches then
        BistooltipData.ResetCustomPriorityCaches()
    end

    -- Enable new data source (binds aliases + replays the plugin overlay)
    EnableSpec(spec_name)

    -- Re-resolve the remembered profile in the new database (fallback 1/1/1)
    self.db.char.class_index = 1
    self.db.char.spec_index = 1
    self.db.char.phase_index = 1
    if className and D and D.GetClassList then
        for i, cls in ipairs(D.GetClassList() or {}) do
            if cls.name == className then
                self.db.char.class_index = i
                if specName and D.GetSpecsForClass then
                    for j, sn in ipairs(D.GetSpecsForClass(cls.name) or {}) do
                        if sn == specName then self.db.char.spec_index = j break end
                    end
                end
                break
            end
        end
    end
    if phaseName and type(_G.Bistooltip_phases) == "table" then
        for k, pn in ipairs(_G.Bistooltip_phases) do
            if pn == phaseName then self.db.char.phase_index = k break end
        end
    end
    
    -- Clear caches
    if self.ClearSourceCache then
        self:ClearSourceCache()
    end
    if self.ClearTooltipCache then
        self:ClearTooltipCache()
    end

    -- Reinitialize
    if self.initBislists then
        self:initBislists()
    end
    if self.reloadData then
        self:reloadData()
    end
end

-- ============================================================
-- Initialize Configuration
-- ============================================================

function BistooltipAddon:initConfig()
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("BisTooltipDB", db_defaults, "Default")

    -- Run migrations
    MigrateAddonDB()

    -- Enable current data source
    EnableSpec(self.db.global.data_source)

    -- Build filter options
    BuildFilterSpecOptions()

    -- Register with Ace3 config
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.AceAddonName, configTable)
    AceConfigDialog:AddToBlizOptions(self.AceAddonName, self.AceAddonName)
end
