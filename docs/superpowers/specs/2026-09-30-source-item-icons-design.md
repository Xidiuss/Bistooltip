# Native source item icons

## Goal

Replace the literal `TOKEN` and `TROPHY` method labels in rendered acquisition
lines with the native WoW item icon for the exact required item, without
changing acquisition semantics or hiding a source when the client cache is
cold.

## Data contract

- Every `kind = "TOKEN"` entry carries `tokenItem = <positive item ID>`.
- T7/T8 `tokenItem` is selected by tier, family, slot, and difficulty from the
  existing `TOKEN_PAGES` oracle mapping.
- T9 uses the established Grand Regalia mapping: Conqueror `47557`, Protector
  `47558`, Vanquisher `47559`.
- `displayVariant = "TROPHY"` continues to derive its icon item from the cost
  component `{ item = 47242, ... }`; no duplicate `trophyItem` field is added.
- `MARK`, ordinary `VENDOR`, `DROP`, `CUSTOM`, and `ACTIVITY` are unchanged.

## Rendering

The formatter remains deterministic unless an optional icon resolver is
provided. The resolver receives an item ID and returns a texture path or nil.
UI callers provide a native resolver backed by the WotLK `GetItemInfo` texture
return.

With a resolved texture:

- `T8 - TOKEN: Wayward Vanquisher [...]` becomes
  `T8 - |T<texture>:14|t Wayward Vanquisher [...]`.
- `T9 - TROPHY: Crusade + 75 Emblem of Triumph` becomes
  `T9 - |T<texture>:14|t Crusade + 75 Emblem of Triumph`.

If the ID is missing, malformed, or its texture is not cached, the existing
literal `TOKEN` or `TROPHY` remains as a readable fallback. The plain formatter
without a resolver remains stable for deduplication and non-UI consumers.

## Validation and generation

Plugin API validation accepts `tokenItem` only for `TOKEN`, requires a positive
whole number, includes it in acquisition identity, and rejects TOKEN entries
without it. The offline migrator emits it for token items and final T7/T8/T9
set gear. The checker proves each emitted ID matches the oracle mapping.

`Private/Legacy` remains offline, unversioned tooling. Its regenerated runtime
output is committed only in the core worktree.

## Verification

- Formatter tests cover TOKEN and TROPHY icon success and cold-cache fallback.
- Integrity tests cover every real TOKEN entry and representative exact
  T7/T8/T9 mappings.
- Plugin boundary tests cover validation and identity behavior.
- Existing Lua diagnostics, package validation, plugin tests, and Python tests
  remain green.
- A final in-client smoke test remains necessary to visually confirm icon size
  and baseline in WoW 3.3.5a.
