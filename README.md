# Bis-Tooltip

A World of Warcraft 3.3.5a (WotLK) addon that displays Best-in-Slot (BiS) information in item tooltips and provides a comprehensive BiS checklist UI.
> **Bistooltip 3.0.0 (META-Z)** — rebuilt data model: 3 selectable ranking databases (WoWSimsBP STANDARD / wowtbc / Wowhead), MASTER source format with colors (per-boss TOKEN/MARK, TOC/TOGC, VoA, HC/HM), VENDOR mode, server plugins (Whitemane:Frostmourne, WOTLK5_S2), standalone vendor Scanner, account-wide personal BiS. See Bistooltip/CHANGELOG.md.

## Features

- **Tooltip Enhancement**: Shows BiS ranking and phase information directly in item tooltips
- **BiS Checklist UI**: Full-featured window displaying all BiS items for your class/spec
- **Dual Mode**: MAIN (general gear) and BIS (checklist) views
- **ASCEND Mode**: Filter items by Emblem of Ascension currency
- **Progress Tracking**: Visual progress bars showing collection completion
- **Gem & Enchant Details**: Optional expanded view showing recommended gems and enchants
- **Shift+Click Linking**: Link gems and enchants to chat with Shift+Click
- **Search & Filter**: Quick search through all BiS items
- **Phase Selection**: Filter items by content phase (PR, T7, T8, T9, T10, RS)
- **Instance Grouping**: Items grouped by raid instance with themed headers
- **Lock System**: Mark items as obtained to track progress
- **Custom Priority**: Drag items to reorder BiS priority per slot

## Installation

1. Download the addon
2. Extract to `World of Warcraft/Interface/AddOns/`
3. Ensure the folder is named `Bistooltip`
4. Restart WoW or `/reload`

## Usage

- `/bis` or `/bistooltip` - Open the BiS checklist window
- `/bis config` or `/bistooltip config` - Open settings
- `/bis reload` or `/bistooltip reload` - Reload data
- `/bistooltip help` - Show all available commands
- Hover over items to see BiS information in tooltips
- Use the class/spec dropdowns to view different specs
- Toggle between MAIN and BIS tabs for different views
- Enable ASCEND mode to filter emblem vendor items
- **Shift+Click** on items to link them to chat
- **Shift+Click** on gems/enchants to link them to chat

## Project Structure

```
Bis-Tooltip/
├── Bistooltip.toc              # Addon manifest (load order)
├── Core.lua                    # Addon initialization & events
├── Config.lua                  # Settings UI (AceConfig)
├── Constants.lua               # UI dimensions, colors, layout constants
│
├── # Data Layer
├── DataProvider.lua            # Data access, filtering, caching
├── StateManager.lua            # Application state management
├── Bistooltip_wowtbc_bislists.lua  # BiS item database
├── Bistooltip_classes.lua      # Class/spec definitions
├── Bistooltip_horde_to_ali.lua # Horde<->Alliance item translations
├── EmblemData.lua              # Emblem vendor items & costs
├── GemData.lua                 # Gem stats database
├── Loot_Sources.lua            # Item drop locations
│
├── # UI Framework
├── UIFramework.lua             # UI helper functions & factories
├── ObjectPool.lua              # High-performance frame pooling
├── BislistUI.lua               # Main checklist window
├── Bistooltip.lua              # Tooltip enhancement logic
│
├── ui/                         # UI Components
│   ├── InstanceHeader.lua      # Collapsible raid instance headers
│   ├── SlotRow.lua             # Equipment slot row rendering
│   └── ProgressBar.lua         # Collection progress bars
│
├── util/                       # Utilities
│   ├── debounce.lua            # Input debouncing for search
│   └── reset.lua               # Frame reset/cleanup functions
│
└── Utils.lua                   # Centralized utility functions
```

## Architecture

### Load Order (defined in .toc)

