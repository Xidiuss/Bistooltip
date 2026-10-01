# Targeted enhancement overrides

## Goal

Let a server plugin replace exactly the first enhancement recommendation for a class/spec/phase/slot while preserving every later gem or enhancement from the active ranking database. A rule may be global or gated by one profession owned by the current character.

The first production consumer is the WOTLK5 S2 plugin. Core remains free of WOTLK5 item IDs and role mappings.

## Confirmed WOTLK5 inputs

Trinket, Finger, Head and Shoulder are COMMON profession rules shared by every phase. Legendary Neck is phase-specific; the currently confirmed Neck rules apply only to `T7`.

### Enchanting — Trinket

These rules require Enchanting skill-line ID `333` and target the literal `Trinket` slot:

- tanks: spell `5000162` — 30 stamina;
- physical/AP DPS: spell `5000161` — 40 AP;
- caster/SP DPS and healers: spell `5000160` — 23 SP.

### Enchanting — Finger

These COMMON rules require Enchanting skill-line ID `333`:

- tanks: spell `59636`;
- physical/AP DPS: spell `44645`;
- caster/SP DPS and healers: spell `44636`.

### Inscription — Head

These rules require Inscription skill-line ID `773` and target `Head`:

- tanks: spell `5000158` — 110 stamina and 20 defense rating;
- physical/AP DPS: spell `5000156` — 150 AP and 20 crit;
- caster/SP DPS: spell `5000159` — 90 SP and 20 crit;
- healers: spell `5000157` — 90 SP and 10 mp5.

### Inscription — Shoulder

These COMMON rules require Inscription skill-line ID `773`:

- tanks: spell `61119`;
- physical/AP DPS: spell `61117`;
- caster/SP DPS: spell `61120`;
- healers: spell `61118`.

### Global legendary Neck

These rules do not require a profession and target `Neck`:

- tanks: item `5000766` — 600 dodge rating for 10 seconds, one-minute cooldown;
- DPS and healers: item `5000764` — 300 haste for 10 seconds, one-minute cooldown;
- Warlock Affliction only: item `5000765` — 300 crit rating for 10 seconds, one-minute cooldown, replacing the general DPS choice.

The existing acquisition records for `5000764`–`5000766` remain unchanged. No price or acquisition source is invented for `5000156`–`5000162`.

## Scope

This change covers:

- stable profession detection for the current player;
- one shared active-specialization detector used by `Your specialization`;
- Feral tank/DPS and Enhancement/Spellhance disambiguation;
- a declarative plugin API for one targeted enhancement override;
- optional profession gating and global rules through the same API;
- view-time resolution without mutating a ranking database;
- preservation of every `enhs` entry after index 1;
- migration cleanup for the retired personal-enchant state;
- confirmed WOTLK5 COMMON profession mappings, T7 Neck mappings and integration tests.

The later `TOKEN` icon change is a separate task and is not part of this implementation.

## Ownership

Core owns:

- reading the current player's class, active talent group, professions and equipped main-hand data;
- validating and storing immutable rule definitions;
- resolving global and profession-gated rules for a requested slot view;
- copying the base `enhs` list and replacing only index 1;
- exposing the active player class/spec to `Your specialization` consumers.

The server plugin owns:

- server-specific enhancement item/spell IDs;
- class/spec role mappings;
- phase, slot and optional profession targets.

## Public API

The old, unpublished full-list `DefineProfessionEnhancement` API is removed. Its replacement is:

```lua
BisTooltip:DefineEnhancementOverride({
    profession = 333, -- optional; nil means global
    class = "Druid",
    spec = "Feral tank",
    phase = nil,     -- optional; nil means COMMON across phases
    slot = "Trinket",
    enhancement = {type = "spell", id = 5000162},
}, "Bistooltip_WOTLK5_S2")
```

The phase-specific Neck rules use `phase = "T7"` instead.

`class`, `spec`, `slot`, `enhancement` and `plugin` are required. `phase` and `profession` are optional. A profession value must be a positive integer skill-line ID. Enhancement descriptors use the existing `item`, `spell` and `none` vocabulary.

Registration validates the complete shape immediately, stores a defensive copy and never writes into a bound ranking table. Duplicate identity is last-write-wins with a plugin-scoped diagnostic. Identity consists of profession-or-global, class, spec, phase-or-COMMON and slot.

Because this API has not been pushed or consumed by a released plugin, no compatibility alias for the full-list prototype is retained.

## Resolution

Resolution occurs while producing a slot view:

