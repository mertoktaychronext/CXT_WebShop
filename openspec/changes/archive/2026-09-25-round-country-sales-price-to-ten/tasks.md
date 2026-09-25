## 1. Implementierung

- [x] 1.1 Lokale Hilfsfunktion `RoundUpToTen(p_decAmount: Decimal): Decimal` in `src/Pages/Pag60322.CXWSalesPriceCheckingList.al` anlegen (`exit(Round(p_decAmount, 10, '>'))`)
- [x] 1.2 In `CreateCountryLine`, Zweig gleiche Währung: `"CXW Stock Price"`, `"CXW Recom. Retail Price"`, `"CXW Strike Price"` über `RoundUpToTen` setzen; Wechselkursfelder unverändert lassen
- [x] 1.3 In `CreateCountryLine`, Zweig Fremdwährung: umgerechnete `"CXW Stock Price"`, `"CXW Recom. Retail Price"`, `"CXW Strike Price"` über `RoundUpToTen` setzen; `"CXW Exchange Rate Amount"` ungerundet lassen
- [x] 1.4 App kompilieren, keine neuen Warnungen

## 2. Test

- [x] 2.1 Manuell prüfen: Quellzeile mit Preis `1.234,01` in MW → Länderzeile gleicher Währung hat `1.240`
- [x] 2.2 Manuell prüfen: Länderzeile in Fremdwährung (z. B. CHF) hat umgerechnete Preise als volle 10er (aufgerundet), `"CXW Exchange Rate Amount"` ungerundet
- [x] 2.3 Manuell prüfen: glatter 10er (`1.230`) bleibt `1.230`, `"CXW Strike Price"` = `0` bleibt `0`

## 3. Dokumentation

- [x] 3.1 `docs/developer-manual-de.md` und `docs/developer-manual-en.md`: Abschnitt "Add all Countries" um die Aufrundung auf volle 10er ergänzen
- [x] 3.2 Funktionsregister (`docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`, `gesamtuebersicht.md`): Beschreibung von `CreateCountryLine` ergänzen und `RoundUpToTen` aufnehmen
