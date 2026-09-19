# Audyt lokalnego importu skanera — 2026-09-19

Porównanie pierwotnego importu w `main.lua` z opublikowanym `b9c258e`, z core po audycie `8a2964c`. Ustalenia poniżej opisują stan przed naprawą; końcowa sekcja opisuje uzgodnione zmiany. Audyt nie jest niezależnym potwierdzeniem cen na serwerze.

## Ustalenia

- Dopisano 138 wywołań `SetAcquisition` dla 138 różnych ID: Lambriesse 37, Sarien 28, Brasael 47 oraz 26 ręcznych obserwacji bez ceny.
- 116 ID miało wcześniej źródła w core lub pierwotnej wtyczce. Import zastępuje 166 wpisów: 43 DROP, 115 VENDOR, 8 TOKEN. Czternaście ID koliduje z wcześniejszym `AddAcquisition` w tym samym pliku.
- 65 ofert używa `Justice` z komentarzem `item:40752`; 47 używa `Valor` z komentarzem `item:40753`. Nie należy zmieniać ich na standardowe nazwy emblematów bez dowodów z tego serwera.

## Problemy wymagające decyzji

### P1: ręczne ID nie dowodzą istnienia oferty vendorowej

26 pustych ofert pochodzi ze skanowania po ID. Nie ustala ono ani miejsca pozyskania, ani ceny. Nie jest to dowód darmowego zakupu.

Sześć ID miało już źródła: `128858`, `130023`, `130031`, `131004`, `150005`, `46017`. Puste wpisy zastępują łącznie 21 wcześniejszych acquisitions. Stormcoil (`150005`) traci cenę 80 Ascension; Val'anyr (`46017`) traci 14 DROP i ofertę 150 Ascension II. Renderer pustego wpisu zwraca `VENDOR: `.

Rekomendacja: zachować ID i nazwy w pliku obserwacji nieładowanym przez TOC. Nie rejestrować nowych źródeł bez potwierdzenia. Nie usuwać wcześniejszych źródeł dla znanych ID.

### P1: SetAcquisition zastępuje wszystkie metody, nie tylko cenę

112 ofert z cenami Justice/Valor usuwa wcześniejsze drogi pozyskania. Przykład `39728`: drop Faerlina + 25 Valor + 12 Ascension zostają zastąpione wyłącznie 700 Justice. `37111` traci Mal'Ganis i dotychczasową ofertę Heroism.

Przed zmianą danych autor musi określić, czy są to:

1. nowe ceny vendorowe zastępujące stare, z zachowaniem DROP/TOKEN/MARK;
2. dodatkowe oferty obok starych;
3. wyłączne źródła zastępujące również dropy.

Samo przejście na `AddAcquisition` mogłoby zachować nieaktualne ceny, dlatego nie zastosowano go automatycznie.

### P2: tożsamość waluty i pochodzenie danych

Currency itemID i lokalizacja vendora są tylko w komentarzach. Runtime operuje nazwami Justice/Valor; nie ma tutaj rejestru walut. Nowe wywołania nie przekazują identyfikatora wtyczki `P`, co pogarsza diagnostykę konfliktów. Skaner nie ustala też sam relacji pomiędzy różnymi ID przedmiotów legendarnych ani ich hierarchii BiS.

## Weryfikacja

Pełny lokalny plik ładuje się z naprawionym core. Powtarzane replaye zachowują obecne zastąpienia; core nie przywraca usuniętych źródeł i nie powinien zmieniać znaczenia SetAcquisition. Integracja obejmuje trzy bazy i obie frakcje. Wykonanie lokalne: Fengari plus parser składni Lua 5.1, nie klient gry.

## Zrealizowane po decyzji autora

- Autor wybrał zastępowanie wcześniejszych cen vendorowych z zachowaniem dropów/tokenów. Lokalny helper `ReplaceVendorAcquisitions` zachowuje wszystkie metody inne niż VENDOR i rejestruje 112 nowych cen z atrybucją `P`. Kontrakt core SetAcquisition pozostaje bez zmian.
- Autor wyjaśnił, że ręczne ID służą przyszłej aktualizacji BiS, i zaktualizował adnotacje o klasach/fazach/ilvl. Najnowszy blok zawiera 23 ID (pierwotny eksport miał 26). Zachowano wszystkie aktualne linie i adnotacje w tym samym pliku jako nieaktywne komentarze `PLANNED`; nie wdrażano nowych ranków.
- Test `import_policy.lua` sprawdza wszystkie 112 ofert, zachowanie nievendorowych źródeł i cen legendarek, brak pustych ofert oraz cztery powtórzenia replay. Stormcoil nadal ma 80 Ascension, Val'anyr zachowuje 14 DROP.
- Integracja z trzema bazami i obiema frakcjami pozostaje osobnym testem core. Native Lua 5.1 i klient gry nadal wymagają uruchomienia przed wydaniem.

Wniosek: destrukcyjne zastąpienia zostały ograniczone do uzgodnionych cen vendorowych; przyszłe rankingi i tożsamość/lokalizacja walut nadal są osobnym zakresem. Nazw Justice/Valor i kwot dostarczonych przez autora nie zmieniano.
