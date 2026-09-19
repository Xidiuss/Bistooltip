# Roadmap Meta-Bistooltipa

Stan planu: 19 września 2026. Punkt wyjścia: [audyt postmigracyjny](POSTMIGRATION-AUDIT.md) i [audyt importu Whitemane](https://github.com/Xidiuss/Bistooltip/blob/Bistooltip_Whitemane_Frostmourne/docs/SCANNER-IMPORT-AUDIT.md). Core dla WoW 3.3.5a, trzy niezależne migawki rankingów, kanoniczne acquisitions i osobne dodatki serwerowe tworzą bazę do dalszego rozwoju. Kolejne etapy mają domknąć zachowanie, wiarygodność danych i użyteczność; nie wymagają ponownej przebudowy całości.

## P0 — zrobić teraz, przed wydaniem

| Działanie | Dlaczego teraz | Warunek ukończenia |
| --- | --- | --- |
| Wstawianie serwerowego BiS na rank 1 | Dotychczasowe `SetBiSSlotRank` usuwało pierwszą bazową alternatywę Whitemane | 27 wpisów używa `InsertBiSSlotRank`; kolejność i liczba bazowych ID zostają zachowane po starcie, zmianie bazy i RESET; MAIN/CUSTOM pokazują przesuniętą siódmą pozycję |
| Spójne opisy czterech gałęzi | Użytkownik musi wiedzieć, co instaluje i od czego zależy wtyczka | Każdy README podaje rolę, instalację, zakres danych, ograniczenia i status weryfikacji; core i Whitemane opisują zależność od nowego API |
| Natywna weryfikacja przed publikacją | Lokalny Fengari nie jest klientem Lua 5.1; nowa konfiguracja CI nie dowodzi udanego przebiegu | Zielone CI Lua 5.1 dla core, obu wtyczek i scannera; odnotowany commit i wynik przebiegu |
| Smoke test w kliencie 3.3.5a | Stubowane API nie dowodzi ładowania TOC, renderowania ani cen serwera | Wykonać [checklistę](DEVELOPMENT.md#in-game-smoke-checklist): core osobno, Alliance/Horde, każda baza z Whitemane, rank 1–7 po RESET, zimny cache, VENDOR, scanner Honor/Arena/token i WOTLK5 scroll; zapisać wyniki i błędy Lua |
| Publikacja zgodnych pakietów | Aktualny Whitemane wywołuje nową funkcję core | Opublikować i instalować zgodny core razem z Whitemane; nie udostępniać nowej wtyczki z wcześniejszym core |

Pierwsze dwa wiersze zrealizowano lokalnie w bieżącej zmianie. Status wydania pozostaje otwarty do czasu potwierdzenia pozostałych bramek. Push sam w sobie nie zastępuje sprawdzenia przebiegu CI.

## P1 — wiarygodność danych

1. **Źródła dla rank 1.** Zacząć od 18 brakujących ID WoWSimsBP Alliance, 17 Horde, 22 wowtbc i 10 Wowhead; następnie zmniejszać pozostałe luki (odpowiednio 134/120/107/102 unikalne ID bez acquisitions w całych bazach). Liczby odnoszą się do migawek z audytu i mogą obejmować te same ID. Każdy wpis powinien mieć potwierdzone źródło, metodę i — jeśli dotyczy — wszystkie składniki ceny; generator ma dawać deterministyczny output i przejść census.
2. **Fazy Wowhead.** Zweryfikować PR/T7 względem dostępności przedmiotów na docelowym progresie, w tym wskazane w audycie 45931 i 48472. Opisać zasady faz i skorygować tylko potwierdzone przypadki; obecnie Wowhead jest alternatywną migawką, nie obietnicą ścisłej progresji.
3. **Kontrola wątpliwych cen.** Sprawdzić kandydatów takich jak 37111 w więcej niż jednym źródle lub w kliencie. Nie usuwać istniejącej oferty wyłącznie dlatego, że pojedynczy oracle jej nie zawiera. Dla Justice/Valor Whitemane zachować przyjętą politykę: nowa cena zastępuje starszą VENDOR, a DROP/TOKEN/MARK pozostają.

## P2 — od skanu do sprawdzalnej wtyczki

1. Eksport scannera z jawnym wyborem **Append** lub **Replace vendor price**, raportem pustych cen, niezbuforowanych ID i alternatywnych ofert różnych merchantów/walut. Wybór musi być widoczny przed wygenerowaniem kodu, ponieważ `SetAcquisition` zastępuje wszystkie metody.
2. Dodać identyfikator realm do klucza obserwacji i zachować itemID waluty oraz pochodzenie skanu w danych do przeglądu. Nie zakładać, że sama nazwa Justice/Valor identyfikuje walutę na wszystkich serwerach.
3. Generować kompletny szkielet dodatku TOC + dane po walidacji. Decyzje o BiS i enchantach pozostają redakcyjne: sam skan merchanta nie wyznacza klasy, speca, fazy ani rankingu.

## P3 — funkcje użytkowe po ustabilizowaniu danych

1. **Koszyk zakupów:** użytkownik wybiera jedną ofertę na przedmiot; suma obejmuje wszystkie jej waluty, tokeny i gold w poprawnych jednostkach, z rozdzieleniem posiadanych i brakujących. Alternatyw nie sumować jak wspólnego obowiązku.
2. **Enchantment:** edytor przypisuje potwierdzony scroll do klasy/speca/fazy/slotu i pokazuje wynik `SetEnhancement`. Sprawdza itemID kontra spellID; osiem scrolli WOTLK5 ma na razie tylko ceny pozyskania.
3. **Cache przedmiotów:** zmierzyć opóźnienia w kliencie, potem zastąpić ograniczenie 2 s kolejką z ponawianiem i tokenem generacji widoku. Dla brakujących ID kolejka musi mieć granicę prób.

## P4 — kontrakt i utrzymanie

- Wersjonować kontrakt PluginAPI i schemat danych; dodać diagnostykę konfliktów overlay oraz identyfikację realm. Zachować osobne znaczenia `SetBiSSlotRank` (zastąp) i `InsertBiSSlotRank` (wstaw/przesuń).
- Zinwentaryzować konsumentów globalnych komponentów UI po testach w kliencie, a następnie usuwać lub wydzielać tylko potwierdzony martwy kod. Wiele elementów BislistUI można upraszczać stopniowo.
- Jeśli prywatne narzędzia `Private/Legacy` mają być wersjonowane, najpierw uzgodnić repozytorium i lokalizację. Ich lokalny stan nie jest częścią publikowanych gałęzi.

## Definicja wydania

Każdy pakiet ma wskazany commit, zielone odpowiednie testy natywnego Lua 5.1, poprawny manifest/składnię oraz zapisany smoke test klienta na właściwym serwerze. Dokumentacja mówi, które źródła i fazy są jeszcze niepełne. Wtyczki są sprawdzane z tą wersją core, z którą użytkownik ma je instalować.
