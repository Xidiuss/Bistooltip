# Native Source Item Icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render exact native item icons instead of the literal `TOKEN` and `TROPHY` labels in source lines.

**Architecture:** Add exact token item IDs to the acquisition contract and generated data. Keep the shared formatter deterministic by accepting an optional texture resolver; runtime UI callers supply a native `GetItemInfo` resolver while unresolved textures retain the current textual labels.

**Tech Stack:** Lua 5.1 / WoW 3.3.5 API, offline Lua data generator, Fengari diagnostics, Python release tests.

**Spec:** `docs/superpowers/specs/2026-09-30-source-item-icons-design.md`

## Global Constraints

- Work only in the core worktree on branch `main`; do not push.
- `MARK` and all non-TOKEN/non-TROPHY output remain unchanged.
- Plain formatting without a resolver stays deterministic and suitable for deduplication.
- Missing or uncached textures retain the literal `TOKEN` or `TROPHY` fallback.
- `Private/Legacy` tooling is offline and cannot be claimed as committed.

## Review Focus

- A cold item cache must retain readable source text and never suppress a line.
- Multiple tokens with the same family but different slot or difficulty must receive distinct correct IDs.
- A malformed plugin TOKEN entry must fail before it can affect runtime data.
- Trophy quantities and remaining currency costs must remain byte-for-byte equivalent apart from the replaced label.
- Icon-aware output must not destabilize plain-line deduplication.

---

### Task 1: Lock the acquisition contract with failing tests

**Files:**
- Modify: `.github/tests/lua/test_data_integrity.lua`
- Modify: `.github/tests/lua/test_plugin_boundaries.lua`
- Modify: `BiSTooltip/PluginAPI.lua`

**Interfaces:**
- Produces: validated `TOKEN.tokenItem: positive integer`, included in acquisition identity.
- Consumes: existing `AddAcquisition` and `ReplaceAcquisitions` validation paths.

- [x] Add tests requiring `tokenItem` on TOKEN entries, rejecting invalid values and proving two otherwise identical TOKEN entries with distinct token IDs are not deduplicated.
- [x] Run the focused Lua diagnostics and observe the new assertions fail for the missing contract.
- [x] Implement validation and identity support in `PluginAPI.lua`.
- [x] Re-run the focused diagnostics and verify they pass.
- [x] Commit the contract and tests.

### Task 2: Generate exact token IDs

**Files:**
- Modify: `Private/Legacy/tools/migrate_sources.lua`
- Modify: `Private/Legacy/tools/check_sources.lua`
- Modify: `BiSTooltip/ItemAcquisition.lua`
- Modify: `.github/tests/lua/test_data_integrity.lua`

**Interfaces:**
- Consumes: Task 1 `TOKEN.tokenItem` contract.
- Produces: every generated TOKEN entry has the exact token item ID.

- [x] Add integrity assertions for complete TOKEN coverage and representative T7/T8/T9 exact mappings; run them and observe failure.
- [x] Teach the migrator to retain the matched `TOKEN_PAGES` item ID and map Grand Conqueror/Protector/Vanquisher to `47557/47558/47559`.
- [x] Extend the offline checker to validate IDs against tier, family, slot, difficulty, and T9 family.
- [x] Regenerate `ItemAcquisition.lua`, run the checker and focused integrity suite, and verify green output.
- [x] Commit the generated runtime data and core test; record the unversioned tooling edits separately.

### Task 3: Render TOKEN and TROPHY icons with native fallback

**Files:**
- Modify: `BiSTooltip/SourceFormatter.lua`
- Modify: `BiSTooltip/Bistooltip.lua`
- Modify: `BiSTooltip/DataProvider.lua`
- Modify: `BiSTooltip/BislistUI.lua`
- Modify: `.github/tests/lua/test_data_integrity.lua`
- Modify: `.github/tests/lua/test_plugin_boundaries.lua`

**Interfaces:**
- Consumes: `entry.tokenItem` and TROPHY cost item `47242`.
- Produces: `BisTooltip_FormatSource(entry, resolveTexture?)` and `BisTooltip_FormatSourceColored(entry, resolveTexture?)`, where `resolveTexture(itemID)` returns a texture path or nil.

- [x] Add formatter tests for exact TOKEN/TROPHY icon output, unchanged cost text, unchanged plain output without a resolver, and nil-resolver fallbacks; run and observe failure.
- [x] Add a native resolver using the texture returned by `GetItemInfo(itemID)` and pass it only from display paths.
- [x] Extend the shared formatter to replace only the method label when a texture resolves.
- [x] Run focused formatter/runtime suites and verify all new and existing assertions pass.
- [x] Commit runtime rendering and tests.

### Task 4: Document and verify the complete change

**Files:**
- Modify: `BiSTooltip/CHANGELOG.md`
- Modify: `docs/PLUGIN-API.md`
- Modify: `D:/PROJEKTY/BIS_project/task_plan.md`
- Modify: `D:/PROJEKTY/BIS_project/progress.md`
- Modify: `D:/PROJEKTY/BIS_project/findings.md`

**Interfaces:**
- Consumes: completed data and renderer contracts.
- Produces: current documentation and reproducible verification evidence.

- [x] Document `tokenItem`, native TOKEN/TROPHY icons, and cold-cache fallbacks.
- [x] Run syntax diagnostics, package validation, all core Lua suites, real plugin suites, offline checker, and Python tests; inspect every output.
- [ ] Run `git diff --check`, verify the core branch/status and local/remote divergence, and update the three root state files with exact evidence.
- [ ] Commit versioned documentation; do not push.
