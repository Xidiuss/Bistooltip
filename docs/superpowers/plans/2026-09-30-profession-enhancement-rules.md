# Targeted Enhancement Overrides Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace only `enhs[1]` through global or profession-gated plugin rules, preserve later gems, and ship COMMON WOTLK5 Trinket/Finger/Head/Shoulder mappings plus phase-specific Neck mappings.

**Architecture:** `PlayerContext.lua` remains the source of current class, spec and professions. `PluginAPI.lua` stores immutable `DefineEnhancementOverride` rules and resolves one descriptor, while `DataProvider.lua` copies the active slot and replaces only index 1. The WOTLK5 plugin owns explicit role tables and all custom IDs. The personal override described in the original execution sequence was retired on 2026-10-01 after plugin mappings became complete.

**Tech Stack:** WoW 3.3.5a API, Lua 5.1, AceAddon runtime, pure-Lua regression scripts, Node package checker, Python `unittest` release checks.

**Spec:** `docs/superpowers/specs/2026-09-30-profession-enhancement-rules-design.md`

## Global Constraints

- Core contains no WOTLK5 item IDs or role mappings.
- `DefineEnhancementOverride` replaces only `enhs[1]`; every later entry remains from the active database.
- A missing `enhs[1]` is created without introducing filler entries.
- Profession rules apply only to the current player's class; global rules apply to normal tabs for every class.
- Exact phase outranks COMMON; WOTLK5 profession slots use COMMON while the confirmed Neck rules use exactly `T7`.
- Personal enchant assignment remains the final, highest-priority layer.
- Enchanting and Inscription use skill-line IDs `333` and `773`.
- No acquisition or price is invented for `5000156`–`5000162`.
- Runtime code remains compatible with Lua 5.1 and WoW `Interface: 30300`.
- The current host lacks native Lua. Diagnostic fallback is `node ..\..\WhitemaneTooltipFix\node_modules\fengari-node-cli\src\lua-cli.js -e 'unpack=table.unpack; loadstring=load' <test.lua>`; inspect output for tracebacks because this runner may return exit 0 after a Lua assertion. It never satisfies the native gate.
- Do not push. Preserve the pre-rewrite state with a local backup ref before changing history.
- The `TOKEN` icon change begins only after this plan passes verification and history cleanup.

## Review Focus

- A global rule must still apply while viewing another class, but a profession-gated rule must not leak there; Task 2 tests both paths.
- An empty Trinket `enhs` table must gain index 1 without corrupting the slot or registry; Task 2 tests the empty-list boundary.
- Head and Neck overrides must preserve every later gem across database switches; Tasks 2 and 4 test real populated lists.
- Owning two professions that target one slot must be deterministic and must not silently depend on table order; Task 1 tests ambiguity and global fallback.
- Rewritten history must produce the byte-identical verified tree and preserve a recovery ref; Task 6 compares tree states after rebuilding commits.

---

### Task 1: Protect the current series and replace the registry contract

**Files:**
- Modify: `Bistooltip/PluginAPI.lua:21-60,300-540`
- Modify: `.github/tests/lua/test_plugin_boundaries.lua`

**Interfaces:**
- Consumes: enhancement descriptors `{type="item"|"spell"|"none", id=number}` and optional profession skill-line IDs.
- Produces: `BisTooltip:DefineEnhancementOverride(rule, plugin) -> true`; `BisTooltip:ResolveEnhancementOverride(className, specName, phase, slotName, professionSet, allowProfessionRules) -> enhancement|nil`.

- [ ] **Step 1: Create the recovery ref before changing implementation**

Run in `Bistooltip-main/core`:

```powershell
git status --short --branch
git branch backup/pre-targeted-enhancement-rewrite-20260930 HEAD
git show-ref --verify refs/heads/backup/pre-targeted-enhancement-rewrite-20260930
```

Expected: `main` is clean; the backup ref resolves to the pre-implementation-plan `HEAD`. Do not push the backup ref.

- [ ] **Step 2: Rewrite the boundary tests to the targeted API and verify red**

