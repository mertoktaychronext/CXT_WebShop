# sales-price-country-copy Specification

## Purpose
Einrichtung von Aktivierung und Verkaufspreiswährung pro Land sowie Erzeugen je einer "CXW Sales Price Checking"-Zeile pro aktiviertem Land (mit Ländercode, Landeswährung und umgerechnetem Preis) über die Aktion "Add all Countries" auf Page 60322 "CXW Sales Price Checking List". Ersetzt die frühere Capability `sales-price-currency-copy`.
## Requirements
### Requirement: Verkaufspreis-Einrichtung pro Land
Die Tabelle `Country/Region` SHALL die Felder `"CXW Sales Price Activated"` (Boolean) und `"CXW Sales Price Currency Code"` (Code[10], Tabellenrelation auf `Currency`) bereitstellen. Beide Felder SHALL auf der Seite "Countries/Regions" pflegbar sein. Ein leerer `"CXW Sales Price Currency Code"` SHALL als Mandantenwährung (MW) interpretiert werden.

#### Scenario: Land für Verkaufspreise aktivieren
- **WHEN** ein Key User auf der Seite "Countries/Regions" für ein Land `"CXW Sales Price Activated"` = true und `"CXW Sales Price Currency Code"` = `CHF` setzt
- **THEN** wird dieses Land von "Add all Countries" berücksichtigt und erhält Preiszeilen in `CHF`

#### Scenario: Leere Verkaufspreiswährung bedeutet Mandantenwährung
- **WHEN** ein aktiviertes Land einen leeren `"CXW Sales Price Currency Code"` hat
- **THEN** erzeugt "Add all Countries" für dieses Land eine Zeile mit leerem `"CXW Currency Code"` (Mandantenwährung)

### Requirement: Aktivierung erfolgt nicht mehr pro Währung
Die Tabelle `Currency` SHALL kein Feld `"CXW Sales Price Activated"` mehr besitzen, und die Währungsliste SHALL keine entsprechende Spalte mehr anzeigen. Welche Währungen Preiszeilen erhalten, SHALL sich ausschließlich aus den aktivierten Ländern ergeben.

#### Scenario: Währung ohne aktiviertes Land
- **WHEN** eine Währung existiert, aber kein aktiviertes Land diese Währung als `"CXW Sales Price Currency Code"` hinterlegt hat
- **THEN** erzeugt "Add all Countries" keine Zeile in dieser Währung

### Requirement: Ländercode auf der Prüfzeile
"CXW Sales Price Checking" SHALL ein Feld `"CXW Country Code"` (Code[10], Tabellenrelation auf `Country/Region`) besitzen, das Teil des Primärschlüssels (`"CXW Item No."`, `"CXW Currency Code"`, `"CXW Country Code"`) ist und auf der Seite "CXW Sales Price Checking List" schreibgeschützt angezeigt wird. Per CSV importierte Zeilen SHALL einen leeren `"CXW Country Code"` haben und gelten als Quellzeilen.

#### Scenario: Importierte Zeile ist Quellzeile
- **WHEN** eine Zeile über "Import CSV" angelegt wird
- **THEN** ist ihr `"CXW Country Code"` leer

#### Scenario: Gleiche Währung, unterschiedliche Länder
- **WHEN** für denselben Artikel Zeilen für DE und AT, jeweils mit leerem `"CXW Currency Code"`, existieren sollen
- **THEN** können beide Zeilen ohne Schlüsselkonflikt nebeneinander bestehen

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

### Requirement: Idempotenz der Länder-Expansion
Nach erfolgreicher Expansion einer Quellzeile SHALL das System auf dieser Quellzeile `"CXW Countries Processed"` = true setzen. Quellzeilen mit `"CXW Countries Processed"` = true SHALL von weiteren Läufen ausgeschlossen sein.

#### Scenario: Erneuter Lauf nach erfolgreicher Expansion
- **WHEN** "Add all Countries" für alle Quellzeilen bereits erfolgreich gelaufen ist und erneut ausgeführt wird
- **THEN** meldet das System "Nothing to process" und legt keine Zeilen an

### Requirement: Vorbedingungen der Aktion
Vor dem Anlegen von Zeilen SHALL "Add all Countries" prüfen: `"CXW Minimum Margin %"` und `"CXW Stock Price Threshold %"` in der allgemeinen Verkaufspreis-Einrichtung sind gefüllt; mindestens eine Prüfzeile existiert; alle Prüfzeilen sind `"CXW Validated"` = true und `"CXW Accept New Setup"` = true; mindestens eine unverarbeitete Quellzeile existiert. Ist eine Bedingung verletzt, SHALL keine Zeile angelegt werden.

#### Scenario: Fehlende Einrichtung
- **WHEN** `"CXW Minimum Margin %"` oder `"CXW Stock Price Threshold %"` nicht gefüllt ist
- **THEN** bricht die Aktion mit Fehler ab und legt keine Zeilen an

#### Scenario: Nicht validierte oder nicht genehmigte Zeilen
- **WHEN** eine Prüfzeile `"CXW Validated"` = false oder `"CXW Accept New Setup"` = false hat
- **THEN** meldet die Aktion "Nothing to process" und legt keine Zeilen an

### Requirement: Feldübernahme von der Quellzeile
Jede von "Add all Countries" erzeugte Zeile SHALL `"CXW Reason Code"`, `"CXW Comment"`, `"CXW Starting Date"`, `"CXW Starting Time"`, `"CXW Ending Date"`, `"CXW Ending Time"`, `"CXW Approved By"` und `"CXW Accept New Setup"` von der Quellzeile übernehmen und mit `"CXW Validated"` = true angelegt werden.

#### Scenario: Übernommene Felder entsprechen der Quellzeile
- **WHEN** eine Länderzeile aus einer Quellzeile erzeugt wird
- **THEN** stimmen die genannten Felder mit der Quellzeile überein und `"CXW Validated"` = true

