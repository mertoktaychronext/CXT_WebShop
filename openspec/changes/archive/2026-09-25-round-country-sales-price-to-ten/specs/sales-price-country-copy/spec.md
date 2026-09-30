## MODIFIED Requirements

### Requirement: Zeilenerzeugung pro Land
Wenn die Aktion "Add all Countries" ausgeführt wird, SHALL das System für jede noch nicht verarbeitete Quellzeile (`"CXW Country Code"` leer, `"CXW Countries Processed"` = false) genau eine neue "CXW Sales Price Checking"-Zeile pro Land mit `"CXW Sales Price Activated"` = true erzeugen, mit `"CXW Country Code"` = Code des Landes und `"CXW Currency Code"` = `"CXW Sales Price Currency Code"` des Landes. Das SHALL auch für Länder gelten, deren Währung der Währung der Quellzeile entspricht. Existiert für Artikel/Währung/Land bereits eine Zeile, SHALL keine weitere angelegt werden. Die Aktion "Add all Currencies" SHALL nicht mehr existieren. `"CXW Stock Price"`, `"CXW Recom. Retail Price"` und `"CXW Strike Price"` jeder erzeugten Zeile SHALL immer auf den nächsten vollen 10er aufgerundet werden; bereits glatte 10er-Beträge und `0` SHALL unverändert bleiben. `"CXW Exchange Rate Amount"` und `"CXW Exchange Rate Date"` SHALL nicht gerundet werden.

#### Scenario: Mehrere Länder teilen sich eine Währung
- **WHEN** "Add all Countries" läuft und DE, AT und FR aktiviert sind, jeweils mit leerem `"CXW Sales Price Currency Code"`
- **THEN** entstehen für jede Quellzeile drei neue Zeilen (DE, AT, FR), jeweils mit leerem `"CXW Currency Code"`

#### Scenario: Land in Quellwährung übernimmt den Preis gerundet
- **WHEN** die Landeswährung eines aktivierten Landes der Währung der Quellzeile entspricht
- **THEN** übernimmt die neue Zeile `"CXW Stock Price"`, `"CXW Recom. Retail Price"` und `"CXW Strike Price"` der Quellzeile, jeweils auf den nächsten vollen 10er aufgerundet, sowie `"CXW Exchange Rate Amount"` und `"CXW Exchange Rate Date"` unverändert

#### Scenario: Land in Fremdwährung erhält umgerechneten, gerundeten Preis
- **WHEN** die Landeswährung eines aktivierten Landes von der Währung der Quellzeile abweicht und ein `Currency Exchange Rate` für diese Währung existiert
- **THEN** werden `"CXW Stock Price"`, `"CXW Recom. Retail Price"` und `"CXW Strike Price"` mit dem aktuellsten Wechselkurs umgerechnet und anschließend auf den nächsten vollen 10er aufgerundet; `"CXW Exchange Rate Amount"` / `"CXW Exchange Rate Date"` werden ungerundet gefüllt

#### Scenario: Aufrunden auf den nächsten 10er
- **WHEN** der (umgerechnete) Preis einer Länderzeile `1.234,01` beträgt
- **THEN** wird `1.240` gespeichert

#### Scenario: Glatter 10er bleibt unverändert
- **WHEN** der (umgerechnete) Preis einer Länderzeile `1.230,00` beträgt
- **THEN** wird `1.230` gespeichert

#### Scenario: Preis 0 bleibt 0
- **WHEN** die Quellzeile z. B. keinen `"CXW Strike Price"` hat (`0`)
- **THEN** ist `"CXW Strike Price"` der erzeugten Länderzeile ebenfalls `0`

#### Scenario: Nicht aktiviertes Land wird übersprungen
- **WHEN** ein Land `"CXW Sales Price Activated"` = false hat
- **THEN** wird für dieses Land keine Zeile erzeugt

#### Scenario: Generierte Zeilen sind keine Quellzeilen
- **WHEN** "Add all Countries" Zeilen mit gesetztem `"CXW Country Code"` erzeugt hat
- **THEN** werden diese Zeilen weder im selben noch in einem späteren Lauf erneut als Quellzeile expandiert
