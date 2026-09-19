# Bis-Tooltip

Bis-Tooltip 3.0.0 is a World of Warcraft 3.3.5a addon that shows Best-in-Slot rankings and item acquisition sources in tooltips, with a window for browsing gear and tracking what your character owns. The runtime targets the client's Lua 5.1 environment.

## Install

Copy the `Bistooltip` directory from this repository into `World of Warcraft/Interface/AddOns/`. The resulting manifest must be `Interface/AddOns/Bistooltip/Bistooltip.toc`. Enable the addon on the character selection screen, then log in or reload the UI.

The core includes its required libraries. DataStore is optional; the core ownership scan covers the current character's bags and equipped items. Do not assume that the checklist includes bank or alternate-character inventory.

## Choose a ranking database

Open `/bis config` and choose a database. The selection is shared across characters on the account.

| Setting | Key | Shipped ranking data |
| --- | --- | --- |
| WoWSimsBP (STANDARD) | `wowsims` | `Bistooltip_WoWSimsBP_final.lua`, including faction-specific overrides |
| wowtbc.gg | `wowtbc` | `Bistooltip_wowtbc_bislists.lua` |
| Wowhead | `wh` | `Bistooltip_wh_bislists.lua` |

`wh` means **Wowhead**, not Whitemane. Available specs, phases, and ranked alternatives depend on the selected dataset. These are bundled snapshots; selecting a database does not download current rankings. Sources and vendor costs use the shared canonical acquisition tables, with optional server-plugin overrides.

## Use the window

- MAIN shows ranked gear alternatives. BIS groups checklist items by acquisition location.
- VENDOR, available in BIS, filters purchasable items. It is not restricted to Emblem of Ascension.
- Search and missing-item filters narrow the list. Ownership indicators and progress use the character's equipment/bag cache.
- LOCK fixes the selected phase. CUSTOM allows slot priorities to be changed by selecting two item icons in an unlocked slot; RESET restores the dataset/plugin order for that selection.
- Personal priorities are saved account-wide and reconciled by item ID when changing databases.
- Optional gem and enchant details expand rows. Shift-click links an available item to chat; Ctrl-click previews equipment where an item link is available.

| Command | Action |
| --- | --- |
| `/bis` or `/bistooltip` | Open the window |
| `/bis config` | Open settings |
| `/bis reload` | Rescan ownership, clear caches, refresh and request item information |
| `/bistooltip help` | Show command help |
| `/bisemblem <item ID or item link>` | Print all recorded vendor purchase options |
| `/bis debug` | Print selection/row integrity diagnostics |
| `/bis debug on` / `/bis debug off` | Enable/disable detailed row snapshots |
| `/bis repairrows` | Rebind the active dataset and replay its overlays |

Item information arrives asynchronously from the game. The current bulk preload waits for up to two seconds. If a slow response leaves a placeholder, use RELOAD or change the selection to redraw it.

## Core, server plugins, and scanner

These components have separate branches and addon directories in the same Git repository. A server plugin supplements the core; the scanner is a separate vendor-data collection tool.

| Component | Branch |
| --- | --- |
| Core addon | `main` |
| Scanner | `Bistooltip_Scanner` |
| Whitemane Frostmourne plugin | `Bistooltip_Whitemane_Frostmourne` |
| WOTLK5 S2 plugin | `Bistooltip_WOTLK5_S2` |

Install the relevant server plugin alongside the core when using that server's changes. A core-only download does not include these other branches.

## Development documentation

- [Architecture and data ownership](docs/ARCHITECTURE.md)
- [Development, regression tests, and in-game checks](docs/DEVELOPMENT.md)
- [Server plugin API and scanner handoff](docs/PLUGIN-API.md)
- [Post-migration audit, remaining data gaps, and roadmap](docs/POSTMIGRATION-AUDIT.md)
- [Changelog](Bistooltip/CHANGELOG.md)

Runtime files live under `Bistooltip/`; public regression tests live under `.github/tests/`. `Bistooltip.toc` defines the actual load graph. `EmblemData.lua` is retained as an offline migration input and is not loaded by the addon.

Original addon/backport credits: Silver [DisruptionAuras]. Refactoring and maintenance: Divian. See the [core license](Bistooltip/LICENSE); bundled third-party libraries retain their own license notices.
