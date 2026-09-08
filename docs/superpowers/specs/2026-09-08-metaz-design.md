# META-Z — Meta-BisTooltip system design

Status: **DRAFT v2.4** — decyzje Q1–Q16 wdrożone; Q14 odwrócona po
weryfikacji upstream + refresh danych wykonany; v2.3: assembly frakcyjne
offline; v2.4: reprezentacja kompaktowa final (baza alliance + overrides
hordy w duchu horde_to_ali); oczekuje na plan implementacji.
Data: 2026-09-08. Gałąź: `META-Z` (utworzona z `feat/meta-bistooltip-data`,
pełna historia). Klasyfikacja: architectural.
Relacja: rozszerza **frozen** `2026-09-07-metabistooltip-data-design.md`
(S1–S4, wdrożone) o poprawki S2-3, S2-4, S2-5, S3-5, S3-6, S3-7, S4-5;
importuje frozen `2026-09-08-vendor-scanner-design.md` + jej plan. v2 wynika
z rewizji etapu przebudowy: `2026-09-08-metaz-stage-review.md` (dowody tam).
v2.1: decyzje Q&A + warstwa Personal BiS (§12). v2.2: Q14 odwrócona
(tabele frakcyjne żywe u upstream, port assembly w W4) + refresh danych
z upstream (provenance: github.com/ExoJdi/BiS-Tooltip_335a_fixed_backport,
commit 2026-06-09). v2.3: assembly frakcyjne OFFLINE (decyzja właściciela —
bez runtime merge w stylu WoWSimsBP; runtime = zwykły alias, generator
`tools/assemble_wowsims.lua`). v2.4: reprezentacja kompaktowa — baza
alliance + mapa nadpisań hordy (`..._horde_overrides`) zamiast dwóch
pełnych tabel (duch `horde_to_ali`; żądanie właściciela 2026-09-08).

## 0. Cel

Jeden addon-core dla czystego WotLK 3.3.5a (STANDARD = WoWSimsBP wg census)
+ przełączalne bazy rankingowe w opcjach + lekkie wtyczki serwerów prywatnych
(diff-only: custom itemy, waluty, koszty, enchants, nadpisania BiS)
+ standalone skaner vendorów produkujący snippet API S3.

Stan wejściowy na `feat/meta-bistooltip-data` (zmierzony, nie zgadywany):

- Zamknięty rdzeń S1–S4 **wdrożony**: `SourceRegistry.lua` (712 kluczy),
  `ItemAcquisition.lua` (7972 DROP + 848 VENDOR), czysty `SourceFormatter.lua`
  (golden testy), `PluginAPI.lua` (5 funkcji, walidacja, replace-wins),
  `tools/` (migrator, audytor, 3 suity testowe). Brak wspólnego runnera.
- Census: `STANDARD = WoWSimsBP`; `wh` = niezależny ranking referencyjny
  (spójność rank-1 z WoWSimsBP 63%), `wowtbc` = runtime reference z **27
  nadpisaniami rank-1 o ID customowych** (5 ID: 128858, 130023, 130031,
  131004, 150005). Pliki `wh`/`WoWSimsBP` były untracked — od teraz trackowane
  na META-Z.
- Przełączanie baz: machineria istnieje (`Config.lua`: `sources`,
  `db.char.data_source`, `EnableSpec` aliasuje `Bistooltip_bislists/classes/
  phases`), ale zarejestrowana jest wyłącznie baza `wowtbc`.
- Luki danych (potwierdzone problemy użytkownika):
  a) **Vault of Archavon nie istnieje** w SourceRegistry/ItemAcquisition
     (0 trafień dla Archavon/Emalon/Koralon/Toravon).
  b) **kind="TOKEN"/"MARK" = 0 wystąpień w danych.** Tier tokeny są zwykłymi
     DROP-ami; gear za marki T10 ma JEDEN zagregowany sztuczny source
     `ICECROWN_CITADEL_25N_MARK` z `boss="Mark"` (~58 itemów) — stąd brak
     formatu `T10 - MARK: Protector [Icecrown Citadel: Boss <25N>]`.
  c) Słownik trudności: Ulduar hard-mody modelowane jako `10HC/25HC`
     (wymagane `10HM/25HM`), heroiki 5-man jako `H` (wymagane `HC`).
  d) Źródła w tooltipie rysowane jednolitą zielenią `|cFF00FF00...|r`
     (Bistooltip.lua ~847-859) — brak rozróżnienia instancja/boss/trudność.
- Custom content serwera w core: `EmblemData.lua` rejestruje waluty
  **Emblem of Ascension** (~511), **Emblem of Ascension II** (~629),
  **Echo of the Titans** (~702) + custom ID (15000, 128858, 130023, 130031,
  131004, 131008, 131010). To content Frostmourne — do ekstrakcji do wtyczki.
- Tryb ASCEND = filtr substring `"Ascension"` po `EmblemData`
  (`SlotHasAscensionSource`, `State.emblemFilterMode`) — działa tylko dzięki
  customowym walutom; na czystym WotLK nie ma sensu. Do przemianowania na
  VENDOR i przełączenia na model ItemAcquisition.
