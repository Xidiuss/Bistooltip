# META-Z — Meta-BisTooltip system design

Status: **DRAFT v2** — oczekuje na review właściciela przed planem implementacji.
Data: 2026-09-08. Gałąź: `META-Z` (utworzona z `feat/meta-bistooltip-data`,
pełna historia). Klasyfikacja: architectural.
Relacja: rozszerza **frozen** `2026-09-07-metabistooltip-data-design.md`
(S1–S4, wdrożone) o poprawki S2-3, S2-4, S2-5, S3-5, S3-6, S4-5; importuje
frozen `2026-09-08-vendor-scanner-design.md` + jej plan. v2 wynika z rewizji
etapu przebudowy: `2026-09-08-metaz-stage-review.md` (dowody tam).

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

## 1. Architektura docelowa

```text
┌─ Bistooltip (CORE, czysty WotLK 3.3.5a) ─────────────────────────────┐
│ BIS DB registry: wowsims (STANDARD, default) | wh | wowtbc           │
│ SourceRegistry + ItemAcquisition (+ VOA, TOKEN/MARK per-boss)        │
│ SourceFormatter: FormatSource (plain, kanoniczny)                    │
│                  FormatSourceColored (ta sama struktura + paleta)    │
│ PluginAPI (5 f-cji) + overlay replay przy zmianie bazy               │
│ Tryb VENDOR (ex-ASCEND) na ItemAcquisition                          │
├─ Wtyczki serwerowe (## Dependencies: Bistooltip) ───────────────────┤
│ Bistooltip_Whitemane (Frostmourne): waluty, itemy, koszty, BiS diff  │
│ …dowolne kolejne (Bistooltip_<Serwer>)…                              │
├─ Narzędzia ──────────────────────────────────────────────────────────┤
│ Bistooltip_Scanner (standalone, OptionalDeps): vendor scan /bis scan │
│ tools/ offline: migrator, backfill tierów, audytor, run_all          │
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
  Bistooltip_wowsims_bislists.lua  # STANDARD (default) — dołączyć do .toc
  Bistooltip_wh_bislists.lua       # baza wybieralna — dołączyć do .toc
  Bistooltip_wowtbc_bislists.lua   # baza wybieralna, OCZYSZCZONA z custom ID
  SourceRegistry.lua / ItemAcquisition.lua / SourceFormatter.lua / PluginAPI.lua
Bistooltip_Whitemane/              # wtyczka serwera (2 pliki: toc + Plugin.lua)
Bistooltip_Scanner/                # per frozen scanner-design (toc + 2 lua)
tools/                             # + backfill_tiers.lua, run_all
```

## 2. Poprawka S2-3 (draft): słownik trudności v2

Closed set rośnie z 6 do 8 wartości:

```text
"" (world/vendor/rep/PvP) | HC (heroiki 5-man) | 10N | 25N | 10HC | 25HC | 10HM | 25HM
```

- Heroiki 5-man: `H` → `HC` (żądanie właściciela; dziś 77 źródeł `H`).
- Ulduar hard-mody: `10HC/25HC` → `10HM/25HM`; Algalon (hard-only) = `HM`.
  ICC/TOGC/RS zostają przy `HC` (taka jest natywna nomenklatura WotLK).
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
- Konfigurowalność palety w options: poza MVP (decyzja: najpierw domyślne).

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
  wowsims = { label = "WoWSims (STANDARD)", bis = Bistooltip_wowsims_bislists,
              classes = …, phases = …, factionTables = true },
  wh      = { label = "wh (reference)" },      -- etykieta: patrz pytania
  wowtbc  = { label = "wowtbc.gg (reference)" },
}
```

  `EnableSpec(dbKey)` aliasuje `Bistooltip_bislists/classes/phases` z
  wybranego wpisu (woWSims: rozstrzygnięcie slotów frakcyjnych przez
  `Bistooltip_bislists_alliance/_horde` wg frakcji gracza — mechanika jak
  dziś, uogólniona). Dropdown `db.char.data_source` z 3 pozycjami, default
  `wowsims` (kwestia domyślnej bazy: patrz pytania).
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
  (`kind=="VENDOR"`; o CUSTOM/Gold — patrz pytania), nie przez substring
  po `EmblemData`. Grupowanie po walucie z `cost[]` (label grupy:
  `<Currency> (N)`), sort po koszcie malejąco.
- Efekt: tryb działa identycznie na czystym WotLK (Emblem of Triumph/Frost)
  i na serwerach custom — waluty wtyczki pojawiają się same, bo są danymi.
- `SlotHasAscensionSource`/substring "Ascension" — usunięte.

## 7. Wtyczka Bistooltip_Whitemane (Frostmourne)

Folder `Bistooltip_Whitemane/` (nazwa folderu bez dwukropka — patrz pytania),
`## Dependencies: Bistooltip`, `Plugin.lua` woła wyłącznie API S3:

