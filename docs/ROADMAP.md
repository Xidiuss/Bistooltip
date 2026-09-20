# Roadmap Meta-Bistooltipa

Aktualizacja 20 września 2026 po testach właściciela w kliencie. Core, scanner, Whitemane i WOTLK5 pozostają osobnymi pakietami. Priorytety poniżej zastępują wcześniejszą kolejność QoL; nadal wymagają testów natywnego Lua 5.1 i kolejnego smoke testu w grze.

## P0 — poprawność bieżącego wydania

1. Utrzymać naprawy wynikające z testów klienta: poprawna frakcja dla Death's Choice/Verdict, ograniczenie wstawienia BiS do sześciu pozycji, VENDOR tylko dla wymaganych pozycji BiS, oraz źródło scrolla WOTLK5 `5000762`. Sprawdzić Alliance/Horde w WoWSimsBP i wowtbc, RESET, przełączanie baz oraz Whitemane.
2. Udostępniać zgodny core i Whitemane razem. Scanner oferuje `append`, `replace_vendor` i `replace_all`; import Justice/Valor używa zastąpienia starego VENDOR, custom emblemy są dodatkowymi źródłami. Nie traktować pustej ceny jako darmowego zakupu.
3. Przejść natywną macierz Lua 5.1 i testy klienta 3.3.5a. Lokalny Fengari jest tylko kontrolą offline. Zanotować commit, realm, frakcję i wyniki; publikację wykonać dopiero po decyzji właściciela.
4. Zachować [pochodzenie WoWSimsBP od ExoJdi](../README.md) i oddzielność pakietu MIT od zewnętrznego zestawienia AtlasLoot GPL-2.0. Nowe fakty pochodzą z ręcznie sprawdzonego przez właściciela `Private/new_data`; nie kopiować kodu ani tabel tego zestawienia.

## P1 — enchanty i cache

1. **Edytor przypisań enchantów.** Pokazać dostępne scroll ID, źródło i cenę, pozwolić przypisać itemID lub spellID do dokładnego class/spec/phase/slot, wyświetlić podgląd `SetEnhancement` i ostrzeżenie o nadpisaniu istniejącej listy. Walidować typ ID i zgodność slotu. Dziewięć scrolli WOTLK5 ma obecnie źródła zakupu, ale nie rekomendacje.
2. **Cache przedmiotów.** Zmierzyć opóźnienia na zimnym cache w kliencie. Następnie wprowadzić ograniczoną kolejkę żądań z ponawianiem, limitem prób i tokenem generacji widoku, aby spóźniona odpowiedź nie przepisywała bieżącej selekcji. Pokazać stan oczekiwania i umożliwić ręczne odświeżenie.

## P2 — domknięcie danych

1. [Import danych właściciela](NEW-DATA-IMPORT.md) dodał 165 źródeł z pierwszej migawki, następnie 17 kompletnych wymian u Yrma, osiem brakujących źródeł przedmiotów wejściowych i 10 cen Alliance. Niedostępne `43792` usunięto z jednego rankingu Shadow PR. Bieżący census wykazuje zero ID bez źródła w aktywnych rankingach core; [spis 193](MISSING-ACQUISITIONS.md) jest migawką historyczną. Kontynuować kontrolę jakości i dokładności źródeł, nie odtwarzać dawnych braków z tej tabeli.
2. Weryfikować w kliencie złożone wymiany item + Sunmote, ceny par Alliance/Horde oraz miejsce pozyskania `43573`. Dla `37761` znany jest world drop z elitarnych i zwykłych mobów; dokładna lista NPC nie jest wymagana do działania.
3. [Dwadzieścia rekordów custom Whitemane](https://github.com/Xidiuss/Bistooltip/blob/Bistooltip_Whitemane_Frostmourne/docs/BIS-CANDIDATES.md) obejmuje 10 częściowych metod quest/drop, siedem odroczonych upgrade'ów i trzy nieustalone metody. Ceny Ascension z niepotwierdzonym ID waluty i puste koszty pozostają nieaktywne. Uzupełnić konkretne questy, bossów, waluty i dokładne class/spec/phase/slot/rank przed kolejnym wstawieniem BiS.
4. Zweryfikować fazy Wowhead PR/T7, szczególnie `45931` i `48472`, oraz historyczną ofertę `37111` na docelowym serwerze.

## P3 — scanner i przyszłe upgrade'y

1. Trzy tryby eksportu są dostępne; kolejnym krokiem jest zapis realm w kluczu obserwacji, pełne zachowanie alternatywnych ofert wielu merchantów również w trybie zastąpienia ceny i podgląd konfliktu z istniejącym acquisition przed eksportem.
2. Po walidacji danych generować pakiet TOC + plik źródeł. Sam skan merchanta nie tworzy rankingów ani enchantów.
3. Model łańcucha upgrade'ów custom Whitemane zaprojektować osobno po poznaniu kosztu i poprzedniego przedmiotu. Nie wpisywać teraz placeholderowych cen dla siedmiu odroczonych rekordów.

## P4 — koszyk zakupów

Koszyk ma być osobną listą **wybranych, brakujących** przedmiotów. Użytkownik wybiera dla każdego przedmiotu dokładnie jedną z dostępnych ofert (np. Justice albo custom emblem); jedna oferta może wymagać kilku składników jednocześnie, takich jak Honor + Arena lub item wejściowy + Sunmote. Widok sumuje wyłącznie wybrane oferty, oddzielnie według waluty i itemID, a gold liczy w miedzi i formatuje na g/s/c. Pokazuje posiadane ilości, brak i miejsce zakupu, pozwala zmienić ofertę bez zmiany rankingu BiS. Alternatywnych ofert nie sumuje jako jednego kosztu; upgrade'y dochodzą dopiero po zdefiniowaniu łańcucha i zużycia przedmiotów wejściowych.

## Kontrakt i utrzymanie

Wersjonować PluginAPI i schemat danych, diagnozować konflikty overlay oraz wydzielać UI stopniowo po testach w kliencie. `SetBiSSlotRank` zastępuje wskazany rank, a `InsertBiSSlotRank` wstawia lub przenosi przedmiot w granicach liczby pozycji danego slotu. Prywatne narzędzia `Private/Legacy` pozostają poza historią Git, dopóki nie zostanie uzgodniona lokalizacja repozytorium.
