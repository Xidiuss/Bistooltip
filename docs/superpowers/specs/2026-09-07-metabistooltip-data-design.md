# Meta-BisTooltip — Data System Design (S1–S4 FROZEN)

Status: **DESIGN FROZEN** (S1–S4) — oczekuje na review przed planem implementacji.
Data: 2026-09-07. Klasyfikacja: architectural.

## 0. Cel i kontekst

Jeden addon bazowy (`Bistooltip`) z dobrze zoptymalizowaną listą przedmiotów
i ich source dla serwerów bez customów + lekkie wtyczki serwerów prywatnych
(np. `Bistooltip_MojSerwer`) opisujące **wyłącznie różnice wobec Standardu**:
custom itemy, marki, enchants, zmienione source, zmienione rankingi BiS.

Stan wejściowy (zinwentaryzowany):
- `Loot_Sources.lua`: `lootTable[zone][boss] = {itemIDs}` + O(N) skan
  w `findSourceInLootTable()` (`Bistooltip.lua:426-450`).
- `EmblemData.lua`: `Bistooltip_emblem_items[itemID] = {currency, cost}`.
- `DataProvider.lua` / `Bistooltip.lua`: dual-source (raid + emblem), heurystyka
  `GetInstanceDifficulty()` zgadująca z substringów.
- Trzy bazy rankingowe: `Bistooltip_wowtbc_bislists.lua` (810 KB),
  `Bistooltip_wh_bislists.lua` (671 KB), `Bistooltip_WoWSimsBP_bislists.lua`
  (1,9 MB) + plik custom items w root. Wszystkie: `BIS[class][spec][phase][slot] = {itemIDs}`.
- ORACLE offline: Pazzions AtlasLoot `wrathofthelichking.lua`
  (`AtlasLoot_Data["BossKey"] = {{idx,itemID,...}}`), licencja GPLv2.

Decyzje przekrojowe (frozen):
- Zakres wtyczek: **wszystko incl. BiS listy i enhancements**.
- Semantyka nadpisywania: **replace-wins** (ostatnia wtyczka wygrywa).
- Brak nowego cache/invalidation frameworka do czasu pomiaru.
- Żadnej nowej warstwy architektonicznej poza domkniętym rdzeniem poniżej.

Zamknięty rdzeń:

```text
BIS (ranking ID-only)
ItemAcquisition (itemID -> metody zdobycia)
SourceRegistry (sourceID -> canonical fakty)
Enhancements (jedyny model gem/enchant)
MASTER Formatter (jedyna funkcja formatująca)
5-function Plugin API
offline migration + offline oracle (walidacja, nie runtime)
```

## S1. Model danych — FROZEN

Dwie tabele + referencja, zero redundancji instancji/bossa/difficulty.

### SourceRegistry[sourceID] — definicja miejsca, raz

```lua
SourceRegistry["ULDUAR_25N_VEZAX"] = { instance="Ulduar", boss="General Vezax", difficulty="25N" }
SourceRegistry["ICC_25HC_MARROWGAR"] = { instance="Icecrown Citadel", boss="Lord Marrowgar", difficulty="25HC" }
```

- Konwencja ID (klucz techniczny, nigdy nie pokazywany graczowi):
  `INSTANCJA_DIFFICULTY_BOSS` dla dropów,
  `TOKEN_T8_WAYWARD_THORIM_25N` dla tierów (szczegóły S2),
  `VENDOR_*` / `CUSTOM_*` dla vendorów/customów.
- Kanonizacja aliasów **przed** wpisem do rejestru (patrz S4):
  `AhnKahet / Ahn'kahet: The Old Kingdom / Ahn'Kahet (H)` → jeden wpis
  `{ instance="Ahn'kahet: The Old Kingdom", difficulty="H" }`.

### ItemAcquisition[itemID] — lista źródeł, O(1)