- Cutover niedokończony (rewizja W1): koszty vendorowe czytane w runtime
  z OBU modeli naraz — UI przez `GetEmblemCost`→`Bistooltip_emblem_items`
  (`DataProvider.lua:399–414`, `BislistUI.lua:3314/3436/3472/5245`), tooltip
  przez `ItemAcquisition`. Do domknięcia w W1.
- Martwy ciężar (rewizja W2/W3): `Loot_Sources.lua` (1624 linii) ładowany
  w `.toc` przy **zerze** konsumentów runtime; martwe pliki poza `.toc`
  (Bislist.lua 3653 linii z przestarzałą logiką ASCEND, FlowView/GridView/
  ItemButton/Pool, legacy/) — **usunięte commitami rewizji**.
- Dane starsze niż origin (Q14): wszystkie 3 bislisty + Loot_Sources
  różniły się od upstream (ExoJdi/BiS-Tooltip_335a_fixed_backport, commit
  2026-06-09 „Add data source UI and new BIS lists"; diff 2751/5072/19376
  linii). **Refresh wykonany** (W0a): 3 bislisty + Loot_Sources +
  `Bistooltip_faction.lua` (nowy w forku — mapa frakcji itemów używana
  przez upstream do scalania). 27 wpisów custom Frostmourne (obecnych
  TYLKO u nas) wyekstrahowane PRZED importem do
  `docs/superpowers/data/whitemane-custom-extract-2026-09-08.lua`.

## 1. Architektura docelowa

```text
┌─ Bistooltip (CORE, czysty WotLK 3.3.5a) ─────────────────────────────┐
│ BIS DB registry: wowsims (STANDARD, default) | wowtbc | wh           │
│ SourceRegistry + ItemAcquisition (+ VOA, TOKEN/MARK per-boss)        │
│ SourceFormatter: FormatSource (plain, kanoniczny)                    │
│                  FormatSourceColored (ta sama struktura + paleta)    │
│ PluginAPI (6 f-cji) + overlay replay przy zmianie bazy               │
│ Personal BiS overrides (db.global, kaskada: baza→plugin→personal)    │
│ Tryb VENDOR (ex-ASCEND) na ItemAcquisition                          │
├─ Wtyczki serwerowe (## Dependencies: Bistooltip) ───────────────────┤
│ Bistooltip_Whitemane_Frostmourne: waluty, itemy, koszty, BiS diff    │
│ …dowolne kolejne (Bistooltip_<Serwer>)…                              │
├─ Narzędzia ──────────────────────────────────────────────────────────┤
│ Bistooltip_Scanner (standalone, OptionalDeps): vendor scan /bis scan │
│ tools/ offline: migrator, backfill tierów, audytor, run_all + CI     │
└───────────────────────────────────────────────────────────────────────┘
```

Zasada META (frozen, utrzymana): core zawiera **wyłącznie** dane czystego
WotLK; wszystko, co serwerowe, jest wtyczką diff-only przez PluginAPI.
Unifikacja źródeł (żądanie właściciela) jest już spełniona modelem S1 —
**jeden** plik faktów miejsca (`SourceRegistry`) + **jeden** plik metod
zdobycia z kosztem w środku (`ItemAcquisition`); `Loot_Sources.lua` i
`EmblemData.lua` po zakończeniu migracji znikają z runtime `.toc`
(zostają jako input migratora offline).

Layout docelowy:

```text
Bistooltip/                        # core
  Bistooltip_wowsims_final.lua     # STANDARD (default) — WYGENEROWANY offline
                                   # (baza alliance + overrides hordy; do .toc)
  Bistooltip_wh_bislists.lua       # baza wybieralna — dołączyć do .toc
  Bistooltip_wowtbc_bislists.lua   # baza wybieralna, OCZYSZCZONA z custom ID
  Bistooltip_WoWSimsBP_bislists.lua + Bistooltip_faction.lua  # INPUT offline
                                   # (nie ładowane w .toc)
  SourceRegistry.lua / ItemAcquisition.lua / SourceFormatter.lua / PluginAPI.lua
Bistooltip_Whitemane_Frostmourne/  # wtyczka serwera (toc + Plugin.lua)
Bistooltip_Scanner/                # per frozen scanner-design (toc + 2 lua)
tools/                             # + backfill_tiers.lua, assemble_wowsims.lua, run_all
```

## 2. Poprawka S2-3 (draft): słownik trudności v2

Closed set rośnie z 6 do 8 wartości:

```text
"" (world/vendor/rep/PvP) | HC (heroiki 5-man) | 10N | 25N | 10HC | 25HC | 10HM | 25HM
```

