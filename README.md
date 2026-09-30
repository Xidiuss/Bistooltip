# Bistooltip WOTLK5 S2

Server acquisition and enhancement overlay for WOTLK5 season 2, WoW 3.3.5a (`Interface: 30300`, TOC version `1.0.1`). Install `Bistooltip_WOTLK5_S2` beside the required `Bistooltip` core addon in `Interface/AddOns`. Enable the overlay only on the matching server; it does not select itself by realm or exclude another server overlay. This addon supplies acquisition data and confirmed T7 enhancement recommendations, not a separate ranking database or UI.

**Current status:** offline core integration has exercised this overlay with three ranking databases and both factions. Native Lua 5.1 CI and a live WOTLK5 merchant/scroll check remain release gates. The [project roadmap](https://github.com/Xidiuss/Bistooltip/blob/main/docs/ROADMAP.md) records the next data and scanner work.

This branch packages only the WOTLK5 S2 addon. `main` packages core, `Bistooltip_Scanner` packages the optional scanner, and `Bistooltip_Whitemane_Frostmourne` is a different server overlay. These are separate addons, not core ranking database choices.

`main.lua` contains 620 `AddAcquisition` calls for vendor alternatives, nine `SetAcquisition` calls for custom enchant scrolls and 96 targeted enhancement rules. Existing core drops/vendor routes are retained for the appended vendor entries. The header attributes the price input to the 2026-09-08 scans of Vexmor Gravebinder and Maldrith Soulleech in Dalaran, plus a hand-appended ENCHANTY section. Header scan totals are provenance, not the count of current executable calls.

The vendor currencies are Emblem of Plague (commented item ID 5000016) and Emblem of Resolve (90630). The nine custom scroll IDs are 5000759, 5000760, 5000761, 5000762, 5000763, 5000764, 5000765, 5000766, and 5000767, each priced at one Plagued Legendary Shard (commented currency item ID 5000971). These currency IDs are comments, not registered currency metadata.

The plugin declares three T7 recommendations for each of 32 role profiles. Trinket requires Enchanting (`333`): tanks use `5000162`, AP DPS `5000161`, and SP DPS/healers `5000160`. Head requires Inscription (`773`): tanks use `5000158`, AP DPS `5000156`, SP DPS `5000159`, and healers `5000157`. Legendary Neck is global: tanks use `5000766`, DPS/healers use `5000764`, except Warlock Affliction uses `5000765`. Each rule replaces only the first recommendation, so later Head/Neck gems remain from the selected core database. PR/T8/T9/T10/RS are intentionally unchanged.

The existing Plagued Legendary Shard prices for `5000764`–`5000766` remain acquisition facts. No source or price was invented for `5000156`–`5000162`; the recommendations do not imply where those scrolls are obtained. The core personal **Enchant editor** still applies last and can override index 1 for one database/class/spec/phase/slot. This addon defines no ranking overrides or new source registry entries.

There are no plugin commands, settings, SavedVariables, or independent UI. The core displays acquisition data and replays the overlay across ranking database switches. Use `/bis` for the core interface and the separate scanner's `/bisscan` commands to collect new evidence.

Core VENDOR already lists and exports purchasable BiS. The planned basket is a later extension for selected non-BiS upgrades, combined costs, a chosen purchase order and affordability alerts; it is not supplied by this overlay.

When updating prices, retain provenance and review scanner warnings. Scanner snippets use `SetAcquisition`, which replaces core routes; use `AddAcquisition` intentionally for additional vendor alternatives. Smoke-test a known vendor item and custom scroll on the target server, then cover one tank, AP DPS, SP DPS, healer and Affliction profile with the T7 profession/global rules. Switch core databases, verify later gems and non-T7 phases, and confirm sources remain visible. Actual item cache availability, prices, enchant effects and profession behavior need live server verification.
