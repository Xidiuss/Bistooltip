# Przedmioty rankingowe bez źródła pozyskania

Historyczna migawka danych z core `main` (`9cca07d`, 19 września 2026), **sprzed [importu danych właściciela](NEW-DATA-IMPORT.md)**. Po imporcie w rankingach core pozostało 31 unikalnych ID bez źródła. W tej tabeli brak oznaczał, że dodatni itemID w dostarczonym rankingu nie miał wpisu w `BisTooltip_ItemAcquisition`. To nie znaczy, że przedmiot nie istnieje ani że jest darmowy. Dodatki serwerowe mogą uzupełniać część tych źródeł. Nazw nie zgadujemy z ID; użytkownik powinien podać nazwę i źródło z klienta.

Kody baz: **A** = WoWSimsBP Alliance, **H** = WoWSimsBP Horde, **T** = wowtbc, **W** = Wowhead (`wh`). Gwiazdka przy kodzie oznacza, że ID występuje na rank 1 w tej bazie. Jeden przykład profilu pomaga odnaleźć pozycję; ID może występować także w innych profilach i fazach.

| Baza | ID bez acquisitions | W tym na rank 1 |
| --- | ---: | ---: |
| A | 134 | 18 |
| H | 120 | 17 |
| T | 107 | 22 |
| W | 102 | 10 |

Łącznie unikalnych ID: **193**; na rank 1 w co najmniej jednej bazie: **34**. Zestawienia baz nakładają się.

## Pełna lista

Najpierw ID z rank 1, potem pozostałe. Dla każdego potrzebne są: nazwa, metoda pozyskania, serwer lub stock, lokacja/NPC albo boss i trudność, pełny koszt z itemID walut oraz potwierdzenie, czy źródło jest alternatywą czy zastępuje starą cenę. Nie przesyłaj pustego `SetAcquisition` jako potwierdzenia darmowego zakupu.

