# REJESTR PRAC DANYCH — Bistooltip META-Z

Właściciel danych: **owner** (praca wsadowa, wg własnego tempa).
Agent: tylko kod (workstreamy [A] na końcu) — na wyraźne „go".
Uzgodnione 2026-09-08: duże zbiory danych obrabia owner, bo zużywają
najwięcej tokenów; ten rejestr jest pojedynczym źródłem prawdy o tym,
co pozostało w danych.

## Środowisko i workflow (zawsze te same komendy)

```bash
# 1) Oracle (GPLv2 — NIGDY commitowany; pobierz na nowo przy refreshie)
curl -sL "https://raw.githubusercontent.com/wonderkidsem-official/Pazzions-WotLK-BiS-List-AtlasLoot-Enhanced-v5.11.04/main/AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua" -o /tmp/oracle_wotlk.lua

# 2) Ekstrakcja faktów (klucze/tokeny/marki/tribute/VOA → /tmp + stdout)
wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && cp /mnt/c/Users/Komputer/AppData/Local/Temp/oracle_wotlk.lua /tmp/ 2>/dev/null; lua5.1 tools/oracle_dump.lua"

# 3) Regeneracja danych + pełny audyt (po każdej zmianie w tier_matrix/inputach)
wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && lua5.1 tools/migrate_sources.lua && lua5.1 tools/check_sources.lua"

# 4) Pełny gate (składnia + testy + census)
wsl -e bash -c "cd '/mnt/j/projekty z/Bistooltip-main/.worktrees/META-Z' && for f in Bistooltip/*.lua tools/*.lua; do luac5.1 -p \"\$f\" || exit 1; done && lua5.1 tools/test_formatter.lua && lua5.1 tools/test_pluginapi.lua && lua5.1 tools/census_bis.lua"
```

Struktura danych, którą edytujesz:
- `tools/tier_matrix.lua` — commitowane FAKTY (bossy marek, marki, klasa→rodzina,
  questy). Tu dopisujesz nowe relacje z oracle.
- `Bistooltip/Loot_Sources.lua` — input stref/bossów (format:
  `["Strefa (10/25)"] = { ["Boss"] = {itemIDy} }`). VOA na końcu pliku jest
  wygenerowany z oracle (blok oznaczony komentarzem).
- `tools/migrate_sources.lua` — słowniki CANON_ZONE / BOSS_ALIASES /
  ZONE_DIFFICULTY + gałęzie specjalne (TROPHY, Tier 10N/HC→MARK).
- `tools/check_sources.lua` — audyty; po dodaniu nowego rodzaju danych
  dorzuć asercję (wzór: audyt MARK ~linia 95+).

Konwencje zamrożone (nie zmieniać): closed set trudności
`"" HC 10N 25N 10HC 25HC 10HM 25HM`; Ulduar tylko N/HM; MASTER formaty
(`Instance [Diff] - Boss`, `TIER - TOKEN/MARK: Family [Instance: Boss <Diff>]`,
`TIER - VENDOR: koszt`, `T9 - TROPHY: Crusade + koszt`); brak dedupu
realnych bossów; rodziny krótkie (Lost/Wayward/Grand Protector/…).

---

## Pozycje rejestru

### D1 — T7/T8 TOKEN per-boss (NAJWIĘKSZA POZYCJA, właściciel)
**Cel:** tokeny i gear T7/T8 w formacie
`T8 - TOKEN: Wayward Protector [Ulduar: <Boss> <25N>]` — po jednej linii
na realnego bossa, z dopasowaniem SLOTU (girdle≠token: patrz Uwagi).

**Fakty już wyekstrahowane** (patrz `/tmp/matrix_facts.txt` po kroku 2):
- T7 „of the Lost X": Gluth (9 wierszy = 3 sloty × 3 rodziny), Thaddius,
  Loatheb, Kel'Thuzad, Four Horsemen, Sartharion — każdy × {10, 25Man}.
- T8 „of the Wayward X": Yogg-Saron, Thorim, Mimiron, Hodir, Freya
  (× {10, 25Man}) + Emalon 25 (w VOA już uwzględniony jako DROP).
- Vendor pages (EmblemofValor2/Heroism3) — tokeny kupowalne za emblemy:
  pomiń w macierzy DROP, jeśli chcesz, dodaj osobno jako VENDOR (zdecyduj).

**Do zrobienia:**
1. `tools/tier_matrix.lua`: dopisz `TOKEN_DROPS` — dla każdego tokenu:
   `{ slot, tier, family, sources = { {instance, boss, diff}, … } }`.
   Slot i rodzinę bierzesz z NAZWY tokenu (Crown/Spaulders/Breastplate/
   Gauntlets/Gloves/Legplates/Leggings → head/shoulder/chest/hands/legs;
   Lost→T7, Wayward→T8; Protector/Conqueror/Vanquisher z nazwy).
