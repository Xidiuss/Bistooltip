# Audyt postmigracyjny — 18–19 września 2026

## Werdykt

Architektura wspiera cel Meta-Bistooltipa: wspólny core dla WotLK 3.3.5a, niezależne rankingi, kanoniczne acquisitions ze składnikami ceny oraz dodatki serwerowe. Nie ma potrzeby kolejnej przebudowy całości. Audyt wykazał jednak rzeczywiste błędy ładowania, migracji stanu, obsługi wtyczek i skanera; opisane niżej poprawki usuwają potwierdzone regresje.

Nie należy jeszcze nazywać całego produktu bezwarunkowo finalnym. Brakuje części źródeł, ranking Wowhead ma ograniczenia faz, a testy offline nie zastępują klienta WoW. Lista poniżej odróżnia naprawione błędy od pozostałego zakresu danych i weryfikacji.

## Zakres i dowody

Punkt wyjścia core: `e7368ca`; Scanner: `45c494b`; Whitemane: `b9c258e`; WOTLK5 S2: `c9a16db`. Sprawdzono manifesty i zależności XML, runtime core/UI, konfigurację i SavedVariables, trzy rankingi, obie frakcje, acquisitions, formatter, PluginAPI, wszystkie trzy dodatki oraz historię migracji. Dawne plany z `Private/Legacy/docs` były kontekstem, nie dowodem aktualnej poprawności.

Zdalna lista gałęzi sprawdzona na początku audytu zawierała cztery publikowane komponenty. `META-Z` był historyczną nazwą etapu migracji; nowy pusty lokalny worktree powstał przed wycofaniem starej instrukcji użytkownika i nie służył do zmian. Zmiany są przypisane do obecnych gałęzi komponentów.

## Potwierdzone i naprawione problemy

| Obszar | Dowód / wcześniejszy skutek | Poprawka i weryfikacja |
| --- | --- | --- |
| Paczka core | TOC wskazywał dwie nieobecne biblioteki SharedMedia i błędny katalog LibDataBroker; inny addon mógł maskować błąd | Poprawiona ścieżka, usunięte martwe deklaracje; rekursywny test TOC/XML |
| RESET | Zapis do `db.global`, kasowanie z `db.char`; personalizacja wracała | Reset właściciela account-wide, regresja odczytu po resecie |
| Migracja konta | Przy każdym logowaniu ponownie importowano stare pola postaci | Jednorazowy znacznik; test zmiany bazy i logowania inną postacią |
| Własność rankingów | Kopiowane były tylko tablice faz; sloty i Horde overrides nadal współdzielono | Świeże kopie slotów; reset po przełączeniu bazy zachowuje bazę/plugin |
| Personalizacja i progress | Kolejność stosowano dopiero po filtrowaniu/splitach ringów | Stosowanie personalizacji przy odczycie, przed filtrami |
| Start Whitemane | Pierwszy override T7 przerywał wtyczkę przy bazie bez tego profilu/fazy | Poprawne cele rank odraczane; start i powtarzane przełączenia testowane na 3 bazach × 2 frakcjach |
| Lua 5.1 replay | `unpack({...})` polegał na nieokreślonej długości tablicy z nil dla COMMON | Jawna liczba argumentów i granice unpack; regresja legalnej granicy długości 2 |
| Replay Add/Set | Drugi replay mógł dopisać starą ofertę do zapisanej tabeli późniejszego SetAcquisition | Każde odtworzenie otrzymuje kopię argumentów; test czterech replayów i rzeczywistych wtyczek |
| CUSTOM source | API akceptowało definicję CUSTOM, renderer DROP konkatenował brakujące instance/boss | Renderowanie etykiety i właściwa klasyfikacja w DataProvider |
| Koszt itemowy | Formatter pomijał składniki `{item=..., amount=...}` | Widoczne wszystkie składniki; zachowany format TROPHY |
| VENDOR | Filtr wymagał waluty tekstowej, gubił item-only/CUSTOM i głębsze ringi | Kwalifikacja według metody; złożone/alternatywne koszty nie udają kompletnego budżetu |
| VENDOR / UI | Kilka ofert pakowano do jednej widocznej kolumny; COST pokazywał pierwszą walutę/surową miedź; pusty widok zachowywał stare nagłówki | Osobne wiersze przedmiotów, jednostki złota, Details dla cen złożonych, zwalnianie nagłówków przed pustym widokiem |
| Globalne Lua | Core podmieniał `table.insert/remove` dla wszystkich addonów | Usunięte przechwytywanie diagnostyczne z dochodzenia `d3369aa`/`427af8d` |
| UI/pule | Drugie Initialize alokowało kolejną pulę; zamknięcie gubiło referencje ramek | Idempotentne pule i ponowne używanie całego okna; poprawiona widoczność locals w cleanup |
| GetItemInfo | Gotowość pierwszych 21 rekordów kończyła preload pozostałych; spell ID wysyłano jako item | Kontrola wszystkich żądanych ID, tylko enhancement typu item |
| Tooltip | Wspólny cooldown blokował drugi tooltip i szybką zmianę modyfikatora | Oba tooltipy reagują na press/release, zachowany reentry guard |
| Dane vendorów | 25 błędnych cen/walut poza wcześniejszym audytem setów | Poprawione wejście offline i odtworzony output, testy cen |
| Scanner / cache | Rozwiązany placeholder pozostawał drugim wpisem; późniejsze nazwy nie trafiały do exportu | Usuwanie resolved pending:N, odświeżanie metadata bez nadpisywania ręcznych kosztów |
| Scanner / CSV | Pusty koszt dawał pięć kolumn pod sześciokolumnowym nagłówkiem | Poprawiony separator, test rzeczywistego eksportu |
| Scanner / klient 3.3.5 | Honor błędnie traktowany jako liczba składników kosztu, token-only pomijany | Osobne Honor/Arena/third-return token count, zachowana zgodność z count-only wariantem serwera |

