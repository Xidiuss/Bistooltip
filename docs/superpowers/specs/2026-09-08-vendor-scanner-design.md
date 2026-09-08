# Vendor Scanner — Design (FROZEN)

Status: **DESIGN FROZEN** — oczekuje na review przed planem implementacji.
Data: 2026-09-08. Klasyfikacja: architectural.
Relacja: realizuje frozen S4-3 z `2026-09-07-metabistooltip-data-design.md`
("skaner generuje dokładnie API S3, bez importera w core").

## 0. Cel i kontekst

`EmblemData.lua` to dziś ręcznie utrzymywane tabele
`Bistooltip_emblem_items[itemID] = {currency, cost}`. Na prywatnych
serwerach koszty i waluty (custom emblemy/tokeny, np. ID 131008+) różnią
się od Standardu i trzeba je zebrać w grze.

Cel: standalone mini-addon `Bistooltip_Scanner` (wtyczka, nie część core),
który przy otwartym vendorze zbiera **ID przedmiotu, nazwę, koszt, walutę**
i generuje gotowy snippet wtyczki serwerowej w API S3. Dane służą do
tworzenia lekkich wtyczek per serwer (`Bistooltip_MojSerwer`).

Decyzje użytkownika (zebrane w brainstormingu):
- Zakres: wszystkie towary (gold + extended cost + waluty).
- Format: snippet API S3 do wklejenia do wtyczki serwera.
- Uruchomienie: przycisk na MerchantFrame + slash command.
- Odbiór: okno z polem do kopiowania (Ctrl+C) + zapis w SavedVariables.

## 1. Architektura i komponenty — FROZEN

- Nowy folder `Bistooltip_Scanner/` obok `Bistooltip/`:
  `Bistooltip_Scanner.toc` (Interface 30300,
  `SavedVariables: BistooltipScannerDB`,
  `OptionalDeps: Bistooltip` — działa solo u zbieracza danych),
  `Scanner.lua` (odczyt + zapis), `Export.lua` (snippet + okno).
- Zero zapisów do tabel core. Skaner tylko czyta merchant API
  i produkuje tekst + własne SV. Brak importera w core.
- Trigger: przycisk na `MerchantFrame` + `/bis scan` (rescan),
  działa tylko przy otwartym vendorze.
- Model w SV per vendor: klucz `"VendorName @ Zone"` →
  `{ vendor, zone, date, items[itemID] =
  { name, money (copper), costs = {{currID, currName, amount}},
  qty, limited } }`.
- Odczyt WotLK 3.3.5a: pętla `1..GetMerchantNumItems()`, na indeks:
  `GetMerchantItemInfo` (name, price, qty, numAvailable, extendedCost)
  + `GetMerchantItemLink` → itemID z `item:(%d+)` + jeśli extendedCost
  to `GetMerchantItemCostInfo` / `GetMerchantItemCostItem` → waluty
  (ID + amount + nazwa jeśli w cache). Bez przełączania stron
  (API indeksuje całość, nie stronę).

## 2. Przepływ danych i format snippeta — FROZEN

- `MERCHANT_SHOW` → aktywuj przycisk + hint na chacie. Klik/`/bis scan`
  → loop po indeksach → wpis do `BistooltipScannerDB[vendorKey]`
  (nadpisanie tego vendora, nie merge między vendorami) → print
  `Zeskanowano N towarów: Vendor @ Zone` → auto-otwarcie okna eksportu.
- Brak linku w cache (`GetMerchantItemLink == nil`) lub brak nazwy
  waluty → wpis z `name = "?"`, ostrzeżenie
  `brak w cache, przeskanuj ponownie`, eksport oznacza `-- UNCACHED`.
- Eksport (snippet API S3): nagłówek
  `-- vendor/zone/date/count by Bistooltip_Scanner`, potem per item
  jedna linia:
  `BisTooltip:SetAcquisition(ID, { { kind="VENDOR",
  cost={ {currency="Gold", amount=Cu},
  {currency="Nazwa", amount=n} -- item:CurrID } } }) -- NazwaItemu`.
  Gold tylko gdy `money > 0`. Dla sklepów donate: checkbox "custom"
  zamienia blok na `DefineSource("CUSTOM_<VENDOR>",
  { kind="CUSTOM", label="Vendor (Zone)" })` +
  `SetAcquisition(..., kind="CUSTOM", label=...)` — domyślnie
  odznaczony (VENDOR).
- Okno: `Frame + ScrollFrame + EditBox` (zaznacz-wszystko, Ctrl+C),
  przyciski Skanuj / Kopiuj / Zamknij. Pełny tekst też w SV
  (odczyt z pliku WTF po wylogowaniu).

## 3. Błędy i edge cases — FROZEN

- Vendor zamknięty w trakcie skanu / `GetMerchantNumItems() == 0` →
  komunikat, brak zapisu, brak okna.
- Item bez linku lub waluta bez nazwy (cache) → zapis z `UNCACHED`,
  eksport z komentarzem, rescan naprawia bez duplikatów (klucz: itemID).
- Stacki (`quantity > 1`) i limitowane (`numAvailable >= 0`) → tylko
  komentarz w snippecie (`-- x5, limited:3`), bez wpływu na koszt.
- Serwery ze zmienionym API (brak `GetMerchantItemCostItem`) → guard
  `if API == nil`, fallback: sam gold + komentarz `-- no cost API`,
  skaner nigdy nie rzuca błędem Lua w twarz gracza.
- Duży vendor (100+ pozycji) → jeden print zbiorczy, nie spam per item;
  okno eksportu pokazuje limit ~500 linii z notką o pełnym tekście w SV.

## 4. Testy i zakres (poza MVP) — FROZEN

- Manual w grze (3.3.5a): vendor gold-only, vendor emblemowy
  (Triumph/Frost), vendor mieszany + custom token, rescan tego samego
  vendora (brak duplikatów), reload UI (dane w SV całe), kopiowanie z okna.
- Weryfikacja snippeta: wklejenie 5 linii do testowej wtyczki, reload,
  brak błędów Lua, tooltip pokazuje VENDOR.
- Poza MVP (nie budujemy teraz): auto-skan w tle, CSV, migrator offline,
  bezpośredni zapis do `EmblemData`, minimapa/LDB, lokalizacje klienta.

## Self-review speca

- Placeholdery: brak.
- Spójność: standalone (S1) + snippet S3 (S2) + guards (S3) + testy (S4);
  CUSTOM wyłącznie przez jawny toggle, domyślnie VENDOR; brak zapisu
  do core (S4-3); klucz SV per vendor zapobiega mieszaniu danych.
- Zakres: jeden mini-addon, 2 pliki Lua + toc; CSV/migrator/auto-crawler
  poza zakresem.
- Niejednoznaczności: klucz vendora `"Name @ Zone"` techniczny (dowolny,
  byle stabilny); kolejność linii eksportu = kolejność indeksów merchant;
  gold w copper z jawnym `currency="Gold"`.