Replace full-list test cases with named cases asserting:

- required `class/spec/slot/enhancement/plugin` fields;
- optional positive integer `profession` and optional phase;
- `item`, `spell` and `none` descriptor validation;
- defensive copies at registration and resolution;
- exact phase over COMMON;
- profession-specific match over a global match;
- two owned profession matches produce one diagnostic and fall back to a global rule;
- replay neither duplicates nor removes registered rules;
- `DefineProfessionEnhancement` and `ResolveProfessionEnhancement` are absent.

Run:

```powershell
lua5.1 .github/tests/lua/test_plugin_boundaries.lua
```

Expected: FAIL because `DefineEnhancementOverride` does not exist.

If native Lua is unavailable, run the same test diagnostically through the existing Fengari CLI and inspect output for a traceback; do not label that result native Lua 5.1.

- [ ] **Step 3: Implement the targeted registry**

In `Bistooltip/PluginAPI.lua`:

- replace `ProfessionEnhancementRules` with one local override registry;
- key rules by profession-or-global/class/spec/phase-or-COMMON/slot;
- implement `DefineEnhancementOverride(rule, plugin)` with defensive storage;
- implement `ResolveEnhancementOverride(...)` with exact-phase precedence, profession-over-global precedence, deterministic ambiguity handling and a fresh returned descriptor;
- remove the unpublished full-list API and its complete-list validation path;
- keep the registry outside overlay replay.

- [ ] **Step 4: Run the focused boundary suite**

Run: `lua5.1 .github/tests/lua/test_plugin_boundaries.lua`

Expected: every named case passes and the final line is `plugin_boundaries: OK`.

- [ ] **Step 5: Commit the registry change**

```powershell
git add Bistooltip/PluginAPI.lua .github/tests/lua/test_plugin_boundaries.lua
git commit -m "feat: register targeted enhancement overrides"
```

### Task 2: Compose targeted overrides into defensive slot views

**Files:**
- Modify: `Bistooltip/DataProvider.lua:449-540`
- Modify: `.github/tests/lua/test_data_state.lua`

**Interfaces:**
- Consumes: `ResolveEnhancementOverride(...) -> enhancement|nil`, `BistooltipPlayerContext.GetPlayerClassKey()`, `GetProfessionSkillLines()`.
- Produces: unchanged `BistooltipData.GetSlotsForSpec(className, specName, phase)` with an effective copied `slot.enhs`.

- [ ] **Step 1: Write failing slot-composition tests**

Add assertions for:

- same-class offspec profession application;
- other-class profession exclusion;
- global rule application on another-class normal tabs;
- profession rule precedence over a global target;
- replacing only index 1 while indices 2..n remain equal to base gems;
- adding index 1 to an empty Trinket list;
- mutation isolation between one returned view, the registry and later reads;
- cleanup of retired personal-override state without masking the automatic rule;
- exact phase only, COMMON fallback and clean database round trips.

Run: `lua5.1 .github/tests/lua/test_data_state.lua`

Expected: FAIL because `DataProvider` still requests a full list from `ResolveProfessionEnhancement`.

- [ ] **Step 2: Implement first-entry view composition**

In `GetSlotsForSpec`:

- request one descriptor from `ResolveEnhancementOverride`;
- permit global resolution for every requested class;
- permit profession resolution only when requested class equals the player's class;
- copy the slot and `enhs` table only when an automatic or personal layer applies;
- assign the automatic descriptor to `view.enhs[1]` without touching later entries;
- apply the existing personal descriptor to index 1 last;
- never mutate the bound dataset or registry.

- [ ] **Step 3: Run state and boundary suites**

```powershell
lua5.1 .github/tests/lua/test_data_state.lua
lua5.1 .github/tests/lua/test_plugin_boundaries.lua
```

Expected: both suites end in `OK`.

- [ ] **Step 4: Commit view composition**

```powershell
git add Bistooltip/DataProvider.lua .github/tests/lua/test_data_state.lua
git commit -m "feat: apply targeted enhancement overrides"
```

