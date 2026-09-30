## Why

"Add all Countries" erzeugt für Länder in Fremdwährung Preise mit krummen Beträgen (z. B. `12.345,67 CHF`), die so nicht im Webshop erscheinen sollen. Die Länderpreise sollen immer glatte Beträge sein, damit sie ohne manuelle Nacharbeit exportiert werden können.

## What Changes

- `CreateCountryLine` (Page 60322 "CXW Sales Price Checking List") rundet `"CXW Stock Price"`, `"CXW Recom. Retail Price"` und `"CXW Strike Price"` der erzeugten Länderzeile immer **auf den nächsten vollen 10er auf** (z. B. `1.234,01` → `1.240`; `1.230,00` bleibt `1.230`).
- Die Rundung gilt in beiden Zweigen: bei umgerechneten Preisen (Fremdwährung) und bei 1:1 übernommenen Preisen (gleiche Währung wie die Quellzeile).
- Ein Preis von `0` bleibt `0`.
- `"CXW Exchange Rate Amount"` / `"CXW Exchange Rate Date"` werden nicht gerundet und bleiben unverändert.
- Quellzeilen (CSV-Import) und alle anderen Preisberechnungen (z. B. `fnCalcNonStockPrice`, Validierung) bleiben unverändert.

## Capabilities

### New Capabilities
<!-- keine -->

### Modified Capabilities
- `sales-price-country-copy`: Die Requirement "Zeilenerzeugung pro Land" ändert sich — erzeugte Länderpreise werden auf den nächsten vollen 10er aufgerundet statt 1:1 bzw. ungerundet umgerechnet übernommen.

## Impact

- Code: `src/Pages/Pag60322.CXWSalesPriceCheckingList.al`, Prozedur `CreateCountryLine`.
- Daten: Neu erzeugte Länderzeilen in "CXW Sales Price Checking" und damit Archiv und JSON-Export enthalten gerundete Preise. Bereits erzeugte Zeilen werden nicht nachträglich geändert.
- Doku: `docs/developer-manual-de.md` / `-en.md` und Funktionsregister-Beschreibung von `CreateCountryLine` um die Rundung ergänzen.
- Keine Schema-, API- oder Abhängigkeitsänderungen.
