# BiSTooltip Changelog

## 3.0.0 — 2026-10-01

- Stabilized the MAIN, BIS, and VENDOR views so database changes, frame reopening, filtering, and overlay replay do not duplicate, omit, or retain stale rows.
- Added clear acquisition details for drops, tokens, marks, vendors, activities, and custom sources, including multi-part costs and separate vendor offers.
- Added native token and Trophy of the Crusade icons with readable text fallbacks while item textures are uncached.
- Added bounded item-cache loading with retry progress, unavailable-item reporting, and protection from late callbacks that belong to an older selection.
- Added independent controls for tooltip source lines and the BIS-window SOURCE column.
- Stabilized live CTRL/SHIFT tooltip refreshes by reusing native bag and equipped-item update paths without replacing their item context.
- Added a compact, button-styled account-wide database selector after **EXPORT** for **WoWSimsBP (STANDARD)** and **wowtbc.gg**, preserving the viewed profile by name when possible.
- Added account-wide 70–130% window scaling through a two-column Interface Options layout and a lower-right drag grip, with reset controls in both locations.
- Added replay-safe server overlays for custom sources, acquisition routes, ranking changes, and automatic enhancement recommendations.
- Replaced routine acquisition-replacement diagnostics with one successful load message from each server plugin while retaining actionable warnings.
- Added profession-aware server recommendations that preserve later gems, follow the active dual specialization, and support legacy WoW 3.3.5a profession detection.
- Improved faction-aware rankings, personal item priorities, ownership progress, vendor filtering, export output, and source formatting.
- Removed the obsolete personal enhancement override UI and its saved layer; server plugins are now the single owner of automatic custom recommendations.
- Corrected standard vendor prices and expanded package validation, Lua regression coverage, plugin integration checks, and release-tree hygiene.
- Packaged Core as a standalone addon with optional, separately installed Scanner and server-plugin components.
