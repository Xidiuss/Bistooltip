# Development and verification

Run commands from the core Git worktree, not the surrounding workspace. This document describes how to verify a change; it is not a record of a completed CI or in-game run.

## Workspace ownership

In the maintained Windows workspace, `D:\PROJEKTY\BIS_project` is not a checkout. The bare repository is `Private/Git/Bistooltip.git`; linked worktrees are:

| Component | Worktree relative to workspace | Branch |
| --- | --- | --- |
| Core | `Bistooltip-main/core` | `main` |
| Scanner | `Bistooltip-main/scanner` | `Bistooltip_Scanner` |
| Whitemane Frostmourne | `Bistooltip-main/whitemane-frostmourne` | `Bistooltip_Whitemane_Frostmourne` |
| WOTLK5 S2 | `Bistooltip-main/wotlk5-s2` | `Bistooltip_WOTLK5_S2` |

All use `https://github.com/Xidiuss/Bistooltip.git` as origin. Verify the branch and existing changes in the owning worktree before editing. Before handing off, inspect its status and local/remote divergence. Do not reset unrelated changes. Ordinary standalone clones can use the same tests from their repository root.

`Private/Legacy` contains private offline inputs/tooling outside every Git worktree. Changes there are not committed by committing the core. Generated runtime outputs belong under `Bistooltip-main/core/Bistooltip` and are versioned on `main`. Do not relocate or add private tooling to a repository without agreeing on its location first. The retained `Bistooltip/EmblemData.lua` is an offline input, excluded from runtime loading.

## Public regression checks

Use native Lua 5.1 for the target-language checks and Node.js for the package graph check. Run each Lua test in a fresh process because the tests install WoW/Ace stubs and mutate globals. Core tests use public repository files; private generator inputs are not a prerequisite.

From the core repository root, PowerShell:

```powershell
node .github/tests/check_package.cjs
if ($LASTEXITCODE -ne 0) { throw 'Package check failed' }

Get-ChildItem .github/tests/lua/test_*.lua |
    Where-Object Name -ne 'test_server_plugins.lua' |
    ForEach-Object {
        & lua5.1 $_.FullName
        if ($LASTEXITCODE -ne 0) { throw "Lua regression failed: $($_.Name)" }
    }
```

Or a POSIX shell:

```sh
node .github/tests/check_package.cjs || exit 1
for test in .github/tests/lua/test_*.lua; do
    case "$test" in */test_server_plugins.lua) continue ;; esac
    lua5.1 "$test" || exit 1
done
```

The package checker follows TOC/XML dependencies and catches missing shipped files, including libraries that other addons could accidentally supply during a manual test.

| Test | Coverage |
| --- | --- |
| `test_data_integrity.lua` | Canonical acquisition and formatting contracts |
| `test_data_state.lua` | Binding, migration, replay, personal order and enchant assignment |
| `test_plugin_boundaries.lua` | Malformed operations and isolation |
| `test_vendor.lua` | Vendor purchase interpretation |
| `test_runtime.lua` | Lifecycle, bounded/retried preloading, stale selection callbacks, tooltip modifiers and vendor command |
| `test_datasets.lua` | Bundled ranking datasets |
| `test_server_plugins.lua` | Actual plugin entry points with core; requires a plugin path argument |

For server integration, check out the corresponding branches and supply their entry-point paths. In the linked-worktree workspace:

```sh
lua5.1 .github/tests/lua/test_server_plugins.lua ../whitemane-frostmourne/Bistooltip_Whitemane_Frostmourne/main.lua
lua5.1 .github/tests/lua/test_server_plugins.lua ../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua
```

An isolated core checkout needs separate plugin checkouts for these two commands. CI uses a plugin branch matrix and a separate integration checkout. [tests.yml](../.github/workflows/tests.yml) is the source of truth for its jobs and inputs; this document does not assert that any particular run has passed.

Syntax-check loaded addon code with native `luac5.1` as well. Syntax validation alone cannot establish correct WoW API usage or addon loading. Discord release tooling has a separate Python suite:

```sh
python -m unittest discover -s .github/tests -p 'test_*.py' -v
```

During local investigation, Fengari (Lua 5.3 semantics) can run many pure-Lua probes with compatibility aliases such as `unpack=table.unpack; loadstring=load`. This is a diagnostic fallback, not native Lua 5.1 validation. Inspect its output for assertion failures; the local CLI used during the audit can return exit code zero despite a Lua assertion failure. Do not report a Fengari run as a native 5.1 pass or as an in-game test.

## Changing data or behavior

Use [ARCHITECTURE.md](ARCHITECTURE.md) to identify the owner before editing. Ranking snapshots, canonical sources/acquisitions, formatter text, and server overlays are different layers. Preserve unrelated acquisition alternatives and keep gold costs in copper. When changing a generated runtime file, record the input and generation/validation method; do not claim private inputs are versioned.