Sygnaturę skanera potwierdza [kod MerchantFrame klienta 3.3.5](https://github.com/wowgaming/3.3.5-interface-files/blob/main/MerchantFrame.lua#L220). Źródłem kontroli cen był [offline oracle AtlasLoot](https://github.com/wonderkidsem-official/Pazzions-WotLK-BiS-List-AtlasLoot-Enhanced-v5.11.04/blob/main/AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua), którego repozytorium deklaruje GPL-2.0. Kod oracle nie został dodany do dodatku ani historii tego audytu. Aby utrzymać osobny pakiet MIT, nie przenosimy jego kodu ani tabel do runtime; fakty zaproponowane przez oracle wymagają niezależnej weryfikacji i zapisu pochodzenia. Historycznie wygenerowane fakty i wejścia generatora wymagają przeglądu pochodzenia przed wydaniem — samo trzymanie pliku oracle poza Git nie rozstrzyga licencji wszystkich wyników. Przykłady poprawionych faktów: 50965 → 95 Frost, 50993 → 60 Frost, 47667 → 25 Triumph. Poprzednia macierz tierów nadal przechodzi audyt.

## Architektura i ownership

Szczegóły zawierają [ARCHITECTURE.md](ARCHITECTURE.md) i [PLUGIN-API.md](PLUGIN-API.md). Istotne rozstrzygnięcia:

- SourceRegistry i ItemAcquisition nie są dwiema konkurencyjnymi bazami ceny: pierwszy opisuje źródło, drugi metodę wraz z kosztem. Ich rozdzielenie jest uzasadnione.
- `EmblemData.lua` było pozostałością migracji w runtime, łącznie z heurystycznym custom T8. Obecnie pozostaje wyłącznie potrzebnym wejściem prywatnego generatora, nie ładuje się w grze. `/bisemblem` korzysta z canonical acquisitions.
- `Config` jest właścicielem wyboru i bindowania, PluginAPI zmian serwera, DataProvider personalizacji i odczytu, formatter tekstu. Nie istnieje osobny aktywny moduł DisplayNames.
- MAIN/BIS nadal mają dużą implementację w BislistUI, obok globalnych pomocników UIFramework/ui. To obszar późniejszej redukcji, nie powód do ryzykownego przepisywania działającego UI teraz.
- Dane obserwowane przez scanner wymagają decyzji autora wtyczki: źródła i ceny nie wyznaczają samoczynnie hierarchii BiS ani rekomendowanych enchantów.

## Cleanup i zachowane elementy

Usunięto 18 śledzonych plików: stary `Libs/Bislist.lua`, niewykorzystywane AceHook/AceTimer/LibGroupTalents i LibParse z jego prywatną kopią LibStub/testami. Sprawdzono manifesty, konsumentów core i wtyczek oraz dynamiczne ładowanie. Wszystkie są do odzyskania z historii Git.

Usunięto osiem lokalnych funkcji BislistUI mających wyłącznie deklarację, bez eksportu/callbacków: AddFrameShadow, CreateTabBar, GetEnchantNameFromEntry, CreateEnhancementsFrame, drawItemSlot, drawTableHeader, ApplySpecTable, CreatePillButton. Zakresy bloków sprawdzono parserem Lua 5.1. Usunięto nieużywaną równoległą tabelę cen w Constants.

Usunięto również blok stopki Ascension sterowany lokalną zmienną, która nigdy nie otrzymywała wartości innej niż nil. Priorytety są stosowane raz przy odczycie danych, nie ponownie po utworzeniu filtrowanych wierszy.

Zachowano `ui/SlotRow.lua`, `ui/ProgressBar.lua` i globalne interfejsy UIFramework: brak aktywnego konsumenta części metod w core nie dowodzi braku zewnętrznych użytkowników. Zachowano trzy rankingi, mapę frakcji i surowe wejście EmblemData, które ma rzeczywistego konsumenta offline. Nie przenoszono prywatnych narzędzi do Git.

## Faktyczna kompletność danych

Acquisitions zawierają 8250 itemID i 10320 wpisów, registry 683 źródła. Pełny audyt formatu/referencji nie wykrywa osieroconych sourceID ani niewyrenderowalnych wpisów. Nie jest to dowód, że każdy przedmiot z rankingów ma źródło.

| Runtime dataset | Sloty | Dodatnie wpisy rankingowe | Unikalne ID bez acquisitions | W tym ID na rank 1 |
| --- | ---: | ---: | ---: | ---: |
| WoWSimsBP Alliance | 2897 | 16732 | 134 | 18 |
| WoWSimsBP Horde | 2897 | 16732 | 120 | 17 |
| wowtbc | 2822 | 16619 | 107 | 22 |
| Wowhead (`wh`) | 2284 | 13614 | 102 | 10 |

Przykłady luk STANDARD: 34181, 34210, 34241, 34340, 34348, 34388, 37574, 40585, 40586, 41678, 42339, 42853, 43253, 43792, 44063, 44210, 51432; Alliance dodatkowo 47698. Lista zawiera też sprzęt spoza raidów WotLK. Test `test_datasets.lua` publikuje bieżący census zamiast maskować brak źródeł heurystyką.

Wowhead PR/T7 wymaga osobnej kuracji faz: wcześniejsze notatki wskazywały np. 45931/Ulduar i 48472/T9 w kontekście PR. W tym audycie nie zmieniano arbitralnie rankingu ani dostępnych faz. Baza pozostaje alternatywną migawką, nie gwarancją ścisłej progresji serwera.

Dodatkowy kandydat do kontroli danych: vendor 60 Heroism dla 37111 pochodzi jeszcze z `e07563c`, a dostępny oracle wykazuje drop Mal'Ganis. Nie zmieniono go wyłącznie na podstawie braku wpisu vendorowego w jednym źródle. WOTLK5 ma osobną, jawną ofertę za Resolve. Tej pozycji nie należy uznawać za zweryfikowany koszt stock.

## Gałęzie

| Gałąź | Rzeczywiste przeznaczenie |
| --- | --- |
| `main` | Samodzielny core i jego publiczne testy/dokumentacja |
| `Bistooltip_Scanner` | Samodzielny scanner, OptionalDeps na core |
| `Bistooltip_Whitemane_Frostmourne` | 377 dodanych acquisitions, 27 nadpisań ranków; brak automatycznego wykrywania realm |
| `Bistooltip_WOTLK5_S2` | 620 dodanych acquisitions, 8 wpisów źródeł zwojów; brak SetEnhancement |

Wydzielenie dodatków jest widoczne w `68d0272` i osobnym pniu dodatków `e766d02`; nie są to gałęzie eksperymentalne do scalania całymi drzewami w main. Starsze nazwy META-Z/feat w dokumentach odnoszą się do historii migracji. Wszystkie aktywne komponenty dostały opis odpowiadający ich zawartości.

Liczby Whitemane w tabeli odnoszą się do opublikowanego punktu wyjścia. Po ustabilizowaniu core osobno zbadano dopisany eksport skanera: autor wybrał 112 ofert Justice/Valor zastępujących stare ceny VENDOR z zachowaniem innych metod. Najnowsze 23 adnotowane ID legendarek pozostają komentarzami do przyszłego BiS, nie pustymi ofertami. Szczegóły i test polityki importu znajdują się na gałęzi Whitemane w `docs/SCANNER-IMPORT-AUDIT.md`.

Zgłoszenie użytkownika dotyczące AMOUNT również potwierdzono: edycja aktywnego presetu aktualizowała zapis, lecz nie ukryte pola robocze. Scanner synchronizuje je teraz natychmiast i chroni SavedVariables przed częściowymi wartościami podczas renderowania. Siedem testów callbacków menu uzupełnia dziesięć regresji merchant/export.

## Weryfikacja i jej granice

Wykonano bieżące regresje core, scanner, formatter/pluginapi oraz prywatny check_sources/census. Rzeczywiste wtyczki testowane są przy 12 kombinacjach startowych (2 dodatki × 3 bazy × 2 frakcje), po sześciu zmianach bazy w każdej kombinacji. Acquisitions nie mnożą się, rank overrides zachowują się na obsługiwanych ścieżkach. Oba pliki outputu generatora sources/acquisitions sprawdzono SHA-256 z regeneracją do osobnego katalogu.

Lokalne wykonanie korzystało z Fengari (Lua 5.3) i osobnego parsera składni Lua 5.1. Kontrolowany runner zwraca błąd procesu przy błędzie Lua, czego użyty CLI Fengari nie gwarantuje. Native Lua 5.1 oraz WoW nie były dostępne: nie jest to wynik testów natywnych ani in-game.

Publiczne CI obejmuje teraz pakiet, składnię i regresje na Lua 5.1, integrację rzeczywistych gałęzi serwerowych oraz osobny job scanner. Istniejące testy Discord pozostały. Konfiguracja CI nie jest dowodem wykonanego zdalnego przebiegu. Checklistę klienta zawiera [DEVELOPMENT.md](DEVELOPMENT.md).

## Bezpieczna kolejność dalszego rozwoju / QoL

1. **Domknięcie wydania:** natywne CI Lua 5.1 i smoke test core-alone, obie frakcje, start Whitemane z każdą bazą, reset po przełączeniu, cold cache, merchant Honor/Arena/token. Dopiero potem oznaczenie wydania jako sprawdzonego w grze.
2. **Kuracja danych:** uzupełnianie luk rank 1 z udokumentowanymi źródłami, kontrola kandydatów takich jak 37111, decyzja o PR/T7 Wowhead. Zmiany przez wejścia generatora i deterministyczny output, bez reguły „podobny slot = tier”.
3. **Scanner → wtyczka:** wybór Append/Replace, zachowanie alternatywnych ofert per vendor i currency itemID, gotowy szkielet TOC + plik danych, eksport bez ucięcia okna i raport niezbuforowanych ID. Realm powinien wejść do klucza obserwacji.
4. **Koszyk zakupów:** jawny wybór jednej oferty dla przedmiotu, suma wszystkich wymaganych składników w poprawnych jednostkach, osobno brakujące i posiadane waluty/tokeny. Nie sumować alternatyw jako jednego obowiązku.
5. **Enchantment QoL:** edytor powiązania zeskanowanego scrolla z klasą/specem/slotem, walidacja itemID vs spellID, podgląd wynikowego SetEnhancement.
6. **Obsługa cache:** jedna ograniczona kolejka z tokenem generacji widoku, ponawianiem i niską częstotliwością sprawdzania; obecny limit bulk 2 s wymaga czasem RELOAD. Zmianę poprzedzić pomiarem w kliencie, nie zwiększać bez końca pętli dla nieistniejących ID.
7. **Kontrakt rozszerzeń:** wersjonowanie API/schematu, jawna identyfikacja realm i konfliktów overlay, provenance danych, pełna walidacja kosztów/ID oraz publiczny proces generatorów po uzgodnieniu repozytorium dla prywatnych narzędzi.
8. **Redukcja UI:** po smoke testach zinwentaryzować zewnętrzne użycie globalnych komponentów, następnie wygasić rzeczywiście zbędne API i wydzielać odpowiedzialności stopniowo. Nie przepisywać całego BislistUI dla estetyki.