| itemID | Bazy (`*` = rank 1) | Przykładowy profil / slot |
| ---: | --- | --- |
| 24116 | W* | Priest / Discipline / T7 / Neck (rank 1) |
| 34180 | A, H, T* | Warrior / Fury / PR / Legs (rank 1) |
| 34181 | A*, H*, T* | Mage / Arcane / PR / Legs (rank 1) |
| 34209 | A, H, T* | Druid / Restoration / PR / Shoulder (rank 1) |
| 34210 | A*, H*, T* | Druid / Balance / PR / Shoulder (rank 1) |
| 34213 | A, H, T*, W | Warrior / Protection / PR / Finger (rank 1) |
| 34241 | A*, H*, T | Rogue / Combat / PR / Back (rank 1) |
| 34332 | A, H, T* | Shaman / Restoration / PR / Head (rank 1) |
| 34340 | A*, H*, T* | Mage / Fire FFB / PR / Head (rank 1) |
| 34348 | A*, H*, T*, W | Warlock / Affliction / PR / Ranged (rank 1) |
| 34386 | A, H, T* | Warlock / Affliction / PR / Legs (rank 1) |
| 34388 | A*, H*, T*, W | Death knight / Frost / PR / Shoulder (rank 1) |
| 34389 | A, H, T* | Warrior / Protection / PR / Shoulder (rank 1) |
| 34392 | A, H, T* | Warrior / Arms / PR / Shoulder (rank 1) |
| 37574 | A*, H*, T*, W | Paladin / Retribution / PR / Relic (rank 1) |
| 40585 | A*, H*, T*, W | Druid / Balance / PR / Finger (rank 1) |
| 40586 | A*, H*, T*, W | Druid / Feral dps / PR / Finger (rank 1) |
| 41678 | A*, H*, W* | Druid / Feral tank / T8 / Head (rank 1) |
| 42339 | A*, H* | Druid / Restoration / PR / Neck (rank 1) |
| 42391 | W* | Druid / Feral tank / PR / Weapon (rank 1) |
| 42608 | A, H, T*, W* | Shaman / Enhancement / T8 / Relic (rank 1) |
| 42853 | A*, H*, T*, W* | Paladin / Retribution / T8 / Relic (rank 1) |
| 42988 | A, H, T*, W | Priest / Discipline / PR / Trinket (rank 1) |
| 43251 | A, H, T* | Shaman / Enhancement / PR / Finger (rank 1) |
| 43253 | A*, H*, T*, W | Mage / Fire / PR / Finger (rank 1) |
| 43792 | A*, H* | Priest / Shadow / PR / Chest (rank 1) |
| 44063 | A*, H*, T, W* | Death knight / Blood tank / T7 / Trinket (rank 1) |
| 44210 | A*, H*, T*, W | Priest / Discipline / PR / Off hand (rank 1) |
| 44935 | A, H, T*, W | Death knight / Frost / PR / Finger (rank 1) |
| 47686 | A, T, W* | Paladin / Holy / PR / Head (rank 1) |
| 47697 | A, T, W* | Paladin / Retribution / PR / Shoulder (rank 1) |
| 47698 | A*, T, W | Death knight / Blood tank / T9 / Shoulder (rank 1) |
| 47708 | A, T, W* | Rogue / Combat / PR / Shoulder (rank 1) |
| 51432 | A*, H*, W* | Druid / Feral tank / T10 / Weapon (rank 1) |
| 24121 | W | Priest / Discipline / PR / Neck (rank 3) |
| 25643 | A, H, T, W | Druid / Restoration / PR / Relic (rank 2) |
| 27484 | W | Paladin / Retribution / T7 / Relic (rank 6) |
| 27518 | W | Druid / Balance / PR / Relic (rank 5) |
| 28523 | A, H, T | Shaman / Restoration / PR / Relic (rank 3) |
| 28795 | A, H | Death knight / Unholy / PR / Wrist (rank 5) |
| 28823 | A, H, T, W | Paladin / Holy / PR / Trinket (rank 3) |
| 30032 | A, H, T | Death knight / Unholy / PR / Waist (rank 5) |
| 30063 | A, H, T | Paladin / Holy / PR / Relic (rank 2) |
| 30872 | A, H, T | Mage / Fire / PR / Off hand (rank 4) |
| 32235 | A, H, T | Rogue / Assassination / PR / Head (rank 4) |
| 32330 | W | Shaman / Elemental / PR / Relic (rank 4) |
| 32345 | A, H, T | Death knight / Frost / PR / Feet (rank 6) |
| 32373 | A, H, T | Death knight / Frost / PR / Head (rank 4) |
| 32387 | A, H, T, W | Druid / Balance / PR / Relic (rank 2) |
| 32483 | A, H, T | Druid / Balance / PR / Trinket (rank 5) |
| 32837 | A, H, T | Rogue / Combat / PR / Weapon (rank 3) |
| 32838 | A, H, T | Rogue / Combat / PR / Off hand (rank 4) |
| 33281 | A, H | Druid / Restoration / PR / Neck (rank 4) |
| 34186 | A, H, T | Shaman / Elemental / PR / Legs (rank 2) |
| 34188 | A, H, T | Druid / Feral dps / PR / Legs (rank 3) |
| 34195 | A, H, T | Rogue / Assassination / PR / Shoulder (rank 4) |
| 34202 | A, H, T | Priest / Discipline / PR / Shoulder (rank 5) |
| 34204 | A, H | Mage / Frost / PR / Neck (rank 6) |
| 34211 | A, H, T | Druid / Feral tank / PR / Chest (rank 4) |
| 34215 | A, H, T, W | Death knight / Unholy / PR / Chest (rank 2) |
| 34233 | A, H, T | Priest / Holy / PR / Chest (rank 6) |
| 34240 | A, H, T | Paladin / Holy / PR / Hands (rank 6) |
| 34242 | A, H, T | Druid / Balance / PR / Back (rank 5) |
| 34243 | A, H | Paladin / Holy / PR / Head (rank 6) |
| 34244 | A, H, T | Druid / Feral dps / PR / Head (rank 3) |
| 34333 | A, H, T, W | Hunter / Beast mastery / PR / Head (rank 4) |
| 34334 | A, H | Hunter / Beast mastery / PR / Ranged (rank 3) |
| 34335 | A, H | Paladin / Holy / PR / Weapon (rank 6) |
| 34339 | A, H, T | Druid / Restoration / PR / Head (rank 2) |
| 34341 | A, H, T | Death knight / Frost / PR / Hands (rank 4) |
| 34342 | A, H, T | Druid / Restoration / PR / Hands (rank 3) |
| 34343 | A, H | Hunter / Beast mastery / PR / Hands (rank 5) |
| 34344 | A, H, T | Druid / Balance / PR / Hands (rank 2) |
| 34346 | A, H, T | Shaman / Enhancement / PR / Off hand (rank 4) |
| 34347 | A, H, T | Mage / Arcane / PR / Ranged (rank 3) |
| 34350 | A, H, T | Shaman / Elemental / PR / Hands (rank 6) |
| 34352 | A, H | Death knight / Blood tank / PR / Hands (rank 6) |
| 34370 | A, H, T, W | Druid / Feral dps / PR / Hands (rank 3) |
| 34378 | A, H, T | Death knight / Unholy / PR / Hands (rank 2) |
| 34381 | A, H, T | Death knight / Blood tank / PR / Legs (rank 4) |
| 34385 | A, H | Druid / Feral tank / PR / Legs (rank 6) |
| 34390 | A, H, T | Paladin / Holy / PR / Shoulder (rank 3) |
| 34394 | A, H, T | Death knight / Blood tank / PR / Chest (rank 5) |
| 34396 | A, H, T | Shaman / Elemental / PR / Chest (rank 4) |
| 34397 | A, H, T | Death knight / Frost / PR / Chest (rank 2) |
| 34398 | A, H, T | Druid / Restoration / PR / Chest (rank 4) |
| 34399 | A, H, T | Druid / Balance / PR / Chest (rank 4) |
| 34400 | A, H | Death knight / Blood tank / PR / Head (rank 6) |
| 34401 | A, H, T | Warrior / Protection / PR / Head (rank 4) |
| 34404 | A, H, T | Druid / Feral dps / PR / Head (rank 4) |
| 34406 | A, H, T | Mage / Arcane / PR / Hands (rank 5) |
| 34408 | A, H | Druid / Feral tank / PR / Hands (rank 6) |
| 34427 | A, H, T, W | Druid / Feral dps / PR / Trinket (rank 6) |
| 37371 | A, H | Druid / Restoration / PR / Finger (rank 6) |
| 37575 | W | Shaman / Enhancement / PR / Relic (rank 5) |
| 37761 | A, H | Druid / Restoration / PR / Waist (rank 5) |
| 38206 | A, H, T | Mage / Arcane / PR / Ranged (rank 3) |
| 38295 | W | Druid / Feral dps / PR / Relic (rank 4) |
| 39653 | A, H | Paladin / Holy / PR / Neck (rank 6) |
| 39655 | A, H | Death knight / Blood tank / PR / Neck (rank 5) |
| 40490 | A, H, T | Shaman / Enhancement / PR / Wrist (rank 5) |
| 40767 | A, H, T, W | Death knight / Blood tank / PR / Trinket (rank 6) |
| 41661 | W | Druid / Feral tank / T8 / Chest (rank 3) |
| 41677 | W | Druid / Feral tank / PR / Head (rank 4) |
| 41714 | W | Druid / Feral tank / PR / Shoulder (rank 3) |
| 41715 | W | Druid / Feral tank / T8 / Shoulder (rank 2) |
| 42341 | A, H, T, W | Death knight / Blood tank / PR / Trinket (rank 4) |
| 42392 | W | Druid / Feral tank / T9 / Weapon (rank 6) |
| 42395 | A, H, T, W | Druid / Balance / PR / Trinket (rank 3) |
| 42413 | A, H, T, W | Paladin / Holy / PR / Trinket (rank 4) |
| 42418 | W | Paladin / Retribution / T7 / Trinket (rank 6) |
| 42621 | W | Death knight / Unholy / PR / Relic (rank 6) |
| 42842 | A, H, T | Mage / Fire FFB / PR / Shoulder (rank 5) |
| 42851 | W | Paladin / Retribution / PR / Relic (rank 3) |
| 42854 | W | Paladin / Retribution / T10 / Relic (rank 3) |
| 42990 | A, H, T, W | Hunter / Beast mastery / PR / Trinket (rank 6) |
| 43186 | A, H | Priest / Holy / PR / Ranged (rank 6) |
| 43198 | A, H, T | Death knight / Frost / PR / Shoulder (rank 3) |
| 43213 | A, H, T | Warrior / Protection / PR / Hands (rank 5) |
| 43573 | A, H, T | Death knight / Frost / PR / Trinket (rank 6) |
| 43940 | A, H | Death knight / Frost / PR / Legs (rank 6) |
| 43944 | A, H, T | Death knight / Frost / PR / Wrist (rank 4) |
| 44017 | A, H | Druid / Balance / PR / Neck (rank 5) |
| 44024 | A, H, T | Druid / Feral dps / PR / Feet (rank 6) |
| 44032 | A, H, T | Paladin / Holy / PR / Off hand (rank 4) |
| 44033 | A, H | Druid / Feral dps / PR / Neck (rank 5) |
| 44322 | A, H, T, W | Druid / Restoration / PR / Trinket (rank 3) |
| 44323 | A, H, T | Death knight / Blood tank / PR / Trinket (rank 5) |
| 44341 | A, H | Death knight / Blood tank / PR / Wrist (rank 6) |
| 44370 | A, H, T | Druid / Restoration / PR / Shoulder (rank 6) |
| 44372 | A, H, T | Hunter / Beast mastery / PR / Shoulder (rank 5) |
| 44373 | A, H, T | Paladin / Protection / PR / Shoulder (rank 4) |
| 44397 | A, H, T | Druid / Feral dps / PR / Hands (rank 6) |
| 44399 | A, H, T | Death knight / Frost / PR / Hands (rank 5) |
| 44405 | A, H | Druid / Feral tank / PR / Chest (rank 6) |
| 44407 | A, H, T | Paladin / Protection / PR / Chest (rank 5) |
| 44735 | A, H | Paladin / Protection / PR / Weapon (rank 6) |
| 44934 | A, H, T, W | Druid / Restoration / PR / Finger (rank 4) |
| 45689 | W | Druid / Restoration / T8 / Finger (rank 6) |
| 45691 | W | Mage / Arcane / T8 / Finger (rank 6) |
| 45813 | A, H | Shaman / Restoration / PR / Neck (rank 5) |
| 45859 | A, H, T | Death knight / Frost / PR / Finger (rank 5) |
| 45949 | W | Druid / Feral dps / T8 / Weapon (rank 4) |
| 45950 | W | Death knight / Blood tank / T7 / Weapon 2h (rank 5) |
| 45952 | W | Druid / Feral tank / T8 / Weapon (rank 2) |
| 45953 | W | Druid / Restoration / T8 / Weapon 2h (rank 4) |
| 45957 | W | Death knight / Frost / T8 / Off hand (rank 3) |
| 45959 | W | Paladin / Protection / T8 / Weapon (rank 4) |
| 45960 | W | Death knight / Blood tank / T8 / Weapon 1h (rank 3) |
| 45962 | W | Rogue / Combat / T8 / Off hand (rank 6) |
| 45966 | W | Death knight / Unholy / T8 / Off hand (rank 5) |
| 45969 | W | Rogue / Combat / T8 / Weapon (rank 6) |
| 45970 | W | Mage / Arcane / T8 / Weapon (rank 4) |
| 45971 | W | Druid / Restoration / T8 / Weapon 1h (rank 4) |
| 47674 | A, T, W | Death knight / Frost / T9 / Head (rank 4) |
| 47677 | A, T, W | Death knight / Blood tank / T9 / Head (rank 4) |
| 47689 | A, T, W | Druid / Feral dps / RS / Head (rank 5) |
| 47690 | A, T, W | Druid / Restoration / RS / Head (rank 6) |
| 47693 | A, T, W | Druid / Balance / T9 / Head (rank 3) |
| 47694 | A, T, W | Priest / Discipline / T9 / Head (rank 5) |
| 47702 | A, T, W | Paladin / Holy / T9 / Shoulder (rank 3) |
| 47704 | A, T | Hunter / Beast mastery / T9 / Shoulder (rank 6) |
| 47713 | A, T, W | Druid / Balance / RS / Shoulder (rank 5) |
| 47715 | A, T, W | Druid / Restoration / T9 / Shoulder (rank 4) |
| 48406 | W | Death knight / Blood tank / PR / Weapon 2h (rank 3) |
| 48408 | W | Priest / Discipline / T9 / Weapon (rank 2) |
| 48410 | W | Warlock / Destruction / T9 / Weapon 2h (rank 3) |
| 48412 | W | Warlock / Demonology / T9 / Weapon 2h (rank 2) |
| 48414 | W | Warlock / Affliction / T9 / Weapon 2h (rank 3) |
| 48507 | W | Rogue / Combat / T9 / Weapon (rank 6) |
| 48511 | W | Paladin / Protection / T9 / Weapon (rank 5) |
| 48513 | W | Death knight / Frost / T9 / Off hand (rank 3) |
| 48519 | W | Paladin / Holy / T9 / Weapon (rank 6) |
| 48523 | W | Druid / Feral tank / T10 / Weapon (rank 5) |
| 48957 | W | Priest / Shadow / T9 / Finger (rank 6) |
| 49076 | W | Mage / Arcane / T7 / Trinket (rank 5) |
| 49118 | W | Druid / Feral tank / PR / Trinket (rank 2) |
| 49123 | W | Mage / Arcane / PR / Finger (rank 5) |
| 49126 | W | Paladin / Retribution / PR / Head (rank 5) |
| 49187 | W | Druid / Restoration / T9 / Off hand (rank 2) |
| 49191 | W | Priest / Holy / T9 / Weapon (rank 3) |
| 49888 | A, H, T, W | Death knight / Blood dps / T10 / Weapon (rank 5) |
| 51393 | W | Death knight / Blood tank / T10 / Weapon 2h (rank 3) |
| 51398 | W | Druid / Restoration / T10 / Weapon 1h (rank 5) |
| 51399 | W | Warlock / Demonology / T10 / Weapon 1h (rank 5) |
| 51401 | W | Warlock / Destruction / T10 / Weapon 2h (rank 6) |
| 51403 | W | Warlock / Demonology / T10 / Weapon 2h (rank 5) |
| 51405 | W | Warlock / Destruction / T10 / Weapon 2h (rank 5) |
| 51407 | W | Druid / Restoration / T10 / Off hand (rank 5) |
| 51425 | W | Druid / Feral tank / T10 / Chest (rank 4) |
| 51427 | W | Druid / Feral tank / T10 / Head (rank 4) |
| 51431 | W | Druid / Feral tank / T10 / Weapon (rank 3) |
| 51520 | W | Paladin / Protection / T10 / Weapon (rank 3) |