2. Gear T7/T8 (np. Valorous/Heroes'/*): dopisz TOKEN entries WYŁĄCZNIE
   tam, gdzie slot gearu = slot tokenu. Slot gearu z deskryptora oracle
   (`#s1#` head, `#s3#` shoulder, `#s5#` chest, `#s9#` hands, `#s11#` legs)
   albo z kontekstu bislisty. Rodzina gearu = klasa → `CLASS_FAMILY`.
3. Migrator: gałąź dla stref `Tier 7/8 Tokens <raid>(<size>)` — zamień
   obecne DROP+tier na `kind="TOKEN"` z family z nazwy tokenu; gear przez
   nową gałąź analogiczną do Tier 10N/HC (MARK) — wzorzec w migratorze,
   sekcja „Tier 10N/10HC sanctified gear".
4. Checker: audyt TOKEN jak MARK (rodziny, render, ICC→odpowiednik
   instancji, coverage ≥ oczekiwana).
**Akceptacja:** krok 3+4 zielony; przykładowy render:
`T7 - TOKEN: Lost Protector [Naxxramas: Gluth <25N>]`.

**Uwagi/pułapki:** „Girdle of the Dauntless Conqueror" (47563, ToC5) to
PAS, nie token (rodzina Dauntless) — nie łapać wzorcem rodziny bez słowa
Lost/Wayward/Grand. Ulduar 10/25 hard-mody: tokeny leżą na stronach N
(bossowych) — nie dublować z HM.

### D2 — T9 Regalia z Tribute Chest (właściciel, mała)
`47557/47558/47559` (Regalia of the Grand Conqueror/Protector/Vanquisher)
— chest-tokeny T9-258 z skrzynki po Anub'araku (25HC; strony oracle
`TrialoftheCrusaderTribute25ManHEROIC_A/_H` — scal A+H).
Tokeny jako `kind="TOKEN", tier="T9"`, boss=`Tribute Chest`, diff=25HC;
gear T9-258 (strefy „Tier 9.5 <Klasa> ToC(25HC)") — tylko slot chest.
Zdecydować/zaakceptować etykietę bossa „Tribute Chest" (render:
`T9 - TOKEN: Grand Protector [Trial of the Crusader: Tribute Chest <25HC>]`).

### D3 — Kolejne itemy `[Quest]` (właściciel, przy okazji gry)
Reguła działa (wzór: 45614 → `Ulduar [25N] - Algalon [Quest]`).
Kandydaci do weryfikacji w grze/w oracle: pozostałe pierścienie Algalona
(10-man quest), inne nagrody questowe przypisane do bossów. Procedura:
dopisz do `tier_matrix.QUEST_DROPS` + usuń item z surowej listy bossów
w Loot_Sources (inaczej pokażą się dwie linie).

### D4 — Refresh oracle / upstreamu (właściciel, okresowo)
Nowa wersja oracle → kroki 1-2 workflow → porównaj fakty
(`/tmp/matrix_facts.txt` vs `tools/tier_matrix.lua`) → uaktualnij
macierz i VOA (stdout kroku 2 podmienia blok VOA w Loot_Sources) →
kroki 3-4. Analogicznie przy refresh bislist z upstream (procedura w
spec v2.4 §4: import → migrator → assembler → census).

### D5 — Weryfikacje in-game (właściciel; po każdej fali danych)
Aktualnie oczekują na potwierdzenie (W2 wave 1):
- [ ] hover T10 sanctified → 5 linii MARK per boss (Saurfang…Lich King)
- [ ] hover item z VOA → `Vault of Archavon [10N/25N] - <Watcher>`
- [ ] 45614 → `Ulduar [25N] - Algalon [Quest]`
- [ ] brak regresji: checklisty, tryb VENDOR, tooltipy HC/HM
Po potwierdzeniu dopisz `Tested-In-Game: yes` w trailerze ostatniego
commitu danych (amend) albo odnotuj w tym rejestrze.

### D6 — Skan Whitemane (właściciel; po zbudowaniu skanera [A-W7])
- Vendorzy Ascension/II/Echo → nazwy/lokacje pod `label` w DefineSource
- Waluty cata-like (valor/justice) — skan NPC
- Weryfikacja: czy serwerowe HC/HM dodają drop (jeśli tak → nowe source)
- Artifact z 27 nadpisaniami legendarnych:
  `docs/superpowers/data/whitemane-custom-extract-2026-09-08.lua`

---

## [A] Workstreamy kodowe (agent — nie częścią batcha ownera)

| # | Zakres | Spec |
|---|---|---|
| W3 | FormatSourceColored + paleta + wpięcie tooltip/checklist | §3 |
| W4 | DB registry (3 bazy) + overlay replay + SetBiSSlotRank + db.global + `tools/assemble_wowsims.lua` (baza alliance + horde_overrides) | §4, §12 |
| W6 | Scaffold wtyczki `Bistooltip_Whitemane_Frostmourne` + czyszczenie EmblemData/wowtbc (po skanach D6) | §7 |
| W7 | `Bistooltip_Scanner` (frozen plan) + `/bis item` | §8 |
| W8 | `tools/run_all` + CI (GitHub Actions) + final audit | §10 |

## Historia rejestru

- 2026-09-08: rejestr utworzony; D1-D6 zdefiniowane; W2 wave 1 (VOA,
  T10 MARK, quest 45614) wykonane przez agenta (commit 86da3ac);
  `tools/oracle_dump.lua` commitowany jako narzędzie ownera.
