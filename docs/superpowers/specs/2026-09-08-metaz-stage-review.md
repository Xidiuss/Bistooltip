# META-Z — rewizja etapu przebudowy (stage review)

Status: **REVIEW COMPLETE** — ustalenia wdrożone do spec v2 + jeden commit porządkowy.
Data: 2026-09-08. Zakres: frozen S1–S4 (design + implementacja na
`feat/meta-bistooltip-data`), stan danych, stan runtime, draft META-Z z 2026-09-08.
Metoda: weryfikacja grepo/odczytem (konsument `lootTable`, konsument
`EmblemData`, martwe pliki vs `.toc`, tabele frakcyjne WoWSimsBP, słownik
trudności, RESERVED w audytorze) — wszystkie twierdzenia mają dowód poniżej.

## 1. Co jest dobre i zostaje bez zmian

1. **Rdzeń S1–S4 jest wdrożony i przetestowany** — SourceRegistry (712),
   ItemAcquisition (8820), formatter z goldens, PluginAPI z walidacją,
   audytor `check_sources.lua` (w tym samosprawdzający się allowlist
   RESERVED: wpis rezerwowany, który zyska referencję, wywala audyt).
   Nie przebudowujemy od zera — META-Z domyka i doszlifowuje.
2. **MASTER nomenklatura** i zasada „dane = fakty, formatter = druk".
   Zero heurystyk difficulty w runtime — usunięte realnie, nie deklaratywnie.
3. **Oracle offline** (AtlasLoot) z separacją licencyjną — poprawny model.
4. **PluginAPI**: replace-wins, walidacja strukturalna z `error(..., 2)`,
   warn-once z atrybucją „Plugin X replaced core …".
5. **Minimalizm wydajnościowy**: O(1) bez cache-frameworka — trafiony.

## 2. Wady znalezione (dowód → werdykt)

### W1. Niedokończony cutover — podwójna prawda o kosztach (krytyczna)

Nowy model dodano, ale **stara ścieżka czytania kosztów żyje w runtime**:

- `DataProvider.lua:399–414` — `GetEmblemCost()` czyta
  `_G.Bistooltip_emblem_items` (EmblemData).
- Konsumenti: `BislistUI.lua:3314/3436/3472/5245`, `DataProvider.lua:609/645`
  (tryb ASCEND, grupowanie emblematów, karty checklisty).
- Równolegle tooltip czyta już z `ItemAcquisition` (VENDOR entries z kosztem).

Czyli: **te same koszty z dwóch miejsc**, mogą się rozjechać po regeneracji
danych; tryb ASCEND w ogóle nie zna nowego modelu. Dodatkowo EmblemData
trzyma w core waluty custom serwera (`EmblemData.lua:29+`: Emblem of
Ascension/II, Echo of the Titans) — zasada „core = czysty WotLK" jest
naruszona już dziś, jeszcze przed powstaniem pierwszej wtyczki.

**Werdykt:** dokończyć cutover (W1 spec v2): `GetEmblemCost` staje się shimem
nad `ItemAcquisition` (sygnatura zachowana, jedno miejsce prawdy), tabela
`Bistooltip_emblem_items` przestaje być czytana w runtime.

### W2. Loot_Sources.lua ładowany bezcelowo (wydajność)

`grep lootTable` poza samym plikiem: **0 konsumentów runtime**. Mimo to
`.toc` ładuje 1624 linie do pamięci przy każdym starcie gry.

**Werdykt:** usunąć `Loot_Sources.lua` z `.toc` w W1 (z obowiązkiem
weryfikacji in-game wg konwencji `Tested-In-Game:`); plik zostaje w repo
jako input migratora offline (migrator czyta z dysku, nie z runtime).

### W3. Martwy kod w folderze addonu (higiena) — ZROBIONE

- `Bislist.lua` — 3653 linie poza `.toc`; zawiera przestarzałą logikę
  ASCEND (`Bislist.lua:3533`), która **myliłaby przy rename VENDOR**.
- `FlowView.lua`, `GridView.lua`, `ItemButton.lua`, `Pool.lua` (root) —
  poza `.toc` (w toc jest tylko `ObjectPool.lua`).
- `legacy/` — README sam opisuje: „Unused/deprecated code".

**Wykonane:** commit `chore: remove dead files not loaded by .toc`
(usunięte 8 plików, README zsyncowany; historia w git).

### W4. Tabele frakcyjne WoWSimsBP bez konsumenta (dane, ~połowa pliku)

`Bistooltip_bislists_alliance/_horde` (druga połowa pliku 1.9 MB,
single-rank + wypełniacze `-1`) — `grep` po całym addonie i tools:
**0 konsumentów**. Census opisał je jako sposób „resolvowania slotów
frakcyjnych", ale runtime ich nigdy nie używa.

**Werdykt:** przy adopcji STANDARD wygenerować plik shippingowy bez tabel
frakcyjnych (mniejszy plik, szybszy load). Decyzja właściciela — Q14
(ewentualnie przewidzieć realny użytek frakcyjny w UI, czego dziś nie ma).

