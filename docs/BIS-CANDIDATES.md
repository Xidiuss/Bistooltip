# Kandydaci BiS Whitemane z eksportu skanera

Stan: 19 września 2026. Wszystkie 23 poniższe ID i adnotacje autora są już zachowane na końcu `Bistooltip_Whitemane_Frostmourne/main.lua` jako komentarze `PLANNED`. Tabela pomaga zebrać brakujące dowody; nie jest aktywną listą BiS ani listą ofert. Puste `cost = {}` z eksportu ID nie dowodzi darmowej oferty i nie wolno go wykonywać jako `SetAcquisition`.

Status źródeł odczytano z core `9cca07d` po załadowaniu bieżącej wtyczki Whitemane. **17 z 23 ID nie ma żadnego acquisition**. Sześć pozostałych ma wpisy, ale ich ceny i dostępność na serwerze nadal wymagają potwierdzenia. Istniejące 27 aktywnych wstawek rang nie są automatycznie zastępowane przez tę tabelę.

| itemID | Przedmiot / cel z notatki autora | Obecne źródła | Co jeszcze ustalić |
| ---: | --- | --- | --- |
| 128858 | Embersoul, feral T8, ilvl 245 | VENDOR | Potwierdzić cenę i docelowe spec/slot; wpis rank 1 T8 Feral dps już działa |
| 315010 | Embersoul, feral T9, ilvl 258 | brak | Źródło/cena i rank dla Feral dps/tank |
| 130023 | Atiesh, mage T7–T8, ilvl 232 | VENDOR | Potwierdzić cenę; dotychczasowe ranki obejmują też inne klasy |
| 315003 | Atiesh, mage T9, ilvl 258 | brak | Źródło/cena i lista speców Mage |
| 130025 | Atiesh, priest T7–T8, ilvl 232 | brak | Źródło/cena; Discipline/Holy/Shadow i relacja do aktywnego 130023 u Shadow |
| 315015 | Atiesh, priest T9, ilvl 258 | brak | Źródło/cena i lista speców Priest |
| 130026 | Atiesh, druid T7–T8, ilvl 232 | brak | Źródło/cena; Balance/Restoration i relacja do aktywnego 130023 u Balance |
| 315016 | Atiesh, druid T9, ilvl 258 | brak | Źródło/cena i lista speców Druid |
| 131001 | Warglaive of Azzinoth, rogue T8 | brak | Źródło/cena i przypisanie do Weapon/Off hand |
| 131002 | Warglaive of Azzinoth, rogue T8 | brak | Źródło/cena i przypisanie do Weapon/Off hand |
| 130031 | Armata Strigoi, warrior/paladin T7–T8 | VENDOR | Potwierdzić cenę i obecne aktywne ranki |
| 315004 | Armata Strigoi, warrior/paladin T9; Fury offhand T10 | brak | Źródło/cena oraz dokładne specy i slot T10 |
| 131004 | Doomhammer, T8 | DROP + VENDOR | Potwierdzić klasy/specy; aktywne ranki Enhancement T8/T9 |
| 315008 | Doomhammer, T9 upgrade | brak | Źródło/cena i czy zastępuje 131004 na rank 1 T9 |
| 132001 | Sulfuras, Death knight tank T9, 2H | brak | Źródło/cena, dokładny spec i slot Weapon |
| 132003 | Thunderfury, Paladin Protection T9 | brak | Źródło/cena i slot Weapon |
| 150005 | Stormcoil, Hunter T7 | VENDOR | Potwierdzić cenę; aktywne ranki Hunter T7 |
| 150090 | Stormcoil, Hunter T8 | brak | Źródło/cena i specy Hunter |
| 315005 | Stormcoil, Hunter T9 | brak | Źródło/cena i specy Hunter |
| 315006 | Nightwing, staff ilvl 258; Mage/Druid/Warlock/Priest | brak | Wybrać fazę i rank wobec Atiesh; notatka `W8` jest niejednoznaczna |
| 46017 | Val'anyr T8 | 14 DROP + VENDOR | Potwierdzić docelowe klasy/specy/slot; zachować istniejące źródła |
| 315009 | Val'anyr T9–T10 | brak | Źródło/cena i dokładne klasy/specy/sloty |
| 217741 | Fury of the Sunwell, shield T10 | brak | Źródło/cena i klasy/specy z Off hand/shield |

## Informacje potrzebne do wdrożenia

Dla każdego ID podaj nazwę z klienta, serwer i realm, metodę pozyskania, NPC/lokację lub bossa/trudność oraz pełny koszt: nazwy i itemID walut, ilości, gold i wymagane tokeny. Jeśli istnieje więcej niż jedna oferta, wypisz każdą osobno i zaznacz, czy nowa cena zastępuje starszą ofertę VENDOR. Dla rankingu podaj dokładny **class / spec / phase / slot / rank** i wskaż, czy item ma wejść na pierwsze miejsce z przesunięciem pozostałych, czy zastąpić określoną pozycję.

Po potwierdzeniu danych wtyczka doda ranki przez `InsertBiSSlotRank` tam, gdzie przedmiot ma wejść na szczyt, i doda lub zaktualizuje acquisition bez usuwania niepowiązanych DROP/TOKEN/MARK. Każdą zmianę trzeba sprawdzić na trzech bazach core, obu frakcjach, po zmianie bazy i po RESET.
