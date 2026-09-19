# Bistooltip WOTLK5 S2

Server acquisition overlay for WOTLK5 season 2, WoW 3.3.5a (`Interface: 30300`, TOC version `1.0.1`). Install `Bistooltip_WOTLK5_S2` beside the required `Bistooltip` core addon in `Interface/AddOns`. Enable the overlay only on the matching server; it does not select itself by realm or exclude another server overlay. This addon supplies acquisition data, not a separate ranking database or UI.

**Current status:** offline core integration has exercised this overlay with three ranking databases and both factions. Native Lua 5.1 CI and a live WOTLK5 merchant/scroll check remain release gates. The [project roadmap](https://github.com/Xidiuss/Bistooltip/blob/main/docs/ROADMAP.md) records the next data and scanner work.

This branch packages only the WOTLK5 S2 addon. `main` packages core, `Bistooltip_Scanner` packages the optional scanner, and `Bistooltip_Whitemane_Frostmourne` is a different server overlay. These are separate addons, not core ranking database choices.

`main.lua` contains 620 `AddAcquisition` calls for vendor alternatives and eight `SetAcquisition` calls for custom enchant scrolls. Existing core drops/vendor routes are retained for the appended vendor entries. The header attributes the input to the 2026-09-08 scans of Vexmor Gravebinder and Maldrith Soulleech in Dalaran, plus a hand-appended ENCHANTY section. Header scan totals are provenance, not the count of current executable calls.

The vendor currencies are Emblem of Plague (commented item ID 5000016) and Emblem of Resolve (90630). The eight custom scroll IDs are 5000759, 5000760, 5000761, 5000763, 5000764, 5000765, 5000766, and 5000767, each priced at one Plagued Legendary Shard (commented currency item ID 5000971). These currency IDs are comments, not registered currency metadata.

The enchant section describes **where to obtain scrolls only**. It contains no `SetEnhancement` assignments and does not add these scrolls to class/spec/slot recommendations. Adding recommendations requires confirmed server rules and explicit class/spec/phase/slot choices; names alone do not establish those choices. This addon also defines no ranking overrides or new source registry entries.

There are no plugin commands, settings, SavedVariables, or independent UI. The core displays acquisition data and replays the overlay across ranking database switches. Use `/bis` for the core interface and the separate scanner's `/bisscan` commands to collect new evidence.

When updating prices, retain provenance and review scanner warnings. Scanner snippets use `SetAcquisition`, which replaces core routes; use `AddAcquisition` intentionally for additional vendor alternatives. Smoke-test a known vendor item and custom scroll on the target server, then switch core databases and confirm sources remain visible. Actual item cache availability, prices, and enchant effects need live server verification.
