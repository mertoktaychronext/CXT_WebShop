## 1. Enum und Tabelle für die generische API-Einrichtung

- [x] 1.1 Enum "SL API Auth Type" anlegen (Werte: None, ApiKeyHeader, BasicAuth), Enum 51004
- [x] 1.2 Tabelle "SL API Interface Setup" anlegen (Table 51007): Code (PK), Description, Endpoint URL, Auth Type, Active, Source Table No.
- [x] 1.3 OnValidate auf "Active" = true: TestField auf Endpoint URL (nicht leer)
- [x] 1.4 Prozedur `SetApiKey` zum Setzen/Löschen des API-Keys über Isolated Storage (DataScope::Module)
- [x] 1.5 Prozedur `GetApiKey` zum Lesen des API-Keys aus Isolated Storage (nur intern verwendet)

## 2. Seite für die API-Einrichtung

- [x] 2.1 Seite "SL API Interface Setup" (Page 51003, List) mit Feldern aus 1.2, ApplicationArea/ToolTips ergänzt
- [x] 2.2 Eingabefeld für den API-Key als separates, nicht persistiertes Seitenfeld (ExtendedDatatype = Masked), OnValidate ruft `SetApiKey` auf
- [x] 2.3 UsageCategory = Administration/ApplicationArea = All auf Seitenebene gesetzt
- [x] 2.4 Navigation-Action auf Page 51000, die zur neuen Seite führt

## 3. Verknüpfung mit der Verkaufspreis-Einrichtung

- [x] 3.1 Neues Feld "API Interface Code" auf Table 51000 (Code[20], TableRelation auf "SL API Interface Setup")
- [x] 3.2 Feld + "Price Export Active" (war bisher nirgends im UI sichtbar) auf Page 51000 in neuer Gruppe "Export" ergänzt, ToolTips ergänzt
- [x] 3.3 OnValidate: TestField der referenzierten API-Einrichtung, dass "Source Table No." = Table::"Sales Price" ist

## 4. HTTP-Versand in Codeunit 51000

- [x] 4.1 Neue Prozedur `SendToApiInterface`, die "SL General Sales Price Setup" liest und bei aktivem Export + gesetztem Interface-Code die referenzierte API-Einrichtung per TestField validiert (Active, Source Table No., Endpoint URL)
- [x] 4.2 HTTP-Versand über `HttpClient`/`HttpRequestMessage`/`HttpContent` an die Endpoint-URL, Timeout 30s, Authentifizierung gemäß Auth Type (Header bei ApiKeyHeader, Basic-Auth-Header bei BasicAuth via `Base64 Convert`)
- [x] 4.3 Bei erfolgreicher Antwort (2xx): Table 51004 auf Status "Processed"; `CreateExternalInterfaceFile` gibt `true` zurück
- [x] 4.4 Bei Fehler (Netzwerkfehler oder Nicht-2xx): Table 51004 auf Status "Error", Fehlertext im neuen Feld "Response Message" (Table 51004); `CreateExternalInterfaceFile` gibt `false` zurück
- [x] 4.5 Versandfehler wirkt sich nur auf "Export Status" (Table 51001) aus, "Accept New Setup" bleibt unangetastet — Rückgabewert von `CreateExternalInterfaceFile` steuert in Page 51001, ob "Export Status" auf `Sent` oder `Error` gesetzt wird

## 5. UI-Rückmeldung

- [x] 5.1 Action "Upload Sales Price" (Page 51001) setzt "Export Status" jetzt anhand des Rückgabewerts von `CreateExternalInterfaceFile` (`Sent` bei Erfolg, `Error` bei Fehlschlag) statt immer `Sent`
- [x] 5.2 Boolean-Feld "Export Processed" durch Enum-Feld "Export Status" (Not Sent/Sent/Error) ersetzt (Enum 51003, Table 51001, Page 51001)
- [x] 5.3 Bestätigungsabfrage eingeführt: bereits als `Sent` markierte Zeilen werden nur nach `Confirm`-Bestätigung erneut verarbeitet; `Not Sent`/`Error`-Zeilen werden immer automatisch (erneut) versucht

## 6. Berechtigungen

- [x] 6.1 Permission Set "SLChronWSAll" um `tabledata`/`table`/`page` für "SL API Interface Setup" ergänzt

## 7. Nacharbeiten (nach Abschluss dieses Changes, nicht Teil der Umsetzung selbst)

- [ ] 7.1 `/al-funktionsregister` erneut laufen lassen
- [ ] 7.2 `/managing-bc-translations` für die neuen Strings laufen lassen
- [ ] 7.3 Key-User-/Entwicklerhandbuch um die neue API-Einrichtung ergänzen

## Hinweis

Der HTTP-Versand (Codeunit 51000, `HttpClient`/`HttpRequestMessage`/`HttpResponseMessage`/`HttpContent`/`HttpHeaders`) wurde in dieser Umgebung **nicht kompiliert** (kein AL-Compiler-CLI verfügbar). Insbesondere die Eigenschaften vs. Methoden auf den Http*-Objekten (`HttpStatusCode`, `Content`, `IsSuccessStatusCode()`) sollten beim ersten Build in VS Code geprüft werden — analog zum bereits einmal aufgetretenen `Variant.AsBoolean()`-Fehler in diesem Projekt.