```lua
ItemAcquisition[49986] = { { kind="DROP", source="ULDUAR_25N_VEZAX" } } -- DROP może nieść opcjonalne tier (pochodzenie ze strefy Tier*)
ItemAcquisition[51834] = { -- mark z 2 realnych bossów: 2 wpisy, BEZ deduplikacji
  { kind="MARK", tier="T10", family="Protector", source="ICC_10HC_BOSS_A" },
  { kind="MARK", tier="T10", family="Protector", source="ICC_25N_BOSS_B" },
}
ItemAcquisition[48545] = {
  { kind="VENDOR", tier="T9", cost={ { currency="Emblem of Triumph", amount=50 } } },
}
ItemAcquisition[T9_245_ITEM] = { -- T9-245: semantycznie VENDOR, prezentacyjnie TROPHY (S2)
  { kind="VENDOR", tier="T9", displayVariant="TROPHY",
    cost={ { item=47242, amount=1 }, { currency="Emblem of Triumph", amount=75 } } },
}
```

Zasady (frozen):
- Brak wpisu = nieznane source (tooltip milczy, nie błąd).
- Wiele wpisów = wiele linii tooltip/UI, kolejność = kolejność wpisów.
- BiS listy trzymają **tylko ID**; source zawsze rozwiązywane live:
  `ItemAcquisition → SourceRegistry → FormatSource()`.
- Enchanty/gemy: **ten sam jedyny model `Enhancements`**
  (migracja 4→1 pozostaje frozen). Zakaz tworzenia `EnchantAcquisition`.

## S2. MASTER formatter — FROZEN (+2 korekty)

Jedna funkcja `BisTooltip.FormatSource(entry)` zamienia fakty na tekst.
Dane przechowują fakty, formatter tylko drukuje. Zero sklejania stringów poza nią.
Zero parserów nazw tokenów w runtime. Zero heurystyk difficulty.

Zamrożone wzory:

```text
DROP:    <Instance> [<Diff>] - <Boss> (puste difficulty bez nawiasów)
TOKEN:   <Tier> - TOKEN: <Family> [<Instance>: <Boss> <<Diff>>]
MARK:    <Tier> - MARK: <Family> [<Instance>: <Boss> <<Diff>>]
VENDOR:  <Tier> - VENDOR: <Cost> <Currency>
TROPHY:  T9 - TROPHY: Crusade + <Cost> <Currency>   (display wariant VENDOR T9-245)
```

Przykłady: `Ulduar [25N] - General Vezax`,
`T8 - TOKEN: Wayward Protector [Ulduar: Thorim <25N>]`,
`T10 - MARK: Protector [Icecrown Citadel: Deathbringer Saurfang <25N>]`,
`T9 - VENDOR: 50 Emblem of Triumph`,
`T9 - TROPHY: Crusade + 75 Emblem of Triumph`.

Korekta S2-1 (frozen): **TROPHY to wyłącznie nomenklatura DISPLAY**
dla kanonicznego VENDOR T9-245 (`displayVariant="TROPHY"` + koszt
`{item=47242} + {currency}`). Zakaz nowego acquisition type `TROPHY`.
Zakaz zgadywania po `item == 47242` w formatterze; zakaz enigmatycznych flag
typu `special=true`.

Korekta S2-2 (frozen): **dedup po finalnym stringu to wyłącznie ostatni guard**
(przed podwójną rejestracją core+plugin tej samej linii).
Normalizacja aliasów semantycznych odbywa się wcześniej w canonical
`SourceRegistry`. Formatter nie naprawia błędów danych.
`Saurfang != Putricide` → dwie linie, nawet przy tym samym instance+diff.

Pozostałe zasady S2 (frozen):
1. `family` zawsze krótka już w danych (`family="Wayward Protector"`,
   nie `Gloves of the Wayward Protector`). Ściąga pełna→krótka w komentarzu
   pliku danych, nie w kodzie.
2. `difficulty` to zamknięty słownik faktów (`10N/25N/10HC/25HC`, `H` dla
   5-man heroic, puste dla world/vendor). Usunąć `GetInstanceDifficulty()`.
