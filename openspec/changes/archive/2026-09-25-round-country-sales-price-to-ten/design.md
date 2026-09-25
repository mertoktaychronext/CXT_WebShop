## Context

`CreateCountryLine` (lokale Prozedur auf Page 60322 "CXW Sales Price Checking List") legt pro aktiviertem Land eine Prüfzeile an. Bei gleicher Währung werden `"CXW Stock Price"`, `"CXW Recom. Retail Price"` und `"CXW Strike Price"` 1:1 übernommen, bei Fremdwährung mit `1 / g_decExchangeRateAmt` umgerechnet — ohne jede Rundung. Die Anforderung "immer auf den nächsten vollen 10er" ist mehrdeutig (kaufmännisch vs. aufrunden); "immer … nächsten" wird hier als **Aufrunden** interpretiert.

## Goals / Non-Goals

**Goals:**
- Die drei Preisfelder jeder erzeugten Länderzeile sind Vielfache von 10, immer aufgerundet.
- Gleiche Rundung in beiden Zweigen (gleiche Währung / Fremdwährung).

**Non-Goals:**
- Keine Rundung der Quellzeilen (CSV-Import), keine Änderung von `fnCalcNonStockPrice`, Validierung oder Export.
- Keine Einrichtungsoption (Rundungspräzision/-richtung konfigurierbar) — fest 10, aufrunden.
- Keine nachträgliche Rundung bereits erzeugter Zeilen.

## Decisions

- **AL-Standardfunktion `Round(Wert, 10, '>')`**: rundet auf das nächste Vielfache von 10 nach oben; glatte 10er und `0` bleiben unverändert. Alternative `'='` (kaufmännisch) verworfen, da "immer auf den nächsten" Aufrunden meint.
- **Kleine lokale Hilfsfunktion** `RoundUpToTen(p_decAmount: Decimal): Decimal` auf der Page, statt `Round(…, 10, '>')` sechsmal zu wiederholen. Präzision/Richtung liegen damit an einer Stelle.
- **Rundung nach der Umrechnung**, nicht auf den Wechselkurs: Nur die Preisfelder werden gerundet; `"CXW Exchange Rate Amount"` bleibt exakt, damit die Umrechnung nachvollziehbar bleibt.
- **Auch der 1:1-Zweig wird gerundet**: "immer" gilt für jede erzeugte Länderzeile; ist der Quellpreis bereits ein glatter 10er, ändert sich nichts.

## Risks / Trade-offs

- [Interpretation "nächster 10er" = aufrunden könnte fachlich anders gemeint sein] → In der Proposal explizit dokumentiert; bei Bedarf nur das Richtungskennzeichen in `RoundUpToTen` ändern.
- [Aufrunden erhöht Preise leicht; Marge/Schwellenwert-Prüfung basiert auf der Quellzeile] → akzeptiert, Abweichung max. < 10 Währungseinheiten.
- [Negative Preise würden Richtung +∞ gerundet] → in der Praxis nicht vorhanden, keine Sonderbehandlung.