### Task 3: Register the confirmed WOTLK5 T7 rules

**Files:**
- Modify: `../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua`
- Create: `../wotlk5-s2/.github/tests/lua/test_enhancement_rules.lua`

**Interfaces:**
- Consumes: `BisTooltip:DefineEnhancementOverride(rule, "Bistooltip_WOTLK5_S2")` from Task 1.
- Produces: four COMMON profession overrides and one T7 Neck override for every declared role profile; 160 unique rule identities across 32 profiles.

- [ ] **Step 1: Write the failing standalone plugin test**

Stub `AddAcquisition`, `SetAcquisition` and `DefineEnhancementOverride`, load the actual plugin, then assert:

- 160 unique rules and no target duplicates;
- Trinket/Finger/Head/Shoulder omit phase (COMMON), while Neck uses `T7`;
- all Trinket rules use profession `333`, spell descriptors and IDs `5000160`–`5000162` by role;
- all Finger rules use profession `333` and spells `59636`/`44645`/`44636` by role;
- all Head rules use profession `773`, spell descriptors and IDs `5000156`–`5000159` by role;
- all Shoulder rules use profession `773` and spells `61119`/`61117`/`61120`/`61118` by role;
- all Neck rules omit profession and use `5000764`/`5000766`, except Warlock Affliction uses only `5000765`;
- the four tank, thirteen AP DPS, ten SP DPS and five healer profiles exactly cover 32 unique class/spec pairs;
- acquisition methods are not called for `5000156`–`5000162`.

Run from `Bistooltip-main/wotlk5-s2`:

```powershell
lua5.1 .github/tests/lua/test_enhancement_rules.lua
```

Expected: FAIL because the plugin registers zero override rules.

- [ ] **Step 2: Add explicit role tables and registration loops**

In `Bistooltip_WOTLK5_S2/main.lua`, add local tank/AP/SP/healer class-spec tables near the enchant section. Register five rules per profile:

- `Trinket`, COMMON, profession `333`, role-specific spell;
- `Finger`, COMMON, profession `333`, role-specific spell;
- `Head`, COMMON, profession `773`, role-specific spell;
- `Shoulder`, COMMON, profession `773`, role-specific spell;
- `Neck`, no profession, role-specific item with the Affliction exception.

Use `P` as the plugin name. Omit `phase` for the four profession rules and use exactly `T7` only for Neck. Keep existing neck acquisition records unchanged and add no acquisition entry for `5000156`–`5000162`.

- [ ] **Step 3: Run the plugin rule test**

Run: `lua5.1 .github/tests/lua/test_enhancement_rules.lua`

Expected: final line `wotlk5_enhancement_rules: OK (160 rules)`.

- [ ] **Step 4: Run actual core-plugin integration**

From `Bistooltip-main/core`:

```powershell
lua5.1 .github/tests/lua/test_server_plugins.lua ../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua
```

Expected: six successful faction/database combinations and no registration error.

- [ ] **Step 5: Commit on the WOTLK5 worktree**

```powershell
git -C ../wotlk5-s2 add Bistooltip_WOTLK5_S2/main.lua .github/tests/lua/test_enhancement_rules.lua
git -C ../wotlk5-s2 commit -m "feat: recommend WOTLK5 T7 enhancements"
```

### Task 4: Prove real slot preservation across core and WOTLK5

**Files:**
- Modify: `.github/tests/lua/test_server_plugins.lua`
- Test: `../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua`

**Interfaces:**
- Consumes: real WOTLK5 rules and core view composition from Tasks 1–3.
- Produces: integration evidence using actual COMMON profession slots across phases and the T7 Neck slot from every bundled database/faction binding.

- [ ] **Step 1: Add targeted integration assertions and verify red if the composition is bypassed**

Extend the harness so the WOTLK5 path asserts representative tank, AP, SP, healer and Affliction views with controlled profession sets. For every targeted slot, snapshot indices 2..n before resolution and assert they are unchanged afterward. Assert COMMON profession slots apply in PR/T8/T9/T10/RS and that Neck retains its original value outside T7.