3. `kind="CUSTOM"` omija szablony DROP/TOKEN/MARK/VENDOR, ale **nie omija
   walidacji strukturalnej**. Canonical shape:
   `{ kind="CUSTOM", label="VIP Shop — Donate Vendor" }`
   (`kind` + niepusty `label`); formatter zwraca po prostu `label`.
4. Nieznany `sourceID` (`SourceRegistry[id] == nil`): pomiń linię + jeden
   dev-warning per sesja, nigdy błąd Lua w tooltipie.

## S3. Plugin API — FROZEN (+4 korekty)

Frozen API — dokładnie 5 funkcji:

```text
DefineSource / SetAcquisition / AddAcquisition / SetBiSSlot / SetEnhancement
```

`DefineSource`, `SetAcquisition`, `SetBiSSlot`, `SetEnhancement` = replace-wins.
`AddAcquisition` = append.

```lua
BisTooltip:DefineSource("ULDUAR_25N_VEZAX", { instance="Ulduar", boss="General Vezax", difficulty="25N" })
BisTooltip:SetAcquisition(49986, { { kind="DROP", source="ULDUAR_25N_VEZAX" } }) -- pełny replace itemu
BisTooltip:AddAcquisition(999001, { kind="DROP", source="CUSTOM_ICC_VIP" })      -- dopisanie 1 linii
BisTooltip:SetBiSSlot("Warrior", "Fury", "T10", "Chest", { 999001, 51289, 50024 })
BisTooltip:SetEnhancement("Warrior", "Fury", "T10", "Weapon",
  { enchant={ type="spell", id=59621 }, gems={ 40111, 40111 } })
BisTooltip:SetEnhancement("Warrior", "Fury", nil, "Weapon", -- COMMON (wszystkie fazy)
  { enchant={ type="spell", id=59621 } })
BisTooltip:DefineSource("CUSTOM_VIP", { kind="CUSTOM", label="VIP Shop — Donate Vendor" })
```

Korekta S3-1 (frozen): brak `EnchantAcquisition`. Piąta funkcja to
`SetEnhancement(...)` na jedynym modelu `Enhancements`:
`Standard Enhancements + plugin override = effective Enhancements`.

Korekta S3-2 (frozen): wtyczka używa `## Dependencies: Bistooltip`
(twarda zależność — bez core nie ma sensu). Brak `_G.BisTooltip_Pending[]`,
brak drain queue, brak nowego lifecycle. `OptionalDeps` odrzucone.

Korekta S3-3 (frozen): CUSTOM wg kształtu z S2 (`kind` + `label`).

Korekta S3-4 (frozen): brak cache/invalidation frameworka.
Lookup już O(1), formatter tani. Cache tylko po pomiarze.
(Uwaga: `DefineSource` dotyka N itemów przez współdzielony sourceID —
precyzyjna invalidacja wymagałaby reverse indexu `sourceID → itemIDs`,
czyli kolejnego systemu. Nie budujemy go na zapas.)

Właściwość celowa (frozen): `DefineSource` na istniejącym ID zmienia źródło
wszystkich wskazujących itemów naraz + jednorazowy dev-warning
`Plugin X replaced core source <ID>` jako ochrona przed literówką.

Efekt docelowy:

```text
STANDARD (BIS + Acquisition + Sources + Enhancements)
+ Bistooltip_Whitemane (17 source, 38 acquisitions, 12 slotów, 6 enhancements)
= effective server data   (bez Whitemane_FullDatabase.lua)
```

## S4. Migracja + ORACLE + wydajność + skaner — FROZEN (+3 poprawki)

### Migracja Loot_Sources (frozen)

Jednorazowy migrator offline odwraca:

```text
STARE: zone -> boss -> itemID
NOWE:  ItemAcquisition[itemID] -> sourceID -> SourceRegistry
```