1. **External Libraries** - Ace3 stack (AceAddon, AceDB, AceGUI, etc.)
2. **Data Files** - Static databases (loot sources, emblems, gems, BiS lists)
3. **Utilities** - Utils, reset, debounce
4. **Constants** - UI configuration values
5. **Data Provider** - Caching & data access layer
6. **State Manager** - Application state
7. **Object Pools** - Frame recycling system
8. **UI Framework** - Common UI helpers
9. **UI Components** - ProgressBar, SlotRow, InstanceHeader
10. **Core** - Addon initialization
11. **Config** - Settings UI
12. **Tooltip** - Tooltip enhancement
13. **Main UI** - BislistUI window

### Key Design Patterns

- **Object Pooling**: Frames are recycled to prevent GC pressure and frame drops
- **Lazy Caching**: Item info, instance colors, and normalized names are cached on first use
- **State Management**: Centralized state with listener pattern for UI updates
- **Debounced Input**: Search input uses 250ms debounce to prevent excessive redraws
- **Centralized Utilities**: Common functions in Utils.lua prevent code duplication

### Performance Optimizations

- O(1) pool acquire/release using index tracking
- Cached GetItemInfo() calls with lowercase name caching
- Reverse lookup tables for Horde<->Alliance translations
- Instance name normalization caching
- Mark-and-compact strategy for delayed call queues
- Event cleanup on addon disable to prevent memory leaks

## Configuration

Access settings via:
- ESC -> Interface -> AddOns -> Bis-Tooltip
- Or click the OPTIONS button in the addon window

### Available Options

- **Show Only Missing**: Hide already obtained items
- **Gem Detailed**: Show gem stats below item icons
- **Enchant Detailed**: Show enchant names in expanded rows
- **Lock Items**: Mark items as obtained manually

## Supported Classes & Specs

All WotLK classes and specs are supported:
- Death Knight: Blood Tank, Frost, Unholy, Blood DPS
- Druid: Balance, Feral Tank, Feral DPS, Restoration
- Hunter: Beast Mastery, Marksmanship, Survival
- Mage: Arcane, Fire, Fire FFB, Frost
- Paladin: Holy, Protection, Retribution
- Priest: Discipline, Holy, Shadow
- Rogue: Assassination, Combat
- Shaman: Elemental, Enhancement, Restoration
- Warrior: Arms, Fury, Protection
- Warlock: Affliction, Demonology, Destruction

## Content Phases

- **PR** - Pre-Raid (Heroic dungeons, crafted, reputation)
- **T7** - Naxxramas, Eye of Eternity, Obsidian Sanctum
- **T8** - Ulduar
- **T9** - Trial of the Crusader
- **T10** - Icecrown Citadel
- **RS** - Ruby Sanctum

## Changelog

### v2.2.0 (2026-02-13)
- **Fixed**: Slash commands `/bis` and `/bistooltip` now work (registration was missing)
- **Fixed**: T9 and other faction-specific items no longer show "NO BIS" when hovering over equipped gear on cross-faction servers
- **Added**: Slash command subcommands: `/bis config`, `/bis reload`, `/bistooltip help`

### v2.1.2 (2026-02-04)
- cleared history and marked as release version

### v2.1.1 (2026-02-04)
- **Fixed**: Options window now opens in front of main addon window
- **Fixed**: CUSTOM mode button properly deactivates when switching to BIS tab
- **Changed**: Bottom buttons unified to uppercase (RELOAD, RESET, DISCORD)

### v2.1.0 (2026-02-04)
- **Fixed**: Shift+Click linking for gems and enchants
- **Fixed**: sortByTier runtime error
- **Fixed**: Config dialog race condition
- **Consolidated**: TooltipSetItemByID, NormalizeItemID, GetSpecIcon
- **Cleanup**: Dead code removal, legacy files moved, memory leak prevention

## Credits

- Original addon by **Silver [DisruptionAuras]**
- Refactored and maintained by **Divian**

## License
MIT License
