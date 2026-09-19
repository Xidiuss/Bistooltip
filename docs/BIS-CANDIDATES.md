# Kandydaci BiS Whitemane z eksportu skanera

Stan: 20 września 2026. Wszystkie 23 poniższe ID i adnotacje autora są zachowane na końcu `Bistooltip_Whitemane_Frostmourne/main.lua` jako komentarze `PLANNED`. Tabela uwzględnia późniejszy handoff 20 customowych rekordów z `Private/new_data`. Puste `cost = {}` z eksportu ID nie dowodzi darmowej oferty i nie wolno go wykonywać jako `SetAcquisition`.

Po załadowaniu bieżącego core i wtyczki **10 z 23 ID nie ma acquisition**. Dziesięć zgłoszonych metod quest/drop zapisano jako częściowe `ACTIVITY`, bez wymyślonego questa, bossa lub ceny. Handoff odracza siedem upgrade'ów; trzy metody pozostają nieokreślone. Sześć kwot Ascension ma nadal niepotwierdzone ID waluty. Istniejące 27 aktywnych wstawek rang nie są automatycznie zastępowane przez tę tabelę.

| itemID | Przedmiot / cel z notatki autora | Obecne źródła | Co jeszcze ustalić |
| ---: | --- | --- | --- |
| 128858 | Embersoul, feral T8, ilvl 245 | VENDOR + częściowy DROP | Ustalić bossa i ID waluty; wpis rank 1 T8 Feral dps już działa |
| 315010 | Embersoul, feral T9, ilvl 258 | brak | Źródło/cena i rank dla Feral dps/tank |
| 130023 | Atiesh, mage T7–T8, ilvl 232 | VENDOR + częściowy QUEST | Ustalić quest i ID waluty; dotychczasowe ranki obejmują też inne klasy |
| 315003 | Atiesh, mage T9, ilvl 258 | brak | Źródło/cena i lista speców Mage |
| 130025 | Atiesh, priest T7–T8, ilvl 232 | częściowy QUEST | Ustalić quest i ID waluty; Shadow wskazany w handoff, relacja do aktywnego 130023 pozostaje otwarta |
| 315015 | Atiesh, priest T9, ilvl 258 | brak | Źródło/cena i lista speców Priest |
| 130026 | Atiesh, druid T7–T8, ilvl 232 | częściowy QUEST | Ustalić quest i ID waluty; Balance wskazany w handoff, relacja do aktywnego 130023 pozostaje otwarta |
| 315016 | Atiesh, druid T9, ilvl 258 | brak | Źródło/cena i lista speców Druid |
| 131001 | Warglaive of Azzinoth, rogue T8 | częściowy DROP | Ustalić bossa/cenę alternatywnego vendora i przypisanie do Weapon/Off hand |
| 131002 | Warglaive of Azzinoth, rogue T8 | częściowy DROP | Ustalić bossa/cenę alternatywnego vendora i przypisanie do Weapon/Off hand |
| 130031 | Armata Strigoi, warrior/paladin T7–T8 | VENDOR + częściowy QUEST | Ustalić quest i ID waluty, sprawdzić aktywne ranki |
| 315004 | Armata Strigoi, warrior/paladin T9; Fury offhand T10 | brak | Źródło/cena oraz dokładne specy i slot T10 |
| 131004 | Doomhammer, T8 | DROP + VENDOR | Potwierdzić klasy/specy; aktywne ranki Enhancement T8/T9 |
| 315008 | Doomhammer, T9 upgrade | brak | Konflikt: handoff wpisuje Priest/Shadow, wcześniejsza notatka mówi Doomhammer; ustalić właściwą klasę/spec i źródło przed zmianą rankingu |
| 132001 | Sulfuras, Death knight tank T9, 2H | częściowy QUEST | Ustalić quest i cenę dodatkowego vendora, dokładny spec i slot Weapon |
| 132003 | Thunderfury, Paladin Protection T9 | częściowy QUEST | Ustalić quest i cenę dodatkowego vendora, slot Weapon |
| 150005 | Stormcoil, Hunter T7 | VENDOR | Potwierdzić cenę; aktywne ranki Hunter T7 |
| 150090 | Stormcoil, Hunter T8 | brak | Źródło/cena i specy Hunter |
| 315005 | Stormcoil, Hunter T9 | brak | Źródło/cena i specy Hunter |
| 315006 | Nightwing, staff ilvl 258; Mage/Druid/Warlock/Priest | brak | Wybrać fazę i rank wobec Atiesh; notatka `W8` jest niejednoznaczna |
| 46017 | Val'anyr T8 | 14 DROP + VENDOR | Potwierdzić docelowe klasy/specy/slot; zachować istniejące źródła |
| 315009 | Val'anyr T9–T10 | brak | Źródło/cena i dokładne klasy/specy/sloty |
| 217741 | Fury of the Sunwell, shield T10 | częściowy QUEST | Ustalić quest i cenę dodatkowego vendora oraz klasy/specy z Off hand/shield |

## Informacje potrzebne do wdrożenia

Dla każdego ID podaj nazwę z klienta, serwer i realm, metodę pozyskania, NPC/lokację lub bossa/trudność oraz pełny koszt: nazwy i itemID walut, ilości, gold i wymagane tokeny. Jeśli istnieje więcej niż jedna oferta, wypisz każdą osobno i zaznacz, czy nowa cena zastępuje starszą ofertę VENDOR. Dla rankingu podaj dokładny **class / spec / phase / slot / rank** i wskaż, czy item ma wejść na pierwsze miejsce z przesunięciem pozostałych, czy zastąpić określoną pozycję.

Po potwierdzeniu danych wtyczka doda ranki przez `InsertBiSSlotRank` tam, gdzie przedmiot ma wejść na szczyt, i doda lub zaktualizuje acquisition bez usuwania niepowiązanych DROP/TOKEN/MARK. Każdą zmianę trzeba sprawdzić na trzech bazach core, obu frakcjach, po zmianie bazy i po RESET.
