# Server data API

Install a separate addon with `## Interface: 30300` and `## Dependencies: Bistooltip`. Load its data after the core. The API object is `BisTooltip`; the AceAddon/UI object is `BistooltipAddon`. They are intentionally different objects.

Core rankings are selected independently of server data. Enable the one server overlay that applies to the current realm. Overlays do not perform automatic server detection or mutual exclusion; when several are enabled, their writes follow addon load order.

| Call | Meaning |
| --- | --- |
| `DefineSource(sourceID, definition, plugin)` | Replace/register source facts |
| `SetAcquisition(itemID, entries, plugin)` | Replace **all** acquisition routes for an item |
| `AddAcquisition(itemID, entry, plugin)` | Append an alternative, deduplicating an identical entry |
| `SetBiSSlot(class, spec, phase, slot, IDs, plugin)` | Replace a complete rank list, preserving slot metadata |
| `SetBiSSlotRank(class, spec, phase, slot, rank, itemID, plugin)` | Replace one existing rank |
| `InsertBiSSlotRank(class, spec, phase, slot, rank, itemID, plugin)` | Insert at a rank and shift later items; move an item already in the slot |
| `SetEnhancement(class, spec, phase, slot, enhancements, plugin)` | Replace enhancements; `phase=nil` applies to every existing phase of the spec |

Pass an identifying plugin string for useful diagnostics. Entries are validated before application. Unknown source IDs may be forward references: define them before the player uses the source. Invalid ranking paths raise errors; both rank methods defer targets present in another bundled database for a later compatible bind. Deferral does not create a missing phase and is not a general registration queue for every API method. `SetBiSSlotRank` accepts an existing rank; `InsertBiSSlotRank` accepts ranks through one past the current end.

Successful operations are recorded for replay after a database switch. Each replay receives fresh argument copies so later appends cannot mutate a recorded replacement. Optional arguments retain their positions, including the nil COMMON phase. Do not modify core tables directly: such mutations bypass the replay contract. The active ranking tables are mutable copies; original dataset slots and Horde overrides stay unchanged. The effective order is database, then server changes, then the user's saved personal order.

## Acquisition records

Source definitions normally contain `instance`, `boss`, and `difficulty`. The stock difficulty vocabulary is `""`, `HC`, `10N`, `25N`, `10HC`, `25HC`, `10HM`, `25HM`. A custom definition instead uses `{kind="CUSTOM", label="..."}`. Display names live with source facts; there is no separate DisplayNames registry.

```lua
local P = "MyServer"
BisTooltip:DefineSource("MYSERVER_DUNGEON_BOSS", {
    instance = "Custom dungeon", boss = "Boss", difficulty = "HC",
}, P)
BisTooltip:AddAcquisition(900001, {
    kind = "DROP", source = "MYSERVER_DUNGEON_BOSS",
}, P)
BisTooltip:AddAcquisition(900001, {
    kind = "VENDOR", cost = {
        {currency = "Justice Points", amount = 50},
        {currency = "Gold", amount = 10000}, -- one gold, stored as copper
        {item = 900002, amount = 2},
    },
}, P)
```

These IDs/names are illustrative, not supplied server data. Named currencies are labels with amounts; there is no mandatory currency registry. Item-based costs retain item IDs and render with an `Item #ID` fallback. All cost parts in one acquisition are required together; multiple acquisition records represent alternatives. An empty cost list means the source has no recorded price, not proof that it is free.

`DROP` references a source. `TOKEN` and `MARK` additionally require `tier` and `family`; use them only for verified tier membership. `VENDOR` carries `cost`; optional `tier`, `displayVariant="TROPHY"`, and `variantLabel` control tier presentation. `CUSTOM` uses a nonempty label, for example a shop description; use VENDOR when you need structured prices.

The VENDOR filter includes VENDOR and CUSTOM entries, with one purchasable item per row. Simple one-part prices can be totaled by their unit; gold is displayed as gold/silver/copper, not raw copper. Compound prices, alternative purchases and unspecified prices display **See item sources** instead of an incomplete budget and **Details** in the COST cell. Full purchase lines remain available in source text and `/bisemblem`.

## Rankings and enhancements

Use exact dataset class/spec/phase/slot names. A ranking override does not automatically add acquisition facts, and acquisition facts alone do not put a new item into a ranking. Similarly, a vendor record for an enchant scroll does not make it a recommended enhancement: call `SetEnhancement` with an item or spell descriptor for a compatible slot.

```lua
BisTooltip:SetBiSSlotRank("Druid", "Balance", "T10", "Head", 1, 900001, P)
-- Use InsertBiSSlotRank instead when the old rank 1 should become rank 2:
BisTooltip:InsertBiSSlotRank("Druid", "Balance", "T10", "Weapon", 1, 900004, P)
BisTooltip:SetEnhancement("Druid", "Balance", "T10", "Head", {
    {type = "item", id = 900003}, -- custom scroll, requested through GetItemInfo
}, P)
```

Enhancements are whole-list replacement, not append. Spell entries use `{type="spell", id=spellID}` and must not be queried as item IDs. Test the plugin on every intended ranking database and faction, including initial login, not only replay.

An insertion keeps all existing alternatives in the data; inserting an ID already present moves it without duplication. MAIN and CUSTOM currently show seven ranked icons per slot. If future overlays produce longer lists, the remaining ranks still exist in the data but need additional UI space to appear in those views.

## Scanner handoff

The Scanner branch collects merchant observations and exports text; it does not install or execute generated plugins. Review output before using it. Its default `SetAcquisition` export replaces routes, and multi-merchant logs keep one record per item ID. Convert a reviewed addition to `AddAcquisition` when it should retain existing core drops. Re-scan observations collected with an older scanner if Honor/Arena/token costs were omitted.

See [development checks](DEVELOPMENT.md) for the real-plugin matrix. The existing Whitemane and WOTLK5 packages demonstrate additive costs; Whitemane also demonstrates rank changes. WOTLK5's scroll prices do not currently include enhancement recommendations.