1. Read the unmodified slot from the currently bound ranking database, including ordinary replayed server data.
2. Consider a global rule for the requested class/spec/phase/slot regardless of the current player's class.
3. Consider profession-gated rules only when the requested class equals the current player's class.
4. Within one scope, prefer an exact phase over COMMON.
5. If one owned profession matches, it outranks a global rule for the same target. If multiple owned professions match, use no profession rule and emit a deterministic diagnostic; a global rule may still apply.
6. When a rule is selected, copy the slot and its `enhs` list, then assign a defensive copy of `rule.enhancement` to `enhs[1]`. An empty list thereby gains its first entry. Entries `enhs[2]` and later remain byte-for-byte equivalent to the active database values.

The former personal Enchant editor layer was retired after the plugin mappings became complete. Migration clears its saved state so it cannot mask a current plugin rule.

Rules are stored independently of overlay replay. Switching databases cannot leave stale overrides behind. A target absent from one database is a no-op there and may work after a later database switch.

## Role mapping

The WOTLK5 plugin defines explicit tables rather than guessing from names at runtime.

### Tanks

- Death knight: `Blood tank`
- Druid: `Feral tank`
- Paladin: `Protection`
- Warrior: `Protection`

### Physical/AP DPS

- Death knight: `Frost`, `Unholy`, `Blood dps`
- Druid: `Feral dps`
- Hunter: `Beast mastery`, `Marksmanship`, `Survival`
- Paladin: `Retribution`
- Rogue: `Assassination`, `Combat`
- Shaman: `Enhancement`
- Warrior: `Arms`, `Fury`

### Caster/SP DPS

- Druid: `Balance`
- Mage: `Arcane`, `Fire`, `Fire FFB`, `Frost`
- Priest: `Shadow`
- Shaman: `Elemental`
- Warlock: `Affliction`, `Demonology`, `Destruction`

### Healers

- Druid: `Restoration`
- Paladin: `Holy`
- Priest: `Discipline`, `Holy`
- Shaman: `Restoration`

`Fire FFB` exists only in databases that expose that profile. Missing class/spec/phase/slot paths do not fail plugin load because rules are resolved against the requested live view.

## Active specialization detection

The existing `BistooltipPlayerContext` design remains valid.

- The active talent tab comes from the active dual-spec group.
- Feral uses Protector of the Pack and Predatory Instincts signals; a hybrid is `Feral tank`, then form fallback, then tank fallback.
- Enhancement selects `Spellhance` only for positive main-hand spell stats and only when the active dataset exposes that profile; otherwise it remains `Enhancement`.
- Normal tabs keep their declared spec. Active talents and gear affect only `Your specialization`.

No current bundled database exposes `Spellhance`; the fallback remains tested for future data.

## Refresh behavior

Profession and gear context is read on demand. Talent-group, talent, equipment and profession events redraw visible tooltips and the main UI through guarded calls. Events may fire before UI construction without producing an error.

## Failure behavior

- On WoW 3.3.5a, resolve stable profession IDs through legacy skill-line and spellbook APIs; a client with no usable profession API or no matching profession uses the global rule or lower-layer recommendation.
- Requested class different from the player class: ignore profession-gated rules, but allow global rules.
- Malformed registration: reject it without changing other rules.
- Missing target in the active database: leave that view unchanged.
- Multiple owned professions matching one target: emit one diagnostic, ignore the profession matches and fall back to a global rule or base data.
- Missing main-hand stats or `Spellhance` profile: use `Enhancement`.

## Tests

Core tests cover:

- validation and defensive copies for global and profession-gated rules;
- exact phase over COMMON;
- profession-specific precedence over a global rule;
- deterministic behavior for two conflicting owned professions;
- same-class offspec application and other-class exclusion for profession rules;
- global rules on normal tabs regardless of player class;
- replacing index 1 of a populated list while preserving all later gems;
- adding index 1 to an empty `Trinket` list;
- cleanup of retired personal-enchant state without masking plugin rules;
- database switching without stale mutation;
- existing PlayerContext and refresh behavior.

The WOTLK5 integration test loads the real plugin and verifies:

- all confirmed COMMON profession mappings and T7 Neck mappings;
- Enchanting and Inscription gates;
- COMMON Trinket/Finger/Head/Shoulder behavior in PR/T7/T8/T9/T10/RS;
- T7-only global Neck behavior and unchanged Neck in other phases;
- the Affliction `5000765` exception;
- preservation of later enhancements and gems in every targeted slot;
- absence of invented acquisition data for `5000156`–`5000162`.

Native Lua 5.1, `luac5.1`, the package checker, actual-plugin integration and the existing Python release tests remain automated release gates. Live-client smoke testing covers dual-spec switching, both professions, representative role groups, Affliction, database switching and another-class tabs.

## Local history transition

The full-list prototype exists only in eight unpushed local commits after `bdfe161`. Before rewriting them, create a local safety ref at the current `HEAD`. Preserve the PlayerContext, TOC load order and refresh behavior; replace the registry/resolver commits and rewrite the design, plan and public documentation to describe targeted overrides. Do not push during this transition.