- Heroiki 5-man: `H` → `HC` (żądanie właściciela; dziś 77 źródeł `H`).
- Ulduar hard-mody: `10HC/25HC` → `10HM/25HM`; Algalon (hard-only) = `HM`.
  ICC/TOGC/RS zostają przy `HC` (taka jest natywna nomenklatura WotLK).
  Potwierdzone (Q10): Ulduar przyjmuje **wyłącznie** 10N/25N/10HM/25HM —
  zero wartości HC. Uwaga serwerowa: Whitemane Frostmourne ma własne tryby
  HC/HM (prawdopodobnie bez dodatkowego dropu) — do weryfikacji skanerem
  na serwerze (§7 pkt 5).
- Implementacja w `tools/migrate_sources.lua` (mapa `ZONE_DIFFICULTY` +
  tabela wyjątków Ulduar), closed set w `tools/check_sources.lua`,
  golden cases w `tools/test_formatter.lua`. Formatter się nie zmienia —
  drukuje `difficulty` verbatim. Regeneracja danych = re-run migratora.

## 3. Poprawka S2-4 (draft): kolorowanie źródeł

- `BisTooltip_FormatSource(entry)` pozostaje **kanoniczny, czysty tekstem**
  (golden testy, dedup, logi). Nowa funkcja
  `BisTooltip_FormatSourceColored(entry)` buduje **identyczną** strukturę
  MASTER, owijając części w `|cAARRGGBB…|r`. Jedno miejsce budowy stringu
  (współdzielone segmenty), dwie funkcje renderujące.
- Domyślna paleta w `Constants.COLORS.SOURCE` ( proposals — patrz pytania):

```text
instancja        #FFD100 (złoto)
boss             #FFFFFF (biel)
difficulty N     #9D9D9D (szary)
difficulty HC    #FF4040 (czerwień)
difficulty HM    #FF9900 (pomarańcz)
metoda TOKEN/MARK/VENDOR/TROPHY + tier  #00CCFF (błękit)
rodzina / label  #FFFFFF
waluta/koszt     #00FFCC (turkus — spójnie z dzisiejszym kolorem emblematów)
```

- Miejsca wpięcia: tooltip (`Bistooltip.lua` OnGameTooltipSetItem — linie
  źródeł zamiast jednolitej zieleni), karty checklisty (`BislistUI.lua`
  1581–1615), nagłówki grup (`ui/InstanceHeader.lua`). Dedup i porównania
  zawsze na stringu **plain** (kolor nigdy nie uczestniczy w tożsamości).
- Konfigurowalność palety w options: poza MVP (Q9: kolorowanie domyślnie
  włączone, paleta doborzona pod czytelność na ciemnym tle tooltipu).

## 3a. Poprawka S2-5 (draft): dane w formatterze i jednostki kosztu

- `variantLabel` w danych zamiast hardcodu: TROPHY drukuje
  `(entry.tier) - TROPHY: (entry.variantLabel) + koszt`; „Crusade" znika
  z `SourceFormatter.lua:18` (dane w kodzie = naruszenie zasady S2).
  Stary wpis T9-245 dostaje `variantLabel="Crusade"` w migratorze.
- Kanon jednostek kosztu: `amount` **zawsze w miedziakach** dla
  `currency="Gold"` (tak jak z API 3.3.5a); formatter renderuje Gold jako
  `g/s/c` (np. `15g`), nie „150000 Gold". Pozostałe waluty: liczba j.owa.

## 4. Poprawka S3-5 (draft): DB registry + overlay replay wtyczek

Problem: `PluginAPI.SetBiSSlot/SetEnhancement` piszą w **aliasowanej**
tabeli aktywnej bazy (`Bistooltip_bislists[...]`). Po zmianie bazy w opcjach
diff wtyczki znika (siedzi w starej tabeli).

Rozwiązanie (bez cache-frameworka — to log operacji, nie cache):

- `Config.lua`: rejestr baz zamiast `sources = { wowtbc }`:

