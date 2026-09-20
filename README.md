# Bistooltip Scanner

Standalone vendor and item-ID collector for WoW 3.3.5a (`Interface: 30300`). This branch ships only `Bistooltip_Scanner`; the current TOC version is `0.2.1`. Core Bistooltip is optional for scanning. Copy `Bistooltip_Scanner` into `Interface/AddOns` and enable it in the client. This tool records observations for review; it does not create BiS rankings or install a server overlay.

**Current status:** local offline regressions cover the corrected 3.3.5 merchant cost signature, cache resolution, CSV rows, and live preset edits. The owner also confirmed all three VENDOR export modes in the game client on 2026-09-20. Native Lua 5.1 validation and broader merchant coverage are still needed before release. The [project roadmap](https://github.com/Xidiuss/Bistooltip/blob/main/docs/ROADMAP.md) tracks the scanner-to-plugin workflow and its remaining limits.

The scanner stores observations in the account SavedVariables table `BistooltipScannerDB`. It does not modify the core addon or install generated plugins. Server APIs and the local item cache determine what can be collected.

## Commands and collection

`/bisscanner` is an alias for `/bisscan`.

| Command | Action |
| --- | --- |
| `/bisscan` | Scan the open merchant; replaces that merchant's previous record. |
| `/bisscan page` | Merge the current merchant page into its record. |
| `/bisscan stab` | Repeat merging scans until stable or the eight-pass limit. Closing the merchant stops it. |
| `/bisscan 12345` | Collect an item by ID without a merchant. This does not discover its source or price. |
| `/bisscan menu` | Open the scanner menu, mark presets, and vendor log controls. |
| `/bisscan setcost 456 7` | Assign seven units of currency item 456 to entries with no detected money or cost in the last record. |
| `/bisscan setcost 12345 456 7` | Replace the item-cost list for item 12345 in the last record. |
| `/bisscan undo` | Undo the last manual cost assignment (one level). |
| `/bisscan custom` | Toggle CUSTOM export for a donate/shop label instead of VENDOR costs. |
| `/bisscan mode append` | Select additive purchase export; default mode. |
| `/bisscan mode replace_vendor` | Select replacement of purchase offers only; requires matching current core. |
| `/bisscan mode replace_all` | Select replacement of every acquisition route; legacy behavior. |
| `/bisscan export` or `/bisscan log` | Export logged merchants, or the last record if the log is empty. |
| `/bisscan csv` | Export semicolon-separated item/cost data. |
| `/bisscan clearlog` | Clear the selected vendor log, retaining observations. |
| `/bisscan clearcache` | Request confirmation to clear collected scanner data. |

With a merchant open, use **Scan BIS** or the menu. Alt-clicking a merchant item captures it and applies the pending mark, when configured. Use the menu's **Dodaj do logu** control to include multiple merchants in an export.

Editing AMOUNT or MARK ID in the checked preset updates the pending price immediately, without toggling its checkmark. Inactive preset edits do not affect that price. An empty amount, deselection or removal clears it. This affects subsequent captures and explicit cost assignments, not already exported Lua text or historical observations. Rendering the menu does not write partially populated fields back into saved presets.

Missing links remain positional placeholders. Rescan the page or run stabilization after the client cache fills; a resolved item replaces its placeholder. Export also refreshes cached item and currency names without replacing manually entered costs. It cannot obtain data the server has not supplied, and no background completion of manual item-ID scans is promised.

Stock 3.3.5 returns `honorPoints, arenaPoints, itemCount` from `GetMerchantItemCostInfo`; the scanner records Honor Points, Arena Points, and token costs together. An Honor price such as 1650 is not a token-row count. A count-only return remains supported for modified server clients. Token rows use `texture, amount, itemLink` from `GetMerchantItemCostItem`, as in [the 3.3.5 merchant interface](https://github.com/wowgaming/3.3.5-interface-files/blob/main/MerchantFrame.lua#L220).

A defensive eight-row cap applies to token counts, without truncating Honor/Arena amounts. Token rows without a currency link are dropped. Missing prices export with an `EMPTY-COST` tail carrying the token count `nCost` diagnostic and stay eligible for `setcost`. Records saved before this correction may contain incorrect prices: rescan merchants. Lua/CSV export skips legacy cost rows that have neither a currency ID nor a name.

## Export contract

The menu's **Export** button cycles through `append`, `replace_vendor`, and `replace_all`; `/bisscan mode ...` selects the same policy. **The mode is applied when you press Export, not when you scan.** It is one setting for the entire generated Lua text, not a property saved on each item. To use different policies for different items, select a mode, export and save that snippet, then switch mode and export the next item separately. Changing the mode does not change text already copied or stored in an earlier export; press Export again. The scanner records observations only: review the Lua and place selected calls in the appropriate server plugin; it does not execute them in the current game session.

| Mode | Generated call for item `5000759` (shown with `offer` below) | What happens when the Lua is loaded | Use when |
| --- | --- | --- | --- |
| `append` | `BisTooltip:AddAcquisition(5000759, offer)` | Adds this purchase option and keeps existing vendor prices, drops, tokens, quests and other routes; an identical entry is deduplicated. | The item gains a second valid offer, such as a custom emblem price. |
| `replace_vendor` | `BisTooltip:ReplaceVendorAcquisitions(5000759, { offer })` | Removes previous `VENDOR` offers for this item, then adds the scanned offer; other acquisition methods remain. | Justice/Valor supersedes old WotLK emblem prices while drops and tokens stay available. Requires a core with `ReplaceVendorAcquisitions`. |
| `replace_all` | `BisTooltip:SetAcquisition(5000759, { offer })` | Replaces **every** acquisition route for this item, including drops and tokens. | A reviewed full correction where all previous routes are intentionally obsolete. |

For this example, `offer` means `{ kind = "VENDOR", cost = { { currency = "Plagued Legendary Shard", amount = 1 } } }`. The actual export writes this value inline; the table above shows how the three calls differ.

These three calls can show the same price in a tooltip when the item had only one vendor source before. Compare the generated function name, or test a single item that already has both a drop and vendor price, to see the policy difference. The trailing `-- item:5000971` in the owner's scroll example is the currency item ID, while `5000759` is the scroll ID. The export policy does not assign a scroll as a recommended enchant or create an item upgrade.

The current core has a separate **Enchant editor** in `/bis config`: after reviewing a scanner export, enter the scroll item ID there and choose an exact database/class/spec/phase/slot for a personal recommendation. The editor previews sources and prices already present in the installed core/plugin data, preserves later gem entries, and does not change this scanner's observations. VENDOR in core already lists and exports purchasable BiS; the future shopping basket will add manually chosen upgrades outside BiS, totals, ordering and affordability alerts.

In `append`, the log exports every merchant offer, including repeated item IDs with different currencies. `replace_vendor` and `replace_all` currently keep the last merchant for each item ID and warn about duplicates; export those alternatives separately or curate a combined offer list before using replacement. Merchant records use `name @ zone` keys, so servers/realms with matching merchant names share that key in the account database. The separate CUSTOM toggle exports a label with `SetAcquisition` regardless of these three VENDOR modes; review it as a full replacement.

Currency names and amounts are executable fields; currency item IDs are retained in trailing Lua comments and CSV `currID`. Money is in **copper**. Quantity/limited-stock details appear in comments. CUSTOM mode exports a label and omits costs. Missing prices produce commented `UNRESOLVED PRICE` lines with EMPTY-COST warnings; resolve them before using the output.

Honor Points and Arena Points have names and amounts but no currency item ID; their CSV `currID` field is empty.

CSV columns are `itemID;name;currency;amount;currID;money`. Each cost has one row; no-cost entries keep the currency fields empty. Semicolons and newlines in text cells become spaces, so CSV is not a lossless text archive. Combined exports include merchant comment lines and repeated headers.

The copy window displays at most 500 lines by default. Full Lua text is stored in `BistooltipScannerDB._logText` (CSV in `_csvText`); SavedVariables are written on logout or `/reload`. Do not treat a truncated copy as the full export.

## Checks

From this branch root, run `lua5.1 .github/tests/lua/scanner_regression.lua` and `lua5.1 .github/tests/lua/menu_regression.lua`. The fixtures cover merged placeholders, CSV alignment, late cache data, stock Honor/Arena/token prices, malformed cost rows, and live preset edits through actual menu callbacks. They stub merchant/cache/frame APIs; merchant clicks and live server timing still require a WoW 3.3.5a smoke test.

Other release branches in the same repository are `main` (core), `Bistooltip_Whitemane_Frostmourne`, and `Bistooltip_WOTLK5_S2`. They are separate addon packages, not alternative scanner databases.
