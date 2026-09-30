# Bistooltip WOTLK5 S2

Server acquisition and enhancement overlay for WOTLK5 season 2, WoW 3.3.5a (`Interface: 30300`, TOC version `1.0.1`). Install `Bistooltip_WOTLK5_S2` beside the required `Bistooltip` core addon in `Interface/AddOns`. Enable the overlay only on the matching server; it does not select itself by realm or exclude another server overlay. This addon supplies acquisition data, shared profession enhancement recommendations and phase-specific legendary Neck recommendations, not a separate ranking database or UI.

**Current status:** offline core integration has exercised this overlay with three ranking databases and both factions. Native Lua 5.1 CI and a live WOTLK5 merchant/scroll check remain release gates. The [project roadmap](https://github.com/Xidiuss/Bistooltip/blob/main/docs/ROADMAP.md) records the next data and scanner work.

This branch packages only the WOTLK5 S2 addon. `main` packages core, `Bistooltip_Scanner` packages the optional scanner, and `Bistooltip_Whitemane_Frostmourne` is a different server overlay. These are separate addons, not core ranking database choices.

`main.lua` contains 620 `AddAcquisition` calls for vendor alternatives, nine `SetAcquisition` calls for custom enchant scrolls and 160 targeted enhancement rules. Existing core drops/vendor routes are retained for the appended vendor entries. The header attributes the price input to the 2026-09-08 scans of Vexmor Gravebinder and Maldrith Soulleech in Dalaran, plus a hand-appended ENCHANTY section. Header scan totals are provenance, not the count of current executable calls.

The vendor currencies are Emblem of Plague (commented item ID 5000016) and Emblem of Resolve (90630). The nine custom scroll IDs are 5000759, 5000760, 5000761, 5000762, 5000763, 5000764, 5000765, 5000766, and 5000767, each priced at one Plagued Legendary Shard (commented currency item ID 5000971). These currency IDs are comments, not registered currency metadata.

The plugin declares five recommendations for each of 32 role profiles. Four profession rules are COMMON and therefore apply in every phase. Enchanting (`333`) supplies Trinket (`5000162` tank, `5000161` AP, `5000160` SP/heal) and Finger (`59636` tank, `44645` AP, `44636` SP/heal). Inscription (`773`) supplies Head (`5000158` tank, `5000156` AP, `5000159` SP, `5000157` heal) and Shoulder (`61119` tank, `61117` AP, `61120` SP, `61118` heal). Legendary Neck remains phase-specific: T7 uses `5000766` for tanks and `5000764` for DPS/healers, except Warlock Affliction uses `5000765`. Each rule replaces only the first recommendation and preserves every later gem from the selected core database.

The existing Plagued Legendary Shard prices for `5000764`–`5000766` remain acquisition facts. No source or price was invented for `5000156`–`5000162`; the recommendations do not imply where those scrolls are obtained. The core personal **Enchant editor** still applies last and can override index 1 for one database/class/spec/phase/slot. This addon defines no ranking overrides or new source registry entries.

There are no plugin commands, settings, SavedVariables, or independent UI. The core displays acquisition data and replays the overlay across ranking database switches. Use `/bis` for the core interface and the separate scanner's `/bisscan` commands to collect new evidence.

Core VENDOR already lists and exports purchasable BiS. The planned basket is a later extension for selected non-BiS upgrades, combined costs, a chosen purchase order and affordability alerts; it is not supplied by this overlay.

When updating prices, retain provenance and review scanner warnings. Scanner snippets use `SetAcquisition`, which replaces core routes; use `AddAcquisition` intentionally for additional vendor alternatives. Smoke-test a known vendor item and custom scroll on the target server, then cover one tank, AP DPS, SP DPS, healer and Affliction profile. Verify all four profession slots in multiple phases, the T7-only Neck, preserved later gems and database switching. Actual item cache availability, prices, enchant effects and profession behavior need live server verification.
