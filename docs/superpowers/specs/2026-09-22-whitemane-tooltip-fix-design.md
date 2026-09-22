# Whitemane Tooltip Fix — design

## Purpose

Create a standalone World of Warcraft 3.3.5a addon that prevents upgraded
Whitemane dungeon items from raising an error while RatingBuster scans their
tooltips. The package must work without BiSTooltip and must not modify the
installed RatingBuster, ElvUI, DBM, Zygor, or client FrameXML files.

The deliverable is an independently installable addon directory named
`WhitemaneTooltipFix`, displayed in the addon list as `Whitemane Tooltip Fix`.

## Confirmed cause

RatingBuster 1.5.0 embeds an old LibStatLogic-1.1 implementation. Its hidden
`StatLogicTooltip` and `StatLogicMinerTooltip` scanners extend the tooltip to
30 rows. For rows created beyond the template-provided rows, the library keeps
the left font string under a predictable global name but creates the right
font string anonymously.

Whitemane's modified client inserts an `Item Level` row into upgraded item
tooltips. Its `GameTooltip_AddItemLevel` path calls `InsertLine`, whose save and
restore code expects both named `TextLeftN` and `TextRightN` font strings. Once
an item tooltip reaches one of LibStatLogic's extended rows, the right lookup
returns `nil` and `TooltipSaveLines` fails. The public tooltip that initiated
the scan (bag, loot, auction, DBM, or Zygor) is only the caller; the failure is
inside the hidden StatLogic scanner.

The separate `!!!ClassicAPI` `GetRGBA` error shown in the same report belongs
to the Wardrobe search box compatibility layer and is outside this addon's
scope.

## Package structure

The Whitemane component branch will contain a second top-level addon directory:

```text
WhitemaneTooltipFix/
  WhitemaneTooltipFix.toc
  TooltipFix.lua
```

The TOC will target interface `30300`, declare no required dependencies or
SavedVariables, and list RatingBuster as an optional dependency. The optional
dependency controls load order when RatingBuster is enabled but does not make
RatingBuster or BiSTooltip mandatory.

The existing `Bistooltip_Whitemane_Frostmourne` addon and its data files will
not load or call the fix. Users may install either addon independently.

## Runtime behavior

`TooltipFix.lua` will inspect only the global scanner frames named
`StatLogicTooltip` and `StatLogicMinerTooltip`.

For each target, it will:

1. Confirm that the object exposes callable `InsertLine` and `AddLine` methods.
2. Confirm the compatibility defect by finding a numbered left font string
   without the matching numbered right font string.
3. Replace `InsertLine` on that scanner instance only with a wrapper that
   appends the requested text through its native `AddLine` method, preserving
   text color and wrapping arguments.
4. Mark the instance as patched so repeated load events are idempotent.

Appending instead of inserting is acceptable for these two frames because
they are hidden parsing tooltips, not UI shown to the player. LibStatLogic
already scans their rows without depending on the visual position of the item
level line. The wrapper avoids the client's faulty save/restore path while
leaving the item-level text available to the scanner.

The addon will attempt the patch immediately and retry after addon load events
so it also handles an embedded or late-loaded LibStatLogic. Once both existing
targets have been considered, repeated attempts remain harmless. It will not
alter the global `GameTooltip_AddItemLevel`, the shared `InsertLine` method, or
any visible tooltip.

The addon will stay silent during normal operation. Absence of RatingBuster or
of either target tooltip is a supported no-op, not an error.

## Compatibility boundaries

- Lua 5.1 syntax only.
- WoW interface version 30300.
- No dependency on BiSTooltip globals or files.
- No dependency on ElvUI or other tooltip callers.
- No edits to third-party addon directories or client FrameXML.
- No attempt to repair arbitrary custom GameTooltip frames; only the two
  known StatLogic scanner names are eligible.
- A scanner with complete Left/Right rows keeps its original `InsertLine`.

These boundaries keep the workaround removable if Whitemane or RatingBuster
later corrects the underlying mismatch.

## Tests

A Lua 5.1 regression test will load the real `TooltipFix.lua` against small WoW
API frame doubles and verify:

- loading without RatingBuster is a silent no-op;
- a broken `StatLogicTooltip` is patched;
- inserted text is appended with the original color and wrapping arguments;
- a complete StatLogic tooltip retains its original insertion behavior;
- unrelated tooltip objects are untouched;
- repeated addon-load events do not wrap an instance more than once;
- a StatLogic tooltip created after this addon loads is patched on a later
  addon-load event;
- `StatLogicMinerTooltip` receives the same targeted protection.

The branch CI will syntax-check both addon directories and run the new test in
addition to the existing Whitemane import-policy test. A final package check
will verify that the TOC references only files present inside
`WhitemaneTooltipFix`.

Live verification remains necessary because the repository cannot run the
Whitemane client. The release check is: with RatingBuster enabled, hover an
upgraded dungeon item from a bag, loot roll, loot window, and auction listing;
confirm that RatingBuster still displays its calculations and no
`Tooltip.lua:102` error is recorded.

## Distribution and documentation

`WhitemaneTooltipFix` is the installable directory and can be zipped by itself.
The branch README will document that it is independent of BiSTooltip, explain
the exact RatingBuster/Whitemane incompatibility it addresses, and state that
it does not address the unrelated `!!!ClassicAPI` Wardrobe error.

The first release version will be `1.0.0`. The addon needs no commands,
configuration UI, or SavedVariables.
