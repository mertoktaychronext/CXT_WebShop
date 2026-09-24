## Why

Die Aktion "Add all Currencies" auf Page 60322 "CXW Sales Price Checking List" erzeugt aus einer importierten Quellzeile genau eine Zeile pro aktivierter **Währung** (`Currency."CXW Sales Price Activated"`). Das Webshop-Zielsystem benötigt die Verkaufspreise aber **pro Land**: Jedes Land, in dem verkauft wird, braucht einen eigenen Preisdatensatz in seiner Verkaufswährung — auch wenn mehrere Länder dieselbe Währung nutzen (z. B. DE, AT, FR in EUR). Mit dem heutigen, rein währungsbasierten Modell fehlt diese Länderzuordnung vollständig: Es gibt weder eine Pflege "Land → Verkaufspreiswährung" noch ein Land auf der Prüfzeile, im Archiv oder im exportierten JSON.

## What Changes

- **BREAKING** Die Aktion "Add all Currencies" wird ersatzlos durch eine neue Aktion **"Add all Countries"** ersetzt. Sie erzeugt pro Quellzeile genau eine Zeile pro Land mit `"CXW Sales Price Activated" = true` — mit der für dieses Land hinterlegten Verkaufspreiswährung und dem entsprechend umgerechneten Preis. Länder mit gleicher Währung wie die Quellzeile erhalten ebenfalls eine eigene Zeile (Preis 1:1 übernommen).
- Neue Tabellenerweiterung auf `Country/Region` mit `"CXW Sales Price Activated"` (Boolean) und `"CXW Sales Price Currency Code"` (Code[10], Relation auf `Currency`, leer = Mandantenwährung), sichtbar über eine neue Page-Erweiterung auf "Countries/Regions".
- **BREAKING** Das Feld `"CXW Sales Price Activated"` auf `Currency` (Table Extension 60320) samt Spalte in der Währungsliste (Page Extension 60327) wird entfernt — die Aktivierung erfolgt künftig ausschließlich pro Land.
- Neues Feld `"CXW Country Code"` auf "CXW Sales Price Checking" (Table 60312) und "CXW Sales Price Archive" (Table 60313), jeweils Teil des Primärschlüssels. Importierte Quellzeilen haben ein leeres Land; generierte Zeilen tragen das Land.
- Idempotenz-Kennzeichen `"CXW Currencies Processed"` wird in `"CXW Countries Processed"` umbenannt (gleiche Feld-ID, gleiche Bedeutung).
- Export ("Upload Sales Price"): Das pro Zeile gesendete JSON enthält zusätzlich den Ländercode; Archiv-Versionierung erfolgt pro Artikel/Währung/Land. Das Rückschreiben in `"Sales Price"` bleibt pro Währung (Standardtabelle hat kein Land im Schlüssel).
- Neue Spalte "Country Code" auf der Checking-List, Captions/Tooltips/Translations (de-DE) und Doku (Handbücher, Funktionsregister) werden angepasst.

## Capabilities

### New Capabilities
- `sales-price-country-copy`: Pflege von Aktivierung und Verkaufspreiswährung pro Land sowie das Erzeugen einer Prüfzeile pro aktiviertem Land (mit Ländercode, Landeswährung und umgerechnetem Preis) über die Aktion "Add all Countries".

### Modified Capabilities
- `sales-price-currency-copy`: Wird vollständig entfernt (alle Requirements REMOVED) — ersetzt durch `sales-price-country-copy`.
- `sales-price-checking-writeback`: Archiv-Snapshot und Versionierung erfolgen pro Artikel/Währung/**Land**; der Archivdatensatz übernimmt den Ländercode der Prüfzeile.
- `sales-price-api-export`: Das pro Prüfzeile gesendete JSON enthält den Ländercode der Zeile.

## Impact

- **Page 60322** "CXW Sales Price Checking List" (`src/Pages/Pag60322.CXWSalesPriceCheckingList.al`): Aktion ersetzt, neue Spalte, Upload-Aktion reicht den Ländercode an den Export weiter.
- **Table 60312** "CXW Sales Price Checking" / **Table 60313** "CXW Sales Price Archive": neues Feld + Primärschlüsseländerung (Schema-Sync mit Datenverlust-Risiko im Archiv — siehe design.md).
- **Codeunit 60329** "CXW Export Gateway Sales Price": `ArchiveCheckingLine` filtert zusätzlich auf Land, `CreateExternalInterfaceFile` erhält den Ländercode (JSON-Feld + Dateiname).
- **XmlPort 60328** "CXW Import Sales Price": Sortierschlüssel an neuen Primärschlüssel anpassen; Import setzt kein Land (Quellzeilen).
- **Table Extension 60320 / Page Extension 60327** (Currency): entfernt. **Neu**: Table Extension 60346 "CXW Country/Region", Page Extension 60347 "CXW Countries/Regions".
- Permission Set `CXWChronWSAll`, `Translations/CHX.Webshop.de-DE.xlf`, `docs/` (Handbücher DE/EN, Funktionsregister) inkl. Confluence-Sync.
- Externes Zielsystem der Preis-API erhält ein zusätzliches JSON-Feld und mehr Datensätze (einer pro Land statt pro Währung) — Abstimmung mit dem Empfänger nötig.