```lua
BisTooltip_DBRegistry = {
  wowsims = { label = "WoWSimsBP (STANDARD)", bis = Bistooltip_wowsims_bislists,
              classes = …, phases = … },
  wowtbc  = { label = "wowtbc.gg" },   -- pełnoprawna 3. baza wybieralna (Q6)
  wh      = { label = "Whitemane (wh)" },
}
```

  `EnableSpec(dbKey)` aliasuje `Bistooltip_bislists/classes/phases` z
  wybranego wpisu. Dropdown `db.global.data_source` (Q16: account-wide,
  z migracją z `db.char`) z 3 pozycjami, default `wowsims` (Q5).
  Dwa ODRĘBNE mechanizmy frakcyjne (uwaga właściciela 2026-09-08: baza
  wowtbc = 800 KB danych + 25 KB `Bistooltip_horde_to_ali` — autorskie
  założenie pakietu):
  1. **Globalny mirror runtime (fork, już istnieje, zostaje):**
     horde→alliance translacja ID przy wyświetlaniu/wyszukiwaniu,
     niezależna od aktywnej bazy — konsumenci: `DataProvider.lua:166-231`,
     `Utils.lua:223`, `Bistooltip.lua:496`, `UIFramework.lua:342/619`.
  2. **Assembly frakcyjne wowsims — OFFLINE + reprezentacja kompaktowa
     (v2.3: „nie robić tego sposobem WoWSimsBP"; v2.4: zmniejszyć plik
     w duchu `horde_to_ali`):** upstream merguje w runtime i ładuje 3
     tabele; META-Z robi merge offline i ładuje mniej.
     `tools/assemble_wowsims.lua` portuje algorytm upstream 1:1
     (primary+fallback, mirror ID, filtr frakcji, aliasowanie
     Ranged/Relic, cap 6), liczy OBA finalne rankingi frakcyjne i emituje
     `Bistooltip_wowsims_final.lua` w postaci kompaktowej:
     `..._final_alliance` (jedna pełna baza) +
     `..._final_horde_overrides` (tylko sloty, w których horda różni się
     w ogóle — cały slot precomputowany; duch `Bistooltip_horde_to_ali`:
     mała mapa różnic zamiast drugiej pełnej tabeli) + classes + phases
     (jedna definicja — duplikat phases znika z definicji). Runtime:
     alliance = czysty alias; horda = alias + pętla podmian referencji
     slotów nadpisanych (O(#overrides), bez kopiowania i bez scalania —
     zgodnie z filozofią zamkniętego rdzenia, jak usunięcie
     `findSourceInLootTable` i heurystyki difficulty). Generator drukuje
     raport zróżnicowania (sloty/%/rozmiar) — pomiar należy do W4a.
     Rebind po zmianie bazy idempotentny z definicji (nadpisania
     podmieniają referencje, overlay/personal reaplikują te same
     wartości). Inputy upstream (3-tabelowy plik, `Bistooltip_faction.lua`)
     zostają w repo, nieładowane w `.toc` — wzorzec Loot_Sources.

     Dowód pomiarowy (WSL lua5.1, 2026-09-08; uzasadnia czemu tabel nie
     wolno zignorować i czemu merge musi istnieć — tylko offline):
     primary = czysto alliance (0 itemów hordy; 396 ali na rank-1,
     2359 w listach); zgodność rank-1 tabel frakcyjnych z primary: horda
     59,5%, ali 64,4% (primary = baseline, nie ranking docelowy);
     ali vs horda 93,6%.

     Konsolidacja map: `Bistooltip_item_faction` staje się wyłącznie
     inputem offline (nie trafia do `.toc`); `Bistooltip_horde_to_ali`
     pozostaje w `.toc` bez zmian (żywi konsumenci z pkt 1; kopie
     zweryfikowane identyczne — 639 wpisów). Procedura refreshu danych
     (W0a): import z upstream → migrator (Źródła) → assembler (wowsims
     final) → census rerun → commit wyników.
- `PluginAPI.lua`: każda udana mutacja (`DefineSource`, `SetAcquisition`,
  `AddAcquisition`, `SetBiSSlot`, `SetBiSSlotRank`, `SetEnhancement`) jest
  zapisywana do wewnętrznego logu overlay `{fn, deep-copy(args), plugin}`.
  Po `changeSpec()` core odbindowuje aliasy, binduje nową bazę i
  **replaying** log w kolejności wykonania. Semantyka replace-wins bez
  zmian. Operacje akwizycji (itemID-kluczowane) są z natury bazoniezależne;
  replay ma sens przede wszystkim dla operacji slotowych.
- Błędy replay (slot/rank nie istnieje w nowej bazie): warn-once per
  plugin+slot, wpis pomijany — wtyczka opisuje serwer, nie konkretną bazę
  rankingową.
- Overlay jest mały (liczba wywołań wtyczki, nie itemów), nie podlega
  invalidation — po prostu wykonuje się ponownie.

### Poprawka S3-6 (draft): `SetBiSSlotRank` — nadpisanie pojedynczego ranku

Szósta funkcja API (rewizja W5 — slot-level replace jest zbyt gruby dla
wtyczek serwerowych):

```lua
BisTooltip:SetBiSSlotRank("Warrior", "Fury", "T7", "Weapon", 1, 130031, plugin)
```

- Nadpisuje **jeden rank** w slocie (`slot[rank] = itemID`), reszta listy
  zostaje z aktywnej bazy — diff jest bazoniezależny („rank 1 = custom")
  i survivaluje aktualizacje rankingów core oraz replay po zmianie bazy.
- Walidacje: `rank` ∈ [1, długość slotu]; warn (nie error), gdy `itemID`
  występuje już na innym ranku tego slotu (duplikat rankingu).
- `SetBiSSlot` (pełna lista) zostaje dla wtyczek świadomie przejmujących
  cały slot. Skaner emituje akwizycje; rankingi wtyczek wyrażają się
  naturalnie przez `SetBiSSlotRank`.

## 5. Poprawka S4-5 (draft): backfill tierów (VOA + TOKEN/MARK per-boss)

Nowy narzędzie offline `tools/backfill_tiers.lua` (wejście: oracle Pazzions
AtlasLoot + wiedza domenowa; wyjście: dopisek do `SourceRegistry.lua` /
`ItemAcquisition.lua`; regenerowalny, deterministyczny):

1. **VOA**: 4 bossów × {10N, 25N} = źródła
   `VOA_10N_ARCHAVON` … `VOA_25N_TORAVON` + akwizycje tokenów rękawic/nóg
   T7–T10 (rodziny wg tieru). Zasada „nie deduplikujemy realnych bossów"
   obowiązuje też tu: Emalon 10N i Emalon 25N to dwa osobne source.
2. **TOKEN T7–T9**: itemy tokenów dostają `kind="TOKEN"`, `tier`,
   `family` (krótkie: Lost/Wayward/Grand Protector…; ściąga pełna→krótka
   w komentarzu pliku danych) + po jednym wpisie **na każdym realnym
   bossie i realnej trudności** dropiącym dany token (Naxx 10N/25N,
   Ulduar 10N/25N, TOC/TOGC 10N/25N/10HC/25HC). Dzisiejsze DROP-y tokenów
   zostają zastąpione (replace, nie append).
3. **MARK T10**: likwidacja sztucznego `ICECROWN_CITADEL_25N_MARK`
   (`boss="Mark"`). Gear z marek (Sanctified i odmiany) dostaje po jednym
   `kind="MARK"` wpisu na realnym bossie (25N: normal Mark; 25HC: heroic
   Mark) → format `T10 - MARK: Protector [Icecrown Citadel: <Boss> <25N>]`
   per boss, wiele linii, bez deduplikacji.
4. **Walidacja** (rozszerzenie `tools/check_sources.lua`):
   - każdy item-token T7–T10 ma ≥1 wpis TOKEN/MARK z family i difficulty
     ze zbioru v2;
   - żaden source nie ma sztucznego bossa (`Mark`, `Trash Mobs` — wyjątki
     jawnie allowlistowane);
   - macierz VOA: dla każdego tieru T7–T10 istnieją akwizycje gloves/legs
     z VOA (oracle cross-check);
   - coverage render: każdy TOKEN/MARK renderuje się niepusto przez
     FormatSource.
5. Oracle = offline validation only (GPLv2, nie commitowany, nie w .toc) —
   zgodnie z frozen S4-2: relacje wymagają klasyfikacji acquisition
   + drugiego źródła tam, gdzie AtlasLoot był jedynym świadkiem.

## 6. Tryb VENDOR (przemianowanie ASCEND)

- Zmiana nazwy wszędzie (State.emblemFilterMode → vendorFilterMode, przycisk
  "VENDOR", komunikaty, sorty/grupowanie w `BuildChecklistGroups`,
  `ui/InstanceHeader.lua`); migracja starego klucza SavedVariables.
- Zmiana **semantyki**: kwalifikacja itemu przez `ItemAcquisition`
  (`kind ∈ {VENDOR, CUSTOM}` — Q8; itemy za gold wchodzą, bo są kind=VENDOR),
  nie przez substring po `EmblemData`. Grupowanie po walucie z `cost[]`
  (label grupy: `<Currency> (N)`), sort po koszcie malejąco.
- Efekt: tryb działa identycznie na czystym WotLK (Emblem of Triumph/Frost)
  i na serwerach custom — waluty wtyczki pojawiają się same, bo są danymi.
- `SlotHasAscensionSource`/substring "Ascension" — usunięte.

## 7. Wtyczka Bistooltip_Whitemane (Frostmourne)

Folder `Bistooltip_Whitemane_Frostmourne/` (Q1 — nazwa z odpowiedzi
„Bistooltip_Whitemane Frostmourne"; podkreślnik zamiast spacji jest
bezpieczniejszy dla narzędzi, Title: „Bistooltip — Whitemane: Frostmourne"),
`## Dependencies: Bistooltip`, `Plugin.lua` woła wyłącznie API S3:

1. `DefineSource` dla vendorów customowych (label np. "Emblem Vendor —
   Dalaran"; finalne label do potwierdzenia / zebrane skanerem).
2. `SetAcquisition` dla itemów customowych z kosztami w customowych
   walutach — treść przeniesiona z `EmblemData.lua`:
   Emblem of Ascension (incl. 130023, 130031; literówka `15000` poprawiona
   na `150005` — Q2), Emblem of Ascension II (Ulduar-HM loot 19–150 +
   131004 „Domhammer", 128858 „Scythe of the Cat God"), Echo of the Titans
   (131010 =2, 131008 =1 itd.). Uwaga właściciela (2026-09-08): 5 ID
   rank-1 (128858, 130023, 130031, 131004, 150005) to **przedmioty
   legendarne** Frostmourne — stąd ich dominacja na rank-1 slotów
   Weapon/Ranged; koszty w customowych emblematach wg EmblemData, ostateczna
   metoda zdobycia (vendor/drop/quest) potwierdzi skaner na serwerze.
3. `SetBiSSlotRank` dla 27 nadpisań rank-1 z bazy wowtbc (5 ID customowych)
   — postać diffu: „rank 1 slotu = custom ID", **bez pieczonych list**
   (rewizja W5): działa na każdej bazie i survivaluje update core.
   Po zmianie bazy overlay replay przenosi diff automatycznie (S3-5);
   brak slotu/ranku w innej bazie = warn-once + skip.
4. Miejsce na przyszłe custom enchants (`SetEnhancement`) i kolejne itemy
   zebrane skanerem.
5. Weryfikacje serwerowe (Q10/Q12): tryby HC/HM Whitemane — sprawdzić,
   czy nie dodają dropu (jeśli dodają: nowe source przez DefineSource +
   SetAcquisition); system walut cata-like (valor/justice) — przeskanować
   NPC skanerem, wpisy kosztów w standardowym formacie `cost[]`.

Równolegle **czyszczenie core**: `EmblemData.lua` traci tabele
Ascension/Echo (zostają wyłącznie standardowe emblemy WotLK), baza `wowtbc`
traci 27 wpisów customowych (custom ID żyją tylko we wtyczce). Po tym:
`.toc` core wyłącza `EmblemData.lua` i `Loot_Sources.lua` z runtime
(`GetEmblemCost` czyta `ItemAcquisition`; auto-rejestracja T8 z EmblemData
zostaje przeniesiona do initu DataProvider).

## 8. Skaner (frozen import + 1 rozszerzenie)

Realizacja 1:1 wg `2026-09-08-vendor-scanner-plan.md` (4 tasky). Rozszerzenia
drafter'owe (małe, w tym samym addonie):

- `/bis item <ID>` — snippet dla pojedynczego itemu po ID (nazwa z cache,
  komentarz `-- UNCACHED` gdy brak), emitujący szkielet
  `DefineSource`/`SetAcquisition` do uzupełnienia. To zamyka żądanie
  „proste dodawanie customowych przedmiotów oraz skanowanie przedmiotów
  po ID".
- Jednostka gold (rewizja W7): eksport zostaje przy `amount` = miedziaki
  (kanon S2-5); formatter renderuje `g/s/c`.


## 9. Wydajność i zasady frozen utrzymane

- Lookup O(1) bez cache-frameworka; overlay replay to N wywołań wtyczki
  (setki, nie tysiące) raz na zmianę bazy.
- Trzy bazy w `.toc` = ~3,4 MB tabel w pamięci (akceptowalne dla 3.3.5a;
  dane statyczne). `.toc` ładuje wyłącznie **wygenerowane pliki final**
  (wowsims: baza alliance + mapa overrides hordy — mniej niż 2 pełne
  tabele, rozmiar zmierzy raport W4a; wh/wowtbc: po jednej) — pliki
  input upstream (3-tabelowy WoWSimsBP, faction.lua) i `Loot_Sources.lua`
  pozostają w repo, ale nie są ładowane (Loot_Sources znika z `.toc`
  już w W1). Jeśli zmierzony load time będzie bolał — ładowanie
  warunkowe/per-frakcja to decyzja po pomiarze, nie z góry.
- TROPHY pozostaje display-only; brak EnchantAcquisition; CUSTOM walidowane;
  brak importerów w core; skaner nigdy nie pisze do tabel core.

## 10. Kolejność prac (workstreamy po zatwierdzeniu designu)

| # | Workstream | Zależy od |
|---|---|---|
| W0 | ~~Gałąź META-Z, track baz, import dokumentów~~ + ~~usunięcie martwych plików~~ (rewizja) — **wykonane** | — |
| W0a | Refresh danych z upstream (ExoJdi, 2026-06-09): 3 bislisty + Loot_Sources + `Bistooltip_faction.lua` — **import + ekstrakcja customów wykonane**; zostało: rerun census + rekonfirmacja STANDARD | — |
| W1 | Cutover runtime: `.toc` clean (Loot_Sources out), `GetEmblemCost` → shim nad ItemAcquisition; słownik trudności v2 (migrator+audyt+goldens, regeneracja danych z kanonicznego Loot_Sources forka — wariant upstream to 9-strefowy subset, patrz korekta w census) | — |
| W2 | Backfill tierów (VOA, TOKEN/MARK per-boss) + walidacja oracle + audyt cross-DB coverage (każdy ID z każdej bazy ma akwizycję albo allowlista) | W1 |
| W3 | FormatSourceColored + paleta + wpięcie tooltip/checklist | W1 |
| W4 | DB registry + options + overlay replay (S3-5) + `SetBiSSlotRank` (S3-6); migracja do `db.global` (`data_source` + `custom_priorities` — warstwa §12); wowsims = alias (alliance) / alias+podmiana overrides (horda); W4a: `tools/assemble_wowsims.lua` (port algorytmu upstream) + wygenerowanie `Bistooltip_wowsims_final.lua` (baza alliance + overrides hordy, raport zróżnicowania) | — |
| W5 | ~~Tryb VENDOR (rename + semantyka ItemAcquisition, kind VENDOR+CUSTOM)~~ — **wykonane przedplanowo** na żądanie właściciela przy testach W1; przy okazji naprawiono zgłoszony wyciek: GroupSlotsByInstance grupował po rank-1 slotu, więc sloty z itemem vendorowym głębiej w rankingu trafiały do grup instancji (np. ToC) w trybie filtru | W1 |
| W6 | Wtyczka `Bistooltip_Whitemane_Frostmourne` (diffy SetBiSSlotRank, poprawka 150005, waluty cata-like po skanie) + czyszczenie EmblemData/wowtbc + usunięcie root `_some custom items.lua` PO ekstrakcji (Q4) | W4, W5 |
| W7 | Bistooltip_Scanner (frozen plan) + `/bis item` + jednostka gold | — |
| W8 | `tools/run_all` + CI GitHub Actions (Q15: TAK) + pełny audyt + manual in-game | W1–W7 |

Każdy workstream dostaje własny implementation plan (workflow superpowers:
design → review → plan → implement). W0 (gałąź META-Z, track baz, import
dokumentów) wykonane przy tworzeniu tego speca.

## 11. Decyzje właściciela (Q1–Q16, 2026-09-08) — zamknięte

| Q | Decyzja |
|---|---|
| 1 | Folder wtyczki: `Bistooltip_Whitemane_Frostmourne` (z odpowiedzi „Bistooltip_Whitemane Frostmourne"; spacja w nazwie folderu WoW technicznie działa, ale podkreślnik jest bezpieczniejszy dla narzędzi); Title: „Bistooltip — Whitemane: Frostmourne" — **ZAAKCEPTOWANE** |
| 2 | `[15000]` = literówka → przy ekstrakcji poprawione na `150005` |
| 3 | 27 nadpisań rank-1 w wowtbc = w całości content Frostmourne → wtyczka |
| 4 | Root `…_some custom items.lua` → usunąć w W6 PO ekstrakcji diffów |
| 5 | Domyślna baza: **WoWSimsBP** |
| 6 | wowtbc = pełnoprawna 3. baza wybieralna; dropdown: „WoWSimsBP (STANDARD)", „wowtbc.gg", „Whitemane (wh)". Uwaga: census nie znalazł w pliku `wh` powiązań z Whitemane (0 stringów, 0 custom ID) — etykieta wedle decyzji właściciela |
| 7 | Label vendorów customowych: zbierane skanerem w grze (do tego czasu placeholder) |
| 8 | Tryb VENDOR: `kind ∈ {VENDOR, CUSTOM}` (istnienie customów wykaże skaner); itemy za gold wchodzą (to kind=VENDOR) |
| 9 | Kolory: włączone **domyślnie**, paleta doborzona pod czytelność (§3) |
| 10 | Ulduar wyłącznie 10N/25N/10HM/25HM (zero wartości HC); serwerowe HC/HM Whitemane — weryfikacja dropu w §7 pkt 5 |
| 11 | Tier tokeny: jednolita etykieta `T7`–`T10`, bez rozróżniania 10N/25N |
| 12 | Whitemane Frostmourne ma system walut cata-like → przeskanować NPC skanerem; wsparcie przez standardowy format `cost[]` |
| 13 | Kolejność W1→W8 potwierdzona |
| 14 | **DECYZJA ODWRÓCONA po weryfikacji upstream**: tabele frakcyjne ZOSTAJĄ i pracują (hook `assemble`, §4); refresh danych wykonany (szczegóły pod tabelą) |
| 15 | CI: rekomendacja zatwierdzona przez właściciela — GitHub Actions (luac -p + suity lua5.1) na push/PR od W8 |
| 16 | `db.char.data_source` → `db.global.data_source`; personal BiS → `db.global` (§12); `db.profile` wyłącznie dla ustawień UI |

Q14 — wynik weryfikacji origin (github.com/ExoJdi/BiS-Tooltip_335a_
fixed_backport, commit 2026-06-09): `Bistooltip_bislists_alliance/_horde`
są **aktywnie konsumowane** przez `assembleActiveBislists()` (Config.lua
upstream): aktywny ranking wowsims = scalanie rank-1 tabeli frakcji
gracza + pełnej tabeli fallback, z mirrorowaniem ID między frakcjami
(`Bistooltip_horde_to_ali`) i filtrowaniem itemów obcej frakcji
(`Bistooltip_item_faction` — plik, którego w naszym forku w ogóle nie
było; dodany przy refreshu). Nasz fork stracił ten krok przy ekstrakcji
danych — stąd błędny wniosek rewizji W4 o „0 konsumentach" (korekta
w stage-review). Dodatkowo wszystkie 4 pliki danych były starsze niż
upstream (diff: 2751/5072/19376 linii) — **refresh wykonany**; 27 wpisów
custom Frostmourne (istniejących tylko u nas) wyekstrahowane PRZED
importem do artifactu W6; census wymaga rerunu na świeżych danych (W0a).

Follow-upy otwarte (nie blokują planów): label vendorów customowych
(uzupełni skaner — Q7), weryfikacja dropu przy serwerowych HC/HM (Q10),
wynik skanu walut cata-like (Q12).

## 12. Personal BiS overrides — warstwa osobista (account-wide)

Poprawka S3-7 (draft). Zgodnie z decyzją właściciela hierarchia efektywna:

```text
wybrana baza bazowa (WoWSimsBP domyślnie | wowtbc | wh)
        ↓
ew. plugin serwera (overlay replay, S3-5)
        ↓
PERSONAL BIS OVERRIDES (db.global, sparse)
        ↓
wynik widoczny w addonie
```

Precedens: **personal > plugin > baza**. Kolejność aplikowania =
kolejność powyższej kaskady (bind bazy → replay wtyczek → aplikacja
personal per slot przy odczycie).

Istniejący mechanizm (zinwentaryzowany, zostaje edytorem warstwy):
- UI: tryb customize (odblokowanie slotu na fioletowo + swap pozycji
  w obrębie slotu) — `StateManager.lua:28-40` (`customizeMode`,
  `unlockedSlots`), swap `BislistUI.lua:1842-1855`, persistencja
  `DataProvider.lua:826-921` (`CustomPriorities`/`SaveCustomPriority`/
  `LoadCustomPriority`/`RestoreOriginalOrder`).
- Storage dziś: `db.char.custom_priorities["Class_Spec_Phase_Slot"] =
  {itemIds}` — per-postać, pełna kolejka **tylko dotkniętych slotów**
  (sparse per slot), rekoncyliacja po ID przy load: itemu nieobecnego
  w slocie nie wstawiamy, nowe itemy dopisywane na końcu.

Target:
1. Migracja do `db.global.custom_priorities` + `db.global.data_source`
   (jednorazowo przy starcie: kopia z przestrzeni char, gdy global puste;
   dane char pozostają uśpione jako backup). `db.profile` zostaje
   wyłącznie ustawieniom UI (możliwym do różnicowania między profilami).
2. Personal = **sparse override nad aktywną bazą+dostawcą, nie kolejna
   baza** — nie kopiujemy całych rankingów, tylko dotknięte sloty.
3. Rekoncyliacja ID zostaje (istniejący algorytm): kolejność osobista
   przeżywa zmianę bazy, update rankingów core i zmiany wtyczki —
   brakujące ID wypadają, nowe dopisywane na końcu.
4. Porządek aplikowania w W4: personal `LoadCustomPriority` wykonuje się
   **po** overlay replay wtyczek (precedens z kaskady).

## Self-review speca

- Placeholdery: brak pytań blokujących (Q1–Q16 zamknięte, §11); otwarte
  follow-upy (label vendorów, weryfikacja HC/HM Whitemane, skan walut
  cata-like) mają właściciela procesu: skaner/serwer.
- Spójność z frozen: S1/S2 bez zmian strukturalnych; TROPHY nadal
  display-only (label przeniesiony do danych); formatter nadal jedyny;
  API rośnie do 6 funkcji wyłącznie o granularny `SetBiSSlotRank`
  (uzasadnienie: rewizja W5); personal BiS nie jest nowym API — to
  istniejący mechanizm customize podniesiony do db.global i wpięty w
  kaskadę precedensu; skaner nadal standalone.
- v2 wg rewizji: cutover przyspieszony do W1 (podwójna prawda kosztów,
  martwy `.toc`), Whitemane bez pieczonych list slotów, kanon jednostek
  gold, audyt cross-DB coverage, higiena pliku STANDARD.
- v2.1 wg decyzji: domyślna baza WoWSimsBP, 3 pełnoprawne bazy, kolory
  domyślnie ON, VENDOR+CUSTOM w trybie VENDOR, tabele frakcyjne OUT,
  CI IN, kaskada baza→plugin→personal (account-wide).
- v2.2 (Q14 zweryfikowane): tabele frakcyjne IN + hook `assemble`
  (port upstream), refresh danych z origin wykonany, ekstrakcja customów
  Frostmourne zabezpieczona artifactem, W0a (census rerun) przed W1.
- v2.3 (decyzja właściciela): assembly frakcyjne offline — runtime bez
  merge; generator + plik final; pomiar uzasadniający (primary czysto
  alliance, zgodność rank-1 59,5%/64,4%) zapisany w §4.
- v2.4 (żądanie właściciela): reprezentacja kompaktowa final — baza
  alliance + `horde_overrides` (całe sloty tam, gdzie horda różni się
  w ogóle); runtime hordy = pętla podmian referencji; nadpisania nigdy
  nie są większe od pełnej tabeli, więc v2.4 ≤ v2.3 rozmiarowo z definicji.
- Nowe ryzyka nazwane: pamięć 3 baz (akcept / pomiar), replay błędów
  (warn-once + skip), oracle jako jedyny świadek (wymóg drugiego źródła),
  personalizacja per slot może maskować nadpisania wtyczki (świadomy
  precedens właściciela), świeżość danych zależna od origin (proces
  refreshu udokumentowany w W0a).
- Zakres: brak nowej warstwy architektonicznej poza wyszczególnionymi
  poprawkami; nic nie budujemy „na zapas" (paleta options, lazy load
  baz — dopiero po pomiarze).
