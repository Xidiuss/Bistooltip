# Architecture and data ownership

The core targets WoW 3.3.5a and Lua 5.1. The authoritative runtime load order is [Bistooltip.toc](../Bistooltip/Bistooltip.toc); a Lua file present on disk is not necessarily loaded.

## Load and initialization

The TOC loads bundled libraries first, then gem/class/ranking/faction tables, followed by `SourceRegistry.lua`, `ItemAcquisition.lua`, `SourceFormatter.lua`, and `PluginAPI.lua`. Utilities and constants precede `PlayerContext.lua`, `DataProvider.lua`, `StateManager.lua`, pooling, and UI helpers/components. `Core.lua` creates the AceAddon instance; `Config.lua`, `Bistooltip.lua`, and `BislistUI.lua` attach its configuration, tooltip, and window methods.

AceAddon invokes `OnInitialize` after those files have loaded. Initialization prepares pools and the equipment watcher, initializes saved settings and the selected database, adds the minimap launcher, and registers commands and tooltip hooks. Most of the native window is created when first opened. Closing it hides the retained frame tree; reopening refreshes its contents.

## Responsibilities

| Owner | Responsibility |
| --- | --- |
| `Config.lua` | AceDB defaults/migration, options, database binding, overlay replay, minimap launcher |
| `Core.lua` | Addon lifecycle and debounced current-character equipment/bag scanning |
| Ranking dataset files | Ranked item IDs and enhancements by class/spec/phase/slot |
| `SourceRegistry.lua` | Canonical source IDs and facts such as instance, boss, and difficulty |
| `ItemAcquisition.lua` | Item IDs mapped to acquisition entries and vendor costs |
| `SourceFormatter.lua` | Plain/colored source text, source palette, vendor cost helpers |
| `PluginAPI.lua` | Validated server mutations and replayable overlay operations |
| `PlayerContext.lua` | Current class, active dual spec, profession IDs and Feral/Spellhance classification |
| `DataProvider.lua` | Selection reads, defensive slot copies, filtering, ownership interpretation, personal priorities |
| `StateManager.lua` | Current selection, UI modes, phase lock, collapsed sections, frame references |
| `Bistooltip.lua` | Item tooltip hooks and modifier-key refresh |
| `BislistUI.lua` | Native MAIN/BIS window, controls, rendering, preload, commands/export |
| `ObjectPool.lua`, `util/reset.lua`, `util/debounce.lua` | Reusable objects, reset behavior, timers and input debounce |
| `ui/InstanceHeader.lua` | Grouping by instance and collapsible headers |

`UIFramework.lua`, `ui/SlotRow.lua`, and `ui/ProgressBar.lua` remain in the load graph, but the main window also contains its own rendering implementations. They should not be described as the sole owners of active rows or progress bars. Before removing an apparently unused global helper, check plugin use, callback registration, aliases, and string-based lookup.

There is currently no standalone `DisplayNames` runtime module. Source facts and names live in the registry; display assembly and coloring belong to the formatter. A separate display-name layer would be a new design change, not an existing dependency.

## Ranking databases and mutable layers

The three database keys are `wowsims`, `wowtbc`, and `wh` (Wowhead). The WoWSimsBP ranking/faction input came from [ExoJdi's fixed 3.3.5a backport](https://github.com/ExoJdi/BiS-Tooltip_335a_fixed_backport); the final core snapshot was assembled offline. `Bistooltip_WoWSimsBP_final.lua` still exports historical globals such as `Bistooltip_wowsims_final`; the filename and exported names are distinct contracts.

For a bind, Config copies the chosen baseline into `Bistooltip_bislists`. The WoWSimsBP selection applies Horde overrides when appropriate. The corresponding class and phase lists are rebound, then recorded server-plugin operations replay. DataProvider returns defensive slot copies and applies saved personal priorities before consumers filter/group them.

```text
bundled ranking snapshot -> fresh active database -> server overlay replay
                                                    |
plugin enhancement rules + current player context -+
                                                    v
                         defensive slot view -> personal override -> UI
```

Personal order does not rewrite the bundled baseline. RESET must restore the active database/plugin baseline. Saved IDs that are absent from a newly selected dataset are reconciled against that dataset; the databases do not promise identical coverage or rank counts. A replay operation targeting an unavailable slot is reported and skipped rather than aborting the whole switch.

Enhancement override rules are a separate, session-only registry rather than overlay mutations. Global rules are considered for every requested class; profession-gated rules are considered only when the requested class is the player's class. Within either scope an exact phase precedes COMMON, one matching owned profession precedes a global rule, and ambiguous profession matches fall back to the global/base layer with a diagnostic. `DataProvider` copies the active slot and its `enhs` list only when an automatic or personal layer applies, replaces only index 1, and preserves later gems. A normal tab supplies its declared spec; only **Your specialization** uses active talents and main-hand context. The personal Enchant editor is applied last.

## Acquisition model

`BisTooltip_SourceRegistry[sourceID]` describes a source. `BisTooltip_ItemAcquisition[itemID]` holds acquisition entries using kinds `DROP`, `TOKEN`, `MARK`, `VENDOR`, or `CUSTOM`. An item may have several entries. Different bosses and alternative vendor purchases must remain distinct.

Vendor entries contain cost components; currency values can include gold, and gold amounts use copper units. Item/token components are separate from currencies. A one-cost compatibility helper cannot represent every purchase option: use the complete entries and formatter when displaying alternatives. `/bisemblem` reads this canonical model.

Source data is shared across ranking databases. Switching rankings does not switch to a separate loot database. Server plugins may change source definitions, acquisitions, ranks, and enhancements through PluginAPI. Scanner output is an offline input to that workflow, not an automatic live update channel into the core.

`Bistooltip/EmblemData.lua` is retained as an offline migration input. It is absent from the TOC and must not compete with ItemAcquisition as a live source of vendor prices.

## SavedVariables and transient state

The TOC declares `BisTooltipDB`, managed by AceDB.

| Scope | Contents |
| --- | --- |
| `db.global` | Selected `data_source` and account-wide `custom_priorities` |
| `db.char` | Class/spec/phase indices, checklist preference, phase lock, tooltip filters/highlights, minimap and detail preferences |
| Session only | Frame pools, item caches, equipment cache, plugin replay log, search/customization/collapse state, debug snapshots |

Migration reads older character-level database/priorities when appropriate. Do not treat the historical `db.char.data_source` field as the current setting. Personal priority keys include class/spec/phase/slot and intentionally omit database identity; reconciliation is by item ID.

The equipment cache scans current bags and equipped slots. It is not a complete inventory service for banks or alternate characters. DataStore is optional and should not be taken as evidence that every ownership view includes its records.

## Runtime limits

`GetItemInfo` may return no data until the client caches an item. The preload code requests item IDs, excludes spell enhancements, checks all requested IDs for completion, and has a two-second bulk timeout. A later response can still require a redraw. Lua tests simulate this boundary; they do not prove network/client timing or frame behavior inside WoW.

Modifier events refresh both visible tooltip types; the reentry guard prevents recursive refresh. Shared `table.insert`/`table.remove` functions are left untouched. Detailed row snapshots are controlled by `/bis debug on`, avoiding the extra diagnostic grouping work during ordinary draws.
