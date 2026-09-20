# Import danych użytkownika

Wejście offline: `Private/new_data/bistooltip_codex_dane.json` (wersja 2026-09-19-v3). Plik wejściowy pozostaje poza Git; wykonywalna migawka znajduje się w `Bistooltip/UserVerifiedSources.lua`. Metody opisane bez NPC albo ceny są oznaczone jako częściowe i nie udają zakupu.

| Typ | Dodane ID |
| --- | ---: |
| CRAFT | 20 |
| DROP | 52 |
| PVP | 44 |
| QUEST | 28 |
| VENDOR | 16 |
| VENDOR_EXCHANGE | 1 |
| WORLD_EVENT | 4 |

Łącznie dodano źródła dla **165** unikalnych ID. Skorygowano też dwa rankingi: przedmiotem docelowym jest `34391`, a `34209` stanowi wyłącznie jeden ze składników wymiany. Nie dodano bezpośredniego dropu docelowego 34391: jego pełna oferta to 1 × 34209 i 1 × Sunmote 34664 u Yrma.

Po tej pierwszej migawce brakowało źródła dla 28 ID WoWSimsBP Alliance, 18 Horde, 24 wowtbc.gg i 10 Wowhead. **Uzupełnienie właściciela z 20 września zamknęło wszystkie te luki w aktywnych rankingach**; lista poniżej zachowuje stan wejściowy przed uzupełnieniem.

## Dawne pominięcia z pierwszej migawki

| itemID | Powód |
| ---: | --- |
| 34381 | Yrma exchange needs precursor item ID |
| 34385 | Yrma exchange needs precursor item ID |
| 34386 | Yrma exchange needs precursor item ID |
| 34388 | Yrma exchange needs precursor item ID |
| 34389 | Yrma exchange needs precursor item ID |
| 34390 | Yrma exchange needs precursor item ID |
| 34392 | Yrma exchange needs precursor item ID |
| 34394 | Yrma exchange needs precursor item ID |
| 34396 | Yrma exchange needs precursor item ID |
| 34397 | Yrma exchange needs precursor item ID |
| 34398 | Yrma exchange needs precursor item ID |
| 34399 | Yrma exchange needs precursor item ID |
| 34400 | Yrma exchange needs precursor item ID |
| 34401 | Yrma exchange needs precursor item ID |
| 34404 | Yrma exchange needs precursor item ID |
| 34406 | Yrma exchange needs precursor item ID |
| 34408 | Yrma exchange needs precursor item ID |
| 43792 | reported unavailable; no automatic alias |
| 47674 | price missing, faction-restricted or unsupported |
| 47677 | price missing, faction-restricted or unsupported |
| 47689 | price missing, faction-restricted or unsupported |
| 47690 | price missing, faction-restricted or unsupported |
| 47693 | price missing, faction-restricted or unsupported |
| 47694 | price missing, faction-restricted or unsupported |
| 47702 | price missing, faction-restricted or unsupported |
| 47704 | price missing, faction-restricted or unsupported |
| 47713 | price missing, faction-restricted or unsupported |
| 47715 | price missing, faction-restricted or unsupported |

Siedem upgrade’ów Whitemane pozostaje odroczonych zgodnie z danymi wejściowymi. Customowe ceny Ascension z nieustalonym ID waluty nie zostały uruchomione. Wtyczka zachowuje dotychczasowe aktywne ranki i źródła; 20 rekordów customowych pozostaje do precyzyjnego mapowania profili i ofert.

## Uzupełnienie zweryfikowane przez właściciela — 20 września

Nowe fakty runtime są w `Bistooltip/OwnerVerifiedAdditions.lua`. Każdy poniższy przedmiot docelowy ma **jedną ofertę u Yrma** wymagającą łącznie 1 × wskazany przedmiot wejściowy oraz 1 × Sunmote `34664`. Boss zrzuca przedmiot wejściowy, nie cel wymiany.

| Cel u Yrma | Przedmiot wejściowy | Źródło wejściowego — Sunwell Plateau 25N |
| ---: | ---: | --- |
| 34381 | 34180 | Brutallus `24882` |
| 34385 | 34188 | Felmyst `25038` |
| 34386 | 34170 | Sathrovarr the Corruptor `24892` |
| 34388 | 34192 | Grand Warlock Alythess `25166` / Lady Sacrolash `25165` |
| 34389 | 34193 | Alythess `25166` / Sacrolash `25165` |
| 34390 | 34208 | Alythess `25166` / Sacrolash `25165` |
| 34392 | 34195 | Alythess `25166` / Sacrolash `25165` |
| 34394 | 34215 | Entropius `25840` |
| 34396 | 34229 | Entropius `25840` |
| 34397 | 34211 | Entropius `25840` |
| 34398 | 34212 | Entropius `25840` |
| 34399 | 34233 | Entropius `25840` |
| 34400 | 34345 | Kil'jaeden `25315` |
| 34401 | 34243 | Kil'jaeden `25315` |
| 34404 | 34244 | Kil'jaeden `25315` |
| 34406 | 34342 | Kil'jaeden `25315` |
| 34408 | 34234 | Entropius `25840` |

`43792` pozostaje bez źródła: właściciel potwierdził, że jest niedostępny dla graczy. Jedyny ranking z tym ID, Priest/Shadow/PR/Chest w WoWSimsBP, używa teraz istniejącego w tej liście `39523` na pierwszym miejscu, a dalsze pozycje przesunięto bez duplikatu. `39515` pozostaje wariantem dla Discipline/Holy. Nie utworzono aliasu `43792`.

Dla dziesięciu cen Alliance dopisano oferty Emblem of Triumph; odpowiadające im wersje Horde i ceny były już w core. Pary 75 emblemów: `47674→47675`, `47677→47678`, `47689→47688`, `47690→47691`, `47693→47692`, `47694→47695`. Pary 45 emblemów: `47702→47701`, `47704→47705`, `47713→47714`, `47715→47716`. Istniejące mapowanie frakcji wybiera odpowiedni itemID; nie jest potrzebny nowy warunek frakcyjny w strukturze kosztu.

`37761` ma opis world drop z elitarnych i zwykłych mobów; liczby „ok 275” nie przeliczono na poziom ani szansę dropu bez określonej jednostki. `43573` wskazuje Nascent Val'kyr, NPC `29570`, bez zgadywania lokalizacji. Test census po załadowaniu uzupełnienia wykazuje **0 brakujących źródeł** w rankingach WoWSimsBP Alliance/Horde, wowtbc.gg i Wowhead. Pełniejsza kuracja źródeł oraz customowe dane Whitemane pozostają osobnymi zadaniami.