WoW nigdy więcej nie wykonuje `findSourceInLootTable()`.
`EmblemData` → wpisy `kind="VENDOR"` z kosztem strukturalnym
`{currency,item,amount}`; T9-245 z `displayVariant="TROPHY"`.
Każda baza rankingowa finalnie tylko:
`BIS[class][spec][phase][slot] = { itemID, itemID, ... }`
(bez source, gemów i enchantów w środku).

### Poprawka S4-1 (frozen): AUTHORITATIVE STANDARD BIS DATASET = NOT YET SELECTED

Nie zamrożono `Standard = wowtbc`. Wybór autorytetu BiS to osobny gate,
nie element mechaniki migracji. Założenie kierunkowe: ranking Standard
przede wszystkim o WoWSims, z Wowhead WotLK i RaidMasterSuite jako cross-check.
Przed wyborem wymagany census (bez budowania nowej bazy od zera):
czym różnią się `wowtbc` vs `WoWSimsBP` (coverage faz/speców),
czy `wh` to wyłącznie Whitemane,
która baza odpowiada Standardowi.
Po audycie: 1 authoritative Standard ranking + ewentualny Whitemane diff;
reszta wyłącznie jako migration/reference dataset, nie runtime.

### Poprawka S4-2 (frozen): AtlasLoot = OFFLINE ORACLE / VALIDATION SOURCE

Kierunek `AtlasLoot → offline oracle → nasza baza` frozen, ale:
AtlasLoot (GPLv2) służy do wykrywania braków, weryfikacji `boss → item`,
cross-check `instance/difficulty` i raportów rozbieżności —
**nie** do hurtowej konwersji całej zawartości do runtime MIT.
Importowane relacje wymagają właściwej klasyfikacji acquisition
(lekcja Stage 5: „źródło mówi, że relacja istnieje" ≠ „to jest acquisition
finalnego itemu") oraz provenance; fakty potwierdzone drugim źródłem tam,
gdzie AtlasLoot był jedynym dowodem.

### Wydajność (frozen)

`ItemAcquisition[itemID]` O(1) + `SourceRegistry[sourceID]` O(1)
zamiast potrójnej pętli `zone/boss/item`. Bez dodatkowego cache do pomiaru.

### Poprawka S4-3 (frozen): skaner generuje dokładnie API S3

Koncepcja frozen: mini-narzędzie `/bis scan` czyta otwarty vendor / item po ID
i drukuje gotowy snippet wtyczki (bez importera w core). Poprawione przykłady:

```lua
-- custom vendor (CUSTOM, nie instance/boss/difficulty):
BisTooltip:DefineSource("CUSTOM_VENDOR_1", { kind="CUSTOM", label="VIP Shop — Donate Vendor" })
BisTooltip:SetAcquisition(999001, { { kind="CUSTOM", label="VIP Shop — Donate Vendor" } })
-- raid scanner:
BisTooltip:DefineSource("ICC_25HC_LK",
  { instance="Icecrown Citadel", boss="The Lich King", difficulty="25HC" })
```

## Gate'y przed implementacją

1. Census 3 baz BiS → wybór authoritative Standard dataset.
2. Review niniejszego speca przez właściciela.
3. Potem: writing-plans → plan implementacji (migracja, formatter, API,
   usunięcie `findSourceInLootTable` + `GetInstanceDifficulty`, audyt ORACLE).

## Self-review speca

- Placeholdery: brak (poza świadomym NOT YET SELECTED + census gate).
- Spójność: TROPHY wyłącznie display; brak `EnchantAcquisition`;
  `Dependencies` bez pending queue; brak cache frameworka; CUSTOM walidowane.
- Zakres: jeden closed core, bez nowych warstw; skaner i build CSV poza zakresem MVP.
- Niejednoznaczności: konwencja ID source jest techniczna (dowolna, byle stabilna);
  COMMON enhancement = `phase=nil`; kolejność linii = kolejność wpisów.