Reproduce behavior defects with a focused regression before fixing them. Exercise real data/binding/formatter code and stub only the unavailable game boundary. Include switching databases, replaying plugins, and restoring personal order when a change crosses those layers. Avoid bulk removal of helpers solely because a text search found few references: callbacks, aliases, exports, TOC/XML loads, and server plugins can be consumers.

## In-game smoke checklist

Use a WoW 3.3.5a client with Lua errors visible. Record the core commit, server, faction, dataset, other enabled addons, and exact steps. Start with core alone, then add the applicable server plugin, then optional UI/DataStore integrations.

1. Log in with only the core enabled. Confirm no missing-library error, a working minimap launcher, and `/bis` and OPTIONS opening normally.
2. Open and close the main window repeatedly using X and Escape. Reopen, change MAIN/BIS tabs, and verify controls, rows, scrolling, and the progress bar remain usable without overlapping duplicates.
3. Switch through all three databases, including while the main window is hidden by OPTIONS. Confirm class/spec/phase dropdowns and the status label agree with the displayed rows. Check a Horde and an Alliance character. In WoWSimsBP and wowtbc.gg verify that Alliance shows Death's Verdict `47115` and Horde Death's Choice `47303` before and after `/reload`.
4. In CUSTOM, change an unlocked slot's priority, change database, return, reload the UI, and verify saved order is reconciled. RESET should recover the current dataset/plugin order. Check the phase LOCK separately.
5. Move/equip an item and use RELOAD. Check ownership marks, missing-item filters, and progress, including ring/trinket slots. Do not count bank/alt inventory as a promised feature.
6. Browse a cold item cache and switch selections during loading. Check icon/name updates, pending count, gem/enchant details and that an old selection never redraws over the new one. A slow response should update within the eight-second retry window; after timeout, confirm the unavailable count and use RELOAD to retry.
7. In `/bis config` → Enchant editor, assign a known scroll item ID to one exact database/class/spec/phase/slot and verify its source/price preview, warning, and icon/name in MAIN/BIS. Switch databases and reload: the personal assignment must persist only in its selected database; Reset this slot restores the plugin/dataset entry and later gems remain.
8. Keep an item-link tooltip open while hovering another item. Press and quickly release Shift/Ctrl; both tooltips should reflect the final modifier state. Check item chat links and dressing-room actions.
9. Enable VENDOR in BIS. For a slot with several ranked alternatives, verify that only rank 1 appears (rank 1 and 2 for Finger/Trinket) when those items have a vendor route. Check Val'anyr, Staff of Endless Winter and Constellus with Whitemane enabled and disabled. Inspect items with multiple purchase options, currency/item-token costs, and gold costs; compare tooltip, list, and `/bisemblem <ID or link>` output. Items whose only known method is quest/drop must stay out of VENDOR.
10. Enable the relevant server plugin. For Whitemane, check a legendary at rank 1, the former first item at rank 2, and exactly six ranked positions in MAIN/CUSTOM before and after database switches and RESET. Check a known source/cost as well. Do not assume the other server's plugin describes this server.
11. Run `/bis debug on`, redraw a selection, then `/bis debug`; collect its output for row issues and finish with `/bis debug off`.
12. With the scanner enabled, capture a merchant with Honor, Arena and item-token costs. Change AMOUNT in the checked preset without toggling its checkmark, then export Lua and CSV; compare all amounts and six CSV columns with the merchant window. In `append`, scan the same item at two merchants and check that both offers are exported. In `replace_vendor`, verify that an old WotLK emblem price is replaced by Justice/Valor without erasing a drop or token; use `append` for an additional custom-emblem purchase. `replace_all` is only for a deliberate full replacement. Record unresolved `EMPTY-COST` rows instead of importing them as free offers.
13. On WOTLK5 S2, enable only its matching server overlay and compare a known vendor item plus scroll `5000762` with the in-game merchant. The scroll should show 1 × Plagued Legendary Shard and remain absent from class/spec enchant recommendations until assigned.
14. Check one complete Yrma exchange: `34388` should require 1 × `34192` and 1 × Sunmote `34664`; `34192` should identify the Eredar Twins in Sunwell Plateau 25N rather than claiming that the target `34388` drops there. Check Priest/Shadow/PR/Chest in WoWSimsBP: `39523` should be first, `43792` absent and no duplicated `39523`. Discipline/Holy should retain `39515` where ranked.
15. Compare Alliance/Horde counterpart prices, for example `47674`/`47675` at 75 Emblem of Triumph and `47702`/`47701` at 45. Check `43573` for the Nascent Val'kyr NPC description and `37761` for the broad world-drop description.

Report automated results, native-runtime availability, and in-game results separately. Passing stubs cannot establish rendering, addon interactions, or server data accuracy.