Run both faction/database matrices. Expected before final harness wiring: FAIL on missing resolved-view assertions.

- [ ] **Step 2: Complete only the harness wiring required to use public core APIs**

Do not add WOTLK IDs to core test fixtures. Load the sibling plugin path supplied to the test and exercise `GetSlotsForSpec` through the same bound-data path used at runtime.

- [ ] **Step 3: Run both actual plugin matrices**

```powershell
lua5.1 .github/tests/lua/test_server_plugins.lua ../whitemane-frostmourne/Bistooltip_Whitemane_Frostmourne/main.lua
lua5.1 .github/tests/lua/test_server_plugins.lua ../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua
```

Expected: Whitemane remains unchanged; WOTLK5 passes the new targeted assertions for all six bindings.

- [ ] **Step 4: Commit the integration coverage on core**

```powershell
git add .github/tests/lua/test_server_plugins.lua
git commit -m "test: cover WOTLK5 enhancement overrides"
```

### Task 5: Align public documentation and release notes

**Files:**
- Modify: `README.md`
- Modify: `Bistooltip/CHANGELOG.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/PLUGIN-API.md`
- Modify: `../wotlk5-s2/README.md`
- Modify: `docs/superpowers/plans/2026-09-30-profession-enhancement-rules.md` only to check completed steps or correct commands discovered during execution

**Interfaces:**
- Consumes: final API and mappings from Tasks 1–4.
- Produces: accurate author/user documentation for targeted index-1 overrides.

- [ ] **Step 1: Rewrite the core documentation**

Document `DefineEnhancementOverride`, optional profession/global scope, phase precedence, index-1-only replacement, later-gem preservation, personal priority, ambiguity behavior and database-switch safety. Remove every claim that automatic rules replace a complete list.

- [ ] **Step 2: Update WOTLK5 documentation**

Describe the confirmed role groups, COMMON profession gates, phase-specific Neck behavior and Affliction exception. State that `5000156`–`5000162` have no invented acquisition data.

- [ ] **Step 3: Scan for stale terminology**

Run:

```powershell
rg -n "DefineProfessionEnhancement|ResolveProfessionEnhancement|whole-list|complete enhancement list" README.md Bistooltip docs .github/tests ../wotlk5-s2
```

Expected: no stale API references outside historical diff/backup data; current documentation and tests use targeted override terminology.

- [ ] **Step 4: Commit documentation in each owning worktree**

Core:

```powershell
git add README.md Bistooltip/CHANGELOG.md docs/ARCHITECTURE.md docs/DEVELOPMENT.md docs/PLUGIN-API.md
git commit -m "docs: describe targeted enhancement overrides"
```

WOTLK5:

```powershell
git -C ../wotlk5-s2 add README.md
git -C ../wotlk5-s2 commit -m "docs: describe T7 enhancement recommendations"
```

### Task 6: Run the complete gate and rebuild clean local history

**Files:**
- Verify: every file modified in Tasks 1–5
- Update after verification: workspace-root `task_plan.md`, `progress.md`, `findings.md` outside Git

**Interfaces:**
- Consumes: verified core and WOTLK5 trees.
- Produces: clean, recoverable local histories and a handoff for native/client validation.

- [ ] **Step 1: Run syntax and package checks**

```powershell
luac5.1 -p Bistooltip/PlayerContext.lua
luac5.1 -p Bistooltip/PluginAPI.lua
luac5.1 -p Bistooltip/DataProvider.lua
luac5.1 -p Bistooltip/Bistooltip.lua
luac5.1 -p ../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua
node .github/tests/check_package.cjs
```

Expected: all commands exit 0 and package check reports success. If native Lua is unavailable, record that gate as pending and run diagnostic `loadfile` through Fengari without relabeling it native.

- [ ] **Step 2: Run every regression and release test**

