# Bistooltip Whitemane Frostmourne

Server data overlay for Whitemane Frostmourne, WoW 3.3.5a (`Interface: 30300`, TOC version `1.0.1`). Install `Bistooltip_Whitemane_Frostmourne` beside the `Bistooltip` core addon in `Interface/AddOns`. Core is a required dependency. Enable only the overlay appropriate to your server; the plugin does not detect your realm or disable another server's overlay.

This branch contains the overlay addon only. `main` contains core; `Bistooltip_Scanner` contains the optional collection tool; `Bistooltip_WOTLK5_S2` contains a different server's data. Core's database key `wh` means **Wowhead rankings**, not this Whitemane plugin.

The original overlay at `b9c258e` registers 377 additional VENDOR acquisition entries using `AddAcquisition`, retaining existing core routes. These include Emblem of Ascension, Emblem of Ascension II, and Echo of the Titans costs. The 27 `SetBiSSlotRank` calls replace rank 1 for selected profiles/phases with custom legendary item IDs 128858, 130023, 130031, 131004, and 150005. Remaining ranks come from the selected core database. The file records the original data extraction and correction of 15000 to 150005.

The reviewed September 19 scanner import adds 112 Justice/Valor offers. Per the author's decision, these replace older VENDOR prices for the same IDs while preserving DROP/TOKEN/MARK and other non-vendor methods. The final 23 annotated legendary IDs are retained as inactive comments for a future BiS update; they do not register empty prices or change current ranks. See [the import audit](docs/SCANNER-IMPORT-AUDIT.md) for findings and the applied policy.

The core records plugin mutations for replay when the user switches ranking databases. Some profiles/phases are absent from some databases; this requires a compatible core that defers valid unavailable rank targets. Older cores can abort plugin startup at the first T7 override when Wowhead or wowtbc is selected. Validate startup as well as an in-session database switch when updating either package.

The addon has no commands, settings, SavedVariables, scanner, or independent UI. Use core's `/bis` interface. Vendor locations are not included in these acquisition rows. Currency display names are data labels; this plugin does not define a currency-item registry or custom enchant assignments.

For maintenance, edit only confirmed server differences, retain plugin attribution `P`, and check every supported database. Collect fresh merchant evidence with the scanner before changing prices. Scanner `SetAcquisition` snippets replace routes; convert additions deliberately to `AddAcquisition` when core routes should remain. Test with only this server overlay enabled and inspect a known vendor item plus a legendary rank override after login and a database switch.

Run `lua5.1 .github/tests/lua/import_policy.lua <core-worktree>` from this branch. This checks all 112 new prices, preservation of non-vendor methods and existing legendary sources, and repeated overlay replay. Use core `8a2964c` or newer (the replay snapshot fix); CI checks this branch against `main`. Native CI and live merchant verification remain required before release.
