# Roadmap Meta-Bistooltipa

Aktualizacja 20 września 2026 po testach właściciela w kliencie. Core, scanner, Whitemane i WOTLK5 pozostają osobnymi pakietami. Priorytety poniżej zastępują wcześniejszą kolejność QoL; nadal wymagają testów natywnego Lua 5.1 i kolejnego smoke testu w grze.

## P0 — poprawność bieżącego wydania

1. Utrzymać naprawy wynikające z testów klienta: poprawna frakcja dla Death's Choice/Verdict, ograniczenie wstawienia BiS do sześciu pozycji, VENDOR tylko dla wymaganych pozycji BiS, oraz źródło scrolla WOTLK5 `5000762`. Sprawdzić Alliance/Horde w WoWSimsBP i wowtbc, RESET, przełączanie baz oraz Whitemane.
2. Udostępniać zgodny core i Whitemane razem. Scanner oferuje `append`, `replace_vendor` i `replace_all`; import Justice/Valor używa zastąpienia starego VENDOR, custom emblemy są dodatkowymi źródłami. Nie traktować pustej ceny jako darmowego zakupu.
3. Przejść natywną macierz Lua 5.1 i testy klienta 3.3.5a. Lokalny Fengari jest tylko kontrolą offline. Zanotować commit, realm, frakcję i wyniki; publikację wykonać dopiero po decyzji właściciela.
4. Zachować [pochodzenie WoWSimsBP od ExoJdi](../README.md) i oddzielność pakietu MIT od zewnętrznego zestawienia AtlasLoot GPL-2.0. Nowe fakty pochodzą z ręcznie sprawdzonego przez właściciela `Private/new_data`; nie kopiować kodu ani tabel tego zestawienia.

## P1 — enchanty i cache

1. **Automatyczne enchanty pluginów — wdrożone.** Customowe rekomendacje należą do pluginów i zastępują wyłącznie pierwszy wpis enhancementu, zachowując dalsze gemy. Ręczny edytor oraz jego osobista warstwa override zostały usunięte po wdrożeniu kompletnych reguł WOTLK5; stare zapisane przypisania są czyszczone podczas migracji.
2. **Cache przedmiotów — poprawiony offline.** Ładowanie listy działa porcjami po osiem ID, ponawia do czterech prób w oknie ośmiu sekund, pokazuje liczbę oczekujących/brakujących i nie pozwala staremu callbackowi skasować nowego widoku. Kolejka doraźna też ponawia i odświeża dane po załadowaniu. Zmierzyć zimny cache i stabilność odświeżania w kliencie; RELOAD pozostaje ręcznym sposobem ponownej próby.

### Stan bieżący: automatyczne enchanty

Rekomendacje ulepszeń pochodzą z deklaratywnych reguł pluginu serwera i są rozwiązywane w czasie budowania widoku. Core współdzieli rozpoznawanie aktywnej specjalizacji dla sekcji „Your specialization”, wykrywa profesje i wybiera regułę globalną albo profession-gated. Zwykła zakładka zawsze określa własny spec; profesje postaci obowiązują wszystkie specy jej klasy i nigdy inne klasy. Nie istnieje późniejsza warstwa ręcznego nadpisania.

Hybrydowy Feral jest klasyfikowany jako tank, a wariant Enhancement/Spellhance w „Your specialization” rozróżnia broń i dostępność profilu Spellhance. Wybrana reguła zastępuje wyłącznie `enhs[1]` w defensywnej kopii slotu i zachowuje wszystkie dalsze gemy. Szczegóły kontraktu i testów opisuje [specyfikacja reguł profesyjnych](superpowers/specs/2026-09-30-profession-enhancement-rules-design.md).

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

VENDOR już jest prostą listą zakupów BiS: pokazuje wymagane pozycje, ich ceny i pozwala eksportować checklistę. Docelowy koszyk ma rozszerzyć ten widok o ręcznie wybierane przedmioty zakupowe **także spoza BiS**, gdy stanowią użyteczny upgrade. Użytkownik wybiera jedną ofertę na przedmiot, może zmieniać kolejność kupna, a widok pokazuje liczbę pozycji i sumy kosztów według waluty/itemID. Składniki jednej oferty (np. Honor + Arena) sumują się razem; alternatywne oferty nie są dodawane jednocześnie. Powiadomienie dźwiękowe ma zadziałać raz, gdy wiarygodnie odczytane zasoby wystarczą na konkretną pozycję; dla walut bez dostępnego stanu nie wolno zgadywać gotowości. Zakupy automatyczne i łańcuchy upgrade'ów nie należą do pierwszego wydania koszyka.

## Kontrakt i utrzymanie

Wersjonować PluginAPI i schemat danych, diagnozować konflikty overlay oraz wydzielać UI stopniowo po testach w kliencie. `SetBiSSlotRank` zastępuje wskazany rank, a `InsertBiSSlotRank` wstawia lub przenosi przedmiot w granicach liczby pozycji danego slotu. Prywatne narzędzia `Private/Legacy` pozostają poza historią Git, dopóki nie zostanie uzgodniona lokalizacja repozytorium.