> **KOREKTA (2026-09-08, po Q14 — weryfikacja origin):** werdykt
> „usunąć tabele frakcyjne" był **błędny**. Upstream
> (github.com/ExoJdi/BiS-Tooltip_335a_fixed_backport, commit 2026-06-09)
> konsumuje je aktywnie w `assembleActiveBislists()` (Config.lua):
> scalanie rank-1 tabeli frakcji gracza z pełną tabelą fallback +
> mirror ID (`Bistooltip_horde_to_ali`) + filtr obcej frakcji
> (`Bistooltip_item_faction`). Nasz fork stracił ten krok przy ekstrakcji
> danych — dlatego grep pokazał „0 konsumentów" (true dla forka, false
> dla origin). Tabele zostają; META-Z W4 portuje assembly (spec v2.2 §4).
> Przy okazji stwierdzono: wszystkie 4 pliki danych forka były starsze
> niż origin — refresh wykonany, 27 wpisów custom Frostmourne
> wyekstrahowanych przed importem.

### W5. `SetBiSSlot` zbyt gruby dla wtyczek serwerowych (projekt API)

Slot-level replace wymaga od wtyczki **upieczenia całej listy ranków**
z konkretnej bazy. Skutki: diff nie przenosi się sensownie na inną bazę
(replay wstawiłby listę z wowsims do wh), aktualizacja rankingów w core
nigdy nie dociera do slotów przejętych przez wtyczkę, a 27 nadpisań
Frostmourne trzeba by ręcznie składać na każdej bazie osobno.

**Werdykt:** nowa (szósta) funkcja `SetBiSSlotRank(class, spec, phase,
slot, rank, itemID)` — nadpisanie **pojedynczego ranku**, niezależne od
bazy: „rank 1 = 130031" działa na wowtbc/wh/wowsims tak samo i survivaluje
update core. Walidacje: `rank ≤` długość slotu; ostrzeżenie, gdy itemID
już występuje na innym ranku tego slotu. `SetBiSSlot` (całość listy) zostaje
dla wtyczek świadomie przejmujących slot. To jedyny wzrost powierzchni
API — uzasadniony głównym use case (server diff + skaner).

### W6. TROPHY hardcode w formatterze (naruszenie własnej zasady S2)

`SourceFormatter.lua:18`: `… " - TROPHY: Crusade + " …` — „Crusade" to
dane (nazwa trofeum 47242) zaszyte w kodzie, wbrew „formatter nie zna danych".

**Werdykt:** pole `variantLabel` w danych (entry), formatter drukuje.
Golden testy bez zmian semantyki.

### W7. Jednostka amount dla gold nieokreślona (skaner/format)

Skaner wyemituje `currency="Gold", amount=150000` (miedziaki z API) —
formatter wypisze „150000 Gold" zamiast „15g". 

**Werdykt:** przypiąć kanon: `amount` w miedziakach; formatter renderuje
walutę Gold jako `g/s/c`. Poprawka do speca skanera + golden case.

### W8. Brak wspólnego runnera testów i CI (proces)

4 suity (`test_formatter`, `test_pluginapi`, `check_sources`, census gate)
uruchamiane ręcznie; dane są **regenerowane offline i commitowane** —
regresja danych bez bramki = cichy bug w grze.

**Werdykt:** `tools/run_all` (W8) + propozycja GitHub Actions (luac -p +
testy na push/PR) — opt-in właściciela (Q15), bo repo ma dziś tylko
discord-release workflow.

### W9. Duplikat definicji phases w WoWSimsBP (dane)

`Bistooltip_wowsims_phases` zdefiniowane dwukrotnie (l. 66 i 3606) —
śląd ręcznego sklejania pliku. Nieszkodliwe, ale przy adopcji STANDARD
plik powinien zostać zregenerowany (jedna definicja, bez tabel z W4).

### W10. `GetItemSourceInfo` zwraca tylko pierwsze źródło — ZAAKCEPTOWANE

Świadomy shim dla grupowania UI. Po backfillu marek T10 (11+ realnych
bossów) grupowanie po pierwszym źródle pozostaje OK; jeśli kiedyś zaboli —
flaga `primary` w danych, nie heurystyka. Watch, nie robić teraz.

### W11. `db.char.data_source` — zasięg wyboru bazy per postać (drobna)

Wybór bazy rankingowej to raczej decyzja profilu niż postaci; przy W4
(DB registry) rozstrzygnąć scope (char → profile) wraz z migracją klucza.

## 3. Ustalenia wdrożone do spec v2

| # | Zmiana | Skutek w specu |
|---|---|---|
| 1 | S3-6: `SetBiSSlotRank` | §4 rozszerzony; Whitemane = 27× „rank 1" bez pieczonych list |
| 2 | Cutover runtime przyspieszony | W1 = też `.toc` clean + `GetEmblemCost` shim |
| 3 | Data hygiene STANDARD | W4a: regeneracja pliku wowsims (bez frakcyjnych po Q14, bez duplikatu phases) |
| 4 | S2-5: `variantLabel` + gold `g/s/c` | §3/§8 poprawione |
| 5 | Audyt cross-DB coverage | W2: każdy ID z każdej bazy ma akwizycję albo jest allowlistowany |
| 6 | Pytania Q14–Q16 | §11 rozszerzone |

## 4. Czego świadomie NIE zmieniam

- MASTER strings (składnia) — tylko kolor i słownik trudności, jak w drafcie.
- Replace-wins, brak cache-frameworka, TROPHY display-only, brak
  EnchantAcquisition, CUSTOM walidowane — frozen S1–S4 utrzymane.
- 5 → 6 funkcji API to jedyne poszerzenie powierzchni (uzasadnienie w W5).
- Nie wprowadzam lazy-load baz ani palety w options „na zapas" — dopiero
  po pomiarze (zgodnie z frozen postawą przeciw frameworkom na zapas).