```powershell
Get-ChildItem .github/tests/lua/test_*.lua |
    Where-Object Name -ne 'test_server_plugins.lua' |
    ForEach-Object {
        & lua5.1 $_.FullName
        if ($LASTEXITCODE -ne 0) { throw "Lua regression failed: $($_.Name)" }
    }
lua5.1 .github/tests/lua/test_server_plugins.lua ../whitemane-frostmourne/Bistooltip_Whitemane_Frostmourne/main.lua
lua5.1 .github/tests/lua/test_server_plugins.lua ../wotlk5-s2/Bistooltip_WOTLK5_S2/main.lua
lua5.1 ../wotlk5-s2/.github/tests/lua/test_enhancement_rules.lua
$pythonExe = Resolve-Path '.\.superpowers\sdd\2026-09-16-github-discord-release-notification\uv-python\cpython-3.13.13-windows-x86_64-none\python.exe'
& $pythonExe -m unittest discover -s .github/tests -p 'test_*.py' -v
```

Expected: all suites pass; native Lua results remain distinct from diagnostic fallback results.

- [ ] **Step 3: Capture the verified pre-rewrite tree**

```powershell
git status --short --branch
git branch backup/verified-targeted-enhancements-20260930 HEAD
git rev-parse backup/verified-targeted-enhancements-20260930^{tree}
```

Expected: core is clean and the verified backup tree OID is recorded.

- [ ] **Step 4: Rebuild the core commits after `bdfe161`**

With both backup refs verified, move only local `main` back to `bdfe161` while preserving the working tree, then recreate these logical commits:

1. `docs: design targeted enhancement overrides` — spec and implementation plan plus the ROADMAP line;
2. `feat: detect player professions and hybrid specs` — `PlayerContext.lua`, its test and TOC load order;
3. `feat: apply targeted enhancement overrides` — PluginAPI, DataProvider and their focused tests;
4. `feat: refresh enhancements on player context changes` — runtime refresh and test;
5. `test: cover WOTLK5 enhancement overrides` — actual-plugin integration harness;
6. `docs: describe targeted enhancement overrides` — public core documentation.

Use a mixed reset only after confirming both backup refs:

```powershell
git reset --mixed bdfe161
```

Stage only the files named for each logical commit. Do not amend or rewrite the WOTLK5 branch.

- [ ] **Step 5: Prove the rewritten tree is identical**

```powershell
git diff --exit-code 'backup/verified-targeted-enhancements-20260930^{tree}' 'HEAD^{tree}'
git diff --check bdfe161..HEAD
git status --short --branch
git rev-list --left-right --count HEAD...origin/main
git -C ../wotlk5-s2 status --short --branch
git -C ../wotlk5-s2 rev-list --left-right --count HEAD...origin/Bistooltip_WOTLK5_S2
```

Expected: identical tree, no whitespace errors, both worktrees clean and no branch behind its fetched upstream.

- [ ] **Step 6: Update the canonical workspace handoff**

Mark completed implementation phases in root `task_plan.md`; record commit hashes, exact test evidence and remaining native/client gates in `progress.md`; replace design uncertainties with observed behavior in `findings.md`. Set the next active task to the separately scoped `TOKEN` icon design only after the enhancement work is verified.

### Task 7: Live-client handoff

**Files:**
- Modify: `docs/DEVELOPMENT.md` only if the smoke run exposes an inaccurate step

**Interfaces:**
- Consumes: rewritten core commits and the matching WOTLK5 plugin commit.
- Produces: manual evidence without conflating it with automated stubs.

- [ ] **Step 1: Record the test build inputs**

Record core commit, WOTLK5 commit, realm, faction, database, class/spec, phase T7, professions and enabled addons.

- [ ] **Step 2: Run representative T7 checks in WoW 3.3.5a**

Cover one tank, AP DPS, SP DPS, healer and Warlock Affliction. Verify Trinket/Finger only with Enchanting, Head/Shoulder only with Inscription across multiple phases, Neck only in its declared phase, preserved later gems, dual-spec refresh and another-class tabs.

- [ ] **Step 3: Record results separately**

Do not mark native Lua or live-client behavior passed unless actually observed. After recording the result, begin the separate `TOKEN` icon task from the canonical root plan.
