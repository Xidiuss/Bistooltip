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

Po imporcie brak źródła dla **28** unikalnych ID w WoWSimsBP Alliance, 18 w WoWSimsBP Horde, 24 w wowtbc.gg oraz 10 w Wowhead. To liczby dla aktywnych rankingów, nie liczba wszystkich przedmiotów w grze. Pełna lista 28 ID i zakres potrzebnych danych znajdują się poniżej.

## Pominięte lub wymagające kolejnych danych

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

## Dane potrzebne do zamknięcia pozostałych 28 pozycji

- **17 wymian u Yrma:** dla każdego ID `34381, 34385, 34386, 34388, 34389, 34390, 34392, 34394, 34396, 34397, 34398, 34399, 34400, 34401, 34404, 34406, 34408` potrzebny jest dokładny itemID przedmiotu oddawanego razem z `34664` (Sunmote). Jeśli miejsce zdobycia przedmiotu wejściowego jest znane, warto podać też jego NPC/instancję. `34388` jest także brakującym rank 1 w WoWSimsBP i wowtbc.gg.
- **`43792`:** potwierdzenie, czy ten itemID istnieje na docelowym serwerze, a jeśli nie, wskazanie właściwego docelowego ID i jego relacji do `40458`/`40625`. Nie tworzymy automatycznego aliasu; jest to drugi brak rank 1 WoWSimsBP.
- **10 cen tylko Alliance:** `47674, 47677, 47689, 47690, 47693, 47694` mają w wejściu cenę 75 × Emblem of Triumph; `47702, 47704, 47713, 47715` mają 45 ×. Kwoty są znane. Przed aktywacją potrzebny jest model ofert zależnych od frakcji i, jeżeli przedmioty występują u Hordy, odpowiadające im ID lub potwierdzenie braku odpowiednika. Te 10 pozycji występuje w rankingach Alliance; nie wymagamy ponownego podawania samej kwoty.

Znane jako **world drop** `37761` i `43573` mają już częściowe źródło bez zgadywania konkretnego NPC. Jeśli dysponujesz miejscem lub przeciwnikiem, można później uszczegółowić opis.