1. `DefineSource` dla vendorów customowych (label np. "Emblem Vendor —
   Dalaran"; finalne label do potwierdzenia / zebrane skanerem).
2. `SetAcquisition` dla itemów customowych z kosztami w customowych
   walutach — treść przeniesiona z `EmblemData.lua`:
   Emblem of Ascension (incl. 130023, 130031, 15000?), Emblem of Ascension II
   (Ulduar-HM loot 19–150 + 131004 „Domhammer", 128858 „Scythe of the Cat
   God"), Echo of the Titans (131010 =2, 131008 =1 itd.).
3. `SetBiSSlotRank` dla 27 nadpisań rank-1 z bazy wowtbc (5 ID customowych)
   — postać diffu: „rank 1 slotu = custom ID", **bez pieczonych list**
   (rewizja W5): działa na każdej bazie i survivaluje update core.
   Po zmianie bazy overlay replay przenosi diff automatycznie (S3-5);
   brak slotu/ranku w innej bazie = warn-once + skip.
4. Miejsce na przyszłe custom enchants (`SetEnhancement`) i kolejne itemy
   zebrane skanerem.

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
  dane statyczne). Jeśli zmierzony load time bolą — ładowanie warunkowe
  jest decyzją po pomiarze, nie z góry. Dodatkowo (rewizja W4): tabele
  frakcyjne WoWSimsBP (~połowa pliku, **0 konsumentów**) do wygenerowania
  lub usunięcia przy adopcji STANDARD — patrz Q14; `Loot_Sources.lua`
  znika z `.toc` już w W1 (0 konsumentów runtime).
- TROPHY pozostaje display-only; brak EnchantAcquisition; CUSTOM walidowane;
  brak importerów w core; skaner nigdy nie pisze do tabel core.

## 10. Kolejność prac (workstreamy po zatwierdzeniu designu)

| # | Workstream | Zależy od |
|---|---|---|
| W0 | ~~Gałąź META-Z, track baz, import dokumentów~~ + ~~usunięcie martwych plików~~ (rewizja) — **wykonane** | — |
| W1 | Cutover runtime: `.toc` clean (Loot_Sources out), `GetEmblemCost` → shim nad ItemAcquisition; słownik trudności v2 (migrator+audyt+goldens, regeneracja danych) | — |
| W2 | Backfill tierów (VOA, TOKEN/MARK per-boss) + walidacja oracle + audyt cross-DB coverage (każdy ID z każdej bazy ma akwizycję albo allowlista) | W1 |
| W3 | FormatSourceColored + paleta + wpięcie tooltip/checklist | W1 |
| W4 | DB registry + options (scope klucza: Q16) + overlay replay (S3-5) + `SetBiSSlotRank` (S3-6); W4a: regeneracja pliku wowsims (frakcyjne tabele wg Q14, duplikat phases) | — |
| W5 | Tryb VENDOR (rename + semantyka ItemAcquisition) | W1 |
| W6 | Wtyczka Whitemane (SetBiSSlotRank diffy) + czyszczenie EmblemData/wowtbc | W4, W5 |
| W7 | Bistooltip_Scanner (frozen plan) + `/bis item` + jednostka gold | — |
| W8 | `tools/run_all` + propozycja CI (Q15) + pełny audyt + manual in-game | W1–W7 |

Każdy workstream dostaje własny implementation plan (workflow superpowers:
design → review → plan → implement). W0 (gałąź META-Z, track baz, import
dokumentów) wykonane przy tworzeniu tego speca.

## 11. Pytania otwarte (do właściciela)

1. Nazwa folderu wtyczki: dwukropek w „Whitemane:Frostmourne" jest
   nielegalny w nazwie folderu Windows — propose `Bistooltip_Whitemane`,
   Title „Bistooltip — Whitemane: Frostmourne". OK?
2. Wolne ID `[15000] = 80` w EmblemData — wygląda na literówkę (150005
   występuje w bislistach, ale nie ma go w EmblemData). Usunąć, poprawić
   na 150005, czy przenieść 1:1?
3. Czy 27 nadpisań rank-1 w wowtbc (w tym 150005) to w całości content
   Frostmourne i wszystkie trafiają do wtyczki?
4. Plik root `Bistooltip_wowtbc_bislists _some custom items.lua` (829 KB,
   wariant nadpisujący bazę) — usunąć po ekstrakcji diffów?
5. Domyślna baza w options: WoWSimsBP (rekomendacja census) czy obecny
   runtime wowtbc aż do audytu in-game?
6. Etykieta bazy `wh` w dropdownie („Wowhead WotLK"?) i czy wowtbc
   (oczyszczony) ma być pełnoprawną 3. bazą wybieralną, czy tylko legacy?
7. Waluty custom (Emblem of Ascension / II, Echo of the Titans): z jakich
   vendorów/lokacji pochodzą (potrzebne do `label` w DefineSource)? Czy
   zbierzesz to skanerem w grze, czy podasz nazwy teraz?
8. Tryb VENDOR: pokazywać wyłącznie `kind="VENDOR"`, czy również
   `kind="CUSTOM"` (sklepy donate) i itemy za gold (`currency="Gold"`)?
9. Paleta kolorów (propozycja w §3): zatwierdzić/zmienić? Kolorowanie
   domyślnie włączone czy przełącznikiem w options?
10. Algalon (hard-only boss Ulduaru): oznaczyć jako `10HM/25HM`
    (propozycja) czy trzymać HC?
11. T7: tokeny 10N („Heroes'") i 25N („Valorous…") jako osobne source bez
    dedup — a etykieta tieru zostaje jednolita `T7` (propozycja), czy
    rozróżniać `T7.10/T7.25`?
12. „Punkty valor/justice jak cata": czy konkretny serwer docelowy ma już
    taki system walut do wsparcia w formacie kosztów, czy to tylko przykład
    przyszłościowej wtyczki?
13. Priorytet workstreamów: proponowana kolejność W1→W8 (najpierw dane,
    potem render/kolory) — zgodna z Twoimi oczekiwaniami?
14. Tabele frakcyjne WoWSimsBP (`Bistooltip_bislists_alliance/_horde`,
    ~połowa pliku, 0 konsumentów w kodzie): usunąć z pliku shippingowego
    przy regeneracji (rekomendacja rewizji W4), czy przewidujesz dla nich
    realny użytek (np. frakcyjne BiS w UI)?
15. CI: czy dodać GitHub Actions (luac -p + wszystkie suity lua5.1 na
    push/PR) jako bramkę dla regenerowanych danych? (rewizja W8)
16. Zasięg wyboru bazy: `db.char.data_source` jest per-postać — przełączyć
    na profil (db.profile) przy W4? (rewizja W11)

## Self-review speca

- Placeholdery: jawnie oznaczone pytania (etykieta wh, label vendorów,
  domyślna baza, frakcyjne tabele, CI, scope klucza) — reszta decyzji
  zamknięta.
- Spójność z frozen: S1/S2 bez zmian strukturalnych; TROPHY nadal
  display-only (label przeniesiony do danych); formatter nadal jedyny;
  API rośnie do 6 funkcji wyłącznie o granularny `SetBiSSlotRank`
  (uzasadnienie: rewizja W5); skaner nadal standalone.
- v2 wg rewizji: cutover przyspieszony do W1 (podwójna prawda kosztów,
  martwy `.toc`), Whitemane bez pieczonych list slotów, kanon jednostek
  gold, audyt cross-DB coverage, higiena pliku STANDARD.
- Nowe ryzyka nazwane: pamięć 3 baz (akcept / pomiar + redukcja o tabele
  frakcyjne), replay błędów (warn-once + skip), oracle jako jedyny świadek
  (wymóg drugiego źródła).
- Zakres: brak nowej warstwy architektonicznej poza wyszczególnionymi
  poprawkami; nic nie budujemy „na zapas" (paleta options, lazy load
  baz — dopiero po pomiarze).
